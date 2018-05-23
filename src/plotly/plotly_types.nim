import chroma

# this module contains all types used in the plotly module

type
  PlotType* {.pure.} = enum
    Scatter = "scatter"
    ScatterGL = "scattergl"
    Bar = "bar"
    Histogram = "histogram"

  PlotMode* {.pure.} = enum
    Lines = "lines"
    Markers = "markers"
    LinesMarkers = "lines+markers"

  BarMode* {.pure.} = enum
    Unset = ""
    Stack = "stack"
    Overlay = "overlay"

  PlotSide* {.pure.} = enum
    Unset = ""
    Left = "left"
    Right = "right"

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
    xs_err*: ErrorBar[T]
    ys_err*: ErrorBar[T]
    marker*: Marker[T]
    text*: seq[string]
    opacity*: float
    mode*: PlotMode
    `type`*: PlotType
    name*: string
    yaxis*: string

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
    autosize*: bool
    showlegend*: bool
    xaxis*: Axis
    yaxis*: Axis
    yaxis2*: Axis
    barmode*: BarMode
