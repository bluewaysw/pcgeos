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
	

	$Id: mainManager.asm,v 1.1 97/04/04 17:48:42 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



include int8087Geode.def
include intCommonConstants.def

StatusToAX	macro
	push	bp
	push	bp
	mov	bp, sp
	fstsw	ss:[bp]
	fwait
	pop	ax
	pop	bp
	endm

.8087

include intCommonDateAndTime.asm
include intCommonMain.asm
include intCommonC.asm
include intCommonFixed.asm
include intCommonLib.asm
include int8087.asm
