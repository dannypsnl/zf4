const std = @import("std");
const stdout = std.io.getStdOut().writer();
const Word = @import("./word.zig").Word;

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
        pub fn run(self: *Self, word: Word) !void {
            switch (word) {
                .plus => {
                    const r = self.pop();
                    const l = self.pop();
                    self.push(l + r);
                },
                .sub => {
                    const r = self.pop();
                    const l = self.pop();
                    self.push(l - r);
                },
                .mul => {
                    const r = self.pop();
                    const l = self.pop();
                    self.push(l * r);
                },
                .div => {
                    const r = self.pop();
                    const l = self.pop();
                    self.push(@divTrunc(l, r));
                },
                .dup => {
                    const v = self.pop();
                    self.push(v);
                    self.push(v);
                },
                .pop => {
                    try stdout.print("{} ", .{self.pop()});
                },
                .print => {
                    try stdout.print("{} ", .{self.top()});
                },
                .bye => {
                    return InterpreterError.Bye;
                },
                .int => |v| {
                    self.push(v);
                },
            }
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
