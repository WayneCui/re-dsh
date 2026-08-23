# host

职责：内核之外的 I/O 出口（shell、可选 http、调度器 delay）。

不做什么：不解释工具名、不写 session、不调用 LLM。

不变量：`run-command` 走真实 `call/wait/shell`；`delay` 只推进确定性调度器，不睡墙钟。
