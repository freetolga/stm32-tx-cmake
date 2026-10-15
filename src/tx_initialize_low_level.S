.syntax unified
    .cpu cortex-m3
    .thumb

    .global  _tx_initialize_low_level
    .global  pend_sv_handler
    .global  sys_tick_handler

    /* libopencm3 linker ve vector.c sembolleri */
    .extern  _stack
    .extern  _ebss
    .extern  vector_table

    /* ThreadX dahili sembolleri */
    .extern  _tx_thread_system_stack_ptr
    .extern  _tx_initialize_unused_memory
    .extern  __tx_PendSVHandler
    .extern  _tx_timer_interrupt

SYSTEM_CLOCK      = 72000000
SYSTICK_CYCLES    = ((SYSTEM_CLOCK / 1000) - 1)

    .text
    .align 2

    .thumb_func
_tx_initialize_low_level:
    cpsid   i

    /* Sistem yığın (stack) işaretçisini kaydet (_stack libopencm3'ten gelir) */
    ldr     r0, =_tx_thread_system_stack_ptr
    ldr     r1, =_stack
    str     r1, [r0]

    /* Kullanılmayan ilk RAM adresini kaydet (_ebss libopencm3'ten gelir) */
    ldr     r0, =_tx_initialize_unused_memory
    ldr     r1, =_ebss
    add     r1, r1, #4
    str     r1, [r0]

    /* VTOR'u libopencm3 vector_table adresine ayarla */
    ldr     r0, =0xE000ED08
    ldr     r1, =vector_table
    str     r1, [r0]

    /* SysTick'i 1 ms (1000 Hz) olacak şekilde yapılandır */
    ldr     r0, =0xE000E000
    ldr     r1, =SYSTICK_CYCLES
    str     r1, [r0, #0x14]     /* SYST_RVR */
    mov     r1, #0
    str     r1, [r0, #0x18]     /* SYST_CVR */
    mov     r1, #7              /* Enable | TickInt | Clksource */
    str     r1, [r0, #0x10]     /* SYST_CSR */

    /* Sistem kesme önceliklerini ayarla (PendSV en düşük, SysTick yüksek) */
    ldr     r0, =0xE000ED18
    ldr     r1, =0x00000000
    str     r1, [r0, #4]        /* SHPR2 (SVCall) */
    ldr     r1, =0x40FF0000     /* SysTick: 0x40, PendSV: 0xFF */
    str     r1, [r0, #8]        /* SHPR3 */

    bx      lr

/* libopencm3 zayıf (weak) kesme fonksiyonlarını ThreadX'e yönlendir */
    .thumb_func
pend_sv_handler:
    b       __tx_PendSVHandler

    .thumb_func
sys_tick_handler:
    push    {r0, lr}
    bl      _tx_timer_interrupt
    pop     {r0, lr}
    bx      lr
