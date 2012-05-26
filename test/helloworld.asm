#include <P12LF1822.INC>
     __CONFIG _CONFIG1, (_FOSC_INTOSC & _WDTE_OFF & _PWRTE_OFF & _MCLRE_OFF & _CP_OFF & _FCMEN_OFF)
     org 0
Start:

     banksel TRISA
;     bsf     STATUS,RP0       ; select Register Page 1
     bcf     TRISA,2          ; make IO Pin C0 an output
;     bcf     STATUS,RP0       ; back to Register Page 0
     banksel PORTA
     bsf     PORTA,2          ; turn on LED C0 (DS1)

     goto    $                ; wait here
     end

