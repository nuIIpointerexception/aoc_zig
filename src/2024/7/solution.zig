const std = @import("std");

fn solve(comptime num_ops: u8, target: u64, result: u64, nums: []const u64) u64 {
    if (nums.len == 0) return @intFromBool(result == target) * target;
    const n = nums[0];
    const rest = nums[1..];

    const sum = solve(num_ops, target, result + n, rest);
    if (sum > 0) return sum;

    const product = solve(num_ops, target, result * n, rest);
    if (product > 0) return product;

    if (num_ops == 3) {
        const shift = @as(u6, if (n >= 100) 2 else if (n >= 10) 1 else 0) * 2;
        const adj: u64 = @as(u64, 10) << shift;
        return solve(num_ops, target, result * adj + n, rest);
    }
    return 0;
}

fn parseNum(line: []const u8, nums: *[15]u64) struct { target: u64, len: u8 } {
    var i: u8 = 0;
    var it = std.mem.tokenizeAny(u8, line, ": ");
    const target = std.fmt.parseInt(u64, it.next().?, 10) catch unreachable;

    while (it.next()) |n| : (i += 1) {
        nums[i] = std.fmt.parseInt(u64, n, 10) catch unreachable;
    }
    return .{ .target = target, .len = i };
}

pub fn main(input: []const u8) !struct { part1: u64, part2: u64, time: f64 } {
    var start = try std.time.Timer.start();
    var sum1: u64 = 0;
    var sum2: u64 = 0;
    var nums: [15]u64 = undefined;

    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        const parsed = parseNum(line, &nums);
        sum1 += solve(2, parsed.target, nums[0], nums[1..parsed.len]);
        sum2 += solve(3, parsed.target, nums[0], nums[1..parsed.len]);
    }

    const time = @as(f64, @floatFromInt(start.lap())) / std.time.ns_per_us;
    return .{ .part1 = sum1, .part2 = sum2, .time = time };
}

test "day 7" {
    const test_input =
        \\190: 10 19
        \\3267: 81 40 27
        \\83: 17 5
        \\156: 15 6
        \\7290: 6 8 6 15
        \\161011: 16 10 13
        \\192: 17 8 14
        \\21037: 9 7 18 13
        \\292: 11 6 16 20
    ;
    const result = try main(test_input);
    try std.testing.expectEqual(3749, result.part1);
    try std.testing.expectEqual(11387, result.part2);
}
