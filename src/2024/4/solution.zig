const std = @import("std");

const GridPattern = struct {
    data: []const u8,
    width: isize,
    stride: isize,
    size: usize,

    const Direction = struct { dx: isize, dy: isize };
    const directions = [_]Direction{
        .{ .dx = 1, .dy = -1 },
        .{ .dx = 1, .dy = 0 },
        .{ .dx = 1, .dy = 1 },
        .{ .dx = 0, .dy = 1 },
        .{ .dx = -1, .dy = 1 },
        .{ .dx = -1, .dy = 0 },
        .{ .dx = -1, .dy = -1 },
        .{ .dx = 0, .dy = -1 },
    };

    fn init(input: []const u8) GridPattern {
        const width = @as(isize, @intCast(std.mem.indexOfScalar(u8, input, '\n') orelse input.len));
        return .{
            .data = input,
            .width = width,
            .stride = width + 1,
            .size = input.len,
        };
    }

    fn countXMAS(self: GridPattern) u64 {
        var count: u64 = 0;
        var row: isize = 0;
        while (row < self.width) : (row += 1) {
            var col: isize = 0;
            while (col < self.width) : (col += 1) {
                const pos = @as(usize, @intCast(col + row * self.stride));
                if (pos >= self.size or self.data[pos] != 'X') continue;

                for (directions) |dir| {
                    const next_pos = col + dir.dx + (row + dir.dy) * self.stride;
                    const next2_pos = col + dir.dx * 2 + (row + dir.dy * 2) * self.stride;
                    const next3_pos = col + dir.dx * 3 + (row + dir.dy * 3) * self.stride;

                    if (next_pos < 0 or next2_pos < 0 or next3_pos < 0) continue;

                    const p1 = @as(usize, @intCast(next_pos));
                    const p2 = @as(usize, @intCast(next2_pos));
                    const p3 = @as(usize, @intCast(next3_pos));

                    if (p1 < self.size and p2 < self.size and p3 < self.size and
                        self.data[p1] == 'M' and self.data[p2] == 'A' and self.data[p3] == 'S')
                    {
                        count += 1;
                    }
                }
            }
        }
        return count;
    }

    fn countDiagonalMatches(self: GridPattern) u64 {
        var count: u64 = 0;
        var row: isize = 0;
        while (row < self.width) : (row += 1) {
            var col: isize = 0;
            while (col < self.width) : (col += 1) {
                const pos = @as(usize, @intCast(col + row * self.stride));
                if (pos >= self.size or self.data[pos] != 'A') continue;

                const up_left = pos -% @as(usize, @intCast(self.stride + 1));
                const up_right = pos -% @as(usize, @intCast(self.stride - 1));
                const down_left = pos +% @as(usize, @intCast(self.stride - 1));
                const down_right = pos +% @as(usize, @intCast(self.stride + 1));

                if (up_left >= self.size or up_right >= self.size or
                    down_left >= self.size or down_right >= self.size) continue;

                const m1 = (self.data[up_left] == 'M' or self.data[down_right] == 'M');
                const m2 = (self.data[up_right] == 'M' or self.data[down_left] == 'M');
                const s1 = (self.data[up_left] == 'S' or self.data[down_right] == 'S');
                const s2 = (self.data[up_right] == 'S' or self.data[down_left] == 'S');

                if (m1 and m2 and s1 and s2) count += 1;
            }
        }
        return count;
    }
};

pub fn main(input: []const u8) !struct { part1: u64, part2: u64, time: f64 } {
    var start = try std.time.Timer.start();
    const pattern = GridPattern.init(input);
    return .{
        .part1 = pattern.countXMAS(),
        .part2 = pattern.countDiagonalMatches(),
        .time = @as(f64, @floatFromInt(start.lap())) / std.time.ns_per_us,
    };
}

test "day 4" {
    const input =
        \\MMMSXXMASM
        \\MSAMXMSMSA
        \\AMXSXMAAMM
        \\MSAMASMSMX
        \\XMASAMXAMM
        \\XXAMMXXAMA
        \\SMSMSASXSS
        \\SAXAMASAAA
        \\MAMMMXMMMM
        \\MXMXAXMASX
    ;
    const result = try main(input);
    try std.testing.expectEqual(18, result.part1);
    try std.testing.expectEqual(9, result.part2);
}
