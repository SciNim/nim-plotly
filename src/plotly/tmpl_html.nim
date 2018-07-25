const defaultTmplString = """
<!DOCTYPE html>
<html>
	<head>
		<meta charset="utf-8" />
		<title>$title</title>
		 <script src="https://cdn.plot.ly/plotly-latest.min.js"></script>
	</head>
	<body>
		<div id="plot0"></div>
		<script>
			Plotly.newPlot('plot0', $data, $layout)
                </script>
                $saveImage
	</body>
</html>
"""

# type needs to be inserted!
# either
# - png
# - svg
# - jpg
const injectImageCode = """
<script>
        var d3 = Plotly.d3;
        var imageData;
        var img = d3.select('#$1-export');
        Plotly.toImage(plot0, {format: '$2', width: $3, height: $4}).then(function(url){
                img.attr("src", url);
                imageData = url;
                return Plotly.toImage(plot0,{format:'$5', width: $6, height: $7});
              })
        var connection = new WebSocket('ws://localhost:8080');
        // after connection opened successfully, send our image
        connection.onopen = function() {
          // need to wait a short while to be sure the promise is fullfilled (I believe?!)
          connection.send("connected")
          setTimeout(function(){ connection.send(imageData); }, 100);
};
</script>
"""

