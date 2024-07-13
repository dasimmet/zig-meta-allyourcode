const std = @import("std");

const FunctionStep = @This();

pub const CacheFunction = *const fn (*Args) anyerror!void;
pub const MakeFunction = *const fn (*Args) anyerror!void;
pub const Args = struct {
    step: *std.Build.Step,
    ctx: ?*anyopaque = null,
    man: *std.Build.Cache.Manifest,
    hash: *std.Build.GeneratedFile,
    pub fn globalDir(self: *Args) []const u8 {
        return self.step.owner.pathJoin(&.{
            self.step.owner.graph.global_cache_root.path.?,
            "o",
            self.hash.path.?,
        });
    }
};

pub const Options = struct {
    name: ?[]const u8 = "",
    cacheFunc: CacheFunction,
    makeFunc: MakeFunction,
    ctx: ?*anyopaque = null,
};
step: std.Build.Step,
cacheFunc: CacheFunction,
makeFunc: MakeFunction,
ctx: ?*anyopaque = null,
hash: std.Build.GeneratedFile,

pub fn init(b: *std.Build, opt: Options) *FunctionStep {
    const self = b.allocator.create(FunctionStep) catch @panic("OOM");
    self.* = .{
        .step = std.Build.Step.init(.{
            .owner = b,
            .makeFn = make,
            .name = opt.name orelse "FunctionStep",
            .id = .custom,
        }),
        .cacheFunc = opt.cacheFunc,
        .makeFunc = opt.makeFunc,
        .ctx = opt.ctx,
        .hash = .{ .step = undefined },
    };
    self.hash.step = &self.step;
    return self;
}

fn make(step: *std.Build.Step, prog_node: std.Progress.Node) anyerror!void {
    const b = step.owner;
    const self: *FunctionStep = @fieldParentPtr("step", step);
    var man = b.graph.cache.obtain();
    defer man.deinit();

    prog_node.setEstimatedTotalItems(1);
    var args: Args = .{
        .step = step,
        .ctx = self.ctx,
        .man = &man,
        .hash = &self.hash,
    };
    try self.cacheFunc(&args);
    if (try step.cacheHit(&man)) {
        self.hash.path = b.dupe(&man.final());
        std.debug.print("CACHED: {any}\n", .{self.hash.getPath()});
    } else {
        self.hash.path = b.dupe(&man.final());
        try self.makeFunc(&args);
        try man.writeManifest();
    }
    prog_node.completeOne();
}
