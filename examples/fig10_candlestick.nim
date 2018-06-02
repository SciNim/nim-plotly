import plotly
import chroma
import sequtils

var d = Trace[float32](mode: PlotMode.Lines, `type`: PlotType.Candlestick)

d.xs = @[1.0'f32, 2.0, 3.0, 4.0, 5.0]
d.open = @[10.0'f32, 20.0, 10.0, 90.0, 50.0]
d.low = @[7'f32, 15, 7, 90, 45]
d.high = @[10'f32, 22, 10, 110, 55]
d.close = @[7'f32, 22, 7, 105, 55]


let
  layout = Layout(title: "Candlestick example", width: 800, height: 800,
                  xaxis: Axis(title: "x-axis", rangeslider: RangeSlider(visible: false)),
                  yaxis: Axis(title: "y-axis"), autosize: false)
  p = Plot[float32](layout: layout, traces: @[d])
echo p.save()
p.show()
