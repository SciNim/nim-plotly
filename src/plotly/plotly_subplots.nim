proc convertDomain(d: Domain | DomainAlt): Domain =
  ## proc to convert a domain tuple from
  ## left, bottom, right, top
  ## notation to
  ## left, bottom, width, height
  when type(d) is tuple[left, bottom, width, height: float]:
    result = d
  else:
    result = (left: d.left,
              bottom: d.bottom,
              width: d.right - d.left,
              height: d.top - d.bottom)

proc combine(baseLayout: Layout,
             plts: openArray[PlotJson],
             domains: openArray[Domain]): PlotJson =
  # we need to combine the plots on a JsonNode level to avoid problems with
  # different plot types!
  var res = newPlot()
  result = res.toPlotJson
  result.layout = % baseLayout
  doAssert plts.len == domains.len, "Every plot needs a domain!"
  for i, p in plts:
    #doAssert p.traces.len == 1
    let trIdx = result.traces.len
    # first add traces of `*each Plot*`, only afterwards flatten them!
    result.traces.add p.traces
    let domain = domains[i]
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
    let xdomain = @[domain.left, domain.left + domain.width]
    let ydomain = @[domain.bottom, domain.bottom + domain.height]
    result.layout[xaxisStr]["domain"] = % xdomain
    result.layout[yaxisStr]["domain"] = % ydomain

    if i > 0:
      # anchor xaxis to y data and vice versa
      result.layout[xaxisStr]["anchor"] = % ("y" & $idx)
      result.layout[yaxisStr]["anchor"] = % ("x" & $idx)

  var i = 0
  # flatten traces and set correct axis for correct original plots
  var traces = newJArray()
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
  for i in 1 ..< plt.len:
    case plt[i].kind
    of nnkPar:
      # is nameless tuple
      doAssert plt[i].len == 4, "Domain needs to consist of 4 elements!"
      domain.add handleDomain(ident"left", plt[i][0])
      domain.add handleDomain(ident"bottom", plt[i][0])
      domain.add handleDomain(ident"width", plt[i][0])
      domain.add handleDomain(ident"height", plt[i][0])
      # ignore what comes after
      break
    of nnkCall:
      # for call RHS is StmtList
      domain.add handleDomain(plt[i][0], plt[i][1][0])
    of nnkAsgn:
      # for assignment RHS is single expr
      domain.add handleDomain(plt[i][0], plt[i][1])
    else:
        error("Plot statement needs to consist of Plot ident, nnkCall or " &
          "nnkAsgn. Line is " & plt[i].repr & " of kind " & $plt[i].kind)
    if domain.len == 4:
      # have a full domain, stop
      break

  result[1] = domain

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
  var
    layout: NimNode
    # plots contain `Plot[T]` identifier and `domain`
    plots: seq[(NimNode, NimNode)]
  for stmt in stmts:
    case stmt.kind
    of nnkCall:
      case stmt[0].strVal
      of "baseLayout":
        layout = stmt[1][0]
      of "plot":
        # only interested in content of `plot:`, hence [1]
        plots.add handlePlotStmt(stmt[1])
    else:
      error("Statement needs to be `baseLayout` or `plot`! " &
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
    domainArray.add quote do:
      `domainIdent`.convertDomain
  # call combine proc
  result = quote do:
    combine(`layout`, `pltArray`, `domainArray`)
