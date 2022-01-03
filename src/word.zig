const std = @import("std");
const eql = std.mem.eql;

pub const Word = enum {
    plus,
    sub,
    mul,
    div,
    pop,
    print,
    bye,
    not,
    pub fn fromString(word: []const u8) Word {
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
            return .not;
        }
    }
};
