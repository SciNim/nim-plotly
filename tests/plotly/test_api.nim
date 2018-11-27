import ../../src/plotly
import unittest
import json

suite "Annotation Json tests":
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

suite "Layout Json tests":
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
