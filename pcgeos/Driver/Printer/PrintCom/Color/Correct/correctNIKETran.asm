COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1995 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Printer Drivers
FILE:		correctNIKETran.asm

AUTHOR:		Dave Durran, June 14 1995

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	06/14/95	Initial revision


DESCRIPTION:
	Color correction table generated for NIKE CMY inks on transparancies


	$Id: correctNIKETran.asm,v 1.1 97/04/18 11:51:38 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CorrectNIKETranInk	segment	resource

nikeTranInkCorrection	label	byte
        ;        R    G    B
        ;       ---  ---  ---
        byte    040h,000h,000h          ;black
        byte    000h,030h,0f0h          ;blue
        byte    040h,0b0h,030h          ;green
        byte    060h,0c0h,0d0h          ;cyan
        byte    0b0h,000h,050h          ;red
        byte    090h,030h,0ffh          ;purple
        byte    0a0h,060h,050h          ;brown
        byte    0b0h,0b0h,0d0h          ;l. gray
        byte    090h,0a0h,0b0h          ;d. gray
        byte    080h,0c0h,0ffh          ;l. blue
        byte    080h,0ffh,000h          ;l. green
        byte    0b0h,0ffh,0ffh          ;l. cyan
        byte    0ffh,000h,020h          ;l. red
        byte    0f0h,090h,0ffh          ;l. purple
        byte    0ffh,0ffh,000h          ;yellow
        byte    0ffh,0ffh,0ffh          ;white


CorrectNIKETranInk	ends
