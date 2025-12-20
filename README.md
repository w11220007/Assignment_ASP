# Zig Fiber & Context Switching Library  
*(Windows x64 – Native Port)*

---

## Module Information

- **Module:** Advanced Systems Programming  
- **Student Name:** Le Thi Cham Anh   
- **Target Platform:** Windows 10 / 11 (x64, native execution)  
- **Programming Language:** Zig (0.16.0 )  
- **Assembler:** x86-64 (Microsoft x64 ABI)  
- **Submission:** Assessment B  

---

## 1. Project Overview

This project implements a **low-level cooperative fiber (coroutine) system** in Zig, built directly on top of **manual CPU context switching and synthetic stack management**.

Unlike high-level concurrency abstractions such as:

- OS threads  
- Zig `async/await`  
- Runtime-managed coroutines  

this implementation operates **below the language runtime**, explicitly managing:

- Stack memory  
- Instruction pointer (`RIP`)  
- Stack pointer (`RSP`)  
- Callee-saved registers  
- ABI-specific calling conventions  

The project demonstrates how execution can be transferred between independent stacks **without kernel involvement**, forming the foundation of a cooperative scheduler.

---

## 2. Motivation & Learning Objectives

The primary objectives of this project are to:

1. Understand **function calls and stack discipline at the ABI level**
2. Learn how CPU execution context is represented and preserved
3. Implement context switching without OS threads
4. Integrate **assembly code with Zig safely**
5. Port low-level systems code from Linux to **Windows x64**

The project intentionally avoids high-level abstractions to expose the mechanics hidden by modern runtimes.

---

## 3. Platform Migration: Linux → Windows x64

The original coursework environment targets a Linux-based cloud system. Due to instability and limited debugging support, the implementation was **ported to run natively on Windows x64**.

This migration required significant changes because Linux and Windows use **different Application Binary Interfaces (ABI)**.

### 3.1 ABI Differences

| Aspect | Linux (System V ABI) | Windows (Microsoft x64 ABI) |
|------|---------------------|-----------------------------|
| First argument register | `RDI` | `RCX` |
| Callee-saved registers | `RBX`, `RBP`, `R12–R15` | `RBX`, `RBP`, `RDI`, `RSI`, `R12–R15` |
| Stack alignment | 16-byte (soft) | **Strict 16-byte enforced** |
| Shadow space | Not required | **32 bytes mandatory** |

Reusing Linux-based context-switching code resulted in crashes due to incorrect register preservation and stack layout.

---

## 4. Low-Level Context Switching

### 4.1 Context Representation

The CPU execution state is represented using a Zig struct:

```zig
pub const Context = struct {
    rip: *anyopaque,
    rsp: *anyopaque,
    rbx: *anyopaque,
    rbp: *anyopaque,
    r12: *anyopaque,
    r13: *anyopaque,
    r14: *anyopaque,
    r15: *anyopaque,
    rdi: *anyopaque,
    rsi: *anyopaque,
};
```
### 4.2 Assembly Context Switcher (Windows x64)

A Windows-specific assembly module (`context.s`) is implemented to perform low-level context switching in compliance with the **Microsoft x64 ABI**.

The module provides three core primitives:

- `get_context` – saves the current CPU execution state
- `set_context` – restores a previously saved context
- `swap_context` – saves one context and switches to another

Key design considerations:

- Function arguments are passed via `RCX` and `RDX`
- All Windows callee-saved registers (`RBX`, `RBP`, `RDI`, `RSI`, `R12–R15`) are preserved
- Stack pointer alignment is strictly enforced
- Control flow is restored using `RET`, not `JMP`

This assembly layer represents the **lowest-level execution control** in the system.

---

## 5. Manual Stack Construction

### 5.1 Motivation

Fibers do not execute on the main program stack. Each fiber requires a **separate synthetic stack** to allow independent execution contexts.

Stack memory is manually allocated and initialized to satisfy all ABI constraints.

---

### 5.2 Windows x64 Stack Requirements

The Microsoft x64 ABI enforces the following constraints:

- `RSP` must be **16-byte aligned**
- A **32-byte shadow space** must be reserved
- A valid return address must be present

Failure to meet these requirements results in undefined behavior or immediate crashes.

---

### 5.3 Synthetic Stack Layout

```text
High Memory Address
+----------------------------+
| Allocated Stack Memory     |
| (4–16 KB capacity)         |
+----------------------------+
| Alignment Padding          |
+----------------------------+
| Shadow Space (32 bytes)    |
+----------------------------+
| Fake Return Address (8 B)  |
+----------------------------+ <- Initial RSP
```
Low Memory Address

## 6. Task-Based Implementation Progress

### 6.1 Task 1.1 – Context Save and Restore
[cite_start]This task validates that[cite: 1, 2, 3]:
* [cite_start]CPU register state can be saved correctly[cite: 1, 2, 3].
* [cite_start]Execution flow can be restored[cite: 1, 2, 3].
* [cite_start]The implementation respects Windows ABI constraints[cite: 1, 2, 3].
* [cite_start]Successful completion confirms correctness of the low-level context primitives[cite: 1, 2, 3].

### 6.2 Task 1.2 – Manual Stack Switching
[cite_start]This task demonstrates[cite: 5, 6, 7, 8, 9, 10]:
* [cite_start]Execution transfer from the main stack to a synthetic stack[cite: 5, 6, 7, 8, 9, 10].
* [cite_start]Correct execution of a function on the new stack[cite: 5, 6, 7, 8, 9, 10].
* [cite_start]Safe termination using `ExitProcess`[cite: 5, 6, 7, 8, 9, 10].
* [cite_start]Returning from a fiber entry function is unsafe due to the lack of a valid caller frame[cite: 5, 6, 7, 8, 9, 10].

### 6.3 Task 1.3 – Fiber Encapsulation
[cite_start]Raw context and stack logic are encapsulated into a reusable Fiber abstraction:

```zig
pub const Fiber = struct {
    context: Context,
    stack: []u8,
    allocator: std.mem.Allocator,
};
```
## 7. Build and Execution

### 7.1 Build Instructions

```bash
zig build-exe task1_3.zig context.o -O ReleaseFast
```
### 7.2 Program Execution
```bash
.\task1_3.exe
```
The program intentionally produces no console output.
```bash
echo $LASTEXITCODE
```
An exit code of 0 confirms that:
- The fiber was successfully created
- Execution was transferred to the synthetic stack
- The fiber entry function executed
- The process terminated cleanly
## 8: Design Decisions and Safety Considerations
### 8.1 Use of ExitProcess
Fibers execute on manually constructed stacks and do not have a valid caller frame. Returning from a fiber entry function would cause undefined behavior by attempting to unwind an invalid stack.
For this reason, ExitProcess is used to terminate execution safely at the operating system level.
### 8.2 Avoidance of Zig Runtime Facilities
Standard Zig runtime features such as std.debug.print assume execution on the main program stack.
Invoking runtime-dependent functionality from a fiber stack can corrupt internal state and lead to crashes. Therefore, runtime I/O and stack-unwinding mechanisms are intentionally avoided.
## 9 Current Limitations
The current implementation has the following limitations:
- Cooperative execution only (no preemption)
- No yielding mechanism implemented yet
- Single-fiber execution model
- Fixed-size stack allocation
- No parallel execution across CPU cores
These limitations are acceptable for the current project stage and reflect deliberate design choices
## 10 Conclusion
This project demonstrates a functional low-level fiber foundation on Windows x64, including:
- ABI-compliant CPU context switching
- Manual synthetic stack construction
- Safe execution transfer between stacks
- Encapsulation into a reusable Fiber abstraction
