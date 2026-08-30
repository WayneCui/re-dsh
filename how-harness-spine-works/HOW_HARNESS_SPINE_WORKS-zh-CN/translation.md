<!-- source: HOW_HARNESS_SPINE_WORKS.md -->

# harness-spine 是怎样工作的

大多数智能体套壳，说白了就是围着厂商 SDK 写个循环。平时够用，可一旦你问出 SDK 答不上来的问题，它就露馅了：我们到底做了什么？能不能停下来、还不撒谎？两个智能体能不能各干各的活，又不共用同一个工具箱？harness-spine 是一套很小的 Rebol 运行时，它偏要把这些问题本身当成产品。它站在 Cordis 移植版的内核之上——插件、waterfall（**分层接力的钩子链**）、isolate（隔离）、thenable（**可等待的延期值**）——然后拒绝让模型拥有记忆、I/O 或工具。

这本书顺着一条依赖脊柱往下讲：从一次 echo 回合（`turn`），一直走到装配和热替换。我们不从 YAML 文件或命令行开关起笔——那些只是决定房间怎么摆。真正有意思的机器，在几次 `registry/plugin` 之后，已经在 `boot-spine` 里转着了：一扇 `host`（通往真实世界的门），一本只许追加的 `session`（会话日志），一条 tools 的 waterfall，一道一次性的审批接缝，一位 LLM 客人，以及每一步都把日志重读一遍的循环。isolate 的房间和取消随后才到——房客不止一个、或某个房客必须停下时，机器靠它们保持诚实。

先跑这两条命令：

```bash
cd ch01-echo-turn/code && bash run.sh
./verify-all.sh
```

源码：[`../`](../)（**Rebol 3**）。实验直接对着那棵源码树 `do %boot.reb`，并不是另起一份 fork。`run.sh` 总会把工作目录设到 harness-spine 根上，因为 `boot.reb` 靠相对路径加载 `../cordis-port` 和同级模块。`PATH` 里没有 `r3` 的话，`verify-all.sh` 会跳过。

**约定：** 读的时候不要改原仓库。每章末尾的「对照真源」指向真实路径。教学切片放在 `chNN-*/code/` 下，跑完会打印 `LAB-OK`。

不带实验、只讲概念的姊妹篇是[写给所有人的 Harness](../harness-for-everyone/README.md)。这条脊柱所挂的内核，在 [Cordis 的 Rebol 移植是怎样工作的](../../cordis-port/how-cordis-port-works/README.md) 里解释。

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

用户输入的字符串进入 `driver/run-turn`。循环先写下 `turn-start` 和一条 `user-message`，导出给模型看的视图，再去问 `llm/stream`，然后写下若干 chunk，外加一条最终的助手消息——或者一次 tool-call；而在 `tools/execute` 跑完 waterfall、host（如果是 bash）真正产生副作用之前，那次调用只是一份数据。审批可以挂在那条 waterfall 上。取消是一面旗子，在上述这些接缝处都会被检查；检查到了，就写一条 `cancelled` 的 tool-result，免得日志里留下鬼魂。两个智能体 isolate 各自的 tools 和 loop，却可以共享 session。热替换会换掉一根插件 Fiber（**一次存活的租约**）、刷新 handle（句柄），让下一回合用的是新客人、旧账本。

---

## 目录

- [第 01 章 你发出「hello」，实际发生了什么？](./ch01-echo-turn/chapter.md)
- [第 02 章 为什么每一种副作用都必须经过同一扇门？](./ch02-host-door/chapter.md)
- [第 03 章 记忆为什么是日志，而不是聊天？](./ch03-session-log/chapter.md)
- [第 04 章 工具为什么不是一次函数调用？](./ch04-tools-waterfall/chapter.md)
- [第 05 章 为什么只问一次、缺席即拒绝，并且两边都写下来？](./ch05-approval-once/chapter.md)
- [第 06 章 为什么模型不当家？](./ch06-llm-guest/chapter.md)
- [第 07 章 为什么每一步都要把日志重读一遍？](./ch07-the-turn/chapter.md)
- [第 08 章 为什么每个智能体都要有自己的房间？](./ch08-isolate-rooms/chapter.md)
- [第 09 章 为什么停下是一份协议，而不是一次异常？](./ch09-cancel-protocol/chapter.md)
- [第 10 章 为什么要装配和热替换，而不是一次写死？](./ch10-assemble-reload/chapter.md)

---

## 怎么读

如果你只想看清这个仓库押的是哪一注，读第 01、03、07 章。那是一个回合、日志与视图的分裂，以及那位拒绝把聊天缓存下来的账房先生。如果你在排查一个「跑了两次」或者「根本没跑」的工具，先读 04 再读 05。两个智能体互相踩了脚，从 08 开始。一次取消留下了写到一半的 session，从 09 开始。第 10 章写给已经相信房间存在的读者，他们要的是 YAML、profile，以及 `reload-spine-plugin`。

内核那本书第一遍可以不读。等到某天，waterfall 监听器里的 `nw/call` 在你眼里像一句咒语，或者热替换看起来「没生效」——其实只是某一代 Fiber 重建了你还攥在手里的服务对象——那时候再去读它。

---

## 验证

```bash
./verify-all.sh
# expect: 10/10 OK
```

需要 `PATH` 上有 `r3`（Rebol 3）。速查表在 [appendix/quick-reference.md](./appendix/quick-reference.md)。**不要**从那里读起——那些一行总结，是各章一点点挣出来的。

<!-- source: ch01-echo-turn/chapter.md -->

# 第 01 章 你发出「hello」，实际发生了什么？

最短、也最诚实的智能体，看起来就是一个围着模型转的循环：你送一串字进去，模型回答；答案里要是点了某个工具的名，你就跑它，再把结果送回去。周末攒出来的原型，能把这个循环做得像模像样。但它没有完工。等你第一次想知道*刚才到底发生了什么*——不是界面上现在显示什么——循环早就把证据扔了。等你第一次想让它停下来，没有什么协议，只有一个被杀掉的进程。等你第一次让两个智能体共用一场聊天，它们的工具表就撞车了。

harness-spine 赌的是另一条路：智能体是一台小机器，能说话、能动手、能记住、也能被叫停，而且这四件事都能从一本日志里重新拼出来。模型是这台机器的客人，不是主人。这一章不打算证明每一层，只做一件事：把整条脊柱启动起来，送一串字进去，看着机器写下一个回合。剩下的章节，再把这个回合一层层拆开。

先把最偷懒的写法摆出来，因为直到今天，多数套壳还是这个样子：

```text
messages.append(user)
reply = llm(messages)
if reply is tool: run it; append result; repeat
else: print reply
```

这套设计里，`messages` 既是记忆又是模型输入，工具执行是一次私下的函数调用，取消就是 `Ctrl-C`。平时能用；可一旦你需要检查其中任何一件事，它就不灵了。所以 harness-spine 换了一个不同的原语作出发点：[`boot.reb`](../../boot.reb) 里的 `boot-spine` 挂上一个根 context，把共享服务装上去，再创建一个默认智能体——它那些负责*动手*的插件，住在一间 isolate 里。

## 一次 echo 已经是一种协议

`boot-spine` 并不构造什么「聊天机器人对象」。它造出一个 Cordis context，挂上确定性调度器，再按固定顺序登记插件：`host`、`session`、`approval`、`llm`、`agents`。然后 [`scope/api.reb`](../../scope/api.reb) 里的 `create-agent-handle` 铸一把 scope 钥匙，把 `tools` / `shell` / `agent-loop` isolate 到子 context 上，返回一个 handle——它的 `run-turn` 就是 `driver/run-turn`。

默认的 LLM 适配器根本不是网络客户端。[`llm/api.reb`](../../llm/api.reb) 里的 `resolve-reply` 先取 `enqueue`（投递队列）里的回复；队列空了，又没配 script 或 HTTP 适配器，就把 `last-user-content` 原样回声。所以 `"hello from spine"` 会原封不动地作为助手文本回来。echo 既是教学用的适配器，也是一句设计宣言：没有厂商，脊柱照样能把一个回合走完。

接下来，[`agent-loop/api.reb`](../../agent-loop/api.reb) 里的 `run-turn-core` 做了一件偷懒循环从来不做的事：写下 `turn-start`，写下用户消息，从日志导出模型可见的视图，把回复以流的方式写下来（流的接收端会写下 `assistant-chunk` 行），再写一条最终的 `assistant-message`，最后用 `turn-end` 收工。跑完实验，你会按顺序看到整张事件表。导出的消息只有两行——一行用户、一行助手——因为 [`session/api.reb`](../../session/api.reb) 里的 `derive-messages`（只读投影）只是一个视图：chunk 被折叠起来，最终那条消息说了算。

所以，第一个回合就已经亮出了脊柱的根本分裂：日志是记忆，视图是模型看到的东西，driver 是一份协议，而模型是谁，就看这个进程里 `llm/stream` 碰巧接的是谁。后面的章节会陆续加上 tools、审批、isolate 房间、取消和热替换，但没有一章会推翻这次分裂——它们全都挂在它上面。

从这里起笔是有代价的：你会一下子撞见好几个名字——`spine`、`driver`、`sessions`、`derive-messages`。这是故意的。如果一本书先讲 host、再讲 session、再讲 tools，却始终不跑一个回合，那每一块看起来都像一个孤立的库。脊柱不是库。它是一台机器，它的第一份工作，就是跑完一个诚实的回合。

这一章还没回答的是：host *为什么*要存在，载荷为什么要冻结，tools 为什么是一条 waterfall。等 echo 适配器不够用的那天，这些问题会自己找上门来。

---

## 动手实验

```bash
cd ch01-echo-turn/code
bash run.sh
```

预期输出（关键行）：

```text
STATUS: text
STEPS: 1
ASSISTANT: hello from spine
MSG 1 user: hello from spine
MSG 2 assistant: hello from spine
--- event types ---
[turn-start user-message step-start assistant-chunk assistant-message step-end turn-end]
LAB-OK
```

### 试一试

1. 在 `demo.reb` 里把用户字符串改成 `"ping"`，再跑一遍。助手文本应当回声 `"ping"`。那是 [`llm/reply.reb`](../../llm/reply.reb) 里的 `last-user-content`，不是训练过的模型。
2. 在 `run-turn` 之前，用 `spine/llm/enqueue` 投进另一条回复（`kind: 'text`，`text: "not-an-echo"`）。助手应当打印那串字，而不是回声。`resolve-reply` 先查队列。
3. 回合结束后，打印 `length? spine/sessions/events-of s/id`，再跟 `length? spine/sessions/derive-messages s/id` 比一比。日志比聊天长。第 03 章就是讲这段落差。

### 对照真源

| 路径 | 符号 |
|------|--------|
| `boot.reb` | `boot-spine`, `create-agent-handle` (via scope) |
| `agent-loop/api.reb` | `run-turn`, `run-turn-core` |
| `llm/api.reb` | `resolve-reply`, `stream` |
| `llm/reply.reb` | `last-user-content` |
| `session/api.reb` | `derive-messages` |

行号是当前树的一份快照；符号才是稳定的锚点。

教学切片是带标注的 `examples/echo-turn.reb`。它并不重写脊柱。

<!-- source: ch02-host-door/chapter.md -->

# 第 02 章 为什么每一种副作用都必须经过同一扇门？

跑通了 echo 回合，下一个诱惑就来了：让 tools 和模型直接伸手摸世界。bash 工具自己调 `call/wait/shell`，HTTP 适配器在自己的函数里调 `curl`，delay 就 `sleep`。单看哪一条都挺顺。可合在一起，取消、测试、审计就全都做不到了：没有一个地方知道哪个子进程还活着，也没有一个地方能被测试替换成文件。

harness-spine 的回答是一个无聊透顶的服务，叫 `host`。名字容易被人一眼扫过，它立下的约束不会。架构文档写得很直白：host 是通往真实 I/O 的那扇门——shell、HTTP、流式 HTTP、delay——它不解释 tools，不写 session，也不解析 LLM 协议。

最省事的做法当然是「谁需要 I/O，谁就自己做」：`bash` 工具占有 `call`，LLM 适配器占有 `curl`，循环等待时占有 `sleep`。问题不在于这些调用慢，而在于它们根本无从问责。循环里的 `cancel-turn` 可以竖起一面旗，却杀不掉一个不是它启动的 curl；想测试流式回复，得先撑起一张真的网络；两个插件各自拉进程，清理时就会互相打架。

所以脊柱需要这样一个对象：它的方法是唯一被允许的出口。[`host/api.reb`](../../host/api.reb) 里的 `make-host-service` 就是它。

## 一扇门，不是一个平台

`run-command` 包住 `call/wait/shell/output/error`，返回的永远是一张带 `ok`、`code`、`stdout`、`stderr` 的 map。退出码非零也不抛异常，只是如实报告。这本身就是一条政策：tools 和测试消费的是一份结果，而不是为了「ls 失败了」去接住一个语言层面的错误。

`http-get` 既接受 `url!` 也接受 `file!`。支持文件路径不是图本地 HTML 方便，而是让脊柱的其他部分——尤其是 `llm/http.reb`——不靠 socket 也能重放一份响应。`http-post` 还是 shell 出去调 `curl`，先把 body 写进临时文件。更有意思的是它的兄弟 `http-post-stream`：`file!` 源经 `host-emit-lines` 一行行吐完；`url!` 源则在后台拉起 `curl -N`，tail 那个输出文件，并且理会一个 cancel 对象——取消的方式是杀掉 pid。循环稍后会把同一个 cancel 对象从 `turn-cancelled?` 一路传下来。

`delay` 和 `settle` 是 Cordis 意义上的 I/O：它们要么跟运行时 scope 上的确定性调度器对话，要么变成一个已决议的 thenable。实验里的 `delay 5 99` 不是把「让操作系统睡五毫秒」当成产品功能，而是在证明：异步等待也走 host 这扇门——这样循环才能一边泵调度器，一边还看得见取消旗。

host 拒绝充当工具解释器。`shell/api.reb` 把 `bash` 登记*在 tools 上*，`bash` 再去调 `host/run-command`；循环自己从不调 host；LLM 的 HTTP 适配器调 `host/http-post` 和 `host/http-post-stream`。session 持久化用的是 `session/store.reb` 里的 `write`——那是日志给自己文件留的一个故意例外，不是给 tools 开的第二扇门。

一扇门的代价也很明显：每多一种 I/O，就想多要一个 host 方法，host 迟早变成杂物抽屉。脊柱故意把这份清单留得很短。另一种做法——每个插件各备一套接口——在白板上更干净，可那样就没法共享一个要杀掉的 pid 了。本章实验先跑 `echo spine-host`，再对一份现成文件做 `http-get`，演示的重点不是 curl，而是：不管世界那边是一个进程还是一个文件，同一个服务返回的都是同一形状的 map。

门自己不记事，这就是下一股压力。host 既然是唯一的出口，就得另有一个地方，做唯一能回答「说过什么、做过什么」的入口。

---

## 动手实验

```bash
cd ch02-host-door/code
bash run.sh
```

预期输出（关键行）：

```text
CMD-OK: #(true)
CMD-CODE: 0
CMD-STDOUT: spine-host
GET-OK: #(true)
GET-BODY: host-file-body
DELAY-THENABLE: #(true)
DELAY-SETTLED: 99
LAB-OK
```

### 试一试

1. 把 `run-command` 改成 `"false"`（那条 Unix 命令）。`CMD-OK` 应当变成 `#(false)`，`CMD-CODE` 是一个非零整数。host 只报告，不抛错。
2. 把 `http-get` 指到一个不存在的文件。`GET-OK` 应当是 `#(false)`，`GET-BODY` 为空；结果 map 上的 `error` 带着这次读取失败。
3. 打印时把 `h/settle d` 换成只打 `d`。你会看见一个 thenable 对象，而不是 `99`。这就是循环和 tools 都去调 `settle`、而不把 delay 当成一个值的原因。

### 对照真源

| 路径 | 符号 |
|------|--------|
| `host/api.reb` | `make-host-service`, `run-command`, `http-get`, `http-post-stream`, `delay`, `settle` |
| `shell/api.reb` | `make-bash-spec` (calls `host-ref/run-command`) |
| `llm/http.reb` | `run-llm-http`, `run-llm-http-stream` |

教学切片并不拉起一台活的 HTTP 服务器。对着 curl 的流式取消，会在第 09 章的协议里讲到，`test/host-stream-test.reb` 里也有覆盖。

<!-- source: ch03-session-log/chapter.md -->

# 第 03 章 记忆为什么是日志，而不是聊天？

跑完一次 echo 回合，你已经看见了那次分裂：日志里七种事件类型，视图里只有两条消息。很容易把这当成记账——「框架多存了点元数据罢了。」不，那不是元数据。脊柱的记忆*就是*事件日志；模型看到的那场聊天，只是这本日志算出来的一个函数，每一步都重算一遍。你要是旁边再握着一个 `messages` 数组，手里就有了两份历史——而它们会在第一次流式重试、第一次回合取消、第一次 fork 分叉时对不上账。

最省事的做法当然是 OpenAI 那种数组：`[{role: user, content: ...}, {role: assistant, ...}]`。每个回合往后追加，把整个数组送给模型，也许再当 JSON 存下来。可助手的回答一旦拆成碎片流过来，这套设计就垮了：每个 chunk 都追加一条消息，还是先缓冲？缓冲到一半崩了，chunk 就丢了；把 chunk 当消息追加，下一次请求看起来就像模型连着说了六次话。工具调用更麻烦：数组得为 `tool` 行发明一套 schema，还拦不住调用方原地改掉昨天的内容。

所以脊柱存的是事件，不是消息。[`session/api.reb`](../../session/api.reb) 的 `append-event` 校验类型和载荷，用 [`session/json.reb`](../../session/json.reb) 的 `snapshot-json-map` 给载荷拍快照，挨个赋上连续的 `index`，发出 `session-event`，必要时再写进文件。实验要证明的第一件事就是快照：你递给 `append-event` 一张活的 map，转手把 `text` 改成 `"after"`，存下来的载荷仍然是 `"before"`。历史不是一根插在调用方堆里的指针。

## 一张可以扔掉的视图

`derive-messages` 把日志走一遍，产出模型可见的数组：用户消息和助手消息变成 `role` / `content` 行；连续的 `assistant-chunk` 事件拼成一条助手消息；后面若跟上 `assistant-message`，chunk 缓冲就被丢掉——最终那条消息说了算。`tool-call` 投影成带 `kind: 'tool-call` 的助手行，`tool-result` 投影成 `role: 'tool`。回合簿记（`turn-start`、`step-end`、审批事件）一概不出现。所以 echo 回合的视图是两行，日志却是七行。

视图既然是导出来的，driver 就不必再握一份影子拷贝。第 07 章你会看到 `run-turn-core` 在每一步开头都调 `derive-messages`。觉得这浪费？那就拿一份分叉历史的代价来比比。`fork` 把前缀拷进一个新的 session id，写下 `forked-from`，之后两本日志各自追加。实验里父本仍是两条消息，子本再长出第三条。没有什么「带写时复制标志的共享数组」等着你去搞错。

设了 `store-dir` 之后，[`session/store.reb`](../../session/store.reb) 会在每次追加后，把 events 块的 `mold/all` 写进 `<id>.events.reb`。新启动时 `open` 会重载这个文件、校验它，并恢复 `derive-messages`。实验先关掉第一条脊柱，再起第二条，把 `"persist me | ok"` 原样读了回来。默认启动没有后端，`open` 会直接报错——这是诚实的做法：持久化是一项配置，不是藏起来的全局变量。

日志的代价是啰嗦，还有一份封闭的事件词汇表。`validate-payload` 会拒绝未知类型，也会拒绝 `text` 不是字符串的用户消息；函数或循环引用的对象也别想偷塞进历史——`json-map?` 不收。这正是目的。另一种做法——「适配器返回什么就存什么」——正是 session 文件变得无法重放的原因。resume 政策在循环里，不在 session：`can-admit-turn?` 会把末尾停在 `user` 的日志判为 `no-input`，所以光秃一条 user-message 不够再叫一次模型。本章的日志规则无论怎样都稳。

这一章如果只记住一幅画面，就记住一本账本：出纳窗口（`derive-messages`）随时可以再誊一遍，但谁也不许改已经合上的一行；fork 就是另开一本账本，开头是第一本的影印件。

## 小结

把 session 想成一本装订笔记本，而不是一个聊天气泡。每一次 `append-event` 都是一行已经影印过的编号记录（`snapshot-json-map`）；调用方的笔可以继续写，笔记本不会跟着改。`derive-messages` 是那位把笔记本大声读给客人模型听的账房先生——把 chunk 折起来，偏爱最终那条助手行，跳过那些只管回合起止的事件。常见的错误是把账房先生的誊本当成笔记本本身。自检：两条 `assistant-chunk` 事件再加一条 `assistant-message` 之后，账房先生会产出几行助手消息？里面是哪段文字？

这一章在 host 之上加了记忆层。谁被允许动手，这里还没有答案——那是 tools 的事。

---

## 动手实验

```bash
cd ch03-session-log/code
bash run.sh
```

预期输出（关键行）：

```text
FROZEN: before
FOLDED: hello
MESSAGE-WINS: hello-final
PARENT-MSGS: 2
CHILD-MSGS: 3
FORKED-FROM: s3
PERSIST-ID: s1
MEMORY-EMPTY: #(true)
OPENED-ID: s1
REOPENED: persist me | ok
LAB-OK
```

`FORKED-FROM: s3` 不是什么神奇的 id。演示在父 session 之前先造了两个，所以父的 id 是 `s3`。

### 试一试

1. 追加 `"before"` 之后，去改载荷里一层嵌套的 map（比如 `tool-call` 上的 `args`），别改 `text`。确认存下来的嵌套 map 仍是那份快照。`snapshot-json-map` 会递归拷贝 map 和 block。
2. 把追加 `assistant-message` 的那行注释掉，再跑一遍。`MESSAGE-WINS` 应当消失；`FOLDED` 仍是 `hello`。这就是 `derive-messages` 只走 chunk 的那条路。
3. 把 `store-dir` 指到一个新文件夹，跳过 `open`，用文本编辑器去 `read` 那个 `.events.reb` 文件。你应当看到一块由 map 组成的 Rebol block，不是聊天用的 JSON 数组。

### 对照真源

| 路径 | 符号 |
|------|--------|
| `session/api.reb` | `append-event`, `derive-messages`, `fork`, `open`, `validate-payload` |
| `session/json.reb` | `snapshot-json-map`, `json-map?` |
| `session/store.reb` | `make-file-session-backend`, `save-session`, `load-session` |

教学切片略过了 `create-from-log` 回放和 `session-end-seed`。它们在 `test/session-test.reb` 里。

<!-- source: ch04-tools-waterfall/chapter.md -->

# 第 04 章 工具为什么不是一次函数调用？

工具看起来像函数：有名字、有参数、有结果。最省事的脊柱会备一张函数表，然后 `do registry[name](args)`。插件往往这么起步，也往往这么漏：没有一个时机能让策略在函数还不存在时拒绝这次调用；没有一个时机能让沙箱在函数跑完后改写 stdout；没有一个事件能让观察者订阅，而不必亲手把每个函数包一层。第一次「就这一回」的 `if name = 'bash [check ...]`，最后会长成第二套解释器。

harness-spine 把工具当成一次有证人在场的公共行为。[`tools/api.reb`](../../tools/api.reb) 的 `execute` 并不一上来就跑本体：它先造一份 `exec` map（`name`、`args`），再跑三条 waterfall，最后发出 `tools-result`。每条 waterfall 的内层都是一个默认动作——要么放行，要么跑 `spec/run/call`，要么把本体结果原样递出去。监听者可以前置或包住这些内层，手法和 Cordis 包任何一条 waterfall 一模一样。

## 四个阶段，一次定格的广播

`tools-pre-execute` 是拒绝的闸门。默认内层返回 `#[kind: 'allow]`；监听者可以返回 `kind: 'deny`（或 `ok: false`）。接着 `pre-denied?` 造一份合成的错误结果，发出 `tools-result`，碰都不碰本体就返回了——实验里 ping 的计数器停在零。闸门跑在 `run/call` *之前*，意义全在这里。

就算预执行没拒绝，规格自己的 `approval`（**审批**）字段仍可能抬出 `kind: 'ask`。那道接缝是第 05 章的事，这里只需知道：ask 不是跑本体的第三条路，而是一次绕行——必须落到「仅此一次允许」（**allowed-once**）上，否则就变成另一次拒绝。

`tools-execute` 是唯一一个默认内层会去调 `spec-ref/run/call` 的阶段。在这里前置的监听者同样可以像预执行那样跳过本体——`test/tools-test.reb` 管这叫「exec-stage deny」。但设计的意图没变：副作用只发生在这一层内层，或者因为本体调了 host 而发生在 host 里；不发生在 pre，也不发生在 post。

`tools-post-execute` 收到的是 `[exec body-out]`，默认内层返回 `arg-block/2`——也就是本体的结果。监听者可以事后改写 `stdout` / `text`：实验里 ping 照样跑了一次，但文本变成了 `"rewritten"`。post 是给策略和涂黑用的，不是用来偷偷干活的。

随后 `emit-result` 往内存里的 `result-log` 追加一行，再带着 `make-scope-target` 给出的 scope 载体，用 `events/emit` 发出一次 `tools-result`。观察者看到的是一份已经做完的 map，没法把本体撤回去。第 08 章会讲清楚：正是这份载体，让智能体 A 的监听者看不见智能体 B 的 ping。

`shell-plugin` 就是一份存在证明：对循环来说，bash 没什么特殊。它注入 `tools` 和 `host`，登记一份名叫 `'bash` 的规格，规格的 `call` 就是 `host-ref/run-command`。所以实验里的 `echo through-host` 走的是 execute → bash 规格 → host → 一份结果 map。循环要用工具时，会带着 session id 和一次取消检查去调 `tools/execute/meta`——它从不调 host，也从不调 bash。

waterfall 的代价是：一次「hello world」现在有了四个名字；监听者要是忘了调 `nw/call`，就会把内层吞掉。另一种做法——tools 自己维护一份 `before/after` 中间件列表——也够用，直到你想复用 Cordis 其余部分那套拦截机制为止。tools 故意复用 `ctx/events/waterfall`。未完成处也得点名：每个阶段上的 `settle/cancel` 意味着 thenable 本体可以被放弃，但本体自己必须配合；规格里一次失控的 `call/wait` 仍是 host 的问题，不是 waterfall 的。

## 小结

把工具执行想象成一条机场安检通道，而不是一张函数表。预执行是查证件——可以把你打发回家，飞机还没动；执行是引擎唯一点火的地方；后执行是海关，检查你已经提着走了一路的那只包；`tools-result` 是广播，宣布发生了什么——包括那些根本没离开柜台的行程。常见错误是先登记一个函数，想着「以后再加日志」。自检：预执行监听者返回 `kind: 'deny` 时，`spec/run/call` 还会跑吗？`tools-result` 还会发出吗？

这一章装上了「动手」这一层。许可——问人一声，只问一次——是这一层的客人，不是第二套工具执行器。

---

## 动手实验

```bash
cd ch04-tools-waterfall/code
bash run.sh
```

预期输出（关键行）：

```text
PING: pong calls=1
UNKNOWN-OK: #(false)
UNKNOWN-ERR: unknown-tool
PRE-DENY: pre-denied calls=0
POST-REWRITE: rewritten calls=1
RESULT-EMITTED: #(true)
BASH-STDOUT: through-host
LAB-OK
```

### 试一试

1. 把预拒绝的监听者改成返回 `kind: 'allow`，再跑一遍。`PRE-DENY` 应当显示 `pong`（或者你得自己去打印 `select d 'text`），并且 `calls=1`。拒绝是一个值，不是监听者没来。
2. 前置一个 `tools-execute` 监听者，返回 `make map! [ok: false error: "exec-denied"]`，不要去调内层。`ping-calls` 应当停在 0。这就是 `test/tools-test.reb` 里的 exec-stage deny。
3. 去 execute `'bash`，但缺少 `command` 键。`shell/api.reb` 里的规格应当返回 `ok: false` / `error: "missing command"`，并且不调 host。

### 对照真源

| 路径 | 符号 |
|------|--------|
| `tools/api.reb` | `execute`, `pre-denied?`, `emit-result`, `register` |
| `shell/api.reb` | `make-bash-spec`, `shell-plugin` |
| `scope/api.reb` | `make-scope-target` (carrier on emit) |

未知工具仍会发出 `tools-result`。没有一声不响的 `none`。

<!-- source: ch05-approval-once/chapter.md -->

# 第 05 章 为什么只问一次、缺席即拒绝，并且两边都写下来？

一条能拒绝的 waterfall，并不等于有人说了「好」。最省事的做法是在工具上挂个布尔值，或者让界面堵一个回调，session 里除了最终的 tool-result 什么也不留。这套做法会朝两个方向撒谎：进程若在提问中途死掉，你无法知道人到底答没答过；同一件工具跑第二次时，「用户已经同意过了」会变成一张你本没打算发、却粘住不放的通行证；要是没有界面在听，布尔值在这个代码库里默认 true，在另一个代码库里默认 false，两边都不留痕迹。

harness-spine 在本体前面放了一道一次性的接缝，把问题和答案都写进日志。[`approval/api.reb`](../../approval/api.reb) 的 `request` 要求有一个打开着的回合（有 `turn-start`，还没有 `turn-end`）。它造出一个 id，追加 `approval-asked`，然后要么在策略 `'never` 下立刻拒绝，要么去跑 `approval-request` 这条 waterfall。这条 waterfall 的默认内层返回 `'unavailable`——没有内置界面。缺一个回答者，本身就是一条被记下的结局，不是挂起，更不是默许。

## 缺席即拒绝，是默认的内层

`decide-outcome` 造一份很小的请求 map，把 `approval-request` 送进 waterfall。内层是 `'unavailable`；测试或 host 上的界面会前置一个监听者，返回 `'allowed-once`、`'rejected`（或 `'cancelled`）。`normalize-approval-outcome` 把其余一切映回 `'unavailable`。随后 `request` 带着这个结局追加 `approval-decided`。实验展示了这种配对：三次提问，三次决定——包括那条根本不去问回答者的 `never` 路径，和真去问了的 `ask` 路径。

策略也住在日志里：`set-policy` 追加一条 `approval-policy`，带上 `'ask` 或 `'never`；`effective-approval-policy` 倒着扫事件，找最近的一行策略，找不到就用服务默认（`'ask`）。于是一次 session 可以先宽松后收紧，回放时也能看见转变发生在哪一刻。没有通行证仓库——`'allowed-once` 管的是这一次调用，不是这件工具这周随便用。

在产品代码里，通往这道接缝的路就是 `tools/execute`。预执行（或规格上的 `approval: 'ask`）一旦抬出 ask，`resolve-approval-ask` 就去查 `approval` 服务，要求 execute 的 meta map 里带 `session-id`，再调 `approval/request`。只有 `'allowed-once` 才能继续走进执行内层。实验里的 `ask-ping` 工具，没有回答者时被拒（`ok: false`），挂上放行监听者之后才跑出 `"allowed-body"`。本体从头到尾看不见拒绝那条路。

在打开的回合之外请求审批会直接抛错。这看着严厉，直到你想象一行审批记录漂在两个回合之间、对不上任何一次 `run-turn`——那时脊柱握着一个人的决定，却没有任何 driver 有义务尊重它。「缺席即拒绝」也包括「现在不行」。

这道接缝的代价是：真正的产品必须自己提供回答者——命令行提示、聊天按钮，或者 CI 里一个永远拒绝的回答者。脊柱不会假装自己就是那款产品。另一种做法——把 `ask` 烤进 tools 变成 `input()`——会堵住调度器，还跳过日志。`approval-outcomes` 里那四个词以外的结局，一律塌缩成 `'unavailable`：界面钩子上的一次拼写错误，不许变成通行证。

这一章没加跨调用的通行证记忆，也没加比 ask/never 更丰富的策略。如果你需要「第一次点头之后 bash 永远放行」，那是你自己的监听者该管的事——而且它仍应写下你可以回放的东西。

---

## 动手实验

```bash
cd ch05-approval-once/code
bash run.sh
```

预期输出（关键行）：

```text
NEVER: rejected
NO-ANSWERER: unavailable
GRANTED: allowed-once
ASKED: 3
DECIDED: 3
OUTSIDE-TURN: #(true)
TOOL-DENIED: #(false)
TOOL-GRANTED: allowed-body
LAB-OK
```

### 试一试

1. 在 `'never` 之下，挂一个返回 `'allowed-once` 的回答者，再跑一遍。`NEVER` 应当仍是 `rejected`。策略 `'never` 不会去调 `decide-outcome`。
2. 让回答者返回字符串 `"allowed-once"`，而不是那个 word。`normalize-approval-outcome` 接受这种转换。若返回 `"sure"`，你应当看到 `unavailable`。
3. 对 `ask-ping` 调用 `tools/execute`，meta 里*不要*带 `session-id`。拒绝原因应当提到：审批的 ask 需要一个 session。

### 对照真源

| 路径 | 符号 |
|------|--------|
| `approval/api.reb` | `request`, `decide-outcome`, `set-policy`, `effective-approval-policy` |
| `tools/api.reb` | `resolve-approval-ask`, `pre-ask?` |

没有通行证仓库，也没有内置界面。不设这些，正是设计。

<!-- source: ch06-llm-guest/chapter.md -->

# 第 06 章 为什么模型不当家？

到这里，脊柱已经能记住、能动手了。剩下的诱惑是让模型拥有循环：去调厂商，把回来的 JSON 随便一解析，就把那个对象当成世界的下一份状态。套壳就是这样变成远程代码解释器的：厂商超时，schema 漂移，流重试，而你的 session 成了上一份 HTTP 正文碰巧长成的样子。

harness-spine 把这个关系倒了过来：循环向一个 `llm` 服务要一份回复，服务返回一份很小的 map——`kind: 'text` 带 `text`，或 `kind: 'tool-call` 带 `name` 和 `args`。适配器可以是队列、Rebol 脚本、HTTP 行协议，或内置的 echo。模型看不见 host，不往 session 追加，也不执行工具。架构文档那句话是对的：llm 不执行工具，也不拥有 session。

最省事的做法是「SDK 就是智能体」：消息递进去，消息出来，里面有 `tool_calls` 就按 SDK 定好的模式跑。问题出在所有权上：取消得跟 SDK 的 HTTP 客户端打架；测试需要真网络；换供应商等于换循环；给缺陷报告准备的脚本夹具加载不了，因为循环在文件头顶就 import 了 `openai`。

## 一位带着队列的客人

[`llm/api.reb`](../../llm/api.reb) 的 `resolve-reply` 是这位客人进门先碰到的窗口：`queue` 非空，`take queue` 赢；否则走配置好的 `script` 路径（经 [`llm/script.reb`](../../llm/script.reb)）；再否则走 `http-url`（经 [`llm/http.reb`](../../llm/http.reb)）；都不行就 echo `last-user-content`。所以实验里第一次 `complete` 没有任何厂商，也返回了 `"hello guest"`；第二次调用前 `enqueue`（**投递**）了 `"from-queue"`，即使消息没变，返回的也是队列里那份 map。测试和后面的章节都依赖这个次序：队列不是上一次 echo 的缓存，而是排在所有其他适配器前面的脚本适配器。

`stream` 是同一位客人，只是多了一个 sink。走 HTTP 流这条路时（队列空、没有 script、设了 `http-url`），`run-llm-http-stream` 经 host 发出 post，解析一种行协议：带 `delta` 的 map、可选的最终 `kind`/`text`，或者把非空的纯文本行当成增量。不走这条路就跑 `resolve-reply`，`emit-text-chunks` 要么把 `chunks` block 挨个送一遍，要么把整份 `text` 送一次。实验 `enqueue` 了 `chunks: ["hel" "lo"]`，sink 看见两截，返回的 map 里仍是 `"hello"`。

第 07 章的 driver 会把每一次 sink 调用写成 `assistant-chunk`，再从最终那份 map 写下 `assistant-message`。实验已经这样跑过一个回合：两条 chunk 事件，一条消息，`derive-messages` 的结果和一个同样返回 `"hello"` 的非分块回合完全对得上。流式只是线路上的形状，不是第二份记忆。

客人不许做的事有两件：另挑一个 session，或者自己去调 `tools/execute`。一份 `tool-call` 回复只是数据——那个名字存不存在、要不要走审批、是不是已经请求了取消，都由循环决定。需要套接字的 HTTP 适配器仍走 host，所以一份文件夹具就能顶替 URL。插件上的 `service-resolve-config` 让 YAML 的 intercept 去合并 `script` / `http-url`，手法和 `max-steps` 合并到循环上一样。

这份谦卑是有代价的：「把 token 流式丢给界面」在适配器里不是一行代码的事——适配器要么填好 `chunks`，要么按那套行协议说话，日志则归循环管。另一种做法——让适配器自己追加事件——会让每个厂商都变成互相抢笔的史官。未完成处也得说清：这棵树的默认适配器是 echo，不是生产用的模型；`examples/full-chain.reb` 和 `llm/http.reb` 展示了 HTTP 那条路，本章实验停在 `enqueue` 上，好让你不用密钥也能跑。

下一章轮到这位客人的东道主登场：一个回合——它重读日志，问客人，然后才动手。

---

## 动手实验

```bash
cd ch06-llm-guest/code
bash run.sh
```

预期输出（关键行）：

```text
ECHO: hello guest
ENQUEUED: from-queue
STREAM-TEXT: hello
STREAM-CHUNKS: ["hel" "lo"]
TURN-ASSISTANT: hello
TURN-TYPES: [turn-start user-message step-start assistant-chunk assistant-chunk assistant-message step-end turn-end]
DERIVE-MATCH: #(true)
LAB-OK
```

### 试一试

1. `enqueue` 一份 `kind: 'tool-call` 的 map（`name: 'bash`，`args` 里带 `command`），不要文本，然后 `complete`。你应当原样拿回那份 map。客人可以提议一次行动；它并不去执行。
2. 把 `chunks` 设成 `["hel" "lo"]`，却把 `text` 设成 `"mismatch"`，再去 stream。sink 仍走 `chunks`；返回的 `text` 是 `"mismatch"`。循环会把 sink 来的 chunk 记进日志，最终消息则取自 `text`。适配器上的诚实要紧。
3. 去读 [`llm/http.reb`](../../llm/http.reb) 的 `parse-llm-stream-line`，给 `host/http-post-stream` 喂一份由增量行组成的夹具文件（见 `test/fixtures/llm-http-stream.txt`）。那才是生产路径；本实验用 `enqueue` 来模拟它。

### 对照真源

| 路径 | 符号 |
|------|--------|
| `llm/api.reb` | `resolve-reply`, `complete`, `stream`, `enqueue` |
| `llm/reply.reb` | `last-user-content`, `normalize-llm-reply` |
| `llm/http.reb` | `run-llm-http-stream`, `parse-llm-stream-line` |

适配器不去调 `sessions/append-event`。若你找到一个调了的，那是缺陷。

<!-- source: ch07-the-turn/chapter.md -->

# 第 07 章 为什么每一步都要把日志重读一遍？

在最省事的想象里，一个回合就是一个可变的对话对象外加一个 while 循环：追加用户字符串，调模型，也许跑个工具，再追加，模型一开口就停。那个活数组*就是*状态。这正是第 03 章在存储上拒绝过的设计，如今作为控制流再失败一次：中途取消，数组里会有一次没有结果的 tool-call；想要恢复，你不知道该不该再送一行新的用户记录；插件想改写模型看到的东西，就得去改界面正在打印的那同一个数组。

[`agent-loop/api.reb`](../../agent-loop/api.reb) 的 `run-turn-core` 则是一份压在日志上的协议：标上 `live-session-id`，写下 `turn-start`，把 inbox（**收件箱**）里的消息领取成 `user-message` 行，可选地写下调用方的用户文本，然后进入循环——`step-start`、derive、pre-step waterfall、request waterfall、`llm/stream`，接下来要么是 tool-call/tool-result，要么是 assistant-message，最后 `step-end`。它在文本处停，在 `max-steps` 处停，在拒绝处停，在取消处停，也在被 dispose 的 Fiber 处停。模型的每一次输入都来自 `sessions/derive-messages`（或对那份视图的一份*拷贝*做 waterfall 改写）。循环上没有 `this.messages` 这个字段。

## 循环是账房先生，不是缓存

实验的第一回合先 `enqueue` 一次 bash 的 `tool-call`，再投进一段文本回复。`run-turn` 写下用户行，把这次工具调用流出来（那是数据，不是执行）、记进日志，带着 cancel-check 去调 `tools/execute/meta`，记下 `tool-result`；再走一步，流出文本，记下 `assistant-message`。派生出的角色序列是 `[user assistant tool assistant]`——正是第 03 章教过的那份投影，如今由活着的 driver 当场算出来。两步之后，状态是 `'text`。模型从没听见过什么旁路，它会在下一次 derive 时听见那条工具结果。

`resume-turn` 就是 `run-turn-core/resume`：不写新的用户行。允许它的时机有两种——`can-admit-turn?` 判定派生视图已经以 `tool` 或 `assistant` 收尾；或者 inbox 领取到了一条会把循环叫醒的 `followup` / `steer`。实验先在 `"seeded"` 上完成一次 echo，再 `enqueue` `"from-resume"` 并 resume：角色变成 `[user assistant assistant]`，用户行仍然是 1 行。这就是 resume 的全部契约：从历史接着走，不许假装人又开口了一次。

一份收尾于孤零零一条 `user-message` 的日志，会返回 `status: 'no-input`——`can-admit-turn?` 并不把「已经有一行用户记录」当成该去叫模型的理由。`test/session-fork-test.reb` 锁住了这条边，并只在已完成回合（assistant/tool 收尾）或 inbox 有 waking 消息时测 happy path。

客人面前拦着两条 waterfall。`agent-pre-step` 收到 `[session-id step-n proposed-messages]`，可以交回一块改写过的 block，也可以交回 `kind: 'reject`；`agent-request` 收到一份带 `messages`、`tools`、`llm` 的请求 map，可以把供应商换掉。实验里的 pre-step 监听者给用户内容加上 `"[prefix] "` 前缀，echo 适配器于是用那串带前缀的字符串作答——所以日志里的 *assistant* 带上了前缀，而原始用户行经 `derive-messages` 仍是 `"hello from pre-step"`。账房先生可以对客人说谎，笔记本上却不会多出一行伪造的人话。（监听者就地改写提案里的 map；那些 map 是 derive 出来的副本，不是事件载荷本身。）

`followup`、`steer`、`inject` 就是 inbox：下一回合还是下一步，叫醒还是不叫醒。它们只有被领取之后，才会变成 `user-message` 行。本章实验不抽干那个队列，那是 `examples/inbox-turn.reb` 的事。要紧的耦合还是那条：领取下来的文本先落进日志，再做下一次 derive——于是模型看见它，走的和看见人亲手打的字符串是同一条路。

重读的代价是实打实的 CPU，长会话尤其如此；它还逼着每个想「随手加一句系统提示」的功能去当 waterfall，而不是循环上的一个字段。另一种做法——缓存上次 derive 的结果——正是取消或 fork 会悄悄端出过期工具表的原因。另一道闸是 `max-steps`（默认 8，可通过 `service-resolve-config` 覆盖）：一个只会回 tool-call 的客人，不许永远跑下去。

## 小结

想象一位账房先生：每天早晨，他把装订好的笔记本大声读给客人听，再把客人说了什么、要做什么记下来。他并不在抽屉里另藏一本。`resume-turn` 是「明天接着干，不许捏造一位新访客」。`agent-pre-step` 是凑到客人耳边换一套措辞，纸上那句访客的原话却不动。常见的错误是以为循环*拥有*一场对话。它没有。它有的是指针 `live-session-id`，以及每一步都去调 `derive-messages` 的习惯。自检：一次 tool-call 步骤之后，下一轮模型输入里的工具结果从哪来——循环上的某个变量，还是 session 里已经写下的那条 `tool-result` 事件？

这一章是脊柱的发动机。下一章要回答：为什么这台发动机要装进每个智能体自己的房间，而笔记本仍放在前台。

---

## 动手实验

```bash
cd ch07-the-turn/code
bash run.sh
```

预期输出（关键行）：

```text
TOOL-STATUS: text
TOOL-STEPS: 2
TOOL-TEXT: saw the tool
TOOL-ROLES: [user assistant tool assistant]
RESUME-TEXT: from-resume
RESUME-ROLES: [user assistant assistant]
RESUME-USER-ROWS: 1
PRESTEP-ASSISTANT: [prefix] hello from pre-step
PRESTEP-LOG-USER: hello from pre-step
LAB-OK
```

### 试一试

1. 工具回合之后，*不要*再 `enqueue` 新回复，直接调 `resume-turn`。echo 适配器会看见最后那条用户内容（`"run it"`），你会多出第三行助手记录，把那句话再复述一遍。Resume 不捏造用户行；它仍会去问客人。
2. 把 pre-step 监听者改成返回 `make map! [kind: 'reject reason: "nope"]`。回合状态应变为 `rejected`，并出现一条 `step-rejected` 事件。日志里的用户行应仍是原来的字符串。
3. 在 `demo.reb` 里打印 `spine/driver/max-steps`，再 `enqueue` 九次 bash 工具调用、不要最后那段文本。状态应变为 `max-steps`。

### 对照真源

| 路径 | 符号 |
|------|--------|
| `agent-loop/api.reb` | `run-turn-core`, `resume-turn`, `can-admit-turn?`, `run-pre-step`, `run-request` |
| `session/api.reb` | `derive-messages` (called every step) |

inbox 的领取规则，看 `examples/inbox-turn.reb` 比看这份切片更清楚。

<!-- source: ch08-isolate-rooms/chapter.md -->

# 第 08 章 为什么每个智能体都要有自己的房间？

如果 tools、shell 和循环都是根上的服务，两个智能体就会共用一张登记表、同一面 `cancel-requested` 旗：在 A 上登记 `whoami`，会改掉 B 跑的东西；取消 A，也就取消了 B；监听 `tools-result`，等于听见所有人。最省事的做法正是这样——一个全局工具箱，许多场会话。在第二个智能体出现之前，它都显得更简单。

harness-spine 按架构文档写明的方式切开世界：每个智能体是 `isolate 'tools`（**隔离**）外加一把 scope 钥匙；session 和 llm 留在根上。[`scope/api.reb`](../../scope/api.reb) 的 `create-agent-handle` 铸出一把不透明的钥匙（带标签的 `make object! []`），可选地 `bind-scope-parent`，然后 `extend-agent-iso` 把 `tools`、`shell`、`agent-loop` 放进根的 `isolate-map`，键名是 `agent-<label>`。子 context 拿到这三个插件；handle（句柄）上的 `tools` 和 `driver` 是在那间 isolate 里查的，不是在根上。

## 私人动手，共享记忆

实验拉起 A 和 B，各自登记一份闭包住 id 的 `whoami` 规格，然后执行：A 返回 `"A"`，B 返回 `"B"`。这不是在同一张 map 里做命名空间，而是两份 `tools` 服务、各有各的 `registry`。`shell` 同样被隔离，所以 A 上的 bash 也不是把规格偷塞给 B 的路子。

事件跟着钥匙走，不跟着进程走。`execute` 发出 `tools-result` 时带着 `make-scope-target scope-of ctx`；`scope-admits?` 从派发钥匙沿父链往上走——监听者的 `scope-of` 若是 B，就不接纳 A 的派发。实验在每个 isolate 的 ctx 上挂监听：A 听得见 A，B 听不见，反过来也一样。父钥匙是那个「算功能、不算漏洞」的例外：实验铸出 `parent`，用 `/parent` 拉起 `child`，把那把钥匙挂到*根* ctx 上，于是根上的监听者听见了孩子的 `tools-result`。子智能体可以向上汇报，兄弟姐妹不能横着偷听。

Session 是共享的前台。A 和 B 在同一个 session id 上各跑一次 `run-turn`，派生出四条消息：来自 A、echo、来自 B、echo。说话的人换了，笔记本并不因此 fork。若你*要*记忆上的隔离，就 `sessions/create` 两次，或者 `fork`。脊柱不会给每间 isolate 凭空再造一本日志——那样的话，「两个智能体，一条线」就做不成了。

[`agent/api.reb`](../../agent/api.reb) 把 handle 的创建包进一张活表，带 `agent-created` / `agent-disposed` 事件。`dispose` 先调 `cancel-turn`，再 `release-agent-handle`，后者会 dispose isolate 上的 Fiber。`boot-spine` 给出的默认智能体也是这么登记的；实验走的捷径是 `boot.reb` 里的 `spawn-agent`。

房间的代价是心智模型更难，还有一条你迟早会绊倒的规矩：`cordis.yml` 根上的 YAML 列出 host、session、approval、llm、agents——没有 tools。tools 仍然会出现，因为 `create-agent-handle` 会装上它们。盯着 YAML 问「bash 在哪？」，是问错了层。另一种做法——把 tools 放在根上、每个方法里再按智能体 id 过滤——会把 isolate 的逻辑摊进每一个插件。`isolate-map` 沿用内核已有的 `extend` 行为，scope 钥匙则让事件路由不必变成「去载荷里翻一个 id」。

## 小结

把这套设计想成一家旅馆：前台（`sessions`、`llm`、`host`）是共用的；每位客人分到一间房，房里的迷你吧（`tools`）、烧水壶（`shell`）、客房电话（`agent-loop`）都不是隔壁那份。房间钥匙是一个不透明对象，不是给你解析的字符串。套房的父钥匙听得见连通房里的动静，隔壁那间听不见。常见的错误是「智能体等于 session」。自检：两间 isolate 都对着 `s1` 跑回合——存在几个 session 对象？几张 `tools` 登记表？

这一章让房子住上了人。怎么让一位房客停下、又不谎报他刚才在干什么——那是下一份协议。

---

## 动手实验

```bash
cd ch08-isolate-rooms/code
bash run.sh
```

预期输出（关键行）：

```text
WHO-A: A
WHO-B: B
A-HEARD-A: #(true)
B-HEARD-A: #(false)
B-HEARD-B: #(true)
A-HEARD-B: #(false)
SHARED-MSGS: 4
FIRST-USER: from A
THIRD-USER: from B
PARENT-HEARD-CHILD: #(true)
LAB-OK
```

### 试一试

1. 只在 A 上登记 `whoami`，然后 `agent-b/tools/execute 'whoami`。你应得到 `unknown-tool`。隔离不是前缀；规格根本不在。
2. 去掉 `attach-scope-ctx spine/ctx parent-key`，再跑父级监听。`PARENT-HEARD-CHILD` 应变为 `#(false)`，因为根上的 `scope-of` 不再匹配孩子的派发链。
3. 打印 `agent-a/ctx` 对比 `spine/ctx`，确认它们不是 `same?`。然后两边都 `reflect/get 'sessions`：session 仍从父链解析；tools 则不该。

### 对照真源

| 路径 | 符号 |
|------|--------|
| `scope/api.reb` | `create-agent-handle`, `extend-agent-iso`, `make-scope-target`, `scope-admits?` |
| `agent/api.reb` | `create`, `dispose`, `register` |
| `boot.reb` | `spawn-agent`, `boot-spine` (default handle) |

智能体 isolate 插件不是 YAML 条目。第 10 章会从装配那一侧再讲一遍。

<!-- source: ch09-cancel-protocol/chapter.md -->

# 第 09 章 为什么停下是一份协议，而不是一次异常？

启动一个回合值得庆祝，停下才是套壳开始撒谎的地方。最省事的停法是 `Ctrl-C`、`kill`，或者从回调里抛异常：进程没了，或者栈被拆了，session 里却留下一次没有结果的 `tool-call`，或一段看起来像模型突然哑火的流。下一次 `derive-messages` 会把这段没写完的故事当作历史，送给一个新模型。

harness-spine 把取消做成一套协作式协议（cooperative cancel）：它仍须让笔记本保持前后一致。循环上的 `cancel-turn` 发现 `live-session-id` 是字符串，就竖起 `cancel-requested`，并返回那个 id；driver 空闲时，它返回 `none`，而且**不**留下旗标。实验的头两行就是这份空闲契约：`_` 和 `#(false)`。一面空闲时粘着不降的旗标，会把下一个无辜的回合也取消掉。

## 先是检查点，然后是一行 cancelled

`run-turn-core` 一开始就记下活着的 session，并清掉旗标。它在步进循环之前、step-start、流结束之后、execute 之前、execute 之后检查 `turn-cancelled?`（旗标，或已经不活动的 Fiber）。循环上的 `settle` 一次只泵一个调度器条目的 thenable，好让 delay 能被打断；tools 的 `settle/cancel` 接收一个 `cancel-check` 对象，其 `call` 就是 `turn-cancelled?`；LLM 的 `stream` 接同样的形状；host 的 `http-post-stream` 在那个对象被触发时杀掉 curl 的 pid。一面旗，三层检查，没有第二种取消。

实验登记了一个 `abort` 工具，本体调用 `driver/cancel-turn` 并返回 `"abort-body"`；队列里后续的文本是 `"should-not-run"`。`run-turn` 之后，状态是 `'cancelled`，旗标已清，日志里有 `turn-start`、`tool-call`、`tool-result`、`turn-end`，**没有** `assistant-message`。tool-result 的载荷带着 `cancelled: true` 和 `text: "cancelled"`。注意：本体确实跑过——这条路径是在规格返回*之后*才取消的，但循环拒绝把那个返回值当成正常结果，改写下来的是 `cancelled-tool-result`。`test/loop-cancel-test.reb` 里还有一条延迟路径：在 `host/delay` 期间取消，本体根本完不成。两条路都以一条 cancelled 的 tool-result 收场，而不是挂死。

那一笔写入就是诚实：下一次 derive 会看见一行内容为 `"cancelled"` 的 tool 记录，新模型能看见这次动手没有做完。后续那条 `enqueue` 还没被消费，所以在新 session 上的下一回合可以正常 echo `"next"`。取消并不会让进程中毒。

[`agent/api.reb`](../../agent/api.reb) 里的 `agents/dispose` 先调 `cancel-turn`，再拆 isolate 上的 Fiber。dispose 之后，`agent-active?` 为假（`fiber/uid` 没了），`run-turn` 返回 `status: 'disposed`，并不假装要开工。实验的最后一行就是这份拒绝。

协作式取消的代价是：一个不理 host、在 Rebol 里空转的工具，要等到自己返回才看得见那面旗。脊柱没法把一次落在不可打断二进制上的 `call/wait` 变成一笔事务。它能做的是：拒绝*记下*一次并非它本意的成功，也拒绝在一根死掉的 Fiber 上开工。另一种做法——杀掉操作系统进程——只有在你连 session 一起扔掉时才算诚实；日志还留着，你就仍需要一行 cancelled。不完整之处也得点名：工具已经向外部 API 提交过的动作，没有分布式两阶段中止。

## 小结

停下不是拔电源线，而是在下一个检查点举手，然后在笔记本上写下「cancelled」，免得下一位客人接手一个鬼魂。空闲时的取消是空操作，免得那只手第二天早晨还举着。dispose 先取消，再收走房间钥匙；之后的 `run-turn` 得到 `disposed`，而不是一项神秘失踪的服务。常见的错误做法是从工具里 `throw`，再指望 session 看起来像那次抛出。自检：abort 工具跑过之后，日志里有没有那条已经在 LLM 队列里的后续助手文本？

这一章收住了「活着」的协议。最后一层是装配：房间如何被建起、叠上、换掉，却不扔掉笔记本。

---

## 动手实验

```bash
cd ch09-cancel-protocol/code
bash run.sh
```

预期输出（关键行）：

```text
IDLE-CANCEL: _
IDLE-FLAG: #(false)
CANCEL-STATUS: cancelled
FLAG-CLEARED: #(false)
HAS-TURN-START: #(true)
HAS-TOOL-CALL: #(true)
HAS-TOOL-RESULT: #(true)
HAS-ASSISTANT: #(false)
RESULT-CANCELLED: #(true)
RESULT-TEXT: cancelled
NEXT-STATUS: text
DISPOSED: disposed
LAB-OK
```

### 试一试

1. 从 abort 工具里去掉 `drv/cancel-turn` 再跑。状态应变为 `'text`，`HAS-ASSISTANT` 为 `#(true)`，带着 `"should-not-run"`。队列被跳过，只因为取消打断了循环。
2. 一次 cancelled 回合之后，在同一场 session 上 `resume-turn`。你应从那条 cancelled 的 tool-result（`role: 'tool`）接着走，而不是一张白纸。历史里包括这次 abort。
3. 空闲时连调两次 `cancel-turn`。两次都应打印 `_`。旗标不许粘住。

### 对照真源

| 路径 | 符号 |
|------|--------|
| `agent-loop/api.reb` | `cancel-turn`, `turn-cancelled?`, `cancelled-tool-result`, `agent-active?` |
| `tools/api.reb` | `settle/cancel` |
| `host/api.reb` | `http-post-stream` `/cancel` |
| `agent/api.reb` | `dispose` (cancel then release) |

`test/loop-cancel-test.reb` 也覆盖了 `host/delay` 期间的取消。

<!-- source: ch10-assemble-reload/chapter.md -->

# 第 10 章 为什么要装配和热替换，而不是一次写死？

前面每一章本都可以塞进一个文件：host 函数、一本日志、一个循环。那个文件很好粘贴，却变不出花样。生产环境要的是：一份最小的 echo profile，一份完整的 HTTP profile，一层把审批关掉的 home 叠层，以及一种换掉 LLM 适配器却不丢 session 的办法。最省事的做法是一堆开关：`if config.useHttp [load http]`。这样先死于组合爆炸；运行时还有更糟的死法——用赋值去换适配器，循环手里捏着的仍是 Fiber 换代之前那份过期的服务对象。

harness-spine 的答案是装配。[`boot.reb`](../../boot.reb) 里的 `boot-spine` 是代码这条路：登记根上的插件，再为 `"default"` 做 `create-agent-handle`；[`boot-yaml.reb`](../../boot-yaml.reb) 的 `boot-spine-from-config` 拼出一份条目列表，用同一批插件对象挂上去。[`cordis.yml`](../../cordis.yml) 列出 host、session、approval、llm、agents——没有 tools，isolate 插件仍来自 `create-agent-handle`。实验把那份列表倒出来，再用同一句 echo 字符串分别走代码启动和 YAML 启动，两边都回答 `"yaml-parity"`。装配不是第二条脊柱，而是给第一条起名的第二种办法。

## 先叠层，再换人，账本不动

[`profile.reb`](../../profile.reb) 把补丁一层层叠起来：bundle → profile 的 `cordis.patch.reb` → home（`HARNESS_HOME` 或仓库里的 `cordis.patch.reb`）→ CLI `--patch`。`profiles/minimal` 是根文件的 YAML 等价物，`profiles/full` 对得上 `examples/full-chain.yml`。你不必背下补丁语言才肯相信这个顺序——架构文档里的表是规格，`r3 -s boot-yaml.reb --profile minimal --dump-config` 是打印机。

同像热替换（homomorphic reload）是装配在运行时的那一半。cordis-port 加载器里的 `reload-plugin` 做 Fiber 对换；`boot.reb` 里的 `reload-spine-plugin` 先对每个活着的 handle 做 `quiesce-agent`（session 还活着就 `cancel-turn`），再热替换根上的插件，然后 `refresh-agent-refs`——因为依赖 `llm` 的 isolate Fiber 可能已被重建——最后 `carry-inbox`，免得易失队列被丢掉。实验的第一回合 echo `"hello cordis"`；对 [`examples/fixtures/llm-upper.reb`](../../examples/fixtures/llm-upper.reb) 做完 `reload-spine-plugin` 之后，同一场 session 的第二回合是 `"HELLO CORDIS"`。派生历史里同时留着原来的 echo 和那行大写——笔记本没有重置，客人换了。

缺文件时，热替换不会只应用一半。实验的回滚路径返回一份加载器错误 map，下一回合仍是大写（`"STILL ALIVE"`）——失败的热替换留下的还是上一个插件。这和取消时的诚实是同一句话：不要把机器留在一种你叫不出名字的形状里。

`reload-agent-plugin` 是 isolate 范围内的表亲：换掉某一个智能体下的工具插件，根上的 `sessions` / `llm` 和兄弟姐妹智能体都不动。`examples/reload-llm.reb` 是本实验的叙事版，`test/reload-turn-test.reb` 覆盖活回合上的 quiesce。

装配的代价是多了一层间接：一个「bash 没登记」的 bug，原因通常是「你看了 YAML 而没看 `create-agent-handle`」，不是 `cordis.yml` 少写了一行。热替换的代价是：任何把服务对象一直攥过对换的东西都会出错——所以 handle 才被故意刷新。另一种做法——重启进程——随时可用，但总会丢掉内存里的 session，除非设了 `store-dir`。热替换存在的理由是：日志*必须*在新客人手里活下来。

现在整条脊柱都在你手里了：一扇门，一本账，几道闸，一次只问一声的许可，一位客人，一位每步重读的账房先生，私人房间，一份停下的协议，以及一套能换客人却不烧掉账本的装配。概念上的姊妹篇 [`harness-for-everyone`](../../harness-for-everyone/README.md)（《写给所有人的 Harness》）把同一个故事讲了一遍，只是不带实验；内核那本 [`how-cordis-port-works`](../../../cordis-port/how-cordis-port-works/README.md)（《Cordis 的 Rebol 移植是怎样工作的》）解释了 `waterfall`、`isolate`、`reload-plugin` 为什么会作为动词存在。这本书，就是那些动词一直在等的产品。

---

## 动手实验

```bash
cd ch10-assemble-reload/code
bash run.sh
```

预期输出（关键行）：

```text
DUMP-HAS-HOST: #(true)
DUMP-HAS-SESSION: #(true)
CODE-ECHO: yaml-parity
YAML-ECHO: yaml-parity
BEFORE-RELOAD: hello cordis
RELOAD: #(true)
AFTER-RELOAD: HELLO CORDIS
HIST user: hello cordis
HIST assistant: hello cordis
HIST user: hello cordis
HIST assistant: HELLO CORDIS
ROLLBACK: {[LoaderError] reload: file not found: %examples/fixtures/no-such-adapter.reb}
STILL-UPPER: STILL ALIVE
LAB-OK
```

### 试一试

1. 在仓库根目录跑 `r3 -s boot-yaml.reb --dump-config`，再跑 `r3 -s boot-yaml.reb --profile minimal --dump-config`。条目名字应当对得上。然后 `--profile full`，去看完整 profile 多出来的 intercept / llm 配置。
2. 在演示里，第一次换完之后，再用*同一份*大写 fixture 做第二次 `reload-spine-plugin`。第三个回合仍应是大写；热替换不是拨动开关。
3. 成功换完之后，打印 `same? spine/llm spine/default-agent/driver/llm`。两边若分叉，你就找到了一个过期的 handle——`refresh-agent-refs` 本该在 driver 上挡住这件事；热替换之前拷进本地 word 的绑定，则仍会过期。这就是缓存对象的代价。

### 对照真源

| 路径 | 符号 |
|------|--------|
| `boot.reb` | `boot-spine`, `reload-spine-plugin`, `reload-agent-plugin`, `quiesce-agent`, `refresh-agent-refs` |
| `boot-yaml.reb` | `boot-spine-from-config`, `compose-spine-entries`, `make-spine-plugin-map` |
| `profile.reb` | `compose-profile-entries` |
| `cordis.yml` | 根上的条目列表 |
| `examples/fixtures/llm-upper.reb` | 大写 `llm` 插件 |

isolate 插件（tools / shell / agent-loop）故意不出现在根 YAML 里。

<!-- source: appendix/quick-reference.md -->

# 速查

> 本附录供查阅，**不是**阅读路径。先读各章。

## 各章小结（精炼）

| 章 | 一句话小结 |
|----|------------------|
| 01 | 一次 echo 回合已经是一套协议：日志、视图、客人、driver——不是厂商循环。 |
| 02 | `host` 是通往世界的唯一一扇门；tools 和 LLM 适配器向它借用，自己不开门。 |
| 03 | 记忆是冻住的事件账本；`derive-messages` 是账房先生的誊本，不是装订笔记本。 |
| 04 | 工具是四段式的公共行为；只有 `tools-execute` 的内层（或 `host`）可以有副作用。 |
| 05 | 审批是一次性的、缺席即拒绝，asked 与 decided 都写入日志；没有通行证仓库，也没有 UI。 |
| 06 | 模型是客人，返回文本或 tool-call 数据；`enqueue` 排在 echo/script/http 前面。 |
| 07 | 循环每一步都重读日志；resume 不捏造用户行；pre-step 可以耳语。 |
| 08 | 动手的房间隔离；前台（session/llm/host）共享；兄弟姐妹听不见彼此。 |
| 09 | 取消是检查点旗标外加一行 cancelled 日志；空闲时的旗标不得粘住；dispose 会拒绝。 |
| 10 | YAML 与 profile 命名的是同一批插件；热替换换掉客人并刷新 handle；日志留下。 |

## 走过的比喻（核心章）

| 章 | 比喻 |
|----|---------|
| 03 | 装订笔记本，不是聊天气泡；追加即影印；账房先生朗读。 |
| 04 | 安检通道：证件、引擎、海关、广播。 |
| 07 | 每天早晨重读装订笔记本的账房先生；抽屉里没有第二本。 |
| 08 | 旅馆：共享前台，私人迷你吧和电话，父级套房听得见。 |
| 09 | 检查点举手，再写下 cancelled，好让下一位客人不被鬼魂缠住。 |

## 源码地图

```
../host/api.reb           # 第 02 章
../session/api.reb        # 第 03、07 章
../session/json.reb       # 第 03 章
../session/store.reb      # 第 03 章
../tools/api.reb          # 第 04、05 章
../shell/api.reb          # 第 04 章
../approval/api.reb       # 第 05 章
../llm/api.reb            # 第 06 章
../llm/http.reb           # 第 06 章
../agent-loop/api.reb     # 第 01、07、09 章
../scope/api.reb          # 第 08 章
../agent/api.reb          # 第 08、09 章
../boot.reb               # 第 01、10 章
../boot-yaml.reb          # 第 10 章
../profile.reb            # 第 10 章
../cordis.yml             # 第 10 章
```

## Cordis 内核（不在本书）

| 脊柱中的角色 | 内核动词 |
|-------------------|-------------|
| 插件挂载 | `registry/plugin` |
| tools/approval/loop 的 intercept | `events/waterfall` |
| 每个智能体的 tools/shell/loop | `extend` isolate-map |
| 延迟 / 流式等待 | thenable + 调度器 |
| 热替换 | `reload-plugin`（loader） |

见 [Cordis 的 Rebol 移植是怎样工作的](../../../cordis-port/how-cordis-port-works/README.md)。
