COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		prefDynamicList.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/ 6/92   	Initial version.

DESCRIPTION:
	

	$Id: prefDynamicList.asm,v 1.1 97/04/04 17:50:21 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefDynamicListInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Send myself a MSG_PREF_DYNAMIC_LIST_BUILD_ARRAY

PASS:		*ds:si	= PrefDynamicListClass object
		ds:di	= PrefDynamicListClass instance data
		es	= dgroup

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	12/ 7/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefDynamicListInit	method	dynamic	PrefDynamicListClass, 
					MSG_PREF_INIT

	mov	di, offset PrefDynamicListClass
	call	ObjCallSuperNoLock
	
	mov	ax, MSG_PREF_DYNAMIC_LIST_BUILD_ARRAY
	GOTO	ObjCallInstanceNoLock
PrefDynamicListInit	endm






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefDynamicListLoadOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Read the init file string and store it in our instance
		data. 

PASS:		*ds:si	= PrefDynamicListClass object
		ds:di	= PrefDynamicListClass instance data
		es	= dgroup
		ss:bp	= GenOptionsParams

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	9/23/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefDynamicListLoadOptions	method	dynamic	PrefDynamicListClass, 
					MSG_GEN_LOAD_OPTIONS


		.enter

		push	ds, si
		mov	cx, ss
		mov	ds, cx
		lea	si, ss:[bp].GOP_category
		lea	dx, ss:[bp].GOP_key
		clr	bp		; allocate a block for us	
		call	InitFileReadString
		pop	ds, si
		jc	done

	;
	; Look for this string.  BP is still zero
	;
		call	MemLock
		mov_tr	cx, ax
		clr	dx

		mov	ax, MSG_PREF_DYNAMIC_LIST_FIND_ITEM
		call	ObjCallInstanceNoLock		; ax <- item #
		jc	afterSetSelection

		mov_tr	cx, ax
		mov	ax, MSG_PREF_ITEM_GROUP_SET_ORIGINAL_SELECTION
		call	ObjCallInstanceNoLock

afterSetSelection:
		call	MemFree

done:

		.leave
		ret
PrefDynamicListLoadOptions	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefDynamicListSaveOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	= PrefDynamicListClass object
		ds:di	= PrefDynamicListClass instance data
		es	= dgroup

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	9/23/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefDynamicListSaveOptions	method	dynamic	PrefDynamicListClass, 
					MSG_GEN_SAVE_OPTIONS

params	local	nptr.GenOptionsParams 	push	bp
SBCS <buffer	local	PREF_ITEM_GROUP_STRING_BUFFER_SIZE	dup (char)>
DBCS <buffer	local	PREF_ITEM_GROUP_STRING_BUFFER_SIZE	dup (wchar)>

	.enter

	push	bp
	mov	cx, ss
	lea	dx, ss:[buffer]
	mov	bp, length buffer
	mov	ax, MSG_PREF_ITEM_GROUP_GET_SELECTED_ITEM_TEXT
	call	ObjCallInstanceNoLock
	mov	ax, bp
	pop	bp
	
	tst	ax
	jz	done

	mov	cx, ss
	mov	ds, cx
	mov	es, cx
	lea	di, ss:[buffer]
	mov	bx, ss:[params]
	lea	si, ss:[bx].GOP_category
	lea	dx, ss:[bx].GOP_key
	push	bp
	call	InitFileWriteString
	pop	bp
done:
	.leave
	ret
PrefDynamicListSaveOptions	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	PrefDynamicListKbdChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Field a keypress when we have the focus.

CALLED BY:	MSG_META_KBD_CHAR, MSG_META_FUP_KBD_CHAR
PASS:		*ds:si	= PrefDynamicList object
	ds:di	= PrefDynamicListInstance structure
	cx	= character value
	dl	= CharFlags
	dh	= ShiftState
	bp.low	= ToggleState
	bp.high	= scan code

RETURN:		nothing

DESTROYED:	ax,cx,dx,bp

PSEUDO CODE/STRATEGY:
	

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/7/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefDynamicListKbdChar	method	dynamic PrefDynamicListClass, 
					MSG_META_KBD_CHAR,
					MSG_META_FUP_KBD_CHAR

	.enter

	;
	; If any modifier besides shift is down, or if the key is a control
	; key, pass it to our superclass to deal with -- we want only
	; straight printable characters here...
	; 
	test	dh, not (mask SS_LSHIFT or mask SS_RSHIFT)
	jnz	passItUp			; ignore all but these states
SBCS <	cmp	ch, CS_BSW						>
SBCS <	jne	passItUp						>
DBCS <	cmp	ch, CS_CONTROL_HB					>
DBCS <	je	passItUp						>
	test	dl, mask CF_RELEASE	; we work on presses only
	jnz	done

	; Add the character to the buffer

	mov	ax, TEMP_PDL_KBD_DATA
	call	ObjVarDerefData		; ds:bx - PDLKbdData

	call	PDLStopTimer

	; Start a new timer

	push	bx, cx
	mov	al, TIMER_EVENT_ONE_SHOT
	mov	bx, ds:[LMBH_handle]
	mov	cx, PDL_TIMER_INTERVAL
	mov	dx, MSG_PREF_DYNAMIC_LIST_TIMER
	call	TimerStart
	mov	dx, bx
	pop	bx, cx
	mov	ds:[bx].PDLKD_timerHandle, dx
	mov	ds:[bx].PDLKD_timerID, ax

	; If the buffer is already full, then do nothing.

	cmp	ds:[bx].PDLKD_count, PDL_CHAR_MAX_COUNT
	je	done

	lea	di, ds:[bx].PDLKD_buffer
SBCS <	add	di, ds:[bx].PDLKD_count					>
SBCS <	clr	ch			; null-terminate		>
DBCS <	mov	ax, ds:[bx].PDLKD_count					>
DBCS <	shl	ax, 1			; ax <- offset into buffer	>
DBCS <	add	di, ax			; di <- offset into buffer	>
	mov	ds:[di], cx		; store next character
DBCS <	mov	{wchar}ds:[di][2], 0	; null-terminate		>
	inc	ds:[bx].PDLKD_count

	mov	cx, ds
	lea	dx, ds:[bx].PDLKD_buffer
	mov	bp, TRUE		; ignore case
	mov	ax, MSG_PREF_DYNAMIC_LIST_FIND_ITEM
	call	ObjCallInstanceNoLock		; ax <- item
	mov_tr	cx, ax
	
	clr	dx
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	call	ObjCallInstanceNoLock

	mov	ax, MSG_GEN_ITEM_GROUP_SET_MODIFIED_STATE
	mov	cx, TRUE
	call	ObjCallInstanceNoLock

	; Send status message as well...

	mov	ax, MSG_GEN_ITEM_GROUP_SEND_STATUS_MSG
	mov	cx, TRUE
	call	ObjCallInstanceNoLock

done:
	.leave
	ret
passItUp:
	mov	di, offset PrefDynamicListClass
	GOTO	ObjCallSuperNoLock
PrefDynamicListKbdChar	endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PDLTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Nuke the buffer

PASS:		*ds:si	= PrefDynamicListClass object
		ds:di	= PrefDynamicListClass instance data
		es	= dgroup

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/23/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PDLTimer	method	dynamic	PrefDynamicListClass, 
					MSG_PREF_DYNAMIC_LIST_TIMER
	.enter

	mov	ax, TEMP_PDL_KBD_DATA
	call	ObjVarFindData
	jnc	done

	clr	ds:[bx].PDLKD_count
done:
	.leave
	ret
PDLTimer	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PDLVisClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Stop the timer

PASS:		*ds:si	= PrefDynamicListClass object
		ds:di	= PrefDynamicListClass instance data
		es	= dgroup

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/23/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PDLVisClose	method	dynamic	PrefDynamicListClass, 
					MSG_VIS_CLOSE
	uses	ax

	.enter
	mov	ax, TEMP_PDL_KBD_DATA
	call	ObjVarFindData		; ds:bx - data
	jnc	done
	call	PDLStopTimer
done:
	.leave

	mov	di, offset PrefDynamicListClass
	GOTO	ObjCallSuperNoLock
PDLVisClose	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PDLStopTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stop the timer

CALLED BY:	PDLVisClose, PDLKbdChar

PASS:		ds:bx - variable data

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/23/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PDLStopTimer	proc near
	uses	ax,bx,cx
	.enter

	clr	ax, cx
	xchg	ax, ds:[bx].PDLKD_timerID
	xchg	cx, ds:[bx].PDLKD_timerHandle
	tst	cx
	jz	afterStop
	mov	bx, cx
	call	TimerStop

afterStop:

	.leave
	ret
PDLStopTimer	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PDLInitializeVarData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Initialize the TEMP_PDL_KBD_DATA	

PASS:		*ds:si	= PrefDynamicListClass object
		ds:di	= PrefDynamicListClass instance data
		es	= dgroup
		cx 	= vardata type

RETURN:		ax - offset to vardata

DESTROYED:	cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/23/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PDLInitializeVarData	method	dynamic	PrefDynamicListClass, 
					MSG_META_INITIALIZE_VAR_DATA
	cmp	cx, TEMP_PDL_KBD_DATA
	jne	callSuper
	mov_tr	ax, cx
	mov	cx, size PDLKbdData
	call	ObjVarAddData
	mov_tr	ax, bx			; offset to data element

	ret

callSuper:
	mov	di, offset PrefDynamicListClass
	GOTO	ObjCallSuperNoLock
PDLInitializeVarData	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefDynamicListQueryItemMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	fetch an item moniker, since all PrefDynamicList
		subclasses are supposed to keep track of this sort of
		thing.

PASS:		*ds:si	= PrefDynamicListClass object
		ds:di	= PrefDynamicListClass instance data
		es	= dgroup
		bp	- item #

RETURN:		nothing 

DESTROYED:	ax,cx,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	12/10/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefDynamicListQueryItemMoniker	method	dynamic	PrefDynamicListClass, 
					MSG_GEN_DYNAMIC_LIST_QUERY_ITEM_MONIKER
	mov	ax, bp

SBCS <buffer		local	MAX_STRING_SIZE	dup (char)		>
DBCS <buffer		local	MAX_STRING_SIZE	dup (wchar)		>
getItemMonikerParams	local	GetItemMonikerParams

	.enter

	mov	ss:[getItemMonikerParams].GIMP_identifier, ax
	mov	ss:[getItemMonikerParams].GIMP_bufferSize, MAX_STRING_SIZE
	mov	ss:[getItemMonikerParams].GIMP_buffer.segment, ss
	lea	ax, ss:[buffer]
	mov	ss:[getItemMonikerParams].GIMP_buffer.offset, ax

	mov	ax, MSG_PREF_ITEM_GROUP_GET_ITEM_MONIKER
	push	bp
	lea	bp, ss:[getItemMonikerParams]
	call	ObjCallInstanceNoLock
	pop	bp

	push	bp
	mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_TEXT
	mov	cx, ss
	lea	dx, ss:[buffer]
	mov	bp, ss:[getItemMonikerParams].GIMP_identifier
	call	ObjCallInstanceNoLock
	pop	bp

	.leave
	ret
PrefDynamicListQueryItemMoniker	endm

