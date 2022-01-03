const std = @import("std");
const stdin = std.io.getStdIn().reader();
const stdout = std.io.getStdOut().writer();
const interpreter = @import("./interpreter.zig");
const Forth = interpreter.ForthInterpreter;
const ForthError = interpreter.InterpreterError;

pub fn main() anyerror!void {
    try repl();
}

fn repl() !void {
    var vm = Forth(2000).init();
    var buf: [120]u8 = undefined;

    while (true) {
        const code = (try stdin.readUntilDelimiterOrEof(buf[0..], '\n')) orelse {
            // No input, probably CTRL-d (EOF).
            try stdout.print("\n", .{});
            return;
        };
        if (vm.run(code)) {} else |err| switch (err) {
            ForthError.Bye => break,
            else => return err,
        }
    }
}
