COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		nimbusEC.asm
FILE:		nimbusEC.asm

AUTHOR:		Gene Anderson, Apr 17, 1992

ROUTINES:
	Name			Description
	----			-----------
	ECNukeVariableBlock	nuke variables so we don't inadvertently
				re-use them

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	4/17/92		Initial revision

DESCRIPTION:
	Error checking code for Nimbus driver

	$Id: nimbusEC.asm,v 1.1 97/04/18 11:45:31 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if ERROR_CHECK

CharMod	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECNukeVariableBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Nuke the Nimbus variable block
CALLED BY:	NimbusStrategy()

PASS:		none
RETURN:		none
DESTROYED:	none (flags preserved)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/17/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ECNukeVariableBlock	proc	far
	uses	ax, bx, cx, di, es
	.enter

	pushf

	;
	; Lock the variable block
	;
	mov	ax, segment udata
	mov	es, ax				;es <- seg addr of idata
	mov	bx, es:variableHandle		;bx <- handle of vars
	tst	bx				;block freed?
	jz	done				;branch if freed
	call	MemLock
	jc	done				;branch if discarded
	mov	es, ax				;es <- seg addr of vars
	;
	; Zero the block
	;
	clr	al				;al <- byte to store
	mov	cx, (size NimbusVars)		;cx <- # of bytes
	clr	di				;es:di <- ptr to vars
	rep	stosb
	;
	; Nuke things we know are segments specially
	;
	mov	es:fontSegment, 0xa000
	mov	es:gstateSegment, 0xa000
	mov	es:infoSegment, 0xa000
	;
	; All done...
	;
	call	MemUnlock
done:

	popf

	.leave
	ret
ECNukeVariableBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckFontSegment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check that the font segment has been initialized
CALLED BY:	UTILITY

PASS:		none
RETURN:		none
DESTROYED:	none (flags preserved)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/17/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ECCheckFontSegment	proc	far
	uses	ax, bx, ds, es
	.enter
	pushf

	call	LockNimbusVars
	mov	ds, ax				;ds <- seg addr of vars
	;
	; Make sure the font segment is reasonable
	;
	mov	ax, ds:fontSegment
	cmp	ax, 0xa000
	ERROR_E	NIMBUS_VARS_UNINITIALIZED
	mov	es, ax				;es <- seg addr of font
	cmp	es:FB_maker, FM_NIMBUSQ
	ERROR_NE NIMBUS_CALLED_WITH_NON_NIMBUS_FONT

	call	MemUnlock

	popf
	.leave
	ret
ECCheckFontSegment	endp

ECCheckFontHandle	proc	far
	uses	ax, bx, ds, es
	.enter
	pushf

	call	LockNimbusVars
	mov	ds, ax				;ds <- seg addr of vars
	push	bx
	;
	; Make sure the font handle is reasonable
	;
	mov	bx, ds:fontHandle
	tst	bx
	ERROR_Z	NIMBUS_VARS_UNINITIALIZED
	call	MemDerefES			;es <- seg addr of font handle
	mov	ax, es
	cmp	ds:fontSegment, ax		;match seg addr of font?
	ERROR_NE NIMBUS_VARS_UNINITIALIZED

	pop	bx
	call	MemUnlock

	popf
	.leave
	ret
ECCheckFontHandle	endp

ECCheckGStateSegment	proc	far
	uses	ax, bx, di, ds, es
	.enter
	pushf

	call	LockNimbusVars
	;
	; Make sure the GState segment is reasonable
	;
	mov	ax, ds:gstateSegment
	cmp	ax, 0xa000
	ERROR_E	NIMBUS_VARS_UNINITIALIZED
	mov	ds, ax				;ds <- seg addr of GState
	mov	di, ds:LMBH_handle		;di <- handle of GState
	call	ECCheckGStateHandle

	call	MemUnlock

	popf
	.leave
	ret
ECCheckGStateSegment	endp

ECCheckInfoSegment	proc	far
	uses	ax, bx, ds, es
	.enter
	pushf

	call	LockNimbusVars
	mov	ds, ax				;ds <- seg addr of vars

	mov	ax, ds:infoSegment		;ax <- seg addr of info
	cmp	ax, 0xa000
	ERROR_E	NIMBUS_VARS_UNINITIALIZED
	mov	es, ax
	cmp	es:LMBH_lmemType, LMEM_TYPE_FONT_BLK
	ERROR_NE NIMBUS_NOT_PASSED_INFO_BLOCK

	call	MemUnlock

	popf
	.leave
	ret
ECCheckInfoSegment	endp

ECCheckFirstChar	proc	far
if not DBCS_PCGEOS
	uses	ax, bx, ds
	.enter
	pushf

	call	LockNimbusVars
	mov	ds, ax

	tst	ds:firstChar
	ERROR_Z	NIMBUS_VARS_UNINITIALIZED

	call	MemUnlock

	popf
	.leave
endif
	ret
ECCheckFirstChar	endp

CharMod	ends

endif

