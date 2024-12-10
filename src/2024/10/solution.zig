const std = @import("std");

const MAPSIZE = 100;
const DIRECTIONS = [_][2]i8{ .{ 0, -1 }, .{ 0, 1 }, .{ -1, 0 }, .{ 1, 0 } };

const Grid = struct {
    data: [MAPSIZE][MAPSIZE]u8,
    rows: i8,
    cols: i8,
};

pub fn main(input: []const u8) !struct { part1: u32, part2: u32, time: f64 } {
    var timer = try std.time.Timer.start();
    var grid: Grid = undefined;
    var start_positions: [MAPSIZE * MAPSIZE][2]i8 = undefined;
    var start_count: u8 = 0;
    var current_row: usize = 0;

    var lines = std.mem.splitScalar(u8, input, '\n');
    while (lines.next()) |line| {
        const trimmed = std.mem.trim(u8, line, &std.ascii.whitespace);
        if (trimmed.len == 0) continue;
        @memcpy(grid.data[current_row][0..trimmed.len], trimmed);
        grid.cols = @intCast(trimmed.len);
        for (trimmed, 0..) |cell, col| {
            if (cell == '0') {
                start_positions[start_count] = .{ @intCast(current_row), @intCast(col) };
                start_count += 1;
            }
        }
        current_row += 1;
    }
    grid.rows = @intCast(current_row);

    var visited_positions = [_]u128{0} ** MAPSIZE;
    var unique_endpoints: u32 = 0;
    var total_endpoints: u32 = 0;
    var path_stack = [_][3]i8{[_]i8{0} ** 3} ** (MAPSIZE * 4);

    @setRuntimeSafety(false);
    for (start_positions[0..start_count]) |start| {
        @memset(&visited_positions, 0);
        var stack_size: u8 = 1;
        path_stack[0] = .{ start[0], start[1], '1' };

        while (stack_size > 0) {
            stack_size -= 1;
            const current = path_stack[stack_size];
            const x = current[0];
            const y = current[1];
            const target_number = current[2];

            for (DIRECTIONS) |dir| {
                const next_x = x + dir[0];
                const next_y = y + dir[1];
                if (next_x < 0 or next_y < 0 or next_x >= grid.rows or next_y >= grid.cols) continue;

                const grid_x: usize = @intCast(next_x);
                const grid_y: usize = @intCast(next_y);
                if (grid.data[grid_x][grid_y] != target_number) continue;

                if (target_number == '9') {
                    total_endpoints += 1;
                    const position_mask = @as(u128, 1) << @as(u7, @intCast(grid_y));
                    if ((visited_positions[grid_x] & position_mask) == 0) {
                        visited_positions[grid_x] |= position_mask;
                        unique_endpoints += 1;
                    }
                    continue;
                }

                path_stack[stack_size] = .{ next_x, next_y, target_number + 1 };
                stack_size += 1;
            }
        }
    }

    const elapsed_time = @as(f64, @floatFromInt(timer.lap())) / std.time.ns_per_us;
    return .{ .part1 = unique_endpoints, .part2 = total_endpoints, .time = elapsed_time };
}

test "day 10" {
    const input =
        \\89010123
        \\78121874
        \\87430965
        \\96549874
        \\45678903
        \\32019012
        \\01329801
        \\10456732
    ;
    const result = try main(input);
    try std.testing.expectEqual(36, result.part1);
    try std.testing.expectEqual(81, result.part2);
}
