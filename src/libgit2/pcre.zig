const std = @import("std");
const libgit2 = @import("../libgit2.zig");

pub fn build(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) *std.Build.Step.Compile {
    const pcre_lib = b.addStaticLibrary(.{
        .name = "pcre",
        .target = target,
        .optimize = optimize,
    });
    const pcre_config_h = b.addConfigHeader(.{
        .include_path = "configheader/config.h",
        .style = .{ .cmake = b.path("deps/pcre/config.h.in") },
    }, libgit2.target_header_config(target));
    pcre_lib.addIncludePath(pcre_config_h.getOutput().dirname());
    pcre_lib.addCSourceFiles(.{
        .files = &files,
        .root = b.path(include_path),
        .flags = &libgit2.common_flags,
    });
    pcre_lib.linkLibC();
    inline for (libgit2.common_macros) |macro| {
        pcre_lib.root_module.addCMacro(macro[0], macro[1]);
    }
    pcre_lib.addIncludePath(pcre_config_h.getOutput().dirname());
    return pcre_lib;
}
pub const include_path = "deps/pcre";
const files = .{
    "pcre_byte_order.c",
    "pcre_chartables.c",
    "pcre_compile.c",
    "pcre_config.c",
    "pcre_dfa_exec.c",
    "pcre_exec.c",
    "pcre_fullinfo.c",
    "pcre_get.c",
    "pcre_globals.c",
    "pcre_jit_compile.c",
    "pcre_maketables.c",
    "pcre_newline.c",
    "pcre_ord2utf8.c",
    "pcre_refcount.c",
    "pcre_string_utils.c",
    "pcre_study.c",
    "pcre_tables.c",
    "pcre_ucd.c",
    "pcre_valid_utf8.c",
    "pcre_version.c",
    "pcre_xclass.c",
    "pcreposix.c",
};
