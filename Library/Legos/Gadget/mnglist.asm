COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		mnglist.asm

AUTHOR:		RON, Sep 27, 1995

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	9/27/95   	Initial revision


DESCRIPTION:
	
		

	$Id: mnglist.asm,v 1.1 98/03/11 04:30:53 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include common.def
include Legos/gadget.def

GadgetListCode	segment	resource

include	gdglist.asm
include	gdgchoic.asm
include	gdgtoggl.asm
include gdgtext.asm
include gdgetry.asm
include gdgpopup.asm
include gdgagg.asm

GadgetListCode	ends

