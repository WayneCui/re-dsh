# tools

职责：工具注册表，以及 **pre → execute → post** 三层 waterfall，最后 `tools-result` emit。

不做什么：不实现 bash、不写 session、不调用 LLM。

## 事件（word!）

| 事件 | 模式 | 参数 | 语义 |
|------|------|------|------|
| `tools-pre-execute` | waterfall | exec, next | `next()` 默认 allow；短路由 `{kind: deny error: ...}` 不跑 body |
| `tools-execute` | waterfall | exec, next | inner 跑工具体 |
| `tools-post-execute` | waterfall | exec, result, next | `next()` 默认 accept；可改 stdout/text 或 block |
| `tools-result` | emit | exec, result | 管道结束后的观察点 |

## 不变量

- 未知工具：不进 inner，仍 emit `tools-result`。
- pre deny：不调用 `tools-execute` inner。
- dispose 当前 fiber 时登记撤回。
