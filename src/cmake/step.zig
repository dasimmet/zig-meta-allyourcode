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
    //"-D" defines for cmake
    defines: []const struct { []const u8, []const u8 } = &.{},
    //store the built cmake in global instead of project local cache
    global_cache: bool = false,
    //additional options added to the MAKEFLAGS env var
    makeflags: []const u8 = "",
    name: []const u8,
    //remove the intermediate build directory
    remove_build: bool = false,
    //directory containing the CMakeLists.txt to build
    source_dir: LazyPath,
    //zig target to build for
    target: ?std.Build.ResolvedTarget,
    toolchain: ?*Toolchain = null,
    //show cmake output - defaults to b.verbose if unset
    verbose: ?bool = null,
};

pub fn init(b: *std.Build, opt: Options) *CmakeStep {
    const target = opt.target orelse b.graph.host;
    const target_triple = target.result.zigTriple(b.allocator) catch @panic("OOM");
    const tc = opt.toolchain orelse Toolchain.zigBuildDefaults(b, .{});

    const cpu_count = std.Thread.getCpuCount() catch blk: {
        std.log.err("Could not get CPU Count!", .{});
        break :blk 4;
    };

    const makeflags = std.fmt.allocPrint(
        b.allocator,
        "-j{d} {s}",
        .{ cpu_count, opt.makeflags },
    ) catch @panic("OOM");

    const bs_run = std.Build.Step.Run.create(b, opt.name);
    if (opt.verbose) |verbose| {
        if (verbose) bs_run.stdio = .inherit;
    } else if (b.verbose) bs_run.stdio = .inherit;

    bs_run.addFileArg(tc.CMAKE_BUILD_RUNNER);
    bs_run.setEnvironmentVariable("ZIG_CMAKE_REMOVE_BUILD_DIR", if (opt.remove_build) "1" else "0");
    bs_run.setEnvironmentVariable("ZIG_EXE", tc.ZIG_EXE);
    bs_run.setEnvironmentVariable("MAKEFLAGS", makeflags);
    bs_run.addFileArg(tc.CMAKE);
    bs_run.addFileArg(tc.MAKE);
    const build_dir = bs_run.addOutputDirectoryArg("build");
    const cmake_output_dir = bs_run.addOutputDirectoryArg(
        "install",
    );

    bs_run.addPrefixedDirectoryArg("@CM:", opt.source_dir);
    bs_run.addArg("@GM:install");
    inline for (.{
        .{ "@CM:-DCMAKE_C_COMPILER=", tc.CC },
        .{ "@CM:-DCMAKE_CXX_COMPILER=", tc.CXX },
    }) |it| {
        bs_run.addPrefixedFileArg(it[0], it[1]);
    }

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
    }) |it| {
        addCmakeDefine(self, it[0], it[1]);
    }
    for (opt.defines) |it|
        addCmakeDefine(self, it[0], it[1]);
    return self;
}

pub fn addCmakeDefine(self: *CmakeStep, key: []const u8, value: []const u8) void {
    const option = std.fmt.allocPrint(self.step.owner.allocator, "@CM:-D{s}={s}", .{ key, value }) catch @panic("OOM");
    self.run.addArg(option);
}

pub fn addCmakeFileDefine(self: *CmakeStep, key: []const u8, lp: std.Build.LazyPath) void {
    const option = std.fmt.allocPrint(self.step.owner.allocator, "@CM:-D{s}=", .{ key }) catch @panic("OOM");
    self.run.addPrefixedFileArg(option, lp);
}

pub fn addCmakeDirectoryDefine(self: *CmakeStep, key: []const u8, lp: std.Build.LazyPath) void {
    const option = std.fmt.allocPrint(self.step.owner.allocator, "@CM:-D{s}=", .{ key }) catch @panic("OOM");
    self.run.addPrefixedDirectoryArg(option, lp);
}

pub fn addCmakeArtifactDefine(self: *CmakeStep, key: []const u8, lp: *std.Build.Step.Compile) void {
    const option = std.fmt.allocPrint(self.step.owner.allocator, "@CM:-D{s}=", .{ key }) catch @panic("OOM");
    self.run.addPrefixedArtifactArg(option, lp);
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
