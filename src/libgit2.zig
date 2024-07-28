const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const git2_exe = git2_cli.build(b, target, optimize);
    b.installArtifact(git2_exe);

    const libgit2 = b.addStaticLibrary(.{
        .name = "libgit2",
        .target = target,
        .optimize = optimize,
    });
    git2_exe.linkLibrary(libgit2);
    libgit2.linkLibC();

    inline for (macros) |macro| {
        libgit2.defineCMacro(macro[0], macro[1]);
    }

    inline for (git2_include_paths) |inc| {
        libgit2.addIncludePath(b.path(inc));
    }
    if (!target.result.isWasm()) {
        inline for (cli_system_libs) |lib| {
            libgit2.linkSystemLibrary(lib);
        }
    }

    libgit2.addCSourceFiles(.{
        .files = &llhttp_files,
        .root = b.path("deps/llhttp"),
        .flags = &common_flags,
    });
    libgit2.addCSourceFiles(.{
        .files = &ntlmclient_files,
        .root = b.path("deps/ntlmclient"),
        .flags = &common_flags,
    });
    libgit2.addCSourceFiles(.{
        .files = &libgit2_files,
        .root = b.path("src/libgit2"),
        .flags = &common_flags,
    });
    b.installArtifact(libgit2);

    const features_h = b.addConfigHeader(.{
        .include_path = "configheader/git2_features.h",
        .style = .{ .cmake = b.path("src/util/git2_features.h.in") },
    }, target_header_config(target));
    libgit2.addIncludePath(features_h.getOutput().dirname());
    libgit2.addIncludePath(features_h.getOutput().dirname());
    git2_exe.addIncludePath(features_h.getOutput().dirname());

    const git2_util_lib = git2_util.build(b, target, optimize);
    git2_util_lib.addIncludePath(features_h.getOutput().dirname());
    libgit2.linkLibrary(git2_util_lib);
    b.installArtifact(git2_util_lib);

    const pcre = b.addStaticLibrary(.{
        .name = "pcre",
        .target = target,
        .optimize = optimize,
    });
    {
        const pcre_config_h = b.addConfigHeader(.{
            .include_path = "configheader/config.h",
            .style = .{ .cmake = b.path("deps/pcre/config.h.in") },
        }, target_header_config(target));
        pcre.addIncludePath(pcre_config_h.getOutput().dirname());
        pcre.addCSourceFiles(.{
            .files = &pcre_files,
            .root = b.path("deps/pcre"),
            .flags = &common_flags,
        });
        pcre.linkLibC();
        inline for (macros) |macro| {
            pcre.defineCMacro(macro[0], macro[1]);
        }
        pcre.addIncludePath(pcre_config_h.getOutput().dirname());
        libgit2.linkLibrary(pcre);
        b.installArtifact(pcre);
    }

    {
        const xdiff = b.addStaticLibrary(.{
            .name = "xdiff",
            .target = target,
            .optimize = optimize,
        });
        xdiff.linkLibC();
        xdiff.addCSourceFiles(.{
            .files = &xdiff_files,
            .root = b.path("deps/xdiff"),
            .flags = &common_flags,
        });
        xdiff.addIncludePath(b.path("deps/pcre"));
        xdiff.addIncludePath(b.path("src/util"));
        xdiff.addIncludePath(b.path("include"));
        xdiff.addIncludePath(features_h.getOutput().dirname());
        libgit2.linkLibrary(xdiff);
        b.installArtifact(xdiff);
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
    // "-Wall",
    // "-Wextra",
    "-Wformat-security",
    "-Wformat",
    "-Wno-bad-function-cast",
    "-Wno-missing-field-initializers",
    "-Wno-pointer-arith",
    "-Wno-sign-compare",
    "-Wno-unused-but-set-variable",
    "-Wunused",
    // "-Wc99-c11-compat",
    // "-Wdeclaration-after-statement",
    // "-Werror",
    // "-Wmissing-declarations",
    // "-Wno-documentation-deprecated-sync",
    // "-Wno-int-conversion",
    // "-Wno-unused-variable",
    // "-Wshift-count-overflow",
    // "-Wstrict-aliasing",
    // "-Wstrict-prototypes",
    // "-Wunused-function",
    "-D_DEBUG",
    "-D_GNU_SOURCE",
    "-fPIC",
    "-fvisibility=hidden",
    "-g",
    // "-pedantic-errors",
    // "-pedantic",
    // "-O0",
    // "-std=c90",
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

pub const cli_system_libs = .{
    // "gssapi_krb5",
    // "krb5",
    // "k5crypto",
    // "com_err",
    // "ssl",
    "crypto",
    "z",
};

pub const git2_include_paths = .{
    "include",
    "src/util",
    "deps/llhttp",
    "deps/pcre",
    "deps/xdiff",
    "deps/ntlmclient",
    "src/libgit2",
    "src/cli",
    // "include/git2", DO NOT INCLUDE THIS IT WILL RUIN STDLIB INCLUDES
};

pub const git2_util = struct {
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
            .flags = &common_flags,
        });
        if (target.result.os.tag != .windows) {
            git2_util_lib.addCSourceFiles(.{
                .files = &unix_files,
                .root = b.path(files_prefix),
                .flags = &common_flags,
            });
        }
        inline for (macros) |macro| {
            git2_util_lib.defineCMacro(macro[0], macro[1]);
        }
        inline for (git2_include_paths) |inc| {
            git2_util_lib.addIncludePath(b.path(inc));
        }
        if (!target.result.isWasm()) {
            inline for (cli_system_libs) |lib| {
                git2_util_lib.linkSystemLibrary(lib);
            }
        }
        return git2_util_lib;
    }
    const files_prefix = "src/util";
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
};

const llhttp_files = .{
    "api.c",
    "http.c",
    "llhttp.c",
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

const git2_cli = struct {
    pub fn build(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) *std.Build.Step.Compile {
        const git2_exe = b.addExecutable(.{
            .name = "git2",
            .target = target,
            .optimize = optimize,
        });
        inline for (git2_include_paths) |inc| {
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
