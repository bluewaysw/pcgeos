COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	GEOS Preferences
MODULE:		PrefLF
FILE:		preflfSameBooleanGroup.asm

AUTHOR:		Jim Guggemos, May 19, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	5/19/94   	Initial revision


DESCRIPTION:
	Contains methods/reoutines for PrefLFSameBooleanGroupClass.
		

	$Id: preflfSameBooleanGroup.asm,v 1.1 97/04/05 01:29:33 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefLFSameBooleanGroupVisOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the state of the object.

CALLED BY:	MSG_VIS_OPEN
PASS:		*ds:si	= PrefLFSameBooleanGroupClass object
		ds:di	= PrefLFSameBooleanGroupClass instance data
		ds:bx	= PrefLFSameBooleanGroupClass object (same as *ds:si)
		es 	= segment of PrefLFSameBooleanGroupClass
		ax	= message #
		bp	= 0 if top window, else window for object to open on

RETURN:		None
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	5/19/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefLFSameBooleanGroupVisOpen	method dynamic PrefLFSameBooleanGroupClass, 
					MSG_VIS_OPEN
	push	bp				; save for call super
	
	call	PrefLFSetSameObject
	
	; Call superclass
	
	mov	di, offset PrefLFSameBooleanGroupClass
	pop	bp				; restore initial arg

	mov	ax, MSG_VIS_OPEN
	GOTO	ObjCallSuperNoLock
PrefLFSameBooleanGroupVisOpen	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefLFSameBooleanGroupReset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Resets group based upon font item groups state

CALLED BY:	MSG_GEN_RESET
PASS:		*ds:si	= PrefLFSameBooleanGroupClass object
		ds:di	= PrefLFSameBooleanGroupClass instance data
		ds:bx	= PrefLFSameBooleanGroupClass object (same as *ds:si)
		es 	= segment of PrefLFSameBooleanGroupClass
		ax	= message #

RETURN:		Nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	5/20/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefLFSameBooleanGroupReset	method dynamic PrefLFSameBooleanGroupClass, 
					MSG_GEN_RESET
	.enter
	mov	di, offset PrefLFSameBooleanGroupClass
	call	ObjCallSuperNoLock
	
	; update value based on font items
	call	PrefLFSetSameObject
	.leave
	ret
PrefLFSameBooleanGroupReset	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefLFSetSameObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the "Same as system font" object based upon the setting
		of the font item groups.

CALLED BY:	PrefLFSameBooleanGroupVisOpen, PrefLFSameBooleanGroupReset
PASS:		*ds:si	= PrefLFSameBooleanGroupClass object
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	5/20/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefLFSetSameObject	proc	near
	.enter
	
	; Decide whether to clear or set the bit
	call	PrefLFGetFontSizeValues			; Destroys: cx,dx,bp
	clr	dx					; Default to FALSE
	cmp	ax, bx
	jne	setBit
	dec	dx					; Whoops - it's TRUE

setBit:
	; otherwise, set the selected booleans for this boolean group
	
	mov	cx, mask PLFSBS_SAME_AS_SYSTEM_TEXT_SIZE
	
	; *ds:si points to self
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_BOOLEAN_STATE
	call	ObjCallInstanceNoLock		; Destroys: ax, cx, dx, bp

	.leave
	ret
PrefLFSetSameObject	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefLFSameBooleanGroupUpdate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Updates the editable text font item group based upon value.

CALLED BY:	MSG_PREFLF_SAME_BOOLEAN_GROUP_UPDATE
PASS:		*ds:si	= PrefLFSameBooleanGroupClass object
		ds:di	= PrefLFSameBooleanGroupClass instance data
		ds:bx	= PrefLFSameBooleanGroupClass object (same as *ds:si)
		es 	= segment of PrefLFSameBooleanGroupClass
		ax	= message #
		cx	= value of selected booleans (PrefLFSameBooleanState)

RETURN:		None
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	5/19/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefLFSameBooleanGroupUpdate	method dynamic PrefLFSameBooleanGroupClass, 
					MSG_PREFLF_SAME_BOOLEAN_GROUP_UPDATE
	.enter
	
	test	cx, mask PLFSBS_SAME_AS_SYSTEM_TEXT_SIZE
	jz	done

	; set to be the same.. make sure that they are the same
	call	PrefLFGetFontSizeValues		; ax = edit text size
						; bx = sys text size
	cmp	ax, bx
	je	done				; already the same, we're done
	
	; okay.. set the editable font size to be the same as the
	; system text size
	
	; *ds:si points to editable font size item group
	mov	si, offset PrefLFEditableFontItemGroup
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	cx, bx				; set to system text font
	clr	dx
	call	ObjCallInstanceNoLock		; Destroys: ax, cx, dx, bp
	
	; force update of text for the editable font
	mov	ax, MSG_PREF_FONT_ITEM_GROUP_UPDATE_TEXT
	mov	cx, bx				; requires point size
	call	ObjCallInstanceNoLock		; Destroys: ax, cx, dx, bp

done:
	.leave
	ret
PrefLFSameBooleanGroupUpdate	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefLFGetFontSizeValues
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the system and editable text font sizes


CALLED BY:	PrefLFSameBooleanGroupUpdate, PrefLFSetSameObject
PASS:		ds = segment containing the item groups

RETURN:		ax = editable text point size
		bx = system text point size

DESTROYED:	cx, dx, bp
SIDE EFFECTS:	
	May invalidate ptrs to instance data.
	
PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	5/19/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefLFGetFontSizeValues	proc	near
	uses	si
	.enter
	
	; *ds:si points to system font size item group
	mov	si, offset PrefLFFontItemGroup
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	call	ObjCallInstanceNoLock		; Destroys: cx, dx, bp
	mov	bx, ax				; store result
	
	; *ds:si points to editable font size item group
	mov	si, offset PrefLFEditableFontItemGroup
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	call	ObjCallInstanceNoLock		; Destroys: cx, dx, bp
	
	.leave
	ret
PrefLFGetFontSizeValues	endp

