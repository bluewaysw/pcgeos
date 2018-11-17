COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1997.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	
MODULE:		
FILE:		simp2or4DevInfo.asm

AUTHOR:		Eric Weber, Jan 29, 1997

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	weber   	1/29/97   	Initial revision


DESCRIPTION:
		
	Driver info struct

	$Id: simp2or4DevInfo.asm,v 1.1 97/04/18 11:43:57 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;	"DevInfo" structure for this driver

idata	segment

DriverTable	VideoDriverInfo < <
			    < Simp2or4Strategy,		; DIS_strategy
			      mask DA_HAS_EXTENDED_INFO,; DIS_driverAttributes
			      DRIVER_TYPE_VIDEO		; DIS_driverType
			    >,
			    handle VideoDevices		; DEIS_resource
			  >,
			  DT_RASTER_DISPLAY,			; DI_tech
			  1,				; DI_verMaj
			  0,				; DI_verMin
			  SCREEN_HEIGHT,		; DI_pageH
			  SCREEN_PIXEL_WIDTH,		; DI_pageW
			  SCREEN_HEIGHT / PHYSICAL_SCREEN_HEIGHT, ; DI_vRes
			  SCREEN_PIXEL_WIDTH / PHYSICAL_SCREEN_WIDTH, ; DI_hRes
			  SCREEN_BYTE_WIDTH,		; DI_bpScan
			  4,				; DI_nColors
			  1,				; DI_nPlanes
			  4, 				; DI_nBits
			  1,				; DI_wColTab
			  BMF_4BIT,			; DI_bmFormat
			  DISPLAY_TYPE			; DI_displayType
			>


ForceRef	DriverTable

idata	ends

	; these are the device enums
VD_SIMP2OR4		enum	VideoDevice, 0

VideoDevices	segment lmem LMEM_TYPE_GENERAL
	; the first thing in the segment is the DriverExtendedInfoTable
	; structure
DriverExtendedInfoTable <
		{},			; lmem header added by Esp
		VideoDevice/2,			; DEIT_numDevices
		offset Simp2or4StringTable,	; DEIT_nameTable
		0 				; DEIT_infoTable
		>


	; this is the table of near pointers to the device strings
Simp2or4StringTable lptr.char \
			Simp2or4String,			; VD_SIMP2OR4
			0				; table terminator

	; these are the strings describing the devices
Simp2or4String	chunk.char "Simple 2 or 4-Bit Greyscale Driver",0 ;VD_SIMP2OR4

VideoDevices	ends
