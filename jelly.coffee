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
    nextId = 0
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
          jelly = new Jelly(this, nextId, x, y, color)
          nextId += 1
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

  waitForAnimation: (cb) ->
    names = ['transitionend', 'webkitTransitionEnd']
    end = () =>
      @dom.removeEventListener(name, end) for name in names
      # Wait one call stack before continuing.  This is necessary if there
      # are multiple pending end transition events (multiple jellies moving);
      # we want to wait for them all here and not accidentally catch them
      # in a subsequent waitForAnimation.
      setTimeout(cb, 0)
    @dom.addEventListener(name, end) for name in names
    return

  # Gather a group of jellies that will slide together.
  # jelly is the jelly to examine for neighbors; dir is the direction
  # to slide.  jellies is an object used in tracking state.
  # Returns a set of jellies keyed by id or null if there's a wall in the way.
  gatherSliders: (jelly, dir, jellies) ->
    return jellies if jelly.id of jellies
    adjacent = @getAdjacent(jelly, dir, 0)
    return null unless adjacent  # wall

    # Add this jelly to the set, examine others.
    jellies[jelly.id] = jelly
    for adj in adjacent
      return null if not @gatherSliders(adj, dir, jellies)
    return jellies

  trySlide: (jelly, dir) ->
    group = @gatherSliders(jelly, dir, {})
    return unless group

    @busy = true
    @move(group[id] for id of group, dir, 0)
    @waitForAnimation () =>
      @checkFall =>
        @checkForMerges()
        @busy = false
    return

  move: (jellies, dx, dy) ->
    @cells[y][x] = null for [x, y] in jelly.cellCoords() for jelly in jellies
    jelly.updatePosition(jelly.x+dx, jelly.y+dy) for jelly in jellies
    @cells[y][x] = jelly for [x, y] in jelly.cellCoords() for jelly in jellies
    return

  # See if there's space for jelly to move by dx/dy.
  # Returns null if there's a wall, an empty array if there's space,
  # and an array of jellies if there's only jellies in the way.
  getAdjacent: (jelly, dx, dy) ->
    jellies = {}
    for [x, y] in jelly.cellCoords()
      next = @cells[y + dy][x + dx]
      if next and next != jelly
        return null unless next instanceof Jelly
        jellies[next.id] = next
    ids = Object.keys(jellies)
    return (jellies[id] for id in ids)

  checkFall: (cb) ->
    moved = false
    didOneMove = true
    while didOneMove
      didOneMove = false
      for jelly in @jellies
        adjacent = @getAdjacent(jelly, 0, 1)
        if adjacent? and adjacent.length == 0
          @move([jelly], 0, 1)
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
      alert("Congratulations! Level completed.")
    return

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
          @jellies = @jellies.filter (j) -> j.id != other.id
          return jelly
    return null

class JellyCell
  constructor: (@jelly, @x, @y, color) ->
    @dom = document.createElement('div')
    @dom.className = 'cell jelly ' + color


class Jelly
  constructor: (stage, @id, @x, @y, @color) ->
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

level = parseInt(location.search.substr(1), 10) or 1
stage = new Stage(document.getElementById('map'), levels[level-1])
window.stage = stage

levelPicker = document.getElementById('level')
for i in [1..levels.length]
  option = document.createElement('option')
  option.value = i
  option.innerText = "Level #{i}"
  levelPicker.appendChild(option)
levelPicker.value = level
levelPicker.addEventListener 'change', () ->
  location.search = '?' + levelPicker.value

document.getElementById('reset').addEventListener 'click', ->
  stage.dom.innerHTML = ''
  stage = new Stage(stage.dom, levels[level-1])
