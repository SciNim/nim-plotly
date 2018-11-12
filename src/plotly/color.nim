import chroma

# this module contains utility functions used in other modules of plotly
# related to the chroma module
func empty*(): Color =
  ## returns completely black
  result = Color(r: 0, g: 0, b: 0, a: 0)

func empty*(c: Color): bool =
  # TODO: this is also black, but should never need black with alpha == 0
  result = c.r == 0 and c.g == 0 and c.b == 0 and c.a == 0

func toHtmlHex*(colors: seq[Color]): seq[string] =
  result = newSeq[string](len(colors))
  for i, c in colors:
    result[i] = c.toHtmlHex
