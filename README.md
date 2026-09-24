# llvm-build

Prebuilt LLVM for [Paco](https://github.com/pacolang/paco): LLVM 18.1.8
(`llvmorg-18.1.8`) with static libraries, `llvm-config` and `lld`, the X86 and
AArch64 targets and no assertions, for linux-x86_64, linux-aarch64,
macos-aarch64, macos-x86_64 and windows-x86_64.

`build.sh <host>` builds and packages `llvm-18.1.8-<host>.tar.xz`. The
`Build LLVM` workflow runs it on every host; dispatched with a `tag`
(`llvm-18.1.8-r<N>`) it publishes the archives as a release with SHA-256
files and a build provenance attestation.

Paco consumes the release through `scripts/fetch-llvm.sh`, which pins the tag
and checksums.
