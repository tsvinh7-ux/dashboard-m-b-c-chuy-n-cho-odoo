"""Đóng gói dashboard.html (dạng fragment) thành index.html mở trực tiếp được bằng trình duyệt."""
from pathlib import Path

here = Path(__file__).parent
body = (here / "dashboard.html").read_text(encoding="utf-8")
html = (
    "<!doctype html>\n<html lang=\"vi\">\n<head>\n<meta charset=\"utf-8\">\n"
    "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1, viewport-fit=cover\">\n"
    "<style>:root{padding-top:env(safe-area-inset-top,0px);padding-bottom:env(safe-area-inset-bottom,0px)}"
    "body{margin:0}img{max-width:100%}[hidden]{display:none!important}</style>\n"
    "</head>\n<body>\n" + body + "\n</body>\n</html>\n"
)
(here / "index.html").write_text(html, encoding="utf-8")
print("Đã tạo", here / "index.html")
