pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
function prepare_text(text, x, y)
  poke(0x5f55, 0x00) -- draw to sprite region
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
  local angle = args[1] or 0
  local scale_x = args[2] or 1
  local scale_y = args[3] or scale_x
  local cs, sn = cos(angle), sin(angle)
  local cx = x + t.w / 2 - 1
  local cy = y + t.h / 2 - 1

  local offset = 0.3
  
  for sy = 0, (t.h - 1) do
    for sx = 0, (t.w - 1) do
      local col = sget(sx + t.x, sy + t.y)
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
  t = prepare_text('\f8p\f9i\fac\fbo\fc8\n\fdr\feo\ffc\f6k\f7s', 64, 32)
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
  symbol(64 - t.w / 2, 64 - t.h / 2, t, angle, scale)
  symbol(105 - t.w / 2, 20 - t.h / 2, t, 0, scale2, 2)
end
