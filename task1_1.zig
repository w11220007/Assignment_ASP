const std = @import("std");
const ctx = @import("context.zig");

pub fn main() void {
    var c: ctx.Context = undefined;

    // get_context trả về int → phải dùng hoặc discard
    _ = ctx.get_context(&c);

    std.debug.print("Task 1.1: get_context OK\n", .{});
    std.debug.print("RIP = {any}\n", .{c.rip});
    std.debug.print("RSP = {any}\n", .{c.rsp});
}
