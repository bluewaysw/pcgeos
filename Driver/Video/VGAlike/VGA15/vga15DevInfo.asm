COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved


PROJECT:	GEOS
MODULE:		SuperVGA Video Driver
FILE:           vga15DevInfo.asm

AUTHOR:		Jim DeFrisco

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	jad	10/92	initial version
        FR       9/97   initial 15-bit version        

DESCRIPTION:
	This file contains the device information structure for the 
        15 bit SuperVGA cards

        $Id: vga15DevInfo.asm,v 1.2 96/08/05 03:51:32 canavese Exp $

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
                          0,                            ; VDI_nColors
			  1,				; VDI_nPlanes
                          15,                           ; VDI_nBits
                          0,                            ; VDI_wColTab
                          BMF_24BIT,                    ; VDI_bmFormat
                          VGA24_DISPLAY_TYPE            ; VDI_displayType
			>
