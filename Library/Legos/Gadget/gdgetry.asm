COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Group Of Objects Library
MODULE:		gadget
FILE:		gadgetEntry.asm

AUTHOR:		David Loftesness, Jun 28, 1994

ROUTINES:
	Name			Description
	----			-----------
    MTD MSG_ENT_INITIALIZE	arrange our guts the way we wants 'em

    MTD MSG_META_RESOLVE_VARIANT_SUPERCLASS
				Inform the system of our association to
				GenText

    MTD MSG_GADGET_ENTRY_GET_TEXT
				Gets the text from the entry and copies it
				to the runtime heap.

    MTD MSG_GADGET_ENTRY_SET_TEXT
				Set the text stored in the entry.

    MTD MSG_ENT_GET_CLASS	return "entry"

    MTD MSG_GADGET_ENTRY_APPLY	

    MTD MSG_ENT_DESTROY		zero out VTI_output so it doesn't cause
				problems

    MTD MSG_VIS_TEXT_FILTER_VIA_REPLACE_PARAMS
				Sent to filter characters because the user
				wants to. This will generate a basic event.

    MTD MSG_GADGET_ENTRY_SET_FILTER
				Sets the filter for the text object

    MTD MSG_GADGET_ENTRY_GET_FILTER
				

    MTD MSG_VIS_TEXT_FILTER_VIA_CHARACTER
				Used to filter new strings a char at a
				time.

    MTD MSG_GADGET_ENTRY_GET_MAX_CHARS
				

    MTD MSG_GADGET_ENTRY_SET_MAX_CHARS
				

    MTD MSG_GADGET_ENTRY_GET_NUM_CHARS
				

    MTD MSG_GADGET_ENTRY_SET_NUM_CHARS
				return a readonly property error

    MTD MSG_GADGET_CLIPBOARDABLE_RAISE_ACCEPT_PASTE_EVENT,
	MSG_GADGET_CLIPBOARDABLE_UPDATE_CLIPBOARDS
				Some clipboardable messages should be
				intercepted and dropped because the entry
				component and clipboard take care of things
				internally.

    MTD MSG_GADGET_CLIPBOARDABLE_CLIPBOARD_ITEM_CHANGED
				Entry components should not raise an
				acceptPaste event when the clipboard
				changes (as do other clipboardables).

    MTD MSG_META_CLIPBOARD_CUT,
	MSG_META_CLIPBOARD_COPY,
	MSG_META_CLIPBOARD_PASTE,
	MSG_META_DELETE		The text object in us knows how to handle
				clipboard events. So have the superclass
				handle the received clipboard message, but
				skip the clipboardable handler because it
				will raise an event.

    MTD MSG_GADGET_SET_HEIGHT	Entries need a little extra vertical space
				so that they can draw their frame.  Make
				sure that they are at least three pixels
				high.

    MTD MSG_META_END_SELECT	Hack to change END_SELECT to
				LARGE_END_SELECT

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	6/28/94   	Initial revision


DESCRIPTION:
	Entries are fairly straight forward. They call some text
	routines for dealing with filters.  They also do a fair amount
	of work to deal with clipboard issues.  It subclass
	GadgetTextSpecClass to save the filter property.  Text objects
	store the filter in Vis intance data not Gen, which is likely
	to be unbuilt, so it must be stored elsewhere.
		

	$Id: gdgetry.asm,v 1.1 98/03/11 04:30:26 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
idata	segment
	GadgetEntryClass
idata	ends
	;
	; property data
	;

GadgetTextCode segment resource

; Define new properties.
makePropEntry entry, text, LT_TYPE_STRING,	\
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_ENTRY_GET_TEXT>, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_ENTRY_SET_TEXT>
	
makePropEntry entry, filter, LT_TYPE_INTEGER,	\
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_ENTRY_GET_FILTER>, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_ENTRY_SET_FILTER>

makePropEntry entry, maxChars, LT_TYPE_INTEGER, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_ENTRY_GET_MAX_CHARS> \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_ENTRY_SET_MAX_CHARS>

makePropEntry entry, numChars, LT_TYPE_INTEGER, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_ENTRY_GET_NUM_CHARS> \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_ENTRY_SET_NUM_CHARS>

; Get rid of the unsupported clipboardable API.
makeUndefinedPropEntry entry, focusable
makeUndefinedPropEntry entry, clipboardable
makeUndefinedPropEntry entry, deletable
makeUndefinedPropEntry entry, copyable

makeUndefinedPropEntry entry, readOnly
makeUndefinedPropEntry entry, caption
makeUndefinedPropEntry entry, graphic


compMkPropTable GadgetEntryProperty, entry, text, filter, maxChars,numChars, \
focusable, clipboardable, deletable, copyable, readOnly, caption, graphic

MakePropRoutines Entry, entry	
	;
	; action data
	;


GadgetInitCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetEntryEntInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	arrange our guts the way we wants 'em

CALLED BY:	MSG_ENT_INITIALIZE
PASS:		*ds:si	= GadgetEntryClass object
		ds:di	= GadgetEntryClass instance data
		ds:bx	= GadgetEntryClass object (same as *ds:si)
		es 	= segment of GadgetEntryClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	6/28/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetEntryEntInitialize	method dynamic GadgetEntryClass, 
					MSG_ENT_INITIALIZE
		uses	bp
		.enter

	;
	; GadgetClipboardableClass regulates focus/target behavior based
	; on CF_focusable and CF_clipboardable.  Set those here.  (Note
	; that the subset of the clipboardable API supported by text
	; excludes these properties.
	;
		or	ds:[di].GCLI_flags, \
			mask CF_focusable or mask CF_clipboardable
		
	;
	; Now call superclass. 
	;
		mov	di, offset GadgetEntryClass
		call	ObjCallSuperNoLock

	;
	; Make single line, use tab for navigation.
	;
		mov	ax, MSG_GEN_TEXT_SET_ATTRS
		clr	cx
		mov	cl, mask GTA_SINGLE_LINE_TEXT or \
			mask GTA_USE_TAB_FOR_NAVIGATION
		call	ObjCallInstanceNoLock
	;
	; Set the apply message and destination to be the object itself
	;
		mov	ax, MSG_GEN_TEXT_SET_DESTINATION
		mov	cx, ds:[LMBH_handle]
		mov	dx, si
		call	ObjCallInstanceNoLock

		mov	ax, MSG_GEN_TEXT_SET_APPLY_MSG
		mov	cx, MSG_GADGET_ENTRY_APPLY
		call	ObjCallInstanceNoLock
	;
	; Set max chars to 250
	;
		mov	ax, MSG_VIS_TEXT_SET_MAX_LENGTH
		mov	cx, GADGET_ENTRY_MAX_CHARS
		call	ObjCallInstanceNoLock

		mov	cx, SpecWidth <SST_PIXELS, 144>
		mov	dx, SpecHeight <SST_PIXELS, 16>
		call	SetTextSize

	;
	; Keep it small
		mov	ax, HINT_TEXT_DO_NOT_MAKE_LARGER_ON_PEN_SYSTEMS
		clr	cx
		call	ObjVarAddData

		mov	ax, ATTR_GEN_SEND_APPLY_MSG_ON_APPLY_EVEN_IF_NOT_MODIFIED
		clr	cx
		call	ObjVarAddData
	
			
	.leave
	ret
GadgetEntryEntInitialize	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetEntryMetaResolveVariantSuperclass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Inform the system of our association to GenText

CALLED BY:	MSG_META_RESOLVE_VARIANT_SUPERCLASS
PASS:		*ds:si	= GadgetEntryClass object
		ds:di	= GadgetEntryClass instance data
		ds:bx	= GadgetEntryClass object (same as *ds:si)
		es 	= segment of GadgetEntryClass
		ax	= message #
RETURN:		cx:dx	= superclass to use
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
 	----	----		-----------
	dloft	6/30/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetEntryMetaResolveVariantSuperclass	method dynamic GadgetEntryClass, 
					MSG_META_RESOLVE_VARIANT_SUPERCLASS
	.enter
 
	cmp	cx, Ent_offset
	je	returnSuper

	mov	di, offset GadgetEntryClass
	call	ObjCallSuperNoLock
done:
 	.leave
	ret

returnSuper:
	mov	cx, segment GadgetTextSpecClass
 	mov	dx, offset GadgetTextSpecClass
	jmp	done

GadgetEntryMetaResolveVariantSuperclass	endm

GadgetInitCode	ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetEntryGetText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the text from the entry and copies it to the runtime
		heap.

CALLED BY:	MSG_GADGET_ENTRY_GET_TEXT
PASS:		*ds:si	= GadgetEntryClass object
		ds:di	= GadgetEntryClass instance data
		ds:bx	= GadgetEntryClass object (same as *ds:si)
		es 	= segment of GadgetEntryClass
		ax	= message #
		on stack:	GetPropertyArgs
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	9/13/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetEntryGetText	method dynamic GadgetEntryClass, 
					MSG_GADGET_ENTRY_GET_TEXT
		uses	es, di
		.enter
	;
	; Figure out how big the text is.
	;
		mov	ax, MSG_VIS_TEXT_GET_TEXT_SIZE
		call	ObjCallInstanceNoLock
		inc	ax		; include null
DBCS <		shl	ax		; it gets length, not size!	>
	;
	; Allocate space for the string on the runtime heap.
	;
		clr	cx
		sub	sp, size RunHeapAllocStruct
		mov	bx, sp
		movdw	ss:[bx].RHAS_data, cxcx		; none
		mov	ss:[bx].RHAS_size, ax
		mov	ss:[bx].RHAS_refCount, cl	; init to 0 ref count
		mov	ss:[bx].RHAS_type, RHT_STRING
		Assert	fptr	ssbp
		movdw	cxdx, ss:[bp].GPA_runHeapInfoPtr
		movdw	ss:[bx].RHAS_rhi, cxdx
		call	RunHeapAlloc
		mov	bx, sp
		movdw	cxdx, ss:[bx].RHAS_rhi

		add	sp, size RunHeapAllocStruct

	;
	; Store the data
	; ax = token
		sub	sp, size RunHeapLockStruct
		mov	bx, sp
		movdw	ss:[bx].RHLS_rhi, cxdx
		lea	dx, ss:[bx].RHLS_eptr
		movdw	ss:[bx].RHLS_dataPtr, ssdx
		mov	ss:[bx].RHLS_token, ax
		call	RunHeapLock
		mov	bx, sp
	; pop the args off the stack after the unlock as we will
	; use the same args :)
		movdw	dxcx, ss:[bx].RHLS_eptr	; fptr to data
		Assert	fptr	dxcx
		mov	ax, ss:[bx].RHLS_token
		
		push	bp
		les	di, ss:[bp].GPA_compDataPtr
		mov	es:[di].CD_type, LT_TYPE_STRING
		mov	es:[di].CD_data.LD_string, ax	; token
		mov	bp, cx				; dx:bp = buffer
		mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
		call	ObjCallInstanceNoLock
		pop	bp
		Assert 	l cx, MAX_STRING  	; can't handle long strings

		call	RunHeapUnlock
		add	sp, size RunHeapLockStruct
		.leave
		ret
GadgetEntryGetText	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetEntrySetText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the text stored in the entry.

CALLED BY:	MSG_GADGET_ENTRY_SET_TEXT
PASS:		*ds:si	= GadgetEntryClass object
		ds:di	= GadgetEntryClass instance data
		ds:bx	= GadgetEntryClass object (same as *ds:si)
		es 	= segment of GadgetEntryClass
		ax	= message #
		on stack:	GetPropertyArgs
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	9/13/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetEntrySetText	method dynamic GadgetEntryClass, 
					MSG_GADGET_ENTRY_SET_TEXT
		uses	es, di
		.enter
		push	bp
		sub	sp, size RunHeapLockStruct
		mov	bx, sp
		les	di, ss:[bp].SPA_compDataPtr
		lea	dx, ss:[bx].RHLS_eptr
		movdw	ss:[bx].RHLS_dataPtr, ssdx
		mov	dx, es:[di].CD_data.LD_string
		mov	ss:[bx].RHLS_token, dx
		movdw	cxdx, ss:[bp].SPA_runHeapInfoPtr
		movdw	ss:[bx].RHLS_rhi, cxdx
	;
	; Grab the text from the heap
		call	RunHeapLock
		mov	bx, sp
	; pop args off stack after the Unlock.

		movdw	dxbp, ss:[bx].RHLS_eptr
		
		clr	cx
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
		call	ObjCallInstanceNoLock

		call	RunHeapUnlock
		add	sp, size RunHeapLockStruct
		pop	bp
		.leave
		ret
GadgetEntrySetText	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetEntryGetClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	return "entry"

CALLED BY:	MSG_ENT_GET_CLASS
PASS:		*ds:si	= GadgetEntryClass object
		ds:di	= GadgetEntryClass instance data
		ds:bx	= GadgetEntryClass object (same as *ds:si)
		es 	= segment of GadgetEntryClass
		ax	= message #
RETURN:		cx:dx	= fptr.char

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	10/28/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetEntryGetClass	method dynamic GadgetEntryClass, 
					MSG_ENT_GET_CLASS
		mov	cx, segment GadgetEntryString
		mov	dx, offset GadgetEntryString
		ret
GadgetEntryGetClass	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetEntryApply
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_GADGET_ENTRY_APPLY
PASS:		*ds:si	= GadgetEntryClass object
		ds:di	= GadgetEntryClass instance data
		ds:bx	= GadgetEntryClass object (same as *ds:si)
		es 	= segment of GadgetEntryClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron	11/16/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
applyString TCHAR	"entered", 0
GadgetEntryApply	method dynamic GadgetEntryClass, 
					MSG_GADGET_ENTRY_APPLY
		params	local	EntHandleEventStruct
		result	local	ComponentData
ForceRef	result		; Not used yet, maybe later
		.enter
		
		mov	ax, offset applyString
		movdw	ss:[params].EHES_eventID.EID_eventName, csax
		lea	ax, ss:[params]
		mov	dx, ax
		movdw	ss:[params].EHES_result, ssax
		mov	ss:[params].EHES_argc, 0
		mov	ax, MSG_ENT_HANDLE_EVENT
		mov	cx, ss				; cx:dx = params
		call	ObjCallInstanceNoLock

		.leave
		ret

GadgetEntryApply	endm






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GEEntDestroy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	zero out VTI_output so it doesn't cause problems

CALLED BY:	MSG_ENT_DESTROY
PASS:		*ds:si	= GoolEntryClass object
		ds:di	= GoolEntryClass instance data
		ds:bx	= GoolEntryClass object (same as *ds:si)
		es 	= segment of GoolEntryClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	 6/ 2/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GEEntDestroy	method dynamic GadgetEntryClass, 
					MSG_ENT_DESTROY
	.enter
	mov	ax, MSG_VIS_TEXT_SET_OUTPUT
	clrdw	cxdx
	call	ObjCallInstanceNoLock

	mov	ax, MSG_ENT_DESTROY
	mov	di, offset GadgetEntryClass
	call	ObjCallSuperNoLock
	.leave
	ret
GEEntDestroy	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetEntryVisTextFilterViaReplaceParams
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sent to filter characters because the user wants to.
		This will generate a basic event.

CALLED BY:	MSG_VIS_TEXT_FILTER_VIA_REPLACE_PARAMS
PASS:		*ds:si	= GadgetEntryClass object
		ds:di	= GadgetEntryClass instance data
		ds:bx	= GadgetEntryClass object (same as *ds:si)
		es 	= segment of GadgetEntryClass
		ax	= message #
		ss:bp	= VisTextReplaceParameters
RETURN:		Carry Set to reject replacement.  Will always be set as
		it expects the user to add the text at this point.
DESTROYED:	
SIDE EFFECTS:
		If there was a memory error creating the string for the event
		handler, then string will automatically be rejected.

PSEUDO CODE/STRATEGY:
		We expect the user to add text during the basic handler.
		If that happens we don't filter that text as it would cause
		an infinite loop.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	8/30/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GadgetEntryVisTextFilterViaReplaceParams	method dynamic GadgetEntryClass, 
					MSG_VIS_TEXT_FILTER_VIA_REPLACE_PARAMS
		uses	ax, cx, dx, bp
		.enter
		call	FilterTextCommon
		.leave
		ret
GadgetEntryVisTextFilterViaReplaceParams	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetEntrySetFilter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the filter for the text object

CALLED BY:	MSG_GADGET_ENTRY_SET_FILTER
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- SetPropertyArgs
RETURN:		SPA_compData.CD_type possibly set to LT_TYPE_ERROR
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		If it is a normal vis text filter add it.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	8/30/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetEntrySetFilter	method dynamic GadgetEntryClass, 
					MSG_GADGET_ENTRY_SET_FILTER
		uses	bp
		.enter
		call	SetTextFilterCommon

		.leave
		Destroy	ax, cx, dx
		ret
GadgetEntrySetFilter	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetEntryGetFilter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_GADGET_ENTRY_GET_FILTER
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- GetPropertyArgs
RETURN:		ComponentData filled in
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	9/ 6/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetEntryGetFilter	method dynamic GadgetEntryClass, 
					MSG_GADGET_ENTRY_GET_FILTER
		.enter
		call	GetTextFilterCommon
		.leave
		Destroy	ax, cx, dx
		ret
GadgetEntryGetFilter	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetEntryVisTextFilterViaCharacter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Used to filter new strings a char at a time.

CALLED BY:	MSG_VIS_TEXT_FILTER_VIA_CHARACTER
PASS:		*ds:si	= GadgetEntryClass object
		ds:di	= GadgetEntryClass instance data
		ds:bx	= GadgetEntryClass object (same as *ds:si)
		es 	= segment of GadgetEntryClass
		ax	= message #
		cx	= character
RETURN:		cx 	- 0 to reject replacement, other the replacement char
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	8/31/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetEntryVisTextFilterViaCharacter	method dynamic GadgetEntryClass, 
					MSG_VIS_TEXT_FILTER_VIA_CHARACTER
		.enter
		.enter
	;
	; If already filtered by KBD_CHAR, don't do it again.
	;
		mov	ax, ATTR_GADGET_TEXT_DONT_FILTER
		call	ObjVarFindData
		jc	done		; return char passed
		call	FilterViaCharCommon

done:
		
		.leave
		ret
GadgetEntryVisTextFilterViaCharacter	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetEntryGetMaxChars
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_GADGET_ENTRY_GET_MAX_CHARS
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- GetPropertyArgs
RETURN:		ComponentData filled in
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	10/15/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetEntryGetMaxChars	method dynamic GadgetEntryClass, 
					MSG_GADGET_ENTRY_GET_MAX_CHARS
	uses	bp
		.enter
		les	di, ss:[bp].GPA_compDataPtr
		mov	ax, MSG_VIS_TEXT_GET_MAX_LENGTH
		call	ObjCallInstanceNoLock
		Assert	fptr	esdi
		mov	es:[di].CD_data.LD_integer, cx
		mov	es:[di].CD_type, LT_TYPE_INTEGER
		
	.leave
	Destroy	ax, cx, dx
	ret
GadgetEntryGetMaxChars	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetEntrySetMaxChars
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_GADGET_ENTRY_SET_MAX_CHARS
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- SetPropertyArgs
RETURN:		SPA_compData.CD_type possibly set to LT_TYPE_ERROR
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	10/15/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetEntrySetMaxChars	method dynamic GadgetEntryClass, 
					MSG_GADGET_ENTRY_SET_MAX_CHARS
		uses	bp
		.enter
		les	di, ss:[bp].SPA_compDataPtr
		mov	cx, es:[di].CD_data.LD_integer
		cmp	cx, 0
		jl	error
		cmp	cx, GADGET_ENTRY_MAX_CHARS
		jg	error

		mov	ax, MSG_VIS_TEXT_SET_MAX_LENGTH
		call	ObjCallInstanceNoLock
done:
		.leave
		Destroy	ax, cx, dx
		ret

error:
		mov	es:[di].CD_data.LD_error, CPE_SPECIFIC_PROPERTY_ERROR
		mov	es:[di].CD_type, LT_TYPE_ERROR
		jmp	done
GadgetEntrySetMaxChars	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetEntryGetNumChars
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_GADGET_ENTRY_GET_NUM_CHARS
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- GetPropertyArgs
RETURN:		ComponentData filled in
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	10/15/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetEntryGetNumChars	method dynamic GadgetEntryClass, 
					MSG_GADGET_ENTRY_GET_NUM_CHARS
	uses	bp
		.enter
		les	di, ss:[bp].GPA_compDataPtr
		mov	ax, MSG_VIS_TEXT_GET_TEXT_SIZE	; length, really
		call	ObjCallInstanceNoLock
		Assert	fptr	esdi
		Assert	e dx, 0
		mov	es:[di].CD_data.LD_integer, ax
		mov	es:[di].CD_type, LT_TYPE_INTEGER
		
	.leave
	Destroy	ax, cx, dx
	ret
GadgetEntryGetNumChars	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetEntrySetNumChars
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	return a readonly property error

CALLED BY:	MSG_GADGET_ENTRY_SET_NUM_CHARS
PASS:		*ds:si	= GadgetEntryClass object
		ds:di	= GadgetEntryClass instance data
		ds:bx	= GadgetEntryClass object (same as *ds:si)
		es 	= segment of GadgetEntryClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	1/19/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetEntrySetNumChars	method dynamic GadgetEntryClass, 
					MSG_GADGET_ENTRY_SET_NUM_CHARS
		.enter

		call	GadgetUtilReturnReadOnlyError
		
		.leave
		ret
GadgetEntrySetNumChars	endm


;************************************************************************
;
; The following section contains methods that GadgetEntryClass intercepts
; to skip the default GadgetClipboardableClass behavior.
;
;************************************************************************


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetEntrySkipClipboardableBehavior
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Some clipboardable messages should be intercepted
		and dropped because the entry component and clipboard
		take care of things internally.

CALLED BY:	MSG_GADGET_CLIPBOARDABLE_RAISE_ACCEPT_PASTE_EVENT
		MSG_GADGET_CLIPBOARDABLE_UPDATE_CLIPBOARDS
PASS:		*ds:si	= GadgetEntryClass object
		ds:di	= GadgetEntryClass instance data
		ds:bx	= GadgetEntryClass object (same as *ds:si)
		es 	= segment of GadgetEntryClass
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 3/ 5/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetEntrySkipClipboardableBehavior	method dynamic GadgetEntryClass, 
			MSG_GADGET_CLIPBOARDABLE_RAISE_ACCEPT_PASTE_EVENT,
			MSG_GADGET_CLIPBOARDABLE_UPDATE_CLIPBOARDS
		.enter
	;
	; This page intentionally left blank
	;
		.leave
		ret
GadgetEntrySkipClipboardableBehavior	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetEntryClipboardItemChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Entry components should not raise an acceptPaste
		event when the clipboard changes (as do other
		clipboardables).

CALLED BY:	MSG_GADGET_CLIPBOARDABLE_CLIPBOARD_ITEM_CHANGED
PASS:		*ds:si	= GadgetEntryClass object
		ds:di	= GadgetEntryClass instance data
		ds:bx	= GadgetEntryClass object (same as *ds:si)
		es 	= segment of GadgetEntryClass
		ax	= message #
		cx:dx	= optr of clipboard component that sent us this
RETURN:		nothing
DESTROYED:	ax,cx,dx,bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 3/ 5/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetEntryClipboardItemChanged	method dynamic GadgetEntryClass, 
				MSG_GADGET_CLIPBOARDABLE_CLIPBOARD_ITEM_CHANGED
		.enter

		mov	ax, MSG_SCB_RAISE_CLIPBOARD_CHANGED_EVENT
		mov	bx, cx
		mov	si, dx
		clr	di
		call	ObjMessage
		
		.leave
		Destroy	ax, cx, dx, bp
		ret
GadgetEntryClipboardItemChanged	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetEntryMetaClipboard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The text object in us knows how to handle clipboard events.
		So have the superclass handle the received clipboard message,
		but skip the clipboardable handler because it will raise
		an event.

CALLED BY:	MSG_META_CLIPBOARD_CUT
PASS:		*ds:si	= GadgetEntryClass object
		ds:di	= GadgetEntryClass instance data
		ds:bx	= GadgetEntryClass object (same as *ds:si)
		es 	= segment of GadgetEntryClass
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 3/ 5/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetEntryMetaClipboard	method dynamic GadgetEntryClass, 
					MSG_META_CLIPBOARD_CUT,
					MSG_META_CLIPBOARD_COPY,
					MSG_META_CLIPBOARD_PASTE,
					MSG_META_DELETE
		.enter

		mov	di, offset GadgetClipboardableClass
		call	ObjCallSuperNoLock
		
		.leave
		ret
GadgetEntryMetaClipboard	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetEntrySetHeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Entries need a little extra vertical space so that they
		can draw their frame.  Make sure that they are at least
		three pixels high.

CALLED BY:	MSG_GADGET_SET_HEIGHT
PASS:		*ds:si	= GadgetEntryClass object
		ds:di	= GadgetEntryClass instance data
		ds:bx	= GadgetEntryClass object (same as *ds:si)
		es 	= segment of GadgetEntryClass
		ax	= message #
RETURN:		nothing
DESTROYED:	cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		We could do this check in the SPUI (OLTextDraw), but....
		  + This is simpler/ doesn't clutter the SPUI
		  + This way we don't have to check our height everytime
		    we do an OLTextDraw.
		  + Don't need to pretend our height is less than 3.
		(see bug 52987)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 5/ 6/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetEntrySetHeight	method dynamic GadgetEntryClass, 
					MSG_GADGET_SET_HEIGHT
		.enter
	;
	; Make height at least 3.
	;
		Assert	fptr	ssbp
		les	di, ss:[bp].SPA_compDataPtr
		Assert	fptr	esdi
		cmp	es:[di].CD_type, LT_TYPE_INTEGER
		jne	callSuper			; Let super handle.
		cmp	es:[di].CD_data.LD_integer, 2
		jg	callSuper
		mov	es:[di].CD_data.LD_integer, 3
callSuper:
		mov	bx, segment GadgetEntryClass
		mov	es, bx
		mov	di, offset GadgetEntryClass
		call	ObjCallSuperNoLock

		.leave
		ret
GadgetEntrySetHeight	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetEntryMetaEndSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Hack to change END_SELECT to LARGE_END_SELECT

CALLED BY:	MSG_META_END_SELECT
PASS:		*ds:si	= GadgetEntryClass object
		ds:di	= GadgetEntryClass instance data
		ds:bx	= GadgetEntryClass object (same as *ds:si)
		es 	= segment of GadgetEntryClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	
	
PSEUDO CODE/STRATEGY:
		Entries need to get LARGE_END_SELECT not END_SELECT so they
		can clear VTI_intSelfFlags:DO_SELECTING.  For some reason when
		the entry is in a gadget it gets an END_SELECT. We will change
		it to a LARGE_END_SELECT and pass it on.
		Strangely, a text components get LARGE_END_OTHER.
		That gets mapped too.
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	5/14/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetEntryMetaEndSelect	method dynamic GadgetEntryClass, 
					MSG_META_END_SELECT
		.enter
		mov	ax, MSG_META_LARGE_END_SELECT
		mov	di, offset GadgetEntryClass
		call	ObjCallSuperNoLock
		.leave
		ret
GadgetEntryMetaEndSelect	endm


GadgetTextCode	ends
