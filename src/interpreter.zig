const std = @import("std");
const stdout = std.io.getStdOut().writer();
const eql = std.mem.eql;

pub const InterpreterError = error{
    Bye,
};

pub fn ForthInterpreter(comptime STACK_SIZE: usize) type {
    return struct {
        const Self = @This();
        stack: [STACK_SIZE]i64 = [_]i64{0} ** STACK_SIZE,
        sp: usize = 0,
        pub fn init() Self {
            return .{};
        }
        pub fn run(self: *Self, code: []const u8) !void {
            var words = std.mem.tokenize(u8, code, " ");
            var wordIt = words.next();
            while (wordIt != null) : (wordIt = words.next()) {
                const word = wordIt.?;
                if (eql(u8, word, "+")) {
                    const r = self.pop();
                    const l = self.pop();
                    self.push(l + r);
                } else if (eql(u8, word, "-")) {
                    const r = self.pop();
                    const l = self.pop();
                    self.push(l - r);
                } else if (eql(u8, word, "*")) {
                    const r = self.pop();
                    const l = self.pop();
                    self.push(l * r);
                } else if (eql(u8, word, "/")) {
                    const r = self.pop();
                    const l = self.pop();
                    self.push(@divTrunc(l, r));
                } else if (eql(u8, word, ".")) {
                    try stdout.print("{} ", .{self.top()});
                    _ = self.pop();
                } else if (eql(u8, word, ".s")) {
                    try stdout.print("{} ", .{self.top()});
                } else if (eql(u8, word, "bye")) {
                    return InterpreterError.Bye;
                } else {
                    const v = try std.fmt.parseInt(i64, word, 10);
                    self.push(v);
                }
            }
            try stdout.print("ok\n", .{});
        }

        fn pop(self: *Self) i64 {
            self.sp -= 1;
            return self.stack[self.sp];
        }
        fn push(self: *Self, v: i64) void {
            self.stack[self.sp] = v;
            self.sp += 1;
        }
        fn top(self: *Self) i64 {
            return self.stack[0];
        }
    };
}

test "arith" {
    var vm = ForthInterpreter(5).init();
    try vm.run(" 1 2 +");
    try std.testing.expect(vm.top() == 3);
    try vm.run("1 - ");
    try std.testing.expect(vm.top() == 2);
    try vm.run(" 3 * ");
    try std.testing.expect(vm.top() == 6);
    try vm.run("2 /");
    try std.testing.expect(vm.top() == 3);
}
