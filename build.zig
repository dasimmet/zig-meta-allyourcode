// meta-allyourcode
//
// by Tobias Simetsreiter <dasimmet@gmail.com>
//

const std = @import("std");
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    _ = target;
    _ = optimize;
}
