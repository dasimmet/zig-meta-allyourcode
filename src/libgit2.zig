const std = @import("std");
const pcre = @import("libgit2/pcre.zig");
const git2_util = @import("libgit2/git2_util.zig");

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

    {
        const libgit2 = LibGIT2.build(b, target, optimize);
        libgit2.addIncludePath(features_h.getOutput().dirname());
        git2_exe.linkLibrary(libgit2);
        b.installArtifact(libgit2);

        const git2_util_lib = git2_util.build(b, target, optimize);
        git2_util_lib.addIncludePath(features_h.getOutput().dirname());
        b.installArtifact(git2_util_lib);
        libgit2.linkLibrary(git2_util_lib);

        const pcre_lib = pcre.build(b, target, optimize);
        b.installArtifact(pcre_lib);
        libgit2.linkLibrary(pcre_lib);
        libgit2.addIncludePath(b.path(pcre.include_path));

        const xdiff_lib = xdiff.build(b, target, optimize);
        xdiff_lib.addIncludePath(features_h.getOutput().dirname());
        xdiff_lib.linkLibrary(pcre_lib);
        xdiff_lib.addIncludePath(b.path(pcre.include_path));

        b.installArtifact(xdiff_lib);
        libgit2.linkLibrary(xdiff_lib);
    }
}

pub const macros = .{
    .{ "_DEBUG", null },
    .{ "_GNU_SOURCE", null },
    .{ "CRYPT_OPENSSL", null },
    .{ "GIT_DEPRECATE_HARD", null },
    .{ "HAVE_CONFIG_H", null },
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

pub fn target_header_config(t: std.Build.ResolvedTarget) @TypeOf(header_config) {
    _ = t;
    var conf_h = header_config;
    conf_h.GIT_ARCH_64 = 1;
    return conf_h;
}

pub const header_config = .{
    .GIT_ARCH_64 = 1,
    .GIT_DEBUG_STRICT_ALLOC = 1,
    .GIT_DEBUG_STRICT_OPEN = 1,
    .GIT_GSSAPI = 0,
    .GIT_HTTPPARSER_BUILTIN = 1,
    .GIT_HTTPS = 1,
    .GIT_IO_POLL = 1,
    .GIT_IO_SELECT = 1,
    .GIT_NTLM = 1,
    .GIT_OPENSSL = 0,
    .GIT_QSORT_GNU = 1,
    .GIT_RAND_GETENTROPY = 1,
    .GIT_RAND_GETLOADAVG = 1,
    .GIT_REGEX_BUILTIN = 1,
    .GIT_SHA1_COLLISIONDETECT = 1,
    .GIT_SHA1_OPENSSL = 0,
    .GIT_SHA256_BUILTIN = 0,
    .GIT_SHA256_MBEDTLS = 0,
    .GIT_SHA256_OPENSSL = 1,
    .GIT_SSH = 1,
    .GIT_SSH_EXEC = 1,
    .GIT_THREADS = 1,
    .GIT_USE_FUTIMENS = 1,
    .GIT_USE_NSEC = 1,
    .GIT_USE_STAT_MTIM = 1,
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
    .LINK_WITH_STATIC_LIBRARIES = 1,
    .NEWLINE = 10,
    .NO_RECURSE = 1,
    .pcre_have_long_long = 1,
    .pcre_have_ulong_long = 1,
    .PCRE_LINK_SIZE = 2,
    .PCRE_MATCH_LIMIT = 10000000,
    .PCRE_MATCH_LIMIT_RECURSION = "MATCH_LIMIT",
    .PCRE_NEWLINE = "LF",
    .PCRE_PARENS_NEST_LIMIT = 250,
    .PCRE_POSIX_MALLOC_THRESHOLD = 10,
    .PCREGREP_BUFSIZE = null,
    .SUPPORT_PCRE8 = 1,
};

pub const system_libs = .{
    // "gssapi_krb5",
    // "krb5",
    // "k5crypto",
    // "com_err",
    // "ssl",
    "crypto",
    "z",
};

const xdiff = struct {
    pub fn build(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) *std.Build.Step.Compile {
        const xdiff_lib = b.addStaticLibrary(.{
            .name = "xdiff",
            .target = target,
            .optimize = optimize,
        });
        xdiff_lib.linkLibC();
        xdiff_lib.addCSourceFiles(.{
            .files = &files,
            .root = b.path(files_prefix),
            .flags = &common_flags,
        });
        inline for (include_paths) |inc| {
            xdiff_lib.addIncludePath(b.path(inc));
        }
        return xdiff_lib;
    }
    const include_paths = .{
        "include",
        git2_util.files_prefix,
    };
    const files_prefix = "deps/xdiff";
    const files = .{
        "xdiffi.c",
        "xemit.c",
        "xhistogram.c",
        "xmerge.c",
        "xpatience.c",
        "xprepare.c",
        "xutils.c",
    };
};

const LibGIT2 = struct {
    pub fn build(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) *std.Build.Step.Compile {
        const libgit2 = b.addStaticLibrary(.{
            .name = "libgit2",
            .target = target,
            .optimize = optimize,
        });
        libgit2.linkLibC();

        inline for (macros) |macro| {
            libgit2.defineCMacro(macro[0], macro[1]);
        }

        inline for (include_paths) |inc| {
            libgit2.addIncludePath(b.path(inc));
        }
        if (!target.result.isWasm()) {
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
            .root = b.path(files_prefix),
            .flags = &common_flags,
        });
        return libgit2;
    }

    pub const include_paths = .{
        "include",
        files_prefix,
        git2_cli.files_prefix,
        git2_util.files_prefix,
        llhttp_prefix,
        ntlmclient_prefix,
        pcre.include_path,
        xdiff.files_prefix,
        // "include/git2", DO NOT INCLUDE THIS IT WILL RUIN STDLIB INCLUDES
    };
    const files_prefix = "src/libgit2";
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
            .root = b.path(files_prefix),
            .flags = &common_flags,
        });
        if (target.result.os.tag != .windows) {
            git2_exe.addCSourceFiles(.{
                .files = &unix_files,
                .root = b.path(files_prefix),
                .flags = &common_flags,
            });
        }
        return git2_exe;
    }

    pub const include_paths = .{
        "include",
        files_prefix,
        git2_util.files_prefix,
        LibGIT2.files_prefix,
        LibGIT2.llhttp_prefix,
        LibGIT2.ntlmclient_prefix,
        pcre.include_path,
        xdiff.files_prefix,
    };
    const files_prefix = "src/cli";
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
