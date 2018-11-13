import plotly
import random
import sequtils

randomize(42)
let
  x = toSeq(0 ..< 50)
  y = toSeq(0 ..< 50).mapIt(rand(50))
  d = Trace[int](`type`: PlotType.Bar,
                   xs: x,
                   ys: y,
                   orientation: Orientation.Horizontal)

let
  layout = Layout(title: "Horizontal bar plot",
                  width: 1200, height: 800,
                  autosize: false)
  p = Plot[int](layout: layout, traces: @[d])
p.show()
