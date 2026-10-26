#!/usr/bin/env node
/**
 * 多边外交数据库 · 轻量 Web 界面（零依赖）
 *
 * 设计取舍：不装 express / mysql2，直接 spawn 系统里的 mysql.exe，用
 * MySQL 的 JSON_OBJECT / JSON_ARRAYAGG 把结果整段取回再 JSON.parse。
 * 好处是换台机器只要有 node + mysql 就能跑，不受 npm 源影响。
 *
 * 运行：node server.js   （默认 http://127.0.0.1:8765）
 */
'use strict';

const http = require('http');
const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');

// ---------------------------------------------------------------- 配置
const PORT = Number(process.env.PORT || 8765);
const HOST = '127.0.0.1';
const MYSQL = process.env.MYSQL_BIN || 'C:/Program Files/MySQL/MySQL Server 9.4/bin/mysql.exe';
const DB = process.env.DB_NAME || 'multilateral-diplomacy-system-schoolwork-';
const PUBLIC_DIR = path.join(__dirname, 'public');
const CRED_FILE = process.env.MYSQL_CRED || 'C:/Users/nbd99/.dsh-backups/db/mysql-root.txt';

function readPassword() {
  if (process.env.MYSQL_PWD) return process.env.MYSQL_PWD;
  try {
    const line = fs.readFileSync(CRED_FILE, 'utf8').split(/\r?\n/)
      .find(l => l.startsWith('password='));
    return line ? line.slice('password='.length) : '';
  } catch {
    return '';
  }
}
const PWD = readPassword();

// ---------------------------------------------------------------- mysql 调用
function mysqlRun(sql) {
  return new Promise((resolve, reject) => {
    const p = spawn(MYSQL, ['-u', 'root', '--default-character-set=utf8mb4',
      '-B', '-N', '--raw', '-D', DB, '-e', sql],
      { env: { ...process.env, MYSQL_PWD: PWD }, windowsHide: true });
    let out = '', err = '';
    p.stdout.setEncoding('utf8');
    p.stderr.setEncoding('utf8');
    p.stdout.on('data', d => (out += d));
    p.stderr.on('data', d => (err += d));
    p.on('error', reject);
    p.on('close', code => {
      if (code === 0) return resolve(out.replace(/\r?\n$/, ''));
      reject(new Error((err || `mysql 退出码 ${code}`).trim()));
    });
  });
}

/** 取一段 JSON 文本（JSON_ARRAYAGG 为空时返回 null，这里统一成数组）。 */
async function jsonArray(sql) {
  const txt = await mysqlRun(sql);
  if (!txt || txt === 'NULL') return [];
  const v = JSON.parse(txt);
  return Array.isArray(v) ? v : [];
}

async function jsonObject(sql) {
  const txt = await mysqlRun(sql);
  return (txt && txt !== 'NULL') ? JSON.parse(txt) : null;
}

// ---------------------------------------------------------------- SQL 安全
function str(v) {
  if (v === null || v === undefined) return 'NULL';
  return "'" + String(v)
    .replace(/\\/g, '\\\\')
    .replace(/'/g, "''")
    .replace(/\n/g, '\\n')
    .replace(/\r/g, '\\r')
    .replace(/\x1a/g, '\\Z') + "'";
}

function int(v, name) {
  const n = Number(v);
  if (!Number.isInteger(n) || n < 0) throw new HttpError(400, `${name} 必须是正整数`);
  return n;
}

function like(v) {
  return "'%" + String(v).replace(/[\\%_']/g, m => '\\' + m) + "%'";
}

class HttpError extends Error {
  constructor(status, message) { super(message); this.status = status; }
}

// ---------------------------------------------------------------- 业务查询
const api = {};

api.health = async () => {
  const version = (await mysqlRun('SELECT VERSION()')).trim();
  const t = await jsonObject(`SELECT JSON_OBJECT(
      'tables', (SELECT COUNT(*) FROM information_schema.tables
                  WHERE table_schema = DATABASE() AND table_type='BASE TABLE'),
      'views',  (SELECT COUNT(*) FROM information_schema.views WHERE table_schema = DATABASE()),
      'triggers',(SELECT COUNT(*) FROM information_schema.triggers WHERE trigger_schema = DATABASE()),
      'routines',(SELECT COUNT(*) FROM information_schema.routines WHERE routine_schema = DATABASE()))`);
  return { ok: true, db: DB, version, ...t, mySqlBin: MYSQL };
};

api.meta = async () => jsonObject(`SELECT JSON_OBJECT(
    'mechanisms', (SELECT JSON_ARRAYAGG(t.j) FROM (
        SELECT JSON_OBJECT('id', mechanism_id, 'name', name) j FROM mechanism ORDER BY mechanism_id) t),
    'countries', (SELECT JSON_ARRAYAGG(t.j) FROM (
        SELECT JSON_OBJECT('id', country_id, 'name', name_cn, 'iso', iso_code) AS j
        FROM country ORDER BY name_cn) t),
    'types', (SELECT JSON_ARRAYAGG(t.j) FROM (
        SELECT JSON_OBJECT('name', v) j FROM (
            SELECT DISTINCT conference_type v FROM conference WHERE conference_type IS NOT NULL) x
        ORDER BY v) t),
    'years', (SELECT JSON_ARRAYAGG(t.j) FROM (
        SELECT JSON_OBJECT('year', y) j FROM (
            SELECT DISTINCT YEAR(start_date) y FROM conference WHERE start_date IS NOT NULL
            ORDER BY y DESC) x) t))`);

api.overview = async () => jsonObject(`SELECT JSON_OBJECT(
    'cards', (SELECT JSON_OBJECT(
        'conferences', (SELECT COUNT(*) FROM conference),
        'countries',   (SELECT COUNT(*) FROM country),
        'documents',   (SELECT COUNT(*) FROM document),
        'actions',     (SELECT COUNT(*) FROM follow_up_action),
        'participants',(SELECT COUNT(*) FROM conference_participant),
        'topics',      (SELECT COUNT(*) FROM topic))),
    'byType', (SELECT JSON_ARRAYAGG(t.j) FROM (
        SELECT JSON_OBJECT('name', conference_type, 'value', c) j FROM (
            SELECT COALESCE(conference_type,'未标注') conference_type, COUNT(*) c
            FROM conference GROUP BY conference_type ORDER BY c DESC) x) t),
    'byYear', (SELECT JSON_ARRAYAGG(t.j) FROM (
        SELECT JSON_OBJECT('name', y, 'value', c) j FROM (
            SELECT YEAR(start_date) y, COUNT(*) c FROM conference
            WHERE start_date IS NOT NULL GROUP BY YEAR(start_date) ORDER BY y DESC) x) t),
    'byRisk', (SELECT JSON_ARRAYAGG(t.j) FROM (
        SELECT JSON_OBJECT('name', r, 'value', c) j FROM (
            SELECT CASE
                     WHEN actual_end_date IS NOT NULL THEN '已完成'
                     WHEN planned_end_date IS NULL THEN '无计划日期'
                     WHEN planned_end_date < CURDATE() THEN '已逾期'
                     ELSE '进行中' END r,
                   COUNT(*) c
            FROM follow_up_action GROUP BY r ORDER BY c DESC) x) t),
    'recent', (SELECT JSON_ARRAYAGG(t.j) FROM (
        SELECT JSON_OBJECT('id', conference_id, 'short', short_name, 'title', title,
                           'start', DATE_FORMAT(start_date,'%Y-%m-%d'),
                           'type', conference_type, 'status', status) j
        FROM conference WHERE start_date IS NOT NULL
        ORDER BY start_date DESC LIMIT 8) t))`);

api.conferences = async (q) => {
  const where = [];
  if (q.mechanism) where.push(`c.mechanism_id = ${int(q.mechanism, 'mechanism')}`);
  if (q.year) where.push(`YEAR(c.start_date) = ${int(q.year, 'year')}`);
  if (q.q) where.push(`(c.title LIKE ${like(q.q)} OR c.short_name LIKE ${like(q.q)} OR c.host_city LIKE ${like(q.q)})`);
  const w = where.length ? 'WHERE ' + where.join(' AND ') : '';
  return jsonArray(`SELECT JSON_ARRAYAGG(t.j) FROM (
    SELECT JSON_OBJECT(
      'id', c.conference_id, 'short', c.short_name, 'title', c.title,
      'type', c.conference_type, 'session', c.session_label,
      'start', DATE_FORMAT(c.start_date,'%Y-%m-%d'), 'end', DATE_FORMAT(c.end_date,'%Y-%m-%d'),
      'status', c.status, 'host', hc.name_cn, 'city', c.host_city,
      'mech', m.name, 'format', c.format,
      'participants', (SELECT COUNT(*) FROM conference_participant p WHERE p.conference_id = c.conference_id),
      'topics', (SELECT COUNT(*) FROM conference_topic t WHERE t.conference_id = c.conference_id),
      'docs', (SELECT COUNT(*) FROM document d WHERE d.conference_id = c.conference_id),
      'actions', (SELECT COUNT(*) FROM follow_up_action a WHERE a.conference_id = c.conference_id)) j
    FROM conference c
    LEFT JOIN country hc ON hc.country_id = c.host_country_id
    LEFT JOIN mechanism m ON m.mechanism_id = c.mechanism_id
    ${w}
    ORDER BY c.start_date DESC, c.conference_id DESC) t`);
};

api.conferenceDetail = async (id) => {
  const cid = int(id, 'conference_id');
  const info = await jsonObject(`SELECT JSON_OBJECT(
      'id', c.conference_id, 'title', c.title, 'short', c.short_name,
      'type', c.conference_type, 'session', c.session_label,
      'start', DATE_FORMAT(c.start_date,'%Y-%m-%d'), 'end', DATE_FORMAT(c.end_date,'%Y-%m-%d'),
      'status', c.status, 'format', c.format, 'theme', c.theme,
      'host', hc.name_cn, 'city', c.host_city, 'mech', m.name, 'org', o.name_cn)
    FROM conference c
    LEFT JOIN country hc ON hc.country_id = c.host_country_id
    LEFT JOIN mechanism m ON m.mechanism_id = c.mechanism_id
    LEFT JOIN international_organization o ON o.org_id = c.org_id
    WHERE c.conference_id = ${cid}`);
  if (!info) throw new HttpError(404, '会议不存在');
  const participants = await jsonArray(`SELECT JSON_ARRAYAGG(t.j) FROM (
      SELECT JSON_OBJECT('country', cn.name_cn, 'iso', cn.iso_code, 'role', p.role,
        'level', p.delegation_level, 'size', p.delegation_size) j
      FROM conference_participant p JOIN country cn ON cn.country_id = p.country_id
      WHERE p.conference_id = ${cid}
      ORDER BY FIELD(p.role,'主办国','主席国','成员国','观察员','嘉宾国'), cn.name_cn) t`);
  const topics = await jsonArray(`SELECT JSON_ARRAYAGG(t.j) FROM (
      SELECT JSON_OBJECT('name', t.name, 'category', t.category, 'core', ct.is_core,
        'date', DATE_FORMAT(ct.discussion_date,'%Y-%m-%d')) j
      FROM conference_topic ct JOIN topic t ON t.topic_id = ct.topic_id
      WHERE ct.conference_id = ${cid} ORDER BY ct.is_core DESC, t.name) t`);
  const documents = await jsonArray(`SELECT JSON_ARRAYAGG(t.j) FROM (
      SELECT JSON_OBJECT('id', d.document_id, 'no', d.doc_no, 'title', d.title,
        'type', d.doc_type, 'method', d.adopt_method, 'status', d.status,
        'date', DATE_FORMAT(d.issue_date,'%Y-%m-%d')) j
      FROM document d WHERE d.conference_id = ${cid} ORDER BY d.issue_date) t`);
  const actions = await jsonArray(`SELECT JSON_ARRAYAGG(t.j) FROM (
      SELECT JSON_OBJECT('id', a.action_id, 'name', a.action_name,
        'lead', lc.name_cn, 'org', o.name_cn,
        'planned', DATE_FORMAT(a.planned_end_date,'%Y-%m-%d'),
        'actual', DATE_FORMAT(a.actual_end_date,'%Y-%m-%d'),
        'progress', a.progress_pct, 'status', a.status) j
      FROM follow_up_action a
      LEFT JOIN country lc ON lc.country_id = a.lead_country_id
      LEFT JOIN international_organization o ON o.org_id = a.responsible_org_id
      WHERE a.conference_id = ${cid} ORDER BY a.action_id) t`);
  return { info, participants, topics, documents, actions };
};

api.documents = async (q) => {
  const where = q.q
    ? `WHERE (d.title LIKE ${like(q.q)} OR d.doc_no LIKE ${like(q.q)} OR d.doc_type LIKE ${like(q.q)})`
    : '';
  return jsonArray(`SELECT JSON_ARRAYAGG(t.j) FROM (
    SELECT JSON_OBJECT('id', d.document_id, 'no', d.doc_no, 'title', d.title,
      'type', d.doc_type, 'method', d.adopt_method, 'status', d.status,
      'date', DATE_FORMAT(d.issue_date,'%Y-%m-%d'),
      'conference', c.short_name,
      'signed', (SELECT COUNT(*) FROM document_sponsor s WHERE s.document_id = d.document_id AND s.stance='联署'),
      'support', (SELECT COUNT(*) FROM document_sponsor s WHERE s.document_id = d.document_id AND s.stance='支持'),
      'reserved', (SELECT COUNT(*) FROM document_sponsor s WHERE s.document_id = d.document_id AND s.stance='保留'),
      'total', (SELECT COUNT(*) FROM document_sponsor s WHERE s.document_id = d.document_id),
      'rate', ${fnRate('d')}) j
    FROM document d LEFT JOIN conference c ON c.conference_id = d.conference_id
    ${where} ORDER BY d.issue_date DESC) t`);
};

// 用数据库里的函数算联署率，保证与 SQL 脚本口径一致
function fnRate(alias) {
  return `fn_consensus_ratio(${alias}.document_id)`;
}

api.documentDetail = async (id) => {
  const did = int(id, 'document_id');
  const sponsors = await jsonArray(`SELECT JSON_ARRAYAGG(t.j) FROM (
    SELECT JSON_OBJECT('country', c.name_cn, 'iso', c.iso_code, 'stance', s.stance) j
    FROM document_sponsor s JOIN country c ON c.country_id = s.country_id
    WHERE s.document_id = ${did} ORDER BY FIELD(s.stance,'联署','支持','保留'), c.name_cn) t`);
  const info = await jsonObject(`SELECT JSON_OBJECT('id', d.document_id, 'title', d.title,
      'no', d.doc_no, 'type', d.doc_type, 'method', d.adopt_method, 'status', d.status,
      'date', DATE_FORMAT(d.issue_date,'%Y-%m-%d'), 'summary', d.summary,
      'conference', c.short_name, 'rate', ${fnRate('d')}) j
    FROM document d LEFT JOIN conference c ON c.conference_id = d.conference_id
    WHERE d.document_id = ${did}`);
  if (!info) throw new HttpError(404, '文件不存在');
  return { info, sponsors };
};

function riskExpr(a) {
  return `CASE
      WHEN ${a}.actual_end_date IS NOT NULL THEN '已完成'
      WHEN ${a}.planned_end_date IS NULL THEN '无计划日期'
      WHEN ${a}.planned_end_date < CURDATE() THEN '已逾期'
      ELSE '进行中' END`;
}

api.actions = async (q) => {
  const where = [];
  if (q.risk === 'overdue') where.push(`${riskExpr('a')} = '已逾期'`);
  else if (q.risk === 'done') where.push(`${riskExpr('a')} = '已完成'`);
  else if (q.risk === 'noplan') where.push(`${riskExpr('a')} = '无计划日期'`);
  if (q.q) where.push(`(a.action_name LIKE ${like(q.q)} OR lc.name_cn LIKE ${like(q.q)})`);
  const w = where.length ? 'WHERE ' + where.join(' AND ') : '';
  return jsonArray(`SELECT JSON_ARRAYAGG(t.j) FROM (
    SELECT JSON_OBJECT('id', a.action_id, 'name', a.action_name,
      'conference', c.short_name, 'lead', lc.name_cn, 'org', o.name_cn,
      'planned', DATE_FORMAT(a.planned_end_date,'%Y-%m-%d'),
      'actual', DATE_FORMAT(a.actual_end_date,'%Y-%m-%d'),
      'progress', a.progress_pct, 'status', a.status,
      'risk', ${riskExpr('a')},
      'overdueDays', CASE WHEN a.actual_end_date IS NULL AND a.planned_end_date IS NOT NULL
                          THEN DATEDIFF(CURDATE(), a.planned_end_date) END) j
    FROM follow_up_action a
    LEFT JOIN conference c ON c.conference_id = a.conference_id
    LEFT JOIN country lc ON lc.country_id = a.lead_country_id
    LEFT JOIN international_organization o ON o.org_id = a.responsible_org_id
    ${w} ORDER BY a.action_id) t`);
};

api.updateAction = async (id, body) => {
  const aid = int(id, 'action_id');
  const sets = [];
  if (body.progress !== undefined && body.progress !== null && body.progress !== '') {
    const p = Number(body.progress);
    if (!Number.isInteger(p) || p < 0 || p > 100) throw new HttpError(400, '进度必须是 0~100 的整数');
    sets.push(`progress_pct = ${p}`);
  }
  const allowedStatus = ['未启动', '进行中', '已完成', '逾期', '终止'];
  if (body.status !== undefined && body.status !== null && body.status !== '') {
    if (!allowedStatus.includes(body.status)) throw new HttpError(400, '状态取值不合法');
    sets.push(`status = ${str(body.status)}`);
  }
  if (body.actual !== undefined) {
    sets.push(`actual_end_date = ${body.actual ? str(body.actual) : 'NULL'}`);
  }
  // 先按已知业务规则拦一次，避免把数据库的 3819 原文直接甩给用户
  if (body.status === '已完成' && !body.actual) {
    const cur = await jsonObject(`SELECT JSON_OBJECT('actual', DATE_FORMAT(actual_end_date,'%Y-%m-%d')) j
        FROM follow_up_action WHERE action_id = ${aid}`);
    if (!cur || !cur.actual) {
      throw new HttpError(400, '标为“已完成”时必须同时填写实际完成日期（数据库约束 follow_up_action_chk_4）');
    }
  }
  if (!sets.length) throw new HttpError(400, '没有需要更新的字段');
  await mysqlRun(`UPDATE follow_up_action SET ${sets.join(', ')} WHERE action_id = ${aid}`);
  const row = await jsonObject(`SELECT JSON_OBJECT('id', action_id, 'progress', progress_pct,
      'status', status, 'actual', DATE_FORMAT(actual_end_date,'%Y-%m-%d')) j
    FROM follow_up_action WHERE action_id = ${aid}`);
  if (!row) throw new HttpError(404, '行动不存在');
  return row;
};

api.china = async () => jsonArray(`SELECT JSON_ARRAYAGG(t.j) FROM (
    SELECT JSON_OBJECT('conference', conference_name, 'type', conference_type,
      'start', DATE_FORMAT(start_date,'%Y-%m-%d'), 'city', host_city, 'host', host_country,
      'mech', mechanism_name, 'role', china_role, 'level', china_delegation_level,
      'size', china_delegation_size, 'note', china_engagement,
      'docs', documents_of_conference, 'signed', documents_china_signed) j
    FROM v_china_multilateral ORDER BY start_date DESC) t`);

api.audit = async () => jsonArray(`SELECT JSON_ARRAYAGG(t.j) FROM (
    SELECT JSON_OBJECT('id', log_id, 'user', u.username, 'role', u.user_role,
      'type', action_type, 'table', target_table, 'target', target_id,
      'old', old_value, 'new', new_value, 'time', DATE_FORMAT(log_time,'%Y-%m-%d %H:%i:%s'),
      'detail', detail) j
    FROM operation_log l LEFT JOIN app_user u ON u.user_id = l.user_id
    ORDER BY log_id DESC LIMIT 100) t`);

api.createConference = async (b) => {
  const need = ['title', 'short_name', 'start_date', 'conference_type'];
  for (const k of need) if (!b[k]) throw new HttpError(400, `缺少必填字段：${k}`);
  const mech = b.mechanism_id ? int(b.mechanism_id, 'mechanism_id') : 'NULL';
  const host = b.host_country_id ? int(b.host_country_id, 'host_country_id') : 'NULL';
  const org = b.org_id ? int(b.org_id, 'org_id') : 'NULL';
  const cols = ['title', 'short_name', 'start_date', 'conference_type'];
  const vals = [str(b.title), str(b.short_name), str(b.start_date), str(b.conference_type)];
  if (b.end_date) { cols.push('end_date'); vals.push(str(b.end_date)); }
  if (b.session_label) { cols.push('session_label'); vals.push(str(b.session_label)); }
  if (b.host_city) { cols.push('host_city'); vals.push(str(b.host_city)); }
  if (b.format) { cols.push('format'); vals.push(str(b.format)); }
  if (b.status) { cols.push('status'); vals.push(str(b.status)); }
  if (b.theme) { cols.push('theme'); vals.push(str(b.theme)); }
  cols.push('mechanism_id', 'host_country_id', 'org_id');
  vals.push(mech, host, org);
  await mysqlRun(`INSERT INTO conference (${cols.join(',')}) VALUES (${vals.join(',')})`);
  const id = (await mysqlRun('SELECT LAST_INSERT_ID()')).trim();
  return { id: Number(id) };
};

api.createParticipant = async (b) => {
  const cid = int(b.conference_id, 'conference_id');
  const country = int(b.country_id, 'country_id');
  if (!b.role) throw new HttpError(400, '缺少参会身份 role');
  const level = b.delegation_level ? str(b.delegation_level) : 'NULL';
  const size = b.delegation_size === undefined || b.delegation_size === '' ? 'NULL'
    : int(b.delegation_size, 'delegation_size');
  await mysqlRun(`INSERT INTO conference_participant
      (conference_id, country_id, role, delegation_level, delegation_size)
      VALUES (${cid}, ${country}, ${str(b.role)}, ${level}, ${size})`);
  return { ok: true };
};

// ---------------------------------------------------------------- 路由
const routes = [
  ['GET', /^\/api\/health$/, () => api.health()],
  ['GET', /^\/api\/meta$/, () => api.meta()],
  ['GET', /^\/api\/overview$/, () => api.overview()],
  ['GET', /^\/api\/conferences$/, (m, q) => api.conferences(q)],
  ['POST', /^\/api\/conferences$/, (m, q, b) => api.createConference(b)],
  ['GET', /^\/api\/conferences\/(\d+)$/, m => api.conferenceDetail(m[1])],
  ['GET', /^\/api\/documents$/, (m, q) => api.documents(q)],
  ['GET', /^\/api\/documents\/(\d+)$/, m => api.documentDetail(m[1])],
  ['GET', /^\/api\/actions$/, (m, q) => api.actions(q)],
  ['PUT', /^\/api\/actions\/(\d+)$/, (m, q, b) => api.updateAction(m[1], b)],
  ['POST', /^\/api\/participants$/, (m, q, b) => api.createParticipant(b)],
  ['GET', /^\/api\/china$/, () => api.china()],
  ['GET', /^\/api\/audit$/, () => api.audit()],
];

function sendJson(res, status, obj) {
  const body = JSON.stringify(obj);
  res.writeHead(status, {
    'Content-Type': 'application/json; charset=utf-8',
    'Cache-Control': 'no-store',
  });
  res.end(body);
}

function readBody(req) {
  return new Promise((resolve, reject) => {
    let data = '';
    req.setEncoding('utf8');
    req.on('data', c => {
      data += c;
      if (data.length > 1e6) { reject(new HttpError(413, '请求体过大')); req.destroy(); }
    });
    req.on('end', () => {
      if (!data) return resolve({});
      try { resolve(JSON.parse(data)); } catch { reject(new HttpError(400, '请求体不是合法 JSON')); }
    });
    req.on('error', reject);
  });
}

const MIME = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
};

function serveStatic(req, res) {
  const urlPath = decodeURIComponent((req.url || '/').split('?')[0]);
  const rel = urlPath === '/' ? 'index.html' : urlPath.replace(/^\/+/, '');
  const file = path.resolve(PUBLIC_DIR, rel);
  if (!file.startsWith(path.resolve(PUBLIC_DIR))) { res.writeHead(403); return res.end('forbidden'); }
  fs.readFile(file, (err, buf) => {
    if (err) { res.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' }); return res.end('404'); }
    res.writeHead(200, { 'Content-Type': MIME[path.extname(file)] || 'application/octet-stream' });
    res.end(buf);
  });
}

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url, `http://${req.headers.host}`);
  if (!url.pathname.startsWith('/api/')) return serveStatic(req, res);

  const q = Object.fromEntries(url.searchParams.entries());
  try {
    for (const [method, re, fn] of routes) {
      const m = url.pathname.match(re);
      if (m && method === req.method) {
        const body = ['POST', 'PUT', 'DELETE'].includes(method) ? await readBody(req) : {};
        return sendJson(res, 200, await fn(m, q, body));
      }
    }
    sendJson(res, 404, { error: '接口不存在' });
  } catch (e) {
    const status = e instanceof HttpError ? e.status : 500;
    const msg = String(e.message || e).replace(/^ERROR \d+ \(\w+\) [^:]*: /, '');
    sendJson(res, status, { error: msg });
  }
});

server.listen(PORT, HOST, () => {
  console.log(`多边外交数据库 Web 界面已启动：http://${HOST}:${PORT}`);
  console.log(`数据库：${DB}`);
  console.log(`客户端：${MYSQL}`);
  if (!PWD) console.warn('警告：未找到 MySQL 密码（MYSQL_PWD 环境变量或凭据文件），查询会失败。');
});
