
COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1988 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		Dumb Raster video drivers
FILE:		dumbcomDevInfo.asm

AUTHOR:		Jim DeFrisco

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	jim	10/88	initial version

DESCRIPTION:
	This file contains the device information structure for the bitmap
driver.

	$Id: dumbcomDevInfo.asm,v 1.1 97/04/18 11:42:28 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

;	"DevInfo" structure for this driver

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
			  SCREEN_HEIGHT,		; DI_pageH
			  SCREEN_PIXEL_WIDTH,		; DI_pageW
			  SCREEN_HEIGHT / PHYSICAL_SCREEN_HEIGHT, ; DI_vRes
			  SCREEN_PIXEL_WIDTH / PHYSICAL_SCREEN_WIDTH, ; DI_hRes
			  SCREEN_BYTE_WIDTH,		; DI_bpScan
			  1,				; DI_nColors
			  1,				; DI_nPlanes
			  1, 				; DI_nBits
			  1,				; DI_wColTab
			  BMF_MONO,			; DI_bmFormat
			  DISPLAY_TYPE			; DI_displayType
			>
