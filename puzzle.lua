local stages = {
  {
    dim_x = 4,
    dim_y = 4,
    img_name = 'test',
    bg_color = 12,
    music = 0,
  },
}
local stage_id = 1
local stage = stages[stage_id]

local board ={}
local panels = {}
local panel_ids = {}
local blank = stage.dim_x * stage.dim_y
local active_cell_id = 1

border = 2
function init_matrix(panel_w, panel_h)
  local offset_x = flr((128 - stage.dim_x * panel_w) / 2)
  local offset_y = flr((128 - stage.dim_y * panel_h) / 2)
  local matrix = {}
  for y = 1, stage.dim_y do
    for x = 1, stage.dim_x do
      add(matrix, {
        id = (y - 1) * stage.dim_x + x,
        x = (x - 1) * panel_w + border / 2 + offset_x,
        y = (y - 1) * panel_h + border / 2 + offset_y,
        width = panel_w - border,
        height = panel_h - border,
      })
    end
  end
  return matrix
end

function init_panel_imgs(panels, img_name)
  for panel in all(panels) do
    panel.img = crop_img(img_name, panel.x, panel.y,
      panel.x + panel.width - 1, panel.y + panel.height - 1)
  end
end

function prepare_cell(img_name, bg_color, cell, x, y)
  poke(0x5f55, 0x00) -- draw to sprite region
  rectfill(x, y, x + cell.width - 1, y + cell.height - 1, bg_color)
  draw_img(img_name, x, y, cell.x, cell.y,
    cell.x + cell.width - 1, cell.y + cell.height - 1)
  poke(0x5f55, 0x60) -- restore
  return {
    x = x,
    y = y,
    w = cell.width,
    h = cell.height,
  }
end

function rotate_cell(c, x, y, angle)
  local cs = cos(angle)
  local sn = sin(angle)
  local s = max(sqrt(c.w ^ 2 / 2), sqrt(c.h ^ 2 / 2))
  for oy = -s, s do
    for ox = -s, s do
      local sx = (cs * ox - sn * oy) + c.w / 2
      local sy = (cs * oy + sn * ox) + c.h / 2
      local col = sget(sx + c.x, sy + c.y)
      if (col > 0) pset(x + ox, y + oy, col)
    end
  end
end

moves = {
  ⬅️ = {
    is_possible = function(cell_id) return cell_id == blank + 1 and blank % stage.dim_x != 0 end,
    vx = -1, vy = 0},
  ➡️ = {
    is_possible = function(cell_id) return cell_id == blank - 1 and blank % stage.dim_x != 1 end,
    vx = 1, vy = 0},
  ⬆️ = {
    is_possible = function(cell_id) return cell_id == blank + stage.dim_x end,
    vx = 0, vy = -1},
  ⬇️ = {
    is_possible = function(cell_id) return cell_id == blank - stage.dim_x end,
    vx = 0, vy = 1},
}

local prev_cell_id = nil

function possible_moves()
  local possible_moves = {}
  for cell_id, panel_id in pairs(panel_ids) do
    for key, move in pairs(moves) do
      if move.is_possible(cell_id) and cell_id != prev_cell_id then
        add(possible_moves, cell_id)
      end
    end
  end
  return possible_moves
end

function shuffle(panel_ids)
  local possible_moves = possible_moves()
  local cell_id = possible_moves[flr(rnd(#possible_moves)) + 1]
  panel_ids[blank], panel_ids[cell_id] = panel_ids[cell_id], panel_ids[blank]
  blank = cell_id
  prev_cell_id = cell_id
  return panel_ids
end

function is_complete()
  for i = 1, #panel_ids do
    if (i != panel_ids[i]) return false
  end
  return true
end

function render_background()
  if state == 'complete' then
    cls(stage.bg_color)
  else
    cls()
    rectfill(
      board[1].x,
      board[1].y,
      board[#board].x + board[#board].width,
      board[#board].y + board[#board].height,
      stage.bg_color
    )
  end
  states.bg:update()
  states.bg:draw()
end

function render_blank()
  local blank_cell = board[blank]
  local x, y = blank_cell.x, blank_cell.y
  rectfill(x - 1, y - 1, x + blank_cell.width, y + blank_cell.height, 0)
end

function render_panel(panel_id, cell, ...)
  args = {...}
  local x = cell.x + (args[1] or 0) -- offset_x
  local y = cell.y + (args[2] or 0) -- offset_y

  rect(x - 1, y - 1, x + cell.width, y + cell.height, 0)
  if (panel_id != cell.id) pal({0, 5, 5, 5, 5, 6, 7, 5, 6, 6, 6, 6, 6, 6, 6, 0}, 0)
  draw_img(panels[panel_id].img, x, y)
  pal()
  print(panel_id, x + 2, y + 2, 0)
end

function render_board()
  render_background()
  render_blank()
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
    print('❎', cell.x + cell.width / 2 - 4, cell.y + cell.height / 2 - 4 + (time() * 4 % 2))
  end
  rect(cell.x - 1, cell.y - 1,
    cell.x + cell.width, cell.y + cell.height, 7)
  fillp(0)
end

function render_complete()
  render_background()
  draw_img(stage.img_name)
  print('clear!', 52, 3, 7)
end

--

states = {}

states.wait = {
  update = function (self)
  end,
  draw = function (self)
  end,
}

states.shuffle = {
  count = stage.dim_x * stage.dim_y * 8 * 2,
  update = function (self)
    if (self.count % 2 == 0) panel_ids = shuffle(panel_ids)
    self.count-= 1
    if self.count == 0 then
      music(stage.music)
      state = 'game'
    end
  end,
  draw = function (self)
    render_board()
  end,
}

states.game = {
  update = function (self)
    if is_complete() then
      music(-1)
      sfx(3)
      state = 'last_cell'
    end

    if (btnp(⬅️) and active_cell_id % stage.dim_x != 1) active_cell_id -= 1
    if (btnp(➡️) and active_cell_id % stage.dim_x != 0) active_cell_id += 1
    if (btnp(⬆️) and active_cell_id > stage.dim_x) active_cell_id -= stage.dim_x
    if (btnp(⬇️) and active_cell_id <= stage.dim_x * (stage.dim_y - 1)) active_cell_id += stage.dim_x

    if btnp(❎) then
      for key, move in pairs(moves) do
        if move.is_possible(active_cell_id) then
          sfx(0)
          states.sliding.move = move
          state = 'sliding'
          return
        end
      end
      sfx(2)
    end
  end,
  draw = function (self)
    render_board()
    render_cursor()
  end,
}

states.sliding = {
  frame_count = 5,
  frame = 0,
  move = nil,
  update = function (self)
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
  draw = function (self)
    render_background()
    render_blank()
    for i, cell in pairs(board) do
      if (i != active_cell_id and i != blank) render_panel(panel_ids[i], cell)
    end

    local sliding_cell = board[active_cell_id]
    render_panel(panel_ids[active_cell_id], sliding_cell,
      sliding_cell.width * self.frame * self.move.vx / self.frame_count,
      sliding_cell.height * self.frame * self.move.vy / self.frame_count)
  end,
}

states.last_cell = {
  cell = nil,
  cx = 0,
  cy = 0,
  radius = 64,
  angle1 = 0,
  angle2 = 0,
  update = function (self)
    if self.cell == nil then
      local last_cell = panels[#panels]
      self.cell = prepare_cell(stage.img_name, stage.bg_color, last_cell, 64, 0)
      self.cx = 127 - last_cell.width / 2
      self.cy = 63 - last_cell.height / 2
      radius = 64
      self.angle1 = 0.25
      self.angle2 = 0
    else
      self.angle1 += 0.00625
      if (self.angle1 > 0.75) then
        self.cell = nil
        sfx(3, -2)
        sfx(0)
        music(4)
        state = 'complete'
      else
        self.angle2 = (self.angle2 + 0.05) % 1
      end
    end
  end,
  draw = function (self)
    render_board()
    if self.cell != nil then
      rotate_cell(
        self.cell,
        cos(self.angle1) * self.radius * 1.8 + self.cx,
        sin(self.angle1) * self.radius + self.cy,
        self.angle2
      )
    end
  end,
}

states.complete = {
  update = function (self)
  end,
  draw = function (self)
    render_complete()
  end,
}

states.bg = {
  particles = {},
  update = function (self)
    if #self.particles == 0 then
        for i = 1, 10 do
          add(self.particles,
            {x = rnd(120),
            y = rnd(20) + 120,
            deg = rnd(1),
            vd = (rnd(2) - 1) / 30})
        end
    end

    local vy = -0.5
    if (state == 'complete') vy = -2

    for p in all(self.particles) do
       p.x += cos(p.deg)
       p.y += sin(p.deg) + vy
       p.deg += p.vd
       if (rnd(10) < 1) p.vd = (rnd(2) - 1) / 30
       if p.y < -10 then
         p.x = rnd(120)
         p.y = rnd(20) + 120
       end
    end
  end,
  draw = function (self)
    local char = "\f1\^w\^t?"
    if (state == 'complete') char = "\f8\^p♥"

    for p in all(self.particles) do
      print(char, p.x, p.y)
    end
  end,
}

state = nil

function _init()
  local panel_w = flr(128 / stage.dim_x)
  local panel_h = flr(128 / stage.dim_y)
  board = init_matrix(panel_w, panel_h)
  panels = init_matrix(panel_w, panel_h)
  init_panel_imgs(panels, stage.img_name)
  panel_ids = {}
  for panel_id = 1, stage.dim_x * stage.dim_y do
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
