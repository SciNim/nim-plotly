import ../../src/plotly
import ../../src/plotly/color
import chroma
import unittest
import json, sequtils
import random

suite "Miscellaneous":
  test "Color checks":
    let c = empty()
    check c.isEmpty
  test "Default AxisType":
    var ty: AxisType
    check ty == AxisType.Default

suite "API serialization":
  test "Color":
    let
      c1 = % color(1.0, 1.0, 1.0)
      c2 = % color(0.5, 0.5, 0.5)
      c3 = % empty()
    check c1 == % "#FFFFFF"
    check c2 == % "#7F7F7F"
    check c3 == % "#000000"

  test "Marker":
    test "make Markers, scalar size":
      let
        mk = Marker[float](size: @[1.0])
        expected = %*{ "size": 1.0 }
      let r = %mk
      check r == expected

    test "make Markers, seq of sizes":
      let
        mk = Marker[float](size: @[1.0, 2.0, 3.0])
        expected = %*{ "size": [1.0, 2.0, 3.0] }
      let r = %mk
      check r == expected

    test "make Markers, scalar color":
      let
        mk = Marker[float](size: @[1.0],
                           color: @[color(0.5, 0.5, 0.5)])
        expected = %*{ "size": 1.0,
                       "color" : "#7F7F7F"
                     }
      let r = %mk
      check r == expected

    test "make Markers, seq of colors":
      let
        mk = Marker[float](size: @[1.0],
                           color: @[color(0.5, 0.5, 0.5), color(1.0, 1.0, 1.0), empty()])
        expected = %*{ "size": 1.0,
                       "color" : ["#7F7F7F", "#FFFFFF", "#000000"]
                     }
      let r = %mk
      check r == expected

    test "make Markers, seq of color based on values; no color map":
      let
        mk = Marker[float](size: @[1.0],
                           colorVals: @[0.25, 0.5, 0.75, 1.0])
        expected = %*{ "size": 1.0,
                       "color" : [0.25, 0.5, 0.75, 1.0],
                       "colorscale" : "",
                       "showscale" : true
                     }
      let r = %mk
      check r == expected

    test "make Markers, seq of color based on values; w/ color map":
      let
        mk = Marker[float](size: @[1.0],
                           colorVals: @[0.25, 0.5, 0.75, 1.0],
                           colormap: ColorMap.Viridis
        )
        expected = %*{ "size": 1.0,
                       "color" : [0.25, 0.5, 0.75, 1.0],
                       "colorscale" : "Viridis",
                       "showscale" : true
                     }
      let r = %mk
      check r == expected

    test "make Markers, color takes precedent over colorVals":
      let
        mk = Marker[float](size: @[1.0],
                           color: @[color(0.5, 0.5, 0.5)],
                           colorVals: @[0.25, 0.5, 0.75, 1.0],
                           colormap: ColorMap.Viridis
        )
        expected = %*{ "size": 1.0,
                       "color" : "#7F7F7F"
                     }
      let r = %mk
      check r == expected

  test "ErrorBar":
    test "make ConstantSym ErrorBar, manual":
      let
        eb = ErrorBar[float](visible: true,
                             color: color(0.0, 1.0, 1.0),
                             thickness: 1.0,
                             width: 1.0,
                             kind: ErrorBarKind.ebkConstantSym,
                             value: 2.0)
        expected = %*{ "visible": true,
                       "color": "#00FFFF",
                       "thickness": 1.0,
                       "width" : 1.0,
                       "symmetric" : true,
                       "type": "constant",
                       "value": 2.0
                    }
      let r = %eb
      check r == expected
    test "make ConstantSym ErrorBar, newErrorBar":
      let
        eb = newErrorBar[float](2.0) # fields not given won't be serialized
        expected = %*{ "visible": true,
                       "symmetric" : true,
                       "type": "constant",
                       "value": 2.0
                    }
      let r = %eb
      check r == expected

    test "make PercentSym ErrorBar, manual":
      let
        eb = ErrorBar[float](visible: true,
                             color: color(0.0, 1.0, 1.0),
                             thickness: 1.0,
                             width: 1.0,
                             kind: ErrorBarKind.ebkPercentSym,
                             percent: 5.0)
        expected = %*{ "visible": true,
                       "color": "#00FFFF",
                       "thickness": 1.0,
                       "width" : 1.0,
                       "symmetric" : true,
                       "type": "percent",
                       "value": 5.0
                    }
      let r = %eb
      check r == expected

    test "make PercentSym ErrorBar, newErrorBar":
      let
        eb = newErrorBar[float](2.0, percent = true) # fields not given won't be serialized
        expected = %*{ "visible": true,
                       "symmetric" : true,
                       "type": "percent",
                       "value": 2.0
                    }
      let r = %eb
      check r == expected

    test "make ConstantAsym ErrorBar, manual":
      let
        eb = ErrorBar[float](visible: true,
                             color: color(0.0, 1.0, 1.0),
                             thickness: 1.0,
                             width: 1.0,
                             kind: ErrorBarKind.ebkConstantAsym,
                             valuePlus: 2.0,
                             valueMinus: 1.0)
        expected = %*{ "visible": true,
                       "color": "#00FFFF",
                       "thickness": 1.0,
                       "width" : 1.0,
                       "symmetric" : false,
                       "type": "constant",
                       "value": 2.0,
                       "valueminus" : 1.0
                    }
      let r = %eb
      check r == expected
    test "make ConstantAsym ErrorBar, newErrorBar":
      let
        eb = newErrorBar[float]((m: 1.0, p: 2.0)) # fields not given won't be serialized
        expected = %*{ "visible": true,
                       "symmetric" : false,
                       "type": "constant",
                       "value": 2.0,
                       "valueminus" : 1.0
                    }
      let r = %eb
      check r == expected

    test "make PercentAsym ErrorBar, manual":
      let
        eb = ErrorBar[float](visible: true,
                             color: color(0.0, 1.0, 1.0),
                             thickness: 1.0,
                             width: 1.0,
                             kind: ErrorBarKind.ebkPercentAsym,
                             percentPlus: 2.0,
                             percentMinus: 1.0)
        expected = %*{ "visible": true,
                       "color": "#00FFFF",
                       "thickness": 1.0,
                       "width" : 1.0,
                       "symmetric" : false,
                       "type": "percent",
                       "value": 2.0,
                       "valueminus" : 1.0
                    }
      let r = %eb
      check r == expected
    test "make ConstantAsym ErrorBar, newErrorBar":
      let
        eb = newErrorBar[float]((m: 1.0, p: 2.0), percent = true) # fields not given won't be serialized
        expected = %*{ "visible": true,
                       "symmetric" : false,
                       "type": "percent",
                       "value": 2.0,
                       "valueminus" : 1.0
                    }
      let r = %eb
      check r == expected

    test "make Sqrt ErrorBar, manual":
      let
        eb = ErrorBar[float](visible: true,
                             color: color(0.0, 1.0, 1.0),
                             thickness: 1.0,
                             width: 1.0,
                             kind: ErrorBarKind.ebkSqrt)
        expected = %*{ "visible": true,
                       "color": "#00FFFF",
                       "thickness": 1.0,
                       "width" : 1.0,
                       "type": "sqrt",
                    }
      let r = %eb
      check r == expected
    test "make Sqrt ErrorBar, newErrorBar":
      let
        eb = newErrorBar[float]() # TODO: this proc should really be renamed!
        expected = %*{ "visible": true,
                       "type": "sqrt",
                    }
      let r = %eb
      check r == expected

    test "make ArraySym ErrorBar, manual":
      let
        eb = ErrorBar[float](visible: true,
                             color: color(0.0, 1.0, 1.0),
                             thickness: 1.0,
                             width: 1.0,
                             kind: ErrorBarKind.ebkArraySym,
                             errors: @[1.0, 2.0, 3.0])
        expected = %*{ "visible": true,
                       "color": "#00FFFF",
                       "thickness": 1.0,
                       "width" : 1.0,
                       "symmetric": true,
                       "type": "data",
                       "array" : [1.0, 2.0, 3.0]
                    }
      let r = %eb
      check r == expected
    test "make ArraySym ErrorBar, newErrorBar":
      let
        eb = newErrorBar[float](@[1.0, 2.0, 3.0]) # TODO: this proc should really be renamed!
        expected = %*{ "visible": true,
                       "symmetric": true,
                       "type": "data",
                       "array": [1.0, 2.0, 3.0]
                    }
      let r = %eb
      check r == expected

    test "make ArrayAsym ErrorBar, manual":
      let
        eb = ErrorBar[float](visible: true,
                             color: color(0.0, 1.0, 1.0),
                             thickness: 1.0,
                             width: 1.0,
                             kind: ErrorBarKind.ebkArrayAsym,
                             errorsPlus: @[1.0, 2.0, 3.0],
                             errorsMinus: @[2.0, 3.0, 4.0])
        expected = %*{ "visible": true,
                       "color": "#00FFFF",
                       "thickness": 1.0,
                       "width" : 1.0,
                       "symmetric": false,
                       "type": "data",
                       "array" : [1.0, 2.0, 3.0],
                       "arrayminus" : [2.0, 3.0, 4.0]
                    }
      let r = %eb
      check r == expected
    test "make ArrayAsym ErrorBar, newErrorBar":
      let
        eb = newErrorBar[float]((m: @[2.0, 3.0, 4.0], p: @[1.0, 2.0, 3.0]))
        expected = %*{ "visible": true,
                       "symmetric": false,
                       "type": "data",
                       "array": [1.0, 2.0, 3.0],
                       "arrayminus": [2.0, 3.0, 4.0]
                    }
      let r = %eb
      check r == expected

  test "Annotation":
    test "make Json object":
      let
        a = Annotation(x:1, xshift:10, y:2, yshift:20, text:"text")
        expected = %*{ "x": 1.0
                    , "xshift": 10.0
                    , "y": 2.0
                    , "yshift": 20.0
                    , "text": "text"
                    , "showarrow": false
                    }
      let r = %a
      check r == expected
    test "make Json object less parameters":
      let
        a = Annotation(x:1,y:2,text:"text")
        expected = %*{ "x": 1.0
                    , "xshift": 0.0
                    , "y": 2.0
                    , "yshift": 0.0
                    , "text": "text"
                    , "showarrow": false
                    }
      let r = %a
      check r == expected

  test "Layout":
    test "Layout with Annotations":
      let
        a = Annotation(x:1, xshift:10, y:2, yshift:20, text:"text")
        layout = Layout(title: "title", width: 10, height: 10,
                        xaxis: Axis(title: "x"),
                        yaxis: Axis(title: "y"),
                        annotations: @[a],
                        autosize: true)
        expected = %*{ "title": "title"
                     , "width": 10
                     , "height": 10
                     , "xaxis": { "title": "x"
                                , "autorange": true
                                }
                     , "yaxis": { "title": "y"
                                , "autorange": true
                                }
                     , "hovermode": "closest"
                     , "annotations": [ { "x": 1.0
                                        , "xshift": 10.0
                                        , "y": 2.0
                                        , "yshift": 20.0
                                        , "text": "text"
                                        , "showarrow": false
                                        }
                                      ]
                     }
      let r = %layout
      check r == expected
    test "Layout without Annotations":
      let
        layout = Layout(title: "title", width: 10, height: 10,
                        xaxis: Axis(title: "x"),
                        yaxis: Axis(title: "y"),
                        autosize: true)
        expected = %*{ "title": "title"
                     , "width": 10
                     , "height": 10
                     , "xaxis": { "title": "x"
                                , "autorange": true
                                }
                     , "yaxis": { "title": "y"
                                , "autorange": true
                                }
                     , "hovermode": "closest"
                     }
      let r = %layout
      check r == expected
    test "Layout with log axis":
      let
        a = Annotation(x:1, xshift:10, y:2, yshift:20, text:"text")
        layout = Layout(title: "title", width: 10, height: 10,
                        xaxis: Axis(title: "x"),
                        yaxis: Axis(title: "y", ty: AxisType.Log),
                        annotations: @[a],
                        autosize: true)
        expected = %*{ "title": "title"
                      , "width": 10
                      , "height": 10
                      , "xaxis": { "title": "x"
                                , "autorange": true
                                }
                      , "yaxis": { "title": "y"
                                , "type": "log"
                                , "autorange": true
                                }
                      , "hovermode": "closest"
                      , "annotations": [ { "x": 1.0
                                        , "xshift": 10.0
                                        , "y": 2.0
                                        , "yshift": 20.0
                                        , "text": "text"
                                        , "showarrow": false
                                        }
                                      ]
                      }
      let r = %layout
      check r == expected

suite "Sugar":
  test "Custom colormap comparisons":
    var data = newSeqWith(1, newSeq[float](1))
    data[0][0] = 1.5
    let d = Trace[float](mode: PlotMode.Lines, `type`: PlotType.HeatMap)
    d.zs = data
    proc customHeatmap(name: PredefinedCustomMaps): Plot[float] =
      d.customColormap = getCustomMap(name)
      d.colorMap = Custom
      let
        layout = Layout(title: $name, width: 800, height: 800,
                        xaxis: Axis(title: "x"),
                        yaxis: Axis(title: "y"), autosize: false)
      result = Plot[float](layout: layout, traces: @[d])
    proc customSugar(name: PredefinedCustomMaps): Plot[float] =
      result = heatmap(data)
        .title($name)
        .width(800)
        .height(800)
        .colormap(name)

    for map in PredefinedCustomMaps:
      let m1 = customHeatmap(map)
      let m2 = customSugar(map)
      check m1.layout.width == m2.layout.width
      check m1.layout.height == m2.layout.height
      check m1.layout.xaxis.title == m2.layout.xaxis.title
      check m1.layout.yaxis.title == m2.layout.yaxis.title
      check m1.traces[0].`type` == m1.traces[0].`type`
      check m1.traces[0].colormap == m1.traces[0].colormap
      check m1.traces[0].customColormap == m1.traces[0].customColormap
      check m1.traces[0].zs == data
      check m1.traces[0].zs == m2.traces[0].zs
      check m1.traces[0].customColormap.name == $map
      check m2.traces[0].customColormap.name == $map

  test "Limit colormap range":
    var data = newSeqWith(28, newSeq[float](28))
    for x in 0 ..< 28:
      for y in 0 ..< 28:
        data[x][y] = max(rand(30.0), 0.1)
    let
      layout = Layout()
    block:
      let d = Trace[float](mode: PlotMode.Lines, `type`: PlotType.HeatMap,
                           zmin: 0.0, zmax: 10.0,
                           zs: data)
      let plt = Plot[float](layout: layout, traces: @[d])
      let pltJson = % plt
      check pltJson["traces"][0]["zmin"] == % 0.0
      check pltJson["traces"][0]["zmax"] == % 10.0
      check pltJson["traces"][0]["zauto"] == % false
    block:
      let d = Trace[float](mode: PlotMode.Lines, `type`: PlotType.HeatMap,
                           zs: data)
      let plt = Plot[float](layout: layout, traces: @[d])
      let pltJson = % plt
      check not hasKey(pltJson["traces"][0], "zmin")
      check not hasKey(pltJson["traces"][0], "zmax")
      check not hasKey(pltJson["traces"][0], "zauto")

    block:
      let pltJson = % heatmap(data)
        .zmin(0.0)
        .zmax(10.0)
      check pltJson["traces"][0]["zmin"] == % 0.0
      check pltJson["traces"][0]["zmax"] == % 10.0
      check pltJson["traces"][0]["zauto"] == % false

suite "show w/ filename without threads fails compilation":
  template compileFails(body: untyped): untyped =
    when not compiles(body):
      true
    else:
      false

  let xs = toSeq(0 ..< 100).mapIt(it.float)
  let ys = xs.mapIt(it * it * it)
  let layout = Layout()
  let d = Trace[float](mode: PlotMode.Lines, `type`: PlotType.Scatter,
                       xs: xs, ys: ys)
  let plt = Plot[float](layout: layout, traces: @[d])

  ## NOTE: the following tests assume the test is compiled without `--threads:on`!
  test "Plot - saveImage fails":
    check compileFails(plt.saveImage("test.svg"))

  test "PlotJson - saveImage fails":
    check compileFails(plt.toPlotJson.saveImage("test.svg"))

  test "Plot - show w/ filename w/o threads:on fails":
    check compileFails(plt.show("test.svg"))

  test "PlotJson - show w/ filename w/o threads:on fails":
    check compileFails(plt.toPlotJson.show("test.svg"))

  test "Grid - show w/ filename w/o threads:on fails":
    var grid = createGrid(1)
    grid[0] = plt
    check compileFails(grid.show("test.svg"))
