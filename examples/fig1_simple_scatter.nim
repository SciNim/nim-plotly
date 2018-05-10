import plotly
import chroma

var colors = @[Color(r:0.9, g:0.4, b:0.0, a: 1.0),
               Color(r:0.9, g:0.4, b:0.2, a: 1.0),
               Color(r:0.2, g:0.9, b:0.2, a: 1.0),
               Color(r:0.1, g:0.7, b:0.1, a: 1.0),
               Color(r:0.0, g:0.5, b:0.1, a: 1.0)]
var d = Trace[int](mode: PlotMode.LinesMarkers, `type`: PlotType.Scatter)
var size = @[16.int]
d.marker = Marker[int](size:size, color: colors)
d.xs = @[1, 2, 3, 4, 5]
d.ys = @[1, 2, 1, 9, 5]
d.text = @["hello", "data-point", "third", "highest", "<b>bold</b>"]

var layout = Layout(title: "testing", width: 1200, height: 400, xaxis: Axis(title:"my x-axis"), yaxis:Axis(title: "y-axis too"), autosize:false)
#echo $(%layout)
var p = Plot[int](layout:layout, datas: @[d])
echo p.save()
p.show()
