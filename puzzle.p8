const [dim_x, dim_y] = dimensions.split('x').map(d => parseInt(d));

let board;
let panels;
let order;

const init_matrix = (panel_w, panel_h, border = 0.03) => {
  const panels = [];
  for (let y = 0; y < dim_y; y++) {
    for (let x = 0; x < dim_x; x++) {
      panels.push({
        x: x * panel_w + panel_w * border / 2,
        y: y * panel_h + panel_h * border / 2,
        width: panel_w - panel_w * border,
        height: panel_h- panel_h * border,
        blank: (x == dim_x - 1 && y == dim_y - 1),
      });
    }
  }
  return panels;
}

const shuffle = (arr) => {
  const blank = arr.findIndex(val => val == arr.length - 1);

  let directions = [];
  if (blank % dim_x > 0) directions.push(blank - 1);
  if (blank % dim_x < dim_x - 1) directions.push(blank + 1);
  if (blank - dim_x >= 0) directions.push(blank - dim_x);
  if (blank + dim_x < arr.length) directions.push(blank + dim_x);

  const destination = directions[Math.floor(Math.random() * directions.length)];
  [arr[blank], arr[destination]] = [arr[destination], arr[blank]];
  return arr;
}

const render = () => {
  context.fillRect(0, 0, canvas.width, canvas.height);
  board.forEach((cell, i) => {
    const panel = panels[order[i]];
    if (!panel.blank)
      context.drawImage(
        image,
        panel.x, panel.y, panel.width, panel.height,
        cell.x, cell.y, cell.width, cell.height,
      );
  });
}

const render_complete = () => {
  context.drawImage(
    image,
    0, 0, image.width, image.height,
    0, 0, canvas.width, canvas.height,
  );
  if (image2.width) {
    setTimeout(() => {fadein(100);}, 3000);
  }
}

const fadein = (repeat, current = 0) => {
  context.clearRect(0, 0, canvas.width, canvas.height);
  context.save();
  context.globalAlpha = 1 - (current / repeat);
  context.drawImage(
    image,
    0, 0, image.width, image.height,
    0, 0, canvas.width, canvas.height,
  );
  context.globalAlpha = current / repeat;
  context.drawImage(
    image2,
    0, 0, image.width, image.height,
    0, 0, canvas.width, canvas.height,
  );
  context.restore();
  if (current < repeat) setTimeout(() => {fadein(repeat, current + 1);}, 1000 / 60);
}

const move_panel  = (e) => {
  const rect = e.target.getBoundingClientRect();
  const x = e.clientX - rect.left - (canvas.offsetWidth - canvas.width) / 2;
  const y = e.clientY - rect.top - (canvas.offsetWidth - canvas.width) / 2;
  const cellIndex = board.findIndex(cell => 
    cell.x <= x && cell.x + cell.width > x &&
    cell.y <= y && cell.y + cell.height > y 
  );

  if (cellIndex !== -1) {
    const blankCellIndex = order.findIndex((val, i) => {
      return panels[val].blank &&
      (
        i === cellIndex - 1 ||
        i === cellIndex + 1 ||
        i === cellIndex - dim_x ||
        i === cellIndex + dim_x
      )}
    );
    if (blankCellIndex !== -1) {
      [order[cellIndex], order[blankCellIndex]] = [order[blankCellIndex], order[cellIndex]];
      if (JSON.stringify(order) == JSON.stringify(Array.from(panels.keys()))) {
        panels[panels.length - 1].blank = false; // the last panel
        render_complete();
      }
      else {
        render();
      
    }
  }
}

const show_shuffle = (repeat) => {
  order = shuffle(order);
  render();
  if (repeat > 0) setTimeout(() => {show_shuffle(repeat - 1);}, 0);
  else canvas.onclick = move_panel;
}

image.onload = () => {
  canvas.height = canvas.width * image.height / image.width;
  board = init_matrix(canvas.width / dim_x, canvas.height / dim_y);
  panels = init_matrix(image.width / dim_x, image.height / dim_y);
  order = Array.from(panels.keys());
  requestAnimationFrame(render);
  setTimeout(() => {show_shuffle(dim_x * dim_y * 8);}, 1000);
}
