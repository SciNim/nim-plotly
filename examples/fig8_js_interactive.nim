import plotly
import chroma
import jsffi
import dom
import json
import sequtils, strutils

# compile this file with
# nim js fig8_js_javascript.nim
# and then open the `index_javascript.html` with a browser

proc animate*(p: Plot) =
    let
      # create JsObjects from data and layout
      data = parseJsonToJs(parseTraces(p.traces))
      layout = parseJsonToJs($(% p.layout))

    # create a new `Plotly` object
    let plotly = newPlotly()
    plotly.newPlot("lineplot", data, layout)
    var i = 0
    proc loop() =
      # update the data we plot
      let update = @[1, 2, 1, 9, i]
      # get first Trace and set new data
      p.traces[0].ys = update
      let dataNew = parseJsonToJs(parseTraces(p.traces))
      # using react we update the plot contained in the `lineplot` div of
      # the index_javascript.html
      plotly.react("lineplot", dataNew, layout)
      inc i

    # using setInterval we update the plot every 100ms with an increased last datapoint
    discard window.setInterval(loop, 100)

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
