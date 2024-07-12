const std = @import("std");

const FunctionStep = @This();

pub const CacheFunction = *const fn(*Args) anyerror!void;
pub const MakeFunction = *const fn(*Args) anyerror!void;
pub const Args = struct {
    step: *std.Build.Step,
    name: []const u8,
    ctx: ?*anyopaque = null,
    man: *std.Build.Cache.Manifest,
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

pub fn init(b: *std.Build, opt: Options) *FunctionStep {
    const self = b.allocator.create(FunctionStep)
        catch @panic("OOM");
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
    };
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
        .name = self.step.name,
        .man = &man,
    }; 
    try self.cacheFunc(&args);
    if (try step.cacheHit(&man)) {
        std.debug.print("CACHED: {any}\n", .{self.ctx});
    } else {
        try self.makeFunc(&args);
        try man.writeManifest();
    }
    prog_node.completeOne();
}