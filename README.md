## nim-plotly: simple plots in nim

this is a relatively minimal version of a plotting library with some functionality
so I can get feedback before proceeding.

This is **not** specifically for the javascript nim target.

Internally, it serializes typed `nim` datastructures to JSON that matches what [plotly](https://plot.ly/javascript/) expects.

## TODO

+ [X] add .show() method to plot which looks for and opens a browser (similar to python webbrowser module)
+ [X] support multiple axes (2 y-axes supported).
+ [ ] experiment with syntax for multiple plots (https://plot.ly/javascript/subplots/ or use separate divs.)
+ [ ] better side-stepping of https://github.com/nim-lang/Nim/issues/7794
+ [ ] convert `%` procs into macros so I don't have to re-write the same code over and over.
+ [ ] more of plotly API
+ [ ] ergonomics / plotting DSL
