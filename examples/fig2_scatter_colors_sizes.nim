import plotly
import math
import chroma


const
  n = 70
  color_choice = @[Color(r: 0.9, g: 0.1, b: 0.1, a: 1.0),
                   Color(r: 0.1, g: 0.1, b: 0.9, a: 1.0)]

var
  y = new_seq[float64](n)
  x = new_seq[float64](n)
  text = new_seq[string](n)
  colors = new_seq[Color](n)
  sizes = new_seq[float64](n)
for i in 0 .. y.high:
  x[i] = i.float
  y[i] = sin(i.float)
  text[i] = $i & " has the sin value: " & $y[i]
  sizes[i] = float64(10 + (i mod 10))
  if i mod 3 == 0:
    colors[i] = color_choice[0]
  else:
    colors[i] = color_choice[1]
  text[i] = text[i] & "<b>" & colors[i].toHtmlHex() & "</b>"

block:
  let d = Trace[float64](mode: PlotMode.LinesMarkers, `type`: PlotType.ScatterGL,
                         xs: x, ys: y, text: text)
  d.marker = Marker[float64](size: sizes, color: colors)

  let layout = Layout(title: "saw the sin", width: 1200, height: 400,
                      xaxis: Axis(title: "my x-axis"),
                      yaxis: Axis(title: "y-axis too"), autosize: false)
  Plot[float64](layout: layout, traces: @[d]).show()
block:
  let d = Trace[float64](mode: PlotMode.LinesMarkers, `type`: PlotType.ScatterGL,
                         xs: x, ys: y, text: text)
  d.marker = Marker[float64](size: sizes, colorVals: y, colorMap: ColorMap.Viridis)

  let layout = Layout(title: "saw the sin, colors of sin value!", width: 1200, height: 400,
                      xaxis: Axis(title: "my x-axis"),
                      yaxis: Axis(title: "y-axis too"), autosize: false)
  Plot[float64](layout: layout, traces: @[d]).show()
