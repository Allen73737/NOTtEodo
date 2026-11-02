// Applies the saved theme before Flutter starts, so the splash matches the app.
// Kept out of index.html so the Content-Security-Policy can forbid inline scripts.
try {
  var mode = null;
  // shared_preferences (web) stores each value JSON-encoded under "flutter.<key>".
  var raw = localStorage.getItem('flutter.nt.__public');
  if (raw) {
    var pub = JSON.parse(raw);
    if (typeof pub === 'string') pub = JSON.parse(pub);
    mode = pub && pub.themeMode;
  }
  if (mode === 'light' || mode === 'dark') {
    document.documentElement.setAttribute('data-theme', mode);
  }
} catch (e) {}
