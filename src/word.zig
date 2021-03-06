const std = @import("std");
const eql = std.mem.eql;

pub const WordTag = enum {
    plus,
    sub,
    mul,
    div,
    dup,
    pop,
    print,
    bye,
    int,
    word,
};
pub const Word = union(WordTag) {
    plus: void,
    sub: void,
    mul: void,
    div: void,
    dup: void,
    pop: void,
    print: void,
    bye: void,
    int: i64,
    word: []const u8,
    pub fn fromString(word: []const u8) !Word {
        if (eql(u8, word, "+")) {
            return .plus;
        } else if (eql(u8, word, "-")) {
            return .sub;
        } else if (eql(u8, word, "*")) {
            return .mul;
        } else if (eql(u8, word, "/")) {
            return .div;
        } else if (eql(u8, word, "dup")) {
            return .dup;
        } else if (eql(u8, word, ".")) {
            return .pop;
        } else if (eql(u8, word, ".s")) {
            return .print;
        } else if (eql(u8, word, "bye")) {
            return .bye;
        } else {
            if (std.fmt.parseInt(i64, word, 10)) |i| {
                return Word{ .int = i };
            } else |_| {
                return Word{ .word = word };
            }
        }
    }
};
