COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	Irlmp Library
MODULE:		TinyTP
FILE:		ttpManager.asm

AUTHOR:		Chung Liu, Dec 22, 1995

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	12/22/95   	Initial revision


DESCRIPTION:
	Includes for TinyTP module.
		
	$Id: ttpManager.asm,v 1.1 97/04/05 01:07:14 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	irlmpGeode.def

TinyTPCode	segment resource

include ttpApi.asm
include ttpCallback.asm
include ttpQueue.asm
include	ttpUtils.asm
include ttpC.asm

TinyTPCode	ends
