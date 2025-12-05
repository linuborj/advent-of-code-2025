const std = @import("std");
const common = @import("common");
const mecha = @import("mecha");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const input = try common.readInput(allocator, "day02");
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

const inputParser = rangeParser.many(.{ .separator = mecha.ascii.char(',').opt().discard() });

fn isValidPart1(n: u64) bool {
    const l = 1 + std.math.log10_int(n);
    if (l % 2 != 0) {
        return true;
    }
    return @mod(n, std.math.pow(u64, 10, l / 2)) != @divTrunc(n, std.math.pow(u64, 10, l / 2));
}

fn isValidPart2(n: u64) bool {
    const l = 1 + std.math.log10_int(n);
    outer: for (1..1 + (l / 2)) |lengthOfPart| {
        if (l % lengthOfPart != 0) {
            continue;
        }
        const part = @mod(n, std.math.pow(u64, 10, lengthOfPart));
        for (1..l / lengthOfPart) |partPosition| {
            if (part != @mod(@divTrunc(n, std.math.pow(u64, 10, lengthOfPart * partPosition)), std.math.pow(u64, 10, lengthOfPart))) {
                continue :outer;
            }
        }
        return false;
    }
    return true;
}

fn part1(allocator: std.mem.Allocator, input: []const u8) !u64 {
    const result = try inputParser.parse(allocator, input);
    const ranges = result.value.ok;
    defer allocator.free(ranges);
    var total: u64 = 0;
    for (ranges) |range| {
        for (range.start..range.end + 1) |i| {
            if (!isValidPart1(i)) {
                total += i;
            }
        }
    }
    return total;
}

fn part2(allocator: std.mem.Allocator, input: []const u8) !u64 {
    const result = try inputParser.parse(allocator, input);
    const ranges = result.value.ok;
    defer allocator.free(ranges);
    var total: u64 = 0;
    for (ranges) |range| {
        for (range.start..range.end + 1) |i| {
            if (!isValidPart2(i)) {
                total += i;
            }
        }
    }
    return total;
}

test "is valid part1" {
    try common.expectResult(bool, false, isValidPart1(11));
    try common.expectResult(bool, false, isValidPart1(123123));
    try common.expectResult(bool, true, isValidPart1(1112));
    try common.expectResult(bool, true, isValidPart1(111));
}

test "is valid part2" {
    try common.expectResult(bool, false, isValidPart2(11));
    try common.expectResult(bool, false, isValidPart2(111));
    try common.expectResult(bool, false, isValidPart2(121212));
    try common.expectResult(bool, true, isValidPart2(121213));
    try common.expectResult(bool, true, isValidPart2(131212));
}

test "part1 example" {
    const input = common.trimInput("11-22,95-115,998-1012,1188511880-1188511890,222220-222224,1698522-1698528,446443-446449,38593856-38593862,565653-565659,824824821-824824827,2121212118-2121212124");
    try common.expectResult(u64, 1227775554, part1(std.testing.allocator, input));
}

test "part2 example" {
    const input = common.trimInput("11-22,95-115,998-1012,1188511880-1188511890,222220-222224,1698522-1698528,446443-446449,38593856-38593862,565653-565659,824824821-824824827,2121212118-2121212124");
    try common.expectResult(u64, 4174379265, part2(std.testing.allocator, input));
}
