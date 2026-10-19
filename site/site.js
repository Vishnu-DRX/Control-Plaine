// Demo only: switches, and the little interactions of each skin. No external requests.
(function () {
  var stage = document.getElementById('stage');
  if (!stage) return;
  var stages = document.querySelectorAll('.stage');
  document.querySelectorAll('.switch').forEach(function (group) {
    var key = group.getAttribute('data-switch');
    group.addEventListener('click', function (e) {
      var btn = e.target.closest('button');
      if (!btn) return;
      stages.forEach(function (s) { s.setAttribute('data-' + key, btn.getAttribute('data-value')); });
      group.querySelectorAll('button').forEach(function (b) {
        b.setAttribute('aria-pressed', b === btn ? 'true' : 'false');
      });
    });
  });

  function $(id) { return document.getElementById(id); }
  function icon(id, name) { var u = $(id); if (u) u.setAttribute('href', '#i-' + name); }

  // Volume: scroll changes the level, the percentage mutes, the device name cycles outputs.
  var vol = 64, muted = false, CIRC = 163.4;
  function paintVol() {
    $('volPct').textContent = muted ? 'MUTED' : vol + '%';
    $('volRing').setAttribute('stroke-dasharray', (muted ? 0 : CIRC * vol / 100).toFixed(1) + ' ' + CIRC);
    icon('volIcon', muted ? 'speaker-muted' : 'speaker');
  }
  var volEl = document.querySelector('#stage .vol');
  volEl.addEventListener('wheel', function (e) {
    e.preventDefault();
    vol = Math.max(0, Math.min(100, vol + (e.deltaY < 0 ? 2 : -2)));
    if (e.deltaY < 0) muted = false;
    paintVol();
  }, { passive: false });
  $('volPct').addEventListener('click', function () { muted = !muted; paintVol(); });
  var outs = ['SPEAKERS', 'HEADPHONES', 'MONITOR'], oi = 0;
  $('volDev').addEventListener('click', function () { oi = (oi + 1) % outs.length; $('volDev').textContent = outs[oi]; });

  // Media: play and pause.
  var playing = true;
  $('mediaPlay').addEventListener('click', function () { playing = !playing; icon('mediaIcon', playing ? 'pause' : 'play'); });

  // Uptime: click previews the orange restart reminder.
  var up = document.querySelector('#stage .uptime'), warn = false;
  up.querySelector('.up-btn').addEventListener('click', function () {
    warn = !warn;
    up.classList.toggle('warn', warn);
    up.querySelector('[data-up="title"]').textContent = warn ? 'RESTART RECOMMENDED' : 'UPTIME';
    up.querySelector('[data-up="value"]').textContent = warn ? '6 DAYS 2 HRS' : '3 DAYS 4 HRS';
  });

  // Recycle Bin: EMPTY empties it.
  $('binEmpty').addEventListener('click', function () {
    $('binSize').textContent = '0 KB';
    icon('binIcon', 'trash-empty');
    this.style.display = 'none';
  });

  // Wi-Fi: click cycles the states the icon can show.
  var wifi = document.querySelector('#stage .wifi');
  var states = [
    ['ok', 'wifi', 'HOME NETWORK'],
    ['nointernet', 'wifi-no-internet-badge', 'NO INTERNET'],
    ['disconnected', 'globe-disconnected', 'NOT CONNECTED'],
    ['ethernet', 'ethernet', 'ETHERNET'],
    ['airplane', 'airplane', 'AIRPLANE MODE']
  ], wi = 0;
  $('wifiBtn').addEventListener('click', function () {
    wi = (wi + 1) % states.length;
    wifi.setAttribute('data-state', states[wi][0]);
    icon('wifiIcon', states[wi][1]);
    $('wifiName').textContent = states[wi][2];
  });

  // Fan Control: the snowflake sends every fan to 100% and back.
  var fan = document.querySelector('#stage .fan');
  $('fanMax').addEventListener('click', function () {
    var on = fan.classList.toggle('max');
    $('fanPct').textContent = on ? '100%' : '42%';
  });

  // SignalRGB: scroll sets the brightness.
  var rgb = 40, rgbEl = document.querySelector('#stage .rgb');
  rgbEl.addEventListener('wheel', function (e) {
    e.preventDefault();
    rgb = Math.max(0, Math.min(100, rgb + (e.deltaY < 0 ? 5 : -5)));
    $('rgbLabel').textContent = 'CASE LIGHTS ' + (rgb ? rgb + '%' : 'OFF');
    rgbEl.querySelector('.srgb').classList.toggle('on', rgb > 0);
  }, { passive: false });

  // DeepCool: click starts or stops the app (accent while it runs).
  var dc = document.querySelector('#stage .dc');
  $('dcBtn').addEventListener('click', function () {
    dc.classList.toggle('on');
  });
})();
