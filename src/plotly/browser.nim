import osproc
import os
import strutils

proc hasExe*(cmd:string): bool =
  let (outp, _) = execCmdEx(cmd)
  return not ("not found" in outp)

const options = @["xdg-open", "mozilla-firefox", "firefox", "chromium", "google-chrome", "chromium-browser"]
var browsers = new_seq[string]()

for o in options:
  var e = findExe(o)
  if e == "": continue
  browsers.add(e)
echo browsers

proc open*(path:string) =
  ## open a browser pointing to the given path
  for b in browsers:
    var (outp, errC) = execCmdEx(b & " " & path)
    echo b & " " & outp
    if errC == 0 and not ("not found" in outp):
      return

when isMainModule:
  open("/tmp/x.html")

