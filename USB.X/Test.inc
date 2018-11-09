Pause   ;x 10ms in W
        movwf   COUNT0
        banksel OPTION_REG
        bcf     OPTION_REG, TMR0CS  ;internal clock
        bcf     OPTION_REG, PSA     ;
        bcf     OPTION_REG, PS0
        bsf     OPTION_REG, PS1
        bcf     OPTION_REG, PS2
        banksel TMR0

psC0_bk
        movlw   0x0a
        movwf   COUNT1
psC1_bk
        clrf    TMR0
        bcf     INTCON, TMR0IF  ; clear interrupt
psT_bk
        btfss   INTCON, TMR0IF
        goto    psT_bk
        decfsz  COUNT1
        goto    psC1_bk
        decfsz  COUNT0
        goto    psC0_bk

        return
;---------------------------------------------------
Flash                               ;flashes LED no. of times controlled by W
        movwf   COUNT0              ;store no. of flashes
        movf    COUNT0              ;test count
        btfsc   STATUS, Z           ;return
        return                      ;if zero

        banksel OPTION_REG
        bcf     OPTION_REG, TMR0CS  ;internal clock
        bcf     OPTION_REG, PSA     ;
        bsf     OPTION_REG, PS0
        bsf     OPTION_REG, PS1
        bsf     OPTION_REG, PS2
        movlw   0x08                ;time adjust

flon
        banksel PORTC           ;PORTC & TMR0
        bsf     ORANGE          ; LED on
        movwf   COUNT1
flonC_bk
        clrf    TMR0
        bcf     INTCON, TMR0IF  ; clear interrupt
flon_bk
        btfss   INTCON, TMR0IF
        goto    flon_bk
        decfsz  COUNT1
        goto    flonC_bk

floff
        bcf     ORANGE          ; LED off
        movwf   COUNT1
floffC_bk
        clrf    TMR0
        bcf     INTCON, TMR0IF  ; clear interrupt
floff_bk
        btfss   INTCON, TMR0IF
        goto    floff_bk
        decfsz  COUNT1
        goto    floffC_bk

        decfsz  COUNT0
        goto    flon

        return
;---------------------------------------------------
Red
        banksel PORTC   ;
        bsf     RED     ;
        return
;---------------------------------------------------
Orng
        banksel PORTC   ;
        bsf     ORANGE  ;
        return
;---------------------------------------------------
Grn
        banksel PORTC   ;
        bsf     GREEN   ;
        return
;---------------------------------------------------
_Grn
        banksel PORTC   ;
        bcf     GREEN   ;
        return
;---------------------------------------------------
Clr
        banksel PORTC   ;
        clrf    PORTC   ;
        return
;---------------------------------------------------
tRst    movfw   BSR
        banksel test
        clrf    bConfig
        incf    num_rst
        movwf   BSR
        return
;---------------------------------------------------
setConf
        movfw   BSR
        banksel test
        incf    bConfig
        movwf   BSR
        return
;---------------------------------------------------
incGD   movfw   BSR
        banksel test
        incf    num_gd
        movwf   BSR
        return
;---------------------------------------------------
incSA   movfw   BSR
        banksel test
        incf    num_sa
        movwf   BSR
        return
;---------------------------------------------------
ShowByte
        banksel test
        movwf   TEMP0
        movwf   TEMP1
        banksel PORTC
        clrf    PORTC       ;clear LEDs

hi:     bsf     RED       ; hi nybble

        banksel test
        lsrf    TEMP0
        lsrf    TEMP0
        lsrf    TEMP0
        lsrf    TEMP0
        movfw   TEMP0
        call    Flash

        movlw   25          ;0.25s
        call    Pause
        banksel PORTC
        clrf    PORTC       ;clear LEDs

        banksel PORTC
        bsf     GREEN

lo:     movlw   0x0f        ; lo nybble
        banksel TEMP0
        andwf   TEMP1,0
        call    Flash

        movlw   25          ;0.25s
        call    Pause

        banksel PORTC
        clrf    PORTC       ;clear LEDs

        movlw   50          ;0.5s
        call    Pause

        return
;---------------------------------------------------
InitTest
        movlw   0x04        ;bank 8
        movwf   FSR1H
        movlw   SC          ;
        movwf   FSR1L
        banksel test
        clrf    bConfig
        clrf    num_rst
        clrf    num_gd
        clrf    num_sa
        clrf    tc
        movlw   0x50
        movwf   COUNT0
        clrw
it_clr  movwi   FSR1++
        decfsz  COUNT0
        goto    it_clr

        return
;---------------------------------------------------
Sh_xy
        banksel test
        movlw   0x02        ;resets
        xorwf   num_rst,0
        btfss   STATUS,Z
        return
        movlw   0x01        ;GetDescriptors
        xorwf   num_gd,0
        btfss   STATUS,Z
        return
nSA     movlw   0x01        ;SetAddress
        xorwf   num_sa,0
        btfss   STATUS,Z
        return
        call    ShowBytes
        return
;---------------------------------------------------
ShowBytes
        call Clr
        movlw   0x32
        call    Pause
        banksel UCON
        movfw   USTAT
        call    ShowByte            ;USTAT
        movlw   0x04        ;DIR mask
        banksel UCON
        andwf   USTAT,0
        btfss   STATUS,Z    ;check Direction
        goto    t_In
t_out   movlw   BD0STATL
        movwf   FSR0L
        movfw   INDF0
        call    ShowByte            ;BD0STAT
        movlw   BD0DATAL + bmRequestType
        movwf   FSR0L
        moviw   FSR0++
        call    ShowByte            ;bmRequestType
        moviw   FSR0++
        call    ShowByte            ;bRequest
        moviw   FSR0++
        call    ShowByte            ;wValueL
        moviw   FSR0++
        call    ShowByte            ;wValueH
        moviw   FSR0++
;        call    ShowByte            ;wIndexL
        moviw   FSR0++
;        call    ShowByte            ;wIndexH
        moviw   FSR0++
        call    ShowByte            ;wLengthL
        moviw   FSR0++
;        call    ShowByte            ;wLengthH
        goto    ds_ex
t_In
        movlw   BD1STATL
        movwf   FSR0L
        movfw   INDF0
        call    ShowByte            ;BD1STAT
ds_ex
        goto    $;***
        return
;---------------------------------------------------
        #define TCOUNT  0x01
TLog
        incf    IN;<<<<<<<<<<<<<<
        return;<<<<<<<<<<<<<<

        banksel test
        movf    bConfig     ;check configured
        btfsc   STATUS,Z
        return

        incf    tc          ;increment count
        movlw   TCOUNT
        xorwf   tc,0
        btfss   STATUS,Z
        return

        call    ShowBytes

;---------------------------------------------------
