# AI 重生成提示词（baoyu-comic · ohmsha 预设 / manga + neutral）

> 用途：当生图 API 可用时（如 `OPENROUTER_API_KEY` + `google/gemini-3.1-flash-image-preview`），用 baoyu-imagine 逐条生成，替换各书 `comics/` 下同名文件（SVG→PNG 时同步更新书中引用后缀）。
> 建议参数：`--ar 4:3 --quality 2k`；如已生成角色表 `characters/characters.png`，每次带 `--ref`。
> 通用前缀（每条提示词开头都要带）：

```
EDUCATIONAL MANGA PAGE (Japanese manga style, clean ink lines, flat colors, white panel gutters).
Layout: 2x2 four panels with a bold title bar at top and a one-line footer caption.
CAST (keep consistent): XIAOKE = young engineer, orange hoodie, round glasses, bob hair;
SPINE-SENSEI = calm architect mentor, gray-blue vest, flat black hair, small beard, rolled blueprint;
A-CU = hasty hacker, green T-shirt, spiky hair, stocky;
CLERK = anthropomorphized agent-loop, dark-indigo robe, round black cap, thin mustache, always holding a bound paper ledger;
GUEST = anthropomorphized LLM, long purple scarf, long black hair, hands always behind back;
DOORMAN = red uniform cap, blocking gesture.
NO talking heads: characters must DO things inside visual metaphors. All speech bubbles in SIMPLIFIED CHINESE, short (≤10 chars per line).
```

---

## Head First harness-spine

**01-cover** — A grand "machine hotel" cutaway. DOORMAN blocks beside the only red door labeled 「host 门」; CLERK at the front desk reading a bound ledger labeled 「session 账本」; GUEST by a window; XIAOKE asks 「就是这台机器？」 and SPINE-SENSEI answers 「十根柱子，十章。」; a corridor shows two rooms labeled 「agent-A 房 / agent-B 房」. Footer: 「能说话 · 能动手 · 能记住 · 能被叫停」.

**02-ch01-wrapper-breaks** — P1: A-CU proudly shows pseudocode `messages.append(user); reply = llm(messages)` on a whiteboard, shouting 「智能体？十分钟！」. P2: 3AM, three giant question bubbles crash onto panicked A-CU: 「刚才到底做了什么？」「能停下来吗？」「工具能分开吗？」. P3: XIAOKE asks 「循环不够用吗？」; SPINE-SENSEI shrugs: 「循环只是皮带。」. P4: SPINE-SENSEI unveils a glowing blueprint of five labeled blocks 门 host / 账 session / 闸 tools / 许可 approval / 客人 llm with CLERK below labeled 账房先生.

**03-ch02-turn-anatomy** — P1: a parcel labeled "hello" rides a conveyor through six checkpoint gates labeled turn-start / user-message / 誊视图 / llm/stream / chunk×n / turn-end. P2: CLERK shows a ledger with 7 numbered rows: 「簿记也要入账。」. P3: CLERK reads aloud a 2-line transcript to GUEST: 「誊本：user 一行，assistant 一行。」. P4: XIAOKE compares 「日志 7 行 ≠ 视图 2 行」 with bullets chunk 折叠 / 簿记不上桌 / 最终消息说了算.

**04-ch03-ledger-and-transcript** — P1: CLERK runs each record through four mini-stations labeled ① 验明正身 ② 影印存档 ③ 编号追加 ④ 广播. P2: A-CU tries to erase a ledger row; CLERK blocks him: 「账本只增不改。」. P3: XIAOKE feeds a live map into a photocopier labeled snapshot-json-map; the copy stays "before" while the original changes to "after". P4: paper scraps "hel" "lo" fold into one page in CLERK's hands: 「最终那条消息说了算。」

**05-ch04-security-lane** — Airport security lane metaphor. P1: DOORMAN checks documents labeled tools-pre-execute, stamps 「kind: 'deny — 回家吧，飞机没动。」. P2: XIAOKE passes the only ignition gate tools-execute with a small engine flame `spec/run/call`. P3: customs desk tools-post-execute relabels a bag 「rewritten」; bubble: 「可以改标签，不可以偷跑。」. P4: a loudspeaker broadcasts `tools-result` to listeners; caption 「没上飞机的行程也有广播」.

**06-ch05-approval-counter** — P1: approval counter with a big red stamp 「仅此一次」 over a form; bubble 「allowed-once？只管这一次调用。」. P2: CLERK writes TWO rows into a ledger: approval-asked and approval-decided. P3: an empty answerer seat with a hanging sign 「unavailable」; XIAOKE shrugs: 「没人应答 = 拒绝，不是默许。」. P4: four legal outcome slots allowed-once / rejected / cancelled / unavailable; a misspelled ticket gets crushed into 「unavailable」.

**07-ch06-guest-not-master** — P1: GUEST talks elegantly, hands behind back: 「我只说话：text 或 tool-call。」. P2: four doors in a row labeled ① enqueue ② script ③ http ④ echo; SPINE-SENSEI: 「按序敲门」. P3: GUEST reaches toward a tool room; DOORMAN blocks: 「客人不下场。」. P4: GUEST's tool-call becomes a paper menu handed to CLERK who checks the registry: 「点不做得成，循环说了算。」

**08-ch07-morning-reading** — P1: every morning CLERK reads the bound ledger aloud to GUEST (derive-messages). P2: CLERK whispers "[prefix]" into GUEST's ear while the ledger's original row stays untouched (✓). P3: three envelopes on a windowsill labeled followup / steer / inject; XIAOKE carries an inbox tray. P4: a transcript ending [user, assistant, tool] with a wooden sign 「resume 不许捏造新访客」.

**09-ch08-hotel** — P1: shared front desk with three windows sessions / llm / host. P2: two private rooms A/B, each with its own minibar (tools), kettle (shell), phone (agent-loop). P3: B tries to eavesdrop on A's broadcast; a red sound-proof wall labeled 「scope 隔音墙」 blocks it. P4: a suite's parent key hears through a connecting door; SPINE-SENSEI: 「父钥匙听得见孩子——特性，不是漏洞。」

**10-ch09-cancel-checkpoint** — P1: a running track with 7 checkpoint flags; XIAOKE raises a hand at one. P2: CLERK writes a row `tool-result: "cancelled"` while the assistant-message row stays empty. P3: at the IDLE station a sticky red flag is crossed out with a big ✗: 「空闲取消是空操作，旗不许粘住。」. P4: SPINE-SENSEI: 「下一回合照常开工」; a dashed ghost outside the ledger with a prohibition sign.

**11-ch10-hot-swap** — P1: a four-layer cake labeled bundle / profile / home / --patch. P2: a crane lowers a NEW guest (wearing an UPPERCASE glove) into a room while the front desk ledger stays under a glass dome. P3: checklist ① quiesce 静默 ② swap 对换 ③ refresh 刷新 handle ④ carry 搬运 inbox; CLERK carries an inbox tray. P4: the ledger shows turn1 "hello cordis" and turn2 "HELLO CORDIS" coexisting: 「客人换了，账本没烧。」

---

## 从零构建 harness-spine

**01-cover** — Triptych: an empty folder labeled 「空文件夹」; SPINE-SENSEI's blueprint with six blocks host/session/tools/approval/llm/loop; an 11-station assembly line S1…S5…; XIAOKE stamps a green 「LAB-OK」 badge.

**02-step1-pipeline** — P1: minimal conveyor turn-start→user→step-start→chunks→assistant→turn-end. P2: XIAOKE sends "hello from spine" to a mirror booth labeled echo 镜子; it reflects the same string. P3: CLERK's ledger with exactly 7 numbered rows. P4: terminal card: `STATUS: text / ASSISTANT: hello from spine / LAB-OK`.

**03-step2-append-only** — P1: four-stage stamping line ① 验明正身 ② 影印存档 ③ 编号追加 ④ 广播. P2: a photocopier; the original map changes "before"→"after" but the filed copy stays "before"; label FROZEN: before. P3: A-CU tries to stuff a function into the ledger; CLERK blocks: 「json-map? 不收。」. P4: two ledgers parent/child, the child's first page a photocopy of the parent's, dashed arrow labeled fork：另起一本.

**04-step3-derive** — P1: scraps "hel" "lo" fold into one page (折叠进缓冲). P2: a final page "hello-final" arrives; the scrap buffer is discarded (MESSAGE-WINS). P3: bookkeeping slips (turn-start, step-end) fall into a wastebasket labeled 簿记不上桌. P4: a cache box labeled 缓存誊本？ gets a big red ✗; SPINE-SENSEI: 「缓存 = 过期工具表的根源。」

**05-step5-waterfall-relay** — P1: three relay runners: pre 查证件（可拒绝）→ execute 点火（唯一副作用）→ post 海关（可改写）. P2: an onion diagram with the body 本体 at the center and listener wrappers around it. P3: DOORMAN denies A-CU at pre; counter shows PRE-DENY: calls=0. P4: loudspeaker broadcasts tools-result; bullets: unknown-tool 也广播 / 拒绝也广播 / 改写也广播.

**06-step9-keys-rooms** — P1: SPINE-SENSEI mints opaque keys on a keyring labeled mint-scope-key. P2: two room boards agent-A isolate / agent-B isolate each listing tools / shell / agent-loop. P3: shared front desk windows session / llm/host labeled 根上共享. P4: red wall between A and B labeled scope-admits? 沿父链核对; B cannot hear A; a connecting door lets the parent key listen.

**07-step10-cancel-track** — P1: track with 7 checkpoint flags labeled 循环×2 / tools settle / host 流; XIAOKE raises a hand. P2: CLERK writes `tool-result text "cancelled" / cancelled: true`. P3: at the IDLE station a sticky flag crossed out: IDLE-CANCEL: _. P4: a red door labeled disposed stays shut; SPINE-SENSEI: 「steps 0，一行事件不写。」

**08-step11-layers-swap** — P1: four-layer patch cake bundle/profile/home/--patch with a verifier receipt --dump-config. P2: YAML list host/session/approval/llm/agents with a red note 「没有 tools！它是房间私产」. P3: four-step elevator ① quiesce ② reload ③ refresh ④ carry; CLERK carries the inbox; bubble 「失败？旧插件原位。」. P4: ledger shows hello cordis then HELLO CORDIS; terminal card STILL ALIVE — 回滚成功.
