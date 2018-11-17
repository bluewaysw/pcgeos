COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GlobalPC 1998 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Cyber16 Video Driver
FILE:		cyber16StringTab.asm

AUTHOR:		Jim DeFrisco, 8/1/90

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	8/1/90		Initial revision


DESCRIPTION:
	This file holds the device string tables
		

	$Id: cyber16StringTab.asm,v 1.3$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

	; these are the device enums
if	ALLOW_BIG_MOUSE_POINTER
VD_IGS_CYBER_PRO_640x480_16_SP	enum	VideoDevice, 0
VD_IGS_CYBER_PRO_640x480_16_BP	enum	VideoDevice
VD_IGS_CYBER_PRO_800x600_16_SP	enum	VideoDevice
VD_IGS_CYBER_PRO_800x600_16_BP	enum	VideoDevice
if	ALLOW_1Kx768_16
VD_IGS_CYBER_PRO_1Kx768_16_SP	enum	VideoDevice
VD_IGS_CYBER_PRO_1Kx768_16_BP	enum	VideoDevice
endif	; ALLOW_1Kx768_16
else
VD_IGS_CYBER_PRO_640x480_16	enum	VideoDevice, 0
VD_IGS_CYBER_PRO_800x600_16	enum	VideoDevice
if	ALLOW_1Kx768_16
VD_IGS_CYBER_PRO_1Kx768_16	enum	VideoDevice
endif	; ALLOW_1Kx768_16
endif	; ALLOW_BIG_MOUSE_POINTER


	; the first thing in the segment is the DriverExtendedInfoTable
	; structure
DriverExtendedInfoTable <
			{},			; lmem header added by Esp
			VideoDevice/2,			; DEIT_numDevices
			offset Cyber16StringTable,	; DEIT_nameTable
			0				; DEIT_infoTable
			>


	; this is the table of near pointers to the device strings
if	ALLOW_BIG_MOUSE_POINTER
Cyber16StringTable lptr.char \
			IGSCP640x480SPString,	;VD_IGS_CYBER_PRO_640x480_16_SP
			IGSCP640x480BPString,	;VD_IGS_CYBER_PRO_640x480_16_BP
			IGSCP800x600SPString,	;VD_IGS_CYBER_PRO_800x600_16_SP
			IGSCP800x600BPString,	;VD_IGS_CYBER_PRO_800x600_16_BP
if	ALLOW_1Kx768_16
			IGSCP1Kx768SPString,	;VD_IGS_CYBER_PRO_1Kx768_16_SP
			IGSCP1Kx768BPString,	;VD_IGS_CYBER_PRO_1Kx768_16_BP
endif	; ALLOW_1Kx768_16
			0			;table terminator
else
Cyber16StringTable lptr.char \
			IGSCP640x480String,	; VD_IGS_CYBER_PRO_640x480_16
			IGSCP800x600String,	; VD_IGS_CYBER_PRO_800x600_16
if	ALLOW_1Kx768_16
			IGSCP1Kx768String,	; VD_IGS_CYBER_PRO_1Kx768_16
endif	; ALLOW_1Kx768_16
			0			; table terminator
endif	; ALLOW_BIG_MOUSE_POINTER


	; these are the strings describing the devices 	
if	ALLOW_BIG_MOUSE_POINTER
LocalDefString IGSCP640x480SPString <"1. Standard Display - small pointer: 640x480",0>
LocalDefString IGSCP640x480BPString <"2. Standard Display - big pointer: 640x480",0>
LocalDefString IGSCP800x600SPString <"3. Large Display - small pointer: 800x600",0>
LocalDefString IGSCP800x600BPString <"4. Large Display - big pointer: 800x600",0>
if	ALLOW_1Kx768_16
LocalDefString IGSCP1Kx768SPString <"5. Largest Display - small pointer: 1024x768",0>
LocalDefString IGSCP1Kx768BPString <"6. Largest Display - big pointer: 1024x768",0>
endif	; ALLOW_1Kx768_16
else
LocalDefString IGSCP640x480String <"1. Standard Display: 640x480",0>
LocalDefString IGSCP800x600String <"2. Large Display: 800x600",0>
if	ALLOW_1Kx768_16
LocalDefString IGSCP1Kx768String <"3. Largest Display: 1024x768",0>
endif	; ALLOW_1Kx768_16
endif	; ALLOW_BIG_MOUSE_POINTER
