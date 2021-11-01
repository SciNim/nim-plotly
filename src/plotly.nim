# we now import the plotly modules and export them so that
# the user sees them as a single module
import plotly / [api, plotly_types, errorbar, plotly_sugar, plotly_subplots]
export api
export plotly_types
export errorbar
export plotly_sugar
export plotly_subplots

when not defined(js):
  import plotly / plotly_display
  export plotly_display
else:
  import plotly / plotly_js
  export plotly_js
