import plotly
import chroma
import random
import sequtils

let
  # The GL heatmap is also supported as HeatMapGL
  d = Trace[float32](mode: PlotMode.Lines, `type`: PlotType.HeatMap)

d.colormap = ColorMap.Viridis
# fill data for colormap with random values. The data needs to be supplied
# as a nested seq.
d.zs = newSeqWith(28, newSeq[float32](28))
for x in 0 ..< 28:
  for y in 0 ..< 28:
    d.zs[x][y] = rand(1.0)
let
  layout = Layout(title: "Heatmap example", width: 800, height: 800,
                  xaxis: Axis(title: "A heatmap x-axis"),
                  yaxis: Axis(title: "y-axis too"), autosize: false)
  p = Plot[float32](layout: layout, traces: @[d])
echo p.save()
p.show()
