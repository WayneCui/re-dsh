# shell

职责：把名为 `bash` 的工具登记到当前 ctx 的 `tools`，经 `host/run-command` 执行。

不做什么：不被 loop 直接调用；不写 session。

不变量：只认 args.command 字符串；缺少 command 时不碰 host。
