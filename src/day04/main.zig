const std = @import("std");
const common = @import("common");
const mecha = @import("mecha");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const input = try common.readInput(allocator, "day04");
    defer allocator.free(input);

    const part1Result = try part1(allocator, input);
    std.debug.print("Part 1: {}\n", .{part1Result});

    const part2Result = try part2(allocator, input);
    std.debug.print("Part 2: {}\n", .{part2Result});
}

const rowParser = mecha.oneOf(.{ mecha.ascii.char('.'), mecha.ascii.char('@') }).many(.{});

const inputParser = rowParser
    .many(.{ .separator = mecha.ascii.char('\n').discard() })
    .map(struct {
    fn toGrid(rows: [][]u8) Grid {
        return .{ .rows = rows };
    }
}.toGrid);

const Direction = enum {
    north,
    northeast,
    east,
    southeast,
    south,
    southwest,
    west,
    northwest,

    fn delta(self: Direction) struct { dx: i8, dy: i8 } {
        return switch (self) {
            .north => .{ .dx = 0, .dy = -1 },
            .northeast => .{ .dx = 1, .dy = -1 },
            .east => .{ .dx = 1, .dy = 0 },
            .southeast => .{ .dx = 1, .dy = 1 },
            .south => .{ .dx = 0, .dy = 1 },
            .southwest => .{ .dx = -1, .dy = 1 },
            .west => .{ .dx = -1, .dy = 0 },
            .northwest => .{ .dx = -1, .dy = -1 },
        };
    }
};

const Position = struct {
    x: usize,
    y: usize,
};

const Grid = struct {
    rows: [][]u8,

    const Iterator = struct {
        grid: *const Grid,
        index: usize,

        fn next(self: *Iterator) ?Position {
            const width = self.grid.rows[0].len;
            const height = self.grid.rows.len;
            if (self.index >= width * height) {
                return null;
            }
            const pos = Position{
                .x = self.index % width,
                .y = self.index / width,
            };
            self.index += 1;
            return pos;
        }
    };

    fn indices(self: *const Grid) Iterator {
        return .{ .grid = self, .index = 0 };
    }

    fn get(self: Grid, pos: Position) ?u8 {
        if (pos.y >= self.rows.len) {
            return null;
        }
        const row = self.rows[pos.y];
        if (pos.x >= row.len) {
            return null;
        }
        return row[pos.x];
    }

    fn set(self: Grid, pos: Position, value: u8) void {
        if (pos.y >= self.rows.len) return;
        const row = self.rows[pos.y];
        if (pos.x >= row.len) return;
        row[pos.x] = value;
    }

    fn countNeighbors(self: Grid, pos: Position, value: u8) u8 {
        var count: u8 = 0;
        for (std.enums.values(Direction)) |dir| {
            const d = dir.delta();
            const x = @as(i64, @intCast(pos.x)) + d.dx;
            const y = @as(i64, @intCast(pos.y)) + d.dy;
            if (x >= 0 and y >= 0) {
                if (self.get(.{ .x = @intCast(x), .y = @intCast(y) }) == value) {
                    count += 1;
                }
            }
        }
        return count;
    }

};

fn part1(allocator: std.mem.Allocator, input: []const u8) !u64 {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();

    const result = try inputParser.parse(arena.allocator(), input);
    const grid = result.value.ok;

    var total: u64 = 0;
    var iter = grid.indices();
    while (iter.next()) |pos| {
        if (grid.get(pos) != '@') continue;
        if (grid.countNeighbors(pos, '@') < 4) {
            total += 1;
        }
    }

    return total;
}

fn part2(allocator: std.mem.Allocator, input: []const u8) !u64 {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();

    const result = try inputParser.parse(arena.allocator(), input);
    const grid = result.value.ok;

    var total: u64 = 0;
    var loop: bool = true;

    while (loop) {
        loop = false;
        var iter = grid.indices();
        while (iter.next()) |pos| {
            if (grid.get(pos) != '@') continue;
            if (grid.countNeighbors(pos, '@') < 4) {
                total += 1;
                grid.set(pos, '.');
                loop = true;
            }
        }
    }

    return total;
}

test "part1 example" {
    const input = common.trimInput("..@@.@@@@.\n@@@.@.@.@@\n@@@@@.@.@@\n@.@@@@..@.\n@@.@@@@.@@\n.@@@@@@@.@\n.@.@.@.@@@\n@.@@@.@@@@\n.@@@@@@@@.\n@.@.@@@.@.");
    try common.expectResult(u64, 13, part1(std.testing.allocator, input));
}

test "part2 example" {
    const input = common.trimInput("..@@.@@@@.\n@@@.@.@.@@\n@@@@@.@.@@\n@.@@@@..@.\n@@.@@@@.@@\n.@@@@@@@.@\n.@.@.@.@@@\n@.@@@.@@@@\n.@@@@@@@@.\n@.@.@@@.@.");
    try common.expectResult(u64, 43, part2(std.testing.allocator, input));
}
