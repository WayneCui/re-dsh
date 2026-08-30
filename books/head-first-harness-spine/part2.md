<!-- 书稿文件之二（第 04–07 章） -->

# 第 4 章 工具不是函数调用，是带证人的公共行为

![漫画：小壳提着行李走进机场安检通道——查证件（pre）、引擎点火（execute）、海关开箱（post）、大喇叭广播（tools-result），阿粗想从后门溜进去被拦下](comics/05-ch04-security-lane.png)

工具看起来最无害：有名字、有参数、有结果，`do registry[name](args)` 一行完事。阿粗的函数表就是这么长的。可 «第一次 «就这一回» 的 `if name = 'bash [check ...]`» 迟早长成第二套解释器——因为函数调用是**私下的**：没有时机让策略在函数存在之前说不，没有事件让旁观者围观，没有槽位让测试替身站进去。

harness-spine 把工具当成**一次有证人在场的公共行为**：`tools/execute` 先造一份 `exec` map（`name`、`args`），然后让这份材料**依次穿过三条 waterfall**，最后广播 `tools-result`。

## 安检通道四段式

| 阶段 | 机场比喻 | 默认内层做的事 | 监听者能干什么 |
|------|----------|----------------|----------------|
| `tools-pre-execute` | 查证件 | 返回 `#[kind: 'allow]` | 交回 `kind: 'deny`——本体碰都不碰，实验里计数器停在 0 |
| `tools-execute` | 引擎点火 | 调 `spec/run/call`（**唯一点火的地方**） | 包住内层（重试、计时），或再次拒绝 |
| `tools-post-execute` | 海关开箱 | 原样递出结果 | 改写输出（实验里文本被换成 `"rewritten"`）——涂黑可以，偷跑不行 |
| `emit tools-result` | 大喇叭广播 | 往 `result-log` 追加并广播 | 只能旁听，本体已经定格 |

关键设计只有一句：**副作用只发生在 `tools-execute` 的内层里（或因为本体调了 host 而发生在 host 里）**。pre 不干活，post 不干活，广播之后没有撤回。

> **你以为**：工具 = 函数，跑没跑只有调用方知道。
> **其实**：工具 = 公共行为，跑没跑、跑出什么，广播里见。连「根本没离开柜台的行程」（被 pre 拒掉的）都有一条 `tools-result`。

## bash 也是普通旅客

`shell-plugin` 登记了一份名叫 `'bash` 的规格，它的 `call` 就是转手调 `host/run-command`。循环要跑工具时，调的是 `tools/execute/meta`，**从不认识 bash，也从不认识 host**。所以「bash 有什么特权」这个问题不存在——特权在结构里，不在名单上。

## 没有笨问题

**问：为什么拒绝要用「值」（`kind: 'deny`）而不是抛异常？**

答：拒绝是一个**需要入账的结果**，不是程序故障。抛异常的语义是「世界出错了」，而 deny 的语义是「世界正常，但这次不行」。值可以被记录、被广播、被测试；异常只会把栈拆了。

**问：监听者忘了调内层 `nw/call` 会怎样？**

答：整条流水线停在他手上——内层被吞，本体不跑。这是 waterfall 的纪律成本：接力棒必须传下去。

## 动一动

```bash
cd ../../how-harness-spine-works/ch04-tools-waterfall/code
bash run.sh
```

对答案：`PRE-DENY: pre-denied calls=0`（拒绝在点火之前）、`POST-REWRITE: rewritten calls=1`（工具真跑了、文本被换掉）、`BASH-STDOUT: through-host`（bash 走的是 host 门）。「试一试」第 2 条让你亲手复现 exec-stage deny。

## 脑力充电站

1. pre 监听者返回 `kind: 'deny` 后，`spec/run/call` 会跑吗？`tools-result` 会广播吗？
2. post 阶段把结果改写掉，算不算「干了私活」？

<details><summary>答案</summary>

1. 不跑；广播。**没有一声不响的拒绝**——这正是「带证人」的含义。
2. 改写输出是 post 的职责（涂黑/脱敏），但改写发生在广播**之前**、由广播见证。偷跑的定义是「绕过广播干活」，而不是「在镜头前改写」。
</details>

## 速记卡

- 三条 waterfall：pre（拒绝闸）→ execute（唯一点火）→ post（改写窗），随后 `tools-result` 定格广播。
- 未知工具 → `#[ok false error "unknown-tool"]`，照样广播。
- 一次「hello world」四个名字——这是**可审计的代价**，不是啰嗦病。

---

# 第 5 章 只问一次，缺席即拒绝

![漫画：审批柜台上「仅此一次」的印章砸下，问题和答案两行同时誊进账本；旁边空无一人的座位挂牌「无人应答 = 拒绝」，墙上的通行证仓库是空的](comics/06-ch05-approval-counter.png)

工具能拒绝（第 4 章），不等于有人说了「允许」。审批要回答的是：**谁来点头，点头的证据放哪。**

## 这道接缝的纪律

`approval/request` 只在**打开的回合内**工作（有 `turn-start` 还没有 `turn-end`，否则直接报错——漂在两个回合之间的许可没人有义务尊重）。它做四件事：

1. 造一个 id（`a<随机数>`）；
2. 账本记一行 `approval-asked`——**问题入账**；
3. 把问题送进 `approval-request` waterfall。默认内层返回 `'unavailable`——**没有内置界面**，没人应答本身就是一条被记下的结局；
4. 不管结局是什么，账本再记一行 `approval-decided`——**答案入账**。

结局只有四个合法值：`allowed-once`、`rejected`、`cancelled`、`unavailable`。**其它一切——包括界面钩子上的一个拼写错误——一律塌缩成 `'unavailable`**。缺省即拒绝（fail-closed），拼写错误不配变成通行证。

> **你以为**：审批 = 一个布尔开关。
> **其实**：审批 = 一对入账的问答 + 一个塌缩规则。布尔值会在这段代码里默认 true、在另一个代码库里默认 false，两边都不留痕迹；账本两边都写，谁也别想装傻。

## 「仅此一次」的准确含义

`'allowed-once` 管的是**这一次调用**，不是「这件工具本周随便用」。没有通行证仓库（grant store）这种东西——想跨调用记住「用户点过一次头」，那是你自己的监听者该造的轮子，而且它也必须写下可以回放的东西。

策略同样住在账本里：`set-policy` 记一行 `approval-policy`（`'ask` 或 `'never`），`effective-approval-policy` 倒着扫事件找最近一行。**同一个 session 可以先宽松后收紧**，回放时转变发生在哪一刻一目了然。

## 没有笨问题

**问：为什么「回合外请求审批」要直接抛错？这么严酷吗？**

答：想象一行审批记录漂在两个回合之间——机器握着一个人的决定，却没有任何 driver 有义务尊重它。「缺席即拒绝」也包括「现在不行」。

**问：那我的产品要弹确认框，在哪弹？**

答：脊柱不管 UI。你把一个监听者挂到 `approval-request` waterfall 上，返回 `'allowed-once` 或 `'rejected`。命令行提示、聊天按钮、CI 里永远拒绝——都行。脊柱只保证：**问和答都上了账，而且问不出去不等于默许。**

## 动一动

```bash
cd ../../how-harness-spine-works/ch05-approval-once/code
bash run.sh
```

对答案：`NEVER: rejected`（策略不问人）、`NO-ANSWERER: unavailable`（缺席即拒绝）、`TOOL-DENIED: #(false)` / `TOOL-GRANTED: allowed-body`（同一工具，两种命运）。「试一试」让你给回答者喂一个字符串 `"sure"`，看它怎么被塌缩成 `unavailable`。

## 脑力充电站

产品在提问中途死机。重启后，你能从日志回答「用户到底答没答过」吗？

<details><summary>答案</summary>

能，而且答案很干净：只有 `approval-asked` 没有 `approval-decided` = 问题问出去了、答案没回来。布尔方案此刻只能两眼一抹黑——这正是「两边都写」存在的理由。
</details>

## 速记卡

- 流程：`approval-asked` → waterfall → `approval-decided`，两次入账。
- 四个结局，其余全塌缩为 `'unavailable`；默认策略 `'ask`，策略也入账。
- 没有通行证仓库；`allowed-once` 只管一次。

---

# 第 6 章 模型是客人，不当家

![漫画：长围巾客人坐在窗边高谈阔论，手上却戴着白手套什么也碰不了；门口的传声筒依次写着 enqueue/script/http/echo，脊先生在旁边核对账本](comics/07-ch06-guest-not-master.png)

到这里机器能记住、能动手了。最后的诱惑是让模型当家：SDK 递进消息、递出 JSON，`tool_calls` 一解析就直接跑——「套壳」就是这样变成远程代码解释器的。厂商超时、schema 漂移、流重试，你的 session 成了「上一份 HTTP 正文碰巧长成的样子」。

harness-spine 把关系倒了过来：**循环向 `llm` 服务要一份回复，回复是一份很小的 map**——`#[kind: 'text text: ...]` 或 `#[kind: 'tool-call name: ... args: ...]`。就这样。没有第三种形状。

## 客人的四扇传声筒

`resolve-reply` 按顺序敲门：

1. **`enqueue` 队列**——测试脚本投递的回复，永远最优先；
2. **外部脚本**——`llm/script.reb` 把请求 `mold` 进临时文件，调 `r3 -q` 跑你的脚本，解析 stdout；
3. **HTTP**——`llm/http.reb` 经 host 发 post（流式则走行协议：`#[delta "..."]` 一行行吐）;
4. **echo 兜底**——把最后一条用户内容原样读回。

客人不许做的事只有两件：**自己另挑一个 session**，或者**自己去调 `tools/execute`**。一份 `tool-call` 回复只是数据——名字存不存在、要不要审批、取消提没提，都由循环决定。

> **你以为**：适配器 = 发 HTTP 的一小段代码。
> **其实**：适配器 = 客人的嘴。它只负责说话（文本或 tool-call 数据），记账、执行、审批、取消全部归机器。让适配器自己追加事件，等于让每个厂商都变成互相抢笔的史官。

## 没有笨问题

**问：为什么 `enqueue` 要排在最前面？真模型来不了吗？**

答：队列是**脚本化适配器**——测试和教学用它固定客人要说的话。次序固定意味着：同一个实验，今天跑和明年跑结果一致。真模型走 script 或 http 那两扇门。

**问：流式适配器想「把 token 直接丢给界面」为什么这么麻烦？**

答：因为 chunk 的记账归循环。适配器要么填好 `chunks`，要么按行协议说话；界面挂在 sink 上收货。多一道手续，换来的是**界面永远看到和账本一致的东西**。

## 动一动

```bash
cd ../../how-harness-spine-works/ch06-llm-guest/code
bash run.sh
```

对答案：`ECHO: hello guest`（四扇门全空时的兜底）、`ENQUEUED: from-queue`（队列插队）、`TURN-TYPES` 里两条 `assistant-chunk`（流式入账）。「试一试」第 2 条最损也最妙：chunk 说 `"hel" "lo"`、`text` 却说 `"mismatch"`——看机器怎么诚实地把两份都记下来。

## 脑力充电站

一份 `kind: 'tool-call` 回复提议了 `'bash`，但当前智能体的房间里根本没登记 bash。谁负责发现？日志里会出现什么？

<details><summary>答案</summary>

循环（`tools/execute` 里查 `registry`）。日志里先出现提议的 `tool-call`，随后是一条 `#[ok false error "unknown-tool"]` 的 `tool-result`——客人可以乱点菜，账本记录「点了、没做成」，一切有据可查。
</details>

## 速记卡

- 回复形状只有两种：`text` / `tool-call`。
- 敲门次序：queue → script → http → echo。
- 客人不下场：不挑 session、不执行工具、不碰 host。

---

# 第 7 章 账房先生的早晨：每一步都重读账本

![漫画：清晨，账房先生立在账本前朗读，客人围巾飘着听写；窗台上摆着三封信（followup/steer/inject），墙上挂着「resume 不许捏造访客」的木牌](comics/08-ch07-morning-reading.png)

现在把镜头对准控制流。最省事的想象里，一个回合 = 一个可变的对话对象 + while 循环：追加、调用、再追加。那个活数组*就是*状态——第 3 章它在存储上失败过，本章它作为**控制流**再败一次：中途取消时数组里有没结果的 tool-call；想恢复时分不清该不该再塞一行用户记录；插件想改模型输入就得改界面正在打印的同一个数组。

`run-turn-core` 的答案是：**循环不持有对话，循环每一步都重读账本。**

## 回合的心跳

```text
标记 live-session-id → turn-start → 领取 inbox → (可选拟用户文本)
→ 每一步: 取消检查? → max-steps? → step-start
   → derive-messages（重读账本）
   → agent-pre-step waterfall（可改写可拒绝）
   → agent-request waterfall（可换供应商）
   → llm/stream → tool-call/tool-result 或 assistant-message
   → step-end
→ turn-end（status: text / max-steps / rejected / cancelled）
```

三个细节值得盯住：

- **`derive-messages` 每步都调**。模型看到的输入永远是账本的**最新誊本**——工具结果一入账，下一步模型就「听见」了，不需要谁去手动同步。
- **pre-step 可以对客人耳语**。实验里监听者给用户内容加前缀 `"[prefix] "`，echo 于是一句带前缀的话——誊本被改了，**账本上的原始用户行纹丝不动**。账房先生可以对客人转述，笔记本不收伪造的人话。
- **inbox（`followup` / `steer` / `inject`）也是账**。信件被领取后才落成 `user-message` 行——走和人打字一模一样的路，模型没有第二条输入通道。

> **你以为**：resume = 「接着上次的话茬，再骗一次模型说用户说话了」。
> **其实**：resume 只允许两种入场券——誊本以 `tool` 或 `assistant` 收尾；或 inbox 里有 `followup`/`steer` 叫醒循环。**不许捏造一位新访客。**

## 没有笨问题

**问：为什么光秃一条 user-message 不能 resume？**

答：`can-admit-turn?` 不把「已经有一行用户记录」当成该去叫模型的理由——那行可能是还没跑完的 turn、手工塞进账本的种子，或取消留下的半截。放行只认两种入场券：誊本以 `tool`/`assistant` 收尾，或 inbox 里有 `followup`/`steer`。`test/session-fork-test.reb` 锁住了这条边：孤零 `user` → `no-input`；先跑完一轮再 resume → 不捏造第二行用户。

**问：重读的代价呢？长会话会不会越来越慢？**

答：会，这是实打实的 CPU。但对照方案——缓存上次誊本——正是取消或 fork 之后「工具表悄悄过期」的根源。花 CPU 买正确性，这笔账在 agent 场景下永远划算。另外有一道闸：`max-steps`（默认 8），一个只会回 tool-call 的客人不许永远跑下去。

## 动一动

```bash
cd ../../how-harness-spine-works/ch07-the-turn/code
bash run.sh
```

对答案：`TOOL-ROLES: [user assistant tool assistant]`（工具结果入了誊本）、`RESUME-ROLES: [user assistant assistant]`（resume 没捏造第二行用户）、`RESUME-USER-ROWS: 1`。「试一试」第 3 条让你塞九次 tool-call，看 `max-steps` 闸门落下。

## 脑力充电站

一次 tool-call 步骤之后，下一轮模型输入里的工具结果从哪来——循环上的某个变量，还是账本？

<details><summary>答案</summary>

账本。`tool-result` 入账后，下一步 `derive-messages` 重算誊本时自然包含它。循环上没有 `this.messages` 字段——这就是「没有缓存」的准确含义。
</details>

## 速记卡

- 循环 = 账房先生：每步重读、可以转述（pre-step）、不许伪造（resume 契约）。
- inbox 三种信：followup（下一回合叫醒）、steer（下一步叫醒）、inject（下一步不叫醒）。
- 状态机：`text` / `max-steps` / `rejected` / `cancelled` / `no-input` / `disposed`。
