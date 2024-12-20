const std = @import("std");
const libgit2 = @import("../libgit2.zig");
const git2_util = @import("git2_util.zig");

pub fn build(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) *std.Build.Step.Compile {
    const xdiff_lib = b.addStaticLibrary(.{
        .name = "xdiff",
        .target = target,
        .optimize = optimize,
    });
    xdiff_lib.linkLibC();
    inline for (libgit2.common_macros) |it| {
        xdiff_lib.root_module.addCMacro(it[0], it[1]);
    }
    xdiff_lib.addCSourceFiles(.{
        .files = &files,
        .root = b.path(include_path),
        .flags = &libgit2.common_flags,
    });
    xdiff_lib.addIncludePath(b.path("include"));
    xdiff_lib.addIncludePath(b.path(
        if (target.result.os.tag == .windows) git2_util.win32_include_path else git2_util.unix_include_path,
    ));
    xdiff_lib.addIncludePath(b.path(git2_util.include_path));
    return xdiff_lib;
}
pub const include_path = "deps/xdiff";
const files = .{
    "xdiffi.c",
    "xemit.c",
    "xhistogram.c",
    "xmerge.c",
    "xpatience.c",
    "xprepare.c",
    "xutils.c",
};
