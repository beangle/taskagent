#!/bin/bash
# RPM 打包脚本。需安装 rpm-build、fakeroot；在 Fedora/RHEL 系系统运行
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

# rpm 4.14 起才写入 SHA256HEADER；旧版 rpmbuild 只能写 SHA1 头摘要，
# 这种包会被要求 SHA256 摘要的新版 rpm 拒绝为 “does not verify: no digest”。
require_modern_rpmbuild() {
  local version
  version="$(rpmbuild --version | awk '{print $3}')"
  if [ -z "$version" ] || \
    [ "$(printf '%s\n%s\n' "$version" "4.14" | sort -V | head -n 1)" != "4.14" ]; then
    ferror "rpmbuild >= 4.14 is required (found ${version:-unknown})" \
      "A newer rpmbuild is required to emit SHA256HEADER; put it first in PATH."
  fi
}

sys_release_version() {
  local os_id
  os_id=$(source /etc/os-release && echo "$ID")
  if [ "$os_id" = "fedora" ]; then
    REVISION="1.fc$(source /etc/os-release && echo "$VERSION_ID")"
  else
    REVISION="1.el$(source /etc/os-release && echo "$VERSION_ID")"
  fi
}

E=0
LIST=""
fcheck() {
  if ! command -v "$1" >/dev/null 2>&1; then
    LIST=$LIST" "$1
    E=1
  fi
}
fcheck gzip
fcheck rpmbuild
fcheck fakeroot
fcheck strip
fcheck dub
if [ $E -eq 1 ]; then
  ferror "Missing commands on your system:" "$LIST"
fi
require_modern_rpmbuild

task_prepare_release_build

MAINTAINER="duantihua <duantihua@163.com>"
VENDOR="Beangle"
VERSION=$(task_package_version)
REVISION=""
[[ -n "$1" ]] && REVISION="$1"
if [ -z "$REVISION" ]; then
  sys_release_version
fi
DESTDIR="$TASK_HOME/target"
VERSION=$(sed 's/-/~/' <<<"$VERSION")
ARCH="x86_64"

PKGDIR="beangle-task-${VERSION}-${REVISION}.${ARCH}"
RPMFILE="beangle-task-${VERSION}-${REVISION}.${ARCH}.rpm"
RPMDIR="$DESTDIR/rpmbuild"

rm -f "$DESTDIR/$RPMFILE"
rm -rf "$DESTDIR/$PKGDIR" "$RPMDIR"

mkdir -p "$DESTDIR/$PKGDIR/usr/bin"
cp -f "$TASK_HOME/target/beangle-task" "$DESTDIR/$PKGDIR/usr/bin/beangle-task"
strip --strip-unneeded "$DESTDIR/$PKGDIR/usr/bin/beangle-task"
chmod 0755 "$DESTDIR/$PKGDIR/usr/bin/beangle-task"

DATE=$(LC_ALL=C date '+%a %b %d %Y')
cat > "$DESTDIR/beangle-task.spec" <<EOF
Name: beangle-task
Version: ${VERSION}
Release: ${REVISION}
Summary: Beangle task agent and WebSocket task broker
Group: Applications/System
License: GPL-3.0-or-later
URL: https://github.com/beangle/task
Vendor: ${VENDOR}
Packager: ${MAINTAINER}
ExclusiveArch: ${ARCH}
Provides: beangle-task(${ARCH}) = ${VERSION}-${REVISION}

%description
A lightweight task runner and WebSocket-based task broker. The same
executable starts as a server when the configuration contains a port,
otherwise it runs as an agent.
Main designer: Duan TiHua

%changelog
* ${DATE} ${MAINTAINER} - ${VERSION}-${REVISION}
- Build beangle-task binary package

%files
EOF

find "$DESTDIR/$PKGDIR" ! -type d | \
  sed 's|'"$DESTDIR"'/'"$PKGDIR"'|/|' >> "$DESTDIR/beangle-task.spec"

echo >> "$DESTDIR/beangle-task.spec"
mkdir -p "$RPMDIR"
echo "%define _rpmdir $RPMDIR" >> "$DESTDIR/beangle-task.spec"
fakeroot rpmbuild --quiet --buildroot="$DESTDIR/$PKGDIR" -bb --target "$ARCH" \
  --define '_binary_payload w9.xzdio' \
  --define '_binary_filedigest_algorithm 8' \
  --define '_source_filedigest_algorithm 8' "$DESTDIR/beangle-task.spec"

mv "$RPMDIR/$ARCH/beangle-task-$VERSION-$REVISION.$ARCH.rpm" "$DESTDIR/$RPMFILE"

rm -rf "$RPMDIR" "$DESTDIR/$PKGDIR" "$DESTDIR/beangle-task.spec"

RPMVERIFY="$(LC_ALL=C rpm -Kv "$DESTDIR/$RPMFILE" 2>&1 || true)"
if ! grep -q 'Header SHA256 digest: OK' <<<"$RPMVERIFY"; then
  ferror "Generated RPM has no SHA256 header digest" "$RPMVERIFY"
fi

echo "Built: $DESTDIR/$RPMFILE"
