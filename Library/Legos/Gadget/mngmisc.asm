COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:        
MODULE:         
FILE:           mngmisc.asm

AUTHOR:         RON, Sep 27, 1995

ROUTINES:
	Name                    Description
	----                    -----------

	
REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
	RON     9/27/95         Initial revision


DESCRIPTION:
	
		

	$Id: mngmisc.asm,v 1.1 98/03/11 04:31:05 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include common.def
include Legos/gadget.def
include gdgvar.def

GadgetCode      segment resource

include gdgdb.asm
; taken out 9/9/97, -eca
;include gdgink.asm
include gdgmast.asm
include gdgscrol.asm
include gdgutil.asm
; taken out 9/9/97, -eca
;include sjis_asm.asm

; Unused so taken out for efficiency.  -jmagasin 6/19/96
;include gdgfig.asm
;include gdgvis.asm

GadgetCode      ends
