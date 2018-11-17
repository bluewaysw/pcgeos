
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Video Drivers
FILE:		cgaStringTab.asm

AUTHOR:		Jim DeFrisco, 8/1/90

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	8/1/90		Initial revision
	jeremy	5/7/92		Added CGA compatible card support

DESCRIPTION:
	This file holds the device string tables
		

	$Id: cgaStringTab.asm,v 1.1 97/04/18 11:42:31 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

	; these are the device enums
VD_CGA		enum	VideoDevice, 0
VD_CGA_BDB	enum	VideoDevice
VD_CGA_BDG 	enum	VideoDevice
VD_CGA_BDC	enum	VideoDevice
VD_CGA_BDR 	enum	VideoDevice
VD_CGA_BDV 	enum	VideoDevice
VD_CGA_BB  	enum	VideoDevice
VD_CGA_BLGy	enum	VideoDevice
VD_CGA_BDGy	enum	VideoDevice
VD_CGA_BLB 	enum	VideoDevice
VD_CGA_BLG 	enum	VideoDevice
VD_CGA_BLC 	enum	VideoDevice
VD_CGA_BLR 	enum	VideoDevice
VD_CGA_BLV 	enum	VideoDevice
VD_CGA_BY  	enum	VideoDevice
VD_CGA_BW  	enum	VideoDevice
VD_CGA_COMPAT	enum	VideoDevice
VD_CGA_INVERSE	enum	VideoDevice


	; the first thing in the segment is the DriverExtendedInfoTable
	; structure
DriverExtendedInfoTable <
		{},			; lmem header added by Esp
		VideoDevice/2,			; DEIT_numDevices
		offset CGAStringTable,		; DEIT_nameTable
		0 				; DEIT_infoTable
		>


	; this is the table of near pointers to the device strings
CGAStringTable	lptr.char \
			CGAString,			; VD_CGA
			CGAStringBDB,			; VD_CGA_BDB 
			CGAStringBDG,			; VD_CGA_BDG 
			CGAStringBDC,			; VD_CGA_BDC 
			CGAStringBDR,			; VD_CGA_BDR 
			CGAStringBDV,			; VD_CGA_BDV 
			CGAStringBB,			; VD_CGA_BB  
			CGAStringBLGy,			; VD_CGA_BLGy
			CGAStringBDGy,			; VD_CGA_BDGy
			CGAStringBLB,			; VD_CGA_BLB 
			CGAStringBLG,			; VD_CGA_BLG 
			CGAStringBLC,			; VD_CGA_BLC 
			CGAStringBLR,			; VD_CGA_BLR 
			CGAStringBLV,			; VD_CGA_BLV 
			CGAStringBY,			; VD_CGA_BY  
			CGAStringBW,			; VD_CGA_BW  
			CGACompatString,		; VD_CGA_COMPAT
			CGAInverseString,		; VD_CGA_INVERSE
			0				; table terminator


	; these are the strings describing the devices
CGAString	chunk.char "CGA: 640x200 Mono",0		; VD_CGA
CGAStringBDB	chunk.char "CGA: 640x200 Black & Dark Blue",0 	; VD_CGA_BDB
CGAStringBDG	chunk.char "CGA: 640x200 Black & Dark Green",0 	; VD_CGA_BDG
CGAStringBDC	chunk.char "CGA: 640x200 Black & Dark Cyan",0 	; VD_CGA_BDC
CGAStringBDR	chunk.char "CGA: 640x200 Black & Dark Red",0 	; VD_CGA_BDR
CGAStringBDV	chunk.char "CGA: 640x200 Black & Dark Violet",0	; VD_CGA_BDV
CGAStringBB	chunk.char "CGA: 640x200 Black & Brown",0 	; VD_CGA_BB
CGAStringBLGy	chunk.char "CGA: 640x200 Black & Light Grey",0 	; VD_CGA_BLGy
CGAStringBDGy	chunk.char "CGA: 640x200 Black & Dark Grey",0 	; VD_CGA_BDGy
CGAStringBLB	chunk.char "CGA: 640x200 Black & Light Blue",0 	; VD_CGA_BLB
CGAStringBLG	chunk.char "CGA: 640x200 Black & Light Green",0	; VD_CGA_BLG
CGAStringBLC	chunk.char "CGA: 640x200 Black & Light Cyan",0 	; VD_CGA_BLC
CGAStringBLR	chunk.char "CGA: 640x200 Black & Light Red",0 	; VD_CGA_BLR
CGAStringBLV	chunk.char "CGA: 640x200 Black & Light Violet",0; VD_CGA_BLV
CGAStringBY	chunk.char "CGA: 640x200 Black & Yellow",0 	; VD_CGA_BY
CGAStringBW	chunk.char "CGA: 640x200 Black & White",0 	; VD_CGA_BW  
CGACompatString	chunk.char "CGA Compatible: 640x200 Mono",0	; VD_CGA_COMPAT
CGAInverseString chunk.char "CGA: 640x200 Inverse Mono",0	; VD_CGA_INVERSE
