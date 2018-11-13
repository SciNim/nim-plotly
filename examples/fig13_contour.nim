import plotly
import sequtils

let
  d = Trace[float32](`type`: PlotType.Contour)

d.xs = @[-2.0, -1.5, -1.0, 0.0, 1.0, 1.5, 2.0, 2.5].mapIt(it.float32)
d.ys = @[0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6].mapIt(it.float32)
  # The data needs to be supplied as a nested seq.
d.zs = @[@[2, 4, 7, 12, 13, 14, 15, 16],
         @[3, 1, 6, 11, 12, 13, 16, 17],
         @[4, 2, 7, 7, 11, 14, 17, 18],
         @[5, 3, 8, 8, 13, 15, 18, 19],
         @[7, 4, 10, 9, 16, 18, 20, 19],
         @[9, 10, 5, 27, 23, 21, 21, 21],
         @[11, 14, 17, 26, 25, 24, 23, 22]].mapIt(it.mapIt(it.float32))

d.colorscale = ColorMap.Jet
# d.heatmap = true # smooth colors
# d.smoothing = 0.001 # rough lines
# d.contours = (2.0, 26.0, 4.0)

let
  layout = Layout(title: "Contour example", width: 600, height: 600,
                  xaxis: Axis(title: "x-axis"),
                  yaxis: Axis(title: "y-axis"), autosize: false)
  p = Plot[float32](layout: layout, traces: @[d])

echo p.save()
p.show()
