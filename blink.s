/*
 * Blink LED connected to 74LS259 output.
 *
 * ROM is at 0x00000-0x0FA00.
 * RAM is at 0x20000-0x2FA00
 * 74LS259 is at 0x60000.
 */

.equ PORT, 0x60000

/* Iterations of delay loop before updating output value */
.equ DELAY, 50000

.section .vectors, "ax"
.title "Init vectors"
  .long .data+0xFF00
  .long .main
  .fill 0x50,4,0x00000200

.section .text
.title "Program"

.main:
    move.l #PORT, %a0

.top:
    move.b #0x0F, %d0   /* set Q7 to low in the addressable latch mode */
    move.b %d0, (%a0)   /* write to 'LS259 */

    move.l #DELAY, %d1
.delay1:
    tst.l %d1
    beq .delay1end
    subq.l #1, %d1
    jmp .delay1

.delay1end:
    move.b #0x0E, %d0   /* set Q7 to high in the addressable latch mode */
    move.b %d0, (%a0)   /* write to 'LS259 */

    move.l #DELAY, %d1
.delay2:
    tst.l %d1
    beq .delay2end
    subq.l #1, %d1
    jmp .delay2

.delay2end:
    jmp .top
