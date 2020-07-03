import plotly
import plotly / color
import chroma
import random
import sequtils

var data = newSeqWith(28, newSeq[float32](28))
for x in 0 ..< 28:
  for y in 0 ..< 28:
    data[x][y] = max(rand(1.0), 0.3)

let randomCustomMap = @[
(r: 0.9719701409339905, g: 0.463617742061615, b: 0.4272273480892181),
(r: 0.638210654258728, g: 0.6486857533454895, b: 0.0),
(r: 0.0, g: 0.7498401999473572, b: 0.4914137721061707),
(r: 0.0, g: 0.6900160312652588, b: 0.9665122032165527),
(r: 0.9064756631851196, g: 0.4206041693687439, b: 0.9523735642433167)
]

block:
  let d = Trace[float32](mode: PlotMode.Lines, `type`: PlotType.HeatMap)
  # generate some random data
  d.zs = data
  proc customHeatmap(name: PredefinedCustomMaps) =
    # use `getCustomMap` to get one of the predefined colormaps and assign
    # it to the `customCmap` field of the `Trace`
    d.customColormap = getCustomMap(name)
    # for the custom map to have any effect, we have to choose the
    # `Custom` value for the `colorMap` field.
    d.colorMap = Custom
    let
      layout = Layout(title: $name, width: 800, height: 800,
                      xaxis: Axis(title: "x"),
                      yaxis: Axis(title: "y"), autosize: false)
      p = Plot[float32](layout: layout, traces: @[d])
    p.show()

  for map in PredefinedCustomMaps:
    customHeatmap(map)

  # and now a fully custom map
  d.customColormap = CustomColorMap(rawColors: randomCustomMap)
  # for the custom map to have any effect, we have to choose the
  # `Custom` value for the `colorMap` field.
  d.colorMap = Custom
  let
    layout = Layout(title: "fully custom", width: 800, height: 800,
                    xaxis: Axis(title: "x"),
                    yaxis: Axis(title: "y"), autosize: false)
    p = Plot[float32](layout: layout, traces: @[d])
  p.show()

block:
  # using plotly_sugar
  proc customHeatmap(name: PredefinedCustomMaps) =
    heatmap(data)
      .title($name & " using sugar")
      # colormap takes one of:
      # - `ColorMap: enum`
      # - `PredefinedCustomMaps: enum`
      # - `CustomColorMap: ref object`
      # - `colormapData: seq[tuple[r, g, b: float64]]`
      .colormap(name)
      .show()

  for map in PredefinedCustomMaps:
    customHeatmap(map)

  heatmap(data)
    .title("fully custom using sugar")
    .colormap(randomCustomMap)
    .show()
