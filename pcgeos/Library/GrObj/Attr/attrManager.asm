COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Attr
FILE:		adminManager.asm

AUTHOR:		Steve Scholl, November 15, 1989

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ss      11/15/89        Initial revision.

DESCRIPTION:
	Manager for this module.

	$Id: attrManager.asm,v 1.1 97/04/04 18:07:06 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


include grobjGeode.def

;------------------------------------------------------------------------------
;	Include definitions.
;------------------------------------------------------------------------------

include attrConstant.def

;------------------------------------------------------------------------------
;	Local variables.
;------------------------------------------------------------------------------
include	attrVariable.def

;------------------------------------------------------------------------------
;	Here comes the code...
;------------------------------------------------------------------------------
include	attrArrays.asm
include	attr.asm
include	attrUtils.asm
include attrMgr.asm
include attrStyle.asm
include attrStyleDesc.asm
include attrStyleStrings.asm
include attrStyleMerge.asm
