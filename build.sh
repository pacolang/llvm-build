#!/usr/bin/env bash
# Builds the pinned LLVM (static libraries, llvm-config, lld; X86 and AArch64)
# and packages it as llvm-<version>-<host>.tar.xz in the current directory.
set -euo pipefail

host="${1:?usage: build.sh <linux-x86_64|linux-aarch64|macos-aarch64|macos-x86_64|windows-x86_64>}"
version=18.1.8
source_sha256=0b58557a6d32ceee97c8d533a59b9212d87e0fc4d2833924eb6c611247db2f2a
work="${WORK_DIR:-$PWD/work}"
name="llvm-$version-$host"
out="$PWD/$name.tar.xz"

mkdir -p "$work"
cd "$work"
tarball="llvm-project-$version.src.tar.xz"
if [ ! -f "$tarball" ]; then
  curl -sfLO "https://github.com/llvm/llvm-project/releases/download/llvmorg-$version/$tarball"
fi
echo "$source_sha256  $tarball" | sha256sum -c -
if [ ! -d "llvm-project-$version.src" ]; then
  tar xJf "$tarball" "llvm-project-$version.src/llvm" "llvm-project-$version.src/lld" \
    "llvm-project-$version.src/cmake" "llvm-project-$version.src/libunwind/include" \
    "llvm-project-$version.src/third-party"
fi

extra=()
case "$host" in
  macos-*) extra+=(-DCMAKE_OSX_DEPLOYMENT_TARGET=11.0) ;;
  windows-*) extra+=(-DCMAKE_C_COMPILER=cl -DCMAKE_CXX_COMPILER=cl) ;;
esac
if command -v sccache > /dev/null; then
  extra+=(-DCMAKE_C_COMPILER_LAUNCHER=sccache -DCMAKE_CXX_COMPILER_LAUNCHER=sccache)
fi

rm -rf "$name"
cmake -G Ninja -S "llvm-project-$version.src/llvm" -B build \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$work/$name" \
  -DLLVM_ENABLE_PROJECTS=lld \
  -DLLVM_TARGETS_TO_BUILD="X86;AArch64" \
  -DLLVM_ENABLE_ASSERTIONS=OFF \
  -DBUILD_SHARED_LIBS=OFF \
  -DLLVM_BUILD_LLVM_DYLIB=OFF \
  -DLLVM_ENABLE_ZLIB=OFF \
  -DLLVM_ENABLE_ZSTD=OFF \
  -DLLVM_ENABLE_LIBXML2=OFF \
  -DLLVM_ENABLE_TERMINFO=OFF \
  -DLLVM_ENABLE_LIBEDIT=OFF \
  -DLLVM_ENABLE_LIBPFM=OFF \
  -DLLVM_ENABLE_Z3_SOLVER=OFF \
  -DLLVM_ENABLE_BINDINGS=OFF \
  -DLLVM_INCLUDE_TESTS=OFF \
  -DLLVM_INCLUDE_EXAMPLES=OFF \
  -DLLVM_INCLUDE_BENCHMARKS=OFF \
  -DLLVM_INCLUDE_DOCS=OFF \
  -DLLVM_DISTRIBUTION_COMPONENTS="llvm-config;llvm-headers;llvm-libraries;cmake-exports;lld" \
  "${extra[@]}"
cmake --build build --target install-distribution

exe=""
case "$host" in windows-*) exe=.exe ;; esac
"$name/bin/llvm-config$exe" --version | grep -qx "$version"
"$name/bin/llvm-config$exe" --link-static --libs > /dev/null
"$name/bin/lld$exe" -flavor gnu --version

XZ_OPT="-T0 -6" tar cJf "$out" "$name"
echo "$out"
