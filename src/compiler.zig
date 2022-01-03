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
        \\.global _main
        \\
        \\printNumberEntry:
        \\    sub  sp, sp, #16
        \\printNumber:
        \\    mov  x16, #10
        \\    udiv x14, x12, x16
        \\    msub x13, x14, x16, x12
        \\    sub  x12, x12, x13
        \\    udiv x12, x12, x16
        \\    add  x13, x13, #48
        \\    strb w13, [sp]
        \\    mov  x0,  #1
        \\    mov  x1,  sp
        \\    mov  x2,  #1
        \\    mov  w8,  #64
        \\    svc  #0
        \\    cmp  x12, #0
        \\    beq  exit
        \\    b    printNumber
        \\exit:
        \\    add  sp, sp, #16
        \\    ret
        \\
        \\_main:
        \\
    , .{});
    while (true) {
        const code = (try file.reader().readUntilDelimiterOrEof(&buf, '\n')) orelse {
            // No input, probably CTRL-d/EOF.
            return;
        };
        var words = std.mem.tokenize(u8, code, " ");
        var wordIt = words.next();
        while (wordIt != null) : (wordIt = words.next()) {
            const word = wordIt.?;
            if (eql(u8, word, "+")) {
                try w.print(
                    \\ldp x0, x1, [sp, {}]
                    \\add x0, x0, x1
                    \\str x0, [sp, {}]
                    \\
                , .{ current_offset, current_offset + 2 * wordsize });
                current_offset += wordsize;
            } else if (eql(u8, word, "-")) {
                try w.print(
                    \\ldp x0, x1, [sp, {}]
                    \\sub x0, x0, x1
                    \\str x0, [sp, {}]
                    \\
                , .{ current_offset, current_offset + 2 * wordsize });
                current_offset += wordsize;
            } else if (eql(u8, word, "*")) {
                try w.print(
                    \\ldp x0, x1, [sp, {}]
                    \\mul x0, x0, x1
                    \\str x0, [sp, {}]
                    \\
                , .{ current_offset, current_offset + 2 * wordsize });
                current_offset += wordsize;
            } else if (eql(u8, word, "/")) {
                try w.print(
                    \\ldp x0, x1, [sp, {}]
                    \\sdiv x0, x0, x1
                    \\str x0, [sp, {}]
                    \\
                , .{ current_offset, current_offset + 2 * wordsize });
                current_offset += wordsize;
            } else if (eql(u8, word, ".")) {
                current_offset -= wordsize;
                try w.print(
                    \\ldr x0, [sp, {}]
                    \\stp x29, x30, [sp, 8]
                    \\bl printNumberEntry
                    \\ldp x29, x30, [sp, 8]
                    \\
                , .{current_offset});
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
