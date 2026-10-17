"""Gera o PWA em app/ a partir de troca-turno.html (fonte única do formulário)."""
import pathlib, re

ROOT = pathlib.Path(__file__).resolve().parent.parent
src = (ROOT / "troca-turno.html").read_text(encoding="utf-8")

src = src.replace(
    "https://cdnjs.cloudflare.com/ajax/libs/jspdf/2.5.1/jspdf.umd.min.js",
    "vendor/jspdf.umd.min.js",
)
title = re.search(r"<title>.*?</title>\n", src).group(0)
src = src.replace(title, "", 1)

head = f"""<!doctype html>
<html lang="pt-BR">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">
{title}<meta name="theme-color" content="#23466b">
<meta name="color-scheme" content="light">
<meta name="apple-mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-title" content="Troca Turno">
<link rel="manifest" href="manifest.webmanifest">
<link rel="icon" href="icons/icon-192.png">
<link rel="apple-touch-icon" href="icons/apple-touch-icon.png">
<style>:root{{padding-top:env(safe-area-inset-top,0px);padding-bottom:env(safe-area-inset-bottom,0px)}}body{{margin:0;font:14px/1.4 system-ui,sans-serif}}img{{max-width:100%}}[hidden]{{display:none!important}}</style>
</head>
<body>
"""
tail = """
<script>
if ('serviceWorker' in navigator) {
  window.addEventListener('load', () => navigator.serviceWorker.register('sw.js').catch(() => {}));
}
</script>
</body>
</html>
"""
(ROOT / "app" / "index.html").write_text(head + src + tail, encoding="utf-8")
print("app/index.html gerado")
