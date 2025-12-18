const std = @import("std");
const Fiber = @import("fiber.zig").Fiber;

fn myFiberTask() noreturn {
    std.debug.print("Hello from fiber!\n", .{});
    std.debug.print("Task 1.3 OK\n", .{});

    std.os.windows.kernel32.ExitProcess(0);
}

pub fn main() !void {
    std.debug.print("=== Task 1.3 ===\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const fiber = try Fiber.init(allocator, myFiberTask);
    defer fiber.deinit();

    std.debug.print("Switching to fiber...\n", .{});
    fiber.switchTo();
}
