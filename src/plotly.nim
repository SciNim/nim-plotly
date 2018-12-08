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
import plotly/plotly_sugar
export plotly_sugar

when defined(webview):
  import webview

when not defined(js):
  # not available on JS backend
  import os

  # normally just import browsers module. Howver, in case we run
  # tests on travis, we need a way to open a browser, which is
  # non-blocking. For some reason `xdg-open` does not return immediately
  # on travis.
  when not defined(travis):
    import browsers

  proc showPlot(file: string) =
    when defined(travis):
      # patched version of Nim's `openDefaultBrowser` which always
      # returns immediately
      var u = quoteShell(file)
      discard execShellCmd("xdg-open " & u & " &")
    elif defined(webview):
      let w = newWebView("Nim Plotly", "file://" & file)
      w.run()
      w.exit()
    else:
      # default normal browser
      openDefaultBrowser(file)

  include plotly/tmpl_html
else:
  import plotly/plotly_js
  export plotly_js

# check whether user is compiling with thread support. We can only compile
# `saveImage` if the user compiles with it!
const hasThreadSupport = compileOption("threads")
when hasThreadSupport and not defined(js):
  import threadpool
  import plotly/image_retrieve

proc parseTraces*[T](traces: seq[Trace[T]]): string =
  ## parses the traces of a Plot object to strings suitable for
  ## plotly by creating a JsonNode and converting to string repr
  result.toUgly(% traces)

when not defined(js):
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
                        p: Plot,
                        filename = ""): string =
    ## fills the HTML template with the correct strings and, if compiled with
    ## ``--threads:on``, inject the save image HTML code and fills that
    var
      slayout = "{}"
      title = ""
    if p.layout != nil:
      slayout = $(%p.layout)
      title = p.layout.title

    # read the HTML template and insert data, layout and title strings
    # imageInject is will be filled iff the user compiles with ``--threads:on``
    # and a filename is given
    var imageInject = ""
    when hasThreadSupport:
      if filename.len > 0:
        # prepare save image code
        let filetype = parseImageType(filename)
        let swidth = $p.layout.width
        let sheight = $p.layout.height
        imageInject = fillImageInjectTemplate(filetype, swidth, sheight)

    # now fill all values into the html template
    result = html_template % ["data", data_string, "layout", slayout,
                              "title", title, "saveImage", imageInject]

  proc save*(p: Plot, path = "", html_template = defaultTmplString, filename = ""): string =
    result = path
    if result == "":
      when defined(Windows):
        result = getEnv("TEMP") / "x.html"
      else:
        result = "/tmp/x.html"

    let
      # convert traces to data suitable for plotly and fill Html template
      data_string = parseTraces(p.traces)
      html = html_template.fillHtmlTemplate(data_string, p, filename)

    var
      f: File
    if not open(f, result, fmWrite):
      quit "could not open file for json"
    f.write(html)
    f.close()

  when not hasThreadSupport:
    # some violation of DRY for the sake of better error messages at
    # compile time
    proc show*(p: Plot,
               filename: string,
               path = "",
               html_template = defaultTmplString) =
      {.fatal: "`filename` argument to save plot only supported if compiled " &
        "with --threads:on!".}

    proc show*(p: Plot, path = "", html_template = defaultTmplString) =
      ## creates the temporary Html file using `save`, and opens the user's
      ## default browser
      let tmpfile = p.save(path, html_template)

      showPlot(tmpfile)
      sleep(1000)
      ## remove file after thread is finished
      removeFile(tmpfile)

    proc saveImage*(p: Plot, filename: string) =
      {.fatal: "`saveImage` only supported if compiled with --threads:on!".}

  else:
    # if compiled with --threads:on
    proc show*(p: Plot, filename = "", path = "", html_template = defaultTmplString) =
      ## creates the temporary Html file using `save`, and opens the user's
      ## default browser
      # if we are handed a filename, the user wants to save the file to disk.
      # Start a websocket server to receive the image data
      var thr: Thread[string]
      if filename.len > 0:
        # wait a short while to make sure the server is up and running
        thr.createThread(listenForImage, filename)

      let tmpfile = p.save(path, html_template, filename)
      showPlot(tmpfile)
      if filename.len > 0:
        # wait for thread to join
        thr.joinThread
      removeFile(tmpfile)

    proc saveImage*(p: Plot, filename: string) =
      ## saves the image under the given filename
      ## supported filetypes:
      ## - jpg, png, svg, webp
      ## Note: only supported if compiled with --threads:on!
      p.show(filename = filename)
