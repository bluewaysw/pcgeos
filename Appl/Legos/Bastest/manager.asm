COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	Legos
MODULE:		bastest
FILE:		manager.asm

AUTHOR:		dubois, Nov  3, 1995

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	11/ 3/95   	Initial revision


DESCRIPTION:
	Stubs and such for bastest

	$Id: manager.asm,v 1.2 98/10/16 00:08:55 martin Exp $
	$Revision: 1.2 $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include geos.def
include geode.def
include ec.def
include stdapp.def


BCHACK	segment resource
SetGeosConvention

FILECOPYLOCAL_BT	proc	far	source:fptr, dest:fptr,\
					sDisk:hptr, dDisk:hptr
	uses si, di, ds, es
	.enter

	; load up the registers
	;
		lds	si, source
		les	di, dest
		mov	cx, sDisk
		mov	dx, dDisk

		call	FileCopyLocal
	.leave
	ret
FILECOPYLOCAL_BT	endp
public FILECOPYLOCAL_BT

SetDefaultConvention
BCHACK	ends
