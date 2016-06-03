/* freakyforms qr code exploit. */
/* plutoo 2016 */
#define GARBAGE 0xDEADC0DE

#if defined(EUR)
#define REGION_CONST(name, eur, usa) .set name, eur
#elif defined(USA)
#define REGION_CONST(name, eur, usa) .set name, usa
#else
    /* I didn't buy the japanese game. :( */
    #error "moshi moshi"
#endif

#define GLOBAL_CONST(name, val) .set name, val

#define PA_TO_GPU_ADDR(pa) ((pa) - 0x0C000000)
#define GPU_TO_PA_ADDR(pa) ((pa) + 0x0C000000)

#if defined(NEW3DS)
#define CODE_VA_TO_PA(va) ((va) + 0x27700000)
#else
#define CODE_VA_TO_PA(va) ((va) + 0x23B00000)
#endif
