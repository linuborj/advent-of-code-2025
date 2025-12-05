const std = @import("std");
const common = @import("common");
const mecha = @import("mecha");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const input = try common.readInput(allocator, "dayXX");
    defer allocator.free(input);

    const part1Result = try part1(allocator, input);
    std.debug.print("Part 1: {}\n", .{part1Result});

    const part2Result = try part2(allocator, input);
    std.debug.print("Part 2: {}\n", .{part2Result});
}

fn part1(allocator: std.mem.Allocator, input: []const u8) !i64 {
    _ = allocator;
    _ = input;
    // TODO: implement once problem is released
    return 0;
}

fn part2(allocator: std.mem.Allocator, input: []const u8) !i64 {
    _ = allocator;
    _ = input;
    // TODO: implement once problem is released
    return 0;
}

test "part1 example" {
    const input = common.trimInput(
        \\paste
        \\example
        \\here
    );
    try common.expectResult(i64, 0, part1(std.testing.allocator, input));
}

test "part2 example" {
    const input = common.trimInput(
        \\paste
        \\example
        \\here
    );
    try common.expectResult(i64, 0, part2(std.testing.allocator, input));
}
