const std = @import("std");

// run a zig cc subcommand with ZIG from env
pub fn main() !void {
    return subcommand("ZIG_EXE", &.{"cc"});
}

// takes a path from the environment and calls its subcommand
pub fn subcommand(env_key: []const u8, cmd: []const []const u8) !void {
    const stderr = std.io.getStdErr();
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var env = try std.process.getEnvMap(arena.allocator());
    var args = std.ArrayList([]const u8).init(arena.allocator());
    var subcommand_found = false;
    if (env.get(env_key)) |subcommand_exe| {
        try args.append(subcommand_exe);
        subcommand_found = true;
    }
    try args.appendSlice(cmd);
    var p_args = std.process.args();
    var last_arg: []const u8 = "";
    var i: usize = 0;
    while (p_args.next()) |arg| : (i += 1) {
        if (i == 0) {
            if (!subcommand_found) {
                const message =
                    \\
                    \\Error: this executable ({s}) needs the
                    \\{s} environment variable pointing to the subcommand executable,
                    \\so it can run "{s} {s}"
                    \\
                    \\
                ;
                try stderr.writer().print(message, .{ arg, env_key, arg, cmd });
                std.process.exit(1);
            }
        } else {
            // workaround for zig c++ not writing to stdout. this only works on unix hosts
            const is_stdout_arg = std.mem.eql(u8, last_arg, "-o") and std.mem.eql(u8, arg, "-");
            if (is_stdout_arg and canWriteDevStdout()) {
                try args.append("/dev/stdout");
            } else {
                try args.append(arg);
            }
        }
        last_arg = arg;
    }
    var proc = std.process.Child.init(
        args.items,
        arena.allocator(),
    );
    proc.stderr_behavior = .Inherit;
    proc.stdin_behavior = .Inherit;
    proc.stdout_behavior = .Inherit;
    try proc.spawn();
    switch (try proc.wait()) {
        .Exited => |exit| std.process.exit(exit),
        .Signal => |sig| {
            std.log.err("Signal Received: {d}\n", .{sig});
            unreachable;
        },
        .Stopped => |stop| {
            std.log.err("Stopped: {d}\n", .{stop});
            unreachable;
        },
        .Unknown => |unknown| {
            std.log.err("Unknown: {d}\n", .{unknown});
            unreachable;
        },
    }
}

fn canWriteDevStdout() bool {
    std.fs.accessAbsolute("/dev/stdout", .{ .mode = .write_only })
        catch return false;
    return true;
}