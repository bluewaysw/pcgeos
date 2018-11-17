COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		User interface.
FILE:		textInstance.asm

AUTHOR:		Tony

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/22/89		Initial revision

DESCRIPTION:
	Low level utility routines for implementing the methods defined on
	VisTextClass.

	$Id: textInstance.asm,v 1.1 97/04/07 11:18:07 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TextInstance segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initializes an object.

CALLED BY:	External.
PASS:		es = segment containing VisTextClass.
		ds:*si = pointer to instance.
		ax = MSG_META_INITIALIZE.
RETURN:		nothing of use.
DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12-Jun-89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextInitialize	method	VisTextClass, MSG_META_INITIALIZE

	; First, to parent class initialization

	mov	di, offset VisTextClass
	CallSuper	MSG_META_INITIALIZE

	; Initialize our own data.  Assume enabled.

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset

	or	ds:[di].VI_attrs, mask VA_FULLY_ENABLED
	or	ds:[di].VI_geoAttrs, mask VGA_NOTIFY_GEOMETRY_VALID
	mov	ds:[di].VTI_state, mask VTS_EDITABLE or mask VTS_SELECTABLE
	mov	ds:[di].VTI_intFlags, 0

	; Create and initialize a text-stream and line structures.
	; Currently only one byte is allocated for the text, and one
	; line-info structure is allocated. This is to reduce the size
	; associated with a one line text-edit object.

	mov	ds:[di].VTI_storageFlags, mask VTSF_DEFAULT_CHAR_ATTR \
			or mask VTSF_DEFAULT_PARA_ATTR
	mov	ds:[di].VTI_paraAttrRuns, VIS_TEXT_INITIAL_PARA_ATTR

	;
	; Create text stream and regions.
	;
	call	TS_SmallCreateTextStorage

	;
	; no need to set things to zero (since they already are):
	;	lrMargin, tbMargin
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	ds:[di].VTI_maxLength, -1

	mov	ds:[di].VTI_leftOffset, INITIAL_LEFT_OFFSET

	mov	ds:[di].VTI_washColor.low, CF_INDEX or C_WHITE

	; Let's get the specific UI's default font and size and use it.

	mov	al, mask OCF_IGNORE_DIRTY	; ObjChunkFlags => AL
	call	TextGetSystemCharAttrRun
	pushf
	mov	di, ds:[si]			; point to instance
	add	di, ds:[di].Vis_offset		; ds:[di] -- VisInstance
	mov	ds:[di].VTI_charAttrRuns, ax	; store charAttr
	popf
	jc	10$				; simple charAttr, branch
	andnf	ds:[di].VTI_storageFlags, not mask VTSF_DEFAULT_CHAR_ATTR
10$:
	ret

VisTextInitialize	endm

COMMENT @----------------------------------------------------------------------

ROUTINE:	TextGetSystemCharAttrRun

SYNOPSIS:	Returns the system charAttr run for this object's specific UI.

CALLED BY:	EXTERNAL

PASS:		*ds:si -- object to get charAttr run for
		al - flags or allocate lmem chunk with (if any)

RETURN:		carry -- clear if chunk allocated, set if default returned
		ax -- new chunk or constant (allocated in passed ds block)
		ds - updated to point at segment of same block as on entry
		Chunk handles in ds may have moved, be sure to dereference them

DESTROYED:	nothing
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/25/90		Initial version

------------------------------------------------------------------------------@
TextGetSystemCharAttrRun	proc	far		uses cx, di, bp, es
objFlags	local	word	push	ax
systemCharAttr	local	VisTextCharAttr
	.enter

	push	bp
	lea	bp, systemCharAttr
	call	T_GetSystemCharAttr

	; try to map it back

	call	TextFindDefaultCharAttr		; default charAttr => AX
	pop	bp				; restore local vars pointer
	jc	done				; default charAttr found, branch

	; Else create an LMem chunk, and copy the system charAttr into it

	mov	ax, objFlags
	mov	cx, size VisTextCharAttr	; bytes to allocate => CX
	call	LMemAlloc			; chunk => AX
	push	si, di, ds

	mov	si, ax
	mov	di, ds:[si]			;es:di = dest
	push	ds
	push	ss
	pop	ds
	pop	es
	lea	si, systemCharAttr			;ds:si = source
	mov	cx, (size VisTextCharAttr)/2
	rep	movsw

	pop	si, di, ds
	clc					;default charAttr not found

done:
	
	.leave
	ret

TextGetSystemCharAttrRun	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	T_GetSystemCharAttr

DESCRIPTION:	Get the system VisTextCharAttr structure

CALLED BY:	INTERNAL

PASS:
	ss:bp - buffer

RETURN:
	buffer - filled

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/ 2/92		Initial version

------------------------------------------------------------------------------@
T_GetSystemCharAttr	proc	far	uses ax, bx, cx, dx
	.enter
	;
	; Let's get the specific UI's default font and size and use it.
	;
	clr	bx
	call	GeodeGetUIData			; bx = specific UI
	mov	ax, SPIR_GET_DISPLAY_SCHEME
	call	ProcGetLibraryEntry
	call	ProcCallFixedOrMovable		; cx = font, dx = point size

	; get structure for default charAttr

	mov	ax, VIS_TEXT_INITIAL_CHAR_ATTR
	call	TextMapDefaultCharAttr

	; stuff in our things

	mov	ss:[bp].VTCA_pointSize.WBF_int, dx
	mov	ss:[bp].VTCA_fontID, cx
	mov	ss:[bp].VTCA_color.CQ_redOrIndex, C_BLACK

	.leave
	ret

T_GetSystemCharAttr	endp

COMMENT @----------------------------------------------------------------------

METHOD:		VisTextReloc -- Relocation for VisTextClass

DESCRIPTION:	Relocate a stored text object

PASS:
	*ds:si - instance data
	es - segment of VisTextClass

	ax - MSG_META_RELOCATE/MSG_META_UNRELOCATE

	cx - handle of block containing relocation
	dx - VMRelocType:
		VMRT_UNRELOCATE_BEFORE_WRITE
		VMRT_RELOCATE_AFTER_READ
		VMRT_RELOCATE_AFTER_WRITE
	bp - data to pass to ObjRelocOrUnRelocSuper

RETURN:
	carry - set if error
	bp - unchanged

DESTROYED:
	bx, di, es (special method handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/89		Initial version

------------------------------------------------------------------------------@

VisTextReloc	method	VisTextClass, reloc

	cmp	dx, VMRT_RELOCATE_AFTER_READ
	jnz	done

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	ds:[di].VTI_output.handle, 0
	mov	ds:[di].VTI_gstate, 0
	mov	ds:[di].VTI_gsRefCount, 0
	mov	ds:[di].VTI_timerHandle, 0
	andnf	ds:[di].VTI_intSelFlags, not (mask VTISF_IS_FOCUS or \
						mask VTISF_IS_TARGET)

.assert	ASST_NOTHING_ACTIVE	eq	0
	andnf	ds:[di].VTI_intFlags, not (mask VTIF_UPDATE_PENDING or \
					mask VTIF_ACTIVE_SEARCH_SPELL)

;	Nuke the various temp vardata items

	mov	ax, TEMP_VIS_TEXT_SYS_TARGET
	call	ObjVarDeleteData

	mov	ax, TEMP_VIS_TEXT_CACHED_UNDO_INFO
	call	ObjVarFindData
	jnc	10$
	movdw	ds:[bx].VTCUI_vmChain, 0
	mov	ds:[bx].VTCUI_file, 0
10$:

done:
	mov	di, offset VisTextClass
	call	ObjRelocOrUnRelocSuper
	ret

VisTextReloc	endm

COMMENT @----------------------------------------------------------------------

METHOD:		VisTextObjFree -- MSG_META_OBJ_FREE for VisTextClass
	
		Destroy the cursor time if it is still around.

DESCRIPTION:	-

PASS:
	*ds:si - instance data
	es - segment of VisTextClass

	ax - MSG_META_OBJ_FREE

RETURN:
	*ds:si - same

DESTROYED:
	bx, di, es (special method handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/93		Initial version

------------------------------------------------------------------------------@
if (0)	; We now kill the timer when we lose sys focus. - Joon (12/8/94)
VisTextObjFree	method	VisTextClass, MSG_META_OBJ_FREE
	clr	bx
	xchg	bx, ds:[di].VTI_timerHandle
	tst	bx
	jz	afterTimer
	mov	ax, ds:[di].VTI_timerID
	call	TimerStop

afterTimer:
	mov	ax, TEMP_VIS_TEXT_NOTIFY_CURSOR_POSITION_INFO
	call	ObjVarFindData
	jnc	callSuper
	mov	ax, ds:[bx].TVTNCPID_id
	clr	dx
	xchg	dx, ds:[bx].TVTNCPID_handle
	tst	dx
	jz	deleteVarData
	mov	bx, dx
	call	TimerStop
deleteVarData:
	mov	ax, TEMP_VIS_TEXT_NOTIFY_CURSOR_POSITION_INFO
	call	ObjVarDeleteData

callSuper:
	mov	ax, MSG_META_OBJ_FREE
	mov	di, offset VisTextClass
	GOTO	ObjCallSuperNoLock

VisTextObjFree	endm
endif


COMMENT @----------------------------------------------------------------------

METHOD:		VisTextFinalObjFree -- MSG_META_FINAL_OBJ_FREE for VisTextClass

DESCRIPTION:	-

PASS:
	*ds:si - instance data
	es - segment of VisTextClass

	ax - MSG_META_FINAL_OBJ_FREE

RETURN:
	*ds:si - same

DESTROYED:
	bx, di, es (special method handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/89		Initial version
	Doug	8/90		Changed to be handler of FINAL_OBJ_FREE from
				OBJ_FREE, so that chunks are freed AFTER
				methods have been flushed through to this object

------------------------------------------------------------------------------@
VisTextFinalObjFree	method	VisTextClass, MSG_META_FINAL_OBJ_FREE
	tst	ds:[di].VTI_text		;is there any text?
	jz	callSuper			;nope, Tony says it's cool to
						;  skip this stuff...

	mov	ax, TEMP_VIS_TEXT_FREEING_OBJECT
	clr	cx				;don't free elements
	call	ObjVarAddData

	clr	dx				;don't delete text (no need)
	mov	ax, MSG_VIS_TEXT_FREE_STORAGE
	call	ObjCallInstanceNoLock

	mov	bx, offset VTI_text
	call	FreeStruct

	call	TL_LineStorageDestroy

callSuper:
	mov	ax, MSG_META_FINAL_OBJ_FREE
	mov	di, offset VisTextClass
	GOTO	ObjCallSuperNoLock

VisTextFinalObjFree	endm

;---

FreeStruct	proc	near
	class	VisTextClass

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	clr	ax
	xchg	ax, ds:[di][bx]			;*ds:di = run
	tst	ax
	jz	done

	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE
	jnz	vm
	call	ObjFreeChunk
	ret
vm:
	clr	bp
	call	T_GetVMFile			;bx = VM file
	call	VMFreeVMChain
done:
	ret
FreeStruct	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextFreeAllStorage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	superset of MSG_VIS_TEXT_FREE_STORAGE

CALLED BY:	MSG_VIS_TEXT_FREE_ALL_STORAGE

PASS:		*ds:si	= VisTextClass object
		ds:di	= VisTextClass instance data
		es 	= segment of VisTextClass
		ax	= MSG_VIS_TEXT_FREE_ALL_STORAGE

		cx	= non-zero to remove element arrays also

RETURN:		nothing

ALLOWED TO DESTROY:	
		ax, cx, dx, bp
		bx, si, di, ds, es

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	6/17/93  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextFreeAllStorage	method	dynamic VisTextClass, MSG_VIS_TEXT_FREE_ALL_STORAGE
	tst	ds:[di].VTI_text		;is there any text?
	jz	done				;nope, Tony says it's cool to
						;  skip this stuff...

	mov	ax, MSG_VIS_TEXT_FREE_STORAGE
	call	ObjCallInstanceNoLock

	mov	bx, offset VTI_text
	call	FreeStruct

	call	TL_LineStorageDestroy
done:
	ret
VisTextFreeAllStorage	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextSetFilter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the text filter.

CALLED BY:	GLOBAL
PASS:		CL - VisTextFilters
RETURN:		nada
DESTROYED:	ax, cx, dx, bp
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextSetFilter	method	VisTextClass, MSG_VIS_TEXT_SET_FILTER
	.enter
	mov	ds:[di].VTI_filters, cl
	Destroy	ax, cx, dx, bp
	.leave
	ret
VisTextSetFilter	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextGetFilter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the text filter.

CALLED BY:	GLOBAL
PASS:		CL - VisTextFilters
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextGetFilter	method	VisTextClass, MSG_VIS_TEXT_GET_FILTER
	.enter
	mov	cl, ds:[di].VTI_filters
	.leave
	ret
VisTextGetFilter	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextSetOutput
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the output for the text object

CALLED BY:	GLOBAL
PASS:		CX:DX <- OD
RETURN:		nada
DESTROYED:	ax, cx, dx, bp
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextSetOutput	method	VisTextClass, MSG_VIS_TEXT_SET_OUTPUT
	.enter
	movdw	ds:[di].VTI_output, cxdx
	Destroy	ax, cx, dx, bp
	.leave
	ret
VisTextSetOutput	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextGetOutput
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the output for the text object

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		CX:DX <- OD
DESTROYED:	nothing
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextGetOutput	method	VisTextClass, MSG_VIS_TEXT_GET_OUTPUT
	.enter
	movdw	cxdx, ds:[di].VTI_output
	.leave
	ret
VisTextGetOutput	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextSetLRMargin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the left/right margin for the text object

CALLED BY:	GLOBAL
PASS:		CL - left/right margin
RETURN:		nada
DESTROYED:	ax, cx, dx, bp
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextSetLRMargin	method	VisTextClass, MSG_VIS_TEXT_SET_LR_MARGIN
	.enter
	mov	ds:[di].VTI_lrMargin, cl
	Destroy	ax, cx, dx, bp
	.leave
	ret
VisTextSetLRMargin	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextGetLRMargin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the left/right margin for the text object

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		CL - lr margin
DESTROYED:	nothing
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextGetLRMargin	method	VisTextClass, MSG_VIS_TEXT_GET_LR_MARGIN
	.enter
	mov	cl, ds:[di].VTI_lrMargin
	.leave
	ret
VisTextGetLRMargin	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextSetTBMargin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the top/bottom margin for the text object

CALLED BY:	GLOBAL
PASS:		CL - top/bottom margin
RETURN:		nada
DESTROYED:	ax, cx, dx, bp
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextSetTBMargin	method	VisTextClass, MSG_VIS_TEXT_SET_TB_MARGIN
	.enter
	mov	ds:[di].VTI_tbMargin, cl
	Destroy	ax, cx, dx, bp
	.leave
	ret
VisTextSetTBMargin	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextGetTBMargin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the top/bottom margin for the text object

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		CL - tb margin
DESTROYED:	nothing
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextGetTBMargin	method	VisTextClass, MSG_VIS_TEXT_GET_TB_MARGIN
	.enter
	mov	cl, ds:[di].VTI_tbMargin
	.leave
	ret
VisTextGetTBMargin	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextNavigationQuery
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle kbd navigation

CALLED BY:	MSG_SPEC_NAVIGATION_QUERY

PASS:		*ds:si	= class object
		ds:di	= class instance data
		es 	= segment of class
		ax	= message #

		^lcx:dx	= object which originated navigation
		bp	= NavigateFlags

RETURN:		^lcx:dx	= replying object
		bp	= NavigateFlags (in reply)
		carry set if found the next/previous navigation object

ALLOWED TO DESTROY:	
		ax, cx, dx, bp
		bx, si, di, ds, es

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/5/93  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextNavigationQuery	method	dynamic VisTextClass, MSG_SPEC_NAVIGATION_QUERY
	clr	bl			;default: not root-level node, is
					;not composite node, is not focusable
					;not menu-related
	test	ds:[di].VTI_state, mask VTS_EDITABLE
	jz	haveFlags		;not editable, not focusable
	test	ds:[di].VI_attrs, mask VA_FULLY_ENABLED
	jz	haveFlags		;not fully enabled, not focusable
	ornf	bl, mask NCF_IS_FOCUSABLE
haveFlags:
	clr	di			;no Generic object to check hints for
					;normal text objects will intercept
					;MSG_SPEC_NAVIGATION_QUERY at
					;OLTextClass, which will handle a
					;Generic object.  This handler is for
					;direct uses of VisTextClass.
	call	VisNavigateCommon
	ret
VisTextNavigationQuery	endm

TextInstance	ends
