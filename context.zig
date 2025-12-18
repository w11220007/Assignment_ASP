const std = @import("std");

pub const Context = extern struct {
    rip: ?*anyopaque,
    rsp: ?*anyopaque,
    rbx: ?*anyopaque,
    rbp: ?*anyopaque,
    r12: ?*anyopaque,
    r13: ?*anyopaque,
    r14: ?*anyopaque,
    r15: ?*anyopaque,
    rdi: ?*anyopaque,
    rsi: ?*anyopaque,
};

pub extern fn get_context(c: *Context) c_int;
pub extern fn set_context(c: *Context) noreturn;
pub extern fn swap_context(out: *Context, in: *Context) void;
