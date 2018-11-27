import chroma

# this module contains all types used in the plotly module

type
  Plot*[T: SomeNumber] = ref object
    traces* : seq[Trace[T]]
    layout*: Layout

  PlotType* {.pure.} = enum
    Scatter = "scatter"
    ScatterGL = "scattergl"
    Bar = "bar"
    Histogram = "histogram"
    Box = "box"
    HeatMap = "heatmap"
    HeatMapGL = "heatmapgl"
    Candlestick = "candlestick"
    Contour = "contour"

  HistFunc* {.pure.} = enum
    # count is plotly.js default
    Count = "count"
    Sum = "sum"
    Avg = "avg"
    Min = "min"
    Max = "max"

  HistNorm* {.pure.} = enum
    None = ""
    Percent = "percent"
    Probability = "probability"
    Density = "density"
    ProbabilityDensity = "probability density"

  PlotFill* {.pure.} = enum
    Unset = ""
    ToNextY = "tonexty"
    ToZeroY = "tozeroy"

  PlotMode* {.pure.} = enum
    Lines = "lines"
    Markers = "markers"
    LinesMarkers = "lines+markers"

  BarMode* {.pure.} = enum
    Unset = ""
    Stack = "stack"
    Overlay = "overlay"

  BarAlign* {.pure.} = enum
    None,
    Edge,
    Center

  Orientation* {.pure.} = enum
    None = ""
    Vertical = "v"
    Horizontal = "h"

  HoverMode* {.pure.} = enum
    Closest = "closest"
    X = "x"
    Y = "y"
    False = "false"

  PlotSide* {.pure.} = enum
    Unset = ""
    Left = "left"
    Right = "right"

  ColorMap* {.pure.} = enum
    None = ""
    Greys = "Greys"
    YlGnBu = "YlGnBu"
    Greens = "Greens"
    YlOrRd = "YlOrRd"
    Bluered = "Bluered"
    RdBu = "RdBu"
    Reds = "Reds"
    Blues = "Blues"
    Picnic = "Picnic"
    Rainbow = "Rainbow"
    Portland = "Portland"
    Jet = "Jet"
    Hot = "Hot"
    Blackbody = "Blackbody"
    Earth = "Earth"
    Electric = "Electric"
    Viridis = "Viridis"
    Cividis = "Cividis"

  ErrorBarKind* = enum   # different error bar kinds (from constant value, array,...)
    ebkConstantSym,      # constant symmetric error
    ebkConstantAsym,     # constant asymmetric error
    ebkPercentSym,       # symmetric error on percent of value
    ebkPercentAsym,      # asymmetric error on percent of value
    ebkSqrt,             # error based on sqrt of value
    ebkArraySym,         # symmetric error based on array of length data.len
    ebkArrayAsym         # assymmetric error based on array of length data.len

  ErrorBar*[T: SomeNumber] = ref object
    visible*: bool
    color*: Color            # color of bars (including alpha channel)
    thickness*: float        # thickness of bar
    width*: float            # width of bar
    case kind*: ErrorBarKind
    of ebkConstantSym:
      value*: T
    of ebkConstantAsym:
      valueMinus*: T
      valuePlus*: T
    of ebkPercentSym:
      percent*: T
    of ebkPercentAsym:
      percentMinus*: T
      percentPlus*: T
    of ebkSqrt:
      # NOTE: the fact that we technically have not type T in the `ErrorBar` for
      # this variant means we have to hand it to the `newErrorBar` proc manually!
      discard
    of ebkArraySym:
      errors*: seq[T]
    of ebkArrayAsym:
      errorsMinus*: seq[T]
      errorsPlus*: seq[T]

  Marker*[T: SomeNumber] = ref object
    size*: seq[T]
    color*: seq[Color]
    # alternatively use sequence of values defining color based on one of
    # the color maps
    colorVals*: seq[T]
    colormap*: ColorMap

  Trace*[T: SomeNumber] = ref object
    xs*: seq[T]
    ys*: seq[T]
    zs*: seq[seq[T]]
    xs_err*: ErrorBar[T]
    ys_err*: ErrorBar[T]
    marker*: Marker[T]
    text*: seq[string]
    opacity*: float
    mode*: PlotMode
    fill*: PlotFill
    name*: string
    yaxis*: string
    # case on `type`, since we only need ColorMap for
    # PlotType.HeatMap
    case `type`*: PlotType
    of HeatMap, HeatMapGL:
      colormap*: ColorMap
    of Contour:
      colorscale*: ColorMap
      # setting no contours implies `autocontour` true
      contours*: tuple[start, stop, size: float]
      heatmap*: bool
      smoothing*: float
    # case on `type`, since we only need Close,High,Low,Open for
    # PlotType.Candlestick
    of Candlestick:
      open*: seq[T]
      high*: seq[T]
      low*: seq[T]
      close*: seq[T]
    of Histogram:
      histFunc*: HistFunc
      histNorm*: HistNorm
      # TODO: include increasing and decreasing distinction?
      cumulative*: bool
      # if `nBins` is set, the `bins` tuple and `binSize` will be ignored
      nBins*: int
      bins*: tuple[start, stop: float]
      # `binSize` is optional, even if `bins` is given.
      binSize*: float
    of Bar:
      # manually set bin width via scalar
      width*: T
      # or seq (widths.len == xs.len), overwritten by `width`
      widths*: seq[T]
      # calculate bin widths automaticlly to leave no space between
      # overwritten by `width`, `widths`
      autoWidth*: bool
      # align bins left or center (default)
      align*: BarAlign
      # orientation of bars, vertical or horizontal
      orientation*: Orientation
    else:
      discard

  Font* = ref object
    family*: string
    size*: int
    color*: Color

  RangeSlider* = ref object
    visible*: bool

  Axis* = ref object
    title*: string
    font*: Font
    domain*: seq[float64]
    side*: PlotSide
    rangeslider*: RangeSlider
    # setting no range implies plotly's `autorange` true
    range*: tuple[start, stop: float]
    # oposite of showticklabels
    hideticklabels*: bool

  Annotation* = ref object
    x*: float
    xshift*: float
    y*: float
    yshift*: float
    text*: string
    showarrow*: bool

  Layout* = ref object
    title*: string
    width*: int
    height*: int
    hovermode*: HoverMode
    annotations*: seq[Annotation]
    autosize*: bool
    showlegend*: bool
    xaxis*: Axis
    yaxis*: Axis
    yaxis2*: Axis
    barmode*: BarMode
