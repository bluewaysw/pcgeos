
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Video Drivers
FILE:		mcgaStringTab.asm

AUTHOR:		Jim DeFrisco, 8/1/90

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	8/1/90		Initial revision
	jeremy	4/10/91		Added "mono VGA" string


DESCRIPTION:
	This file holds the device string tables
		

	$Id: mcgaStringTab.asm,v 1.1 97/04/18 11:42:34 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

	; these are the device enums
if PZ_PCGEOS
VD_IBM_MVGA		enum	VideoDevice, 0
VD_IBM_MVGA_INVERSE	enum	VideoDevice
else
VD_IBM_MCGA		enum	VideoDevice, 0
VD_IBM_MVGA		enum	VideoDevice
VD_IBM_MVGA_INVERSE	enum	VideoDevice
endif

        ; the first thing in the segment is the DriverExtendedInfoTable
	; structure
DriverExtendedInfoTable <
		{},			; lmem header added by Esp
		VideoDevice/2,                  ; DEIT_numDevices
		offset MCGAStringTable,          ; DEIT_nameTable
		0                               ; DEIT_infoTable
		>

if not PZ_PCGEOS
	; this is the table of near pointers to the device strings
MCGAStringTable lptr.char \
			IBMMCGAString,			; VD_IBM_MCGA
			IBMMonoVGAString,		; VD_IBM_MCGA
			IBMInverseMonoVGAString,	; VD_IBM_MCGA_INVERSE
			0				; table terminator

else
	; this is the table of near pointers to the device strings
MCGAStringTable lptr.char \
			IBMMonoVGAString,		; VD_IBM_MCGA
			IBMInverseMonoVGAString,	; VD_IBM_MCGA_INVERSE
			0				; table terminator
endif

	; these are the strings describing the devices
if not PZ_PCGEOS
LocalDefString IBMMCGAString <"IBM MCGA: 640x480 Mono",0> 	; VD_IBM_MCGA
endif

LocalDefString IBMMonoVGAString <"VGA: 640x480 Mono",0> 	; VD_IBM_MCGA
LocalDefString IBMInverseMonoVGAString <"VGA: 640x480 Inverse Mono",0>
							; VD_IBM_MCGA_INVERSE
