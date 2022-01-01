const std = @import("std");

pub fn main() anyerror!void {}

const STACK_SIZE: usize = 20000;
var stack = [_]i64{0} ** STACK_SIZE;

var sp: usize = 0;
fn run(codes: []const []const u8) std.fmt.ParseIntError!void {
    for (codes) |code| {
        if (std.mem.eql(u8, code, "+")) {
            const l = pop();
            const r = pop();
            push(l + r);
        } else {
            const v = try std.fmt.parseInt(i64, code, 10);
            push(v);
        }
    }
}

fn pop() i64 {
    sp -= 1;
    return stack[sp];
}
fn push(v: i64) void {
    stack[sp] = v;
    sp += 1;
}
fn top() i64 {
    return stack[0];
}

test "run" {
    const code = [_][]const u8{ "1", "2", "+" };
    try run(code[0..]);
    try std.testing.expect(top() == 3);
}
