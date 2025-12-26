if (!$argument || !$network.v4) $done({});
const args = $argument.split(",");
if (args.length !== 3) $done({});
const [router, source, target] = args;
const isInternal = $network.v4.primaryRouter === router;
if (!isInternal) $done({});
$done({ url: $request.url.replace(source, target) });
