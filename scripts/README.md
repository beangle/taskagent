# 构建与打包脚本

| 路径 | 用途 |
|------|------|
| `build_common.sh` | 打包共用：从 `dub.sdl` 读取版本号，清理并执行 release 构建 |
| `build_deb.sh` | 构建 `.deb`（需 Debian 系或 `dpkg-deb`、`fakeroot`） |
| `build_rpm.sh` | 构建二进制 `.rpm`（需 `rpmbuild >= 4.14`、`fakeroot`） |

产物统一输出到 `target/`：

- `target/beangle-task`：release 二进制
- `target/beangle-task_<v>-<r>_amd64.deb`：Debian/Ubuntu 安装包
- `target/beangle-task-<v>-<r>.<arch>.rpm`：Fedora/RHEL 安装包

包内只安装 `/usr/bin/beangle-task`。配置文件路径作为启动参数传入：

```bash
beangle-task path/to/sas.xml
```

版本号取自 `dub.sdl` 的 `version` 字段；也可以通过第一个参数覆盖打包 revision：

```bash
./scripts/build_deb.sh 2
./scripts/build_rpm.sh 2
```
