# meta-allyourcode

lazy dependencies for zig build.
This repository is for writing `build.zig` configurations for other c/c++ projects

## CMake

using the zig build system, this repository bootstraps `cmake` `3.30.0` without any system cmake
or the usual shellscript method. it takes a while and is only tested on x64 linux,
but can be used to build your C/C++ dependency libraries.

I'm still working out some cacheing issues, the cmake stage2 partially gets rerun ATM.

```
zig fetch --save https://github.com/dasimmet/zig-meta-allyourcode/archive/refs/heads/master.tar.gz
```
build.zig (from <example/build.zig>)
```
const meta_allyourcode = @import("meta_allyourcode");
pub fn build() void {
  const cmakeStep = meta_allyourcode.addCMakeStep(b, .{
    .target = b.standardTargetOptions(.{}),
    .name = "cmake",
    .source_dir = b.path(""),
  });
  cmakeStep.addCmakeDefine("CMAKE_BUILD_TYPE","Release");
}
```

## External `build.zig`

the `src/cmake.zig` is my attempt at bootstrapping cmake with zig.
The main `build.zig` will pass the `cmake` dependency to it's `build()` method,
and it will run the build as if committed to the cmake repository.

## Ideas for integration

- cmake (including custom build step?)
  - ✅ stage1
  - ✅ running bootstrap `cmake` to reconfigure itself with `CC=zig cc`
  - ✅ use zig built `make` to rebuild `cmake`
  - try to link cmake fully static
  - fix any cacheing issues
  - test other architectures
  - test building other cmake projects
- libgit2 ✅
  - build for wasm32-wasi
