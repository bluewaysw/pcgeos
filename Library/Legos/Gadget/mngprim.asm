COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		mngsrvc.asm

AUTHOR:		RON, Sep 27, 1995

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	9/27/95   	Initial revision


DESCRIPTION:
	
		

	$Id: mngprim.asm,v 1.1 98/03/11 04:30:49 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


include common.def
include	Legos/gadget.def

;------------------------------------------------------------------------------
;	Local variables.
;------------------------------------------------------------------------------

GadgetCode	segment	resource

include	gdgflot.asm
include gdgspace.asm
include gdgsprt.asm
include gdgwin.asm

GadgetCode	ends



