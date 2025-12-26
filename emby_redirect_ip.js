if (!$argument || !$network.ipv4) $done({});
const args = $argument.split(",");
if (args.length !== 3) $done({});
const [router, source, target] = args;
const isInternal = $network.ipv4.primaryRouter === router;
if (!isInternal) $done({});
$done({ url: $request.url.replace(source, target) });
