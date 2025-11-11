const std = @import("std");

pub fn main() !void {
    std.log.info("hello world!", .{});
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    const global_cache_root = args[1];
    try clean_cache_dir_entries_older_than(global_cache_root, 3600 * 24 * 90);
    const cache_root = args[2];
    try clean_cache_dir_entries_older_than(cache_root, 3600 * 24 * 90);
}

fn clean_cache_dir_entries_older_than(dir_abspath: []const u8, age: i128) !void {
    const cd = try std.fs.cwd().openDir(dir_abspath, .{
        .iterate = true,
    });
    var iter = cd.iterate();
    while (try iter.next()) |c_entry| {
        std.log.info("d: {s}{s}{s}", .{ dir_abspath, std.fs.path.sep_str, c_entry.name });
        inline for (.{ "o", "z", "h", "tmp" }) |dir| {
            if (c_entry.kind == .directory and std.mem.eql(u8, c_entry.name, dir)) {
                const cdo = try cd.openDir(c_entry.name, .{
                    .iterate = true,
                });
                try clean_dir_entries_older_than(cdo, age);
            }
        }
    }
}

fn clean_dir_entries_older_than(dir: std.fs.Dir, age: i128) !void {
    var cdo_iter = dir.iterate();
    const time = std.time.nanoTimestamp();
    while (try cdo_iter.next()) |cdo_entry| {
        const stat = try dir.statFile(cdo_entry.name);
        const age_diff = time - stat.mtime;
        if (@divFloor(age_diff, std.time.ns_per_s) > age) {
            std.log.info("o: {s} {d} {any}", .{ cdo_entry.name, @divFloor(age_diff, std.time.ns_per_s), stat });
            try dir.deleteTree(cdo_entry.name);
        }
    }
}
