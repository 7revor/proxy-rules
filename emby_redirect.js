if ($argument && $network.wifi) {
  const args = $argument.split(",");
  if (args.length === 3) {
    const [ssid, source, target] = args;
    if ($network.wifi.ssid === ssid) {
      $done({ url: $request.url.replace(source, target) });
    } else {
      $done({});
    }
  } else {
    $done({});
  }
} else {
  $done({});
}
