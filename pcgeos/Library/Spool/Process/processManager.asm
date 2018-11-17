COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		System Spooler
FILE:		processManager.asm

AUTHOR:		Jim DeFrisco, 9 March 1990

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	3/13/90		Initial revision


DESCRIPTION:
	This file contains the code to assemble the library portion of the
	spooler 

	$Id: processManager.asm,v 1.1 97/04/07 11:11:33 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;	Common Geode stuff
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

include	spoolGeode.def				; this includes the .def files

include sem.def					; ThreadLock routines
include	Internal/semInt.def			; we use a semaphore here...
include	timedate.def				; we use system time function
include	thread.def				; we have mulitple threads
include	fileEnum.def				; need the FileEnum stuff
include	gstring.def				; graphics string for monikers
include medium.def

if _DUAL_THREADED_PRINTING
include sem.def					; dual threaded printing
endif

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;	Constants/Variables
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

include	processConstant.def			; common spooler constants
include	spoolVariable.def			; common spooler variables

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;	Code
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	; queue manipulation code
include		processQueue.asm		; all queue manipulation
include		processUtils.asm		; general utility routines
include		processRestart.asm		; restart printing

	; printing thread code
include		processError.asm		; deals with errors
include		processThread.asm		; all code for spool file proc
include		processText.asm			; text mode printing
include		processGraphics.asm		; graphics mode printing
include		processPDL.asm			; PDL printing
if _LABELS
include		processLabel.asm		; label printing
endif
include		processPort.asm			; deals with i/o ports
include		processTables.asm		; tables of routines, etc.

if _DUAL_THREADED_PRINTING
include		processDualThread.asm		; print on another thread
endif

	; individual port support routines
include		processParallel.asm		; parallel  ports
include		processSerial.asm		; serial ports
include		processFile.asm			; file "ports"
include		processNothing.asm		; unknown ports
include		processCustom.asm		; custom ports

	; code to support the application
include		processApp.asm			; application part of spooler
include		processControlPanel.asm

	; fixed code (in idata)
include		processLoop.asm			; fixed part of thread code
include		processLockQueue.asm		; more common code

include	    	processC.asm	    	    	; C stubs for process module
