import math
import plotly

const n = 50
var y1 = new_seq[float64](n)
var y2 = new_seq[float64](n)
var x = new_seq[float64](n)

for i in 0..x.high:
  x[i] = i.float64
  y1[i] = sin(i.float64) * 100
  y2[i] = cos(i.float64) / 100

var t1 = Trace[float64](mode:PlotMode.Lines, `type`: PlotType.Scatter, ys:y1, name: "sin*100")
var t2 = Trace[float64](mode:PlotMode.Lines, `type`: PlotType.Scatter, ys:y2, name: "cos/100", yaxis:"y2")
var layout = Layout(title: "multiple axes in nim plotly", width: 1200, height: 400,
                    xaxis: Axis(title:"x"),
                    yaxis: Axis(title:"sin"),
                    yaxis2: Axis(title:"cos", side:PlotSide.Right), autosize:false)

Plot[float64](layout:layout, datas: @[t1, t2]).show()

    


