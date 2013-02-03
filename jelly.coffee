levels = [
  [ "xxxxxxxxxxxxxx",
    "x            x",
    "x      r     x",
    "x      xx    x",
    "x  g     r b x",
    "xxbxxxg xxxxxx",
    "xxxxxxxxxxxxxx", ],

  [ "xxxxxxxxxxxxxx",
    "x            x",
    "x            x",
    "x     g   g  x",
    "x   r r   r  x",
    "xxxxx x x xxxx",
    "xxxxxxxxxxxxxx", ],
  ]

CELL_SIZE = 48

class Stage
  constructor: (@dom, map) ->
    @busy = false
    @jellies = []
    @loadMap(map)

    maybeSwallowEvent = (e) =>
      e.preventDefault()
      e.stopPropagation() if @busy

    for event in ['contextmenu', 'click']
      @dom.addEventListener(event, maybeSwallowEvent, true)

    @checkStuck()

  loadMap: (map) ->
    table = document.createElement('table')
    @dom.appendChild(table)
    @cells = for y in [0...map.length]
      row = map[y].split(//)
      tr = document.createElement('tr')
      table.appendChild(tr)
      for x in [0...row.length]
        color = null
        cell = null
        switch row[x]
          when 'x'
            cell = document.createElement('td')
            cell.className = 'cell wall'
            tr.appendChild(cell)
          when 'r' then color = 'red'
          when 'g' then color = 'green'
          when 'b' then color = 'blue'

        unless cell
          tr.appendChild(document.createElement('td'))
        if color
          jelly = new Jelly(this, x, y, color)
          @dom.appendChild(jelly.dom)
          @jellies.push jelly
          cell = jelly
        cell
    @addBorders()

  addBorders: () ->
    for y in [0...@cells.length]
      for x in [0...@cells[0].length]
        cell = @cells[y][x]
        continue unless cell and cell.tagName == 'TD'
        border = 'solid 1px #aaa'
        edges = [
          ['borderBottom',  0,  1],
          ['borderTop',     0, -1],
          ['borderLeft',   -1,  0],
          ['borderRight',   1,  0],
        ]
        for [attr, dx, dy] in edges
          continue unless 0 <= (y+dy) < @cells.length
          continue unless 0 <= (x+dx) < @cells[0].length
          other = @cells[y+dy][x+dx]
          cell.style[attr] = border unless other and other.tagName == 'TD'

  trySlide: (jelly, dir) ->
    return if @cells[jelly.y][jelly.x + dir]
    return if jelly.stuck
    @busy = true
    @move(jelly, jelly.x + dir, jelly.y)
    jelly.slide dir, () =>
      @checkFall()
      @checkStuck()
      @busy = false

  move: (jelly, x, y) ->
    @cells[jelly.y][jelly.x] = null
    jelly.updatePosition(x, y)
    @cells[y][x] = jelly

  checkFall: () ->
    moved = true
    while moved
      moved = false
      for jelly in @jellies
        continue if @cells[jelly.y + 1][jelly.x]
        @move(jelly, jelly.x, jelly.y + 1)
        moved = true

  checkStuck: () ->
    loop
      console.log('examining ' + @jellies.length + ' jellies', @jellies)
      jelly = @doOneMerge()
      return unless jelly
      for cell in jelly.cells
        @cells[jelly.y + cell.y][jelly.x + cell.x] = jelly

  doOneMerge: () ->
    for jelly in @jellies
      console.log('examining jelly', jelly)
      for cell in jelly.cells
        # Only look right and down; left and up are handled by that side
        # itself looking right and down.
        for [dx, dy] in [[1, 0], [0, 1]]
          # Is there a Jelly nearby?
          other = @cells[jelly.y + cell.y + dy][jelly.x + cell.x + dx]
          continue unless other and other instanceof Jelly
          continue unless other != jelly
          # Is it of the same color?
          continue unless jelly.color == other.color
          jelly.merge other
          @jellies = @jellies.filter (j) -> j != other
          console.log('new jellies ', @jellies.length)
          return jelly
    return null

class JellyCell
  constructor: (@jelly, @x, @y, color) ->
    @dom = document.createElement('div')
    @dom.className = 'cell jelly ' + color


class Jelly
  constructor: (stage, @x, @y, @color) ->
    @dom = document.createElement('div')
    @dom.style.left = x * CELL_SIZE
    @dom.style.top = y * CELL_SIZE
    @dom.className = 'cell jellybox'

    cell = new JellyCell(this, 0, 0, @color)
    @dom.appendChild(cell.dom)
    @cells = [cell]

    @dom.addEventListener 'contextmenu', (e) =>
      stage.trySlide(this, 1)
    @dom.addEventListener 'click', (e) =>
      stage.trySlide(this, -1)

  slide: (dir, cb) ->
    end = () =>
      @dom.style.webkitAnimation = ''
      @dom.removeEventListener 'webkitAnimationEnd', end
      cb()
    @dom.addEventListener 'webkitAnimationEnd', end
    @dom.style.webkitAnimation = '400ms ease-out'
    if dir == 1
      @dom.style.webkitAnimationName = 'slideRight'
    else
      @dom.style.webkitAnimationName = 'slideLeft'

  updatePosition: (@x, @y) ->
    @dom.style.left = @x * CELL_SIZE
    @dom.style.top = @y * CELL_SIZE

  merge: (other) ->
    dx = other.x - this.x
    dy = other.y - this.y

    for cell in other.cells
      @cells.push cell
      cell.x += dx
      cell.y += dy
      cell.dom.style.left = cell.x * CELL_SIZE
      cell.dom.style.top = cell.y * CELL_SIZE
      @dom.appendChild(cell.dom)
    other.cells = null
    other.dom.parentNode.removeChild(other.dom)

    # Remove internal borders.
    for cell in @cells
      for othercell in @cells
        continue if othercell == cell
        if othercell.x == cell.x + 1 and othercell.y == cell.y
          cell.dom.style.borderRight = 'none'
        else if othercell.x == cell.x - 1 and othercell.y == cell.y
          cell.dom.style.borderLeft = 'none'
        else if othercell.x == cell.x and othercell.y == cell.y + 1
          cell.dom.style.borderBottom = 'none'
        else if othercell.x == cell.x and othercell.y == cell.y - 1
          cell.dom.style.borderTop = 'none'

stage = new Stage(document.getElementById('stage'), levels[0])
window.stage = stage
