COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991-1995 -- All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	GEOS
MODULE:		Kernel/Boot
FILE:		bootStrings.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version

DESCRIPTION:
	This file contains strings for the kernel

	$Id: bootStrings.asm,v 1.2 98/04/25 11:14:59 gene Exp $

------------------------------------------------------------------------------@

.warn	-unref	; most of these things are referenced as a constant plus
		; a base chunk handle, so don't bitch about them being
		; unreferenced.

InitStringBlock	macro	start
_curChunk	= start
		endm

DefString	macro	const, data, name
    .assert _curChunk eq (const)
    _curChunk	= _curChunk + 1
ifb <name>
    .warn -unref
if DBCS_PCGEOS
    const&Str chunk.wchar	data
else
    const&Str chunk.char	data
endif
    .warn @unref
else
if DBCS_PCGEOS
    name	chunk.wchar	data
else
    name	chunk.char	data
endif
endif
		endm

FixedStrings	segment	lmem	LMEM_TYPE_GENERAL

InitStringBlock	FIRST_STRING_IN_FIXED_STRINGS

DefString KS_TE_DIVIDE_BY_ZERO, <"KR-01", 0>
	localize not
DefString KS_TE_OVERFLOW, <"KR-02", 0>
	localize not
DefString KS_TE_BOUND, <"KR-03", 0>
	localize not
DefString KS_TE_FPU_EXCEPTION, <"KR-04", 0>
	localize not
DefString KS_TE_SINGLE_STEP, <"KR-05", 0>
	localize not
DefString KS_TE_BREAKPOINT, <"KR-06", 0>
	localize not
DefString KS_TIE_ILLEGAL_INST, <"KR-07", 0>
	localize not
ifdef	CATCH_PROTECTION_FAULT
DefString KS_TIE_PROTECTION_FAULT, <"KR-11", 0>
	localize not
endif	; CATCH_PROTECTION_FAULT
ifdef	CATCH_STACK_EXCEPTION
DefString KS_TIE_STACK_EXCEPTION, <"KR-19", 0>
	localize not
endif	; CATCH_STACK_EXCEPTION

DefString KS_SYS_EMPTY_CALLED, <"KR-08", 0>
	localize not
DefString KS_ILLEGAL_HANDLE, <"KR-09", 0>
	localize not
DefString KS_BAD_MOVE_BLOCK, <"KR-10", 0>
	localize not

DefString KS_HANDLE_TABLE_FULL, <"Out of system resource handles. (KR-12)", 0>
	localize "This text is printed to the DOS text screen after the system shuts down abnormally due to running out of handles."

ifdef	GPC
 DefString KS_CANNOT_ALLOC_LOCAL_MEM, <"KR-13", 0>
else
 DefString KS_CANNOT_ALLOC_LOCAL_MEM, <"Cannot allocate local memory (KR-13)", 0> 
endif	; GPC
	localize "Appears in a SysNotify box preceded by \"Undefined error in geos: \""

DefString KS_TE_SYSTEM_ERROR, <"System Error Code: ", 0>
	localize "This is the initial part of the error string displayed for the \"anonymous\" errors (those that are just KR-xx, with no other explanation)", 
		SYS_NOTIFY_MAX_STRING-5

DefString KS_FATAL_ERROR_IN, <"Undefined error in ", 0>

ifdef	GPC
DefString KS_CODE_EQUALS, <": KRX-", 0>
else
DefString KS_CODE_EQUALS, <". Error Code: KRX-", 0>
endif
DefString KS_KERNEL, <"kernel", 0>

ifdef	GPC
DefString KS_FILE_ERROR, <"KR-14", 0>
else
DefString KS_UNRECOVERABLE_ERROR_IN, <"Error in ", 0>
DefString KS_UNRECOVERABLE_ERROR_PART_TWO, <"Operation cannot be completed. (KR-14)", 0>
endif	; GPC

ifdef	GPC
DefString KS_FILE_READ, <"-R", 0>
DefString KS_FILE_WRITE, <"-W", 0>
DefString KS_FILE_CLOSE, <"-C", 0>
DefString KS_FILE_COMMIT, <"-M", 0>
DefString KS_FILE_TRUNCATE, <"-T", 0>
else
DefString KS_FILE_READ, <"FileRead", 0>
DefString KS_FILE_WRITE, <"FileWrite", 0>
DefString KS_FILE_CLOSE, <"FileClose", 0>
DefString KS_FILE_COMMIT, <"FileCommit", 0>
DefString KS_FILE_TRUNCATE, <"FileTruncate", 0>
endif	; GPC

ifdef	GPC
if _NDO2000
DefString KS_TOO_MUCH_AT_ONCE, <"Your software is doing too much at once.", 0>, tooMuchAtOnce
else
DefString KS_TOO_MUCH_AT_ONCE, <"Your GlobalPC is doing too much at once.", 0>, tooMuchAtOnce
endif
DefString KS_TOO_MUCH_AT_ONCE_PART_TWO, <"Please exit a program or close a document.", 0>, tooMuchAtOncePartTwo
DefString KS_MEMORY_FULL, <"KR-16", 0>	; paired with KS_TE_SYSTEM_ERROR
else
DefString KS_LOW_ON_HANDLES_1, <"Low on system resource handles.", 0>
DefString KS_LOW_ON_HANDLES_2, <"Please exit an application. (KR-15)", 0>
DefString KS_MEMORY_FULL, <"Conventional memory (below 640K)", 0>, memFull1
DefString KS_MEMORY_FULL2, <"is full (KR-16)", 0>, memFull2
DefString KS_SWAP_DEVICES_FULL, <"WARNING: swap space is full.", 0>, swapDevFull
DefString KS_SWAP_DEVICES_FULL_PART_TWO, <"You may be low on disk space. (KR-17)", 0>, swapDevFull2
endif
DefString KS_SWAP_IN_ERROR, <"KR-18", 0>	; paired with KS_TE_SYSTEM_ERROR

DefString KS_THE_DISK_IN_DRIVE, <"The disk in drive ", 0>
DefString KS_HAS_NO_NAME_AND, <" has no name and", 0>
DefString KS_WILL_BE_REFERRED_TO_AS, <"will be referred to as ", 0>
DefString KS_PLEASE_INSERT_DISK, <"Please insert disk ", 0>
DefString KS_INTO_DRIVE, <"into drive ", 0>

DefString KS_UNNAMED, <"Unnamed", 0>

if CHECKSUM_DOS_BLOCKS
DefString KS_DOS_BLOCK_CHECKSUM_BAD, <"DOS Block Checksum Failure", 0>
endif

;		For LibSysError handling

;
; Older products use "HARDWARE_TYPE". Historical reasons
;
ifidn HARDWARE_TYPE, <GULLIVER>

; Gulliver-specific system error strings ------------------------------------- 

LocalDefString	errorStringC	<'Tap the top hard icon to continue',0>

LocalDefString	confusion	<'I''m so confused',0>

LocalDefString	errorStringRA	<'Top hard icon to retry, bottom to abort', 0>

LocalDefString	errorStringA	<'Tap the bottom hard icon to abort',0>

LocalDefString	errorStringBE1	<'Tap the bottom hard icon to restart',0>
LocalDefString	errorStringBE2	<0>

LocalDefString	errorStringE	<'Tap the bottom hard icon to restart',0>

LocalDefString	errorStringR	<'Tap the top hard icon to retry',0>

LocalDefString	errorStringRB	<'Top hard icon to retry, bottom to restart',0>

LocalDefString	errorStringB	<'Tap the bottom hard icon to restart', 0>

LocalDefString	errorStringBiz	<'Please see Troubleshooting Guide', 0>

LocalDefString	unableToExit	<"The system is unable to exit.\\r\\nPlease restart your computer. (KR-35)", 0>

else


; General machine system error strings ------------------------------------- 

LocalDefString	errorStringC	<'Press Enter to continue', 0>

LocalDefString	confusion	<'I''m so confused', 0>

LocalDefString	errorStringRA	<'"R" to retry, "A" to abort', 0>

LocalDefString	errorStringA	<'"A" to abort',0>

ifndef	GPC

LocalDefString	errorStringBE1	<'Press "E" to exit. If this fails, try', 0>
LocalDefString	errorStringBE2	<'restarting your computer.', 0>

LocalDefString	errorStringE	<'"E" to exit cleanly',0>

LocalDefString	errorStringRB	<'"R" to retry, "B" to reboot Ensemble', 0>

LocalDefString	errorStringB	<'"B" to reboot Ensemble', 0>

LocalDefString	errorKeys	<"BARE", 0>

else

LocalDefString	errorKeys	<"AR", 0>

endif	; GPC

LocalDefString	errorStringR	<'"R" to retry',0>

LocalDefString	errorStringBiz	<'Please see Troubleshooting Guide', 0>

LocalDefString	unableToExit	<"The system is unable to exit.\\r\\nPlease restart your computer. (KR-35)", 0 >

.warn -unref
LocalDefString vmHeaderOverflow1, <'Document too big.', 0>
LocalDefString vmHeaderOverflow2, <'Contact customer service.', 0>
.warn @unref

endif

;
; Some product-only strings.
;

ifdef	GPC

; The number of strings here MUST be equal to the value of GPCErrorMsgCount
; defined in sysError.asm.
if _NDO2000
.warn -unref
LocalDefString	GPCErrorMsg1	<'The software has experienced an error.', 0>
LocalDefString	GPCErrorMsg2	<'Press E to exit.  If this fails, press', 0>
LocalDefString	GPCErrorMsg3	<'CTRL+ALT+DEL or restart your computer.', 0>
LocalDefString	GPCErrorMsg4	<'Then start the software again.', 0>
.warn @unref
else
.warn -unref
LocalDefString	GPCErrorMsg1	<'Your GlobalPC has experienced an error.', 0>
LocalDefString	GPCErrorMsg2	<'Press the On/Off button on the front', 0>
LocalDefString	GPCErrorMsg3	<'panel to restart the GlobalPC.  If the', 0>
LocalDefString	GPCErrorMsg4	<'problem persists, call customer service.', 0>
.warn @unref
endif
	
endif

FixedStrings	ends

;----------------------------------------------------------------------------

MovableStrings	segment lmem	LMEM_TYPE_GENERAL

InitStringBlock	FIRST_STRING_IN_MOVABLE_STRINGS
DefString KS_CANNOT_PRESERVE_VOLATILE_SWAP_DATA, <"Not enough swap space.", 0>

ife ERROR_CHECK
;---


ifdef	GPC

DefString KS_CORRUPTED_INI_BUFFER, <"KR-20", 0>
DefString KS_OBJ_LOAD_ERROR, <"KR-21", 0>
DefString KS_OBJ_VM_LOAD_ERROR, <"KR-22", 0>

else

LocalDefString corruptedIniBufferStringOne <"GEOS.INI file is damaged. Restore it from backup", 0>
LocalDefString corruptedIniBufferStringTwo <"or delete it and reinstall the system software (KR-20)", 0>

LocalDefString objLoadError1	<"Error restoring state. Please exit and", 0>
LocalDefString objLoadError2 	<"restart the system. (KR-21)", 0>

LocalDefString objVMLoadError1	<"Error reading VM file. The document or data", 0>
LocalDefString objVMLoadError2	<"file may be damaged. (KR-22)", 0>

endif	; GPC

endif	; !ERROR_CHECK
;---

LocalDefString noSpaceForIniString1 <"No room to write GEOS.INI. Please", 0>
LocalDefString noSpaceForIniString2 <"make room, now. (KR-36)", 0>

; pulled non-localizable string from sysmisc.geo - jfh 12/04/03
LocalDefString	PowerOffString <'You may now safely turn off the computer',0>
  localize "the power off message (displayed in DOS) after shutting down Geos"

MovableStrings	ends

;----------------------------------------------------------------------------

InitStrings	segment lmem	LMEM_TYPE_GENERAL

InitStringBlock	FIRST_STRING_IN_INIT_STRINGS


DefString KS_CANNOT_LOAD_MEMORY_VIDEO_DRIVER, <"Cannot load a required system file (vidmem). You may need to reinstall the system software. (KR-25)", 0>
DefString KS_CANNOT_LOAD_KEYBOARD_DRIVER, <"Cannot load a required system file (keyboard). You may need to reinstall the system software. (KR-26)", 0>
DefString KS_CANNOT_LOAD_UI, <"Cannot load a required system file (ui). You may need to reinstall the system software. (KR-27)", 0
DefString KS_BAD_FONT_PATH, <"Cannot find USERDATA\\\\FONT directory. You may need to reinstall the system software. (KR-28)", 0>
DefString KS_NO_FONT_FILES, <"No valid font files found in USERDATA\\\\FONT directory. (KR-29)", 0>
DefString KS_DEFAULT_FONT_NOT_FOUND, <"Cannot load a required system file (sysfont). You may need to reinstall the system software. (KR-30)", 0>
DefString KS_UNSUPPORTED_DOS_VERSION, <"DOS version too old. You need DOS version 3.0 or higher. (KR-31)", 0>
DefString KS_UNABLE_TO_REGISTER_TOP_LEVEL_DISK, <"Unable to register the disk containing main system directory. (KR-32)", 0>
DefString KS_FILE_SYSTEM_DRIVER_FOR_DRIVE, <"File-system driver for drive ", 0>
DefString KS_NOT_LOADED, <"not loaded. (KR-33)", 0>
DefString KS_PRIMARY_FSD_NOT_LOADED, <"Unable to identify file-system in use. (KR-34)", 0>

DefString KS_ERROR_PREFIX, <"System error: ", 0>

InitStrings	ends


.warn	@unref
