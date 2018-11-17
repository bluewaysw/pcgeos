
COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1988 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		Video driver
FILE:		vgaDevInfo.asm

AUTHOR:		Jim DeFrisco

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	jad	5/88	initial version

DESCRIPTION:
	This file contains the device information structure for the VGA driver.

	$Id: vgaDevInfo.asm,v 1.1 97/04/18 11:41:57 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

;	fill out info for VGA card, use defaults where possible
;	(structure is defined in "globlcon")

;	here are the values used for the VGA

DriverTable	VideoDriverInfo < <
			    < DriverStrategy,		; DIS_strategy
			      mask DA_HAS_EXTENDED_INFO,; DIS_driverAttributes
			      DRIVER_TYPE_VIDEO		; DIS_driverType
			    >,
			    handle VideoDevices		; DEIS_resource
			  >,
			  DT_RASTER_DISPLAY,			; DI_tech
			  1,				; DI_verMaj
			  0,				; DI_verMin
			  480,				; DI_pageH
			  640,				; DI_pageW
			  64, 				; DI_vRes
			  64, 				; DI_hRes
			  320,				; DI_bpScan
			  4,				; DI_nColors
			  4,				; DI_nPlanes
			  1, 				; DI_nBits
			  18,				; DI_wColTab
			  BMF_4BIT,			; DI_bmFormat
			  VGA_DISPLAY_TYPE		; DI_displayType
			>
