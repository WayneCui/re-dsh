<!-- 书稿文件之三（第 08–10 章 + 结尾） -->

# 第 8 章 一人一间房：两个智能体的和平共处

![漫画：旅馆大堂——前台（session/llm/host）共用，两条走廊通向各自房间；A 房迷你吧独立，B 房电话独立；套房父钥匙从连通房探出半张脸](comics/09-ch08-hotel.png)

如果 tools、shell、循环都是根上的公共服务，两个智能体就会共用一张登记表、同一面取消旗：在 A 上登记 `whoami`，会改掉 B 跑的东西；取消 A，也就取消了 B；监听 `tools-result`，等于听见所有人。阿粗会说：「一个全局工具箱多省事！」——在第二个智能体出现之前，它确实显得更简单。

harness-spine 的做法：**每个智能体分到一间 isolate 房间，前台共享。**

## 房间与钥匙

`create-agent-handle` 四步造房：

1. **铸钥匙**——`mint-scope-key` 产出一把不透明的对象钥匙（你没法解析它，只能拿着它）；
2. **（可选）认亲**——`bind-scope-parent` 把孩子钥匙挂到父钥匙上；
3. **隔房间**——`extend-agent-iso` 把 `tools`、`shell`、`agent-loop` 三个插件放进 isolate-map，键名 `agent-<label>`——每个智能体**各有一份**；
4. **发钥匙**——钥匙挂进房间 ctx，handle 上的 `tools` 和 `driver` 都从**这间房**里查。

前台（`session`、`llm`、`host`）留在根上：所有智能体共享记忆、共享客人、共享那扇门。

## 事件跟着钥匙走

工具执行广播 `tools-result` 时，带着自己的钥匙（`make-scope-target`）；监听者`scope-admits?` 从派发钥匙沿父链核对——**A 的监听者听不见 B 的动静，兄弟姐妹不能横着偷听**。唯一的例外是父钥匙：实验里铸出 `parent`，用它拉起 `child`，把父钥匙挂到根上——根上的监听者就能听见孩子的广播。**孩子可以向上汇报，这是特性不是漏洞。**

> **你以为**：「智能体 = session」。
> **其实**：两个 isolate 房间可以对着同一个 session id 跑回合（共享记忆、说话人换了账本不换）；也可以 `fork` 出两本账（记忆隔离）。**房间管动手权，账本管记忆，两件事独立配置。**

## 没有笨问题

**问：为什么 YAML 里列的是 host/session/approval/llm/agents，没有 tools？**

答：因为 tools 是**每个智能体的私产**，由 `create-agent-handle` 装进房间，不走根装配。盯着 YAML 问「bash 在哪」，是问错了层——这个「故意不在场」第 10 章还会再考一次。

**问：钥匙为什么要做成不透明对象，一个字符串不是更方便？**

答：字符串会被打印、被猜、被伪造。不透明对象只能被**持有**，而持有关系（谁拿的是谁发的钥匙）正是权限的本义。scope 的路由逻辑因此不必去载荷里翻一个 id。

## 动一动

```bash
cd ../../how-harness-spine-works/ch08-isolate-rooms/code
bash run.sh
```

对答案：`WHO-A: A / WHO-B: B`（同名工具各归各）、`B-HEARD-A: #(false)`（横着偷听失败）、`PARENT-HEARD-CHILD: #(true)`（向上汇报成功）。「试一试」第 3 条用 `reflect/get` 验证：session 从父链解析，tools 则不该。

## 脑力充电站

两间 isolate 都对着 `s1` 跑回合：存在几个 session 对象？几张 `tools` 登记表？

<details><summary>答案</summary>

一个；两张。前台共享所以账本只有一本——四条消息（A 说的、echo、B 说的、echo）在同一个 id 下排队；动手的登记表各房一份。这正是「私人动手、共享记忆」的字面意思。
</details>

## 速记卡

- isolate 三件套：`tools` / `shell` / `agent-loop`，键名 `agent-<label>`；前台三件套：`session` / `llm` / `host`。
- 事件路由靠 scope 钥匙与父链，不靠载荷翻 id。
- 父钥匙听连通房，兄弟姐妹互相隔音。

---

# 第 9 章 停下，但不撒谎

![漫画：赛道上若干检查点，一位跑者举手示意停下；账房先生在账本上郑重写下「cancelled」一行；角落里，一面粘在「空闲」站牌上的旗被 marked 大红叉](comics/10-ch09-cancel-checkpoint.png)

启动一个回合值得庆祝，**停下才是套壳开始撒谎的地方**。`Ctrl-C`、`kill`、回调里抛异常——进程没了，session 里却留下一次没有结果的 `tool-call`，或一段「模型突然哑火」的半截流。下一次誊本把这段没写完的故事当历史，送给新模型：**账本里住进了鬼魂。**

## 协作式取消：一面旗，三层检查，没有第二种取消

`cancel-turn` 只在**回合活着**的时候竖旗（`live-session-id` 是字符串）；driver 空闲时它返回 `none`，**不**留下旗标——一面粘在空闲上的旗，会把下一回合无辜的工作也取消掉。

旗竖起来之后，机器在七处检查点张望：步进循环开头、`step-start` 之后、流结束之后、execute 之前、execute 之后，以及每次 settle 泵调度器的时候（tools 的 `settle/cancel`、LLM 的 stream、host 的 `http-post-stream`——最后那位取消的方式是**杀掉 curl 的 pid**）。任何一处看见旗，回合立即收束：

- 已提议未执行的工具调用，落一条特殊的 `tool-result`：`#[text: "cancelled" cancelled: true]`——**没做完就是没做完，白纸黑字**；
- 回合以 `status: 'cancelled` 收工，旗自动降下。

> **你以为**：取消 = 把正在跑的东西掐死。
> **其实**：取消 = 「在下一个检查点举手」+「在账本上写下 cancelled」。它不撤销已经发生的事（外部 API 已经提交的请求没有两阶段中止），它只拒绝**记下一笔没有发生的成功**。

## 拒绝假装

dispose 之后的 `run-turn` 也不含糊：Fiber 已经不活着，`turn-cancelled?` 直接为真，回合返回 `status: 'disposed`、steps 0、**一行事件都不写**。机器不下线时假装开工，也不下线时假装下线。

## 没有笨问题

**问：一个死循环的工具不理旗，怎么办？**

答：要到它自己返回才看得见旗——协作式取消的天花板。脊柱没法把「对不可打断二进制的一次 `call/wait`」变成事务。它守住的下限是：**宁可让世界慢一点，不让账本脏一点。** 真要硬杀进程？只有当你连 session 一起扔掉时才算诚实。

**问：取消后队列里还没消费的回复去哪了？**

答：原地待命。下一回合照常取用——实验里取消后换新 session echo `"next"`，一切正常。取消不弄脏进程，只诚实了账本。

## 动一动

```bash
cd ../../how-harness-spine-works/ch09-cancel-protocol/code
bash run.sh
```

对答案：`IDLE-CANCEL: _` + `IDLE-FLAG: #(false)`（空闲契约）、`HAS-TOOL-CALL: #(true)` / `HAS-TOOL-RESULT: #(true)` / `HAS-ASSISTANT: #(false)`（提议入账、取消入账、假回答缺席）、`RESULT-TEXT: cancelled`。「试一试」第 3 条连按两次空闲取消，两次都该是 `_`——**旗不许粘住**。

## 脑力充电站

abort 工具的本体其实跑完了并返回了 `"abort-body"`。为什么日志里没有这个字符串？

<details><summary>答案</summary>

取消检查点在「本体返回之后」仍然有效：循环拒绝把一个取消回合的返回值当成正常结果，改写为 `cancelled-tool-result`。本体的产出被扔掉是**故意的**——记录一个「取消后仍然生效的成功」才是撒谎。（另一条延迟路径里，`host/delay` 中被取消的本体根本完不成。）
</details>

## 速记卡

- 取消 = 检查点旗标 + 一行 cancelled，不是异常。
- 空闲取消是空操作；dispose 后的回合 `status: 'disposed`，不写事件。
- 诚实下限：不记没发生的成功；已知上限：外部副作用不可回滚。

---

# 第 10 章 换客人，不烧账本：装配与热替换

![漫画：旅馆楼顶，工人用吊车把一位新客人（大写手套）吊进 201 房，账本前台纹丝不动；旁边叠着四层蛋糕（bundle→profile→home→patch），一层拉杆写着 hot-swap](comics/11-ch10-hot-swap.png)

最后一章把所有零件装回一台机器，并回答收官之问：**客人换了，账本怎么活下来？**

## 装配：给同一台机器起两次名字

harness-spine 的答案是装配。两条路，同一批插件：

- **代码路**：`boot-spine` 按固定次序挂根插件（host → session → approval → llm → agents），再 `create-agent-handle "default"`；
- **YAML 路**：`cordis.yml` 列出同一批条目，`boot-spine-from-config` 拼装挂载。

实验让两种启动方式各跑一句 echo，都回答 `"yaml-parity"`。**装配不是第二条脊柱，而是给第一条起名的第二种办法。**

## 叠层：四个来源的先后

补丁从四层叠下来：**bundle → profile → home（`HARNESS_HOME` 的 `cordis.patch.reb`，或仓库根的）→ CLI `--patch`**。`profiles/minimal` 是根 YAML 的等价物；`profiles/full` 顺手给 session 配上 `store-dir`、给 llm 配上 script 适配器。你不必背下补丁语言——架构文档里的表是规格，`r3 -s boot-yaml.reb --profile minimal --dump-config` 是打印机。

## 热替换：同像热替换的仪式

`reload-spine-plugin` 五步换人，账本不动：

1. **静默**：对每个活着的智能体 `quiesce-agent`（回合开着就先 `cancel-turn`——用第 9 章的诚实协议收尾）；
2. **对换**：内核 `reload-plugin` 卸旧挂新（失败则回滚——失败的热替换留下的还是上一个插件，**缺文件不会装到一半**）;
3. **刷新**：`refresh-agent-refs` 把每个 handle 上的 `tools`/`driver` 重新指到新服务——因为依赖 `llm` 的 isolate Fiber 可能已被重建；
4. **搬运**：`carry-inbox` 把旧 driver 里没消费的信件搬进新 driver；
5. **回执**：同一场 session 的下一回合，echo 变成了 `"HELLO CORDIS"`——**客人换了，账本上上一回合的小写原封不动**。

> **你以为**：换适配器 = 重新赋值一个变量。
> **其实**：变量赋值换不掉 Fiber 换代之前被攥在手里的旧服务对象。所以才有仪式：静默、对换、刷新、搬运——**任何把服务对象一直攥过对换的东西都会出错，handle 被刷新正是为了这个。**

## 收官

现在整条脊柱都在你手里了：一扇门，一本账，几道闸，一次只问一声的许可，一位客人，一位每步重读的账房先生，私人房间，一份停下的协议，一套能换客人却不烧账本的装配。

接下来去哪？

- 想**亲手搭一遍**这台机器 → [《从零构建 harness-spine》](../build-harness-spine-from-scratch/BUILD_HARNESS_SPINE_FROM_SCRATCH.md)；
- 想逐行走源码 → 《harness-spine 是怎样工作的》；
- 想先吃透内核动词（waterfall / isolate / thenable / reload）→ 《Cordis 的 Rebol 移植是怎样工作的》。

## 动一动

```bash
cd ../../how-harness-spine-works/ch10-assemble-reload/code
bash run.sh
```

对答案：`CODE-ECHO / YAML-ECHO: yaml-parity`、`HIST` 四行（小写与大写共存一本账）、`ROLLBACK` 显示 `[LoaderError]` 且 `STILL-UPPER: STILL ALIVE`（回滚成功）。「试一试」第 3 条让你打印 `same? spine/llm spine/default-agent/driver/llm`——`true` 说明刷新真的发生了。

## 脑力充电站

1. 为什么热替换前要先静默所有智能体？
2. 热替换后，谁可能还攥着旧服务对象？

<details><summary>答案</summary>

1. 为了让每个打开的回合都经过第 9 章的诚实收尾（cancelled tool-result、turn-end），而不是在对换瞬间被腰斩——账本不允许「换成一半」的形状。
2. 任何在对换**之前**把 `spine/llm` 之类的服务拷进本地变量的人。handle 会被 `refresh-agent-refs` 刷新，你手里的临时绑定不会——这是缓存对象的代价。
</details>

## 速记卡

- 装配两条路：`boot-spine` / `cordis.yml`，`--dump-config` 验证等价。
- 叠层次序：bundle → profile → home → `--patch`。
- 热替换五步：quiesce → reload（可回滚）→ refresh handles → carry inbox → 下一回合见新客。

---

## 结业典礼

十 章 通关。回头看你学会的不是「某个框架的用法」，而是一组可以搬走的**判断题**：

| 下次有人说…… | 你可以问…… |
|---|---|
| 「存个 messages 数组就行」 | 取消后半截流谁来记？fork 后两份历史怎么不撞车？ |
| 「工具就是个函数」 | 被拒绝的调用有没有广播？测试替身插在哪一层？ |
| 「审批加个布尔」 | 问题死了，答案在哪？两个代码库默认值打架怎么办？ |
| 「模型说了算」 | 它拿什么执行？取消了它知道吗？ |
| 「杀进程就停了」 | session 里那只鬼魂谁清理？ |

每一条的答案都不在 slogan 里，在**账本的结构**里。欢迎带着这本速记卡，去读源码、去写你自己的 harness。

`LAB-OK`
