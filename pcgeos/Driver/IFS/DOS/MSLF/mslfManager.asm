COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GlobalPC 1999.  All rights reserved.
	GLOBALPC CONFIDENTIAL

PROJECT:	Global PC
MODULE:		MS DOS Longname IFS Driver
FILE:		mslfManager.asm

AUTHOR:		Allen Yuen, Jan 21, 1999

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	1/21/99   	Initial revision


DESCRIPTION:
		
	Manager file of MSLF driver.

	$Id$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

_MSLF		equ	TRUE	; define the version of DOS driven by this
				;  driver.

_MS4		equ	TRUE	; This is an MS4 dirver with more functions.

include	dosGeode.def

include mslfInterface.def

include dosConstant.def
include dosMacro.def

;------------------------------------------------------------------------------
;				Variables
;------------------------------------------------------------------------------

include dosStrings.asm
include	dosVariable.def

include mslfStrings.asm
include msVariable.def

;------------------------------------------------------------------------------
;				Code
;------------------------------------------------------------------------------

include	dosEntry.asm		; strategy & administrative gradoo
include	dosDisk.asm		; DR_FS_DISK* implementation
include dosDrive.asm		; DR_FS_DRIVE* implementation
include msDrive.asm		; MS4-specific support routines for same
include dosPath.asm		; DR_FS_CUR_PATH* implementation
				; DR_FS_ALLOC_OP
				; DR_FS_PATH_OP
include dosEnum.asm		; DR_FS_FILE_ENUM implementation
include dosFormat.asm		; DR_FS_DISK_FORMAT
include dosFormatInit.asm
include dosDiskCopy.asm		; DR_FS_DISK_COPY
include dosIO.asm		; DR_FS_HANDLE_OP
include dosPrimary.asm		; Primary FSD responsibilities
include dosInitExit.asm		; version-independent initialization
include msInitExit.asm		; Initialization/exit routines.
include dosCritical.asm		; Critical-error handler
include dosUtils.asm		; Random utility things.
include dosVirtual.asm		; Virtual namespace support
include dosWaitPost.asm		; Wait/post support.

include msSFT.asm		; MS-DOS SFT utility routines
include	dosSuspend.asm		; DR_SUSPEND/DR_UNSUSPEND
include dosLink.asm		; links
include dosIdle.asm		; Idle-time notification
include dosFileChange.asm	; File-change notification

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
ifdef GB_2312_EUC_SUPPORT
include	dosConstantGB.def	; constants for GB support
include	dosConvertGB.asm	; code for GB support
include	dosCMapGB.asm		; map for GB support
endif
endif

