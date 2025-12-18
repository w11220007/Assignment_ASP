const std = @import("std");
const Scheduler = @import("scheduler.zig").Scheduler;

const TaskContext = struct {
    sched: *Scheduler,
    counter: *i32,
    id: i32,
};

var global_sched: ?*Scheduler = null;
var global_ctx: TaskContext = undefined;

fn demo_worker() void {
    std.debug.print("   [Worker] Working...\n", .{});

    if (global_sched) |s| {
        std.debug.print("   [Worker] Yielding...\n", .{});
        s.yield();
    }

    global_ctx.counter.* += 5;
    std.debug.print(
        "   [Worker] Resumed! Counter: {}\n",
        .{global_ctx.counter.*},
    );
}

fn task_yield() void {
    demo_worker();
}

pub fn main() !void {
    std.debug.print(
        "=== TASK 3: Yield & Shared Data (Target: 110) ===\n",
        .{},
    );

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var sched = Scheduler.init(allocator);
    defer sched.deinit();

    global_sched = &sched;

    var counter: i32 = 100;
    global_ctx = TaskContext{
        .sched = &sched,
        .counter = &counter,
        .id = 1,
    };

    try sched.spawn(task_yield, &global_ctx);
    try sched.spawn(task_yield, &global_ctx);

    std.debug.print("Main: Starting Round-Robin...\n", .{});
    sched.do_it();

    std.debug.print(
        "Main: Done. Final Counter: {} (Expected 110)\n",
        .{counter},
    );
}
