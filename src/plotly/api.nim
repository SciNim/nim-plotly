import tables
import json
import chroma
import strformat
import sequtils

# plotly internal modules
import plotly_types
import color
import errorbar

proc toPlotJson*[T](plt: Plot[T]): PlotJson =
  ## converts a given `Plot[T]` object to a `PlotJson` object
  result = new PlotJson
  result.traces = % plt.traces
  result.layout = % plt.layout

func parseHistogramFields[T](fields: var OrderedTable[string, JsonNode], t: Trace[T]) =
  ## parse the fields of the histogram type. Usese a separate proc
  ## for clarity.
  fields["cumulative"] = %* {
    "enabled" : % t.cumulative
  }
  fields["histfunc"] = % t.histFunc
  fields["histnorm"] = % t.histNorm

  # string to store direction of bars, used to assign
  # the fields without explcitily naming 'x' or 'y' fields
  var bars = "x"
  if t.xs.len == 0:
    bars = "y"

  if t.nbins > 0:
    fields[&"nbins{bars}"] = % t.nbins
    # if nbins is set, this provides the maximum number of bins allowed to be
    # calculated by the autobins algorithm
    fields[&"autobin{bars}"] = % true

  elif t.bins.start != t.bins.stop:
    fields[&"{bars}bins"] = %* {
      "start" : % t.bins.start,
      "end" : % t.bins.stop,
      "size" : % t.binSize
    }
    # in case bins are set manually, disable autobins
    fields[&"autobin{bars}"] = % false

func calcBinWidth[T](t: Trace[T]): seq[float] =
  ## returns the correct bin width according to the bin width priority
  ## explained in `setWidthField`.
  ## `xs` may contain `ys.len + 1` elements, i.e. the last right edge of
  ## all bars is given too.
  ## Returns an empty seq, if sequence not needed further
  if t.width.float > 0.0:
    result = repeat(t.width.float, t.ys.len)
  elif t.widths.len > 0:
    when T isnot float:
      result = t.widths.mapIt(it.float)
    else:
      result = t.widths
  elif t.align == BarAlign.Edge or t.autoWidth:
    # have to calculate from `t.xs` bar locations
    result = newSeq[float](t.ys.len)
    for i in 0 ..< t.xs.high:
      result[i] = (t.xs[i+1] - t.xs[i]).float
    if t.xs.len == t.ys.len:
      # duplicate last element
      result[^1] = result[^2]

func setWidthField[T](fields: var OrderedTable[string, JsonNode],
                      t: Trace[T], widths: seq[float] = @[]) =
  ## Bar width priority:
  ## 1. width  <- single value
  ## 2. widths <- sequence of values
  ## 3. autoWidth <- if neither given
  ## If all 3 are empty, let Plotly calculate widths automatically
  if t.width.float > 0.0:
    fields["width"] = % t.width
  elif t.widths.len > 0:
    fields["width"] = % t.widths
  elif t.autoWidth:
    fields["width"] = % widths

func shiftToLeftEdge[T](t: Trace[T], widths: seq[float]): seq[float] =
  ## calculates the new bars if left aligned bars are selected
  # `xs` values represent *left* edge of bins
  result = newSeq[float](t.ys.len)
  for i in 0 .. widths.high:
    result[i] = t.xs[i].float + (widths[i] / 2.0)

func parseBarFields[T](fields: var OrderedTable[string, JsonNode], t: Trace[T]) =
  ## parses the `Trace` fields for the Bar kind
  # calculate width of needed bars
  let widths = calcBinWidth(t)
  fields.setWidthField(t, widths)
  case t.align
  of BarAlign.Edge:
    # need bin width
    fields["x"] = % shiftToLeftEdge(t, widths)
  of BarAlign.Center:
    # given data are bar positions already
    fields["x"] = % t.xs
  else: discard

  case t.orientation
  of Orientation.Vertical, Orientation.Horizontal:
    fields["orientation"] = % t.orientation
  else: discard

func `%`*(c: Color): JsonNode =
  result = % c.toHtmlHex()

func `%`*(f: Font): JsonNode =
  var fields = initOrderedTable[string, JsonNode](4)
  if f.size != 0:
    fields["size"] = % f.size
  if not f.color.isEmpty:
    fields["color"] = % f.color
  if f.family.len > 0:
    fields["family"] = % f.family
  result = JsonNode(kind: JObject, fields: fields)

func `%`*(a: Axis): JsonNode =
  var fields = initOrderedTable[string, JsonNode](4)
  if a.title.len > 0:
    fields["title"] = % a.title
  if a.font != nil:
    fields["titlefont"] = % a.font
  if a.domain.len > 0:
    fields["domain"] = % a.domain
  if a.side != PlotSide.Unset:
    fields["side"] = % a.side
    fields["overlaying"] = % "y"
  if a.hideticklabels:
    fields["showticklabels"] = % false
  if a.ty != AxisType.Default:
    fields["type"] = % a.ty

  if a.range.start != a.range.stop:
    fields["autorange"] = % false
    # range is given as an array of two elements, start and stop
    fields["range"] = % [a.range.start, a.range.stop]
  else:
    fields["autorange"] = % true

  if a.rangeslider != nil:
    fields["rangeslider"] = % a.rangeslider

  if not a.gridColor.isEmpty:
    fields["gridcolor"] = % a.gridColor
  if a.gridWidth != 0:
    fields["gridwidth"] = % a.gridWidth

  result = JsonNode(kind: JObject, fields: fields)

func `%`*(l: Legend): JsonNode =
  var fields = initOrderedTable[string, JsonNode](4)
  if l.font != nil:
    fields["font"] = % l.font
  if not l.backgroundColor.isEmpty:
    fields["bgcolor"] = % l.backgroundColor
  if not l.bordercolor.isEmpty:
    fields["bordercolor"] = % l.borderColor
  if l.borderwidth != 0:
    fields["borderwidth"] = % l.borderWidth
  case l.orientation
  of Orientation.Vertical, Orientation.Horizontal:
    fields["orientation"] = % l.orientation
  else: discard
  # fields for x and y are used always. Zero initialized means that if no
  # x, y given, but colors / width set, location will be at x / y == 0 / 0
  # alternative would be to check for != 0 on both, which would disallow 0 / 0!
  fields["x"] = % l.x
  fields["y"] = % l.y
  result = JsonNode(kind: JObject, fields: fields)

func `%`*(l: Layout): JsonNode =
  var fields = initOrderedTable[string, JsonNode](4)
  if l == nil:
    return JsonNode(kind: JObject, fields: fields)
  if l.title != "":
    fields["title"] = % l.title
  if l.width != 0:
    fields["width"] = % l.width
  if l.font != nil:
    fields["font"] = % l.font
  if l.height != 0:
    fields["height"] = % l.height
  if l.xaxis != nil:
    fields["xaxis"] = % l.xaxis
  if l.yaxis != nil:
    fields["yaxis"] = % l.yaxis
  if l.yaxis2 != nil:
    fields["yaxis2"] = % l.yaxis2
  if $l.barmode != "":
    fields["barmode"] = % l.barmode
  if l.legend != nil:
    fields["legend"] = % l.legend
    fields["showlegend"] = % l.showlegend
  # default to closest because other modes suck.
  fields["hovermode"] = % "closest"
  if $l.hovermode != "":
    fields["hovermode"] = % l.hovermode
  if 0 < l.annotations.len:
    fields["annotations"] = % l.annotations
  if not l.backgroundColor.isEmpty:
    fields["plot_bgcolor"] = % l.backgroundColor
  if not l.paperColor.isEmpty:
    fields["paper_bgcolor"] = % l.paperColor

  result = JsonNode(kind: JObject, fields: fields)

func `%`*(a: Annotation): JsonNode =
  ## creates a JsonNode from an `Annotations` object depending on the object variant
  result = %[ ("x", %a.x)
            , ("xshift", %a.xshift)
            , ("y", %a.y)
            , ("yshift", %a.yshift)
            , ("text", %a.text)
            , ("showarrow", %a.showarrow)
            ]

func `%`*(b: ErrorBar): JsonNode =
  ## creates a JsonNode from an `ErrorBar` object depending on the object variant
  var fields = initOrderedTable[string, JsonNode](4)
  fields["visible"] = % b.visible
  if not b.color.isEmpty:
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
  if t.xs.len == 0:
    if t.text.len > 0 and t.`type` != PlotType.Histogram:
      fields["x"] = % t.text
  else:
    fields["x"] = % t.xs

  if t.ys.len > 0:
    fields["y"] = % t.ys

  if t.xaxis != "":
    fields["xaxis"] = % t.xaxis

  if t.yaxis != "":
    fields["yaxis"] = % t.yaxis

  if t.opacity != 0:
    fields["opacity"] = % t.opacity

  if $t.fill != "":
    fields["fill"] = % t.fill

  # now check variant object to fill correct fields
  case t.`type`
  of PlotType.HeatMap, PlotType.HeatMapGL:
    # heatmap stores data in z only
    if t.zs.len > 0:
      fields["z"] = % t.zs

    fields["colorscale"] = % t.colormap
  of PlotType.Contour:
    if t.zs.len > 0: fields["z"] = % t.zs
    fields["colorscale"] = % t.colorscale
    if t.contours.start != t.contours.stop:
      fields["autocontour"] = % false
      fields["contours"] = %* {
        "start" : % t.contours.start,
        "end" : % t.contours.stop,
        "size" : % t.contours.size
      }
    else:
      fields["autocontour"] = % true
      fields["contours"] = %* {}
    if t.heatmap:
      fields["contours"]["coloring"] = % "heatmap"
    if t.smoothing > 0:
      fields["line"] = %* {
        "smoothing": % t.smoothing
      }
  of PlotType.Candlestick:
    fields["open"] = % t.open
    fields["high"] = % t.high
    fields["low"] = % t.low
    fields["close"] = % t.close
  of PlotType.Histogram:
    fields.parseHistogramFields(t)
  of PlotType.Bar:
    # if `xs` not given, user wants `string` named bars
    if t.xs.len > 0:
      fields.parseBarFields(t)
  of PlotType.Scatter, PlotType.ScatterGL:
    if t.lineWidth > 0:
      fields["line"] = %* {"width": t.lineWidth}
  else:
    discard

  if t.xs_err != nil:
    fields["error_x"] = % t.xs_err
  if t.ys_err != nil:
    fields["error_y"] = % t.ys_err

  fields["mode"] = % t.mode
  fields["type"] = % t.`type`
  if t.name.len > 0:
    fields["name"] = % t.name
  if t.text.len > 0:
    fields["text"] = % t.text
  if t.marker != nil:
    fields["marker"] = % t.marker

  result = JsonNode(kind: JObject, fields: fields)

func `%`*(m: Marker): JsonNode =
  var fields = initOrderedTable[string, JsonNode](8)
  if m.size.len > 0:
    if m.size.len == 1:
      fields["size"] = % m.size[0]
    else:
      fields["size"] = % m.size
  if m.color.len > 0:
    if m.color.len == 1:
      fields["color"] = % m.color[0]
    else:
      fields["color"] = % m.color
  elif m.colorVals.len > 0:
    fields["color"] = % m.colorVals
    fields["colorscale"] = % m.colormap
    fields["showscale"] = % true

  result = JsonNode(kind: JObject, fields: fields)

func `$`*(d: Trace): string =
  var j = % d
  result = $j

func json*(d: Trace, as_pretty=false): string =
  var j = % d
  if as_pretty:
    result = pretty(j)
  else:
    result = $d
