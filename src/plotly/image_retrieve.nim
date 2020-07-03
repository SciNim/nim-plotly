import ws
import asynchttpserver, asyncnet, asyncdispatch
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

template withDebug(actions: untyped) =
  # use this template to echo statements, if the
  # -d:DEBUG compile flag is set
  when defined(DEBUG):
    actions

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
  stopServerChannel: Channel[bool]
filenameChannel.open(1)
# used by the callback function to stop the server when the file has
# been written or an error occured
stopServerChannel.open(1)

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
  #let (ws, error) = await verifyWebsocketRequest(req)
  var ws = await newWebSocket(req)
  if ws.isNil:
    echo "WS negotiation failed: ", ws.repr
    await req.respond(Http400, "Websocket negotiation failed: " & $ws.repr)
    req.client.close()
    return
  else:
    # receive connection successful package
    let (opcodeConnect, dataConnect) = await ws.receivePacket()
    if dataConnect == $Message.Connected:
      withDebug:
        debugEcho "Plotly connected successfully!"
    else:
      echo "Connection broken :/"
      return

  # now await the actual data package
  let (opcode, data) = await ws.receivePacket()
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
    echo "Saving plot to file ", filename
    writeFile(filename, image)
  except IOError:
    echo "Warning: file could not be written to ", filename

  # write ``true`` to the channel to let the server know it can be closed
  stopServerChannel.send(true)

proc listenForImage*(filename: string) =
  withDebug:
    debugEcho "Starting server"
  let server = newAsyncHttpServer()
  filenameChannel.send(filename)
  # start the async server
  asyncCheck server.serve(Port(8080), cb)
  # two booleans to keep track of whether we should poll or
  # can close the server. The callback writes to a channel once
  # its
  var
    stopAvailable = false
    stop = false
  while not stopAvailable:
    # we try to receive data from the stop channel. Once we do
    # check it's actually ``true`` and stop the server
    (stopAvailable, stop) = stopServerChannel.tryRecv
    if stop:
      withDebug:
        debugEcho "Closing server"
      server.close()
      break
      #break
    # else poll for events, i.e. let the callback work
    poll(500)
