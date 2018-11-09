;********************************************************************************
;
;	USB HID CLASS DEVICE
;
;********************************************************************************
	list p=16f1454
	#include p16f1454.inc
    #include usb_defs.inc

    errorlevel -302 ; supress "register not in bank0, check page bits" message
    errorlevel -303 ; supress "Program word too large.  Truncated to core size." message
    errorlevel -305 ; supress "Using default destination of 1 (file)." message

; 16MHz HS, 3x PLL, USBLSCLK /6,        Fosc =

; CONFIG1
; __config 0xFC2
 __CONFIG _CONFIG1, _FOSC_HS & _WDTE_OFF & _PWRTE_ON & _MCLRE_ON & _CP_OFF & _BOREN_ON & _CLKOUTEN_OFF & _IESO_OFF & _FCMEN_OFF
; CONFIG2
; __config 0x39FF
 __CONFIG _CONFIG2, _WRT_OFF & _CPUDIV_CLKDIV6 & _USBLSCLK_48MHz & _PLLMULT_3x & _PLLEN_ENABLED & _STVREN_OFF & _BORV_HI & _LPBOR_OFF & _LVP_ON
;*******************************************************
#define RED                 PORTC, RC2      ;RED LED
#define ORANGE              PORTC, RC3      ;ORANGE LED
#define GREEN               PORTC, RC4      ;GREEN LED
#define LED                 PORTC, RC5      ;Production LED
#define USBL                0x00            ;          > USB 2.0 <
#define USBH                0x02            ;
#define VIDL                0xD8            ;Microchip > VID 04D8 <
#define VIDH                0x04            ;Microchip
#define PIDL                0x77            ;          > PID cc77 <
#define PIDH                0xcc            ;
#define REVL                0x01            ;          > REV 0001 <
#define REVH                0x00            ;

        udata_shr   0x70 ; - 0x7f
Device_State        res     1
MaskedInts          res     1
ADDR                res     1
USB_dev_req         res     1
PID                 res     1
Data_wLength        res     1
DescriptorType      res     1
DescriptorIndex     res     1
DescriptorLength    res     1
IN                  res     1
OUT                 res     1
EP1_dev_req         res     1
COUNT0              res     1
COUNT1              res     1
TOGGLE              res     1


bank7       udata   0x3a0
bConfig             res     1
num_rst             res     1
num_gd              res     1
num_sa              res     1
TEMP0               res     1
TEMP1               res     1
TEMP2               res     1
LEDS                res     1
tc                  res     1
test                res     1

bank8       udata   0x420
SC                  res     1
S0                  res     1

;===========================================================================
		org 0x0000 				;Reset vector
		goto	Main
;---------------------------------------------------
		org	0x0004 				;Interrupt Vector

        banksel UCON
        movfw   UIR
        andwf   UIE,0
        movwf   MaskedInts
        btfsc   MaskedInts, IDLEIF      ;bus idle
        goto    idle
        btfsc   MaskedInts, TRNIF       ;transaction complete
        goto    tranCom
        btfsc   MaskedInts, UERRIF      ;err
        goto    err
        btfsc   MaskedInts, URSTIF      ;reset
        goto    rset
        retfie                  ;fall through

err     clrf   UEIR            ;ERROR!!!!!!
        goto    exit_int

idle    call    Idle
        goto    exit_int

tranCom call    ServiceUSB
        goto    exit_int

rset    call    USBReset
        goto    exit_int

exit_int
        banksel UCON
        clrf    UIR
        banksel PIR2            ;bank 0
        bcf     PIR2, USBIF
        retfie
;===========================================================================
;===========================================================================
LED_On
        banksel PORTC   
        bsf     LED
        return
;---------------------------------------------------
LED_Off
        banksel PORTC
        bcf     LED
        return
;===========================================================================
InitUSB
        movlw   BD0STATL            ;Initialise buffers
        movwf   FSR0L               ;
        clrw                        ;BD0STAT
        movwi   FSR0++
        movlw   MAX_PACKET_SIZE     ;ByteCount
        movwi   FSR0++
        movlw   BD0DATAL            ;bufferL
        movwi   FSR0++
        movlw   BD0DATAH            ;bufferH
        movwi   FSR0++
        clrw                        ;BD1STAT
        movwi   FSR0++
        movlw   MAX_PACKET_SIZE     ;ByteCount
        movwi   FSR0++
        movlw   BD1DATAL            ;bufferL
        movwi   FSR0++
        movlw   BD1DATAH            ;bufferH
        movwi   FSR0++
        clrw                        ;BD2STAT
        movwi   FSR0++
        movlw   OUT_REPORT_SIZE     ;ByteCount
        movwi   FSR0++
        movlw   BD2DATAL            ;bufferL
        movwi   FSR0++
        movlw   BD2DATAH            ;bufferH
        movwi   FSR0++
        clrw                        ;BD3STAT
        movwi   FSR0++
        movlw   IN_REPORT_SIZE      ;ByteCount
        movwi   FSR0++
        movlw   BD3DATAL            ;bufferL
        movwi   FSR0++
        movlw   BD3DATAH            ;bufferH
        movwi   FSR0++

        banksel UCON                ;UCON & all USB special registers
        bsf     UCFG, UPUEN         ;enable pull-ups
        bsf     UCFG, FSEN          ;full speed
        movlw   DEFAULT_STATE       ;start in
        movwf   Device_State        ;default state
        movlw   NO_REQUEST          ;start with
        movwf   USB_dev_req         ;no requests
        movwf   EP1_dev_req         ;

        movlw   ENDPT_DISABLED      ;Disable Endpoints
        movwf   UEP0                ;until USBReset
        movwf   UEP1                ;& Set_Config

        clrf    UEIR                ;clear USB error interrupts
        clrf    UIR                 ;clear USB interrupts
        movlw   b'10011111'         ;all error
        movwf   UEIE                ;interrupts enabled
        movlw   b'00010011'         ;Idle, Errors & USBreset *******
        movwf   UIE                 ;interrupts enabled

pll_bk
        banksel OSCSTAT
        btfss   OSCSTAT, PLLRDY     ;wait for PLL
        goto    pll_bk              ;to stabilise
        banksel UCON
        bsf     UCON, USBEN         ;enable USB module

se0_bk
        btfsc   UCON, SE0           ;wait for
        goto    se0_bk              ;end of SE0
        bsf     INTCON, GIE

        return
;===========================================================================
USBReset
        call    LED_Off
        movlw   DEFAULT_STATE       ;change to
        movwf   Device_State        ;default state
        movlw   NO_REQUEST
        movwf   USB_dev_req
        movwf   EP1_dev_req
        clrf    ADDR
        banksel UCON
        movlw   b'00011011'         ;Idle, Transaction Complete, Errors & USBreset
        movwf   UIE                 ;interrupts enabled
        bcf     UIR, TRNIF          ;clear
        bcf     UIR, TRNIF          ;out
        bcf     UIR, TRNIF          ;USTAT
        clrf    UIR                 ;FIFO
        bcf     UCON, PKTDIS        ;enable next packet
        call    Reset_EP0_OutBuffer ;ready for OUT/SETUP packets
        call    Reset_EP0_InBuffer  ;ready for IN packets
        movlw   ENDPT_CONTROL       ;handshake, control, in/out, clear stall
        movwf   UEP0                ;enable ENDPOINT0

;        call    tRst;<--------------<<<<<<<<<<<<<<<<<<<<<<<<
        return
;===========================================================================
Idle
        banksel LATC    ;store outputs
        movfw   LATC
        clrf    LATC
        banksel LEDS
        movwf   LEDS

        banksel UCON
        bcf     UIR, ACTVIF         ;clr active flag
        bcf     UIE, IDLEIF         ;disable idle interrupt
        bsf     UCON, SUSPND        ;enter SUSPEND mode

        btfss   UIR, ACTVIF         ;wait for
        goto    $-1                 ;bus activity

        bcf     UCON, SUSPND        ;exit SUSPEND mode
        bcf     UIR, IDLEIF         ;clr idle flag
        bsf     UIE, IDLEIE         ;enable idle interrupt
act_cf  bcf     UIR, ACTVIF         ;clear bus activity flag
        btfsc   UIR, ACTVIF         ;test and
        goto    act_cf              ;repeat if neccessary

        banksel LEDS    ;restore outputs
        movfw   LEDS
        banksel PORTC
        movwf   PORTC
        return
;===========================================================================
Reset_EP0_OutBuffer
        movlw   BD0STATL + BYTECOUNT
        movwf   FSR0L
        movlw   MAX_PACKET_SIZE         ;count
        movwi   FSR0--
        clrf    INDF0                   ;clr BD0STAT
        bsf     INDF0, UOWN         ;hand over control to SIE
        return
;===========================================================================
Reset_EP0_InBuffer
        movlw   BD1STATL + BYTECOUNT
        movwf   FSR0L
        movlw   MAX_PACKET_SIZE         ;count
        movwi   FSR0--
        clrf    INDF0                   ;clr BD1STAT
        bsf     INDF0, UOWN         ;hand over control to SIE
        return
;===========================================================================
Reset_EP1_OutBuffer
        movlw   BD2STATL + BYTECOUNT
        movwf   FSR0L
        movlw   OUT_REPORT_SIZE     ;count
        movwi   FSR0--
        clrf    INDF0               ;clr BD2STAT
        bsf     INDF0, UOWN     ;hand over control to SIE
        return
;===========================================================================
Reset_EP1_InBuffer
        movlw   BD3STATL + BYTECOUNT
        movwf   FSR0L
        movlw   IN_REPORT_SIZE     ;count
        movwi   FSR0--
        clrf    INDF0               ;clr BD2STAT
        bsf     INDF0, UOWN     ;hand over control to SIE
        return
;===========================================================================
Stall_EP0_OutBuffer
        movlw   BD0STATL
        movwf   FSR0L
        bsf     INDF0, BSTALL
        return
;===========================================================================
Stall_EP0_InBuffer
        movlw   BD1STATL
        movwf   FSR0L
        bsf     INDF0, BSTALL
        return
;===========================================================================
Stall_EP1_OutBuffer
        movlw   BD2STATL
        movwf   FSR0L
        bsf     INDF0, BSTALL
        return
;===========================================================================
Stall_EP1_InBuffer
        movlw   BD3STATL
        movwf   FSR0L
        bsf     INDF0, BSTALL
        return
;===========================================================================
Send_0Len_pkt
        movlw   BD1STATL        ;IN buffer
        movwf   FSR0L
        clrf    INDF0
        incf    FSR0L           ;BD1CNT
        clrf    INDF0           ;zero count
        decf    FSR0L
        movlw   0x48            ;data1
        movwf   INDF0
        bsf     INDF0, UOWN     ;hand over control to SIE
        return
;===========================================================================
SendData
        movlw   BD1ADRHL        ;Set buffer control registers
        movwf   FSR0L
        movlw   BD1DATAH        ; => BD1ADRH
        movwi   FSR0--
        movlw   BD1DATAL        ; => BD1ADRL
        movwi   FSR0--
        movfw   Data_wLength    ; => BD1CNT
        movwi   FSR0--
        movlw   0x48            ;data1 => BD1STAT
        movwf   INDF0
        bsf     INDF0, UOWN     ;hand over control to SIE
        return
;===========================================================================
Init_TMR2
        banksel TMR2
        movlw   0x7f        ;postscaler 16, prescaler 64
        movwf   T2CON
        movlw   0x80;0x4d        ;
        movwf   PR2         ;period register
        clrf    TMR2
        bcf     PIR1, TMR2IF
        return
;===========================================================================
Main
        bsf     INTCON, PEIE            ;enable peripheral interupts
        clrf    PORTC                   ;clear outputs
        banksel ANSELC
        clrf    ANSELC
        banksel TRISC                   ;TRISC, PIE2, OPTION_REG
        bsf     PIE2, USBIE             ;enable USB interupts
        movlw   b'11011111'             ;RC0 - RC4 inputs, RC5 output
        movwf   TRISC
        bsf     OSCCON, SPLLMULT        ;3x
        bcf     OPTION_REG, NOT_WPUEN   ;enable pull-ups
        movlw   BD0STATH
        movwf   FSR0H
;        call    InitTest;<<<<<<<<<<<<<<<<<<<<<<<<<<<<
        call    Init_TMR2
        call    InitUSB

loop_bk
        movlw   CONFIG_STATE
        xorwf   Device_State,0
        btfss   STATUS,Z
        goto    loop_bk                 ; rpt forever

        banksel PIR1                    ;if configured perform
        btfss   PIR1, TMR2IF            ;interrupt transfers
        goto    loop_bk                 ;
        banksel PORTC
        movfw   PORTC                   ;read PORTC
        andlw   0x1f                    ;only bit 0-5 ***
        movwf   IN
        call    send_data_int           ;interrupt IN transfer
        bcf     PIR1, TMR2IF
        goto    loop_bk
;===========================================================================
;===========================================================================
ServiceUSB
;        call    TLog;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

        banksel UCON
        movlw   0x78                ;ENDP mask
        andwf   USTAT,0
        btfss   STATUS,Z            ;check endpoint
        goto    EP_1
EP_0    movlw   0x04                ;DIR mask
        andwf   USTAT,0
        btfss   STATUS,Z            ;check Direction
        goto    EP0_In

EP0_Out
        movlw   BD0STATL            ;BD0STAT
        movwf   FSR0L
        movlw   0x3c                ;PID mask
        andwf   INDF0,0
        movwf   PID                 ;store PID

        movlw   TOKEN_SETUP         ;setup packet
        xorwf   PID,0
        btfsc   STATUS,Z
        call    Setup
        movlw   TOKEN_OUT           ;host sending data
        xorwf   PID,0
        btfsc   STATUS,Z
        call    Out
        return

EP0_In
        movlw   BD1STATL            ;BD1STAT
        movwf   FSR0L
        movlw   0x3c                ;PID mask
        andwf   INDF0,0
        movwf   PID                 ;store PID

        movlw   TOKEN_IN            ;host requests data
        xorwf   PID,0
        btfsc   STATUS,Z
        call    In
        return

;===========================================================================
;       SETUP   TOKEN
;===========================================================================
Setup
        movlw   BD0DATAL            ;bmRequestType
        movwf   FSR0L

        movlw   0x60        ;request type mask
        andwf   INDF0,w
        xorlw   CLASS
        btfsc   STATUS,Z
        goto    ClassSpecificRequest

        movlw   HOSTTODEVICE        ;standard requests
        xorwf   INDF0,0
        btfsc   STATUS,Z
        goto    HostToDevice
        movlw   DEVICETOHOST
        xorwf   INDF0,0
        btfsc   STATUS,Z
        goto    DeviceToHost
        movlw   HOSTTOINTERFACE
        xorwf   INDF0,0
        btfsc   STATUS,Z
        goto    HostToInterface
        movlw   INTERFACETOHOST
        xorwf   INDF0,0
        btfsc   STATUS,Z
        goto    InterfaceToHost
        movlw   HOSTTOENDPOINT
        xorwf   INDF0,0
        btfsc   STATUS,Z
        goto    HostToEndpoint
        movlw   ENDPOINTTOHOST
        xorwf   INDF0,0
        btfsc   STATUS,Z
        goto    EndpointToHost
        goto    su_exit
;-----------------------------------------------------------
HostToDevice
        movlw   BD0DATAL + bRequest ;bRequest
        movwf   FSR0L

        movlw   CLEAR_FEATURE       ;
        xorwf   INDF0,0
        btfsc   STATUS,Z
        call    ClearFeature
        movlw   SET_FEATURE         ;
        xorwf   INDF0,0
        btfsc   STATUS,Z
        call    SetFeature
        movlw   SET_ADDRESS         ;
        xorwf   INDF0,0
        btfsc   STATUS,Z
        call    SetAddress
        movlw   SET_DESCRIPTOR      ;
        xorwf   INDF0,0
        btfsc   STATUS,Z
        call    SetDescriptor
        movlw   SET_CONFIGURATION   ;
        xorwf   INDF0,0
        btfsc   STATUS,Z
        call    SetConfiguration
        goto    su_exit
;-----------------------------------------------------------
DeviceToHost
        movlw   BD0DATAL + bRequest  ;bRequest
        movwf   FSR0L

        movlw   GET_STATUS          ;
        xorwf   INDF0,0
        btfsc   STATUS,Z
        call    GetStatus
        movlw   GET_DESCRIPTOR      ;
        xorwf   INDF0,0
        btfsc   STATUS,Z
        call    GetDescriptor
        movlw   GET_CONFIGURATION   ;
        xorwf   INDF0,0
        btfsc   STATUS,Z
        call    GetConfiguration
        goto    su_exit
;-----------------------------------------------------------
HostToInterface
        movlw   BD0DATAL + bRequest  ;bRequest
        movwf   FSR0L

        movlw   CLEAR_FEATURE       
        xorwf   INDF0,0
        btfsc   STATUS,Z
        call    ClearInterfaceFeature
        movlw   SET_FEATURE         
        xorwf   INDF0,0
        btfsc   STATUS,Z
        call    SetInterfaceFeature
        movlw   SET_INTERFACE       
        xorwf   INDF0,0
        btfsc   STATUS,Z
        call    SetInterface
        goto    su_exit
;-----------------------------------------------------------
InterfaceToHost
        movlw   BD0DATAL + bRequest  ;bRequest
        movwf   FSR0L

        movlw   GET_STATUS          
        xorwf   INDF0,0
        btfsc   STATUS,Z
        call    GetInterfaceStatus
        movlw   GET_DESCRIPTOR
        xorwf   INDF0,0
        btfsc   STATUS,Z
        call    GetDescriptor
        movlw   GET_INTERFACE       
        xorwf   INDF0,0
        btfsc   STATUS,Z
        call    GetInterface      
        goto    su_exit
;-----------------------------------------------------------
HostToEndpoint
        movlw   BD0DATAL + bRequest  ;bRequest
        movwf   FSR0L

        movlw   CLEAR_FEATURE       
        xorwf   INDF0,0
        btfsc   STATUS,Z
        call    ClearEndpointFeature
        movlw   SET_FEATURE         
        xorwf   INDF0,0
        btfsc   STATUS,Z
        call    SetEndpointFeature
        goto    su_exit
;-----------------------------------------------------------
EndpointToHost
        movlw   BD0DATAL + bRequest  ;bRequest
        movwf   FSR0L

        movlw   GET_STATUS          
        xorwf   INDF0,0
        btfsc   STATUS,Z
        call    GetEndpointStatus
        movlw   SYNCH_FRAME         
        xorwf   INDF0,0
        btfsc   STATUS,Z
        call    EpSynchFrame       
        goto    su_exit
;-----------------------------------------------------------
su_exit call    Reset_EP0_OutBuffer
        banksel UCON
        bcf     UCON, PKTDIS    ;enable next packet
        bcf     UIR, TRNIF
        return
;===========================================================================
;       IN   TOKEN
;===========================================================================
In       
        movlw   SET_ADDRESS     ;check if 
        xorwf   USB_dev_req,0   ;SET_ADDRESS
        btfsc   STATUS,Z        ;is in progress
        call    WriteAddr
        call    Reset_EP0_InBuffer
        return
;===========================================================================
;       OUT   TOKEN
;===========================================================================
Out
        movlw   SET_REPORT      ;check if
        xorwf   USB_dev_req,0   ;SET_REPORT
        btfsc   STATUS,Z        ;is in progress
        call    StoreReport
        movlw   NO_REQUEST
        movwf   USB_dev_req
        call    Reset_EP0_OutBuffer
        return
;===========================================================================
;===========================================================================
;           Standard Requests - Device
;===========================================================================
GetStatus                                   ;(0x00)
        movlw   BD1DATAL
        movwf   FSR0L
        movlw   DEVICE_REMOTE_WAKEUP    ;statusL
        moviw   FSR0++
        movlw   0x00                    ;statusH
        movwf   INDF0

        movlw   0x02                    ;byte count
        movwf   Data_wLength
        call    SendData

        movlw   GET_STATUS       ;
        movwf   USB_dev_req
        return
;===========================================================================
ClearFeature                                ;(0x01)
        call    Stall_EP0_InBuffer
        return
;===========================================================================
SetFeature                                  ;(0x03)
        call    Stall_EP0_InBuffer
        return
;===========================================================================
SetAddress                                  ;(0x05)
        call    Send_0Len_pkt
        movlw   BD0DATAL + wValue
        movwf   FSR0L
        movfw   INDF0
        movwf   ADDR                ;store address
        movlw   SET_ADDRESS
        movwf   USB_dev_req
        return
WriteAddr
        movfw   ADDR                ;write
        banksel UCON                ;address
        movwf   UADDR               ;to UADDR
        clrf    ADDR
        movlw   ADDRESS_STATE
        movwf   Device_State        ;set ADDRESSED!!!
        movlw   NO_REQUEST          ;clear
        movwf   USB_dev_req         ;request state
;        call    incSA;<------------------<<<<<<<<<<<<<<<<<<<<<<<<<<<<
        return
;===========================================================================
; GetDescriptor in Descriptors.inc
;===========================================================================
SetDescriptor                               ;(0x07) not supported
        call    Stall_EP0_InBuffer
        return
;===========================================================================
GetConfiguration                            ;(0x08)
        movlw   BD1DATAL
        movwf   FSR0L
        movlw   0x01            ;configured
        movwf   INDF0
        movlw   CONFIG_STATE    ;check if
        xorwf   Device_State,0  ;configured
        btfss   STATUS,Z        ;If not
        clrf    INDF0           ;send zero

        movlw   0x01            ;byte count
        movwf   Data_wLength
        call    SendData

        movlw   GET_CONFIGURATION       ;
        movwf   USB_dev_req
        return
;===========================================================================
SetConfiguration            ;(0x09)
        movlw   BD0DATAL + wValue   ;if wValue
        movwf   FSR0                ;contains 1,
        movlw   0x01                ;set configured
        xorwf   INDF0,0
        btfsc   STATUS,Z
        goto    configured
        call    Stall_EP0_InBuffer   ;not configured
        return

configured
        call    Send_0Len_pkt
        banksel UCON
        movlw   ENDPT_NON_CONTROL   ;handshake, in/out, clear stall <<<<<<<<<<
        movwf   UEP1                ;enable ENDPOINT1
        call    Reset_EP1_OutBuffer
        movlw   CONFIG_STATE
        movwf   Device_State        ;**** CONFIGURED!!!!!!!!!!
        call    LED_On
;        call    setConf;<-----------------------------<<<<<<<<<<<<<<<<<<<<<<<
        return
;===========================================================================
;           Standard Requests - Interface
;===========================================================================
GetInterfaceStatus                          ;(0x00)
        movlw   BD1DATAL
        movwf   FSR0L
        movlw   0x00            ;reserved
        moviw   FSR0++
        movlw   0x00            ;reserved
        movwf   INDF0

        movlw   0x02            ;byte count
        movwf   Data_wLength
        call    SendData

        movlw   GET_STATUS       
        movwf   USB_dev_req
        return
;===========================================================================
ClearInterfaceFeature                       ;(0x01)
        call    Stall_EP0_InBuffer
        return
;===========================================================================
SetInterfaceFeature                         ;(0x03)
        call    Stall_EP0_InBuffer
        return
;===========================================================================
ifGetDescriptor;<<<<<<<<<<<<<<<<
        call    Stall_EP0_InBuffer
        return
;===========================================================================
GetInterface                                ;(0x0A)
        movlw   BD0DATAL + wIndex   ;wIndex contains
        movwf   FSR0                ;interface nummber
        movf    INDF0
        btfsc   STATUS,Z
        goto    send_bAlternate
        call    Stall_EP0_InBuffer
        return
send_bAlternate
        movlw   BD1DATAL
        movwf   FSR0L
        movlw   0x00            ;only interface
        moviw   FSR0++

        movlw   0x01            ;byte count
        movwf   Data_wLength
        call    SendData
        movlw   GET_INTERFACE
        movwf   USB_dev_req
        return
;===========================================================================
SetInterface                                ;(0x11)
        call    Stall_EP0_InBuffer
        return
;===========================================================================
;           Standard Requests - Endpoint
;===========================================================================
GetEndpointStatus                           ;(0x00)
        movlw   BD1DATAL
        movwf   FSR0L
        movlw   0x00            ;reserved
        moviw   FSR0++
        movlw   0x00            ;dir & endpoint
        movwf   INDF0

        movlw   0x02            ;byte count
        movwf   Data_wLength
        call    SendData

        movlw   GET_STATUS      
        movwf   USB_dev_req
        return
;===========================================================================
ClearEndpointFeature                        ;(0x01)
        call    Stall_EP0_InBuffer
        return
;===========================================================================
SetEndpointFeature                          ;(0x03)
        call    Stall_EP0_InBuffer
        return
;===========================================================================
EpSynchFrame                                ;(0x12)
        call    Stall_EP0_InBuffer
        return
;===========================================================================
;                       HID requests
;===========================================================================
ClassSpecificRequest ;(HID)
        movlw   BD0DATAL + bRequest  ;bRequest
        movwf   FSR0L

        movlw   GET_REPORT
        xorwf   INDF0,0
        btfsc   STATUS,Z
        goto    GetReport
        movlw   GET_IDLE
        xorwf   INDF0,0
        btfsc   STATUS,Z
        goto    GetIdle
        movlw   GET_PROTOCOL
        xorwf   INDF0,0
        btfsc   STATUS,Z
        goto    GetProtocol
        movlw   SET_REPORT
        xorwf   INDF0,0
        btfsc   STATUS,Z
        goto    SetReport
        movlw   SET_IDLE
        xorwf   INDF0,0
        btfsc   STATUS,Z
        goto    SetIdle
        movlw   SET_PROTOCOL
        xorwf   INDF0,0
        btfsc   STATUS,Z
        goto    SetProtocol
fallthrough                     ;shouldn't reach here
        goto    su_exit
;-----------------------------------------------------------
GetReport                                   ;(0x01)
        movlw   BD0DATAL + wValue   ;
        movwf   FSR0L
        moviw   FSR0++
        movwf   DescriptorIndex     ;wValue => Index
        movfw   INDF0
        movwf   DescriptorType      ;wValueHigh => Type
        movlw   BD0DATAL + wLength
        movwf   FSR0L
        movfw   INDF0
        movwf   Data_wLength        ;wLength => max length

        movlw   REPORT_TYPE_INPUT
        xorwf   DescriptorType,0
        btfsc   STATUS,Z
        goto    getInputReport
        movlw   REPORT_TYPE_FEATURE
        xorwf   DescriptorType,0
        btfsc   STATUS,Z
        goto    getFeatureReport
        call    Stall_EP0_InBuffer
        goto    su_exit

getInputReport
        movlw   BD1DATAL
        movwf   FSR0L
        banksel IN
        movfw   IN              ;  DATA: DEVICE TO HOST
        movwi   FSR0++

        movlw   0x01            ;byte count
        movwf   Data_wLength
        call    SendData

        movlw   GET_REPORT
        movwf   USB_dev_req
        goto    su_exit

getFeatureReport
        call    Stall_EP0_InBuffer
        goto    su_exit
;===========================================================================
GetIdle                                     ;(0x02)
        call    Stall_EP0_InBuffer
        goto    su_exit
;===========================================================================
GetProtocol                                 ;(0x03)
        call    Stall_EP0_InBuffer
        goto    su_exit
;===========================================================================
SetReport                                   ;(0x09)
        movlw   SET_REPORT
        movwf   USB_dev_req
        goto    su_exit
StoreReport
        movlw   BD0DATAL
        movwf   FSR0L
        moviw   FSR0++
        movwf   OUT
        call    Send_0Len_pkt
        return
;===========================================================================
SetIdle                                     ;(0x0a) ^^^^^^^^^^TODO^^^^^^^^^^^^^^^^
        call    Stall_EP0_InBuffer
;        call    Send_0Len_pkt
        goto    su_exit
;===========================================================================
SetProtocol                                 ;(0x0b)
        call    Send_0Len_pkt
        goto    su_exit
;===========================================================================
send_data_int                               ;put output data into EP1 IN buffer
        movlw   NO_REQUEST                  ;check
        xorwf   EP1_dev_req,0               ;EP1
        btfss   STATUS,Z                    ;not busy
        return
        movlw   BD3DATAL
        movwf   FSR0L               
        movfw   IN              ; data
        movwi   FSR0++

        movlw   BD3CNTL         ;
        movwf   FSR0L
        movlw   0x01            ; => BD3CNT
        movwi   FSR0--

        movlw   0x00            ;set DTSEN => BD1STAT
        movwf   INDF0
        btfsc   TOGGLE,0
        bsf     INDF0,DTS

        bsf     INDF0,UOWN      ;hand over control to SIE
        movlw   INT_IN
        movwf   EP1_dev_req
        incf    TOGGLE
        return
;==========================================
;   >>>>>>>>>>>  EP1  <<<<<<<<<<<<                                                                      >>>>>> EP1 <<<<<<
;==========================================                                     =============================================================
EP_1
        banksel UCON
        movlw   0x04                ;DIR mask
        andwf   USTAT,0
        btfsc   STATUS,Z            ;check Direction
        goto    EP1_Out

EP1_In
        movlw   NO_REQUEST
        movwf   EP1_dev_req
        return
;---------------------------------------------------
EP1_Out
        call    Reset_EP1_OutBuffer
        movlw   NO_REQUEST
        movwf   EP1_dev_req
        return
;*****************************************************
    #include "Descriptors.inc"
;    #include "Test.inc"
;*****************************************************
		end
