const std = @import("std");

pub fn main(input: []const u8) !struct { part1: u64, part2: u64, time: f64 } {
    var timer = try std.time.Timer.start();
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const Position = struct {
        x: isize,
        y: isize,

        fn new(x: isize, y: isize) @This() {
            return .{ .x = x, .y = y };
        }
    };

    const AntennaList = std.BoundedArray(Position, 16);
    var antennas = std.AutoHashMapUnmanaged(u8, AntennaList){};
    defer antennas.deinit(allocator);
    try antennas.ensureTotalCapacity(allocator, 64);

    var width: usize = 0;
    var height: usize = 0;
    var row: usize = 0;

    var line_it = std.mem.tokenizeScalar(u8, input, '\n');
    while (line_it.next()) |line| : (row += 1) {
        if (line.len == 0) break;
        width = line.len;

        for (line, 0..) |cell, col| {
            if (std.ascii.isAlphanumeric(cell)) {
                var gop = try antennas.getOrPut(allocator, cell);
                if (!gop.found_existing) {
                    gop.value_ptr.* = try AntennaList.init(0);
                }
                try gop.value_ptr.append(Position.new(@intCast(col), @intCast(row)));
            }
        }
    }
    height = row;

    var part1 = std.AutoHashMapUnmanaged(Position, void){};
    var part2 = std.AutoHashMapUnmanaged(Position, void){};
    defer part1.deinit(allocator);
    defer part2.deinit(allocator);

    try part1.ensureTotalCapacity(allocator, 1024);
    try part2.ensureTotalCapacity(allocator, 2048);

    const w: isize = @intCast(width);
    const h: isize = @intCast(height);

    var antenna_it = antennas.iterator();
    while (antenna_it.next()) |entry| {
        const positions = entry.value_ptr.slice();
        if (positions.len < 2) continue;

        for (positions[0 .. positions.len - 1], 0..) |pos1, i| {
            const next_positions = positions[i + 1 ..];
            for (next_positions) |pos2| {
                var a = pos1;
                var b = pos2;
                if (a.x > b.x or (a.x == b.x and a.y > b.y)) {
                    const tmp = a;
                    a = b;
                    b = tmp;
                }

                const xdist = b.x - a.x;
                const ydist = b.y - a.y;

                {
                    var m: isize = 0;
                    while (true) : (m += 1) {
                        const px = a.x - xdist * m;
                        const py = a.y - ydist * m;
                        if (px < 0 or px >= w or py < 0 or py >= h) break;

                        const new_pos = Position.new(px, py);
                        try part2.put(allocator, new_pos, {});
                        if (m == 1) try part1.put(allocator, new_pos, {});
                    }
                }

                {
                    var m: isize = 1;
                    while (true) : (m += 1) {
                        const px = b.x + xdist * (m - 1);
                        const py = b.y + ydist * (m - 1);
                        if (px < 0 or px >= w or py < 0 or py >= h) break;

                        const new_pos = Position.new(px, py);
                        try part2.put(allocator, new_pos, {});
                        if (m == 2) try part1.put(allocator, new_pos, {});
                    }
                }
            }
        }
    }

    const time = @as(f64, @floatFromInt(timer.lap())) / std.time.ns_per_us;
    return .{
        .part1 = @intCast(part1.count()),
        .part2 = @intCast(part2.count()),
        .time = time,
    };
}

test "day 8" {
    const test_input =
        \\............
        \\........0...
        \\.....0......
        \\.......0....
        \\....0.......
        \\......A.....
        \\............
        \\............
        \\........A...
        \\.........A..
        \\............
        \\............
    ;
    const result = try main(test_input);
    try std.testing.expectEqual(14, result.part1);
    try std.testing.expectEqual(34, result.part2);
}
