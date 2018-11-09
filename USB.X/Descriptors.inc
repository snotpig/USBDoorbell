GetDescriptor                   ;(0x06)
;        call    incGD;<-----------<<<<<<<<<<
        movlw   GET_DESCRIPTOR
        movwf   USB_dev_req         ;set current request

        movlw   BD0DATAL + wValue   ;get descriptor type/index from SETUP packet
        movwf   FSR0L
        moviw   FSR0++
        movwf   DescriptorIndex     ;wValue => Index
        movfw   INDF0
        movwf   DescriptorType      ;wValueHigh => Type
        movlw   BD0DATAL + wLength
        movwf   FSR0L
        movfw   INDF0
        movwf   Data_wLength        ;wLength => max length

        movlw   BD1DATAL            ;setup
        movwf   FSR0L               ;FSR0

        clrf    DescriptorLength    ;get selected descriptor data
        movlw   DEVICE          
        xorwf   DescriptorType,0
        btfsc   STATUS,Z
        call    DeviceDescriptor
        movlw   CONFIGURATION
        xorwf   DescriptorType,0
        btfsc   STATUS,Z
        call    ConfigurationDescriptor
        movlw   STRING
        xorwf   DescriptorType,0
        btfsc   STATUS,Z
        call    StringDescriptor
        movlw   INTERFACE
        xorwf   DescriptorType,0
        btfsc   STATUS,Z
        call    InterfaceDescriptor
        movlw   ENDPOINT
        xorwf   DescriptorType,0
        btfsc   STATUS,Z
        call    EndpointDescriptor
        movlw   HID
        xorwf   DescriptorType,0
        btfsc   STATUS,Z
        call    HIDDescriptor
        movlw   REPORT
        xorwf   DescriptorType,0
        btfsc   STATUS,Z
        call    ReportDescriptor

        movf    DescriptorLength    ;test for fallthrough
        btfss   STATUS,Z
        goto    sendD
unSupp  movlw   BD1STATL            ;unsupported:
        movwf   FSR0L               ;enable STALL
        bsf     INDF0, BSTALL       ;on IN buffer
        return

sendD   movfw   DescriptorLength    ;If requested length
        subwf   Data_wLength,0      ;is longer than
        movfw   DescriptorLength    ;descriptor length,
        btfsc   STATUS,C            ;set Data_wLength to
        movwf   Data_wLength        ;length of descriptor

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
;--------------------------------------------------------------
DeviceDescriptor
        movlw   DEVDESCBC           ; bLength
        movwi   FSR0++
        movlw   DEVICE              ; bDescriptorType
        movwi   FSR0++
        movlw   USBL                ; bcdUSB (low byte)     v
        movwi   FSR0++
        movlw   USBH                ; bcdUSB (high byte)  >2.0<
        movwi   FSR0++
        movlw   0x00                ; bDeviceClass
        movwi   FSR0++
        movlw   0x00                ; bDeviceSubClass
        movwi   FSR0++
        movlw   0x00                ; bDeviceProtocol
        movwi   FSR0++
        movlw   MAX_PACKET_SIZE     ; bMaxPacketSize
        movwi   FSR0++
        movlw   VIDL                ; idVendor (low byte)      v
        movwi   FSR0++
        movlw   VIDH                ; idVendor (high byte) >Microchip<
        movwi   FSR0++
        movlw   PIDL                ; idProduct (low byte),
        movwi   FSR0++
        movlw   PIDH                ; idProduct (high byte)
        movwi   FSR0++
        movlw   REVL                ; bcdDevice (low byte)
        movwi   FSR0++
        movlw   REVH                ; bcdDevice (high byte)
        movwi   FSR0++
        movlw   0x01                ; iManufacturer
        movwi   FSR0++
        movlw   0x02                ; iProduct
        movwi   FSR0++
        movlw   0x00                ; iSerialNumber (none)
        movwi   FSR0++
        movlw   NUM_CONFIGURATIONS  ; bNumConfigurations
        movwi   FSR0++

        movlw   DEVDESCBC
        movwf   DescriptorLength
        return
;--------------------------------------------------------------
ConfigurationDescriptor
        movlw   CONFDESCBC          ; bLength
        movwi   FSR0++
        movlw   CONFIGURATION       ; bDescriptorType
        movwi   FSR0++
        movlw   TOTALCONFDESCBC     ; wTotalLength (low byte)
        movwi   FSR0++
        movlw   0x00                ; wTotalLength (high byte) 
        movwi   FSR0++
        movlw   NUM_INTERFACES      ; bNumInterfaces
        movwi   FSR0++
        movlw   0x01                ; bConfigurationValue
        movwi   FSR0++
        movlw   0x00                ; iConfiguration (none)
        movwi   FSR0++
        movlw   0xA0                ; bmAttributes (bus powered, remote wakeup)
        movwi   FSR0++
        movlw   0x32                ; bMaxPower (100 mA)
        movwi   FSR0++

        call    InterfaceDescriptor
        call    HIDDescriptor
        call    Endpoint1InDescriptor
        call    Endpoint1OutDescriptor
        movlw   TOTALCONFDESCBC
        movwf   DescriptorLength
        return
;--------------------------------------------------------------
InterfaceDescriptor
        movlw   IFDESCBC             ; bLength      ** INTERFACE **
        movwi   FSR0++
        movlw   INTERFACE            ; bDescriptorType
        movwi   FSR0++
        movlw   0x00                 ; bInterfaceNumber
        movwi   FSR0++
        movlw   0x00                 ; bAlternateSetting
        movwi   FSR0++
        movlw   0x02                 ; bNumEndpoints (exc. EP0)[1_IN & 1_OUT]<<
        movwi   FSR0++
        movlw   USB_HID_CLASS_CODE   ; bInterfaceClass (PID)
        movwi   FSR0++
        movlw   NO_SUBCLASS          ; bInterfaceSubClass
        movwi   FSR0++
        movlw   PROTOCOL_NONE        ; bInterfaceProtocol (vendor specific protocol used)
        movwi   FSR0++
        movlw   0x00                 ; iInterface (none)
        movwi   FSR0++

        movlw   IFDESCBC
        movwf   DescriptorLength
        return
;--------------------------------------------------------------
EndpointDescriptor
        movf    DescriptorIndex
        btfss   STATUS,Z
        goto    Endpoint1OutDescriptor

Endpoint1InDescriptor
        movlw   EPDESCBC            ; bLength       ** ENDPOINT 1 IN**
        movwi   FSR0++
        movlw   ENDPOINT            ; bDescriptorType
        movwi   FSR0++
        movlw   0x81                ; bEndpointAddress
        movwi   FSR0++
        movlw   0x03                ; bmAttributes (Interrupt)
        movwi   FSR0++
        movlw   0x04                ; wMaxPacketSize (low byte)
        movwi   FSR0++
        movlw   0x00                ; wMaxPacketSize (high byte)
        movwi   FSR0++
        movlw   0x0a                ; bInterval (ms @full speed)
        movwi   FSR0++

        movlw   EPDESCBC
        movwf   DescriptorLength
        return
;--------------------
Endpoint1OutDescriptor
        movlw   EPDESCBC            ; bLength       ** ENDPOINT 1 OUT**
        movwi   FSR0++
        movlw   ENDPOINT            ; bDescriptorType
        movwi   FSR0++
        movlw   0x01                ; bEndpointAddress
        movwi   FSR0++
        movlw   0x03                ; bmAttributes (Interrupt)
        movwi   FSR0++
        movlw   0x04                ; wMaxPacketSize (low byte)
        movwi   FSR0++
        movlw   0x00                ; wMaxPacketSize (high byte)
        movwi   FSR0++
        movlw   0x0a                ; bInterval (ms @full speed)
        movwi   FSR0++

        movlw   EPDESCBC
        movwf   DescriptorLength
        return
;--------------------------------------------------------------
StringDescriptor                ;selected by index
        movfw   DescriptorIndex
        xorlw   0
        btfsc   STATUS,Z
        goto    String0
        movfw   DescriptorIndex
        xorlw   1
        btfsc   STATUS,Z
        goto    String1
        movfw   DescriptorIndex
        xorlw   2
        btfsc   STATUS,Z
        goto    String2
        return
;--------------------
String0
        movlw   STR0DESCBC      ; bLength
        movwi   FSR0++
        movlw   STRING          ; bDescriptorType
        movwi   FSR0++
        movlw   0x09            ; wLANGID[0] (low byte)
        movwi   FSR0++
        movlw   0x04            ; wLANGID[0] (high byte)
        movwi   FSR0++

        movlw   STR0DESCBC
        movwf   DescriptorLength
        return
;--------------------
String1
        movlw   STR1DESCBC      ; bLength
        movwi   FSR0++
        movlw   STRING          ; bDescriptorType
        movwi   FSR0++
        movlw   'A'             ;3
        movwi   FSR0++
        movlw   0x00            ;
        movwi   FSR0++
        movlw   'c'             ;5
        movwi   FSR0++
        movlw   0x00            ;
        movwi   FSR0++
        movlw   'e'             ;7
        movwi   FSR0++
        movlw   0x00            ;
        movwi   FSR0++
        movlw   'T'             ;9
        movwi   FSR0++
        movlw   0x00            ;
        movwi   FSR0++
        movlw   'e'             ;b
        movwi   FSR0++
        movlw   0x00            ;
        movwi   FSR0++
        movlw   'c'             ;d
        movwi   FSR0++
        movlw   0x00            ;
        movwi   FSR0++
        movlw   'h'             ;f
        movwi   FSR0++
        movlw   0x00            ;10
        movwi   FSR0++

        movlw   STR1DESCBC
        movwf   DescriptorLength
        return
;--------------------
String2
        movlw   STR2DESCBC      ; bLength
        movwi   FSR0++
        movlw   STRING          ; bDescriptorType
        movwi   FSR0++
        movlw   'D'
        movwi   FSR0++
        movlw   0x00            ;4
        movwi   FSR0++
        movlw   'o'
        movwi   FSR0++
        movlw   0x00            ;6
        movwi   FSR0++
        movlw   'o'
        movwi   FSR0++
        movlw   0x00            ;8
        movwi   FSR0++
        movlw   'r'
        movwi   FSR0++
        movlw   0x00            ;a
        movwi   FSR0++
        movlw   'b'
        movwi   FSR0++
        movlw   0x00            ;c
        movwi   FSR0++
        movlw   'e'
        movwi   FSR0++
        movlw   0x00            ;e
        movwi   FSR0++
        movlw   'l'
        movwi   FSR0++
        movlw   0x00            ;10
        movwi   FSR0++
        movlw   'l'
        movwi   FSR0++
        movlw   0x00            ;12
        movwi   FSR0++

        movlw   STR2DESCBC
        movwf   DescriptorLength
        return
;===========================================================================
;                       HID Descriptors
;===========================================================================
HIDDescriptor
        movlw   HIDDESCBC       ; bLength
        movwi   FSR0++
        movlw   HID             ; bDescriptorType
        movwi   FSR0++
        movlw   0x11            ; bcdHID (low byte)
        movwi   FSR0++
        movlw   0x01            ; bcdHID (high byte)
        movwi   FSR0++
        movlw   0x00            ; bCountryCode
        movwi   FSR0++
        movlw   0x01            ; bNumDescriptors
        movwi   FSR0++
        movlw   REPORT          ; bDescriptorType
        movwi   FSR0++
        movlw   REPORTDESCBC    ; wItemLengthL(byte count of report descriptor) 
        movwi   FSR0++
        movlw   0x00            ; wItemLengthH
        movwi   FSR0++

        movlw   HIDDESCBC
        movwf   DescriptorLength
        return
;--------------------------------------------------------------
ReportDescriptor
        movlw   0x06            ; USAGE PAGE
        movwi   FSR0++
        movlw   0xa0            ; Usage Page (low byte)
        movwi   FSR0++
        movlw   0xff            ; Usage Page (high byte) (vendor defined)
        movwi   FSR0++
        movlw   0x09            ; USAGE
        movwi   FSR0++
        movlw   0x02            ; Usage (vendor defined)
        movwi   FSR0++

        movlw   0xa1            ; COLLECTION
        movwi   FSR0++
        movlw   0x01            ; Collection    (application)
        movwi   FSR0++

        movlw   0x09            ; USAGE
        movwi   FSR0++
        movlw   0x03            ; Usage
        movwi   FSR0++
        movlw   0x15            ; LOGICAL MINIMUM
        movwi   FSR0++
        movlw   0x00            ; Logical Minimum
        movwi   FSR0++
        movlw   0x26            ; LOGICAL MAXIMUM
        movwi   FSR0++
        movlw   0xff            ; Logical Maximum (low byte)
        movwi   FSR0++
        movlw   0x00            ; Logical Maximum (high byte)
        movwi   FSR0++
        movlw   0x75            ; REPORT SIZE
        movwi   FSR0++
        movlw   0x08            ; Report Size
        movwi   FSR0++
        movlw   0x95            ; REPORT COUNT
        movwi   FSR0++
        movlw   0x01            ; Report Count
        movwi   FSR0++
        movlw   0x81            ; INPUT
        movwi   FSR0++
        movlw   0x02            ; (Data, Variable, Absolute)
        movwi   FSR0++

        movlw   0x09            ; USAGE
        movwi   FSR0++
        movlw   0x04            ; Usage
        movwi   FSR0++
        movlw   0x15            ; LOGICAL MINIMUM
        movwi   FSR0++
        movlw   0x00            ; Logical Minimum
        movwi   FSR0++
        movlw   0x26            ; LOGICAL MAXIMUM
        movwi   FSR0++
        movlw   0xff            ; Logical Maximum (low byte)
        movwi   FSR0++
        movlw   0x00            ; Logical Maximum (high byte)
        movwi   FSR0++
        movlw   0x75            ; REPORT SIZE
        movwi   FSR0++
        movlw   0x08            ; Report Size
        movwi   FSR0++
        movlw   0x95            ; REPORT COUNT
        movwi   FSR0++
        movlw   0x01            ; Report Count
        movwi   FSR0++
        movlw   0x91            ; OUTPUT
        movwi   FSR0++
        movlw   0x02            ; (Data, Variable, Absolute)
        movwi   FSR0++

        movlw   0xc0            ; END COLLECTION
        movwi   FSR0++

        movlw   REPORTDESCBC
        movwf   DescriptorLength
        return

;--------------------

