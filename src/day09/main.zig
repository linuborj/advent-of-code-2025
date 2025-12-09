const std = @import("std");
const common = @import("common");
const mecha = @import("mecha");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const input = try common.readInput(allocator, "day09");
    defer allocator.free(input);

    std.debug.print("Part 1: {}\n", .{try part1(allocator, input)});
    std.debug.print("Part 2: {}\n", .{try part2(allocator, input)});
}

const V2 = struct {
    x: i64,
    y: i64,

    fn sub(self: V2, other: V2) V2 {
        return .{ .x = self.x - other.x, .y = self.y - other.y };
    }

    fn cross(self: V2, other: V2) i64 {
        return self.x * other.y - self.y * other.x;
    }
};

const Edge = struct {
    a: V2,
    b: V2,

    fn dir(self: Edge) V2 {
        return self.b.sub(self.a);
    }

    fn containsPoint(self: Edge, p: V2) bool {
        if (p.x < @min(self.a.x, self.b.x) or p.x > @max(self.a.x, self.b.x)) return false;
        if (p.y < @min(self.a.y, self.b.y) or p.y > @max(self.a.y, self.b.y)) return false;
        return self.dir().cross(p.sub(self.a)) == 0;
    }

    fn oppositeSides(self: Edge, p1: V2, p2: V2) bool {
        const d = self.dir();
        const s1 = d.cross(p1.sub(self.a));
        const s2 = d.cross(p2.sub(self.a));
        return (s1 > 0 and s2 < 0) or (s1 < 0 and s2 > 0);
    }

    fn intersects(self: Edge, other: Edge) bool {
        return self.oppositeSides(other.a, other.b) and other.oppositeSides(self.a, self.b);
    }

    fn horizontalRayCrossesAt(self: Edge, rayOrigin: V2) bool {
        if ((self.a.y > rayOrigin.y) == (self.b.y > rayOrigin.y)) return false;
        const xInt = self.b.x + @divTrunc((rayOrigin.y - self.b.y) * (self.a.x - self.b.x), (self.a.y - self.b.y));
        return rayOrigin.x < xInt;
    }
};

const parser = mecha.int(i64, .{})
    .manyN(2, .{ .separator = mecha.ascii.char(',').discard() })
    .map(struct {
        fn f(t: [2]i64) V2 {
            return .{ .x = t[0], .y = t[1] };
        }
    }.f).many(.{ .separator = mecha.ascii.char('\n').discard() });

fn area(a: V2, b: V2) u64 {
    return (@abs(a.x - b.x) + 1) * (@abs(a.y - b.y) + 1);
}

fn polyEdge(poly: []const V2, i: usize) Edge {
    return .{ .a = poly[i], .b = poly[(i + 1) % poly.len] };
}

fn rectInside(poly: []const V2, a: V2, b: V2) bool {
    const x1 = @min(a.x, b.x);
    const x2 = @max(a.x, b.x);
    const y1 = @min(a.y, b.y);
    const y2 = @max(a.y, b.y);

    const corners = [_]V2{
        .{ .x = x1, .y = y1 },
        .{ .x = x2, .y = y1 },
        .{ .x = x2, .y = y2 },
        .{ .x = x1, .y = y2 },
    };

    for (corners) |c| {
        if (!inside(poly, c)) return false;
    }

    for (0..4) |i| {
        const rectEdge = Edge{ .a = corners[i], .b = corners[(i + 1) % 4] };
        for (0..poly.len) |j| {
            if (rectEdge.intersects(polyEdge(poly, j))) return false;
        }
    }
    return true;
}

fn inside(poly: []const V2, p: V2) bool {
    for (0..poly.len) |i| {
        if (polyEdge(poly, i).containsPoint(p)) return true;
    }
    return raycast(poly, p);
}

fn raycast(poly: []const V2, p: V2) bool {
    var result = false;
    for (0..poly.len) |i| {
        if (polyEdge(poly, i).horizontalRayCrossesAt(p)) result = !result;
    }
    return result;
}

fn part1(allocator: std.mem.Allocator, input: []const u8) !u64 {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const poly = (try parser.parse(arena.allocator(), input)).value.ok;

    var best: u64 = 0;
    for (poly, 0..) |a, i| {
        for (poly[i + 1 ..]) |b| {
            best = @max(best, area(a, b));
        }
    }
    return best;
}

fn part2(allocator: std.mem.Allocator, input: []const u8) !u64 {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const poly = (try parser.parse(arena.allocator(), input)).value.ok;

    var best: u64 = 0;
    for (poly, 0..) |a, i| {
        for (poly[i + 1 ..]) |b| {
            if (a.x == b.x or a.y == b.y) continue;
            if (rectInside(poly, a, b)) best = @max(best, area(a, b));
        }
    }
    return best;
}

test "part1 example" {
    const input = common.trimInput(
        \\7,1
        \\11,1
        \\11,7
        \\9,7
        \\9,5
        \\2,5
        \\2,3
        \\7,3
    );
    try common.expectResult(u64, 50, part1(std.testing.allocator, input));
}

test "part2 example" {
    const input = common.trimInput(
        \\7,1
        \\11,1
        \\11,7
        \\9,7
        \\9,5
        \\2,5
        \\2,3
        \\7,3
    );
    try common.expectResult(u64, 24, part2(std.testing.allocator, input));
}
