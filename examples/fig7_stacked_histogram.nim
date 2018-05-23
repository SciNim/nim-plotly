import plotly
import random
let
  d1 = Trace[int](`type`: PlotType.Histogram, opacity: 0.8, name:"some values")
  d2 = Trace[int](`type`: PlotType.Histogram, opacity: 0.8, name:"other stuff")

# using ys will make a horizontal bar plot
# using xs will make a vertical.
d1.ys = newSeq[int](200)
d2.ys = newSeq[int](200)

for i, x in d1.ys:
  d1.ys[i] = rand(20)
  d2.ys[i] = rand(30)

for i in 0..40:
  d1.ys[i] = 12

let
  layout = Layout(title: "stacked histogram", width: 1200, height: 400,
                  yaxis: Axis(title:"values"),
                  xaxis: Axis(title: "count"),
                  barmode: BarMode.Stack,
                  #barmode: BarMode.Overlay,
                  autosize: false)
  p = Plot[int](layout: layout, traces: @[d1, d2])
p.show()
