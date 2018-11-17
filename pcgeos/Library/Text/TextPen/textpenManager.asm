COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	Text
MODULE:		TextPen
FILE:		penManager.asm

AUTHOR:		Andrew Wilson, Feb 14, 1992

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/14/92		Initial revision

DESCRIPTION:
	This includes files for the pen support in the text object.	

	$Id: textpenManager.asm,v 1.1 97/04/07 11:21:25 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
include textGeode.def
include texttext.def
include textstorage.def
include textattr.def
include textpen.def
include textgr.def
include textui.def
include textundo.def
include textselect.def


include hwr.def
include	textregion.def

include penConstant.def

include penCode.asm

