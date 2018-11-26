import plotly_types
import sugar
import sequtils
import chroma

proc roundOrIdent*[T: SomeNumber](x: T): T =
  when T is SomeInteger:
    x
  else:
    x.round

template barPlot*(x, y: untyped): untyped =
  type xType = type(x[0])
  type yType = type(y[0])
  when xType is string:
    let xData = x
  else:
    # make sure x and y are same type
    let xData = x.mapIt(yType(it))
  let title = "Bar plot of " & astToStr(x) & " vs. " & astToStr(y)
  let plLayout = Layout(title: title,
                        width: 800, height: 600,
                        xaxis: Axis(title: astToStr(x)),
                        yaxis: Axis(title: astToStr(y)),
                        autosize: false)
  var tr = Trace[yType](`type`: PlotType.Bar,
                        ys: y)
  when xType is string:
    tr.text = xData
  else:
    tr.xs = xData
  let plt = Plot[yType](traces: @[tr], layout: plLayout)
  plt

template histPlot*(hist: untyped): untyped =
  type hType = type(hist[0])
  let title = "Histogram of " & astToStr(hist)
  let plLayout = Layout(title: title,
                        width: 800, height: 600,
                        xaxis: Axis(title: astToStr(x)),
                        yaxis: Axis(title: "Counts"),
                        autosize: false)
  let tr = Trace[hType](`type`: PlotType.Histogram,
                        xs: hist)
  var plt = Plot[hType](traces: @[tr], layout: plLayout)
  plt

template heatmap*(x, y, z: untyped): untyped =
  type xType = type(x[0])
  let xData = x
  let yData = y.mapIt(xType(it))
  let zData = z.mapIt(xType(it))
  var zs = newSeqWith(max(xData).roundOrIdent.int + 1,
                      newSeq[xType](max(yData).roundOrIdent.int + 1))
  for i in 0 .. xData.high:
    let xIdx = xData[i].roundOrIdent.int
    let yIdx = yData[i].roundOrIdent.int
    zs[xIdx][yIdx] += zData[i]
  let title = "Heatmap of " & astToStr(x) & " vs. " & astToStr(y) & " on " & astToStr(z)
  let plLayout = Layout(title: title,
                        width: 800, height: 800,
                        xaxis: Axis(title: astToStr(x)),
                        yaxis: Axis(title: astToStr(y)),
                        autosize: true)
  let tr = Trace[xType](`type`: PlotType.Heatmap,
                        colormap: ColorMap.Viridis,
                        zs: zs)
  var plt = Plot[xType](traces: @[tr], layout: plLayout)
  plt

template heatmap*[T](z: seq[seq[T]]): untyped =
  type zType = type(z[0][0])
  var zs = z
  let title = "Heatmap of " & astToStr(z)
  let plLayout = Layout(title: title,
                        width: 800, height: 800,
                        xaxis: Axis(title: "x"),
                        yaxis: Axis(title: "y"),
                        autosize: true)
  let tr = Trace[zType](`type`: PlotType.Heatmap,
                        colormap: ColorMap.Viridis,
                        zs: zs)
  var plt = Plot[zType](traces: @[tr], layout: plLayout)
  plt


template scatterPlot*(x, y: untyped): untyped =
  type xType = type(x[0])
  let xData = x
  # make sure y has same dtype
  let yData = y.mapIt(xType(it))
  let title = "Scatter plot of " & astToStr(x) & " vs. " & astToStr(y)
  let plLayout = Layout(title: title,
                        width: 800, height: 600,
                        xaxis: Axis(title: astToStr(x)),
                        yaxis: Axis(title: astToStr(y)),
                        autosize: false)
  let tr = Trace[xType](mode: PlotMode.Markers,
                        marker: Marker[xType](),
                        `type`: PlotType.Scatter,
                        xs: xData,
                        ys: yData)
  var plt = Plot[xType](traces: @[tr], layout: plLayout)
  plt

template scatterColor*(x, y, z: untyped): untyped =
  ## adds a color dimension to the scatter plot in addition
  type xType = type(x[0])
  let zData = z.mapIt(xType(it))
  let zText = zData.mapIt((astToStr(z) & ": " & $it))
  let title = "Scatter plot of " & astToStr(x) & " vs. " & astToStr(y) &
    " with colorscale of " & astToStr(z)
  let plt = scatterPlot(x, y)
    .title(title)
    .text(zText)
    .markercolor(colors = zData,
                 map = ColorMap.Viridis)
  plt

proc title*[T](plt: Plot[T], t: string): Plot[T] =
  result = plt
  result.layout.title = t

proc width*[T, U: SomeNumber](plt: Plot[T], width: U): Plot[T] =
  result = plt
  result.layout.width = U.roundOrIdent.int

proc height*[T, U: SomeNumber](plt: Plot[T], height: U): Plot[T] =
  result = plt
  result.layout.height = height.roundOrIdent.int

proc text*[T; U: string | seq[string]](plt: Plot[T],
                                       val: U,
                                       idx = 0): Plot[T] =
  result = plt
  when type(val) is string:
    result.traces[idx].text = @[val]
  else:
    result.traces[idx].text = val

proc markersize*[T](plt: Plot[T],
                    val: SomeNumber,
                    idx = 0): Plot[T] =
  result = plt
  result.traces[idx].marker.size = @[T(val)]


proc markersizes*[T](plt: Plot[T],
                     sizes: seq[T],
                     idx = 0): Plot[T] =
  result = plt
  result.traces[idx].marker.size = sizes

proc markercolor*[T](plt: Plot[T],
                     colors: seq[Color] | seq[T] = @[],
                     map: ColorMap = ColorMap.None,
                     idx = 0): Plot[T] =
  result = plt
  if colors.len > 0:
    when type(colors[idx]) is Color:
      result.traces[idx].marker.color = colors
    else:
      result.traces[idx].marker.colorVals = colors
  if map != ColorMap.None:
    result.traces[idx].marker.colormap = map

proc mode*[T](plt: Plot[T], m: PlotMode, idx = 0): Plot[T] =
  result = plt
  result.traces[idx].mode = m

proc markerSize*[T, U: SomeNumber](plt: Plot[T], val: U, idx = 0): Plot[T] =
  result = plt
  result.traces[idx].marker.size = @[T(val)]

template pltLabel*(plt: untyped,
                   axis: untyped,
                   label: string): untyped =
  plt.layout.axis.title = label

proc xlabel*[T](plt: Plot[T], label: string): Plot[T] =
  result = plt
  result.pltLabel(xaxis, label)

proc ylabel*[T](plt: Plot[T], label: string): Plot[T] =
  result = plt
  result.pltLabel(yaxis, label)

proc nbins*[T](plt: Plot[T], nbins: int, idx = 0): Plot[T] =
  result = plt
  doAssert result.traces[idx].`type` == PlotType.Histogram
  result.traces[idx].nbins = nbins

proc binSize*[T](plt: Plot[T], size: float, idx = 0): Plot[T] =
  result = plt
  doAssert result.traces[idx].`type` == PlotType.Histogram
  result.traces[idx].binSize = size

proc binRange*[T](plt: Plot[T], start, stop: float, idx = 0): Plot[T] =
  result = plt
  doAssert result.traces[idx].`type` == PlotType.Histogram
  result.traces[idx].bins = (start, stop)
