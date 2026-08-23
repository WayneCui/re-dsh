# llm

职责：给定消息和工具表，返回 `text` 或 `tool-call`。默认 echo；测试可 `enqueue` 脚本回复。

不做什么：不执行工具、不拥有 session、不读 host。

不变量：`complete` 纯函数于当前队列 + 入参；echo 只回放最近一条 user content。
