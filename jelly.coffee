levels = [
  [ "xxxxxxxxxxxxxx",
    "x            x",
    "x            x",
    "x      r     x",
    "x      xx    x",
    "x  g     r b x",
    "xxbxxxg xxxxxx",
    "xxxxxxxxxxxxxx", ],

  [ "xxxxxxxxxxxxxx",
    "x            x",
    "x            x",
    "x            x",
    "x     g   g  x",
    "x   r r   r  x",
    "xxxxx x x xxxx",
    "xxxxxxxxxxxxxx", ],

  [ "xxxxxxxxxxxxxx",
    "x            x",
    "x            x",
    "x   bg  x g  x",
    "xxx xxxrxxx  x",
    "x      b     x",
    "xxx xxxrxxxxxx",
    "xxxxxxxxxxxxxx", ],

  [ "xxxxxxxxxxxxxx",
    "x            x",
    "x       r    x",
    "x       b    x",
    "x       x    x",
    "x b r        x",
    "x b r      b x",
    "xxx x      xxx",
    "xxxxx xxxxxxxx",
    "xxxxxxxxxxxxxx", ],

  [ "xxxxxxxxxxxxxx",
    "x            x",
    "x            x",
    "xrg  gg      x",
    "xxx xxxx xx  x",
    "xrg          x",
    "xxxxx  xx   xx",
    "xxxxxx xx  xxx",
    "xxxxxxxxxxxxxx", ],

  [ "xxxxxxxxxxxxxx",
    "xxxxxxx      x",
    "xxxxxxx g    x",
    "x       xx   x",
    "x r   b      x",
    "x x xxx x g  x",
    "x         x bx",
    "x       r xxxx",
    "x   xxxxxxxxxx",
    "xxxxxxxxxxxxxx", ],
  ]

CELL_SIZE = 48

Array::unique = ->
  output = {}
  output[@[key]] = @[key] for key in [0...@length]
  value for key, value of output

moveToCell = (dom, x, y) ->
  dom.style.left = x * CELL_SIZE + 'px'
  dom.style.top = y * CELL_SIZE + 'px'

class Stage
  constructor: (@dom, map) ->
    @jellies = []
    @loadMap(map)

    # Capture and swallow all click events during animations.
    @busy = false
    maybeSwallowEvent = (e) =>
      e.preventDefault()
      e.stopPropagation() if @busy
    for event in ['contextmenu', 'click', 'touchstart', 'touchmove']
      @dom.addEventListener(event, maybeSwallowEvent, true)

    @checkForMerges()

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
          td = document.createElement('td')
          td.className = 'transparent'
          tr.appendChild(td)
        if color
          jelly = new Jelly(this, x, y, color)
          @dom.appendChild(jelly.dom)
          @jellies.push jelly
          cell = jelly
        cell
    @addBorders()
    return

  addBorders: ->
    for y in [0...@cells.length]
      for x in [0...@cells[0].length]
        cell = @cells[y][x]
        continue unless cell and cell.tagName == 'TD'
        border = 'solid 1px #777'
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
    return

  canSlide: (jelly, dir) ->
    obstacles = @checkFilled(jelly, dir, 0)
    for obstacle in obstacles
      return false unless @canSlide(obstacle, dir)
    return true

  slide: (jelly, dir) ->
    obstacles = @checkFilled(jelly, dir, 0)
    @slide(obstacle, dir) for obstacle in obstacles
    @busy = true
    @move(jelly, jelly.x + dir, jelly.y)
    @waitForAnimation () =>
      @checkFall =>
        @checkForMerges()
        @busy = false

  waitForAnimation: (cb) ->
    names = ['transitionend', 'webkitTransitionEnd']
    end = () =>
      @dom.removeEventListener(name, end) for name in names
      cb()
    @dom.addEventListener(name, end) for name in names
    return

  trySlide: (jelly, dir) ->
    return unless @canSlide(jelly, dir)
    @slide(jelly, dir)

  trySlide: (jelly, dir) ->
    return unless @canSlide(jelly, dir)
    @slide(jelly, dir)

  move: (jelly, targetX, targetY) ->
    @cells[y][x] = null for [x, y] in jelly.cellCoords()
    jelly.updatePosition(targetX, targetY)
    @cells[y][x] = jelly for [x, y] in jelly.cellCoords()
    return

  checkFilled: (jelly, dx, dy) ->
    obstacles = []
    for [x, y] in jelly.cellCoords()
      next = @cells[y + dy][x + dx]
      if next and next != jelly
        obstacles.push next
    return obstacles.unique()

  checkFall: (cb) ->
    moved = false
    didOneMove = true
    while didOneMove
      didOneMove = false
      for jelly in @jellies
        if @checkFilled(jelly, 0, 1).length == 0
          @move(jelly, jelly.x, jelly.y + 1)
          didOneMove = true
          moved = true
    if moved
      @waitForAnimation cb
    else
      cb()
    return

  checkForMerges: ->
    merged = false
    while jelly = @doOneMerge()
      merged = true
      for [x, y] in jelly.cellCoords()
        @cells[y][x] = jelly
    @checkForCompletion() if merged
    return

  checkForCompletion: ->
    colors = {}
    colors[j.color] = 1 for j in @jellies
    if Object.keys(colors).length == @jellies.length
      @showCongrats()
    return

  showCongrats: ->
      alert("Congratulations! Level completed.")

  doOneMerge: ->
    for jelly in @jellies
      for [x, y] in jelly.cellCoords()
        # Only look right and down; left and up are handled by that side
        # itself looking right and down.
        for [dx, dy] in [[1, 0], [0, 1]]
          other = @cells[y + dy][x + dx]
          continue unless other and other instanceof Jelly
          continue unless other != jelly
          continue unless jelly.color == other.color
          jelly.merge other
          @jellies = @jellies.filter (j) -> j != other
          return jelly
    return null

class JellyCell
  constructor: (@jelly, @x, @y, color) ->
    @dom = document.createElement('div')
    @dom.className = 'cell jelly ' + color


class Jelly
  constructor: (stage, @x, @y, @color) ->
    @dom = document.createElement('div')
    @updatePosition(@x, @y)
    @dom.className = 'cell jellybox'

    cell = new JellyCell(this, 0, 0, @color)
    @dom.appendChild(cell.dom)
    @cells = [cell]

    @dom.addEventListener 'contextmenu', (e) =>
      stage.trySlide(this, 1)
    @dom.addEventListener 'click', (e) =>
      stage.trySlide(this, -1)

    @dom.addEventListener 'touchstart', (e) =>
      @start = e.touches[0].pageX
    @dom.addEventListener 'touchmove', (e) =>
      dx = e.touches[0].pageX - @start
      if Math.abs(dx) > 10
        dx = Math.max(Math.min(dx, 1), -1)
        stage.trySlide(this, dx)

  cellCoords: ->
    [@x + cell.x, @y + cell.y] for cell in @cells

  updatePosition: (@x, @y) ->
    moveToCell @dom, @x, @y

  merge: (other) ->
    # Reposition other's cells as children of this jelly.
    dx = other.x - this.x
    dy = other.y - this.y
    for cell in other.cells
      @cells.push cell
      cell.x += dx
      cell.y += dy
      moveToCell cell.dom, cell.x, cell.y
      @dom.appendChild(cell.dom)

    # Delete references from/to other.
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
    return

run = ->
  level = parseInt(location.search.substr(1), 10) or 0
  stage = new Stage(document.getElementById('map'), levels[level])
  window.stage = stage

  levelPicker = document.getElementById('level')
  levelPicker.value = level
  levelPicker.addEventListener 'change', () ->
    location.search = '?' + levelPicker.value

  document.getElementById('reset').addEventListener 'click', ->
    stage.dom.innerHTML = ''
    stage = new Stage(stage.dom, levels[level])

global = exports ? this
global.run = run
global.Stage = Stage
global.Jelly = Jelly

