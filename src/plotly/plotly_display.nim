import strutils
import os, osproc
import json
import sequtils
import posix_utils

# we now import the plotly modules and export them so that
# the user sees them as a single module
import api, plotly_types, plotly_subplots

when defined(webview) or defined(travis):
  import webview

# normally just import browsers module. Howver, in case we run
# tests on travis, we need a way to open a browser, which is
# non-blocking. For some reason `xdg-open` does not return immediately
# on travis.
when not defined(travis):
  import browsers

# check whether user is compiling with thread support. We can only compile
# `saveImage` if the user compiles with it!
const hasThreadSupport* = compileOption("threads")
when hasThreadSupport:
  import threadpool
  import plotly/image_retrieve

template openBrowser(): untyped {.dirty.} =
  # default normal browser
  when defined(posix):
    # check if running under WSL, if so convert to full path
    let release = posix_utils.uname().release
    if "microsoft" in release or "Microsoft" in release:
      let res = execCmdEx("wslpath -m " & file)
      openDefaultBrowser("file://" & res[0].strip)
    else:
      openDefaultBrowser(file)
  else:
    openDefaultBrowser(file)

when hasThreadSupport:
  proc showPlotThreaded(file: string, thr: Thread[string], onlySave: static bool = false) =
    when defined(webview) or defined(travis):
      # on travis we use webview when saving files. We run the webview loop
      # until the image saving thread is finished
      let w = newWebView("Nim Plotly", "file://" & file)
      when onlySave or defined(travis):
        while thr.running:
          discard w.loop(1)
        thr.joinThread
      else:
        w.run()
      w.exit()
    else:
      # WARNING: dirty template, see above!
      openBrowser()
else:
  proc showPlot(file: string) =
    when defined(webview):
      let w = newWebView("Nim Plotly", "file://" & file)
      w.run()
      w.exit()
    elif defined(travis):
      # patched version of Nim's `openDefaultBrowser` which always
      # returns immediately
      var u = quoteShell(file)
      let cmd = "xdg-open"
      discard startProcess(command = cmd, args = [file], options = {poUsePath})
    else:
      # WARNING: dirty template, see above!
      openBrowser()

include plotly/tmpl_html

proc parseTraces*[T](traces: seq[Trace[T]]): string =
  ## parses the traces of a Plot object to strings suitable for
  ## plotly by creating a JsonNode and converting to string repr
  result.toUgly(% traces)

# `show` and `save` are only used for the C target
proc fillImageInjectTemplate(filetype, width, height: string): string =
  ## fill the image injection code with the correct fields
  ## Here we use numbering of elements to replace in the template.
  # Named replacements don't seem to work because of the characters
  # around the `$` calls
  result = injectImageCode % [filetype,
                              filetype,
                              width,
                              height,
                              filetype,
                              width,
                              height]

proc fillHtmlTemplate(html_template,
                      data_string: string,
                      p: SomePlot,
                      filename = ""): string =
  ## fills the HTML template with the correct strings and, if compiled with
  ## ``--threads:on``, inject the save image HTML code and fills that
  var
    slayout = "{}"
    title = ""
  if p.layout != nil:
    when type(p) is Plot:
      slayout = $(%p.layout)
      title = p.layout.title
    else:
      slayout = $p.layout
      title = p.layout{"title"}.getStr

  # read the HTML template and insert data, layout and title strings
  # imageInject is will be filled iff the user compiles with ``--threads:on``
  # and a filename is given
  var imageInject = ""
  when hasThreadSupport:
    if filename.len > 0:
      # prepare save image code
      let filetype = parseImageType(filename)
      when type(p) is Plot:
        let swidth = $p.layout.width
        let sheight = $p.layout.height
      else:
        let swidth = $p.layout{"width"}
        let sheight = $p.layout{"height"}
      imageInject = fillImageInjectTemplate(filetype, swidth, sheight)

  # now fill all values into the html template
  result = html_template % ["data", data_string, "layout", slayout,
                            "title", title, "saveImage", imageInject]

proc save*(p: SomePlot, path = "", html_template = defaultTmplString, filename = ""): string =
  result = path
  if result == "":
    when defined(Windows):
      result = getEnv("TEMP") / "x.html"
    else:
      result = "/tmp/x.html"

  when type(p) is Plot:
    # convert traces to data suitable for plotly and fill Html template
    let data_string = parseTraces(p.traces)
  else:
    let data_string = $p.traces
  let html = html_template.fillHtmlTemplate(data_string, p, filename)

  var
    f: File
  if not open(f, result, fmWrite):
    quit "could not open file for json"
  f.write(html)
  f.close()

when not hasThreadSupport:
  # some violation of DRY for the sake of better error messages at
  # compile time
  proc show*(p: SomePlot,
             filename: string,
             path = "",
             html_template = defaultTmplString)
    {.error: "`filename` argument to `show` only supported if compiled " &
      "with --threads:on!".}

  proc show*(p: SomePlot, path = "", html_template = defaultTmplString) =
    ## creates the temporary Html file using `save`, and opens the user's
    ## default browser
    let tmpfile = p.save(path, html_template)

    showPlot(tmpfile)
    sleep(1000)
    ## remove file after thread is finished
    removeFile(tmpfile)

  proc saveImage*(p: SomePlot, filename: string)
    {.error: "`saveImage` only supported if compiled with --threads:on!".}

  when not defined(js):
    proc show*(grid: Grid, filename: string)
      {.error: "`filename` argument to `show` only supported if compiled " &
        "with --threads:on!".}

    proc show*(grid: Grid) =
      ## display the `Grid` plot. Converts the `grid` to a call to
      ## `combine` and calls `show` on it.
      grid.toPlotJson.show()
else:
  # if compiled with --threads:on
  proc show*(p: SomePlot,
             filename = "",
             path = "",
             html_template = defaultTmplString,
             onlySave: static bool = false) =
    ## creates the temporary Html file using `save`, and opens the user's
    ## default browser.
    ## If `onlySave` is true, the plot is only saved and "not shown". However
    ## this only works on the `webview` target. And a webview window has to
    ## be opened, but will be closed automatically the moment the plot is saved.
    var thr: Thread[string]
    if filename.len > 0:
      # start a second thread with a webview server to capture the image
      thr.createThread(listenForImage, filename)

    let tmpfile = p.save(path, html_template, filename)
    showPlotThreaded(tmpfile, thr, onlySave)
    if filename.len > 0:
      # wait for thread to join
      thr.joinThread

    removeFile(tmpfile)

  proc saveImage*(p: SomePlot, filename: string) =
    ## saves the image under the given filename
    ## supported filetypes:
    ## - jpg, png, svg, webp
    ## Note: only supported if compiled with --threads:on!
    ## If the `webview` target is used, the plot is ``only`` saved and not
    ## shown (for long; webview closed after image saved correctly).
    p.show(filename = filename, onlySave = true)

  when not defined(js):
    proc show*(grid: Grid, filename = "") =
      ## display the `Grid` plot. Converts the `grid` to a call to
      ## `combine` and calls `show` on it.
      grid.toPlotJson.show(filename)
