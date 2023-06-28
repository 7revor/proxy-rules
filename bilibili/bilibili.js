const url = $request.url;
if (!$response.body) $done({});

if (url.includes("/x/v2/account/myinfo")) {
  const body = JSON.parse($response.body);
  if (body.data.vip.status !== 1) {
    body.data.vip_type = 2;
    body.data.vip.type = 2;
    body.data.vip.status = 1;
    body.data.vip.vip_pay_type = 1;
    body.data.vip.due_date = 2208960000; // Unix 时间戳 2040-01-01 00:00:00
    body.data.vip.role = 3;
    $done({ body: JSON.stringify(body) });
  }
}

$done({});
