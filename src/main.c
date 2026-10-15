#include <libopencm3/stm32/rcc.h>
#include <libopencm3/stm32/gpio.h>
#include "tx_api.h"

#define BLINK_STACK_SIZE 512

static TX_THREAD blink_thread;
static uint8_t blink_stack[BLINK_STACK_SIZE] __attribute__((aligned(8)));

static void blink_thread_entry(ULONG thread_input)
{
    (void)thread_input;

    while (1) {
        gpio_toggle(GPIOC, GPIO13);
        /* 500 tick = 500 ms uyku (deterministik context switch) */
        tx_thread_sleep(500);
    }
}

void tx_application_define(void *first_unused_memory)
{
    (void)first_unused_memory;

    tx_thread_create(
        &blink_thread,
        "LED Blink Thread",
        blink_thread_entry,
        0,
        blink_stack,
        BLINK_STACK_SIZE,
        3,  /* Öncelik */
        3,  /* Preemption eşiği */
        TX_NO_TIME_SLICE,
        TX_AUTO_START
    );
}

static void hardware_init(void)
{
    /* 8 MHz harici kristalden 72 MHz PLL saatini kur */
    rcc_clock_setup_pll(&rcc_hse_configs[RCC_CLOCK_HSE8_72MHZ]);

    /* PC13 (Blue Pill dahili LED) çıkış olarak ayarla */
    rcc_periph_clock_enable(RCC_GPIOC);
    gpio_set_mode(GPIOC, GPIO_MODE_OUTPUT_2_MHZ, GPIO_CNF_OUTPUT_PUSHPULL, GPIO13);
}

int main(void)
{
    hardware_init();

    /* ThreadX çekirdeğini başlat (buradan asla geri dönmez) */
    tx_kernel_enter();

    return 0;
}
