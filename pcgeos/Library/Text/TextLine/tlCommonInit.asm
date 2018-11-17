COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		tlCommonInit.asm

AUTHOR:		John Wedgwood, Dec 31, 1991

ROUTINES:
	Name			Description
	----			-----------
	CommonInitLineAndField	Initialize a line/field	structure

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	12/31/91	Initial revision

DESCRIPTION:
	Code for initializing lines and fields.

	$Id: tlCommonInit.asm,v 1.1 97/04/07 11:20:30 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextInit	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CommonInitLineAndField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize a line and the first field in the line.

CALLED BY:	SmallStorageCreate, LargeStorageCreate
PASS:		*ds:si	= Instance ptr
		es:di	= Pointer to the line/field structure to fill in
RETURN:		Line/field initialized
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/31/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
INIT_LINE_FLAGS			=	mask LF_STARTS_PARAGRAPH or \
					mask LF_ENDS_PARAGRAPH or \
					mask LF_ENDS_IN_NULL

INIT_FIELD_TAB_REFERENCE	=	(TRT_OTHER shl offset TR_TYPE) or \
					RULER_TAB_TO_LINE_LEFT

CommonInitLineAndField	proc	far
	uses	ax
	.enter
	;
	; First do the line
	;
	mov	es:[di].LI_flags, INIT_LINE_FLAGS
	
	clr	ax
	clrwbf	es:[di].LI_hgt, ax
	clrwbf	es:[di].LI_blo, ax
	clrwbf	es:[di].LI_spacePad, ax
	mov	es:[di].LI_adjustment, ax
	
	;
	; Do the first field of the line
	;
	mov	es:[di].LI_firstField.FI_nChars, ax
	mov	es:[di].LI_firstField.FI_position, ax
	mov	es:[di].LI_firstField.FI_width, ax
	mov	es:[di].LI_firstField.FI_tab, INIT_FIELD_TAB_REFERENCE
	.leave
	ret
CommonInitLineAndField	endp


TextInit	ends
