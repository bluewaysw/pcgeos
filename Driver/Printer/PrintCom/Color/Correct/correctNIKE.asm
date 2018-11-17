COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1995 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Printer Drivers
FILE:		correctNIKE.asm

AUTHOR:		Dave Durran

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	6/14/95		Initial revision


DESCRIPTION:
	Color correction table generated for NIKE CMY Color.
	On plain copier paper


	$Id: correctNIKE.asm,v 1.1 97/04/18 11:51:37 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CorrectNIKE	segment	resource

nikeInkCorrection	label	byte

	;	 R    G    B
	;	---  ---  ---
	byte	000h,000h,070h		;black
	byte	000h,0a0h,0ffh		;blue
	byte	000h,0f0h,000h		;green
	byte	060h,0f0h,0e0h		;cyan
	byte	0e0h,000h,0a0h		;red
	byte	080h,060h,0ffh		;purple
	byte	0c0h,090h,020h		;brown
	byte	0d0h,0e0h,0e0h		;l. gray
	byte	0a0h,0b0h,0c0h		;d. gray
	byte	060h,0c8h,0ffh		;l. blue
	byte	0c0h,0ffh,090h		;l. green
	byte	0b0h,0ffh,0ffh		;l. cyan
	byte	0ffh,000h,040h		;l. red
	byte	0e0h,0c0h,0ffh		;l. purple
	byte	0ffh,0ffh,000h		;yellow
	byte	0ffh,0ffh,0ffh		;white

CorrectNIKE	ends
