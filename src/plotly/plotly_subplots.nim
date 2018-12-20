import json, macros, math
import plotly_types, plotly_sugar, api

type
  # subplot specific object, which stores intermediate information about
  # the grid layout to use for multiple plots
  Grid = object
    useGrid: bool
    rows: int
    columns: int

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
  ## input for `rows` and `columns`. If no input is given, calculate the next
  ## possible rectangle of plots that favors columns over rows
  if rows == 0 and columns == 0:
    # calc square of plots
    let sqPlt = sqrt(nPlots.float)
    result[1] = sqPlt.ceil.int
    result[0] = sqPlt.round.int
  elif rows == 0 and columns > 0:
    # 1 row, user desired # cols
    result = (1, columns)
  elif rows > 0 and columns == 0:
    # user desired # row, 1 col
    result = (rows, 1)
  else:
    result = (rows, columns)

proc assignGrid(plt: PlotJson, grid: Grid) =
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
             grid: Grid): PlotJson =
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
    let trIdx = result.traces.len
    # first add traces of `*each Plot*`, only afterwards flatten them!
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
    of nnkPar:
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
    of nnkDotExpr:
      # assume the user accesses some object storing a domain of
      # either type `Domain` or `DomainAlt`, take as is
      domain = plt[i]
      isSymbol = true
    else:
        error("Plot statement needs to consist of Plot ident, nnkCall or " &
          "nnkAsgn. Line is " & plt[i].repr & " of kind " & $plt[i].kind)
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
  ## `Grid` object storing the information.
  let gridIdent = ident"gridImpl"
  var gridVar = quote do:
    var `gridIdent` = Grid()
  var gridObj = nnkObjConstr.newTree(
    bindSym"Grid",
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
    var `gridIdent` = Grid(useGrid: false)

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
          var `gridIdent` = Grid(useGrid: true)

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
