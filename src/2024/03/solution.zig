const std = @import("std");

const Parser = struct {
    input: []const u8,
    pos: usize = 0,
    is_enabled: bool = true,

    const Result = struct {
        part1: u64,
        part2: u64,
    };

    fn init(input: []const u8) Parser {
        return .{ .input = input };
    }

    fn parse(self: *Parser) Result {
        var sums = Result{ .part1 = 0, .part2 = 0 };

        while (self.pos < self.input.len - 2) : (self.pos += 1) {
            switch (self.input[self.pos]) {
                'd' => {
                    if (self.shouldHandleDirective()) {
                        self.handleDirective();
                    }
                },
                '(' => {
                    if (self.isMultiplication()) {
                        self.pos += 1;
                        if (self.parseExpression()) |product| {
                            sums.part1 +%= product;
                            if (self.is_enabled) sums.part2 +%= product;
                        }
                    }
                },
                else => {},
            }
        }
        return sums;
    }

    fn shouldHandleDirective(self: Parser) bool {
        if (self.pos >= self.input.len - 3) return false;
        return self.input[self.pos + 1] == 'o' and
            (self.input[self.pos + 2] == '(' or
            (self.pos + 6 < self.input.len and
            self.input[self.pos + 2] == 'n' and
            self.input[self.pos + 3] == '\''));
    }

    fn handleDirective(self: *Parser) void {
        self.is_enabled = self.input[self.pos + 2] == '(';
        self.pos = std.mem.indexOfScalarPos(u8, self.input, self.pos, ')') orelse (self.input.len - 1);
    }

    fn isMultiplication(self: Parser) bool {
        return self.pos >= 3 and
            self.input[self.pos - 3] == 'm' and
            self.input[self.pos - 2] == 'u' and
            self.input[self.pos - 1] == 'l';
    }

    fn parseExpression(self: *Parser) ?u64 {
        const first = self.parseNumber() orelse return null;
        if (self.pos >= self.input.len or self.input[self.pos] != ',') return null;
        self.pos += 1;

        const second = self.parseNumber() orelse return null;
        if (self.pos >= self.input.len or self.input[self.pos] != ')') return null;

        return first *% second;
    }

    fn parseNumber(self: *Parser) ?u64 {
        var num: u64 = 0;
        var digits: u8 = 0;

        while (self.pos < self.input.len) : (self.pos += 1) {
            const c = self.input[self.pos];
            if (c >= '0' and c <= '9') {
                num = num * 10 + (c - '0');
                digits += 1;
                if (digits > 3) return null;
            } else break;
        }
        return if (digits > 0) num else null;
    }
};

pub fn main(input: []const u8) !struct { part1: u64, part2: u64, time: f64 } {
    var timer = try std.time.Timer.start();
    var parser = Parser.init(input);
    const result = parser.parse();
    return .{
        .part1 = result.part1,
        .part2 = result.part2,
        .time = @as(f64, @floatFromInt(timer.lap())) / std.time.ns_per_us,
    };
}

test "day 3" {
    const test_input = "xmul(2,4)&mul[3,7]!^don't()_mul(5,5)+mul(32,64](mul(11,8)do()?mul(8,5))";
    const result = try main(test_input);
    try std.testing.expectEqual(@as(u64, 161), result.part1);
    try std.testing.expectEqual(@as(u64, 48), result.part2);
}
