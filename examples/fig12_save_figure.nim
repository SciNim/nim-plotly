import plotly
import chroma

const colors = @[Color(r:0.9, g:0.4, b:0.0, a: 1.0),
                 Color(r:0.9, g:0.4, b:0.2, a: 1.0),
                 Color(r:0.2, g:0.9, b:0.2, a: 1.0),
                 Color(r:0.1, g:0.7, b:0.1, a: 1.0),
                 Color(r:0.0, g:0.5, b:0.1, a: 1.0)]
let
  d = Trace[int](mode: PlotMode.LinesMarkers, `type`: PlotType.Scatter)
  size = @[16.int]
d.marker = Marker[int](size: size, color: colors)
d.xs = @[1, 2, 3, 4, 5]
d.ys = @[1, 2, 1, 9, 5]
d.text = @["hello", "data-point", "third", "highest", "<b>bold</b>"]

let
  layout = Layout(title: "Saving a figure!", width: 1200, height: 400,
                  xaxis: Axis(title:"my x-axis"),
                  yaxis: Axis(title: "y-axis too"),
                  autosize: false)
  p = Plot[int](layout: layout, traces: @[d])
# now call the show proc with the `filename` argument to save the
# file with the given filetype
# p.show(filename = "HelloImage.png")
# alternatively call the `saveImage` proc instead of show
p.saveImage("HelloImage.svg")
# NOTE: if we compile this without --threads:on support, we'll get
# an error at compile time that thread support is needed.
