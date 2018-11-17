COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved
	Copyright (c) New Deal 1998 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		ntfatManager.asm

AUTHOR:		Gene, January 23, 1998

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	1/23/98		based on OS/2 driver


DESCRIPTION:
	The thing what gets assembled.
		

	$Id: ntfatManager.asm,v 1.1 98/01/24 23:13:54 gene Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

_OS2		equ	TRUE	; define the version of DOS driven by this
				;  driver.
; this is basically OS/2 with a minor change to OS2CreateDrive
_NTFAT		equ	TRUE

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
include ntfatInitExit.asm	; Initialization/exit routines.
include dosCritical.asm		; Critical-error handler
include dosUtils.asm		; Random utility things.
include os2Utils.asm		; more random utility things
include dosVirtual.asm		; Virtual namespace support

include	dosSuspend.asm		; DR_SUSPEND/DR_UNSUSPEND
include dosLink.asm		; links
include dosIdle.asm		; Idle-time notification
include dosFileChange.asm	; File-change notification
