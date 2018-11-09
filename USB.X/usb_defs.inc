#define	NUM_CONFIGURATIONS	1
#define	NUM_INTERFACES		1
#define NUM_STRINGS			2
#define MAX_PACKET_SIZE		0x40	; maximum packet size for low-speed peripherals is 8 bytes, for full-speed peripherals it can be 8, 16, 32, or 64 bytes
#define UPDATE_PERIOD       0x03    ; x4 ms
#define OUT_REPORT_SIZE     0x02
#define IN_REPORT_SIZE      0x02

; Define the states that the USB interface can be in
#define	POWERED_STATE	0x00
#define	DEFAULT_STATE	0x01
#define	ADDRESS_STATE	0x02
#define	CONFIG_STATE	0x03

; Define the states for Control EndPoints
#define	EP_IDLE_STATE		0x00
#define	EP_SETUP_STATE		0x01
#define	EP_DISABLED_STATE	0xff

#define	ENDPT_DISABLED		0x00
#define ENDPT_IN_ONLY		0x12
#define ENDPT_OUT_ONLY		0x14
#define ENDPT_CONTROL		0x16	; enable for in, out and setup
#define ENDPT_NON_CONTROL	0x1E	; enable for in, and out

#define INT_STAT_MASK_RESET         0x01
#define INT_STAT_MASK_ERROR         0x02
#define INT_STAT_MASK_TOKEN_DONE	0x04
#define INT_STAT_MASK_SLEEP         0x08
#define INT_STAT_MASK_STALL         0x10

#define TOKEN_OUT	(0x01<<2)
#define TOKEN_ACK	(0x02<<2)
#define TOKEN_IN	(0x09<<2)
#define TOKEN_SETUP	(0x0D<<2)

; Define buffer descriptor table register mapping for no ping-pong buffers
#define BD0STATL    0x00
#define BD0STATH    0x20
#define BD0CNTL		0x01
#define BD0CNTH		0x20
#define BD0ADRLL	0x02
#define BD0ADRLH	0x20
#define BD0ADRHL	0x03
#define BD0ADRHH	0x20
#define BD0DATAL	0x40
#define BD0DATAH	0x20
#define BD1STATL    0x04
#define BD1STATH    0x20
#define BD1CNTL		0x05
#define BD1CNTH		0x20
#define BD1ADRLL	0x06
#define BD1ADRLH	0x20
#define BD1ADRHL	0x07
#define BD1ADRHH	0x20
#define BD1DATAL	0x80
#define BD1DATAH	0x20
#define BD2STATL    0x08
#define BD2STATH    0x20
#define BD2CNTL		0x09
#define BD2CNTH		0x20
#define BD2ADRLL	0x0a
#define BD2ADRLH	0x20
#define BD2ADRHL	0x0b
#define BD2ADRHH	0x20
#define BD2DATAL	0xc0
#define BD2DATAH	0x20
#define BD3STATL    0x0c
#define BD3STATH    0x20
#define BD3CNTL		0x0d
#define BD3CNTH		0x20
#define BD3ADRLL	0x0e
#define BD3ADRLH	0x20
#define BD3ADRHL	0x0f
#define BD3ADRHH	0x20
#define BD3DATAL	0xe0
#define BD3DATAH	0x20

#define BSTALL      0x02
#define DTSEN       0x03
#define DTS         0x06
#define	UOWN		0x07

; offsets from the beginning of the Buffer Descriptor
#define BYTECOUNT	0x01
#define	ADDRESSL	0x02
#define ADDRESSH	0x03

; standard descriptor types
#define	DEVICE          1
#define	CONFIGURATION	2
#define	STRING          3
#define	INTERFACE       4
#define	ENDPOINT        5

; descriptor byte counts
#define DEVDESCBC       0x12
#define CONFDESCBC      0x09
#define IFDESCBC        0x09
#define EPDESCBC        0x07
#define STR0DESCBC      0x04
#define STR1DESCBC      0x10
#define STR2DESCBC      0x12
#define INTINDESCBC     0x07
#define HIDDESCBC       0x09
#define REPORTDESCBC    0x22
#define JSREPORTDESCBC  0x2b
#define TOTALCONFDESCBC CONFDESCBC + IFDESCBC + HIDDESCBC + EPDESCBC + EPDESCBC

; HID class descriptor types
#define HID			0x21
#define REPORT		0x22
#define PHYSICAL	0x23

; offsets from the beginning of the setup data record
#define	bmRequestType	0x00
#define	bRequest        0x01
#define	wValue          0x02
#define	wValueHigh      0x03
#define	wIndex          0x04
#define	wIndexHigh      0x05
#define	wLength         0x06
#define	wLengthHigh     0x07

; Standard USB requests
#define NO_REQUEST          0xFF
#define	GET_STATUS          0x00
#define	CLEAR_FEATURE       0x01
#define	SET_FEATURE         0x03
#define	SET_ADDRESS         0x05
#define	GET_DESCRIPTOR      0x06
#define SET_DESCRIPTOR      0x07
#define	GET_CONFIGURATION	0x08
#define	SET_CONFIGURATION	0x09
#define	GET_INTERFACE       0x0A
#define	SET_INTERFACE       0x0B
#define SYNCH_FRAME         0x0C
#define TEST                0xfa; for test only
#define INT_IN              0xfb; non-standard
#define INT_OUT             0xfc; non-standard

; HID Class requests
#define GET_REPORT		0x01
#define GET_IDLE		0x02
#define GET_PROTOCOL	0x03
#define SET_REPORT		0x09
#define SET_IDLE		0x0A
#define SET_PROTOCOL	0x0B

#define REPORT_TYPE_INPUT   0x01
#define REPORT_TYPE_FEATURE 0x03

#define	GET_STRING_DESCRIPTOR	0x66
#define	HID_SET_REPORT          0x21
#define	VEND_SET_MEMORY         0x80

#define EP0				0x00 << 3
#define EP1				0x01 << 3
#define EP2				0x02 << 3

#define STANDARD		0x00 << 5
#define CLASS			0x01 << 5
#define VENDOR			0x02 << 5

#define RECIPIENT_DEVICE	0x00
#define RECIPIENT_INTERFACE	0x01
#define RECIPIENT_ENDPOINT	0x02

#define HOSTTODEVICE        0x00
#define DEVICETOHOST        0x80
#define HOSTTOINTERFACE     0x01
#define INTERFACETOHOST     0x81
#define HOSTTOENDPOINT      0x02
#define ENDPOINTTOHOST      0x82

#define DEVICE_REMOTE_WAKEUP	0x01
#define ENDPOINT_HALT			0x00

;/////////////////////////////////////////////////////////////////////
;// Interface Descriptor values
;// bInterfaceClass values
#define USB_HID_CLASS_CODE                  0x03
#define USB_MASS_STORAGE_CLASS_CODE         0x08
#define USB_HUB_CLASS_CODE                  0x09

;// bInterfaceSubClass value for HID
#define NO_SUBCLASS                         0x00
#define BOOT_INTERFACE_SUBCLASS             0x01

;// bInterfaceSubClass value for MSC
#define RBC_SUBCLASS                        0x01
#define DVD_SUBCLASS                        0x02
#define TAPE_SUBCLASS                       0x03
#define UFI_SUBCLASS                        0x04
#define FDD_SUBCLASS                        0x05
#define SCSI_SUBCLASS                       0x06

;// bInterfaceProtocol values for HID
#define PROTOCOL_NONE                       0x00
#define PROTOCOL_KEYBOARD                   0x01
#define PROTOCOL_MOUSE                      0x02

