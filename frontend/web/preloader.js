// Splash preloader (kept out of index.html so the CSP can forbid inline scripts).
(function () {
  // Minute track: 60 hairline ticks, every fifth one heavier.
  var ticks = document.getElementById('ticks');
  var ns = 'http://www.w3.org/2000/svg';
  for (var i = 0; i < 60; i++) {
    var a = (i / 60) * Math.PI * 2 - Math.PI / 2;
    var major = i % 5 === 0;
    var r1 = 94, r2 = major ? 87 : 91;
    var line = document.createElementNS(ns, 'line');
    line.setAttribute('x1', (104 + Math.cos(a) * r1).toFixed(2));
    line.setAttribute('y1', (104 + Math.sin(a) * r1).toFixed(2));
    line.setAttribute('x2', (104 + Math.cos(a) * r2).toFixed(2));
    line.setAttribute('y2', (104 + Math.sin(a) * r2).toFixed(2));
    line.setAttribute('style', 'stroke:var(--accent)');
    line.setAttribute('stroke-opacity', major ? '0.7' : '0.32');
    line.setAttribute('stroke-width', major ? '1.6' : '0.9');
    line.setAttribute('stroke-linecap', 'round');
    ticks.appendChild(line);
  }

  var preloader = document.getElementById('sanctuary-preloader');
  var status = document.getElementById('preloader-status');
  var dots = '<i>.</i><i>.</i><i>.</i>';
  var stages = ['Preparing your sanctuary', 'Winding the movement', 'Unsealing your vault'];
  var stage = 0;
  var rotate = setInterval(function () {
    stage = Math.min(stage + 1, stages.length - 1);
    status.innerHTML = stages[stage] + dots;
  }, 2400);

  function dismiss() {
    if (!preloader || preloader.classList.contains('loaded')) return;
    clearInterval(rotate);
    preloader.classList.add('loaded');
    preloader.setAttribute('aria-busy', 'false');
    setTimeout(function () { preloader.remove(); }, 500);
  }

  // Hand off as soon as Flutter paints its first frame (the matching logo reveal).
  window.addEventListener('flutter-first-frame', dismiss);

  // Never pull the curtain on a blank page: on a slow network, say so instead.
  setTimeout(function () {
    if (preloader && !preloader.classList.contains('loaded')) {
      clearInterval(rotate);
      status.innerHTML = 'Still loading · slow connection' + dots;
    }
  }, 15000);
})();
  
