const std = @import("std");

/// Read the entire contents of an input file for a given day
pub fn readInput(allocator: std.mem.Allocator, comptime day: []const u8) ![]const u8 {
    const path = "inputs/" ++ day ++ ".txt";
    return std.fs.cwd().readFileAlloc(allocator, path, std.math.maxInt(usize)) catch |err| {
        std.debug.print("Failed to read {s}: {}\n", .{ path, err });
        return err;
    };
}

/// Split input into lines, skipping empty trailing lines
pub fn lines(input: []const u8) std.mem.SplitIterator(u8, .sequence) {
    return std.mem.splitSequence(u8, std.mem.trimRight(u8, input, "\n"), "\n");
}

/// Split by any delimiter sequence
pub fn splitSeq(input: []const u8, delim: []const u8) std.mem.SplitIterator(u8, .sequence) {
    return std.mem.splitSequence(u8, input, delim);
}

/// Split by any of the given characters (e.g., " \t" for whitespace)
pub fn splitAny(input: []const u8, delimiters: []const u8) std.mem.SplitIterator(u8, .any) {
    return std.mem.splitAny(u8, input, delimiters);
}

/// Tokenize by any of the given characters, collapsing consecutive delimiters
pub fn tokenize(input: []const u8, delimiters: []const u8) std.mem.TokenIterator(u8, .any) {
    return std.mem.tokenizeAny(u8, input, delimiters);
}

/// Parse a string as an integer
pub fn parseInt(comptime T: type, str: []const u8) !T {
    return std.fmt.parseInt(T, str, 10);
}

/// Extract all integers from a string
pub fn extractInts(comptime T: type, allocator: std.mem.Allocator, input: []const u8) !std.ArrayList(T) {
    var result = std.ArrayList(T).init(allocator);
    var i: usize = 0;

    while (i < input.len) {
        // Skip non-digit, non-minus characters
        while (i < input.len and !std.ascii.isDigit(input[i]) and input[i] != '-') {
            i += 1;
        }
        if (i >= input.len) break;

        // Find end of number
        var j = i;
        if (input[j] == '-') j += 1;
        while (j < input.len and std.ascii.isDigit(input[j])) {
            j += 1;
        }

        if (j > i and !(j == i + 1 and input[i] == '-')) {
            const num = std.fmt.parseInt(T, input[i..j], 10) catch {
                i = j;
                continue;
            };
            try result.append(num);
        }
        i = j;
    }

    return result;
}

test "lines splits correctly" {
    const input = "line1\nline2\nline3\n";
    var iter = lines(input);

    try std.testing.expectEqualStrings("line1", iter.next().?);
    try std.testing.expectEqualStrings("line2", iter.next().?);
    try std.testing.expectEqualStrings("line3", iter.next().?);
    try std.testing.expect(iter.next() == null);
}

test "extractInts finds all integers" {
    const allocator = std.testing.allocator;
    const input = "Game 1: 3 blue, -4 red; 12 green";
    var ints = try extractInts(i32, allocator, input);
    defer ints.deinit();

    try std.testing.expectEqualSlices(i32, &[_]i32{ 1, 3, -4, 12 }, ints.items);
}

test "tokenize collapses whitespace" {
    var iter = tokenize("  hello   world  ", " ");

    try std.testing.expectEqualStrings("hello", iter.next().?);
    try std.testing.expectEqualStrings("world", iter.next().?);
    try std.testing.expect(iter.next() == null);
}

// ============================================================================
// Testing utilities
// ============================================================================

/// Test that a solution function returns the expected result for given input
pub fn expectResult(comptime T: type, expected: T, actual: anyerror!T) !void {
    const value = actual catch |err| {
        std.debug.print("Function returned error: {}\n", .{err});
        return error.TestUnexpectedResult;
    };
    try std.testing.expectEqual(expected, value);
}

/// Multiline string literal helper - trims leading newline and trailing whitespace
pub fn trimInput(input: []const u8) []const u8 {
    var result = input;
    if (result.len > 0 and result[0] == '\n') {
        result = result[1..];
    }
    return std.mem.trimRight(u8, result, " \n");
}

test "expectResult passes on match" {
    const f = struct {
        fn solve(_: []const u8) !i32 {
            return 42;
        }
    }.solve;
    try expectResult(i32, 42, f(""));
}

test "trimInput removes leading newline" {
    const input = trimInput(
        \\first
        \\second
    );
    try std.testing.expectEqualStrings("first\nsecond", input);
}
