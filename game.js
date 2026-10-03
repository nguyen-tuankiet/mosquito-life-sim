'use strict';
/* MOSQUITO: LIFE CYCLE — prototype
   Trứng → Lăng quăng → Nhộng → Muỗi trưởng thành → Giao phối → Đẻ trứng → Thế hệ tiếp theo */

const W = 960, H = 600, WW = 3600, GY = 540, DAYLEN = 7, EGGT = 9, PUPAT = 10;
const cv = document.getElementById('c'), ctx = cv.getContext('2d');
cv.width = W; cv.height = H;

const rnd = (a, b) => a + Math.random() * (b - a);
const clamp = (v, a, b) => v < a ? a : v > b ? b : v;
const dist = (ax, ay, bx, by) => Math.hypot(ax - bx, ay - by);
const pick = a => a[Math.random() * a.length | 0];
const pad = n => String(n).padStart(2, '0');

/* ───────── input ───────── */
const keys = {}, hit = {};
addEventListener('keydown', e => {
  if (['Space', 'ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight'].includes(e.code)) e.preventDefault();
  if (!keys[e.code]) hit[e.code] = true;
  keys[e.code] = true; initAudio();
});
addEventListener('keyup', e => { keys[e.code] = false; });
addEventListener('blur', () => { for (const k in keys) keys[k] = false; });
cv.addEventListener('pointerdown', () => { hit.Enter = true; initAudio(); });
const K = (...c) => c.some(x => keys[x]);
const axis = () => ({ x: (K('ArrowRight', 'KeyD') ? 1 : 0) - (K('ArrowLeft', 'KeyA') ? 1 : 0), y: (K('ArrowDown', 'KeyS') ? 1 : 0) - (K('ArrowUp', 'KeyW') ? 1 : 0) });
const ACT = () => K('Space', 'KeyE');
const ACTHIT = () => hit.Space || hit.KeyE;

/* ───────── audio ───────── */
let AC = null, muted = false;
const hum = { on: false };
function initAudio() {
  if (!AC) {
    try { AC = new (window.AudioContext || window.webkitAudioContext)(); } catch (e) { AC = null; }
    if (AC) humInit();
  }
  if (AC && AC.state === 'suspended') AC.resume();
}
function beep(f, d = 0.1, type = 'sine', vol = 0.06, slide = 0) {
  if (!AC || muted) return;
  const o = AC.createOscillator(), g = AC.createGain(), t = AC.currentTime;
  o.type = type; o.frequency.setValueAtTime(f, t);
  if (slide) o.frequency.exponentialRampToValueAtTime(Math.max(30, f + slide), t + d);
  g.gain.setValueAtTime(vol, t); g.gain.exponentialRampToValueAtTime(0.0001, t + d);
  o.connect(g); g.connect(AC.destination); o.start(t); o.stop(t + d + 0.02);
}
function humInit() {
  try {
    const o = AC.createOscillator(), g = AC.createGain(), p = AC.createStereoPanner(), lfo = AC.createOscillator(), lg = AC.createGain();
    o.type = 'sawtooth'; o.frequency.value = 430; lfo.frequency.value = 24;
    g.gain.value = 0; lg.gain.value = 0;
    lfo.connect(lg); lg.connect(g.gain); o.connect(g); g.connect(p); p.connect(AC.destination);
    o.start(); lfo.start();
    Object.assign(hum, { on: true, o, g, p, lg });
  } catch (e) { hum.on = false; }
}
function humSet(vol, pan, freq) {
  if (!hum.on) return;
  const v = muted ? 0 : vol;
  hum.g.gain.value = v * 0.5; hum.lg.gain.value = v * 0.5;
  hum.p.pan.value = clamp(pan, -1, 1);
  if (freq) hum.o.frequency.value = freq;
}

/* ───────── dữ liệu ───────── */
const TR = ['vit', 'mob', 'det', 'oxy', 'fee', 'rep'];
const TRN = { vit: ['❤️', 'Sinh lực'], mob: ['💨', 'Cơ động'], det: ['👁️', 'Cảm nhận'], oxy: ['🫧', 'Oxy'], fee: ['🍃', 'Kiếm ăn'], rep: ['🥚', 'Sinh sản'] };
const BUILDS = {
  survivor: { name: 'Survivor', desc: 'Né tránh & ẩn nấp: khó bị phát hiện hơn' },
  fast: { name: 'Fast Growth', desc: 'Ăn nhiều: hút mật hiệu quả, nhiều trứng hơn' },
  explorer: { name: 'Explorer', desc: 'Khám phá: bay nhanh hơn, cảm nhận xa hơn' },
};
const STAGE = { egg: 'TRỨNG', larva: 'LĂNG QUĂNG', pupa: 'NHỘNG', adult: 'TRƯỞNG THÀNH' };

const SITES = [
  { id: 'puddle', name: 'Vũng nước', wx: 520, ww: 230, water: .45, temp: .8, food: .5, pred: .3, light: .9, human: .1, humanEv: 0,
    pond: { px0: 190, px1: 770, surf: 330, preds: ['beetle', 'strider'], sky: ['#9fd3ee', '#e8f3f0'], ground: '#6a5538', water: ['#6e9a86', '#33564c'], rim: null, dark: 0 } },
  { id: 'bucket', name: 'Xô nước', wx: 1090, ww: 90, water: .7, temp: .55, food: .25, pred: .05, light: .45, human: .85, humanEv: .3,
    pond: { px0: 300, px1: 660, surf: 150, preds: [], sky: ['#a6d4ec', '#e9f2ee'], ground: '#575f66', water: ['#6aa7bd', '#2b5d78'], rim: '#6d7b86', dark: 0 } },
  { id: 'pot', name: 'Chậu cây', wx: 2135, ww: 90, water: .6, temp: .5, food: .45, pred: .2, light: .4, human: .5, humanEv: .18,
    pond: { px0: 340, px1: 620, surf: 230, preds: ['strider'], sky: ['#a6d4ec', '#e9f2ee'], ground: '#4b3a2c', water: ['#6e9c78', '#2d5a45'], rim: '#b0643e', dark: 0 } },
  { id: 'pond', name: 'Ao nhỏ', wx: 2560, ww: 380, water: .85, temp: .45, food: .95, pred: .9, light: .5, human: .1, humanEv: 0,
    pond: { px0: 40, px1: 920, surf: 160, preds: ['fish', 'beetle', 'nymph', 'strider'], sky: ['#8fc7e8', '#e6f1ee'], ground: '#3f4f2e', water: ['#4c9aa6', '#1b4552'], rim: null, dark: 0 } },
  { id: 'drain', name: 'Cống thoát nước', wx: 3180, ww: 140, water: .4, temp: .4, food: .85, pred: .5, light: .1, human: .2, humanEv: .08,
    pond: { px0: 200, px1: 760, surf: 210, preds: ['beetle', 'nymph'], sky: ['#3d4650', '#5c6670'], ground: '#2f3236', water: ['#4f6354', '#1c2a24'], rim: null, dark: .4 } },
];

const S = { mode: 'title', t: 0, paused: false, banner: null, dead: false, deadT: 0, cause: '', stageT: 0, shake: 0, sum: null, ending: null };
let L = null, G = null, P = null, A = null, pl = null, FX = [];
let best = 1;
try { best = +localStorage.getItem('mosq_best') || 1; } catch (e) { /* bỏ qua */ }

const tv = k => L.tr[k] - 1;
const dayNo = () => 1 + Math.floor(G.lifeT / DAYLEN);

function newLineage() {
  return { gen: 1, tr: { vit: 1, mob: 1, det: 1, oxy: 1, fee: 1, rep: 1 }, reserve: 2, sibs: 4, site: 2, sex: Math.random() < .5 ? 'M' : 'F', weather: 'normal', ach: {}, houseLays: 0 };
}
function startGame() { L = newLineage(); beginGeneration(); }
function beginGeneration() {
  G = { food: 0, nectar: 0, hits: 0, dist: 0, noticed: 0, lowO2: 0, hidden: 0, lifeT: 0, eggs: 0, build: 'survivor', survivedSpray: false, weather0: L.weather };
  enterEgg(false, false);
}
function banner(title, sub) { S.banner = { t: 0, title, sub }; }
const fxClear = () => { FX = []; };
function fx(x, y, n, c, sp = 60, life = .8, r = 2.5) {
  for (let i = 0; i < n; i++) { const a = rnd(0, 6.28), v = rnd(.2, 1) * sp; FX.push({ x, y, vx: Math.cos(a) * v, vy: Math.sin(a) * v, l: life, m: life, c, r }); }
}
function fxText(x, y, s, c = '#ff6fa8', size = 22) { FX.push({ x, y, vx: rnd(-12, 12), vy: -38, l: 1.4, m: 1.4, c, s, size }); }
function updateFx(dt) {
  for (const f of FX) { f.l -= dt; f.x += f.vx * dt; f.y += f.vy * dt; if (!f.s) { f.vx *= .96; f.vy *= .96; } }
  FX = FX.filter(f => f.l > 0);
}
function drawFx() {
  for (const f of FX) {
    ctx.globalAlpha = clamp(f.l / f.m, 0, 1);
    if (f.s) txt(f.s, f.x, f.y, f.size, f.c, 'center', '700');
    else { ctx.fillStyle = f.c; ctx.beginPath(); ctx.arc(f.x, f.y, f.r, 0, 7); ctx.fill(); }
  }
  ctx.globalAlpha = 1;
}

/* ───────── chết / hồi sinh bằng anh em dự phòng ───────── */
function die(cause) {
  if (S.dead) return;
  S.dead = true; S.deadT = 0; S.cause = cause; S.shake = .4;
  fx(pl.x, pl.y, 26, '#ff4d4d', 110, 1);
  beep(180, .5, 'sawtooth', .08, -120);
}
function resolveDeath() {
  if (L.reserve > 0) {
    L.reserve--; S.dead = false;
    const m = S.mode;
    if (m === 'egg') enterEgg(true, true);
    else if (m === 'larva') enterLarva(true);
    else if (m === 'pupa') enterPupa(true);
    else enterAdult(true);
    banner('MỘT ANH EM THAY THẾ BẠN', `Còn ${L.reserve} cá thể dự phòng trong dòng họ`);
  } else {
    S.mode = 'over';
    try { localStorage.setItem('mosq_best', String(Math.max(best, L.gen))); } catch (e) { /* bỏ qua */ }
    best = Math.max(best, L.gen);
  }
}

/* ═════════════ GIAI ĐOẠN DƯỚI NƯỚC ═════════════ */
function makePond(site, weather, nsib) {
  const c = site.pond;
  const p = { site, c, x0: c.px0, x1: c.px1, bottom: 560, surf: c.surf, lvl: 0, weather, t: 0, preds: [], food: [], sibs: [], weeds: [], rocks: [], leaves: [], foodT: 0, draining: false, humanAt: null, warned: false, bub: [] };
  const w = p.x1 - p.x0, n = Math.max(1, Math.round(w / 320));
  for (let i = 0; i < n; i++) p.weeds.push({ x: p.x0 + w * (i + .5) / n + rnd(-30, 30), r: 52 });
  p.rocks.push({ x: p.x0 + w * rnd(.2, .8), r: 44 });
  const nl = Math.max(1, Math.round(w / 450));
  for (let i = 0; i < nl; i++) p.leaves.push({ x: p.x0 + w * (i + .5) / nl + rnd(-60, 60), w: 150, r: 58 });
  for (const k of c.preds) p.preds.push(mkPred(k, p));
  for (let i = 0; i < nsib; i++) p.sibs.push({ x: rnd(p.x0 + 30, p.x1 - 30), y: p.surf, vx: 0, vy: 0, alive: true, tx: 0, ty: 0, t: 0, act: .2, ph: rnd(0, 6) });
  const target = 8 + site.food * 34;
  P = p;
  for (let i = 0; i < target; i++) spawnFood();
  return p;
}
function mkPred(k, p) {
  const w = p.x1 - p.x0;
  const o = { k, x: p.x0 + rnd(.2, .8) * w, y: 0, vx: 0, vy: 0, face: Math.random() < .5 ? -1 : 1, st: 'patrol', t: 0, cd: 0, tx: 0, ty: 0, ph: rnd(0, 6) };
  if (k === 'fish') o.y = p.surf + (p.bottom - p.surf) * .5;
  else if (k === 'beetle') { o.y = rnd(p.surf + 30, p.bottom - 30); o.tx = o.x; o.ty = o.y; }
  else if (k === 'nymph') { const h = pick([...p.weeds, ...p.rocks]); o.x = o.hx = h.x; o.y = o.hy = p.bottom - 22; }
  else if (k === 'strider') o.y = p.surf;
  return o;
}
const shaded = x => P.leaves.some(l => Math.abs(x - l.x) < l.w / 2);
function inShelter(x, y) {
  for (const w of P.weeds) if (dist(x, y, w.x, P.bottom - 48) < w.r) return true;
  for (const r of P.rocks) if (dist(x, y, r.x, P.bottom - 26) < r.r) return true;
  for (const l of P.leaves) if (dist(x, y, l.x, P.surf + 22) < l.r) return true;
  return false;
}
const FOODT = { bact: { r: 3, val: 2, c: '#b7e86b' }, plant: { r: 5, val: 4, c: '#4caf50' }, micro: { r: 4, val: 3.5, c: '#ff9ecb' }, org: { r: 5, val: 5, c: '#9a7a52' } };
function spawnFood() {
  const r = Math.random(), t = r < .45 ? 'bact' : r < .65 ? 'plant' : r < .85 ? 'micro' : 'org';
  const x = rnd(P.x0 + 15, P.x1 - 15);
  const y = t === 'plant' ? rnd(P.surf + 8, P.surf + 80) : t === 'org' ? rnd(P.bottom - 100, P.bottom - 10) : rnd(P.surf + 20, P.bottom - 20);
  P.food.push({ t, x, y, ph: rnd(0, 6.28) });
}

function enterEgg(keepPond, resp) {
  S.mode = 'egg'; S.stageT = 0; S.dead = false; S.ending = null; fxClear();
  if (!keepPond) makePond(SITES[L.site], G.weather0, L.sibs);
  pl = { x: P.x0 + rnd(.2, .8) * (P.x1 - P.x0), y: P.surf, vx: 0, vy: 0, heat: 0, et: 0, hp: 1, act: 0, hidden: false, inv: 0 };
  for (const o of P.preds) {
    if (Math.abs(o.x - pl.x) < 280) o.x = pl.x < (P.x0 + P.x1) / 2 ? clamp(pl.x + 320, P.x0 + 30, P.x1 - 30) : clamp(pl.x - 320, P.x0 + 30, P.x1 - 30);
    if (o.k === 'nymph') o.hx = o.x;
    o.cd = Math.max(o.cd, 2.5);
  }
  if (!resp) banner('TRỨNG', `${SITES[L.site].name} — đừng chết trước khi được sinh ra`);
}
function enterLarva(resp) {
  const pg = resp && pl && pl.growth ? pl.growth * .5 : 0;
  S.mode = 'larva'; S.stageT = 0; S.dead = false; fxClear();
  const mh = 100 + 15 * tv('vit');
  pl = { x: pl ? clamp(pl.x, P.x0 + 20, P.x1 - 20) : (P.x0 + P.x1) / 2, y: P.surf + 14, vx: 0, vy: 0, hp: mh, maxhp: mh, o2: 100, growth: pg, act: 0, face: 1, ang: 0, inv: 0, dashCd: 0, dashT: 0, hidden: false };
  for (const o of P.preds) o.cd = Math.max(o.cd, 2);
  if (!resp) { P.humanAt = (L.gen > 1 && Math.random() < P.site.humanEv) ? rnd(35, 55) : null; P.warned = false; }
  if (!resp) banner('LĂNG QUĂNG', 'Ăn, hít thở, né kẻ săn mồi — lớn đủ để hóa nhộng');
}
function chooseBuild() {
  const s = { survivor: G.hidden / 18, fast: G.food / 28, explorer: G.dist / 3200 };
  let b = 'survivor', m = -1;
  for (const k in s) if (s[k] > m) { m = s[k]; b = k; }
  G.build = b;
}
function enterPupa(resp) {
  if (!resp) chooseBuild();
  S.mode = 'pupa'; S.stageT = 0; S.dead = false; fxClear();
  const mh = 100 + 15 * tv('vit');
  pl = { x: pl ? clamp(pl.x, P.x0 + 20, P.x1 - 20) : (P.x0 + P.x1) / 2, y: pl ? clamp(pl.y, P.surf + 20, P.bottom - 20) : P.surf + 60, vx: 0, vy: 0, hp: mh, maxhp: mh, act: 0, anchored: false, pt: 0, hidden: false, inv: 0, face: 1, ang: 0 };
  banner('NHỘNG — ' + BUILDS[G.build].name.toUpperCase(), 'Tìm chỗ trú (rong, đá, bóng lá) rồi nhấn SPACE để bám và chờ biến đổi');
}

function targets() {
  const a = [];
  const egg = S.mode === 'egg';
  if (!S.dead) a.push({ ref: pl, x: pl.x, y: pl.y, sp: Math.hypot(pl.vx || 0, pl.vy || 0), act: pl.act, hid: pl.hidden, egg });
  for (const s of P.sibs) if (s.alive) a.push({ ref: s, x: s.x, y: s.y, sp: Math.hypot(s.vx, s.vy), act: s.act, hid: false, egg });
  return a;
}
function catchT(t, dmg, cause) {
  if (t.ref === pl) damagePlayer(dmg, cause);
  else { t.ref.alive = false; fx(t.ref.x, t.ref.y, 10, '#ffd0d0', 60, .6); }
}
function damagePlayer(d, cause) {
  if (pl.inv > 0 || S.dead) return;
  if (S.mode === 'egg') { die(cause); return; }
  pl.hp -= d; pl.inv = 1.2; G.hits++; S.shake = .25;
  fx(pl.x, pl.y, 12, '#ff6b6b', 90, .7);
  beep(260, .18, 'square', .06, -120);
  if (pl.hp <= 0) die(cause);
}

function updatePondEnv(dt) {
  const p = P; p.t += dt;
  if (p.weather === 'drought') p.lvl = Math.min(p.lvl + 1.3 * dt, 100);
  else if (p.weather === 'rain') p.lvl = Math.max(p.lvl - .5 * dt, -35);
  if (p.draining) p.lvl += 80 * dt;
  p.surf = p.c.surf + p.lvl;
  if (p.surf > p.bottom - 14) p.surf = p.bottom - 14;
  if (S.mode === 'larva' || S.mode === 'pupa') {
    if (p.humanAt !== null && !p.draining) {
      const warnAt = p.humanAt - 5;
      const tt = S.stageT;
      if (S.mode === 'larva') {
        if (!p.warned && tt > warnAt) { p.warned = true; banner('👣 CÓ NGƯỜI ĐẾN GẦN…', 'Họ sắp đổ nước đi! Hãy lớn nhanh và hóa nhộng — hoặc chịu số phận'); }
        if (tt > p.humanAt) { p.draining = true; beep(120, 1, 'sawtooth', .06, -60); }
      }
    }
    if (p.draining && p.surf >= p.bottom - 15) die('Nước bị người đổ đi — môi trường sống biến mất');
  }
  if (Math.random() < dt * 2.2) p.bub.push({ x: rnd(p.x0, p.x1), y: p.bottom, r: rnd(1.5, 3.5), v: rnd(18, 40) });
  for (const b of p.bub) { b.y -= b.v * dt; b.x += Math.sin(p.t * 2 + b.y * .05) * 6 * dt; }
  p.bub = p.bub.filter(b => b.y > p.surf);
}

function updateFood(dt) {
  const target = 8 + P.site.food * 34;
  P.foodT -= dt;
  if (P.food.length < target && P.foodT <= 0) { spawnFood(); P.foodT = .35; }
  for (const f of P.food) {
    f.x += Math.sin(P.t * .7 + f.ph) * 6 * dt + (f.t === 'micro' ? Math.sin(P.t * 2 + f.ph) * 22 * dt : 0);
    f.y += Math.cos(P.t * .5 + f.ph) * 4 * dt;
    f.x = clamp(f.x, P.x0 + 6, P.x1 - 6); f.y = clamp(f.y, P.surf + 4, P.bottom - 4);
  }
}

function updateSibs(dt) {
  for (const s of P.sibs) {
    if (!s.alive) continue;
    if (S.mode === 'egg') { s.x += Math.sin(P.t * .8 + s.ph) * 8 * dt; s.y = P.surf; s.vx = s.vy = 0; s.act = 0; continue; }
    if (S.mode === 'pupa') { s.vx = s.vy = 0; s.act = 0; s.y = clamp(s.y, P.surf + 4, P.bottom - 4); continue; }
    s.t -= dt;
    if (s.t <= 0) { s.t = rnd(1.2, 3); s.tx = rnd(P.x0 + 20, P.x1 - 20); s.ty = rnd(P.surf + 10, P.bottom - 20); }
    const d = dist(s.tx, s.ty, s.x, s.y) || 1;
    s.vx = (s.tx - s.x) / d * 42; s.vy = (s.ty - s.y) / d * 42;
    s.x += s.vx * dt; s.y = clamp(s.y + s.vy * dt, P.surf + 4, P.bottom - 4); s.act = .25;
    for (let i = 0; i < P.food.length; i++) if (dist(P.food[i].x, P.food[i].y, s.x, s.y) < 11) { P.food.splice(i, 1); break; }
  }
}

function updatePlAq(dt) {
  const a = axis();
  pl.inv = Math.max(0, pl.inv - dt);
  pl.act = Math.max(0, pl.act - .9 * dt);
  if (S.mode === 'egg') {
    pl.vx += (a.x * 42 - pl.vx) * Math.min(1, dt * 3);
    pl.x = clamp(pl.x + pl.vx * dt + Math.sin(P.t) * 3 * dt, P.x0 + 14, P.x1 - 14); pl.y = P.surf;
    const sh = shaded(pl.x);
    const rate = P.site.light * 14 * (P.weather === 'drought' ? 1.4 : P.weather === 'rain' ? .6 : 1);
    pl.heat = clamp(pl.heat + (sh ? -6 : rate) * dt, 0, 100);
    pl.hidden = false;
    if (pl.heat >= 100) die('Trứng bị nắng nóng làm hỏng');
    pl.et += dt;
    if (pl.et >= EGGT && !S.dead) { banner('NỞ RỒI!', 'Bạn đã trở thành một con lăng quăng'); enterLarva(false); beep(600, .2, 'sine', .07, 400); }
    return;
  }
  const pupa = S.mode === 'pupa';
  const acc = pupa ? 220 : 720, maxSp = (pupa ? 50 : 140) * (1 + .08 * tv('mob'));
  if (!(pupa && pl.anchored)) {
    const n = Math.hypot(a.x, a.y) || 1;
    if (a.x || a.y) { pl.vx += a.x / n * acc * dt; pl.vy += a.y / n * acc * dt; }
    if (!pupa && ACTHIT() && pl.dashCd <= 0) {
      const dx = (a.x || a.y) ? a.x / n : pl.face, dy = (a.x || a.y) ? a.y / n : 0;
      pl.vx = dx * 300; pl.vy = dy * 300; pl.dashCd = 1.1; pl.dashT = .3; pl.act = 1; beep(380, .12, 'triangle', .04, 200);
    }
    pl.dashCd = Math.max(0, pl.dashCd - dt); pl.dashT = Math.max(0, (pl.dashT || 0) - dt);
    pl.vx *= Math.exp(-2.4 * dt); pl.vy *= Math.exp(-2.4 * dt);
    const sp = Math.hypot(pl.vx, pl.vy);
    if (pl.dashT <= 0 && sp > maxSp) { pl.vx *= maxSp / sp; pl.vy *= maxSp / sp; }
    pl.x = clamp(pl.x + pl.vx * dt, P.x0 + 8, P.x1 - 8);
    pl.y = clamp(pl.y + pl.vy * dt, P.surf + 4, P.bottom - 6);
    if (Math.abs(pl.vx) > 8) pl.face = Math.sign(pl.vx);
    const spd = Math.hypot(pl.vx, pl.vy);
    G.dist += spd * dt;
    if (!pupa) pl.act = Math.max(pl.act, spd / 220);
    if (spd > 8) pl.ang += (Math.atan2(pl.vy, pl.vx) - pl.ang) * Math.min(1, dt * 6) * 0; // góc chỉ để vẽ
  } else { pl.vx = pl.vy = 0; pl.act = 0; pl.y = clamp(pl.y, P.surf + 4, P.bottom - 6); }

  const spd = Math.hypot(pl.vx, pl.vy);
  pl.hidden = inShelter(pl.x, pl.y) && pl.act < .45 && spd < 70;
  if (pupa) {
    if (ACTHIT() && !pl.anchored) { pl.anchored = true; pl.pt = 0; fx(pl.x, pl.y, 8, '#ffe9a8', 40, .5); beep(300, .15, 'sine', .05); }
    if (pl.anchored) {
      pl.pt += dt;
      if (pl.pt >= PUPAT && !S.dead) { enterAdult(false); }
    }
    return;
  }
  if (pl.hidden) G.hidden += dt;
  // hô hấp
  const atSurf = pl.y < P.surf + 16;
  const drain = 3.5 * (1 + (P.site.water < .5 ? .3 : 0)) / (1 + .2 * tv('oxy'));
  if (atSurf) { pl.o2 = Math.min(100, pl.o2 + 55 * dt); if (Math.random() < dt * 8) fx(pl.x, P.surf, 1, '#fff', 20, .5, 1.5); }
  else pl.o2 -= drain * dt;
  if (pl.o2 < 25) G.lowO2 += dt;
  if (pl.o2 <= 0) { pl.o2 = 0; pl.hp -= 12 * dt; if (pl.hp <= 0) die('Ngạt thở dưới nước'); }
  else pl.hp = Math.min(pl.maxhp, pl.hp + 2 * dt);
  // ăn
  const feeF = 1 + .1 * tv('fee'), sz = 4 + pl.growth * .05;
  for (let i = P.food.length - 1; i >= 0; i--) {
    const f = P.food[i];
    if (dist(f.x, f.y, pl.x, pl.y) < sz + FOODT[f.t].r + 4) {
      pl.growth += FOODT[f.t].val * .7 * feeF; G.food++; pl.act = Math.min(1, pl.act + .35);
      fx(f.x, f.y, 4, FOODT[f.t].c, 40, .4, 1.8); P.food.splice(i, 1); beep(700 + rnd(0, 150), .05, 'sine', .03);
    }
  }
  pl.growth += .35 * feeF * dt;
  if (pl.growth >= 100 && !S.dead) enterPupa(false);
}

function moveTo(o, tx, ty, sp, dt) {
  const d = Math.hypot(tx - o.x, ty - o.y) || 1;
  o.vx = (tx - o.x) / d * sp; o.vy = (ty - o.y) / d * sp;
  o.x += o.vx * dt; o.y += o.vy * dt;
  if (Math.abs(o.vx) > 5) o.face = Math.sign(o.vx);
}
function updatePreds(dt) {
  const T = targets(), p = P, egg = S.mode === 'egg';
  for (const o of p.preds) {
    o.cd = Math.max(0, o.cd - dt);
    if (o.k === 'fish') {
      let best = null, bd = 1e9;
      for (const t of T) {
        if (t.hid) continue;
        if (t.egg && shaded(t.x)) continue;
        const dx = t.x - o.x, d = Math.hypot(dx, t.y - o.y), r = 210 * (t.sp < 10 ? .6 : 1);
        if (d > r) continue;
        if (d > 70 && dx * o.face < -20) continue;
        if (d < bd) { bd = d; best = t; }
      }
      if (best && o.cd <= 0) {
        o.st = 'chase'; moveTo(o, best.x, Math.max(best.y, p.surf + 8), 175, dt);
        if (bd < 26) { catchT(best, 55, 'Bị cá ăn thịt'); o.cd = 2.5; o.st = 'patrol'; }
      } else {
        o.st = 'patrol';
        if (o.x < p.x0 + 40) o.face = 1; if (o.x > p.x1 - 40) o.face = -1;
        o.vx = o.face * 70; o.x += o.vx * dt;
        const my = p.surf + (p.bottom - p.surf) * .5 + Math.sin(p.t * .6 + o.ph) * 50;
        o.y += (my - o.y) * Math.min(1, dt);
      }
      o.y = clamp(o.y, p.surf + 8, p.bottom - 14);
    } else if (o.k === 'beetle') {
      let best = null, bd = 1e9;
      if (!egg) for (const t of T) {
        const d = dist(t.x, t.y, o.x, o.y), r = 250 * (t.hid ? .5 : 1);
        if (d < r && (t.sp > 35 || t.act > .35) && d < bd) { bd = d; best = t; }
      }
      if (best && o.cd <= 0) {
        o.st = 'chase'; moveTo(o, best.x, best.y, 145, dt);
        if (bd < 20) { catchT(best, 40, 'Bị bọ nước cắn'); o.cd = 2.2; o.tx = rnd(p.x0 + 30, p.x1 - 30); o.ty = rnd(p.surf + 30, p.bottom - 30); }
      } else {
        o.st = 'patrol'; o.t -= dt;
        if (o.t <= 0) { o.t = rnd(2, 4); o.tx = rnd(p.x0 + 30, p.x1 - 30); o.ty = rnd(p.surf + 30, p.bottom - 30); }
        moveTo(o, o.tx, o.ty, 55, dt);
      }
      o.y = clamp(o.y, p.surf + 8, p.bottom - 10);
    } else if (o.k === 'nymph') {
      if (o.st === 'patrol' || o.st === 'ambush') {
        o.st = 'ambush'; o.x += (o.hx - o.x) * Math.min(1, dt * 2); o.y += (o.hy - o.y) * Math.min(1, dt * 2);
        if (o.cd <= 0 && !egg) for (const t of T) {
          const d = dist(t.x, t.y, o.x, o.y);
          if (d < 100 && ((t.sp > 15 && !t.hid) || d < 50)) { o.st = 'wind'; o.t = .5; o.tx = t.x; o.ty = t.y; break; }
        }
      } else if (o.st === 'wind') {
        o.t -= dt; if (o.t <= 0) { o.st = 'lunge'; o.t = .35; const d = Math.hypot(o.tx - o.x, o.ty - o.y) || 1; o.vx = (o.tx - o.x) / d * 430; o.vy = (o.ty - o.y) / d * 430; if (Math.abs(o.vx) > 5) o.face = Math.sign(o.vx); beep(150, .2, 'sawtooth', .06, 100); }
      } else if (o.st === 'lunge') {
        o.t -= dt; o.x += o.vx * dt; o.y += o.vy * dt;
        for (const t of T) if (dist(t.x, t.y, o.x, o.y) < 24) { catchT(t, 80, 'Bị ấu trùng chuồn chuồn vồ'); o.t = 0; break; }
        if (o.t <= 0) { o.st = 'recover'; o.t = 2.4; o.cd = 2.4; }
      } else if (o.st === 'recover') {
        o.t -= dt; moveTo(o, o.hx, o.hy, 70, dt); if (o.t <= 0) o.st = 'ambush';
      }
      o.x = clamp(o.x, p.x0 + 6, p.x1 - 6); o.y = clamp(o.y, p.surf + 8, p.bottom - 8);
    } else if (o.k === 'strider') {
      o.y = p.surf;
      if (o.st === 'patrol') {
        if (o.x < p.x0 + 30) o.face = 1; if (o.x > p.x1 - 30) o.face = -1;
        o.x += o.face * 45 * dt;
        if (o.cd <= 0) for (const t of T) {
          const dx = Math.abs(t.x - o.x);
          if (t.egg && shaded(t.x)) continue;
          if (t.y < p.surf + 34 && dx < (t.egg ? 45 : 130)) { o.st = 'wind'; o.t = .45; o.tx = t.x; break; }
        }
      } else if (o.st === 'wind') {
        o.t -= dt; o.x += Math.sign(o.tx - o.x) * 70 * dt; o.face = Math.sign(o.tx - o.x) || o.face;
        if (o.t <= 0) {
          o.st = 'stab'; o.t = .25; beep(500, .08, 'square', .04, -200);
          for (const t of T) if (Math.abs(t.x - o.x) < (t.egg ? 24 : 34) && t.y < p.surf + 60 && !(t.egg && shaded(t.x))) catchT(t, 35, 'Bị sinh vật mặt nước phục kích');
        }
      } else if (o.st === 'stab') { o.t -= dt; if (o.t <= 0) { o.st = 'patrol'; o.cd = 2.5; } }
    }
  }
}

function updateAquatic(dt) {
  if (S.dead) {
    S.deadT += dt; updatePondEnv(dt); updateFx(dt); updateSibs(dt); updatePreds(dt);
    if (S.deadT > 2.2) resolveDeath();
    return;
  }
  G.lifeT += dt; S.stageT += dt;
  updatePondEnv(dt);
  const mode = S.mode;
  updatePlAq(dt);
  if (S.mode !== mode) return; // đã chuyển giai đoạn
  updateSibs(dt); updateFood(dt); updatePreds(dt); updateFx(dt);
}

/* ═════════════ GIAI ĐOẠN TRƯỞNG THÀNH ═════════════ */
const attrs = s => {
  const w = A ? A.weather : 'normal';
  const a = { water: s.water, temp: s.temp, food: s.food, pred: s.pred, light: s.light, human: s.human };
  if (w === 'drought') { a.temp = Math.min(1, a.temp + .2); a.water = Math.max(0, a.water - .15); a.food = Math.max(0, a.food - .1); }
  if (w === 'rain') { a.temp = Math.max(0, a.temp - .1); a.water = Math.min(1, a.water + .1); a.light = Math.max(0, a.light - .15); }
  return a;
};
const goodness = a => ({
  'Nước tù': a.water, 'Nhiệt độ': clamp(1 - Math.abs(a.temp - .5) * 2, 0, 1), 'Thức ăn': a.food,
  'Kẻ săn mồi': 1 - a.pred, 'Ánh sáng': clamp(1 - Math.abs(a.light - .35) * 1.6, 0, 1), 'Con người': 1 - a.human,
});
const scoreOf = a => { const g = goodness(a); return .2 * g['Nước tù'] + .15 * g['Nhiệt độ'] + .2 * g['Thức ăn'] + .2 * g['Kẻ săn mồi'] + .1 * g['Ánh sáng'] + .15 * g['Con người']; };
const siteDry = i => A.weather === 'drought' && SITES[i].id === 'puddle';

const bsF = () => ({ stealth: G.build === 'survivor' ? .75 : 1, nectar: G.build === 'fast' ? 1.25 : 1, eggs: G.build === 'fast' ? 1.2 : 1, speed: G.build === 'explorer' ? 1.12 : 1, sense: G.build === 'explorer' ? 1.3 : 1, drain: G.build === 'fast' ? .9 : 1 });
const senseR = () => 420 * (1 + .12 * tv('det')) * bsF().sense;

/* ═════════════ KẾT THÚC THẾ HỆ ═════════════ */
function finishGeneration(eggs, siteIdx) {
  G.eggs = eggs;
  const p = { vit: Math.min(1, G.hits / 3), mob: Math.min(1, G.dist / 7000), det: Math.min(1, G.noticed / 3), oxy: Math.min(1, G.lowO2 / 12), fee: Math.min(1, (G.food + G.nectar / 12) / 45), rep: Math.min(1, eggs / 150) };
  const ch = {}, why = { vit: 'bị thương nhiều', mob: 'bay/bơi nhiều', det: 'bị phát hiện, phải cảnh giác', oxy: 'thiếu oxy khi lặn', fee: 'ăn nhiều', rep: 'đẻ nhiều trứng' };
  for (const k of TR) { const d = +(0.8 * p[k]).toFixed(2); ch[k] = d; L.tr[k] = Math.min(6, L.tr[k] + d); }
  const got = [];
  const ach = (id, t) => { if (!L.ach[id]) { L.ach[id] = 1; got.push(t); } };
  if (L.gen >= 10) ach('g10', '🏆 Sống sót 10 thế hệ');
  if (L.gen >= 100) ach('g100', '👑 Duy trì quần thể 100 thế hệ');
  if (G.weather0 === 'drought') ach('drought', '🌵 Vượt qua hạn hán');
  if (G.survivedSpray) ach('spray', '🧴 Sống sót sau khi bị phun thuốc');
  if (SITES[siteIdx].human >= .5) { L.houseLays++; if (L.houseLays >= 3) ach('house', '🏠 Lập quần thể trong nhà người'); }
  try { localStorage.setItem('mosq_best', String(Math.max(best, L.gen))); } catch (e) { /* bỏ qua */ }
  best = Math.max(best, L.gen);
  S.sum = { eggs, site: siteIdx, ch, why, p, got, t: 0, build: G.build, sex: L.sex, days: dayNo() };
  S.mode = 'summary'; humSet(0, 0);
}
function nextGen() {
  L.gen++; L.site = S.sum.site;
  L.reserve = clamp(Math.floor(S.sum.eggs / 25), 1, 6);
  L.sibs = clamp(Math.round(S.sum.eggs / 15), 2, 12);
  L.sex = Math.random() < .5 ? 'M' : 'F';
  beginGeneration();
}

/* ═════════════ VẼ — TIỆN ÍCH ═════════════ */
function txt(s, x, y, size = 16, col = '#fff', al = 'left', w = '600', stroke = true) {
  ctx.font = `${w} ${size}px "Segoe UI",system-ui,"Segoe UI Emoji","Apple Color Emoji",sans-serif`;
  ctx.textAlign = al; ctx.textBaseline = 'middle';
  if (stroke) { ctx.lineWidth = 3; ctx.strokeStyle = 'rgba(0,0,0,.5)'; ctx.lineJoin = 'round'; ctx.strokeText(s, x, y); }
  ctx.fillStyle = col; ctx.fillText(s, x, y);
}
function emo(e, x, y, size) {
  ctx.font = `${size}px "Segoe UI Emoji","Apple Color Emoji","Noto Color Emoji",sans-serif`;
  ctx.textAlign = 'center'; ctx.textBaseline = 'middle'; ctx.fillStyle = '#000'; ctx.fillText(e, x, y);
}
function rr(x, y, w, h, r) { ctx.beginPath(); if (ctx.roundRect) ctx.roundRect(x, y, w, h, r); else ctx.rect(x, y, w, h); }
function bar(x, y, w, h, v, col, label) {
  ctx.fillStyle = 'rgba(0,0,0,.45)'; rr(x, y, w, h, h / 2); ctx.fill();
  ctx.fillStyle = col; rr(x, y, Math.max(h, w * clamp(v, 0, 1)), h, h / 2); ctx.fill();
  if (label) txt(label, x + 8, y + h / 2 + 1, h - 3, '#fff', 'left', '600');
}
function panel(x, y, w, h) { ctx.fillStyle = 'rgba(8,14,18,.72)'; rr(x, y, w, h, 12); ctx.fill(); ctx.strokeStyle = 'rgba(255,255,255,.15)'; ctx.stroke(); }
function ell(x, y, rx, ry, rot = 0) { ctx.beginPath(); ctx.ellipse(x, y, rx, ry, rot, 0, 7); }

/* ───────── vẽ sinh vật ───────── */
function drawMosq(x, y, face, sex, flap, blood, scale, alpha) {
  ctx.save(); ctx.translate(x, y); ctx.scale(face * scale, scale); ctx.globalAlpha = alpha;
  const wa = Math.sin(flap * 60) * .5;
  ctx.fillStyle = 'rgba(215,232,255,.55)';
  ctx.save(); ctx.rotate(-.45 + wa * .35); ell(-2, -10, 13, 4, -.3); ctx.fill(); ctx.restore();
  ctx.save(); ctx.rotate(-.1 - wa * .3); ell(-4, -9, 10, 3, -.2); ctx.fill(); ctx.restore();
  ctx.strokeStyle = '#1d1a18'; ctx.lineWidth = 1.2;
  for (let i = 0; i < 3; i++) { ctx.beginPath(); ctx.moveTo(-2 + i * 3, 3); ctx.lineTo(-8 + i * 6, 11 + (i % 2) * 2); ctx.lineTo(-12 + i * 7, 17 - i); ctx.stroke(); }
  ctx.fillStyle = blood > .02 ? `rgb(${90 + blood * 130 | 0},18,26)` : '#4d4238';
  ell(-15, 2, 12 + blood * 3, 4 + blood * 3.5); ctx.fill();
  ctx.strokeStyle = 'rgba(255,255,255,.25)'; ctx.lineWidth = 1;
  for (let i = 0; i < 3; i++) { ctx.beginPath(); ctx.moveTo(-10 - i * 4, -2); ctx.lineTo(-10 - i * 4, 6); ctx.stroke(); }
  ctx.fillStyle = '#2a2420'; ell(-1, 0, 6, 5); ctx.fill();
  ctx.beginPath(); ctx.arc(6, 0, 3.6, 0, 7); ctx.fill();
  ctx.strokeStyle = '#1d1a18'; ctx.lineWidth = 1.2;
  if (sex === 'F') { ctx.beginPath(); ctx.moveTo(9, 1); ctx.lineTo(21, 6); ctx.stroke(); }
  else { ctx.beginPath(); ctx.moveTo(8, -2); ctx.lineTo(15, -9); ctx.moveTo(8, -1); ctx.lineTo(16, -5); ctx.moveTo(9, 1); ctx.lineTo(14, 5); ctx.stroke(); }
  ctx.restore();
}
function drawLarva(x, y, face, size, t, col, alpha, wig = 1) {
  ctx.save(); ctx.globalAlpha = alpha;
  const seg = size * .85;
  for (let i = 6; i >= 0; i--) {
    const px = x - face * i * seg, py = y + Math.sin(t * 11 * wig - i * .9) * i * 1.1 * (size / 6);
    ctx.fillStyle = i === 0 ? '#3a2f26' : col;
    ctx.beginPath(); ctx.arc(px, py, size * (i === 0 ? 1.05 : 1 - i * .09), 0, 7); ctx.fill();
  }
  ctx.strokeStyle = col; ctx.lineWidth = 1.6; ctx.beginPath();
  ctx.moveTo(x - face * 6 * seg, y); ctx.lineTo(x - face * 6.7 * seg, y - size * 1.4); ctx.stroke();
  ctx.fillStyle = '#fff'; ctx.beginPath(); ctx.arc(x + face * size * .4, y - size * .3, size * .22, 0, 7); ctx.fill();
  ctx.restore();
}
function drawPupa(x, y, size, t, alpha, anchored) {
  ctx.save(); ctx.globalAlpha = alpha; ctx.translate(x, y); if (!anchored) ctx.rotate(Math.sin(t * 6) * .12);
  ctx.fillStyle = '#7b5a3a'; ctx.beginPath(); ctx.arc(0, 0, size * 1.5, 0, 7); ctx.fill();
  ctx.strokeStyle = '#7b5a3a'; ctx.lineWidth = size * .85; ctx.lineCap = 'round';
  ctx.beginPath(); ctx.arc(-size * 1.2, size * .8, size * 1.7, -.2, 1.9); ctx.stroke();
  ctx.fillStyle = 'rgba(255,255,255,.35)'; ctx.beginPath(); ctx.arc(-size * .4, -size * .5, size * .45, 0, 7); ctx.fill();
  ctx.strokeStyle = '#4b3a28'; ctx.lineWidth = 2; ctx.beginPath(); ctx.moveTo(size * .3, -size * 1.2); ctx.lineTo(size * .5, -size * 2.1); ctx.moveTo(size * .8, -size * 1.0); ctx.lineTo(size * 1.2, -size * 1.8); ctx.stroke();
  ctx.restore();
}
function drawEgg(x, y, alpha, heat) {
  ctx.save(); ctx.globalAlpha = alpha; ctx.translate(x, y - 4);
  const h = (heat || 0) / 100;
  ctx.fillStyle = `rgb(${235},${230 - h * 90 | 0},${200 - h * 120 | 0})`; ell(0, 0, 6, 9); ctx.fill();
  ctx.fillStyle = 'rgba(255,255,255,.6)'; ell(-2, -3, 1.8, 3.4); ctx.fill();
  ctx.restore();
}
function drawFish(o) {
  ctx.save(); ctx.translate(o.x, o.y); ctx.scale(o.face, 1);
  const wob = Math.sin(P.t * 8 + o.ph) * 4;
  ctx.fillStyle = '#d18a4b'; ctx.beginPath(); ctx.moveTo(-32, 0); ctx.lineTo(-54, -13 + wob); ctx.lineTo(-54, 13 + wob); ctx.closePath(); ctx.fill();
  const g = ctx.createLinearGradient(0, -14, 0, 14); g.addColorStop(0, '#c9772f'); g.addColorStop(1, '#f1d9b5');
  ctx.fillStyle = g; ell(0, 0, 34, 14); ctx.fill();
  ctx.fillStyle = '#b8652a'; ctx.beginPath(); ctx.moveTo(-6, -12); ctx.lineTo(8, -22); ctx.lineTo(14, -11); ctx.closePath(); ctx.fill();
  ctx.fillStyle = '#fff'; ctx.beginPath(); ctx.arc(22, -3, 4, 0, 7); ctx.fill();
  ctx.fillStyle = '#111'; ctx.beginPath(); ctx.arc(23, -3, 2, 0, 7); ctx.fill();
  ctx.restore();
  if (o.st === 'chase') txt('!', o.x, o.y - 32, 24, '#ff5252', 'center', '800');
}
function drawBeetle(o) {
  ctx.save(); ctx.translate(o.x, o.y); ctx.scale(o.face, 1);
  ctx.strokeStyle = '#2a1d14'; ctx.lineWidth = 1.5;
  for (let i = -1; i <= 1; i++) { const w = Math.sin(P.t * 12 + i) * 4; ctx.beginPath(); ctx.moveTo(i * 6, 6); ctx.lineTo(i * 8 - 6, 14 + w); ctx.moveTo(i * 6, -6); ctx.lineTo(i * 8 - 6, -14 - w); ctx.stroke(); }
  ctx.fillStyle = '#3d2b1e'; ell(0, 0, 17, 10); ctx.fill();
  ctx.fillStyle = 'rgba(255,255,255,.25)'; ell(-3, -3, 9, 3); ctx.fill();
  ctx.fillStyle = '#2a1d14'; ctx.beginPath(); ctx.arc(17, 0, 5, 0, 7); ctx.fill();
  ctx.restore();
  if (o.st === 'chase') txt('!', o.x, o.y - 24, 22, '#ff5252', 'center', '800');
}
function drawNymph(o) {
  ctx.save(); ctx.translate(o.x, o.y); ctx.scale(o.face, 1);
  const flash = o.st === 'wind' ? (Math.floor(P.t * 14) % 2) : 0;
  ctx.fillStyle = flash ? '#a23b2a' : '#6a6a3a'; ell(0, 0, 30, 10); ctx.fill();
  ctx.strokeStyle = 'rgba(0,0,0,.3)'; ctx.lineWidth = 1.5;
  for (let i = -2; i <= 2; i++) { ctx.beginPath(); ctx.moveTo(i * 9, -9); ctx.lineTo(i * 9, 9); ctx.stroke(); }
  ctx.strokeStyle = '#4a4a28'; ctx.lineWidth = 2;
  for (let i = -1; i <= 1; i++) { ctx.beginPath(); ctx.moveTo(i * 9, 8); ctx.lineTo(i * 9 - 5, 17); ctx.moveTo(i * 9, -8); ctx.lineTo(i * 9 - 5, -17); ctx.stroke(); }
  ctx.fillStyle = '#4a4a28'; ctx.beginPath(); ctx.arc(28, 0, 8, 0, 7); ctx.fill();
  const open = o.st === 'wind' || o.st === 'lunge' ? 10 : 3;
  ctx.strokeStyle = '#2d2d18'; ctx.lineWidth = 3; ctx.beginPath(); ctx.moveTo(33, -3); ctx.lineTo(44, -open); ctx.moveTo(33, 3); ctx.lineTo(44, open); ctx.stroke();
  ctx.fillStyle = '#ffdd55'; ctx.beginPath(); ctx.arc(29, -4, 2.4, 0, 7); ctx.fill();
  ctx.restore();
  if (o.st === 'wind') txt('!!', o.x, o.y - 30, 26, '#ff3d3d', 'center', '800');
}
function drawStrider(o) {
  ctx.save(); ctx.translate(o.x, o.y);
  ctx.strokeStyle = '#2b2b2b'; ctx.lineWidth = 1.3;
  const stab = o.st === 'stab' ? 30 : 0;
  for (let i = -1; i <= 1; i++) {
    ctx.beginPath(); ctx.moveTo(i * 4, -4); ctx.lineTo(i * 14 - 6, -9); ctx.lineTo(i * 20 - 8, 2); ctx.stroke();
    ctx.beginPath(); ctx.moveTo(i * 4, -4); ctx.lineTo(i * 14 + 6, -9); ctx.lineTo(i * 20 + 8, 2); ctx.stroke();
  }
  if (stab) { ctx.lineWidth = 2.2; ctx.beginPath(); ctx.moveTo(0, -3); ctx.lineTo(0, stab); ctx.stroke(); }
  ctx.fillStyle = '#3a3a2a'; ell(0, -6, 10, 3.6); ctx.fill();
  ctx.restore();
  if (o.st === 'wind') txt('!', o.x, o.y - 24, 22, '#ff5252', 'center', '800');
}

/* ═════════════ VẼ — DƯỚI NƯỚC ═════════════ */
function drawPondBG() {
  const p = P, c = p.c, s = p.surf;
  let g = ctx.createLinearGradient(0, 0, 0, Math.max(40, c.surf));
  const rain = p.weather === 'rain', dr = p.weather === 'drought';
  g.addColorStop(0, rain ? '#7d8a96' : dr ? '#e8b878' : c.sky[0]); g.addColorStop(1, rain ? '#a9b4bc' : dr ? '#f3dcae' : c.sky[1]);
  ctx.fillStyle = g; ctx.fillRect(0, 0, W, H);
  if (c.dark < .3 && !rain) { ctx.fillStyle = dr ? '#ffcf5a' : '#fff3b0'; ctx.beginPath(); ctx.arc(820, 70, dr ? 42 : 30, 0, 7); ctx.fill(); }
  ctx.fillStyle = c.ground; ctx.fillRect(0, c.surf - 26, W, H);
  // cỏ hai bên
  ctx.fillStyle = 'rgba(70,120,50,.75)';
  for (let x = 0; x < W; x += 16) { if (x > p.x0 - 6 && x < p.x1 + 6) continue; ctx.beginPath(); ctx.moveTo(x, c.surf - 26); ctx.lineTo(x + 5, c.surf - 40 - (x * 7 % 13)); ctx.lineTo(x + 10, c.surf - 26); ctx.fill(); }
  // nước
  g = ctx.createLinearGradient(0, s, 0, p.bottom); g.addColorStop(0, c.water[0]); g.addColorStop(1, c.water[1]);
  ctx.fillStyle = g; ctx.beginPath(); ctx.moveTo(p.x0, s); ctx.lineTo(p.x1, s); ctx.lineTo(p.x1, p.bottom - 14); ctx.quadraticCurveTo(p.x1, p.bottom + 4, p.x1 - 18, p.bottom + 4);
  ctx.lineTo(p.x0 + 18, p.bottom + 4); ctx.quadraticCurveTo(p.x0, p.bottom + 4, p.x0, p.bottom - 14); ctx.closePath(); ctx.fill();
  ctx.save(); ctx.clip();
  // tia sáng & caustic
  ctx.fillStyle = 'rgba(255,255,255,.05)';
  for (let i = 0; i < 5; i++) { const bx = p.x0 + (p.x1 - p.x0) * (i + .5) / 5 + Math.sin(p.t * .3 + i) * 30; ctx.beginPath(); ctx.moveTo(bx - 20, s); ctx.lineTo(bx + 20, s); ctx.lineTo(bx + 90, p.bottom); ctx.lineTo(bx - 60, p.bottom); ctx.fill(); }
  ctx.strokeStyle = 'rgba(255,255,255,.07)'; ctx.lineWidth = 1.5;
  for (let i = 0; i < 6; i++) { ctx.beginPath(); for (let x = p.x0; x <= p.x1; x += 14) { const y = s + 20 + i * 38 + Math.sin(x * .03 + p.t * .8 + i) * 6; x === p.x0 ? ctx.moveTo(x, y) : ctx.lineTo(x, y); } ctx.stroke(); }
  // đáy
  ctx.fillStyle = 'rgba(40,30,20,.55)'; ctx.fillRect(p.x0, p.bottom - 12, p.x1 - p.x0, 16);
  // đá
  for (const r of p.rocks) { ctx.fillStyle = '#6b6e72'; ell(r.x, p.bottom - 14, 42, 26); ctx.fill(); ctx.fillStyle = 'rgba(255,255,255,.12)'; ell(r.x - 10, p.bottom - 24, 18, 8); ctx.fill(); }
  // rong
  for (const w of p.weeds) {
    ctx.strokeStyle = '#3f8f4a'; ctx.lineWidth = 5; ctx.lineCap = 'round';
    for (let i = -2; i <= 2; i++) {
      const bx = w.x + i * 12, h = 70 + (i * 17 % 25), sw = Math.sin(p.t * 1.4 + i + w.x) * 10;
      ctx.beginPath(); ctx.moveTo(bx, p.bottom - 8); ctx.quadraticCurveTo(bx + sw, p.bottom - h * .5, bx + sw * 1.6, p.bottom - h); ctx.stroke();
    }
  }
  // bong bóng
  ctx.fillStyle = 'rgba(255,255,255,.28)';
  for (const b of p.bub) { ctx.beginPath(); ctx.arc(b.x, b.y, b.r, 0, 7); ctx.fill(); }
  if (c.dark) { ctx.fillStyle = `rgba(0,0,12,${c.dark})`; ctx.fillRect(p.x0, s, p.x1 - p.x0, p.bottom - s + 6); }
  ctx.restore();
  // viền thùng / chậu
  if (c.rim) {
    ctx.fillStyle = c.rim;
    ctx.fillRect(p.x0 - 12, c.surf - 30, 12, p.bottom - c.surf + 40); ctx.fillRect(p.x1, c.surf - 30, 12, p.bottom - c.surf + 40); ctx.fillRect(p.x0 - 12, p.bottom + 4, p.x1 - p.x0 + 24, 14);
  }
  // mặt nước
  ctx.strokeStyle = 'rgba(255,255,255,.85)'; ctx.lineWidth = 2; ctx.beginPath();
  for (let x = p.x0; x <= p.x1; x += 8) { const y = s + Math.sin(x * .05 + p.t * 2) * 1.6; x === p.x0 ? ctx.moveTo(x, y) : ctx.lineTo(x, y); }
  ctx.stroke();
  // lá nổi
  for (const l of p.leaves) {
    ctx.fillStyle = 'rgba(0,20,10,.18)'; ell(l.x, s + 30, l.w * .5, 22); ctx.fill();
    ctx.fillStyle = '#4f9a3c'; ell(l.x, s + 3, l.w * .5, 8); ctx.fill();
    ctx.strokeStyle = '#356f2a'; ctx.lineWidth = 1.5; ctx.beginPath(); ctx.moveTo(l.x - l.w * .45, s + 3); ctx.lineTo(l.x + l.w * .45, s + 3); ctx.stroke();
  }
  // mưa
  if (rain) { ctx.strokeStyle = 'rgba(200,225,255,.6)'; ctx.lineWidth = 1.3; for (let i = 0; i < 70; i++) { const x = (i * 97 + p.t * 140) % W, y = (i * 53 + p.t * 520) % (H - 20); ctx.beginPath(); ctx.moveTo(x, y); ctx.lineTo(x - 4, y + 14); ctx.stroke(); } }
}
function drawAquatic() {
  drawPondBG();
  const p = P, t = p.t;
  for (const f of p.food) { const d = FOODT[f.t]; ctx.fillStyle = d.c; ctx.beginPath(); ctx.arc(f.x, f.y, d.r, 0, 7); ctx.fill(); }
  for (const o of p.preds) { if (o.k === 'fish') drawFish(o); else if (o.k === 'beetle') drawBeetle(o); else if (o.k === 'nymph') drawNymph(o); else drawStrider(o); }
  for (const s of p.sibs) {
    if (!s.alive) continue;
    if (S.mode === 'egg') drawEgg(s.x, s.y, .9, 0);
    else if (S.mode === 'pupa') drawPupa(s.x, s.y, 3.5, t, .7, true);
    else drawLarva(s.x, s.y, s.vx < 0 ? -1 : 1, 3.6, t + s.ph, '#d7cbb4', .75);
  }
  if (!S.dead) {
    const blink = pl.inv > 0 && Math.floor(S.t * 14) % 2 ? .4 : 1;
    if (S.mode === 'egg') { drawEgg(pl.x, pl.y, 1, pl.heat); ctx.strokeStyle = 'rgba(255,255,160,.8)'; ctx.lineWidth = 2; ctx.beginPath(); ctx.arc(pl.x, pl.y - 4, 16 + Math.sin(S.t * 5) * 2, 0, 7); ctx.stroke(); }
    else if (S.mode === 'larva') drawLarva(pl.x, pl.y, pl.face, 4 + pl.growth * .05, t, pl.hidden ? '#bfd0c0' : '#efe6cf', pl.hidden ? .55 : blink, 1 + pl.act);
    else drawPupa(pl.x, pl.y, 5, t, pl.hidden ? .6 : blink, pl.anchored);
    if (pl.hidden) txt('ẩn nấp', pl.x, pl.y - 22, 13, '#cfe', 'center', '500');
  }
  drawFx();
  hudAq();
}
function hudAq() {
  txt(`THẾ HỆ ${pad(L.gen)}  ·  NGÀY ${dayNo()}  ·  ${STAGE[S.mode]}`, 16, 20, 17, '#fff');
  let y = 40;
  if (S.mode === 'egg') {
    bar(16, y, 220, 16, pl.heat / 100, pl.heat > 70 ? '#e8452c' : '#ffb347', 'Nhiệt'); y += 22;
    bar(16, y, 220, 16, pl.et / EGGT, '#9be37d', 'Sắp nở');
    txt('←/→ trôi dạt: chui vào bóng lá để tránh nắng · tránh cá và sinh vật mặt nước', W / 2, H - 22, 16, '#fff', 'center');
  } else if (S.mode === 'larva') {
    bar(16, y, 220, 16, pl.hp / pl.maxhp, '#e85a5a', 'Máu'); y += 22;
    bar(16, y, 220, 16, pl.o2 / 100, pl.o2 < 25 ? '#ff6b3d' : '#5fd0f0', 'Oxy — lên mặt nước để thở'); y += 22;
    bar(16, y, 220, 16, pl.growth / 100, '#9be37d', 'Lớn lên'); y += 22;
    bar(16, y, 220, 16, 1 - pl.dashCd / 1.1, '#e3d27d', 'Quẫy (SPACE)');
    txt('WASD/mũi tên: bơi · SPACE: quẫy nước · ẩn trong rong/đá/dưới lá · cá thấy bằng mắt, bọ nước thấy chuyển động', W / 2, H - 22, 15, '#fff', 'center');
  } else {
    bar(16, y, 220, 16, pl.hp / pl.maxhp, '#e85a5a', 'Máu'); y += 22;
    if (pl.anchored) bar(16, y, 220, 16, pl.pt / PUPAT, '#d6b3ff', 'Đang biến đổi…');
    txt(pl.anchored ? 'Đừng cử động — chờ biến đổi thành muỗi' : 'Tìm chỗ trú an toàn rồi nhấn SPACE để bám', W / 2, H - 22, 16, '#fff', 'center');
  }
  hudRight();
  if (P.draining) txt('⚠ NƯỚC ĐANG BỊ ĐỔ ĐI!', W / 2, 60, 28, '#ff5252', 'center', '800');
  if (P.weather === 'drought') txt('☀️ Hạn hán: mực nước đang hạ', W / 2, 24, 15, '#ffe8a8', 'center');
  if (P.weather === 'rain') txt('🌧️ Mưa: mực nước dâng', W / 2, 24, 15, '#d8ecff', 'center');
}
function hudRight() {
  txt(`Anh em dự phòng: ${L.reserve}`, W - 16, 20, 15, '#ffe9a8', 'right');
  txt(`Mục tiêu: sống sót ${L.gen}/10 thế hệ`, W - 16, 40, 14, '#cfe8d0', 'right', '500');
  txt(`Kỷ lục: ${best} thế hệ  ·  M: âm thanh  ·  P: tạm dừng`, W - 16, 58, 12, '#9db', 'right', '400');
}

/* ═════════════ VẼ — TRƯỞNG THÀNH ═════════════ */
/* ═════════════ MÀN HÌNH PHỤ ═════════════ */
function drawTitle() {
  const g = ctx.createLinearGradient(0, 0, 0, H); g.addColorStop(0, '#0e2a33'); g.addColorStop(1, '#14414a');
  ctx.fillStyle = g; ctx.fillRect(0, 0, W, H);
  ctx.fillStyle = 'rgba(255,255,255,.05)';
  for (let i = 0; i < 24; i++) { ctx.beginPath(); ctx.arc((i * 83 + S.t * 12) % W, (i * 47 + Math.sin(S.t + i) * 20) % H, 3 + i % 4, 0, 7); ctx.fill(); }
  drawMosq(480 + Math.sin(S.t) * 120, 200 + Math.sin(S.t * 2) * 25, Math.cos(S.t) > 0 ? 1 : -1, 'F', S.t, .3, 3, 1);
  txt('MOSQUITO: LIFE CYCLE', W / 2, 280, 54, '#fff', 'center', '800');
  txt('You don\'t play a mosquito. You play a lineage.', W / 2, 330, 20, '#9fe0d0', 'center', '500');
  txt('Trứng → Lăng quăng → Nhộng → Muỗi trưởng thành → Giao phối → Đẻ trứng → Thế hệ tiếp theo', W / 2, 372, 15, '#cfe', 'center', '500');
  txt('Dưới nước: WASD/mũi tên + SPACE   ·   Muỗi 3D: chuột/mũi tên nhìn, WASD bay, Space lên, Shift xuống, E hành động   ·   M âm thanh · P dừng', W / 2, 430, 16, '#fff', 'center', '500');
  txt('Chết không có nghĩa là hết — miễn là dòng họ đã sinh sản.', W / 2, 460, 16, '#fff', 'center', '500');
  if (Math.floor(S.t * 2) % 2) txt('Nhấn ENTER hoặc SPACE để bắt đầu', W / 2, 520, 24, '#ffe9a8', 'center', '700');
  txt(`Kỷ lục: ${best} thế hệ`, W - 16, H - 18, 14, '#9db', 'right', '400');
}
function drawSummary() {
  const s = S.sum;
  ctx.fillStyle = '#0d1b22'; ctx.fillRect(0, 0, W, H);
  txt(`THẾ HỆ ${pad(L.gen)} HOÀN TẤT`, W / 2, 46, 36, '#fff', 'center', '800');
  txt(`${s.sex === 'M' ? '♂ Muỗi đực' : '♀ Muỗi cái'} · build ${BUILDS[s.build].name} · sống ${s.days} ngày · ${s.eggs} trứng ở "${SITES[s.site].name}"`, W / 2, 86, 17, '#9fe0d0', 'center');
  panel(60, 112, 840, 262);
  txt('DI TRUYỀN (Genetic Legacy) — điều kiện sống ảnh hưởng đến thế hệ sau', 80, 134, 16, '#fff');
  TR.forEach((k, i) => {
    const y = 168 + i * 34;
    txt(`${TRN[k][0]} ${TRN[k][1]}`, 90, y, 16, '#fff', 'left', '600', false);
    ctx.fillStyle = 'rgba(255,255,255,.12)'; ctx.fillRect(230, y - 8, 300, 16);
    ctx.fillStyle = '#6fd3a0'; ctx.fillRect(230, y - 8, 300 * Math.min(1, (L.tr[k] - 1) / 5), 16);
    txt(L.tr[k].toFixed(2), 540, y, 15, '#fff', 'left', '600', false);
    if (s.ch[k] > 0.05) txt(`+${s.ch[k].toFixed(2)}  (${s.why[k]})`, 600, y, 14, '#ffe9a8', 'left', '500', false);
  });
  panel(60, 388, 840, 130);
  txt(`Thế hệ ${pad(L.gen + 1)}: ${Math.min(6, Math.floor(s.eggs / 25) || 1)} cá thể dự phòng · ${Math.max(2, Math.min(12, Math.round(s.eggs / 15)))} anh chị em cạnh tranh thức ăn & chia sẻ rủi ro`, 80, 412, 15, '#fff');
  txt('Mục tiêu: 🏆 sống sót 10 thế hệ · 🏠 lập quần thể trong nhà người · 🌵 vượt hạn hán · 🧴 sống sót sau phun thuốc', 80, 440, 14, '#cfe', 'left', '500');
  const got = s.got.length ? 'Thành tựu mới: ' + s.got.join('   ') : 'Đã đạt: ' + (Object.keys(L.ach).length ? Object.keys(L.ach).join(', ') : 'chưa có');
  txt(got, 80, 470, 15, '#ffd86a', 'left', '700');
  txt(`Tiến độ: ${L.gen}/10 thế hệ · ${L.houseLays}/3 lần đẻ trong nhà người`, 80, 498, 14, '#cfe', 'left', '500');
  if (s.t > .6 && Math.floor(S.t * 2) % 2) txt('ENTER để tiếp tục sang thế hệ sau →', W / 2, 560, 22, '#ffe9a8', 'center', '700');
}
function drawOver() {
  ctx.fillStyle = '#12090b'; ctx.fillRect(0, 0, W, H);
  txt('DÒNG HỌ ĐÃ TUYỆT CHỦNG', W / 2, 210, 46, '#ff6b6b', 'center', '800');
  txt(S.cause, W / 2, 270, 20, '#fff', 'center');
  txt(`Dòng họ tồn tại ${L.gen} thế hệ  ·  Kỷ lục: ${best}`, W / 2, 320, 22, '#ffe9a8', 'center', '700');
  txt('Nhấn ENTER để bắt đầu một dòng họ mới', W / 2, 400, 22, '#fff', 'center', '600');
}
function drawBanner() {
  const b = S.banner; if (!b) return;
  const a = b.t < .4 ? b.t / .4 : b.t > 3 ? Math.max(0, (3.6 - b.t) / .6) : 1;
  ctx.globalAlpha = a; ctx.fillStyle = 'rgba(0,0,0,.55)'; ctx.fillRect(0, 150, W, 90);
  txt(b.title, W / 2, 182, 32, '#fff', 'center', '800');
  txt(b.sub, W / 2, 218, 16, '#ffe9a8', 'center', '500');
  ctx.globalAlpha = 1;
}
function drawDead() {
  ctx.fillStyle = 'rgba(30,0,0,.5)'; ctx.fillRect(0, 0, W, H);
  txt('💀 ' + S.cause, W / 2, H / 2 - 14, 28, '#fff', 'center', '800');
  txt(L.reserve > 0 ? `Một anh em trong dòng họ sẽ thay thế… (còn ${L.reserve})` : 'Không còn cá thể nào thay thế…', W / 2, H / 2 + 26, 18, '#ffe9a8', 'center');
}

/* ═════════════ VÒNG LẶP CHÍNH ═════════════ */
function update(dt) {
  S.t += dt;
  if (S.banner) { S.banner.t += dt; if (S.banner.t > 3.6) S.banner = null; }
  if (S.shake > 0) S.shake -= dt;
  if (S.mode !== 'adult') humSet(0, 0);
  switch (S.mode) {
    case 'title': if (hit.Enter || hit.Space || hit.KeyE) startGame(); break;
    case 'summary': S.sum.t += dt; if (S.sum.t > .6 && (hit.Enter || hit.Space)) nextGen(); break;
    case 'over': if (hit.Enter || hit.Space) { S.mode = 'title'; } break;
    case 'egg': case 'larva': case 'pupa': updateAquatic(dt); break;
    case 'adult': updateAdult3D(dt); break;
  }
}
function render() {
  if (S.mode !== 'adult') setGL(false);
  ctx.save();
  if (S.shake > 0 && S.mode !== 'adult') ctx.translate(rnd(-4, 4), rnd(-4, 4));
  switch (S.mode) {
    case 'title': drawTitle(); break;
    case 'summary': drawSummary(); break;
    case 'over': drawOver(); break;
    case 'adult': renderAdult3D(); break;
    default: drawAquatic();
  }
  if (S.dead && (S.mode === 'egg' || S.mode === 'larva' || S.mode === 'pupa' || S.mode === 'adult')) drawDead();
  drawBanner();
  if (muted) txt('🔇', W - 20, H - 18, 16, '#fff', 'right');
  if (S.paused) { ctx.fillStyle = 'rgba(0,0,0,.6)'; ctx.fillRect(0, 0, W, H); txt('TẠM DỪNG — nhấn P để tiếp tục', W / 2, H / 2, 30, '#fff', 'center', '700'); }
  ctx.restore();
}
let last = performance.now();
function frame(now) {
  const dt = Math.min(.05, (now - last) / 1000); last = now;
  if (hit.KeyM) muted = !muted;
  if (hit.KeyP && !['title', 'summary', 'over'].includes(S.mode)) S.paused = !S.paused;
  if (!S.paused) update(dt);
  render();
  for (const k in hit) delete hit[k];
  requestAnimationFrame(frame);
}
requestAnimationFrame(frame);
