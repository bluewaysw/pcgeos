COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GlobalPC 1998 -- All Rights Reserved


PROJECT:	GEOS
MODULE:		Cyber16 Video Driver
FILE:		cyber16DevInfo.asm

AUTHOR:		Jim DeFrisco

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	jad	10/92	initial version

DESCRIPTION:
	This file contains the device information structure for the 
	16 bit SuperVGA cards

	$Id: cyber16DevInfo.asm,v 1.2$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;	here are the values used for the 16-bit drivers

DriverTable	VideoDriverInfo < <
			    < DriverStrategy,		; DIS_strategy
			      mask DA_HAS_EXTENDED_INFO,; DIS_driverAttributes
			      DRIVER_TYPE_VIDEO		; DIS_driverType
			    >,
			    handle VideoDevices		; DEIS_resource
			  >,
			  DT_RASTER_DISPLAY,		; VDI_tech
			  1,				; VDI_verMaj
			  0,				; VDI_verMin
			  440,				; VDI_pageH
			  640,				; VDI_pageW
			  66, 				; VDI_vRes
			  72, 				; VDI_hRes
			  640 * size word,		; VDI_bpScan
			  16,				; VDI_nColors
			  1,				; VDI_nPlanes
			  16,				; VDI_nBits
			  0,				; VDI_wColTab
			  BMF_24BIT,			; VDI_bmFormat
			  TV24_DISPLAY_TYPE		; VDI_displayType
			>
