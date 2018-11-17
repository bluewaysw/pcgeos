COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		prefBooleanGroup.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/25/92   	Initial version.

DESCRIPTION:
	

	$Id: prefBooleanGroup.asm,v 1.2 98/04/24 01:20:53 gene Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefBooleanGroupHasStateChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	= PrefBooleanGroupClass object
		ds:di	= PrefBooleanGroupClass instance data
		es	= Segment of PrefBooleanGroupClass.

RETURN:		IF CHANGE:
			CARRY SET
		ELSE
			CARRY CLEAR

DESTROYED:	ax, cx, dx, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/21/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefBooleanGroupHasStateChanged	method	dynamic	PrefBooleanGroupClass, 
					MSG_PREF_HAS_STATE_CHANGED

	.enter

	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
	call	ObjCallInstanceNoLock

	mov	di, ds:[si]
	add	di, ds:[di].Pref_offset

	cmp	ax, ds:[di].PBGI_originalState
	je	done			; carry clear
	stc
done:
	.leave
	ret

PrefBooleanGroupHasStateChanged	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefBooleanGroupReset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	= PrefBooleanGroupClass object
		ds:di	= PrefBooleanGroupClass instance data
		es	= Segment of PrefBooleanGroupClass.

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/ 2/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefBooleanGroupReset	method	dynamic	PrefBooleanGroupClass, 
					MSG_GEN_RESET
	.enter

	mov	cx, ds:[di].PBGI_originalState
	clr	dx
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
	call	ObjCallInstanceNoLock

	.leave
	ret
PrefBooleanGroupReset	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefBooleanGroupLoadOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	handle the higher-level part

PASS:		*ds:si	= PrefBooleanGroupClass object
		ds:di	= PrefBooleanGroupClass instance data
		es	= Segment of PrefBooleanGroupClass.

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/12/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefBooleanGroupLoadOptions	method	dynamic	PrefBooleanGroupClass, 
					MSG_META_LOAD_OPTIONS
	.enter

	; Do the low-level stuff first.

	push	ax
	mov	di, offset PrefBooleanGroupClass
	call	ObjCallSuperNoLock
	pop	ax

	call	LoadOrSaveBooleanGroup

	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
	call	ObjCallInstanceNoLock

	mov	di, ds:[si]
	add	di, ds:[di].Pref_offset
	mov	ds:[di].PBGI_originalState, ax

	;
	; Send out status message as well.
	;

	mov	ax, MSG_GEN_BOOLEAN_GROUP_SEND_STATUS_MSG
	clr	cx			; No "changed" boolean to go with this
					;  msg.  If our superclass changed
					;  anything while loading options, it
					;  would've sent a status msg already.
	call	ObjCallInstanceNoLock


	.leave
	ret
PrefBooleanGroupLoadOptions	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefBooleanGroupSetOriginalSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Set the original state for the boolean group

PASS:		*ds:si	= PrefBooleanGroupClass object
		ds:di	= PrefBooleanGroupClass instance data
		es	= Segment of PrefBooleanGroupClass.
		cx	= selection

RETURN:		nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/22/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefBooleanGroupSetOriginalSelection	method	dynamic	PrefBooleanGroupClass, 
				MSG_PREF_BOOLEAN_GROUP_SET_ORIGINAL_STATE

	uses	ax,cx,dx,bp
	.enter
	mov	ds:[di].PBGI_originalState, cx
	clr	dx			; no indeterminates
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
	call	ObjCallInstanceNoLock

	.leave
	ret
PrefBooleanGroupSetOriginalSelection	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefBooleanGroupSaveOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Save or load our options

PASS:		*ds:si	= PrefBooleanGroupClass object
		ds:di	= PrefBooleanGroupClass instance data
		es	= Segment of PrefBooleanGroupClass.

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	4/20/98 	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefBooleanGroupSaveOptions	method	dynamic	PrefBooleanGroupClass, 
					MSG_META_SAVE_OPTIONS
		call	LoadOrSaveBooleanGroup
		jc	haveSeparate
	;
	; No separate keys -- just do a standard save
	;
notSeparate::
		mov	ax, dx
		mov	di, offset PrefBooleanGroupClass
		call	ObjCallSuperNoLock
haveSeparate:
		ret
PrefBooleanGroupSaveOptions	endm

LoadOrSaveBooleanGroup	proc	near
		mov	dx, ax				;dx <- message
	;
	; See if there are separate keys
	;
		mov	ax, ATTR_PREF_BOOLEAN_GROUP_SEPARATE_BOOLEAN_KEYS
		call	ObjVarFindData
		jnc	notSeparate
	;
	; Separate keys -- save each boolean child separately
	;
		mov	ax, dx
		call	GenSendToChildren
		stc					;carry <- separate
notSeparate:
		ret
LoadOrSaveBooleanGroup	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefBooleanSaveOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Save our options

PASS:		*ds:si	= PrefBooleanClass object
		ds:di	= PrefBooleanClass instance data
		es	= Segment of PrefBooleanClass

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	4/20/98 	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefBooleanSaveOptions	method	dynamic	PrefBooleanClass, 
					MSG_META_SAVE_OPTIONS
gop		local	GenOptionsParams
curState	local	word
		.enter
ForceRef	gop
	;
	; Get our current state
	;
		push	bp
		mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
		call	GenCallParent
		pop	bp
		mov	di, ds:[si]
		add	di, ds:[di].GenBoolean_offset
		and	ax, ds:[di].GBI_identifier
		mov	ss:curState, ax
	;
	; Get the category and key
	;
		call	GetCatAndKey
		jnc	done				;branch if no key
	;
	; Write the value
	;
		mov	ax, ss:curState			;ax <- zero/non-zero
		call	InitFileWriteBoolean
done:
		.leave
		ret
PrefBooleanSaveOptions	endm

GetCatAndKey	proc	near
		.enter	inherit PrefBooleanSaveOptions
	;
	; Get the category
	;
		push	bp
		mov	cx, ss
		lea	dx, ss:gop.GOP_category
		mov	ax, MSG_META_GET_INI_CATEGORY
		mov	di, offset PrefBooleanClass
		call	ObjCallSuperNoLock
		pop	bp
	;
	; Get the key
	;
		mov	ax, ATTR_GEN_INIT_FILE_KEY
		call	ObjVarFindData
		mov	cx, ds
		mov	dx, bx				;cx:dx <- key
		segmov	ds, ss
		lea	si, ss:gop.GOP_category		;ds:si <- category

		.leave
		ret
GetCatAndKey	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefBooleanLoadOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Load our options

PASS:		*ds:si	= PrefBooleanClass object
		ds:di	= PrefBooleanClass instance data
		es	= Segment of PrefBooleanClass

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	4/20/98 	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefBooleanLoadOptions	method	dynamic	PrefBooleanClass, 
					MSG_META_LOAD_OPTIONS
gop		local	GenOptionsParams
curState	local	word
		.enter

ForceRef	gop
ForceRef	curState

	;
	; Get the category and key
	;
		push	si
		call	GetCatAndKey
	;
	; Read the value
	;
		call	InitFileReadBoolean
		pop	si
		mov	ds, cx
		jc	done				;branch if no key
	;
	; Set the value in our parent
	;
		push	bp
		mov	di, ds:[si]
		add	di, ds:[di].GenBoolean_offset
		mov	cx, ds:[di].GBI_identifier	;cx <- our ID
		mov	dx, ax				;dx <- zero/non-zero
		mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_BOOLEAN_STATE
		call	GenCallParent
		pop	bp
done:
		.leave
		ret
PrefBooleanLoadOptions	endm
