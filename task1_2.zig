const ctx = @import("context.zig");

extern "kernel32" fn ExitProcess(code: u32) callconv(.c) noreturn;
extern "kernel32" fn GetStdHandle(nStdHandle: i32) callconv(.c) isize;
extern "kernel32" fn WriteFile(
    hFile: isize,
    lpBuffer: [*]const u8,
    nNumberOfBytesToWrite: u32,
    lpNumberOfBytesWritten: ?*u32,
    lpOverlapped: usize,
) callconv(.c) i32;

const STD_OUTPUT_HANDLE = -11;

fn foo() callconv(.c) noreturn {
    const msg = "You called foo\n";

    const h = GetStdHandle(STD_OUTPUT_HANDLE);
    var written: u32 = 0;

    _ = WriteFile(
        h,
        msg,
        msg.len,
        &written,
        0,
    );

    ExitProcess(0);
}

pub fn main() void {
    var stack: [4096]u8 = undefined;

    var sp: usize = @intFromPtr(&stack) + stack.len;
    sp &= ~@as(usize, 0xF);
    sp -= 32; // Windows shadow space

    var c: ctx.Context = undefined;
    c.rip = @ptrCast(@constCast(&foo));
    c.rsp = @ptrFromInt(sp);

    ctx.set_context(&c);
}
