const std = @import("std");
const LazyPath = std.Build.LazyPath;
const build_zig = @import("../build.zig");
const DefaultBuildOptions = build_zig.DefaultBuildOptions;

pub fn wasm2wat(b: *std.Build, wasm: LazyPath, out_basename: []const u8) LazyPath {
    const this_dep = b.dependencyFromBuildZig(build_zig, .{
        .dependency = .wabt,
        .target = b.host,
    });
    const wat_run = b.addRunArtifact(this_dep.artifact("wasm2wat"));
    wat_run.addFileArg(wasm);
    return wat_run.addPrefixedOutputFileArg("--output=", out_basename);
}

pub fn addBuild(b: *std.Build, defaults: DefaultBuildOptions) void {
    const static_target = b.resolveTargetQuery(.{
        .cpu_arch = defaults.target.result.cpu.arch,
        .os_tag = defaults.target.result.os.tag,
        .abi = if (defaults.target.result.os.tag == .linux) .musl else null,
    });
    if (b.lazyDependency("wabt", .{
        .target = defaults.target,
        .optimize = defaults.optimize,
    })) |wabt| {
        const lib = b.addStaticLibrary(.{
            .name = "wabt",
            .target = static_target,
            .optimize = defaults.optimize,
        });
        lib.linkLibCpp();
        lib.addIncludePath(wabt.path("include"));
        lib.addIncludePath(b.path("src/include"));
        if (b.lazyDependency("wasmc", .{})) |wasmc| {
            lib.addIncludePath(wasmc.path("include"));
        }
        if (b.lazyDependency("picosha", .{})) |picosha| {
            lib.addIncludePath(picosha.path(""));
        }
        lib.addCSourceFiles(.{
            .files = libwabt_sources,
            .root = wabt.path("src"),
        });
        if (static_target.result.isWasm()) {
            lib.defineCMacro("_WASI_EMULATED_MMAN", null);
            lib.linkSystemLibrary("wasi-emulated-mman");
        } else {
            lib.addCSourceFiles(.{
                .files = wasm2c_sources,
                .root = wabt.path("wasm2c"),
            });
        }
        b.installArtifact(lib);

        inline for (wabt_tools) |exe_name| {
            const exe = b.addExecutable(.{
                .name = exe_name,
                .target = static_target,
                .optimize = defaults.optimize,
                .linkage = if (defaults.target.result.os.tag != .macos) .static else null,
            });
            exe.addCSourceFiles(.{
                .files = &.{"tools/" ++ exe_name ++ ".cc"},
                .root = wabt.path("src"),
            });
            exe.linkLibrary(lib);
            exe.addIncludePath(wabt.path("include"));
            exe.addIncludePath(b.path("src/include"));

            b.installArtifact(exe);
        }
    }
}

pub const wabt_tools = &.{
    "wasm2c",
    "wasm2wat",
    // "wasm2wat-fuzz",
    "wasm-decompile",
    "wasm-interp",
    // "wasm-objdump",
    // "wasm-stats",
    "wasm-strip",
    "wasm-validate",
    "wast2json",
    "wat2wasm",
    "wat-desugar",
};

pub const wasm2c_sources = &.{
    "wasm-rt-impl.c",
    "wasm-rt-exceptions-impl.c",
    "wasm-rt-mem-impl.c",
};

pub const libwabt_sources = &.{
    "apply-names.cc",
    "binary-reader-ir.cc",
    "binary-reader-logging.cc",
    "binary-reader.cc",
    "binary-writer-spec.cc",
    "binary-writer.cc",
    "binary.cc",
    "binding-hash.cc",
    "color.cc",
    "common.cc",
    "config.cc",
    "decompiler.cc",
    "error-formatter.cc",
    "expr-visitor.cc",
    "feature.cc",
    "filenames.cc",
    "generate-names.cc",
    "ir-util.cc",
    "ir.cc",
    "leb128.cc",
    "lexer-source-line-finder.cc",
    "lexer-source.cc",
    "literal.cc",
    "opcode-code-table.c",
    "opcode.cc",
    "option-parser.cc",
    "resolve-names.cc",
    "sha256.cc",
    "shared-validator.cc",
    "stream.cc",
    "token.cc",
    "tracing.cc",
    "type-checker.cc",
    "utf8.cc",
    "validator.cc",
    "wast-lexer.cc",
    "wast-parser.cc",
    "wat-writer.cc",
    "c-writer.cc",
    "prebuilt/wasm2c_header_top.cc",
    "prebuilt/wasm2c_header_bottom.cc",
    "prebuilt/wasm2c_source_includes.cc",
    "prebuilt/wasm2c_source_declarations.cc",
    "prebuilt/wasm2c_simd_source_declarations.cc",
    "prebuilt/wasm2c_atomicops_source_declarations.cc",
    "interp/binary-reader-interp.cc",
    "interp/interp.cc",
    "interp/interp-util.cc",
    "interp/istream.cc",
    "apply-names.cc",
    "binary-reader-ir.cc",
    "binary-reader-logging.cc",
    "binary-reader.cc",
    "binary-writer-spec.cc",
    "binary-writer.cc",
    "binary.cc",
    "binding-hash.cc",
    "color.cc",
    "common.cc",
    "config.cc",
    "decompiler.cc",
    "error-formatter.cc",
    "expr-visitor.cc",
    "feature.cc",
    "filenames.cc",
    "generate-names.cc",
    "ir-util.cc",
    "ir.cc",
    "leb128.cc",
    "lexer-source-line-finder.cc",
    "lexer-source.cc",
    "literal.cc",
    "opcode-code-table.c",
    "opcode.cc",
    "option-parser.cc",
    "resolve-names.cc",
    "sha256.cc",
    "shared-validator.cc",
    "stream.cc",
    "token.cc",
    "tracing.cc",
    "type-checker.cc",
    "utf8.cc",
    "validator.cc",
    "wast-lexer.cc",
    "wast-parser.cc",
    "wat-writer.cc",
    "c-writer.cc",
    "prebuilt/wasm2c_header_top.cc",
    "prebuilt/wasm2c_header_bottom.cc",
    "prebuilt/wasm2c_source_includes.cc",
    "prebuilt/wasm2c_source_declarations.cc",
    "prebuilt/wasm2c_simd_source_declarations.cc",
    "prebuilt/wasm2c_atomicops_source_declarations.cc",
    "interp/binary-reader-interp.cc",
    "interp/interp.cc",
    "interp/interp-util.cc",
    "interp/istream.cc",
    "interp/interp-wasm-c-api.cc",
};
