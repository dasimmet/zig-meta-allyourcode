const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const lib = b.addExecutable(.{
        .name = "git2",
        .target = target,
        .optimize = optimize,
    });
    lib.linkLibC();
    const config_h = b.addConfigHeader(.{
        .include_path = "config.h",
        .style = .{ .cmake = b.path("deps/pcre/config.h.in") },
        // .include_guard_override = "PCRE_CONFIG_H_OVERRIDE",
    }, pcre_config);
    lib.addIncludePath(config_h.getOutput().dirname());
    const features_h = b.addConfigHeader(.{
        .include_path = "git2_features.h",
        .style = .{ .cmake = b.path("src/util/git2_features.h.in") },
    }, .{});
    lib.addIncludePath(features_h.getOutput().dirname());
    lib.defineCMacro("HAVE_CONFIG_H", null);
    lib.defineCMacro("_DEBUG", null);
    lib.defineCMacro("_GNU_SOURCE", null);
    lib.defineCMacro("CRYPT_OPENSSL", null);
    lib.defineCMacro("GIT_DEPRECATE_HARD", null);
    lib.defineCMacro("NTLM_STATIC", "1");
    lib.defineCMacro("OPENSSL_API_COMPAT", "0x10100000L");
    lib.defineCMacro("UNICODE_BUILTIN", "1");

    inline for (git2_include_paths) |inc| {
        lib.addIncludePath(b.path(inc));
    }
    lib.addCSourceFiles(.{
        .files = &pcre_files,
        .root = b.path("deps/pcre"),
    });
    lib.addCSourceFiles(.{
        .files = &git2_cli_files,
        .root = b.path("src/cli"),
    });
    inline for (cli_system_libs) |l| {
        lib.linkSystemLibrary(l);
    }
    b.installArtifact(lib);
}

pub const pcre_config = .{
    .HAVE_BCOPY = 1,
    .HAVE_DIRENT_H = 1,
    .HAVE_INTTYPES_H = 1,
    .HAVE_LONG_LONG = 1,
    .HAVE_MEMMOVE = 1,
    .HAVE_STDINT_H = 1,
    .HAVE_STRERROR = 1,
    .HAVE_STRTOLL = 1,
    .HAVE_STRTOQ = 1,
    .HAVE_SYS_STAT_H = 1,
    .HAVE_SYS_TYPES_H = "1",
    .HAVE_UNISTD_H = 1,
    .HAVE_UNSIGNED_LONG_LONG = 1,
    .NEWLINE = 10,
    .NO_RECURSE = 1,
    .PCRE_LINK_SIZE = 2,
    .PCRE_MATCH_LIMIT = 10000000,
    .PCRE_MATCH_LIMIT_RECURSION = "MATCH_LIMIT",
    .PCRE_NEWLINE = "LF",
    .PCRE_PARENS_NEST_LIMIT = 250,
    .PCRE_POSIX_MALLOC_THRESHOLD = 10,
    .PCREGREP_BUFSIZE = null,
    .SUPPORT_PCRE8 = 1,
};
pub const cli_system_libs = .{
    "gssapi_krb5",
    "krb5",
    "k5crypto",
    "com_err",
    "ssl",
    "crypto",
    "z",
};

pub const git2_include_paths = .{
    "deps/pcre",
    "src/pcre",
    "src/cli",
    "src/util",
    "src/libgit2",
    "include",
};
const git2_cli_files = .{
    "cmd.c",
    "cmd_cat_file.c",
    "cmd_clone.c",
    "cmd_config.c",
    "cmd_hash_object.c",
    "cmd_help.c",
    "cmd_index_pack.c",
    "common.c",
    "main.c",
    "opt.c",
    "opt_usage.c",
    "progress.c",
    "unix/sighandler.c",
};

const ntlmclient_files = .{
    "ntlm.c",
    "util.c",
    "unicode_builtin.c",
    "crypt_openssl.c",
};

const xdiff_files = .{
    "xdiffi.c",
    "xemit.c",
    "xhistogram.c",
    "xmerge.c",
    "xpatience.c",
    "xprepare.c",
    "xutils.c",
};

const pcre_files = .{
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

pub fn dir_src(b: *std.Build, dir: []const u8, suffix: []const u8) [][]const u8 {
    return dir_src_internal(b, dir, suffix) catch @panic("dir_src");
}
fn dir_src_internal(b: *std.Build, dir: []const u8, suffix: []const u8) ![][]const u8 {
    var acc = std.ArrayListUnmanaged([]const u8){};
    const cwd = std.fs.cwd();
    var fd = try cwd.openDir(dir, .{
        .iterate = true,
    });
    defer fd.close();
    var fd_it = fd.iterate();
    while (try fd_it.next()) |f| {
        if (std.mem.endsWith(u8, f.name, suffix)) {
            try acc.append(
                b.allocator,
                try std.fs.path.join(b.allocator, &.{
                    dir, f.name,
                }),
            );
        }
    }
    return try acc.toOwnedSlice(b.allocator);
}
