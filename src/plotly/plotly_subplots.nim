import json, macros, math
import plotly_types, plotly_sugar, api

type
  # subplot specific object, which stores intermediate information about
  # the grid layout to use for multiple plots
  GridLayout = object
    useGrid: bool
    rows: int
    columns: int

  Grid* = object
    # layout of the plot itself
    layout*: Layout
    numPlotsPerRow*: int
    plots: seq[PlotJson]

proc convertDomain*(d: Domain | DomainAlt): Domain =
  ## proc to get a `Domain` from either a `Domain` or `DomainAlt` tuple.
  ## That is a tuple of:
  ## left, bottom, right, top
  ## notation to:
  ## left, bottom, width, height
  when type(d) is Domain:
    result = d
  else:
    result = (left: d.left,
              bottom: d.bottom,
              width: d.right - d.left,
              height: d.top - d.bottom)

proc assignDomain(plt: PlotJson, xaxis, yaxis: string, domain: Domain) =
  ## assigns the `domain` to the plot described by `xaxis`, `yaxis`
  let xdomain = @[domain.left, domain.left + domain.width]
  let ydomain = @[domain.bottom, domain.bottom + domain.height]
  plt.layout[xaxis]["domain"] = % xdomain
  plt.layout[yaxis]["domain"] = % ydomain

proc calcRowsColumns(rows, columns: int, nPlots: int): (int, int) =
  ## Calculates the desired rows and columns for # of `nPlots` given the user's
  ## input for `rows` and `columns`.
  ## - If no input is given, calculate the next possible rectangle of plots
  ##   that favors columns over rows.
  ## - If either row or column is 0, sets this dimension to 1
  ## - If either row or column is -1, calculate square of nPlots for rows / cols
  ## - If both row and column is -1 or either -1 and the other 0, default back
  ##   to the next possible square.
  if rows <= 0 and columns <= 0:
    # calc square of plots
    let sqPlt = sqrt(nPlots.float)
    result[1] = sqPlt.ceil.int
    result[0] = sqPlt.round.int
  elif rows == -1 and columns > 0:
    result[0] = (nPlots.float / columns.float).ceil.int
    result[1] = columns
  elif rows > 0 and columns == -1:
    result[0] = rows
    result[1] = (nPlots.float / rows.float).ceil.int
  elif rows == 0 and columns > 0:
    # 1 row, user desired # cols
    result = (1, columns)
  elif rows > 0 and columns == 0:
    # user desired # row, 1 col
    result = (rows, 1)
  else:
    result = (rows, columns)

proc assignGrid(plt: PlotJson, grid: GridLayout) =
  ## assigns the `grid` to the layout of `plt`
  ## If a grid is desired, but the user does not specify rows and columns,
  ## plots are aranged in a rectangular grid automatically.
  ## If only either rows or columns is specified, the other is set to 1.
  plt.layout["grid"] = newJObject()
  plt.layout["grid"]["pattern"] = % "independent"
  let (rows, columns) = calcRowsColumns(grid.rows, grid.columns, plt.traces.len)
  plt.layout["grid"]["rows"] = % rows
  plt.layout["grid"]["columns"] = % columns

proc combine(baseLayout: Layout,
             plts: openArray[PlotJson],
             domains: openArray[Domain],
             grid: GridLayout): PlotJson =
  # we need to combine the plots on a JsonNode level to avoid problems with
  # different plot types!
  var res = newPlot()
  var useGrid = grid.useGrid
  result = res.toPlotJson
  result.layout = % baseLayout
  if not grid.useGrid and domains.len == 0:
    useGrid = true
  for i, p in plts:
    #doAssert p.traces.len == 1
    # first add traces of `*each Plot*`, only afterwards flatten them!
    if not p.isNil:
      result.traces.add p.traces
      # first plot needs to be treated differently than all others
      let idx = result.traces.len
      var
        xaxisStr = "xaxis"
        yaxisStr = "yaxis"
      if i > 0:
        xaxisStr &= $idx
        yaxisStr &= $idx

      result.layout[xaxisStr] = p.layout["xaxis"]
      result.layout[yaxisStr] = p.layout["yaxis"]

      if not useGrid:
        result.assignDomain(xaxisStr, yaxisStr, domains[i])

      if i > 0:
        # anchor xaxis to y data and vice versa
        result.layout[xaxisStr]["anchor"] = % ("y" & $idx)
        result.layout[yaxisStr]["anchor"] = % ("x" & $idx)

  var i = 0
  # flatten traces and set correct axis for correct original plots
  var traces = newJArray()
  if useGrid:
    result.assignGrid(grid)

  for tr in mitems(result.traces):
    if i > 0:
      for t in tr:
        t["xaxis"] = % ("x" & $(i + 1))
        t["yaxis"] = % ("y" & $(i + 1))
        traces.add t
    else:
      for t in tr:
        traces.add t
    inc i
  result.traces = traces

proc handleDomain(field, value: NimNode): NimNode =
  ## receives a field of the domain description and the corresponding
  ## element and returns an element for a named tuple of the domain for the plot
  case field.strVal
  of "left", "l":
    result = nnkExprColonExpr.newTree(ident"left", value)
  of "right", "r":
    result = nnkExprColonExpr.newTree(ident"right", value)
  of "bottom", "b":
    result = nnkExprColonExpr.newTree(ident"bottom", value)
  of "top", "t":
    result = nnkExprColonExpr.newTree(ident"top", value)
  of "width", "w":
    result = nnkExprColonExpr.newTree(ident"width", value)
  of "height", "h":
    result = nnkExprColonExpr.newTree(ident"height", value)
  else:
    error("Plot domain needs to be described by:\n" &
      "\t{`left`, `right`, `bottom`, `top`, `width`, `height`}\n" &
      "Field: " & field.repr & ", Value: " & value.repr)

proc handlePlotStmt(plt: NimNode): (NimNode, NimNode) =
  ## handle Plot description.
  ## First line needs to be identifier of the `Plot[T]` object
  ## Second line either a (nameless) tuple of
  ## (left: float, bottom: float, width: float, height: float)
  ## or several lines with either of the following keys:
  ## left = left end of this plot
  ## bottom = bottom end of this plot
  ## and:
  ## width = width of this plot
  ## height = width of this plot
  ## ``or``:
  ## right = right end of this plot
  ## top = top end of this plot
  ## These can either be done as an assignment, i.e. via `=` or
  ## as a call, i.e. via `:`
  result[0] = plt[0]
  var domain = newNimNode(kind = nnkPar)
  # flag to differentiate user handing field of object containing
  # `Domain` vs. user leaves out elements of tuple specification
  var isSymbol = false
  for i in 1 ..< plt.len:
    case plt[i].kind
    of nnkPar, nnkTupleConstr:
      # is nameless tuple
      doAssert plt[i].len == 4, "Domain needs to consist of 4 elements!"
      domain.add handleDomain(ident"left", plt[i][0])
      domain.add handleDomain(ident"bottom", plt[i][1])
      domain.add handleDomain(ident"width", plt[i][2])
      domain.add handleDomain(ident"height", plt[i][3])
      # ignore what comes after
      break
    of nnkCall:
      # for call RHS is StmtList
      domain.add handleDomain(plt[i][0], plt[i][1][0])
    of nnkAsgn:
      # for assignment RHS is single expr
      domain.add handleDomain(plt[i][0], plt[i][1])
    of nnkDotExpr, nnkBracketExpr, nnkIdent:
      # assume the user accesses some object, array or identifier
      # storing a domain of either type `Domain` or `DomainAlt`
      domain = plt[i]
      isSymbol = true
    else:
      error("Domain description needs to be of node kind nnkIdent, nnkCall, " &
        "nnkDotExpr, nnkBracketExpr or nnkAsgn. Line is " & plt[i].repr &
        " of kind " & $plt[i].kind)
    if domain.len == 4:
      # have a full domain, stop
      break
  if domain.len != 4 and not isSymbol:
    # replace by empty node, since user didn't specify domain
    domain = newEmptyNode()

  result[1] = domain

proc handleRowsCols(field, value: NimNode): NimNode =
  ## handling of individual assignments for rows / columns for the
  ## grid layout
  case field.strVal
  of "rows", "r":
    result = nnkExprColonExpr.newTree(ident"rows", value)
  of "columns", "cols", "c":
    result = nnkExprColonExpr.newTree(ident"columns", value)
  else:
    error("Invalid field for grid layout description: " & $field &
      "! Use only elements of  {\"rows\", \"r\"} and {\"columns\", \"cols\", \"c\"}.")

proc handleGrid(stmt: NimNode): NimNode =
  ## handles parsing of the grid layout description.
  ## It looks like the following for example:
  ## grid:
  ##   rows: 2
  ##   columns: 3
  ## which is rewritten to an object constructor for a
  ## `GridLayout` object storing the information.
  let gridIdent = ident"gridImpl"
  var gridVar = quote do:
    var `gridIdent` = GridLayout()
  var gridObj = nnkObjConstr.newTree(
    bindSym"GridLayout",
    nnkExprColonExpr.newTree(
      ident"useGrid",
      ident"true")
  )
  for el in stmt[1]:
    case el.kind
    of nnkCall, nnkAsgn:
      gridObj.add handleRowsCols(el[0], el[1])
    else:
      error("Invalid statement in grid layout description: " & el.repr &
        " of kind " & $el.kind)
  # replace object constructor tree in `gridVar`
  gridVar[0][2] = gridObj
  result = gridVar

macro subplots*(stmts: untyped): untyped =
  ## macro to create subplots from several `Plot[T]` objects
  ## the macro needs to contain the blocks `baseLayout`
  ## and one or more `plot` blocks. A plot block has the
  ## `Plot[T]` object in line 1, followed by the domain description
  ## of the subplot, i.e. the location within the whole canvas.
  ##
  ## .. code-block:: nim
  ## let plt1 = scatterPlot(x, y) # x, y some seq[T]
  ## let plt2 = scatterPlot(x2, y2) # x2, y2 some other seq[T]
  ## let layout = Layout(...) # some layout for the whole canvas
  ## let subplt = subplots:
  ##   baseLayout: layout
  ##   plot:
  ##     plt1
  ##     left: 0.0
  ##     bottom: 0.0
  ##     width: 0.45
  ##     height: 1.0
  ##     # alternatively use right, top instead of width, height
  ##     # single letters also supported, e.g. l == left
  ##   plot:
  ##     plt2
  ##     # or just write a concise tuple, here the
  ##     (0.55, 0.0, 0.45, 1.0)
  ##
  ## will create a subplot of `plt1` on the left and `plt2` on the
  ## right.
  ## This simply creates the following call to `combine`.
  ## let subplt = combine(layout,
  ##                      [plt1.toPlotJson, plt2.toPlotJson],
  ##                      [(left: 0.0, bottom: 0.0, width: 0.45, height: 1.0),
  ##                       (left: 0.55, bottom: 0.0, width: 0.45, height: 1.0)])
  var
    layout: NimNode
    # plots contain `Plot[T]` identifier and `domain`
    plots: seq[(NimNode, NimNode)]
    grid: NimNode
  let gridIdent = ident"gridImpl"
  grid = quote do:
    var `gridIdent` = GridLayout(useGrid: false)

  for stmt in stmts:
    case stmt.kind
    of nnkCall:
      case stmt[0].strVal
      of "baseLayout":
        layout = stmt[1][0]
      of "plot":
        # only interested in content of `plot:`, hence [1]
        plots.add handlePlotStmt(stmt[1])
      of "grid":
        grid = handleGrid(stmt)
    of nnkIdent:
      case stmt.strVal
      of "grid":
        grid = quote do:
          var `gridIdent` = GridLayout(useGrid: true)

    else:
      error("Statement needs to be `baseLayout`, `plot`, `grid`! " &
        "Line `" & stmt.repr & "` is " & $stmt.kind)

  var
    pltArray = nnkBracket.newTree()
    domainArray = nnkBracket.newTree()
  # split the plot tuples and apply conversions
  # `Plot` -> `PlotJson`
  # `DomainAlt` | `Domain` -> `Domain`
  for i, plt in plots:
    let pltIdent = plt[0]
    let domainIdent = plt[1]
    pltArray.add quote do:
      `pltIdent`.toPlotJson
    if domainIdent.kind != nnkEmpty:
      domainArray.add quote do:
        `domainIdent`.convertDomain

  # call combine proc
  result = quote do:
    block:
      `grid`
      combine(`layout`, `pltArray`, `domainArray`, `gridIdent`)

proc createGrid*(numPlots: int, numPlotsPerRow = 0, layout = Layout()): Grid =
  ## creates a `Grid` object with `numPlots` to which one can assign plots
  ## at runtime. Optionally the number of desired plots per row of the grid
  ## may be given. If left empty, the grid will attempt to produce a square,
  ## resorting to more columns than rows if not possible.
  ## Optionally a base layout can be given for the grid.
  result = Grid(layout: layout,
                numPlotsPerRow: numPlotsPerRow,
                plots: newSeq[PlotJson](numPlots))

proc createGrid*(size: tuple[rows, cols: int], layout = Layout()): Grid =
  ## creates a `Grid` object with `rows` x `cols` plots to which one can assign
  ## plots at runtime.
  ## Optionally a base layout can be given for the grid.
  let nPlots = size.rows * size.cols
  result = createGrid(nPlots, size.cols, layout)

proc add*[T](grid: var Grid, plt: Plot[T]) =
  ## add a new plot to the grid. Extends the number of plots stored in the
  ## `Grid` by one.
  ## NOTE: the given `Plot[T]` object is converted to a `PlotJson` object
  ## upon assignment!
  grid.plots.add plt.toPlotJson

proc `[]=`*[T](grid: var Grid, idx: int, plt: Plot[T]) =
  ## converts the given `Plot[T]` to a `PlotJson` and assigns to the given
  ## index.
  if idx > grid.plots.high:
    raise newException(IndexError, "Index position " & $idx & " is out of " &
      "bounds for grid with " & $grid.plots.len & " plots.")
  grid.plots[idx] = plt.toPlotJson

proc `[]=`*[T](grid: var Grid, coord: tuple[row, col: int], plt: Plot[T]) =
  ## converts the given `Plot[T]` to a `PlotJson` and assigns to specified
  ## (row, column) coordinate of the grid.
  let idx = grid.numPlotsPerRow * coord.row + coord.col
  if coord.col > grid.numPlotsPerRow:
    raise newException(IndexError, "Column " & $coord.col & " is out of " &
      "bounds for grid with " & $grid.numPlotsPerRow & " columns!")
  if idx > grid.plots.high:
    raise newException(IndexError, "Position (" & $coord.row & ", " & $coord.col &
      ") is out of bounds for grid with " & $grid.plots.len & " plots.")
  grid.plots[idx] = plt.toPlotJson

proc `[]`*(grid: Grid, idx: int): PlotJson =
  ## returns the plot at index `idx`.
  ## NOTE: the plot is returned as a `PlotJson` object, not as the `Plot[T]`
  ## originally put in!
  result = grid.plots[idx]

proc `[]`*(grid: Grid, coord: tuple[row, col: int]): PlotJson =
  ## returns the plot at (row, column) coordinate `coord`.
  ## NOTE: the plot is returned as a `PlotJson` object, not as the `Plot[T]`
  ## originally put in!
  let idx = grid.numPlotsPerRow * coord.row + coord.col
  result = grid.plots[idx]

proc toPlotJson*(grid: Grid): PlotJson =
  ## converts the `Grid` object to a `PlotJson` object ready to be plotted
  ## via the normal `show` procedure.
  let
    (rows, cols) = calcRowsColumns(rows = -1,
                                   columns = grid.numPlotsPerRow,
                                   nPlots = grid.plots.len)
    gridLayout = GridLayout(useGrid: true, rows: rows, columns: cols)
  result = combine(grid.layout, grid.plots, [], gridLayout)

when isMainModule:
  # test the calculation of rows and columns
  doAssert calcRowsColumns(2, 0, 4) == (2, 1)
  doAssert calcRowsColumns(0, 2, 4) == (1, 2)
  doAssert calcRowsColumns(7, 3, 1) == (7, 3)
  doAssert calcRowsColumns(0, 0, 1) == (1, 1)
  doAssert calcRowsColumns(0, 0, 2) == (1, 2)
  doAssert calcRowsColumns(0, 0, 3) == (2, 2)
  doAssert calcRowsColumns(0, 0, 4) == (2, 2)
  doAssert calcRowsColumns(0, 0, 5) == (2, 3)
  doAssert calcRowsColumns(0, 0, 6) == (2, 3)
  doAssert calcRowsColumns(0, 0, 7) == (3, 3)
  doAssert calcRowsColumns(0, 0, 8) == (3, 3)
  doAssert calcRowsColumns(0, 0, 9) == (3, 3)
  doAssert calcRowsColumns(-1, 2, 4) == (2, 2)
  doAssert calcRowsColumns(-1, 0, 4) == (2, 2)
  doAssert calcRowsColumns(2, -1, 4) == (2, 2)
