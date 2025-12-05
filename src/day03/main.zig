const std = @import("std");
const common = @import("common");
const mecha = @import("mecha");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const input = try common.readInput(allocator, "day03");
    defer allocator.free(input);

    const part1Result = try part1(allocator, input);
    std.debug.print("Part 1: {}\n", .{part1Result});

    const part2Result = try part2(allocator, input);
    std.debug.print("Part 2: {}\n", .{part2Result});
}

const digitParser = mecha.ascii.digit(10).map(struct {
    fn f(c: u8) u8 {
        return c - '0';
    }
}.f);

const rowParser = digitParser.many(.{});

const inputParser = rowParser.many(.{ .separator = mecha.ascii.char('\n').discard() });

fn part1(allocator: std.mem.Allocator, input: []const u8) !u64 {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();

    const result = try inputParser.parse(arena.allocator(), input);
    const banks = result.value.ok;

    var total: u64 = 0;

    for (banks) |bank| {
        if (bank.len < 2) continue;

        var maxDigit = bank[0];
        var maxJoltage: u64 = 0;
        for (bank[1..]) |digit| {
            maxJoltage = @max(maxJoltage, 10 * maxDigit + digit);
            maxDigit = @max(maxDigit, digit);
        }
        total += maxJoltage;
    }

    return total;
}

fn part2(allocator: std.mem.Allocator, input: []const u8) !u64 {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();

    const result = try inputParser.parse(arena.allocator(), input);
    const banks = result.value.ok;

    var total: u64 = 0;

    for (banks) |bank| {
        if (bank.len < 12) continue;
        var minPossibleIndex: usize = 0;
        var joltage: u64 = 0;
        for (0..12) |i| {
            const maxPossibleIndex: usize = bank.len - 12 + i;
            var maxDigit: u64 = 0;

            for (minPossibleIndex..maxPossibleIndex + 1) |j| {
                if (bank[j] > maxDigit) {
                    maxDigit = bank[j];
                    minPossibleIndex = j + 1;
                }
            }

            joltage = 10 * joltage + maxDigit;
        }
        total += joltage;
    }

    return total;
}

test "part1 example" {
    const input = common.trimInput("987654321111111\n811111111111119\n234234234234278\n818181911112111");
    try common.expectResult(u64, 357, part1(std.testing.allocator, input));
}

test "part2 example" {
    const input = common.trimInput("987654321111111\n811111111111119\n234234234234278\n818181911112111");
    try common.expectResult(u64, 3121910778619, part2(std.testing.allocator, input));
}
