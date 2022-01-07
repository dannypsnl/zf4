const std = @import("std");
const stdin = std.io.getStdIn().reader();
const stdout = std.io.getStdOut().writer();
const eql = std.mem.eql;
const interpreter = @import("./interpreter.zig");
const Forth = interpreter.ForthInterpreter;
const ForthError = interpreter.InterpreterError;
const Compiler = @import("./compiler.zig").Compiler;

pub fn main() anyerror!void {
    var args = std.process.args();
    defer args.deinit();

    // this one is executable itself
    _ = args.nextPosix();

    const first = args.nextPosix();
    if (first == null) {
        try runStream(stdin);
        try stdout.print("\n", .{});
    } else if (eql(u8, "compile", first.?)) {
        const must_a_file = args.nextPosix().?;
        var file = try std.fs.cwd().openFile(must_a_file, .{});
        defer file.close();

        try compileStream(file.reader());
    } else {
        // seems like a file!
        var file = try std.fs.cwd().openFile(first.?, .{});
        defer file.close();

        try runStream(file.reader());
    }
}

fn compileStream(reader: std.io.Reader(std.fs.File, std.os.ReadError, std.fs.File.read)) !void {
    var asm_f = try std.fs.cwd().createFile(
        "/tmp/forth.s",
        .{ .truncate = true },
    );
    defer asm_f.close();
    var compiler = Compiler.init(asm_f);
    var buf: [1024]u8 = undefined;

    try compiler.prepare();

    while (true) {
        const code = (try reader.readUntilDelimiterOrEof(&buf, '\n')) orelse {
            const w = asm_f.writer();
            try w.print("ret\n", .{});
            return;
        };
        if (compiler.compile(code)) {} else |err| switch (err) {
            else => return err,
        }
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
