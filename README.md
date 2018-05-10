## nim-plotly: simple plots in nim

this is a relatively minimal version of a plotting library with some functionality
so I can get feedback before proceeding.

This is **not** specifically for the javascript nim target.

Internally, it serializes typed `nim` datastructures to JSON that matches what [plotly](https://plot.ly/javascript/) expects.

## Examples

#### Simple Scatter plot

```Nim
import plotly
import chroma

var colors = @[Color(r:0.9, g:0.4, b:0.0, a: 1.0),
               Color(r:0.9, g:0.4, b:0.2, a: 1.0),
               Color(r:0.2, g:0.9, b:0.2, a: 1.0),
               Color(r:0.1, g:0.7, b:0.1, a: 1.0),
               Color(r:0.0, g:0.5, b:0.1, a: 1.0)]
var d = Trace[int](mode: PlotMode.LinesMarkers, `type`: PlotType.Scatter)
var size = @[16.int]
d.marker =Marker[int](size:size, color: colors)
d.xs = @[1, 2, 3, 4, 5]
d.ys = @[1, 2, 1, 9, 5]
d.text = @["hello", "data-point", "third", "highest", "<b>bold</b>"]

var layout = Layout(title: "testing", width: 1200, height: 400,
                    xaxis: Axis(title:"my x-axis"),
                    yaxis:Axis(title: "y-axis too"), autosize:false)
var p = Plot[int](layout:layout, datas: @[d])
p.show()
```

![simple scatter](https://user-images.githubusercontent.com/1739/39875828-e65293a8-542e-11e8-9b18-12130b8694c3.png)


#### Scatter with custom colors and sizes

[source](https://github.com/brentp/nim-plotly/blob/master/examples/fig2_scatter_colors_sizes.nim)

![sizes and colors](https://user-images.githubusercontent.com/1739/39875826-e641acaa-542e-11e8-9c05-c936c112f36c.png)

#### Multiple plot types

[source](https://github.com/brentp/nim-plotly/blob/master/examples/fig2_scatter_colors_sizes.nim)

![multiple plot types](https://user-images.githubusercontent.com/1739/39875825-e62d5c0a-542e-11e8-83be-cdbfa18cfec9.png)

#### Other examples 

[in examples](https://github.com/brentp/nim-plotly/blob/master/examples/)


## TODO

+ [X] add .show() method to plot which looks for and opens a browser (similar to python webbrowser module)
+ [X] support multiple axes (2 y-axes supported).
+ [ ] experiment with syntax for multiple plots (https://plot.ly/javascript/subplots/ or use separate divs.)
+ [ ] better side-stepping of https://github.com/nim-lang/Nim/issues/7794
+ [ ] convert `%` procs into macros so I don't have to re-write the same code over and over.
+ [ ] more of plotly API
+ [ ] ergonomics / plotting DSL
