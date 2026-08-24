# harness-spine 模块地图

脊柱改写：session 日志 + tools waterfall + agent-loop + 一个 LLM + 一个 shell。
插件用 `registry/plugin` 装配。没有 profile / bundle / HMR。

## 依赖 DAG

```
cordis-port (kernel)
  -> scope         per-agent opaque key + event filter carrier
  -> host          真实 I/O 出口（shell / 可选 http / delay）
  -> session       追加事件日志（硬化 payload）+ replay + fork + 可选 store-dir 落盘；derive-messages 是视图
  -> approval      一次性审批 seam；tools `ask` 决策路由
  -> tools         注册表 + pre/execute/post waterfall + tools-result emit
       -> shell    把 bash 登记到 tools，经 host 执行
  -> llm           complete / stream(messages, tool-specs)；enqueue / script / http / echo
  -> agent-loop    一轮 turn：写日志、流式问模型、跑工具、再问；resume-turn 无新 user
  -> agent         live 注册表：create / dispose / list；agent-created / agent-disposed
boot / boot-yaml 只做装配，不含业务。
```

装配有两条入口：

- `boot.reb` → `boot-spine`：代码里直接 `registry/plugin`
- `boot-yaml.reb` → `boot-spine-from-config`：读 `cordis.yml`（+ 可选 `cordis.patch.reb`），经 cordis-port `include` + `loader` 挂载；`r3 -s boot-yaml.reb --dump-config` 打印解析后的 entry 列表

Agent isolate 插件（tools / shell / agent-loop）仍由 `create-agent-handle` 安装，不进根 YAML。

## 模块

| 切片 | 单一职责 | 不做什么 |
|------|----------|----------|
| scope | mint/bind scope key，`make-scope-target` 路由 | 不持有 session/tools |
| host | 把 shell/http/delay 留在内核之外 | 不解释工具、不写 session |
| session | 追加事件、fork 分支、投影消息（chunk 折叠）；可选文件 backend | 不跑模型、不执行工具 |
| approval | `request` / `approval-policy`；配对 audit 事件 | 无 grant store、无内置 UI |
| tools | 登记工具并通过 waterfall 调用 | 不拥有 bash 实现、不写日志 |
| llm | `complete` / `stream`；返回 text 或 tool-call | 不执行工具、不拥有 session |
| shell | 作为 tools 上的一个 `bash` 规格 | 不直接被 loop 调用 |
| agent-loop | `run-turn` / `resume-turn` / `cancel-turn`；dispose 后拒绝 | 不直接 spawn 进程 |
| agent | 登记 live agent；create / dispose / lookup | 不驱动 turn、不建 session |

## 不变量

- 模型可见内容必须能从 session 事件重建（derive-messages 只读日志）；`assistant-chunk` 折叠进 assistant，有 `assistant-message` 时以其为准；配置 `store-dir` 时可跨进程 `open` 恢复；`fork` 后分支互不污染。
- 工具副作用只发生在 `tools-execute` waterfall 的 inner，或经 host 出口；pre/post 可拒绝或改写结果。
- 每个 agent = `isolate 'tools` + scope key；session 与 llm 留在根上共享。
- `agents/dispose` 先 `cancel-turn`，再卸 isolate fiber；`run-turn` / `resume-turn` 对 inactive fiber 返回 `status: disposed`。
- turn 取消合作式：`cancel-turn` 置位；loop 与 tools `settle/cancel`（meta `cancel-check`）每 tick 检查；取消写 `cancelled` tool-result。
- `tools-result` / `session-event` 按 scope 路由；父 scope 可收到子 agent 事件。
- host 不 import 上层切片。

## 内核契约（cordis-port）

- waterfall 的 inner / listener 可以返回 thenable；loop / tools 用 settle（可带 cancel）取就绪值。
- 服务查找走 `reflect/get`，没有 Proxy。
