COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		mainMananger.asm

AUTHOR:		jimmy lefkowitz

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	6/29/92		Initial version.

DESCRIPTION:
	

	$Id: mainManager.asm,v 1.1 97/04/04 17:48:26 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



include intx87Geode.def
include intCommonConstants.def

StatusToAX	equ <fstswax>

.287

include intCommonDateAndTime.asm
include intCommonMain.asm
include intCommonC.asm
include intCommonFixed.asm
include intCommonLib.asm

include intx87.asm
