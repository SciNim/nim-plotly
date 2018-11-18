import nimdata
import plotly
import sugar
import sequtils
import chroma

proc roundOrIdent*[T: SomeNumber](x: T): T =
  when T is SomeInteger:
    x
  else:
    x.round

template mutPlot*(plt: typed, actions: untyped): untyped =
  ## helper template which wraps the code using `mplt` (= mutable `plt`)
  ## in a block and returns it
  ## We need it to overwrite parameters of a plot and have it stick.
  block:
    var mplt {.inject.} = plt
    actions
    mplt

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
    let x = xData[i].roundOrIdent.int
    let y = yData[i].roundOrIdent.int
    zs[x][y] += zData[i]
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
                        `type`: PlotType.ScatterGL,
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

template text*[T](plt: Plot[T], val: untyped): untyped =
  mutPlot(plt):
    when type(val) is string:
      mplt.traces[0].text = @[val]
    else:
      mplt.traces[0].text = val


template markersize*[T](plt: Plot[T],
                        val: SomeNumber): untyped =
  mutPlot(plt):
    mplt.traces[0].marker.size = @[T(val)]


template markersizes*[T](plt: Plot[T],
                         sizes: seq[T]): untyped =
  mutPlot(plt):
    mplt.traces[0].marker.size = sizes

template markercolor*[T](plt: Plot[T],
                         colors: seq[Color] | seq[T] = @[],
                         map: ColorMap = ColorMap.None): untyped =
  mutPlot(plt):
    if colors.len > 0:
      when type(colors[0]) is Color:
        mplt.traces[0].marker.color = colors
      else:
        mplt.traces[0].marker.colorVals = colors
    if map != ColorMap.None:
      mplt.traces[0].marker.colormap = map

template mode*[T](plt: Plot[T], m: PlotMode, id = 0): untyped =
  # for some reason need to create a mutable copy of `plt` to change
  # the mode
  mutPlot(plt):
    mplt.traces[0].mode = PlotMode.m

template markerSize*[T](plt: Plot[T], val: untyped): untyped =
  mutPlot(plt):
    mplt.traces[0].marker.size = @[T(val)]


template pltLabel*(plt: untyped,
                   axis: untyped,
                   label: string): untyped =
  plt.layout.axis.title = label

template xlabel*[T](plt: Plot[T], label: string): untyped =
  mutPlot(plt):
    mplt.pltLabel(xaxis, label)

template ylabel*[T](plt: Plot[T], label: string): untyped =
  mutPlot(plt):
    mplt.pltLabel(yaxis, label)

template nbins*[T](plt: Plot[T], nbins: int): untyped =
  mutPlot(plt):
    doAssert mplt.traces[0].`type` == PlotType.Histogram
    mplt.traces[0].nbins = nbins

template binSize*[T](plt: Plot[T], size: float): untyped =
  mutPlot(plt):
    doAssert mplt.traces[0].`type` == PlotType.Histogram
    mplt.traces[0].binSize = size

template binRange*[T](plt: Plot[T], start, stop: float): untyped =
  mutPlot(plt):
    doAssert mplt.traces[0].`type` == PlotType.Histogram
    mplt.traces[0].bins = (start, stop)


template title*[T](plt: Plot[T], s: string): untyped =
  mutPlot(plt):
    mplt.layout.title = s
