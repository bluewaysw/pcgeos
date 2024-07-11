COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Legos
MODULE:		Fido Library
FILE:		manager.asm

AUTHOR:		Paul DuBois, Aug  5, 1994

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	8/ 5/94		Initial revision

DESCRIPTION:
	This file defines the entry point and a stupid test class.
	
	$Revision: 1.2 $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;%		Common geode includes
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

;include fidoGeod.def
;include fidoStr.def
include fidoint.def
include char.def			;for text modules
include Internal/heapInt.def		; for TPD_processHandle
include Internal/geodeStr.def		; GeodeHeader structure def
include geode.def			; GeodeAttrs record
include localize.def			; LocalStrSize

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;%		Code
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

include mtask.asm
include mmodule.asm
