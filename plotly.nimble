# Package

version       = "0.3.3"
author        = "Brent Pedersen"
description   = "plotting library for nim"
license       = "MIT"


requires "nim >= 0.18.0", "chroma", "jsbind", "webview", "ws"

srcDir = "src"

skipDirs = @["tests"]

import os, strutils

task test, "run the tests":
  exec "nim c -r tests/plotly/test_api.nim"
  exec "nim c --lineDir:on --debuginfo -r examples/all"
  exec "nim c --lineDir:on --debuginfo --threads:on -r examples/fig12_save_figure.nim"

task testCI, "run the tests on github actions":
  exec "nim c -r tests/plotly/test_api.nim"
  # define the `testCI` flag to use our custom `xdg-open` based proc to open
  # firefox, which is non-blocking
  exec "nim c --lineDir:on -d:testCI --debuginfo -r examples/all"
  exec "nim c --lineDir:on -d:testCI -d:DEBUG --debuginfo --threads:on -r examples/fig12_save_figure.nim"

task testCINoSave, "run the tests on travis":
  exec "nim c -r tests/plotly/test_api.nim"
  # TODO: check if this works
  exec "nim c --lineDir:on -d:testCI --debuginfo -r examples/all"

task docs, "Builds documentation":
  mkDir("docs"/"plotly")
  #exec "nim doc2 --verbosity:0 --hints:off -o:docs/index.html  src/hts.nim"
  for file in listfiles("src/"):
    if splitfile(file).ext == ".nim":
      exec "nim doc2 --verbosity:0 --hints:off -o:" & "docs" /../ file.changefileext("html").split("/", 1)[1] & " " & file
  for file in listfiles("src/plotly/"):
    if splitfile(file).ext == ".nim":
      exec "nim doc2 --verbosity:0 --hints:off -o:" & "docs/plotly" /../ file.changefileext("html").split("/", 1)[1] & " " & file
