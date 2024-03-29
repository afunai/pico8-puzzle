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

function balloon(text, t, x, y)
  local corner_radius = 3

  local oy = cos(time() / 0.7 % 1) * 2

  rectfill(x, y - corner_radius + oy, x + t.w - 1, y + t.h + corner_radius + oy, 7)
  rectfill(x - corner_radius - 1, y + oy, x + t.w + corner_radius - 1, y + t.h + oy, 7)
  circfill(x - 1, y + oy, corner_radius, 7)
  circfill(x + t.w - 1, y + oy, corner_radius, 7)
  circfill(x - 1, y + t.h + oy, corner_radius, 7)
  circfill(x + t.w - 1, y + t.h + oy, corner_radius, 7)
  ovalfill(x + t.w / 2 - 2, y + t.h - 2 + oy, x + t.w / 2 + 2, y + t.h + 6 + oy, 7)

  print(text, x, y + oy + 1, 0)
end
