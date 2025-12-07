const std = @import("std");
const common = @import("common");
const mecha = @import("mecha");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const input = try common.readInput(allocator, "day07");
    defer allocator.free(input);

    const part1Result = try part1(allocator, input);
    std.debug.print("Part 1: {}\n", .{part1Result});

    const part2Result = try part2(allocator, input);
    std.debug.print("Part 2: {}\n", .{part2Result});
}

fn part1(allocator: std.mem.Allocator, input: []const u8) !u64 {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    var lineIterator = std.mem.splitScalar(u8, input, '\n');
    var lineArray: std.ArrayListUnmanaged([]u8) = .empty;
    while (lineIterator.next()) |line| {
        if (line.len == 0) continue;
        const mutableLine = try arena.allocator().dupe(u8, line);
        try lineArray.append(arena.allocator(), mutableLine);
    }

    var lines = lineArray.items;
    const height = lines.len;
    const width = lines[0].len;

    var total: u64 = 0;

    for (1..height) |y| {
        for (0..width) |x| {
            const above = lines[y - 1][x];
            const current = &lines[y][x];

            if (current.* == '^' and above == '|') {
                total += 1;
                if (x > 0) {
                    const left = &lines[y][x - 1];
                    if (left.* == '.') {
                        left.* = '|';
                    }
                }
                if (x < width - 1) {
                    const right = &lines[y][x + 1];
                    if (right.* == '.') {
                        right.* = '|';
                    }
                }
            } else if ((above == 'S' or above == '|') and current.* == '.') {
                current.* = '|';
            }
        }
    }

    return total;
}

const Cell = struct {
    char: u8,
    value: u64 = 0,
};

fn part2(allocator: std.mem.Allocator, input: []const u8) !u64 {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    var lineIterator = std.mem.splitScalar(u8, input, '\n');
    var lineArray: std.ArrayListUnmanaged([]Cell) = .empty;
    while (lineIterator.next()) |line| {
        if (line.len == 0) continue;
        const mutableLine = try arena.allocator().alloc(Cell, line.len);
        for (mutableLine, line) |*dest, src| {
            dest.* = .{ .char = src };
        }
        try lineArray.append(arena.allocator(), mutableLine);
    }

    var lines = lineArray.items;
    const height = lines.len;
    const width = lines[0].len;
    var total: u64 = 0;

    for (1..height) |y| {
        for (0..width) |x| {
            const above = lines[y - 1][x];
            const current = &lines[y][x];

            if (current.char == '^' and above.char == '|') {
                if (x > 0) {
                    const left = &lines[y][x - 1];
                    if (left.char == '.' or left.char == '|') {
                        left.char = '|';
                        left.value += above.value;
                    }
                }
                if (x < width - 1) {
                    const right = &lines[y][x + 1];
                    if (right.char == '.' or right.char == '|') {
                        right.char = '|';
                        right.value += above.value;
                    }
                }
            } else if (above.char == 'S') {
                current.char = '|';
                current.value = 1;
            } else if (above.char == '|' and (current.char == '.' or current.char == '|')) {
                current.char = '|';
                current.value += above.value;
            }

            if (y == height - 1 and current.char == '|') total += current.value;
        }
    }

    return total;
}

test "part1 example" {
    const input = common.trimInput(
        \\.......S.......
        \\...............
        \\.......^.......
        \\...............
        \\......^.^......
        \\...............
        \\.....^.^.^.....
        \\...............
        \\....^.^...^....
        \\...............
        \\...^.^...^.^...
        \\...............
        \\..^...^.....^..
        \\...............
        \\.^.^.^.^.^...^.
        \\...............
    );
    try common.expectResult(u64, 21, part1(std.testing.allocator, input));
}

test "part2 example" {
    const input = common.trimInput(
        \\.......S.......
        \\...............
        \\.......^.......
        \\...............
        \\......^.^......
        \\...............
        \\.....^.^.^.....
        \\...............
        \\....^.^...^....
        \\...............
        \\...^.^...^.^...
        \\...............
        \\..^...^.....^..
        \\...............
        \\.^.^.^.^.^...^.
        \\...............
    );
    try common.expectResult(u64, 40, part2(std.testing.allocator, input));
}
