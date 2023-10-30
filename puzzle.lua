local dim_x, dim_y = 4, 4

local board ={}
local panels = {}
local panel_ids = {}
local blank = dim_x * dim_y
local active_cell_id = 10

border = 2
function init_matrix(panel_w, panel_h)
  local matrix = {}
  for y = 1, dim_y do
    for x = 1, dim_x do
      add(matrix, {
        ['x'] = (x - 1) * panel_w + border / 2,
        ['y'] = (y - 1) * panel_h + border / 2,
        ['width'] = panel_w - border,
        ['height'] = panel_h - border,
      })
    end
  end
  return matrix
end

moves = {
  [⬅️] = {
    ['is_possible'] = function(cell_id) return cell_id == blank + 1 and blank % dim_x != 0 end,
    ['vx'] = -1, ['vy'] = 0},
  [➡️] = {
    ['is_possible'] = function(cell_id) return cell_id == blank - 1 and blank % dim_x != 1 end,
    ['vx'] = 1, ['vy'] = 0},
  [⬆️] = {
    ['is_possible'] = function(cell_id) return cell_id == blank + dim_x end,
    ['vx'] = 0, ['vy'] = -1},
  [⬇️] = {
    ['is_possible'] = function(cell_id) return cell_id == blank - dim_x end,
    ['vx'] = 0, ['vy'] = 1},
}

function possible_moves()
  local possible_moves = {}
  for cell_id, panel_id in pairs(panel_ids) do
    for key, move in pairs(moves) do
      if (move.is_possible(cell_id)) add(possible_moves, cell_id)
    end
  end
  return possible_moves
end

function shuffle(panel_ids)
  local possible_moves = possible_moves()
  local cell_id = possible_moves[flr(rnd(#possible_moves)) + 1]
  panel_ids[blank], panel_ids[cell_id] = panel_ids[cell_id], panel_ids[blank]
  blank = cell_id
  return panel_ids
end

function is_complete()
  for i = 1, #panel_ids do
    if (i != panel_ids[i]) return false
  end
  return true
end

function render_panel(panel_id, cell, ...)
  args = {...}
  local x = cell.x + (args[1] or 0) -- offset_x
  local y = cell.y + (args[2] or 0) -- offset_y

  -- TODO
  rectfill(x, y, x + cell.width - 1, y + cell.height - 1, 3)
  print(panel_id, x + 2, y + 2, 0)
end

function render_board()
  cls()
  for i, cell in pairs(board) do
    if (i != blank) render_panel(panel_ids[i], cell)
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
    cell.x + cell.width, cell.y + cell.height, 7)
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
    if (self.count % 2 == 0) panel_ids = shuffle(panel_ids)
    self.count-= 1
    if (self.count == 0) state = 'game'
  end,
  ['draw'] = function (self)
    render_board()
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
          sfx(0)
          states.sliding.move = move
          state = 'sliding'
          break
        end
      end
    end
  end,
  ['draw'] = function (self)
    render_board()
    render_cursor()
  end,
}

states.sliding = {
  ['frame_count'] = 5,
  ['frame'] = 0,
  ['move'] = nil,
  ['update'] = function (self)
    if self.frame < self.frame_count then
      self.frame += 1
    else
      panel_ids[blank], panel_ids[active_cell_id] = panel_ids[active_cell_id], panel_ids[blank]
      blank, active_cell_id = active_cell_id, blank
      self.frame = 0
      if (active_cell_id == panel_ids[active_cell_id]) sfx(1)
      state = 'game'
    end
  end,
  ['draw'] = function (self)
    cls()
    for i, cell in pairs(board) do
      if (i != active_cell_id and i != blank) render_panel(panel_ids[i], cell)
    end

    local sliding_cell = board[active_cell_id]
    render_panel(panel_ids[active_cell_id], sliding_cell,
      sliding_cell.width / self.frame_count * self.frame * self.move.vx,
      sliding_cell.height / self.frame_count * self.frame * self.move.vy)
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
  panel_ids = {}
  for panel_id = 1, dim_x * dim_y do
    add(panel_ids, panel_id)
  end

  state = 'shuffle'
end

function _update60()
  states[state]:update()
end

function _draw()
  states[state]:draw()
end
