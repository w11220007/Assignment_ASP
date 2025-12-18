const std = @import("std");
const Scheduler = @import("scheduler.zig").Scheduler;

fn simple_task() void {
    std.debug.print("Task 2: Fiber running on custom stack.\n", .{});
    // Không gọi exit_process(0), để nó tự return về Scheduler
}

pub fn main() !void {
    std.debug.print("=== TASK 2: Cooperative Fibers (Spawn & Run) ===\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var sched = Scheduler.init(allocator);
    defer sched.deinit();

    try sched.spawn(simple_task, null);
    try sched.spawn(simple_task, null);

    sched.do_it();
    std.debug.print("Main: All tasks finished.\n", .{});
}
