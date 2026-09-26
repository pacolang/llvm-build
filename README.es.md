# llvm-build

**Leer en:** [English](README.md) · [Português](README.pt-BR.md) · **Español**

LLVM precompilado para [Paco](https://github.com/pacolang/paco): LLVM
18.1.8 (`llvmorg-18.1.8`) con bibliotecas estáticas, `llvm-config` y `lld`,
los targets X86 y AArch64 y sin assertions, para linux-x86_64,
linux-aarch64, macos-aarch64, macos-x86_64 y windows-x86_64.

`build.sh <host>` compila y empaqueta `llvm-18.1.8-<host>.tar.xz`. El
workflow `Build LLVM` lo ejecuta en cada host, luego hace un smoke test del
archivo (`llvm-config`, y `smoke/`, que enlaza `llvm-sys` estáticamente
contra él y emite objetos para cada target); disparado con un `tag`
(`llvm-18.1.8-r<N>`) publica los archivos como un release con archivos
SHA-256 y una attestation de procedencia de build.

Paco consume el release a través de `scripts/fetch-llvm.sh`, que fija el
tag y los checksums.

Los archivos oficiales de release de LLVM no se reempaquetan: el 18.1.8 no
tiene ninguno para macos-x86_64, los de Linux enlazan `llvm-config` contra
`libtinfo.so.5` y sus bibliotecas estáticas necesitan zlib y terminfo en el
host. Compilar cada host a partir de la misma configuración, con zlib,
zstd, libxml2 y terminfo deshabilitados, deja bibliotecas que no necesitan
nada más allá de los runtimes de C y C++.

Si un bump debe llegar antes de que termine un build, el paquete
`llvmdev` de conda-forge tiene bibliotecas estáticas y `llvm-config` para
los cinco hosts (win-64 es MSVC); está compilado con zlib y zstd, así que
una copia reempaquetada agrega `-lz -lzstd` a `llvm-config --system-libs`.
En Windows el build deshabilita el DIA SDK, así que `llvm-config
--system-libs` no nombra ninguna ruta de Visual Studio (el archivo oficial
de Windows de la serie 18.1.x nombra el `diaguids.lib` de la máquina de
build, llvm/llvm-project#86250).
