# Package

version       = "0.1.0"
author        = "Brent Pedersen"
description   = "plotting library for nim"
license       = "MIT"


requires "nim >= 0.18.0", "chroma"
srcDir = "src"

skipDirs = @["tests"]

import ospaths,strutils

task test, "run the tests":
  exec "nim c --lineDir:on --debuginfo -r examples/all"

task docs, "Builds documentation":
  mkDir("docs"/"plotly")
  #exec "nim doc2 --verbosity:0 --hints:off -o:docs/index.html  src/hts.nim"
  for file in listfiles("src/"):
    if splitfile(file).ext == ".nim":
      exec "nim doc2 --verbosity:0 --hints:off -o:" & "docs" /../ file.changefileext("html").split("/", 1)[1] & " " & file
  for file in listfiles("src/plotly/"):
    if splitfile(file).ext == ".nim":
      exec "nim doc2 --verbosity:0 --hints:off -o:" & "docs/plotly" /../ file.changefileext("html").split("/", 1)[1] & " " & file


