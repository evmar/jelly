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

CELL_SIZE = 24

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
    jelly.slide dir, () =>
      @move(jelly, jelly.x + dir, jelly.y)
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
    stuck = true
    while stuck
      stuck = false
      for jelly in @jellies
        # Only look left and up; right and down are handled by that side
        # itself looking left and up.
        for [dx, dy] in [[-1, 0], [0, -1]]
          other = @cells[jelly.y + dy][jelly.x + dx]
          # Is there a Jelly nearby?
          continue unless other and other instanceof Jelly
          # Is it of the same color?
          continue unless jelly.color == other.color
          # Is it already stuck to us?
          continue if jelly.stuck and jelly.stuck == other.stuck
          jelly.stickTo other
          stuck = true

class Jelly
  constructor: (stage, @x, @y, @color) ->
    @stuck = null

    @dom = document.createElement('div')
    @dom.style.left = x * CELL_SIZE
    @dom.style.top = y * CELL_SIZE
    @dom.className = 'cell jellybox'

    @displayDom = document.createElement('div')
    @displayDom.className = 'cell jelly ' + @color
    @dom.appendChild(@displayDom)

    @dom.addEventListener 'contextmenu', (e) =>
      stage.trySlide(this, 1)
    @dom.addEventListener 'click', (e) =>
      stage.trySlide(this, -1)

  slide: (dir, cb) ->
    end = () =>
      @displayDom.style.webkitAnimation = ''
      @displayDom.removeEventListener 'webkitAnimationEnd', end
      cb()
    @displayDom.addEventListener 'webkitAnimationEnd', end
    @displayDom.style.webkitAnimation = '400ms ease-out'
    if dir == 1
      @displayDom.style.webkitAnimationName = 'slideRight'
    else
      @displayDom.style.webkitAnimationName = 'slideLeft'

  updatePosition: (@x, @y) ->
    @dom.style.left = @x * CELL_SIZE
    @dom.style.top = @y * CELL_SIZE

  stickTo: (other) ->
    this.stuck = [this] if not this.stuck
    other.stuck = [other] if not other.stuck

    other.stuck = other.stuck.concat @stuck
    for jelly in @stuck
      jelly.stuck = other.stuck

stage = new Stage(document.getElementById('stage'), levels[0])
window.stage = stage
