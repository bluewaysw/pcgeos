
COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		SuperVGA Video Driver
FILE:		svgaDevInfo.asm

AUTHOR:		Jim DeFrisco

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	jad	9/90	initial version

DESCRIPTION:
	This file contains the device information structure for the 
	800x600 cards

	$Id: svgaDevInfo.asm,v 1.1 97/04/18 11:42:24 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

;	here are the values used for the 800x600 drivers

DriverTable	VideoDriverInfo < <
			    < DriverStrategy,		; DIS_strategy
			      mask DA_HAS_EXTENDED_INFO,; DIS_driverAttributes
			      DRIVER_TYPE_VIDEO		; DIS_driverType
			    >,
			    handle VideoDevices		; DEIS_resource
			  >,
			  DT_RASTER_DISPLAY,			; VDI_tech
			  1,				; VDI_verMaj
			  0,				; VDI_verMin
			  600,				; VDI_pageH
			  800,				; VDI_pageW
			  80, 				; VDI_vRes
			  80, 				; VDI_hRes
			  400,				; VDI_bpScan
			  4,				; VDI_nColors
			  4,				; VDI_nPlanes
			  1, 				; VDI_nBits
			  18,				; VDI_wColTab
			  BMF_4BIT,			; VDI_bmFormat
			  SVGA_DISPLAY_TYPE		; VDI_displayType
			>
