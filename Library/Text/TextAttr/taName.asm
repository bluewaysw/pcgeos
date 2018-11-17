COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		User/Text
FILE:		textMethodType.asm

METHODS:
	Name				Description
	----				-----------
   GLB	MSG_VIS_TEXT_ADD_NAME		Adds a name to a name element array
					increasing ref count if it exists

   GLB	MSG_VIS_TEXT_FIND_NAME		Finds a name in a name element array

   GLB	MSG_VIS_TEXT_FIND_NAME_BY_TOKEN	Finds a name in a name element
					array given a name token

   GLB	MSG_VIS_TEXT_FIND_NAME_BY_INDEX	Finds a name in a name element
					array given a name index

   GLB	MSG_VIS_TEXT_REMOVE_NAME	Removes a name from a name element
					array decreasing ref count.


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version
	Benson	8/91		Changed parameters of VisTextAddName
				and bug fixes in AddNameCallback

DESCRIPTION:
	This file contains method handlers for type methods

	$Id: taName.asm,v 1.1 97/04/07 11:18:35 newdeal Exp $

------------------------------------------------------------------------------@

TextNameType segment resource

COMMENT @----------------------------------------------------------------------

METHOD:		VisTextAddName -- MSG_VIS_TEXT_ADD_NAME for VisTextClass

DESCRIPTION:	Add a name to the name array (or add a reference to an
		existing name).  Set the data for the name to the given data.
		If this data is different than existing data, the existing
		data is overwritten.

PASS: 	*ds:si - instance data (VisTextInstance)
	dx - size VisTextAddNameParams (if called remotely)
	ss:bp - VisTextAddNameParams

RETURN:
	ax - name token
	carry - set if name newly added
	dx - non-zero if newly added

DESTROYED:
	ax, bx, cx, dx, di, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version
	Benson	8/91		Change parameters

------------------------------------------------------------------------------@

VisTextAddName	proc	far		; MSG_VIS_TEXT_ADD_NAME
	class	VisTextClass

if ERROR_CHECK
	;
	; Validate that the name is not in a movable code segment
	;
FXIP<	push	bx, si							>
FXIP<	mov	bx, ss:[bp].VTANP_name.segment				>
FXIP<	mov	si, ss:[bp].VTANP_name.offset				>
FXIP<	call	ECAssertValidFarPointerXIP				>
FXIP<	pop	bx, si							>
endif

	; Get the name array for manipulation

	call	LockNameArray			; *ds:si - name array
	push	bx				; save flag

	les	di, ss:[bp].VTANP_name		;es:di = name
	mov	cx, ss:[bp].VTANP_size
	mov	bx, ss:[bp].VTANP_flags
	mov	dx, ss
	lea	ax, ss:[bp].VTANP_data
	call	NameArrayAdd

	pop	bx
	call	UnlockNameArray

	mov	dx, 0				;assume not newly added
	jnc	done
	inc	dx				;preserves carry
done:

	ret

VisTextAddName	endp

COMMENT @----------------------------------------------------------------------

METHOD:		VisTextFindName -- MSG_VIS_TEXT_FIND_NAME for
					VisTextClass

DESCRIPTION:	Find a name in the name array

PASS:
	*ds:si - instance data
	es - segment of VisTextClass

	ss:bp - VisTextFindNameParams

RETURN:
	carry - set if name found
	ax - token found (CA_NULL_ELEMENT if not found)

DESTROYED:
	bx, si, di, ds, es (method handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	7/16/91		Initial version

------------------------------------------------------------------------------@

VisTextFindName	proc	far		; MSG_VIS_TEXT_FIND_NAME
	class	VisTextClass
	uses	cx, dx
	.enter

if ERROR_CHECK
	;
	; Validate that the name is not in a movable code segment
	;
FXIP<	push	bx, si							>
FXIP<	movdw	bxsi, ss:[bp].VTFNP_name				>
FXIP<	call	ECAssertValidFarPointerXIP				>
FXIP<	pop	bx, si							>
endif

	; Get the name array for manipulation

	call	LockNameArray			; *ds:si - name array
	push	bx				; save vm file

	les	di, ss:[bp].VTFNP_name		;es:di = name to find
	mov	cx, ss:[bp].VTFNP_size
	movdw	dxax, ss:[bp].VTFNP_data	;dx:ax <- ptr to buffer
	call	NameArrayFind

	pop	bx				; restore vm file
	call	UnlockNameArray			; clean up

	.leave
	ret

VisTextFindName	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	VisTextFindNameByToken -- MSG_VIS_TEXT_FIND_NAME_BY_TOKEN
							for VisTextClass

DESCRIPTION:	Given a name token return the associated data

PASS:
	*ds:si - instance data
	es - segment of VisTextClass

	ax - The message

	cx:dx - buffer
	bp - token

RETURN:
	buffer - filled
	carry set if not found

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	7/31/91		Initial version
	Benson	8/91		Bug fixes.
------------------------------------------------------------------------------@
VisTextFindNameByToken	proc	far	; MSG_VIS_TEXT_FIND_NAME_BY_TOKEN
	class	VisTextClass

	; Get the name array for manipulation

	call	LockNameArray			; *ds:si - name array

	; Get the element data

	mov_tr	ax, bp				; ax = token
	call	ChunkArrayGetElement

	call	UnlockNameArray			; clean up
	ret

VisTextFindNameByToken	endp


COMMENT @----------------------------------------------------------------------

MESSAGE:	VisTextFindNameByIndex -- MSG_VIS_TEXT_FIND_NAME_BY_INDEX
							for VisTextClass

DESCRIPTION:	Given a name index return the associated data

PASS:
	*ds:si - instance data
	es - segment of VisTextClass

	ax - The message

	ss:bp - VisTextFindNameIndexParams

RETURN:
	ax - token for index, or CA_NULL_ELEMENT if name not found
	buffer - filled

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	6/30/94		Initial version

------------------------------------------------------------------------------@
VisTextFindNameByIndex	proc	far	; MSG_VIS_TEXT_FIND_NAME_BY_INDEX
	class	VisTextClass
	uses	cx,dx	
	.enter

	; Get the name array for manipulation

	call	LockNameArray			; *ds:si - name array

	mov	ax, ss:[bp].VTFNIP_index
	mov	dx, ss:[bp].VTFNIP_file
	mov	cl, ss:[bp].VTFNIP_type
	call	NameToToken
	jnc	notFound

	; Get the element data, if it is desired

	movdw	cxdx, ss:[bp].VTFNIP_name
	tstdw	cxdx
	jz	done	
	push	ax
	call	ChunkArrayGetElement
	pop	ax
done:
	call	UnlockNameArray			; clean up
	.leave
	ret
notFound:
	mov	ax, CA_NULL_ELEMENT
	jmp	done	
VisTextFindNameByIndex	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	VisTextAddRefForName -- MSG_VIS_TEXT_ADD_REF_FOR_NAME
							for VisTextClass

DESCRIPTION:	Add a reference for a name

PASS:
	*ds:si - instance data
	es - segment of VisTextClass

	ax - The message

	cx - token

RETURN:
	none

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	7/31/91		Initial version
	Benson	8/91		Bug fixes.
------------------------------------------------------------------------------@
VisTextAddRefForName	proc	far	; MSG_VIS_TEXT_ADD_REF_FOR_NAME
	class	VisTextClass

	; Get the name array for manipulation

	call	LockNameArray			; *ds:si - name array

	; Get the element data

	mov_tr	ax, cx				; ax = token
	call	ElementArrayAddReference

	call	UnlockNameArray			; clean up
	ret

VisTextAddRefForName	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextRemoveName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove a given name from the name array

CALLED BY:	MSG_VIS_TEXT_REMOVE_NAME
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of VisTextClass
		ax - the message

		cx - token of name to remove

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	7/16/91		Initial version
	gene	9/ 2/92		fixed, updated comments

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VisTextRemoveName	proc	far	; MSG_VIS_TEXT_REMOVE_NAME
	class	VisTextClass
	;
	; Get the name array for manipulation
	;
	call	LockNameArray			; *ds:si - name array
	push	bx				; save vm file
	;
	; Remove reference to the name
	;
	mov_tr	ax, cx				; ax - name token
	call	ElementArrayDelete		; remove name

	pop	bx				; restore vm file
	call	UnlockNameArray			; clean up
	Destroy ax, cx, dx, bp
	ret
VisTextRemoveName	endp

;-----------------------------------------------------------------------------
;		Utility routines below here
;-----------------------------------------------------------------------------



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LockNameArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock the name array for a text object

CALLED BY:	UTILITY
PASS:		*ds:si - VisTextInstance
RETURN:		*ds:si - element array
		bx - value to pass UnlockNameArray()
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version
	gene	9/ 7/92		rewrote

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FarLockNameArray		proc	far
	call	LockNameArray
	ret
FarLockNameArray		endp

LockNameArray		proc	near
	uses	ax, di, bp
	.enter
	class	VisTextClass

EC <	call	T_AssertIsVisText					>

	call	GetNameArray
EC <	ERROR_NC VIS_TEXT_OBJECT_MUST_HAVE_NAME_ARRAY 			>
	jnz	large

	mov	bx, ax				;bx <- not VM

done:
	mov	si, di				;*ds:si <- name array
	.leave
	ret

large:
	call	T_GetVMFile			;bx <- VM file
	call	VMLock
	mov	ds, ax				;ds <- seg addr of names
	mov	bx, bp				;bx <- VM handle for unlock
	jmp	done
LockNameArray		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetNameArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the name array for a text object

CALLED BY:	LockNameArray(), GenNameNotify()
PASS:		*ds:si - text object
RETURN:		carry - clear if no names
		z flag - clear (jnz) if a large text object
		    di - flag for name array
		    ax - VM handle of array
		else:
		    di - chunk of name array
		    ax - 0
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetNameArray		proc	near
	uses	bx
	class	VisTextClass

	.enter

EC <	call	T_AssertIsVisText					>

	;
	; Find the name array
	;
	mov	ax, ATTR_VIS_TEXT_NAME_ARRAY
	call	ObjVarFindData
	jnc	done				;branch if no names
	mov	ax, ds:[bx]
	;
	; The name array is stored differently depending on whether
	; we're a small text object or a large text object.
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE
	jnz	large
	;
	; this is a small object -- it *might* still have VM blocks for the
	; name array, we have to look and see

	mov	bx, ds:[di].VTI_charAttrRuns
	mov	bx, ds:[bx]			;ds:bx = TextRunArrayHeader
	tst	ds:[bx].TRAH_elementVMBlock
	jnz	large
	mov_tr	di, ax				;di <- chunk of name array
	mov	ax, 0				;ax <- not VM

done:
	stc					;carry <- have names
	.leave
	ret

	;
	; We're in a large text object, so the name array is in a huge array
	; which is in a VM block.
	;
large:
	mov	di, VM_ELEMENT_ARRAY_CHUNK	;di <- flag for name array
	jmp	done
GetNameArray		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UnlockNameArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlock the name array for a text object

CALLED BY:	UTILITY
PASS:		bx - value from LockNameArray()
RETURN:		none
DESTROYED:	none (flags preserved)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/27/91		Initial version
	gene	9/ 7/92		rewrote & commented

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FarUnlockNameArray		proc	far
	call	UnlockNameArray
	ret
FarUnlockNameArray		endp

UnlockNameArray		proc	near
	uses	bp
	.enter
	pushf

	tst	bx				;VM handle?
	jz	notVM				;branch if not VM handle
	mov	bp, bx				;bp <- VM handle
	call	VMUnlock
notVM:

	popf
	.leave
	ret
UnlockNameArray		endp

TextNameType ends
