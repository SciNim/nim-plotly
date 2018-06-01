import plotly
import chroma
import random
import sequtils
import future

var d = Trace[float32](mode: PlotMode.Lines, `type`: PlotType.Candlestick)
# Weird cast to float32 needed because on Windows 10 the system float is float64
d.xs = lc[float32(x) | (x <- @[1.0, 2.0, 3.0, 4.0, 5.0], float32(x) > 0), float32]
d.open = lc[float32(x) | (x <- @[10.0, 20.0, 10.0, 90.0, 50.0], float32(x) > 0), float32]
d.low = lc[float32(x) | (x <- @[7, 15, 7, 90, 45], float32(x) > 0), float32]
d.high = lc[float32(x) | (x <- @[10, 22, 10, 110, 55], float32(x) > 0), float32]
d.close = lc[float32(x) | (x <- @[7, 22, 7, 105, 55], float32(x) > 0), float32]


let
  layout = Layout(title: "Candlestick example", width: 800, height: 800,
                  xaxis: Axis(title: "x-axis", rangeslider: RangeSlider(visible: false)),
                  yaxis: Axis(title: "y-axis"), autosize: false)
  p = Plot[float32](layout: layout, traces: @[d])
echo p.save()
p.show()
