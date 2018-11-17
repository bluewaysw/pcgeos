COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		ccomremPDL.asm

AUTHOR:		Adam de Boor, Sep 28, 1993

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	9/28/93		Initial revision


DESCRIPTION:
	Empty PDL functions that keep the spooler from doing too much work
	for us when we've copied the spool file over wholesale.
		

	$Id: ccomremPDL.asm,v 1.1 97/04/18 11:52:47 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FaxPrintGString	proc	far
	mov	ax, GSRT_COMPLETE
	clc
	ret
FaxPrintGString	endp

FaxSetPageTransform proc far
	clc
	ret
FaxSetPageTransform endp
