const std = @import("std");
const ctx = @import("context.zig");

pub const Fiber = struct {
    context: ctx.Context,
    stack: []align(16) u8,
    allocator: std.mem.Allocator,

    pub fn init(
        allocator: std.mem.Allocator,
        entry: *const fn () noreturn,
    ) !*Fiber {
        const self = try allocator.create(Fiber);
        self.allocator = allocator;

        const alignment = comptime std.mem.Alignment.fromByteUnits(16);
        self.stack = try allocator.alignedAlloc(u8, alignment, 4096);

        var sp = @intFromPtr(self.stack.ptr) + self.stack.len;

        // Windows x64 ABI
        sp &= ~@as(usize, 15); // align 16
        sp -= 8;              // fake return address

        _ = ctx.get_context(&self.context);
        self.context.rip = @ptrCast(@constCast(entry));
        self.context.rsp = @ptrFromInt(sp);

        return self;
    }

    pub fn deinit(self: *Fiber) void {
        self.allocator.free(self.stack);
        self.allocator.destroy(self);
    }

    pub fn switchTo(self: *Fiber) noreturn {
        ctx.set_context(&self.context);
    }
};
