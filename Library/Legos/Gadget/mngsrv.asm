COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		mngsrv.asm

AUTHOR:		RON, Sep 27, 1995

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	9/27/95   	Initial revision


DESCRIPTION:
	

	$Id: mngsrv.asm,v 1.1 98/03/11 04:30:56 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include common.def
include Legos/gadget.def
include geoworks.def
include math.def

GadgetServiceCode	segment	resource

include servsys.asm
include srvclipb.asm
;;include srvalarm.asm
include srvdate.asm
include srvtimer.asm
include alclient.asm
include gdgbtn.asm
include gdgnumb.asm
include gdglabel.asm

GadgetServiceCode	ends

