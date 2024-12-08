const std = @import("std");

const Rule = struct {
    before: i64,
    after: i64,
};

pub fn main(input: []const u8) !struct { part1: u64, part2: u64, time: f64 } {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var timer = try std.time.Timer.start();

    var rules = try parseRules(allocator, input);
    defer rules.deinit();

    const sums = try processSequences(allocator, input, rules);

    const time = @as(f64, @floatFromInt(timer.lap())) / std.time.ns_per_us;

    return .{
        .part1 = @intCast(sums.part1),
        .part2 = @intCast(sums.part2),
        .time = time,
    };
}

fn parseRules(allocator: std.mem.Allocator, input: []const u8) !std.ArrayList(Rule) {
    var rules = std.ArrayList(Rule).init(allocator);
    var lines = std.mem.splitSequence(u8, input, "\n");

    while (lines.next()) |line| {
        if (line.len == 0) break;

        var nums_it = std.mem.splitSequence(u8, line, "|");
        const n1 = try std.fmt.parseInt(i64, std.mem.trim(u8, nums_it.next().?, " "), 10);
        const n2 = try std.fmt.parseInt(i64, std.mem.trim(u8, nums_it.next().?, " "), 10);
        try rules.append(.{ .before = n1, .after = n2 });
    }
    return rules;
}

fn processSequences(
    allocator: std.mem.Allocator,
    input: []const u8,
    rules: std.ArrayList(Rule),
) !struct { part1: i64, part2: i64 } {
    var sum1: i64 = 0;
    var sum2: i64 = 0;

    var lines = std.mem.splitSequence(u8, input, "\n");
    while (lines.next()) |line| {
        if (line.len == 0) break;
    }

    while (lines.next()) |line| {
        if (line.len == 0) continue;

        var nums = try parseNumberSequence(allocator, line);
        defer nums.deinit();

        const items = nums.items;
        if (items.len == 0) continue;

        if (isValidSequence(items, rules)) {
            sum1 += items[(items.len - 1) / 2];
        }

        if (try applyRules(items, rules)) {
            sum2 += items[(items.len - 1) / 2];
        }
    }

    return .{ .part1 = sum1, .part2 = sum2 };
}

fn parseNumberSequence(allocator: std.mem.Allocator, line: []const u8) !std.ArrayList(i64) {
    var nums = std.ArrayList(i64).init(allocator);
    var nums_it = std.mem.splitSequence(u8, line, ",");

    while (nums_it.next()) |num_str| {
        const n = try std.fmt.parseInt(i64, std.mem.trim(u8, num_str, " "), 10);
        try nums.append(n);
    }
    return nums;
}

fn isValidSequence(items: []i64, rules: std.ArrayList(Rule)) bool {
    for (items, 0..) |x, i| {
        for (items[i + 1 ..]) |y| {
            for (rules.items) |rule| {
                if (x == rule.after and y == rule.before) {
                    return false;
                }
            }
        }
    }
    return true;
}

fn applyRules(items: []i64, rules: std.ArrayList(Rule)) !bool {
    var any_change = false;
    var changed = true;

    while (changed) {
        changed = false;
        for (0..items.len) |i| {
            for (i + 1..items.len) |j| {
                for (rules.items) |rule| {
                    if (items[i] == rule.after and items[j] == rule.before) {
                        const temp = items[i];
                        items[i] = items[j];
                        items[j] = temp;
                        changed = true;
                        any_change = true;
                    }
                }
            }
        }
    }
    return any_change;
}

test "day 5" {
    const input =
        \\47|53
        \\97|13
        \\97|61
        \\97|47
        \\75|29
        \\61|13
        \\75|53
        \\29|13
        \\97|29
        \\53|29
        \\61|53
        \\97|53
        \\61|29
        \\47|13
        \\75|47
        \\97|75
        \\47|61
        \\75|61
        \\47|29
        \\75|13
        \\53|13
        \\
        \\75,47,61,53,29
        \\97,61,53,29,13
        \\75,29,13
        \\75,97,47,61,53
        \\61,13,29
        \\97,13,75,29,47
    ;
    const result = try main(input);
    try std.testing.expectEqual(@as(u64, 143), result.part1);
    try std.testing.expectEqual(@as(u64, 123), result.part2);
}
