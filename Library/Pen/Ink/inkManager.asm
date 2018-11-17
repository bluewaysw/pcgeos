COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved

PROJECT:	Pen
MODULE:		Ink
FILE:		inkManager.asm

AUTHOR:		Andrew Wilson, Oct 10, 1991

ROUTINES:
	Name			Description
	----			-----------
	PenEntry		Entry point for pen stuff

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/10/91	Initial revision

DESCRIPTION:
	

	$Id: inkManager.asm,v 1.1 97/04/05 01:27:47 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
include penGeode.def
include penConstant.def
include geoworks.def


include gstring.def
include system.def

include Internal/mouseDr.def

include inkMacro.def
include inkConstant.def
include inkCursors.asm
include	inkClassCommon.asm
include	inkClassEdit.asm
include inkMouse.asm
include inkControlClass.asm
include inkControl.rdef
include inkSelection.asm
include	inkBackspace.asm

include inkMP.asm
					
end
