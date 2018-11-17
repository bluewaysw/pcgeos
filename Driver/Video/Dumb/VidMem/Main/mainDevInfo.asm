COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		VIDMEM	
FILE:		mainDevInfo.asm

AUTHOR:		Jim DeFrisco, Jan  9, 1992

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	1/ 9/92		Initial revision


DESCRIPTION:
		Bogus device info block so we can supply the strategy routine

	$Id: mainDevInfo.asm,v 1.1 97/04/18 11:42:43 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DriverTable	DriverInfoStruct < 
			      DriverStrategy,		; DIS_strategy
			      0,			; DIS_driverAttributes
			      DRIVER_TYPE_VIDEO		; DIS_driverType
			    >
