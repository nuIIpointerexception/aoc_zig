const std = @import("std");
const builtin = @import("builtin");

const NumberPair = struct {
    left: u64,
    right: u64,
};

const Parser = struct {
    input: []const u8,
    pos: usize = 0,

    fn init(input: []const u8) Parser {
        return .{ .input = input };
    }

    fn skipWhitespace(self: *Parser) void {
        const input = self.input;
        var pos = self.pos;
        while (pos < input.len and input[pos] <= ' ') {
            pos += 1;
        }
        self.pos = pos;
    }

    fn parseNumber(self: *Parser) u64 {
        @setRuntimeSafety(false);
        const input = self.input;
        var pos = self.pos;
        var num: u64 = input[pos] - '0';
        pos += 1;

        const input_ptr = input.ptr;
        while (pos < input.len and input_ptr[pos] >= '0' and input_ptr[pos] <= '9') {
            num = (num << 3) + (num << 1) + (input_ptr[pos] - '0');
            pos += 1;
        }
        self.pos = pos;
        return num;
    }

    fn parsePair(self: *Parser) ?NumberPair {
        if (self.pos >= self.input.len) return null;
        self.skipWhitespace();
        if (self.pos >= self.input.len) return null;
        const left = self.parseNumber();
        self.skipWhitespace();
        const right = self.parseNumber();
        return NumberPair{ .left = left, .right = right };
    }
};

inline fn absDiff(a: u64, b: u64) u64 {
    if (builtin.cpu.arch == .x86_64) {
        return asm (
            \\movq %[a], %%rax
            \\subq %[b], %%rax
            \\jae 1f
            \\negq %%rax
            \\1:
            : [ret] "={rax}" (-> u64),
            : [a] "r" (a),
              [b] "r" (b),
        );
    }
    return if (a > b) a - b else b - a;
}

fn insertionSort(arr: []u64) void {
    @setRuntimeSafety(false);
    const len = arr.len;
    if (len <= 1) return;

    var i: usize = 1;
    while (i < len) : (i += 1) {
        const key = arr[i];
        var j: isize = @as(isize, @intCast(i)) - 1;
        const ptr = arr.ptr;
        while (j >= 0 and ptr[@as(usize, @intCast(j))] > key) : (j -= 1) {
            ptr[@as(usize, @intCast(j + 1))] = ptr[@as(usize, @intCast(j))];
        }
        ptr[@as(usize, @intCast(j + 1))] = key;
    }
}

fn calcPart1(left: []u64, right: []u64, pair_count: usize) u64 {
    @setRuntimeSafety(false);
    var part1: u64 = 0;
    var j: usize = 0;

    while (j + 8 <= pair_count) : (j += 8) {
        const l_ptr = left.ptr + j;
        const r_ptr = right.ptr + j;
        part1 += absDiff(l_ptr[0], r_ptr[0]) +
            absDiff(l_ptr[1], r_ptr[1]) +
            absDiff(l_ptr[2], r_ptr[2]) +
            absDiff(l_ptr[3], r_ptr[3]) +
            absDiff(l_ptr[4], r_ptr[4]) +
            absDiff(l_ptr[5], r_ptr[5]) +
            absDiff(l_ptr[6], r_ptr[6]) +
            absDiff(l_ptr[7], r_ptr[7]);
    }

    while (j < pair_count) : (j += 1) {
        part1 += absDiff(left[j], right[j]);
    }

    return part1;
}

pub fn main(input: []const u8) !struct { part1: u64, part2: u64, time: f64 } {
    var timer = try std.time.Timer.start();

    var left: [1000]u64 = undefined;
    var right: [1000]u64 = undefined;
    var left_original: [1000]u64 = undefined;
    var pair_count: usize = 0;

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var right_freq = std.AutoHashMap(u64, u64).init(arena.allocator());
    defer right_freq.deinit();
    try right_freq.ensureTotalCapacity(1000);

    var parser = Parser.init(input);
    while (parser.parsePair()) |pair| {
        left[pair_count] = pair.left;
        left_original[pair_count] = pair.left;
        right[pair_count] = pair.right;

        const entry = right_freq.getOrPutAssumeCapacity(pair.right);
        entry.value_ptr.* = if (entry.found_existing) entry.value_ptr.* + 1 else 1;

        pair_count += 1;
    }

    const left_slice = left[0..pair_count];
    const right_slice = right[0..pair_count];

    if (pair_count > 32) {
        std.sort.pdq(u64, left_slice, {}, comptime std.sort.asc(u64));
        std.sort.pdq(u64, right_slice, {}, comptime std.sort.asc(u64));
    } else {
        insertionSort(left_slice);
        insertionSort(right_slice);
    }

    const part1 = calcPart1(left_slice, right_slice, pair_count);

    var part2: u64 = 0;
    const left_orig_slice = left_original[0..pair_count];
    for (left_orig_slice) |num| {
        if (right_freq.get(num)) |count| {
            part2 += num * count;
        }
    }

    const time = @as(f64, @floatFromInt(timer.lap())) / std.time.ns_per_us;
    return .{ .part1 = part1, .part2 = part2, .time = time };
}

test "day 1" {
    const input =
        \\3   4
        \\4   3
        \\2   5
        \\1   3
        \\3   9
        \\3   3
    ;
    const result = try main(input);
    try std.testing.expectEqual(@as(u64, 11), result.part1);
    try std.testing.expectEqual(@as(u64, 31), result.part2);
}
