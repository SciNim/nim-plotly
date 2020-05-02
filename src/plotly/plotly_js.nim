import jsbind
import jsffi
import dom
import plotly_types
import api
# defines some functions and types used for the JS target. In this case
# we call the plotly.js functions directly.

type PlotlyObj = ref object of JsObject
# create a new plotly object
proc newPlotly*(): PlotlyObj {.jsimportgWithName: "function(){return (Plotly)}" .}
proc newPlot*(p: PlotlyObj; divname: cstring; data: JsObject; layout: JsObject) {.jsimport.}
# `react` has the same signature as `newPlot` but is used to quickly update a given
# plot
proc react*(p: PlotlyObj; divname: cstring; data: JsObject; layout: JsObject) {.jsimport.}
proc restyle*(p: PlotlyObj; divname: cstring, update: JsObject) {.jsimport.}
# parseJsonToJs is used to parse stringified JSON to a `JsObject`.
# NOTE: in principle there is `toJs` in the jsffi module, but that
# seems to behave differently
proc parseJsonToJs*(json: cstring): JsObject {.jsimportgWithName: "JSON.parse".}

proc parseTraces*[T](traces: seq[Trace[T]]): string =
  ## parses the traces of a Plot object to strings suitable for
  ## plotly by creating a JsonNode and converting to string repr
  result.toUgly(% traces)
