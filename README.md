# How to setup hot-reloading server with [elm-go](https://github.com/lucamug/elm-go)

## 1. Create an `index.html` file
```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>MIU System</title>
</head>
<body>
  <div id="app"></div>

  <script src="elm.js"></script>
  <script>
    Elm.Main.init({
      node: document.getElementById("app")
    });
  </script>
</body>
</html>
```

## 2. Start the server

`elm-go src/Main.elm --open -- --output=elm.js`