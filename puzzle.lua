local dim_x, dim_y = 4, 4

local board ={}
local panels = {}
local order = {}
local blank = dim_x * dim_y

border = 2 / 32
function init_matrix(panel_w, panel_h)
  local panels = {}
  for y = 1, dim_y do
    for x = 1, dim_x do
      add(panels, {
        ['x'] = (x - 1) * panel_w + panel_w * border / 2,
        ['y'] = (y - 1) * panel_h + panel_h * border / 2,
        ['width'] = panel_w - panel_w * border,
        ['height'] = panel_h - panel_h * border,
      })
    end
  end
  return panels
end

moves = {
  [⬅️] = {['is_possible'] = function() return blank % dim_x != 0 end, ['v'] = 1}, -- left
  [➡️] = {['is_possible'] = function() return blank % dim_x != 1 end, ['v'] = -1}, --right
  [⬆️] = {['is_possible'] = function() return blank + dim_x <= #order end, ['v'] = dim_x}, -- up
  [⬇️] = {['is_possible'] = function() return blank - dim_x >= 1 end, ['v'] = -dim_x}, -- down
}

function possible_moves()
  local possible_moves = {}
  for i, move in pairs(moves) do
    if (move.is_possible()) add(possible_moves, move)
  end
  return possible_moves
end

function shuffle(order)
  local possible_moves = possible_moves()
  local destination = blank + possible_moves[flr(rnd(#possible_moves)) + 1].v
  order[blank], order[destination] = order[destination], order[blank]
  blank = destination
  return order
end

function is_complete()
  for i = 1, #order do
    if (i != order[i]) return false
  end
  return true
end

function render()
  cls()
  for i, cell in pairs(board) do
    local panel = panels[order[i]]
    if i != blank then
      -- TODO
      rectfill(cell.x, cell.y,
        cell.x + cell.width, cell.y + cell.height, 3)
      print(order[i], cell.x + 2, cell.y + 2, 0)
    end
  end
end

function render_complete()
  cls()
  print('you win', 50, 60, 7)
end

--

states = {}

states.wait = {
  ['update'] = function (self)
  end,
  ['draw'] = function (self)
  end,
}

states.shuffle = {
  ['count'] = dim_x * dim_y * 8 * 2,
  ['update'] = function (self)
    if (self.count % 2 == 0) order = shuffle(order)
    self.count-= 1
    if (self.count == 0) state = 'game'
  end,
  ['draw'] = function (self)
    render()
  end,
}

states.game = {
  ['update'] = function (self)
    if (is_complete()) state = 'complete'

    for key, move in pairs(moves) do
      if btnp(key) and move.is_possible() then
        local destination = blank + move.v
        order[blank], order[destination] = order[destination], order[blank]
        blank = destination
      end
    end
  end,
  ['draw'] = function (self)
    render()
  end,
}

states.complete = {
  ['update'] = function (self)
  end,
  ['draw'] = function (self)
    render_complete()
  end,
}

state = nil

function _init()
  board = init_matrix(128 / dim_x, 128 / dim_y)
  panels = init_matrix(128 / dim_x, 128 / dim_y)
  order = {}
  for i = 1, dim_x * dim_y do
    add(order, i)
  end

  state = 'shuffle'
end

function _update60()
  states[state]:update()
end

function _draw()
  states[state]:draw()
end
