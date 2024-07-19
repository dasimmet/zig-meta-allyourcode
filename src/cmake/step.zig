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

pub const Options = struct {
    target: ?std.Build.ResolvedTarget,
    name: []const u8,
    source_dir: LazyPath,
    toolchain: ?*Toolchain = null,
};

pub fn init(b: *std.Build, opt: Options) *CmakeStep {
    const target = opt.target orelse b.graph.host;
    const target_triple = target.result.zigTriple(b.allocator) catch @panic("OOM");
    const tc = opt.toolchain orelse Toolchain.zigBuildDefaults(b, null);

    const cpu_count = std.Thread.getCpuCount() catch blk: {
        std.log.err("Could not get CPU Count!", .{});
        break :blk 4;
    };

    const makeflags = std.fmt.allocPrint(
        b.allocator,
        "-j{d}",
        .{cpu_count},
    ) catch @panic("OOM");

    // we compile a simple tool to run both cmake and build step after one another,
    // and pass arguments for both to it
    // otherwise we cannot work with the zig cache, as cmake wants to know the output
    // directory of gmake
    const bs_run = std.Build.Step.Run.create(b, "cmake");
    bs_run.addFileArg(tc.CMAKE_WRAPPER);
    bs_run.setEnvironmentVariable("ZIG", tc.ZIG);
    bs_run.setEnvironmentVariable("MAKEFLAGS", makeflags);
    if (b.verbose) bs_run.stdio = .inherit;

    bs_run.addFileArg(tc.CMAKE);
    bs_run.addFileArg(tc.MAKE);
    const build_dir = bs_run.addOutputDirectoryArg("build");

    bs_run.addPrefixedDirectoryArg("@CM:", opt.source_dir);
    inline for (.{
        .{ "@CM:-DCMAKE_C_COMPILER=", tc.CC },
        .{ "@CM:-DCMAKE_CXX_COMPILER=", tc.CXX },
        .{ "@CM:-DCMAKE_MAKE_PROCESSOR=", tc.MAKE },
    }) |it| {
        bs_run.addPrefixedFileArg(it[0], it[1]);
    }
    const cmake_output_dir = bs_run.addPrefixedOutputDirectoryArg(
        "@CM:-DCMAKE_INSTALL_PREFIX=",
        "install",
    );
    bs_run.addArg("@GM:install");

    const self = b.allocator.create(CmakeStep) catch @panic("OOM");
    self.* = .{
        .source_dir = opt.source_dir,
        .build_dir = build_dir,
        .install_dir = cmake_output_dir,
        .run = bs_run,
        .toolchain = opt.toolchain.?,
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
        .{ "CMAKE_C_COMPILER_WORKS", "1" }, // f-ing cmake writes a "-" file to the source dir without this
    }) |it| {
        addCmakeDefine(self, it[0], it[1]);
    }
    return self;
}

pub fn addCmakeDefine(self: *CmakeStep, key: []const u8, value: []const u8) void {
    const option = std.fmt.allocPrint(self.step.owner.allocator, "@CM:-D{s}={s}", .{ key, value }) catch @panic("OOM");
    self.run.addArg(option);
}

//generates a reusable namedWriteFile depending on generate and install
pub fn installNamedWriteFile(self: *CmakeStep, b: *std.Build, name: []const u8) *std.Build.Step.WriteFile {
    const wf = b.addNamedWriteFiles(name);
    _ = wf.addCopyDirectory(self.install_dir, "", .{});
    wf.step.dependOn(&self.step);
    return wf;
}

pub fn install(self: *CmakeStep, b: *std.Build, subdir: []const u8) *std.Build.Step.InstallDir {
    return b.addInstallDirectory(.{
        .install_dir = .{ .custom = "" },
        .source_dir = self.install_dir,
        .install_subdir = subdir,
    });
}
