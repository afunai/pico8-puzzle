pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
#include pen_decoder.lua
#include pen_data.lua

function _draw_plane_rotate(matrix, plane_index, x, y, dx1, dy1, dx2, dy2, cs, sn)
  local cx = x + (dx2 - dx1) / 2
  local cy = y + (dy2 - dy1) / 2

  for y1 = dy1, dy2 do
    local row_data = matrix[flr(y1) + 1]
    for token in all(row_data[plane_index]) do
      line(
        cs * (x + token.x1 - cx) + sn * (y + y1 - cy) + cx,
        cs * (y + y1 - cy) - sn * (x + token.x1 - cx) + cy,
        cs * (x + token.x2 - cx) + sn * (y + y1 - cy) + cx,
        cs * (y + y1 - cy) - sn * (x + token.x2 - cx) + cy,
        token.p)
    end
  end
end
--[[
  draw_img(img, 47, 47, nil, nil, nil, nil,
    function (matrix, plane_index, x, y, dx1, dy1, dx2, dy2)
      clip(0)
      _draw_plane_rotate(matrix, plane_index, x, y, dx1, dy1, dx2, dy2, cos(angle), sin(angle))
    end)
--]]

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

function rotate_spr(x, y, c, angle)
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

local last_cell = {
  x = 3 * 32 + 1,
  y = 3 * 32 + 1,
  width = 32 - 2,
  height = 32 - 2,
}

cx = 127 - last_cell.width / 2
cy = 63 - last_cell.height / 2
radius = 64

function _init()
  c = prepare_cell('test', 12, last_cell, 64, 48)
  angle1 = 0.25
  angle2 = 0
end

function _update60()
  angle1 += 0.0125
  if (angle1 > 0.75) then
    angle1 = 0.75
  else
    angle2 = (angle2 + 0.1) % 1
  end
end

function _draw()
  cls(1)
  rotate_spr(cos(angle1) * radius * 1.8 + cx, sin(angle1) * radius + cy, c, angle2)
end
