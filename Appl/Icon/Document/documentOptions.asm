COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Icon Editor
FILE:		documentOptions.asm

AUTHOR:		Steve Yegge, Apr  8, 1993

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	4/ 8/93		Initial revision

DESCRIPTION:

	Code to implement various options in the Options menu.

	$Id: documentOptions.asm,v 1.1 97/04/04 16:06:05 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


OptionsCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IASetOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends options to all documents.

CALLED BY:	MSG_ICON_APPLICATION_SET_OPTIONS

PASS:		*ds:si	= IconApplicationClass object
		ds:di	= IconApplicationClass instance data

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	4/23/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IASetOptions	method dynamic IconApplicationClass, 
					MSG_ICON_APPLICATION_SET_OPTIONS
		uses	ax, cx, dx, bp
		.enter
	;
	;  Get the options.
	;
		GetResourceHandleNS	OptionsBooleanGroup, bx
		mov	si, offset	OptionsBooleanGroup
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
		call	ObjMessage
	;
	;  Record a classed event for the options.
	;
		mov_tr	cx, ax				; cx = options
		GetResourceSegmentNS	DBViewerClass, es
		mov	bx, es
		mov	si, offset	DBViewerClass
		mov	ax, MSG_DB_VIEWER_SET_OPTIONS
		mov	di, mask MF_RECORD
		call	ObjMessage			; ^hdi = event
	;
	;  Send the options to each document
	;
		mov	cx, di				; ^hcx = event
		GetResourceHandleNS	IconDocumentGroup, bx
		mov	si, offset	IconDocumentGroup
		clr	di
		mov	ax, MSG_GEN_SEND_TO_CHILDREN
		call	ObjMessage
		
		.leave
		ret
IASetOptions	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBViewerSetOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deals with the user changing an option in the options menu.

CALLED BY:	MSG_DB_VIEWER_SET_OPTIONS

PASS:		*ds:si	= DBViewer object
		ds:di	= DBViewerInstance
		cx	= IconOptions

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	9/29/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBViewerSetOptions	method dynamic DBViewerClass,
					MSG_DB_VIEWER_SET_OPTIONS

		call	ViewerSetDatabase
		call	ViewerSetFormatArea		; deal with that option
		call	ViewerSetFatbits		; deal with fatbits

		ret
DBViewerSetOptions	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ViewerSetFormatArea
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Shows or hides the format area

CALLED BY:	DBViewerSetOptions

PASS:		*ds:si	= DBViewer object
		ds:di	= DBViewerInstance
		cx = selected booleans

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

 	Set the format view usable or not-usable, depending on the
	passed option.  The catch is, we resize the primary if it's
	set not-usable, to keep the blank space from just generally 
	loooking ugly.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	10/26/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ViewerSetFormatArea	proc	near
		class	DBViewerClass
		uses	ax,bx,cx,dx,si,di,bp
		.enter
		
		test	cx, mask IO_SHOW_FORMAT		; mask out other bits
		jnz	setUsable
	;
	;  Set format view not-usable
	;
		mov	ax, MSG_GEN_SET_NOT_USABLE
		jmp	short	setIt
setUsable:
		mov	ax, MSG_GEN_SET_USABLE
setIt:
		mov	bx, ds:[di].GDI_display
		mov	si, offset FormatView
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	dl, VUM_NOW
		call	ObjMessage

		.leave
		ret
ViewerSetFormatArea	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ViewerSetFatbits
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Shows or hides the fatbits

CALLED BY:	DBViewerSetOptions

PASS:		*ds:si	= DBViewer object
		ds:di	= DBViewerInstance
		cx = selected booleans

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- sets the fatbits usable or not-usable
	- if they were set not-usable, redraw the primary
	  (turning off the fatbits has a large effect on
	   the geometry; redrawing the primary may help it
	   out some.)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	10/26/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ViewerSetFatbits	proc	near
		class	DBViewerClass
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	;  See what the user's doing with the fatbits
	;
		test	cx, mask IO_SHOW_FATBITS
		jnz	setFatbitsUsable
		
		mov	ax, MSG_GEN_SET_NOT_USABLE
		jmp	short	setThem
		
setFatbitsUsable:
		mov	ax, MSG_GEN_SET_USABLE 
setThem:
		mov	bx, ds:[di].GDI_display
		mov	si, offset FatbitsView
		mov	di, mask MF_CALL
		mov	dl, VUM_NOW
		call	ObjMessage

		.leave
		ret
ViewerSetFatbits	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ViewerSetDatabase
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Shows or hides the database viewer.

CALLED BY:	DBViewerSetOptions

PASS:		*ds:si	= DBViewer object
		ds:di	= DBViewerInstance
		cx	= selected booleans

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	4/ 8/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ViewerSetDatabase	proc	near
		class	DBViewerClass
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	;  See whether we should show them or hide them.
	;
		test	cx, mask IO_SHOW_DATABASE
		jnz	setUsable
	;
	;  Do it.
	;
		mov	ax, MSG_GEN_SET_NOT_USABLE
		jmp	short	setIt
setUsable:
		mov	ax, MSG_GEN_SET_USABLE
setIt:
		mov	bx, ds:[di].GDI_display
		mov	si, offset IconDBView
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	dl, VUM_NOW
		call	ObjMessage

		.leave
		ret
ViewerSetDatabase	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBViewerSetFormatOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Basically pops in or out the format list.

CALLED BY:	MSG_DB_VIEWER_SET_FORMAT_OPTIONS

PASS:		*ds:si	= DBViewerClass object
		ds:di	= DBViewerClass instance data
		cx	= FormatOptions

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	4/24/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBViewerSetFormatOptions	method dynamic DBViewerClass, 
					MSG_DB_VIEWER_SET_FORMAT_OPTIONS
		uses	ax, cx, dx, bp
		.enter

		call	PopFormatList

		.leave
		ret
DBViewerSetFormatOptions	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PopFormatList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	pops out or pops in the format view interaction

CALLED BY:	DBViewerSetFormatOptions

PASS:		*ds:si	= DBViewer object
		ds:di	= DBViewerInstance
		cx = options (selected booleans)

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	11/25/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PopFormatList	proc	near
		class	DBViewerClass
		uses	ax,bx,cx,dx,si,di,bp
		.enter
		
		test	cx, mask FO_FLOATING_FORMATS	; isolate our bit
		jz	popin
	;
	;  Pop out the format list
	;
		mov	ax, MSG_GEN_INTERACTION_POP_OUT
		jmp	short	setIt
popin:
		mov	ax, MSG_GEN_INTERACTION_POP_IN
setIt:
		mov	bx, ds:[di].GDI_display
		mov	si, offset FormatViewGroup
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage

		.leave
		ret
PopFormatList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IASaveOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	save-options handler for IconApplicationClass

CALLED BY:	MSG_META_SAVE_OPTIONS

PASS:		*ds:si	= IconApplicationClass object
		ds:di	= IconApplicationClass instance data

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	4/14/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IASaveOptions	method dynamic IconApplicationClass, 
					MSG_META_SAVE_OPTIONS
		.enter

		call	IconMarkBusy
	;
	;  Call the superclass.
	;
		mov	di, offset IconApplicationClass
		call	ObjCallSuperNoLock
	;
	;  Get the show/hide options.
	;
		push	si
		GetResourceHandleNS	OptionsBooleanGroup, bx
		mov	si, offset	OptionsBooleanGroup
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
		call	ObjMessage
		pop	si
		
		mov	bp, ax			; bp <- options
	;
	;  Get our category.
	;
		sub	sp, INI_CATEGORY_BUFFER_SIZE
		movdw	cxdx, sssp

		push	bp			; save options
		mov	ax, MSG_META_GET_INI_CATEGORY
		call	ObjCallInstanceNoLock
		pop	bp			; restore options
	;
	;  Write the show/hide options.
	;
		mov	ax, sp

		push	si, ds
		segmov	ds, ss
		mov_tr	si, ax			; ds:si = category
		mov	cx, cs
		mov	dx, offset featuresKey
		call	InitFileWriteInteger
	;
	;  Write the current fatbit size.
	;
		mov	dx, offset IBSKey	; cx:dx = key
		call	IconAppGetImageBitSize	; ax = ImageBitSize
		mov_tr	bp, ax
		call	InitFileWriteInteger
		pop	si, ds

		add	sp, INI_CATEGORY_BUFFER_SIZE

		call	IconMarkNotBusy

		.leave
		ret

featuresKey	char	"features", 0
IBSKey		char	"imageBitSize", 0
		
IASaveOptions	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IALoadOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load our options from the ini file.

CALLED BY:	MSG_META_LOAD_OPTIONS

PASS:		*ds:si	= IconApplicationClass object
		ds:di	= IconApplicationClass instance data

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	4/14/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IALoadOptions	method dynamic IconApplicationClass, 
					MSG_META_LOAD_OPTIONS
		.enter
	;
	;  Call the superclass.
	;
		mov	di, offset IconApplicationClass
		call	ObjCallSuperNoLock
	;		
	;  Get the ini file category.
	;
		sub	sp, INI_CATEGORY_BUFFER_SIZE
		movdw	cxdx, sssp
		
		mov	ax, MSG_META_GET_INI_CATEGORY
		call	ObjCallInstanceNoLock
		
		mov	ax, sp
		
		push	si, ds
		segmov	ds, ss
		mov_tr	si, ax
		mov	cx, cs
		mov	dx, offset featuresKey
		call	InitFileReadInteger
		jc	doneFeatures
	;
	;  Set the options in the boolean group.
	;
		call	SetBooleans
doneFeatures:
		mov	dx, offset IBSKey
		call	InitFileReadInteger
		pop	si, ds			; instance
		mov	bp, sp
		lea	sp, ss:[bp+INI_CATEGORY_BUFFER_SIZE]
		jc	doneFatbits
	;
	;  Set the fatbit size.
	;
		call	SetFatbits
doneFatbits:
	;
	;  tools.
	;
		.leave
		ret
IALoadOptions	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetBooleans
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets options in OptionsBooleanGroup

CALLED BY:	IALoadOptions

PASS:		ax	= booleans

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	4/14/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetBooleans	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		.enter

		GetResourceHandleNS	OptionsBooleanGroup, bx
		mov	si, offset	OptionsBooleanGroup
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov_tr	cx, ax
		clr	dx
		mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
		call	ObjMessage

		.leave
		ret
SetBooleans	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetFatbits
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the fatbit size in FatbitImageSizeGroup

CALLED BY:	IALoadOptions

PASS:		ax	= fatbit size

RETURN:		nothing 
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	4/14/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetFatbits	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		.enter

		GetResourceHandleNS	FatbitImageSizeGroup, bx
		mov	si, offset	FatbitImageSizeGroup
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov_tr	cx, ax
		clr	dx
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		call	ObjMessage

		.leave
		ret
SetFatbits	endp


OptionsCode	ends


