COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved


PROJECT:	GEOS
MODULE:		SuperVGA Video Driver
FILE:		vga8DevInfo.asm

AUTHOR:		Jim DeFrisco

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	jad	10/92	initial version

DESCRIPTION:
	This file contains the device information structure for the 
	8 bit SuperVGA cards

	$Id: vga8DevInfo.asm,v 1.1 97/04/18 11:42:00 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

;	here are the values used for the 8-bit drivers

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
			  480,				; VDI_pageH
			  640,				; VDI_pageW
			  80, 				; VDI_vRes
			  80, 				; VDI_hRes
			  640,				; VDI_bpScan
			  8,				; VDI_nColors
			  1,				; VDI_nPlanes
			  8, 				; VDI_nBits
			  18,				; VDI_wColTab
			  BMF_8BIT,			; VDI_bmFormat
			  VGA8_DISPLAY_TYPE		; VDI_displayType
			>
