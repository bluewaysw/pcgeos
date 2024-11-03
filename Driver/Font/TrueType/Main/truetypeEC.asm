COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) blueway.Softworks 2021 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		TrueType Font Driver
FILE:		truetypeEC.asm

AUTHOR:		Falk Rehwagen, Jan 1, 2021

ROUTINES:
	Name			Description
	----			-----------
	ECNukeVariableBlock	nuke variables so we don't inadvertently
				re-use them

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	FR	1/24/21		Initial revision

DESCRIPTION:
	Error checking code for TrueType driver

	$Id: truetypeEC.asm,v 1.1 21/01/24 11:45:31 bluewaysw Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if ERROR_CHECK

CharMod	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECNukeVariableBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Nuke the TrueType variable block
CALLED BY:	NimbusStrategy()

PASS:		none
RETURN:		none
DESTROYED:	none (flags preserved)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	FR	1/29/21		Initial version

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
	mov	cx, (size TrueTypeVars)		;cx <- # of bytes
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


CharMod	ends

endif

