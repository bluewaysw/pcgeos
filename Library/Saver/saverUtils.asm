COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		saverUtils.asm

AUTHOR:		Adam de Boor, Dec  9, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	12/ 9/92	Initial revision


DESCRIPTION:
	Utility routines for internal and external use.
		

	$Id: saverUtils.asm,v 1.1 97/04/07 10:44:32 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SaverUtilsCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SaverCreateLaunchBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create an AppLaunchBlock to use for a master saver.

CALLED BY:	(GLOBAL)
PASS:		bp	= disk handle on which saver is located
		cx:dx	= path to saver
		ds	= some segment that can be fixed up
RETURN:		bx	= AppLaunchBlock handle
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 9/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SaverCreateLaunchBlock proc	far
		uses	si, di, cx, dx, bp, es
		.enter
	;
	; Create a default launch block using the IACP function of the
	; same name.
	; 
		push	cx, dx
		mov	dx, MSG_GEN_PROCESS_OPEN_APPLICATION
		call	IACPCreateDefaultLaunchBlock
	;
	; Now copy the path into the AppInstanceReference stored therein.
	; 
		xchg	bx, dx
		pop	cx, si
		push	ds
		mov	ds, cx
		call	MemLock
		mov	es, ax
		ornf	es:[ALB_launchFlags], mask ALF_NO_ACTIVATION_DIALOG
		mov	es:[ALB_appRef].AIR_diskHandle, bp
		mov	di, offset ALB_appRef.AIR_fileName
copyName:
if DBCS_PCGEOS
		lodsw
		stosw
		tst	ax
else
		lodsb
		stosb
		tst	al
endif
		jnz	copyName
		pop	ds
	;
	; Locate the system field to which the saver will want to attach, so
	; it doesn't get biffed when one leaves the current field.
	; 
		push	bx		; save ALB handle
		
		mov	cx, SEGMENT_CS
		mov	dx, offset SULocateSystemField
		mov	bp, es		; bp <- ax for callback
		mov	ax, MSG_GEN_SYSTEM_FOREACH_FIELD
		call	UserCallSystem
	;
	; All set.
	; 
		pop	bx
		call	MemUnlock	
		.leave
		ret
SaverCreateLaunchBlock endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SULocateSystemField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Record the passed field as the one to which we should
		attach, on the assumption it's the last, i.e. the system,
		field.

CALLED BY:	SaverCreateLaunchBlock via MSG_GEN_SYSTEM_FOREACH_FIELD
PASS:		^lbx:si	= field
		ax	= segment of AppLaunchBlock
RETURN:		carry set to stop enumerating
DESTROYED:	es

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/25/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SULocateSystemField proc	far
		.enter
		mov	es, ax
		mov	es:[ALB_genParent].handle, bx
		mov	es:[ALB_genParent].chunk, si
		clc
		.leave
		ret
SULocateSystemField endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SaverDuplicateALB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make a copy of the given block of memory.

CALLED BY:	(GLOBAL)
PASS:		bx	= handle of block to duplicate
RETURN:		dx	= old handle
		bx	= new handle
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/12/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SaverDuplicateALB 	proc	far
		uses	ax, ds, si, di, es, cx
		.enter
	;
	; Figure the size of the block.
	; 
		mov	ax, MGIT_SIZE
		call	MemGetInfo
		push	ax		; save for copy
	;
	; Allocate another the same size, locked. (XXX: pass NO_ERR flag.
	; Ought to be able to handle an error more gracefully, but I have
	; no time to code it -- ardeb 11/23/92)
	; 
		mov	dx, bx
		mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK or mask HF_SHARABLE
		call	MemAlloc
		mov	es, ax
	;
	; Lock down the source block.
	; 
		xchg	bx, dx
		call	MemLock
		mov	ds, ax
	;
	; Copy the contents from the old to the new.
	; 
		clr	si, di
		pop	cx
		shr	cx
		rep	movsw
	;
	; Unlock the old.
	; 
		call	MemUnlock
	;
	; Unlock the new.
	; 
		xchg	bx, dx
		call	MemUnlock
		.leave
		ret
SaverDuplicateALB endp

SaverUtilsCode	ends
