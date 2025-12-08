const std = @import("std");
const common = @import("common");
const mecha = @import("mecha");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const input = try common.readInput(allocator, "day08");
    defer allocator.free(input);

    const part1Result = try part1(allocator, input);
    std.debug.print("Part 1: {}\n", .{part1Result});

    const part2Result = try part2(allocator, input);
    std.debug.print("Part 2: {}\n", .{part2Result});
}

const digitsParser = mecha.ascii.digit(10).many(.{ .collect = false }).asStr();

const v3Parser = digitsParser.convert(mecha.toFloat(f32)).manyN(3, .{ .separator = mecha.ascii.char(',').discard() }).map(struct {
    fn f(tuple: [3]f32) V3 {
        return .{ .x = tuple[0], .y = tuple[1], .z = tuple[2] };
    }
}.f);

const inputParser = v3Parser.many(.{ .separator = mecha.ascii.char('\n').discard() });

const V3 = struct {
    x: f32,
    y: f32,
    z: f32,

    fn distanceSquared(self: V3, other: V3) f32 {
        const dx = self.x - other.x;
        const dy = self.y - other.y;
        const dz = self.z - other.z;
        return dx * dx + dy * dy + dz * dz;
    }
};

const Circuits = struct {
    parent: []usize,
    size: []usize,

    fn init(allocator: std.mem.Allocator, n: usize) !Circuits {
        const parent = try allocator.alloc(usize, n);
        const size = try allocator.alloc(usize, n);
        for (0..n) |i| {
            parent[i] = i;
            size[i] = 1;
        }
        return .{ .parent = parent, .size = size };
    }

    fn findOrigin(self: *Circuits, x: usize) usize {
        if (self.parent[x] != x) {
            self.parent[x] = self.findOrigin(self.parent[x]);
        }
        return self.parent[x];
    }

    fn connect(self: *Circuits, x: usize, y: usize) void {
        const originX = self.findOrigin(x);
        const originY = self.findOrigin(y);
        if (originX != originY) {
            self.parent[originX] = originY;
            self.size[originY] += self.size[originX];
        }
    }

    fn getTop3CircuitSizes(self: *Circuits) [3]usize {
        var top = [_]usize{ 0, 0, 0 };
        for (0..self.parent.len) |i| {
            if (self.parent[i] != i) continue;
            if (self.size[i] > top[0]) {
                top[2] = top[1];
                top[1] = top[0];
                top[0] = self.size[i];
            } else if (self.size[i] > top[1]) {
                top[2] = top[1];
                top[1] = self.size[i];
            } else if (self.size[i] > top[2]) {
                top[2] = self.size[i];
            }
        }
        return top;
    }
};

const Pair = struct {
    i: usize,
    j: usize,
    distanceSquared: f32,
};

// I tried cleverer approaches which were a lot quicker. But this is more than quick
// enough and nice and small
fn getSortedPairs(allocator: std.mem.Allocator, points: []const V3) ![]Pair {
    const numberOfPairs = points.len * (points.len - 1) / 2;
    var pairs = try allocator.alloc(Pair, numberOfPairs);

    var index: usize = 0;
    for (0..points.len) |i| {
        for (i + 1..points.len) |j| {
            pairs[index] = .{
                .i = i,
                .j = j,
                .distanceSquared = points[i].distanceSquared(points[j]),
            };
            index += 1;
        }
    }

    std.mem.sort(Pair, pairs, {}, struct {
        fn cmp(_: void, a: Pair, b: Pair) bool {
            return a.distanceSquared < b.distanceSquared;
        }
    }.cmp);

    return pairs;
}

fn part1(allocator: std.mem.Allocator, input: []const u8) !u64 {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const result = try inputParser.parse(arena.allocator(), input);
    const coordinates = result.value.ok;

    const pairs = try getSortedPairs(arena.allocator(), coordinates);
    var circuits = try Circuits.init(arena.allocator(), coordinates.len);
    for (pairs[0..1000]) |pair| {
        circuits.connect(pair.i, pair.j);
    }

    const top3 = circuits.getTop3CircuitSizes();
    return top3[0] * top3[1] * top3[2];
}

fn part2(allocator: std.mem.Allocator, input: []const u8) !u64 {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const result = try inputParser.parse(arena.allocator(), input);
    const coordinates = result.value.ok;

    const pairs = try getSortedPairs(arena.allocator(), coordinates);

    var circuits = try Circuits.init(arena.allocator(), coordinates.len);
    var connectionsMade: usize = 0;

    for (pairs) |pair| {
        if (circuits.findOrigin(pair.i) == circuits.findOrigin(pair.j)) continue;

        circuits.connect(pair.i, pair.j);
        connectionsMade += 1;

        if (connectionsMade != coordinates.len - 1) continue;

        const x1: u64 = @intFromFloat(coordinates[pair.i].x);
        const x2: u64 = @intFromFloat(coordinates[pair.j].x);
        return x1 * x2;
    }

    unreachable;
}

// Example uses 10 connections instead of 1000, so this will fail :)
//
// test "part1 example" {
//     const input = common.trimInput(
//         \\162,817,812
//         \\57,618,57
//         \\906,360,560
//         \\592,479,940
//         \\352,342,300
//         \\466,668,158
//         \\542,29,236
//         \\431,825,988
//         \\739,650,466
//         \\52,470,668
//         \\216,146,977
//         \\819,987,18
//         \\117,168,530
//         \\805,96,715
//         \\346,949,466
//         \\970,615,88
//         \\941,993,340
//         \\862,61,35
//         \\984,92,344
//         \\425,690,689
//     );
//     try common.expectResult(u64, 40, part1(std.testing.allocator, input));
// }

test "part2 example" {
    const input = common.trimInput(
        \\162,817,812
        \\57,618,57
        \\906,360,560
        \\592,479,940
        \\352,342,300
        \\466,668,158
        \\542,29,236
        \\431,825,988
        \\739,650,466
        \\52,470,668
        \\216,146,977
        \\819,987,18
        \\117,168,530
        \\805,96,715
        \\346,949,466
        \\970,615,88
        \\941,993,340
        \\862,61,35
        \\984,92,344
        \\425,690,689
    );
    try common.expectResult(u64, 25272, part2(std.testing.allocator, input));
}
