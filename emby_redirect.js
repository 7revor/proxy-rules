const isTV = $environment.system === "tvOS";
if ($argument && $network.wifi || isTV) {
  const args = $argument.split(",");
  console.log("length:"+args.length)
  if (args.length === 3) {
    const [ssid, source, target] = args;
    if ($network.wifi.ssid === ssid || isTV) {
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
