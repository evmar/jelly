
global = exports ? this

left=-1
right=1

tests = [
  name: "move left single jelly to empty block"
  action:
    move: left
    row: 1
    col: 2
  input: [
    "xxxx",
    "x rx",
    "xxxx", ]
  result: [
    "xxxx",
    "xr x",
    "xxxx", ]
 ,
  name: "move left with adjacent jelly"
  action:
    move: left
    row: 1
    col: 3
  input: [ "xxxxx",
    "x rgx",
    "xxxxx", ]
  result: [ "xxxxx",
    "xrg x",
    "xxxxx", ]
 ,
  name: "move left pushing several jellies"
  action:
    move: left
    row: 1
    col: 4
  input: [ "xxxxxx",
    "x rgbx",
    "xxxxxx", ]
  result: [ "xxxxxx",
    "xrgb x",
    "xxxxxx", ]
 ,
  name: "move left a tower pushing tower of several jellies"
  action:
    move: left
    row: 2
    col: 3
  input: [ "xxxxx",
    "x bgx",
    "x rgx",
    "xxxxx", ]
  result: [ "xxxxx",
    "xbg x",
    "xrg x",
    "xxxxx", ]
 ,
]

runTest = (test) ->
  testsDiv = document.getElementById('tests')
  testDiv = document.createElement('div')
  testsDiv.appendChild(testDiv)
  stage = createStage(testDiv, test.input)
  stage.trySlide(stage.cells[test.action.row][test.action.col], test.action.move)

  actual = []
  for y in [0...stage.cells.length]
    row = ""
    for x in [0...stage.cells[0].length]
      cell = stage.cells[y][x]
      if cell
        if cell instanceof global.Jelly
          r = cell.color[0]
        else
          r = "x"
      else
        r = " "
      row += r
    actual.push row
  return actual

addStageToResult = (resultDiv, className, stage) ->
  div = document.createElement('div')
  div.className = 'stage ' + className
  resultDiv.appendChild(div)
  new createStage(div, stage)

addName = (resultDiv, name) ->
  div = document.createElement('div')
  resultDiv.appendChild(div)
  div.innerHTML = name

createStage = (dom, stage) ->
  stage = new global.Stage(dom, stage)
  stage.showCongrats = ->
  return stage

addResult = (test, actual) ->
  resultsDiv = document.getElementById('results')
  resultDiv = document.createElement('div')
  resultDiv.className = if ("#{actual}" is "#{test.result}") then 'success' else 'failure'
  resultsDiv.appendChild(resultDiv)
  addName(resultDiv, test.name)
  addStageToResult(resultDiv, 'initial', test.input)
  addStageToResult(resultDiv, 'actual', actual)
  addStageToResult(resultDiv, 'expected', test.result)

for test in tests
  addResult(test, runTest(test))
