const std = @import("std");
const common = @import("common");
const mecha = @import("mecha");

const Region = struct {
    width: u16,
    height: u16,
    counts: []const u16,
};

const Input = struct {
    shapeSizes: []const u8,
    regions: []const Region,
};

const shapeCell = mecha.oneOf(.{ mecha.ascii.char('#'), mecha.ascii.char('.') });
const shapeRow = shapeCell.many(.{ .min = 1 }).asStr();

const shapeParser = mecha.combine(.{
    mecha.int(u8, .{}).discard(),
    mecha.string(":\n").discard(),
    shapeRow.many(.{ .min = 1, .separator = mecha.ascii.char('\n').discard() }),
});

const regionParser = mecha.combine(.{
    mecha.int(u16, .{}),
    mecha.ascii.char('x').discard(),
    mecha.int(u16, .{}),
    mecha.string(": ").discard(),
    mecha.int(u16, .{}).many(.{ .min = 1, .separator = mecha.ascii.char(' ').discard() }),
});

const inputParser = mecha.combine(.{
    shapeParser.many(.{ .min = 1, .separator = mecha.string("\n\n").discard() }),
    mecha.string("\n\n").discard(),
    regionParser.many(.{ .min = 1, .separator = mecha.ascii.char('\n').discard() }),
});

fn countHashes(rows: []const []const u8) u8 {
    var count: u8 = 0;
    for (rows) |row| {
        for (row) |c| {
            if (c == '#') count += 1;
        }
    }
    return count;
}

fn parseInput(allocator: std.mem.Allocator, input: []const u8) !Input {
    const parsed = (try inputParser.parse(allocator, input)).value.ok;

    const shapeSizes = try allocator.alloc(u8, parsed[0].len);
    for (parsed[0], 0..) |rows, i| {
        shapeSizes[i] = countHashes(rows);
    }

    const regions = try allocator.alloc(Region, parsed[1].len);
    for (parsed[1], 0..) |r, i| {
        regions[i] = .{ .width = r[0], .height = r[1], .counts = r[2] };
    }

    return .{ .shapeSizes = shapeSizes, .regions = regions };
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();

    const inputText = try common.readInput(allocator, "day12");
    defer allocator.free(inputText);

    const parsed = try parseInput(arena.allocator(), inputText);
    std.debug.print("Part 1: {}\n", .{part1(parsed)});
}

fn part1(input: Input) u64 {
    var count: u64 = 0;
    for (input.regions) |region| {
        var pieceCells: u64 = 0;
        for (region.counts, input.shapeSizes) |c, s| {
            pieceCells += @as(u64, c) * @as(u64, s);
        }
        if (pieceCells <= @as(u64, region.width) * @as(u64, region.height)) {
            count += 1;
        }
    }
    return count;
}

test "part1 example" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const input = common.trimInput(
        \\0:
        \\###
        \\##.
        \\##.
        \\
        \\1:
        \\###
        \\..#
        \\###
        \\
        \\2:
        \\###
        \\.##
        \\..#
        \\
        \\3:
        \\.##
        \\##.
        \\###
        \\
        \\4:
        \\###
        \\.#.
        \\###
        \\
        \\5:
        \\#..
        \\##.
        \\.##
        \\
        \\4x4: 0 0 0 0 2 0
        \\12x5: 1 0 1 0 2 2
        \\12x5: 1 0 1 0 3 2
    );

    const parsed = try parseInput(arena.allocator(), input);
    try std.testing.expectEqual(@as(u64, 3), part1(parsed));
}

test "parse example" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const input = common.trimInput(
        \\0:
        \\###
        \\##.
        \\##.
        \\
        \\1:
        \\###
        \\..#
        \\###
        \\
        \\2:
        \\###
        \\.##
        \\..#
        \\
        \\3:
        \\.##
        \\##.
        \\###
        \\
        \\4:
        \\###
        \\.#.
        \\###
        \\
        \\5:
        \\#..
        \\##.
        \\.##
        \\
        \\4x4: 0 0 0 0 2 0
        \\12x5: 1 0 1 0 2 2
        \\12x5: 1 0 1 0 3 2
    );

    const parsed = try parseInput(arena.allocator(), input);

    try std.testing.expectEqual(@as(u8, 7), parsed.shapeSizes[0]);
    try std.testing.expectEqual(@as(u8, 6), parsed.shapeSizes[2]);
    try std.testing.expectEqual(@as(u8, 5), parsed.shapeSizes[5]);
    try std.testing.expectEqual(@as(usize, 3), parsed.regions.len);
}
