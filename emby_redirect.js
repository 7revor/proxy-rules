if (!$argument || !$network.wifi) $done({});
const args = $argument.split(",");
if (args.length !== 3) $done({});
const [ssid, source, target] = args;
const isInternal = $network.wifi.ssid ? $network.wifi.ssid === ssid : $environment.system === "tvOS";
if (!isInternal) $done({});
$done({ url: $request.url.replace(source, target) });
