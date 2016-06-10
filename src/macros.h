/* freakyforms qr code exploit. */
/* plutoo 2016 */
#define GARBAGE 0xDEADC0DE

#if defined(EUR)
#define REGION_CONST(name, eur, usa, jap) .set name, eur
#elif defined(USA)
#define REGION_CONST(name, eur, usa, jap) .set name, usa
#elif defined(JAP)
#define REGION_CONST(name, eur, usa, jap) .set name, jap
#else
#error "wat"
#endif

#define GLOBAL_CONST(name, val) .set name, val

#define PA_TO_GPU_ADDR(pa) ((pa) - 0x0C000000)
#define GPU_TO_PA_ADDR(pa) ((pa) + 0x0C000000)

/* Apparently JAP code is a bit smaller than the other ones, making code.bin
   being allocated at a slightly different address. */
REGION_CONST(NEW_VA_TO_PA, 0x27700000, 0x27700000, 0x27800000);
REGION_CONST(OLD_VA_TO_PA, 0x23B00000, 0x23B00000, 0x23C00000);

#if defined(NEW3DS)
#define CODE_VA_TO_PA(va) ((va) + NEW_VA_TO_PA)
#else
#define CODE_VA_TO_PA(va) ((va) + OLD_VA_TO_PA)
#endif
