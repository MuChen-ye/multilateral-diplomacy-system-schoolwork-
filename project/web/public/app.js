'use strict';

/* ------------------------------------------------------------------ 基础工具 */
const $ = sel => document.querySelector(sel);
const $$ = sel => Array.from(document.querySelectorAll(sel));

const state = {
  meta: null,
  view: 'overview',
  confs: [],
};

function esc(v) {
  return String(v === null || v === undefined ? '' : v)
    .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;').replace(/'/g, '&#39;');
}

function dash(v) {
  return (v === null || v === undefined || v === '') ? '—' : esc(v);
}

function toast(msg, bad) {
  const el = $('#toast');
  el.textContent = msg;
  el.className = 'toast show' + (bad ? ' bad' : '');
  clearTimeout(toast._t);
  toast._t = setTimeout(() => { el.className = 'toast'; }, bad ? 5200 : 2600);
}

async function api(path, opts) {
  const res = await fetch(path, Object.assign({ headers: { 'Content-Type': 'application/json' } }, opts));
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(data.error || `请求失败（${res.status}）`);
  return data;
}

function tagRisk(risk) {
  const map = { '已完成': 'tag-ok', '已逾期': 'tag-bad', '无计划日期': 'tag-warn', '进行中': 'tag-brand' };
  return `<span class="tag ${map[risk] || ''}">${esc(risk || '未知')}</span>`;
}

function pbar(v) {
  if (v === null || v === undefined) return '<span class="muted">—</span>';
  const n = Math.max(0, Math.min(100, Number(v)));
  return `<div class="pbar"><div class="track"><div class="fill${n < 50 ? ' warn' : ''}" style="width:${n}%"></div></div><span class="muted">${n}%</span></div>`;
}

function loading(el) { el.innerHTML = '<div class="loading">加载中…</div>'; }
function empty(msg) { return `<div class="empty">${esc(msg)}</div>`; }

/* ------------------------------------------------------------------ 视图切换 */
function switchView(name) {
  state.view = name;
  if (location.hash !== '#/' + name) history.replaceState(null, '', '#/' + name);
  $$('.nav-item').forEach(b => b.classList.toggle('active', b.dataset.view === name));
  $$('.view').forEach(v => v.classList.toggle('active', v.id === 'view-' + name));
  loadCurrent();
}

function loadCurrent() {
  const v = state.view;
  if (v === 'overview') return loadOverview();
  if (v === 'conferences') return loadConferences();
  if (v === 'documents') return loadDocuments();
  if (v === 'actions') return loadActions();
  if (v === 'china') return loadChina();
  if (v === 'audit') return loadAudit();
  if (v === 'admin') return initAdmin();
}

/* ------------------------------------------------------------------ 概览 */
async function loadOverview() {
  const wrap = $('#overview-cards');
  loading(wrap);
  try {
    const d = await api('/api/overview');
    const c = d.cards;
    wrap.innerHTML = [
      ['会议', c.conferences, '场'], ['国家', c.countries, '个'], ['成果文件', c.documents, '份'],
      ['后续行动', c.actions, '项'], ['参会记录', c.participants, '条'], ['议题', c.topics, '个'],
    ].map(([k, v, u]) => `<div class="stat"><div class="k">${k}</div><div class="v">${v}<span class="u">${u}</span></div></div>`).join('');

    renderBars('#chart-type', d.byType, '场');
    const riskBars = renderBars('#chart-risk', d.byRisk, '项');
    $('#risk-hint').textContent = riskBars.includes('无计划日期')
      ? '注意：相当一部分行动没有计划完成日期（原始资料未公开），因此“已逾期”只统计有计划日期的记录。'
      : '';

    $('#recent-table').innerHTML = d.recent.length ? `
      <table><thead><tr><th>开始日期</th><th>会议</th><th>类型</th><th>状态</th></tr></thead><tbody>
      ${d.recent.map(r => `<tr class="clickable" data-conf="${r.id}">
        <td>${dash(r.start)}</td><td>${dash(r.short || r.title)}</td>
        <td>${dash(r.type)}</td><td><span class="tag">${dash(r.status)}</span></td></tr>`).join('')}
      </tbody></table>` : empty('暂无会议记录');
  } catch (e) { wrap.innerHTML = ''; toast(e.message, true); }
}

function renderBars(sel, rows, unit) {
  const el = $(sel);
  if (!rows || !rows.length) { el.innerHTML = empty('暂无数据'); return ''; }
  const max = Math.max(...rows.map(r => r.value), 1);
  el.innerHTML = rows.map(r => {
    const cls = /逾期/.test(r.name) ? 'warn' : /完成/.test(r.name) ? 'ok' : '';
    return `<div class="bar-row">
      <div class="bar-label" title="${esc(r.name)}">${esc(r.name)}</div>
      <div class="bar-track"><div class="bar-fill ${cls}" style="width:${(r.value / max * 100).toFixed(1)}%"></div></div>
      <div class="bar-num">${r.value} ${unit || ''}</div>
    </div>`;
  }).join('');
  return el.textContent;
}

/* ------------------------------------------------------------------ 会议 */
async function loadConferences() {
  const box = $('#conf-table');
  loading(box);
  const params = new URLSearchParams();
  const q = $('#conf-q').value.trim();
  const mech = $('#conf-mech').value;
  const year = $('#conf-year').value;
  if (q) params.set('q', q);
  if (mech) params.set('mechanism', mech);
  if (year) params.set('year', year);
  try {
    const rows = await api('/api/conferences?' + params.toString());
    state.confs = rows;
    $('#conf-count').textContent = `共 ${rows.length} 场`;
    if (!rows.length) { box.innerHTML = empty('没有符合条件的会议'); return; }
    box.innerHTML = `<table><thead><tr>
      <th>开始</th><th>会议</th><th>类型</th><th>举办地</th><th>机制</th>
      <th class="num">参会</th><th class="num">议题</th><th class="num">文件</th><th class="num">行动</th><th>状态</th>
    </tr></thead><tbody>
    ${rows.map(r => `<tr class="clickable" data-conf="${r.id}">
      <td class="date">${dash(r.start)}</td>
      <td><strong>${dash(r.short || r.title)}</strong><div class="muted">${dash(r.title)}</div></td>
      <td>${dash(r.type)}</td>
      <td>${dash(r.city)}${r.host ? '<div class="muted">' + dash(r.host) + '</div>' : ''}</td>
      <td>${dash(r.mech)}</td>
      <td class="num">${r.participants}</td><td class="num">${r.topics}</td>
      <td class="num">${r.docs}</td><td class="num">${r.actions}</td>
      <td><span class="tag">${dash(r.status)}</span></td>
    </tr>`).join('')}
    </tbody></table>`;
  } catch (e) { box.innerHTML = ''; toast(e.message, true); }
}

async function openConference(id) {
  const body = $('#drawer-body');
  $('#drawer-title').textContent = '会议详情';
  body.innerHTML = '<div class="loading">加载中…</div>';
  $('#drawer').hidden = false;
  try {
    const d = await api('/api/conferences/' + id);
    const i = d.info;
    $('#drawer-title').textContent = i.short || i.title;
    body.innerHTML = `
      <div class="kv">
        <div class="k">全称</div><div>${dash(i.title)}</div>
        <div class="k">时间</div><div>${dash(i.start)} ~ ${dash(i.end)}</div>
        <div class="k">类型 / 届次</div><div>${dash(i.type)} / ${dash(i.session)}</div>
        <div class="k">举办地</div><div>${dash(i.city)} ${i.host ? '（' + esc(i.host) + '）' : '（线上）'}</div>
        <div class="k">机制 / 组织</div><div>${dash(i.mech)} / ${dash(i.org)}</div>
        <div class="k">形式 / 状态</div><div>${dash(i.format)} / ${dash(i.status)}</div>
        ${i.theme ? `<div class="k">主题</div><div>${esc(i.theme)}</div>` : ''}
      </div>
      <h4>参会国家（${d.participants.length}）</h4>
      ${d.participants.length ? `<table><thead><tr><th>国家</th><th>身份</th><th>级别</th><th class="num">人数</th></tr></thead><tbody>
        ${d.participants.map(p => `<tr><td>${dash(p.country)} <span class="muted">${dash(p.iso)}</span></td>
          <td>${dash(p.role)}</td><td>${dash(p.level)}</td><td class="num">${dash(p.size)}</td></tr>`).join('')}
      </tbody></table>` : empty('未登记参会国家')}
      <h4>议题（${d.topics.length}）</h4>
      ${d.topics.length ? `<table><thead><tr><th>议题</th><th>领域</th><th>核心</th><th>讨论日期</th></tr></thead><tbody>
        ${d.topics.map(t => `<tr><td>${dash(t.name)}</td><td>${dash(t.category)}</td>
          <td>${t.core ? '<span class="tag tag-brand">核心</span>' : ''}</td><td>${dash(t.date)}</td></tr>`).join('')}
      </tbody></table>` : empty('未挂接议题')}
      <h4>成果文件（${d.documents.length}）</h4>
      ${d.documents.length ? `<table><thead><tr><th>编号</th><th>标题</th><th>类型</th><th>通过方式</th><th>日期</th></tr></thead><tbody>
        ${d.documents.map(x => `<tr class="clickable" data-doc="${x.id}"><td>${dash(x.no)}</td>
          <td>${dash(x.title)}</td><td>${dash(x.type)}</td><td>${dash(x.method)}</td><td>${dash(x.date)}</td></tr>`).join('')}
      </tbody></table>` : empty('未登记成果文件')}
      <h4>后续行动（${d.actions.length}）</h4>
      ${d.actions.length ? `<table><thead><tr><th>行动</th><th>牵头国</th><th>计划</th><th>实际</th><th>进度</th></tr></thead><tbody>
        ${d.actions.map(a => `<tr><td>${dash(a.name)}</td><td>${dash(a.lead)}</td>
          <td>${dash(a.planned)}</td><td>${dash(a.actual)}</td><td>${pbar(a.progress)}</td></tr>`).join('')}
      </tbody></table>` : empty('暂无后续行动')}`;
  } catch (e) { body.innerHTML = ''; toast(e.message, true); }
}

/* ------------------------------------------------------------------ 成果文件 */
async function loadDocuments() {
  const box = $('#doc-table');
  loading(box);
  const q = $('#doc-q').value.trim();
  try {
    const rows = await api('/api/documents' + (q ? '?q=' + encodeURIComponent(q) : ''));
    $('#doc-count').textContent = `共 ${rows.length} 份`;
    if (!rows.length) { box.innerHTML = empty('没有符合条件的文件'); return; }
    box.innerHTML = `<table><thead><tr>
      <th class="date">通过日期</th><th>编号</th><th>标题</th><th>类型</th><th>方式</th><th>会议</th>
      <th class="num">联署</th><th class="num">支持</th><th class="num">保留</th><th>联署率</th>
    </tr></thead><tbody>
    ${rows.map(r => `<tr class="clickable" data-doc="${r.id}">
      <td class="date">${dash(r.date)}</td><td>${dash(r.no)}</td>
      <td><strong>${dash(r.title)}</strong></td>
      <td>${dash(r.type)}</td><td>${dash(r.method)}</td><td>${dash(r.conference)}</td>
      <td class="num">${r.signed}</td><td class="num">${r.support}</td><td class="num">${r.reserved}</td>
      <td>${r.total === 0 ? '<span class="muted">无表态</span>' : pbar(r.rate)}</td>
    </tr>`).join('')}
    </tbody></table>
    <p class="hint">联署率＝联署国数 ÷ 表态国总数，由数据库函数 fn_consensus_ratio 计算，与 SQL 脚本口径一致。</p>`;
  } catch (e) { box.innerHTML = ''; toast(e.message, true); }
}

async function openDocument(id) {
  const body = $('#drawer-body');
  $('#drawer-title').textContent = '成果文件详情';
  body.innerHTML = '<div class="loading">加载中…</div>';
  $('#drawer').hidden = false;
  try {
    const d = await api('/api/documents/' + id);
    const i = d.info;
    $('#drawer-title').textContent = i.title;
    body.innerHTML = `
      <div class="kv">
        <div class="k">编号</div><div>${dash(i.no)}</div>
        <div class="k">类型 / 方式</div><div>${dash(i.type)} / ${dash(i.method)}</div>
        <div class="k">通过日期</div><div>${dash(i.date)}</div>
        <div class="k">所属会议</div><div>${dash(i.conference)}</div>
        <div class="k">状态</div><div>${dash(i.status)}</div>
        <div class="k">联署率</div><div>${i.rate === null ? '—' : i.rate + '%'}</div>
        ${i.summary ? `<div class="k">摘要</div><div>${esc(i.summary)}</div>` : ''}
      </div>
      <h4>联署与表态（${d.sponsors.length}）</h4>
      ${d.sponsors.length ? `<table><thead><tr><th>国家</th><th>ISO</th><th>态度</th></tr></thead><tbody>
        ${d.sponsors.map(s => `<tr><td>${dash(s.country)}</td><td>${dash(s.iso)}</td>
          <td>${s.stance === '联署' ? '<span class="tag tag-ok">联署</span>'
              : s.stance === '支持' ? '<span class="tag tag-brand">支持</span>'
              : '<span class="tag tag-warn">' + dash(s.stance) + '</span>'}</td></tr>`).join('')}
      </tbody></table>` : empty('该文件暂无表态记录')}`;
  } catch (e) { body.innerHTML = ''; toast(e.message, true); }
}

/* ------------------------------------------------------------------ 后续行动 */
async function loadActions() {
  const box = $('#act-table');
  loading(box);
  const params = new URLSearchParams();
  const q = $('#act-q').value.trim();
  const risk = $('#act-risk').value;
  if (q) params.set('q', q);
  if (risk) params.set('risk', risk);
  try {
    const rows = await api('/api/actions?' + params.toString());
    $('#act-count').textContent = `共 ${rows.length} 项`;
    if (!rows.length) { box.innerHTML = empty('没有符合条件的行动'); return; }
    box.innerHTML = `<table><thead><tr>
      <th class="num">ID</th><th>行动</th><th>会议</th><th>牵头国</th><th>责任组织</th>
      <th>计划完成</th><th>实际完成</th><th>进度</th><th>状态</th><th>风险</th>
    </tr></thead><tbody>
    ${rows.map(r => `<tr class="clickable" data-act="${r.id}">
      <td class="num">${r.id}</td><td>${dash(r.name)}</td><td>${dash(r.conference)}</td>
      <td>${dash(r.lead)}</td><td>${dash(r.org)}</td>
      <td>${dash(r.planned)}</td><td>${dash(r.actual)}</td>
      <td>${pbar(r.progress)}</td><td><span class="tag">${dash(r.status)}</span></td>
      <td>${tagRisk(r.risk)}${r.risk === '已逾期' && r.overdueDays > 0 ? `<div class="muted">逾期 ${r.overdueDays} 天</div>` : ''}</td>
    </tr>`).join('')}
    </tbody></table>`;
  } catch (e) { box.innerHTML = ''; toast(e.message, true); }
}

async function openAction(id) {
  const body = $('#drawer-body');
  $('#drawer-title').textContent = '更新行动进度';
  body.innerHTML = '<div class="loading">加载中…</div>';
  $('#drawer').hidden = false;
  try {
    const rows = await api('/api/actions');
    const a = rows.find(r => r.id === Number(id));
    if (!a) throw new Error('行动不存在');
    body.innerHTML = `
      <div class="kv">
        <div class="k">行动</div><div>${dash(a.name)}</div>
        <div class="k">会议</div><div>${dash(a.conference)}</div>
        <div class="k">牵头国</div><div>${dash(a.lead)}</div>
        <div class="k">计划完成</div><div>${dash(a.planned)}</div>
        <div class="k">当前风险</div><div>${tagRisk(a.risk)}</div>
      </div>
      <h4>修改</h4>
      <form id="form-act" class="form">
        <label>进度（0~100）
          <input class="input" type="number" name="progress" min="0" max="100" value="${a.progress === null ? '' : a.progress}">
        </label>
        <label>状态
          <select class="input" name="status">
            <option value="">（不改）</option>
            ${['未启动', '进行中', '已完成', '逾期', '终止'].map(s =>
              `<option value="${s}" ${a.status === s ? 'selected' : ''}>${s}</option>`).join('')}
          </select>
        </label>
        <label>实际完成日期
          <input class="input" type="date" name="actual" value="${a.actual || ''}">
        </label>
        <button class="btn btn-primary" type="submit">保存修改</button>
        <p class="hint">修改会触发 trg_action_audit 写入审计日志。标为“已完成”时必须同时填实际完成日期（数据库 CHECK 约束）；进度填 150 之类会被拒绝，可以顺手试一下。</p>
      </form>`;
    $('#form-act').addEventListener('submit', async ev => {
      ev.preventDefault();
      const f = ev.target;
      const payload = {
        progress: f.progress.value,
        status: f.status.value,
        actual: f.actual.value,
      };
      try {
        const r = await api('/api/actions/' + id, { method: 'PUT', body: JSON.stringify(payload) });
        toast(`已保存：进度 ${r.progress ?? '—'}，状态 ${r.status ?? '—'}`);
        $('#drawer').hidden = true;
        loadActions();
      } catch (e) { toast(e.message, true); }
    });
  } catch (e) { body.innerHTML = ''; toast(e.message, true); }
}

/* ------------------------------------------------------------------ 中国参与 */
async function loadChina() {
  const box = $('#china-table');
  loading(box);
  try {
    const rows = await api('/api/china');
    const cards = $('#china-cards');
    if (!rows.length) {
      cards.innerHTML = '';
      box.innerHTML = empty('视图 v_china_multilateral 暂无数据');
      return;
    }
    const total = rows.length;
    const hosted = rows.filter(r => r.role && r.role.includes('主办')).length;
    const sizes = rows.map(r => Number(r.size)).filter(n => Number.isFinite(n) && n > 0);
    const avg = sizes.length ? Math.round(sizes.reduce((a, b) => a + b, 0) / sizes.length) : null;
    const signed = rows.reduce((a, r) => a + Number(r.signed || 0), 0);
    cards.innerHTML = [
      ['中国参与会议', total, '场'], ['其中中方主办', hosted, '场'],
      ['平均代表团人数', avg === null ? '—' : avg, avg === null ? '' : '人'], ['中方联署文件', signed, '份'],
    ].map(([k, v, u]) => `<div class="stat"><div class="k">${k}</div><div class="v">${v}<span class="u">${u}</span></div></div>`).join('');

    box.innerHTML = `<table><thead><tr>
      <th>会议</th><th>类型</th><th>开始</th><th>地点</th><th>机制</th>
      <th>中国身份</th><th>级别</th><th class="num">人数</th>
      <th class="num">文件</th><th class="num">中国联署</th>
    </tr></thead><tbody>
    ${rows.map(r => `<tr>
      <td>${dash(r.conference)}</td><td>${dash(r.type)}</td><td>${dash(r.start)}</td>
      <td>${dash(r.city)}${r.host ? '<div class="muted">' + dash(r.host) + '</div>' : ''}</td>
      <td>${dash(r.mech)}</td>
      <td>${r.role ? '<span class="tag tag-brand">' + esc(r.role) + '</span>' : '—'}</td>
      <td>${dash(r.level)}</td><td class="num">${dash(r.size)}</td>
      <td class="num">${dash(r.docs)}</td><td class="num">${dash(r.signed)}</td>
    </tr>`).join('')}
    </tbody></table>`;
  } catch (e) { box.innerHTML = ''; toast(e.message, true); }
}

/* ------------------------------------------------------------------ 审计 */
async function loadAudit() {
  const box = $('#audit-table');
  loading(box);
  try {
    const rows = await api('/api/audit');
    if (!rows.length) { box.innerHTML = empty('暂无审计记录（对行动状态/进度的修改会自动写入这里）'); return; }
    box.innerHTML = `<table><thead><tr>
      <th>时间</th><th>用户</th><th>操作</th><th>目标</th><th>变更前</th><th>变更后</th><th>说明</th>
    </tr></thead><tbody>
    ${rows.map(r => `<tr>
      <td>${dash(r.time)}</td><td>${dash(r.user)}</td><td>${dash(r.type)}</td>
      <td>${dash(r.table)} #${dash(r.target)}</td>
      <td class="muted">${dash(r.old)}</td><td>${dash(r.new)}</td><td class="muted">${dash(r.detail)}</td>
    </tr>`).join('')}
    </tbody></table>`;
  } catch (e) { box.innerHTML = ''; toast(e.message, true); }
}

/* ------------------------------------------------------------------ 数据维护 */
async function initAdmin() {
  if (state.adminReady) return;
  state.adminReady = true;
  try {
    const m = state.meta || await api('/api/meta');
    const opt = (arr, label) => '<option value="">（不指定）</option>' +
      arr.map(x => `<option value="${x.id}">${esc(label(x))}</option>`).join('');
    $('#form-mech').innerHTML = opt(m.mechanisms, x => x.name);
    $('#form-country').innerHTML = opt(m.countries, x => x.name);
    $('#form-country2').innerHTML = m.countries.map(x => `<option value="${x.id}">${esc(x.name)}</option>`).join('');
  } catch (e) { toast(e.message, true); }
}

function bindAdmin() {
  $('#form-conf').addEventListener('submit', async ev => {
    ev.preventDefault();
    const f = ev.target;
    const payload = {
      title: f.title.value.trim(),
      short_name: f.short_name.value.trim(),
      conference_type: f.conference_type.value,
      start_date: f.start_date.value,
      end_date: f.end_date.value || null,
      mechanism_id: f.mechanism_id.value || null,
      host_country_id: f.host_country_id.value || null,
      host_city: f.host_city.value.trim() || null,
    };
    try {
      const r = await api('/api/conferences', { method: 'POST', body: JSON.stringify(payload) });
      toast(`已新增会议 #${r.id}`);
      f.reset();
      loadConferences();
    } catch (e) { toast(e.message, true); }
  });

  $('#form-part').addEventListener('submit', async ev => {
    ev.preventDefault();
    const f = ev.target;
    const payload = {
      conference_id: f.conference_id.value,
      country_id: f.country_id.value,
      role: f.role.value,
      delegation_size: f.delegation_size.value,
    };
    try {
      await api('/api/participants', { method: 'POST', body: JSON.stringify(payload) });
      toast('参会登记已保存');
      f.reset();
    } catch (e) { toast(e.message, true); }
  });

  // 约束演示：两个都是“故意做错”，预期失败，不会改数据
  $('#btn-bad-progress').addEventListener('click', async () => {
    try {
      await api('/api/actions/1', { method: 'PUT', body: JSON.stringify({ progress: 150 }) });
      toast('意外成功了：数据库没有拦住进度 150', true);
    } catch (e) {
      toast('数据库拒绝：' + e.message, true);
    }
  });

  $('#btn-dup-part').addEventListener('click', async () => {
    try {
      const d = await api('/api/conferences/1');
      const p = d.participants[0];
      if (!p) return toast('1 号会议没有参会记录，无法演示', true);
      const meta = state.meta || await api('/api/meta');
      const country = meta.countries.find(c => c.name === p.country);
      await api('/api/participants', {
        method: 'POST',
        body: JSON.stringify({
          conference_id: 1, country_id: country.id, role: p.role,
          delegation_level: p.level, delegation_size: p.size,
        }),
      });
      toast('意外成功了：重复参会没有被拦住', true);
    } catch (e) {
      toast('数据库拒绝：' + e.message, true);
    }
  });
}

/* ------------------------------------------------------------------ 事件绑定 */
function bind() {
  $$('.nav-item').forEach(b => b.addEventListener('click', () => switchView(b.dataset.view)));
  $('#btn-refresh').addEventListener('click', () => loadCurrent());
  $('#drawer-close').addEventListener('click', () => { $('#drawer').hidden = true; });

  $('#conf-search').addEventListener('click', loadConferences);
  $('#doc-search').addEventListener('click', loadDocuments);
  $('#act-search').addEventListener('click', loadActions);
  $('#conf-q').addEventListener('keydown', e => { if (e.key === 'Enter') loadConferences(); });
  $('#doc-q').addEventListener('keydown', e => { if (e.key === 'Enter') loadDocuments(); });
  $('#act-q').addEventListener('keydown', e => { if (e.key === 'Enter') loadActions(); });

  document.body.addEventListener('click', e => {
    const conf = e.target.closest('[data-conf]');
    const doc = e.target.closest('[data-doc]');
    const act = e.target.closest('[data-act]');
    if (conf) return openConference(conf.dataset.conf);
    if (doc) return openDocument(doc.dataset.doc);
    if (act) return openAction(act.dataset.act);
  });

  bindAdmin();
}

/* ------------------------------------------------------------------ 启动 */
async function boot() {
  bind();
  try {
    const h = await api('/api/health');
    const pill = $('#conn');
    pill.className = 'pill pill-ok';
    pill.textContent = `已连接 · MySQL ${h.version}`;
    $('#side-version').textContent = `${h.tables} 表 / ${h.views} 视图`
      + (h.triggers ? ` / ${h.triggers} 触发器` : '');
    const m = await api('/api/meta');
    state.meta = m;
    $('#conf-mech').innerHTML = '<option value="">全部机制</option>' +
      m.mechanisms.map(x => `<option value="${x.id}">${esc(x.name)}</option>`).join('');
    $('#conf-year').innerHTML = '<option value="">全部年份</option>' +
      m.years.map(y => `<option value="${y.year}">${y.year}</option>`).join('');
    const wanted = (location.hash.match(/^#\/(\w+)$/) || [])[1]
      || new URLSearchParams(location.search).get('view');
    switchView(wanted || 'overview');
  } catch (e) {
    const pill = $('#conn');
    pill.className = 'pill pill-bad';
    pill.textContent = '连接失败';
    toast('无法连接数据库：' + e.message, true);
  }
}

boot();
