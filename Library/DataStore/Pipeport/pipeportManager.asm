COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	
MODULE:		
FILE:		pipeportManager.asm

AUTHOR:		Robert Greenwalt, Dec  4, 1996

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	robertg	12/ 4/96   	Initial revision


DESCRIPTION:
		
	

	$Id: pipeportManager.asm,v 1.1 97/04/04 17:53:59 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	dsGeode.def
include	pipeport.def

DSClassStructures segment resource
	DSApplicationClass
DSClassStructures ends

include pipeportAppl.asm
include	pipeportBehaviors.asm
