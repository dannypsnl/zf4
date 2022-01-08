const std = @import("std");
const stdin = std.io.getStdIn().reader();
const stdout = std.io.getStdOut().writer();
const eql = std.mem.eql;
const interpreter = @import("./interpreter.zig");
const Forth = interpreter.ForthInterpreter;
const ForthError = interpreter.InterpreterError;
const Word = @import("./word.zig").Word;

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
    var g = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = g.deinit();
    var vm = Forth(2000).init(g.allocator());
    defer vm.deinit();
    var buf: [1024]u8 = undefined;
    var in_comment: bool = false;
    var in_define: bool = false;
    var seq = std.ArrayList(Word).init(g.allocator());
    var newWord: []const u8 = undefined;

    while (true) {
        const code = (try reader.readUntilDelimiterOrEof(&buf, '\n')) orelse {
            // No input, probably CTRL-d/EOF.
            return;
        };
        var words = std.mem.tokenize(u8, code, " ");
        var wordIt = words.next();
        while (wordIt != null) : (wordIt = words.next()) {
            if (eql(u8, wordIt.?, "(")) {
                in_comment = true;
            } else if (eql(u8, wordIt.?, ")")) {
                in_comment = false;
                continue;
            } else if (eql(u8, wordIt.?, ":")) {
                in_define = true;
                seq = std.ArrayList(Word).init(g.allocator());
                newWord = words.next().?;
                continue;
            } else if (eql(u8, wordIt.?, ";")) {
                in_define = false;
                try vm.record(newWord, seq.toOwnedSlice());
                continue;
            }
            if (in_comment) {
                continue;
            }
            if (in_define) {
                try seq.append(try Word.fromString(wordIt.?));
                continue;
            }
            const word = try Word.fromString(wordIt.?);
            if (vm.run(word)) {} else |err| switch (err) {
                ForthError.Bye => break,
                else => return err,
            }
        }
        try stdout.print("ok\n", .{});
    }
}
