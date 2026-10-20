# Build Instructions

This document summarizes build dependencies and procedures for ME7Sum on Linux, native Windows (MSVC), and Cygwin.

## Build System Overview

The project uses multiple build systems:

- **GNUmakefile** + **vars.mk** + **rules.mk** — Unix-like builds (Linux, macOS, Cygwin, MinGW). `inifile/*.c` is compiled into `me7sum`
- **makefile** — Native Windows with MSVC/nmake

---

## Linux

### Dependencies

- **gcc** — C compiler
- **make** — Build tool
- **git** — For `GIT_VERSION` (git describe)
- **libgmp-dev** — GMP library (arbitrary-precision arithmetic for RSA)

On Debian/Ubuntu:

```bash
sudo apt install build-essential git libgmp-dev
```

### Build

```bash
make
make test   # optional
```

Produces: `build/<triplet>/bin/me7sum`

---

## Native Windows (MSVC)

### Windows Dependencies

- **Visual Studio Build Tools 2022** (or any VS 2017+ install) with the **Desktop development with C++** workload — free download from [Visual Studio](https://visualstudio.microsoft.com/downloads/)
- **nmake** — Included with the C++ build tools
- **Git** — For `GIT_VERSION` (git describe)

`build.cmd` locates MSVC via `vswhere` (any edition: Community, Professional, Enterprise, or Build Tools). Override auto-detection by setting `VSINSTALL` to the Visual Studio installation directory before running `build.cmd`.

The Windows build uses **bundled MPIR** (`mpir/mpir-2017.lib`) for big-integer math. No system GMP or MPIR installation is required. The library was built with the VS 2017 toolset but links with newer MSVC versions; rebuild MPIR only if linking fails after a major VS upgrade.

### Windows Build

From a normal Command Prompt:

```cmd
build
```

Or explicitly:

```cmd
build clean
build
```

`build.cmd` sets up the VS environment and runs `nmake`. GitHub Actions uses the same script (`build.cmd` on `windows-latest`). Produces: `me7sum.exe`

---

## Cygwin

### Cygwin Dependencies

- **gcc** (Cygwin)
- **make**
- **git**
- **libgmp-devel** — GMP development package (headers and library)

Install via Cygwin setup:

```bash
# Install gcc-core, make, git, libgmp-devel
```

### Cygwin Build

```bash
make
make test   # optional
```

Produces: `build/<triplet>/bin/me7sum.exe`

---

## MacOS

### MacOS Dependencies

- **Xcode Command Line Tools** (or full Xcode) — provides `gcc`/`clang`
- **Homebrew** — for GMP
- **pkg-config** — so the build can find GMP; install it if it is not already present
- **gmp** — via Homebrew

```bash
brew install pkg-config gmp
```

The makefile asks `pkg-config` for GMP's include and library flags. If that returns nothing, it uses `brew --prefix gmp` (Apple Silicon or Intel Homebrew). It does not hardcode a Homebrew path.

### MacOS Build

```bash
make
make test   # optional
```

Produces: `build/<triplet>/bin/me7sum`

---

## Tests and corpus

`make test` runs `me7sum` over the test images and fails on any `ABORT`, `WARNING` or `ERROR`. Reports go to the gitignored `testdata/reports/`. The images are:

- every image in the private [ecu-corpus](https://github.com/nyetlabs/ecu-corpus) submodule (`ecu-corpus/`) whose `corpus.tsv` row has `checksums` = `ok`
- the modified (non-OEM) images in `testdata/modified/`; `testdata/broken/` holds images ME7Sum can't handle and is not tested

With read access to `ecu-corpus`, fetch the submodule at its pinned commit with `make corpus`; `make corpus-bump` moves it to the corpus head (commit the change yourself). The submodule URL is HTTPS; to use SSH, run `git config --global url.git@github.com:.insteadOf https://github.com/`. Without access, `ecu-corpus/` stays empty and `make test` skips the corpus images. `CORPUS` points the tests at another corpus checkout, and `REQUIRE_CORPUS=1` (set in CI) makes a missing corpus a failure. See xdfkit's `docs/corpus.md` for the corpus specification.

---

## Platform-Specific Notes

| Platform | GMP/MPIR source                         | Executable                         |
| -------- | --------------------------------------- | ---------------------------------- |
| Linux    | System `libgmp-dev`                     | `build/<triplet>/bin/me7sum`       |
| macOS    | Homebrew `gmp` via `pkg-config`         | `build/<triplet>/bin/me7sum`       |
| Cygwin   | `libgmp-devel`                          | `build/<triplet>/bin/me7sum.exe`   |
| MinGW    | Bundled `mpir/libgmp-<triplet>.a`       | `build/<triplet>/bin/me7sum.exe`   |
| Windows  | Bundled `mpir/mpir-2017.lib`            | `me7sum.exe`                       |

`make package` is GNU make. Linux and macOS write `build/me7sum-<os>-<version>.tar.gz` (the binary, `README.md`, `sample.ini`, and on Linux `ME7Check_linux`). Cygwin writes `build/me7sum-<version>.zip` (the gcc binary, `ME7Check.exe`, `README.md`, `sample.ini`). Windows CI does not run that target. `build.cmd` builds with nmake, then the workflow zips `me7sum.exe`, `ME7Check.exe`, `README.md`, and `sample.ini` to the same zip name with `tar`.

---

## Optional: Cross-compile for Windows (MinGW)

Requires MinGW toolchain and GMP built for MinGW (included in `mpir/`).

Debian:

```shell
sudo apt install gcc-mingw-w64 gcc-mingw-w64-i686
```

Under cygwin:

- **mingw64-i686-gcc-g++** and/or **mingw64-x86_64-gcc-g++**

GMP for these targets is the bundled archive `mpir/libgmp-<triplet>.a` on every host (Linux, Cygwin, and macOS). `make mingw` and `make mingw32` set `SYS` to the MinGW triplet; `vars.mk` links that archive whenever `SYS` contains `mingw`.

```shell
make mingw
```

or

```shell
make mingw32
```
