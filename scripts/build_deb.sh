#!/bin/bash
# Debian/Ubuntu 打包脚本。需在 Debian 系系统运行，或安装 dpkg：apt install dpkg-dev fakeroot
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
export TASK_HOME="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$TASK_HOME"

set -e -o pipefail
# shellcheck source=build_common.sh
source "$SCRIPT_DIR/build_common.sh"

ferror() {
  echo "==========================================================" >&2
  echo "$1" >&2
  echo "$2" >&2
  echo "==========================================================" >&2
  exit 1
}

E=0
LIST=""
fcheck() {
  if ! command -v "$1" >/dev/null 2>&1; then
    LIST=$LIST" "$1
    E=1
  fi
}
fcheck dpkg-deb
fcheck fakeroot
fcheck strip
fcheck dub
if [ $E -eq 1 ]; then
  ferror "Missing commands on your system:" "$LIST"
fi

task_prepare_release_build

MAINTAINER="duantihua <duantihua@163.com>"
VERSION=$(task_package_version)
REVISION="1"
[[ -n "$1" ]] && REVISION="$1"
DESTDIR="$TASK_HOME/target"
ARCH="amd64"
DEBFILE="beangle-task_${VERSION}-${REVISION}_${ARCH}.deb"
PKGDIR="$DESTDIR/beangle-task_${VERSION}-${REVISION}_${ARCH}"

rm -f "$DESTDIR/$DEBFILE"
rm -rf "$PKGDIR"

mkdir -p "$PKGDIR/usr/bin"
cp -f "$TASK_HOME/target/beangle-task" "$PKGDIR/usr/bin/beangle-task"
strip --strip-unneeded "$PKGDIR/usr/bin/beangle-task"
chmod 0755 "$PKGDIR/usr/bin/beangle-task"

mkdir -p "$PKGDIR/DEBIAN"
cat > "$PKGDIR/DEBIAN/control" << EOF
Package: beangle-task
Version: ${VERSION}-${REVISION}
Section: utils
Priority: optional
Architecture: ${ARCH}
Maintainer: ${MAINTAINER}
Homepage: https://github.com/beangle/task
Depends: libc6
Description: Beangle task agent and WebSocket task broker
 A lightweight task runner and WebSocket-based task broker. The same
 executable starts as a server when the configuration contains a port,
 otherwise it runs as an agent.
 .
 Main designer: Duan TiHua
EOF

fakeroot dpkg-deb --build -Zxz "$PKGDIR" "$DESTDIR/$DEBFILE" 2>/dev/null || \
  fakeroot dpkg-deb --build "$PKGDIR" "$DESTDIR/$DEBFILE"

rm -rf "$PKGDIR"

echo "Built: $DESTDIR/$DEBFILE"
