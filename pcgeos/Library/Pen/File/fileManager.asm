COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved

PROJECT:	Pen
MODULE:		File
FILE:		fileManager.asm

AUTHOR:		Andrew Wilson, Feb 3, 1992

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/10/91	Initial revision

DESCRIPTION:
	

	$Id: fileManager.asm,v 1.1 97/04/05 01:28:02 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
include penGeode.def
include penConstant.def
include hugearr.def
include timedate.def

include fileMacro.def
include fileConstant.def
include fileStrings.rdef
include fileAccess.asm
include fileC.asm
Strings segment lmem
Strings ends
end
