const std = @import("std");
const Step = std.Build.Step;
const LazyPath = std.Build.LazyPath;
const CmakeStep = @This();
pub const Toolchain = @import("cmake_toolchain.zig");

step: Step,
source_dir: LazyPath,
generate_dir: []const u8,
install_dir: LazyPath,
generate: *Step.Run,
compile: *Step.Run,
toolchain: Toolchain,

const Options = struct {
    name: []const u8,
    source_dir: LazyPath,
    toolchain: Toolchain = .{},
};

pub fn init(b: *std.Build, opt: Options) *CmakeStep {
    const tc = opt.toolchain;
    const bs_run = std.Build.Step.Run.create(b, "cmake_stage2");
    bs_run.addFileArg(tc.CMAKE);
    const stage2_path = b.makeTempPath();
    bs_run.setCwd(.{ .cwd_relative = stage2_path });
    bs_run.addDirectoryArg(opt.source_dir);
    inline for (.{
        .{ "-DCMAKE_C_COMPILER=", tc.CC },
        .{ "-DCMAKE_CXX_COMPILER=", tc.CXX },
        .{ "-DCMAKE_MAKE_PROCESSOR=", tc.MAKE },
    }) |it| {
        bs_run.addPrefixedDirectoryArg(it[0], it[1]);
    }
    bs_run.setEnvironmentVariable("ZIG", tc.ZIG);
    const cmake_output_dir = bs_run.addPrefixedOutputDirectoryArg("-DCMAKE_INSTALL_PREFIX=", "cmake_install");

    const cmake_compile = Step.Run.create(b, "cmake_compile");
    cmake_compile.step.dependOn(&bs_run.step);
    cmake_compile.setEnvironmentVariable("ZIG", opt.toolchain.ZIG);
    const cpu_count = std.Thread.getCpuCount() catch @panic("Could not get CPU Count");
    const makeflags = std.fmt.allocPrint(b.allocator, "-j{d}", .{cpu_count}) catch @panic("OOM");
    cmake_compile.setCwd(.{ .cwd_relative = stage2_path });
    cmake_compile.setEnvironmentVariable("MAKEFLAGS", makeflags);
    cmake_compile.addFileArg(opt.toolchain.MAKE);
    cmake_compile.addArg("install");

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
            .makeFn = make,
        }),
    };
    self.step.dependOn(&cmake_compile.step);
    return self;
}

pub fn addCmakeDefine(self: *CmakeStep, key: []const u8, value: []const u8) void {
    const b = self.step.owner;
    const option = std.fmt.allocPrint(b.allocator, "-D{s}={s}", .{ key, value }) catch @panic("OOM");
    self.generate.addArg(option);
}

fn make(step: *Step, prog_node: std.Progress.Node) anyerror!void {
    const self: *CmakeStep = @fieldParentPtr("step", step);
    _ = prog_node;
    try std.fs.deleteTreeAbsolute(self.generate_dir);
}
