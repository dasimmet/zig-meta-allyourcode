const std = @import("std");
const pcre = @import("libgit2/pcre.zig");
const git2_util = @import("libgit2/git2_util.zig");
const xdiff = @import("libgit2/xdiff.zig");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const git2_exe = git2_cli.build(b, target, optimize);
    b.installArtifact(git2_exe);

    const features_h = b.addConfigHeader(.{
        .include_path = "configheader/git2_features.h",
        .style = .{ .cmake = b.path("src/util/git2_features.h.in") },
    }, target_header_config(target));
    git2_exe.addIncludePath(features_h.getOutput().dirname());

    const libgit2 = LibGIT2.build(b, target, optimize);
    libgit2.addIncludePath(features_h.getOutput().dirname());
    b.installArtifact(libgit2);

    // if (target.result.os.tag == .windows) libgit2.linkLibrary(zlib.artifact("zlib"));

    linkLibrary(b, git2_exe, libgit2, LibGIT2.include_path);

    const git2_util_lib = git2_util.build(b, target, optimize);
    git2_util_lib.addIncludePath(features_h.getOutput().dirname());
    b.installArtifact(git2_util_lib);
    linkLibrary(b, libgit2, git2_util_lib, git2_util.include_path);

    const pcre_lib = pcre.build(b, target, optimize);
    b.installArtifact(pcre_lib);
    linkLibrary(b, libgit2, pcre_lib, pcre.include_path);

    const xdiff_lib = xdiff.build(b, target, optimize);
    xdiff_lib.addIncludePath(features_h.getOutput().dirname());
    linkLibrary(b, xdiff_lib, pcre_lib, pcre.include_path);
    linkLibrary(b, xdiff_lib, git2_util_lib, git2_util.include_path);
    b.installArtifact(xdiff_lib);

    linkLibrary(b, libgit2, xdiff_lib, xdiff.include_path);
    libgit2.linkLibrary(xdiff_lib);
}

pub fn linkLibrary(b: *std.Build, compile: *std.Build.Step.Compile, lib: *std.Build.Step.Compile, path: []const u8) void {
    compile.linkLibrary(lib);
    compile.addIncludePath(b.path(path));
}

pub const common_macros = .{
    .{ "_DEBUG", "" },
    .{ "_GNU_SOURCE", "" },
    .{ "CRYPT_OPENSSL", "" },
    .{ "GIT_DEPRECATE_HARD", "" },
    .{ "HAVE_CONFIG_H", "" },
    .{ "NTLM_STATIC", "1" },
    .{ "OPENSSL_API_COMPAT", "0x10100000L" },
    .{ "SIZE_MAX", "0xFFFFFFFFFFFFFFFFULL" },
    .{ "UNICODE_BUILTIN", "1" },
};

pub const common_flags = .{
    "-D_DEBUG",
    "-D_GNU_SOURCE",
    "-fPIC",
    "-fvisibility=hidden",
    "-g",
    "-Wformat-security",
    "-Wformat",
    "-Wno-bad-function-cast",
    "-Wno-missing-field-initializers",
    "-Wno-pointer-arith",
    "-Wno-sign-compare",
    "-Wno-unused-but-set-variable",
    "-Wunused",
    // "-O0",
    // "-pedantic-errors",
    // "-pedantic",
    // "-std=c90",
    // "-Wall",
    // "-Wc99-c11-compat",
    // "-Wdeclaration-after-statement",
    // "-Werror",
    // "-Wextra",
    // "-Wmissing-declarations",
    // "-Wno-documentation-deprecated-sync",
    // "-Wno-int-conversion",
    // "-Wno-unused-variable",
    // "-Wshift-count-overflow",
    // "-Wstrict-aliasing",
    // "-Wstrict-prototypes",
    // "-Wunused-function",
};

pub fn target_header_config(t: std.Build.ResolvedTarget) header_config {
    var conf_h: header_config = .{};
    if (t.result.os.tag == .windows) {
        conf_h.GIT_IO_POLL = 0;
        conf_h.GIT_IO_WSAPOLL = 1;
        conf_h.GIT_OPENSSL = 0;
        conf_h.GIT_SHA1_COLLISIONDETECT = 0;
        conf_h.GIT_SHA1_WIN32 = 1;
        conf_h.GIT_SHA256_OPENSSL = 0;
        conf_h.GIT_SHA256_WIN32 = 1;
        conf_h.GIT_QSORT_GNU = 0;
        conf_h.GIT_QSORT_MSC = 1;
    }
    return conf_h;
}

pub const header_config = struct {
    GIT_ARCH_64: u1 = 1,
    GIT_DEBUG_STRICT_ALLOC: u1 = 1,
    GIT_DEBUG_STRICT_OPEN: u1 = 1,
    GIT_GSSAPI: u1 = 0,
    GIT_HTTPPARSER_BUILTIN: u1 = 1,
    GIT_HTTPS: u1 = 1,
    GIT_IO_POLL: u1 = 1,
    GIT_IO_WSAPOLL: u1 = 0,
    GIT_IO_SELECT: u1 = 1,
    GIT_NTLM: u1 = 1,
    GIT_OPENSSL_DYNAMIC: u1 = 0,
    GIT_OPENSSL: u1 = 1,
    GIT_QSORT_GNU: u1 = 1,
    GIT_QSORT_MSC: u1 = 0,
    GIT_RAND_GETENTROPY: u1 = 1,
    GIT_RAND_GETLOADAVG: u1 = 1,
    GIT_REGEX_BUILTIN: u1 = 1,
    GIT_SHA1_BUILTIN: u1 = 0,
    GIT_SHA1_COLLISIONDETECT: u1 = 1,
    GIT_SHA1_OPENSSL: u1 = 0,
    GIT_SHA1_WIN32: u1 = 0,
    GIT_SHA256_BUILTIN: u1 = 0,
    GIT_SHA256_MBEDTLS: u1 = 0,
    GIT_SHA256_OPENSSL: u1 = 1,
    GIT_SHA256_WIN32: u1 = 0,
    GIT_SSH_EXEC: u1 = 1,
    GIT_SSH: u1 = 1,
    GIT_THREADS: u1 = 1,
    GIT_USE_FUTIMENS: u1 = 1,
    GIT_USE_NSEC: u1 = 1,
    GIT_USE_STAT_MTIM: u1 = 1,
    HAVE_BCOPY: u1 = 1,
    HAVE_DIRENT_H: u1 = 1,
    HAVE_INTTYPES_H: u1 = 1,
    HAVE_LONG_LONG: u1 = 1,
    HAVE_MEMMOVE: u1 = 1,
    HAVE_STDINT_H: u1 = 1,
    HAVE_STRERROR: u1 = 1,
    HAVE_STRTOLL: u1 = 1,
    HAVE_STRTOQ: u1 = 1,
    HAVE_SYS_STAT_H: u1 = 1,
    HAVE_SYS_TYPES_H: u1 = 1,
    HAVE_UNISTD_H: u1 = 1,
    HAVE_UNSIGNED_LONG_LONG: u1 = 1,
    LINK_WITH_STATIC_LIBRARIES: u1 = 1,
    NEWLINE: u8 = 10,
    NO_RECURSE: u1 = 1,
    pcre_have_long_long: u1 = 1,
    pcre_have_ulong_long: u1 = 1,
    PCRE_LINK_SIZE: u2 = 2,
    PCRE_MATCH_LIMIT_RECURSION: []const u8 = "MATCH_LIMIT",
    PCRE_MATCH_LIMIT: u32 = 10000000,
    PCRE_NEWLINE: []const u8 = "LF",
    PCRE_PARENS_NEST_LIMIT: u18 = 250,
    PCRE_POSIX_MALLOC_THRESHOLD: u8 = 10,
    PCREGREP_BUFSIZE: ?void = null,
    SUPPORT_PCRE8: u1 = 1,
};

pub const system_libs = .{
    // "gssapi_krb5",
    // "krb5",
    // "k5crypto",
    // "com_err",
    "ssl",
    "crypto",
    "z",
};

pub const LibGIT2 = struct {
    pub fn build(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) *std.Build.Step.Compile {
        const libgit2 = b.addStaticLibrary(.{
            .name = "libgit2",
            .target = target,
            .optimize = optimize,
        });
        libgit2.linkLibC();

        inline for (common_macros) |macro| {
            libgit2.root_module.addCMacro(macro[0], macro[1]);
        }

        inline for (include_paths) |inc| {
            libgit2.addIncludePath(b.path(inc));
        }
        if ((!target.result.cpu.arch.isWasm()) and target.result.os.tag != .windows) {
            inline for (system_libs) |lib| {
                libgit2.linkSystemLibrary(lib);
            }
        }

        libgit2.addCSourceFiles(.{
            .files = &llhttp_files,
            .root = b.path(llhttp_prefix),
            .flags = &common_flags,
        });
        libgit2.addCSourceFiles(.{
            .files = &ntlmclient_files,
            .root = b.path(ntlmclient_prefix),
            .flags = &common_flags,
        });
        libgit2.addCSourceFiles(.{
            .files = &libgit2_files,
            .root = b.path(include_path),
            .flags = &common_flags,
        });
        return libgit2;
    }

    pub const include_paths = .{
        "include",
        include_path,
        git2_cli.include_path,
        llhttp_prefix,
        git2_util.include_path,
        ntlmclient_prefix,
    };
    pub const include_path = "src/libgit2";
    const libgit2_files = .{
        "annotated_commit.c",
        "apply.c",
        "attr.c",
        "attr_file.c",
        "attrcache.c",
        "blame.c",
        "blame_git.c",
        "blob.c",
        "branch.c",
        "buf.c",
        "cache.c",
        "checkout.c",
        "cherrypick.c",
        "clone.c",
        "commit.c",
        "commit_graph.c",
        "commit_list.c",
        "config.c",
        "config_cache.c",
        "config_file.c",
        "config_list.c",
        "config_mem.c",
        "config_parse.c",
        "config_snapshot.c",
        "crlf.c",
        "delta.c",
        "describe.c",
        "diff.c",
        "diff_driver.c",
        "diff_file.c",
        "diff_generate.c",
        "diff_parse.c",
        "diff_print.c",
        "diff_stats.c",
        "diff_tform.c",
        "diff_xdiff.c",
        "email.c",
        "fetch.c",
        "fetchhead.c",
        "filter.c",
        "grafts.c",
        "graph.c",
        "hashsig.c",
        "ident.c",
        "idxmap.c",
        "ignore.c",
        "index.c",
        "indexer.c",
        "iterator.c",
        "libgit2.c",
        "mailmap.c",
        "merge.c",
        "merge_driver.c",
        "merge_file.c",
        "message.c",
        "midx.c",
        "mwindow.c",
        "notes.c",
        "object.c",
        "object_api.c",
        "odb.c",
        "odb_loose.c",
        "odb_mempack.c",
        "odb_pack.c",
        "offmap.c",
        "oid.c",
        "oidarray.c",
        "oidmap.c",
        "pack-objects.c",
        "pack.c",
        "parse.c",
        "patch.c",
        "patch_generate.c",
        "patch_parse.c",
        "path.c",
        "pathspec.c",
        "proxy.c",
        "push.c",
        "reader.c",
        "rebase.c",
        "refdb.c",
        "refdb_fs.c",
        "reflog.c",
        "refs.c",
        "refspec.c",
        "remote.c",
        "repository.c",
        "reset.c",
        "revert.c",
        "revparse.c",
        "revwalk.c",
        "settings.c",
        "signature.c",
        "stash.c",
        "status.c",
        "strarray.c",
        "streams/mbedtls.c",
        "streams/openssl.c",
        "streams/openssl_dynamic.c",
        "streams/openssl_legacy.c",
        "streams/registry.c",
        "streams/schannel.c",
        "streams/socket.c",
        "streams/stransport.c",
        "streams/tls.c",
        "submodule.c",
        "sysdir.c",
        "tag.c",
        "trace.c",
        "trailer.c",
        "transaction.c",
        "transport.c",
        "transports/auth.c",
        "transports/auth_gssapi.c",
        "transports/auth_ntlmclient.c",
        "transports/auth_sspi.c",
        "transports/credential.c",
        "transports/credential_helpers.c",
        "transports/git.c",
        "transports/http.c",
        "transports/httpclient.c",
        "transports/httpparser.c",
        "transports/local.c",
        "transports/smart.c",
        "transports/smart_pkt.c",
        "transports/smart_protocol.c",
        "transports/ssh.c",
        "transports/ssh_exec.c",
        "transports/ssh_libssh2.c",
        "transports/winhttp.c",
        "tree-cache.c",
        "tree.c",
        "worktree.c",
    };

    const ntlmclient_prefix = "deps/ntlmclient";
    const ntlmclient_files = .{
        "ntlm.c",
        "util.c",
        "unicode_builtin.c",
        "crypt_openssl.c",
    };

    const llhttp_prefix = "deps/llhttp";
    const llhttp_files = .{
        "api.c",
        "http.c",
        "llhttp.c",
    };
};

const git2_cli = struct {
    pub fn build(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) *std.Build.Step.Compile {
        const git2_exe = b.addExecutable(.{
            .name = "git2",
            .target = target,
            .optimize = optimize,
        });
        inline for (include_paths) |inc| {
            git2_exe.addIncludePath(b.path(inc));
        }
        git2_exe.linkLibC();
        git2_exe.addCSourceFiles(.{
            .files = &common_files,
            .root = b.path(include_path),
            .flags = &common_flags,
        });
        if (target.result.os.tag != .windows) {
            git2_exe.addCSourceFiles(.{
                .files = &unix_files,
                .root = b.path(include_path),
                .flags = &common_flags,
            });
        }
        return git2_exe;
    }

    pub const include_paths = .{
        "include",
        include_path,
        git2_util.include_path,
    };
    const include_path = "src/cli";
    const common_files = .{
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
    };
    const unix_files = .{
        "unix/sighandler.c",
    };
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
