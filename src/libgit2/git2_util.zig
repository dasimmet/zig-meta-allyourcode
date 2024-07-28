const std = @import("std");
const libgit2 = @import("../libgit2.zig");
const pcre = @import("pcre.zig");

pub fn build(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) *std.Build.Step.Compile {
    const git2_util_lib = b.addStaticLibrary(.{
        .name = "git2_util",
        .target = target,
        .optimize = optimize,
    });
    git2_util_lib.linkLibC();
    git2_util_lib.addCSourceFiles(.{
        .files = &common_files,
        .root = b.path(files_prefix),
        .flags = &libgit2.common_flags,
    });
    if (target.result.os.tag != .windows) {
        git2_util_lib.addCSourceFiles(.{
            .files = &unix_files,
            .root = b.path(files_prefix),
            .flags = &libgit2.common_flags,
        });
    }
    inline for (libgit2.macros) |macro| {
        git2_util_lib.defineCMacro(macro[0], macro[1]);
    }
    inline for (include_paths) |inc| {
        git2_util_lib.addIncludePath(b.path(inc));
    }
    if (!target.result.isWasm()) {
        inline for (libgit2.system_libs) |lib| {
            git2_util_lib.linkSystemLibrary(lib);
        }
    }
    return git2_util_lib;
}
const include_paths = .{
    "include",
    "src/libgit2",
    // LibGIT2.ntlmclient_prefix,
    files_prefix,
    pcre.include_path,
};
pub const files_prefix = "src/util";
const common_files = .{
    "alloc.c",
    "allocators/failalloc.c",
    "allocators/stdalloc.c",
    "allocators/win32_leakcheck.c",
    "date.c",
    "errors.c",
    "filebuf.c",
    "fs_path.c",
    "futils.c",
    "hash.c",
    "net.c",
    "pool.c",
    "posix.c",
    "pqueue.c",
    "rand.c",
    "regexp.c",
    "runtime.c",
    "sortedcache.c",
    "str.c",
    "strlist.c",
    "strmap.c",
    "thread.c",
    "tsort.c",
    "utf8.c",
    "util.c",
    "varint.c",
    "vector.c",
    "wildmatch.c",
    "zstream.c",
    "hash/collisiondetect.c",
    "hash/sha1dc/sha1.c",
    "hash/sha1dc/ubc_check.c",
    "hash/openssl.c",
};
const unix_files = .{
    "unix/map.c",
    "unix/process.c",
    "unix/realpath.c",
};
