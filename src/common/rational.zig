const std = @import("std");

pub const Rational = struct {
    num: i64,
    denom: i64,

    pub fn init(num: i64, denom: i64) Rational {
        var r = Rational{ .num = num, .denom = denom };
        r.normalize();
        return r;
    }

    pub fn fromInt(n: i64) Rational {
        return .{ .num = n, .denom = 1 };
    }

    fn gcd(a: i64, b: i64) i64 {
        var x = @abs(a);
        var y = @abs(b);
        while (y != 0) {
            const t = y;
            y = @mod(x, y);
            x = t;
        }
        return @intCast(x);
    }

    fn normalize(self: *Rational) void {
        if (self.denom == 0) @panic("division by zero");

        if (self.denom < 0) {
            self.num = -self.num;
            self.denom = -self.denom;
        }

        const g = gcd(self.num, self.denom);
        self.num = @divExact(self.num, g);
        self.denom = @divExact(self.denom, g);
    }

    pub fn add(a: Rational, b: Rational) Rational {
        return init(a.num * b.denom + b.num * a.denom, a.denom * b.denom);
    }

    pub fn sub(a: Rational, b: Rational) Rational {
        return init(a.num * b.denom - b.num * a.denom, a.denom * b.denom);
    }

    pub fn mul(a: Rational, b: Rational) Rational {
        return init(a.num * b.num, a.denom * b.denom);
    }

    pub fn div(a: Rational, b: Rational) Rational {
        return init(a.num * b.denom, a.denom * b.num);
    }

    pub fn negate(self: Rational) Rational {
        return .{ .num = -self.num, .denom = self.denom };
    }

    pub fn isZero(self: Rational) bool {
        return self.num == 0;
    }

    pub fn isInteger(self: Rational) bool {
        return self.denom == 1;
    }

    pub fn toInt(self: Rational) ?i64 {
        if (self.denom == 1) return self.num;
        return null;
    }

    pub fn eql(a: Rational, b: Rational) bool {
        return a.num == b.num and a.denom == b.denom;
    }

    pub fn format(
        self: Rational,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        if (self.denom == 1) {
            try writer.print("{}", .{self.num});
        } else {
            try writer.print("{}/{}", .{ self.num, self.denom });
        }
    }
};

test "basic operations" {
    const half = Rational.init(1, 2);
    const third = Rational.init(1, 3);

    // 1/2 + 1/3 = 5/6
    const sum = Rational.add(half, third);
    try std.testing.expectEqual(@as(i64, 5), sum.num);
    try std.testing.expectEqual(@as(i64, 6), sum.denom);

    // 1/2 * 1/3 = 1/6
    const prod = Rational.mul(half, third);
    try std.testing.expectEqual(@as(i64, 1), prod.num);
    try std.testing.expectEqual(@as(i64, 6), prod.denom);

    // 1/2 / 1/3 = 3/2
    const quot = Rational.div(half, third);
    try std.testing.expectEqual(@as(i64, 3), quot.num);
    try std.testing.expectEqual(@as(i64, 2), quot.denom);
}

test "normalization" {
    // 4/8 = 1/2
    const r = Rational.init(4, 8);
    try std.testing.expectEqual(@as(i64, 1), r.num);
    try std.testing.expectEqual(@as(i64, 2), r.denom);

    // -3/-6 = 1/2
    const r2 = Rational.init(-3, -6);
    try std.testing.expectEqual(@as(i64, 1), r2.num);
    try std.testing.expectEqual(@as(i64, 2), r2.denom);

    // 3/-6 = -1/2
    const r3 = Rational.init(3, -6);
    try std.testing.expectEqual(@as(i64, -1), r3.num);
    try std.testing.expectEqual(@as(i64, 2), r3.denom);
}

test "integer conversion" {
    const whole = Rational.init(6, 2); // 3
    try std.testing.expect(whole.isInteger());
    try std.testing.expectEqual(@as(i64, 3), whole.toInt().?);

    const frac = Rational.init(1, 2);
    try std.testing.expect(!frac.isInteger());
    try std.testing.expectEqual(@as(?i64, null), frac.toInt());
}
