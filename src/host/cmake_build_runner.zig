const std = @import("std");
const builtin = @import("builtin");

// run both cmake configure and make command in two subsequent subprocesses
// forwarding stdio through pipes
pub fn main() !void {
    const stderr = std.io.getStdErr();
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var gen_args = std.ArrayList([]const u8).init(arena.allocator());
    var build_args = std.ArrayList([]const u8).init(arena.allocator());
    var build_dir: []const u8 = undefined;
    var p_args = std.process.args();
    var i: usize = 0;
    var arg0: []const u8 = undefined;
    while (p_args.next()) |arg| : (i += 1) {
        if (i == 0) {
            arg0 = arg;
        } else if (i == 1) { // path to CMAKE
            try gen_args.append(arg);
        } else if (i == 2) { // path to GMAKE
            try build_args.append(arg);
        } else if (i == 3) { // path to build dir
            build_dir = arg;
            const gen_dir_arg = try std.mem.join(
                allocator,
                "",
                &.{ "-B", arg },
            );
            try gen_args.append(gen_dir_arg);
            try build_args.append("-C");
            try build_args.append(arg);
        } else if (std.mem.startsWith(u8, arg, "@CM:")) {
            try gen_args.append(arg[4..]);
        } else if (std.mem.startsWith(u8, arg, "@GM:")) {
            try build_args.append(arg[4..]);
        } else {
            const msg =
                \\ unknown argument. this command "{s}" expects
                \\ @CM: or @GM: prefixes on arguments: "{s}"
                \\
            ;
            try stderr.writer().print(msg, .{ arg0, arg });
            return error.UnknownArgument;
        }
    }

    if (builtin.mode == .Debug or builtin.mode == .ReleaseSafe) {
        try stderr.writer().print("cmake cmd: ", .{});
        for (gen_args.items) |it| {
            try stderr.writer().print("{s} ", .{it});
        }
        try stderr.writer().print("\nmake cmd: ", .{});
        for (build_args.items) |it| {
            try stderr.writer().print("{s} ", .{it});
        }
        try stderr.writer().print("\n", .{});
    }

    try callChild(gen_args.items, arena.allocator());
    try callChild(build_args.items, arena.allocator());
    const env = try std.process.getEnvMap(arena.allocator());
    if (env.get("ZIG_CMAKE_RELEASE_BUILD")) |env_v| {
        if (std.mem.eql(u8, env_v, "1")) {
            try std.fs.deleteTreeAbsolute(build_dir);
        }
    }
}

fn callChild(args: []const []const u8, arena: std.mem.Allocator) !void {
    const stderr = std.io.getStdErr();
    var proc = std.process.Child.init(
        args,
        arena,
    );
    proc.stdin_behavior = .Close;
    proc.stderr_behavior = .Pipe;
    proc.stdout_behavior = .Pipe;
    try proc.spawn();

    try forward_stdio_pipes(&proc);

    switch (try proc.wait()) {
        .Exited => |ex| {
            if (ex != 0) std.process.exit(ex);
        },
        .Signal => |sig| {
            try stderr.writer().print(
                "Signal Received: {d}\n",
                .{sig},
            );
            unreachable;
        },
        .Stopped => |stop| {
            try stderr.writer().print(
                "Stopped: {d}\n",
                .{stop},
            );
            unreachable;
        },
        .Unknown => |unknown| {
            try stderr.writer().print(
                "Unknown: {d}\n",
                .{unknown},
            );
            unreachable;
        },
    }
}

fn forward_stdio_pipes(proc: *std.process.Child) !void {
    const stderr = std.io.getStdErr();
    const stdout = std.io.getStdOut();

    var poller = std.io.poll(proc.allocator, enum { stdout, stderr }, .{
        .stdout = proc.stdout.?,
        .stderr = proc.stderr.?,
    });
    defer poller.deinit();
    const stdout_f = poller.fifo(.stdout);
    const stderr_f = poller.fifo(.stderr);
    while (try poller.poll()) {
        while (stdout_f.count > 0) {
            const count = try stdout.write(stdout_f.buf[stdout_f.head..stdout_f.count]);
            stdout_f.discard(count);
        }
        while (stderr_f.count > 0) {
            const count = try stderr.write(stderr_f.buf[stderr_f.head..stderr_f.count]);
            stderr_f.discard(count);
        }
    }
}
