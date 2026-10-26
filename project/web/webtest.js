// Web 界面后端回归测试：node webtest.js
const B = 'http://127.0.0.1:8765';
let pass = 0, fail = 0;
const ok = (cond, name, extra = '') => {
  if (cond) { pass++; console.log('  ✓', name, extra); }
  else { fail++; console.log('  ✗', name, extra); }
};
const j = async (p, o) => {
  const r = await fetch(B + p, o);
  let body = null;
  try { body = await r.json(); } catch { body = null; }
  return { s: r.status, b: body };
};
const put = (p, obj) => j(p, { method: 'PUT', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(obj) });
const post = (p, obj) => j(p, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(obj) });

(async () => {
  console.log('— 基础 —');
  let r = await j('/api/health');
  ok(r.s === 200 && r.b.tables === 12 && r.b.views === 6 && r.b.triggers === 4, 'health 对象数', JSON.stringify({ t: r.b?.tables, v: r.b?.views, g: r.b?.triggers }));

  r = await j('/api/meta');
  ok(r.s === 200 && r.b.mechanisms.length === 17 && r.b.countries.length === 69, 'meta 机制/国家数');

  r = await j('/api/overview');
  ok(r.s === 200 && r.b.cards.conferences === 50, 'overview 会议数', String(r.b?.cards?.conferences));
  ok(Array.isArray(r.b.byRisk) && r.b.byRisk.length > 0, 'overview 风险分布非空');

  console.log('— 会议 —');
  r = await j('/api/conferences');
  ok(r.s === 200 && r.b.length === 50, '会议列表 50');
  const c33 = r.b.find(x => x.id === 33);
  ok(!!c33 && c33.participants > 0, '33 号会议参会数 > 0');

  r = await j('/api/conferences?year=2026');
  ok(r.s === 200 && r.b.length === 10, '按年筛选 2026=10');
  r = await j('/api/conferences?q=上合');
  ok(r.s === 200 && r.b.length > 0 && r.b.every(x => /上合/.test(x.short + x.title)), '关键词搜索只返回匹配项', String(r.b.length));
  r = await j('/api/conferences?mechanism=99999');
  ok(r.s === 200 && r.b.length === 0, '不存在的机制 → 空数组（不是 500）');

  r = await j('/api/conferences/33');
  ok(r.s === 200 && r.b.info && r.b.participants.length > 0, '会议详情');
  r = await j('/api/conferences/999999');
  ok(r.s === 404, '不存在会议 → 404', String(r.s));

  console.log('— 文件 —');
  r = await j('/api/documents');
  ok(r.s === 200 && r.b.length === 56, '文件列表 56');
  ok(r.b.every(d => d.rate === null || (d.rate >= 0 && d.rate <= 100)), '联署率范围合法');
  r = await j('/api/documents?q=联合公报');
  ok(r.s === 200, '文件搜索 200');
  r = await j('/api/documents/39');
  ok(r.s === 200 && r.b.info, '文件详情');
  r = await j('/api/documents/999999');
  ok(r.s === 404, '不存在文件 → 404');

  console.log('— 行动 —');
  r = await j('/api/actions');
  ok(r.s === 200 && r.b.length === 38, '行动列表 38');
  ok(r.b.every(a => a.risk && a.risk.length > 0), '每条行动都有风险判定');
  r = await j('/api/actions?risk=overdue');
  ok(r.s === 200 && Array.isArray(r.b), '逾期筛选返回数组');
  r = await j('/api/actions?q=不存在的东西');
  ok(r.s === 200 && r.b.length === 0, '行动搜索空结果');

  console.log('— 写入与约束 —');
  r = await put('/api/actions/1', { progress: 45 });
  ok(r.s === 200 && r.b.progress === 45, '改进度 45');
  r = await put('/api/actions/1', { progress: 150 });
  ok(r.s === 400 && /0~100/.test(r.b.error), '非法进度被拒', r.b?.error);
  r = await put('/api/actions/1', { status: '已完成' });
  ok(r.s === 500 || r.s === 400, '已完成但无完成日期被拒', `${r.s} ${r.b?.error}`);
  r = await put('/api/actions/1', { status: '瞎写' });
  ok(r.s === 400, '非法状态被白名单拦截');
  r = await put('/api/actions/1', {});
  ok(r.s === 400, '空更新被拒');

  r = await j('/api/audit');
  ok(r.s === 200 && r.b.length >= 1, '审计日志已产生', String(r.b.length));

  console.log('— 静态与错误处理 —');
  for (const p of ['/', '/index.html', '/app.js', '/style.css']) {
    const res = await fetch(B + p);
    ok(res.status === 200, '静态文件 ' + p);
  }
  ok((await fetch(B + '/../../etc/passwd')).status >= 400, '路径穿越被拒');
  r = await j('/api/nope');
  ok(r.s === 404, '未知接口 404');

  console.log(`\n通过 ${pass}，失败 ${fail}`);
  process.exit(fail ? 1 : 0);
})();
