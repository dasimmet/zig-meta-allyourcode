
const std = @import("std");
const DefaultBuildOptions = @import("../build.zig").DefaultBuildOptions;

pub fn addBuild(b: *std.Build, defaults: DefaultBuildOptions) void {
    if (b.lazyDependency("wabt", .{
        .target = defaults.target,
        .optimize = defaults.optimize,
    })) |wabt| {
        const lib = b.addStaticLibrary(.{
            .name = "wabt",
            .target = defaults.target,
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
            .files = &.{
                "wasm2c/wasm-rt-impl.c",
                "wasm2c/wasm-rt-exceptions-impl.c",
                "wasm2c/wasm-rt-mem-impl.c",
            },
            .root = wabt.path(""),
        });
        lib.addCSourceFiles(.{
            .files = &.{
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
            },
            .root = wabt.path("src"),
        });
        b.installArtifact(lib);

        const exe = b.addExecutable(.{
            .name = "wasm2wat",
            .target = b.resolveTargetQuery(.{
                .cpu_arch = .x86_64,
                .os_tag = .linux,
                .abi = .musl,
            }),
            .optimize = defaults.optimize,
            .linkage = .static,
        });
        exe.addCSourceFiles(.{
            .files = &.{"tools/wasm2wat.cc"},
            .root = wabt.path("src"),
        });
        // exe.linkLibCpp();
        exe.linkLibrary(lib);
        exe.addIncludePath(wabt.path("include"));
        exe.addIncludePath(b.path("src/include"));
        // if (b.lazyDependency("wasmc", .{})) |wasmc| {
        //     exe.addIncludePath(wasmc.path("include"));
        // }
        // if (b.lazyDependency("picosha", .{})) |picosha| {
        //     exe.addIncludePath(picosha.path(""));
        // }

        // b.installArtifact(exe);
    }
}
