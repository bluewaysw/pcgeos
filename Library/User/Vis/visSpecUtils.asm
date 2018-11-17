COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		User/Spec
FILE:		visSpecUtils.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	7/91		Initial version

DESCRIPTION:
	This file contains visual utilities that are needed for the specific
	UI implementation only.

	$Id: visSpecUtils.asm,v 1.1 97/04/07 11:44:38 newdeal Exp $

------------------------------------------------------------------------------@


Build	segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	VisAddChildRelativeToGen

DESCRIPTION:	Adds a visual object to another visual object, selecting
		the insertion point among the current children by
		seeing if any of the generic objects to the right of
		the reference object have the same visual parent.  If
		none do, the object is added at the end.  If one does,
		the object is added before that object.

CALLED BY:	EXTERNAL
		VisSpecBuild

PASS:
	*ds:si	- generic object, which will be used as the reference obj
	^lax:bx	- visual object to add to parent
	^lcx:dx	- visual parent to use
	bp	- SpecBuildFlags:
		mask SBF_WIN_GROUP			- if building top
							  level WIN_GROUP
		mask SBF_TREE_BUILD			- if building whole
							  WIN_GROUP
		mask SBF_VIS_PARENT_WITHIN_SCOPE_OF_TREE_BUILD
							- set if vis parent
							  is in same WIN_GROUP
							  as child.

RETURN:
	*ds:si	- unchanged
	(ds - updated to point at segment of same block as on entry)
	^lax:bx	- unchanged
	^lcx:dx	- unchanged
	bp	- unchanged


DESTROYED:
	Nothing
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/89		Initial version
------------------------------------------------------------------------------@

VisAddChildRelativeToGen	proc	far
	class	VisClass

	uses	ax, bx, cx, dx, si, bp
	.enter

	test	bp, mask SBF_TREE_BUILD	; doing tree build?
	jz	HardWay			; if not, do it the hard way
					; If so, see if adding within WIN_GROUP
	test	bp, mask SBF_VIS_PARENT_WITHIN_SCOPE_OF_TREE_BUILD
	jz	HardWay			; if not, then have to do hard way

;EasyWay:

	mov	si, bx
	mov	bx, ax			;^lbx:si = object to add
	xchg	bx, cx
	xchg	si, dx			;^lbx:si = parent
					;^lcx:dx = child
					; Else, just add at end.
	mov	bp, CCO_LAST
	jmp	DoAdd

HardWay:
	push	cx			; Save the vis parent
	push	dx	
	push	ax			; Save the vis object
	push	bx

					; ^lcx:dx = vis parent
					; *ds:si  = gen object

	push	ds:[LMBH_handle]	; push block handle, so we can restore
					; ds value later.

	test	bp, mask SBF_TREE_BUILD	; doing tree build?
	jz	searchToRightOfStartObject	; if not, look to right.

					; Otherwise, siblings to right
					; can't possibly have been vis-built
					; yet, so skip this work
					; Now, get generic parent of gen object
	call	GenSwapLockParent
EC <	ERROR_NC	UI_VIS_ADD_CHILD_REL_NO_GEN_PARENT		>
	jmp	afterSiblingsToRightChecked

searchToRightOfStartObject:
	;
	; Find the first generic child after ours whose visible parent matches
	; ours and is specifically built.  If found, we'll insert our child before
	; it in the visible tree.
	;
					; Start pusing PARAMS for
					; ObjCompProcessChildren here.
	push	ds:[LMBH_handle]	; Start processing at generic object
	push	si			;	passed

					; Now, get generic parent of gen object
	call	GenSwapLockParent
EC <	ERROR_NC	UI_VIS_ADD_CHILD_REL_NO_GEN_PARENT		>
					; bp = SpecBuildFlags

	or	bp, mask SBF_SKIP_CHILD	; skip first object (the ref gen obj)
	mov	ax, -1			; no matches found yet
					; that we can skip test on this object
	mov	bx,offset GI_link
	push	bx			; push offset to LinkPart
NOFXIP <	push	cs			;pass callback routine	>
FXIP <		mov	bx, SEGMENT_CS					>
FXIP <		push	bx						>
	mov	bx,offset FindVisParentMatch
	push	bx
	mov	bx,offset Gen_offset
	mov	di,offset GI_comp
	call	ObjCompProcessChildren	; returns ax = position to insert at
	tst	ax			; any match?
	jns	HaveCompFlags
afterSiblingsToRightChecked:

	;
	; We didn't find any generic children after ours who had been visibly
	; built with the same vis parent.  Let's now go through the generic 
	; children again, and find the last one specifically built with the same
	; parent.  We'll insert our child after that one in the visible tree.
	;
	or	bp, mask SBF_FIND_LAST	; find last match
	mov	ax, -1			; no matches found yet
					; that we can skip test on this object
	clr	di			; start at first child
	push	di			; 
	push	di			; 
	mov	bx,offset GI_link
	push	bx			; push offset to LinkPart
NOFXIP <	push	cs			;pass callback routine	>
FXIP <		mov	bx, SEGMENT_CS					>
FXIP <		push	bx						>
	mov	bx,offset FindVisParentMatch
	push	bx
	mov	bx,offset Gen_offset
	mov	di,offset GI_comp
	call	ObjCompProcessChildren	; returns ax = position to insert at
	tst	ax			; any match?
	mov	bp, CCO_LAST		; assume not, we'll add our object last
	js	80$			; no, find last vis object before ours
	inc	ax			; Add before the next object (or as the
					; last object)

HaveCompFlags:
	xchg	bp,ax 			; Put ref # in bp (1 byte inst)
80$:
	pop	bx			; get block handle of orig object
	call	ObjSwapUnlock
					; bp = flags for vis add
	pop	dx			; Get vis object
	pop	cx
	pop	si			; Get vis parent
	pop	bx

DoAdd:
					; DO the MSG_VIS_ADD_CHILD
	mov	ax, MSG_VIS_ADD_CHILD
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret

VisAddChildRelativeToGen	endp




COMMENT @----------------------------------------------------------------------

FUNCTION:	FindVisParentMatch

DESCRIPTION:	Callback routine for ObjCompProcessChildren to see whether this
		generic child has been implemented as a visual object
		and has the passed object as a visual parent.
		
		Various flags are passed in bp, one of which is SBF_FIND_LAST.
		If this is set, we will keep looking though all the children
		to find the last child that matches the criteria.  If it's clear
		we'll return as soon as we find the first match.

CALLED BY:	VisAddChildRelativeToGen (as call-back)

PASS:
	*ds:si - child
	*es:di - composite
	
	ax	- any previous match, or -1 if no match found yet
	cx:dx	- Visible parent to check against.
	bp	- SpecBuildFlags (mask SBF_WIN_GROUP set if looking for visible
		  implementation of win-group version of object, clear if
		  looking for child visible object.)  Also, SBF_SKIP_CHILD
		  is set if this object should skip test, clear this flag,
		  & return.


RETURN:
	carry set if we've found a match and SBF_FIND_LAST is clear.
	ax	- updated to this child if we've found a match
	cx:dx	- unchanged
	bp	- unchanged

DESTROYED:
	bx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/89		Initial version
	Doug	6/89		Changed function to look for prior visibly
				built object.
	Doug	9/89		Quite revised
	Chris	1/90		Changed to look for either the first match or
				the last match.

------------------------------------------------------------------------------@

FindVisParentMatch	proc	far
	class	VisClass
	push	ax		; save previous match
	push	di
	mov	di, dx		; keep chunk of vis parent to match in di
	push	bp

	push	cx
				; If First call, skip (object itself we wish
				; to skip)
	test	bp, mask SBF_SKIP_CHILD
	jnz	IPVBO_NotDoneYet

;	call	VisCheckIfSpecBuilt	; check to see if this object is built
;	jnc	IPVBO_NotDoneYet	; skip if not.
;
				; Query this child to get visual equivalent
	push	es:[LMBH_handle]
	call	VisGetSpecificVisObject
	mov	bp, bx		;Save BX
	pop	bx		;Get handle of ES block
	call	MemDerefES	;Dereference it.
	mov	bx, bp

	pop	bp		; Put handle of vis parent to match in bp
	push	bp		; Put back on stack

	; Else cx:dx is visible object.

	tst	cx
	jz	IPVBO_NotDoneYet	; if none, then is'nt what we want.

	; Find this object's visible parent.
	push	bx
	push	si
	push	ds
	mov	bx, cx			; get handle of this object
	call	ObjLockObjBlock
	mov	ds, ax
	mov	si, dx			; setup this object in *ds:si

	call	VisCheckIfSpecBuilt	; check to see if this object is built
	jnc	IPVBO_UnlockNotDoneYet	; skip if not.

	call	VisFindParent		; does not change ds or es
					; puts vis parent in ^lbx:si
	; See if vis parent is the same as the generic composite
	cmp	bx, bp
	jne	IPVBO_UnlockNotDoneYet	; skip if not
	cmp	si, di
	jne	IPVBO_UnlockNotDoneYet  ; skip if not
	
	;
	; A MATCH!  Figure out what number visible child it is
	;
	push	di			; save parent handle
	mov	ax, MSG_VIS_FIND_CHILD
	mov	di, mask MF_CALL or mask MF_FIXUP_DS or mask MF_FIXUP_ES
	call	ObjMessage
	pop	di			; restore parent handle

	mov	bx, ds:[LMBH_handle]
	call	MemUnlock
	mov	ax, bp			; return result # in ax
	pop	ds
	pop	si
	pop	bx

	pop	cx
	pop	bp
	mov	dx, di			; restore parent handle
	pop	di			
	pop	bx			; throw away any previous match
	test	bp, mask SBF_FIND_LAST	; looking for the last match?
	clc				; assume so, we'll do all children
	jnz	10$			; branch if so
	stc				; else return with this value
10$:
	ret

IPVBO_UnlockNotDoneYet:
	mov	bx, ds:[LMBH_handle]
	call	MemUnlock
	pop	ds
	pop	si
	pop	bx

IPVBO_NotDoneYet:
	pop	cx
	pop	bp
	mov	dx, di
	pop	di
	pop	ax			; restore previous match
					; show no longer on first call
	and	bp, not mask SBF_SKIP_CHILD
	clc				; not done yet
	ret
	
FindVisParentMatch	endp

Build	ends

;
;---------------
;
		
VisUpdate	segment	resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	VisSetNotRealized

DESCRIPTION:	Primitive function which will VIS_CLOSE a visual branch
		if it is REALIZED, by sending non-win groups a MSG_VIS_CLOSE,
		or by clearing the VA_VISIBLE bit for non-generic WIN_GROUPS &
		calling MSG_VIS_VUP_UPDATE_WIN_GROUP.

CALLED BY:	EXTERNAL
		VisUnbuild

PASS:
	*ds:si - instance data
	dl - VisUpdateMode


RETURN:
	ds - updated to point at segment of same block as on entry

DESTROYED:
	none
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/90		Initial version

------------------------------------------------------------------------------@

VisSetNotRealized	proc	far	uses ax, bx, cx, dx, di, bp
	class	VisClass
	.enter
					; *ds:si = visible object to unrealize

	call	VisCheckIfVisGrown	; If not visibly grown,
	jnc	AfterClosed		; then can't possibly be REALIZED.

					; OTHERWISE unrealize it.
	clr	dh
	mov	bp, dx			; Keep update mode in bp

	; First, close down visual branch
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
					; See if realized or not (OPEN)
	test	ds:[di].VI_attrs, mask VA_REALIZED
	jz	AfterClosed	; skip if already not visible (CLOSED)
					; See if WIN_GROUP or not
	test	ds:[di].VI_typeFlags, mask VTF_IS_WIN_GROUP
	jz	CloseNonWinGroup	; If not, branch to close down a
					; non-WIN_GROUP object

;
; We can't close a generic WIN_GROUP here, because VA_VISIBLE for generic
; objects may only be changed by the routine VisUpdateGenWinGroup.
;
EC <	test	ds:[di].VI_typeFlags, mask VTF_IS_GEN			>
EC <	jz	ECNotGen						>
EC <	ERROR_NZ UI_GENERIC_WIN_GROUP_MUST_BE_NOT_VISIBLE_BEFORE_REMOVING >
EC <ECNotGen:							>

;CloseWinGroup:
					; close visible-only WIN_GROUP by
					; setting not VISIBLE & updating.
	push	bp
					; Clear visible bit
	and	ds:[di].VI_attrs, not mask VA_VISIBLE
	mov	dl, VUM_NOW		; Close immediately
;	mov	ax, MSG_VIS_VUP_UPDATE_WIN_GROUP
;	call	ObjCallInstanceNoLock
	call	VisVupUpdateWinGroup	; call statically
	pop	bp
	jmp	short AfterClosed


CloseNonWinGroup:
	push	bp
	mov	bp, -1			; not top obj
	mov	ax, MSG_VIS_CLOSE
	call	ObjCallInstanceNoLock
	pop	bp

AfterClosed:
	.leave
	ret
VisSetNotRealized	endp


VisUpdate	ends
		
;
;--------------
;
		
Build	segment resource
	

COMMENT @----------------------------------------------------------------------

FUNCTION:	VisIfFlagSetCallGenChildren

DESCRIPTION:	Sends message to all generic children which are marked as
		USABLE, and are either not WIN_GROUPS or are WIN_GROUPS
		with DUAL_BUILD, AND have one or more of the specified bits
		set in VI_optFlags.

		NOTE that objects which are DUAL_BUILD will have to be
		careful not to send messages on down to their children, since
		generally the intention is that the non-WIN_GROUP portion
		of the object is receiving this messages.  Flags passed in
		cx or bp should be used to clarify this & prevent that 
		occurence where it is not desired.


CALLED BY:	INTERNAL

PASS:
	ax - message to pass
	*ds:si - instance
	dl	- flags to compare with children's VI_optFlags
	     if 0,  no compare will be made, message will be sent
	cx 	- data to pass on to child.  Will be passed in both cx and dx.
	bp	- flags to pass on to any children called

RETURN:
	ds - updated to point at segment of same block as on entry

DESTROYED:
	ax, bx, cx, dx, bp, di
	
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	5/89		Initial version

------------------------------------------------------------------------------@

VisIfFlagSetCallGenChildren	proc	far
	class	GenClass

	mov	di, ds:[si]		; make sure composite
	add	di, ds:[di].Gen_offset
	cmp	ds:[di].GI_comp.CP_firstChild.handle, 0
	je	IFSCGC_90			;if not, exit

	clr	bx			; initial child (first
	push	bx			; child of
	push	bx			; composite)
	mov	bx,offset GI_link
	push	bx			;push offset to LinkPart
NOFXIP <	push	cs			;pass callback routine	>
FXIP <		mov	bx, SEGMENT_CS					>
FXIP <		push	bx						>
	mov	bx,offset CCWFS_callBack
	push	bx

	mov	bx,offset Gen_offset
	mov	di,offset GI_comp
	call	ObjCompProcessChildren	;must use a call (no GOTO) since
					;parameters are passed on the stack
IFSCGC_90:
	ret

VisIfFlagSetCallGenChildren	endp

				
				


COMMENT @----------------------------------------------------------------------

FUNCTION:	CCWFS_callBack

DESCRIPTION:	Sends message to all generic children which are marked as
		USABLE, and are either not WIN_GROUPS or are WIN_GROUPS
		with DUAL_BUILD, AND have one or more of the specified bits
		set in VI_optFlags.

CALLED BY:	VisIfFlagSetCallGenChildren (as call-back)

PASS:
	*ds:si - child
	*es:di - composite
	dl - flag(s) to look for.  Will send message if any are set
	     if 0,  no compare will be made, message will be sent
	cx - data to pass on to child, will be passed in both cx and dx.
	bp - data to pass on to child
	ax - message

RETURN:
	carry - set to end processing
	cx, dx, bp - data to send to next child

DESTROYED:
	ax, bx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version

------------------------------------------------------------------------------@

CCWFS_callBack	proc	far
	class	VisClass

	push	bp			; preserve bp for end

	push	ax
	mov	bx, ds:[si]		; get ptr to child instance data
	cmp	ds:[bx].Vis_offset, 0	; Has visible part been grown yet?
	jne	AfterVisGrown		; branch if so
					; Else grow it.
	mov	bx, Vis_offset
	push	es:[LMBH_handle]	; save handle of comp block
	call	ObjInitializePart	; Make sure part has been grown
	pop	bx			; get handle of comp block
	call	MemDerefES		; restore segment of comp block to ES
	mov	bx, ds:[si]		; Get pointer to instance
AfterVisGrown:

	add	bx, ds:[bx].Vis_offset	; ds:bx = VisInstance

	; Make sure we don't send it to something not usable
	push	di
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GI_states, mask GS_USABLE
	pop	di
	jz	Done			; If not usable, skip sending message

	; Make sure we don't send to something that isn't allowed by dl flags
	tst	dl			; If clear, then flags don't need to
					;	be tested.
	jz	AfterOptFlagAbortTest
	test	ds:[bx].VI_optFlags, dl	; see if any of the flags are set
	jz	Done			; no, can't send through to object
AfterOptFlagAbortTest:

	; If this is NOT a WIN_GROUP, then allow message to be sent
	test	ds:[bx].VI_typeFlags, mask VTF_IS_WIN_GROUP
	jz	AfterWinGroupAbortTest	; if not, send message

	; If this is a DUAL_BUILD object, then allow message to be sent
	test	ds:[bx].VI_specAttrs, mask SA_USES_DUAL_BUILD
;	jnz	AfterWinGroupAbortTest	; if so, send it

	; If a pure WIN_GROUP, see if we should take optimization for
	; MSG_SPEC_BUILD_BRANCH or not.  (Code removed 5/ 4/92 cbh that
	; forces displays to be spec built.  We suspect this code is no longer
	; needed.)
	;
	jz	Done

;	cmp	ax, MSG_SPEC_BUILD_BRANCH
;	jne	Done			; if not update spec build, don't send
;					; message to WIN_GROUP's
;
;	test	ds:[bx].VI_specAttrs, mask SA_SPEC_BUILD_ALWAYS
;	jz	Done			; if bit not set, then don't build out
;					; the WIN_GROUP.  If it is, then fall
;					; through & build out per the request
;
;					; Set SpecBuildFlags for win-group, tree
;					; build when crossing boundary to 
;					; a WIN_GROUP
;	andnf	bp, not mask SBF_IN_UPDATE_WIN_GROUP
;	ornf	bp, mask SBF_WIN_GROUP or mask SBF_TREE_BUILD

AfterWinGroupAbortTest:

	push	cx
	push	dx			; preserve flag passed
					; Use ES version since *es:di is
					;	composite object
	mov	dx, cx			; pass argument in both cx and dx
	call	ObjCallInstanceNoLockES	; send it
	pop	dx
	pop	cx
Done:
	clc

	pop	ax
	pop	bp
	ret

CCWFS_callBack	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	VisConvertSpecVisSize

SYNOPSIS:	Converts a SpecVisSize value into a pixel value for an 
		object.   Doesn't do anything if the value has been 
		previously converted (to something less than 1023).

CALLED BY:	utility

PASS:		*ds:si -- handle of visible object (must be in visible tree)
		ax	- SpecSizeSpec value (Documented in visClass.asm)
			  (cx for message version)
		di	- GState including font to use for conversion
			  (bp for message version)

RETURN:		ax	- pixel value (cx for message version)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		You can only pass pixel data through untouched if the return 
		value is less than 1024.  Otherwise the routine will do 
		something you don't expect (actually the current version will 
		fatal error between 1023 and 2047).

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Clayton	10/89		Initial version

------------------------------------------------------------------------------@

BuildUncommon segment resource

VisConvertSize		method VisClass, MSG_SPEC_CONVERT_SIZE
	mov	di, bp
	mov	ax, cx
	call	VisConvertSpecVisSize
	mov	cx, ax
	ret
VisConvertSize		endm

BuildUncommon ends
			
VisConvertSpecVisSize	proc	far
	class	VisClass
	uses	cx, dx, bp, di, si
	
	.enter
	tst	ax				; no desired size, exit
	jz	exit
	push	bx
	mov	bl, ah				; Get the SpecSizeType
	and	bl, (mask SSS_TYPE) shr 8
	clr	bh
	shr	bl, 1				; Calc its jumptable routine
EC <	cmp	bx, (SST_LINES_OF_TEXT * 2) ; and check if it's valid >
EC <	jle	VCSVS_10						>
EC <	ERROR	UI_VIS_BAD_SPEC_SIZE_ARGUMENT				>
EC <VCSVS_10:								>
	add	bx, offset SpecSizeRoutines	
	call	cs:[bx]				; If so, go calc size
	pop	bx
exit:
	.leave
	ret
VisConvertSpecVisSize	endp

			
			
SpecSizeRoutines	label 	word
	word	offset SpecSizePixels		;SST_PIXELS
	word	offset SpecSizeError		;SST_COUNT
		; You can't call this routine to process SST_COUNT.  It should
		; be handled by the caller in conjunction with one of the
		; SpecSizeTypes below.
	word	offset SpecSizePercentScrWidth	;SST_PCT_OF_FIELD_WIDTH
	word	offset SpecSizePercentScrHeight	;SST_PCT_OF_FIELD_HEIGHT
	word	offset SpecSizeNumAvgCharWidth	;SST_AVG_CHAR_WIDTHS
	word	offset SpecSizeNumMaxCharWidth	;SST_WIDE_CHAR_WIDTHS
	word	offset SpecSizeNumTextLines	;SST_LINES_OF_TEXT


SpecSizePercentScrWidth	proc	near
	and	ax, mask SSS_DATA		; Clear out the type bits
	mov	bx, ax				; Extract the percentage of
	push	bx				;   the scr width & save it
	;
	; Get the field height and width
	
	call	GetSizeOfField
	;
	; Now calculate the percentage of the screen width
	pop	bx				; Recover the % of screen width
	mov	ax, cx				; Use the screen width
	call	CalcPercentOfScreen		;   and calc % of screen width
	ret
SpecSizePercentScrWidth	endp

GetSizeOfField	proc	near
	push	si
	clr	cx
	clr	dx		; assume no size if nothing found
	mov	ax, MSG_VIS_GET_SIZE
	mov	bx, segment GenFieldClass
	mov	si, offset GenFieldClass
	mov	di, mask MF_RECORD 
	call	ObjMessage
	mov	cx, di		; Get handle to ClassedEvent in cx
	pop	si		; Get object below primary to be iconified
	mov	ax, MSG_VIS_VUP_CALL_OBJECT_OF_CLASS
	call	UserCallApplication
	jcxz	tryScreen
	tst	dx
	jnz	haveSize
tryScreen:
	push	si
EC <	clr	cx							>
EC <	clr	dx		; assume no size if nothing found	>
	mov	ax, MSG_VIS_GET_SIZE
	mov	bx, segment GenScreenClass
	mov	si, offset GenScreenClass
	mov	di, mask MF_RECORD 
	call	ObjMessage
	mov	cx, di		; Get handle to ClassedEvent in cx
	pop	si		; Get object below primary to be iconified
	mov	ax, MSG_VIS_VUP_CALL_OBJECT_OF_CLASS
	call	UserCallApplication
haveSize:
EC <	tst	cx							>
EC <	ERROR_Z	UI_VIS_SPEC_CANT_GET_A_FIELD_SIZE			>
EC <	tst	dx							>
EC <	ERROR_Z	UI_VIS_SPEC_CANT_GET_A_FIELD_SIZE			>
	ret
GetSizeOfField	endp
		
SpecSizePercentScrHeight	proc	near
	and	ax, mask SSS_DATA		; Clear out the type bits
	mov	bx, ax				; Extract the percentage of
	push	bx				;    the scr height & save it
	;
	; Get the screen height and width
	
	call	GetSizeOfField
	;
	; Now calculate the percentage of the screen height
	pop	bx				; Recover the percentage
	mov	ax, dx				; Use the screen height
	call	CalcPercentOfScreen		;   and calc % of screen height
	ret
SpecSizePercentScrHeight	endp

CalcPercentOfScreen	proc	near		; ax = screeen size
						; bx = % of screen size
	mul	bx				; Calc total size in DX:AX
	mov	cx, 6				; Shift the integer part of 
SSPSW_20:					;   the result into DX
	sal	ax, 1				;   (then AX is the fractional
	rcl	dx, 1				;    part)
	loop	SSPSW_20
	tst	ax				; Check if you should round up
	jns	SSPSW_30
	inc	dx				;   Round up, if necessary
SSPSW_30:
	mov	ax, dx				; Ret (calculated size in AX)
	ret
CalcPercentOfScreen	endp

SpecSizeNumAvgCharWidth	proc	near
	push	ax				;Save # characters
	mov	si, GFMI_ROUNDED or GFMI_AVERAGE_WIDTH
	call	GrFontMetrics			;get average character width
PZ <	shr	dx, 1				;dx <- 1/2 max for Pizza>
	pop	ax
	and	ax, mask SSS_DATA		;Clear out the type bits
	mul	dl				;Calc total width (# chars *
						; average width)
	ret
SpecSizeNumAvgCharWidth	endp

SpecSizeNumMaxCharWidth	proc	near
	push	ax				;Save # characters
	mov	si, GFMI_ROUNDED or GFMI_MAX_WIDTH
	call	GrFontMetrics			;get maximum character width
	pop	ax
	and	ax, mask SSS_DATA		;Clear out the type bits
	mul	dl				;Calc total width (# chars *
	ret
SpecSizeNumMaxCharWidth	endp

SpecSizeNumTextLines	proc	near
	and	ax, mask SSS_DATA		; Clear out the type bits
	mov	si, GFMI_HEIGHT or GFMI_ROUNDED	;si <- info to return, rounded
	call	GrFontMetrics			;dx -> font height
	mov	cx, dx				;cx <- font height
	mul	cl				; Calc total height
	ret
SpecSizeNumTextLines	endp

SpecSizePixels	proc	near
;	and	ax, mask SSS_DATA		; This enum is zero already
	ret					; Just return pixel data
SpecSizePixels	endp

SpecSizeError	proc	near
EC <	ERROR	UI_VIS_SPEC_SIZE_CANT_USE_COUNT_HERE			>
NEC <	ret								>
SpecSizeError	endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	VisConvertCoordsToRatio

SYNOPSIS:	Converts a coordinate pair (x,y) value into a SpecWinSizePair
		structure (see visClass.asm)

CALLED BY:	utility

PASS:		*ds:si - handle of visible object (must be in visible tree)
		ax, bx - coordinate pair (in pixels, can be negative)
		cl     - clear if comparing coords to win group size, 
			 set if comparing to field

RETURN:		ax, bx	- SpecWinSizePair structure

DESTROYED:	cx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	11/89		Initial version

------------------------------------------------------------------------------@

BuildUncommon segment resource

VisConvertCoordsToRatio	proc	far
	push	bp
	push	di
	push	dx

	;first send a query up the visual tree to find the size of the Field
	;window.

	call	GetSizeOfFieldOrWinGroup	;
	
	;pass ax = coordinate, cx = Field size value

	push	dx
	call	VisConvertCoordToRatio	;returns ax = ratio for X coordinate
	xchg	ax, bx			;set bx = result, ax = Y coordinate

	pop	cx			;pass cx = Field height this time
	call	VisConvertCoordToRatio	;convert Y coord to ratio
	xchg	ax, bx			;swap results
	pop	dx
	pop	di
	pop	bp
	ret
VisConvertCoordsToRatio	endp

;pass:
;	ax = coordinate value (in pixels, can be negative)
;	cx = Field window size value (in pixels)
;return:
;	ax = SpecWinSizeSpec (with FIELD flag set)
;trashes:
;	dx

	.assert	(offset SWSS_RATIO) ge 8
	.assert	(offset SWSS_MANTISSA) eq 10

VisConvertCoordToRatio	proc	near
	;in our universe, it is considered bad to divide by 0!
EC <	tst	cx							>
EC <	ERROR_Z	UI_RATIO_OF_FIELD_WITH_FIELD_SIZE_ZERO			>

	tst	ax			;is it negative?
	pushf				;save sign of coordinate
	jns	isMagnitude		;skip if not...

	neg	ax			;calculate magnitude

isMagnitude:
	;first must test for overflow, because DIV instruction is lame

;NOTE:  ERIC: test for overflow in VisConvertCoordToRatio

	;now multiple the divisor (coord) by 2^10 (1024) so that the fractional
	;portion of the result has 10 bits.

	clr	dh
	mov	dl, ah			;8-bit shift from ax into dx
	mov	ah, al
	clr	al

	shl	ah, 1			;now shift 2 bits from ah into dx
	rcl	dx
	shl	ah, 1
	rcl	dx

	div	cx			;set AX = DX:AX / CX

	;check for overflow: value >= 16.0

	test	ah, (not (mask SWSS_MANTISSA or mask SWSS_FRACTION)) shr 8
	jz	noOverflow

	mov	ax, mask SWSS_MANTISSA or mask SWSS_FRACTION
					;stuff MAX value (x15.99999999)

noOverflow:
	or	ah, (mask SWSS_RATIO) shr 8	;set flag: is ratio
	popf				;check sign
	jns	noSign

	or	ah, (mask SWSS_SIGN) shr 8 ;set flag: is negative
noSign:
	ret

VisConvertCoordToRatio	endp

BuildUncommon ends

COMMENT @----------------------------------------------------------------------

ROUTINE:	GetSizeOfFieldOrWinGroup

SYNOPSIS:	Returns size of field or win group, depending on cl.

CALLED BY:	VisConvertCoordToRatio, VisConvertRatioToCoord

PASS:		*ds:si -- object
		cl     - clear to get win group size, 
			 set to get field size.

RETURN:		cx, dx -- size of win group or field,
			  zero if no info yet.

DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	8/ 6/91		Initial version

------------------------------------------------------------------------------@

GetSizeOfFieldOrWinGroup	proc	far	uses	ax, bx
	.enter
	mov	ax, MSG_VIS_VUP_CALL_WIN_GROUP	;assume we're looking for a
	mov	bx, segment VisClass		;  win group
	mov	di, offset VisClass	
	tst	cl			
	jz	10$
	mov	ax, MSG_VIS_VUP_CALL_OBJECT_OF_CLASS 
	mov	bx, segment GenFieldClass	;look for a field instead
	mov	di, offset GenFieldClass
10$:
	push	ax				;save method to use to find size
	push	si				;save our handle
	mov	si, di				;class to allow in bx:si
	mov	ax, MSG_VIS_GET_SIZE
	mov	di, mask MF_RECORD 
	call	ObjMessage
	mov	cx, di			        ;Get ClassedEvent in ^hcx
	pop	si
	pop	ax				;restore method to use

EC <	tst	si							>
EC <	ERROR_Z	UI_TRIED_TO_GET_WINDOW_SIZE_WITHOUT_VIS_PARENT		>

	;
	; If no vis parent yet, return zeroes.  -cbh 4/21/93
	;
	push	si
	call	VisFindParent
	tst	si
	pop	si
	jz	returnZeroes

	call	VisCallParent
exit:
	.leave
	ret


returnZeroes:
	clr	cx
	clr	dx
	jmp	short exit


GetSizeOfFieldOrWinGroup	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	VisConvertRatioToCoords

SYNOPSIS:	Converts a coordinate pair (x,y) value into a SpecWinSizePair
		structure (see visClass.asm)

CALLED BY:	utility

PASS:		*ds:si -- handle of visible object (must be in visible tree)
		ax, bx	- SpecWinSizePair structure
		cl     - clear if comparing coords to win group size, 
			 set if comparing to field

RETURN:		ax, bx	- coordinate pair (in pixels, can be negative)
		carry set if parent geometry was invalid (size = 0)

DESTROYED:	cx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	11/89		Initial version

------------------------------------------------------------------------------@

	.assert	(offset SWSS_RATIO) ge 8

VisConvertRatioToCoords	proc	far
	test	ah, (mask SWSS_RATIO) shr 8	;is it a ratio?
	jnz	isRatio				;skip if so...

	;are pixel values: just extend sign

	test	ah, (mask SWSS_SIGN) shr 8	;negative?
	jz	haveX			;skip if not...
	or	ah, 80h			;set sign bit
haveX:
	test	bh, (mask SWSS_SIGN) shr 8	;negative?
	jz	haveY			;skip if not...
	or	bh, 80h			;set sign bit
haveY:
	clc				;flag: "parent" was OK.
	ret

isRatio:
	;first send a query up the visual tree to find the size of the
	;Field or Parent window.

	call	GetSizeOfFieldOrWinGroup
	tst	cx
	jne	isOK
	tst	dx
	jne	isOK

	;abort with carry set, indicating parent geometry not set yet
	stc
	ret

isOK:	;pass ax = coordinate, cx = Field/Parent size value
	push	dx
	call	VisConvertRatioToCoord	;returns ax = X coordinate
	xchg	ax, bx			;set bx = result, ax = Y SpecWinSizeSpec

	pop	cx			;pass cx = Field/Parent height this time
	call	VisConvertRatioToCoord	;convert Y SpecWinSizeSpec to coord
	xchg	ax, bx			;swap results
	clc				;indicate parent geometry was OK
	ret
VisConvertRatioToCoords	endp

;pass:
;	ax = SpecWinSizeSpec
;	cx = Field/Parent window size value (in pixels)
;return:
;	ax = coordinate value (in pixels, can be negative)
;trashes:
;	dx

	.assert	(offset SWSS_SIGN) eq 14
	.assert (offset SWSS_MANTISSA) eq 10

VisConvertRatioToCoord	proc	near
	sahf				;set ZF= AX:14 (SWSS_SIGN)
	pushf

	and	ax, mask SWSS_MANTISSA or mask SWSS_FRACTION
					;keep value only

	;
	; Our fraction goes up to 3fffh, not 4000h.  To get accurate results,
	; we must bump all values above PCT_50 a pixel.  (-cbh 1/28/93)
	;
	test	ax, PCT_50		
	jz	multiply
	inc	ax

multiply:
	mul	cx			;DX:AX = AX*CX

	mov	al, ah			;divide by 2^10 to normalize
	mov	ah, dl
	shr	ax, 1
	shr	ax, 1
	jnc	checkSign		;skip if not rounding up...

	inc	ax			;round up

checkSign:
	popf				;check sign of SpecWinSizeSpec
					;(IS IN Z FLAG)
	jnz	notSigned		;skip if not sign...

	neg	ax			;negate value

notSigned:
	ret

VisConvertRatioToCoord	endp

Build	ends
;
;-------------------
;
VisOpenClose	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		VisGetGenBranchInfo

DESCRIPTION:	Check to see if this object & all objects above it through
		the WIN_GROUP are USABLE, & that the specific UI has not
		decided to visually minimize the branch at any point

PASS:
	*ds:si - instance data

RETURN:
	ax	- GenBranchInfo
		  mask GBI_USABLE set if object is completely usable
			(ALL generic parents checked)
		  mask GBI_BRANCH_MINIMIZED set if in a branch which
		 	 the specific UI has set the SA_BRANCH_MINIMIZED in.
			 (Only valid if GBI_USABLE is set)
	ds - updated to point at segment of same block as on entry

DESTROYED:
	Nothing
	
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

	This thing currently has to go all the way through GenSystem testing!
	This is due mostly to the fact that we won't know a WIN_GROUP when
	we see it, since this is a visible attribute, & the object may NOT
	be specifically built.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	10/1/89		Initial version

------------------------------------------------------------------------------@


VisGetGenBranchInfo	proc	far
	push	bx
	push	di
	push	bp
				; Start w/flags assuming usable, until
				; proved otherwise.  Likewise, assume
				; NOT in minimized branch.
	mov	bp, mask GBI_USABLE
				; Call recursive routine to check here &
				; all parents
	call	VisContinueGenBranchCheck

	mov	ax, bp		; Put return values in ax
	pop	bp
	pop	di
	pop	bx
	ret

VisGetGenBranchInfo	endp


COMMENT @----------------------------------------------------------------------

METHOD/ROUTINE:		VisContinueGenBranchCheck

DESCRIPTION:	Check to see if this object & all objects above it through
		the WIN_GROUP are USABLE, & that the specific UI has not
		decided to visually minimize the branch at any point


PASS:
	*ds:si - instance data
	bp	- current GenBranchInfo flags


RETURN:
	bp	- mask GBI_USABLE cleared if any generic
			parent found that is not usable
		- mask GBI_BRANCH_MINIMIZED set if in a branch which the
			specific UI has set the SA_BRANCH_MINIMIZED in.
			(Only valid if GBI_USABLE is set)
	ds - updated to point at segment of same block as on entry


DESTROYED:
	ax, bx, di
	
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

	This thing currently has to go all the way through GenSystem testing!

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	10/1/89		Initial version

------------------------------------------------------------------------------@

;
; Call-back routine for VisExecute call above
;
VisContinueRoutine	proc	far
	class	VisClass
EC <	; Make sure master part grown out				>
EC <	;								>
EC <	call	VisCheckVisAssumption					>
EC <									>
EC <	; Make sure actually of VisClass				>
EC <	;								>
EC <	push	di, es							>
EC <	mov	di, segment VisClass					>
EC <	mov	es, di							>
EC <	mov	di, offset VisClass					>
EC <	call	ObjIsObjectInClass					>
EC <	pop	di, es							>
EC <	ERROR_NC	UI_EXPECTED_VIS_CLASS_OBJECT			>

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_specAttrs, mask SA_BRANCH_MINIMIZED
	jz	done			; if clear, not minimized, done.
					; Else SET the flag
	or	bp, mask GBI_BRANCH_MINIMIZED
	jmp	short exit		; can stop going up now
done:
					; Call this routine to do recursion
	call	VisContinueGenBranchCheck
exit:
	ret
VisContinueRoutine	endp

VisContinueGenBranchCheck	proc	far	uses	cx, si
	class	GenClass
	.enter

	clr	cl			; presume no visible attr flags

	mov	di, ds:[si]		; & check for GS_USABLE bit
	add	di, ds:[di].Gen_offset
	test	ds:[di].GI_states, mask GS_USABLE
	jz	notUsable		; if NOT usable, done, return
					; that object is NOT fully usable

	call	VisCheckIfVisGrown	; See if has visible part
	jnc	afterNotMinimizableCheck
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	cl, ds:[di].VI_attrs	; fetch visible attributes
afterNotMinimizableCheck:

	call	GenFindParent		; Get generic parent
	tst	bx
	jz	afterParent		; if no parent, don't go up, done

	mov	ax, SEGMENT_CS		; Call back routine in same segment
	mov	di, offset VisContinueRoutine
	call	VisExecute		; Execute routine on object in ^bx:si
	jmp	short afterParent

notUsable:
	and	bp, not mask GBI_USABLE	; clear usable bit.

afterParent:
					; See if this object overrides 
					; branch minimized bit
	test	cl, mask VA_BRANCH_NOT_MINIMIZABLE
	jz	done
					; if so, if does override, clear bit
	and	bp, not mask GBI_BRANCH_MINIMIZED
done:
	.leave
	ret

VisContinueGenBranchCheck	endp


VisOpenClose	ends
;
;-------------------
;
Build	segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	VisGetSpecificVisObject

DESCRIPTION:	Do default message of determining what visual object is
		representing a generic object.

CALLED BY:	EXTERNAL

PASS:
	*ds:si	- object to figure out vis
	bp	- SpecBuildFlags:
		mask SBF_WIN_GROUP

RETURN:
	*ds:si	- still pointing at object
	(ds - updated to point at segment of same block as on entry)
	cx:dx	- Visual object representing generic object, or 0 if none

DESTROYED:
	Nothing
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/89		Initial version
------------------------------------------------------------------------------@

VisGetSpecificVisObject	proc	far
	class	VisClass		; Indicate function is a friend
					; of VisClass so it can play with
					; instance data.

	push	ax
	push	di
				; If no visible section, then we may assume
				; that the GENERIC object has not been visually
				; built, since even if it uses dual build, it
				; must grow out the visible portion to be
				; able to set the vis flags
	call	VisCheckIfVisGrown
	jnc	VGSVO_NoObj	; if not grown, return NULL visible object
				; for specific implementation

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
				; See if simple generic object (one vis)
	test	ds:[di].VI_specAttrs, mask SA_SIMPLE_GEN_OBJ
	jnz	VGSVO_Default	; if so, is this object if WIN_GROUP flag
				; matches (branch to handle)

				; ELSE ...
				; Call custom message handler to determine
				; 	visual object representing gen object
	mov	ax, MSG_SPEC_GET_SPECIFIC_VIS_OBJECT
	call	ObjCallInstanceNoLock
	jc	VGSVO_Done	; if reply received, use it.
				; OTHERWISE, fall through & use default

VGSVO_Default:

				; DOES object use dual build?
EC <	test	ds:[di].VI_specAttrs, mask SA_USES_DUAL_BUILD		   >
EC <				; If so, Can't use default handler.	   >
EC <	ERROR_NZ	UI_MISSING_HANDLER_FOR_SPEC_GET_SPECIFIC_VIS_OBJECT >


				; Is this object a win group?
	test	ds:[di].VI_typeFlags, mask VTF_IS_WIN_GROUP
	jnz	VGSVO_WinGroups	; skip if not
				; HERE if NOT a win group.  Are we looking for
				; a non-win group?
	test	bp, mask SBF_WIN_GROUP
	jz	VGSVO_ThisObj	; if so, use this object
	jnz	VGSVO_NoObj	; if not, skip this object

VGSVO_WinGroups:
				; HERE if a WIN GROUP. Are we looking for one?
	test	bp, mask SBF_WIN_GROUP
	jnz	VGSVO_ThisObj	; if so, use this object

VGSVO_NoObj:
	clr	cx		; No visible representation
	clr	dx
	jmp	short VGSVO_Done

VGSVO_ThisObj:
				; This object IS the visual representation
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
VGSVO_Done:
	pop	di
	pop	ax	
	ret

VisGetSpecificVisObject	endp

			


COMMENT @----------------------------------------------------------------------

ROUTINE:	VisApplySizeHints

SYNOPSIS:	For generic objects, looks for any of the size hints (HINT_
		FIXED_SIZE, HINT_INITIAL_SIZE, HINT_MINIMUM_SIZE, HINT_
		MAXIMUM_SIZE), converts them to pixel values, and applies
		the values to the passed size as appropriate.  This is called
		at the start of MSG_VIS_RECALC_SIZE handlers for objects,
		to fix things up as needed.  Some objects may want to do
		special things with the hints instead of this standard stuff,
		or only apply certain hints.  See VisSetupSizeArgs, 
		VisApplyInitialSizeArgs, VisApplySizeArgsToWidth, and 
		VisApplySizeArgsToHeight for ways to do this.

CALLED BY:	utility

PASS:		*ds:si -- object
		cx, dx -- passed size

		ax, bx	-- DON'T CARE (may safely be called using CallMod)

RETURN:		cx, dx -- passed size, adjusted as necessary

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
       VisSetupSizeArgs (SSA_minWidth, SSA_minHeight, SSA_maxWidth, SSA_maxHeight, 
		SSA_initWidth, SSA_initHeight)
       if coming up for the first time
       		if SSA_initWidth cx = SSA_initWidth
		if SSA_initHeight dx = SSA_initHeight
       if SSA_maxWidth and (cx < SSA_maxWidth)
       		cx = SSA_maxWidth
       if SSA_minWidth and (cx > SSA_minWidth)
       		cx = SSA_minWidth
       if SSA_maxHeight and (dx < SSA_maxHeight)
       		dx = SSA_maxHeight
       if SSA_minHeight and (dx > SSA_minHeight)
       		dx = SSA_minHeight

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/30/91		Initial version

------------------------------------------------------------------------------@

VisApplySizeHints	proc	far		
	class	VisClass
	desiredSize		local	SpecSizeArgs
	.enter
	ForceRef	desiredSize		;to get esp to shut up
	
	call	VisSetupSizeArgs		;set up local vars
	call	VisApplyInitialSizeArgs
	call	VisApplySizeArgsToWidth
	call	VisApplySizeArgsToHeight
	.leave
	ret
VisApplySizeHints	endp


			


COMMENT @----------------------------------------------------------------------

ROUTINE:	VisApplyInitialSizeArgs

SYNOPSIS:	For generic objects, looks for HINT_INITIAL_SIZE, converts the
		arguments to pixel values, and applies them to the passed size
		if the object is sizing for the first time. This is often called
		at the start of MSG_VIS_RECALC_SIZE handlers for objects.
		It is assumed that VisSetupSizeArgs has been called to load
		any size hint arguments into local storage, like so:
		
		desiredSize		local	SpecSizeArgs
		.enter
		call	VisSetupSizeArgs		;set up local vars
		call	VisApplyInitialSizeArgs
		
		The simpler approach that works for most objects is to call
		VisApplySizeHints.  Check that routine to see what it does.

CALLED BY:	global

PASS:		ss:bp  -- SpecSizeArgs
		cx, dx -- passed size

RETURN:		cx, dx -- size updated if necessary

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
       if coming up for the first time
       		if SSA_initWidth cx = SSA_initWidth
		if SSA_initHeight dx = SSA_initHeight

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	8/ 1/91		Initial version

------------------------------------------------------------------------------@

VisApplyInitialSizeArgs	proc	far
	class	VisClass
	desiredSize		local	SpecSizeArgs
	.enter	inherit
	
	push	di
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_geoAttrs, mask VGA_GEOMETRY_CALCULATED
	jnz	5$				;not initial sizing, branch
	tst	cx				;can choose width?
	jns	3$				;no, don't use our value
	tst	desiredSize.SSA_initWidth
	jz	3$
	mov	cx, desiredSize.SSA_initWidth
3$:	
	tst	desiredSize.SSA_initHeight
	jz	5$
	tst	dx				;can choose height?
	jns	5$				;no, don't use our value
	mov	dx, desiredSize.SSA_initHeight
5$:	
	pop	di
	.leave
	ret
VisApplyInitialSizeArgs	endp




COMMENT @----------------------------------------------------------------------

ROUTINE:	VisApplySizeArgsToWidth

SYNOPSIS:	Limits width to any minimum or maximum widths specified.
		It is assumed that VisSetupSizeArgs has been called to load
		any size hint arguments into local storage, like so:
		
		desiredSize		local	SpecSizeArgs
		.enter
		call	VisSetupSizeArgs		;set up local vars
		call	VisApplySizeArgsToHeight
		
		The simpler approach that works for most objects is to call
		VisApplySizeHints.  Check that routine to see what it does.

CALLED BY:	global

PASS:		ss:bp -- SpecSizeArgs
		cx    -- width

RETURN:		cx -- width, possibly changed

DESTROYED:	ax

PSEUDO CODE/STRATEGY:
       if SSA_maxWidth and (cx < SSA_maxWidth)
       		cx = SSA_maxWidth
       if SSA_minWidth and (cx > SSA_minWidth)
       		cx = SSA_minWidth

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	8/ 1/91		Initial version

------------------------------------------------------------------------------@

VisApplySizeArgsToWidth	proc	far
	class	VisClass
	desiredSize		local	SpecSizeArgs
	.enter	inherit
	;
	; Change this code to use fixed size, when there, regardless of
	; whether desired size is passed in or not.  This is because we
	; don't want to not wrap on the first pass, return a huge width,
	; then wrap the damn thing on the second pass.  It kind of leaves
	; the parent hanging with a big width, especially if it had expand-
	; to-fit children in there as well.  -cbh 5/15/91
	;
	tst	desiredSize.SSA_fixedWidth		;doing fixed width, go ahead
	jnz	10$				;  and replace desired with
						;  the fixed (also max) size.
	tst	cx				;passed desired, branch
	js	exit
10$:
	mov	ax, desiredSize.SSA_maxWidth	;get maximum width
	tst	ax				;is there any?
	jz	limitWidthToMin			;no, branch
	cmp	cx, ax				;is passed value larger?
	jb	limitWidthToMin			;no, leave it alone
	mov	cx, ax				;else replace it
	
limitWidthToMin:
	mov	ax, desiredSize.SSA_minWidth	;get minimum width
	tst	ax				;is there any?
	jz	exit				;no, branch
	cmp	cx, ax				;is passed value smaller?
	ja	exit				;no, leave it alone
	mov	cx, ax				;else replace it
exit:
	.leave
	ret
VisApplySizeArgsToWidth	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	VisApplySizeArgsToHeight

SYNOPSIS:	Limits height to any minimum or maximum heights specified.
		It is assumed that VisSetupSizeArgs has been called to load
		any size hint arguments into local storage, like so:
		
		desiredSize		local	SpecSizeArgs
		.enter
		call	VisSetupSizeArgs		;set up local vars
		call	VisApplySizeArgsToHeight
		
		The simpler approach that works for most objects is to call
		VisApplySizeHints.  Check that routine to see what it does.

CALLED BY:	global

PASS:		ss:bp -- SpecSizeArgs
		dx    -- height

RETURN:		dx -- height, possibly changed

DESTROYED:	ax

PSEUDO CODE/STRATEGY:
       if SSA_maxHeight and (dx < SSA_maxHeight)
       		dx = SSA_maxHeight
       if SSA_minHeight and (dx > SSA_minHeight)
       		dx = SSA_minHeight

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	8/ 1/91		Initial version

------------------------------------------------------------------------------@

VisApplySizeArgsToHeight	proc	far
	class	VisClass
	desiredSize		local	SpecSizeArgs
	.enter	inherit
	;
	; Change this code to use fixed size, when there, regardless of
	; whether desired size is passed in or not.  This is because we
	; don't want to not wrap on the first pass, return a huge height,
	; then wrap the damn thing on the second pass.  It kind of leaves
	; the parent hanging with a big height, especially if it had expand-
	; to-fit children in there as well.  -cbh 5/15/91
	;
	tst	desiredSize.SSA_fixedHeight		;doing fixed height, go ahead
	jnz	10$				;  and replace desired with
						;  the fixed (also max) size.
	tst	dx				;passed desired, branch
	js	exit
10$:
	mov	ax, desiredSize.SSA_maxHeight	;get maximum height
	tst	ax				;is there any?
	jz	limitHeightToMin		;no, branch
	cmp	dx, ax				;is passed value larger?
	jb	limitHeightToMin		;no, leave it alone
	mov	dx, ax				;else replace it
	
limitHeightToMin:
	mov	ax, desiredSize.SSA_minHeight	;get minimum height
	tst	ax				;is there any?
	jz	exit				;no, branch
	cmp	dx, ax				;is passed value smaller?
	ja	exit				;no, leave it alone
	mov	dx, ax				;else replace it
exit:
	.leave
	ret
VisApplySizeArgsToHeight	endp


	


COMMENT @----------------------------------------------------------------------

ROUTINE:	VisSetupSizeArgs

SYNOPSIS:	For generic objects, looks for any of the size hints (HINT_
		FIXED_SIZE, HINT_INITIAL_SIZE, HINT_MINIMUM_SIZE, HINT_
		MAXIMUM_SIZE), converts them to pixel values, and leaves
		the results in local variables which have been set up 
		beforehand like so:
		
		desiredSize		local	SpecSizeArgs
		.enter
		call	VisSetupSizeArgs		;set up local vars
		
		MSG_VIS_RECALC_SIZE handlers will use these values to change
		the size returned.  The simpler approach that works for most 
		handlers is to call VisApplySizeHints.  Check that routine to 
		see what it does.

CALLED BY:	DoDesiredSizeProcessing

PASS:		ss:bp-(size SpecSizeArgs) --- inherited SpecSizeArgs

RETURN:		SpecSizeArgs -- filled in

DESTROYED:	es may need to be fixed up around this routine, as it makes
		method calls.

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/30/91		Initial version
	Chris	12/18/92	Changed to give min and max precendence over
				fixed size.

------------------------------------------------------------------------------@

VisSetupSizeArgs	proc	far	uses	ax, bx, cx, dx, bp, di, es
	class	VisClass
	desiredSize	local	SpecSizeArgs
	.enter	inherit
	
	segmov	es, ss
	lea	di, desiredSize			
	mov	ax, 0
	mov	cx, (size SpecSizeArgs)/2
	rep	stosw				;initialize local vars
	
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_typeFlags, mask VTF_IS_GEN	
	jz	exit				;not generic object, exit now
	
	test	ds:[di].VI_geoAttrs, mask VGA_NO_SIZE_HINTS
	jnz	exit				;already checked for hints,exit
	or	ds:[di].VI_geoAttrs, mask VGA_NO_SIZE_HINTS
						;else assume no hints here
	mov	di, cs
	mov	es, di
	mov	di, offset cs:DesiredSizeHints
	mov	ax, length (cs:DesiredSizeHints)
	call	ObjVarScanData			;scan for raw hints

	mov	ax, desiredSize.SSA_minWidth	
	mov	cx, desiredSize.SSA_fixedWidth	
	mov	dx, desiredSize.SSA_maxWidth
	call	CorrectMinMaxFixedSizesIfNeeded
	mov	desiredSize.SSA_minWidth, ax
	mov	desiredSize.SSA_fixedWidth, cx
	mov	desiredSize.SSA_maxWidth, dx

	mov	ax, desiredSize.SSA_minHeight	
	mov	cx, desiredSize.SSA_fixedHeight
	mov	dx, desiredSize.SSA_maxHeight
	call	CorrectMinMaxFixedSizesIfNeeded
	mov	desiredSize.SSA_minHeight, ax
	mov	desiredSize.SSA_fixedHeight, cx
	mov	desiredSize.SSA_maxHeight, dx


	mov	ax, desiredSize.SSA_fixedNumChildren
	tst	ax
	jz	exit
	mov	desiredSize.SSA_minNumChildren, ax
	mov	desiredSize.SSA_maxNumChildren, ax
exit:
	.leave
	ret
VisSetupSizeArgs	endp

			
DesiredSizeHints	VarDataHandler \
 <HINT_INITIAL_SIZE, offset InitialSize>,
 <HINT_MINIMUM_SIZE, offset MinimumSize>,
 <HINT_MAXIMUM_SIZE, offset MaximumSize>,
 <HINT_FIXED_SIZE, offset FixedSize>
 



COMMENT @----------------------------------------------------------------------

ROUTINE:	CorrectMinMaxFixedSizesIfNeeded

SYNOPSIS:	Adjusts min, max, fixed sizes according to proper precidence.

CALLED BY:	VisSetupSizeArgs

PASS:		ax -- minimum size
		cx -- fixed size
		dx -- maximum size

RETURN:		ax, cx, dx -- updated

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	if fixedSize 
		if maximumSize and (fixedSize > maximumSize)
				fixedSize = maximumSize
			else
				maximumSize = fixedSize
		if minimumSize and (fixedSize < minimumSize)
				fixedSize = minimumSize
				maximumSize = minimumSize
			else
				minimumSize = fixedSize

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/20/92       	Initial version

------------------------------------------------------------------------------@

CorrectMinMaxFixedSizesIfNeeded	proc	near
	tst	cx				;no fixed size, exit
	jz	exit				

	tst	dx				;no max size, use fixed
	jz	maxIsFixed			
	
	cmp	cx, dx				;else keep the smaller
	jbe	maxIsFixed
	mov	cx, dx	
	jmp	short tryMin

maxIsFixed:
	mov	dx, cx
tryMin:
	tst	ax				;no min size, use fixed
	jz	minIsFixed
	
	cmp	cx, ax				;else keep the larger
	jae	minIsFixed
	mov	cx, ax				;fixed is minimum
	mov	dx, ax				;max is minimum, too
	jmp	short exit

minIsFixed:
	mov	ax, cx
exit:
	ret

CorrectMinMaxFixedSizesIfNeeded	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	FixedSize, InitialSize, MaximumSize, MinimumSize

SYNOPSIS:	Sets up fixed size.  The way this works is, on the first
		pass, we'll convert any raw hints that are around.  On the
		second pass, we'll look for converted hints.  If we've got
		internal data already for the given hint, it was probably
		just converted from a raw hint on the first pass, and we'll
		store the converted data in the hint.  We can't store the
		converted data on the first pass because the hint chunk will
		tend to move around during the conversion process, so the
		hint data is no longer accessible.

CALLED BY:	SetupAnyDesiredSizes (via ObjVarScanData)

PASS:		*ds:si -- object
		desiredSize -- inherited local variable.

RETURN:		desiredSize -- args filled in

DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/30/91		Initial version

------------------------------------------------------------------------------@

InitialSize	proc	far
	desiredSize	local	SpecSizeArgs
	.enter	inherit
	call	ConvertSize
	mov	desiredSize.SSA_initWidth, cx	;keep in local vars
	mov	desiredSize.SSA_initHeight, dx
	mov	desiredSize.SSA_initNumChildren, ax
	.leave
	ret
InitialSize	endp
		
		
MinimumSize	proc	far
	class	VisCompClass
	desiredSize	local	SpecSizeArgs
	.enter	inherit
	call	ConvertSize
	mov	desiredSize.SSA_minWidth, cx	;keep in local vars
	mov	desiredSize.SSA_minHeight, dx
	mov	desiredSize.SSA_minNumChildren, ax
	.leave
	ret
MinimumSize	endp
		
		
MaximumSize	proc	far
	desiredSize	local	SpecSizeArgs
	.enter	inherit
	call	ConvertSize
	mov	desiredSize.SSA_maxWidth, cx	;keep in local vars
	mov	desiredSize.SSA_maxHeight, dx
	mov	desiredSize.SSA_maxNumChildren, ax
	.leave
	ret
MaximumSize	endp
		
		
FixedSize	proc	far
	desiredSize	local	SpecSizeArgs
	.enter	inherit
	call	ConvertSize
	mov	desiredSize.SSA_fixedWidth, cx	;keep in local vars
	mov	desiredSize.SSA_fixedHeight, dx
	mov	desiredSize.SSA_fixedNumChildren, ax
	.leave
	ret
FixedSize	endp
		
		

		


COMMENT @----------------------------------------------------------------------

ROUTINE:	ConvertSize

SYNOPSIS:	Takes a desired size hint entry, calculates the actual size,
		and redoes the hint data appropriately.

CALLED BY:	FixedSize, InitialSize, MinimumSize, MaximumSize

PASS:		*ds:si  -- our beloved object
		ds:bx   -- hint entry
		ax	-- converted hint name to change to

RETURN:		cx, dx  -- converted size args
		ax	-- number of children

DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/30/91		Initial version

------------------------------------------------------------------------------@

ConvertSize	proc	near		uses	bp
	class	VisClass
	.enter
	;
	; Clear the NO_SIZE_HINTS flag so hints will be checked from now on.
	;
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	and	ds:[di].VI_geoAttrs, not mask VGA_NO_SIZE_HINTS
	
	;
	; Load the variable number of arguments...
	;
	VarDataSizePtr	ds, bx, ax
EC <	tst	ax					;no args at all?  >
EC <	ERROR_E	UI_SIZE_HINT_MUST_HAVE_ARGUMENTS			  >
   
	mov	cx, ({CompSizeHintArgs} ds:[bx]).CSHA_width
	clr	bp					;assume no children
	clr	dx					;and no height
	cmp	ax, size SpecWidth
	je	10$					;branch if no height
	mov	dx, ({CompSizeHintArgs} ds:[bx]).CSHA_height
	cmp	ax, size GadgetSizeHintArgs
	je	10$					;branch if no children
	mov	bp, ({CompSizeHintArgs} ds:[bx]).CSHA_count
EC <	cmp	ax, size CompSizeHintArgs				>
EC <	ERROR_A	UI_SIZE_HINT_TOO_MANY_ARGUMENTS				>
10$:
	
EC <	push	cx, dx							>
EC <	tst	cx							>
EC <	jz	EC12							>
EC <	and	cx, mask SSS_TYPE					>
EC <	cmp	cx, SST_PCT_OF_FIELD_HEIGHT shl offset SSS_TYPE	>
EC <	ERROR_E	UI_SIZE_HINT_ILLEGAL_TYPE_FOR_WIDTH_ARGUMENT		>
EC <	cmp	cx, SST_LINES_OF_TEXT shl offset SSS_TYPE	>
EC <	ERROR_E	UI_SIZE_HINT_ILLEGAL_TYPE_FOR_WIDTH_ARGUMENT		>
EC <	cmp	cx, SST_COUNT shl offset SSS_TYPE			>
EC <	ERROR_E	UI_SIZE_HINT_ILLEGAL_TYPE_FOR_WIDTH_ARGUMENT		>
EC <EC12:								>
EC <	tst	dx							>
EC <	jz	EC14							>
EC <	and	dx, mask SSS_TYPE					>
EC <	cmp	dx, SST_PCT_OF_FIELD_WIDTH shl offset SSS_TYPE	>
EC <	ERROR_E	UI_SIZE_HINT_ILLEGAL_TYPE_FOR_HEIGHT_ARGUMENT		>
EC <	cmp	dx, SST_AVG_CHAR_WIDTHS shl offset SSS_TYPE	>
EC <	ERROR_E	UI_SIZE_HINT_ILLEGAL_TYPE_FOR_HEIGHT_ARGUMENT		>
EC <	cmp	dx, SST_WIDE_CHAR_WIDTHS shl offset SSS_TYPE	>
EC <	ERROR_E	UI_SIZE_HINT_ILLEGAL_TYPE_FOR_HEIGHT_ARGUMENT		>
EC <	cmp	dx, SST_COUNT shl offset SSS_TYPE			>
EC <	ERROR_E	UI_SIZE_HINT_ILLEGAL_TYPE_FOR_HEIGHT_ARGUMENT		>
EC <EC14:								>
EC <	test	bp, mask SSS_TYPE					>
EC <	ERROR_NZ UI_SIZE_HINT_COUNT_ARGUMENT_MUST_BE_A_PLAIN_NUMBER	>
EC <	cmp	bp, 255							>
EC <	ERROR_A	 UI_SIZE_HINT_CHILD_COUNT_TOO_LARGE			>
EC <	pop	cx, dx							>
   
	push	bp
	mov	ax, MSG_SPEC_CONVERT_DESIRED_SIZE_HINT
	call	ObjCallInstanceNoLock			;convert the size args
	pop	ax					;return children in ax
	.leave
	ret
ConvertSize	endp




COMMENT @----------------------------------------------------------------------

ROUTINE:	VisSpecCheckForPosHints

SYNOPSIS:	Checks for some position hints, such as:
			ATTR_GEN_POSITION
			ATTR_GEN_POSITION_X
			ATTR_GEN_POSITION_Y
			HINT_X_ALIGN_WITH_OBJECT
			HINT_Y_ALIGN_WITH_OBJECT

CALLED BY:	VisSpecBuild, VisSpecNotifyGeometryValid

PASS:		*ds:di -- object

RETURN:		carry set if any exist, with:
			cx, dx -- new position to use.

DESTROYED:	bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/ 4/92		Initial version

------------------------------------------------------------------------------@

VisSpecCheckForPosHints	proc	far
	class	VisClass

	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	mov	cx, ds:[di].VI_bounds.R_left	
	mov	dx, ds:[di].VI_bounds.R_top
	clr	bp				;assume no position hint

	mov	di, cs
	mov	es, di
	mov	di, offset cs:PosHints
	mov	ax, length (cs:PosHints)
	call	ObjVarScanData			;scan for raw hints

	rcl	bp, 1				;rotate flag into carry
	ret
VisSpecCheckForPosHints	endp


PosHints	VarDataHandler \
 <ATTR_GEN_POSITION, offset DoPosition>,
 <ATTR_GEN_POSITION_X, offset DoPositionX>,
 <ATTR_GEN_POSITION_Y, offset DoPositionY>,
 <HINT_ALIGN_LEFT_EDGE_WITH_OBJECT, offset DoLeftAlign>,
 <HINT_ALIGN_TOP_EDGE_WITH_OBJECT, offset DoTopAlign>,
 <HINT_ALIGN_RIGHT_EDGE_WITH_OBJECT, offset DoRightAlign>,
 <HINT_ALIGN_BOTTOM_EDGE_WITH_OBJECT, offset DoBottomAlign>




COMMENT @----------------------------------------------------------------------

ROUTINE:	VisSpecCheckForSpecPosHints

SYNOPSIS:	Checks for some spec position hints:
			ATTR_SPEC_POSITION
			ATTR_SPEC_POSITION_X
			ATTR_SPEC_POSITION_Y

CALLED BY:	VisSpecBuild, VisSpecNotifyGeometryValid

PASS:		*ds:di -- object

RETURN:		carry set if any exist, with:
			cx, dx -- new position to use.

DESTROYED:	bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/ 4/92		Initial version

------------------------------------------------------------------------------@




COMMENT @----------------------------------------------------------------------

ROUTINE:	DoPosition, DoPositionX, DoPositionY

SYNOPSIS:	ATTR_GEN_POSITION, ATTR_GEN_POSITION_X, ATTR_GEN_POSITION_Y handlers.

CALLED BY:	ObjVarScanData(PosHints)

PASS:		ds:bx -- pointer to var data arguments, if any
		bp -- position flag, between 0 and -5 (non-zero means there
			has been some vardata found already
		cx, dx -- current position for object

RETURN:		bp -- decremented
		cx, dx, -- position for object, possibly changed

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/ 4/92		Initial version

------------------------------------------------------------------------------@

DoPosition	proc	far
	mov	ax, ({Point} ds:[bx]).P_x		;new x position 
	mov	bx, ({Point} ds:[bx]).P_y		;new y positionn
	call	MakePositionAbsolute
	mov	cx, ax					;use both x and y
	mov	dx, bx
	dec	bp
	ret
DoPosition	endp

DoPositionX	proc	far
	mov	ax, {word} ds:[bx]			;new x position
	call	MakePositionAbsolute			;add parent pos
	mov	cx, ax					;use x position
	dec	bp
	ret
DoPositionX	endp

DoPositionY	proc	far
	mov	bx, {word} ds:[bx]			;use new y position
	call	MakePositionAbsolute			;add parent pos
	mov	dx, bx					;use it
	dec	bp
	ret
DoPositionY	endp




COMMENT @----------------------------------------------------------------------

ROUTINE:	MakePositionAbsolute

SYNOPSIS:	Adds in visual parent's position.

CALLED BY:	DoPositionX, DoPositionY

PASS:		ax, bx -- position relative to parent 

RETURN:		ax, bx -- absolute position

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/ 4/92		Initial version

------------------------------------------------------------------------------@

MakePositionAbsolute	proc	near		uses	cx, dx, bp
	.enter
	push	ax, bx				;parent is a window, do nothing!
	mov	ax, MSG_VIS_GET_TYPE_FLAGS	;   7/25/94 cbh
	call	VisCallParent
	test	cl, mask VTF_IS_WINDOW
	pop	ax, bx
	jnz	exit

	push	ax, bx
	mov	ax, MSG_VIS_GET_POSITION
	call	VisCallParent			;returns parent pos in cx, dx
	pop	ax, bx
	add	ax, cx
	add	bx, dx
exit:
	.leave
	ret
MakePositionAbsolute	endp




COMMENT @----------------------------------------------------------------------

ROUTINE:	DoLeftAlign, DoTopAlign

SYNOPSIS:	Handler for HINT_ALIGN_LEFT_EDGE_WITH_OBJECT,
			    HINT_ALIGN_TOP_EDGE_WITH_OBJECT

CALLED BY:	ObjVarScanData(PosHandler)

PASS:		ds:bx -- pointer to var data arguments, if any
		bp -- position flag, between 0 and -5 (non-zero means there
			has been some vardata found already
		cx, dx -- current position for object

RETURN:		bp -- decremented
		cx, dx, -- position for object, possibly changed

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/ 4/92		Initial version

------------------------------------------------------------------------------@

DoLeftAlign	proc	far
	call	GetOtherObjPos			;returns other pos in cx, dx
						;our position in ax, bx
						;bp decremented
	mov	dx, bx				;preserve object's y position
	ret
DoLeftAlign	endp

DoTopAlign	proc	far
	call	GetOtherObjPos			;returns other pos in cx, dx
						;our position in ax, bx
						;bp decremented
	mov	cx, ax				;preserve object's x position
	ret
DoTopAlign	endp

GetOtherObjPos	proc	near
	push	cx, dx, bp, si
	mov	si, ({optr} ds:[bx]).chunk	;object to align with
	mov	bx, ({optr} ds:[bx]).handle	
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_VIS_GET_POSITION
	call	ObjMessage			;returns position in cx, dx
	pop	ax, bx, bp, si			;our pos returned in ax, bx
	dec	bp				;set hint found
	ret
GetOtherObjPos	endp

COMMENT @----------------------------------------------------------------------

ROUTINE:	DoRightAlign, DoBottomAlign

SYNOPSIS:	Handler for HINT_ALIGN_RIGHT_EDGE_WITH_OBJECT,
			    HINT_ALIGN_BOTTOM_EDGE_WITH_OBJECT

CALLED BY:	ObjVarScanData(PosHandler)

PASS:		ds:bx -- pointer to var data arguments, if any
		bp -- position flag, between 0 and -5 (non-zero means there
			has been some vardata found already
		cx, dx -- current position for object

RETURN:		bp -- decremented
		cx, dx, -- position for object, possibly changed

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/ 4/92		Initial version

------------------------------------------------------------------------------@

DoRightAlign	proc	far
	call	GetOtherObjRightBottom		;will return other object's
						;  right edge minus our width,
						;and other object's bottom edge
						;  minus our height.
						;bp decremented
	mov	dx, bx				;preserve object's y position
	ret
DoRightAlign	endp

DoBottomAlign	proc	far
	call	GetOtherObjRightBottom		;will return other object's
						;  right edge minus our width,
						;and other object's bottom edge
						;  minus our height.
						;our position in ax, bx
						;bp decremented
	mov	cx, ax				;preserve object's x position
	ret
DoBottomAlign	endp

GetOtherObjRightBottom	proc	near
	push	cx, dx, bp
	push	si
	mov	si, ({optr} ds:[bx]).chunk	;object to align with
	mov	bx, ({optr} ds:[bx]).handle	

	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_VIS_GET_BOUNDS
	call	ObjMessage			;returns R/B in cx, dx
	mov	ax, cx
	mov	bx, dx
	pop	si
	;
	; Get our size and subtract from object's right/bottom edges.
	;
	call	VisGetSize
	sub	ax, cx
	sub	bx, dx

	mov	cx, ax				;return in cx, dx
	mov	dx, bx
	pop	ax, bx, bp			;our pos returned in ax, bx
	dec	bp				;set hint found
	ret
GetOtherObjRightBottom	endp

Build	ends

;
;---------------
;
		
Navigation	segment	resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	VisNavigateCommon

DESCRIPTION:	This is a utility routine used by  MSG_SPEC_NAVIGATION_QUERY
		handlers to implement the keyboard navigation
		within-a-window mechanism.  Queries an object to see if it
		is wants to answer the navigation query.  If it doesn't, it
		returns the next object to query.

CALLED BY:	VisSpecNavigate, and specific UI MSG_SPEC_NAVIGATION_QUERY handlers.

PASS:		*ds:si	= instance data for object
		cx:dx	= OD of object which originated the navigation message
		bp	= NavigateFlags
		bl	= NavigateCommonFlags
		di	= chunk handle of generic instance data for this
				object - must be in same block. This is
				used when scanning for a hint. Pass di=0
				if no generic part or don't want to check
				hints. Pass di=si if generic part MAY be
				present in this object.

RETURN:		ds, si	= same
		(ds - updated to point at segment of same block as on entry)
		cx:dx	= OD returned by final recipient of this message
		bp	= NavigationFlags returned by final recipient.
		al	= clear if can't take focus via backtracking, set
				if the object can
		carry set if found the next/previous object we were seeking

DESTROYED:	ax, bx, es, di
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

PSEUDO CODE/STRATEGY:
	see paper file.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/90		initial version
	Chris	12/ 9/91	Re-written to be non-recursive

------------------------------------------------------------------------------@

VisNavigateCommon	proc	far	;THIS LABEL USED BY SHOWCALLS IN SWAT.
	class	VisCompClass		; Indicate function is a friend
					; of VisCompClass so it can play with
					; composite instance data if desired
					
EC <	call	ECCheckNavigationFlags					>
	;
	; Return al set if we are interested in navigation, and we mean to
	; "backtrack" to the previous node when we get to our destination.
	; The last node that returns al set before we complete the circuit
	; will get the focus.  If the object is being skipped (except initially)
	; or is not focusable, we'll return al clear.
	;
	clr	al
	test	bp, mask NF_BACKTRACK_AFTER_TRAVELING
	jz	returnNotFocusable

	test	bp, mask NF_INITIATE_QUERY
	jnz	20$
	test	bp, mask NF_SKIP_NODE	;skipping the node and not initial?
	jnz	returnNotFocusable	;yes, can't be focusable
20$:
	call	VisTestNode		;see if focusable
	jnc	returnNotFocusable	;no, branch
	dec	al			;say focusable
returnNotFocusable:
	push	ax

	;first: if this object is to initiate the query, don't check if
	;have been at this object before.  Also if we're skipping the node
	;(and hence are coming up from one of the children), and we haven't
	;already reached the root node.
	
	test	bp, mask NF_REACHED_ROOT
	jnz	testForCompletedCircuit
	test	bp, mask NF_INITIATE_QUERY or mask NF_SKIP_NODE
	jnz	testFlags			

testForCompletedCircuit:
	;if this message originated from this object (recursion!), then
	;return with the NF_COMPLETED_CIRCUIT flag set.

	cmp	dx, si
	jnz	testFlags
	cmp	cx, ds:[LMBH_handle]
	jnz	testFlags

VNC_completedCircuit label near		;THIS LABEL USED BY SHOWCALLS IN SWAT.
	ForceRef	VNC_completedCircuit

	;if this node is NOT focusable, it means that it was attempting to
	;push the FOCUS off of itself. If this is the case, let's return
	;cx:dx = 0:0, so that the window will have NO focused object.

	test	bl, mask NCF_IS_FOCUSABLE
	jnz	10$			;skip if this node is focusable...
					;(i.e. navigation wrapped around)
	clr	cx
	clr	dx

10$:
	ORNF	bp, mask NF_COMPLETED_CIRCUIT
					;set flag indicating reached start
	jmp	returnCarrySet		;skip if so...

testFlags:

	;check some passed flags
	
	test	bl, mask NCF_IS_COMPOSITE  ;does this object have kids?
	jnz	isComposite		   ;skip if not...
	

	;For non-composites, send to next node if not focusable, else handle
	;as a leaf (i.e. give it the focus if appropriate)
	
	call	VisTestNode		;can we navigate to this node or
					;its children?
	jnc	forwardToNextNode	;skip if not...
	test	bp, mask NF_SKIP_NODE	;want to skip this node?
	jnz	forwardToNextNode	;not skipping, skip node
	jmp	short takeFocusIfNeeded	;else try to get focus

isComposite:			;THIS LABEL USED BY SHOWCALLS IN SWAT
	ForceRef	isComposite

	;For composites, if focusable, and skip-node is not set, we'll treat
	;ourselves as a leaf and try to get the focus.  If not focusable, 
	;we'll treat as a composite and send to our first child.  If skip-node
	;is set, we'll forward to the next node if not initiating the query.
	;If we've initiated the query, we'll assume we didn't totally want to
	;skip the node and will send to our first child.
	
	call	VisTestNode		;see if focusable
	jc	focusable		;yes, branch
	test	bp, mask NF_SKIP_NODE	;want to skip this node altogether?
	jz	VNC_sendToFirstChild	;no, send to children
	jmp	short forwardToNextNode	;else skip the node completely
	
focusable:
	test	bp, mask NF_SKIP_NODE	;want to skip this node?
	jz	takeFocusIfNeeded	;not skipping, handle as leaf node
	
	test	bp, mask NF_INITIATE_QUERY
	jz	forwardToNextNode	;didn't initiate, skip completely
					;else send to first child
					
VNC_sendToFirstChild label near	   ;THIS LABEL USED BY SHOWCALLS IN SWAT
	ForceRef	VNC_sendToFirstChild
	
	push	di
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	mov	cx, ds:[di].VCI_comp.CP_firstChild.handle
	mov	dx, ds:[di].VCI_comp.CP_firstChild.chunk
	pop	di
	jcxz	noChildren

	ANDNF	bp, not (mask NF_INITIATE_QUERY or mask NF_SKIP_NODE)
	clc
	jmp	short VNC_done		   ;have a child to return, exit

noChildren:

	;this composite has no children: if not focusable, forward query
	;to next sibling

	test	bl, mask NCF_IS_FOCUSABLE
	jz	forwardToNextNode	;skip to send to next node....

	;parent node is focusable: treat as a leaf node...

;bug fix here - brianc 2/17/92
;instead of falling through, and causing an infinite loop (if not
;NF_TRAVEL_CIRCUIT), we check NF_TRAVEL_CIRCUIT here and handle
			; NEW - if the starting object is a focusable
			; composite with no children, we move to next node,
			; do the same if we want to skip this node
	test	bp, mask NF_INITIATE_QUERY or mask NF_SKIP_NODE	; NEW
	jnz	short forwardToNextNode				; NEW
						; clear both for 'returnOD'
	ANDNF	bp, not (mask NF_INITIATE_QUERY or mask NF_SKIP_NODE)
	test	bp, mask NF_TRAVEL_CIRCUIT
	jz	returnOD
	jmp	short forwardToNextNode		; we know it is a composite,
						; and that it has no children,
						; so we can just do this
;end of fix

takeFocusIfNeeded:
	test	bp, mask NF_TRAVEL_CIRCUIT ;are we travelling the circuit?
	jz	returnOD		   ;skip if not to return this
					   ;objects OD...

	;Else continue query with first child or next node...
	
	test	bl, mask NCF_IS_COMPOSITE
	jnz	VNC_sendToFirstChild
	
forwardToNextNode:

	;if this is the root node, it means that either this query has
	;just begun (in a window where no object has the FOCUS exclusive yet)
	;or this query has travelled through the visible tree to the last
	;leaf, which sent the message up to its parent. We want to allow
	;wrap-around by sending this message to the first child of this node.

	ANDNF	bp, not (mask NF_INITIATE_QUERY or mask NF_SKIP_NODE)
	
	test	bl, mask NCF_IS_ROOT_NODE
	jz	sendToNextNode

VNC_reachedRoot label near		;THIS LABEL USED BY SHOWCALLS IN SWAT.
	ForceRef	VNC_reachedRoot
EC <	test	bp, mask NF_REACHED_ROOT				>
EC <	ERROR_NZ UI_NAVIGATION_QUERY_REACHED_ROOT_NODE_TWICE		>

	ORNF	bp, mask NF_REACHED_ROOT ;set flag which might be useful
	push	di
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	mov	cx, ds:[di].VCI_comp.CP_firstChild.handle
	mov	dx, ds:[di].VCI_comp.CP_firstChild.chunk
	pop	di
	clc
	jmp	short VNC_done		;whatever the child returns (CY=0
					;if there are no children)

sendToNextNode:
	;send this message on to the next node

	ANDNF	bp, not (mask NF_INITIATE_QUERY or mask NF_SKIP_NODE)
	push	bx
	call	VisNavGetNextNode	;will use visible tree of ID scheme
	pop	bx			;to find next node in circuit
	clc
	jmp	short VNC_done

returnOD: ;the query has reached its destination. Return our OD.
	mov	cx, ds:[LMBH_handle]
	mov	dx, si

EC <VNC_returnODCXDX label near	 ;THIS LABEL USED BY SHOWCALLS IN SWAT	>
EC <	ForceRef	VNC_returnODCXDX				>
EC <	nop			 ;must keep label distinct		>

returnCarrySet:
	stc
VNC_done label near			;THIS LABEL USED BY SHOWCALLS IN SWAT.
	pop	ax			;restore focusable flag
	ret
VisNavigateCommon	endp




COMMENT @----------------------------------------------------------------------

ROUTINE:	VisTestNode

SYNOPSIS:	Checks to see if an object is focusable.  Looks at flags
		passed in.

CALLED BY:	VisNavigateCommon

PASS:		bl -- NavigateCommonFlags for the object
		bp -- NavigateFlags passed in to VisNavigateCommon

RETURN:		carry set if node is focusable

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/10/91		Initial version

------------------------------------------------------------------------------@

VisTestNode	proc	near
	push	ax
	test	bl, mask NCF_IS_FOCUSABLE
					;if leaf object and not focusable,
	jz	returnCarry		;skip to send to next node....
					;(CARRY CLEAR)

	;make sure NCF_IS_MENU_RELATED = NF_NAV_MENU_BAR to examine node.

	mov	ax, bp			;get NavigateFlags (LOW BYTE ONLY)
	xor	al, bl			;xor the menu flags
	test	al, mask NCF_IS_MENU_RELATED
	jnz	returnCarry		;mismatch: skip to send to next node
					;(CARRY CLEAR)...

	stc				;return flag: OK to examine node

returnCarry:
	pop	ax
	ret
VisTestNode	endp

ECVisStartNavigation	proc	far	;for swat's showcalls
	ret
ECVisStartNavigation	endp

ECVisEndNavigation	proc	far	;for swat's showcalls
	ret
ECVisEndNavigation	endp

if ERROR_CHECK	;--------------------------------------------------------------

;error checking for VisNavigateCommon

ECCheckNavigationFlags	proc	near
	class	VisClass

	;make sure caller is passing valid info

	test	bl, not (mask NavigateCommonFlags)
	ERROR_NZ UI_BAD_NAVIGATE_COMMON_FLAGS

	;error checking for root node case

	test	bl, mask NCF_IS_ROOT_NODE
	jz	10$
	test	bl, mask NCF_IS_COMPOSITE
	ERROR_Z UI_NAVIGATION_QUERY_ROOT_NODE_MUST_BE_COMPOSITE

10$:	;error checking for composite node case

	;make sure that BP mode flags are cool

	test	bp, mask NF_BACKTRACK_AFTER_TRAVELING
	jz	30$
	test	bp, mask NF_TRAVEL_CIRCUIT
	ERROR_Z	UI_NAVIGATION_QUERY_MUST_TRAVEL_CIRCUIT_TO_BACKTRACK

30$:	;error checking for INITIATE query case: must have been sent to
	;a root node, or to a focused object in the window.

	test	bp, mask NF_COMPLETED_CIRCUIT
	ERROR_NZ UI_BAD_NAVIGATION_QUERY_FLAGS

	ret
ECCheckNavigationFlags	endp
endif		;--------------------------------------------------------------


COMMENT @----------------------------------------------------------------------

FUNCTION:	VisNavGetNextNode

DESCRIPTION:	This procedure forwards the MSG_SPEC_NAVIGATION_QUERY
		message to the next object in the circuit.

CALLED BY:	VisNavigateCommon

PASS:		*ds:si	= instance data for object
		cx:dx	= OD of node (object) which originated query
		bp	= NavigationFlags
		di	= chunk handle of generic instance data for this
				object - must be in same block. This is
				used when scanning for a hint. Pass di=0
				if no generic part or don't want to check
				hints.

RETURN:		cx:dx	= the next node to query
		bp	= NavigationFlags, possibly changed

DESTROYED:	ax, bx, di

PSEUDO CODE/STRATEGY:
	send this message on to the next node, using the visible tree,
	or an ID scheme using hints which allows jumping around the
	visible tree.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/90		initial version
	Chris	12/ 9/91	Changed to be non-recursive

------------------------------------------------------------------------------@

VisNavGetNextNode	proc	near
	class	VisClass

	;if we have a HINT_NAVIGATION_NEXT_ID hint, use it now.

	tst	di			;is there a generic part?
	jz	VNGNN_sendToSibling		;skip if not...

	call	VisNavTestForNextIDHint
	jnc	VNGNN_sendToSibling		;no hint, send to next sibling
	
VNGNN_sendViaHint label near		; USED BY SHOWCALLS -N
	ForceRef	VNGNN_sendViaHint
	jmp	short done
	
VNGNN_sendToSibling label near		;THIS LABEL USED BY SHOWCALLS IN SWAT.
	;must use visible tree. First try to send to next sibling

	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	mov	cx, ds:[di].VI_link.handle	
	mov	dx, ds:[di].VI_link.chunk
	test	dl, LP_IS_PARENT
	jz	done

VNGNN_sendToParent label near		 ;THIS LABEL USED BY SHOWCALLS IN SWAT.
	ForceRef	VNGNN_sendToParent

	;send to parent, indicating that we want the parent to send this
	;message on to its visible sibling (parent may also have an ID hint
	;allowing a jump from this group to another object in the tree.)

	and	dl, not LP_IS_PARENT
	ORNF	bp, mask NF_SKIP_NODE
done:
	ret
VisNavGetNextNode	endp

;see if this object has HINT_NAVIGATION_NEXT_ID

VisNavTestForNextIDHint	proc	near
	class	VisClass

	push	cx, dx, bp, si
	mov	si, di			;set *ds:si = object which has gen part

	push	ax
	mov	di, offset cs:VisNavigationHintNextIDTable
	mov	ax, length (cs:VisNavigationHintNextIDTable)
	call	DontLookNowVisClassScanningForGenHint
	pop	ax
	jnc	done			;skip if not...

	;send a VUP message to the window group which will initiate
	;a broadcast throughout the visible tree. Yes, will be slower than hooey.
	;Pass:	bp = ID to find (may have NAVIGATION_ID_START_OF_RANGE bit
	;set if looking for IDs in a range.)

	push	ax
	mov	bp, cx			;set bp = ID value
	;
	; This doesn't ever seem to be handled.  I'm removing the method
	; and letting it fatal error, until someone figures out what this was
	; supposed to do.  -cbh 8/14/91
	;
;	mov	ax, MSG_SPEC_START_BROADCAST_FOR_NAV_ID
;	call	VisCallParent
EC <	ERROR_NC UI_NAVIGATION_BROADCAST_FOR_ID_FAILED			>
	pop	ax

done:	;return carry set if found object using ID in hint.
	pop	cx, dx, bp, si
	ret
VisNavTestForNextIDHint	endp



;Yes, this is bad. VisClass handlers should not use generic instance data,
;but we can check the VTF_IS_GEN flag first...
;Pass:		*ds:si = instance data for generic object
;		ax     = # of handlers
;		cs:di  = VarDataHandler Table
;returns:	cx = word of data from hint
;		carry set if hint found

DontLookNowVisClassScanningForGenHint	proc	near
	class	VisClass

	;see if passed object has gen data

	mov	bp, ds:[si]
	add	bp, ds:[bp].Vis_offset
	test	ds:[bp].VI_typeFlags, mask VTF_IS_GEN
	jz	done			;skip (CY=0) if no generic part...

	segmov	es, cs			;setup es:di to be ptr to
					;Hint handler table
	clr	cx			;default: no hint
	call	ObjVarScanData		;has more error checking code
	test	cx, 0xffff		;was an ID returned?
	jz	done			;skip if not (CY=0)...
	stc				;return carry set: cx = data
done:
	ret
DontLookNowVisClassScanningForGenHint	endp

if 0
VisNavigationHintGetIDTable	VarDataHandler \
	< HINT_NAVIGATION_ID, offset Navigation:HintNavID >
endif

VisNavigationHintNextIDTable	VarDataHandler \
	< HINT_NAVIGATION_NEXT_ID, offset Navigation:HintNavID >

HintNavID	proc	far
	mov	cx, ds:[bx]		;cx = ID number
	ret
HintNavID	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	VisCheckMnemonic

SYNOPSIS:	Checks kbd char info to see if mnemonic matches.  Does some
		other basic checking, such as whether we have a generic
		object, whether it's enabled, etc.  It also ignores case
		distinctions.  This is used by the default
		VisClass handler for MSG_SPEC_ACTIVATE_OBJECT_WITH_MNEMONIC.  
		It doesn't check win-group parts of dually build objects -- 
		it assumes you only want to match the mnemonic in the 
		non-win-group part.  To do special mnemonic checking for your 
		object, you may want to to subclass MSG_SPEC_ACTIVATE_OBJECT_-
		WITH_MNEMONIC, and use this routine as needed.

CALLED BY:	UTILITY

PASS:		*ds:si -- object to check
		same as MSG_META_KBD_CHAR:
			cl - Character		(Chars or VChar)
			ch - CharacterSet	(CS_BSW or CS_CONTROL)
			dl - CharFlags
			dh - ShiftState		(left from conversion)
			bp low - ToggleState
			bp high - scan code

RETURN:		carry set if match

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/24/90		Initial version

------------------------------------------------------------------------------@

VisCheckMnemonic	method VisClass, MSG_SPEC_CHECK_MNEMONIC
	uses	bx, cx, di
	class	VisClass
	.enter
	mov	di, ds:[si]						
	add	di, ds:[di].Vis_offset					
	test	ds:[di].VI_typeFlags, mask VTF_IS_GEN			
	jz	noMatch				 ;not generic object, no match
   
   	; Enabled check should be done by caller.
	
;	clr	cx				; allow optimization
;	call	GenCheckIfFullyEnabled		 ;enabled?
;	jnc	noMatch				 ;no, nothing more to do
	
	mov	di, ds:[si]			 ;point to instance
	add	di, ds:[di].Gen_offset
	mov	di, ds:[di].GI_visMoniker	 ;point to vis moniker
	tst	di
	jz	noMatch			 	 ;no vis moniker, branch
	
	mov	di, ds:[di]			 ;dereference
	test	ds:[di].VM_type, mask VMT_GSTRING
	jnz	noMatch			 	;yes, nothing to match, branch
	
	mov	bl, ds:[di].VM_data.VMT_mnemonicOffset 
	cmp	bl, VMO_NO_MNEMONIC		 ;any mnemonic?
	je	noMatch				 ;no, go try children
	
	;
	; If cancel, we'll send it to the application object to see if it
	; matches the specific UI's notion of cancel.
	;
	cmp	bl, VMO_CANCEL			 ;standard cancel?
	jne	useCharFromMonikerString	 ;if not, out of non-offset
						 ;values, branch & look at
						 ;string.
	push	ax
	mov	ax, MSG_GEN_APPLICATION_TEST_FOR_CANCEL_MNEMONIC
	call	GenCallApplication
	pop	ax
	jmp	short exit			 ;exit with result

useCharFromMonikerString:
	cmp	bl, VMO_MNEMONIC_NOT_IN_MKR_TEXT
	jne	5$
	;
	; scan to end of moniker to get mnemonic char
	;
	add	di, VM_data + VMT_text		 ;ds:di = text moniker
	push	ax, cx, es
	segmov	es, ds				 ;es:di = text moniker
	mov	cx, -1
SBCS <	clr	al							>
DBCS <	clr	ax							>
SBCS <	repne scasb				 ;find byte after null-term >
DBCS <	repne scasw				 ;find char after null-term >
SBCS <	mov	bl, ds:[di]			 ;bl = mnemonic char	>
DBCS <	mov	bx, ds:[di]			 ;bx = mnemonic char	>
	pop	ax, cx, es
	jmp	short 7$

5$:
	clr	bh				 ;else make word offset
DBCS <	shl	bx, 1							>
SBCS <	mov	bl, ds:[di].VM_data.VMT_text[bx] ;get stored mnemonic	>
DBCS <	mov	bx, ds:[di].VM_data.VMT_text[bx] ;get stored mnemonic	>
7$:
   	;
	; If key pressed uppercase, make lowercase and compare to moniker char.
	;
	LocalCmpChar cx, 'A'			 ;see if uppercase
	jb	10$				 ;no, branch
	LocalCmpChar cx, 'Z'
	ja	10$
	sub	cl, 'A'-'a'			 ;force lowercase
10$:
	LocalCmpChar bx, 'A'			 ;see if uppercase
	jb	20$				 ;no, branch
	LocalCmpChar bx, 'Z'
	ja	20$
	sub	bl, 'A'-'a'			 ;force lowercase
20$:
SBCS <	cmp	cl, bl				 ;see if character matches >
DBCS <	cmp	cx, bx				 ;see if character matches >
	stc					 ;assume that it does
	je	exit				 ;yes, exit
noMatch:	
	clc					 ;exit no match
exit:
	.leave
	ret
VisCheckMnemonic	endm

Navigation	ends

;
;---------------
;
		
Build	segment	resource


COMMENT @----------------------------------------------------------------------

ROUTINE:	VisSpecBuildSetEnabledState

SYNOPSIS:	Sets the VA_FULLY_ENABLED flag based on the object's generic 
		enabled state and the SBF_VIS_PARENT_FULLY_ENABLED bit in the 
		SpecBuildFlags passed to your object's MSG_SPEC_BUILD handler. 
		MSG_SPEC_BUILD_BRANCH passes this flag along so your object
		can avoid checking GS_ENABLED flags all the way up the 
		generic tree.   Call this at the beginning of your
		object's MSG_SPEC_BUILD handler if you don't call your
		superclass.  (Passing SBF_VIS_PARENT_FULLY_ENABLED

CALLED BY:	FAR

PASS:		*ds:si -- object
		bp -- SpecBuildFlags

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/ 9/90		Initial version

------------------------------------------------------------------------------@

VisSpecBuildSetEnabledState	proc	far		uses	di, bx
	class	VisClass
	.enter
EC <	call	VisCheckVisAssumption		;assume vis built	>

	; First, set the fully enabled based on our parent's fully enabled
	; state (passed in with BuildFlags) and our enabled state.
	
	mov	di, ds:[si]						
	add	di, ds:[di].Vis_offset					
	and	ds:[di].VI_attrs, not mask VA_FULLY_ENABLED
	test	bp, mask SBF_VIS_PARENT_FULLY_ENABLED
	jz	10$			; Parent's not fully enabled, branch
	
	test	ds:[di].VI_typeFlags, mask VTF_IS_GEN
	jz	20$			; No gen part, will assume enablable
	
	mov	bx, ds:[si]		; point to instance
	add	bx, ds:[bx].Gen_offset	; ds:[di] -- GenInstance
	test	ds:[bx].GI_states, mask GS_ENABLED
	jz	10$			; This object's not enabled, branch
20$:
	or	ds:[di].VI_attrs, mask VA_FULLY_ENABLED
10$:
   	.leave
	ret
VisSpecBuildSetEnabledState	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	VisSendSpecBuild, VisSendSpecBuildBranch

SYNOPSIS:	Sends a MSG_SPEC_BUILD or MSG_SPEC_BUILD_BRANCH to an object,
		initializing the SBF_VIS_PARENT_FULLY_ENABLED bit
		based on the GS_ENABLED states of the object and all
		its generic ancestors.  This can be used by objects that need
		to send MSG_SPEC_BUILD's to other objects on the fly, not as a
		direct result of their own MSG_SPEC_BUILD handler.  (Usually in 
		a MSG_SPEC_BUILD handler you can take the SBF_VIS_PARENT_FULLY_-
		ENABLED bit passed in and figure out what to pass to the new 
		object without checking all the GS_ENABLED bits.)

CALLED BY:	global

PASS:		*ds:si  -- object
		bp	-- SpecBuildFlags, SBF_VIS_PARENT_FULLY_ENABLED will
		           be set correctly in this routine

RETURN:		ds - updated to point at segment of same block as on entry

DESTROYED:	ax, cx, dx, bp
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/ 9/90		Initial version

------------------------------------------------------------------------------@

VisSendSpecBuild	proc	far
	and	bp, not mask SBF_VIS_PARENT_FULLY_ENABLED
	mov	cx, -1			; no optimizations
	call	GenCheckIfFullyEnabled	; see if we're fully enabled
	jnc	10$			; no, branch
	or	bp, mask SBF_VIS_PARENT_FULLY_ENABLED
10$:
	mov	ax, MSG_SPEC_BUILD
	GOTO	ObjCallInstanceNoLock	; send the message
	
VisSendSpecBuild	endp
		
VisSendSpecBuildBranch	proc	far

	push	di
	mov	di, UI_STACK_SPACE_REQUIREMENT_FOR_RECURSE_ITERATION
	call	ThreadBorrowStackSpace
	push	di

	and	bp, not mask SBF_VIS_PARENT_FULLY_ENABLED
	mov	cx, -1			; no optimizations
	call	GenCheckIfFullyEnabled	; see if we're fully enabled
	jnc	10$			; no, branch
	or	bp, mask SBF_VIS_PARENT_FULLY_ENABLED
10$:
	mov	ax, MSG_SPEC_BUILD_BRANCH
	call	ObjCallInstanceNoLock	; send the message

	pop	di
	call	ThreadReturnStackSpace
	pop	di
	ret

VisSendSpecBuildBranch	endp


Build	ends
