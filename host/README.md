# host

职责：内核之外的 I/O 出口（shell、http、调度器 delay）。

不做什么：不解释工具名、不写 session、不调用 LLM、不解析 LLM 行协议。

## API

| 方法 | 说明 |
|------|------|
| `run-command` | 真实 `call/wait/shell` |
| `http-get` | `url!` / `file!` |
| `http-post` | curl POST，整包 body |
| `http-post-stream/on-line/cancel` | 按行推送；`file!` 读 fixture；`url!` 用 `curl -N` + pid kill |
| `delay` / `settle` | 确定性调度器 |

不变量：`http-post-stream` 在每行 / 每个 poll tick 检查 `cancel-obj/call`；取消时对 url 路径 `kill` curl。
