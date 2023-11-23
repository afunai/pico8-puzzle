--preserve: Pen
if (Pen == nil) Pen = {data = {}}

local stages = {
  {
    dim_x = 2,
    dim_y = 2,
    img = {base = 'bunny_base'},
    bg_color = 14,
    music = 0,
  },
  {
    dim_x = 2,
    dim_y = 2,
    img = {base = 'ol_base', cloth = 'ol_cloth'},
    bg_color = 10,
    music = 0,
  },
  {
    dim_x = 3,
    dim_y = 3,
    img = {base = 'test', cloth = 'test_cloth'},
    bg_color = 9,
    music = 5,
  },
}
local stage_id = 1
local stage = stages[1]

local panel_img = nil
local board = {}
local panels = {}
local panel_ids = {}
local blank = 1
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

function init_panel_imgs(blank_panels)
  for panel in all(blank_panels) do
    panel.img = Pen.crop(panel_img, panel.x, panel.y,
      panel.x + panel.width - 1, panel.y + panel.height - 1)
  end
end

function prepare_cell(bg_color, cell, x, y)
  poke(0x5f55, 0x00) -- draw to sprite region
  cls() -- TODO
  rectfill(x, y, x + cell.width - 1, y + cell.height - 1, bg_color)
  Pen.draw(panel_img, x, y,
    {cell.x, cell.y, cell.x + cell.width - 1, cell.y + cell.height - 1})
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

function prepare_text(text, x, y)
  poke(0x5f55, 0x00) -- draw to sprite region
  cls() -- TODO
  local width = print(text, x, y)
  poke(0x5f55, 0x60) -- restore hardware state
  return {
    x = x,
    y = y,
    w = width - x,
    h = peek(0x5f27) - y,
  }
end

function symbol(x, y, t, ...)
  local args = {...}
  local scale_x = args[1] or 1
  local scale_y = args[2] or scale_x
  local cx = x + t.w / 2 - 1
  local cy = y + t.h / 2 - 1

  local offset = 0.3

  for sy = 0, (t.h - 1) do
    for sx = 0, (t.w - 1) do
      local col = sget(sx + t.x, sy + t.y)
      if col > 0 then
        rectfill(
          (x + sx - cx - offset) * scale_x + cx - sgn(scale_x),
          (y + sy - cy - offset) * scale_y + cy - sgn(scale_y),
          (x + sx - cx + offset) * scale_x + cx + sgn(scale_x),
          (y + sy - cy + offset) * scale_y + cy + sgn(scale_y),
          7)
      end
    end
  end

  for sy = 0, (t.h - 1) do
    for sx = 0, (t.w - 1) do
      local col = sget(sx + t.x, sy + t.y)
      if col > 0 then
        rectfill(
          (x + sx - cx - offset) * scale_x + cx,
          (y + sy - cy - offset) * scale_y + cy,
          (x + sx - cx + offset) * scale_x + cx,
          (y + sy - cy + offset) * scale_y + cy,
          col)
      end
    end
  end
end

--

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

function get_possible_moves()
  local possible_moves = {}
  for cell_id, _ in pairs(panel_ids) do
    for _, move in pairs(moves) do
      if move.is_possible(cell_id) and cell_id != prev_cell_id then
        add(possible_moves, cell_id)
      end
    end
  end
  return possible_moves
end

function shuffle(current_panel_ids)
  local possible_moves = get_possible_moves()
  local cell_id = possible_moves[flr(rnd(#possible_moves)) + 1]
  current_panel_ids[blank], current_panel_ids[cell_id] =
    current_panel_ids[cell_id], current_panel_ids[blank]
  blank = cell_id
  prev_cell_id = cell_id
  return current_panel_ids
end

function is_complete()
  for i = 1, #panel_ids do
    if (i != panel_ids[i]) return false
  end
  return true
end

threads = {}

threads.bg = {
  particles = {},
  update = function (self)
    if #self.particles == 0 then
        for _ = 1, 10 do
          add(self.particles,
            {x = rnd(120),
            y = rnd(20) + 120,
            deg = rnd(1),
            vd = (rnd(2) - 1) / 30})
        end
    end

    local vy = -0.5
    if (state == 'complete' or state == 'minigame') vy = -2

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
    if (state == 'complete' or state == 'minigame') char = "\f8\^p♥"

    for p in all(self.particles) do
      print(char, p.x, p.y)
    end
  end,
}

function render_background()
  if state == 'complete' or state == 'minigame' then
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
  if state == 'game' or state == 'complete' or state == 'minigame' then
    threads.bg:update()
    threads.bg:draw()
  end
end

function render_blank()
  local blank_cell = board[blank]
  local x, y = blank_cell.x, blank_cell.y
  rectfill(x - 1, y - 1, x + blank_cell.width, y + blank_cell.height, 0)
end

function render_panel(panel_id, cell, ...)
  local args = {...}
  local x = cell.x + (args[1] or 0) -- offset_x
  local y = cell.y + (args[2] or 0) -- offset_y

  rect(x - 1, y - 1, x + cell.width, y + cell.height, 0)
  if (panel_id != cell.id) pal({0, 5, 5, 5, 5, 6, 7, 5, 6, 6, 6, 6, 6, 6, 6, 0}, 0)
  Pen.draw(panels[panel_id].img, x, y)
  pal()
  print(panel_id, x + 2, y + 2, 0)
end

function render_board(stop_render_blank)
  render_background()
  if (not stop_render_blank) render_blank()
  for i, cell in pairs(board) do
    if (i != blank) render_panel(panel_ids[i], cell)
  end
end

function render_cursor()
  local moveable = false
  for _, move in pairs(moves) do
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

--

states = {}

states.init = {
  update = function (_)
    stage = stages[stage_id]
    if stage.img.cloth != nil then
      panel_img = Pen.composite(stage.img.cloth, stage.img.base)
    else
      panel_img = Pen.get(stage.img.base)
    end
    board = {}
    panels = {}
    panel_ids = {}
    blank = stage.dim_x * stage.dim_y
    active_cell_id = 1

    local panel_w = flr(128 / stage.dim_x)
    local panel_h = flr(128 / stage.dim_y)
    board = init_matrix(panel_w, panel_h)
    panels = init_matrix(panel_w, panel_h)
    init_panel_imgs(panels)
    panel_ids = {}
    for panel_id = 1, stage.dim_x * stage.dim_y do
      add(panel_ids, panel_id)
    end

    state = 'shuffle'
  end,
  draw = function (_)
  end,
}

states.shuffle = {
  update = function (self)
    if self.count == nil then
      self.count = stage.dim_x * stage.dim_y * 8 * 2
      self.t = prepare_text('\f1stage '..stage_id, 32, 0)
      music(-1)
    end

    if (self.count % 2 == 0) then
      sfx(4)
      panel_ids = shuffle(panel_ids)
    end
    self.count -= 1
    if self.count == 0 then
      self.count = nil
      music(stage.music)
      state = 'game'
    end
  end,
  draw = function (self)
    render_board()
    if self.t != nil then
      symbol(65 - self.t.w / 2, 65 - self.t.h / 2 + cos(time() * 1.5) * 5,
        self.t, 3, 3)
    end
  end,
}

states.game = {
  update = function (_)
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
      for _, move in pairs(moves) do
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
  draw = function (_)
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
  radius = 64,
  update = function (self)
    if self.cell == nil then
      local last_cell = panels[#panels]
      self.cell = prepare_cell(stage.bg_color, last_cell, 64, 0)
      self.cx = 127 - last_cell.width / 2
      self.cy = 63 - last_cell.height / 2
      self.angle1 = 0.25
      self.angle2 = 0
    else
      self.angle1 += 0.00625
      if (self.angle1 > 0.75) then
        self.cell = nil
        sfx(3, -2)
        sfx(0)
        render_board(true)
        render_panel(#panels, board[#board])
        for _ = 1, 25 do flip() end
        state = 'complete_logo'
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

shades = {
  0b1111111111111011,
  0b1111011111111101,
  0b1111111011111010,
  0b1111010111110101,
  0b1111101001111010,
  0b1110010111100101,
  0b0111101001011010,
  0b1010010110100101,

  0b0101101001001010,
  0b1010010100000101,
  0b0001101000001010,
  0b0000010100000101,
  0b0000101000000010,
  0b0000010000000100,
  0b0000001000000000,
  0b0000000000000000,
}

states.complete_logo = {
  update = function (self)
    if self.t == nil then
      music(7)
      self.t = prepare_text('\f8\|gs\|ht\|ha\|hg\|he\n\|cc\|hl\|he\|ha\|hr', 32, 0)
      self.frame = 0
      self.scale = 15
    else
      if self.frame > 0.25 and self.scale >= 4 then
        self.scale = 5
        self.frame += 5.002
        if self.frame > 1000 then
          self.t = nil
          state = 'complete'
        end
      else
        self.frame += 0.01
        self.scale = cos(self.frame) * 15
      end
    end
  end,
  draw = function (self)
    render_board(true)
    render_panel(#panels, board[#board])
    if self.frame != nil and self.frame > 1 then
      fillp(shades[min(flr(self.frame / 5) + 1, 16)] + 0b.1)
      rectfill(0, 0, 127, 127, 0)
      fillp()
    end
    if self.t != nil then
      symbol(65 - self.t.w / 2, 65 - self.t.h / 2,
        self.t, cos(self.frame * 5) * self.scale, abs(self.scale))
    end
  end,
}

states.complete = {
  frame = 16,
  update = function (self)
    self.frame -= 0.25
    if self.frame <= 0 then
      self.frame = 16
      state = 'minigame'
    end
  end,
  draw = function (self)
    render_background()
    Pen.draw(stage.img.base)
    if (stage.img.cloth != nil) Pen.draw(stage.img.cloth)

    fillp(shades[ceil(self.frame)] + 0b.1)
    rectfill(0, 0, 127, 127, 0)
    fillp()
  end,
}

states.minigame = {
  opacity = 16.5,
  frames_from_click = 0,

  update = function (self)
    if btnp(❎) then
      if (self.frames_from_click == 0) self.frames_from_click = 1
      self.opacity -= 0.5
    end

    if self.frames_from_click > 0 then
      self.frames_from_click += 1
      if (self.opacity > 1) self.opacity += self.frames_from_click / 10000
      if self.frames_from_click == 30 and self.opacity >= 16 then
        self.opacity = 17 -- skip minigame if not double clicked
      end
    end

    if self.opacity > 16.5 or self.frames_from_click > 12 * 60 then
      self.opacity = 16.5
      self.frames_from_click = 0
      stage_id += 1
      if (stage_id > #stages) stage_id = 1
      state = 'init'
    end
  end,
  draw = function (self)
    render_background()
    Pen.draw(stage.img.base)
    if (stage.img.cloth != nil) Pen.draw(stage.img.cloth, 0, 0, nil, self.opacity)
    if (self.opacity > 1) print('❎', 118, 119 + (time() * 8 % 2), 0)
  end,
}

function _init()
  state = 'init'
end

function _update60()
  states[state]:update()
end

function _draw()
  states[state]:draw()
end
