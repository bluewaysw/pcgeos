COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	Pasta	
MODULE:		Fax
FILE:		group3Tables.asm

AUTHOR:		Andy Chiu, Oct  2, 1993

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	10/ 2/93   	Initial revision


DESCRIPTION:
	This file contains any printer specific fixed code tables
		

	$Id: group3Tables.asm,v 1.1 97/04/18 11:52:59 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
;--------------------------------------------------------------------------
;	Escape codes supported and routine table
;--------------------------------------------------------------------------

if 1
escCodes	label	word			; escape codes supported
	word	DR_PRINT_ESC_PREPEND_PAGE

NUM_ESC_ENTRIES	equ	($ - escCodes)/2


escHanJumpTable hptr	handle CommonCode

escOffJumpTable nptr.far	\
			FaxInfoPrintCoverSheet

endif


