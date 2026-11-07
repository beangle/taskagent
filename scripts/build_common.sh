#!/bin/bash
# 打包脚本共用：版本号与 release 构建。

# 包版本号以 dub.sdl 的 version 字段为唯一来源，和 mk_artifact.sh 保持一致。
task_package_version() {
  local root="${TASK_HOME:?TASK_HOME not set}"
  local ver
  ver="$(sed -n 's/^version *"\([^"]*\)".*/\1/p' "$root/dub.sdl" | head -n 1)"
  if [ -z "$ver" ]; then
    echo "==========================================================" >&2
    echo "Could not determine version from dub.sdl" >&2
    echo '（期望找到：version "x.y.z"）' >&2
    echo "==========================================================" >&2
    exit 1
  fi
  printf '%s' "$ver"
}

task_prepare_release_build() {
  local root="${TASK_HOME:?TASK_HOME not set}"
  cd "$root" || exit 1
  echo "task: dub clean ..."
  if command -v dub >/dev/null 2>&1; then
    dub clean || true
  fi
  echo "task: removing target/ ..."
  rm -rf "$root/target"
  mkdir -p "$root/target"
  echo "task: dub build --build=release-nobounds --compiler=ldc2"
  dub build --build=release-nobounds --compiler=ldc2
}
