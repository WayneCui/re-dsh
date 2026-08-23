# llm

职责：给定消息和工具表，返回 `text` 或 `tool-call`。

适配器（`llm-plugin` config map，优先级：`enqueue` > `script` > `http-url` > echo）：

| 键 | 行为 |
|----|------|
| （无） | echo 最近一条 user content |
| `script` | 调 `r3 -q <script> <req-file>`；stdout 为 `mold/all` reply |
| `http-url` | `host/http-post` 发送 `mold/all` request，解析 body |

测试仍用 `enqueue`；生产示例见 `examples/tool-pipeline-turn.reb`。

协议：`llm/reply.reb`（request/reply mold）、`llm/script.reb`、`llm/http.reb`。

不做什么：不执行工具、不拥有 session。

不变量：`complete` 只依赖队列 + 入参 + 配置的 adapter；reply 须 `kind: text` 或 `kind: tool-call`（含 `args` map）。
