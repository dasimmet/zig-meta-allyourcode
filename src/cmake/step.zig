const std = @import("std");
const Step = std.Build.Step;
const LazyPath = std.Build.LazyPath;
const CmakeStep = @This();
pub const Toolchain = @import("toolchain.zig");

step: Step,
source_dir: LazyPath,
generate_dir: LazyPath,
install_dir: LazyPath,
generate: *Step.Run,
compile: *Step.Run,
toolchain: *Toolchain,

const Options = struct {
    target: std.Build.ResolvedTarget,
    name: []const u8,
    source_dir: LazyPath,
    toolchain: *Toolchain,
};

pub fn init(b: *std.Build, opt: Options) *CmakeStep {
    const target_triple = opt.target.result.zigTriple(b.allocator) catch @panic("OOM");
    const tc = opt.toolchain;
    const bs_run = std.Build.Step.Run.create(b, "cmake_generate");
    bs_run.addFileArg(tc.CMAKE);

    const stage2_path = bs_run.addPrefixedOutputDirectoryArg("-B", "cmake_generate");
    bs_run.addPrefixedDirectoryArg("-H", opt.source_dir);
    inline for (.{
        .{ "-DCMAKE_C_COMPILER=", tc.CC },
        .{ "-DCMAKE_CXX_COMPILER=", tc.CXX },
        .{ "-DCMAKE_MAKE_PROCESSOR=", tc.MAKE },
    }) |it| {
        bs_run.addPrefixedFileArg(it[0], it[1]);
    }
    bs_run.setEnvironmentVariable("ZIG", tc.ZIG);
    const cmake_output_dir = bs_run.addPrefixedOutputDirectoryArg("-DCMAKE_INSTALL_PREFIX=", "cmake_install");

    const cpu_count = std.Thread.getCpuCount() catch @panic("Could not get CPU Count");
    const make_parallel = std.fmt.allocPrint(b.allocator, "-j{d}", .{cpu_count}) catch @panic("OOM");

    const cmake_compile = Step.Run.create(b, "cmake_build");
    cmake_compile.addFileArg(opt.toolchain.MAKE);
    cmake_compile.addPrefixedFileArg("CC=",opt.toolchain.CC);
    cmake_compile.addPrefixedFileArg("CXX=",opt.toolchain.CXX);
    cmake_compile.addArg("-C");
    cmake_compile.addDirectoryArg(stage2_path);
    cmake_compile.addArg("install");
    cmake_compile.addArg(make_parallel);

    cmake_compile.step.dependOn(&bs_run.step);
    cmake_compile.setEnvironmentVariable("ZIG", opt.toolchain.ZIG);

    const self = b.allocator.create(CmakeStep) catch @panic("OOM");
    self.* = .{
        .source_dir = opt.source_dir,
        .generate_dir = stage2_path,
        .install_dir = cmake_output_dir,
        .generate = bs_run,
        .compile = cmake_compile,
        .toolchain = opt.toolchain,
        .step = Step.init(.{
            .id = .custom,
            .name = opt.name,
            .owner = b,
        }),
    };
    self.step.dependOn(&cmake_compile.step);
    inline for (.{
        .{ "CMAKE_C_COMPILER_TARGET", target_triple },
        .{ "CMAKE_CXX_COMPILER_TARGET", target_triple },
    }) |it| {
        addCmakeDefine(self, it[0], it[1]);
    }
    return self;
}

//generates a reusable namedWriteFile depending on generate and install
pub fn getInstallDir(self: *CmakeStep) *std.Build.Step.WriteFile {
    const wf = self.step.owner.addNamedWriteFiles(self.step.name);
    _ = wf.addCopyDirectory(self.install_dir, "", .{});
    wf.step.dependOn(&self.step);
    return wf;
}

pub fn addCmakeDefine(self: *CmakeStep, key: []const u8, value: []const u8) void {
    const option = std.fmt.allocPrint(self.step.owner.allocator, "-D{s}={s}", .{ key, value }) catch @panic("OOM");
    self.generate.addArg(option);
}