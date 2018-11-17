COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		Complete Communicator driver
FILE:		ccomTables.asm

AUTHOR:		Huan Le, Apr 29, 1993

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	HL	4/29/93   	Initial revision


DESCRIPTION:
	This file contains any printer specific fixed code tables

	$Id: ccomTables.asm,v 1.1 97/04/18 11:52:35 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
;--------------------------------------------------------------------------
;	Escape codes supported and routine table
;--------------------------------------------------------------------------

escCodes	label	word			; escape codes supported
	word	DR_PRINT_ESC_PREPEND_PAGE

NUM_ESC_ENTRIES	equ	($ - escCodes)/2


escHanJumpTable label	word
                hptr    handle  CommonCode

escOffJumpTable label	word
                word    offset  FaxInfoPrintCoverSheet
