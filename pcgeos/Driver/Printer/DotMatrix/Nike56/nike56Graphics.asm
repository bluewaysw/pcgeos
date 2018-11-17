
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Brother NIKE 56-jet print drivers
FILE:		nike56Graphics.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	10/94		Initial revision


DESCRIPTION:
	This file contains most of the code to implement the Brothre NIKE
	print driver graphics mode support

	$Id: nike56Graphics.asm,v 1.1 97/04/18 11:55:34 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	Graphics/graphicsCommon.asm		;common graphic print routines
include Graphics/graphicsPrintSwathNike.asm	;PrintSwath routine.
include	Graphics/graphicsHiNike.asm		;Both res routine,
include	Graphics/graphicsSendHiNike.asm		;buffer send routine,
