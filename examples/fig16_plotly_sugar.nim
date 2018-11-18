import plotly
import plotly / plotly_sugar
import math
import sequtils
import random

block:
  # example of a scatter plot with the markers in color
  # of the `y` value
  const
    n = 70

  var
    y = newSeq[float64](n)
    x = newSeq[float64](n)
    text = newSeq[string](n)
    sizes = newSeq[float64](n)
  for i in 0 .. y.high:
    x[i] = i.float
    y[i] = sin(i.float)
    text[i] = $i & " has the sin value: " & $y[i]
    sizes[i] = float64(10 + (i mod 10))

  scatterColor(x, y, y)
    .mode(PlotMode.LinesMarkers)
    .markersize(15)
    .show()

block:
  # example of a heatmap from seq[seq[float]]
  var zs = newSeqWith(28, newSeq[float32](28))
  for x in 0 ..< 28:
    for y in 0 ..< 28:
      zs[x][y] = rand(1.0)
  heatmap(zs)
    .xlabel("Some x label!")
    .ylabel("Some y label too!")
    .show()

block:
  # example of a heatmap from x, y, z: seq[T]
  var
    xs = newSeq[float](28 * 28)
    ys = newSeq[float](28 * 28)
    zs = newSeq[float](28 * 28)
  for i in 0 .. xs.high:
    xs[i] = rand(27.0)
    ys[i] = rand(27.0)
    zs[i] = rand(1.0)
  heatmap(xs, ys, zs)
    .xlabel("Some x label!")
    .ylabel("Some y label too!")
    .show()

block:
  var hist: seq[int]
  for i in 0 .. 1000:
    hist.add rand(25)
  histPlot(hist)
    .binSize(2.0)
    .show()

block:
  var bars = newSeq[int](100)
  var counts = newSeq[int](100)
  for i in 0 .. 25:
    bars[i] = i * 4
    counts[i] = rand(100)
  barPlot(bars, counts).show()

block:
  var bars = newSeq[string](10)
  var counts = newSeq[int](10)
  var i = 0
  for x in {'a' .. 'j'}:
    bars[i] = $x
    counts[i] = rand(100)
    inc i

  barPlot(bars, counts)
    .title("Some char label bar plot")
    .show()
