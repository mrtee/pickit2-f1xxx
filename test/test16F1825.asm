# This little program blinks the LEDs in a row on PICKit2 Low Pincount Demo Board
# using PIC16F1825 14-pin microcontroller

#include <P16F1825.INC>
     __CONFIG _CONFIG1, (_FOSC_INTOSC & _WDTE_SWDTEN )
#     __CONFIG _CONFIG2, (_LVP_OFF)
    cblock 0x70
valt
w1
random
w2
cnt1
    endc

    org 0

    bra         start

    org 4

    reset

start
    banksel     WDTCON
    movlw       b'00010011'
    movwf       WDTCON

    banksel     TRISC
    clrf        TRISC

    banksel     PORTC
hah
    clrf        valt
    clrf        PORTC
    sleep
    bsf         valt,0
    movf        valt,w
    movwf       PORTC
    sleep
    bsf         valt,1
    movf        valt,w
    movwf       PORTC
    sleep
    bsf         valt,2
    movf        valt,w
    movwf       PORTC
    sleep
    bsf         valt,3
    movf        valt,w
    movwf       PORTC
    sleep
    goto        hah

    end
