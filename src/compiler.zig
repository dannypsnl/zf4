const std = @import("std");
const eql = std.mem.eql;
const Word = @import("./word.zig").Word;

pub const Compiler = struct {
    const Self = @This();
    asm_file: std.fs.File,
    pub fn init(a: std.fs.File) Self {
        return .{
            .asm_file = a,
        };
    }
    pub fn prepare(self: *Self) !void {
        const w = self.asm_file.writer();
        try w.print(aarch64_program, .{});
    }
    pub fn compile(self: *Self, code: []const u8) !void {
        const w = self.asm_file.writer();

        const wordsize = 8;
        var current_offset: isize = 0;

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
                        \\str lr, [sp, 8]
                        \\bl printNumberEntry
                        \\ldr lr, [sp, 8]
                        \\
                    , .{current_offset});
                },
                .print => {
                    try w.print(
                        \\ldr x0, [sp, {}]
                        \\str lr, [sp, 8]
                        \\bl printNumberEntry
                        \\ldr lr, [sp, 8]
                        \\
                    , .{current_offset + wordsize});
                },
                .bye => try w.print("ret\n", .{}),
                .int => |v| {
                    try w.print(
                        \\mov x0, #{}
                        \\str x0, [sp, {}]
                        \\
                    , .{ v, current_offset });
                    current_offset -= wordsize;
                },
            }
        }
    }
};

const aarch64_program =
    \\.text
    \\.p2align 2
    \\
    \\.global printNumberEntry
    \\printNumberEntry:
    \\    mov x15, #10
    \\    mov x12, x0
    // print prepare
    // fd(x0) = 1(stdout)
    \\    mov x0, #1
    // len(x2) = 1
    \\    mov x2, #1
    // Unix write system call
    \\    mov x16, #4
    // x17 for store shift
    \\    mov x17, #0
    \\save_loop:
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
    \\    strb w13, [sp, x17]
    \\    sub x17, x17, #4
    // loop part
    \\    cmp x12, #0
    \\    b.eq print_loop
    \\    b save_loop
    \\print_loop:
    \\    add x17, x17, #4
    \\    add x1, sp, x17
    \\    svc #0
    \\    cmp x17, #0
    \\    b.eq exit
    \\    b print_loop
    \\exit:
    \\    mov x13, #10
    \\    strb w13, [sp]
    \\    mov x1, sp
    \\    svc #0
    \\    ret
    \\
    \\.global _start
    \\_start:
    \\entry:
    \\
;
