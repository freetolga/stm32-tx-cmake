#ifndef TX_USER_H
#define TX_USER_H

#define TX_MAX_PRIORITIES                       32
#define TX_MINIMUM_STACK                        200
#define TX_TIMER_THREAD_STACK_SIZE              512
#define TX_TIMER_THREAD_PRIORITY                0
#define TX_TIMER_TICKS_PER_SECOND               1000

/* Gereksiz şişkinlikleri kapat */
#define TX_DISABLE_PREEMPTION_THRESHOLD
#define TX_DISABLE_NOTIFY_CALLBACKS

#endif /* TX_USER_H */
