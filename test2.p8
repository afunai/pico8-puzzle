pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
function prepare_text(text, x, y)
  poke(0x5f55, 0x00) -- draw to sprite region
  local width = print(text, x, y)
  poke(0x5f55, 0x60) -- restore hardware state
  return width
end

function symbol(x, y, width, height, ...)
  local args = {...}
  local angle = args[1] or 0
  local scale_x = args[2] or 1
  local scale_y = args[3] or scale_x
  local cs, sn = cos(angle), sin(angle)
  local cx = x + width / 2 - 1
  local cy = y + height / 2 - 1

  local offset = 0.3
  
  for sy = 0, (height - 1) do
    for sx = 0, (width - 1) do
      local col = sget(sx, sy)
      if col > 0 then
        line(
          cs * (x + sx - cx - offset) * scale_x + sn * (y + sy - cy - offset) * scale_y + cx,
          cs * (y + sy - cy - offset) * scale_y - sn * (x + sx - cx - offset) * scale_x + cy,
          cs * (x + sx - cx + offset) * scale_x + sn * (y + sy - cy - offset) * scale_y + cx,
          cs * (y + sy - cy - offset) * scale_y - sn * (x + sx - cx + offset) * scale_x + cy,
          col)
        line(
          cs * (x + sx - cx + offset) * scale_x + sn * (y + sy - cy + offset) * scale_y + cx,
          cs * (y + sy - cy + offset) * scale_y - sn * (x + sx - cx + offset) * scale_x + cy,
          col)
        line(
          cs * (x + sx - cx - offset) * scale_x + sn * (y + sy - cy + offset) * scale_y + cx,
          cs * (y + sy - cy + offset) * scale_y - sn * (x + sx - cx - offset) * scale_x + cy,
          col)
        line(
          cs * (x + sx - cx - offset) * scale_x + sn * (y + sy - cy - offset) * scale_y + cx,
          cs * (y + sy - cy - offset) * scale_y - sn * (x + sx - cx - offset) * scale_x + cy,
          col)
      end
    end
  end
end

function _init()
  width = prepare_text('\f8p\f9i\fac\fbo\fc8\n\fdr\feo\ffc\f6k\f7s', 0, 0)
  height = 12
  angle = 0
  scale = 1
  scale2 = 2
end

function _update60()
  if (time() % 2 > 1) angle = (angle + 0.025) % 1
  scale = cos(time() / 6) * 7
  scale2 = cos(time() / 2 % 1) * 2
end

function _draw()
  cls()
  symbol(64 - width / 2, 64 - height / 2, width, height, angle, scale)
  symbol(105 - width / 2, 20 - height / 2, width, height, 0, scale2, 2)
end
