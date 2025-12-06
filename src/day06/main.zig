const std = @import("std");
const common = @import("common");
const mecha = @import("mecha");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const input = try common.readInput(allocator, "day06");
    defer allocator.free(input);

    const part1Result = try part1(allocator, input);
    std.debug.print("Part 1: {}\n", .{part1Result});

    const part2Result = try part2(allocator, input);
    std.debug.print("Part 2: {}\n", .{part2Result});
}

const spaces = mecha.many(mecha.ascii.char(' '), .{});
const numberLineParser = mecha.combine(.{
    spaces,
    mecha.int(u64, .{}).many(.{ .min = 1, .separator = mecha.many(mecha.ascii.char(' '), .{ .min = 1 }).discard() }),
    spaces,
}).map(struct {
    fn f(tuple: std.meta.Tuple(&.{ []u8, []u64, []u8 })) []u64 {
        return tuple[1];
    }
}.f);

const Operator = enum { add, mul };
const operatorParser = mecha.oneOf(.{
    mecha.ascii.char('+').mapConst(Operator.add),
    mecha.ascii.char('*').mapConst(Operator.mul),
});
const operatorLineParser = mecha.combine(.{
    spaces,
    operatorParser.many(.{ .separator = mecha.many(mecha.ascii.char(' '), .{ .min = 1 }).discard() }),
}).map(struct {
    fn f(tuple: std.meta.Tuple(&.{ []u8, []Operator })) []Operator {
        return tuple[1];
    }
}.f);

const Part1Input = struct {
    rows: [][]u64,
    operators: []Operator,
};

const part1InputParser = mecha.combine(.{
    numberLineParser.many(.{ .separator = mecha.ascii.char('\n').discard() }),
    mecha.ascii.char('\n'),
    operatorLineParser,
}).map(struct {
    fn f(tuple: std.meta.Tuple(&.{ [][]u64, u8, []Operator })) Part1Input {
        return .{ .rows = tuple[0], .operators = tuple[2] };
    }
}.f);

fn part1(allocator: std.mem.Allocator, rawInput: []const u8) !u64 {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const result = try part1InputParser.parse(arena.allocator(), rawInput);
    const input = result.value.ok;

    var total: u64 = 0;
    for (input.operators, 0..) |operator, col| {
        var problemSolution: u64 = input.rows[0][col];
        for (input.rows[1..]) |row| {
            switch (operator) {
                .add => problemSolution += row[col],
                .mul => problemSolution *= row[col],
            }
        }
        total += problemSolution;
    }

    return total;
}

fn transpose(alloc: std.mem.Allocator, rows: []const []const u8) ![][]u8 {
    var maxWidth: usize = 0;
    for (rows) |row| {
        maxWidth = @max(maxWidth, row.len);
    }

    var columns = try alloc.alloc([]u8, maxWidth);
    for (0..maxWidth) |col| {
        columns[col] = try alloc.alloc(u8, rows.len);
        for (rows, 0..) |row, rowIdx| {
            columns[col][rowIdx] = if (col < row.len) row[col] else ' ';
        }
    }

    return columns;
}

fn getOperator(column: []const u8) ?Operator {
    for (column) |c| {
        if (c == '+') return .add;
        if (c == '*') return .mul;
    }
    return null;
}

fn getNumber(column: []const u8) ?u64 {
    var number: ?u64 = null;
    for (column) |c| {
        if (!std.ascii.isDigit(c)) continue;
        number = 10 * (number orelse 0) + (c - '0');
    }
    return number;
}

fn part2(allocator: std.mem.Allocator, rawInput: []const u8) !u64 {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var lineList: std.ArrayList([]const u8) = .empty;
    var lines = std.mem.splitScalar(u8, rawInput, '\n');
    while (lines.next()) |line| {
        try lineList.append(alloc, line);
    }

    const columns = try transpose(alloc, lineList.items);

    var total: u64 = 0;
    var operator: Operator = .add;
    var problemSolution: ?u64 = null;

    for (columns) |column| {
        if (getOperator(column)) |newOperator| {
            if (problemSolution) |value| total += value;
            operator = newOperator;
            problemSolution = null;
        }
        if (getNumber(column)) |number| {
            if (problemSolution == null) {
                problemSolution = number;
            } else {
                switch (operator) {
                    .add => problemSolution = problemSolution.? + number,
                    .mul => problemSolution = problemSolution.? * number,
                }
            }
        }
    }

    if (problemSolution) |value| total += value;

    return total;
}

test "part1 example" {
    const input = common.trimInput(
        \\123 328  51 64 
        \\ 45 64  387 23 
        \\  6 98  215 314
        \\*   +   *   +  
    );
    try common.expectResult(u64, 4277556, part1(std.testing.allocator, input));
}

test "part2 example" {
    const input = common.trimInput(
        \\123 328  51 64 
        \\ 45 64  387 23 
        \\  6 98  215 314
        \\*   +   *   +  
    );
    try common.expectResult(u64, 3263827, part2(std.testing.allocator, input));
}
