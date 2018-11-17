COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GrObjVis
FILE:		grobjVissManager.asm

AUTHOR:		Steve Scholl, November 15, 1989

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ss      11/15/89        Initial revision.

DESCRIPTION:
	Manager for this module.

	$Id: grobjvisManager.asm,v 1.1 97/04/04 18:08:47 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


include grobjGeode.def

;------------------------------------------------------------------------------
;	Include definitions.
;------------------------------------------------------------------------------

include grobjVisConstant.def

;------------------------------------------------------------------------------
;	Local variables.
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;	Here comes the code...
;------------------------------------------------------------------------------
include grobjVis.asm
include grobjBitmap.asm
include grobjSpline.asm
include grobjText.asm
