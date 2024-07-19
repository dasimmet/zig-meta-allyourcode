# meta-allyourcode

lazy dependencies for zig build.
This repository is for writing `build.zig` configurations for other c/c++ projects

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
