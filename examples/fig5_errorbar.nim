import sequtils
import plotly
import chroma

# simple example showcasing scatter plot with error bars

var colors = @[Color(r:0.9, g:0.4, b:0.0, a: 1.0),
               Color(r:0.9, g:0.4, b:0.2, a: 1.0),
               Color(r:0.2, g:0.9, b:0.2, a: 1.0),
               Color(r:0.1, g:0.7, b:0.1, a: 1.0),
               Color(r:0.0, g:0.5, b:0.1, a: 1.0)]
var d = Trace[float](mode: PlotMode.LinesMarkers, `type`: PlotType.Scatter)
var size = @[16.float]
d.marker = Marker[float](size: size, color: colors)
d.xs = @[1'f64, 2, 3, 4, 5]
d.ys = @[1'f64, 2, 1, 9, 5]

# set an asymmetric error bar on x
d.xs_err = newErrorBar((0.2, 0.5), color = colors[0])
# create a sequence of increasing error bars for y
let yerrs = @[0.1, 0.2, 0.3, 0.4, 0.5]
d.ys_err = newErrorBar(yerrs, color = colors[0])

d.text = @["hello", "data-point", "third", "highest", "<b>bold</b>"]

var layout = Layout(title: "testing", width: 1200, height: 400, xaxis: Axis(title:"my x-axis"), yaxis:Axis(title: "y-axis too"), autosize:false)
var p = Plot[float](layout:layout, datas: @[d])
echo p.save()
p.show()
