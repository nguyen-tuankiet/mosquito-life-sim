'use strict';
/* ═════════════ MUỖI TRƯỞNG THÀNH — 3D (Three.js) ═════════════
   Đơn vị: mét. Nhà 14×9 m, người cao ~1,75 m, muỗi dài ~7 cm.
   x: đông-tây, z: bắc-nam (nam = +z, cửa chính ở phía nam), y: độ cao. */

const HWALL = 2.7, HR = 24 / 120, M2PX = 56;
const HOUSE = { x0: -7, x1: 7, z0: -4.5, z1: 4.5 };
const FD = [5, 4.5];                                       // tâm cửa chính
const DOOR = { 0: [-4, .5], 1: [0, .5], 2: [4.5, .5] };    // cửa từ các phòng ra phòng khách (tường z=0,5)
const ROOMN = ['Phòng ngủ', 'Phòng tắm', 'Bếp', 'Phòng khách'];
const SITE3 = [ // cùng thứ tự với SITES: vũng, xô, chậu, ao, cống
  { x: -14, z: 8, r: 1.6 }, { x: -9.2, z: 2.5, r: .3 }, { x: -6, z: 3.6, r: .3 }, { x: 16, z: -4, r: 3.5 }, { x: 14, z: 12, r: .7 },
];
const SPOT3 = {
  bed:   { dad: [-5.6, -3.5], mom: [-5.6, -2.5], kid: [-3.2, -3.8] },
  bath:  { dad: [0, -3], mom: [0, -3], kid: [0, -3] },
  table: { dad: [4.4, -1.6], mom: [5.6, -1.6], kid: [5, -.9] },
  stove: { dad: [3.2, -3.9], mom: [3.2, -3.9], kid: [3.2, -3.9] },
  chore: { dad: [-2, 2.2], mom: [-2, 2.2], kid: [-2, 2.2] },
  sofa:  { dad: [-.6, 3.3], mom: [.6, 3.3], kid: [0, 2] },
  out:   { dad: [5, 9], mom: [5, 9], kid: [5, 9] },
};
const AWARE = { sleep: .35, tv: .55, eat: .8, cook: 1, walk: 1.15, bath: .9, chore: 1, play: 1.3, study: .7, alert: 1.7 };
const ACTTXT = { sleep: 'đang ngủ', tv: 'xem TV', eat: 'ăn cơm', cook: 'nấu ăn', walk: 'đi lại', bath: 'tắm rửa', chore: 'dọn nhà', play: 'chơi đùa', study: 'học bài', alert: 'ĐANG TÌM MUỖI!' };
const FAMILY = {
  dad: { name: 'Bố', reward: 1.35, nr: 2.8, alert: 1.1, swat: 1.35, reach: 2.1, spd: 1.3, scale: 1.02, shirt: 0x3b6fb6, pants: 0x333b4a, hair: 0x2a1b10,
    sched: [[0, 'sleep', 'bed'], [6.5, 'bath', 'bath'], [7, 'eat', 'table'], [7.5, 'away', 'out'], [17.5, 'tv', 'sofa'], [19, 'eat', 'table'], [19.8, 'tv', 'sofa'], [21.5, 'bath', 'bath'], [22.2, 'sleep', 'bed']] },
  mom: { name: 'Mẹ', reward: 1.3, nr: 2.8, alert: 1.15, swat: 1.3, reach: 2, spd: 1.2, scale: .95, shirt: 0xc0508a, pants: 0x4a3a5a, hair: 0x4a2a14,
    sched: [[0, 'sleep', 'bed'], [6, 'bath', 'bath'], [6.3, 'cook', 'stove'], [7, 'eat', 'table'], [7.5, 'chore', 'chore'], [9, 'away', 'out'], [11, 'cook', 'stove'], [12.5, 'eat', 'table'], [13, 'chore', 'chore'], [14, 'tv', 'sofa'], [17.5, 'cook', 'stove'], [19, 'eat', 'table'], [19.8, 'tv', 'sofa'], [21, 'bath', 'bath'], [21.6, 'sleep', 'bed']] },
  kid: { name: 'Bé', reward: .9, nr: 3, alert: 1, swat: 1.1, reach: 1.6, spd: 2, scale: .68, shirt: 0xf2a33a, pants: 0x3a6a4a, hair: 0x1c1c1c,
    sched: [[0, 'sleep', 'bed'], [6.8, 'bath', 'bath'], [7, 'eat', 'table'], [7.4, 'away', 'out'], [16.5, 'play', 'sofa'], [19, 'eat', 'table'], [19.6, 'study', 'table'], [21, 'bath', 'bath'], [21.5, 'sleep', 'bed']] },
};
const ANIMALS = {
  rat:  { name: 'Chuột', reward: .6, nr: 1.4, alert: .8, swat: .8, reach: .5, home: [-18, -6], amp: 2.5, sp: 1.1, r: .14, cy: .1, kind: 'rat' },
  dog:  { name: 'Chó', reward: 1, nr: 1.9, alert: 1, swat: 1, reach: 1, home: [-12, -2], amp: 3, sp: .5, r: .48, cy: .4, kind: 'dog' },
  cat:  { name: 'Mèo', reward: .9, nr: 2, alert: 1.3, swat: 1.1, reach: .9, home: [3, 2.6], amp: 1.1, sp: .6, r: .3, cy: .22, kind: 'cat' },
  bird: { name: 'Chim', reward: .8, nr: 2.4, alert: 1.4, swat: 1.4, reach: 4, home: [26, 6], amp: 0, sp: 0, r: .22, cy: 3.5, kind: 'bird' },
  cow:  { name: 'Gia súc', reward: 1.1, nr: 1.5, alert: .5, swat: .95, reach: 2, home: [22, 5], amp: 1.5, sp: .4, r: 1, cy: 1, kind: 'cow' },
};
const schedEntry = (df, hr) => { let e = df.sched[0]; for (const s of df.sched) if (hr >= s[0]) e = s; return e; };
const nightAmt = h => (h >= 20 || h < 5) ? 1 : h >= 18 ? (h - 18) / 2 : h < 7 ? 1 - (h - 5) / 2 : 0;
const roomAt = (x, z) => (x < HOUSE.x0 || x > HOUSE.x1 || z < HOUSE.z0 || z > HOUSE.z1) ? 4 : z >= .5 ? 3 : x < -1.5 ? 0 : x < 1.5 ? 1 : 2;
const inHouse = (x, z, m = 0) => x > HOUSE.x0 - m && x < HOUSE.x1 + m && z > HOUSE.z0 - m && z < HOUSE.z1 + m;
const sense3 = () => 14 * (1 + .12 * tv('det')) * bsF().sense;

/* ───────── trạng thái 3D ───────── */
const T3 = { ok: false, yaw: 0, pitch: -.12, fx: [], cols: [], texCache: {}, lock: false };
let R3, SC, CAM, glc, staticG, dynG, sunL, hemiL, headL, rainPts, doorGrp, doorCol, sprayMesh, puddleWet, puddleDry;
let F3 = [], B3 = [], roomL = [], siteLab = [], mosqG = null;
const MC = {};
const mat = (c, o) => { const k = c + JSON.stringify(o || {}); return MC[k] || (MC[k] = new THREE.MeshStandardMaterial(Object.assign({ color: c, roughness: .85, metalness: 0 }, o || {}))); };
function bx(w, h, d, c, x, y, z, par, o) { const m = new THREE.Mesh(new THREE.BoxGeometry(w, h, d), mat(c, o)); m.position.set(x, y, z); (par || staticG).add(m); return m; }
function cyl(rt, rb, h, c, x, y, z, par, o, seg = 18) { const m = new THREE.Mesh(new THREE.CylinderGeometry(rt, rb, h, seg), mat(c, o)); m.position.set(x, y, z); (par || staticG).add(m); return m; }
function sph(r, c, x, y, z, par, sx = 1, sy = 1, sz = 1, o) { const m = new THREE.Mesh(new THREE.SphereGeometry(r, 16, 12), mat(c, o)); m.position.set(x, y, z); m.scale.set(sx, sy, sz); (par || staticG).add(m); return m; }
function plane(w, d, c, x, y, z, par, tex) {
  const m = new THREE.Mesh(new THREE.PlaneGeometry(w, d), tex ? new THREE.MeshStandardMaterial({ map: tex, roughness: .9 }) : mat(c));
  m.rotation.x = -Math.PI / 2; m.position.set(x, y, z); (par || staticG).add(m); return m;
}
function ctex(w, h, fn, rep) {
  const c = document.createElement('canvas'); c.width = w; c.height = h; fn(c.getContext('2d'), w, h);
  const t = new THREE.CanvasTexture(c); t.wrapS = t.wrapT = THREE.RepeatWrapping; if (rep) t.repeat.set(rep[0], rep[1]); return t;
}
function addCol(x0, x1, y0, y1, z0, z1, extra) { const c = Object.assign({ x0, x1, y0, y1, z0, z1 }, extra || {}); T3.cols.push(c); return c; }

/* tường có khe cửa / cửa sổ */
function addWall(axis, f, a, b, gaps, col) {
  gaps = (gaps || []).slice().sort((p, q) => p.a - q.a);
  let cur = a;
  const seg = (s, e, y0, y1, c, glass) => {
    if (e - s < .01 || y1 - y0 < .01) return;
    const len = e - s, h = y1 - y0, mid = (s + e) / 2, ym = (y0 + y1) / 2;
    const w = axis === 'z' ? len : .2, d = axis === 'z' ? .2 : len, x = axis === 'z' ? mid : f, z = axis === 'z' ? f : mid;
    bx(w, h, d, c, x, ym, z, staticG, glass ? { transparent: true, opacity: .28, roughness: .1 } : null);
    addCol(x - w / 2, x + w / 2, ym - h / 2, ym + h / 2, z - d / 2, z + d / 2);
  };
  for (const g of gaps) {
    seg(cur, g.a, 0, HWALL, col);
    if (g.y0 > 0) seg(g.a, g.b, 0, g.y0, col);
    if (g.y1 < HWALL) seg(g.a, g.b, g.y1, HWALL, col);
    if (g.glass) seg(g.a, g.b, g.y0, g.y1, 0xaed8ee, true);
    cur = g.b;
  }
  seg(cur, b, 0, HWALL, col);
}
function labelSprite(text, size = .8) {
  const c = document.createElement('canvas'); c.width = 256; c.height = 64; const g = c.getContext('2d');
  g.font = '700 30px Segoe UI, sans-serif'; g.textAlign = 'center'; g.textBaseline = 'middle'; g.lineWidth = 6; g.strokeStyle = 'rgba(0,0,0,.6)'; g.strokeText(text, 128, 32); g.fillStyle = '#fff'; g.fillText(text, 128, 32);
  const s = new THREE.Sprite(new THREE.SpriteMaterial({ map: new THREE.CanvasTexture(c), transparent: true, depthTest: false }));
  s.scale.set(size * 4, size, 1); return s;
}
function emojiTex(e) {
  if (T3.texCache[e]) return T3.texCache[e];
  const c = document.createElement('canvas'); c.width = c.height = 64; const g = c.getContext('2d');
  g.font = '48px "Segoe UI Emoji","Apple Color Emoji",sans-serif'; g.textAlign = 'center'; g.textBaseline = 'middle'; g.fillText(e, 32, 36);
  return (T3.texCache[e] = new THREE.CanvasTexture(c));
}
function fx3(e, x, y, z, s = .25, life = 1.2) {
  const sp = new THREE.Sprite(new THREE.SpriteMaterial({ map: emojiTex(e), transparent: true, depthTest: false }));
  sp.scale.set(s, s, 1); sp.position.set(x, y, z); SC.add(sp); T3.fx.push({ sp, life, max: life, vy: .35 });
}

/* ───────── dựng thế giới tĩnh ───────── */
function init3D() {
  glc = document.getElementById('gl');
  try {
    R3 = new THREE.WebGLRenderer({ canvas: glc, antialias: true });
  } catch (e) { T3.ok = false; return; }
  R3.setPixelRatio(Math.min(2, window.devicePixelRatio || 1)); R3.setSize(W, H, false);
  SC = new THREE.Scene(); SC.background = new THREE.Color(0x87ceeb); SC.fog = new THREE.Fog(0x87ceeb, 25, 90);
  CAM = new THREE.PerspectiveCamera(72, W / H, .02, 220);
  hemiL = new THREE.HemisphereLight(0xffffff, 0x556644, .95); SC.add(hemiL);
  sunL = new THREE.DirectionalLight(0xfff0cc, .8); sunL.position.set(20, 40, 15); SC.add(sunL);
  headL = new THREE.PointLight(0xfff4e0, .5, 3.5); SC.add(headL);
  staticG = new THREE.Group(); SC.add(staticG); dynG = new THREE.Group(); SC.add(dynG);

  // mặt đất
  const grass = ctex(128, 128, (g, w, h) => { g.fillStyle = '#5c9140'; g.fillRect(0, 0, w, h); for (let i = 0; i < 900; i++) { g.fillStyle = `rgba(${40 + Math.random() * 40 | 0},${110 + Math.random() * 60 | 0},${30 + Math.random() * 30 | 0},.5)`; g.fillRect(Math.random() * w, Math.random() * h, 2, 3); } }, [60, 60]);
  plane(240, 240, 0, 0, 0, 0, staticG, grass);
  const wood = ctex(128, 128, (g, w, h) => { for (let i = 0; i < 8; i++) { g.fillStyle = i % 2 ? '#b98a56' : '#c79a63'; g.fillRect(0, i * 16, w, 16); g.fillStyle = 'rgba(0,0,0,.18)'; g.fillRect(0, i * 16, w, 1); } }, [4, 3]);
  const tile = (a, b) => ctex(64, 64, (g, w, h) => { g.fillStyle = a; g.fillRect(0, 0, w, h); g.fillStyle = b; g.fillRect(0, 0, 32, 32); g.fillRect(32, 32, 32, 32); }, [5, 5]);
  plane(5.5, 5, 0, -4.25, .01, -2, staticG, wood);                 // phòng ngủ
  plane(3, 5, 0, 0, .01, -2, staticG, tile('#bfe4de', '#a8d4cd'));  // tắm
  plane(5.5, 5, 0, 4.25, .01, -2, staticG, tile('#f1e6c4', '#e3d4a8')); // bếp
  plane(14, 4, 0, 0, .01, 2.5, staticG, wood);                      // khách
  // tường
  const WC = 0xf0e6d2;
  addWall('z', HOUSE.z0, HOUSE.x0, HOUSE.x1, null, WC);
  addWall('x', HOUSE.x0, HOUSE.z0, HOUSE.z1, [{ a: -3.4, b: -2.4, y0: 1.2, y1: 2.0 }], WC); // cửa sổ phòng ngủ luôn hé mở
  addWall('x', HOUSE.x1, HOUSE.z0, HOUSE.z1, [{ a: -3, b: -2, y0: 1.1, y1: 1.9, glass: true }], WC);
  addWall('z', HOUSE.z1, HOUSE.x0, HOUSE.x1, [{ a: 4.5, b: 5.5, y0: 0, y1: 2.1 }, { a: -5, b: -3, y0: 1, y1: 2, glass: true }, { a: -.5, b: 1.5, y0: 1, y1: 2, glass: true }], WC);
  addWall('z', .5, HOUSE.x0, HOUSE.x1, [{ a: -4.5, b: -3.5, y0: 0, y1: 2.1 }, { a: -.5, b: .5, y0: 0, y1: 2.1 }, { a: 3, b: 6, y0: 0, y1: 2.1 }], WC);
  addWall('x', -1.5, HOUSE.z0, .5, null, WC);
  addWall('x', 1.5, HOUSE.z0, .5, null, WC);
  // trần + mái
  bx(14.4, .2, 9.4, 0xe8e0d0, 0, HWALL + .1, 0); addCol(-7.2, 7.2, HWALL, HWALL + .2, -4.7, 4.7);
  const roof = bx(15.2, .25, 10.2, 0x9a4a36, 0, HWALL + .35, 0);
  const ridge = new THREE.Mesh(new THREE.CylinderGeometry(0, 5.4, 1.4, 4, 1), mat(0x9a4a36)); ridge.rotation.y = Math.PI / 4; ridge.scale.set(1.55, 1, 1); ridge.position.set(0, HWALL + 1.1, 0); staticG.add(ridge); roof.visible = true;
  // cửa chính (động)
  doorGrp = new THREE.Group(); doorGrp.position.set(4.5, 0, HOUSE.z1); staticG.add(doorGrp);
  bx(1, 2.1, .08, 0x7a4a2c, .5, 1.05, 0, doorGrp); sph(.04, 0xe8c36a, .85, 1, .06, doorGrp);
  doorCol = addCol(4.5, 5.5, 0, 2.1, HOUSE.z1 - .1, HOUSE.z1 + .1);
  // nội thất phòng ngủ
  bx(2.1, .35, 1.9, 0x7b5a3c, -5.6, .3, -3, staticG); bx(2.0, .18, 1.8, 0xe9f0f7, -5.6, .55, -3);
  bx(.35, .12, .6, 0xffffff, -6.5, .66, -3.5); bx(.35, .12, .6, 0xffffff, -6.5, .66, -2.5);
  bx(1.7, .3, .9, 0x7b5a3c, -3.2, .25, -3.8); bx(1.6, .15, .85, 0xf2d6e0, -3.2, .45, -3.8);
  bx(.6, 2, 1.2, 0x8a6a48, -6.55, 1, 1);                              // tủ quần áo
  // phòng tắm
  cyl(.2, .2, .4, 0xffffff, -.9, .2, -4.1); bx(.45, .5, .2, 0xffffff, -.9, .6, -4.35);
  bx(1.6, .55, .8, 0xeef4f6, .6, .28, -4.0); bx(.04, 2.0, .04, 0xaaaaaa, 0, 1, -3.4); bx(.5, .04, .04, 0xaaaaaa, .22, 2, -3.4);
  // bếp
  bx(2.4, .9, .6, 0xcfd3d6, 3.8, .45, -4.15); bx(.7, .06, .5, 0x333333, 3.2, .93, -4.15);
  bx(.7, 1.9, .7, 0xe8eef2, 6.55, .95, -4.1);
  bx(1.5, .06, .9, 0x9a6b3d, 5, .74, -1.4); for (const [dx, dz] of [[-.65, -.35], [.65, -.35], [-.65, .35], [.65, .35]]) bx(.06, .72, .06, 0x7a5030, 5 + dx, .36, -1.4 + dz);
  for (const [dx, dz] of [[-1, 0], [1, 0]]) bx(.45, .06, .45, 0x7a5030, 5 + dx, .45, -1.4 + dz);
  // phòng khách
  bx(2.4, .45, .9, 0x7a5a8a, 0, .23, 3.6); bx(2.4, .55, .25, 0x6a4a7a, 0, .7, 3.95); bx(.25, .65, .9, 0x6a4a7a, -1.2, .35, 3.6); bx(.25, .65, .9, 0x6a4a7a, 1.2, .35, 3.6);
  bx(1.8, .5, .45, 0x4a3a2c, 0, .25, 1); bx(1.2, .7, .08, 0x111111, 0, .85, 1, staticG, { emissive: 0x1a2a3a });
  bx(1.1, .06, .6, 0x8a6a48, 0, .36, 2.5);
  // chậu cây trong nhà (địa điểm đẻ trứng)
  cyl(.28, .2, .35, 0xb0643e, SITE3[2].x, .18, SITE3[2].z); cyl(.22, .22, .02, 0x4a8a6a, SITE3[2].x, .36, SITE3[2].z, null, { transparent: true, opacity: .85 });
  for (let i = 0; i < 6; i++) { const a = i * 1.05; sph(.12, 0x3f9a4a, SITE3[2].x + Math.cos(a) * .12, .62 + (i % 2) * .1, SITE3[2].z + Math.sin(a) * .12, null, 1, 1.6, .6); }
  // đèn phòng
  for (const [x, z] of [[-4.25, -2], [0, -2], [4.25, -2], [0, 2.5]]) { const l = new THREE.PointLight(0xffe2b0, 0, 9, 1.4); l.position.set(x, 2.3, z); SC.add(l); roomL.push(l); }
  buildYard();
  T3.ok = true;
}

function buildYard() {
  // địa điểm nước
  const water = (r, c) => { const m = new THREE.Mesh(new THREE.CircleGeometry(r, 28), new THREE.MeshStandardMaterial({ color: c, roughness: .15, transparent: true, opacity: .88 })); m.rotation.x = -Math.PI / 2; return m; };
  const s0 = SITE3[0]; puddleWet = water(s0.r, 0x5f8f9f); puddleWet.position.set(s0.x, .02, s0.z); staticG.add(puddleWet);
  puddleDry = new THREE.Mesh(new THREE.CircleGeometry(s0.r, 28), mat(0x8f7442)); puddleDry.rotation.x = -Math.PI / 2; puddleDry.position.set(s0.x, .02, s0.z); puddleDry.visible = false; staticG.add(puddleDry);
  const s1 = SITE3[1]; cyl(.32, .26, .4, 0x6d7b86, s1.x, .2, s1.z, null, { side: THREE.DoubleSide }); const w1 = water(.28, 0x5a97b0); w1.position.set(s1.x, .36, s1.z); staticG.add(w1);
  const s3 = SITE3[3]; const w3 = water(s3.r, 0x3f8a96); w3.position.set(s3.x, .03, s3.z); staticG.add(w3);
  for (let i = 0; i < 18; i++) { const a = i / 18 * 6.28; sph(.28 + (i % 3) * .06, 0x77787a, s3.x + Math.cos(a) * (s3.r + .2), .12, s3.z + Math.sin(a) * (s3.r + .2), null, 1, .6, 1); }
  for (let i = 0; i < 10; i++) { const a = i / 10 * 6.28; cyl(.02, .02, 1.1, 0x4f8a3a, s3.x + Math.cos(a) * (s3.r + .5), .55, s3.z + Math.sin(a) * (s3.r + .5)); }
  const s4 = SITE3[4]; bx(1.4, .1, .7, 0x25282b, s4.x, .03, s4.z); for (let i = -3; i <= 3; i++) bx(.04, .08, .66, 0x888888, s4.x + i * .18, .09, s4.z); plane(1.8, 1.1, 0x2a3a30, s4.x, .015, s4.z);
  // nhãn
  const lab = (i, y) => { const s = labelSprite(SITES[i].name, .45); s.position.set(SITE3[i].x, y, SITE3[i].z); s.visible = false; SC.add(s); siteLab[i] = s; };
  lab(0, 1.1); lab(1, 1.2); lab(2, 1.3); lab(3, 1.6); lab(4, 1.0);
  // hoa
  const cols = [0xff6fa8, 0xffd23f, 0xb57bff, 0xff8a3d, 0xffffff];
  for (let i = 0; i < 46; i++) {
    let x, z, ok;
    do { x = rnd(-30, 32); z = rnd(-20, 22); ok = !inHouse(x, z, 2.5) && SITE3.every(s => Math.hypot(x - s.x, z - s.z) > s.r + 1.2); } while (!ok);
    const h = rnd(.3, .8), g = new THREE.Group(); g.position.set(x, 0, z);
    cyl(.012, .012, h, 0x3f8f3a, 0, h / 2, 0, g, null, 6);
    for (let k = 0; k < 6; k++) sph(.04, pick(cols), Math.cos(k * 1.05) * .06, h, Math.sin(k * 1.05) * .06, g, 1, .5, 1);
    const core = sph(.04, 0xffd23f, 0, h + .02, 0, g); staticG.add(g);
    F3.push({ x, y: h, z, nec: 100, core });
  }
  // bụi cây (vùng ẩn nấp)
  for (const [x, z] of [[-11, 3], [-17, -6], [-4, 9], [10, 8], [12, -9], [24, -2], [20, 11], [-9, -9], [-24, 5]]) {
    const g = new THREE.Group(); g.position.set(x, 0, z);
    for (const [dx, dy, dz, r] of [[0, .7, 0, .95], [.7, .5, .3, .7], [-.7, .5, -.2, .75], [.1, .55, .7, .65]]) sph(r, 0x2f7a3a, dx, dy, dz, g);
    staticG.add(g); B3.push({ x, y: .8, z, r: 1.1 });
  }
  // cây
  const tree = (x, z, s = 1) => { cyl(.18 * s, .24 * s, 2.4 * s, 0x6b4a2e, x, 1.2 * s, z); sph(1.3 * s, 0x3f8a3a, x, 3.2 * s, z); sph(.9 * s, 0x4a9a44, x + .8 * s, 2.8 * s, z + .3 * s); };
  for (const [x, z, s] of [[-20, -10, 1.3], [-14, 14, 1.1], [-28, 0, 1.4], [8, -14, 1.2], [18, -12, 1], [28, 12, 1.3], [-6, 16, 1], [30, -8, 1.2], [-22, 18, 1.2]]) tree(x, z, s);
  tree(26, 6, 1.5); cyl(.05, .05, 1.2, 0x6b4a2e, 26.6, 3.3, 6, null, null, 6).rotation.z = Math.PI / 2; // cây có chim
  // hàng rào
  for (let x = -34; x <= 34; x += 2) { bx(.12, 1, .12, 0xcdb89a, x, .5, -26); bx(.12, 1, .12, 0xcdb89a, x, .5, 26); }
  // mưa
  const pos = new Float32Array(900 * 3); for (let i = 0; i < 900; i++) { pos[i * 3] = rnd(-12, 12); pos[i * 3 + 1] = rnd(0, 10); pos[i * 3 + 2] = rnd(-12, 12); }
  const geo = new THREE.BufferGeometry(); geo.setAttribute('position', new THREE.BufferAttribute(pos, 3));
  rainPts = new THREE.Points(geo, new THREE.PointsMaterial({ color: 0xbcd8ff, size: .06, transparent: true, opacity: .7 })); rainPts.visible = false; rainPts.frustumCulled = false; SC.add(rainPts);
  // sương độc
  sprayMesh = new THREE.Mesh(new THREE.SphereGeometry(1, 20, 14), new THREE.MeshBasicMaterial({ color: 0xbfff5a, transparent: true, opacity: .22, depthWrite: false })); sprayMesh.visible = false; SC.add(sprayMesh);
}

/* ───────── mô hình sinh vật ───────── */
function makeMosq(sex) {
  const g = new THREE.Group(), dk = 0x2a2420;
  const s = sph(.016, dk, 0, 0, 0, g, 1, .9, 1.25); const h = sph(.01, dk, 0, .002, .026, g);
  const abd = sph(.013, 0x4d4238, 0, -.002, -.034, g, 1, 1, 2.6);
  for (const sx of [-1, 1]) sph(.004, 0xaa2222, sx * .007, .004, .031, g);
  const prob = cyl(.0018, .0018, .034, 0x1d1a18, 0, 0, .05, g, null, 5); prob.rotation.x = Math.PI / 2;
  if (sex === 'M') for (const sx of [-1, 1]) { const a = cyl(.0012, .004, .03, 0x6a6258, sx * .007, .012, .038, g, null, 5); a.rotation.x = .9; a.rotation.z = sx * .4; }
  for (let i = 0; i < 6; i++) { const sx = i % 2 ? 1 : -1, z0 = .012 - Math.floor(i / 2) * .012; const l = cyl(.0013, .0013, .05, 0x1d1a18, sx * .02, -.016, z0, g, null, 4); l.rotation.z = sx * .9; l.rotation.x = (Math.floor(i / 2) - 1) * .3; }
  const wm = mat(0xdbe9ff, { transparent: true, opacity: .5, side: THREE.DoubleSide });
  const wL = new THREE.Group(), wR = new THREE.Group(); wL.position.set(-.008, .012, 0); wR.position.set(.008, .012, 0);
  const wing = () => { const m = new THREE.Mesh(new THREE.PlaneGeometry(.05, .016), wm); m.rotation.x = -Math.PI / 2; return m; };
  const a = wing(); a.position.x = -.025; wL.add(a); const b = wing(); b.position.x = .025; wR.add(b);
  g.add(wL, wR); g.userData = { abd, wL, wR };
  return g;
}
function makePerson(cfg) {
  const g = new THREE.Group(), skin = 0xf0c8a0;
  bx(.42, .6, .24, cfg.shirt, 0, 1.12, 0, g); sph(.13, skin, 0, 1.58, 0, g); sph(.14, cfg.hair, 0, 1.63, -.02, g, 1, .75, 1);
  for (const sx of [-1, 1]) sph(.02, 0x111111, sx * .05, 1.6, .115, g);
  const limb = (w, h, d, c, px, py) => { const p = new THREE.Group(); p.position.set(px, py, 0); bx(w, h, d, c, 0, -h / 2, 0, p); g.add(p); return p; };
  const legL = limb(.16, .8, .16, cfg.pants, -.11, .8), legR = limb(.16, .8, .16, cfg.pants, .11, .8);
  const armL = limb(.11, .62, .11, cfg.shirt, -.28, 1.4), armR = limb(.11, .62, .11, cfg.shirt, .28, 1.4);
  g.scale.setScalar(cfg.scale); g.userData = { legL, legR, armL, armR };
  return g;
}
function makeAnimal(kind) {
  const g = new THREE.Group();
  const q = (len, hgt, wid, c, hc, legH, tail) => {
    bx(len, hgt, wid, c, 0, legH + hgt / 2, 0, g); bx(len * .35, hgt * .8, wid * .85, hc, 0, legH + hgt * .8, wid * .15 + len * .5, g);
    for (const [dx, dz] of [[-1, -1], [1, -1], [-1, 1], [1, 1]]) bx(.08 * len / .7, legH, .08 * len / .7, hc, dx * wid * .35, legH / 2, dz * len * .35, g);
    if (tail) bx(.05, .05, len * .45, c, 0, legH + hgt * .85, -len * .6, g);
  };
  // thân dọc theo +z (đầu hướng +z)
  if (kind === 'dog') q(.8, .38, .34, 0xb5772f, 0x8a5522, .32, true);
  else if (kind === 'cat') q(.5, .24, .2, 0x8a8f96, 0x6a6f76, .2, true);
  else if (kind === 'cow') { q(1.9, .95, .8, 0xf2f2f2, 0x2a2a2a, .8, true); bx(.6, .5, .5, 0x222222, .1, 1.5, .1, g); }
  else if (kind === 'rat') q(.2, .1, .08, 0x6a5a50, 0x4a3a30, .04, true);
  else { sph(.15, 0x4a6aa8, 0, 0, 0, g, 1, 1, 1.4); sph(.08, 0x4a6aa8, 0, .12, .2, g); bx(.4, .02, .18, 0x38568a, 0, .02, -.05, g); bx(.03, .03, .14, 0xf2a33a, 0, .12, .3, g); }
  // chuyển nhỏ nhắn về y=0
  return g;
}
function makeDragon() {
  const g = new THREE.Group();
  const b = cyl(.025, .012, .6, 0x1f8a8a, 0, 0, 0, g, null, 8); b.rotation.x = Math.PI / 2; sph(.05, 0x16706f, 0, 0, .3, g); sph(.025, 0xffd24a, .03, .02, .33, g); sph(.025, 0xffd24a, -.03, .02, .33, g);
  const wm = mat(0xcfe6ff, { transparent: true, opacity: .5, side: THREE.DoubleSide }), wings = [];
  for (const [sx, z] of [[-1, .12], [1, .12], [-1, .02], [1, .02]]) { const w = new THREE.Group(); w.position.set(sx * .02, .02, z); const m = new THREE.Mesh(new THREE.PlaneGeometry(.38, .09), wm); m.rotation.x = -Math.PI / 2; m.position.x = sx * .19; w.add(m); g.add(w); wings.push([w, sx]); }
  g.userData = { wings, body: b }; g.scale.setScalar(1.3);
  return g;
}

/* ───────── thế giới động của mỗi thế hệ ───────── */
function makeWorld3(weather) {
  while (dynG.children.length) dynG.remove(dynG.children[0]);
  const w = { t: 0, weather, clock: 18 + rnd(0, 3), doorOpen: false, hosts: [], drag: [], npc: [], spray: null, sprayAt: null, warned: false };
  for (const f of F3) f.nec = 100;
  for (const k in ANIMALS) {
    const d = ANIMALS[k], grp = makeAnimal(d.kind);
    const h = { k, def: d, human: false, x: d.home[0], z: d.home[1], y: d.cy, yaw: 0, grp, alert: 0, st: 'idle', t: 0, cd: 0, ph: rnd(0, 6), away: false, hunt: 0, wake: 0, act: 'idle', sleeping: false, ring: null };
    grp.position.set(h.x, d.kind === 'bird' ? d.cy - .15 : 0, h.z); dynG.add(grp); w.hosts.push(h);
  }
  for (const k in FAMILY) {
    const d = FAMILY[k], e = schedEntry(d, w.clock), grp = makePerson(d);
    const sp = SPOT3[e[2]][k];
    const h = { k, def: d, human: true, x: sp[0], z: sp[1], y: 0, yaw: 0, grp, alert: 0, st: 'idle', t: 0, cd: 0, ph: rnd(0, 6), act: e[1], away: e[1] === 'away', walk: false, hunt: 0, wake: 0, toss: rnd(6, 12), tossing: 0, sleeping: false, wp: [], goal: '' };
    h.sleeping = h.act === 'sleep';
    dynG.add(grp); w.hosts.push(h);
  }
  for (const h of w.hosts) {
    const r = new THREE.Mesh(new THREE.SphereGeometry(1, 18, 12), new THREE.MeshBasicMaterial({ color: 0xff3030, transparent: true, opacity: .18, depthWrite: false })); r.visible = false; dynG.add(r); h.ring = r;
  }
  const nd = 2 + (L.gen > 5 ? 1 : 0);
  for (let i = 0; i < nd; i++) {
    const grp = makeDragon(); dynG.add(grp);
    const cx = i % 2 ? rnd(12, 26) : rnd(-26, -12), cz = rnd(-14, 14);
    w.drag.push({ grp, cx, cz, rad: rnd(5, 9), a: rnd(0, 6), x: cx, y: rnd(1.5, 3.5), z: cz, by: rnd(1.5, 3.5), st: 'patrol', t: 0, ph: rnd(0, 6), yaw: 0 });
  }
  if (L.gen >= 4 && Math.random() < .6) w.sprayAt = rnd(40, 75);
  return w;
}

/* ───────── vào giai đoạn trưởng thành ───────── */
function enterAdult(resp) {
  if (!T3.ok && !glc) init3D();
  S.mode = 'adult'; S.stageT = 0; S.dead = false; S.ending = null; S.prompt = ''; fxClear();
  if (!T3.ok) { S.mode = 'summary'; S.sum = { eggs: 60, site: L.site, ch: { vit: 0, mob: 0, det: 0, oxy: 0, fee: 0, rep: 0 }, why: {}, p: {}, got: [], t: 0, build: G.build, sex: L.sex, days: 1 }; return; }
  if (!resp) {
    const r = Math.random();
    L.weather = r < .18 ? 'drought' : r < .4 ? 'rain' : 'normal';
    A = makeWorld3(L.weather); applyWeather();
  } else { for (const h of A.hosts) { h.alert = 0; h.st = 'idle'; h.cd = 0; h.hunt = 0; } for (const d of A.drag) { d.st = 'patrol'; d.t = 0; } if (A.spray) { A.spray = null; A.warned = false; A.sprayAt = null; sprayMesh.visible = false; } }
  const s = SITE3[L.site];
  pl = { x: s.x + .3, y: 1, z: s.z + .3, vx: 0, vy: 0, vz: 0, yaw: 0, energy: L.sex === 'F' ? 70 : 85, age: 0, blood: 0, protein: 0, mated: false, landed: null, sucking: false, mate: 0, lay: 0, inv: 0, hidden: false, exposure: 0, flap: 0 };
  T3.yaw = 0; T3.pitch = -.1;
  if (mosqG) SC.remove(mosqG);
  mosqG = makeMosq(L.sex); SC.add(mosqG);
  A.npc = [];
  const n = L.sex === 'M' ? 1 : 2;
  for (let i = 0; i < n; i++) {
    let x, z; do { x = rnd(-22, 28); z = rnd(-14, 16); } while (Math.hypot(x - pl.x, z - pl.z) < 12);
    const grp = makeMosq(L.sex === 'M' ? 'F' : 'M'); grp.scale.setScalar(1.3); dynG.add(grp);
    A.npc.push({ grp, x, y: rnd(.8, 2), z, hx: x, hz: z, tx: x, ty: 1.2, tz: z, t: 0, alive: true, ph: rnd(0, 6) });
  }
  if (!resp) {
    const wtxt = { drought: '☀️ Hạn hán — nước cạn dần', rain: '🌧️ Trời mưa', normal: '🌤️ Trời quang' }[L.weather];
    banner(`MUỖI ${L.sex === 'M' ? 'ĐỰC ♂' : 'CÁI ♀'} — ${BUILDS[G.build].name.toUpperCase()}`,
      (L.sex === 'M' ? 'Hút mật hoa, lắng nghe tiếng vỗ cánh của muỗi cái để tìm bạn tình' : 'Lách vào nhà người, hút máu khi họ ngủ hoặc mải xem TV — đói quá sẽ chết, bị phát hiện sẽ bị đập!') + '  ·  ' + wtxt);
  }
}
function applyWeather() {
  const w = A.weather;
  rainPts.visible = w === 'rain'; puddleDry.visible = w === 'drought'; puddleWet.visible = w !== 'drought';
}

/* ───────── người: đi lại theo lịch ───────── */
function route(fx, fz, tx, tz) {
  const r1 = roomAt(fx, fz), r2 = roomAt(tx, tz), w = [];
  if (r1 === r2) { w.push([tx, tz]); return w; }
  if (r1 <= 2) { const d = DOOR[r1]; w.push([d[0], d[1] - 1], [d[0], d[1] + 1]); }
  else if (r1 === 4) w.push([FD[0], FD[1] + 1.6], [FD[0], FD[1] - 1]);
  if (r2 <= 2) { const d = DOOR[r2]; w.push([d[0], d[1] + 1], [d[0], d[1] - 1]); }
  else if (r2 === 4) w.push([FD[0], FD[1] - 1], [FD[0], FD[1] + 1.6]);
  w.push([tx, tz]); return w;
}
function updateHuman3(h, dt) {
  const df = h.def, e = schedEntry(df, A.clock);
  let act = e[1], sp = SPOT3[e[2]][h.k], tx = sp[0], tz = sp[1], spd = df.spd;
  if (h.wake > 0) { h.wake -= dt; act = 'alert'; tx = h.x; tz = h.z; }
  if (act === 'away') { if (h.away) return; }
  else if (h.away) { h.away = false; h.x = SPOT3.out[h.k][0]; h.z = SPOT3.out[h.k][1]; h.wp = []; h.goal = ''; }
  if (act === 'chore' || act === 'play') { tx += Math.sin(A.t * .5 + h.ph) * 1.2; tz += Math.cos(A.t * .4 + h.ph) * .8; }
  if (h.hunt > 0) {
    h.hunt -= dt;
    if (!pl.hidden && roomAt(pl.x, pl.z) !== 4) { act = 'alert'; tx = pl.x; tz = pl.z; spd *= 1.35; }
  }
  if (h.st === 'wind') return;
  const goal = (tx | 0) + ',' + (tz | 0) + ',' + roomAt(tx, tz);
  if (goal !== h.goal || (h.hunt > 0 && A.t % .6 < dt)) { h.goal = goal; h.wp = route(h.x, h.z, tx, tz); }
  let moving = false;
  while (h.wp.length) {
    const p = h.wp[0], dx = p[0] - h.x, dz = p[1] - h.z, d = Math.hypot(dx, dz);
    const last = h.wp.length === 1;
    if (d < (last ? .08 : .2)) { if (last) { h.wp.shift(); break; } h.wp.shift(); continue; }
    const st = Math.min(d, spd * dt); h.x += dx / d * st; h.z += dz / d * st; h.yaw = Math.atan2(dx, dz); moving = true; break;
  }
  h.walk = moving; h.act = moving ? 'walk' : act;
  if (act === 'away' && !moving && roomAt(h.x, h.z) === 4 && h.z > 7) h.away = true;
  h.sleeping = h.act === 'sleep';
  if (!moving && (h.act === 'tv' || h.act === 'sleep' || h.act === 'bath')) h.yaw = h.act === 'tv' ? Math.PI : h.act === 'bath' ? Math.PI : h.yaw;
}

/* thân thể vật chủ: đoạn thẳng + bán kính, dùng cho đậu/khoảng cách */
function hostBody(h) {
  if (h.human) {
    if (h.sleeping) return { a: [h.x - .85 * h.def.scale, .72, h.z], b: [h.x + .85 * h.def.scale, .72, h.z], r: .26 };
    const s = h.def.scale; return { a: [h.x, .12, h.z], b: [h.x, 1.55 * s, h.z], r: .26 * s };
  }
  return { a: [h.x, h.y, h.z], b: [h.x, h.y, h.z], r: h.def.r };
}
function segPoint(a, b, x, y, z) {
  const dx = b[0] - a[0], dy = b[1] - a[1], dz = b[2] - a[2], l2 = dx * dx + dy * dy + dz * dz;
  let t = l2 > 1e-9 ? ((x - a[0]) * dx + (y - a[1]) * dy + (z - a[2]) * dz) / l2 : 0; t = clamp(t, 0, 1);
  return [a[0] + dx * t, a[1] + dy * t, a[2] + dz * t];
}
function hostDist(h) { const bd = hostBody(h), p = segPoint(bd.a, bd.b, pl.x, pl.y, pl.z); return Math.max(0, Math.hypot(pl.x - p[0], pl.y - p[1], pl.z - p[2]) - bd.r); }

/* ───────── va chạm ───────── */
function collide(p, r) {
  for (const c of T3.cols) {
    if (c === doorCol && A.doorOpen) continue;
    const cx = clamp(p.x, c.x0, c.x1), cy = clamp(p.y, c.y0, c.y1), cz = clamp(p.z, c.z0, c.z1);
    let dx = p.x - cx, dy = p.y - cy, dz = p.z - cz; const d2 = dx * dx + dy * dy + dz * dz;
    if (d2 >= r * r) continue;
    let nx, ny, nz;
    if (d2 > 1e-10) { const d = Math.sqrt(d2); nx = dx / d; ny = dy / d; nz = dz / d; p.x += nx * (r - d); p.y += ny * (r - d); p.z += nz * (r - d); }
    else {
      const a = [p.x - c.x0, c.x1 - p.x, p.y - c.y0, c.y1 - p.y, p.z - c.z0, c.z1 - p.z]; let mi = 0; for (let i = 1; i < 6; i++) if (a[i] < a[mi]) mi = i;
      nx = ny = nz = 0; if (mi === 0) { nx = -1; p.x = c.x0 - r; } else if (mi === 1) { nx = 1; p.x = c.x1 + r; } else if (mi === 2) { ny = -1; p.y = c.y0 - r; } else if (mi === 3) { ny = 1; p.y = c.y1 + r; } else if (mi === 4) { nz = -1; p.z = c.z0 - r; } else { nz = 1; p.z = c.z1 + r; }
    }
    const vn = p.vx * nx + p.vy * ny + p.vz * nz; if (vn < 0) { p.vx -= vn * nx; p.vy -= vn * ny; p.vz -= vn * nz; }
  }
}

/* ───────── cập nhật chính ───────── */
const fwd3 = () => [-Math.sin(T3.yaw) * Math.cos(T3.pitch), Math.sin(T3.pitch), -Math.cos(T3.yaw) * Math.cos(T3.pitch)];
const right3 = () => [Math.cos(T3.yaw), 0, -Math.sin(T3.yaw)];
const ACT3 = () => keys.KeyE, ACT3HIT = () => hit.KeyE;

function completeMate3(n) {
  pl.mated = true; pl.mate = 0; n.alive = false; n.grp.visible = false;
  for (let i = 0; i < 6; i++) fx3('❤', pl.x + rnd(-.2, .2), pl.y + rnd(0, .3), pl.z + rnd(-.2, .2), .22, 1.6);
  beep(660, .25, 'sine', .07, 400);
  if (L.sex === 'M') {
    const bf = bsF();
    const eggs = Math.round(rnd(55, 85) * (1 + .12 * tv('rep')) * bf.eggs * (.6 + .4 * pl.energy / 100));
    let bi = 0, bd = 1e9;
    SITES.forEach((s, i) => { if (siteDry(i)) return; const d = Math.hypot(SITE3[i].x - pl.x, SITE3[i].z - pl.z); if (d < bd) { bd = d; bi = i; } });
    S.ending = { t: 0, eggs, site: bi, text: `❤ Giao phối thành công! Con cái bay đến "${SITES[bi].name}" và đẻ ${eggs} trứng.`, sub: 'Bạn đã truyền lại gen — cuộc đời của bạn kết thúc, dòng họ vẫn tiếp tục.' };
  }
}
function layEggs3(i) {
  const bf = bsF(), sc = scoreOf(attrs(SITES[i]));
  const eggs = Math.round((20 + 130 * Math.min(1.4, pl.protein)) * (1 + .12 * tv('rep')) * bf.eggs * (.55 + .45 * sc));
  S.ending = { t: 0, eggs, site: i, text: `🥚 Bạn đã đẻ ${eggs} trứng ở "${SITES[i].name}"`, sub: 'Bạn kiệt sức và qua đời — dòng họ của bạn tiếp tục ở thế hệ sau.' };
  beep(500, .3, 'sine', .07, 300);
}
function siteOver() {
  for (let i = 0; i < SITE3.length; i++) { const s = SITE3[i]; if (Math.hypot(pl.x - s.x, pl.z - s.z) < s.r + .35 && pl.y < .9) return i; }
  return -1;
}

function updateAdult3D(dt) {
  if (!T3.ok) return;
  if (S.dead) { S.deadT += dt; updateFx3(dt); humSet(0, 0); if (S.deadT > 2.2) resolveDeath(); return; }
  A.t += dt; G.lifeT += dt; S.stageT += dt;
  A.clock = (A.clock + dt * HR) % 24;
  A.doorOpen = A.hosts.some(h => h.human && !h.away && h.act === 'walk' && Math.hypot(h.x - FD[0], h.z - FD[1]) < 1.6);
  const bf = bsF();
  pl.flap += dt; pl.inv = Math.max(0, pl.inv - dt);
  // góc nhìn bằng phím mũi tên
  T3.yaw += ((K('ArrowLeft') ? 1 : 0) - (K('ArrowRight') ? 1 : 0)) * 1.9 * dt;
  T3.pitch = clamp(T3.pitch + ((K('ArrowUp') ? 1 : 0) - (K('ArrowDown') ? 1 : 0)) * 1.3 * dt, -1.3, 1.3);

  if (S.ending) {
    S.ending.t += dt; humSet(0, 0); pl.vx *= .9; pl.vy *= .9; pl.vz *= .9;
    if (S.ending.t > 3.4) finishGeneration(S.ending.eggs, S.ending.site);
    animate3D(dt); return;
  }

  /* bay / đậu */
  const fw = fwd3(), rt = right3();
  let ix = 0, iy = 0, iz = 0;
  if (K('KeyW')) { ix += fw[0]; iy += fw[1]; iz += fw[2]; }
  if (K('KeyS')) { ix -= fw[0]; iy -= fw[1]; iz -= fw[2]; }
  if (K('KeyD')) { ix += rt[0]; iz += rt[2]; }
  if (K('KeyA')) { ix -= rt[0]; iz -= rt[2]; }
  if (K('Space')) iy += 1;
  if (K('ShiftLeft', 'ShiftRight', 'KeyC', 'ControlLeft')) iy -= 1;
  const wantMove = ix || iy || iz;
  if (pl.landed) {
    const h = pl.landed.h;
    pl.x = h.x + pl.landed.ox; pl.y = Math.max(.06, pl.landed.oy); pl.z = h.z + pl.landed.oz; pl.vx = pl.vy = pl.vz = 0;
    if (wantMove) { pl.landed = null; pl.sucking = false; pl.vy = 1.2; }
  }
  if (!pl.landed) {
    const maxSp = 4.2 * (1 + .08 * tv('mob')) * bf.speed * (1 - .42 * pl.blood) * (pl.energy < 20 ? .75 : 1);
    const n = Math.hypot(ix, iy, iz) || 1;
    if (wantMove) { pl.vx += ix / n * 16 * dt; pl.vy += iy / n * 16 * dt; pl.vz += iz / n * 16 * dt; }
    const dr = Math.exp(-3.2 * dt); pl.vx *= dr; pl.vy *= dr; pl.vz *= dr;
    const sp = Math.hypot(pl.vx, pl.vy, pl.vz);
    if (sp > maxSp) { pl.vx *= maxSp / sp; pl.vy *= maxSp / sp; pl.vz *= maxSp / sp; }
    const sub = Math.max(1, Math.ceil(sp * dt / .04)), sdt = dt / sub;
    for (let i = 0; i < sub; i++) {
      pl.x += pl.vx * sdt; pl.y += pl.vy * sdt + Math.sin(A.t * 7) * .02 * sdt; pl.z += pl.vz * sdt;
      pl.x = clamp(pl.x, -38, 38); pl.z = clamp(pl.z, -24, 24); pl.y = clamp(pl.y, .05, 16);
      collide(pl, .045);
    }
    G.dist += sp * dt * M2PX;
  }
  const spd = Math.hypot(pl.vx, pl.vy, pl.vz);
  pl.hidden = !pl.landed && B3.some(b => Math.hypot(pl.x - b.x, pl.y - b.y, pl.z - b.z) < b.r);

  /* năng lượng & tuổi */
  pl.age += dt;
  pl.energy -= (L.sex === 'F' ? 1.25 : 1.3) * (1 + .35 * pl.blood) * bf.drain * (pl.landed ? .5 : 1) * dt;
  if (!pl.sucking) pl.blood = Math.max(0, pl.blood - .012 * dt);
  if (pl.energy <= 0) { pl.energy = 0; die(L.sex === 'F' ? 'Chết đói — quá lâu không hút được máu' : 'Kiệt sức vì thiếu năng lượng'); return; }
  const maxAge = L.sex === 'M' ? 160 : 240;
  if (pl.age > maxAge) { die('Hết tuổi thọ trước khi kịp sinh sản'); return; }

  /* tương tác */
  let prompt = '';
  pl.sucking = false;
  let fl = null, fd = .3;
  for (const f of F3) { const d = Math.hypot(pl.x - f.x, pl.y - (f.y + .03), pl.z - f.z); if (d < fd) { fd = d; fl = f; } }
  let mate = null;
  for (const n of A.npc) if (n.alive && Math.hypot(pl.x - n.x, pl.y - n.y, pl.z - n.z) < .4) mate = n;
  let host = null;
  if (L.sex === 'F' && !pl.landed) for (const h of A.hosts) if (!h.away && hostDist(h) < .16) host = h;
  const overSite = L.sex === 'F' && pl.mated && pl.protein > .05 ? siteOver() : -1;

  if (pl.landed) {
    const h = pl.landed.h;
    prompt = pl.blood >= 1 ? `Đã no! Bay đi ngay (WASD) trước khi ${h.def.name} phát hiện` : `Giữ E: hút máu ${h.def.name}  ·  WASD/Space: bay đi`;
    if (ACT3() && pl.blood < 1) {
      pl.sucking = true;
      const gain = .22 * (1 + .08 * tv('fee')) * dt;
      pl.blood = Math.min(1, pl.blood + gain); pl.protein += gain * h.def.reward;
      pl.energy = Math.min(100, pl.energy + gain * 90);
    }
  } else if (mate && !pl.mated) {
    prompt = 'Giữ E để giao phối ❤';
    if (ACT3()) { pl.mate += dt; if (Math.random() < dt * 5) fx3('❤', pl.x, pl.y + .1, pl.z, .15, 1); if (pl.mate >= 1.5) completeMate3(mate); }
    else pl.mate = Math.max(0, pl.mate - dt);
  } else if (host) {
    pl.mate = Math.max(0, pl.mate - dt);
    prompt = `E: đậu lên ${host.def.name}`;
    if (ACT3HIT()) {
      const bd = hostBody(host), p = segPoint(bd.a, bd.b, pl.x, pl.y, pl.z);
      let dx = pl.x - p[0], dy = pl.y - p[1], dz = pl.z - p[2]; const d = Math.hypot(dx, dy, dz) || 1;
      const sx = p[0] + dx / d * (bd.r + .02), sy = Math.max(.06, p[1] + dy / d * (bd.r + .02)), sz = p[2] + dz / d * (bd.r + .02);
      pl.landed = { h: host, ox: sx - host.x, oy: sy, oz: sz - host.z }; pl.vx = pl.vy = pl.vz = 0;
    }
  } else if (overSite >= 0) {
    pl.mate = Math.max(0, pl.mate - dt);
    if (siteDry(overSite)) { prompt = 'Chỗ này đã khô cạn!'; pl.lay = 0; }
    else { prompt = `Giữ E: đẻ trứng ở ${SITES[overSite].name}`; if (ACT3()) { pl.lay += dt; if (pl.lay >= 1.8) layEggs3(overSite); } else pl.lay = Math.max(0, pl.lay - dt); }
  } else if (fl && fl.nec > 0) {
    pl.mate = Math.max(0, pl.mate - dt);
    prompt = 'Giữ E: hút mật hoa';
    if (ACT3()) {
      pl.energy = Math.min(100, pl.energy + 32 * bf.nectar * (L.sex === 'F' ? .45 : 1) * (1 + .1 * tv('fee')) * dt);
      fl.nec = Math.max(0, fl.nec - 22 * dt); G.nectar += 32 * dt;
    }
  } else { pl.mate = Math.max(0, pl.mate - dt); pl.lay = Math.max(0, pl.lay - dt); }
  S.prompt = prompt;
  for (const f of F3) if (f.nec < 100) f.nec = Math.min(100, f.nec + 4 * dt);

  /* vật chủ: sinh hoạt, cảnh giác & đập */
  const stealth = bf.stealth * Math.max(.5, 1 - .05 * tv('det'));
  for (const h of A.hosts) {
    const df = h.def;
    if (h.human) { updateHuman3(h, dt); if (h.away) { h.alert = 0; h.st = 'idle'; continue; } }
    else if (df.amp) {
      const nx = df.home[0] + Math.sin(A.t * df.sp + h.ph) * df.amp, nz = df.home[1] + Math.cos(A.t * df.sp * .8 + h.ph) * df.amp * .7;
      if (Math.hypot(nx - h.x, nz - h.z) > .002) h.yaw = Math.atan2(nx - h.x, nz - h.z);
      h.x = nx; h.z = nz;
    }
    h.cd = Math.max(0, h.cd - dt);
    if (h.st === 'wind') {
      h.t -= dt;
      if (h.t <= 0) {
        h.st = 'idle'; h.cd = h.human ? 1.6 : 3; h.alert = .35;
        if (h.human) { h.hunt = 6; if (h.sleeping) h.wake = 12; }
        if (Math.hypot(pl.x - h.x, pl.z - h.z) < df.swat && pl.y < df.reach + .2) { die(`Bị ${df.name} đập chết`); return; }
        beep(220, .12, 'square', .05, -100);
      }
      continue;
    }
    const d = hostDist(h);
    let g = 0;
    if (pl.landed && pl.landed.h === h) g = pl.sucking ? (.08 + .18 * pl.blood) : .02;
    else if (d < df.nr && !pl.hidden) g = .025 + .09 * Math.min(1, spd / 4);
    if (h.human && h.hunt > 0 && !pl.hidden && (roomAt(pl.x, pl.z) === roomAt(h.x, h.z) || d < 3)) g = Math.max(g, .35);
    const aw = h.human ? (AWARE[h.hunt > 0 ? 'alert' : h.act] || 1) : 1;
    g *= df.alert * stealth * aw;
    if (h.human && h.sleeping) {
      h.toss -= dt;
      if (h.toss <= 0) { h.tossing = 1.2; h.toss = rnd(8, 14); }
      if (h.tossing > 0) { h.tossing -= dt; if (pl.landed && pl.landed.h === h) g += .35 * stealth; }
    }
    if (g > 0) h.alert += g * dt; else h.alert = Math.max(0, h.alert - .14 * dt);
    if (h.alert >= 1 && h.cd <= 0) {
      h.st = 'wind'; h.t = h.k === 'kid' ? .5 : .65; G.noticed++; beep(900, .25, 'square', .06, -300);
      if (h.sleeping) h.wake = 12;
    } else if (h.alert > 1) h.alert = 1;
  }

  /* chuồn chuồn (chỉ ở ngoài trời) */
  const dsense = 7 * (1 / Math.max(.6, bf.stealth + .1)) * (L.gen > 3 ? 1.1 : 1) * (G.build === 'survivor' ? .8 : 1);
  for (const d of A.drag) {
    if (d.st === 'patrol') {
      d.a += dt * .5; const nx = d.cx + Math.cos(d.a) * d.rad, nz = d.cz + Math.sin(d.a * 1.3) * d.rad;
      d.yaw = Math.atan2(nx - d.x, nz - d.z); d.x = nx; d.z = nz; d.y = d.by + Math.sin(A.t * 1.2 + d.ph) * .6;
      const dd = Math.hypot(pl.x - d.x, pl.y - d.y, pl.z - d.z);
      if (!pl.hidden && dd < dsense && (spd > 1.2 || dd < 2.5)) { d.st = 'chase'; d.t = 3.4; G.noticed++; beep(1000, .15, 'sawtooth', .05); }
    } else if (d.st === 'chase') {
      d.t -= dt;
      const dx = pl.x - d.x, dy = pl.y - d.y, dz = pl.z - d.z, dd = Math.hypot(dx, dy, dz) || 1;
      d.x += dx / dd * 3.9 * dt; d.y += dy / dd * 3.9 * dt; d.z += dz / dd * 3.9 * dt; d.yaw = Math.atan2(dx, dz);
      if (inHouse(d.x, d.z, 1.2)) { // không vào được nhà
        const l = d.x - (HOUSE.x0 - 1.2), r = HOUSE.x1 + 1.2 - d.x, t = d.z - (HOUSE.z0 - 1.2), b = HOUSE.z1 + 1.2 - d.z, m = Math.min(l, r, t, b);
        if (m === l) d.x = HOUSE.x0 - 1.2; else if (m === r) d.x = HOUSE.x1 + 1.2; else if (m === t) d.z = HOUSE.z0 - 1.2; else d.z = HOUSE.z1 + 1.2;
      }
      d.y = clamp(d.y, .3, 8);
      if (Math.hypot(pl.x - d.x, pl.y - d.y, pl.z - d.z) < .38) { die('Bị chuồn chuồn bắt'); return; }
      if (pl.hidden || d.t <= 0 || inHouse(pl.x, pl.z, 0)) { d.st = 'rest'; d.t = 2; d.by = clamp(d.y, 1.2, 4); d.cx = d.x; d.cz = d.z; }
    } else { d.t -= dt; if (d.t <= 0) d.st = 'patrol'; }
  }

  /* NPC bạn tình */
  for (const n of A.npc) {
    if (!n.alive) continue;
    n.t -= dt;
    if (n.t <= 0) { n.t = rnd(1.5, 3.5); n.tx = clamp(n.hx + rnd(-4, 4), -34, 34); n.tz = clamp(n.hz + rnd(-4, 4), -22, 22); n.ty = rnd(.6, 2.2); }
    const dx = n.tx - n.x, dy = n.ty - n.y, dz = n.tz - n.z, d = Math.hypot(dx, dy, dz) || 1;
    n.x += dx / d * .9 * dt; n.y += dy / d * .9 * dt; n.z += dz / d * .9 * dt;
  }
  // tiếng vỗ cánh (Wingbeat Hunting) — âm thanh nổi theo hướng nhìn
  let tgt = null, td = 1e9;
  if (!pl.mated) for (const n of A.npc) if (n.alive) { const d = Math.hypot(pl.x - n.x, pl.y - n.y, pl.z - n.z); if (d < td) { td = d; tgt = n; } }
  if (tgt) humSet(Math.pow(clamp(1 - td / (16 * (1 + .12 * tv('det'))), 0, 1), 1.4) * .22, ((tgt.x - pl.x) * rt[0] + (tgt.z - pl.z) * rt[2]) / 6, L.sex === 'M' ? 380 : 560);
  else humSet(0, 0);

  /* phun thuốc diệt muỗi */
  if (A.sprayAt !== null && !A.spray && S.stageT > A.sprayAt - 5 && !A.warned) {
    A.warned = true; const sx = pl.x > 0 ? rnd(-12, -9) : rnd(9, 12);
    A.spray = { cx: inHouse(pl.x, pl.z, 2) ? sx : clamp(pl.x + rnd(-3, 3), -30, 30), cz: clamp(pl.z + rnd(-3, 3), -18, 18), t: -5, r: 0 };
    banner('🧴 CON NGƯỜI SẮP PHUN THUỐC DIỆT MUỖI!', 'Hãy bay ra xa khỏi vùng sương xanh đang lan ra!');
  }
  if (A.spray) {
    const sp = A.spray; sp.t += dt; sp.r = sp.t > 0 ? Math.min(9, sp.t * .7) : 0;
    if (sp.t > 0 && sp.t < 18 && Math.hypot(pl.x - sp.cx, pl.z - sp.cz) < sp.r && pl.y < 6) {
      pl.exposure += dt; if (pl.exposure > 2) { die('Chết vì thuốc diệt muỗi'); return; }
    } else pl.exposure = Math.max(0, pl.exposure - dt);
    if (sp.t >= 18) { G.survivedSpray = true; A.spray = null; A.sprayAt = null; sprayMesh.visible = false; }
  }
  animate3D(dt);
}

function updateFx3(dt) {
  for (const f of T3.fx) { f.life -= dt; f.sp.position.y += f.vy * dt; f.sp.material.opacity = clamp(f.life / f.max, 0, 1); }
  T3.fx = T3.fx.filter(f => { if (f.life <= 0) { SC.remove(f.sp); return false; } return true; });
}

/* ───────── hoạt ảnh & ánh sáng ───────── */
let _lastYaw = 0;
function animate3D(dt) {
  updateFx3(dt);
  const nt = nightAmt(A.clock), w = A.weather;
  // trời & đèn
  const day = new THREE.Color(w === 'rain' ? 0x7d8a96 : w === 'drought' ? 0xe9b878 : 0x87ceeb), night = new THREE.Color(0x070b1e);
  const sky = day.lerp(night, nt * .95); SC.background.copy(sky); SC.fog.color.copy(sky);
  hemiL.intensity = .12 + .85 * (1 - nt); sunL.intensity = .05 + .8 * (1 - nt) * (w === 'rain' ? .5 : 1);
  const lit = [0, 0, 0, 0];
  for (const h of A.hosts) if (h.human && !h.away && !h.sleeping) { const r = roomAt(h.x, h.z); if (r >= 0 && r < 4) lit[r] = 1; }
  roomL.forEach((l, i) => { const tgt = nt > .05 || w === 'rain' ? (lit[i] ? 1.15 : 0) : (lit[i] ? .5 : 0); l.intensity += (tgt - l.intensity) * Math.min(1, dt * 4); });
  headL.position.set(pl.x, pl.y + .1, pl.z); headL.intensity = .15 + .4 * nt;
  // cửa chính
  const target = A.doorOpen ? -1.5 : 0; doorGrp.rotation.y += (target - doorGrp.rotation.y) * Math.min(1, dt * 6);
  // mưa
  if (rainPts.visible) {
    rainPts.position.set(pl.x, 0, pl.z);
    const p = rainPts.geometry.attributes.position;
    for (let i = 0; i < p.count; i++) { let y = p.getY(i) - 12 * dt; if (y < 0) y += 10; p.setY(i, y); }
    p.needsUpdate = true;
  }
  // hoa
  for (const f of F3) { const s = .6 + .4 * f.nec / 100; f.core.scale.setScalar(s); f.core.material = f.nec > 25 ? mat(0xffd23f) : mat(0x9a9a8a); }
  // vật chủ
  for (const h of A.hosts) {
    const g = h.grp; g.visible = !h.away;
    if (h.away) { if (h.ring) h.ring.visible = false; continue; }
    if (h.human) {
      const u = g.userData, s = h.def.scale;
      if (h.sleeping) {
        g.rotation.set(0, 0, -Math.PI / 2); g.position.set(h.x - .8 * s, .5 + .2 * s, h.z);
        u.legL.rotation.x = u.legR.rotation.x = u.armL.rotation.x = u.armR.rotation.x = 0;
        const tossing = h.tossing > 0 ? Math.sin(A.t * 20) * .1 : 0; g.rotation.x = tossing;
      } else {
        g.rotation.set(0, h.yaw, 0); g.position.set(h.x, 0, h.z);
        const ph = A.t * 8;
        if (h.walk) { u.legL.rotation.x = Math.sin(ph) * .7; u.legR.rotation.x = -Math.sin(ph) * .7; u.armL.rotation.x = -Math.sin(ph) * .5; u.armR.rotation.x = Math.sin(ph) * .5; }
        else { u.legL.rotation.x = u.legR.rotation.x = 0; u.armL.rotation.x = u.armR.rotation.x = 0; if (h.act === 'cook') u.armR.rotation.x = -.9 + Math.sin(A.t * 6) * .2; if (h.act === 'eat') u.armR.rotation.x = -1 + Math.sin(A.t * 3) * .3; }
        if (h.st === 'wind') u.armR.rotation.x = -2.9 + Math.sin(A.t * 40) * .1;
        if (h.sleeping === false && h.act === 'sleep') g.rotation.z = 0;
      }
    } else {
      g.position.set(h.x, h.def.kind === 'bird' ? h.def.cy - .15 : 0, h.z); g.rotation.y = h.yaw + (h.st === 'wind' ? Math.sin(A.t * 50) * .15 : 0);
    }
    const r = h.ring; if (r) { r.visible = h.st === 'wind'; if (r.visible) { r.position.set(h.x, h.def.reach / 2, h.z); r.scale.set(h.def.swat, h.def.reach / 2 + .2, h.def.swat); } }
  }
  // chuồn chuồn
  for (const d of A.drag) {
    d.grp.position.set(d.x, d.y, d.z); d.grp.rotation.y = d.yaw;
    for (const [w, sx] of d.grp.userData.wings) w.rotation.z = sx * Math.sin(A.t * 60 + d.ph) * .5;
  }
  // NPC
  for (const n of A.npc) {
    if (!n.alive) continue;
    n.grp.position.set(n.x, n.y, n.z); n.grp.rotation.y = Math.atan2(n.tx - n.x, n.tz - n.z);
    flapMosq(n.grp, A.t + n.ph);
  }
  // sương độc
  if (A.spray) { sprayMesh.visible = true; const r = A.spray.t < 0 ? .5 : A.spray.r; sprayMesh.scale.set(r, Math.min(r, 6), r); sprayMesh.position.set(A.spray.cx, Math.min(r, 6) * .5, A.spray.cz); sprayMesh.material.opacity = A.spray.t < 0 ? .1 : .25 * (A.spray.t > 14 ? (18 - A.spray.t) / 4 : 1); }
  // nhãn địa điểm
  for (let i = 0; i < siteLab.length; i++) { const s = SITE3[i]; siteLab[i].visible = Math.hypot(pl.x - s.x, pl.z - s.z) < 10; siteLab[i].material.opacity = 1; }
  // muỗi người chơi
  const mg = mosqG;
  mg.position.set(pl.x, pl.y, pl.z);
  const sp = Math.hypot(pl.vx, pl.vz);
  if (sp > .3) _lastYaw = Math.atan2(pl.vx, pl.vz);
  let dy = _lastYaw - mg.rotation.y; while (dy > Math.PI) dy -= 2 * Math.PI; while (dy < -Math.PI) dy += 2 * Math.PI;
  mg.rotation.y += dy * Math.min(1, dt * 10);
  mg.rotation.x = clamp(-pl.vy * .12, -.6, .6);
  flapMosq(mg, pl.flap, pl.landed ? .2 : 1);
  mg.userData.abd.scale.set(1 + pl.blood * .7, 1 + pl.blood * .7, 2.6 + pl.blood * 1.2);
  mg.userData.abd.material = pl.blood > .02 ? mat(new THREE.Color().setRGB(.35 + pl.blood * .5, .05, .08).getHex()) : mat(0x4d4238);
  // camera bám đuôi
  const fw = fwd3(), dist3 = .62;
  let cx = pl.x - fw[0] * dist3, cy = pl.y - fw[1] * dist3 + .1, cz = pl.z - fw[2] * dist3;
  if (inHouse(pl.x, pl.z, 0)) { cx = clamp(cx, HOUSE.x0 + .15, HOUSE.x1 - .15); cz = clamp(cz, HOUSE.z0 + .15, HOUSE.z1 - .15); cy = clamp(cy, .08, HWALL - .1); }
  else cy = Math.max(cy, .08);
  CAM.position.set(cx, cy, cz); CAM.lookAt(pl.x + fw[0] * .4, pl.y + fw[1] * .4 + .02, pl.z + fw[2] * .4);
}
function flapMosq(g, t, k = 1) { const u = g.userData, a = Math.sin(t * 70) * .6 * k; u.wL.rotation.z = -.2 - a; u.wR.rotation.z = .2 + a; }

/* ───────── vẽ ───────── */
function setGL(on) { const c = document.getElementById('gl'); if (c) c.style.visibility = on ? 'visible' : 'hidden'; }
const _pv = new THREE.Vector3();
function toScreen(x, y, z) { _pv.set(x, y, z).project(CAM); return { x: (_pv.x * .5 + .5) * W, y: (-_pv.y * .5 + .5) * H, behind: _pv.z > 1 }; }

function renderAdult3D() {
  setGL(true);
  if (!T3.ok) return;
  if (S.shake > 0) CAM.position.x += rnd(-.01, .01);
  R3.render(SC, CAM);
  ctx.clearRect(0, 0, W, H);
  hudAdult3D();
}

function hudAdult3D() {
  const nt = nightAmt(A.clock);
  txt(`THẾ HỆ ${pad(L.gen)}  ·  NGÀY ${dayNo()}  ·  ${L.sex === 'M' ? 'MUỖI ĐỰC ♂' : 'MUỖI CÁI ♀'}  ·  ${BUILDS[G.build].name}`, 16, 20, 16, '#fff');
  const maxAge = L.sex === 'M' ? 160 : 240;
  let y = 40;
  bar(16, y, 230, 16, pl.energy / 100, pl.energy < 30 ? '#ff4d3d' : '#ffd23f', L.sex === 'F' ? (pl.energy < 30 ? '⚠ ĐÓI! Hút máu ngay' : 'No bụng (hút máu để sống)') : 'Năng lượng (hút mật)'); y += 22;
  bar(16, y, 230, 16, 1 - pl.age / maxAge, '#b0b8c0', 'Tuổi thọ'); y += 22;
  if (L.sex === 'F') {
    bar(16, y, 230, 16, pl.blood, '#c0202e', 'Máu đã hút'); y += 26;
    txt(`${pl.mated ? '☑' : '☐'} Giao phối   ${pl.protein > .05 ? '☑' : '☐'} Hút máu   ☐ Đẻ trứng ở nước tù`, 16, y, 14, '#fff');
  } else txt(`${pl.mated ? '☑' : '☐'} Tìm muỗi cái bằng tiếng vỗ cánh 🎧`, 16, y + 4, 14, '#fff');
  { const hh = Math.floor(A.clock), mm = Math.floor((A.clock % 1) * 60); txt(`${nt > .5 ? '🌙' : '☀️'} ${pad(hh)}:${pad(mm)}`, W / 2, 20, 18, '#fff', 'center'); }
  hudRight();
  // bản đồ nhìn từ trên xuống
  { const sc = 3.2, ox = -24, oz = -11, mx = 16, my = H - 108, mw = 56 * sc * .95, mh = 29 * sc * .95;
    ctx.fillStyle = 'rgba(8,14,18,.62)'; rr(mx - 4, my - 4, mw + 8, mh + 8, 8); ctx.fill();
    const P2 = (x, z) => [mx + (x - ox) * sc, my + (z - oz) * sc];
    let a = P2(HOUSE.x0, HOUSE.z0); ctx.strokeStyle = '#e8d9b8'; ctx.lineWidth = 2; ctx.strokeRect(a[0], a[1], 14 * sc, 9 * sc);
    ctx.fillStyle = '#8fd0ff'; SITE3.forEach(s => { const p = P2(s.x, s.z); ctx.beginPath(); ctx.arc(p[0], p[1], Math.max(2.5, s.r * sc * .6), 0, 7); ctx.fill(); });
    ctx.fillStyle = '#ffb04a'; for (const h of A.hosts) if (!h.away) { const p = P2(h.x, h.z); ctx.fillRect(p[0] - 1.5, p[1] - 1.5, 3, 3); }
    ctx.fillStyle = '#ff5050'; for (const d of A.drag) if (Math.hypot(d.x - pl.x, d.z - pl.z) < 14) { const p = P2(d.x, d.z); ctx.fillRect(p[0] - 2, p[1] - 2, 4, 4); }
    const pp = P2(pl.x, pl.z); ctx.fillStyle = '#fff'; ctx.beginPath(); ctx.arc(pp[0], pp[1], 3.5, 0, 7); ctx.fill();
  }
  // nhãn & thanh cảnh giác trên đầu vật chủ
  for (const h of A.hosts) {
    if (h.away) continue;
    const top = h.human ? (h.sleeping ? 1.2 : 1.85 * h.def.scale + .2) : h.def.cy + h.def.r + .25;
    const d = Math.hypot(pl.x - h.x, pl.y - top, pl.z - h.z); if (d > 12) continue;
    const s = toScreen(h.x, top, h.z); if (s.behind || s.x < -40 || s.x > W + 40) continue;
    if (h.alert > .04) { const bw = 56; ctx.fillStyle = 'rgba(0,0,0,.55)'; ctx.fillRect(s.x - bw / 2, s.y - 12, bw, 7); ctx.fillStyle = h.alert > .7 ? '#ff4d4d' : '#ffc94d'; ctx.fillRect(s.x - bw / 2, s.y - 12, bw * h.alert, 7); }
    if (h.st === 'wind') txt('❗ ĐẬP!', s.x, s.y - 30, 26, '#ff3d3d', 'center', '800');
    if (L.sex === 'F' && d < 7) { const at = h.human ? ' · ' + (ACTTXT[h.hunt > 0 ? 'alert' : h.act] || '') : ''; txt(h.def.name + at, s.x, s.y + 6, 13, h.hunt > 0 ? '#ff9a9a' : '#fff', 'center', '600'); }
  }
  // chỉ hướng mục tiêu trong tầm cảm nhận
  { const sr = sense3(), list = [];
    if (!pl.mated) for (const n of A.npc) if (n.alive) list.push({ x: n.x, y: n.y, z: n.z, c: '#ff7fb0', t: 'bạn tình' });
    if (L.sex === 'F' && pl.blood < .95) for (const h of A.hosts) if (!h.away) list.push({ x: h.x, y: h.human ? 1 : h.def.cy, z: h.z, c: '#ff5a3d', t: h.def.name });
    let b = null, bd = 1e9;
    for (const t of list) { const d = Math.hypot(pl.x - t.x, pl.y - t.y, pl.z - t.z); if (d < bd) { bd = d; b = t; } }
    if (b && bd < sr && bd > 1) {
      const s = toScreen(b.x, b.y, b.z), al = clamp(1 - bd / sr, .35, 1);
      ctx.save(); ctx.globalAlpha = al;
      if (!s.behind && s.x > 30 && s.x < W - 30 && s.y > 30 && s.y < H - 30) { ctx.fillStyle = b.c; ctx.beginPath(); ctx.moveTo(s.x, s.y + 24); ctx.lineTo(s.x - 9, s.y + 8); ctx.lineTo(s.x + 9, s.y + 8); ctx.fill(); txt(`${b.t} ${bd.toFixed(1)}m`, s.x, s.y + 38, 12, b.c, 'center', '600'); }
      else { let dx = s.x - W / 2, dy = s.y - H / 2; if (s.behind) { dx = -dx; dy = -dy; } const ang = Math.atan2(dy, dx); const ex = W / 2 + Math.cos(ang) * 300, ey = H / 2 + Math.sin(ang) * 210; ctx.translate(clamp(ex, 30, W - 30), clamp(ey, 30, H - 30)); ctx.rotate(ang); ctx.fillStyle = b.c; ctx.beginPath(); ctx.moveTo(14, 0); ctx.lineTo(-8, -9); ctx.lineTo(-8, 9); ctx.fill(); }
      ctx.restore();
    }
    for (const d of A.drag) if (d.st === 'chase') { const s = toScreen(d.x, d.y, d.z); if (s.behind || s.x < 0 || s.x > W) txt('⚠ chuồn chuồn', clamp(s.behind ? W - s.x : s.x, 70, W - 70), H - 130, 14, '#ff6b6b', 'center', '700'); else txt('!', s.x, s.y - 30, 28, '#ff3d3d', 'center', '800'); }
  }
  // thanh tiến độ giao phối / đẻ trứng
  if (pl.mate > 0 || pl.lay > 0) { const v = Math.max(pl.mate / 1.5, pl.lay / 1.8); ctx.fillStyle = 'rgba(0,0,0,.55)'; ctx.fillRect(W / 2 - 60, H / 2 + 50, 120, 9); ctx.fillStyle = pl.mate > 0 ? '#ff6fa8' : '#fff6d6'; ctx.fillRect(W / 2 - 60, H / 2 + 50, 120 * v, 9); }
  // viền đỏ khi đói
  if (L.sex === 'F' && pl.energy < 30 && !S.dead) {
    const a = (.18 + .12 * Math.sin(S.t * 6)) * (1 - pl.energy / 30);
    const vg = ctx.createRadialGradient(W / 2, H / 2, 200, W / 2, H / 2, 560); vg.addColorStop(0, 'rgba(160,0,0,0)'); vg.addColorStop(1, `rgba(160,0,0,${a * 3})`); ctx.fillStyle = vg; ctx.fillRect(0, 0, W, H);
  }
  if (pl.exposure > 0 && !S.dead) txt('☠ ĐANG HÍT THUỐC ĐỘC!', W / 2, 80, 26, '#ff4d4d', 'center', '800');
  if (A.spray && A.spray.t < 0) txt('🧴 SẮP PHUN THUỐC — rời khỏi vùng sương!', W / 2, 60, 22, '#d6ff6a', 'center', '800');
  if (S.prompt && !S.ending) txt(S.prompt, W / 2, H - 52, 20, '#fff', 'center', '700');
  else if (!S.ending) txt('Chuột/kéo: nhìn · W A S D: bay · Space: lên · Shift: xuống · E: hành động', W / 2, H - 22, 14, '#fff', 'center', '500');
  // bảng đánh giá nguồn nước
  if (L.sex === 'F') {
    let si = -1, sd = 1e9;
    SITES.forEach((s, i) => { const d = Math.hypot(pl.x - SITE3[i].x, pl.z - SITE3[i].z) - SITE3[i].r; if (d < 6 && d < sd) { sd = d; si = i; } });
    if (si >= 0) {
      const s = SITES[si], a = attrs(s), gd = goodness(a), sc2 = scoreOf(a);
      const bx0 = W - 250, by = 92; panel(bx0, by, 236, 188);
      txt(`💧 ${s.name}${siteDry(si) ? ' — KHÔ' : ''}`, bx0 + 12, by + 18, 15, '#fff');
      let yy = by + 42;
      for (const k in gd) {
        txt(k, bx0 + 12, yy, 12, '#cde', 'left', '500', false);
        const v = gd[k]; ctx.fillStyle = 'rgba(255,255,255,.12)'; ctx.fillRect(bx0 + 100, yy - 5, 120, 10);
        ctx.fillStyle = v > .66 ? '#6fd36a' : v > .4 ? '#e5c24a' : '#e5584a'; ctx.fillRect(bx0 + 100, yy - 5, 120 * v, 10); yy += 20;
      }
      txt(`Điểm phù hợp: ${Math.round(sc2 * 100)}%`, bx0 + 12, by + 172, 14, siteDry(si) ? '#ff8a8a' : '#fff', 'left', '700');
    }
  }
  if (S.ending) {
    ctx.fillStyle = 'rgba(0,0,0,.55)'; ctx.fillRect(0, 0, W, H);
    txt(S.ending.text, W / 2, H / 2 - 20, 24, '#fff', 'center', '700');
    txt(S.ending.sub, W / 2, H / 2 + 20, 17, '#ffe9a8', 'center');
  }
}

/* ───────── điều khiển chuột ───────── */
addEventListener('mousemove', e => {
  if (S.mode !== 'adult') return;
  if (document.pointerLockElement === cv || T3.drag) {
    T3.yaw -= (e.movementX || 0) * .0025; T3.pitch = clamp(T3.pitch - (e.movementY || 0) * .0025, -1.3, 1.3);
  }
});
cv.addEventListener('pointerdown', () => { T3.drag = true; if (S.mode === 'adult' && cv.requestPointerLock && !document.pointerLockElement) { try { cv.requestPointerLock(); } catch (e) { /* bỏ qua */ } } });
addEventListener('pointerup', () => { T3.drag = false; });
