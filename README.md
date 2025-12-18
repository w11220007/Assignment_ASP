# 🧵 Zig Fiber Library – Cooperative Coroutines

**Module:** Advanced Systems Programming  
**Assessment:** Task B – User-Level Fibers  
**Language:** Zig  
**Target Platform:** Windows x86_64  
**Zig Version:** 0.16.x (dev)

---

## 📌 Project Overview

This repository contains a **user-level fiber (co-routine) library implemented in Zig**, developed as part of **ASP Task B**.

The project demonstrates advanced systems programming techniques including:

- Manual CPU context switching
- Stack management and ABI compliance
- Cooperative scheduling
- Shared-state concurrency without OS threads
- Unit testing using Zig’s testing framework

The implementation follows the assignment specification exactly and is divided into **three incremental tasks**, each building on the previous one.

---

## 🎯 Learning Objectives

- Understand how fibers differ from OS threads
- Implement manual context switching using Zig + assembly
- Design a cooperative round-robin scheduler
- Safely share data between fibers
- Write meaningful unit tests for low-level systems code
- Produce professional documentation suitable for real-world projects

---

## 🧠 Technical Background

### What Are Fibers?

Fibers are **lightweight user-space execution units**:

- Managed entirely in user space
- Much cheaper than OS threads
- Deterministic execution
- Commonly used in game engines and real-time systems

### Why Cooperative Scheduling?

This project uses **cooperative scheduling**, meaning:

- Fibers yield control explicitly
- No preemption or interrupts
- Predictable execution order
- Easier debugging and reasoning

This model is ideal for understanding concurrency fundamentals.

---

## 🗂 Repository Structure

```text
.
├── build.zig
├── src/
│   ├── asm/
│   │   └── context_windows.s
│   ├── context.zig
│   ├── fiber.zig
│   ├── scheduler.zig
│   ├── task1_part1.zig
│   ├── task1_part2.zig
│   ├── task1_part3.zig
│   ├── task2.zig
│   ├── task3.zig
│   └── tests.zig
└── README.md
