import plotly
import chroma
import jsffi
import dom
import json
import sequtils, strutils

proc animate*(p: Plot) =
    let
      # call `json` for each element of `Plot.traces`
      jsons = mapIt(p.traces, it.json(as_pretty = false))
      #data_string = mapIt(jsons, toJs(it))
      data_string = parseJsonToJs("[" & join(jsons, ",") & "]")
      #layout_Js = toJs("[" & pretty(% p.layout) & "]")
      layout_Js = parseJsonToJs(pretty(% p.layout))

    # create a new `Plotly` object
    let plotly = newPlotly()
    plotly.newPlot("lineplot", data_string, layout_Js)#jss)
    var i = 0
    proc doAgain() =
      let layout = layout_Js
      #document.write("i is " & $i)
      let data_new = @[1, 2, 1, 9, i]
      var tr = p.traces[0]
      tr.ys = data_new
      var pnew = p
      pnew.traces[0] = tr
      let
        jnew = mapIt(pnew.traces, it.json(as_pretty = false))
        dnew = parseJsonToJs("[" & join(jnew, ",") & "]")

      plotly.react("lineplot", dnew, layout)
      inc i

    # using setInterval we update the plot every 100ms with an increased last datapoint
    discard window.setInterval(doAgain, 100)

when isMainModule:
  const colors = @[Color(r:0.9, g:0.4, b:0.0, a: 1.0),
                   Color(r:0.9, g:0.4, b:0.2, a: 1.0),
                   Color(r:0.2, g:0.9, b:0.2, a: 1.0),
                   Color(r:0.1, g:0.7, b:0.1, a: 1.0),
                   Color(r:0.0, g:0.5, b:0.1, a: 1.0)]
  let
    d = Trace[int](mode: PlotMode.LinesMarkers, `type`: PlotType.Scatter)
    size = @[16.int]
  d.marker = Marker[int](size: size, color: colors)
  d.xs = @[1, 2, 3, 4, 5]
  d.ys = @[1, 2, 1, 9, 5]

  let
    layout = Layout(title: "Interactive plot using Plotly.react with JS backend", width: 1200, height: 400,
                    xaxis: Axis(title:"my x-axis"),
                    yaxis: Axis(title: "y-axis too"),
                    autosize: false)
    p = Plot[int](layout: layout, traces: @[d])

  p.animate()
