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
      _draw_plane_rotate(matrix, plane_index, x, y, dx1, dy1, dx2, dy2, cos(deg), sin(deg))
    end)
--]]

function prepare_img()
  poke(0x5f55, 0x00) -- draw to sprite region
  local x, y = 0, 0
  rectfill(x, y, x + 31, y + 31, 12)
  draw_img('test', x, y, 0, 0, 31, 31)
  poke(0x5f55, 0x60) -- restore
end

function rotate_spr(x, y, size, deg)
  local c = cos(deg)
  local s = sin(deg)
  local b = c ^ 2 + s ^ 2
  local w = sqrt(size ^ 2 * 2)
  for oy = -w, w do
    for ox = -w, w do
      local sx = (c * ox + s * oy) / b + size
      local sy = (c * oy - s * ox) / b + size
      local col = sget(sx, sy)
      if (col > 0) pset(x + ox, y + oy, col)
    end
  end
end

function _init()
  prepare_img()
  deg = 0
end

function _update60()
  deg = (deg + 0.025) % 1
end

function _draw()
  cls()
  rotate_spr(64, 64, 16, deg)
end
