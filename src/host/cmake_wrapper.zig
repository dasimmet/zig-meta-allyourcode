const std = @import("std");
const builtin = @import("builtin");

// run a zig cc subcommand with ZIG from env
pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var gen_args = std.ArrayList([]const u8).init(arena.allocator());
    var build_args = std.ArrayList([]const u8).init(arena.allocator());
    var p_args = std.process.args();
    var i: usize = 0;
    while (p_args.next()) |arg| : (i += 1) {
        if (i == 0) {} else if (i == 1) { // path to CMAKE
            try gen_args.append(arg);
        } else if (i == 2) { // path to GMAKE
            try build_args.append(arg);
        } else if (i == 3) { // path to build dir
            const gen_dir = try std.mem.join(
                arena.allocator(),
                "",
                &.{ "-B", arg },
            );
            try gen_args.append(gen_dir);
            try build_args.append("-C");
            try build_args.append(arg);
        } else if (std.mem.startsWith(u8, arg, "@CMAKE:")) {
            try gen_args.append(arg["@CMAKE:".len..]);
        } else if (std.mem.startsWith(u8, arg, "@GMAKE:")) {
            try build_args.append(arg["@GMAKE:".len..]);
        }
    }
    for (gen_args.items) |it| {
        debug_log("{s} ", .{it});
    }
    debug_log("\n", .{});
    for (build_args.items) |it| {
        debug_log("{s} ", .{it});
    }
    debug_log("\n", .{});
    try callChild(gen_args.items, arena.allocator());
    try callChild(build_args.items, arena.allocator());
}

fn callChild(args: []const []const u8, arena: std.mem.Allocator) !void {
    const stderr = std.io.getStdErr();
    const stdout = std.io.getStdOut();
    var proc = std.process.Child.init(
        args,
        arena,
    );
    proc.stdin_behavior = .Close;
    proc.stderr_behavior = .Pipe;
    proc.stdout_behavior = .Pipe;
    try proc.spawn();

    var poller = std.io.poll(proc.allocator, enum { stdout, stderr }, .{
        .stdout = proc.stdout.?,
        .stderr = proc.stderr.?,
    });
    defer poller.deinit();
    // var buf: [128]u8 = undefined;

    const stdout_f = poller.fifo(.stdout);
    const stderr_f = poller.fifo(.stderr);
    while (try poller.poll()) {
        while (stdout_f.count > 0) {
            const count = try stdout.write(stdout_f.buf[stdout_f.head..stdout_f.count]);
            stdout_f.discard(count);
        }
        while (stderr_f.count > 0) {
            const count = try stdout.write(stderr_f.buf[stderr_f.head..stderr_f.count]);
            stderr_f.discard(count);
        }
    }

    const res = try proc.wait();
    switch (res) {
        .Exited => |ex| {
            if (ex != 0) std.process.exit(res.Exited);
        },
        .Signal => {
            try stderr.writer().print(
                "Signal Received: {}\n",
                .{res.Signal},
            );
            unreachable;
        },
        .Stopped => {
            try stderr.writer().print(
                "Stopped: {}\n",
                .{res.Stopped},
            );
            unreachable;
        },
        .Unknown => {
            try stderr.writer().print(
                "Unknown: {}\n",
                .{res.Unknown},
            );
            unreachable;
        },
    }
}

fn debug_log(comptime fmt: []const u8, args: anytype) void {
    if (builtin.mode == .Debug) {
        std.debug.print(fmt, args);
    }
}