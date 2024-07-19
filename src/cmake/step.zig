const std = @import("std");
const Step = std.Build.Step;
const LazyPath = std.Build.LazyPath;
const CmakeStep = @This();
pub const Toolchain = @import("toolchain.zig");

step: Step,
source_dir: LazyPath,
build_dir: LazyPath,
install_dir: LazyPath,
run: *Step.Run,
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

    // we compile a simple tool to run both cmake and build step after one another,
    // and pass arguments for both to it
    // otherwise we cannot work with the zig cache, as cmake wants to know the output
    // directory of gmake
    const cm_runner = b.addExecutable(.{
        .name = "cmake_wrapper",
        .root_source_file = .{ .cwd_relative = "src/host/cmake_make_wrapper.zig" },
        .target = b.graph.host,
        .optimize = .Debug,
    });
    const bs_run = b.addRunArtifact(cm_runner);
    if (b.verbose) bs_run.stdio = .inherit;
    bs_run.addFileArg(tc.CMAKE);
    bs_run.addFileArg(tc.MAKE);
    const build_dir = bs_run.addOutputDirectoryArg("build");

    bs_run.addPrefixedDirectoryArg("@CMAKE:-H", opt.source_dir);
    inline for (.{
        .{ "@CMAKE:-DCMAKE_C_COMPILER=", tc.CC },
        .{ "@CMAKE:-DCMAKE_CXX_COMPILER=", tc.CXX },
        .{ "@CMAKE:-DCMAKE_MAKE_PROCESSOR=", tc.MAKE },
    }) |it| {
        bs_run.addPrefixedFileArg(it[0], it[1]);
    }
    bs_run.setEnvironmentVariable("ZIG", tc.ZIG);
    const cmake_output_dir = bs_run.addPrefixedOutputDirectoryArg(
        "@CMAKE:-DCMAKE_INSTALL_PREFIX=",
        "install",
    );

    const cpu_count = std.Thread.getCpuCount() catch @panic("Could not get CPU Count");
    const make_parallel = std.fmt.allocPrint(
        b.allocator,
        "@GMAKE:-j{d}",
        .{cpu_count},
    ) catch @panic("OOM");

    bs_run.addPrefixedFileArg("@GMAKE:", opt.toolchain.MAKE);
    bs_run.addPrefixedFileArg("@GMAKE:CC=", opt.toolchain.CC);
    bs_run.addPrefixedFileArg("@GMAKE:CXX=", opt.toolchain.CXX);
    bs_run.addArg("@GMAKE:install");
    bs_run.addArg(make_parallel);

    const self = b.allocator.create(CmakeStep) catch @panic("OOM");
    self.* = .{
        .source_dir = opt.source_dir,
        .build_dir = build_dir,
        .install_dir = cmake_output_dir,
        .run = bs_run,
        .toolchain = opt.toolchain,
        .step = Step.init(.{
            .id = .custom,
            .name = opt.name,
            .owner = b,
        }),
    };
    self.step.dependOn(&bs_run.step);
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
    const option = std.fmt.allocPrint(self.step.owner.allocator, "@CMAKE:-D{s}={s}", .{ key, value }) catch @panic("OOM");
    self.run.addArg(option);
}
