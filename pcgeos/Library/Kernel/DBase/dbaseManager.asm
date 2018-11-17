COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Database management.
FILE:		Manager.asm

AUTHOR:		John Wedgwood, 21-Jun-89

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	21-Jun-89	Initial revision

DESCRIPTION:
	Manager file for the database manager.

	$Id: dbaseManager.asm,v 1.1 97/04/05 01:17:33 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include kernelGeode.def

;--------------------------------------
;	Include files
;--------------------------------------

include lmem.def
include vm.def
include dbase.def

include dbaseConstant.def	;Database constants
include dbaseMacro.def		;Database macros
include dbaseVariable.def

include Internal/geodeStr.def
include Internal/dbaseInt.def

;-------------------------------------

include dbaseErrorCheck.asm	; Error checking code.
include dbaseStructure.asm	; * General structure manipulation.
include	dbaseItemBlock.asm	; * Manipulation of item-blocks.
include	dbaseGroup.asm		; * Lock/unlock of group blocks.
include	dbaseMapBlk.asm		; * Handling of the byte manager map block.
include dbaseCode.asm		; * Routines callable by the user.

include dbaseC.asm

;;;include dbaseRegister.asm	; * Register/notify code.

end
