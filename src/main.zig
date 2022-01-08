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
        try runStream(stdin);
        try stdout.print("\n", .{});
    } else {
        // seems like a file!
        var file = try std.fs.cwd().openFile(first.?, .{});
        defer file.close();

        try runStream(file.reader());
    }
}

fn runStream(reader: std.io.Reader(std.fs.File, std.os.ReadError, std.fs.File.read)) !void {
    var vm = Forth(2000).init();
    var buf: [1024]u8 = undefined;

    while (true) {
        const code = (try reader.readUntilDelimiterOrEof(&buf, '\n')) orelse {
            // No input, probably CTRL-d/EOF.
            return;
        };
        if (vm.run(code)) {} else |err| switch (err) {
            ForthError.Bye => break,
            else => return err,
        }
    }
}
