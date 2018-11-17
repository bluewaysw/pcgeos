COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		os2Manager.asm

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
		

	$Id: os2Manager.asm,v 1.1 97/04/10 11:55:18 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

_OS2		equ	TRUE	; define the version of DOS driven by this
				;  driver.

include	dosGeode.def

include os2Interface.def
;include os2Macro.def
;include	os2Constant.def

include dosConstant.def
include dosMacro.def

;------------------------------------------------------------------------------
;				Variables
;------------------------------------------------------------------------------

include dosStrings.asm
include	dosVariable.def

include os2Strings.asm
include os2Variable.def

;------------------------------------------------------------------------------
;				Code
;------------------------------------------------------------------------------

include	dosEntry.asm		; strategy & administrative gradoo
include	dosDisk.asm		; DR_FS_DISK* implementation
include dosDrive.asm		; DR_FS_DRIVE* implementation
include os2Drive.asm		; MS4-specific support routines for same
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
include os2InitExit.asm		; Initialization/exit routines.
include dosCritical.asm		; Critical-error handler
include dosUtils.asm		; Random utility things.
include os2Utils.asm		; more random utility things
include dosVirtual.asm		; Virtual namespace support

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
