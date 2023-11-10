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

function prepare_img(cell)
  poke(0x5f55, 0x00) -- draw to sprite region
  local sx, sy = 0, 0
  rectfill(sx, sy, sx + cell.width - 1, sy + cell.height - 1, 12)
  draw_img('test', sx, sy, cell.x, cell.y,
    cell.x + cell.width - 1, cell.y + cell.height - 1)
  poke(0x5f55, 0x60) -- restore
end

function rotate_spr(x, y, width, height, angle)
  local cs = cos(angle)
  local sn = sin(angle)
  local s = max(sqrt(width ^ 2 / 2), sqrt(height ^ 2 / 2))
  for oy = -s, s do
    for ox = -s, s do
      local sx = (cs * ox - sn * oy) + width / 2
      local sy = (cs * oy + sn * ox) + height / 2
      local col = sget(sx, sy)
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
  prepare_img(last_cell)
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
  rotate_spr(cos(angle1) * radius * 1.8 + cx, sin(angle1) * radius + cy,
    last_cell.width, last_cell.height, angle2)
end
