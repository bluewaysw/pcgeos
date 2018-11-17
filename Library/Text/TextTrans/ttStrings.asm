COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		ttStrings.asm

AUTHOR:		Ian Porteous, Mar 17, 1995

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	3/17/95   	Initial revision


DESCRIPTION:
	Strings for the Text Transfer module
		

	$Id: ttStrings.asm,v 1.1 97/04/07 11:20:00 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TextTransStrings	segment	lmem	LMEM_TYPE_GENERAL

LocalDefString TransferSizeWarning <"Due to memory constraints the \
size of the text cut or copied was reduced. If you are trying to \
transfer the entire text, use the Save As command.", 0>

if _CHAR_LIMIT

LocalDefString CharLimitWarningString <"Due to memory constraints, no more \
text may be entered. Try to break this document up into smaller pieces.", 0>

endif

TextTransStrings	ends
