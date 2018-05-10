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

  Marker*[T: SomeNumber] = ref object
    size*: seq[T]
    color*: seq[Color]

  Trace*[T: SomeNumber] = ref object
    xs*: seq[T]
    ys*: seq[T]
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

proc empty(c:Color): bool =
  # TODO: this is also black, but should never need black with alpha == 0
  return c.r == 0 and c.g == 0 and c.b == 0 and c.a == 0

proc `%`*(c:Color): string =
  return c.toHtmlHex()

proc `%`*(f:Font): JsonNode =
  var fields = initOrderedTable[string, JsonNode](4)
  if f.size != 0:
    fields["size"] = % f.size
  if f.color.empty:
    fields["color"] = % f.color.toHtmlHex()
  if f.family != nil and f.family != "":
    fields["family"] = % f.family
  result = JsonNode(kind:Jobject, fields:  fields)

proc `%`*(a:Axis): JsonNode =
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

proc `%`*(l:Layout): JsonNode =
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

proc toHtmlHex(colors: seq[Color]): seq[string] =
  result = new_seq[string](len(colors))
  for i, c in colors:
    result[i] = c.toHtmlHex

proc `%`*(t: Trace): JsonNode =
  var fields = initOrderedTable[string, JsonNode](8)
  if t.xs == nil or t.xs.len == 0:
    if t.text != nil:
      fields["x"] = % t.text
  else:
    fields["x"] = % t.xs
  if t.yaxis != "":
    fields["yaxis"] = % t.yaxis
  fields["y"] = % t.ys
  fields["mode"] = % t.mode
  fields["type"] = % t.`type`
  if t.name != nil:
    fields["name"] = % t.name
  if t.text != nil:
    fields["text"] = % t.text
  if t.marker != nil:
    fields["marker"] = % t.marker
  result = JsonNode(kind:Jobject, fields:  fields)

proc `%`*(m: Marker): JsonNode =
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

proc `$`*(d:Trace): string =
  var j = % d
  return $j

proc json*(d:Trace, as_pretty=true): string =
  var j = % d
  if as_pretty:
    return pretty(j)
  return $d
