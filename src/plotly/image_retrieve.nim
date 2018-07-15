import websocket, asynchttpserver, asyncnet, asyncdispatch
import strutils, strformat
import re
import os
# to decode SVG data
import uri
# to decode jpeg, png and webp data
import base64

type
  # simple type for clarity, ``Connected`` package first sent after
  # connection to websocket server has been established
  Message {.pure.} = enum
    Connected = "connected"

proc parseImageType*(filename: string): string =
  let
    (dir, file, ext) = filename.splitFile  
    filetype = ext.strip(chars = {'.'})
  # now check for the given type
  case filetype
  of "jpg":
    # plotly expects the filetype to be given as ".jpeg"
    result = "jpeg"
  of "jpeg", "png", "svg", "webp":
    result = filetype
  else:
    echo "Warning: Only the following filetypes are allowed:"
    echo "\t jpeg, svg, png, webp"
    echo "will save file as png"
    result = "png"

# data header which we use to insert the filetype and then strip
# it from the data package
# jpeg header = data:image/jpeg;base64,
# png header  = data:image/png;base64,
# webp header = data:image/webp;base64,
# svg header  = data:image/svg+xml,
# template for jpg, png and webp
const base64Tmpl = r"data:image/$#;base64,"
# template for svg
const urlTmpl = r"data:image/$#+xml,"

# use a channel to hand the filename to the callback function
var
  filenameChannel: Channel[string]
filenameChannel.open(1)

template parseFileType(header: string, regex: Regex): string =
  # template due to GC safety. Just have it replaced in code below
  var result = ""
  if header =~ regex:
    # pipe output through ``parseImageType``
    result = matches[0]
  else:
    # default to png
    result = "png"
  result

proc cb(req: Request) {.async.} =
  # compile regex to parse the data header
  let regex = re(r"data:image\/(\w+)[;+].*")
  # receive the filename from the channel
  let filename = filenameChannel.recv()
  
  # now await the connection of the websocket client
  let (ws, error) = await verifyWebsocketRequest(req)

  if ws.isNil:
    echo "WS negotiation failed: ", error
    await req.respond(Http400, "Websocket negotiation failed: " & error)
    req.client.close()
    return
  else:
    # receive connection successful package
    let (opcodeConnect, dataConnect) = await ws.readData()
    if dataConnect == $Message.Connected:
      echo "Plotly connected successfully!"
    else:
      echo "Connection broken :/"
      return

  # now await the actual data package
  let (opcode, data) = await ws.readData()
  # get header to parse the actual filetype and remove the header from the data
  # determine header length from data, first appearance of `,`
  let headerLength = data.find(',')
  let
    header = (data.strip)[0 .. headerLength]
    filetype = header.parseFileType(regex)
  var
    onlyData = ""
    image = ""
  case filetype
  of "jpeg", "png", "webp":
    onlyData = data.replace(base64Tmpl % filetype, "")
    # decode the base64 decoded data packet
    image = (onlyData).decode
  of "svg":
    onlyData = data.replace(urlTmpl % filetype, "")
    # decode the URI decoded data packet
    image = onlyData.decodeUrl
  else:
    echo "Warning: Unsupported filetype :", filetype
  try:
    # try to write the filename the user requested
    writeFile(filename, image)
  except IOError:
    echo "Warning: file could not be written to ", filename

proc listenForImage*(filename: string) = 
  let server = newAsyncHttpServer()
  echo "Saving plot to file ", filename
  filenameChannel.send(filename)
  waitFor server.serve(Port(8080), cb)
  
