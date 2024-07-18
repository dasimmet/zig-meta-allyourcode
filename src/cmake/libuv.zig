const LibUV = @This();
const Self = LibUV;
const std = @import("std");
const cmake = @import("../cmake.zig");

pub fn build(b: *std.Build, opt: anytype) *std.Build.Step.Compile {
    const libuv = b.addStaticLibrary(.{
        .name = "uv",
        .target = opt.target,
        .optimize = opt.optimize,
    });
    libuv.linkLibC();
    cmake.addMacros(b, libuv);
    libuv.addCSourceFiles(.{
        .files = LibUV.C_SOURCES,
        .root = b.path("Utilities/cmlibuv/src"),
        .flags = &.{"-D_GNU_SOURCE"},
    });
    libuv.addIncludePath(opt.generated_headers);
    inline for (Self.IncludePaths) |p| {
        libuv.addIncludePath(b.path(p));
    }
    return libuv;
}
pub const IncludePaths = &.{
    "Utilities/cmlibuv/include",
    "Utilities/cmlibuv/src",
    "Utilities/cmlibuv/src/unix",
};
pub const C_SOURCES = &.{
    "strscpy.c",
    "strtok.c",
    "timer.c",
    "uv-common.c",
    "unix/cmake-bootstrap.c",
    "unix/core.c",
    "unix/fs.c",
    "unix/loop.c",
    "unix/loop-watcher.c",
    "unix/no-fsevents.c",
    "unix/pipe.c",
    "unix/poll.c",
    "unix/posix-hrtime.c",
    "unix/posix-poll.c",
    "unix/process.c",
    "unix/signal.c",
    "unix/stream.c",
    "unix/tcp.c",
    "unix/tty.c",
};
