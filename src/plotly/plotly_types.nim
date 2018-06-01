import chroma

# this module contains all types used in the plotly module

type
  PlotType* {.pure.} = enum
    Scatter = "scatter"
    ScatterGL = "scattergl"
    Bar = "bar"
    Histogram = "histogram"
    Box = "box"
    HeatMap = "heatmap"
    HeatMapGL = "heatmapgl"
    Candlestick = "candlestick"

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
    # case on `type`, since we only need Close,High,Low,Open for
    # PlotType.Candlestick
    of Candlestick:
      open*: seq[T]
      high*: seq[T]
      low*: seq[T]
      close*: seq[T]
    else:
      discard

  Font* = ref object
    family*: string
    size*: int
    color*: Color

  Axis* = ref object
    title*: string
    font*: Font
    domain*: seq[float64]
    side*: PlotSide

  Layout* = ref object
    title*: string
    width*: int
    height*: int
    hovermode*: HoverMode
    autosize*: bool
    showlegend*: bool
    xaxis*: Axis
    yaxis*: Axis
    yaxis2*: Axis
    barmode*: BarMode
