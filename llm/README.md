# llm

职责：给定消息和工具表，返回 `text` 或 `tool-call`；可选流式 `stream` 推送文本 delta。

适配器（`llm-plugin` config map，优先级：`enqueue` > `script` > `http-url` > echo）：

| 键 | 行为 |
|----|------|
| （无） | echo 最近一条 user content |
| `script` | 调 `r3 -q <script> <req-file>`；stdout 为 `mold/all` reply |
| `http-url` | `host/http-post` 发送 `mold/all` request，解析 body |

## API

| 方法 | 说明 |
|------|------|
| `complete messages tool-specs` | 一次性取 reply |
| `stream/on-chunk messages tool-specs sink` | 对 text reply 调 `sink/call text`，再返回与 `complete` 相同的 reply |
| `enqueue reply` | 测试队列；text 可带 `chunks: [string!...]` |

不做什么：不执行工具、不拥有 session、不写 `assistant-chunk`（由 agent-loop 的 sink 写日志）。

不变量：`complete` / `stream` 只依赖队列 + 入参 + adapter；reply 须 `kind: text` 或 `kind: tool-call`（含 `args` map）；无 `chunks` 时 text 流式发一整段。
