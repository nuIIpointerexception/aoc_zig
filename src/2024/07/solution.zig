const std = @import("std");

inline fn nextPowerOf10(x: u64) u64 {
    var power: u64 = 10;
    while (x >= power) power *= 10;
    return power;
}

fn canConstructTarget(target: u64, ops: []const u64, comptime allowConcatenation: bool) bool {
    if (ops.len == 1) return target == ops[0];
    if (ops.len == 0) return target == 0;

    const current = ops[ops.len - 1];
    const remaining = ops[0 .. ops.len - 1];

    if (allowConcatenation) {
        const power = nextPowerOf10(current);
        if (target >= current and @rem(target - current, power) == 0) {
            if (canConstructTarget((target - current) / power, remaining, allowConcatenation)) return true;
        }
    }

    if (@rem(target, current) == 0) {
        if (canConstructTarget(target / current, remaining, allowConcatenation)) return true;
    }

    if (target >= current) {
        if (canConstructTarget(target - current, remaining, allowConcatenation)) return true;
    }

    return false;
}

fn solve(lines: []const []const u8) struct { part1: u64, part2: u64 } {
    var part1: u64 = 0;
    var part2: u64 = 0;
    var numbers: [64]u64 = undefined;

    for (lines) |line| {
        var count: usize = 0;
        numbers[0] = 0;

        for (line) |char| {
            if (char >= '0' and char <= '9') {
                numbers[count] = numbers[count] * 10 + (char - '0');
            } else if (numbers[count] != 0) {
                count += 1;
                numbers[count] = 0;
            }
        }
        if (numbers[count] != 0) count += 1;

        const target = numbers[0];
        const operands = numbers[1..count];

        if (canConstructTarget(target, operands, false)) {
            part1 += target;
            part2 += target;
        } else if (canConstructTarget(target, operands, true)) {
            part2 += target;
        }
    }

    return .{ .part1 = part1, .part2 = part2 };
}

pub fn main(input: []const u8) !struct { part1: u64, part2: u64, time: f64 } {
    var timer = try std.time.Timer.start();
    var lines = std.ArrayList([]const u8).init(std.heap.page_allocator);
    defer lines.deinit();

    var it = std.mem.splitSequence(u8, std.mem.trim(u8, input, &std.ascii.whitespace), "\n");
    while (it.next()) |line| {
        try lines.append(line);
    }

    const result = solve(lines.items);
    const time = @as(f64, @floatFromInt(timer.read())) / std.time.ns_per_us;
    return .{ .part1 = result.part1, .part2 = result.part2, .time = time };
}
