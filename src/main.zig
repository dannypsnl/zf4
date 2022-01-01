const std = @import("std");
const stdin = std.io.getStdIn().reader();
const interpreter = @import("./interpreter.zig");
const Forth = interpreter.ForthInterpreter;
const ForthError = interpreter.InterpreterError;

pub fn main() anyerror!void {
    var vm = Forth(2000).init();
    var buf: [120]u8 = undefined;

    while (true) {
        const code = try stdin.readUntilDelimiterOrEof(buf[0..], '\n');
        if (vm.run(code.?)) {} else |err| switch (err) {
            ForthError.Bye => break,
            else => return err,
        }
    }
}
