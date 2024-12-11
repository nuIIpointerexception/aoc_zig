const std = @import("std");
const mem = std.mem;

const MazeParser = struct {
    allocator: mem.Allocator,
    lines: std.ArrayList([]const u8),
    width: usize,
    height: usize,
    start_x: u64,
    start_y: u64,

    const Direction = enum(usize) {
        North = 0,
        East = 1,
        South = 2,
        West = 3,
    };

    const Position = struct {
        x: u64,
        y: u64,
    };

    const DIRECTION_OFFSETS = struct {
        const dx: [4]u64 = @bitCast([4]i64{ -1, 0, 1, 0 });
        const dy: [4]u64 = @bitCast([4]i64{ 0, 1, 0, -1 });
    };

    pub fn init(allocator: mem.Allocator, input: []const u8) !MazeParser {
        var lines = std.ArrayList([]const u8).init(allocator);
        var lines_iter = std.mem.tokenizeSequence(u8, input, "\n");

        while (lines_iter.next()) |line| {
            try lines.append(line);
        }

        var parser = MazeParser{
            .allocator = allocator,
            .lines = lines,
            .width = if (lines.items.len > 0) lines.items[0].len else 0,
            .height = lines.items.len,
            .start_x = 0,
            .start_y = 0,
        };

        try parser.findStartPosition();
        return parser;
    }

    fn findStartPosition(self: *MazeParser) !void {
        for (self.lines.items, 0..) |line, i| {
            for (line, 0..) |c, j| {
                if (c == '^') {
                    self.start_x = @intCast(i);
                    self.start_y = @intCast(j);
                    return;
                }
            }
        }
    }

    fn createGrid(self: *const MazeParser, comptime T: type) ![][]T {
        var grid = try self.allocator.alloc([]T, self.height);
        errdefer self.allocator.free(grid);

        for (0..self.height) |i| {
            grid[i] = try self.allocator.alloc(T, self.width);
            errdefer {
                for (0..i) |j| {
                    self.allocator.free(grid[j]);
                }
                self.allocator.free(grid);
            }

            if (T == bool) {
                @memset(grid[i], false);
            } else {
                @memset(grid[i], 0);
            }
        }
        return grid;
    }

    fn freeGrid(self: *const MazeParser, comptime T: type, grid: [][]T) void {
        for (grid) |row| {
            self.allocator.free(row);
        }
        self.allocator.free(grid);
    }

    fn isValidPosition(self: *const MazeParser, pos: Position) bool {
        return pos.x < self.height and pos.y < self.width;
    }

    fn solveMaze(self: *const MazeParser) !struct { part1: u64, part2: u64 } {
        var visited = try self.createGrid(bool);
        defer self.freeGrid(bool, visited);

        const state_visited = try self.createGrid(u8);
        defer self.freeGrid(u8, state_visited);

        const working_grid = try self.createGrid(u8);
        defer self.freeGrid(u8, working_grid);

        for (self.lines.items, 0..) |line, i| {
            @memcpy(working_grid[i], line);
        }

        var rocked = try self.createGrid(bool);
        defer self.freeGrid(bool, rocked);

        rocked[self.start_x][self.start_y] = true;

        var current_pos = Position{ .x = self.start_x, .y = self.start_y };
        var facing: usize = 0;
        var steps: u64 = 0;
        var loops: u64 = 0;

        while (true) {
            if (!visited[current_pos.x][current_pos.y]) {
                visited[current_pos.x][current_pos.y] = true;
                steps += 1;
            }

            const next_pos = Position{
                .x = current_pos.x +% DIRECTION_OFFSETS.dx[facing],
                .y = current_pos.y +% DIRECTION_OFFSETS.dy[facing],
            };

            if (!self.isValidPosition(next_pos)) break;

            if (working_grid[next_pos.x][next_pos.y] == '#') {
                facing = (facing + 1) % 4;
            } else {
                if (!rocked[next_pos.x][next_pos.y]) {
                    if (try self.checkForLoop(current_pos, facing, working_grid, state_visited)) {
                        loops += 1;
                    }
                    rocked[next_pos.x][next_pos.y] = true;
                }
                current_pos = next_pos;
            }
        }

        return .{ .part1 = steps, .part2 = loops };
    }

    fn checkForLoop(
        self: *const MazeParser,
        start_pos: Position,
        initial_facing: usize,
        working_grid: [][]u8,
        state_visited: [][]u8,
    ) !bool {
        const next_x = start_pos.x +% DIRECTION_OFFSETS.dx[initial_facing];
        const next_y = start_pos.y +% DIRECTION_OFFSETS.dy[initial_facing];
        const original_cell = working_grid[next_x][next_y];
        working_grid[next_x][next_y] = '#';

        var current_pos = start_pos;
        var facing = (initial_facing + 1) % 4;
        var is_loop = false;

        state_visited[current_pos.x][current_pos.y] |= @as(u8, 1) << @intCast(facing);

        while (true) {
            const next_pos = Position{
                .x = current_pos.x +% DIRECTION_OFFSETS.dx[facing],
                .y = current_pos.y +% DIRECTION_OFFSETS.dy[facing],
            };

            if (!self.isValidPosition(next_pos)) break;

            if (working_grid[next_pos.x][next_pos.y] == '#') {
                facing = (facing + 1) % 4;
                if ((state_visited[current_pos.x][current_pos.y] & (@as(u8, 1) << @intCast(facing))) != 0) {
                    is_loop = true;
                    break;
                }
            } else {
                current_pos = next_pos;
                if ((state_visited[current_pos.x][current_pos.y] & (@as(u8, 1) << @intCast(facing))) != 0) {
                    is_loop = true;
                    break;
                }
            }
            state_visited[current_pos.x][current_pos.y] |= @as(u8, 1) << @intCast(facing);
        }

        working_grid[next_x][next_y] = original_cell;
        for (state_visited) |row| {
            @memset(row, 0);
        }

        return is_loop;
    }

    pub fn deinit(self: *MazeParser) void {
        self.lines.deinit();
    }
};

pub fn main(input: []const u8) !struct { part1: u64, part2: u64, time: f64 } {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    var start = try std.time.Timer.start();

    var parser = try MazeParser.init(arena.allocator(), input);
    defer parser.deinit();

    const data = try parser.solveMaze();

    const time = @as(f64, @floatFromInt(start.lap())) / std.time.ns_per_us;

    if (parser.height == 0) return .{ .part1 = 0, .part2 = 0, .time = 0 };
    return .{ .part1 = data.part1, .part2 = data.part2, .time = time };
}

test "day 6" {
    const input =
        \\....#.....
        \\.........#
        \\..........
        \\..#.......
        \\.......#..
        \\..........
        \\.#..^.....
        \\........#.
        \\#.........
        \\......#...
    ;
    const result = try main(input);
    try std.testing.expectEqual(@as(u64, 41), result.part1);
    try std.testing.expectEqual(@as(u64, 6), result.part2);
}
