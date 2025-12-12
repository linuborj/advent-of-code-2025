const std = @import("std");
const common = @import("common");
const mecha = @import("mecha");

const Rational = common.Rational;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const input = try common.readInput(allocator, "day10");
    defer allocator.free(input);

    std.debug.print("Part 1: {}\n", .{try part1(allocator, input)});
    std.debug.print("Part 2: {}\n", .{try part2(allocator, input)});
}

const indicatorLightParser = mecha.combine(.{
    mecha.ascii.char('[').discard(),
    mecha.ascii.wrap(struct {
        fn p(c: u8) bool {
            return c == '#' or c == '.';
        }
    }.p).many(.{}),
    mecha.ascii.char(']').discard(),
});

const buttonParser = mecha.combine(.{
    mecha.ascii.char('(').discard(),
    mecha.int(u8, .{}).many(.{ .separator = mecha.ascii.char(',').discard() }),
    mecha.ascii.char(')').discard(),
});

const joltageParser = mecha.combine(.{
    mecha.ascii.char('{').discard(),
    mecha.int(u64, .{}).many(.{ .separator = mecha.ascii.char(',').discard() }),
    mecha.ascii.char('}').discard(),
});

const lineParser = mecha.combine(.{
    indicatorLightParser,
    mecha.ascii.char(' ').discard(),
    buttonParser.many(.{ .separator = mecha.ascii.char(' ').discard() }),
    mecha.ascii.char(' ').discard(),
    joltageParser,
});

const inputParser = lineParser.many(.{ .separator = mecha.ascii.char('\n').discard() });

fn part1(allocator: std.mem.Allocator, input: []const u8) !u64 {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const lines = (try inputParser.parse(arena.allocator(), input)).value.ok;

    var total: u64 = 0;
    for (lines) |line| {
        const target, const buttons, _ = line;
        total += try minPressesXor(arena.allocator(), target, buttons);
    }
    return total;
}

fn minPressesXor(allocator: std.mem.Allocator, target: []const u8, buttons: []const []const u8) !u64 {
    const targetBits = targetBitmap(target);
    const buttonBits = try allocator.alloc(u16, buttons.len);
    for (buttons, buttonBits) |b, *bb| bb.* = buttonBitmap(b);

    const State = struct { bits: u16, presses: u64 };
    var queue: std.ArrayList(State) = .empty;
    defer queue.deinit(allocator);
    var visited = std.StaticBitSet(65536).initEmpty();

    visited.set(0);
    try queue.append(allocator, .{ .bits = 0, .presses = 0 });

    while (queue.items.len > 0) {
        const current = queue.orderedRemove(0);
        for (buttonBits) |button| {
            const next = current.bits ^ button;
            if (next == targetBits) return current.presses + 1;
            if (visited.isSet(next)) continue;
            visited.set(next);
            try queue.append(allocator, .{ .bits = next, .presses = current.presses + 1 });
        }
    }
    return error.NoSolutionFound;
}

fn targetBitmap(indicator: []const u8) u16 {
    var bits: u16 = 0;
    for (indicator, 0..) |c, i| {
        if (c == '#') bits |= @as(u16, 1) << @intCast(i);
    }
    return bits;
}

fn buttonBitmap(counters: []const u8) u16 {
    var bits: u16 = 0;
    for (counters) |c| bits |= @as(u16, 1) << @intCast(c);
    return bits;
}

fn part2(allocator: std.mem.Allocator, input: []const u8) !u64 {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    const lines = (try inputParser.parse(alloc, input)).value.ok;

    var total: u64 = 0;
    for (lines) |line| {
        _, const buttons, const joltages = line;

        const coefficients = try buildCoefficientMatrix(alloc, buttons, joltages.len);
        const constants = try alloc.alloc(Rational, joltages.len);
        for (joltages, constants) |j, *c| c.* = Rational.fromInt(@intCast(j));

        const solution = try common.gauss.solve(alloc, coefficients, constants);
        const freeVars = try solution.getFreeVars(alloc);
        const maxJoltage = std.mem.max(u64, joltages);

        total += try findMinNonNegativeSum(alloc, solution, freeVars, @intCast(maxJoltage)) orelse
            return error.UnsolvableSystem;
    }
    return total;
}

fn buildCoefficientMatrix(alloc: std.mem.Allocator, buttons: []const []const u8, numCounters: usize) ![][]const Rational {
    const coefficients = try alloc.alloc([]const Rational, numCounters);
    for (0..numCounters) |counter| {
        const row = try alloc.alloc(Rational, buttons.len);
        for (buttons, row) |button, *coeff| {
            coeff.* = Rational.fromInt(if (std.mem.indexOfScalar(u8, button, @intCast(counter)) != null) 1 else 0);
        }
        coefficients[counter] = row;
    }
    return coefficients;
}

fn findMinNonNegativeSum(allocator: std.mem.Allocator, solution: common.gauss.Solution, freeVars: []const usize, maxSearch: i64) !?u64 {
    if (freeVars.len == 0) {
        // No free variables, just sum up the found values for the variables
        var total: u64 = 0;
        for (0..solution.numVars) |v| {
            total += @intCast(solution.evaluate(v, freeVars, &.{}).toInt().?);
        }
        return total;
    }

    // Search over free variable values
    var bestTotal: u64 = std.math.maxInt(u64);
    const freeVals = try allocator.alloc(i64, freeVars.len);
    searchFreeVars(solution, freeVars, freeVals, 0, maxSearch, &bestTotal);
    return if (bestTotal == std.math.maxInt(u64)) null else bestTotal;
}

fn searchFreeVars(solution: common.gauss.Solution, freeVars: []const usize, freeVals: []i64, depth: usize, maxSearch: i64, bestTotal: *u64) void {
    if (depth == freeVars.len) {
        var total: u64 = 0;
        for (0..solution.numVars) |v| {
            const val = solution.evaluate(v, freeVars, freeVals).toInt() orelse return;
            if (val < 0) return;
            total += @intCast(val);
        }
        if (total < bestTotal.*) bestTotal.* = total;
        return;
    }

    var v: i64 = 0;
    while (v <= maxSearch) : (v += 1) {
        freeVals[depth] = v;
        searchFreeVars(solution, freeVars, freeVals, depth + 1, maxSearch, bestTotal);
    }
}

test "part1 example" {
    const input = common.trimInput(
        \\[.##.] (3) (1,3) (2) (2,3) (0,2) (0,1) {3,5,4,7}
        \\[...#.] (0,2,3,4) (2,3) (0,4) (0,1,2) (1,2,3,4) {7,5,12,7,2}
        \\[.###.#] (0,1,2,3,4) (0,3,4) (0,1,2,4,5) (1,2) {10,11,11,5,10,5}
    );
    try common.expectResult(u64, 7, part1(std.testing.allocator, input));
}

test "part2 example" {
    const input = common.trimInput(
        \\[.##.] (3) (1,3) (2) (2,3) (0,2) (0,1) {3,5,4,7}
        \\[...#.] (0,2,3,4) (2,3) (0,4) (0,1,2) (1,2,3,4) {7,5,12,7,2}
        \\[.###.#] (0,1,2,3,4) (0,3,4) (0,1,2,4,5) (1,2) {10,11,11,5,10,5}
    );
    try common.expectResult(u64, 33, part2(std.testing.allocator, input));
}
