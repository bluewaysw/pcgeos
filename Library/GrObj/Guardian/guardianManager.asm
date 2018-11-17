COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Guaridian
FILE:		guardianManager.asm

AUTHOR:		Steve Scholl, November 15, 1989

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ss      11/15/89        Initial revision.

DESCRIPTION:
	Manager for this module.

	$Id: guardianManager.asm,v 1.1 97/04/04 18:08:57 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


include grobjGeode.def

;------------------------------------------------------------------------------
;	Include definitions.
;------------------------------------------------------------------------------

include guardianConstant.def

;------------------------------------------------------------------------------
;	Local variables.
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;	Here comes the code...
;------------------------------------------------------------------------------
include grobjVisGuardian.asm
include grobjVisGuardianTransfer.asm
include bitmapGuardian.asm
include splineGuardian.asm
include textGuardian.asm
include multTextGuardian.asm
include editTextGuardian.asm
