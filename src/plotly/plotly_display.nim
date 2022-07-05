import std / [strutils, os, osproc, json, sequtils, times]

# we now import the plotly modules and export them so that
# the user sees them as a single module
import api, plotly_types, plotly_subplots

when defined(webview) or defined(testCI):
  import webview

# normally just import browsers module. Howver, in case we run
# tests on testCI, we need a way to open a browser, which is
# non-blocking. For some reason `xdg-open` does not return immediately
# on testCI.
when not defined(testCI):
  import browsers

# check whether user is compiling with thread support. We can only compile
# `saveImage` if the user compiles with it!
const hasThreadSupport* = compileOption("threads")
when hasThreadSupport:
  import threadpool
  import plotly/image_retrieve

when defined(posix):
  import posix_utils

template openBrowser(): untyped {.dirty.} =
  # default normal browser
  when defined(posix):
    # check if running under WSL, if so convert to full path
    let release = uname().release
    if "microsoft" in release or "Microsoft" in release:
      let res = execCmdEx("wslpath -m " & file)
      openDefaultBrowser("file://" & res[0].strip)
    else:
      openDefaultBrowser(file)
  else:
    openDefaultBrowser(file)

when hasThreadSupport:
  proc showPlotThreaded(file: string, thr: Thread[string], onlySave: static bool = false) =
    when defined(webview) or defined(testCI):
      # on testCI we use webview when saving files. We run the webview loop
      # until the image saving thread is finished
      let w = newWebView("Nim Plotly", "file://" & file)
      when onlySave or defined(testCI):
        while thr.running:
          if not w.isNil:
            discard w.loop(1)
          else:
            break
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
    elif defined(testCI):
      # patched version of Nim's `openDefaultBrowser` which always
      # returns immediately
      var u = quoteShell(file)
      const osOpenCmd =
        when defined(macos) or defined(macosx) or defined(windows): "open" else: "xdg-open" ## \
        ## Alias for the operating system specific *"open"* command,
        ## `"open"` on OSX, MacOS and Windows, `"xdg-open"` on Linux, BSD, etc.
        ## NOTE: from Nim stdlib
      let cmd = osOpenCmd
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

proc fillHtmlTemplate(htmlTemplate,
                      data_string: string,
                      p: SomePlot,
                      filename = "",
                      autoResize = true): string =
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

  let scriptTag = if autoResize: resizeScript()
                  else: staticScript()
  let scriptFilled = scriptTag % [ "data", data_string,
                                   "layout", slayout ]

  # now fill all values into the html template
  result = htmlTemplate % [ "title", title,
                            "scriptTag", scriptFilled,
                            "saveImage", imageInject]

proc genPlotDirname(filename, outdir: string): string =
  ## generates unique name for the given input file based on its name and
  ## the current time
  const defaultName = "nim_plotly"
  let filename = if filename.len == 0: defaultName # default to give some sane human readable idea
                 else: splitFile(filename)[1]
  let timeStr = format(now(), "yyyy-MM-dd'_'HH-mm-ss'.'fff")
  let dir = outdir / defaultName
  createDir(dir)
  let outfile = filename & "_" & timeStr & ".html"
  result = dir / outfile

proc save*(p: SomePlot,
           htmlPath = "",
           htmlTemplate = defaultTmplString,
           filename = "",
           autoResize = true
          ): string =
  result = if htmlPath.len > 0: htmlPath
           else: genPlotDirname(filename, getTempDir())

  when type(p) is Plot:
    # convert traces to data suitable for plotly and fill Html template
    let data_string = parseTraces(p.traces)
  else:
    let data_string = $p.traces
  let html = htmlTemplate.fillHtmlTemplate(data_string, p, filename, autoResize)

  writeFile(result, html)

when not hasThreadSupport:
  # some violation of DRY for the sake of better error messages at
  # compile time
  proc show*(p: SomePlot,
             filename: string,
             htmlPath = "",
             htmlTemplate = defaultTmplString,
             removeTempFile = false,
             autoResize = true)
    {.error: "`filename` argument to `show` only supported if compiled " &
      "with --threads:on!".}

  proc show*(p: SomePlot,
             htmlPath = "",
             htmlTemplate = defaultTmplString,
             removeTempFile = false,
             autoResize = true) =
    ## Creates the temporary Html file in using `save`, and opens the user's
    ## default browser.
    ##
    ## If `htmlPath` is given the file is stored in the given path and name.
    ## Else a suitable name will be generated based on the current time.
    ##
    ## `htmlTemplate` allows to overwrite the default HTML template.
    ##
    ## If `removeTempFile` is true, the temporary file will be deleted after
    ## a short while (not recommended).
    ##
    ## If `autoResize` is true, the shown plot will automatically resize according
    ## to the browser window size. This overrides any possible custom sizes for
    ## the plot. By default it is disabled for plots that should be saved.
    let tmpfile = p.save(htmlPath = htmlPath,
                         htmlTemplate = htmlTemplate,
                         autoResize = autoResize)
    showPlot(tmpfile)
    if removeTempFile:
      sleep(2000)
      ## remove file after thread is finished
      removeFile(tmpfile)

  proc saveImage*(p: SomePlot, filename: string,
                  htmlPath = "",
                  htmlTemplate = defaultTmplString,
                  removeTempFile = false,
                  autoResize = false)
    {.error: "`saveImage` only supported if compiled with --threads:on!".}

  when not defined(js):
    proc show*(grid: Grid, filename: string,
               htmlPath = "",
               htmlTemplate = defaultTmplString,
               removeTempFile = false,
               autoResize = true)
      {.error: "`filename` argument to `show` only supported if compiled " &
        "with --threads:on!".}

    proc show*(grid: Grid,
               htmlPath = "",
               htmlTemplate = defaultTmplString,
               removeTempFile = false,
               autoResize = true) =
      ## Displays the `Grid` plot. Converts the `grid` to a call to
      ## `combine` and calls `show` on it.
      ##
      ## If `htmlPath` is given the file is stored in the given path and name.
      ## Else a suitable name will be generated based on the current time.
      ##
      ## `htmlTemplate` allows to overwrite the default HTML template.
      ##
      ## If `removeTempFile` is true, the temporary file will be deleted after
      ## a short while (not recommended).
      ##
      ## If `autoResize` is true, the shown plot will automatically resize according
      ## to the browser window size. This overrides any possible custom sizes for
      ## the plot. By default it is disabled for plots that should be saved.
      grid.toPlotJson.show(htmlPath = htmlPath,
                           htmlTemplate = defaultTmplString,
                           removeTempFile = removeTempFile,
                           autoResize = autoResize)
else:
  # if compiled with --threads:on
  proc show*(p: SomePlot,
             filename = "",
             htmlPath = "",
             htmlTemplate = defaultTmplString,
             onlySave: static bool = false,
             removeTempFile = false,
             autoResize = true) =
    ## Creates the temporary Html file using `save`, and opens the user's
    ## default browser.
    ##
    ## If `onlySave` is true, the plot is only saved and "not shown". However
    ## this only works on the `webview` target. And a webview window has to
    ## be opened, but will be closed automatically the moment the plot is saved.
    ##
    ## If `htmlPath` is given the file is stored in the given path and name.
    ## Else a suitable name will be generated based on the current time.
    ##
    ## `htmlTemplate` allows to overwrite the default HTML template.
    ##
    ## If `removeTempFile` is true, the temporary file will be deleted after
    ## a short while (not recommended).
    ##
    ## If `autoResize` is true, the shown plot will automatically resize according
    ## to the browser window size. This overrides any possible custom sizes for
    ## the plot. By default it is disabled for plots that should be saved.
    var thr: Thread[string]
    if filename.len > 0:
      # start a second thread with a webview server to capture the image
      thr.createThread(listenForImage, filename)

    let tmpfile = p.save(htmlPath = htmlPath,
                         filename = filename,
                         htmlTemplate = htmlTemplate,
                         autoResize = autoResize)
    showPlotThreaded(tmpfile, thr, onlySave)
    if filename.len > 0:
      # wait for thread to join
      thr.joinThread
    if removeTempFile:
      sleep(2000)
      removeFile(tmpfile)

  proc saveImage*(p: SomePlot, filename: string,
                  htmlPath = "",
                  htmlTemplate = defaultTmplString,
                  removeTempFile = false,
                  autoResize = false) =
    ## Saves the image under the given filename
    ## supported filetypes:
    ##
    ## - jpg, png, svg, webp
    ##
    ## Note: only supported if compiled with --threads:on!
    ##
    ## If the `webview` target is used, the plot is ``only`` saved and not
    ## shown (for long; webview closed after image saved correctly).
    ##
    ## If `htmlPath` is given the file is stored in the given path and name.
    ## Else a suitable name will be generated based on the current time.
    ##
    ## `htmlTemplate` allows to overwrite the default HTML template.
    ##
    ## If `removeTempFile` is true, the temporary file will be deleted after
    ## a short while (not recommended).
    ##
    ## If `autoResize` is true, the shown plot will automatically resize according
    ## to the browser window size. This overrides any possible custom sizes for
    ## the plot. By default it is disabled for plots that should be saved.
    p.show(filename = filename,
           htmlPath = htmlPath,
           htmlTemplate = htmlTemplate,
           onlySave = true,
           removeTempFile = removeTempFile,
           autoResize = autoResize)

  when not defined(js):
    proc show*(grid: Grid,
               filename = "",
               htmlPath = "",
               htmlTemplate = defaultTmplString,
               removeTempFile = false,
               autoResize = true) =
      ## Displays the `Grid` plot. Converts the `grid` to a call to
      ## `combine` and calls `show` on it.
      ##
      ## If `htmlPath` is given the file is stored in the given path and name.
      ## Else a suitable name will be generated based on the current time.
      ##
      ## `htmlTemplate` allows to overwrite the default HTML template.
      ##
      ## If `removeTempFile` is true, the temporary file will be deleted after
      ## a short while (not recommended).
      ##
      ## If `autoResize` is true, the shown plot will automatically resize according
      ## to the browser window size. This overrides any possible custom sizes for
      ## the plot. By default it is disabled for plots that should be saved.
      grid.toPlotJson.show(filename,
                           htmlPath = htmlPath,
                           htmlTemplate = htmlTemplate,
                           removeTempFile = removeTempFile,
                           autoResize = autoResize)
