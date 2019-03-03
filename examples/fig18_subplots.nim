import plotly, sequtils, macros, algorithm
import json
import math
import chroma
import strformat

# given some data
const
  n = 5
var
  y = new_seq[float64](n)
  x = new_seq[float64](n)
  x2 = newSeq[int](n)
  y2 = newSeq[int](n)
  x3 = newSeq[int](n)
  y3 = newSeq[int](n)
  sizes = new_seq[float64](n)
for i in 0 .. y.high:
  x[i] = i.float
  y[i] = sin(i.float)
  x2[i] = i
  y2[i] = i * 5
  x3[i] = i
  y3[i] = -(i * 5)
  sizes[i] = float64(10 + (i mod 10))

# and with it defined plots of possibly different datatypes (note `float` and `int`)
let d = Trace[float64](mode: PlotMode.LinesMarkers, `type`: PlotType.ScatterGL,
                       xs: x, ys: y)
let d2 = Trace[int](mode: PlotMode.LinesMarkers, `type`: PlotType.ScatterGL,
                    xs: x2, ys: y2)
let d3 = Trace[float](mode: PlotMode.LinesMarkers, `type`: PlotType.ScatterGL,
                      xs: x2.mapIt(it.float), ys: y2.mapIt(it.float))
let d4 = Trace[int](mode: PlotMode.LinesMarkers, `type`: PlotType.ScatterGL,
                      xs: x3, ys: y3)

let layout = Layout(title: "saw the sin, colors of sin value!", width: 1000, height: 400,
                    xaxis: Axis(title: "my x-axis"),
                    yaxis: Axis(title: "y-axis too"), autosize: false)

let baseLayout = Layout(title: "A bunch of subplots!", width: 800, height: 800,
                        xaxis: Axis(title: "linear x"),
                        yaxis: Axis(title: "y also linear"), autosize: false)

let plt1 = Plot[float64](layout: layout, traces: @[d, d3])
let plt2 = Plot[int](layout: baseLayout, traces: @[d2, d4])
let plt3 = scatterPlot(x3, y3).title("Another plot!").width(1000)

# we wish to create a subplot including all three plots. The `subplots` macro
# returns a special `PlotJson` object, which stores the same information as
# a `Plot[T]` object, but already converted to `JsonNodes`. This is done for easier
# handling of different data types. But fear not, this object is given straight to
# `show` or `saveImage` unless you wish to manually add something to the `JsonNodes`.
let pltCombined = subplots:
  # first we need to define a base layout for our plot, which defines size
  # of canvas and other applicable properties
  baseLayout: baseLayout
  # now we define all plots in `plot` blocks
  plot:
    # the first identifier points to a `Plot[T]` object
    plt1
    # it follows the description of the `Domain`, i.e. the location and
    # size of the subplot. This can be done explicitly as follows:
    # Note that the order of the fields is not important, but you need to
    # define all 4!
    left: 0.0
    bottom: 0.0
    width: 0.45
    height: 1.0
  plot:
    plt2
    # alternatively a nameless tuple conforming to the order
    (0.6, 0.5, 0.4, 0.5)
  plot:
    plt3
    # or instead of defining via `:`, you can use `=`
    left = 0.7
    bottom = 0.0
    # and also replace `widht` and `height` by the right and top edge of the plot
    # NOTE: you *cannot* mix e.g. right with height!
    right = 1.0
    top = 0.3
pltCombined.show()

# if you do not wish to define domains for each plot, you also simply define
# grid as we do here
let pltC2 = subplots:
  baseLayout: baseLayout
  # this requires the `grid` block
  grid:
    # it may contain a `rows` and `column` field, although both are optional
    # If only one is set, the other will be set to 1. If neither is set,
    # nor any domains on the plots, a grid will be calculated automatically,
    # favoring more columns than rows.
    rows: 3
    columns: 1
  plot:
    plt1
  plot:
    plt2
  plot:
    plt3
pltC2.show()

# Finally you may want to create a grid, to which you only add
# plots at a later time, potentially at runtime. Use `createGrid` for this.
# Note: internally the returned `Grid` object stores all plots already
# converted to `PlotJson` (i.e. the `layout` and `traces` fields are
# `JsonNodes`).
var grid = createGrid(numPlots = 2) #,
                      # allows to set the desired number of columns
                      # if not set will try to arange in a square
                      # numPlotsPerRow = 2,
                      # optionally set a layout for the plots
                      # layout = baseLayout)
# the returned grid has space for 2 plots.
grid[0] = plt1
grid[1] = plt2
# However, you may also extend the grid by using `add`
grid.add plt3
grid.show()

# alternatively define grid using rows and columns directly:
var gridAlt = createGrid((rows: 2, cols: 2))
# to which you can assign also in tuples
gridAlt[(0, 0)] = plt1
# or as named tuples
gridAlt[(row: 0, col: 1)] = plt2
gridAlt[(row: 1, col: 0)] = plt3
# Assigning the third plot in a 2x2 grid to coord (1, 1) moves it to (1, 0),
# i.e. the rows are always filled from left to right, if plots are missing!

# Note that the underlying `Grid` object is the same, so both can
# be used interchangeably.
gridAlt.show()
