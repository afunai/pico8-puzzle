--preserve: Pen
if (Pen == nil) Pen = {data = {}}

local stages = {
  {
    dim_x = 2,
    dim_y = 2,
    img = {base = 'swimsuit_base', cloth = 'swimsuit_cloth'},
    bg_color = 12,
    music = 5,
    balloon = {text = 'you\'ll\nget soaked\nif you\'re\nnear me!', x = 80, y = 9},
  },
  {
    dim_x = 2,
    dim_y = 2,
    img = {base = 'teacher_base', cloth = 'teacher_cloth'},
    bg_color = 10,
    music = 0,
    balloon = {text = 'it\'s\nyour\nturn\nto\nteach\nme\f8♥', x = 77, y = 8},
  },
  {
    dim_x = 2,
    dim_y = 2,
    img = {base = 'candy_base'},
    bg_color = 1,
    music = 0,
    balloon = {text = 'you\ndirty\nold\ndevil!\-h\fe:\-e)', x = 15, y = 35},
  },
  {
    dim_x = 2,
    dim_y = 2,
    img = {base = 'bunny_base'},
    bg_color = 14,
    music = 0,
    balloon = {text = '\f8game over\n\|j\fethank you\nfor\nplaying\nwith us\f8♥', x = 13, y = 15},
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
      if sx >= 0 and sx < c.w and sy >= 0 and sy <= c.h then -- opaque square
        pset(x + ox, y + oy, sget(sx + c.x, sy + c.y))
      end
    end
  end
end

--

local moves = {
  {
    is_possible = function(cell_id) return cell_id == blank + 1 and blank % stage.dim_x != 0 end,
    vx = -1, vy = 0},
  {
    is_possible = function(cell_id) return cell_id == blank - 1 and blank % stage.dim_x != 1 end,
    vx = 1, vy = 0},
  {
    is_possible = function(cell_id) return cell_id == blank + stage.dim_x end,
    vx = 0, vy = -1},
  {
    is_possible = function(cell_id) return cell_id == blank - stage.dim_x end,
    vx = 0, vy = 1},
}

local prev_cell_id = nil

function get_possible_moves()
  local possible_moves = {}
  for cell_id, _ in pairs(panel_ids) do
    for move in all(moves) do
      if move.is_possible(cell_id) and cell_id != prev_cell_id then
        add(possible_moves, cell_id)
      end
    end
  end
  return possible_moves
end

function shuffle()
  local possible_moves = get_possible_moves()
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

threads = {}

threads.bg = {
  particles = {},
  update = function (self, in_game)
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
    if (not in_game) vy = -2

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
  draw = function (self, in_game)
    local char = "\f7\^w\^t?"
    if (not in_game) char = "\f8\^p♥"

    for p in all(self.particles) do
      print(char, p.x, p.y)
    end

    if in_game then
      -- repaint the frame :(
      local rx1 = board[1].x - 1
      local ry1 = board[1].y - 1
      local rx2 = board[#board].x + board[#board].width
      local ry2 = board[#board].y + board[#board].height
      if (rx1 > 0) rectfill(0, 0, rx1, 127, 0)
      if (rx2 < 127) rectfill(rx2, 0, 127, 127, 0)
      if (ry1 > 0) rectfill(0, 0, 127, ry1, 0)
      if (ry2 < 127) rectfill(0, ry2, 127, 127, 0)
    end
  end,
}

function render_board_background()
  cls()
  rectfill(
    board[1].x,
    board[1].y,
    board[#board].x + board[#board].width,
    board[#board].y + board[#board].height,
    stage.bg_color
  )
  threads.bg:update(true)
  threads.bg:draw(true)
end

function render_complete_background()
  cls(stage.bg_color)
  threads.bg:update(false)
  threads.bg:draw(false)
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
  pal(0)
  print(panel_id, x + 2, y + 2, 0)
end

function render_board(stop_render_blank)
  render_board_background()
  if (not stop_render_blank) render_blank()
  for i, cell in pairs(board) do
    if (i != blank) render_panel(panel_ids[i], cell)
  end
end

function render_cursor()
  local moveable = false
  for move in all(moves) do
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

states.title = {
  text = '\f8press ❎\nto start',
  title = '\f8panels\n  \-i&\n\-igirls',
  update = function (self)
    if (not self.bt) self.bt = prepare_text(self.text, 0, 0)
    if (not self.tt) self.tt = prepare_text(self.title, 0, 0)

    if btnp(❎) then
      self.tt = nil
      stage_id = 1
      state = 'init'
    end
  end,
  draw = function (self)
    cls(12)
    render_complete_background()
    Pen.draw('bunny_base', 2, cos(time() / 3) * 2.5)
    if (time() % 10 > 9.5) Pen.draw('bunny_wink', 2, cos(time() / 3) * 2.5)
    balloon(self.text, self.bt, 15, 55)
    if (self.tt) symbol(20, 20, self.tt, 2, 2)
  end,
}

states.init = {
  update = function (_)
    Pen.cache = nil -- prevent 'out of memory'

    stage = stages[stage_id]
    board = {}
    panels = {}
    panel_ids = {}
    panel_img = nil
    blank = stage.dim_x * stage.dim_y
    active_cell_id = 1

    if stage.img.cloth != nil then
      panel_img = Pen.composite(stage.img.cloth, stage.img.base)
    else
      panel_img = Pen.get(stage.img.base)
    end

    local panel_w = flr(128 / stage.dim_x)
    local panel_h = flr(128 / stage.dim_y)
    board = init_matrix(panel_w, panel_h)
    panels = init_matrix(panel_w, panel_h)
    init_panel_imgs(panels)
    for panel_id = 1, stage.dim_x * stage.dim_y do
      add(panel_ids, panel_id)
    end

    if (stage.balloon.t == nil) stage.balloon.t = prepare_text(stage.balloon.text, 0, 0)

    state = 'shuffle'
  end,
  draw = function (_)
  end,
}

states.shuffle = {
  update = function (self)
    if self.count == nil then
      self.count = stage.dim_x * stage.dim_y * 8 * 3
      self.t = prepare_text('\f1stage '..stage_id, 32, 0)
      music(-1)
    end

    if (self.count % 2 == 0) then
      sfx(4)
      shuffle()
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
      for move in all(moves) do
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
    render_board_background()
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
  0b1111111111111111,

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
  max_frames = 800,
  update = function (self)
    if self.t == nil then
      music(7)
      self.t = prepare_text('\f8\|gs\|ht\|ha\|hg\|he\n\|cc\|hl\|he\|ha\|hr', 32, 0)
      self.frame = 0
      self.scale = 15
    else
      if self.frame > 0.25 and self.scale >= 4 then
        self.scale = 5
        self.frame += 5.0014
        if self.frame > self.max_frames then
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
    if (self.t == nil) return

    if self.frame / 5 < 17 then
      -- fade out the panels
      render_board(true)
      render_panel(#panels, board[#board])
      fillp(shades[flr(self.frame / 5) + 1] + 0b.1)
      rectfill(0, 0, 127, 127, stage.bg_color)
      fillp()
    else
      render_complete_background()
    end

    if (cos(self.frame * 5) < 0) pal(8, 6, 0)
    symbol(65 - self.t.w / 2, 65 - self.t.h / 2,
      self.t, cos(self.frame * 5) * self.scale, abs(self.scale))
    pal(0)
  end,
}

states.complete = {
  frame = 17,
  update = function (self)
    self.frame -= 0.25
    if self.frame <= 0 then
      self.frame = 17
      state = 'minigame'
    end
  end,
  draw = function (self)
    render_complete_background()
    Pen.draw(panel_img)

    fillp(shades[ceil(self.frame)] + 0b.1)
    rectfill(0, 0, 127, 127, 0)
    fillp()
  end,
}

states.minigame = {
  y = 0,
  opacity = 16,
  update = function (self)
    if self.frames_from_click == nil then
      self.frames_from_click = 0
      self.opacity = 16.5
      self.min_y = min(128 - panel_img.h, 0)
      self.radius = abs(self.min_y / 2)
      self.angle = nil
      self.y = 0
    end

    if btnp(❎) then
      if (self.frames_from_click == 0) self.frames_from_click = 1
      self.opacity -= 0.5
    end

    if self.frames_from_click > 0 then
      self.frames_from_click += 1

      if self.opacity > 1 then
         self.opacity += self.frames_from_click / 10000
      else
        -- win!
        self.frames_from_click = 1 -- stop timeout

        if self.angle == nil then
          -- start auto scroll
          self.angle = atan2(
            sqrt(self.radius ^ 2 - (self.radius + self.y) ^ 2),
            self.radius + self.y
          )
        end
      end
    end

    if self.angle != nil then
      -- auto scroll
      self.y = sin(self.angle) * self.radius - self.radius
      if self.y < -0.5 then
        self.angle = (self.angle + 0.0018) % 1
      else
        -- finish auto scroll
        self.frames_from_click = nil
        state = 'minigame_win'
        return
      end
    elseif self.frames_from_click > 30 then
      self.y = min(0, (16.5 - self.opacity) / 16 * (self.min_y / 2))
    end

    -- game over
    if (
      (not nsfw_mode() and self.frames_from_click > 0) or -- skip minigame
      self.frames_from_click > 12 * 60 or -- timeout
      self.opacity > 16.5 or -- lost
      (self.frames_from_click == 30 and self.opacity >= 16) -- not double clicked
    ) then
      self.frames_from_click = nil
      stage_id += 1
      if (stage_id > #stages) stage_id = 1
      state = 'init'
    end
  end,
  draw = function (self)
    render_complete_background()
    if self.frames_from_click != nil and self.frames_from_click > 0 then
      Pen.draw(stage.img.base, 0, self.y)
      if (stage.img.cloth != nil) Pen.draw(stage.img.cloth, 0, self.y, nil, self.opacity)
    else
      Pen.draw(panel_img)
    end
    if (self.opacity > 1) print('❎', 118, 119 + (time() * (2 + dget(0) * 6) % 2), 0)
  end,
}

states.minigame_win = {
  update = function (self)
    if (self.frames == nil) self.frames = 0

    self.frames += 1
    if self.frames > 5 * 60 then
      self.frames = nil
      stage_id += 1
      if (stage_id <= #stages) state = 'init'
    end
  end,
  draw = function (self)
    render_complete_background()
    Pen.draw(stage.img.base)
    balloon(stage.balloon.text, stage.balloon.t, stage.balloon.x, stage.balloon.y)
  end,
}

function nsfw_mode()
  return dget(0) == 1
end

function menu_nsfw_label()
  if (nsfw_mode()) return 'nsfw: on' else return 'nsfw: off'
end

function menu_nsfw(b)
  if b & 32 > 0 then
    dset(0, 1 - dget(0))
    menuitem(1, menu_nsfw_label())
  end
  return true
end

function _init()
  cartdata('afunai_pandg_1')
  menuitem(1, menu_nsfw_label(), menu_nsfw)

  state = 'title'
end

function _update60()
  states[state]:update()
end

function _draw()
  states[state]:draw()
end
