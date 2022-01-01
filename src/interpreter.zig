const std = @import("std");
const mem = std.mem;

fn ForthInterpreter(comptime STACK_SIZE: usize) type {
    return struct {
        const Self = @This();
        stack: [STACK_SIZE]i64 = [_]i64{0} ** STACK_SIZE,
        sp: usize = 0,
        pub fn init() Self {
            return .{};
        }
        pub fn run(self: *Self, codes: []const []const u8) !void {
            for (codes) |code| {
                if (mem.eql(u8, code, "+")) {
                    const l = self.pop();
                    const r = self.pop();
                    self.push(l + r);
                } else if (mem.eql(u8, code, "-")) {
                    const r = self.pop();
                    const l = self.pop();
                    self.push(l - r);
                } else {
                    const v = try std.fmt.parseInt(i64, code, 10);
                    self.push(v);
                }
            }
        }

        pub fn pop(self: *Self) i64 {
            self.sp -= 1;
            return self.stack[self.sp];
        }
        pub fn push(self: *Self, v: i64) void {
            self.stack[self.sp] = v;
            self.sp += 1;
        }
        pub fn top(self: *Self) i64 {
            return self.stack[0];
        }
    };
}

test "run" {
    var vm = ForthInterpreter(5).init();
    try vm.run(([_][]const u8{ "1", "2", "+" })[0..]);
    try std.testing.expect(vm.top() == 3);
    try vm.run(([_][]const u8{ "1", "-" })[0..]);
    try std.testing.expect(vm.top() == 2);
}
