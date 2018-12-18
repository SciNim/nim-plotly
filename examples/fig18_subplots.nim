import plotly, sequtils, macros, algorithm
import json
import math
import chroma
import strformat


const
  n = 5
var
  y = new_seq[float64](n)
  x = new_seq[float64](n)
  x2 = newSeq[int](n)
  y2 = newSeq[int](n)
  x3 = newSeq[int](n)
  y3 = newSeq[int](n)
  sizes = new_seq[float64](n)
for i in 0 .. y.high:
  x[i] = i.float
  y[i] = sin(i.float)
  x2[i] = i
  y2[i] = i * 5
  x3[i] = i
  y3[i] = -(i * 5)
  sizes[i] = float64(10 + (i mod 10))

let d = Trace[float64](mode: PlotMode.LinesMarkers, `type`: PlotType.ScatterGL,
                       xs: x, ys: y,
                       marker: Marker[float64](size: sizes,
                                               colorVals: y,
                                               colorMap: ColorMap.Viridis))

let d2 = Trace[int](mode: PlotMode.LinesMarkers, `type`: PlotType.ScatterGL,
                    xs: x2, ys: y2)
let d3 = Trace[float](mode: PlotMode.LinesMarkers, `type`: PlotType.ScatterGL,
                      xs: x2.mapIt(it.float), ys: y2.mapIt(it.float))
let d4 = Trace[int](mode: PlotMode.LinesMarkers, `type`: PlotType.ScatterGL,
                      xs: x3, ys: y3)

let layout = Layout(title: "saw the sin, colors of sin value!", width: 1000, height: 400,
                    xaxis: Axis(title: "my x-axis"),
                    yaxis: Axis(title: "y-axis too"), autosize: false)

let baseLayout = Layout(title: "A bunch of subplots!", width: 800, height: 800,
                        xaxis: Axis(title: "linear x"),
                        yaxis: Axis(title: "y also linear"), autosize: false)


let plt1 = Plot[float64](layout: layout, traces: @[d, d3])
let plt2 = Plot[int](layout: baseLayout, traces: @[d2, d4])
let plt3 = scatterPlot(x3, y3).title("Another plot!").width(1000)

let pltCombined = subplots:
  baseLayout: baseLayout
  plot:
    plt1
    left: 0.0
    bottom: 0.0
    right: 0.45
    top: 1.0
  plot:
    plt2
    (0.6, 0.5, 0.4, 0.5)
  plot:
    plt3
    left = 0.7
    bottom = 0.0
    right = 1.0
    top = 0.3
pltCombined.show()
