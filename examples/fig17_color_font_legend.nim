import plotly
import math
import chroma


const
  n = 70

var
  y = newSeq[float64](n)
  x = newSeq[float64](n)
  y2 = newSeq[float64](n)
  x2 = newSeq[float64](n)
  sizes = newSeq[float64](n)
for i in 0 .. y.high:
  x[i] = i.float
  y[i] = sin(i.float)
  x2[i] = (i.float + 0.5)
  y2[i] = i.float * 0.1
  sizes[i] = float64(10 + (i mod 10))

let d = Trace[float64](mode: PlotMode.LinesMarkers, `type`: PlotType.ScatterGL,
                       xs: x, ys: y, lineWidth: 10)
let d2 = Trace[float64](mode: PlotMode.LinesMarkers, `type`: PlotType.ScatterGL,
                       xs: x2, ys: y2)
d.marker = Marker[float64](size: sizes)

let legend = Legend(x: 0.1,
                    y: 0.9,
                    backgroundColor: color(0.6, 0.6, 0.6),
                    orientation: Vertical,
                    font: Font(color: color())
)

let layout = Layout(title: "saw the sin", width: 800, height: 600,
                    xaxis: Axis(title: "my x-axis"),
                    yaxis: Axis(title: "y-axis too"),
                    autosize: false,
                    backgroundColor: color(0.92, 0.92, 0.92),
                    legend: legend,
                    showLegend: true
)

Plot[float64](layout: layout, traces: @[d, d2]).show()

# alternatively using plotly_sugar
# scatterPlot(x, y)
#   .addTrace(scatterTrace(x2, y2))
#   .mode(LinesMarkers)
#   .mode(LinesMarkers, idx = 1)
#   .markerSizes(sizes)
#   .legend(legend)
#   .lineWidth(10, idx = 0)
#   .xlabel("my x-axis")
#   .ylabel("y-axis too")
#   .backgroundColor(color(0.92, 0.92, 0.92))
#   .width(800)
#   .height(600)
#   .show()
