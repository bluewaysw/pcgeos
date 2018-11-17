COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Sound Driver	
FILE:		soundblasterManager.asm

AUTHOR:		Todd Stumpf, Aug  5, 1992

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	8/ 5/92		Initial revision


DESCRIPTION:
	This is the manager file for the Sound Blaster sound driver.
	This truly is an extended device driver, being capable of
	supporting the SoundBlaster Pro as well as the regular sound
	blaster cards.

	$Id: soundblasterManager.asm,v 1.1 97/04/18 11:57:39 newdeal Exp $

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
include	char.def
include	localize.def

include	Internal/interrup.def

include soundblasterConstant.def
include	soundblasterError.def
include soundblasterPCTimer.def

UseLib	  sound.def
UseDriver Internal/DMADrv.def
UseDriver Internal/strDrInt.def

DefDriver Internal/soundDrv.def

;-----------------------------------------------------------------------------
;		Conditional Compile Flags
;-----------------------------------------------------------------------------

DSP_LOG		equ	0	; generates and maintains a log
				; of the commands sent to the DSP


;-----------------------------------------------------------------------------
;		Source files for driver
;-----------------------------------------------------------------------------
	.ioenable
include soundblasterError.asm		; Error Checking routines and such

include soundblasterRegister.asm	; FM register writing routine and n.e.
include soundblasterInit.asm		; set up board for use
include	soundblasterTimeDelay.asm	; micro second busy-wait code
include	soundblasterStrategy.asm	; strategy routine and nothing else
include soundblasterInt.asm		; interrupt code for DMA

include	soundblasterVoice.asm		; regular driver code
include soundblasterDAC.asm		; DAC driver code

include soundblasterStream.asm		; stream stuff for dac







