COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GrObj
FILE:		pointerManager.asm

AUTHOR:		Steve Scholl, November 15, 1989

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ss      11/15/89        Initial revision.

DESCRIPTION:
	Manager for this module.

	$Id: pointerManager.asm,v 1.1 97/04/04 18:08:39 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


include grobjGeode.def

;------------------------------------------------------------------------------
;	Here comes the code...
;------------------------------------------------------------------------------
include	pointerUtils.asm
include	pointer.asm
include pointerRotate.asm
include pointerZoom.asm
