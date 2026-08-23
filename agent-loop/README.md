# agent-loop

职责：驱动一轮 turn：写 session、问 llm、经 tools waterfall 执行、再问，直到文本回复或步数用尽。

不做什么：不直接 spawn 进程、不实现模型、不解释 bash。

不变量：每一步的模型输入来自 `derive-messages`；工具结果先入日志再进入下一步。
