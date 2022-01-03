const std = @import("std");
const eql = std.mem.eql;

pub const WordTag = enum {
    plus,
    sub,
    mul,
    div,
    pop,
    print,
    bye,
    int,
};
pub const Word = union(WordTag) {
    plus: void,
    sub: void,
    mul: void,
    div: void,
    pop: void,
    print: void,
    bye: void,
    int: i64,
    pub fn fromString(word: []const u8) !Word {
        if (eql(u8, word, "+")) {
            return .plus;
        } else if (eql(u8, word, "-")) {
            return .sub;
        } else if (eql(u8, word, "*")) {
            return .mul;
        } else if (eql(u8, word, "/")) {
            return .div;
        } else if (eql(u8, word, ".")) {
            return .pop;
        } else if (eql(u8, word, ".s")) {
            return .print;
        } else if (eql(u8, word, "bye")) {
            return .bye;
        } else {
            return Word{ .int = try std.fmt.parseInt(i64, word, 10) };
        }
    }
};
