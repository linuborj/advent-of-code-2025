const std = @import("std");
const common = @import("common");
const mecha = @import("mecha");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const input = try common.readInput(allocator, "day01");
    defer allocator.free(input);

    const part1Result = try part1(allocator, input);
    std.debug.print("Part 1: {}\n", .{part1Result});

    const part2Result = try part2(allocator, input);
    std.debug.print("Part 2: {}\n", .{part2Result});
}

const Direction = enum { L, R };

const Instruction = struct {
    dir: Direction,
    dist: i64,
};

const dirParser = mecha.oneOf(.{
    mecha.ascii.char('L').mapConst(Direction.L),
    mecha.ascii.char('R').mapConst(Direction.R),
});
const lineParser = mecha.combine(.{ dirParser, mecha.int(i64, .{}) })
    .map(struct {
    fn f(tuple: std.meta.Tuple(&.{ Direction, i64 })) Instruction {
        return .{ .dir = tuple[0], .dist = tuple[1] };
    }
}.f);
const inputParser = lineParser.many(.{ .separator = mecha.ascii.char('\n').opt().discard() });

fn part1(allocator: std.mem.Allocator, input: []const u8) !i64 {
    const result = try inputParser.parse(allocator, input);
    const instructions = result.value.ok;
    defer allocator.free(instructions);
    var position: i64 = 50;
    var password: i64 = 0;
    for (instructions) |instruction| {
        position += if (instruction.dir == Direction.L) (-instruction.dist) else instruction.dist;
        position = @mod(position, 100);
        if (position == 0) {
            password += 1;
        }
    }

    return password;
}

fn part2(allocator: std.mem.Allocator, input: []const u8) !i64 {
    const result = try inputParser.parse(allocator, input);
    const instructions = result.value.ok;
    defer allocator.free(instructions);
    var position: i64 = 50;
    var password: i64 = 0;
    for (instructions) |instruction| {
        const newPosition = position + if (instruction.dir == Direction.L) -instruction.dist else instruction.dist;
        const offset: i64 = if (instruction.dir == Direction.L) (-1) else 0;
        password += @intCast(@abs(@divFloor(newPosition + offset, 100) - @divFloor(position + offset, 100)));
        position = @mod(newPosition, 100);
    }

    return password;
}

test "part1 example" {
    const input = common.trimInput("L68\nL30\nR48\nL5\nR60\nL55\nL1\nL99\nR14\nL82");
    try common.expectResult(i64, 3, part1(std.testing.allocator, input));
}

test "part2 example" {
    const input = common.trimInput("L68\nL30\nR48\nL5\nR60\nL55\nL1\nL99\nR14\nL82");
    try common.expectResult(i64, 6, part2(std.testing.allocator, input));
}
