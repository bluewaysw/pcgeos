COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Legos
MODULE:		Fido Library
FILE:		etable.asm

AUTHOR:		Paul L. DuBois, Sep 19, 1994

ROUTINES:
	Name			Description
	----			-----------
    GLB FidoUnlockComponentInfoTable
				Unlock component info table.

    GLB FidoLockComponentInfoTable
				Lock component info table

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	9/19/94   	Initial revision


DESCRIPTION:
	Exported routines for messing with the exported component table.

	$Revision: 1.2 $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TableCode	segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FidoUnlockComponentInfoTable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlock component info table.

CALLED BY:	GLOBAL

PASS:		ax	= handle of library
		bx	= vseg of table
RETURN:		nothing
DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	9/14/94    	Pulled out of FidoProcessLibrary

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FidoUnlockComponentInfoTable	proc	far
if GENERAL_FIDO
		.enter
		call	MemUnlockFixedOrMovable
		mov_tr	bx, ax
		call	GeodeFreeLibrary
		.leave
else
EC <		ERROR	FIDO_ROUTINE_EXISTS_IN_GENERAL_FIDO_ONLY	>
endif
		ret
FidoUnlockComponentInfoTable	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FidoLockComponentInfoTable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock component info table

CALLED BY:	GLOBAL
PASS:		ds:si	= FileLongName of library
RETURN:		ax	= handle of library
		bx 	= vseg of table
		ds:si	= table of pointers to EntClassPtrStruct
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	9/14/94    	Pulled out of FidoProcessLibrary

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FidoLockComponentInfoTable	proc	far
if GENERAL_FIDO
		.enter
		clr	ax		; don't care about protocol #
		call	GeodeUseLibrary
		jc	errorDone
		push	bx		; save library handle
	;
	; Lock block containing table of exported components down,
	; put fptr into ds:bx.	Save the vseg off so we can unlock
	; it later...
	;
		mov	ax, ENT_TABLE_ENTRY_NUMBER
		call	ProcGetLibraryEntry	; bx:ax = vfptr to table

		mov	si, ax
		call	MemLockFixedOrMovable
EC <		ERROR_C BARK_YELP_YELP				>
		mov	ds, ax		; ds:si = classPtrTable
		pop	ax		; ax = library handle
		clc
errorDone:
		.leave
else
EC <		ERROR	FIDO_ROUTINE_EXISTS_IN_GENERAL_FIDO_ONLY	>
endif
		ret
FidoLockComponentInfoTable	endp

TableCode	ends
