const std = @import("std");

const max_nums = 32;

const PackedNums = struct {
    data: [max_nums]i8 align(16),
    len: u8,
};

const Direction = struct {
    const NONE: u8 = 0;
    const UP: u8 = 1;
    const DOWN: u8 = 2;
    const BOTH: u8 = UP | DOWN;
};

inline fn isValidStep(curr: i8, prev: i8) bool {
    const diff = @abs(curr - prev);
    return diff > 0 and diff <= 3;
}

inline fn updateDirection(direction: *u8, curr: i8, prev: i8) void {
    direction.* |= if (curr > prev) Direction.UP else Direction.DOWN;
}

inline fn safe(nums: []const i8, len: u8) bool {
    if (len <= 1) return true;
    if (len > max_nums) return false;

    var direction: u8 = Direction.NONE;
    var prev = nums[0];

    // process in 4
    var i: u8 = 1;
    while (i + 4 <= len) : (i += 4) {
        inline for (0..4) |offset| {
            const curr = nums[i + offset];
            if (!isValidStep(curr, prev)) return false;
            updateDirection(&direction, curr, prev);
            if (direction == Direction.BOTH) return false;
            prev = curr;
        }
    }

    // remaining nums
    while (i < len) : (i += 1) {
        const curr = nums[i];
        if (!isValidStep(curr, prev)) return false;
        updateDirection(&direction, curr, prev);
        if (direction == Direction.BOTH) return false;
        prev = curr;
    }

    return true;
}

const NumberParser = struct {
    lookup: [256]i8,

    fn init() NumberParser {
        var table: [256]i8 = undefined;
        @memset(&table, -1);
        for ("0123456789", 0..) |c, i| {
            table[c] = @intCast(i);
        }
        return .{ .lookup = table };
    }

    fn parseLine(self: *const NumberParser, line: []const u8, nums: *PackedNums) void {
        nums.len = 0;
        var num: i8 = 0;

        for (line) |c| {
            const digit = self.lookup[c];
            if (digit >= 0) {
                num = num * 10 + digit;
            } else if (c == ' ' and num != 0) {
                nums.data[nums.len] = num;
                nums.len += 1;
                num = 0;
            }
        }

        if (num != 0) {
            nums.data[nums.len] = num;
            nums.len += 1;
        }
    }
};

fn removeNum(nums: *const PackedNums, temp: *PackedNums) bool {
    for (0..nums.len) |skip_idx| {
        @memcpy(temp.data[0..skip_idx], nums.data[0..skip_idx]);
        @memcpy(temp.data[skip_idx .. nums.len - 1], nums.data[skip_idx + 1 .. nums.len]);
        temp.len = nums.len - 1;

        if (safe(&temp.data, temp.len)) {
            return true;
        }
    }
    return false;
}

pub fn main(input: []const u8) !struct { part1: u64, part2: u64, time: f64 } {
    var timer = try std.time.Timer.start();
    const parser = NumberParser.init();

    var count_part1: u64 = 0;
    var count_part2: u64 = 0;

    var nums = PackedNums{ .data = undefined, .len = 0 };
    var temp = PackedNums{ .data = undefined, .len = 0 };

    const trimmed = std.mem.trim(u8, input, &[_]u8{ '\n', '\r' });
    var lines = std.mem.splitScalar(u8, trimmed, '\n');

    while (lines.next()) |line| {
        parser.parseLine(line, &nums);

        if (safe(&nums.data, nums.len)) {
            count_part1 += 1;
            count_part2 += 1;
            continue;
        }

        if (nums.len > 1 and removeNum(&nums, &temp)) {
            count_part2 += 1;
        }
    }

    const time = @as(f64, @floatFromInt(timer.lap())) / std.time.ns_per_us;

    return .{
        .part1 = count_part1,
        .part2 = count_part2,
        .time = time,
    };
}

test "day 2" {
    const input =
        \\7 6 4 2 1
        \\1 2 7 8 9
        \\9 7 6 2 1
        \\1 3 2 4 5
        \\8 6 4 4 1
        \\1 3 6 7 9
    ;
    const result = try main(input);
    try std.testing.expectEqual(@as(u64, 2), result.part1);
    try std.testing.expectEqual(@as(u64, 4), result.part2);
}
