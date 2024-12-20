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
    inline for (libgit2.common_macros) |macro| {
        git2_util_lib.root_module.addCMacro(macro[0], macro[1]);
    }

    git2_util_lib.addCSourceFiles(.{
        .files = &common_files,
        .root = b.path(include_path),
        .flags = &libgit2.common_flags,
    });
    if (target.result.os.tag == .windows) {
        git2_util_lib.addCSourceFiles(.{
            .files = &win32_files,
            .root = b.path(win32_include_path),
            .flags = &libgit2.common_flags,
        });
        git2_util_lib.root_module.addCMacro("GIT_WIN32", "");
        git2_util_lib.root_module.addCMacro("GIT_IO_WSAPOLL", "1");
        git2_util_lib.addIncludePath(b.path(win32_include_path));
    } else {
        git2_util_lib.addCSourceFiles(.{
            .files = &unix_files,
            .root = b.path(unix_include_path),
            .flags = &libgit2.common_flags,
        });
        git2_util_lib.addCSourceFiles(.{
            .files = &hash_files,
            .root = b.path(include_path),
            .flags = &libgit2.common_flags,
        });
        inline for (libgit2.system_libs) |lib| {
            git2_util_lib.linkSystemLibrary(lib);
        }
    }
    inline for (include_paths) |inc| {
        git2_util_lib.addIncludePath(b.path(inc));
    }
    return git2_util_lib;
}
const include_paths = .{
    "include",
    // LibGIT2.ntlmclient_prefix,
    include_path,
    libgit2.LibGIT2.include_path,
    pcre.include_path,
};
pub const include_path = "src/util";
const common_files = .{
    "alloc.c",
    "allocators/failalloc.c",
    "allocators/stdalloc.c",
    "allocators/win32_leakcheck.c",
    "date.c",
    "errors.c",
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
};
const hash_files = .{
    "hash/collisiondetect.c",
    "hash/sha1dc/sha1.c",
    "hash/sha1dc/ubc_check.c",
    "hash/openssl.c",
    "zstream.c",
    "filebuf.c",
};

pub const unix_include_path = "src/util/unix";
const unix_files = .{
    "map.c",
    "process.c",
    "realpath.c",
};
pub const win32_include_path = "src/util/win32";
const win32_files = .{
    "dir.c",
    "process.c",
    "error.c",
    "thread.c",
    "map.c",
    "utf-conv.c",
    "path_w32.c",
    "w32_buffer.c",
    "posix_w32.c",
    "w32_leakcheck.c",
    "precompiled.c",
    "w32_util.c",
};
