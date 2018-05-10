include plotly/api
import plotly/browser
import os
import strutils
import json
import chroma

type
  Plot*[T:SomeNumber] = ref object
    datas* : seq[Trace[T]]
    layout*: Layout

proc newPlot*(xlabel:string="", ylabel:string="", title:string=""): Plot[float64] =
  ## create a plot with sane default layout.
  result = Plot[float64]()
  result.datas = new_seq[Trace[float64]]()
  result.layout = Layout(title: title, width: 600, height: 600, xaxis: Axis(title:xlabel), yaxis:Axis(title: ylabel), autosize:false)

proc add*[T](p:Plot, d:Trace[T]) =
  ## add a new data set to a plot.
  if p.datas == nil:
    p.datas = new_seq[Trace[float64]]()
  p.datas.add(d)

proc show*(p:Plot, path:string="", html_template:string=currentSourcePath().parentDir / "tmpl.html") =
  var path = p.save(path, html_template)
  browser.open(path)
  removeFile(path)

proc save*(p:Plot, path:string="", html_template:string=currentSourcePath().parentDir / "tmpl.html"): string =
  var ipath = path
  if ipath == "":
    ipath = "/tmp/x.html"
  var jsons = new_seq[string]()
  for d in p.datas:
    jsons.add(d.json(as_pretty=true))
  var data_string = "[" & join(jsons, ",") & "]"
  var s = ($readFile(html_template)) % ["data", data_string, "layout", $(%p.layout), "title", p.layout.title]
  var f:File
  if not open(f, ipath, fmWrite):
    quit "could not open file for json"
  f.write(s)
  f.close()
  return ipath

when isMainModule:
  import math

  var colors = @[Color(r:0.9, g:0.4, b:0.0, a: 1.0),
                 Color(r:0.9, g:0.4, b:0.2, a: 1.0),
                 Color(r:0.2, g:0.9, b:0.2, a: 1.0),
                 Color(r:0.1, g:0.7, b:0.1, a: 1.0),
                 Color(r:0.0, g:0.5, b:0.1, a: 1.0)]
  var d = Trace[int](mode: PlotMode.LinesMarkers, `type`: PlotType.Scatter)
  var size = @[16.int]
  var m = Marker[int](size:size, color: colors)
  d.marker = m
  d.xs = @[1, 2, 3, 4, 5]
  d.ys = @[1, 2, 1, 9, 5]
  d.text = @["hello", "data-point", "third", "highest", "<b>bold</b>"]

  var layout = Layout(title: "testing", width: 1200, height: 400, xaxis: Axis(title:"my x-axis"), yaxis:Axis(title: "y-axis too"), autosize:false)
  #echo $(%layout)
  var p = Plot[int](layout:layout, datas: @[d])
  echo p.save()
  p.show()


  block:

    var n = 70
    var color_choice = @[Color(r:0.9, g:0.1, b:0.1, a:1.0), Color(r:0.1, g:0.1, b:0.9, a:1.0)]
  
    var
      y = new_seq[float64](n)
      x = new_seq[float64](n)
      text = new_seq[string](n)
      colors = new_seq[Color](n)
      sizes = new_seq[float64](n)

    for i in 0..y.high:
      x[i] = i.float
      y[i] = sin(i.float)
      text[i] = $i & " has the sin value: " & $y[i]
      sizes[i] = float64(10 + (i mod 10))
      if i mod 3 == 0:
        colors[i] = color_choice[0]
      else:
        colors[i] = color_choice[1]
      text[i] = text[i] & "<b>" & colors[i].toHtmlHex() & "</b>"

    var d = Trace[float64](mode:PlotMode.LinesMarkers, `type`: PlotType.ScatterGL, xs:x, ys:y, text:text)
    d.marker = Marker[float64](size:sizes, color:colors)
  
    var layout = Layout(title: "saw the sin", width: 1200, height: 400,
                        xaxis: Axis(title:"my x-axis"),
                        yaxis:Axis(title: "y-axis too"), autosize:false)
    Plot[float64](layout:layout, datas: @[d]).show()
  
  block:
    var text = @["a", "b", "c", "d"]
    var layout = Layout(title: "nim-plotly bar+scattter chart example", width: 1200, height: 400,
                        xaxis: Axis(title:"category"),
                        yaxis: Axis(title:"value"), autosize:false)

    var y = @[25.5'f64, 5, 9, 10.0]
    var y2 = @[35.5'f64, 1, 19, 20.0]
    var y3 = @[15.5'f64, 41, 29, 30.0]

    var d1 = Trace[float64](mode:PlotMode.LinesMarkers, `type`: PlotType.Bar, ys:y, text:text, name: "first group")
    var d2 = Trace[float64](mode:PlotMode.LinesMarkers, `type`: PlotType.Bar, ys:y2, text:text, name: "second group")
    var d3 = Trace[float64](mode:PlotMode.LinesMarkers, `type`: PlotType.Bar, ys:y3, text:text, name: "third group")
    var d4 = Trace[float64](mode:PlotMode.LinesMarkers, `type`: PlotType.ScatterGL, ys:y3, text:text, name: "scatter")
    var d5 = Trace[float64](mode:PlotMode.Markers, `type`: PlotType.ScatterGL, ys:y, text:text, name: "just markers")
    d5.marker = Marker[float64](size: @[25'f64])

    Plot[float64](layout:layout, datas: @[d1, d2, d3, d4, d5]).show()


  block:

    const n = 50
    var y1 = new_seq[float64](n)
    var y2 = new_seq[float64](n)
    var x = new_seq[float64](n)

    for i in 0..x.high:
      x[i] = i.float64
      y1[i] = sin(i.float64) * 100
      y2[i] = cos(i.float64) / 100

    var t1 = Trace[float64](mode:PlotMode.Lines, `type`: PlotType.Scatter, ys:y1, name: "sin*100")
    var t2 = Trace[float64](mode:PlotMode.Lines, `type`: PlotType.Scatter, ys:y2, name: "cos/100", yaxis:"y2")
    var layout = Layout(title: "multiple axes in nim plotly", width: 1200, height: 400,
                        xaxis: Axis(title:"x"),
                        yaxis: Axis(title:"sin"),
                        yaxis2: Axis(title:"cos", side:PlotSide.Right), autosize:false)

    Plot[float64](layout:layout, datas: @[t1, t2]).show()

    


