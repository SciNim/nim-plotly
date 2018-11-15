import sequtils
import plotly
import chroma

# simple example showcasing scatter plot with error bars

const colors = @[Color(r:0.9, g:0.4, b:0.0, a: 1.0),
                 Color(r:0.9, g:0.4, b:0.2, a: 1.0),
                 Color(r:0.2, g:0.9, b:0.2, a: 1.0),
                 Color(r:0.1, g:0.7, b:0.1, a: 1.0),
                 Color(r:0.0, g:0.5, b:0.1, a: 1.0)]
let
  d = Trace[float](mode: PlotMode.LinesMarkers, `type`: PlotType.Scatter)
  size = @[16.float]
d.marker = Marker[float](size: size, color: colors)
d.xs = @[1'f64, 2, 3, 4, 5]
d.ys = @[1'f64, 2, 1, 9, 5]

# Note: all `newErrorBar` procs receive an optional `color` argument

# example of constant error
# d.xs_err = newErrorBar(0.5)
# example of constant percentual error. Note that the value given is in actual
# percent and not a ratio
# d.xs_err = newErrorBar(10.0, percent = true)
# example of an asymmetric error bar on x
d.xs_err = newErrorBar((0.1, 0.25), color = colors[0])

# create a sequence of increasing error bars for y
let yerrs = mapIt(toSeq(0..5), it.float * 0.25)
d.ys_err = newErrorBar(yerrs)
# import algorithm
# example of asymmetric error bars for each element
# let yerrs_high = @[0.1, 0.2, 0.3, 0.4, 0.5].reversed
# d.ys_err = newErrorBar((yerrs_low, yerrs_high))
# example of a sqrt error on y. Need to hand the correct type here manually,
# otherwise we'll get a "cannot instantiate `ErrorBar[T]`" error, due to
# no value from which type can be deduced is present
# d.ys_err = newErrorBar[float]()

d.text = @["hello", "data-point", "third", "highest", "<b>bold</b>"]

let
  layout = Layout(title: "testing", width: 1200, height: 400,
                  xaxis: Axis(title: "my x-axis"),
                  yaxis: Axis(title: "y-axis too"), autosize: false)
  p = Plot[float](layout: layout, traces: @[d])
echo p.save()
p.show()
