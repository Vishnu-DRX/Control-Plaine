// Demo switches: LEFT/RIGHT alignment and DARK/LIGHT mode. No external requests.
(function () {
  var stage = document.getElementById('stage');
  if (!stage) return;
  document.querySelectorAll('.switch').forEach(function (group) {
    var key = group.getAttribute('data-switch');
    group.addEventListener('click', function (e) {
      var btn = e.target.closest('button');
      if (!btn) return;
      stage.setAttribute('data-' + key, btn.getAttribute('data-value'));
      group.querySelectorAll('button').forEach(function (b) {
        b.setAttribute('aria-pressed', b === btn ? 'true' : 'false');
      });
    });
  });
})();
