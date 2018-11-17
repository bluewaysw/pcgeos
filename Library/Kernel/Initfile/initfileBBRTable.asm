COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:
MODULE:
FILE:		initFileNikeData.asm

AUTHOR:		Muhammad Mohsin Hussain, Oct 13, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MMH	10/13/94   	Initial revision


DESCRIPTION:
	This file contains the BatterBackedRamTable for nike and other
	char strings for the table. All this stuff must be in code segment
	else the code needs to change if this is put in another segment.

	$Id: initfileBBRTable.asm,v 1.1 97/04/05 01:18:03 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef NIKE_GERMAN
_NIKE_GERMAN = 1
else
_NIKE_GERMAN = 0
endif

ifdef NIKE_DUTCH
_NIKE_DUTCH = 1
else
_NIKE_DUTCH = 0
endif

kinit	segment	resource

include	Objects/gViewCC.def

;------------------------------------------------------------------------------
;		Constants
;------------------------------------------------------------------------------

RTC_ADDR			equ	378h
RTC_DATA			equ	379h
BBR_SIZE			equ	80h

GEOS_BBR_FIRST_BYTE		equ	40h
GEOS_BBR_INIT_FLAG_BYTE		equ	7fh
GEOS_BBR_SIZE			equ	40h

BBR_INITIALIZED			equ	04Ch

END_OF_TABLE			equ	-1
NUM_BITS_IN_WORD		equ	16

; Identifiers for NumericWord type
NWT_HIGH_WORD			equ	1
NWT_BIT_HIGH_WORD		equ	2
NWT_MULTIPLE			equ	3

;------------------------------------------------------------------------------
;		Structures and Enum
;------------------------------------------------------------------------------

BatteryBackedRamType	etype	byte, 0 ,2
BBR_NUMERIC		enum	BatteryBackedRamType
BBR_BOOLEAN		enum	BatteryBackedRamType
BBR_STRING		enum	BatteryBackedRamType
BBR_STRINGSECTION	enum	BatteryBackedRamType
BBR_TABLE		enum	BatteryBackedRamType
BBR_NUMERICWORD		enum	BatteryBackedRamType
BBR_STRUCT		enum	BatteryBackedRamType


BatteryBackedRamTableEntry	struct
	BBR_byteLocation	byte
	BBR_bitOffset		byte
	BBR_bitWidth		byte
	BBR_category		nptr.char
	BBR_key			nptr.char
	BBR_type		BatteryBackedRamType
	BBR_tableLength		byte	
	BBR_value		nptr	
BatteryBackedRamTableEntry	ends


ScrollBarStruct	struct
    scale		word
    attrs		GenViewControlAttrs
ScrollBarStruct	ends

COMMENT @
    GVCI_scale		word	100
    GVCI_attrs		GenViewControlAttrs	\
			mask GVCA_SHOW_HORIZONTAL or mask GVCA_SHOW_VERTICAL \
			or mask GVCA_APPLY_TO_ALL
@


;------------------------------------------------------------------------------
;		InitFile TestStuff
;------------------------------------------------------------------------------

nil			char	"0"

TestFile		char	"NikeIniFile",0
zeroBuffer		word	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

;------------------------------------------------------------------------------
;		InitFile Categories in alpha order
;------------------------------------------------------------------------------

clockCategory		char	"clock options",0
dClockCategory		char	"digital clock",0
geoCalcCategory		char	"geocalc ",0
lightsOutCategory	char	"Lights Out",0
mainMenuCategory	char	"MAIN MENU",0
myModemCategory		char	"My Modem",0
printerCategory		char	"installedPrinter",0
UICategory		char 	"ui",0
writeCategory		char	"write",0

;------------------------------------------------------------------------------
;		InitFile Keys in alpha order
;------------------------------------------------------------------------------

autosaveKey		char	"autosave",0
autosaveTimeKey		char	"autosaveTime",0
backgroundColor		char	"backgroundColor",0
backgroundMask		char	"backgroundMask",0
baudRateKey		char	"baudRate",0
clockXPosKey		char	"fixedX",0
clockYPosKey		char	"fixedY",0
clockJustificationKey	char	"justification",0
ctsKey			char	"cts",0
dcdKey			char	"dcd",0
dsrKey			char	"dsr",0
dtrKey			char	"dtr",0
evenKey			char	"even",0
execOnStartup		char	"execOnStartup",0
formatKey		char	"format",0
handShakeKey		char	"handshake",0
hardwareKey		char	"hardware",0
intervalKey		char	"interval",0
lightsOutLauncherKey	char	"Lights Out Launcher",0
mainMenuTitle		char	"title",0
markKey			char	"mark",0
miscSettingsKey		char	"miscSettings",0
noneKey			char	"none",0
oddKey			char	"odd",0
overstrikeKey		char	"overstrikeMode",0
parityKey		char	"parity",0
rtsKey			char	"rts",0
screenBlankerKey	char	"screenBlanker",0
screenSaverTimeKey	char	"screenBlankerTimeout",0
showBarsKey		char	"showbars",0
softwareKey		char	"software",0
soundKey		char	"sound",0
spaceKey		char	"space",0
specificKey		char	"specific",0
stopBitsKey		char	"stopBits",0
stopLocalKey		char	"stopLocal",0
stopRemoteKey		char	"stopRemote",0
textRulerKey		char	"textRulerAttrs",0
toneDialKey		char	"toneDial",0
viewControlKey		char	"viewControlExtra",0
wordLengthKey		char	"wordLength",0

onScClock		char 	"OnScreenClock",0
EC  < clockExecKey	char	"Desk Accessories\\\\EC Clock", 0	>
NEC < clockExecKey	char	"Desk Accessories\\\\Clock", 0		>

if _NIKE_GERMAN
dancingLinesKey		char	"Tanzlinien",0
defaultBlankerKey	char	"Bildschirm dunkel",0
demonstrationKey	char	"Demonstration",0

elseif _NIKE_DUTCH
dancingLinesKey		char	"Dansende Lijnen",0
defaultBlankerKey	char	"Schermleegmaker",0
demonstrationKey	char	"Demonstratie",0

else
EC  < dancingLinesKey	char	"EC Dancing Lines",0		>
NEC < dancingLinesKey	char	"Dancing Lines",0		>
defaultBlankerKey	char	"Screen Blanker",0
demonstrationKey	char	"Demonstration",0
endif

paperSourceKey		char	"paperSource",0
inkSaverKey		char	"inkSaver",0
pageWidthKey		char	"width",0
pageHeightKey		char	"height",0
pageLayoutKey		char	"layout",0

;------------------------------------------------------------------------------
;		InitFile Tables Elements
;------------------------------------------------------------------------------
; CLOCK TABLE KEYS

Int1     char    "1",0
Int1_5   char    "1.5",0
Int2     char    "2",0
Int16    char    "16",0
Int20    char    "20",0
Int60    char    "60",0
Int300   char    "300",0
Int600   char    "600",0
Int1200  char    "1200",0
Int2400  char    "2400",0
Int4800  char    "4800",0
Int9600  char    "9600",0
Int19200 char    "19200",0

;------------------------------------------------------------------------------
;		InitFile Tables
;------------------------------------------------------------------------------

BaudRateTable		word \
		offset	Int300,	
		offset	Int600,	
		offset	Int1200,	
		offset	Int2400,
		offset	Int4800,
		offset	Int9600,
		offset	Int19200
word		END_OF_TABLE			; end of table

ParityTable		word \
		offset	noneKey,
		offset	evenKey,
		offset	oddKey,
		offset	markKey,
		offset	spaceKey
word		END_OF_TABLE			; end of table

HandshakeTable		word \
		offset	noneKey,
		offset	hardwareKey,
		offset	softwareKey
word		END_OF_TABLE			; end of table

StopBitsTable		word \
		offset	Int1,
		offset	Int1_5,
		offset	Int2	
word		END_OF_TABLE			; end of table


StopRemoteTable		word \
		offset	dtrKey,
		offset	rtsKey
word		END_OF_TABLE			; end of table

StopLocalTable		word \
		offset	ctsKey,
		offset	dcdKey,
		offset	dsrKey
word		END_OF_TABLE			; end of table

;execonstartup TO BE DONE

;formatTable	16,20
ClockFormatTable	word \
		offset	Int16,
		offset	Int20
word		END_OF_TABLE			; end of table

;intervalTable	1,60
ClockIntervalTable	word \
		offset	Int1,
		offset	Int60
word		END_OF_TABLE			; end of table

;** Don't change the order of this table there is code in InitFileHack
;   which depends on it **
;(mohsin's order is dancing, blanker, demo)
SpecificTable		word \
		offset	demonstrationKey,
		offset	dancingLinesKey,
		offset	defaultBlankerKey
word		END_OF_TABLE			; end of table


;------------------------------------------------------------------------------
;		BatteryBackedRamTable in order of Table in Spec
;------------------------------------------------------------------------------

BatteryBackedRamTable	BatteryBackedRamTableEntry \
	< ; Printer - paper source
		64,			;BBR_byteLocation
		0,			;BBR_bitOffset
		8,			;BBR_bitWidth
		offset printerCategory,	;BBR_category
		offset paperSourceKey,	;BBR_key
		BBR_NUMERIC,		;BBR_type
		0,			;BBR_tableLength
		offset nil		;BBR_value
	>,
	< ; Printer - ink saver
		65,			;BBR_byteLocation
		0,			;BBR_bitOffset
		8,			;BBR_bitWidth
		offset printerCategory,	;BBR_category
		offset inkSaverKey,	;BBR_key
		BBR_NUMERIC,		;BBR_type
		0,			;BBR_tableLength
		offset nil		;BBR_value
	>,
	< ; Printer - page width
		66,			;BBR_byteLocation
		0,			;BBR_bitOffset
		16,			;BBR_bitWidth
		offset printerCategory,	;BBR_category
		offset pageWidthKey,	;BBR_key
		BBR_NUMERIC,		;BBR_type
		0,			;BBR_tableLength
		offset nil		;BBR_value
	>,
	< ; Printer - page height
		68,			;BBR_byteLocation
		0,			;BBR_bitOffset
		16,			;BBR_bitWidth
		offset printerCategory,	;BBR_category
		offset pageHeightKey,	;BBR_key
		BBR_NUMERIC,		;BBR_type
		0,			;BBR_tableLength
		offset nil		;BBR_value
	>,
	< ; Printer - page layout
		70,			;BBR_byteLocation
		0,			;BBR_bitOffset
		16,			;BBR_bitWidth
		offset printerCategory,	;BBR_category
		offset pageLayoutKey,	;BBR_key
		BBR_NUMERIC,		;BBR_type
		0,			;BBR_tableLength
		offset nil		;BBR_value
	>,
;------------------------------------------------------------------------------
;			Screen Saver
;------------------------------------------------------------------------------
	< ; screen saver 
		90,			;BBR_byteLocation
		7,			;BBR_bitOffset	
		1,			;BBR_bitWidth	
		offset UICategory,	;BBR_category	
		offset screenBlankerKey,;BBR_key		
		BBR_BOOLEAN,		;BBR_type	
		0,			;BBR_tableLength
		offset	nil		;BBR_value	
	>,
	< ; SpecificTable
		91,			;BBR_byteLocation
		6,			;BBR_bitOffset	
		2,			;BBR_bitWidth	
		offset	lightsOutCategory,	;BBR_category	
		offset	specificKey,	;BBR_key		
		BBR_TABLE,		;BBR_type	
		3,			;BBR_tableLength
		offset	SpecificTable	;BBR_value	
	>,
	< ;Screen saver time 1-30
		90,			;BBR_byteLocation
		0,			;BBR_bitOffset	
		5,			;BBR_bitWidth	
		offset	UICategory,	;BBR_category	
		offset	screenSaverTimeKey,	;BBR_key		
		BBR_NUMERIC,		;BBR_type	
		0,			;BBR_tableLength
		offset nil		;BBR_value	
	>,
;------------------------------------------------------------------------------
;				Preferences
;------------------------------------------------------------------------------
	< ;overstrikeMode
		90,			;BBR_byteLocation
		5,			;BBR_bitOffset	
		1,			;BBR_bitWidth	
		offset	UICategory,	;BBR_category	
		offset	overstrikeKey,	;BBR_key		
		BBR_BOOLEAN,		;BBR_type	
		0,			;BBR_tableLength
		offset	nil		;BBR_value	
	>,
	< ;sound
		90,			;BBR_byteLocation
		6,			;BBR_bitOffset	
		1,			;BBR_bitWidth	
		offset	UICategory,	;BBR_category	
		offset	soundKey,	;BBR_key		
		BBR_BOOLEAN,		;BBR_type	
		0,			;BBR_tableLength
		offset	nil		;BBR_value	
	>,
	< ; Document safeguarding
		91,			;BBR_byteLocation
		0,			;BBR_bitOffset	
		1,			;BBR_bitWidth	
		offset	UICategory,	;BBR_category	
		offset	autosaveKey,	;BBR_key		
		BBR_BOOLEAN,		;BBR_type	
		0,			;BBR_tableLength
		offset nil			;BBR_value	
	>,
	< ; Document safeguarding time 1-18 x 60
		91,			;BBR_byteLocation
		1,			;BBR_bitOffset	
		5,			;BBR_bitWidth	
		offset	UICategory,	;BBR_category	
		offset  autosaveTimeKey,	;BBR_key		
		BBR_NUMERICWORD,	;BBR_type	
		NWT_MULTIPLE,		;BBR_tableLength
		60			;BBR_value	
	>,

;-----------------------------Modem Pref --------------------------------------
	< ; modem tone/pulse
		92,			;BBR_byteLocation
		0,			;BBR_bitOffset	
		1,			;BBR_bitWidth	
		offset	myModemCategory,;BBR_category	
		offset	toneDialKey,	;BBR_key		
		BBR_BOOLEAN,		;BBR_type	
		0,			;BBR_tableLength
		offset nil		;BBR_value	
	>,
	< ; modem baudrate
		92,			;BBR_byteLocation
		1,			;BBR_bitOffset	
		3,			;BBR_bitWidth	
		offset	myModemCategory,;BBR_category	
		offset	baudRateKey,	;BBR_key		
		BBR_TABLE,		;BBR_type	
		7,			;BBR_tableLength
		offset	BaudRateTable	;BBR_value	
	>,
	< ; modem parity  
		92,			;BBR_byteLocation
		4,			;BBR_bitOffset	
		3,			;BBR_bitWidth	
		offset	myModemCategory,;BBR_category	
		offset	parityKey,	;BBR_key		
		BBR_TABLE,		;BBR_type	
		5,			;BBR_tableLength
		offset	ParityTable	;BBR_value	
	>,
	< ; modem word length 5-8  
		93,			;BBR_byteLocation
		0,			;BBR_bitOffset	
		4,			;BBR_bitWidth	
		offset	myModemCategory,;BBR_category	
		offset	wordLengthKey,	;BBR_key		
		BBR_NUMERIC,		;BBR_type	
		0,			;BBR_tableLength
		offset	nil		;BBR_value	
	>,
	< ; modem stopBits = 1, 1.5, 2
		93,			;BBR_byteLocation
		4,			;BBR_bitOffset	
		2,			;BBR_bitWidth	
		offset	myModemCategory,;BBR_category	
		offset	stopBitsKey,	;BBR_key		
		BBR_TABLE,		;BBR_type	
		3,			;BBR_tableLength
		offset	StopBitsTable	;BBR_value	
	>,
	< ; modem handshake 
		94,			;BBR_byteLocation
		0,			;BBR_bitOffset	
		3,			;BBR_bitWidth	
		offset	myModemCategory,;BBR_category	
		offset	handShakeKey,	;BBR_key		
		BBR_STRINGSECTION,		;BBR_type	
		3,			;BBR_tableLength
		offset	HandshakeTable	;BBR_value	
	>,
	< ; modem stopremote
		94,			;BBR_byteLocation
		3,			;BBR_bitOffset	
		2,			;BBR_bitWidth	
		offset	myModemCategory,;BBR_category	
		offset	stopRemoteKey,	;BBR_key		
		BBR_STRINGSECTION,		;BBR_type	
		2,			;BBR_tableLength
		offset	StopRemoteTable	;BBR_value	
	>,
	< ; modem stopLocal
		94,			;BBR_byteLocation
		5,			;BBR_bitOffset	
		3,			;BBR_bitWidth	
		offset	myModemCategory,;BBR_category	
		offset	stopLocalKey,	;BBR_key		
		BBR_STRINGSECTION,	;BBR_type	
		3,			;BBR_tableLength
		offset	StopLocalTable	;BBR_value	
	>,
;------------------------------------------------------------------------------
;				GeoWrite
; Note : For BBR_NUMERICWORD, value represents the position at which the
; width # bits hold the value. 
;------------------------------------------------------------------------------
	<	; all the menu bars
		95,			;BBR_byteLocation
		2,			;BBR_bitOffset	
		5,			;BBR_bitWidth	
		offset writeCategory,	;BBR_category	
		offset showBarsKey,	;BBR_key		
		BBR_NUMERICWORD,	;BBR_type	
		NWT_HIGH_WORD,		;BBR_tableLength
		12			;BBR_value 
	>,
	<	;show invisibles
		95,			;BBR_byteLocation
		7,			;BBR_bitOffset	
		1,			;BBR_bitWidth	
		offset writeCategory,	;BBR_category	
		offset miscSettingsKey,	;BBR_key		
		BBR_NUMERICWORD,	;BBR_type	
		NWT_BIT_HIGH_WORD,	;BBR_tableLength
		14			;BBR_value	
	>,
	<	; snap ruler & allign ruler
		96,			;BBR_byteLocation
		0,			;BBR_bitOffset	
		2,			;BBR_bitWidth	
		offset writeCategory,	;BBR_category	
		offset textRulerKey,	;BBR_key		
		BBR_NUMERICWORD,	;BBR_type	
		NWT_HIGH_WORD,		;BBR_tableLength
		15			;BBR_value	
	>,
	<	; 96 2,3 for scrolbars
		96,			;BBR_byteLocation
		2,			;BBR_bitOffset	
		2,			;BBR_bitWidth	
		offset writeCategory,	;BBR_category	
		offset viewControlKey,	;BBR_key		
		BBR_STRUCT,		;BBR_type	
		0,			;BBR_tableLength
		offset	nil		;BBR_value 
	>,
;------------------------------------------------------------------------------
;				SpreadSheet
;------------------------------------------------------------------------------

	<	; all the menu bars
		97,			;BBR_byteLocation
		2,			;BBR_bitOffset	
		5,			;BBR_bitWidth	
		offset geoCalcCategory,	;BBR_category	
		offset showBarsKey,	;BBR_key		
		BBR_NUMERIC,		;BBR_type	
		0,			;BBR_tableLength
		offset nil		;BBR_value	
	>,
	<	; 97 0,1 for scrolbars
		97,			;BBR_byteLocation
		0,			;BBR_bitOffset	
		2,			;BBR_bitWidth	
		offset geoCalcCategory,	;BBR_category	
		offset viewControlKey,	;BBR_key		
		BBR_STRUCT,		;BBR_type	
		0,			;BBR_tableLength
		offset nil		;BBR_value 
	>,
;------------------------------------------------------------------------------
;				CLOCK
;------------------------------------------------------------------------------
	<	; auto start
		99,			;BBR_byteLocation
		0,			;BBR_bitOffset	
		1,			;BBR_bitWidth	
		offset UICategory,	;BBR_category	
		offset onScClock,	;BBR_key		
		BBR_BOOLEAN,		;BBR_type	
		0,			;BBR_tableLength
		offset	nil		;BBR_value	
	>,
	<	; format
		99,			;BBR_byteLocation
		1,			;BBR_bitOffset	
		1,			;BBR_bitWidth	
		offset dClockCategory,	;BBR_category	
		offset formatKey,	;BBR_key		
		BBR_TABLE,		;BBR_type	
		2,			;BBR_tableLength
		offset ClockFormatTable	;BBR_value	
	>,
	<	; show secs/ interval
		99,			;BBR_byteLocation
		4,			;BBR_bitOffset	
		1,			;BBR_bitWidth	
		offset clockCategory,	;BBR_category	
		offset intervalKey,	;BBR_key		
		BBR_TABLE,		;BBR_type	
		2,			;BBR_tableLength
		offset ClockIntervalTable	;BBR_value	
	>,
	<	; x position of clock
		100,			;BBR_byteLocation
		0,			;BBR_bitOffset
		16,			;BBR_bitWidth
		offset clockCategory,	;BBR_category
		offset clockXPosKey,	;BBR_key
		BBR_NUMERIC,		;BBR_type
		0,			;BBR_tableLength
		offset nil		;BBR_value
	>,
	<	; y position of clock
		102,			;BBR_byteLocation
		0,			;BBR_bitOffset
		16,			;BBR_bitWidth
		offset clockCategory,	;BBR_category
		offset clockYPosKey,	;BBR_key
		BBR_NUMERIC,		;BBR_type
		0,			;BBR_tableLength
		offset nil		;BBR_value
	>,
	<	; justification of clock position
		104,			;BBR_byteLocation
		0,			;BBR_bitOffset
		16,			;BBR_bitWidth
		offset clockCategory,	;BBR_category
		offset clockJustificationKey,	;BBR_key
		BBR_NUMERIC,		;BBR_type
		0,			;BBR_tableLength
		offset nil		;BBR_value
	>,

;------------------------------------------------------------------------------
;				MAIN MENU
;------------------------------------------------------------------------------
	<
		106,			;BBR_byteLocation
		0,			;BBR_bitOffset	
		4,			;BBR_bitWidth	
		offset mainMenuCategory,;BBR_category	
		offset backgroundColor,	;BBR_key		
		BBR_NUMERIC,		;BBR_type	
		0,			;BBR_tableLength
		offset nil		;BBR_value	
	>,
	<
		106,			;BBR_byteLocation
		4,			;BBR_bitOffset	
		4,			;BBR_bitWidth	
		offset mainMenuCategory,;BBR_category	
		offset backgroundMask,	;BBR_key		
		BBR_NUMERIC,		;BBR_type	
		0,			;BBR_tableLength
		offset nil		;BBR_value	
	>,
	<
		107, 			;BBR_byteLocation
		0,			;BBR_bitOffset	
		20*8,			;BBR_bitWidth	
		offset mainMenuCategory,;BBR_category	
		offset mainMenuTitle,	;BBR_key		
		BBR_STRING,		;BBR_type	
		0,			;BBR_tableLength
		offset nil		;BBR_value	
	>
word	END_OF_TABLE			; end of table

; **************************************************
;	DON'T CHANGE THE ORDER OF THIS TABLE 
;     	CODE IN BBRWriteInitFileHack DEPENDS ON IT
; **************************************************

BBRHackTable	BatteryBackedRamTableEntry \
	<	; for execOnStartup add an entry clock app
		99,			;BBR_byteLocation
		0,			;BBR_bitOffset	
		1,			;BBR_bitWidth	
		offset UICategory,	;BBR_category	
		offset execOnStartup,	;BBR_key		
		BBR_BOOLEAN,		;BBR_type	
		0,			;BBR_tableLength
		offset clockExecKey	;BBR_value	
	>,
	<	; the next 3 entries r for Lights out launcher / screen saver 
		90,			;BBR_byteLocation
		7,			;BBR_bitOffset	
		1,			;BBR_bitWidth	
		offset UICategory,	;BBR_category	
		offset screenBlankerKey,;BBR_key		
		BBR_BOOLEAN,		;BBR_type	
		0,			;BBR_tableLength
		offset	nil		;BBR_value	
	>,
	< ; SpecificTable
		91,			;BBR_byteLocation
		6,			;BBR_bitOffset	
		2,			;BBR_bitWidth	
		offset	lightsOutCategory,;BBR_category	
		offset	specificKey,	;BBR_key		
		BBR_TABLE,		;BBR_type	
		3,			;BBR_tableLength
		offset	SpecificTable	;BBR_value	
	>,
	<	
		90,			;BBR_byteLocation put addr of
		7,			;BBR_bitOffset	
		1,			;BBR_bitWidth	
		offset UICategory,	;BBR_category	
		offset execOnStartup,	;BBR_key		
		BBR_BOOLEAN,		;BBR_type	
		0,			;BBR_tableLength
		offset lightsOutLauncherKey;BBR_value	
	>
word	END_OF_TABLE			; end of table

kinit	ends
