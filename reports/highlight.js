
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

document.addEventListener('DOMContentLoaded', function() {
  var toc = document.getElementsByClassName('toc');
  var lis = document.getElementsByClassName('listing');
  if (toc.length != 1 || lis.length != 1)
    return;

  window.onscroll = function() {
    if (lis[0].getBoundingClientRect().y <= 0) {
      toc[0].classList.add('toc-fixed');
      lis[0].classList.add('listing-fixed');
    } else {
      toc[0].classList.remove('toc-fixed');
      lis[0].classList.remove('listing-fixed');
    }
  }
});
