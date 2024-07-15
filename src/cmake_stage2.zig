const std = @import("std");
const Toolchain = @import("cmake_toolchain.zig");

pub fn build(b: *std.Build, tc: Toolchain) std.Build.LazyPath {
    const bs_run = std.Build.Step.Run.create(b, "cmake_stage2");
    bs_run.addFileArg(tc.CMAKE);
    // const bs_run = b.addRunArtifact(bootstrap_exe);
    const stage2_path = b.makeTempPath();
    const stage2_path_arg = std.mem.join(b.allocator, "", &.{
        "-DCMAKE_DUMMY_CWD_ARG=",
        stage2_path,
    }) catch @panic("OOM");
    bs_run.setCwd(.{ .cwd_relative = stage2_path });
    bs_run.addDirectoryArg(b.path(""));
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
    bs_run.has_side_effects = true;
    const cmake_output_dir = bs_run.addPrefixedOutputDirectoryArg("-DCMAKE_INSTALL_PREFIX=", "cmake_install");
    return cmake_output_dir;
}
