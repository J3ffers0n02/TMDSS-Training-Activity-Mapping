fetch('/env.js')
  .then(res => res.text())
  .then(eval)
  .then(() => {
    const script = document.createElement("script");
    script.src = "https://maps.googleapis.com/maps/api/js?key=" + window.GOOGLE_MAPS_API_KEY;
    document.head.appendChild(script);
  });
