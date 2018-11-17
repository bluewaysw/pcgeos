COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GrObj
FILE:		objectManager.asm

AUTHOR:		Steve Scholl, November 15, 1989

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ss      11/15/89        Initial revision.

DESCRIPTION:
	Manager for this module.

	$Id: shapeManager.asm,v 1.1 97/04/04 18:08:26 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


include grobjGeode.def

include shapeConstant.def

;------------------------------------------------------------------------------
;	Local variables.
;------------------------------------------------------------------------------

idata segment
include	shapeVariable.def
idata ends


;------------------------------------------------------------------------------
;	Here comes the code...
;------------------------------------------------------------------------------
include rect.asm
include roundedRect.asm
include ellipse.asm
include line.asm
include	group.asm
include groupTransfer.asm
include gstring.asm
include arc.asm

