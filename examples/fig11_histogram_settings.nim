import plotly
import math
import sequtils
import mersenne

proc gauss(x, mean, sigma: float): float =
  # unsafe helper proc producing gaussian distribution
  let arg = (x - mean) / sigma
  result = exp(-0.5 * arg * arg) / sqrt(2 * PI)

proc draw(samples: int): seq[float] =
  # create some gaussian data (not very efficient :))
  var random = newMersenneTwister(42)
  const
    mean = 0.5
    sigma = 0.1
  result = newSeqOfCap[float](samples)
  while result.len < samples:
    let
      r = random.getNum().float / uint32.high.float
      rejectProb = gauss(r, mean, sigma)
    if (random.getNum().float / uint32.high.float) < rejectProb:
      result.add r

var data = draw(10_000)


# The following simply showcases a few different ways to set different binning
# ranges and sizes
# NOTE: the `nBins` field of a histogram does not force that number of bins!
# It is merely used as an input for plotly's autobinning algorithm. `nBins`
# is the maximum number of allowed bins. But in some cases it might decide
# that a few bins less visualize the data better. Plotly's description states:
#   "Specifies the maximum number of desired bins. This value will be used in
#    an algorithm that will decide the optimal bin size such that the histogram
#    best visualizes the distribution of the data."
block:
  let
    d = Trace[float](`type`: PlotType.Histogram, cumulative: true,
                     # set a range for the bins and a bin size
                     bins: (0.0, 1.0), binSize: 0.01)
  d.xs = data
  let
    layout = Layout(title: "cumulative histogram in range (0.0 / 1.0) with custom bin size and range",
                    width: 1200, height: 800,
                    # set the range of the axis manually. If not, plotly may not show
                    # empty bins in its range
                    xaxis: Axis(title:"values", range: (0.0, 1.0)),
                    yaxis: Axis(title: "counts"),
                    autosize: false)
    p = Plot[float](layout: layout, traces: @[d])
  p.show()

block:
  let
    d = Trace[float](`type`: PlotType.Histogram, cumulative: true,
                     nBins: 100)
  d.xs = data
  let
    layout = Layout(title: "cumulative histogram in range (0.0 / 1.0) with specific max number of bins",
                    width: 1200, height: 800,
                    # set the range of the axis manually. If not, plotly may not show
                    # empty bins in its range
                    xaxis: Axis(title:"values", range: (0.0, 1.0)),
                    yaxis: Axis(title: "counts"),
                    autosize: false)
    p = Plot[float](layout: layout, traces: @[d])
  p.show()

block:
  # here we only specify the number of bins, but not the bin range nor the axis
  # range. This may result in less than 50 bins (if some bins slightly wider bins
  # fit better according to plotly's algorithm). Additionally, the range of the
  # plot may be cut to bins which contain data.
  let
    d = Trace[float](`type`: PlotType.Histogram, nBins: 50)
  d.xs = data
  let
    layout = Layout(title: "histogram in automatic range with specific max number of bins",
                    width: 1200, height: 800,
                    xaxis: Axis(title:"values"),
                    yaxis: Axis(title: "counts"),
                    autosize: false)
    p = Plot[float](layout: layout, traces: @[d])
  p.show()

block:
  # Setting the bin size and bin range manually. Without specifying the axis range
  # empty bins may still be discarded from the range.
  let
    d = Trace[float](`type`: PlotType.Histogram,
                     bins: (0.0, 1.0), binSize: 0.05)
  d.xs = data
  let
    layout = Layout(title: "histogram in automatic range with specific bin range and size",
                    width: 1200, height: 800,
                    xaxis: Axis(title:"values"),
                    yaxis: Axis(title: "counts"),
                    autosize: false)
    p = Plot[float](layout: layout, traces: @[d])
  p.show()
