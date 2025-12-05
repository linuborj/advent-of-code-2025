const std = @import("std");
const common = @import("common");
const mecha = @import("mecha");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const input = try common.readInput(allocator, "day05");
    defer allocator.free(input);

    const part1Result = try part1(allocator, input);
    std.debug.print("Part 1: {}\n", .{part1Result});

    const part2Result = try part2(allocator, input);
    std.debug.print("Part 2: {}\n", .{part2Result});
}

const Range = struct { start: u64, end: u64 };

const rangeParser = mecha.combine(.{ mecha.int(u64, .{}), mecha.ascii.char('-'), mecha.int(u64, .{}) }).map(struct {
    fn f(tuple: std.meta.Tuple(&.{ u64, u8, u64 })) Range {
        return .{ .start = tuple[0], .end = tuple[2] };
    }
}.f);

const inputParser = mecha.combine(.{
    rangeParser.many(.{ .separator = mecha.ascii.char('\n').discard() }),
    mecha.string("\n\n"),
    mecha.int(u64, .{}).many(.{ .separator = mecha.ascii.char('\n').discard() }),
}).map(struct {
    fn f(tuple: std.meta.Tuple(&.{ []Range, []const u8, []u64 })) struct { ranges: []Range, numbers: []u64 } {
        return .{ .ranges = tuple[0], .numbers = tuple[2] };
    }
}.f);

fn part1(allocator: std.mem.Allocator, input: []const u8) !u64 {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const result = try inputParser.parse(arena.allocator(), input);
    const rangesAndNumbers = result.value.ok;

    var total: u64 = 0;

    for (rangesAndNumbers.numbers) |number| {
        for (rangesAndNumbers.ranges) |range| {
            if (number >= range.start and number <= range.end) {
                total += 1;
                break;
            }
        }
    }

    return total;
}

fn part2(allocator: std.mem.Allocator, input: []const u8) !u64 {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const result = try inputParser.parse(arena.allocator(), input);
    const rangesAndNumbers = result.value.ok;
    std.mem.sort(Range, rangesAndNumbers.ranges, {}, struct {
        fn lessThan(_: void, a: Range, b: Range) bool {
            return a.start < b.start;
        }
    }.lessThan);

    var total: u64 = 0;
    var low: u64 = 0;

    for (rangesAndNumbers.ranges) |range| {
        low = @max(low, range.start);
        if (range.end >= low) {
            total += 1 + range.end - low;
        }
        low = @max(low, range.end + 1);
    }

    return total;
}

test "part1 example" {
    const input = common.trimInput(
        \\3-5
        \\10-14
        \\16-20
        \\12-18
        \\
        \\1
        \\5
        \\8
        \\11
        \\17
        \\32
    );
    try common.expectResult(u64, 3, part1(std.testing.allocator, input));
}

test "part2 example" {
    const input = common.trimInput(
        \\3-5
        \\10-14
        \\16-20
        \\12-18
        \\
        \\1
        \\5
        \\8
        \\11
        \\17
        \\32
    );
    try common.expectResult(u64, 14, part2(std.testing.allocator, input));
}
