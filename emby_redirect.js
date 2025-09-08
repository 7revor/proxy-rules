console.log($network.wifi);
console.log($argument);
console.log($request.url)
if ($argument && $network.wifi) {
  const args = $argument.split(",");
  console.log("length:"+args.length)
  if (args.length === 3) {
    const [ssid, source, target] = args;
    console.log(ssid)
    console.log(source)
    console.log(target)
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
