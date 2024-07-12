const std = @import("std");

const FunctionStep = @This();

pub const CacheFunction = *const fn(*std.Build.Cache.Manifest, ?*anyopaque) anyerror!void;
pub const MakeFunction = *const fn(*std.Build.Cache.Manifest, ?*anyopaque) anyerror!void;
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
            .name = opt.name orelse "func",
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
    try self.cacheFunc(&man, self.ctx);
    if (try step.cacheHit(&man)) {
        std.debug.print("CACHED: {any}\n", .{self.ctx});
    } else {
        try self.makeFunc(&man, self);
        try man.writeManifest();
        std.debug.print("WOLOLO: {x}\n", .{std.fmt.fmtSliceHexLower(&man.final())});
        std.debug.print("WOLOLO: {x}\n", .{std.fmt.fmtSliceHexLower(&man.final())});
    }
    prog_node.completeOne();
}