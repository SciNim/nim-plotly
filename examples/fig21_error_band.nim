import sequtils
import plotly
import chroma
from std / algorithm import reversed

# simple example showcasing error bands (by hand)

let
  d = Trace[float](mode: PlotMode.LinesMarkers, `type`: PlotType.Scatter)
  size = @[16.float]
d.marker = Marker[float](size: size)
d.xs = @[1'f64, 2, 3, 4, 5]
d.ys = @[1'f64, 2, 1, 9, 5]

# Create a Trace for the error band
let
  dBand = Trace[float](mode: PlotMode.Lines, `type`: PlotType.Scatter,
                       opacity: 0.75, # opacity 75% to be prettier
                       fill: ToSelf, # `ToSelf` means the filling is done to its own data
                       hideLine: true) # line width 0 disables the outline
# Create X data that is first increasing and then decreasing
dBand.xs = concat(d.xs, d.xs.reversed)
# Assign the actual ribbon band. Currently needs to be a seq
dBand.marker = Marker[float](color: @[color(0.6, 0.6, 0.6)])

# define some errors we will use (symmetric)
let yErr = d.ys.mapIt(0.25)
# now create the first upper band range
var yErrs = newSeqOfCap[float](d.ys.len * 2) # first upper, then lower
for i in 0 ..< d.ys.len: # upper errors
  yErrs.add(d.ys[i] + yErr[i])
# and now the lower
for i in countdown(d.ys.high, 0): # lower errors
  yErrs.add(d.ys[i] - yErr[i])
dBand.ys = yErrs

let
  layout = Layout(title: "testing", width: 1200, height: 400,
                  xaxis: Axis(title: "my x-axis"),
                  yaxis: Axis(title: "y-axis too"), autosize: false)
  p = Plot[float](layout: layout, traces: @[d, dBand]) # assign both traces
echo p.save()
p.show()
