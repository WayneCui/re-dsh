# llm

职责：给定消息和工具表，返回 `text` 或 `tool-call`；可选流式 `stream` 推送文本 delta。

适配器（`llm-plugin` config map，优先级：`enqueue` > `script` > `http-url` > echo）：

| 键 | 行为 |
|----|------|
| （无） | echo 最近一条 user content |
| `script` | 调 `r3 -q <script> <req-file>`；stdout 为 `mold/all` reply |
| `http-url` | `url!`：curl POST；`file!`：本地 fixture。`complete` 整包解析；`stream` 走行协议 |

## API

| 方法 | 说明 |
|------|------|
| `complete messages tool-specs` | 一次性取 reply |
| `stream/on-chunk/cancel ... sink cancel` | 推送 delta；HTTP 路径可中途 abort |
| `enqueue reply` | 测试队列；text 可带 `chunks: [string!...]` |

## HTTP 流式行协议

每行一个单行 `mold/all` map：

```
#(map! [ delta: "hel" ])
#(map! [ delta: "lo" ])
#(map! [ kind: text text: "hello" ])
```

有 `delta` 则 `sink/call`；有 `kind` 则为最终 reply。无最终行时拼接 delta 成 text。

不做什么：不执行工具、不拥有 session、不写 `assistant-chunk`（由 agent-loop sink 写日志）。

不变量：`complete` / `stream` 只依赖队列 + 入参 + adapter；abort 时 reply 可带 `cancelled: true`。
