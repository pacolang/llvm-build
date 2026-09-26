# llvm-build

**Leia em:** [English](README.md) · **Português** · [Español](README.es.md)

LLVM pré-compilado para o [Paco](https://github.com/pacolang/paco): LLVM
18.1.8 (`llvmorg-18.1.8`) com bibliotecas estáticas, `llvm-config` e `lld`,
os targets X86 e AArch64 e sem assertions, para linux-x86_64,
linux-aarch64, macos-aarch64, macos-x86_64 e windows-x86_64.

`build.sh <host>` compila e empacota `llvm-18.1.8-<host>.tar.xz`. O
workflow `Build LLVM` roda em cada host, depois faz um smoke test do
arquivo (`llvm-config`, e `smoke/`, que linka o `llvm-sys` estaticamente
contra ele e emite objetos para cada target); disparado com uma `tag`
(`llvm-18.1.8-r<N>`) ele publica os arquivos como um release com arquivos
SHA-256 e uma attestation de proveniência de build.

O Paco consome o release através de `scripts/fetch-llvm.sh`, que fixa a tag
e os checksums.

Os arquivos oficiais de release do LLVM não são reempacotados: o 18.1.8 não
tem nenhum para macos-x86_64, os do Linux linkam o `llvm-config` contra
`libtinfo.so.5` e suas bibliotecas estáticas precisam de zlib e terminfo no
host. Compilar cada host a partir da mesma configuração, com zlib, zstd,
libxml2 e terminfo desabilitados, deixa bibliotecas que não precisam de
nada além dos runtimes de C e C++.

Se um bump precisar ser feito antes de um build terminar, o pacote
`llvmdev` do conda-forge tem bibliotecas estáticas e `llvm-config` para os
cinco hosts (win-64 é MSVC); ele é compilado com zlib e zstd, então uma
cópia reempacotada adiciona `-lz -lzstd` a `llvm-config --system-libs`. No
Windows o build desabilita o DIA SDK, então `llvm-config --system-libs` não
nomeia nenhum caminho do Visual Studio (o arquivo oficial do Windows para a
série 18.1.x nomeia o `diaguids.lib` da máquina de build,
llvm/llvm-project#86250).
