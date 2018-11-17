
COMMENT @-----------------------------------------------------------------------

	Copyright (c) Geoworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		

AUTHOR:		Cheng, 1/91

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial revision

DESCRIPTION:
		
	$Id: floatManager.asm,v 1.1 97/04/05 01:23:18 newdeal Exp $

-------------------------------------------------------------------------------@

include mathGeode.def
include mathGlobals.def
include mathConstants.def
include floatConstant.def
include floatMacro.def
include	Internal/heapInt.def

include floatVariable.def

InitCode segment resource
include floatStack.asm
InitCode ends


CommonCode      segment resource
        include floatConstants.asm      ; fp constants
        include floatLow.asm            ; low level routines
        include floatComp.asm           ; comparison routines
        include floatHigh.asm           ; global routines
        include floatConvert.asm        ; conversion routines
        include floatFloatToAscii.asm   ; conversion routines
        include floatFormat.asm         ; routine to generate a format string
        include floatEC.asm             ; error checking code
        include floatGlobal.asm         ; global routines
        include floatTrans.asm          ; transcendental functions
CommonCode      ends

FloatFixedCode segment resource
include floatFixed.asm
FloatFixedCode	ends


FloatDateTime	segment resource
include	floatDateTime.asm
FloatDateTime	ends

C_Float	segment	resource
include floatC.asm
C_Float ends

idata	segment	
global	stackDepth:word
idata	ends




