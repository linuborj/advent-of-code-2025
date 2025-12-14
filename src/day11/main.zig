const std = @import("std");
const common = @import("common");
const mecha = @import("mecha");

const deviceName = mecha.ascii.alphabetic.many(.{ .min = 1 }).asStr();

const lineParser = mecha.combine(.{
    deviceName,
    mecha.string(": ").discard(),
    deviceName.many(.{ .min = 1, .separator = mecha.ascii.char(' ').discard() }),
});

const inputParser = lineParser.many(.{ .separator = mecha.ascii.char('\n').discard() });

const Graph = std.StringHashMap([]const []const u8);

fn parseGraph(allocator: std.mem.Allocator, input: []const u8) !Graph {
    const lines = (try inputParser.parse(allocator, input)).value.ok;

    var graph = Graph.init(allocator);
    for (lines) |line| {
        const name, const outputs = line;
        try graph.put(name, outputs);
    }
    return graph;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const input = try common.readInput(allocator, "day11");
    defer allocator.free(input);

    const part1Result = try part1(allocator, input);
    std.debug.print("Part 1: {}\n", .{part1Result});

    const part2Result = try part2(allocator, input);
    std.debug.print("Part 2: {}\n", .{part2Result});
}

fn part1(allocator: std.mem.Allocator, input: []const u8) !u64 {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const graph = try parseGraph(arena.allocator(), input);
    var memo = std.StringHashMap(u64).init(arena.allocator());
    return countPathsPart1(graph, "you", &memo);
}

fn countPathsPart1(graph: Graph, node: []const u8, memo: *std.StringHashMap(u64)) u64 {
    if (std.mem.eql(u8, node, "out")) return 1;

    if (memo.get(node)) |cached| return cached;

    const outputs = graph.get(node) orelse return 0;
    var total: u64 = 0;
    for (outputs) |next| {
        total += countPathsPart1(graph, next, memo);
    }

    memo.put(node, total) catch {};
    return total;
}

const Visited = enum(u2) {
    neither = 0,
    dac_only = 1,
    fft_only = 2,
    both = 3,

    fn visit(self: Visited, node: []const u8) Visited {
        var bits = @intFromEnum(self);
        if (std.mem.eql(u8, node, "dac")) bits |= 1;
        if (std.mem.eql(u8, node, "fft")) bits |= 2;
        return @enumFromInt(bits);
    }
};

const State = std.EnumArray(Visited, ?u64);

fn part2(allocator: std.mem.Allocator, input: []const u8) !u64 {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const graph = try parseGraph(arena.allocator(), input);
    var memo = std.StringHashMap(State).init(arena.allocator());
    return countPathsPart2(graph, "svr", .neither, &memo);
}

fn countPathsPart2(graph: Graph, node: []const u8, state: Visited, memo: *std.StringHashMap(State)) u64 {
    const visited = state.visit(node);

    if (std.mem.eql(u8, node, "out")) {
        return if (visited == .both) 1 else 0;
    }

    if (memo.get(node)) |entry| {
        if (entry.get(visited)) |cached| return cached;
    }

    const outputs = graph.get(node).?;
    var total: u64 = 0;
    for (outputs) |next| {
        total += countPathsPart2(graph, next, visited, memo);
    }

    const memoized = memo.getOrPutValue(node, State.initFill(null)) catch return total;
    memoized.value_ptr.set(visited, total);
    return total;
}

test "part1 example" {
    const input = common.trimInput(
        \\aaa: you hhh
        \\you: bbb ccc
        \\bbb: ddd eee
        \\ccc: ddd eee fff
        \\ddd: ggg
        \\eee: out
        \\fff: out
        \\ggg: out
        \\hhh: ccc fff iii
        \\iii: out
    );
    try common.expectResult(u64, 5, part1(std.testing.allocator, input));
}

test "part2 example" {
    const input = common.trimInput(
        \\svr: aaa bbb
        \\aaa: fft
        \\fft: ccc
        \\bbb: tty
        \\tty: ccc
        \\ccc: ddd eee
        \\ddd: hub
        \\hub: fff
        \\eee: dac
        \\dac: fff
        \\fff: ggg hhh
        \\ggg: out
        \\hhh: out
    );
    try common.expectResult(u64, 2, part2(std.testing.allocator, input));
}
