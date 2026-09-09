# Third-party packages

Vendored copies used when GitHub SPM resolve is unreliable.

| 目录 | 来源 | 版本 |
| --- | --- | --- |
| [SFSafeSymbols](SFSafeSymbols) | https://github.com/SFSafeSymbols/SFSafeSymbols | 6.2.0 |

`app/example` 通过本地路径 `../../third_party/SFSafeSymbols` 引用。升级时替换该目录内容，并确认 App 仍能编译。
