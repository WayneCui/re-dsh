# 写给所有人的 Harness

Harness-spine 是一套智能体运行时。可它最先要守住的不是技术，而是一句关于诚实的承诺。一台能说话、能动手、能记住、也能被停下的机器，不许在这四件事上互相撒谎。模型不该装作自己拥有这个世界。模型看见的那串聊天，不该装作就是全部记录。工具被拒绝之后，不该装作自己已经跑过。停下，也不该装作已经停完。

这就是脊柱。它挂在 Cordis 用来安插件、管 Fiber（**一次存活的租约**）、做清理的同一套内核上——在这里，是 Rebol 语言的移植版 [cordis-port](file:///Users/wayne/2-learning/agent-projects/cordis-port)。Cordis 问的是：这么多活动的零件，怎么共享一个世界，而不把它撕开。Harness-spine 问得更窄，也更危险：其中一块零件若被允许去*动手*，怎样还能让其余零件对「发生了什么」保有同一幅连贯的图景。

这本小册子写给想先抓住这个想法、再去碰机器的读者。我们仍会指向真实源码，因为一套 harness 若只剩比喻，就没什么好看的。只是我们把它读成一扇门、一本账、一次许可、一次停下的故事，而不是一本服务名词词典。

读的时候只记一条实用规矩：名字一旦显得沉，就把它翻回人话。`host` 说的是真实世界。`session` 说的是记录。`tools` 说的是证人。`approval` 说的是许可。`llm` 说的是一位客人。`agent-loop` 说的是一个回合。`scope` 说的是一件事属于哪一间房。问题清楚了，名字也就不再冷。

```text
小小的承诺
   -> 不要让模型拥有世界
   -> 不要把一场对话当成这场对话的全部记录
   -> 不要让工具在没有证人的情况下跑起来
   -> 不要把许可当成装饰
   -> 不要碰巧共用一间房
   -> 不要假装停下已经停完
   -> 不要靠一厢情愿的硬编码来装配
   -> 不要用热替换去践踏还活着的对话
```

这个项目的技术生活，在 `examples/` 下那些能跑的例子里，也在测试里。这一版更温和。它问的是：harness-spine 想造出怎样一种智能体世界，以及一条脊柱为什么会对「小心」这件事这么认真。

---

## 第一章 智能体为什么不是套在模型外面的循环？

想象一个智能体，最省事的办法是把它想成一个有礼貌的 while 循环。问模型。它要命令，就跑命令。把输出贴回去。再问，直到它说出人话。这幅图好看，因为它像人真在做事：想，做，看，再想。

客气维持不了多久。所谓「对话」很快变成一个事后还能改的数组。第二个智能体继承了第一个的 shell。取消等于 `kill -9` 再加一点希望。热替换等于重启，重启完就忘了你为什么在这儿。这些失败都不像模型的问题。它们像世界已经错位，模型却还在若无其事地说话。

Harness-spine 在门口就拒绝当一个文件。在 [ARCHITECTURE.md](file:///Users/wayne/2-learning/agent-projects/harness-spine/ARCHITECTURE.md) 里，产品是一条有方向的链：`host` 管真实 I/O，`session` 管日志，`approval` 管许可，`tools` 管有证人的调用，`llm` 管回答，`agent-loop` 管一个回合，`agent` 管还活着的身体。[boot.reb](file:///Users/wayne/2-learning/agent-projects/harness-spine/boot.reb) 并不另起一套内核。它把这些插件挂到一个 Cordis 的 context 上，等共享服务都在了，才去创建默认的智能体 handle。

顺序可以在 [boot-spine](file:///Users/wayne/2-learning/agent-projects/harness-spine/boot.reb#L133-L165) 里看见。根上拿到的是 `host`、`session`、`approval`、`llm` 和 `agents`。默认智能体的 tools 和 loop 并不挂在那根上。它们稍后才从 `create-agent-handle` 来。这已经是一件穿着启动顺序外衣的伦理选择：共享的世界先装配好；动手的身体是这个世界的客人，不是它的主人。

## 小结

Harness-spine 最先保护的不是聪明，而是一种权利：说话、动手、记住、停下，各住各的地方。常见的误会是把脊柱想成「带了插件的聊天机器人」。它更接近一组房间，每间只干一件事，好让谁也不能冒充谁。

---

## 第二章 为什么要把真实世界关在一扇门后面？

一旦承认智能体可以动手，下一个诱惑就是让正握着对话的那一层直接摸操作系统。循环可以去调 `shell`。模型适配器可以去 `curl`。工具可以用空转来睡觉。这些捷径在演示里都好用。它们也都会让取消、测试和诚实变得更难——因为真实世界从此有了好几扇非正式的门。

这就是 [host/api.reb](file:///Users/wayne/2-learning/agent-projects/harness-spine/host/api.reb) 存在的原因。`host` 是 I/O 出口：`run-command`、`http-get`、`http-post`、`http-post-stream`、`delay`。它不知道工具是什么。它不写 session 事件。它不解析模型的回复。在 [run-command](file:///Users/wayne/2-learning/agent-projects/harness-spine/host/api.reb#L96-L113) 里，一个字符串变成一次等待完毕的 shell 调用，回来时带着 `ok`、`code`、`stdout` 和 `stderr`。没有更多了。

名为 `bash` 的工具并不是循环的朋友。在 [shell/api.reb](file:///Users/wayne/2-learning/agent-projects/harness-spine/shell/api.reb#L30-L38) 里，`shell-plugin` 注入 `tools` 和 `host`，登记一份名叫 `bash` 的规格，然后离开。命令字符串若缺失，它碰都不碰 `host`。循环稍后会调用 `tools/execute`。它自己不会去拉起进程。这层拐弯就是目的。副作用应当发生在一个地方，或者根本不发生。

这会少一点亲近感。单文件的智能体摸起来更贴着金属。脊柱宁愿让你感觉到一扇门在关上，也不愿你在一次失败的取消之后才发现：有个 curl 进程，还在往一场已经正式结束的对话里写字。

## 小结

Harness-spine 把真实世界当成你要出门才去的地方，而不是每一层都可以随手摸一把的东西。容易读错的读法是：「`host` 不过是个 shell 帮手。」更严的读法是：动手若是一种特权，它就需要单独一扇门，好让停下和测试有地方站稳。

---

## 第三章 记忆为什么是日志，而不是聊天记录？

多数聊天产品训练我们，把记忆想成界面上那一排数组。消息往后面加，有时改一改，token 预算紧了就丢掉几条。那是视图。把它当成地基是危险的，因为视图可以重画，画得让人舒服。日志不能。

在 [session/api.reb](file:///Users/wayne/2-learning/agent-projects/harness-spine/session/api.reb) 里，一次 session 是只许追加的事件日志。`append-event` 校验类型，把载荷快照下来以免事后改写历史，提交这一行，发出 `session-event`，必要时再刷到磁盘。快照在 [json.reb](file:///Users/wayne/2-learning/agent-projects/harness-spine/session/json.reb#L57-L63)：存下来的是一份 JSON 安全的拷贝，不是你手里还握着的那个活对象。

模型看见的不是那本日志。`derive-messages` 是只读投影。连续的 `assistant-chunk` 会折成一轮助手发言。若后面跟上最终的 `assistant-message`，chunk 就让路：写完的句子才是真相。这条规则公开写在 [derive-messages](file:///Users/wayne/2-learning/agent-projects/harness-spine/session/api.reb#L368-L445)。工具调用和工具结果各自成行。审批事件可以坐在同一本日志里，而不必假装自己是聊天。

这就是 `fork` 会把前缀拷进一个新 id、再让两条枝各自生长的原因；也是 `open` 能从 `store-dir` 恢复一次 session、并且投影出同样消息的原因。对话不是循环肚子里的缓存。它是循环必须重读的记录。代价是仪式感。回报是：谁也不能靠改过去，来让后来的人怀疑自己究竟看见过什么。

## 小结

Harness-spine 先记下发生了什么，再在账本上面画一场对话。常见错误是把 `derive-messages` 当成记忆本身。它是视图。记忆是日志；视图是客人被允许看见的那一层。

---

## 第四章 为什么每个工具都要过几道门？

若工具只是函数，诚实的实现就是调用它。Harness-spine 拒绝这份客气。一次工具调用是公共行为。它可以在发生前被拒绝，在发生后被改写，也可以被没跑过它的人看见。这是不同的工作，所以不能塞进同一个回调。

在 [tools/api.reb](file:///Users/wayne/2-learning/agent-projects/harness-spine/tools/api.reb) 里，`execute` 是三层 waterfall（**分层接力的钩子链**），然后再 emit。`tools-pre-execute` 可以 `allow`、`deny` 或 `ask`。过了这一关，`tools-execute` 才跑本体。`tools-post-execute` 仍可以改写 stdout，或挡住结果。然后发出 `tools-result`，让系统其余部分看见一份冻住的结局。连未知的名字也不会蒸发。它仍会发出一次 deny 结果。登记表上的空缺，不许变成记录上的空缺。

登记本身也不是一张便利贴。`register` 挂上 Fiber 的 `effect`，拥有它的 Fiber 被 dispose 时，工具名会被撤回。这是 Cordis 的清理，出现在看起来像字典的地方。工具表是一份租约，不是一张写上就永远属于全世界的表。

代价是「直接跑」不再是一行代码。收获是：策略、执行、观察可以彼此不同意，却不必伪造结局。预拒绝永远到不了内层本体。缺失的工具仍会留下证人。

## 小结

这里的工具不是你碰巧能调用的函数。它是必须被允许、被执行、被记录的公共行为，而且是三个分开的时刻。常见误会是听见 waterfall，就想起中间件那套时髦说法。在这套设计里，waterfall 是脊柱用来防止动手变成私下副作用的办法。

---

## 第五章 为什么动手之前先要问一声？

工具有了门，许可还得有个住的地方。许多系统把它当成界面问题，或当成人类点过头就永远有效的通行证。Harness-spine 没那么信任。审批是一道接缝，不是一款产品。它没有给人点的窗口，也没有 `allow-always` 仓库。没人回答，就缺席即拒绝。

在 [approval/api.reb](file:///Users/wayne/2-learning/agent-projects/harness-spine/approval/api.reb) 里，`request` 在未打开的回合外甚至不会跑。听起来挑剔，直到你看见它挡住了什么：一场并不在发生的对话，却有工具来要许可。回合之内，服务先追加 `approval-asked`，然后要么因策略是 `never` 而拒绝，要么去问 `approval-request` 这条 waterfall。默认的内层答案是 `unavailable`。随后追加 `approval-decided`。两件事都坐在 session 日志里，许可因此是历史的一部分，不是侧栏里的一句耳语。

工具到达这道接缝有两条路。规格上可以带 `approval: 'ask`。`tools-pre-execute` 监听者也可以返回 `{kind: ask}`。在 [resolve-approval-ask](file:///Users/wayne/2-learning/agent-projects/harness-spine/tools/api.reb#L50-L79) 里，没有审批服务、没有 session id、拒绝、取消、不可用，全部变成 deny 结果。只有 `allowed-once` 让本体跑。这个名字在干活：一次，不是永远。

脊柱让人觉得严厉，有一处就在这里。它宁愿让工具失望，也不愿虚构一个点了头的人。

## 小结

Harness-spine 里的许可，是一次当众提出的、发生在活着的回合里的问题；失败的意思就是：不行。容易读错的读法是「approval 是设置里的复选框」。正确的读法是：对世界动手，本就该可打断、可听见，并且稍微有一点不方便。

---

## 第六章 为什么不让模型当家？

把智能体建成以语言模型当主角，很容易。其余都成布景：一段提示词、一套工具、一份模型正在「使用」的逐字稿。Harness-spine 把它倒过来。模型是客人。它拿到消息和工具规格。它返回文本或一次工具调用。它可以流式吐出增量。它不写日志。它不执行 bash。它不拥有 session。

在 [llm/api.reb](file:///Users/wayne/2-learning/agent-projects/harness-spine/llm/api.reb) 里，`complete` 和 `stream` 共用 `resolve-reply`。适配器是一架又短又严的梯子：先是测试队列（`enqueue`），然后是 `script`，然后是 `http-url`，再不行就把最近一条用户内容原样送回去。HTTP 流式有自己的按行协议：增量，加上最后一行 `kind`，并且可以中途中止。没有 HTTP 流的时候，`stream` 照样接受 sink 和 cancel 对象，好让脊柱其余部分不必关心是哪一个适配器在回答。

决定这些增量对历史意味着什么的，是循环，不是模型。在 [agent-loop/api.reb](file:///Users/wayne/2-learning/agent-projects/harness-spine/agent-loop/api.reb#L382-L401) 里，每一块流式 chunk 先成为一行 `assistant-chunk`，然后才落下完整的 `assistant-message` 或一次 `tool-call`。你把模型拔掉，日志还是日志。你换掉适配器，客人换了；房子没有换。

少了一点浪漫。收获是：「模型这么说的」永远不许变成「所以它发生了」。

## 小结

这里的语言模型是你可以打断的神谕，不是拿着大楼钥匙的经理。常见错误是把 `llm` 当成智能体。智能体是回合、日志和那些门。`llm` 是在某一步被提问的那道声音。

---

## 第七章 为什么一个回合是自己跟自己说话？

一次模型调用还不是智能体。智能体是：答案可能是行动，行动必须被说回同一场对话，而下一问不许记得一份私下的事件版本。用本地数组很容易假造这个循环。Harness-spine 拒绝假造。

在 [run-turn-core](file:///Users/wayne/2-learning/agent-projects/harness-spine/agent-loop/api.reb#L286-L451) 里，一个回合从写下 `turn-start` 开始。它可能领取 inbox（**收件箱**）里的消息，写成落进日志、抹不掉的 `user-message` 行。若不是 resume，它也会写下调用方的用户文本。然后一步一步用 `sessions/derive-messages` 重建模型输入。没有旁路缓存。`agent-pre-step` 可以改写或拒绝这份提案。`agent-request` 仍可以改消息、改工具表，甚至改用哪一个 `llm` 对象。然后才跑 `stream`。工具调用在执行前先入日志；工具结果在下一步之前先入日志。文本回复结束回合。步数太多则以 `max-steps` 结束。

`resume-turn` 是同一台机器，只是没有新的用户句子。热替换之后、取消之后、或一条还挂着的工具结果之后，这件事要紧。对话从日志继续，而不是从上一进程还留在内存里的东西继续。

inbox 是外部世界加入的方式，却不必在墙上打洞。`followup` 等到下一回合。`steer` 和 `inject` 等到下一步。领取下来的文本变成普通的用户消息。模型从来收不到秘密通道。它只看见日志愿意投影出来的东西。

## 小结

一个回合是脊柱通过日志跟自己说话：写，重读，问，也许动手，再写。常见误会是以为循环「拥有」这些消息。它没有。它每一步都必须向 session 打听：这场对话此刻是什么。

---

## 第八章 为什么每个智能体都要有自己的房间？

若两个智能体共用一张工具表，它们就共用一个关于 `bash` 的想法、同一套预执行策略，以及一次踩到对方登记的机会。若它们完全不共享事件，父级就看不见孩子做了什么。这两种切开，Harness-spine 都要：私人的动手房间，共享的记忆和声音，以及知道自己从哪间房出来的事件。

这就是 [create-agent-handle](file:///Users/wayne/2-learning/agent-projects/harness-spine/scope/api.reb#L132-L168) 做的事。它铸造一把不透明的 scope 钥匙，可选地绑上父级，然后 `extend` 根，让 `tools`、`shell`、`agent-loop` 在每个智能体自己的标签下 isolate（**隔离**）。这三个插件装在隔离后的 context 上。`sessions` 和 `llm` 留在根上。handle 是一个对象，它的 `run-turn` 和 inbox 方法委托给当前的 `driver`，所以后来的热替换可以换掉循环，而不强迫调用方去找一个新对象。

事件用这把钥匙当过滤器。[make-scope-target](file:///Users/wayne/2-learning/agent-projects/harness-spine/scope/api.reb#L113-L119) 带着一个 `filter`：当派发钥匙落在监听者的祖先链上，就放行。没有 scope 的监听者听见所有人。子事件可以冒泡到父级。兄弟姐妹不能靠站在旁边偷听。`tools-result` 和 `session-event` 走这条路，于是父级的房间可以旁观，而不必共用工具箱。

代价是：再也没有一个全局唯一的 tools 服务。一个消失的 `bash` 也许只是属于另一个智能体。回报是：动手可以是本地的，记住和说话仍可以是大家共用的东西。

## 小结

这里的智能体是一间私人工坊，挂在共享的图书馆和共享的声音上。容易读错的读法是「一个进程，所以一张工具表」。正确的读法是：动手的东西应当隔离；记住和说话的东西仍可共享——只要事件知道自己离开的是哪间工坊。

---

## 第九章 为什么停下和启动一样要紧？

启动智能体是演示喜欢的部分。停下才决定别人还能否信任这套系统。若取消的意思是「我们拔了插头」，日志就会在沉默里结束，curl 可能还在跑，下一回合只好猜。Harness-spine 把停下当成协议，而不是电闸。

`cancel-turn` 并不杀死世界。在 [agent-loop/api.reb](file:///Users/wayne/2-learning/agent-projects/harness-spine/agent-loop/api.reb#L258-L267) 里，若有活着的 session，它会置上 `cancel-requested`；空闲时返回 `none`，免得一个过期的取消标志去纠缠下一回合。循环和 tools 的 `settle` 助手在调度器的每个节拍检查这个标志。LLM `stream` 的 cancel 对象问的是同一个问题。`host/http-post-stream` 每一行、每一次轮询都检查，并会 `kill` 掉 curl 的 pid。工具若被夹在半途，日志仍会收到一条文本为 `cancelled` 的 `tool-result`。回合以 `status: cancelled` 结束。对话被允许知道自己被打断了。

Dispose 对顺序更严。在 [agent/api.reb](file:///Users/wayne/2-learning/agent-projects/harness-spine/agent/api.reb#L59-L70) 里，`dispose` 先调用 `cancel-turn`，发出 `agent-disposed`，从活表里拿掉 handle，这才释放隔离的 Fiber。此后 `run-turn` 和 `resume-turn` 返回 `status: disposed`。[shutdown-spine](file:///Users/wayne/2-learning/agent-projects/harness-spine/boot.reb#L23-L36) 先 dispose 每一个活着的智能体，再 dispose 根 Fiber。清理是一段顺序，不是指望垃圾回收会注意到。

这是协作式的，不是抢占式的。一个永不回到 `settle` 的工具本体，仍可以无视那个标志。脊柱对这个限度是诚实的。它不会把没有的急停开关卖给你。它卖给你的是检查点、记录、以及操作的次序。

## 小结

停下是一个回合之真相的一部分。常见错误是把取消当成不耐烦用户的实现细节。在这里它是一句承诺：打断应当留下连贯的日志，在检查点允许的范围内关上通往真实世界的门，并且在身体被要求离开之后，拒绝继续动手。

---

## 第十章 为什么要装配脊柱，而不是一次写死？

脊柱若是一组房间，总还得有人摆家具。天真的办法是把 `boot-spine` 写死，然后管它叫产品。这在你想要一台更小的机器、一层本地叠层、或一次不扔掉对话的插件替换之前，都好用。装配不是打包。它是一个活着的系统承认：自己会被装配不止一次。

[boot-spine](file:///Users/wayne/2-learning/agent-projects/harness-spine/boot.reb#L133-L165) 是代码形状的门：按固定顺序 `registry/plugin`，然后一个默认智能体。[boot-yaml.reb](file:///Users/wayne/2-learning/agent-projects/harness-spine/boot-yaml.reb) 是文件形状的门。[cordis.yml](file:///Users/wayne/2-learning/agent-projects/harness-spine/cordis.yml) 列出根上的插件，并在注释里说明它不会列出什么：tools、shell、agent-loop 仍来自 `create-agent-handle`。Profile 走得更远。在 [profile.reb](file:///Users/wayne/2-learning/agent-projects/harness-spine/profile.reb#L29-L54) 里，层是这样叠的：bundle，然后 profile 补丁，然后 home（`HARNESS_HOME/cordis.patch.reb` 或仓库里的 `cordis.patch.reb`），然后 `--patch`。`profiles/minimal` 对应根上的 YAML。`profiles/full` 对应更丰富的示例链。活着的世界是组合后的条目列表，不是你碰巧先打开的那份文件。

热替换是人还在楼里的时候，装配再来一次。[reload-spine-plugin](file:///Users/wayne/2-learning/agent-projects/harness-spine/boot.reb#L103-L131) 先请每一个活着的回合取消，再通过 Cordis 的 `reload-plugin` 换掉根上的插件（例如 `llm`），然后刷新每个智能体 handle 上的 `tools` 和 `driver`，并把尚未处理的 inbox 带过去。[reload-agent-plugin](file:///Users/wayne/2-learning/agent-projects/harness-spine/boot.reb#L83-L101) 在一处 isolate 下做同样的事，根上的服务和 session 日志不动。新插件若站不住，旧的仍留着。[reload-llm.reb](file:///Users/wayne/2-learning/agent-projects/harness-spine/examples/reload-llm.reb) 里的演示几乎直白：同一场 session，新的客人，历史还在，文件缺失就回滚。

代价是：「这个程序」不再是你可以从 `main` 读完的单一故事。收获是：配置、叠层、热替换变成同一类动作——摆好房间，却不假装对话是今天才开始的。

## 小结

脊柱是装配出来的，因此也可以再装配一次。容易读错的读法是：YAML 是更好看的 `boot-spine`，热替换是开发者的方便。更好的读法是：两者都是改机器而不改写机器本应尊重的那份记录。

---

## 收尾

若从符号后退一步，harness-spine 是一套关于「动手时仍要克制」的运行时。它不假定模型该拿着钥匙，不假定聊天窗口就是够用的记忆，不假定一次函数调用就是够用的工具，不假定许可可以是一张便利贴，不假定两个智能体会碰巧共用一间工坊，也不假定停下会自己收拾干净。所以它会显得严厉。严厉换来更温和的结果：有东西在说话、动手、记住或停下时，其余的不必去猜哪一个故事是真的。

这也是脊柱值得慢慢读的原因。表层之下，它不只在教你怎么把智能体接起来。它在教：一旦程序被允许触摸世界，什么样的承诺才值得许下。

若这本小册子做完了它的工作，这套运行时现在应当少一点像一堆 Rebol 服务，多一点像一套给一位不稳的客人定下的社交规矩。停在这里正好。等问题真正活起来，例子和测试可以接手。
