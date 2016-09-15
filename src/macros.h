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

#if defined(NEW3DS)
#define APPLICATION_HEAP_END (0x20000000 + 0x07C00000)
#else
#define APPLICATION_HEAP_END (0x20000000 + 0x04000000)
#endif

#define CODE_VA_TO_PA(va) ((va) + APPLICATION_HEAP_END - (GAME_CODEBIN_SIZE &~ 0xFFFFF))
