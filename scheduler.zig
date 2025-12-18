const std = @import("std");
const builtin = @import("builtin");
const ctx = @import("context.zig");

/// Cross-platform process exit helper
pub fn exit_process(code: u8) noreturn {
    if (builtin.os.tag == .windows) {
        std.os.windows.kernel32.ExitProcess(code);
    } else {
        std.process.exit(code);
    }
}

pub const Fiber = struct {
    context: ctx.Context,
    // Stack aligned to 16 bytes for ABI compliance
    stack: []align(16) u8,
    id: usize,
    data: ?*anyopaque,

    // INTRUSIVE LINKED LIST POINTERS
    next: ?*Fiber = null,
    prev: ?*Fiber = null,

    pub fn deinit(self: *Fiber, allocator: std.mem.Allocator) void {
        allocator.free(self.stack);
    }
};

pub const Scheduler = struct {
    // Queue Head/Tail pointers
    head: ?*Fiber,
    tail: ?*Fiber,
    count: usize,

    main_context: ctx.Context,
    allocator: std.mem.Allocator,

    current_fiber: ?*Fiber,
    finished_fiber: ?*Fiber,

    pub fn init(allocator: std.mem.Allocator) Scheduler {
        return Scheduler{
            .head = null,
            .tail = null,
            .count = 0,
            .main_context = undefined,
            .allocator = allocator,
            .current_fiber = null,
            .finished_fiber = null,
        };
    }

    pub fn deinit(self: *Scheduler) void {
        while (self.dequeue()) |f| {
            f.deinit(self.allocator);
            self.allocator.destroy(f);
        }
    }

    // --- O(1) Queue Operations (Marked pub for Testing) ---
    pub fn enqueue(self: *Scheduler, fiber: *Fiber) void {
        fiber.next = null;
        fiber.prev = self.tail;
        if (self.tail) |tail| {
            tail.next = fiber;
        } else {
            self.head = fiber;
        }
        self.tail = fiber;
        self.count += 1;
    }

    pub fn dequeue(self: *Scheduler) ?*Fiber {
        const first = self.head orelse return null;
        self.head = first.next;
        if (self.head) |new_head| {
            new_head.prev = null;
        } else {
            self.tail = null;
        }
        first.next = null;
        first.prev = null;
        self.count -= 1;
        return first;
    }
    // ------------------------------------------------------

    pub fn spawn(self: *Scheduler, function: *const fn () void, data: ?*anyopaque) !void {
        const fiber = try self.allocator.create(Fiber);

        const alignment = comptime std.mem.Alignment.fromByteUnits(16);
        fiber.stack = try self.allocator.alignedAlloc(u8, alignment, 16384);

        fiber.id = self.count + 1;
        fiber.data = data;

        fiber.next = null;
        fiber.prev = null;

        var sp = @intFromPtr(fiber.stack.ptr) + fiber.stack.len;
        sp = (sp & @as(usize, @bitCast(@as(isize, -16)))) - 128;
        sp -= 8;

        _ = ctx.get_context(&fiber.context);
        fiber.context.rip = @ptrFromInt(@intFromPtr(&entry_point));
        fiber.context.rsp = @ptrFromInt(sp);

        fiber.context.r12 = @ptrFromInt(@intFromPtr(function));
        fiber.context.r13 = @ptrFromInt(@intFromPtr(self));

        self.enqueue(fiber);
    }

    fn entry_point() callconv(.c) void {
        var c: ctx.Context = undefined;
        
        _ = ctx.get_context(&c);

        const func: *const fn () void = @ptrCast(@alignCast(c.r12));
        const sched: *Scheduler = @ptrCast(@alignCast(c.r13));

        func();
        sched.fiber_exit();
    }

    pub fn do_it(self: *Scheduler) void {
        _ = ctx.get_context(&self.main_context);

        if (self.finished_fiber) |f| {
            f.deinit(self.allocator);
            self.allocator.destroy(f);
            self.finished_fiber = null;
        }

        if (self.dequeue()) |next_fiber| {
            self.current_fiber = next_fiber;
            ctx.set_context(&next_fiber.context);
        }
    }

    pub fn fiber_exit(self: *Scheduler) void {
        self.finished_fiber = self.current_fiber;
        self.current_fiber = null;
        ctx.set_context(&self.main_context);
    }

    pub fn yield(self: *Scheduler) void {
        if (self.count == 0) return;

        const current = self.current_fiber orelse return;
        const next = self.dequeue() orelse return;

        self.enqueue(current);
        self.current_fiber = next;

        ctx.swap_context(&current.context, &next.context);
    }

    pub fn get_data(self: *Scheduler) ?*anyopaque {
        if (self.current_fiber) |f| {
            return f.data;
        }
        return null;
    }
};