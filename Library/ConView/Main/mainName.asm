COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Condo viewer
MODULE:		main - view and text
FILE:		mainName.asm

AUTHOR:		Jonathan Magasin, May 10, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	5/10/94   	Initial revision


DESCRIPTION:
	Content code for dealing with name array.
		

	$Id: mainName.asm,v 1.1 97/04/04 17:49:23 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


BookFileCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MNSetNameArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the VM handle of the name array

CALLED BY:	UTILITY
PASS:		*ds:si - ContentGenView
		ax - VM handle of name array
		di - CTRF_searchText flag
RETURN:		none
DESTROYED:	di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/26/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MNSetNameArray		proc	far
		class	ContentGenViewClass
		uses	bx
		.enter
EC <		call	AssertIsCGV				>

		test	di, mask CTRF_searchText
		jnz	searchText
		mov	di, ds:[si]
		add	di, ds:[di].ContentGenView_offset
		mov	ds:[di].CGVI_nameArrayVM, ax	
done:
		.leave
		ret
searchText:
		push	ax
		mov	ax, CONTENT_SEARCH_DATA
		call	ObjVarFindData
EC <		ERROR_NC -1						>
		pop	ds:[bx].CSD_nameArrayVM
		jmp	done		
MNSetNameArray		endp

BookFileCode	ends


ContentLibraryCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MNLockNameArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock the name array

CALLED BY:	MNFindNameForContext()
PASS:		*ds:si - ContentGenView instance
		ax - ContentTextRequestFlags
		     CTRF_searchText if should lock search text's name array
RETURN:		*ds:si - name array
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/25/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MNLockNameArray		proc	far
	uses	ax, bx, bp
	.enter
EC <	call	AssertIsCGV				>

	call	MFGetFile			;bx <- handle of help file
	call	MNGetNameArray			;ax <- VM handle of names
	call	VMLock
	mov	ds, ax
	mov	si, VM_ELEMENT_ARRAY_CHUNK	;*ds:si <- name array

	.leave
	ret
MNLockNameArray		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MNUnlockNameArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlock the name array

CALLED BY:	MNFindNameForContext()
PASS:		ds - seg addr of name array
RETURN:		none
DESTROYED:	none (flags preserved)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/25/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MNUnlockNameArray		proc	far
	uses	bp
	.enter

	mov	bp, ds:LMBH_handle		;bp <- memory handle of names
	call	VMUnlock

	.leave
	ret
MNUnlockNameArray		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MNGetNameArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the name array for the current file

CALLED BY:	UTILITY
PASS:		*ds:si <- ContentGenView instance
		ax - ContentTextRequestFlags
		     CTRF_searchText if should lock search text's name array
RETURN:		ax - VM handle of name array
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/26/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MNGetNameArray		proc	near
		uses	bx,di
		class	ContentGenViewClass
		.enter
EC <		call	AssertIsCGV				>

		test	ax, mask CTRF_searchText
		jnz	searchText
		mov	di, ds:[si]
		add	di, ds:[di].ContentGenView_offset
		mov	ax, ds:[di].CGVI_nameArrayVM
done:
		.leave
		ret
searchText:
		mov	ax, CONTENT_SEARCH_DATA
		call	ObjVarFindData
EC <		ERROR_NC	-1					>
		mov	ax, ds:[bx].CSD_nameArrayVM
		jmp	done
		
MNGetNameArray		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MNGetName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the Nth name

CALLED BY:	UTILITY
PASS:		*ds:si - name array
		es:di - ptr to buffer for name
		ax - # of name to get
RETURN:		es:di - filled in
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/28/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MNGetName		proc	far
	uses	cx, dx, ds, si, bp, di
	.enter

	;
	; We round the size (up) to a word size to keep swat happy
	;
	sub	sp, (((size NameArrayMaxElement)+1) and 0xfffe)
	;
	; Get the name & data
	;
	mov	dx, sp
	mov	cx, ss				;cx:dx <- ptr to buffer
	call	ChunkArrayGetElement
EC <	cmp	ax, (size RefElementHeader)	;>
EC <	ERROR_E HELP_LINK_TO_NO_WHERE		;>
	;
	; Copy the name
	;
	mov	si, ds:[si]			;ds:si <- ptr to array header
	mov	cx, ds:[si].NAH_dataSize	;cx <- size of our data
	add	cx, (size NameArrayElement)	;cx <- + size of name element
	mov	si, dx
	add	si, cx
	segmov	ds, ss				;ds:si <- ptr to name
	xchg	cx, ax				;cx <- size of element
	sub	cx, ax				;cx <- size of name
EC <	cmp	cx, FILE_LONGNAME_LENGTH	;>
EC <	ERROR_A HELP_NAME_TOO_LONG		;>
	rep	movsb				;copy me jesus
	;
	; NULL-terminate the name
	;
	clr	ax				;ax <- NULL
	LocalPutChar	esdi, ax		;NULL-terminate

	add	sp, (((size NameArrayMaxElement)+1) and 0xfffe)

	.leave
	ret
MNGetName		endp



ContentLibraryCode	ends
