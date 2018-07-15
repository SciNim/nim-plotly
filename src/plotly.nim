when not defined(js):
  # not available on JS backend
  import os

import strutils
import json
import chroma
import sequtils

# we now import the plotly modules and export them so that
# the user sees them as a single module
import plotly/api
export api
import plotly/plotly_types
export plotly_types
import plotly/errorbar
export errorbar
when not defined(js):
  import browsers
  include plotly/tmpl_html
  import plotly/image_retrieve
  import threadpool
else:
  import plotly/plotly_js
  export plotly_js

type
  Plot*[T:SomeNumber] = ref object
    traces* : seq[Trace[T]]
    layout*: Layout

proc newPlot*(xlabel = "", ylabel = "", title = ""): Plot[float64] =
  ## create a plot with sane default layout.
  result = Plot[float64]()
  result.traces = newSeq[Trace[float64]]()
  result.layout = Layout(title: title, width: 600, height: 600,
                         xaxis: Axis(title: xlabel),
                         yaxis: Axis(title: ylabel),
                         autosize: false)

proc add*[T](p: Plot, d: Trace[T]) =
  ## add a new data set to a plot.
  if p.traces == nil:
    p.traces = newSeq[Trace[float64]]()
  p.traces.add(d)

proc parseTraces*[T](traces: seq[Trace[T]]): string =
  ## parses the traces of a Plot object to strings suitable
  ## for plotly by concating the json representations
  let
    # call `json` for each element of `Plot.traces`
    jsons = mapIt(traces, it.json(as_pretty = false))
  result = "[" & join(jsons, ",") & "]"

when not defined(js):
  # `show` and `save` are only used for the C target
  proc show*(p: Plot, path = "", html_template = defaultTmplString, filename = "") =
    var path: string
    # if we are handed a filename, the user wants to save the file to disk. Start
    # a websocket server to receive the image data
    # create and run the websocket server
    var thr: Thread[string]
    thr.createThread(listenForImage, filename)

    # wait a short while to make sure the server is up and running
    sleep(100)

    path = p.save(path, html_template, filename)
    browsers.openDefaultBrowser(path)
    sleep(1000)
    removeFile(path)

  proc save*(p: Plot, path = "", html_template = defaultTmplString, filename = ""): string =
    result = path
    if result == "":
      result = "/tmp/x.html"

    let data_string = parseTraces(p.traces)

    var
      slayout = "{}"
      title = ""
    if p.layout != nil:
      slayout = $(%p.layout)
      title = p.layout.title

    # read the HTML template and insert data, layout and title strings
    var s = ""
    if filename.len > 0:
      # prepare save image code
      let filetype = parseImageType(filename)
      let swidth = $p.layout.width
      let sheight = $p.layout.height
      # here we use numbering of elements to replace in template
      # named replacements don't like the characters around
      let imageInject = injectImageCode % [filetype,
                                           filetype,
                                           swidth,
                                           sheight,
                                           filetype,
                                           swidth,
                                           sheight]
      s = html_template % ["data", data_string, "layout", slayout,
                               "title", title, "saveImage", imageInject]
    else:
      s = html_template % ["data", data_string, "layout", slayout,
                               "title", title, "saveImage", ""]
    var
      f: File
    if not open(f, result, fmWrite):
      quit "could not open file for json"
    f.write(s)
    f.close()

  proc saveImage*(p: Plot, filename: string) =
    ## saves the image under the given filename
    ## supported filetypes:
    ## - jpg, png, svg, webp
    p.show(filename = filename)

when isMainModule:
  import math

  let
    # define a few colors
    colors = @[Color(r:0.9, g:0.4, b:0.0, a: 1.0),
               Color(r:0.9, g:0.4, b:0.2, a: 1.0),
               Color(r:0.2, g:0.9, b:0.2, a: 1.0),
               Color(r:0.1, g:0.7, b:0.1, a: 1.0),
               Color(r:0.0, g:0.5, b:0.1, a: 1.0)]
    d = Trace[int](mode: PlotMode.LinesMarkers, `type`: PlotType.Scatter)
    size = @[16.int]
    m = Marker[int](size: size, color: colors)
  # assign fields of `Trace` object
  d.marker = m
  d.xs = @[1, 2, 3, 4, 5]
  d.ys = @[1, 2, 1, 9, 5]
  d.text = @["hello", "data-point", "third", "highest", "<b>bold</b>"]

  let
    layout = Layout(title: "testing", width: 1200, height: 400,
                    xaxis: Axis(title:"my x-axis"),
                    yaxis:Axis(title: "y-axis too"),
                    autosize:false)
    p = Plot[int](layout: layout, traces: @[d])
  echo p.save()
  p.show()

  block:

    const
      n = 70
      color_choice = @[Color(r: 0.9, g: 0.1, b: 0.1, a: 1.0),
                       Color(r: 0.1, g: 0.1, b: 0.9, a: 1.0)]

    var
      y = newSeq[float64](n)
      x = newSeq[float64](n)
      text = newSeq[string](n)
      colors = newSeq[Color](n)
      sizes = newSeq[float64](n)

    for i in 0 .. y.high:
      x[i] = i.float
      y[i] = sin(i.float)
      text[i] = $i & " has the sin value: " & $y[i]
      sizes[i] = float64(10 + (i mod 10))
      if i mod 3 == 0:
        colors[i] = color_choice[0]
      else:
        colors[i] = color_choice[1]
      text[i] = text[i] & "<b>" & colors[i].toHtmlHex() & "</b>"

    let d = Trace[float64](mode: PlotMode.LinesMarkers, `type`: PlotType.ScatterGL,
                           xs: x, ys: y, text: text)
    d.marker = Marker[float64](size: sizes, color: colors)

    let layout = Layout(title: "saw the sin", width: 1200, height: 400,
                        xaxis: Axis(title:"my x-axis"),
                        yaxis: Axis(title: "y-axis too"), autosize: false)
    Plot[float64](layout: layout, traces: @[d]).show()

  block:
    const text = @["a", "b", "c", "d"]
    let layout = Layout(title: "nim-plotly bar+scattter chart example", width: 1200, height: 400,
                        xaxis: Axis(title:"category"),
                        yaxis: Axis(title:"value"), autosize:false)

    const
      y = @[25.5'f64, 5, 9, 10.0]
      y2 = @[35.5'f64, 1, 19, 20.0]
      y3 = @[15.5'f64, 41, 29, 30.0]
    let
      # define some `Trace` instances showcasing different styles
      d1 = Trace[float64](mode: PlotMode.LinesMarkers, `type`: PlotType.Bar, ys: y,
                          text: text, name: "first group")
      d2 = Trace[float64](mode: PlotMode.LinesMarkers, `type`: PlotType.Bar, ys: y2,
                          text: text, name: "second group")
      d3 = Trace[float64](mode: PlotMode.LinesMarkers, `type`: PlotType.Bar, ys: y3,
                          text: text, name: "third group")
      d4 = Trace[float64](mode: PlotMode.LinesMarkers, `type`: PlotType.ScatterGL,
                          ys:y3, text: text, name: "scatter")
      d5 = Trace[float64](mode: PlotMode.Markers, `type`: PlotType.ScatterGL, ys:y,
                          text: text, name: "just markers")
    d5.marker = Marker[float64](size: @[25'f64])

    Plot[float64](layout: layout, traces: @[d1, d2, d3, d4, d5]).show()


  block:

    const n = 50
    var y1 = newSeq[float64](n)
    var y2 = newSeq[float64](n)
    var x = newSeq[float64](n)

    for i in 0 .. x.high:
      x[i] = i.float64
      y1[i] = sin(i.float64) * 100
      y2[i] = cos(i.float64) / 100

    let
      t1 = Trace[float64](mode: PlotMode.Lines, `type`: PlotType.Scatter, ys: y1,
                          name: "sin*100")
      t2 = Trace[float64](mode: PlotMode.Lines, `type`: PlotType.Scatter, ys: y2,
                          name: "cos/100", yaxis: "y2")
      layout = Layout(title: "multiple axes in nim plotly", width: 1200, height: 400,
                      xaxis: Axis(title:"x"),
                      yaxis: Axis(title:"sin"),
                      yaxis2: Axis(title:"cos", side: PlotSide.Right), autosize: false)

    Plot[float64](layout: layout, traces: @[t1, t2]).show()
