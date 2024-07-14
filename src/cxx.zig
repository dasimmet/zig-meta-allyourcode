const cc = @import("cc.zig");

pub fn main() !void {
    return cc.subcommand("c++");
}