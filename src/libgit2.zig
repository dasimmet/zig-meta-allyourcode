const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const git_exe = b.addExecutable(.{
        .name = "git2",
        .target = target,
        .optimize = optimize,
    });
    git_exe.linkLibC();

    const config_h = b.addConfigHeader(.{
        .include_path = "config.h",
        .style = .{ .cmake = b.path("deps/pcre/config.h.in") },
    }, header_config);
    git_exe.addIncludePath(config_h.getOutput().dirname());

    const features_h = b.addConfigHeader(.{
        .include_path = "git2_features.h",
        .style = .{ .cmake = b.path("src/util/git2_features.h.in") },
    }, header_config);
    git_exe.addIncludePath(features_h.getOutput().dirname());

    git_exe.defineCMacro("_DEBUG", null);
    git_exe.defineCMacro("_GNU_SOURCE", null);
    git_exe.defineCMacro("CRYPT_OPENSSL", null);
    git_exe.defineCMacro("GIT_DEPRECATE_HARD", null);
    git_exe.defineCMacro("HAVE_CONFIG_H", null);
    git_exe.defineCMacro("NTLM_STATIC", "1");
    git_exe.defineCMacro("OPENSSL_API_COMPAT", "0x10100000L");
    git_exe.defineCMacro("SIZE_MAX", "0xFFFFFFFFFFFFFFFFULL");
    git_exe.defineCMacro("UNICODE_BUILTIN", "1");

    inline for (git2_include_paths) |inc| {
        git_exe.addIncludePath(b.path(inc));
    }
    git_exe.addCSourceFiles(.{
        .files = &git2_util_files,
        .root = b.path("src/util"),
        .flags = &common_flags,
    });
    git_exe.addCSourceFiles(.{
        .files = &llhttp_files,
        .root = b.path("deps/llhttp"),
        .flags = &common_flags,
    });
    git_exe.addCSourceFiles(.{
        .files = &pcre_files,
        .root = b.path("deps/pcre"),
        .flags = &common_flags,
    });
    git_exe.addCSourceFiles(.{
        .files = &ntlmclient_files,
        .root = b.path("deps/ntlmclient"),
        .flags = &common_flags,
    });
    git_exe.addCSourceFiles(.{
        .files = &libgit2_files,
        .root = b.path("src/libgit2"),
        .flags = &common_flags,
    });
    git_exe.addCSourceFiles(.{
        .files = &git2_cli_files,
        .root = b.path("src/cli"),
        .flags = &common_flags,
    });
    inline for (cli_system_libs) |l| {
        git_exe.linkSystemLibrary(l);
    }
    b.installArtifact(git_exe);
}

pub const common_flags = .{
    // "-Wall",
    // "-Wextra",
    "-fvisibility=hidden",
    "-fPIC",
    // "-Wno-documentation-deprecated-sync",
    // "-Wno-missing-field-initializers",
    // "-Wmissing-declarations",
    // "-Wstrict-aliasing",
    // "-Wstrict-prototypes",
    // "-Wdeclaration-after-statement",
    // "-Wshift-count-overflow",
    // "-Wunused-const-variable",
    // "-Wunused-function",
    // "-Wint-conversion",
    // "-Wc99-c11-compat",
    "-Wformat",
    "-Wformat-security",
    "-g",
    "-D_DEBUG",
    "-D_GNU_SOURCE",
    // "-O0",
    // "-std=c90",
};

pub const header_config = .{
    .GIT_ARCH_64 = 1,
    .GIT_DEBUG_STRICT_ALLOC = 1,
    .GIT_DEBUG_STRICT_OPEN = 1,
    .GIT_GSSAPI = 1,
    .GIT_HTTPPARSER_BUILTIN = 1,
    .GIT_HTTPS = 1,
    .GIT_IO_POLL = 1,
    .GIT_IO_SELECT = 1,
    .GIT_NTLM = 1,
    .GIT_OPENSSL = 1,
    .GIT_QSORT_GNU = 1,
    .GIT_RAND_GETENTROPY = 1,
    .GIT_RAND_GETLOADAVG = 1,
    .GIT_REGEX_BUILTIN = 1,
    .GIT_SHA1_COLLISIONDETECT = 1,
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
    "gssapi_krb5",
    "krb5",
    "k5crypto",
    "com_err",
    "ssl",
    "crypto",
    "z",
};

pub const git2_include_paths = .{
    "include",
    "src/util",
    "deps/llhttp",
    "deps/pcre",
    "src/ntlmclient",
    "src/libgit2",
    "src/cli",
    "include/git2",
};

pub const git2_util_files = .{
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
    "unix/map.c",
    "unix/process.c",
    "unix/realpath.c",
    "hash/collisiondetect.c",
    "hash/sha1dc/sha1.c",
    "hash/sha1dc/ubc_check.c",
    "hash/openssl.c",
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
