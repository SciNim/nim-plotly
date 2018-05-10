import plotly
import chroma

var text = @["a", "b", "c", "d"]
var layout = Layout(title: "nim-plotly bar+scattter chart example", width: 1200, height: 400,
                    xaxis: Axis(title:"category"),
                    yaxis: Axis(title:"value"), autosize:false)

var y = @[25.5'f64, 5, 9, 10.0]
var y2 = @[35.5'f64, 1, 19, 20.0]
var y3 = @[15.5'f64, 41, 29, 30.0]

var d1 = Trace[float64](mode:PlotMode.LinesMarkers, `type`: PlotType.Bar, ys:y, text:text, name: "first group")
var d2 = Trace[float64](mode:PlotMode.LinesMarkers, `type`: PlotType.Bar, ys:y2, text:text, name: "second group")
var d3 = Trace[float64](mode:PlotMode.LinesMarkers, `type`: PlotType.Bar, ys:y3, text:text, name: "third group")
var d4 = Trace[float64](mode:PlotMode.LinesMarkers, `type`: PlotType.ScatterGL, ys:y3, text:text, name: "scatter")
var d5 = Trace[float64](mode:PlotMode.Markers, `type`: PlotType.ScatterGL, ys:y, text:text, name: "just markers")
d5.marker = Marker[float64](size: @[25'f64])

Plot[float64](layout:layout, datas: @[d1, d2, d3, d4, d5]).show()

