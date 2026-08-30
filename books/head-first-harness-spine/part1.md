<!-- 书稿文件之一（头部 + 第 01–03 章），与 part2/part3 合并为 HEAD_FIRST_HARNESS_SPINE.md -->

# Head First harness-spine

**用漫画、谜题和一台诚实的机器，重新学会「智能体」**

> 姊妹篇：[写给所有人的 Harness](../../harness-for-everyone/HARNESS_FOR_EVERYONE.md)（概念版）、[harness-spine 是怎样工作的](../../how-harness-spine-works/HOW_HARNESS_SPINE_WORKS.md)（源码版）、[从零构建 harness-spine](../build-harness-spine-from-scratch/BUILD_HARNESS_SPINE_FROM_SCRATCH.md)（动手版）。

---

## 怎么用这本书

这不是一本「读完就算」的书。Head First 的老规矩：**我们希望你一边笑，一边把概念焊进脑子里**。所以每一章你都会遇到：

- **一幅漫画**——把抽象机制画成一台你看得见的机器；
- **没有笨问题**——你刚想说「等等，那……」的时候，我们就替你问了；
- **动一动**——每一个概念都连着一个**真的能跑**的实验（用真实仓库里的教学切片，跑完会打印 `LAB-OK`）；
- **脑力充电站**——几道小题，答案就翻在下面，但请先自己想十秒；
- **速记卡**——合上书之前扫一眼的那张卡。

这条学习路线的押注是：**智能体不是「围着厂商 SDK 写个循环」**。它是一台小机器——能说话、能动手、能记住、能被叫停，而且这四件事都经得起追问。十 章 结束时，你会亲手跑过这台机器的每一个零件。

先跑一下环境检查（需要 `PATH` 上有 `r3`，即 Rebol 3）：

```bash
cd ../../how-harness-spine-works
./verify-all.sh
# expect: 10/10 OK
```

看到 10/10，就翻页。

---

# 第 1 章 你以为你在写智能体，其实你在写循环

![漫画：阿粗的套壳在凌晨三点露馅，小壳看着冒烟的消息数组发问，脊先生递来一张「机器」蓝图](comics/02-ch01-wrapper-breaks.png)

**深夜的hackathon现场。** 阿粗拍着胸脯：「智能体？十分钟！」——`messages.append(user)`、`llm(messages)`、工具一跑、结果一塞、循环再来一遍。台下掌声雷动。

凌晨三点，产品经理发来三个问题，阿粗的套壳当场露馅：

1. 「刚才那次调用，模型**到底**看到了什么？」
2. 「能让它**停下来**吗？别撒谎的那种停。」
3. 「第二个智能体能不能不跟第一个**共用工具箱**？」

循环早就把证据扔了。它没有协议，只有 `Ctrl-C`。两个智能体一上场，工具表就撞车。

> **你以为**：智能体 = 模型 + 循环。
> **其实**：循环只是传动皮带。真正的机器是——一扇门（副作用）、一本账（记忆）、一道审批缝（许可）、一位客人（模型）、一位重读账本的账房先生（控制流）。SDK 循环五样缺四样。

## 机器的四条底线

harness-spine 是一个很小的 Rebol 运行时，它把上面三个问题当成**产品本身**来回答。它的赌注可以背下来：

> **智能体是一台能说话、能动手、能记住、能被叫停的机器——而且这四件事，都经得起从日志里查账。**

「经得起查账」是关键词。不是「看起来能」，是「日志里每一行都对得上」。模型在这台机器里是**客人**：可以发言，不当家；不带记忆，不碰 I/O。

### 先看一眼这台机器的全身图

```text
cordis-port 内核（ctx, plugin, waterfall, isolate）
  -> host            唯一的 I/O 门
  -> session         只许追加的日志；聊天是一种视图
  -> tools           pre / execute / post + tools-result
       -> shell      bash 是一份登记过的规格，不是循环的原语
  -> approval        一次性，缺席即拒绝，两边都写进日志
  -> llm             客人：enqueue / script / http / echo
  -> agent-loop      一个重读日志的回合
  -> scope + agent   私用的动手房间，共享的前台
  -> boot / yaml / reload
```

别慌，每一根柱子后面都有一章。你现在只需要记住三件事：**门只有一扇、账只增不改、客人不下场动手。**

## 没有笨问题

**问：我用的框架（LangChain / 某Agent SDK）很好啊，为什么要自虐？**

答：不冲突。那些框架管的是「怎么把活干得更顺」，harness-spine 管的是「怎么让每个动作都对得上账」。前者是家具新品目录，后者是承重墙。本书的全部实验都跑在真实源码上——你随时可以打开每一个 `api.reb` 对照。

**问：Rebol？这语言我连听都没听过。**

答：这正是选它的原因——它小到你可以**读完**。全书只要求你认得几种形状：`map!`（花括号字典 `#[key: value]`）、`block!`（方括号列表 `[a b c]`）、word（`'bash` 这种带引号的名字）。跟着漫画走，你不会迷路。

## 动一动：让机器说第一句话

```bash
cd ../../how-harness-spine-works/ch01-echo-turn/code
bash run.sh
```

预期看到（关键行）：

```text
STATUS: text
ASSISTANT: hello from spine
--- event types ---
[turn-start user-message step-start assistant-chunk assistant-message step-end turn-end]
LAB-OK
```

注意 `ASSISTANT: hello from spine`——**没有一个真的模型在场**。默认适配器是 echo：它只是把你的话原样读回来。而这恰恰是重点：连「假模型」都能把一个回合走完整，说明协议本身站得住。

## 脑力充电站

1. 阿粗的套壳里，`messages` 数组同时扮演了哪两个角色？
2. 「取消 = Ctrl-C」违背了四条底线中的哪几条？
3. echo 适配器证明了什么、没证明什么？

<details><summary>答案</summary>

1. 记忆 + 模型输入。所以工具一多、流式一来，两份历史必然对不上账。
2. 至少两条：能被叫停（没有协议，只有杀进程）＋ 经得起查账（session 里留下没写完的鬼魂）。
3. 证明了**回合协议**不依赖厂商；没证明真实模型的适配器——那是第 6 章的事。
</details>

## 速记卡

- 套壳的死因：记忆与输入同源、副作用无门、取消无协议、工具表共用。
- harness-spine 五大件：host（门）/ session（账）/ tools（证人）/ approval（许可）/ llm（客人），外加 agent-loop（账房先生）。
- 一切实验以 `LAB-OK` 收尾；`./verify-all.sh` 应为 10/10。

---

# 第 2 章 一条「hello」的奇幻漂流

![漫画：小壳发出的「hello」变成包裹，沿流水线经过账本登记、视图誊写、客人窗口，变成 chunk 又合体](comics/03-ch02-turn-anatomy.png)

你敲下 `hello from spine`，回车。这条字符串接下来去哪了？本章跟着它走完全程——**这是全书最重要的一章**，后面九章都在给这条流水线加岗哨。

## 流水线六站

`driver/run-turn` 一开口，机器就开始记账：

1. **`turn-start`**——回合开幕，账本上先落一行（空载荷，纯簿记）。
2. **`user-message`**——你的话原文入账。从此它是**历史**，不是变量。
3. **誊一份视图**——`derive-messages` 从账本现场算出「模型可见的聊天记录」。注意：是**算**出来的，不是存着的。
4. **问客人**——`llm/stream` 收到视图，吐出若干截文本；每截都记一行 `assistant-chunk`。
5. **合体**——流结束后，一条最终的 `assistant-message` 入账，chunk 碎片在视图里被折叠。
6. **`turn-end`**——带着 `status`、`steps`、`text` 三样收工。

**日志里落了七行，模型看到的视图却只有两行**（一条 user、一条 assistant）。这个差值不是浪费——它就是「账本 vs 誊本」的第一次现身。

> **你以为**：聊天记录就是历史。
> **其实**：聊天记录是**视图**，历史是**日志**。视图随时可以扔掉重算；日志一行都不许改。

## echo 的宣言

默认适配器 `resolve-reply` 的查找顺序是：队列 `enqueue` → 外部脚本 → HTTP → **echo 兜底**（把 `last-user-content` 原样读回）。所以第一回合里，「模型」其实是一面镜子。

这不是偷懒，是**实验设计**：如果协议必须靠真模型才能跑通，那协议就把自己卖给了厂商。echo 在说：**没有客人，这台机器照样把一个回合走完整。**

## 没有笨问题

**问：为什么每个 chunk 都要单独记账？合并成一条不行吗？**

答：流式回复中途取消、重试、崩溃时，**chunk 是唯一诚实的证据**。合并发生在视图层（誊本上），原始事实留在日志层（账本上）。誊本可以错，账本不会。

**问：`derive-messages` 每一步都重算，不浪费吗？**

答：浪费一点 CPU，买到的是「缓存永远不可能过期」。第 7 章你会看到，多少「诡异的工具表漂移」都是缓存惹的祸。

## 动一动：给流水线加戏

```bash
cd ../../how-harness-spine-works/ch01-echo-turn/code
bash run.sh   # 先看基线
```

然后打开 `demo.reb`：

1. 把用户字符串改成 `"ping"`——助手应当原样回声（`last-user-content` 的功劳）。
2. 在 `run-turn` 之前 `enqueue` 一条 `text: "not-an-echo"` 的回复——队列排在 echo 前面，输出会变。
3. 打印 `length? spine/sessions/events-of s/id` 和 `length? spine/sessions/derive-messages s/id`——亲眼看 7 对 2 的落差。

## 脑力充电站

1. `turn-start` 的载荷是空的，为什么还要记？
2. 如果流式中途崩溃，日志里会留下什么？视图里会留下什么？

<details><summary>答案</summary>

1. 簿记也是事实。「这个回合什么时候开始」本身就是审计问题。
2. 日志：若干 `assistant-chunk`，一条不少；视图：残余 chunk 拼成一条半截的助手消息。下次重算视图，机器（和人）都能看见「上次说到一半」。
</details>

## 速记卡

- 回合流水线：`turn-start → user-message → derive → llm/stream → assistant-chunk×n → assistant-message → turn-end`。
- 日志 7 行、视图 2 行——差额 = 簿记 + chunk + 折叠规则。
- echo 兜底 = 协议独立于厂商的宣言。

---

# 第 3 章 记忆是账本，聊天是誊本

![漫画：账房先生把装订账本大声读给围巾客人听，碎纸片（chunk）在他手里被折成一张完整页](comics/04-ch03-ledger-and-transcript.png)

第 2 章末尾那个「7 对 2」，本章掰开揉碎。

## 一本只许追加的账本

脊柱的记忆是**事件日志**：每次 `append-event` 都是一条带编号的记录。三道工序，缺一不可：

1. **验明正身**——`validate-payload` 拒绝未知事件类型、拒绝载荷不合规矩（比如 `text` 不是字符串）。历史不容错别字。
2. **影印存档**——`snapshot-json-map` 把载荷深拷贝快照。你递给它一张**活的** map，转手改了 `text`，账本上仍是改之前的值——历史不是插在你堆里的指针。
3. **编号追加**——赋上连续的 `index`，追加，广播 `session-event`。只增不改，是这本账的全部纪律。

最省事的替代方案是 OpenAI 式数组：`[{role: user, content: ...}, ...]`，整个数组每回合塞给模型。可助手回答一旦流式拆碎，这套设计就垮了：chunk 算一条消息吗？缓冲到一半崩了丢谁的？——**数组把「存储格式」和「传输格式」焊死在一起**，账本不犯这个错。

## 誊本的三条规则

`derive-messages` 把账本走一遍，产出模型可见的聊天：

- `user-message` / `assistant-message` → 直接誊；
- 连续的 `assistant-chunk` → 先折进缓冲，一旦后面跟着 `assistant-message`，**最终那条说了算**，缓冲作废；
- `tool-call` → 誊成带 `kind: 'tool-call` 的助手行，`tool-result` → 誊成 `role: 'tool` 行；回合簿记（`turn-start`、`step-end`、审批事件）一概不上誊本。

> **你以为**：誊本就是账本的摘要，少几行而已。
> **其实**：誊本是**函数**，账本是**数据**。函数永远可以重跑，数据永远只有一个真相。

## 开分支：另起一本账

`fork` 把前缀拷进一个新 session id，两本账从此各写各的。没有「共享数组 + 写时复制标志」这种等着你去搞错的机关。持久化同理：设了 `store-dir`，每次追加都把整本账的 `mold/all` 落盘成 `<id>.events.reb`；重启后 `open` 校验重载——**持久化是配置项，不是藏起来的全局变量**。

## 没有笨问题

**问：为什么不存 JSON？**

答：`json-map?` 连函数、循环引用对象都不收——它们没法安全重放。Rebol block 直接 `mold/all` / `do` 往返，格式和语言同源，没有第二套序列化器要维护。

**问：诚实的代价是什么？**

答：啰嗦。一次 echo 回合七行事件。但审计从来不怕行数多，只怕行数不可信。

## 动一动

```bash
cd ../../how-harness-spine-works/ch03-session-log/code
bash run.sh
```

看四件事：`FROZEN: before`（快照生效）、`FOLDED: hello`（chunk 折叠）、`MESSAGE-WINS: hello-final`（最终消息说了算）、`REOPENED: persist me | ok`（重启后账本完整）。「试一试」里还有一个坏主意验证：注释掉 `assistant-message` 那行，看誊本怎么表现。

## 脑力充电站

两条 `assistant-chunk`（`"hel"`、`"lo"`）之后又来一条 `assistant-message`（`"hello-final"`）。誊本里助手有几行？内容是什么？

<details><summary>答案</summary>

一行，内容 `"hello-final"`。chunk 缓冲被最终消息清掉。若 `assistant-message` 没来，则同样一行，内容 `"hello"`——缓冲兜底，一截都不丢。
</details>

## 速记卡

- `append-event` = 验类型 + 快照 + 编号 + 广播。
- 誊本规则：chunk 折叠、最终消息优先、簿记不上桌。
- fork = 另起一本账；持久化 = 配置，不是全局变量。
