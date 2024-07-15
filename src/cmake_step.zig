const std = @import("std");
const Step = std.Build.Step;
const LazyPath = std.Build.LazyPath;
const CmakeStep = @This();
pub const Toolchain = @import("cmake_toolchain.zig");

step: Step,
source_dir: LazyPath,
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
    // const bs_run = b.addRunArtifact(bootstrap_exe);
    const stage2_path = b.makeTempPath();
    const stage2_path_arg = std.mem.join(b.allocator, "", &.{
        "-DCMAKE_DUMMY_CWD_ARG=",
        stage2_path,
    }) catch @panic("OOM");
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
    inline for (.{
        "-DBUILD_CMAKE_FROM_SOURCE=1",
        "-DCMAKE_BIN_DIR=",
        "-DCMAKE_BOOTSTRAP=1",
        "-DCMAKE_DATA_DIR=",
        "-DCMAKE_DOC_DIR=",
        "-DCMAKE_MAN_DIR=",
        "-DCMAKE_USE_SYSTEM_LIBRARIES=0",
        "-DCMAKE_XDGDATA_DIR=",
    }) |arg| {
        bs_run.addArg(arg);
    }
    bs_run.addArg(stage2_path_arg);
    const cmake_output_dir = bs_run.addPrefixedOutputDirectoryArg("-DCMAKE_INSTALL_PREFIX=", "cmake_install");

    const cmake_compile = Step.Run.create(b, "cmake_compile");
    cmake_compile.step.dependOn(&bs_run.step);
    cmake_compile.setEnvironmentVariable("ZIG", opt.toolchain.ZIG);
    cmake_compile.addFileArg(opt.toolchain.MAKE);
    cmake_compile.addArg("-C");
    cmake_compile.addArg(stage2_path);
    cmake_compile.addArg("install");

    const self = b.allocator.create(CmakeStep) catch @panic("OOM");
    self.* = .{
        .source_dir = opt.source_dir,
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
    self.step.dependOn(&self.compile.step);
    return self;
}
