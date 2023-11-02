pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
#include pen_decoder.lua
#include pen_data.lua

function _draw_plane_rotate(matrix, plane_index, x, y, dx1, dy1, dx2, dy2, cs, sn)
  local cx = x + (dx2 - dx1) / 2
  local cy = y + (dy2 - dy1) / 2

  for y1 = dy1, dy2, 0.3 do

    local row_data = matrix[flr(y1) + 1]
    for token in all(row_data[plane_index]) do
      line(
        cs * (x + token.x1 - cx) + sn * (y + y1 - cy) + cx,
        cs * (y + y1 - cy) - sn * (x + token.x1 - cx) + cy,
        cs * (x + token.x2 - cx) + sn * (y + y1 - cy) + cx,
        cs * (y + y1 - cy) - sn * (x + token.x2 - cx) + cy,
        token.p)
--[[
      line(
        cs * (x + token.x1 - cx + 0.5) + sn * (y + y1 - cy) + cx,
        cs * (y + y1 - cy) - sn * (x + token.x1 - cx + 0.5) + cy,
        cs * (x + token.x2 - cx - 0.5) + sn * (y + y1 - cy) + cx,
        cs * (y + y1 - cy) - sn * (x + token.x2 - cx - 0.5) + cy,
        token.p)
--]]
    end
  end
end

deg = 0.125
x1, y1 = 32, 32
x2, y2 = 95, 95
cx, cy = 64, 64

function _init()
  poke(0x5f55, 0x00)
  local x, y = 0, 0
  rectfill(x, y, x + 31, y + 31, 12)
  draw_img('test', x, y, 0, 0, 31, 31)
  poke(0x5f55, 0x60)
end

function _update60()
  deg = (deg + 0.025) % 1
end

function _draw()
  cls()
  local s = sin(deg)
  local c = cos(deg)
  local b = s * s + c * c
  local size = 16
  local w = sqrt(size ^ 2 * 2)
  for y = -w, w do
    for x = -w, w do
      local ox = (c * x + s * y) / b + size
      local oy = (c * y - s * x) / b + size
      local col = sget(ox, oy)
      if (col > 0) pset(64 + x, 64 + y, col)
    end
  end

  --[[
  draw_img(img, 47, 47, nil, nil, nil, nil,
    function (matrix, plane_index, x, y, dx1, dy1, dx2, dy2)
      clip(0)
      _draw_plane_rotate(matrix, plane_index, x, y, dx1, dy1, dx2, dy2, cos(deg), sin(deg))
    end)
--]]
end
