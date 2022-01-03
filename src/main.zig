const std = @import("std");
const stdin = std.io.getStdIn().reader();
const stdout = std.io.getStdOut().writer();
const eql = std.mem.eql;
const interpreter = @import("./interpreter.zig");
const Forth = interpreter.ForthInterpreter;
const ForthError = interpreter.InterpreterError;

pub fn main() anyerror!void {
    var args = std.process.args();
    defer args.deinit();

    // this one is executable itself
    _ = args.nextPosix();

    const first = args.nextPosix();
    if (first == null) {
        try repl();
    } else if (eql(u8, "compile", first.?)) {
        // compile a file
        std.debug.print("say compile!\n", .{});
    } else {
        // seems like a file!
        std.debug.print("run file isn't implemented yet!\n", .{});
    }
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
