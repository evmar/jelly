(function() {
  var CELL_SIZE, Jelly, JellyCell, Stage, i, level, levelPicker, levels, moveToCell, option, stage, _i, _ref;

  levels = [["xxxxxxxxxxxxxx", "x            x", "x            x", "x      r     x", "x      xx    x", "x  g     r b x", "xxbxxxg xxxxxx", "xxxxxxxxxxxxxx"], ["xxxxxxxxxxxxxx", "x            x", "x            x", "x            x", "x     g   g  x", "x   r r   r  x", "xxxxx x x xxxx", "xxxxxxxxxxxxxx"], ["xxxxxxxxxxxxxx", "x            x", "x            x", "x   bg  x g  x", "xxx xxxrxxx  x", "x      b     x", "xxx xxxrxxxxxx", "xxxxxxxxxxxxxx"], ["xxxxxxxxxxxxxx", "x            x", "x       r    x", "x       b    x", "x       x    x", "x b r        x", "x b r      b x", "xxx x      xxx", "xxxxx xxxxxxxx", "xxxxxxxxxxxxxx"], ["xxxxxxxxxxxxxx", "x            x", "x            x", "xrg  gg      x", "xxx xxxx xx  x", "xrg          x", "xxxxx  xx   xx", "xxxxxx xx  xxx", "xxxxxxxxxxxxxx"], ["xxxxxxxxxxxxxx", "xxxxxxx      x", "xxxxxxx g    x", "x       xx   x", "x r   b      x", "x x xxx x g  x", "x         x bx", "x       r xxxx", "x   xxxxxxxxxx", "xxxxxxxxxxxxxx"]];

  CELL_SIZE = 48;

  moveToCell = function(dom, x, y) {
    dom.style.left = x * CELL_SIZE + 'px';
    return dom.style.top = y * CELL_SIZE + 'px';
  };

  Stage = (function() {

    function Stage(dom, map) {
      var event, maybeSwallowEvent, _i, _len, _ref,
        _this = this;
      this.dom = dom;
      this.jellies = [];
      this.loadMap(map);
      this.busy = false;
      maybeSwallowEvent = function(e) {
        e.preventDefault();
        if (_this.busy) {
          return e.stopPropagation();
        }
      };
      _ref = ['contextmenu', 'click', 'touchstart', 'touchmove'];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        event = _ref[_i];
        this.dom.addEventListener(event, maybeSwallowEvent, true);
      }
      this.checkForMerges();
    }

    Stage.prototype.loadMap = function(map) {
      var cell, color, jelly, nextId, row, table, td, tr, x, y;
      nextId = 0;
      table = document.createElement('table');
      this.dom.appendChild(table);
      this.cells = (function() {
        var _i, _ref, _results;
        _results = [];
        for (y = _i = 0, _ref = map.length; 0 <= _ref ? _i < _ref : _i > _ref; y = 0 <= _ref ? ++_i : --_i) {
          row = map[y].split(/(?:)/);
          tr = document.createElement('tr');
          table.appendChild(tr);
          _results.push((function() {
            var _j, _ref1, _results1;
            _results1 = [];
            for (x = _j = 0, _ref1 = row.length; 0 <= _ref1 ? _j < _ref1 : _j > _ref1; x = 0 <= _ref1 ? ++_j : --_j) {
              color = null;
              cell = null;
              switch (row[x]) {
                case 'x':
                  cell = document.createElement('td');
                  cell.className = 'cell wall';
                  tr.appendChild(cell);
                  break;
                case 'r':
                  color = 'red';
                  break;
                case 'g':
                  color = 'green';
                  break;
                case 'b':
                  color = 'blue';
              }
              if (!cell) {
                td = document.createElement('td');
                td.className = 'transparent';
                tr.appendChild(td);
              }
              if (color) {
                jelly = new Jelly(this, nextId, x, y, color);
                nextId += 1;
                this.dom.appendChild(jelly.dom);
                this.jellies.push(jelly);
                cell = jelly;
              }
              _results1.push(cell);
            }
            return _results1;
          }).call(this));
        }
        return _results;
      }).call(this);
      this.addBorders();
    };

    Stage.prototype.addBorders = function() {
      var attr, border, cell, dx, dy, edges, other, x, y, _i, _j, _k, _len, _ref, _ref1, _ref2, _ref3, _ref4;
      for (y = _i = 0, _ref = this.cells.length; 0 <= _ref ? _i < _ref : _i > _ref; y = 0 <= _ref ? ++_i : --_i) {
        for (x = _j = 0, _ref1 = this.cells[0].length; 0 <= _ref1 ? _j < _ref1 : _j > _ref1; x = 0 <= _ref1 ? ++_j : --_j) {
          cell = this.cells[y][x];
          if (!(cell && cell.tagName === 'TD')) {
            continue;
          }
          border = 'solid 1px #777';
          edges = [['borderBottom', 0, 1], ['borderTop', 0, -1], ['borderLeft', -1, 0], ['borderRight', 1, 0]];
          for (_k = 0, _len = edges.length; _k < _len; _k++) {
            _ref2 = edges[_k], attr = _ref2[0], dx = _ref2[1], dy = _ref2[2];
            if (!((0 <= (_ref3 = y + dy) && _ref3 < this.cells.length))) {
              continue;
            }
            if (!((0 <= (_ref4 = x + dx) && _ref4 < this.cells[0].length))) {
              continue;
            }
            other = this.cells[y + dy][x + dx];
            if (!(other && other.tagName === 'TD')) {
              cell.style[attr] = border;
            }
          }
        }
      }
    };

    Stage.prototype.waitForAnimation = function(cb) {
      var end, name, names, _i, _len,
        _this = this;
      names = ['transitionend', 'webkitTransitionEnd'];
      end = function() {
        var name, _i, _len;
        for (_i = 0, _len = names.length; _i < _len; _i++) {
          name = names[_i];
          _this.dom.removeEventListener(name, end);
        }
        return setTimeout(cb, 0);
      };
      for (_i = 0, _len = names.length; _i < _len; _i++) {
        name = names[_i];
        this.dom.addEventListener(name, end);
      }
    };

    Stage.prototype.gatherSliders = function(jelly, dir, jellies) {
      var adj, adjacent, _i, _len;
      if (jelly.id in jellies) {
        return jellies;
      }
      adjacent = this.getAdjacent(jelly, dir, 0);
      if (!adjacent) {
        return null;
      }
      jellies[jelly.id] = jelly;
      for (_i = 0, _len = adjacent.length; _i < _len; _i++) {
        adj = adjacent[_i];
        if (!this.gatherSliders(adj, dir, jellies)) {
          return null;
        }
      }
      return jellies;
    };

    Stage.prototype.trySlide = function(jelly, dir) {
      var group, id,
        _this = this;
      group = this.gatherSliders(jelly, dir, {});
      if (!group) {
        return;
      }
      this.busy = true;
      this.move((function() {
        var _results;
        _results = [];
        for (id in group) {
          _results.push(group[id]);
        }
        return _results;
      })(), dir, 0);
      this.waitForAnimation(function() {
        return _this.checkFall(function() {
          _this.checkForMerges();
          return _this.busy = false;
        });
      });
    };

    Stage.prototype.move = function(jellies, dx, dy) {
      var jelly, x, y, _i, _j, _k, _l, _len, _len1, _len2, _len3, _len4, _m, _ref, _ref1, _ref2, _ref3;
      for (_i = 0, _len = jellies.length; _i < _len; _i++) {
        jelly = jellies[_i];
        _ref = jelly.cellCoords();
        for (_j = 0, _len1 = _ref.length; _j < _len1; _j++) {
          _ref1 = _ref[_j], x = _ref1[0], y = _ref1[1];
          this.cells[y][x] = null;
        }
      }
      for (_k = 0, _len2 = jellies.length; _k < _len2; _k++) {
        jelly = jellies[_k];
        jelly.updatePosition(jelly.x + dx, jelly.y + dy);
      }
      for (_l = 0, _len3 = jellies.length; _l < _len3; _l++) {
        jelly = jellies[_l];
        _ref2 = jelly.cellCoords();
        for (_m = 0, _len4 = _ref2.length; _m < _len4; _m++) {
          _ref3 = _ref2[_m], x = _ref3[0], y = _ref3[1];
          this.cells[y][x] = jelly;
        }
      }
    };

    Stage.prototype.getAdjacent = function(jelly, dx, dy) {
      var id, ids, jellies, next, x, y, _i, _len, _ref, _ref1;
      jellies = {};
      _ref = jelly.cellCoords();
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        _ref1 = _ref[_i], x = _ref1[0], y = _ref1[1];
        next = this.cells[y + dy][x + dx];
        if (next && next !== jelly) {
          if (!(next instanceof Jelly)) {
            return null;
          }
          jellies[next.id] = next;
        }
      }
      ids = Object.keys(jellies);
      return (function() {
        var _j, _len1, _results;
        _results = [];
        for (_j = 0, _len1 = ids.length; _j < _len1; _j++) {
          id = ids[_j];
          _results.push(jellies[id]);
        }
        return _results;
      })();
    };

    Stage.prototype.checkFall = function(cb) {
      var adjacent, didOneMove, jelly, moved, _i, _len, _ref;
      moved = false;
      didOneMove = true;
      while (didOneMove) {
        didOneMove = false;
        _ref = this.jellies;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          jelly = _ref[_i];
          adjacent = this.getAdjacent(jelly, 0, 1);
          if ((adjacent != null) && adjacent.length === 0) {
            this.move([jelly], 0, 1);
            didOneMove = true;
            moved = true;
          }
        }
      }
      if (moved) {
        this.waitForAnimation(cb);
      } else {
        cb();
      }
    };

    Stage.prototype.checkForMerges = function() {
      var jelly, merged, x, y, _i, _len, _ref, _ref1;
      merged = false;
      while (jelly = this.doOneMerge()) {
        merged = true;
        _ref = jelly.cellCoords();
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          _ref1 = _ref[_i], x = _ref1[0], y = _ref1[1];
          this.cells[y][x] = jelly;
        }
      }
      if (merged) {
        this.checkForCompletion();
      }
    };

    Stage.prototype.checkForCompletion = function() {
      var colors, j, _i, _len, _ref;
      colors = {};
      _ref = this.jellies;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        j = _ref[_i];
        colors[j.color] = 1;
      }
      if (Object.keys(colors).length === this.jellies.length) {
        alert("Congratulations! Level completed.");
      }
    };

    Stage.prototype.doOneMerge = function() {
      var dx, dy, jelly, other, x, y, _i, _j, _k, _len, _len1, _len2, _ref, _ref1, _ref2, _ref3, _ref4;
      _ref = this.jellies;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        jelly = _ref[_i];
        _ref1 = jelly.cellCoords();
        for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
          _ref2 = _ref1[_j], x = _ref2[0], y = _ref2[1];
          _ref3 = [[1, 0], [0, 1]];
          for (_k = 0, _len2 = _ref3.length; _k < _len2; _k++) {
            _ref4 = _ref3[_k], dx = _ref4[0], dy = _ref4[1];
            other = this.cells[y + dy][x + dx];
            if (!(other && other instanceof Jelly)) {
              continue;
            }
            if (other === jelly) {
              continue;
            }
            if (jelly.color !== other.color) {
              continue;
            }
            jelly.merge(other);
            this.jellies = this.jellies.filter(function(j) {
              return j.id !== other.id;
            });
            return jelly;
          }
        }
      }
      return null;
    };

    return Stage;

  })();

  JellyCell = (function() {

    function JellyCell(jelly, x, y, color) {
      this.jelly = jelly;
      this.x = x;
      this.y = y;
      this.dom = document.createElement('div');
      this.dom.className = 'cell jelly ' + color;
    }

    return JellyCell;

  })();

  Jelly = (function() {

    function Jelly(stage, id, x, y, color) {
      var cell,
        _this = this;
      this.id = id;
      this.x = x;
      this.y = y;
      this.color = color;
      this.dom = document.createElement('div');
      this.updatePosition(this.x, this.y);
      this.dom.className = 'cell jellybox';
      cell = new JellyCell(this, 0, 0, this.color);
      this.dom.appendChild(cell.dom);
      this.cells = [cell];
      this.dom.addEventListener('contextmenu', function(e) {
        return stage.trySlide(_this, 1);
      });
      this.dom.addEventListener('click', function(e) {
        return stage.trySlide(_this, -1);
      });
      this.dom.addEventListener('touchstart', function(e) {
        return _this.start = e.touches[0].pageX;
      });
      this.dom.addEventListener('touchmove', function(e) {
        var dx;
        dx = e.touches[0].pageX - _this.start;
        if (Math.abs(dx) > 10) {
          dx = Math.max(Math.min(dx, 1), -1);
          return stage.trySlide(_this, dx);
        }
      });
    }

    Jelly.prototype.cellCoords = function() {
      var cell, _i, _len, _ref, _results;
      _ref = this.cells;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        cell = _ref[_i];
        _results.push([this.x + cell.x, this.y + cell.y]);
      }
      return _results;
    };

    Jelly.prototype.updatePosition = function(x, y) {
      this.x = x;
      this.y = y;
      return moveToCell(this.dom, this.x, this.y);
    };

    Jelly.prototype.merge = function(other) {
      var cell, dx, dy, othercell, _i, _j, _k, _len, _len1, _len2, _ref, _ref1, _ref2;
      dx = other.x - this.x;
      dy = other.y - this.y;
      _ref = other.cells;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        cell = _ref[_i];
        this.cells.push(cell);
        cell.x += dx;
        cell.y += dy;
        moveToCell(cell.dom, cell.x, cell.y);
        this.dom.appendChild(cell.dom);
      }
      other.cells = null;
      other.dom.parentNode.removeChild(other.dom);
      _ref1 = this.cells;
      for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
        cell = _ref1[_j];
        _ref2 = this.cells;
        for (_k = 0, _len2 = _ref2.length; _k < _len2; _k++) {
          othercell = _ref2[_k];
          if (othercell === cell) {
            continue;
          }
          if (othercell.x === cell.x + 1 && othercell.y === cell.y) {
            cell.dom.style.borderRight = 'none';
          } else if (othercell.x === cell.x - 1 && othercell.y === cell.y) {
            cell.dom.style.borderLeft = 'none';
          } else if (othercell.x === cell.x && othercell.y === cell.y + 1) {
            cell.dom.style.borderBottom = 'none';
          } else if (othercell.x === cell.x && othercell.y === cell.y - 1) {
            cell.dom.style.borderTop = 'none';
          }
        }
      }
    };

    return Jelly;

  })();

  level = parseInt(location.search.substr(1), 10) || 1;

  stage = new Stage(document.getElementById('map'), levels[level - 1]);

  window.stage = stage;

  levelPicker = document.getElementById('level');

  for (i = _i = 1, _ref = levels.length; 1 <= _ref ? _i <= _ref : _i >= _ref; i = 1 <= _ref ? ++_i : --_i) {
    option = document.createElement('option');
    option.value = i;
    option.innerText = "Level " + i;
    levelPicker.appendChild(option);
  }

  levelPicker.value = level;

  levelPicker.addEventListener('change', function() {
    return location.search = '?' + levelPicker.value;
  });

  document.getElementById('reset').addEventListener('click', function() {
    stage.dom.innerHTML = '';
    return stage = new Stage(stage.dom, levels[level - 1]);
  });

}).call(this);

// Generated by CoffeeScript 1.5.0-pre
