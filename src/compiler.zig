const std = @import("std");
const eql = std.mem.eql;
const Word = @import("./word.zig").Word;

pub fn compile(file: std.fs.File) !void {
    var asm_f = try std.fs.cwd().createFile(
        "/tmp/forth.s",
        .{ .truncate = true },
    );
    defer asm_f.close();
    const w = asm_f.writer();

    var buf: [1024]u8 = undefined;

    const wordsize = 8;
    var current_offset: isize = 0;

    try w.print(
        \\.text
        \\.p2align 2
        \\
        \\.global printNumberEntry
        \\printNumberEntry:
        // asked two words on stack
        \\    sub sp, sp, #16
        \\    mov x15, #10
        \\    mov x12, x0
        \\printNumber:
        // number = x12
        // x14 = x12 / 10
        // now x14 is rounded-down quotient of x12
        \\    udiv x14, x12, x15
        // x13 = x14 * 10 - x12
        \\    msub x13, x14, x15, x12
        // store rounded-down quotient to x12 for next loop
        \\    mov x12, x14
        // digit to string
        \\    add x13, x13, #48
        \\    strb w13, [sp]
        // print part
        // fd(x0) = 1(stdout)
        \\    mov x0, #1
        // buf(x1) = sp
        \\    mov x1, sp
        // len(x2) = 1
        \\    mov x2, #1
        // Unix write system call
        \\    mov x16, #4
        \\    svc #0
        // loop part
        \\    cmp x12, #0
        \\    b.eq exit
        \\    b printNumber
        \\exit:
        // put used stack back
        \\    add sp, sp, #16
        \\    ret
        \\
        \\.global newline
        \\newline:
        \\    sub sp, sp, #16
        \\    mov x0, #10
        \\    strb w0, [sp]
        \\    mov x0, #1
        \\    mov x1, sp
        \\    mov x2, #1
        \\    mov x16, #4
        \\    svc #0
        \\    add sp, sp, #16
        \\    ret
        \\
        \\.global _start
        \\_start:
        \\entry:
        \\
    , .{});

    while (true) {
        const code = (try file.reader().readUntilDelimiterOrEof(&buf, '\n')) orelse {
            // No input, probably CTRL-d/EOF.
            try w.print("ret\n", .{});
            return;
        };
        var words = std.mem.tokenize(u8, code, " ");
        var wordIt = words.next();
        while (wordIt != null) : (wordIt = words.next()) {
            const word = try Word.fromString(wordIt.?);
            switch (word) {
                .plus => {
                    current_offset += wordsize;
                    try w.print(
                        \\ldp x0, x1, [sp, {}]
                        \\add x0, x1, x0
                        \\str x0, [sp, {}]
                        \\
                    , .{ current_offset, current_offset + wordsize });
                },
                .sub => {
                    current_offset += wordsize;
                    try w.print(
                        \\ldp x0, x1, [sp, {}]
                        \\sub x0, x1, x0
                        \\str x0, [sp, {}]
                        \\
                    , .{ current_offset, current_offset + wordsize });
                },
                .mul => {
                    current_offset += wordsize;
                    try w.print(
                        \\ldp x0, x1, [sp, {}]
                        \\mul x0, x1, x0
                        \\str x0, [sp, {}]
                        \\
                    , .{ current_offset, current_offset + wordsize });
                },
                .div => {
                    current_offset += wordsize;
                    try w.print(
                        \\ldp x0, x1, [sp, {}]
                        \\sdiv x0, x1, x0
                        \\str x0, [sp, {}]
                        \\
                    , .{ current_offset, current_offset + wordsize });
                },
                .pop => {
                    current_offset += wordsize;
                    try w.print(
                        \\ldr x0, [sp, {}]
                        \\stp x29, x30, [sp, 8]
                        \\bl printNumberEntry
                        \\bl newline
                        \\ldp x29, x30, [sp, 8]
                        \\
                    , .{current_offset});
                },
                .print => {
                    try w.print(
                        \\ldr x0, [sp, {}]
                        \\stp x29, x30, [sp, 8]
                        \\bl printNumberEntry
                        \\bl newline
                        \\ldp x29, x30, [sp, 8]
                        \\
                    , .{current_offset + wordsize});
                },
                .bye => try w.print("ret\n", .{}),
                .int => |v| {
                    try w.print(
                        \\mov x0, {}
                        \\str x0, [sp, {}]
                        \\
                    , .{ v, current_offset });
                    current_offset -= wordsize;
                },
            }
        }
    }
}
