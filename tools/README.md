# tools

职责：工具注册表，以及 `tools-execute` waterfall（inner 才跑工具体）。

不做什么：不实现 bash、不写 session、不调用 LLM。

不变量：dispose 当前 fiber 时登记撤回；未知工具不跑 inner，返回 ok: false。
