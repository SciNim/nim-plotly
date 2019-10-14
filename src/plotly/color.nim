import chroma
import json, strformat, sequtils
from plotly_types import CustomColorMap, PredefinedCustomMaps
# defines raw data for viridis, plasma, magma, inferno
import predefined_colormaps

type
  # TODO: make `ColorRange` work as types. Apparently cannot create
  # (r: 0.5, g: 0.4, b: 0.1) as tuple w/ ColorRange fields. Implicit
  # conversion only works for individual values, not tuples?
  # ColorRange = range[0.0 .. 1.0]
  CmapData = seq[tuple[r, g, b: float64]]

# this module contains utility functions used in other modules of plotly
# related to the chroma module as well as custom color maps
func empty*(): Color =
  ## returns completely black
  result = Color(r: 0, g: 0, b: 0, a: 0)

func isEmpty*(c: Color): bool =
  ## checks whether given color is black according to above
  # TODO: this is also black, but should never need black with alpha == 0
  result = c == empty()

func toHtmlHex*(colors: seq[Color]): seq[string] =
  result = newSeq[string](len(colors))
  for i, c in colors:
    result[i] = c.toHtmlHex

proc makeZeroWhite*(cmap: CmapData): CmapData =
  result = @[(r: 1.0, g: 1.0, b: 1.0)]
  result.add cmap[1 .. ^1]

proc makePlotlyCustomMap*(map: CustomColorMap): JsonNode =
  result = newJArray()
  for i, row in map.rawColors:
    let rowJarray = % [% (i.float / (map.rawColors.len - 1).float),
                       % &"rgb({row[0] * 256.0}, {row[1] * 256.0}, {row[2] * 256.0})"]
    result.add rowJarray

proc getCustomMap*(customMap: PredefinedCustomMaps): CustomColorMap =
  var data: CmapData
  case customMap
  of ViridisZeroWhite:
    data = makeZeroWhite(ViridisRaw)
  of Plasma:
    data = PlasmaRaw
  of PlasmaZeroWhite:
    data = makeZeroWhite(PlasmaRaw)
  of Magma:
    data = MagmaRaw
  of MagmaZeroWHite:
    data = makeZeroWhite(MagmaRaw)
  of Inferno:
    data = InfernoRaw
  of InfernoZeroWHite:
    data = makeZeroWhite(InfernoRaw)
  of WhiteToBlack:
    data = toSeq(0 .. 255).mapIt((r: 1.0 - it.float / 255.0,
                                  g: 1.0 - it.float / 255.0,
                                  b: 1.0 - it.float / 255.0))
  of Other:
    discard
  result = CustomColorMap(rawColors: data,
                          name: $customMap)
