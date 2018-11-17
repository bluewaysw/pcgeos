
COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1988 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		MEGA video driver
FILE:		megaDevInfo.asm

AUTHOR:		Jim DeFrisco, Jeremy Dashe

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	jeremy	4/12/91	Initial version

DESCRIPTION:
	This file contains the device information structure for the MEGA driver.

	$Id: megaDevInfo.asm,v 1.1 97/04/18 11:42:19 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

;	fill out info for EGA card, use defaults where possible
;	(structure is defined in "globlcon")

;	here are the values used for the EGA

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
			  350,				; DI_pageH
			  640,				; DI_pageW
			  47, 				; DI_vRes
			  64, 				; DI_hRes
			  320,				; DI_bpScan
			  1,				; DI_nColors
			  1,				; DI_nPlanes
			  1, 				; DI_nBits
			  1,				; DI_wColTab
			  BMF_MONO,			; DI_bmFormat
			  MEGA_DISPLAY_TYPE		; DI_displayType
			>
