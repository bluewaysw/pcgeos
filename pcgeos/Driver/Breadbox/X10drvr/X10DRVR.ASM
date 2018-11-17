COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Breadbox Computer 1995 -- All Rights Reserved

PROJECT:	Breadbox Home Automation
MODULE:	X-10 Power Code Driver	
FILE:		x10drvr.asm

AUTHOR: Fred Goya

REVISION HISTORY:

DESCRIPTION:

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;-----------------------------------------------------------------------------
;		Include Files
;-----------------------------------------------------------------------------

;
include	geos.def
include	file.def
include	geode.def
include	resource.def
include	ec.def
include	driver.def
include	heap.def
include	system.def
include	timer.def
include	initfile.def
include 	internal/interrup.def

include	timechip.def

global	X10Sleep:far

;-----------------------------------------------------------------------------
;		Source files for driver
;-----------------------------------------------------------------------------
	.ioenable
include X10Init.asm		; set up board for use
include X10Strat.asm		; strategy routine and nothing else
include X10Send.asm		; code for sending codes synchronized w/zero
								;  crossing point
include X10Sleep.asm		; microsecond delay code.







