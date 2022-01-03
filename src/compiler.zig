const std = @import("std");
const eql = std.mem.eql;

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
        // x13 = x12 / 10
        \\    udiv x13, x12, x15
        // x13 = x13 * 10 - x12
        \\    msub x13, x13, x15, x12
        // x12 = x12 - x13
        \\    sub x12, x12, x13
        // x12 = x12 / 10
        \\    udiv x12, x12, x15
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
            try w.print(
                \\ret
                \\
            , .{});
            return;
        };
        var words = std.mem.tokenize(u8, code, " ");
        var wordIt = words.next();
        while (wordIt != null) : (wordIt = words.next()) {
            const word = wordIt.?;
            if (eql(u8, word, "+")) {
                current_offset += 2 * wordsize;
                try w.print(
                    \\ldp x0, x1, [sp, {}]
                    \\add x0, x0, x1
                    \\str x0, [sp, {}]
                    \\
                , .{ current_offset - wordsize, current_offset });
            } else if (eql(u8, word, "-")) {
                current_offset += 2 * wordsize;
                try w.print(
                    \\ldp x0, x1, [sp, {}]
                    \\sub x0, x0, x1
                    \\str x0, [sp, {}]
                    \\
                , .{ current_offset - wordsize, current_offset });
            } else if (eql(u8, word, "*")) {
                current_offset += 2 * wordsize;
                try w.print(
                    \\ldp x0, x1, [sp, {}]
                    \\mul x0, x0, x1
                    \\str x0, [sp, {}]
                    \\
                , .{ current_offset - wordsize, current_offset });
            } else if (eql(u8, word, "/")) {
                current_offset += 2 * wordsize;
                try w.print(
                    \\ldp x0, x1, [sp, {}]
                    \\sdiv x0, x0, x1
                    \\str x0, [sp, {}]
                    \\
                , .{ current_offset - wordsize, current_offset });
            } else if (eql(u8, word, ".")) {
                try w.print(
                    \\ldr x0, [sp, {}]
                    \\stp x29, x30, [sp, 8]
                    \\bl printNumberEntry
                    \\bl newline
                    \\ldp x29, x30, [sp, 8]
                    \\
                , .{current_offset});
                current_offset += wordsize;
            } else {
                const v = try std.fmt.parseInt(i64, word, 10);
                try w.print(
                    \\mov x0, {}
                    \\str x0, [sp, {}]
                    \\
                , .{ v, current_offset });
                current_offset -= wordsize;
            }
        }
    }
}
