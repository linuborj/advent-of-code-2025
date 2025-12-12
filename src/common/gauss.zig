const std = @import("std");
const Rational = @import("rational.zig").Rational;

/// Result of Gaussian elimination.
/// Each variable is expressed as: var = constant + sum(coeff[i] * freeVar[i])
/// Free variables are those where expressions[v][v+1] != 0 (they depend on themselves).
pub const Solution = struct {
    /// expressions[var][0] = constant, expressions[var][i+1] = coefficient for variable i
    expressions: [][]Rational,
    numVars: usize,

    /// Evaluate a variable given values for free variables
    pub fn evaluate(self: Solution, varIdx: usize, freeVars: []const usize, freeVals: []const i64) Rational {
        var val = self.expressions[varIdx][0];
        for (freeVars, freeVals) |fv, fval| {
            val = val.add(self.expressions[varIdx][fv + 1].mul(Rational.fromInt(fval)));
        }
        return val;
    }

    /// Get list of free variable indices
    pub fn getFreeVars(self: Solution, allocator: std.mem.Allocator) ![]usize {
        var list: std.ArrayList(usize) = .empty;
        for (0..self.numVars) |v| {
            if (!self.expressions[v][v + 1].isZero()) {
                try list.append(allocator, v);
            }
        }
        return list.toOwnedSlice(allocator);
    }
};

/// Solve a system of linear equations using Gaussian elimination.
/// Returns expressions for each variable in terms of free variables.
/// Returns error.Inconsistent if the system has no solution.
pub fn solve(allocator: std.mem.Allocator, coefficients: []const []const Rational, constants: []const Rational) !Solution {
    const numEquations = coefficients.len;
    const numVars = coefficients[0].len;

    // remaining[eq][0] = target, remaining[eq][var+1] = -coefficient
    const remaining = try allocator.alloc([]Rational, numEquations);
    for (0..numEquations) |i| {
        remaining[i] = try allocator.alloc(Rational, numVars + 1);
        remaining[i][0] = constants[i];
        for (0..numVars) |j| {
            remaining[i][j + 1] = coefficients[i][j].negate();
        }
    }

    // expressions[var] = expression for that variable
    const expressions = try allocator.alloc([]Rational, numVars);
    for (0..numVars) |i| {
        expressions[i] = try allocator.alloc(Rational, numVars + 1);
        expressions[i][0] = Rational.fromInt(0);
        for (0..numVars) |j| {
            expressions[i][j + 1] = if (i == j) Rational.fromInt(1) else Rational.fromInt(0);
        }
    }

    // Gaussian elimination: repeatedly solve the most constrained equation
    while (true) {
        var bestEq: ?usize = null;
        var fewestUnknowns: usize = std.math.maxInt(usize);

        for (0..numEquations) |eq| {
            var unknowns: usize = 0;
            for (0..numVars) |v| {
                if (!remaining[eq][v + 1].isZero()) unknowns += 1;
            }

            if (remaining[eq][0].isZero() and unknowns == 0) continue; // Already satisfied
            if (unknowns == 0 and !remaining[eq][0].isZero()) return error.Inconsistent;

            if (unknowns < fewestUnknowns) {
                fewestUnknowns = unknowns;
                bestEq = eq;
            }
        }

        const eq = bestEq orelse break; // All equations satisfied

        // Pick first non-zero variable in this equation
        var solveVar: usize = undefined;
        for (0..numVars) |v| {
            if (!remaining[eq][v + 1].isZero()) {
                solveVar = v;
                break;
            }
        }

        // Solve: var = (target - sum(coeff * other)) / coeff
        const coeff = remaining[eq][solveVar + 1];
        expressions[solveVar][0] = remaining[eq][0].negate().div(coeff);
        for (0..numVars) |other| {
            expressions[solveVar][other + 1] = if (other == solveVar)
                Rational.fromInt(0)
            else
                remaining[eq][other + 1].negate().div(coeff);
        }

        // Substitute into remaining equations
        for (0..numEquations) |otherEq| {
            const c = remaining[otherEq][solveVar + 1];
            if (c.isZero()) continue;
            remaining[otherEq][0] = remaining[otherEq][0].add(c.mul(expressions[solveVar][0]));
            for (0..numVars) |other| {
                remaining[otherEq][other + 1] = remaining[otherEq][other + 1].add(c.mul(expressions[solveVar][other + 1]));
            }
            remaining[otherEq][solveVar + 1] = Rational.fromInt(0);
        }

        // Substitute into other variable expressions
        for (0..numVars) |otherVar| {
            if (otherVar == solveVar) continue;
            const c = expressions[otherVar][solveVar + 1];
            if (c.isZero()) continue;
            expressions[otherVar][0] = expressions[otherVar][0].add(c.mul(expressions[solveVar][0]));
            for (0..numVars) |other| {
                expressions[otherVar][other + 1] = expressions[otherVar][other + 1].add(c.mul(expressions[solveVar][other + 1]));
            }
            expressions[otherVar][solveVar + 1] = Rational.fromInt(0);
        }
    }

    return .{ .expressions = expressions, .numVars = numVars };
}

test "determined system" {
    // x + y = 3, x - y = 1  =>  x = 2, y = 1
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const coeffs = [_][]const Rational{
        &.{ Rational.fromInt(1), Rational.fromInt(1) },
        &.{ Rational.fromInt(1), Rational.fromInt(-1) },
    };
    const consts = [_]Rational{ Rational.fromInt(3), Rational.fromInt(1) };

    const sol = try solve(arena.allocator(), &coeffs, &consts);
    const freeVars = try sol.getFreeVars(arena.allocator());

    try std.testing.expectEqual(0, freeVars.len);
    try std.testing.expectEqual(2, sol.evaluate(0, freeVars, &.{}).toInt().?); // x = 2
    try std.testing.expectEqual(1, sol.evaluate(1, freeVars, &.{}).toInt().?); // y = 1
}

test "underdetermined system" {
    // x + y = 5  =>  y is free, x = 5 - y
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const coeffs = [_][]const Rational{
        &.{ Rational.fromInt(1), Rational.fromInt(1) },
    };
    const consts = [_]Rational{Rational.fromInt(5)};

    const sol = try solve(arena.allocator(), &coeffs, &consts);
    const freeVars = try sol.getFreeVars(arena.allocator());

    try std.testing.expectEqual(1, freeVars.len);
    try std.testing.expectEqual(1, freeVars[0]); // y is free
    try std.testing.expectEqual(5, sol.evaluate(0, freeVars, &.{0}).toInt().?); // y=0 => x=5
    try std.testing.expectEqual(3, sol.evaluate(0, freeVars, &.{2}).toInt().?); // y=2 => x=3
}
