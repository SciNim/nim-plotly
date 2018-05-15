import tables
import json
import chroma

type
  PlotType* {.pure.} = enum
    Scatter = "scatter"
    ScatterGL = "scattergl"
    Bar = "bar"

  PlotMode* {.pure.} = enum
    Lines = "lines"
    Markers = "markers"
    LinesMarkers = "lines+markers"

  PlotSide* {.pure.} = enum
    Unset = ""
    Left = "left"
    Right = "right"

  ErrorBarKind = enum   # different error bar kinds (from constant value, array,...)
    ebkConstantSym,      # constant symmetric error
    ebkConstantAsym,     # constant asymmetric error
    ebkPercentSym,       # symmetric error on percent of value
    ebkPercentAsym,      # asymmetric error on percent of value
    ebkSqrt,             # error based on sqrt of value
    ebkArraySym,         # symmetric error based on array of length data.len
    ebkArrayAsym        # assymmetric error based on array of length data.len

  ErrorBar*[T: SomeNumber] = ref object
    visible*: bool
    color*: Color            # color of bars (including alpha channel)
    thickness*: float        # thickness of bar
    width*: float            # width of bar
    case kind: ErrorBarKind
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
    of ebkSqrt: discard
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

func newErrorBar*[T: SomeNumber](err: T, color: Color, thickness = 0.0, width = 0.0, visible = true, percent = false): ErrorBar[T] =
  ## creates an `ErrorBar` object of type `ebkConstantSym` or `ebkPercentSym`, if the `percent` flag
  ## is set to `true`
  # NOTE: there is a lot of visual noise in the creation here... change how?
  if percent == false:
    result = ErrorBar[T](visible: visible, color: color, thickness: thickness, width: width, kind: ebkConstantSym)
    result.value = err
  else:
    result = ErrorBar[T](visible: visible, color: color, thickness: thickness, width: width, kind: ebkPercentSym)
    result.percent = err

func newErrorBar*[T: SomeNumber](err: tuple[p, m: T], color: Color, thickness = 0.0, width = 0.0, visible = true, percent = false): ErrorBar[T] =
  ## creates an `ErrorBar` object of type `ebkConstantAsym`, constant plus and minus errors given as tuple
  ## or `ebkPercentAsym` of `percent` flag is set to true
  if percent == false:
    result = ErrorBar[T](visible: visible, color: color, thickness: thickness, width: width, kind: ebkConstantAsym)
    result.valuePlus  = err.p
    result.valueMinus = err.m
  else:
    result = ErrorBar[T](visible: visible, color: color, thickness: thickness, width: width, kind: ebkPercentAsym)
    result.percentPlus  = err.p
    result.percentMinus = err.m

func newErrorBar*[T: SomeNumber](color: Color, thickness = 0.0, width = 0.0, visible = true): ErrorBar[T] =
  ## creates an `ErrorBar` object of type `ebkSqrt`
  result = ErrorBar[T](visible: visible, color: color, thickness: thickness, width: width, kind: ebkSqrt)

func newErrorBar*[T](err: seq[T], color: Color, thickness = 0.0, width = 0.0, visible = true): ErrorBar[T] =
  ## creates an `ErrorBar` object of type `ebkArraySym`
  result = ErrorBar[T](visible: visible, color: color, thickness: thickness, width: width, kind: ebkArraySym)
  result.errors = err

func newErrorBar*[T: SomeNumber](err: tuple[p, m: seq[T]], color: Color, thickness = 0.0, width = 0.0, visible = true): ErrorBar[T] =
  ## creates an `ErrorBar` object of type `ebkArrayAsym`
  result = ErrorBar[T](visible: visible, color: color, thickness: thickness, width: width, kind: ebkArraySym)
  result.errorsPlus  = err.p
  result.errorsMinus = err.m

func empty(c: Color): bool =
  # TODO: this is also black, but should never need black with alpha == 0
  result = c.r == 0 and c.g == 0 and c.b == 0 and c.a == 0

func `%`*(c: Color): string =
  result = c.toHtmlHex()

func `%`*(f: Font): JsonNode =
  var fields = initOrderedTable[string, JsonNode](4)
  if f.size != 0:
    fields["size"] = % f.size
  if f.color.empty:
    fields["color"] = % f.color.toHtmlHex()
  if f.family != nil and f.family != "":
    fields["family"] = % f.family
  result = JsonNode(kind:Jobject, fields:  fields)

func `%`*(a: Axis): JsonNode =
  var fields = initOrderedTable[string, JsonNode](4)
  if a.title != nil and a.title != "":
    fields["title"] = % a.title
  if a.font != nil:
    fields["titlefont"] = % a.font
  if a.domain != nil:
    fields["domain"] = % a.domain
  if a.side != PlotSide.Unset:
    fields["side"] = % a.side
    fields["overlaying"] = % "y"

  result = JsonNode(kind:Jobject, fields:  fields)

func `%`*(l: Layout): JsonNode =
  var fields = initOrderedTable[string, JsonNode](4)
  if l.title != "":
    fields["title"] = % l.title
  if l.width != 0:
    fields["width"] = % l.width
  if l.height != 0:
    fields["height"] = % l.height
  if l.xaxis != nil:
    fields["xaxis"] = % l.xaxis
  if l.yaxis != nil:
    fields["yaxis"] = % l.yaxis
  if l.yaxis2 != nil:
    fields["yaxis2"] = % l.yaxis2

  result = JsonNode(kind:Jobject, fields:  fields)

func toHtmlHex(colors: seq[Color]): seq[string] =
  result = new_seq[string](len(colors))
  for i, c in colors:
    result[i] = c.toHtmlHex

func `%`*(b: ErrorBar): JsonNode =
  ## creates a JsonNode from an `ErrorBar` object depending on the object variant
  var fields = initOrderedTable[string, JsonNode](4)
  fields["visible"] = % b.visible
  fields["color"] = % b.color.toHtmlHex
  if b.thickness > 0:
    fields["thickness"] = % b.thickness
  if b.width > 0:
    fields["width"] = % b.width
  case b.kind
  of ebkConstantSym:
    fields["symmetric"] = % true
    fields["type"] = % "constant"
    fields["value"] = % b.value
  of ebkConstantAsym:
    fields["symmetric"] = % false
    fields["type"] = % "constant"
    fields["valueminus"] = % b.valueMinus
    fields["value"] = % b.valuePlus
  of ebkPercentSym:
    fields["symmetric"] = % true
    fields["type"] = % "percent"
    fields["value"] = % b.percent
  of ebkPercentAsym:
    fields["symmetric"] = % false
    fields["type"] = % "percent"
    fields["valueminus"] = % b.percentMinus
    fields["value"] = % b.percentPlus
  of ebkSqrt:
    fields["type"] = % "sqrt"
  of ebkArraySym:
    fields["symmetric"] = % true
    fields["type"] = % "data"
    fields["array"] = % b.errors
  of ebkArrayAsym:
    fields["symmetric"] = % false
    fields["type"] = % "data"
    fields["arrayminus"] = % b.errorsMinus
    fields["array"] = % b.errorsPlus
  result = JsonNode(kind: JObject, fields: fields)

func `%`*(t: Trace): JsonNode =
  var fields = initOrderedTable[string, JsonNode](8)
  if t.xs == nil or t.xs.len == 0:
    if t.text != nil:
      fields["x"] = % t.text
  else:
    fields["x"] = % t.xs
  if t.yaxis != "":
    fields["yaxis"] = % t.yaxis
  fields["y"] = % t.ys

  if t.xs_err != nil:
    fields["error_x"] = % t.xs_err
  if t.ys_err != nil:
    fields["error_y"] = % t.ys_err

  fields["mode"] = % t.mode
  fields["type"] = % t.`type`
  if t.name != nil:
    fields["name"] = % t.name
  if t.text != nil:
    fields["text"] = % t.text
  if t.marker != nil:
    fields["marker"] = % t.marker
  result = JsonNode(kind:Jobject, fields: fields)

func `%`*(m: Marker): JsonNode =
  var fields = initOrderedTable[string, JsonNode](8)
  if m.size != nil:
    if m.size.len == 1:
      fields["size"] = % m.size[0]
    else:
      fields["size"] = % m.size
  if m.color != nil:
    if m.color.len == 1:
      fields["color"] = % m.color[0].toHtmlHex()
    else:
      fields["color"] = % m.color.toHtmlHex()
  result = JsonNode(kind:Jobject, fields:  fields)

func `$`*(d: Trace): string =
  var j = % d
  result = $j

func json*(d: Trace, as_pretty=true): string =
  var j = % d
  if as_pretty:
    result = pretty(j)
  result = $d
