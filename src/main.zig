const std = @import("std");
const interpreter = @import("./interpreter.zig");
const Forth = interpreter.ForthInterpreter;
const ForthError = interpreter.InterpreterError;

pub fn main() anyerror!void {
    var vm = Forth(2000).init();
    while (true) {
        if (vm.run(([_][]const u8{ "1", "2", "+", "bye" })[0..])) {} else |err| switch (err) {
            ForthError.Bye => break,
            else => return err,
        }
    }
}
