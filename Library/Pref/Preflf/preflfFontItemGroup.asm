COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		preflfFontItemGroup.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------
    INT SetFontAndPointSize	Sets the font and point size of a given
				GenText object.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/28/92   	Initial version.
        JimG	3/8/94		Added support for "editable text"
				options.

DESCRIPTION:
	

	$Id: preflfFontItemGroup.asm,v 1.1 97/04/05 01:29:26 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefFontItemGroupLoadOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Sets the value of the small size depending on the
		display type

PASS:		*ds:si	= PrefFontItemGroupClass object
		ds:di	= PrefFontItemGroupClass instance data
		es	= Segment of PrefFontItemGroupClass.

RETURN:		None

DESTROYED:	ax, cx, dx, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/21/92   	Initial version.
	JimG	3/7/94		Added code for "editable text" option.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefFontItemGroupLoadOptions	method	dynamic	PrefFontItemGroupClass, 
					MSG_META_LOAD_OPTIONS
	
	; Preserve ax & si for superclass call
	uses	ax,si
	.enter

	push	ds
	mov	ax, GDDT_VIDEO
	call    GeodeGetDefaultDriver   ;ax <- default video driver
	mov_tr	bx, ax
	call    GeodeInfoDriver         ;ds:si <- DriverInfoStruct
	cmp     ds:[si][VDI_pageH], LOW_RES_THRESHOLD
	mov	cx, FID_SIZE_SMALL
	ja	gotFont
	mov	cx, FID_SIZE_SMALL_CGA
gotFont:
	pop	ds
	; Set the identifier of the SMALL child to the current small
	; font point size, for both small font items.

	mov	si, offset SmallFontItem
	mov	ax, MSG_GEN_ITEM_SET_IDENTIFIER
	push	cx, ax
	call	ObjCallInstanceNoLock			; destroys: ax,cx,dx,bp
	pop	cx, ax
	mov	si, offset EditableSmallFontItem
	call	ObjCallInstanceNoLock

	; Now, call superclass

	.leave

	mov	di, offset PrefFontItemGroupClass
	GOTO	ObjCallSuperNoLock
PrefFontItemGroupLoadOptions	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefFontItemGroupSaveOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Saves modified options to init file.

PASS:		*ds:si	= PrefFontItemGroupClass object
		ds:di	= PrefFontItemGroupClass instance data
		es	= Segment of PrefFontItemGroupClass.

RETURN:		

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	
	Save the "fontsize" and "fontid" in the UI category.  If
	PFIGI_writeFontSizeKey is true, then this data is also
	stored in the SYSTEM category.


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/21/92   	Initial version.
	JimG	3/7/94		Now uses dynamic category/key names.
				Support for "editable text" selection.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefFontItemGroupSaveOptions	method	dynamic	PrefFontItemGroupClass, 
					MSG_META_SAVE_OPTIONS
	.enter

	mov	bx, di			; use bx for instance data access
	
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	call	ObjCallInstanceNoLock

	mov	di, offset smallFontName
	cmp	ax, FID_SIZE_SMALL
	je	doWrite

	mov	di, offset mediumFontName
	cmp	ax, FID_SIZE_MEDIUM
	je	doWrite

	mov	di, offset largeFontName

doWrite:
	;es - already dgroup
	
	;ax - point size
	;di - offset to font name string

	mov	bp, ax				; point size in bp for
						; InitFileWriteInteger
						
	; Only write to system if requested
	tst	ds:[bx].PFIGI_writeToSystemDefaults
	jz	afterWriteSystem
	
	push	ax, di, ds			; save point size &
						; font name & ds
	
	mov	cx, ds
	mov	si, ds:[bx].PFIGI_writeFontIDKey
	mov	dx, ds:[si]			; cx:dx <= key string
	mov	ax, segment dgroup
	mov	ds, ax
	mov	si, offset systemCatString	; ds:si <= category string
	call	InitFileWriteString		; es:di <= data string

	mov	ds, cx				; ds <= obj pointer
	mov	di, ds:[bx].PFIGI_writeFontSizeKey
	mov	dx, ds:[di]			; cx:dx <= key string
	mov	ds, ax				; ds <= dgroup,ds:si <= cat str
	call	InitFileWriteInteger		; bp <= int value

	pop	ax, di, ds			; restore point size &
						; font name & ds

afterWriteSystem:
	mov	si, ds:[bx].PFIGI_writeFontIDKey; ds:si <= cat string
	mov	dx, ds:[si]			; cx:dx <= key string
	mov	si, ds:[bx].PFIGI_writeCategory
	mov	si, ds:[si]
	mov	cx, ds				; es:di <= string data
	call	InitFileWriteString

	mov	di, ds:[bx].PFIGI_writeFontSizeKey
	mov	dx, ds:[di]			; cx:dx <= key string
	call	InitFileWriteInteger		; bp <= int value

	; set a flag for the UI to cause the state files to be nuke when
	; GEOS is restarted

	; cx, ds <= dgroup
	mov	cx, es
	mov	ds, cx
	
	mov	si, offset uiCategoryString
	mov	dx, offset tempDeleteStateFilesString
	mov	ax, TRUE
	call	InitFileWriteBoolean

	.leave
	ret
PrefFontItemGroupSaveOptions	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefFontItemGroupApply
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Called as the applyMsg of an object.  Updates the text
		associated with this object and possibly mirrors the update
		for the other text object.

CALLED BY:	MSG_PREF_FONT_ITEM_GROUP_APPLY
PASS:		*ds:si	= PrefFontItemGroupClass object
		ds:di	= PrefFontItemGroupClass instance data
		ds:bx	= PrefFontItemGroupClass object (same as *ds:si)
		es 	= segment of PrefFontItemGroupClass
		ax	= message #
		cx 	= point size
		
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	5/19/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefFontItemGroupApply	method dynamic PrefFontItemGroupClass, 
					MSG_PREF_FONT_ITEM_GROUP_APPLY
	.enter
	
	push	cx, si				; preserve size, self
	
	; send update text to myself first
	mov	ax, MSG_PREF_FONT_ITEM_GROUP_UPDATE_TEXT
	call	ObjCallInstanceNoLock

	; *ds:si points to editable font "same" boolean
	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
	mov	si, offset PrefLFEditableFontSameAsSystemGroup
	call	ObjCallInstanceNoLock		; Destroys: cx, dx, bp
	test	ax, mask PLFSBS_SAME_AS_SYSTEM_TEXT_SIZE
	pop	bx, si
	jz	done

	; need to update "mirrored" object
	mov	di, ds:[si]
	add	di, ds:[di].PrefFontItemGroup_offset
	mov	si, ds:[di].PFIGI_mirroredObject

	; change setting of mirrored object
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	cx, bx				; font size
	clr	dx
	call	ObjCallInstanceNoLock		; Destroys: ax, cx, dx, bp
	
	; force update of text for the mirrored object
	mov	ax, MSG_PREF_FONT_ITEM_GROUP_UPDATE_TEXT
	mov	cx, bx				; requires point size
	call	ObjCallInstanceNoLock		; Destroys: ax, cx, dx, bp
	
done:	
	.leave
	ret
PrefFontItemGroupApply	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefFontItemGroupUpdateText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Updates the text associated with the given
		PrefFontItemGroupClass object.

PASS:		*ds:si	= PrefFontItemGroupClass object
		ds:di	= PrefFontItemGroupClass instance data
		es	= dgroup
		cx 	= point size

RETURN:		None

DESTROYED:	cx, dx, ax, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/28/92   	Initial version.
        JimG	3/7/94		Use PFIGI_targetSampleText as target.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefFontItemGroupUpdateSpecific	method	dynamic PrefFontItemGroupClass,
				MSG_PREF_FONT_ITEM_GROUP_UPDATE_TEXT
	.enter

	mov	dx, cx		; current selection
	
	mov	bp, FID_SMALL
	cmp	dx, FID_SIZE_SMALL
	je	setSample

	mov	bp, FID_MEDIUM
	cmp	dx, FID_SIZE_MEDIUM
	je	setSample

	mov	bp, FID_LARGE

setSample:
	; The sample text IS in the same segment
	mov	si, ds:[di].PFIGI_targetSampleText.offset
	call	SetFontAndPointSize


	.leave
	ret
PrefFontItemGroupUpdateSpecific	endm






COMMENT @----------------------------------------------------------------------

FUNCTION:	SetFontAndPointSize

DESCRIPTION:	Sets the font and point size of a given GenText object.

CALLED BY:	INTERNAL

PASS:		*ds:si - GenText object to set
		bp - font id of font to change to
		dx - point size of font to change to

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DI

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/90		Initial version
	
------------------------------------------------------------------------------@

SetFontAndPointSize	proc	near
	uses	dx, bp
	.enter

	push	dx			; font size
	push	bp
	mov	ax, MSG_META_SUSPEND
	call	ObjCallInstanceNoLock
	pop	ax			; font ID

	;set font

	sub	sp, size VisTextSetFontIDParams
	mov	bp, sp
	mov	ss:[bp].VTSFIDP_fontID, ax
	mov	ax, MSG_VIS_TEXT_SET_FONT_ID
	mov	dx, size VisTextSetFontIDParams
	call	ObjCallInstanceNoLock
	add	sp, size VisTextSetFontIDParams
	pop	dx			; font size

	;set the point size

	sub	sp, size VisTextSetPointSizeParams
	mov	bp, sp
	mov	ss:[bp].VTSPSP_pointSize.WWF_frac, 0
	mov	ss:[bp].VTSPSP_pointSize.WWF_int, dx
	mov	ax, MSG_VIS_TEXT_SET_POINT_SIZE
	mov	dx, size VisTextSetPointSizeParams
	call	ObjCallInstanceNoLock
	add	sp, size VisTextSetPointSizeParams

	mov	ax, MSG_GEN_TEXT_SET_MODIFIED_STATE
	clr	cx				; not modified
	call	ObjCallInstanceNoLock

	mov	ax, MSG_META_UNSUSPEND
	call	ObjCallInstanceNoLock

	.leave
	ret
SetFontAndPointSize	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PreflfFontItemGroupReset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Handles a GEN_RESET message.

PASS:		*ds:si	- PrefFontItemGroupClass object
		ds:di	- PrefFontItemGroupClass instance data
		es	- dgroup

RETURN:		

DESTROYED:	ax, cx, dx, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	2/ 3/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PreflfFontItemGroupReset	method	dynamic	PrefFontItemGroupClass, 
					MSG_GEN_RESET
	mov	di, offset PrefFontItemGroupClass
	call	ObjCallSuperNoLock			; Destroys: ax,cx,dx,bp

	; Make sure we update the text for this item group.  Previously,
	; this sent a MSG_GEN_ITEM_GROUP_SEND_STATUS_MSG which will send an
	; MSG_PREF_FONT_ITEM_GROUP_APPLY message.  This will refer to the
	; "same" status to see if we should mirror the setting.  This is NOT
	; a good idea on a RESET since it may cause the settings to be reset
	; incorrectly.  Instead, we just send the UPDATE_TEXT message directly.
	
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	
	mov	cx, ds:[di].GIGI_selection		; pass selection
	mov	ax, MSG_PREF_FONT_ITEM_GROUP_UPDATE_TEXT
	GOTO	ObjCallInstanceNoLock
PreflfFontItemGroupReset	endm

