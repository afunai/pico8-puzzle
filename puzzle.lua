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

function possible_directions()
  local directions = {}
  if (blank % dim_x != 1) add(directions, blank - 1)
  if (blank % dim_x != 0) add(directions, blank + 1)
  if (blank - dim_x >= 1) add(directions, blank - dim_x)
  if (blank + dim_x <= #order) add(directions, blank + dim_x)
  return directions
end

function shuffle(order)
  local directions = possible_directions()
  local destination = directions[flr(rnd(#directions)) + 1]
  order[blank], order[destination] = order[destination], order[blank]
  blank = destination
  return order
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
  -- TODO
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
  ['count'] = dim_x * dim_y * 8 * 5,
  ['update'] = function (self)
    if (self.count % 5 == 0) order = shuffle(order)
    self.count-= 1
    if (self.count == 0) state = 'wait'
  end,
  ['draw'] = function (self)
    render()
  end,
}

state = nil

function _init()
  board = init_matrix(128 / dim_x, 128 / dim_y)
  panels = init_matrix(128 / dim_x, 128 / dim_y)
  order = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16}

  state = 'shuffle'
end

function _update60()
  states[state]:update()
end

function _draw()
  states[state]:draw()
end
