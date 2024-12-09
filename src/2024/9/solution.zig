const std = @import("std");

const Interval = struct {
    start: u32,
    size: u32,
    id: u32,

    inline fn checksum(self: Interval) u64 {
        return self.id * arithmeticSeries(self.start, self.size);
    }
};

inline fn arithmeticSeries(start: u64, count: u64) u64 {
    const twice_start = start << 1;
    return (count * (twice_start + count - 1)) >> 1;
}

inline fn isDigit(c: u8) bool {
    return c >= '1' and c <= '9';
}

inline fn digitToInt(c: u8) u32 {
    return @as(u32, c - '0');
}

pub fn main(input: []const u8) !struct { part1: u64, part2: u64, time: f64 } {
    var start = try std.time.Timer.start();
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const counts = countElements(input);
    const part1_result = try calculatePart1(allocator, input, counts.max_pos);
    const part2_result = try calculatePart2(allocator, input, counts);

    const time = @as(f64, @floatFromInt(start.lap())) / std.time.ns_per_ms;
    return .{ .part1 = part1_result, .part2 = part2_result, .time = time };
}

const Counts = struct {
    max_pos: usize,
    file_count: usize,
    space_count: usize,
};

inline fn countElements(input: []const u8) Counts {
    var max_pos: usize = 0;
    var file_count: usize = 0;
    var space_count: usize = 0;

    // Input already done on higher level
    @setRuntimeSafety(false);
    for (input, 0..) |c, i| {
        if (!isDigit(c)) continue;
        const size = digitToInt(c);
        max_pos += size;
        if (i % 2 == 0) {
            file_count += 1;
        } else {
            space_count += 1;
        }
    }

    return .{
        .max_pos = max_pos,
        .file_count = file_count,
        .space_count = space_count,
    };
}

fn calculatePart1(allocator: std.mem.Allocator, input: []const u8, max_pos: usize) !u64 {
    var positions = try allocator.alloc(u32, max_pos);
    var pos_len: usize = 0;
    var id: u32 = 0;

    // Input bounds already verified
    @setRuntimeSafety(false);
    for (input, 0..) |c, i| {
        if (!isDigit(c)) continue;
        const count = digitToInt(c);
        const fill_value = if (i % 2 == 0) id else std.math.maxInt(u32);

        @memset(positions[pos_len .. pos_len + count], fill_value);
        pos_len += count;

        if (i % 2 == 0) id += 1;
    }

    var left: usize = 0;
    var right: usize = pos_len - 1;
    while (left < right) {
        while (left < right and positions[left] != std.math.maxInt(u32)) left += 1;
        while (left < right and positions[right] == std.math.maxInt(u32)) right -= 1;
        if (left < right) {
            std.mem.swap(u32, &positions[left], &positions[right]);
        }
    }

    var checksum: u64 = 0;
    for (positions[0..pos_len], 0..) |pos, idx| {
        if (pos != std.math.maxInt(u32)) {
            checksum += idx * pos;
        }
    }

    return checksum;
}

fn calculatePart2(allocator: std.mem.Allocator, input: []const u8, counts: Counts) !u64 {
    var files = try allocator.alloc(Interval, counts.file_count);
    var spaces = try allocator.alloc(Interval, counts.space_count);

    var position: u32 = 0;
    var id: u32 = 0;
    var f_idx: usize = 0;
    var s_idx: usize = 0;

    // Input already verified
    @setRuntimeSafety(false);
    for (input, 0..) |c, i| {
        if (!isDigit(c)) continue;
        const size = digitToInt(c);
        if (i % 2 == 0) {
            files[f_idx] = .{ .start = position, .size = size, .id = id };
            f_idx += 1;
            id += 1;
        } else {
            spaces[s_idx] = .{ .start = position, .size = size, .id = 0 };
            s_idx += 1;
        }
        position += size;
    }

    var max_size: u32 = std.math.maxInt(u32);
    var idx = f_idx;
    while (idx > 0) {
        idx -= 1;
        const file = &files[idx];
        if (file.size >= max_size) continue;

        for (spaces[0..s_idx]) |*space| {
            const can_fit = file.start >= space.start and space.size >= file.size;
            if (!can_fit) continue;

            file.start = space.start;
            space.start += file.size;
            space.size -= file.size;
            break;
        } else max_size = file.size;
    }

    var checksum: u64 = 0;
    for (files[0..f_idx]) |file| {
        checksum += file.checksum();
    }

    return checksum;
}

test "day 9" {
    const input = "2333133121414131402";
    const result = try main(input);
    try std.testing.expectEqual(1928, result.part1);
    try std.testing.expectEqual(2858, result.part2);
}
