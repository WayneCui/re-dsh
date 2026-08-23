# harness-spine 模块地图

脊柱改写：session 日志 + tools waterfall + agent-loop + 一个 LLM + 一个 shell。
插件用 `registry/plugin` 装配。没有 profile / bundle / HMR。

## 依赖 DAG

```
cordis-port (kernel)
  -> host          真实 I/O 出口（shell / 可选 http / delay）
  -> session       只追加的事件日志；derive-messages 是视图
  -> tools         注册表 + pre/execute/post waterfall + tools-result emit
       -> shell    把 bash 登记到 tools，经 host 执行
  -> llm           complete(messages, tool-specs)；echo 或脚本
  -> agent-loop    一轮 turn：写日志、问模型、跑工具、再问
boot 只做装配，不含业务。
```

## 模块

| 切片 | 单一职责 | 不做什么 |
|------|----------|----------|
| host | 把 shell/http/delay 留在内核之外 | 不解释工具、不写 session |
| session | 追加事件并投影模型可见消息 | 不跑模型、不执行工具 |
| tools | 登记工具并通过 waterfall 调用 | 不拥有 bash 实现、不写日志 |
| llm | 给定消息和工具表，返回 text 或 tool-call | 不执行工具、不拥有 session |
| shell | 作为 tools 上的一个 `bash` 规格 | 不直接被 loop 调用 |
| agent-loop | 驱动 turn/step | 不直接 spawn 进程 |

## 不变量

- 模型可见内容必须能从 session 事件重建（derive-messages 只读日志）。
- 工具副作用只发生在 `tools-execute` waterfall 的 inner，或经 host 出口；pre/post 可拒绝或改写结果。
- 每个 agent 的 tools 用 `isolate 'tools` 隔开；session 与 llm 留在根上共享。
- host 不 import 上层切片。

## 内核契约（cordis-port）

- waterfall 的 inner / listener 可以返回 thenable；loop 用 `thenable-wait` 取就绪值。
- 服务查找走 `reflect/get`，没有 Proxy。
