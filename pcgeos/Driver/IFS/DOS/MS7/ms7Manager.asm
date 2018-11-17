COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		ms4Manager.asm

AUTHOR:		Adam de Boor, March 19, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	3/19/92		Initial revision


DESCRIPTION:
	The thing what gets assembled.
		

	$Id: ms7Manager.asm,v 1.1 97/04/10 11:55:39 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

_MS7		equ	TRUE	; define the version of DOS driven by this
				;  driver.
_MS4		equ	TRUE	;

_SFN_CACHE	equ	TRUE

include	Common/dos7Geode.def
;include	ms4Interface.def
include ms7Interface.def
;include ms4Macro.def
;include	ms4Constant.def

include Common/dos7Constant.def
include Common/dos7Macro.def

;------------------------------------------------------------------------------
;				Variables
;------------------------------------------------------------------------------

include dosStrings.asm
include	Common/dos7Variable.def

include ms7Strings.asm
include msVariable.def

;------------------------------------------------------------------------------
;				Code
;------------------------------------------------------------------------------

include ms7Utils.asm		; stuff we use for long name support
include ms7Path.asm		; dosPath support for longnames

include	dosEntry.asm		; strategy & administrative gradoo
include	Common/dos7Disk.asm		; DR_FS_DISK* implementation
include dosDrive.asm		; DR_FS_DRIVE* implementation
include msDrive.asm		; MS4-specific support routines for same
include Common/dos7Path.asm		; DR_FS_CUR_PATH* implementation
				; DR_FS_ALLOC_OP
				; DR_FS_PATH_OP
include Common/dos7Enum.asm		; DR_FS_FILE_ENUM implementation
include dosFormat.asm		; DR_FS_DISK_FORMAT
include dosFormatInit.asm
include dosDiskCopy.asm		; DR_FS_DISK_COPY
include Common/dos7IO.asm		; DR_FS_HANDLE_OP
include dosPrimary.asm		; Primary FSD responsibilities
include dosInitExit.asm		; version-independent initialization
include Common/dos7InitExit.asm		; Initialization/exit routines.
include dosCritical.asm		; Critical-error handler
include Common/dos7Utils.asm		; Random utility things.
include Common/dos7Virtual.asm		; Virtual namespace support
include dosWaitPost.asm		; Wait/post support.

include msSFT.asm		; MS-DOS SFT utility routines
include	dosSuspend.asm		; DR_SUSPEND/DR_UNSUSPEND
include Common/dos7Link.asm		; links
include dosIdle.asm		; Idle-time notification
include Common/dos7FileChange.asm	; File-change notification


if DBCS_PCGEOS
include dosConvert.asm		; DOS/GEOS string conversion
include dosCMapUS.asm		; US Code Page (437)
include dosCMapMulti.asm 	; Multilingual Code Page (850)
ifdef SJIS_SUPPORT
include dosConstantSJIS.def	; constants for SJIS support
include dosConvertSJIS.asm	; code for SJIS support
include dosCMapSJIS.asm		; map for SJIS support
include dosConvertJIS.def	; constans for JIS and EUC support
include dosConvertJIS.asm	; code for JIS support
include	dosConvertEUC.asm	; code for EUC support
endif
endif

