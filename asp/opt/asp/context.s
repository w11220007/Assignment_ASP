/* src/asm/context_windows.s */
.text
.align 16
.global get_context
get_context:
  movq (%rsp), %r8
  movq %r8, 0x00(%rcx)       /* Save RIP (Instruction Pointer) */
  leaq 8(%rsp), %r8
  movq %r8, 0x08(%rcx)       /* Save RSP (Stack Pointer) */
  movq %rbx, 0x10(%rcx)
  movq %rbp, 0x18(%rcx)
  movq %r12, 0x20(%rcx)
  movq %r13, 0x28(%rcx)
  movq %r14, 0x30(%rcx)
  movq %r15, 0x38(%rcx)
  movq %rdi, 0x40(%rcx)      /* Windows requires saving RDI (non-volatile) */
  movq %rsi, 0x48(%rcx)      /* Windows requires saving RSI (non-volatile) */
  xorl %eax, %eax
  ret

.global set_context
set_context:
  movq 0x08(%rcx), %rsp      /* Restore RSP */
  movq 0x00(%rcx), %r8       /* Load RIP */
  movq 0x10(%rcx), %rbx
  movq 0x18(%rcx), %rbp
  movq 0x20(%rcx), %r12
  movq 0x28(%rcx), %r13
  movq 0x30(%rcx), %r14
  movq 0x38(%rcx), %r15
  movq 0x40(%rcx), %rdi
  movq 0x48(%rcx), %rsi
  pushq %r8                  /* Push RIP to stack so RET can pop it */
  xorl %eax, %eax
  ret

.global swap_context
swap_context:
  /* --- Save current context to RCX (1st argument) --- */
  movq (%rsp), %r8
  movq %r8, 0x00(%rcx)
  leaq 8(%rsp), %r8
  movq %r8, 0x08(%rcx)
  movq %rbx, 0x10(%rcx)
  movq %rbp, 0x18(%rcx)
  movq %r12, 0x20(%rcx)
  movq %r13, 0x28(%rcx)
  movq %r14, 0x30(%rcx)
  movq %r15, 0x38(%rcx)
  movq %rdi, 0x40(%rcx)
  movq %rsi, 0x48(%rcx)
  
  /* --- Load new context from RDX (2nd argument) --- */
  movq 0x00(%rdx), %r8
  movq 0x08(%rdx), %rsp
  movq 0x10(%rdx), %rbx
  movq 0x18(%rdx), %rbp
  movq 0x20(%rdx), %r12
  movq 0x28(%rdx), %r13
  movq 0x30(%rdx), %r14
  movq 0x38(%rdx), %r15
  movq 0x40(%rdx), %rdi
  movq 0x48(%rdx), %rsi
  pushq %r8
  xorl %eax, %eax
  ret