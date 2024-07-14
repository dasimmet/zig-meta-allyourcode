const std = @import("std");

// run a zig cc subcommand with ZIG from env
pub fn main() !void {
    return subcommand("cc");
}
pub fn subcommand(cmd: []const u8) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var env = try std.process.getEnvMap(arena.allocator());
    var args = std.ArrayList([]const u8).init(arena.allocator());
    try args.append(env.get("ZIG").?);
    try args.append(cmd);
    var p_args = std.process.args();
    var i: usize = 0;
    while (p_args.next()) |arg| : (i += 1) {
        if (i == 0) {
        } else {
            try args.append(arg);
        }
    }
    for (args.items) |it| {
        std.debug.print("{s} ", .{it});
    }
    var proc = std.process.Child.init(
        args.items,
        arena.allocator(),
    );
    proc.stderr_behavior = .Inherit;
    proc.stdin_behavior = .Inherit;
    proc.stdout_behavior = .Inherit;
    try proc.spawn();
    const res = try proc.wait();
    switch (res) {
        .Exited => 
            std.process.exit(res.Exited),
        .Signal => {
            std.debug.print("Signal Received: {}\n", .{res.Signal});
            unreachable;
        },
        .Stopped => {
            std.debug.print("Stopped: {}\n", .{res.Stopped});
            unreachable;

        },
        .Unknown => {
            std.debug.print("Unknown: {}\n", .{res.Stopped});
            unreachable;
        },
    }
}
