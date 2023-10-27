local dim_x, dim_y = 4, 4

local board ={}
local panels = {}
local order = {}
local blank = dim_x * dim_y
local active_cell_id = 10

border = 2
function init_matrix(panel_w, panel_h)
  local panels = {}
  for y = 1, dim_y do
    for x = 1, dim_x do
      add(panels, {
        ['x'] = (x - 1) * panel_w + border / 2,
        ['y'] = (y - 1) * panel_h + border / 2,
        ['width'] = panel_w - border,
        ['height'] = panel_h - border,
      })
    end
  end
  return panels
end

moves = {
  [⬅️] = {
    ['is_possible'] = function(cell_id) return cell_id == blank + 1 and blank % dim_x != 0 end,
    ['v'] = -1},
  [➡️] = {
    ['is_possible'] = function(cell_id) return cell_id == blank - 1 and blank % dim_x != 1 end,
    ['v'] = 1},
  [⬆️] = {
    ['is_possible'] = function(cell_id) return cell_id == blank + dim_x end,
    ['v'] = -dim_x},
  [⬇️] = {
    ['is_possible'] = function(cell_id) return cell_id == blank - dim_x end,
    ['v'] = dim_x},
}

function possible_moves()
  local possible_moves = {}
  for cell_id, panel_id in pairs(order) do
    for key, move in pairs(moves) do
      if (move.is_possible(cell_id)) add(possible_moves, cell_id)
    end
  end
  return possible_moves
end

function shuffle(order)
  local possible_moves = possible_moves()
  local cell_id = possible_moves[flr(rnd(#possible_moves)) + 1]
  order[blank], order[cell_id] = order[cell_id], order[blank]
  blank = cell_id
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
    if i != blank then
      local panel_id = order[i]
      -- TODO
      rectfill(cell.x, cell.y,
        cell.x + cell.width, cell.y + cell.height, 3)
      print(panel_id, cell.x + 2, cell.y + 2, 0)
    end
  end
end

function render_cursor()
  local moveable = false
  for key, move in pairs(moves) do
    if (move.is_possible(active_cell_id)) moveable = true
  end

  local cell = board[active_cell_id]
  if moveable then
    if (time() * 2 % 1 > .5) fillp(0b1010010110100101) else fillp(0b0101101001011010)
  end
  rect(cell.x - 1, cell.y - 1,
    cell.x + cell.width + 1, cell.y + cell.height + 1, 7)
  fillp(0)
end

function render_complete()
  print('you win', 51, 60, 7)
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

    if (btnp(⬅️) and active_cell_id % 4 != 1) active_cell_id -= 1
    if (btnp(➡️) and active_cell_id % 4 != 0) active_cell_id += 1
    if (btnp(⬆️) and active_cell_id > dim_x) active_cell_id -= dim_x
    if (btnp(⬇️) and active_cell_id <= dim_x * (dim_y - 1)) active_cell_id += dim_x

    if btnp(❎) then
      for key, move in pairs(moves) do
        if move.is_possible(active_cell_id) then
          order[blank], order[active_cell_id] = order[active_cell_id], order[blank]
          blank, active_cell_id = active_cell_id, blank
          break
        end
      end
    end
  end,
  ['draw'] = function (self)
    render()
    render_cursor()
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
  for panel_id = 1, dim_x * dim_y do
    add(order, panel_id)
  end

  state = 'shuffle'
end

function _update60()
  states[state]:update()
end

function _draw()
  states[state]:draw()
end
