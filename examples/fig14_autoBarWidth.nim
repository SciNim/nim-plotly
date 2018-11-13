import plotly
import math, random
import sequtils

block:
  # `x` can be either the real bin edges (i.e. N + 1 bin edges for
  # N bins, last element being right edge of last bin)
  let x = @[0.0, 5.0, 10.0, 15.0]
  # or last right edge can be dropped. Last bins width will be assumed
  # to be same as before, if `autoWidth` is used.
  # let x = @[0.0, 5.0, 10.0]
  let y = @[5.0, 12.0, 3.3]
  let
    d = Trace[float](`type`: PlotType.Bar,
                     xs: x,
                     ys: y,
                     align: BarAlign.Edge,
                     autoWidth: true)

  let
    layout = Layout(title: "Bar plot with left aligned bins, width calculated automatically",
                    width: 1200, height: 800,
                    autosize: false)
    p = Plot[float](layout: layout, traces: @[d])
  p.show()

block:
  # center aligned, automatical width calculation
  let
    x = @[0.0, 5.0, 10.0]
    y = @[5.0, 12.0, 3.3]
    d = Trace[float](`type`: PlotType.Bar,
                     xs: x,
                     ys: y,
                     align: BarAlign.Center,
                     autoWidth: true)

  let
    layout = Layout(title: "Bar plot with centered bins, width calculated automatically ",
                    width: 1200, height: 800,
                    autosize: false)
    p = Plot[float](layout: layout, traces: @[d])
  p.show()

block:
  # hand sequence of widths, left aligned
  let
    x = @[0.0, 5.0, 10.0]
    y = @[5.0, 12.0, 3.3]
    widths = @[5.0, 5.0, 5.0]
    d = Trace[float](`type`: PlotType.Bar,
                     xs: x,
                     ys: y,
                     widths: widths, # don't confuse with `width` field (no `s`)!
                     align: BarAlign.Edge)

  let
    layout = Layout(title: "Bar plot with left aligned bins, manual sequence of bin widths",
                    width: 1200, height: 800,
                    autosize: false)
    p = Plot[float](layout: layout, traces: @[d])
  p.show()

block:
  # hand scalar width, left aligned
  let
    x = @[0.0, 5.0, 10.0]
    y = @[5.0, 12.0, 3.3]
    width = 5.0
    d = Trace[float](`type`: PlotType.Bar,
                     xs: x,
                     ys: y,
                     width: width, # don't confuse with `widths` (with `s`)!
                     align: BarAlign.Edge)

  let
    layout = Layout(title: "Bar plot with left aligned bins, single manual bin width",
                    width: 1200, height: 800,
                    autosize: false)
    p = Plot[float](layout: layout, traces: @[d])
  p.show()

block:
  # hand scalar width, center aligned
  let
    x = @[0.0, 5.0, 10.0]
    y = @[5.0, 12.0, 3.3]
    width = 5.0
    d = Trace[float](`type`: PlotType.Bar,
                     xs: x,
                     ys: y,
                     width: width, # don't confuse with `widths` (with `s`)!
                     align: BarAlign.Center)

  let
    layout = Layout(title: "Bar plot with centered bins, single manual bin width",
                    width: 1200, height: 800,
                    autosize: false)
    p = Plot[float](layout: layout, traces: @[d])
  p.show()

block:
  # bar plot with default settings
  let
    x = @[0.0, 5.0, 10.0]
    y = @[5.0, 12.0, 3.3]
    d = Trace[float](`type`: PlotType.Bar,
                     xs: x,
                     ys: y)

  let
    layout = Layout(title: "Bar plot with default width and alignment",
                    width: 1200, height: 800,
                    autosize: false)
    p = Plot[float](layout: layout, traces: @[d])
  p.show()

block:
  # example of non equal bin widths, calculated automatically
  randomize(42)
  let
    x = toSeq(0 ..< 50).mapIt(pow(it.float, 3.0))
    y = toSeq(0 ..< 50).mapIt(rand(100.0))
    d = Trace[float](`type`: PlotType.Bar,
                     xs: x,
                     ys: y,
                     align: BarAlign.Edge,
                     autoWidth: true)

  let
    layout = Layout(title: "Bar plot unequal bin widths, automatically calculated",
                    width: 1200, height: 800,
                    autosize: false)
    p = Plot[float](layout: layout, traces: @[d])
  p.show()
