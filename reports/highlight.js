
var lastId = null;
var lastBg = null;

function highlight(id) {
  var el = document.getElementById(id);
  if (el) {
    if (lastId)
      unhighlight(lastId, lastBg);

    lastId = id;
    lastBg = el.style.backgroundColor;

    el.style.backgroundColor = 'yellow';
  }
}

function unhighlight(id, bg) {
  var el = document.getElementById(id);
  if (el) { el.style.backgroundColor = bg; }
}
