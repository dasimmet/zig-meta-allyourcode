# meta-allyourcode

lazy dependencies for zig build.
This repository is for writing `build.zig` configurations for other c/c++ projects

## CMake

using the zig build system, this repository bootstraps `cmake` `3.30.1` without any system cmake
or the usual shellscript method. it takes a while and is only tested on x64 linux,
but can be used to build your C/C++ dependency libraries.

the package also has a custom `CMakeStep` that will configure and build and install a cmake project,
and providdes a `.install(b, name)` function to get the artifacts:
```
zig fetch --save https://github.com/dasimmet/zig-meta-allyourcode/archive/refs/heads/master.tar.gz
```
build.zig (from [example](./example/build.zig)):
```
pub fn build() void {
  const meta_import = b.lazyImport(@This(), "meta_allyourcode");

  if (meta_import) |meta_allyourcode| {}
  const cmakeStep = meta_allyourcode.addCMakeStep(b, .{
    .target = b.standardTargetOptions(.{}),
    .name = "cmake",
    .source_dir = b.path(""),
      .defines = &.{
          .{ "CMAKE_BUILD_TYPE", if (optimize == .Debug) "Debug" else "Release" },
      },
  });
  cmakeStep.addCmakeDefine();
  const install_step = cmakeStep.install(b, "");
  b.getInstallStep().dependOn(&install_step.step);
}
```

## integrated builds

- cmake (including custom build step?)
  - ✅ stage1 linux
  - ✅ running bootstrap `cmake` to reconfigure itself with `CC=zig cc`
  - ✅ use zig built `make` to rebuild `cmake`
  - 🏃‍♂️ stage1 windows
  - 🏃‍♂️ stage1 macos
  - 🏃‍♂️test building other cmake projects
  - try to link cmake fully static
  - test other architectures
- libgit2 ✅
  - build for wasm32-wasi
- wabt
