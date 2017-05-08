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
            lea         PORT, %a4

.blink:     lea         _seq, %a5
            moveq       #5, %d0
.loop:
            moveq       #2, %d1
            #move.b      %a5@+, %d1

.loop1:     bsr.w       .led_on
            bsr.w       .led_off
            dbra        %d1, .loop1         | blink led the number of times from %d1

            bsr.w       .gap                | delay between blink sequence to next

            dbra        %d0, .loop          | move to next sequence

            bra.w       .blink              | run through each sequence again

*************************************************************************
*
*  Turn on LED
*
.led_on:
            move.b      #0x0F, %a4@
            move.l      #50000, %d5
            bsr.s       .delay
            rts

*************************************************************************
*
*  Turn off LED
*
.led_off:
            move.b      #0x0E, %a4@
            move.l      #100000, %d5
            bsr.s       .delay
            rts

*************************************************************************
*
*  Arbitary Delay - Takes delay count via %d5
*
.gap:
            move.l      #1000000, %d5       | delay between blink sequence to next
            bsr.s       .delay
            rts

.delay:     tst.l       %d5
            beq         .delay_end
            subq.l      #1, %d5
            bra.s       .delay
.delay_end: rts

.align 2
_seq:       .byte       0x01
            .byte       0x02
            .byte       0x03
            .byte       0x04
            .byte       0x05
            .byte       0x06
            .byte       0x07
