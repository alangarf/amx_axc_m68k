/*
 * Memory Map
 * --------------
 * 0x00000-0x0FFFF System ROM
 * 0x40000-0x4FFFF RAM
 *
 */

.include "sim40.inc"

.section .vectors, "a"
.title "Init vectors"
    .long   _stack_start
    .long   .init
    .long   .unhandled  | bus error
    .long   .unhandled  | addr error
    .long   .unhandled  | illegal instruction
    .long   .unhandled  | divide by zero
    .rept 0x2e
    .long .reset
    .endr
    .rept 0x40
    .long 0xffffffff
    .endr
    .rept 0x80
    .long .reset
    .endr

.section .text
.title "Program"

.unhandled: rte         | return exception
.reset:     reset       | reset

.init:
            move.w      #0x2700, %sr                | mask interrupts and set supervisor mode

            moveq       #7, %d0
            movec       %d0, %dfc
            move.l      #_sim40 + 1, %d0
            move.sl     %d0, 0x3ff00                | move sim40 base address to 0x80000

            /* setup ROM chip select CS0 */
            move.l      #0x03fffd, _sm_csam0 + _sim40   | 16 bit port, three wait, mask FC bits, 256KB in size
            move.l      #0x000001, _sm_csbar0 + _sim40  | starting at 0x00000

            /* setup RAM chip select CS1 */
            move.l      #0x03fff1, _sm_csam1 + _sim40   | 16 bit port, zero wait, mask FC bits, 256KB in size
            move.l      #0x040001, _sm_csbar1 + _sim40  | starting at 0x40000

            /* setup system protects and clock */
            move.b      #0x06, _sm_sypcr + _sim40   | turn off watchdogs, bus fault, bus monitor
            move.w      #0x7c00, _sm_syncr + _sim40 | set clock to 15.991 MHz
            move.w      #0x420f, _sm_mcr + _sim40   | set MCR, no interrupts etc

            bsr         .setup_dma
            bsr         .setup_timers
            bsr         .setup_portb
            bsr         .setup_uart

            | move.w      #0x2000, %sr                | enabled interrupts by clearing mask from SR

            /* setup ssp */
            lea         _stack_start, %sp

.blink:     lea         _seq, %a5
            moveq       #5, %d0
.loop:
            moveq       #0, %d1
            move.b      %a5@+, %d1

.loop1:     bsr.w       .led_on
            bsr.w       .led_off
            dbra        %d1, .loop1         | blink led the number of times from %d1

            bsr.w       .gap                | delay between blink sequence to next

            lea         _banner, %a0
            bsr         .tx_string

            dbra        %d0, .loop          | move to next sequence

            bra.w       .blink              | run through each sequence again

*************************************************************************
*
*  UART functions
*
.tx_string:
            movem.l     %a5, %a7@-                  | save a5 to stack
            lea         _uarts, %a5

_txrdy:     btst        #2, %a5@(_ua_srb)           | test TxRDY bit in status
            beq.s       _txrdy                      | loop till TxRDY is clear
            move.b      %a0@+, %a5@(_ua_tbb)        | send character in buffer of a0
            tstb        %a0@                        | check if there is another character to send
            bnes        _txrdy                      | send it if there is

            movem.l     %a7@+, %a5                  | restore a5 from stack
            rts

.setup_uart:
            lea         _uarts, %a0

            move.b      #0x20, %a0@(_ua_cra)        | reset RX on uart a
            move.b      #0x30, %a0@(_ua_cra)        | reset TX on uart a
            move.b      #0x20, %a0@(_ua_crb)        | reset RX on uart b
            move.b      #0x30, %a0@(_ua_crb)        | reset TX on uart b

            move.w      #0x02, %a0@(_ua_mcr)        | enable uarts, enable user access and set IARB priority
            move.b      #0x01, %a0@(_ua_ilr)        | set uart interrupt priority to 1
            move.b      #0x80, %a0@(_ua_ivr)        | set interrupt vector number 7
            clrb        %a0@(_ua_ier)               | disable interrupts
            move.b      #0x80, %a0@(_ua_acr)        | set 2 of BRG baud rates
            clrb        %a0@(_ua_opcr)              | disable uart status output pins (eg. TxRDY etc)

            /* uart b */
            move.b      #0xDD, %a0@(_ua_csrb)       | set uart b TX and RX to 38.4k
            move.b      #0x13, %a0@(_ua_mr1b)       | 8 bits, no parity bit, char error mode,
                                                    | char status in ISR for RX rather than full fifo
            move.b      #0x07, %a0@(_ua_mr2b)       | set one stop bit, no cts/rts, normal mode
            move.b      #0x05, %a0@(_ua_crb)        | nop command, enable TX and RX

            /* uart a */
            move.b      #0xEE, %a0@(_ua_csra)       | set uart a TX and RX to SCLK/16
            move.b      #0x13, %a0@(_ua_mr1a)       | 8 bits, no parity bit, char error mode,
                                                    | char status in ISR for RX rather than full fifo
            move.b      #0x07, %a0@(_ua_mr2a)       | set one stop bit, no cts/rts, normal mode
            move.b      #0x05, %a0@(_ua_crb)        | nop command, enable TX and RX

            | move.b      #34, %a0@(_ua_ier)        | enable RxRDYA and RxRDYB interrupts
            rts


*************************************************************************
*
*  Timer functions
*
.setup_timers:
            lea         _timers, %a0

            move.w      #-32768, %a0@(_tm1_mcr)     | disable timer 1
            move.w      #-32768, %a0@(_tm2_mcr)     | disable timer 1
            rts

*************************************************************************
*
*  DMA functions
*
.setup_dma:
            lea         _dma, %a0

            movew       #-32768, %a0@(_dma1_mcr)    | disable DMA channel 1
            movew       #-32768, %a0@(_dma2_mcr)    | disable DMA channel 2
            rts

*************************************************************************
*
*  PORTB functions
*
.setup_portb:
            lea         _sim40, %a0

            move.b      #0, %a0@(_sm_pparb)         | set portb 3,5,6,7 to be I/O and CS pins
            move.b      #0xfe, %a0@(_sm_ddrb)       | set all portb except bit 0 to be outputs
            move.b      #0x80, %a0@(_sm_portb)      | set bit 7 on, the rest off
            rts

*************************************************************************
*
*  Utility functions
*
.led_on:
            ori.b       #0x20, 0x80019      | turn LED on
            move.l      #50000, %d5
            bsr.s       .delay
            rts

.led_off:
            andi.b      #0xdf, 0x80019      | turn LED off
            move.l      #100000, %d5
            bsr.s       .delay
            rts

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

_banner:    .asciz      "Hello there!\r\n"
