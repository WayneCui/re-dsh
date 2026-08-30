// harness-spine 漫画生成器 —— minimalist 四格风格（baoyu-comic four-panel 预设的实现）
// 运行: bun comic-gen.ts  → 输出各 books/*/comics/*.svg

const OUT_HF = "/Users/wayne/2-learning/agent-projects/harness-spine/books/head-first-harness-spine/comics";
const OUT_BS = "/Users/wayne/2-learning/agent-projects/harness-spine/books/build-harness-spine-from-scratch/comics";

// ---------- 调色 ----------
const INK = "#1F2937";        // 线条
const PAPER = "#FDF6EC";      // 纸面
const PANEL = "#FFFFFF";
const C_XK = "#F59E0B";       // 小壳 · 橙
const C_JX = "#64748B";       // 脊先生 · 灰蓝
const C_AC = "#10B981";       // 阿粗 · 绿
const C_ZF = "#1E3A8A";       // 账房先生 · 藏蓝
const C_GK = "#8B5CF6";       // 客人 · 紫
const C_MF = "#DC2626";       // 门房 · 红
const C_FG = "#0D9488";       // 前台 · 青
const RED = "#DC2626", GREEN = "#16A34A", BLUE = "#2563EB", GRAY = "#9CA3AF";

// ---------- 基础元件 ----------
// 点归一化：函数一律接受 {x,y} 或 (x, y)
type Pt = { x: number; y: number };
function px(v: number | Pt, dy?: number): number { return typeof v === "object" ? v.x : v as number; }
function py(v: number | Pt, dy?: number): number { return typeof v === "object" ? v.y : (dy ?? 0); }

function bubble(x: number | Pt, y: number, w: number, lines: string[], tail = "down", fill = "#FFFFFF") {
  const X = px(x, y), Y = py(x, y);
  const h = 16 + lines.length * 16;
  const cx = X + w / 2;
  let tailSvg = "";
  if (tail === "down") tailSvg = `<path d="M ${cx - 7} ${Y + h} L ${cx} ${Y + h + 12} L ${cx + 7} ${Y + h} Z" fill="${fill}" stroke="${INK}" stroke-width="1.6"/>`;
  if (tail === "left") tailSvg = `<path d="M ${X} ${Y + h / 2 - 6} L ${X - 12} ${Y + h / 2 + 4} L ${X} ${Y + h / 2 + 8} Z" fill="${fill}" stroke="${INK}" stroke-width="1.6"/>`;
  if (tail === "right") tailSvg = `<path d="M ${X + w} ${Y + h / 2 - 6} L ${X + w + 12} ${Y + h / 2 + 4} L ${X + w} ${Y + h / 2 + 8} Z" fill="${fill}" stroke="${INK}" stroke-width="1.6"/>`;
  const text = lines.map((l, i) =>
    `<text x="${cx}" y="${Y + 22 + i * 16}" font-size="13" text-anchor="middle" fill="${INK}" font-weight="600">${l}</text>`).join("\n");
  return `<rect x="${X}" y="${Y}" width="${w}" height="${h}" rx="10" fill="${fill}" stroke="${INK}" stroke-width="1.6"/>
${tailSvg}\n${text}`;
}

function caption(x: number | Pt, y: number, text: string, size = 14, color = INK) {
  return `<text x="${px(x, y)}" y="${py(x, y)}" font-size="${size}" fill="${color}" font-weight="700">${text}</text>`;
}

function label(x: number | Pt, y: number, text: string, color = INK, size = 12, anchor = "middle") {
  return `<text x="${px(x, y)}" y="${py(x, y)}" font-size="${size}" text-anchor="${anchor}" fill="${color}" font-weight="600">${text}</text>`;
}

// 旗帜
function flag(x: number | Pt, y: number, color = RED, up = true) {
  const X = px(x, y), Y = py(x, y);
  const tip = up ? Y - 20 : Y - 4;
  return `<line x1="${X}" y1="${Y}" x2="${X}" y2="${tip}" stroke="${INK}" stroke-width="2.5"/>
<path d="M ${X} ${tip} L ${X + 20} ${tip + 5} L ${X} ${tip + 11} Z" fill="${color}" stroke="${INK}" stroke-width="1.4"/>`;
}

// 书本/账本（可开合）
function ledger(x: number | Pt, y: number, w = 46, h = 34, open = true) {
  const X = px(x, y), Y = py(x, y);
  if (open) return `<path d="M ${X} ${Y} Q ${X + w / 2} ${Y - 8} ${X + w / 2} ${Y} Q ${X + w / 2} ${Y - 8} ${X + w} ${Y} L ${X + w} ${Y + h} Q ${X + w / 2} ${Y + h - 6} ${X} ${Y + h} Z" fill="#FEF3C7" stroke="${INK}" stroke-width="2"/>
<line x1="${X + w / 2}" y1="${Y}" x2="${X + w / 2}" y2="${Y + h}" stroke="${INK}" stroke-width="1.6"/>
${[1, 2, 3].map(i => `<line x1="${X + 5}" y1="${Y + 6 + i * 7}" x2="${X + w / 2 - 6}" y2="${Y + 6 + i * 7}" stroke="${GRAY}" stroke-width="1.2"/><line x1="${X + w / 2 + 6}" y1="${Y + 6 + i * 7}" x2="${X + w - 5}" y2="${Y + 6 + i * 7}" stroke="${GRAY}" stroke-width="1.2"/>`).join("\n")}`;
  return `<rect x="${X}" y="${Y}" width="${w}" height="${h}" rx="3" fill="#FEF3C7" stroke="${INK}" stroke-width="2"/><line x1="${X + 7}" y1="${Y}" x2="${X + 7}" y2="${Y + h}" stroke="${INK}" stroke-width="1.6"/>`;
}

// 门
function door(x: number | Pt, y: number, w = 42, h = 74, color = "#FFFFFF") {
  const X = px(x, y), Y = py(x, y);
  return `<rect x="${X}" y="${Y - h}" width="${w}" height="${h}" rx="4" fill="${color}" stroke="${INK}" stroke-width="2.4"/>
<circle cx="${X + w - 8}" cy="${Y - h / 2}" r="3.2" fill="${INK}"/>
<rect x="${X - 4}" y="${Y}" width="${w + 8}" height="5" fill="${INK}"/>`;
}

// 影印机（快照）
function copier(x: number | Pt, y: number) {
  const X = px(x, y), Y = py(x, y);
  return `<rect x="${X}" y="${Y - 40}" width="86" height="46" rx="5" fill="#E5E7EB" stroke="${INK}" stroke-width="2"/>
<rect x="${X + 12}" y="${Y - 34}" width="62" height="12" rx="2" fill="#FFFFFF" stroke="${INK}" stroke-width="1.4"/>
<circle cx="${X + 74}" cy="${Y - 8}" r="4" fill="${GREEN}" stroke="${INK}" stroke-width="1.2"/>
<rect x="${X + 30}" y="${Y + 6}" width="26" height="14" fill="#FFFFFF" stroke="${INK}" stroke-width="1.6"/>
<line x1="${X + 34}" y1="${Y + 20}" x2="${X + 52}" y2="${Y + 20}" stroke="${INK}" stroke-width="1.4"/>`;
}

// 大喇叭
function speaker(x: number | Pt, y: number, scale = 1) {
  const X = px(x, y), Y = py(x, y);
  const s = scale;
  return `<g transform="translate(${X},${Y}) scale(${s})">
<path d="M 0 0 L 26 -16 L 26 16 Z" fill="${C_JX}" stroke="${INK}" stroke-width="2"/>
<rect x="-14" y="-6" width="14" height="12" fill="${INK}"/>
${[-12, 0, 12].map(d => `<path d="M 30 ${d} q 6 ${-d / 3} 12 0" stroke="${INK}" stroke-width="1.6" fill="none"/>`).join("\n")}
</g>`;
}

// 印章手柄
function stamp(x: number | Pt, y: number, text: string) {
  const X = px(x, y), Y = py(x, y);
  return `<g transform="translate(${X},${Y})">
<rect x="-6" y="-34" width="12" height="22" rx="3" fill="${C_MF}" stroke="${INK}" stroke-width="1.6"/>
<rect x="-20" y="-12" width="40" height="12" rx="2" fill="${INK}"/>
<rect x="-24" y="-56" width="48" height="24" rx="6" fill="${PAPER}" stroke="${C_MF}" stroke-width="2.4"/>
<text x="0" y="-39" font-size="12" text-anchor="middle" fill="${C_MF}" font-weight="800">${text}</text>
</g>`;
}

// 鬼魂（虚线）
function ghost(x: number | Pt, y: number, s = 1) {
  const X = px(x, y), Y = py(x, y);
  return `<g transform="translate(${X},${Y}) scale(${s})" opacity="0.85">
<path d="M -14 10 L -14 -4 Q -14 -18 0 -18 Q 14 -18 14 -4 L 14 10 L 9 5 L 5 10 L 0 5 L -5 10 L -9 5 Z"
 fill="none" stroke="${GRAY}" stroke-width="2.2" stroke-dasharray="4 3"/>
<circle cx="-5" cy="-6" r="1.8" fill="${GRAY}"/><circle cx="5" cy="-6" r="1.8" fill="${GRAY}"/>
</g>`;
}

// ---------- 人物 ----------
// pose: stand|point-r|point-l|raise|panic|shrug|read|write|walk|carry|block
function figure(x: number, y: number, who: string, pose = "stand", scale = 1) {
  const cfg: Record<string, { c: string; hair: string; extra: string }> = {
    xiaoke: { c: C_XK, hair: "bob", extra: "glasses" },
    spine: { c: C_JX, hair: "flat", extra: "beard" },
    acu: { c: C_AC, hair: "spiky", extra: "" },
    clerk: { c: C_ZF, hair: "cap", extra: "mustache" },
    guest: { c: C_GK, hair: "long", extra: "scarf" },
    doorman: { c: C_MF, hair: "uniformcap", extra: "" },
    desk: { c: C_FG, hair: "bun", extra: "" },
  };
  const { c, hair, extra } = cfg[who];
  const g = (body: string) => `<g transform="translate(${x},${y}) scale(${scale})">${body}</g>`;

  // 身体基座（头心在 0,-72；地面 y=0）
  let head = `<circle cx="0" cy="-72" r="14" fill="#FFE8CC" stroke="${INK}" stroke-width="2.2"/>`;
  if (hair === "bob") head += `<path d="M -14 -74 Q -13 -89 0 -89 Q 13 -89 14 -74 Q 8 -80 0 -79 Q -8 -80 -14 -74 Z" fill="${c}" stroke="${INK}" stroke-width="1.6"/><path d="M -15 -72 Q -17 -60 -12 -55 L -10 -62" fill="${c}" stroke="${INK}" stroke-width="1.4"/>`;
  if (hair === "flat") head += `<path d="M -14 -78 Q -6 -86 8 -84 Q 14 -83 14 -77 L 12 -74 Q 4 -80 -10 -77 Z" fill="${INK}"/>`;
  if (hair === "spiky") head += `<path d="M -13 -76 L -11 -88 L -6 -80 L -2 -91 L 3 -81 L 8 -90 L 11 -79 L 14 -75 Q 6 -84 -6 -82 Z" fill="${INK}"/>`;
  if (hair === "cap") head += `<path d="M -14 -76 Q -14 -88 0 -88 Q 14 -88 14 -76 Z" fill="${c}" stroke="${INK}" stroke-width="1.6"/><rect x="-19" y="-78" width="38" height="4.5" rx="2" fill="${INK}"/>`;
  if (hair === "long") head += `<path d="M -14 -74 Q -16 -90 0 -90 Q 16 -90 14 -74 Q 15 -60 12 -50 L 8 -62 Q 9 -72 6 -76 Q 0 -82 -8 -76 Q -11 -72 -10 -60 L -13 -50 Q -16 -62 -14 -74 Z" fill="${INK}"/>`;
  if (hair === "uniformcap") head += `<path d="M -14 -76 Q -14 -88 0 -88 Q 14 -88 14 -76 Z" fill="${c}" stroke="${INK}" stroke-width="1.6"/><rect x="-18" y="-80" width="36" height="6" rx="2.5" fill="${c}" stroke="${INK}" stroke-width="1.4"/>`;
  if (hair === "bun") head += `<circle cx="9" cy="-87" r="5" fill="${INK}"/><path d="M -14 -74 Q -13 -88 0 -88 Q 13 -88 14 -74 Q 7 -81 0 -80 Q -7 -81 -14 -74 Z" fill="${INK}"/>`;
  if (extra === "glasses") head += `<circle cx="-5.5" cy="-71" r="4.4" fill="none" stroke="${INK}" stroke-width="1.5"/><circle cx="5.5" cy="-71" r="4.4" fill="none" stroke="${INK}" stroke-width="1.5"/><line x1="-1.2" y1="-71" x2="1.2" y2="-71" stroke="${INK}" stroke-width="1.5"/>`;
  if (extra === "beard") head += `<path d="M -7 -62 Q 0 -56 7 -62 Q 4 -58 0 -58 Q -4 -58 -7 -62 Z" fill="${INK}"/>`;
  if (extra === "mustache") head += `<path d="M -6 -65 Q 0 -69 6 -65 Q 0 -63 -6 -65 Z" fill="${INK}"/>`;
  if (extra === "scarf") head += `<path d="M -12 -58 Q 0 -52 12 -58 L 12 -50 Q 0 -45 -12 -50 Z" fill="${c}" stroke="${INK}" stroke-width="1.5"/><path d="M 10 -52 Q 18 -44 14 -34 L 9 -44 Z" fill="${c}" stroke="${INK}" stroke-width="1.5"/>`;

  // 躯干（服装色块）+ 四肢
  let body = `<path d="M -10 -58 L 10 -58 L 12 -26 L -12 -26 Z" fill="${c}" stroke="${INK}" stroke-width="2"/>`;
  let arms = `<line x1="-10" y1="-52" x2="-18" y2="-38" stroke="${INK}" stroke-width="2.4"/><line x1="10" y1="-52" x2="18" y2="-38" stroke="${INK}" stroke-width="2.4"/>`;
  let legs = `<line x1="-5" y1="-26" x2="-7" y2="0" stroke="${INK}" stroke-width="2.4"/><line x1="5" y1="-26" x2="7" y2="0" stroke="${INK}" stroke-width="2.4"/>`;
  let props = "";

  if (pose === "point-r") arms = `<line x1="-10" y1="-52" x2="-16" y2="-36" stroke="${INK}" stroke-width="2.4"/><line x1="10" y1="-52" x2="30" y2="-56" stroke="${INK}" stroke-width="2.4"/><circle cx="32" cy="-56" r="2.6" fill="${INK}"/>`;
  if (pose === "point-l") arms = `<line x1="10" y1="-52" x2="16" y2="-36" stroke="${INK}" stroke-width="2.4"/><line x1="-10" y1="-52" x2="-30" y2="-56" stroke="${INK}" stroke-width="2.4"/><circle cx="-32" cy="-56" r="2.6" fill="${INK}"/>`;
  if (pose === "raise") arms = `<line x1="-10" y1="-52" x2="-14" y2="-34" stroke="${INK}" stroke-width="2.4"/><line x1="10" y1="-52" x2="20" y2="-72" stroke="${INK}" stroke-width="2.4"/><circle cx="21" cy="-75" r="3.4" fill="#FFE8CC" stroke="${INK}" stroke-width="1.6"/>`;
  if (pose === "panic") {
    arms = `<line x1="-10" y1="-52" x2="-24" y2="-64" stroke="${INK}" stroke-width="2.4"/><line x1="10" y1="-52" x2="24" y2="-64" stroke="${INK}" stroke-width="2.4"/>`;
    head += `<path d="M -8 -92 q 2 -6 4 0 M 0 -94 q 2 -6 4 0" stroke="${GRAY}" stroke-width="1.4" fill="none"/>`;
  }
  if (pose === "shrug") arms = `<line x1="-10" y1="-52" x2="-22" y2="-58" stroke="${INK}" stroke-width="2.4"/><line x1="10" y1="-52" x2="22" y2="-58" stroke="${INK}" stroke-width="2.4"/><circle cx="-23" cy="-60" r="2.4" fill="${INK}"/><circle cx="23" cy="-60" r="2.4" fill="${INK}"/>`;
  if (pose === "read") {
    arms = `<line x1="-10" y1="-52" x2="-14" y2="-38" stroke="${INK}" stroke-width="2.4"/><line x1="10" y1="-52" x2="14" y2="-38" stroke="${INK}" stroke-width="2.4"/>`;
    props += ledger(-22, -40, 44, 30, true);
  }
  if (pose === "write") {
    arms = `<line x1="-10" y1="-52" x2="-13" y2="-40" stroke="${INK}" stroke-width="2.4"/><line x1="10" y1="-52" x2="16" y2="-42" stroke="${INK}" stroke-width="2.4"/>`;
    props += ledger(-20, -40, 40, 26, true) + `<line x1="14" y1="-46" x2="22" y2="-52" stroke="${INK}" stroke-width="2.6"/>`;
  }
  if (pose === "walk") legs = `<line x1="-5" y1="-26" x2="-14" y2="-4" stroke="${INK}" stroke-width="2.4"/><line x1="5" y1="-26" x2="12" y2="-2" stroke="${INK}" stroke-width="2.4"/>`;
  if (pose === "carry") {
    arms = `<line x1="-10" y1="-52" x2="-16" y2="-36" stroke="${INK}" stroke-width="2.4"/><line x1="10" y1="-52" x2="16" y2="-36" stroke="${INK}" stroke-width="2.4"/>`;
    props += `<rect x="-18" y="-36" width="36" height="22" rx="3" fill="#FFFFFF" stroke="${INK}" stroke-width="2"/><text x="0" y="-21" font-size="10" text-anchor="middle" fill="${INK}">inbox</text>`;
  }
  if (pose === "block") {
    arms = `<line x1="-10" y1="-52" x2="-22" y2="-48" stroke="${INK}" stroke-width="2.4"/><line x1="10" y1="-52" x2="24" y2="-46" stroke="${INK}" stroke-width="2.4"/>`;
    props += `<line x1="26" y1="-64" x2="26" y2="-8" stroke="${C_MF}" stroke-width="6" stroke-linecap="round"/>`;
  }

  return g(head + body + arms + legs + props);
}

// 桌台/柜台
function counter(x: number | Pt, y: number, w = 120, h = 40, fill = "#F3E8D3") {
  const X = px(x, y), Y = py(x, y);
  return `<rect x="${X}" y="${Y - h}" width="${w}" height="${h}" fill="${fill}" stroke="${INK}" stroke-width="2.2"/><line x1="${X}" y1="${Y - h}" x2="${X + w}" y2="${Y - h}" stroke="${INK}" stroke-width="3"/>`;
}

// 对勾 / 叉
function check(x: number | Pt, y: number, ok = true, s = 1) {
  const X = px(x, y), Y = py(x, y);
  const col = ok ? GREEN : RED;
  const d = ok ? `M ${X - 10 * s} ${Y} L ${X - 2 * s} ${Y + 8 * s} L ${X + 12 * s} ${Y - 10 * s}` : `M ${X - 9 * s} ${Y - 9 * s} L ${X + 9 * s} ${Y + 9 * s} M ${X + 9 * s} ${Y - 9 * s} L ${X - 9 * s} ${Y + 9 * s}`;
  return `<path d="${d}" stroke="${col}" stroke-width="${4 * s}" fill="none" stroke-linecap="round"/>`;
}

// ---------- 版面 ----------
const W = 960, H = 760;
const PADX = 34, TITLE_H = 64, GAP = 14;
const PW = (W - PADX * 2 - GAP) / 2;   // ~439
const PH = 300;
const P1 = { x: PADX, y: TITLE_H };
const P2 = { x: PADX + PW + GAP, y: TITLE_H };
const P3 = { x: PADX, y: TITLE_H + PH + GAP };
const P4 = { x: PADX + PW + GAP, y: TITLE_H + PH + GAP };

function page(title: string, panels: string[], footer?: string) {
  const boxes = panels.map((body, i) => {
    const p = [P1, P2, P3, P4][i];
    return `<rect x="${p.x}" y="${p.y}" width="${PW}" height="${PH}" rx="10" fill="${PANEL}" stroke="${INK}" stroke-width="2.6"/>
<g clip-path="url(#pc${i})">${body}</g>
<clipPath id="pc${i}"><rect x="${p.x}" y="${p.y}" width="${PW}" height="${PH}" rx="10"/></clipPath>`;
  }).join("\n");
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}" font-family="'PingFang SC','Hiragino Sans GB','Microsoft YaHei',sans-serif">
<rect width="${W}" height="${H}" fill="${PAPER}"/>
<text x="${W / 2}" y="40" font-size="27" font-weight="800" text-anchor="middle" fill="${INK}">${title}</text>
<line x1="${PADX}" y1="52" x2="${W - PADX}" y2="52" stroke="${INK}" stroke-width="1.6"/>
${boxes}
${footer ? `<text x="${W / 2}" y="${H - 16}" font-size="14.5" text-anchor="middle" fill="${INK}" font-weight="700">${footer}</text>` : ""}
</svg>`;
}

// 面板内坐标助手：返回相对面板左上角的绝对坐标
function at(p: { x: number; y: number }, dx: number, dy: number) {
  return { x: p.x + dx, y: p.y + dy };
}
const GROUND = 272; // 面板内地面 y（相对面板）

function comicsSvg(defs: ComicDef[], outDir: string) {
  for (const d of defs) {
    const svg = page(d.title, d.panels, d.footer);
    await0(Bun.write(`${outDir}/${d.file}.svg`, svg));
  }
}
async function await0(p: Promise<unknown>) { await p; }

interface ComicDef { file: string; title: string; panels: string[]; footer?: string }

// =====================================================================
// 《Head First harness-spine》
// =====================================================================
const hf: ComicDef[] = [];

// 01 封面
hf.push({
  file: "01-cover", title: "Head First harness-spine · 机器旅馆全家福",
  panels: [
    // P1 旅馆外观
    (() => { const p = P1; return `
${door(at(p, 78, GROUND).x, at(p, 78, GROUND).y)}
${figure(at(p, 36, GROUND).x, at(p, 36, GROUND).y, "doorman", "block")}
${label(at(p, 99, GROUND - 92).x, at(p, 99, GROUND - 92).y, "host 门", C_MF)}
${figure(at(p, 200, GROUND).x, at(p, 200, GROUND).y, "xiaoke", "walk")}
${figure(at(p, 250, GROUND).x, at(p, 250, GROUND).y, "spine", "point-l")}
${bubble(at(p, 150, 60).x, at(p, 150, 60).y, 150, ["就是这台机器？"])}
${bubble(at(p, 300, 34).x, at(p, 300, 34).y, 170, ["十根柱子，十章。"], "left")}
${caption(at(p, 24, 30).x, at(p, 24, 30).y, "欢迎入住", 16)}`; })(),
    // P2 前台
    (() => { const p = P2; return `
${counter(at(p, 90, GROUND - 40), 260, 40)}
${figure(at(p, 150, GROUND - 40).x, at(p, 150, GROUND - 40).y, "clerk", "read", 0.9)}
${label(at(p, 220, GROUND - 52).x, at(p, 220, GROUND - 52).y, "session 账本 · 只增不改", C_ZF)}
${figure(at(p, 320, GROUND).x, at(p, 320, GROUND).y, "guest", "stand")}
${label(at(p, 320, GROUND + 14).x, at(p, 320, GROUND + 14).y, "客人：只动嘴", C_GK)}
${caption(at(p, 24, 30).x, at(p, 24, 30).y, "记忆在前台，模型是客人", 15)}`; })(),
    // P3 房间走廊
    (() => { const p = P3; return `
${[0, 1].map(i => `${door(at(p, 120 + i * 150, GROUND - 30).x, at(p, 120 + i * 150, GROUND - 30).y, 42, 74)}${label(at(p, 141 + i * 150, GROUND - 14).x, at(p, 141 + i * 150, GROUND - 14).y, i ? "agent-B 房" : "agent-A 房", INK, 12)}`).join("")}
${label(at(p, 220, 70).x, at(p, 220, 70).y, "isolate 房间：tools / shell / loop 各一份", INK, 13)}
${figure(at(p, 40, GROUND).x, at(p, 40, GROUND).y, "xiaoke", "point-r")}
${caption(at(p, 24, 30).x, at(p, 24, 30).y, "一人一间，动手权私有", 15)}`; })(),
    // P4 全家福名单
    (() => { const p = P4; return `
${["host · 唯一的 I/O 门", "session · 只许追加的日志", "tools · 有证人的公共行为", "approval · 只问一次，缺席即拒绝", "llm · 客人适配器", "agent-loop · 重读账本的账房"].map((t, i) =>
      `${label(at(p, 40, 76 + i * 34).x, at(p, 40, 76 + i * 34).y, t, INK, 14, "start")}${check(at(p, 390, 71 + i * 34), true, 0.8)}`).join("")}
${caption(at(p, 24, 30).x, at(p, 24, 30).y, "这台机器的五个零件 + 一位账房", 15)}`; })(),
  ],
  footer: "能说话 · 能动手 · 能记住 · 能被叫停 —— 且都经得起查账",
});

// 02 ch01 套壳露馅
hf.push({
  file: "02-ch01-wrapper-breaks", title: "第 1 章 · 套壳的末日",
  panels: [
    (() => { const p = P1; return `
${figure(at(p, 395, GROUND).x, at(p, 395, GROUND).y, "acu", "point-l")}
${bubble(at(p, 140, 40).x, at(p, 140, 40).y, 180, ["智能体？十分钟！"], "right")}
${`<rect x="${at(p, 40, 150).x}" y="${at(p, 40, 150).y}" width="330" height="86" rx="8" fill="#F3F4F6" stroke="${INK}" stroke-width="1.6"/>` }
${["messages.append(user)", "reply = llm(messages)", "if tool: run; append; repeat"].map((l, i) => label(at(p, 56, 174 + i * 22).x, at(p, 56, 174 + i * 22).y, l, INK, 14, "start")).join("")}
${caption(at(p, 24, 30).x, at(p, 24, 30).y, "Hackathon 现场，掌声雷动", 15)}`; })(),
    (() => { const p = P2; return `
${figure(at(p, 150, GROUND).x, at(p, 150, GROUND).y, "acu", "panic")}
${bubble(at(p, 40, 34).x, at(p, 40, 34).y, 150, ["刚才到底做了", "什么？"])}
${bubble(at(p, 250, 30).x, at(p, 250, 30).y, 150, ["能停下来吗？"], "down")}
${bubble(at(p, 150, 130).x, at(p, 150, 130).y, 170, ["工具能分开吗？"], "down")}
${label(at(p, 330, GROUND + 12).x, at(p, 330, GROUND + 12).y, "凌晨 3:00", GRAY)}
${caption(at(p, 24, 30).x, at(p, 24, 30).y, "三个问题，当场露馅", 15)}`; })(),
    (() => { const p = P3; return `
${figure(at(p, 90, GROUND).x, at(p, 90, GROUND).y, "xiaoke", "point-r")}
${bubble(at(p, 130, 40).x, at(p, 130, 40).y, 170, ["循环不够用吗？"], "left")}
${figure(at(p, 330, GROUND).x, at(p, 330, GROUND).y, "spine", "shrug")}
${bubble(at(p, 240, 140).x, at(p, 240, 140).y, 180, ["循环只是皮带。"], "down")}
${caption(at(p, 24, 30).x, at(p, 24, 30).y, "小壳的疑问", 15)}`; })(),
    (() => { const p = P4; return `
${[["门 host", C_MF, 36], ["账 session", C_ZF, 116], ["闸 tools", BLUE, 196], ["许可 approval", GREEN, 276], ["客人 llm", C_GK, 352]].map(([t, c, x]) => `
<rect x="${at(p, Number(x), 90).x}" y="${at(p, Number(x), 90).y}" width="82" height="30" rx="6" fill="${c}" opacity="0.14" stroke="${c}" stroke-width="2"/>
${label(at(p, Number(x) + 41, 110).x, at(p, Number(x) + 41, 110).y, String(t), c, 12)}`).join("")}
${figure(at(p, 220, GROUND).x, at(p, 220, GROUND).y, "clerk", "read", 0.95)}
${label(at(p, 220, GROUND + 16).x, at(p, 220, GROUND + 16).y, "账房先生 agent-loop", C_ZF)}
${caption(at(p, 24, 30).x, at(p, 24, 30).y, "真正的机器：五件套 + 账房", 15)}`; })(),
  ],
  footer: "智能体 ≠ 循环。它是一台四件事都经得起查账的机器。",
});

// 03 ch02 回合解剖
hf.push({
  file: "03-ch02-turn-anatomy", title: "第 2 章 · 一条 hello 的奇幻漂流",
  panels: [
    (() => { const p = P1; return `
<line x1="${at(p, 20, GROUND - 60).x}" y1="${at(p, 20, GROUND - 60).y}" x2="${at(p, 420, GROUND - 60).x}" y2="${at(p, 420, GROUND - 60).y}" stroke="${INK}" stroke-width="3"/>
${[0, 1, 2, 3, 4, 5].map(i => `<circle cx="${at(p, 55 + i * 66, GROUND - 60).x}" cy="${at(p, 55 + i * 66, GROUND - 60).y}" r="9" fill="#FFFFFF" stroke="${INK}" stroke-width="2"/>`).join("")}
<rect x="${at(p, 40, GROUND - 110).x}" y="${at(p, 40, GROUND - 110).y}" width="70" height="36" rx="6" fill="#FEF3C7" stroke="${INK}" stroke-width="2"/>
${label(at(p, 75, GROUND - 88).x, at(p, 75, GROUND - 88).y, "hello", INK, 14)}
${["turn-start", "user-message", "誊视图", "llm/stream", "chunk×n", "turn-end"].map((t, i) => label(at(p, 55 + i * 66, GROUND - 34).x, at(p, 55 + i * 66, GROUND - 34).y, t, INK, 11)).join("")}
${caption(at(p, 24, 30).x, at(p, 24, 30).y, "流水线六站，包裹一路入账", 15)}`; })(),
    (() => { const p = P2; return `
${ledger(at(p, 60, GROUND - 90), 150, 60, true)}
${[1, 2, 3, 4, 5, 6, 7].map(i => `<circle cx="${at(p, 76, GROUND - 82).x}" cy="${at(p, 76, GROUND - 82 + i * 8).y}" r="1.6" fill="${INK}"/>`).join("")}
${label(at(p, 226, GROUND - 76).x, at(p, 226, GROUND - 76).y, "日志 7 行", C_ZF, 14, "start")}
${figure(at(p, 320, GROUND).x, at(p, 320, GROUND).y, "clerk", "read")}
${bubble(at(p, 230, 40).x, at(p, 230, 40).y, 170, ["簿记也要入账。"], "down")}
${caption(at(p, 24, 30).x, at(p, 24, 30).y, "① turn-start ② user-message … ⑦ turn-end", 14)}`; })(),
    (() => { const p = P3; return `
${figure(at(p, 120, GROUND).x, at(p, 120, GROUND).y, "clerk", "read")}
${bubble(at(p, 200, 44).x, at(p, 200, 44).y, 190, ["誊本：user 一行，", "assistant 一行。"], "left")}
${figure(at(p, 360, GROUND).x, at(p, 360, GROUND).y, "guest", "stand")}
${label(at(p, 360, GROUND + 16).x, at(p, 360, GROUND + 16).y, "模型只看誊本", C_GK)}
${caption(at(p, 24, 30).x, at(p, 24, 30).y, "视图是算出来的，不是存着的", 15)}`; })(),
    (() => { const p = P4; return `
${label(at(p, 220, 66).x, at(p, 220, 66).y, "日志 7 行  ≠  视图 2 行", C_ZF, 17)}
${["chunk 碎片 → 折叠", "簿记 → 不上桌", "最终 assistant-message → 说了算"].map((t, i) => label(at(p, 90, 116 + i * 34).x, at(p, 90, 116 + i * 34).y, t, INK, 14, "start")).join("")}
${figure(at(p, 340, GROUND).x, at(p, 340, GROUND).y, "spine", "point-l")}
${bubble(at(p, 60, 170).x, at(p, 60, 170).y, 200, ["差额每一行都有名字。"], "right")}
${caption(at(p, 24, 30).x, at(p, 24, 30).y, "echo 兜底：没有厂商也走得完", 15)}`; })(),
  ],
  footer: "日志是记忆，视图是模型看到的东西——这次分裂贯穿全书。",
});

// 04 ch03 账本与誊本
hf.push({
  file: "04-ch03-ledger-and-transcript", title: "第 3 章 · 账本与誊本",
  panels: [
    (() => { const p = P1; return `
${figure(at(p, 100, GROUND).x, at(p, 100, GROUND).y, "clerk", "write")}
${ledger(at(p, 200, GROUND - 100), 180, 76, true)}
${["① 验明正身", "② 影印存档", "③ 编号追加", "④ 广播"].map((t, i) => label(at(p, 250, 70 + i * 26).x, at(p, 250, 70 + i * 26).y, t, C_ZF, 13, "start")).join("")}
${caption(at(p, 24, 30).x, at(p, 24, 30).y, "append-event 四道工序", 15)}`; })(),
    (() => { const p = P2; return `
${figure(at(p, 110, GROUND).x, at(p, 110, GROUND).y, "clerk", "block")}
${figure(at(p, 200, GROUND).x, at(p, 200, GROUND).y, "acu", "point-l")}
${bubble(at(p, 230, 50).x, at(p, 230, 50).y, 180, ["我就改一小行…"], "left")}
${bubble(at(p, 30, 120).x, at(p, 30, 120).y, 170, ["账本只增不改。"], "right")}
${caption(at(p, 24, 30).x, at(p, 24, 30).y, "历史不容涂改", 15)}`; })(),
    (() => { const p = P3; return `
${copier(at(p, 50, GROUND - 60))}
${figure(at(p, 200, GROUND).x, at(p, 200, GROUND).y, "xiaoke", "point-r")}
${bubble(at(p, 240, 44).x, at(p, 240, 44).y, 190, ["递进去活的 map，", "存下来是快照。"], "left")}
${`<rect x="${at(p, 330, GROUND - 90).x}" y="${at(p, 330, GROUND - 90).y}" width="70" height="24" rx="4" fill="#FEF3C7" stroke="${INK}" stroke-width="1.6"/>`}
${label(at(p, 365, GROUND - 73).x, at(p, 365, GROUND - 73).y, "快照", INK, 12)}
${caption(at(p, 24, 30).x, at(p, 24, 30).y, "snapshot-json-map：历史不是指针", 15)}`; })(),
    (() => { const p = P4; return `
${["hel", "lo"].map((t, i) => `<rect x="${at(p, 60 + i * 74, GROUND - 110).x}" y="${at(p, 60 + i * 74, GROUND - 110).y}" width="58" height="26" rx="5" fill="#EEF2FF" stroke="${INK}" stroke-width="1.6" transform="rotate(${i ? 8 : -6} ${at(p, 89 + i * 74, GROUND - 97).x} ${at(p, 89 + i * 74, GROUND - 97).y})"/><text x="${at(p, 89 + i * 74, GROUND - 91).x}" y="${at(p, 89 + i * 74, GROUND - 91).y}" font-size="14" text-anchor="middle" fill="${INK}">${t}</text>`).join("")}
<path d="M ${at(p, 70, GROUND - 70).x} ${at(p, 70, GROUND - 70).y} Q ${at(p, 150, GROUND - 40).x} ${at(p, 150, GROUND - 40).y} ${at(p, 230, GROUND - 66).x} ${at(p, 230, GROUND - 66).y}" stroke="${C_ZF}" stroke-width="2.4" fill="none" stroke-dasharray="5 4"/>
${label(at(p, 150, GROUND - 34).x, at(p, 150, GROUND - 34).y, "折叠", C_ZF)}
${figure(at(p, 330, GROUND).x, at(p, 330, GROUND).y, "clerk", "read", 0.95)}
${bubble(at(p, 240, 44).x, at(p, 240, 44).y, 190, ["最终那条消息", "说了算。"], "left")}
${caption(at(p, 24, 30).x, at(p, 24, 30).y, "誊本三规则", 15)}`; })(),
  ],
  footer: "日志是数据，视图是函数——誊本随时撕掉重算。",
});

// 05 ch04 安检通道
hf.push({
  file: "05-ch04-security-lane", title: "第 4 章 · 工具的安检通道",
  panels: [
    (() => { const p = P1; return `
${figure(at(p, 90, GROUND).x, at(p, 90, GROUND).y, "doorman", "block")}
${figure(at(p, 200, GROUND).x, at(p, 200, GROUND).y, "xiaoke", "carry")}
${bubble(at(p, 240, 44).x, at(p, 240, 44).y, 180, ["kind: 'deny —", "回家吧，飞机没动。"], "left")}
${label(at(p, 220, 120).x, at(p, 220, 120).y, "pre：查证件（可拒绝）", BLUE)}
${caption(at(p, 24, 30).x, at(p, 24, 30).y, "tools-pre-execute", 15)}`; })(),
    (() => { const p = P2; return `
${figure(at(p, 150, GROUND).x, at(p, 150, GROUND).y, "xiaoke", "walk")}
${`<path d="M ${at(p, 200, GROUND - 40).x} ${at(p, 200, GROUND - 40).y} l 14 -34 l 14 34 z" fill="${C_MF}" stroke="${INK}" stroke-width="2"/>`}
${[0, 1, 2].map(i => `<path d="M ${at(p, 236 + i * 16, GROUND - 44).x} ${at(p, 236 + i * 16, GROUND - 44).y} q 6 -12 0 -22" stroke="${C_MF}" stroke-width="2.4" fill="none"/>`).join("")}
${label(at(p, 220, 90).x, at(p, 220, 90).y, "execute：引擎唯一点火处", BLUE)}
${bubble(at(p, 40, 40).x, at(p, 40, 40).y, 170, ["spec/run/call"])}
${caption(at(p, 24, 30).x, at(p, 24, 30).y, "tools-execute", 15)}`; })(),
    (() => { const p = P3; return `
${counter(at(p, 70, GROUND - 50), 280, 50)}
${figure(at(p, 140, GROUND - 50).x, at(p, 140, GROUND - 50).y, "desk", "write", 0.9)}
${label(at(p, 300, GROUND - 70).x, at(p, 300, GROUND - 70).y, "rewritten", GREEN, 14)}
${figure(at(p, 110, GROUND).x, at(p, 110, GROUND).y, "xiaoke", "stand")}
${bubble(at(p, 220, 44).x, at(p, 220, 44).y, 200, ["海关：可以改标签，", "不可以偷跑。"], "down")}
${caption(at(p, 24, 30).x, at(p, 24, 30).y, "tools-post-execute", 15)}`; })(),
    (() => { const p = P4; return `
${speaker(at(p, 200, 120), 1.6)}
${label(at(p, 220, 70).x, at(p, 220, 70).y, "tools-result 广播", BLUE, 15)}
${figure(at(p, 80, GROUND).x, at(p, 80, GROUND).y, "xiaoke", "stand")}
${figure(at(p, 350, GROUND).x, at(p, 350, GROUND).y, "spine", "stand")}
${bubble(at(p, 130, 150).x, at(p, 130, 150).y, 220, ["没上飞机的行程也有广播。"], "down")}
${caption(at(p, 24, 30).x, at(p, 24, 30).y, "定格：观察者看见做完的 map", 15)}`; })(),
  ],
  footer: "拒绝用值不用异常；未知工具照样广播——没有一声不响的 none。",
});

// 06 ch05 审批柜台
hf.push({
  file: "06-ch05-approval-counter", title: "第 5 章 · 只问一次，缺席即拒绝",
  panels: [
    (() => { const p = P1; return `
${counter(at(p, 80, GROUND - 60), 260, 60)}
${stamp(at(p, 210, GROUND - 60), "仅此一次")}
${figure(at(p, 120, GROUND - 60).x, at(p, 120, GROUND - 60).y, "desk", "stand", 0.9)}
${bubble(at(p, 40, 60).x, at(p, 40, 60).y, 200, ["allowed-once？", "只管这一次调用。"], "down")}
${caption(at(p, 24, 30).x, at(p, 24, 30).y, "没有通行证仓库", 15)}`; })(),
    (() => { const p = P2; return `
${ledger(at(p, 80, GROUND - 110), 190, 80, true)}
${label(at(p, 100, GROUND - 92).x, at(p, 100, GROUND - 92).y, "approval-asked", C_ZF, 12, "start")}
${label(at(p, 100, GROUND - 60).x, at(p, 100, GROUND - 60).y, "approval-decided", C_ZF, 12, "start")}
${figure(at(p, 330, GROUND).x, at(p, 330, GROUND).y, "clerk", "write")}
${bubble(at(p, 150, 44).x, at(p, 150, 44).y, 210, ["问与答，两行都入账。"], "down")}
${caption(at(p, 24, 30).x, at(p, 24, 30).y, "进程死在中途也能对答案", 15)}`; })(),
    (() => { const p = P3; return `
${counter(at(p, 90, GROUND - 60), 240, 60)}
${label(at(p, 210, GROUND - 80).x, at(p, 210, GROUND - 80).y, "座位空着", GRAY, 14)}
${`<rect x="${at(p, 180, GROUND - 46).x}" y="${at(p, 180, GROUND - 46).y}" width="60" height="20" rx="4" fill="#FEE2E2" stroke="${C_MF}" stroke-width="1.8"/>`}
${label(at(p, 210, GROUND - 31).x, at(p, 210, GROUND - 31).y, "unavailable", C_MF, 11)}
${figure(at(p, 340, GROUND).x, at(p, 340, GROUND).y, "xiaoke", "shrug")}
${bubble(at(p, 60, 50).x, at(p, 60, 50).y, 200, ["没人应答 = 拒绝。", "不是默许。"], "down")}
${caption(at(p, 24, 30).x, at(p, 24, 30).y, "默认内层 'unavailable", 15)}`; })(),
    (() => { const p = P4; return `
${label(at(p, 220, 60).x, at(p, 220, 60).y, "合法结局只有四个", INK, 15)}
${["allowed-once", "rejected", "cancelled", "unavailable"].map((t, i) => `<rect x="${at(p, 60, 84 + i * 34).x}" y="${at(p, 60, 84 + i * 34).y}" width="170" height="24" rx="5" fill="#ECFDF5" stroke="${INK}" stroke-width="1.6"/><text x="${at(p, 145, 101 + i * 34).x}" y="${at(p, 145, 101 + i * 34).y}" font-size="13" text-anchor="middle" fill="${INK}" font-weight="600">${t}</text>`).join("")}
${figure(at(p, 350, GROUND).x, at(p, 350, GROUND).y, "spine", "point-l")}
${bubble(at(p, 40, 234).x, at(p, 40, 234).y, 190, ["拼错？塌缩成", "unavailable。"], "right")}
${caption(at(p, 24, 30).x, at(p, 24, 30).y, "策略 'ask / 'never 也住在账本里", 15)}`; })(),
  ],
  footer: "审批 = 一对入账的问答 + 一个塌缩规则。",
});

// 07 ch06 客人不当家
hf.push({
  file: "07-ch06-guest-not-master", title: "第 6 章 · 模型是客人，不当家",
  panels: [
    (() => { const p = P1; return `
${figure(at(p, 150, GROUND).x, at(p, 150, GROUND).y, "guest", "stand")}
${bubble(at(p, 220, 50).x, at(p, 220, 50).y, 200, ["我只说话：text 或", "tool-call。"], "left")}
${figure(at(p, 60, GROUND).x, at(p, 60, GROUND).y, "xiaoke", "point-r")}
${label(at(p, 150, GROUND + 16).x, at(p, 150, GROUND + 16).y, "手背在身后", C_GK)}
${caption(at(p, 24, 30).x, at(p, 24, 30).y, "回复只有两种形状", 15)}`; })(),
    (() => { const p = P2; return `
${["① enqueue 队列", "② script 脚本", "③ http 网络", "④ echo 兜底"].map((t, i) => `
<rect x="${at(p, 60, 66 + i * 44).x}" y="${at(p, 60, 66 + i * 44).y}" width="240" height="30" rx="6" fill="${i === 3 ? "#FEF3C7" : "#EEF2FF"}" stroke="${INK}" stroke-width="1.8"/>
${label(at(p, 180, 87 + i * 44).x, at(p, 180, 87 + i * 44).y, t, INK, 14)}`).join("")}
${figure(at(p, 360, GROUND).x, at(p, 360, GROUND).y, "spine", "point-l")}
${bubble(at(p, 285, 56).x, at(p, 285, 56).y, 128, ["按序敲门"], "left")}
${caption(at(p, 24, 30).x, at(p, 24, 30).y, "resolve-reply 的四级适配器", 15)}`; })(),
    (() => { const p = P3; return `
${door(at(p, 250, GROUND - 20), 46, 80)}
${figure(at(p, 300, GROUND).x, at(p, 300, GROUND).y, "doorman", "block")}
${figure(at(p, 170, GROUND).x, at(p, 170, GROUND).y, "guest", "point-r")}
${bubble(at(p, 60, 60).x, at(p, 60, 60).y, 200, ["客人不下场，", "不碰 tools/execute。"], "right")}
${caption(at(p, 24, 30).x, at(p, 24, 30).y, "tool-call 只是数据（点菜单）", 15)}`; })(),
    (() => { const p = P4; return `
${`<rect x="${at(p, 60, 90).x}" y="${at(p, 60, 90).y}" width="200" height="90" rx="8" fill="#FEF3C7" stroke="${INK}" stroke-width="2"/>`}
${["客人点菜：bash", "账房查房：有吗？", "没有 → unknown-tool"].map((t, i) => label(at(p, 80, 118 + i * 24).x, at(p, 80, 118 + i * 24).y, t, INK, 13, "start")).join("")}
${figure(at(p, 340, GROUND).x, at(p, 340, GROUND).y, "clerk", "read", 0.95)}
${bubble(at(p, 250, 50).x, at(p, 250, 50).y, 180, ["点不做得成，", "循环说了算。"], "left")}
${caption(at(p, 24, 30).x, at(p, 24, 30).y, "执行权永远在机器手里", 15)}`; })(),
  ],
  footer: "让适配器自己记账，等于让每个厂商抢笔当史官。",
});

// 08 ch07 账房先生的早晨
hf.push({
  file: "08-ch07-morning-reading", title: "第 7 章 · 账房先生的早晨",
  panels: [
    (() => { const p = P1; return `
${figure(at(p, 110, GROUND).x, at(p, 110, GROUND).y, "clerk", "read")}
${figure(at(p, 250, GROUND).x, at(p, 250, GROUND).y, "guest", "stand")}
${bubble(at(p, 160, 44).x, at(p, 160, 44).y, 220, ["每天早晨，把账本", "大声读给客人。"], "left")}
${caption(at(p, 24, 30).x, at(p, 24, 30).y, "derive-messages：每步重读", 15)}`; })(),
    (() => { const p = P2; return `
${figure(at(p, 100, GROUND).x, at(p, 100, GROUND).y, "clerk", "point-r")}
${bubble(at(p, 150, 50).x, at(p, 150, 50).y, 210, ["（对客人耳语 [prefix]）"], "left")}
${ledger(at(p, 220, GROUND - 100).x, at(p, 220, GROUND - 100).y, 140, 70, true)}
${label(at(p, 230, GROUND - 84).x, at(p, 230, GROUND - 84).y, "原话不动 ✓", GREEN, 12, "start")}
${figure(at(p, 385, GROUND).x, at(p, 385, GROUND).y, "guest", "stand")}
${caption(at(p, 24, 30).x, at(p, 24, 30).y, "pre-step 可以转述，账本不收伪话", 15)}`; })(),
    (() => { const p = P3; return `
${["followup · 下一回合叫醒", "steer · 下一步叫醒", "inject · 下一步不叫醒"].map((t, i) => `
<rect x="${at(p, 50, 66 + i * 46).x}" y="${at(p, 50, 66 + i * 46).y}" width="70" height="34" rx="4" fill="#FFFFFF" stroke="${INK}" stroke-width="1.8"/>
<line x1="${at(p, 85, 66 + i * 46).x}" y1="${at(p, 85, 66 + i * 46).y}" x2="${at(p, 85, 78 + i * 46).x}" y2="${at(p, 85, 78 + i * 46).y}" stroke="${INK}" stroke-width="1.6"/>
${label(at(p, 140, 88 + i * 46).x, at(p, 140, 88 + i * 46).y, t, INK, 13, "start")}`).join("")}
${figure(at(p, 360, GROUND).x, at(p, 360, GROUND).y, "xiaoke", "carry")}
${caption(at(p, 24, 30).x, at(p, 24, 30).y, "inbox 三种信：领取后才成 user-message", 15)}`; })(),
    (() => { const p = P4; return `
${`<rect x="${at(p, 50, 70).x}" y="${at(p, 50, 70).y}" width="300" height="110" rx="8" fill="#FFFFFF" stroke="${INK}" stroke-width="2"/>`}
${[["user", INK], ["assistant", INK], ["tool", GREEN], ["← resume 从这里接", GREEN]].map(([t, c], i) => label(at(p, 70, 100 + i * 24).x, at(p, 70, 100 + i * 24).y, String(t), c as string, 13, "start")).join("")}
${figure(at(p, 390, GROUND).x, at(p, 390, GROUND).y, "clerk", "stand", 0.95)}
${bubble(at(p, 190, 196).x, at(p, 190, 196).y, 175, ["不许捏造", "新访客。"], "right")}
${caption(at(p, 24, 30).x, at(p, 24, 30).y, "resume 契约：从历史接着走", 15)}`; })(),
  ],
  footer: "循环上没有 this.messages——只有每步都调 derive 的习惯。",
});

// 09 ch08 旅馆
hf.push({
  file: "09-ch08-hotel", title: "第 8 章 · 一人一间房",
  panels: [
    (() => { const p = P1; return `
${counter(at(p, 90, GROUND - 60), 260, 60, "#E0F2F1")}
${["sessions", "llm", "host"].map((t, i) => label(at(p, 130 + i * 90, GROUND - 36).x, at(p, 130 + i * 36 + GROUND - 36).y * 0 + at(p, 130 + i * 90, GROUND - 36).y, t, C_FG, 14)).join("")}
${label(at(p, 220, 66).x, at(p, 220, 66).y, "共享前台", C_FG, 15)}
${figure(at(p, 60, GROUND).x, at(p, 60, GROUND).y, "desk", "stand", 0.9)}
${caption(at(p, 24, 30).x, at(p, 24, 30).y, "记忆、客人、大门：全员共用", 15)}`; })(),
    (() => { const p = P2; return `
${[["A 房", 70], ["B 房", 250]].map(([t, x]) => `
<rect x="${at(p, Number(x), 90).x}" y="${at(p, Number(x), 90).y}" width="140" height="140" rx="8" fill="#FFFFFF" stroke="${INK}" stroke-width="2"/>
${label(at(p, Number(x) + 70, 114).x, at(p, Number(x) + 70, 114).y, String(t), INK, 15)}
${label(at(p, Number(x) + 70, 150).x, at(p, Number(x) + 70, 150).y, "tools 迷你吧", BLUE, 12)}
${label(at(p, Number(x) + 70, 174).x, at(p, Number(x) + 70, 174).y, "shell 烧水壶", BLUE, 12)}
${label(at(p, Number(x) + 70, 198).x, at(p, Number(x) + 70, 198).y, "loop 客房电话", BLUE, 12)}`).join("")}
${caption(at(p, 24, 30).x, at(p, 24, 30).y, "isolate：动手的东西各一份", 15)}`; })(),
    (() => { const p = P3; return `
<line x1="${at(p, 220, 70).x}" y1="${at(p, 220, 70).y}" x2="${at(p, 220, GROUND - 30).x}" y2="${at(p, 220, GROUND - 30).y}" stroke="${C_MF}" stroke-width="7" stroke-linecap="round"/>
${label(at(p, 130, 90).x, at(p, 130, 90).y, "A 广播", INK, 13)}
${label(at(p, 310, 90).x, at(p, 310, 90).y, "B 想偷听", INK, 13)}
${label(at(p, 320, 150).x, at(p, 320, 150).y, "scope 隔音墙", C_MF, 14)}
${figure(at(p, 100, GROUND).x, at(p, 100, GROUND).y, "xiaoke", "stand")}
${figure(at(p, 340, GROUND).x, at(p, 340, GROUND).y, "acu", "point-l")}
${caption(at(p, 24, 30).x, at(p, 24, 30).y, "scope-admits?：钥匙对不上就听不见", 15)}`; })(),
    (() => { const p = P4; return `
${door(at(p, 200, GROUND - 20), 46, 80, "#EEF2FF")}
${label(at(p, 223, 90).x, at(p, 223, 90).y, "连通房", INK, 12)}
${figure(at(p, 120, GROUND).x, at(p, 120, GROUND).y, "spine", "point-r")}
${bubble(at(p, 30, 60).x, at(p, 30, 60).y, 220, ["父钥匙听得见孩子，", "孩子能向上汇报。"], "right")}
${label(at(p, 223, GROUND + 14).x, at(p, 223, GROUND + 14).y, "特性，不是漏洞", GREEN, 13)}
${caption(at(p, 24, 30).x, at(p, 24, 30).y, "智能体 ≠ session：房间管动手，账本管记忆", 14)}`; })(),
  ],
  footer: "两间 isolate 对着同一个 s1 跑回合：一个 session，两张 tools 登记表。",
});

// 10 ch09 取消
hf.push({
  file: "10-ch09-cancel-checkpoint", title: "第 9 章 · 停下，但不撒谎",
  panels: [
    (() => { const p = P1; return `
<line x1="${at(p, 30, GROUND - 70).x}" y1="${at(p, 30, GROUND - 70).y}" x2="${at(p, 410, GROUND - 70).x}" y2="${at(p, 410, GROUND - 70).y}" stroke="${INK}" stroke-width="3"/>
${[0, 1, 2, 3, 4, 5, 6].map(i => flag(at(p, 50 + i * 56, GROUND - 70), GRAY, false)).join("")}
${flag(at(p, 162, GROUND - 70), RED, true)}
${figure(at(p, 134, GROUND).x, at(p, 134, GROUND).y, "xiaoke", "raise")}
${label(at(p, 230, GROUND - 100).x, at(p, 230, GROUND - 100).y, "7 个检查点", INK, 13)}
${caption(at(p, 24, 30).x, at(p, 24, 30).y, "在下个检查点举手，不是拔电源", 15)}`; })(),
    (() => { const p = P2; return `
${figure(at(p, 90, GROUND).x, at(p, 90, GROUND).y, "clerk", "write")}
${ledger(at(p, 180, GROUND - 104), 200, 74, true)}
${label(at(p, 200, GROUND - 86).x, at(p, 200, GROUND - 86).y, "tool-call ✓", INK, 12, "start")}
${label(at(p, 200, GROUND - 58).x, at(p, 200, GROUND - 58).y, "tool-result: \"cancelled\"", C_MF, 12, "start")}
${label(at(p, 200, GROUND - 40).x, at(p, 200, GROUND - 40).y, "assistant-message ✗ 无", GRAY, 12, "start")}
${caption(at(p, 24, 30).x, at(p, 24, 30).y, "本体返回被扔掉：不记没发生的成功", 15)}`; })(),
    (() => { const p = P3; return `
${label(at(p, 120, GROUND - 90).x, at(p, 120, GROUND - 90).y, "空闲站", GRAY, 14)}
${flag(at(p, 120, GROUND - 70), RED, true)}
${check(at(p, 170, GROUND - 95), false, 1.6)}
${figure(at(p, 280, GROUND).x, at(p, 280, GROUND).y, "xiaoke", "point-l")}
${bubble(at(p, 200, 60).x, at(p, 200, 60).y, 220, ["空闲取消是空操作：", "旗不许粘住。"], "left")}
${caption(at(p, 24, 30).x, at(p, 24, 30).y, "cancel-turn：live 才竖旗", 15)}`; })(),
    (() => { const p = P4; return `
${figure(at(p, 90, GROUND).x, at(p, 90, GROUND).y, "spine", "point-r")}
${bubble(at(p, 140, 60).x, at(p, 140, 60).y, 220, ["下一回合照常开工，", "没有鬼魂。"], "left")}
${ghost(at(p, 330, GROUND - 60), 1.4)}
${label(at(p, 330, GROUND - 10).x, at(p, 330, GROUND - 10).y, "账本里不许有这个", GRAY, 12)}
${caption(at(p, 24, 30).x, at(p, 24, 30).y, "disposed：一行事件都不写", 15)}`; })(),
  ],
  footer: "一面旗，三层检查，没有第二种取消。",
});

// 11 ch10 热替换
hf.push({
  file: "11-ch10-hot-swap", title: "第 10 章 · 换客人，不烧账本",
  panels: [
    (() => { const p = P1; return `
${["bundle", "profile", "home", "--patch"].map((t, i) => `
<rect x="${at(p, 110, GROUND - 50 - i * 36).x}" y="${at(p, 110, GROUND - 50 - i * 36).y}" width="200" height="30" rx="6" fill="${["#FDE68A", "#BBF7D0", "#BFDBFE", "#FBCFE8"][i]}" stroke="${INK}" stroke-width="1.8"/>
${label(at(p, 210, GROUND - 29 - i * 36).x, at(p, 210, GROUND - 29 - i * 36).y, t, INK, 13)}`).join("")}
${label(at(p, 210, 70).x, at(p, 210, 70).y, "叠层次序（先来先垫底）", INK, 13)}
${caption(at(p, 24, 30).x, at(p, 24, 30).y, "装配：bundle→profile→home→patch", 15)}`; })(),
    (() => { const p = P2; return `
<line x1="${at(p, 260, 60).x}" y1="${at(p, 260, 60).y}" x2="${at(p, 260, GROUND - 90).x}" y2="${at(p, 260, GROUND - 90).y}" stroke="${INK}" stroke-width="3"/>
<rect x="${at(p, 230, 54).x}" y="${at(p, 230, 54).y}" width="60" height="22" rx="4" fill="${C_JX}" stroke="${INK}" stroke-width="1.8"/>
<line x1="${at(p, 260, 76).x}" y1="${at(p, 260, 76).y}" x2="${at(p, 260, 120).x}" y2="${at(p, 260, 120).y}" stroke="${INK}" stroke-width="2"/>
<line x1="${at(p, 250, 120).x}" y1="${at(p, 250, 120).y}" x2="${at(p, 270, 120).x}" y2="${at(p, 270, 120).y}" stroke="${INK}" stroke-width="2"/>
${figure(at(p, 260, GROUND - 90).x, at(p, 260, GROUND - 90).y, "guest", "walk", 0.85)}
${figure(at(p, 90, GROUND).x, at(p, 90, GROUND).y, "spine", "point-r")}
${bubble(at(p, 20, 60).x, at(p, 20, 60).y, 200, ["吊走旧客人，", "吊进新客人。"], "right")}
${caption(at(p, 24, 30).x, at(p, 24, 30).y, "reload-plugin：卸旧挂新（可回滚）", 15)}`; })(),
    (() => { const p = P3; return `
${["① quiesce 先静默", "② swap 对换", "③ refresh 刷新 handle", "④ carry 搬运 inbox"].map((t, i) => label(at(p, 60, 80 + i * 38).x, at(p, 60, 80 + i * 38).y, t, INK, 14, "start")).join("")}
${figure(at(p, 350, GROUND).x, at(p, 350, GROUND).y, "clerk", "carry", 0.95)}
${bubble(at(p, 220, 56).x, at(p, 220, 56).y, 190, ["信件不丢，", "钥匙换新。"], "left")}
${caption(at(p, 24, 30).x, at(p, 24, 30).y, "缺文件？旧插件原位保留", 15)}`; })(),
    (() => { const p = P4; return `
${ledger(at(p, 70, GROUND - 110), 190, 80, true)}
${label(at(p, 90, GROUND - 90).x, at(p, 90, GROUND - 90).y, "turn1: hello cordis", INK, 12, "start")}
${label(at(p, 90, GROUND - 62).x, at(p, 90, GROUND - 62).y, "turn2: HELLO CORDIS", C_MF, 12, "start")}
${figure(at(p, 330, GROUND).x, at(p, 330, GROUND).y, "spine", "stand")}
${bubble(at(p, 200, 56).x, at(p, 200, 56).y, 210, ["客人换了，", "账本没烧。"], "down")}
${caption(at(p, 24, 30).x, at(p, 24, 30).y, "同一场 session，两代客人共处一账", 15)}`; })(),
  ],
  footer: "热替换五步：quiesce → reload → refresh → carry → 下一回合见新客。",
});

// =====================================================================
// 《从零构建 harness-spine》
// =====================================================================
const bs: ComicDef[] = [];

bs.push({
  file: "01-cover", title: "从零构建 harness-spine · 蓝图",
  panels: [
    (() => { const p = P1; return `
${`<rect x="${at(p, 70, 90).x}" y="${at(p, 70, 90).y}" width="120" height="90" rx="6" fill="#FFFFFF" stroke="${GRAY}" stroke-width="2" stroke-dasharray="6 5"/>`}
${label(at(p, 130, 140).x, at(p, 130, 140).y, "空文件夹", GRAY, 14)}
${figure(at(p, 280, GROUND).x, at(p, 280, GROUND).y, "xiaoke", "shrug")}
${bubble(at(p, 220, 60).x, at(p, 220, 60).y, 180, ["就从这里开始？"], "left")}
${caption(at(p, 24, 30).x, at(p, 24, 30).y, "Step 0", 15)}`; })(),
    (() => { const p = P2; return `
${figure(at(p, 90, GROUND).x, at(p, 90, GROUND).y, "spine", "point-r")}
${`<rect x="${at(p, 180, 80).x}" y="${at(p, 180, 80).y}" width="220" height="150" rx="6" fill="#EEF2FF" stroke="${C_JX}" stroke-width="2.2"/>`}
${["host", "session", "tools", "approval", "llm", "loop"].map((t, i) => `<rect x="${at(p, 196 + (i % 2) * 100, 96 + Math.floor(i / 2) * 42).x}" y="${at(p, 196 + (i % 2) * 100, 96 + Math.floor(i / 2) * 42).y}" width="86" height="28" rx="5" fill="#FFFFFF" stroke="${C_JX}" stroke-width="1.6"/><text x="${at(p, 239 + (i % 2) * 100, 115 + Math.floor(i / 2) * 42).x}" y="${at(p, 239 + (i % 2) * 100, 115 + Math.floor(i / 2) * 42).y}" font-size="13" text-anchor="middle" fill="${INK}">${t}</text>`).join("")}
${caption(at(p, 24, 30).x, at(p, 24, 30).y, "十一个零件的图纸", 15)}`; })(),
    (() => { const p = P3; return `
<line x1="${at(p, 20, GROUND - 60).x}" y1="${at(p, 20, GROUND - 60).y}" x2="${at(p, 420, GROUND - 60).x}" y2="${at(p, 420, GROUND - 60).y}" stroke="${INK}" stroke-width="3"/>
${["S1", "S2", "S3", "S4", "S5"].map((t, i) => `<circle cx="${at(p, 60 + i * 76, GROUND - 60).x}" cy="${at(p, 60 + i * 76, GROUND - 60).y}" r="16" fill="#FFFFFF" stroke="${INK}" stroke-width="2"/><text x="${at(p, 60 + i * 76, GROUND - 55).x}" y="${at(p, 60 + i * 76, GROUND - 55).y}" font-size="12" text-anchor="middle" fill="${INK}" font-weight="700">${t}</text>`).join("")}
${figure(at(p, 60, GROUND).x, at(p, 60, GROUND).y, "xiaoke", "walk")}
${label(at(p, 240, GROUND - 90).x, at(p, 240, GROUND - 90).y, "11 站装配线", INK, 13)}
${caption(at(p, 24, 30).x, at(p, 24, 30).y, "每站：设计压力 → 代码 → 实验", 15)}`; })(),
    (() => { const p = P4; return `
${figure(at(p, 110, GROUND).x, at(p, 110, GROUND).y, "clerk", "read")}
${figure(at(p, 250, GROUND).x, at(p, 250, GROUND).y, "xiaoke", "point-l")}
${bubble(at(p, 160, 50).x, at(p, 160, 50).y, 230, ["每台机器都从", "LAB-OK 开始。"], "left")}
${`<rect x="${at(p, 60, 160).x}" y="${at(p, 60, 160).y}" width="110" height="30" rx="6" fill="#ECFDF5" stroke="${GREEN}" stroke-width="2"/>`}
${label(at(p, 115, 181).x, at(p, 115, 181).y, "LAB-OK", GREEN, 15)}
${caption(at(p, 24, 30).x, at(p, 24, 30).y, "毕业标准：账本重新讲出一切", 15)}`; })(),
  ],
  footer: "Build harness-spine from scratch —— 11 步，一个诚实的机器",
});

bs.push({
  file: "02-step1-pipeline", title: "Step 1 · 会回声的机器",
  panels: [
    (() => { const p = P1; return `
<line x1="${at(p, 20, GROUND - 60).x}" y1="${at(p, 20, GROUND - 60).y}" x2="${at(p, 420, GROUND - 60).x}" y2="${at(p, 420, GROUND - 60).y}" stroke="${INK}" stroke-width="3"/>
${[0, 1, 2, 3, 4, 5].map(i => `<circle cx="${at(p, 55 + i * 66, GROUND - 60).x}" cy="${at(p, 55 + i * 66, GROUND - 60).y}" r="9" fill="#FFFFFF" stroke="${INK}" stroke-width="2"/>`).join("")}
${["turn-start", "user", "step-start", "chunks", "assistant", "turn-end"].map((t, i) => label(at(p, 55 + i * 66, GROUND - 34).x, at(p, 55 + i * 66, GROUND - 34).y, t, INK, 11)).join("")}
${caption(at(p, 24, 30).x, at(p, 24, 30).y, "先落边界，再谈智能", 15)}`; })(),
    (() => { const p = P2; return `
${figure(at(p, 100, GROUND).x, at(p, 100, GROUND).y, "xiaoke", "point-r")}
${bubble(at(p, 150, 60).x, at(p, 150, 60).y, 170, ["hello from", "spine"], "left")}
${`<rect x="${at(p, 290, GROUND - 110).x}" y="${at(p, 290, GROUND - 110).y}" width="90" height="70" rx="8" fill="#FEF3C7" stroke="${INK}" stroke-width="2"/>`}
${label(at(p, 335, GROUND - 66).x, at(p, 335, GROUND - 66).y, "echo", INK, 15)}
${label(at(p, 335, GROUND - 48).x, at(p, 335, GROUND - 48).y, "镜子", GRAY, 12)}
${caption(at(p, 24, 30).x, at(p, 24, 30).y, "客人是一面镜子，协议照样成立", 15)}`; })(),
    (() => { const p = P3; return `
${figure(at(p, 110, GROUND).x, at(p, 110, GROUND).y, "clerk", "write")}
${ledger(at(p, 210, GROUND - 104), 170, 74, true)}
${[1, 2, 3, 4, 5, 6, 7].map(i => label(at(p, 226, GROUND - 92 + i * 9).x, at(p, 226, GROUND - 92 + i * 9).y, `${i}`, INK, 10, "start")).join("")}
${bubble(at(p, 40, 50).x, at(p, 40, 50).y, 190, ["七行，一行不少。"], "down")}
${caption(at(p, 24, 30).x, at(p, 24, 30).y, "回合 = 有开有收的记账", 15)}`; })(),
    (() => { const p = P4; return `
${`<rect x="${at(p, 60, 110).x}" y="${at(p, 60, 110).y}" width="330" height="90" rx="8" fill="#F3F4F6" stroke="${INK}" stroke-width="1.8"/>`}
${["STATUS: text", "ASSISTANT: hello from spine", "LAB-OK"].map((l, i) => label(at(p, 80, 140 + i * 24).x, at(p, 80, 140 + i * 24).y, l, i === 2 ? GREEN : INK, 14, "start")).join("")}
${figure(at(p, 380, GROUND).x, at(p, 380, GROUND).y, "spine", "stand", 0.95)}
${caption(at(p, 24, 30).x, at(p, 24, 30).y, "你的第一台机器跑起来了", 15)}`; })(),
  ],
  footer: "真实版：how-harness-spine-works/ch01-echo-turn/code",
});

bs.push({
  file: "03-step2-append-only", title: "Step 2 · 只许追加的账本",
  panels: [
    (() => { const p = P1; return `
${["① 验明正身", "② 影印存档", "③ 编号追加", "④ 广播"].map((t, i) => label(at(p, 60, 84 + i * 40).x, at(p, 60, 84 + i * 40).y, t, C_ZF, 15, "start")).join("")}
${figure(at(p, 330, GROUND).x, at(p, 330, GROUND).y, "clerk", "write")}
${bubble(at(p, 190, 60).x, at(p, 190, 60).y, 200, ["纪律做进追加动作。"], "left")}
${caption(at(p, 24, 30).x, at(p, 24, 30).y, "append-event 四工序", 15)}`; })(),
    (() => { const p = P2; return `
${copier(at(p, 40, GROUND - 60))}
${figure(at(p, 220, GROUND).x, at(p, 220, GROUND).y, "xiaoke", "point-r")}
${bubble(at(p, 245, 50).x, at(p, 245, 50).y, 180, ["改原件？", "账本不跟。"], "left")}
${label(at(p, 83, GROUND + 16).x, at(p, 83, GROUND + 16).y, "FROZEN: before", GREEN, 13)}
${caption(at(p, 24, 30).x, at(p, 24, 30).y, "snapshot-json-map", 15)}`; })(),
    (() => { const p = P3; return `
${figure(at(p, 100, GROUND).x, at(p, 100, GROUND).y, "clerk", "block")}
${figure(at(p, 190, GROUND).x, at(p, 190, GROUND).y, "acu", "point-l")}
${bubble(at(p, 220, 56).x, at(p, 220, 56).y, 190, ["函数也塞进去？", "json-map? 不收。"], "left")}
${caption(at(p, 24, 30).x, at(p, 24, 30).y, "封闭词汇表：未知类型一律拒收", 15)}`; })(),
    (() => { const p = P4; return `
${ledger(at(p, 40, GROUND - 100), 150, 70, true)}
${label(at(p, 115, 158).x, at(p, 115, 158).y, "parent", INK, 12)}
${ledger(at(p, 250, GROUND - 100), 150, 70, true)}
${label(at(p, 325, 158).x, at(p, 325, 158).y, "child", INK, 12)}
<path d="M ${at(p, 190, GROUND - 70).x} ${at(p, 190, GROUND - 70).y} Q ${at(p, 220, GROUND - 40).x} ${at(p, 220, GROUND - 40).y} ${at(p, 250, GROUND - 70).x} ${at(p, 250, GROUND - 70).y}" stroke="${C_ZF}" stroke-width="2.4" fill="none" stroke-dasharray="5 4"/>
${label(at(p, 220, GROUND - 26).x, at(p, 220, GROUND - 26).y, "fork：另起一本，开头是影印件", C_ZF, 12)}
${caption(at(p, 24, 30).x, at(p, 24, 30).y, "forked-from 是字段不是事件", 15)}`; })(),
  ],
  footer: "持久化是配置（store-dir），不是藏起来的全局变量。",
});

bs.push({
  file: "04-step3-derive", title: "Step 3 · 誊本机器",
  panels: [
    (() => { const p = P1; return `
${["hel", "lo"].map((t, i) => `<rect x="${at(p, 70 + i * 80, GROUND - 110).x}" y="${at(p, 70 + i * 80, GROUND - 110).y}" width="60" height="28" rx="5" fill="#EEF2FF" stroke="${INK}" stroke-width="1.6"/><text x="${at(p, 100 + i * 80, GROUND - 90).x}" y="${at(p, 100 + i * 80, GROUND - 90).y}" font-size="14" text-anchor="middle" fill="${INK}">${t}</text>`).join("")}
<path d="M ${at(p, 80, GROUND - 66).x} ${at(p, 80, GROUND - 66).y} Q ${at(p, 160, GROUND - 34).x} ${at(p, 160, GROUND - 34).y} ${at(p, 240, GROUND - 62).x} ${at(p, 240, GROUND - 62).y}" stroke="${C_ZF}" stroke-width="2.4" fill="none" stroke-dasharray="5 4"/>
${label(at(p, 160, GROUND - 24).x, at(p, 160, GROUND - 24).y, "折叠进缓冲", C_ZF, 13)}
${caption(at(p, 24, 30).x, at(p, 24, 30).y, "chunk → 一条助手消息", 15)}`; })(),
    (() => { const p = P2; return `
${figure(at(p, 90, GROUND).x, at(p, 90, GROUND).y, "clerk", "point-r")}
${bubble(at(p, 140, 56).x, at(p, 140, 56).y, 220, ["final 来了，缓冲作废。"], "left")}
${label(at(p, 100, 150).x, at(p, 100, 150).y, "MESSAGE-WINS: hello-final", GREEN, 13, "start")}
${caption(at(p, 24, 30).x, at(p, 24, 30).y, "最终 assistant-message 说了算", 15)}`; })(),
    (() => { const p = P3; return `
${`<rect x="${at(p, 60, GROUND - 120).x}" y="${at(p, 60, GROUND - 120).y}" width="120" height="46" rx="8" fill="#F3F4F6" stroke="${GRAY}" stroke-width="2" stroke-dasharray="5 4"/>`}
${label(at(p, 120, GROUND - 92).x, at(p, 120, GROUND - 92).y, "簿记碎纸篓", GRAY, 13)}
${["turn-start", "step-end"].map((t, i) => `<rect x="${at(p, 80 + i * 44, GROUND - 116).x}" y="${at(p, 80 + i * 44, GROUND - 116).y}" width="38" height="16" rx="3" fill="#FFFFFF" stroke="${GRAY}" stroke-width="1.2" transform="rotate(${i ? 14 : -10} ${at(p, 99 + i * 44, GROUND - 108).x} ${at(p, 99 + i * 44, GROUND - 108).y})"/>`).join("")}
${figure(at(p, 300, GROUND).x, at(p, 300, GROUND).y, "clerk", "stand", 0.95)}
${bubble(at(p, 220, 70).x, at(p, 220, 70).y, 200, ["簿记不上桌。"], "left")}
${caption(at(p, 24, 30).x, at(p, 24, 30).y, "视图两行，日志七行", 15)}`; })(),
    (() => { const p = P4; return `
${`<rect x="${at(p, 50, GROUND - 120).x}" y="${at(p, 50, GROUND - 120).y}" width="130" height="80" rx="8" fill="#FEF2F2" stroke="${C_MF}" stroke-width="2"/>`}
${label(at(p, 115, GROUND - 90).x, at(p, 115, GROUND - 90).y, "缓存誊本？", C_MF, 14)}
${check(at(p, 115, GROUND - 60), false, 1.4)}
${figure(at(p, 300, GROUND).x, at(p, 300, GROUND).y, "spine", "point-l")}
${bubble(at(p, 190, 60).x, at(p, 190, 60).y, 220, ["缓存 = 过期工具表", "的根源。"], "left")}
${caption(at(p, 24, 30).x, at(p, 24, 30).y, "誊本随时撕掉重算", 15)}`; })(),
  ],
  footer: "日志是数据，视图是函数。",
});

bs.push({
  file: "05-step5-waterfall-relay", title: "Step 5 · 三棒接力",
  panels: [
    (() => { const p = P1; return `
${[["pre 查证件", "可拒绝", C_XK], ["execute 点火", "唯一副作用", GREEN], ["post 海关", "可改写", C_GK]].map(([t, d, c], i) => `
<rect x="${at(p, 40 + i * 130, 80).x}" y="${at(p, 40 + i * 130, 80).y}" width="110" height="56" rx="8" fill="#FFFFFF" stroke="${c}" stroke-width="2.4"/>
${label(at(p, 95 + i * 130, 102).x, at(p, 95 + i * 130, 102).y, String(t), c as string, 13)}
${label(at(p, 95 + i * 130, 122).x, at(p, 95 + i * 130, 122).y, String(d), GRAY, 11)}`).join("")}
${[0, 1].map(i => `<path d="M ${at(p, 152 + i * 130, 108).x} ${at(p, 152 + i * 130, 108).y} l 16 0 m -5 -5 l 5 5 l -5 5" stroke="${INK}" stroke-width="2.2" fill="none"/>`).join("")}
${figure(at(p, 220, GROUND).x, at(p, 220, GROUND).y, "xiaoke", "walk")}
${caption(at(p, 24, 30).x, at(p, 24, 30).y, "接力棒必须传下去（nw/call）", 15)}`; })(),
    (() => { const p = P2; return `
${[3, 2, 1].map((r, i) => `<circle cx="${at(p, 210, GROUND - 80).x}" cy="${at(p, 210, GROUND - 80).y}" r="${r * 26}" fill="none" stroke="${[C_GK, GREEN, BLUE][i]}" stroke-width="3"/>`).join("")}
${label(at(p, 210, GROUND - 76).x, at(p, 210, GROUND - 76).y, "本体", INK, 13)}
${label(at(p, 210, GROUND - 128).x, at(p, 210, GROUND - 128).y, "监听者可以包住每一层", INK, 13)}
${caption(at(p, 24, 30).x, at(p, 24, 30).y, "waterfall 洋葱：内层是默认动作", 15)}`; })(),
    (() => { const p = P3; return `
${figure(at(p, 100, GROUND).x, at(p, 100, GROUND).y, "doorman", "block")}
${figure(at(p, 200, GROUND).x, at(p, 200, GROUND).y, "acu", "point-l")}
${bubble(at(p, 225, 56).x, at(p, 225, 56).y, 200, ["kind: 'deny —", "计数器停在 0。"], "left")}
${label(at(p, 60, 150).x, at(p, 60, 150).y, "PRE-DENY: calls=0", BLUE, 13, "start")}
${caption(at(p, 24, 30).x, at(p, 24, 30).y, "拒绝在点火之前", 15)}`; })(),
    (() => { const p = P4; return `
${speaker(at(p, 180, 110), 1.5)}
${label(at(p, 200, 60).x, at(p, 200, 60).y, "tools-result", BLUE, 15)}
${["unknown-tool 也广播", "拒绝也广播", "改写也广播"].map((t, i) => label(at(p, 70, 160 + i * 30).x, at(p, 70, 160 + i * 30).y, `· ${t}`, INK, 13, "start")).join("")}
${figure(at(p, 370, GROUND).x, at(p, 370, GROUND).y, "clerk", "read", 0.9)}
${caption(at(p, 24, 30).x, at(p, 24, 30).y, "定格广播：没有一声不响的 none", 15)}`; })(),
  ],
  footer: "工具是有证人的公共行为；特权在结构里，不在名单上。",
});

bs.push({
  file: "06-step9-keys-rooms", title: "Step 9 · 房间与钥匙",
  panels: [
    (() => { const p = P1; return `
${figure(at(p, 90, GROUND).x, at(p, 90, GROUND).y, "spine", "point-r")}
${bubble(at(p, 140, 60).x, at(p, 140, 60).y, 220, ["mint-scope-key：", "铸一把不透明钥匙。"], "left")}
${`<circle cx="${at(p, 330, GROUND - 60).x}" cy="${at(p, 330, GROUND - 60).y}" r="16" fill="none" stroke="${INK}" stroke-width="2.6"/>`}
${["A", "B"].map((t, i) => `<rect x="${at(p, 344, GROUND - 96 + i * 26).x}" y="${at(p, 344, GROUND - 96 + i * 26).y}" width="34" height="18" rx="3" fill="${[C_XK, C_AC][i]}" stroke="${INK}" stroke-width="1.4"/><text x="${at(p, 361, GROUND - 83 + i * 26).x}" y="${at(p, 361, GROUND - 83 + i * 26).y}" font-size="11" text-anchor="middle" fill="${INK}">${t}</text>`).join("")}
${caption(at(p, 24, 30).x, at(p, 24, 30).y, "钥匙只能持有，不能解析", 15)}`; })(),
    (() => { const p = P2; return `
${["", ""].map((_, i) => `
<rect x="${at(p, 50 + i * 190, 80).x}" y="${at(p, 50 + i * 190, 80).y}" width="170" height="120" rx="8" fill="#FFFFFF" stroke="${INK}" stroke-width="2"/>
${label(at(p, 135 + i * 190, 102).x, at(p, 135 + i * 190, 102).y, `agent-${i ? "B" : "A"} isolate`, INK, 13)}
${["tools", "shell", "agent-loop"].map((t, j) => label(at(p, 135 + i * 190, 128 + j * 22).x, at(p, 135 + i * 190, 128 + j * 22).y, `· ${t}`, BLUE, 12)).join("")}`).join("")}
${caption(at(p, 24, 30).x, at(p, 24, 30).y, "extend-agent-iso：三件套各一份", 15)}`; })(),
    (() => { const p = P3; return `
${counter(at(p, 90, GROUND - 60), 260, 60, "#E0F2F1")}
${["session", "llm", "host"].map((t, i) => label(at(p, 130 + i * 92, GROUND - 36).x, at(p, 130 + i * 92, GROUND - 36).y, t, C_FG, 13)).join("")}
${label(at(p, 220, 70).x, at(p, 220, 70).y, "根上共享（reflect 走父链）", C_FG, 13)}
${figure(at(p, 60, GROUND).x, at(p, 60, GROUND).y, "desk", "stand", 0.9)}
${caption(at(p, 24, 30).x, at(p, 24, 30).y, "同一个 reflect，两种归属", 15)}`; })(),
    (() => { const p = P4; return `
<line x1="${at(p, 220, 80).x}" y1="${at(p, 220, 80).y}" x2="${at(p, 220, GROUND - 40).x}" y2="${at(p, 220, GROUND - 40).y}" stroke="${C_MF}" stroke-width="7" stroke-linecap="round"/>
${label(at(p, 130, 100).x, at(p, 130, 100).y, "A 的广播", INK, 13)}
${label(at(p, 310, 100).x, at(p, 310, 100).y, "B：听不见", GRAY, 13)}
${label(at(p, 320, 150).x, at(p, 320, 150).y, "scope-admits? 沿父链核对", C_MF, 13)}
${figure(at(p, 90, GROUND).x, at(p, 90, GROUND).y, "xiaoke", "stand")}
${figure(at(p, 350, GROUND).x, at(p, 350, GROUND).y, "spine", "point-l")}
${caption(at(p, 24, 30).x, at(p, 24, 30).y, "父钥匙听连通房——向上汇报是特性", 14)}`; })(),
  ],
  footer: "SHARED-MSGS: 4 —— 说话人换了，账本不换。",
});

bs.push({
  file: "07-step10-cancel-track", title: "Step 10 · 停机协议",
  panels: [
    (() => { const p = P1; return `
<line x1="${at(p, 30, GROUND - 70).x}" y1="${at(p, 30, GROUND - 70).y}" x2="${at(p, 410, GROUND - 70).x}" y2="${at(p, 410, GROUND - 70).y}" stroke="${INK}" stroke-width="3"/>
${[0, 1, 2, 3, 4, 5, 6].map(i => flag(at(p, 50 + i * 56, GROUND - 70), GRAY, false)).join("")}
${flag(at(p, 218, GROUND - 70), RED, true)}
${figure(at(p, 206, GROUND).x, at(p, 206, GROUND).y, "xiaoke", "raise")}
${["循环×2", "tools settle", "host 流"].map((t, i) => label(at(p, 90 + i * 130, GROUND - 100).x, at(p, 90 + i * 130, GROUND - 100).y, t, INK, 12)).join("")}
${caption(at(p, 24, 30).x, at(p, 24, 30).y, "一面旗，三层检查", 15)}`; })(),
    (() => { const p = P2; return `
${figure(at(p, 90, GROUND).x, at(p, 90, GROUND).y, "clerk", "write")}
${ledger(at(p, 180, GROUND - 104), 210, 74, true)}
${label(at(p, 200, GROUND - 86).x, at(p, 200, GROUND - 86).y, "tool-result text \"cancelled\"", C_MF, 12, "start")}
${label(at(p, 200, GROUND - 58).x, at(p, 200, GROUND - 58).y, "cancelled: true", C_MF, 12, "start")}
${bubble(at(p, 220, 56).x, at(p, 220, 56).y, 200, ["没做完就写没做完。"], "down")}
${caption(at(p, 24, 30).x, at(p, 24, 30).y, "cancelled-tool-result", 15)}`; })(),
    (() => { const p = P3; return `
${label(at(p, 110, GROUND - 90).x, at(p, 110, GROUND - 90).y, "空闲站", GRAY, 14)}
${flag(at(p, 110, GROUND - 70), RED, true)}
${check(at(p, 160, GROUND - 95), false, 1.6)}
${figure(at(p, 270, GROUND).x, at(p, 270, GROUND).y, "xiaoke", "point-l")}
${bubble(at(p, 190, 60).x, at(p, 190, 60).y, 220, ["空闲竖旗？返回 none。"], "left")}
${caption(at(p, 24, 30).x, at(p, 24, 30).y, "IDLE-CANCEL: _ — 旗不许粘住", 15)}`; })(),
    (() => { const p = P4; return `
${door(at(p, 200, GROUND - 20), 50, 84, "#FEE2E2")}
${label(at(p, 225, 100).x, at(p, 225, 100).y, "disposed", C_MF, 14)}
${figure(at(p, 120, GROUND).x, at(p, 120, GROUND).y, "doorman", "block")}
${figure(at(p, 330, GROUND).x, at(p, 330, GROUND).y, "spine", "point-l")}
${bubble(at(p, 30, 36).x, at(p, 30, 36).y, 190, ["steps 0，", "一行事件不写。"], "right")}
${caption(at(p, 24, 30).x, at(p, 24, 30).y, "拒绝假装开工", 15)}`; })(),
  ],
  footer: "取消不是异常：是检查点举手 + 一行 cancelled。",
});

bs.push({
  file: "08-step11-layers-swap", title: "Step 11 · 叠层与热替换",
  panels: [
    (() => { const p = P1; return `
${["bundle", "profile", "home", "--patch"].map((t, i) => `
<rect x="${at(p, 110, GROUND - 50 - i * 36).x}" y="${at(p, 110, GROUND - 50 - i * 36).y}" width="200" height="30" rx="6" fill="${["#FDE68A", "#BBF7D0", "#BFDBFE", "#FBCFE8"][i]}" stroke="${INK}" stroke-width="1.8"/>
${label(at(p, 210, GROUND - 29 - i * 36).x, at(p, 210, GROUND - 29 - i * 36).y, t, INK, 13)}`).join("")}
${figure(at(p, 380, GROUND).x, at(p, 380, GROUND).y, "spine", "point-l")}
${caption(at(p, 24, 30).x, at(p, 24, 30).y, "--dump-config 是验钞机", 15)}`; })(),
    (() => { const p = P2; return `
${["host", "session", "approval", "llm", "agents"].map((t, i) => `<rect x="${at(p, 60, 74 + i * 34).x}" y="${at(p, 60, 74 + i * 34).y}" width="150" height="26" rx="5" fill="#EEF2FF" stroke="${INK}" stroke-width="1.6"/><text x="${at(p, 135, 92 + i * 34).x}" y="${at(p, 135, 92 + i * 34).y}" font-size="12.5" text-anchor="middle" fill="${INK}">${t}</text>`).join("")}
${label(at(p, 300, 90).x, at(p, 300, 90).y, "没有 tools！", C_MF, 14)}
${label(at(p, 300, 114).x, at(p, 300, 114).y, "它是房间私产", INK, 12)}
${figure(at(p, 370, GROUND).x, at(p, 370, GROUND).y, "xiaoke", "shrug")}
${caption(at(p, 24, 30).x, at(p, 24, 30).y, "cordis.yml = boot-spine 的逐条等价", 14)}`; })(),
    (() => { const p = P3; return `
${["① quiesce 静默", "② reload 对换", "③ refresh 钥匙", "④ carry 搬信"].map((t, i) => label(at(p, 56, 80 + i * 38).x, at(p, 56, 80 + i * 38).y, t, INK, 14, "start")).join("")}
${figure(at(p, 350, GROUND).x, at(p, 350, GROUND).y, "clerk", "carry", 0.95)}
${bubble(at(p, 210, 56).x, at(p, 210, 56).y, 200, ["失败？旧插件原位。"], "left")}
${caption(at(p, 24, 30).x, at(p, 24, 30).y, "缺文件不会装到一半", 15)}`; })(),
    (() => { const p = P4; return `
${ledger(at(p, 70, GROUND - 110), 190, 80, true)}
${label(at(p, 90, GROUND - 90).x, at(p, 90, GROUND - 90).y, "hello cordis", INK, 12, "start")}
${label(at(p, 90, GROUND - 62).x, at(p, 90, GROUND - 62).y, "HELLO CORDIS", C_MF, 12, "start")}
${figure(at(p, 330, GROUND).x, at(p, 330, GROUND).y, "spine", "stand")}
${bubble(at(p, 200, 56).x, at(p, 200, 56).y, 210, ["STILL ALIVE —", "回滚成功。"], "down")}
${caption(at(p, 24, 30).x, at(p, 24, 30).y, "同像热替换：客人换，账本留", 15)}`; })(),
  ],
  footer: "reload-spine-plugin 五步 —— 任何攥过对换的缓存必错。",
});

// ---------- 输出 ----------
import { existsSync, mkdirSync } from "node:fs";
for (const dir of [OUT_HF, OUT_BS]) if (!existsSync(dir)) mkdirSync(dir, { recursive: true });
for (const d of hf) await Bun.write(`${OUT_HF}/${d.file}.svg`, page(d.title, d.panels, d.footer));
for (const d of bs) await Bun.write(`${OUT_BS}/${d.file}.svg`, page(d.title, d.panels, d.footer));
console.log(`HF: ${hf.length} 张, Build: ${bs.length} 张 已生成`);
