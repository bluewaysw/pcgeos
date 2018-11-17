COMMENT @/********************************************************

	Copyright (c) Dirk Lausecker -- All Rights Reserved

PROJECT:	BestSound Driver

DATEI:		Manager.asm

AUTOR:		Dirk Lausecker

REVISION HISTORY:
	Name	Datum		Beschreibung
	----	-----		------------
	DL	08.08.98	Init
        DL	07.10.1999	Ableitung fÅr Recording
        DL	22.12.1999	Ableitung fÅr NewWave (Umgehung Soundlib)
        DL	22.08.2000	Translation for ND


*****************************************************************/@

;-----------------------------------------------------------------------------
;		Include Files
;-----------------------------------------------------------------------------

;
include	geos.def
include	file.def
include	geode.def
include dirk.def

include dirksnd.def

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

include bsConst.def
include	bsError.def
include bsTimer.asm

UseLib	  sound.def
UseDriver Internal/DMADrv.def
UseDriver Internal/strDrInt.def

DefDriver Internal/soundDrv.def

;-----------------------------------------------------------------------------
;		Conditional Compile Flags
;-----------------------------------------------------------------------------

BS_OUTPUT_DSP		equ	1	; use soundcard

; BS_SWAT_WARNING	equ	1

;-----------------------------------------------------------------------------
;		Source files for driver
;-----------------------------------------------------------------------------
	.ioenable
include bsError.asm		; Error Checking routines and such

include bsRegs.asm		; FM register writing routine and n.e.
include bsInit.asm		; set up board for use
include	bsDelay.asm		; micro second busy-wait code
include	bsStrate.asm		; strategy routine and nothing else
include bsInt.asm		; interrupt code for DMA

include	bsVoice.asm		; regular driver code
include bsDAC.asm		; DAC driver code

include bsStream.asm		; stream stuff for dac
include	bsWav.asm		;
include	bsMixer.asm		; Mixer control
include	mixLib.def		; Mixerdefinitions

include bsRecord.asm		; Recording Functions
include	bsNWav.asm		; NewWave-Play

