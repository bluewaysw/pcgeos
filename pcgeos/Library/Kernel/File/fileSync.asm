COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel/File -- Synchronization
FILE:		fileSync.asm

AUTHOR:		Adam de Boor, Apr  5, 1990

ROUTINES:
	Name			Description
	----			-----------
	PFileList		Gain exclusive access to the list of open
				files.
	VFileList		Release exclusive access to the list of
				open files.

REVISION HISTORY:
	Adam	4/ 5/90		Initial revision


DESCRIPTION:
	Synchronization primitives for the File module
		

	$Id: fileSync.asm,v 1.1 97/04/05 01:11:43 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PFileList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gain exclusive access to the list of open files.

CALLED BY:	INTERNAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	flags

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/15/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PFileListFar	proc	far
		call	PFileList
		ret
PFileListFar	endp

PFileList	proc	near
		push	bx, ax, ds
		call	FSLoadVarSegDS
		PSem	ds, fileListSem, TRASH_AX_BX, NO_EC
		pop	bx, ax, ds
		ret
PFileList	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VFileList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Release exclusive access to the list of open files.

CALLED BY:	INTERNAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing (flags preserved)

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/15/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VFileListFar	proc	far
		call	VFileList
		ret
VFileListFar	endp

VFileList	proc	near
		pushf
		push	bx, ax, ds
		call	FSLoadVarSegDS
		VSem	ds, fileListSem, TRASH_AX_BX, NO_EC
		pop	bx, ax, ds
		popf
		ret
VFileList	endp
