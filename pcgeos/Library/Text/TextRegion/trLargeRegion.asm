COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		trLargeRegion.asm

AUTHOR:		John Wedgwood, Feb 12, 1992

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	 2/12/92	Initial revision

DESCRIPTION:
	Region create/nuke notification stuff.

	$Id: trLargeRegion.asm,v 1.1 97/04/07 11:21:41 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextRegion	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LargeRegionMakeNextRegion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Force the creation of another region.

CALLED BY:	TR_MakeNextRegion via CallRegionHandler
PASS:		*ds:si	= Instance
		cx	= Region number to append after
		dx	= Non-zero to skip to next region
RETURN:		cx	= Next region
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/12/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LargeRegionMakeNextRegion	proc	near
	uses	ax, bx, dx, bp, di
	.enter
tryAgain:
	call	PointAtRegionElement		;ds:di = data, z set if last
						;ax = element size
	jz	makeNext
	
	;
	; See if we want to go to the first region of the next section.
	;
	tst	dx
	jz	checkForNext			; Branch if we don't
	
	;
	; We want the first region in the next section
	;
	mov	bx, ds:[di].VLTRAE_section	; bx <- current section
nextSectionLoop:
	inc	cx				; cx <- next region number

	; make ds:di point at next region

	call	scanNextDIAX			; ds:di = next region
	cmp	bx, ds:[di].VLTRAE_section	; Check for same section
	je	nextSectionLoop			; Loop until we find it
	jmp	quit

checkForNext:
	;
	; The current region is not the last one, but it may be the last one
	; in this section... First we check to see if it is the last one
	; in the section.
	;
	mov	bx, ds:[di].VLTRAE_section	; bx <- section of this region
	call	scanNextDIAX			; ds:di = next region
	cmp	bx, ds:[di].VLTRAE_section	; Compare to current section
	jne	makeNext			; Branch if not in same section

	;
	; We want to make sure that the next region isn't marked as empty.
	;
	and	ds:[di].VLTRAE_flags, not mask VLTRF_EMPTY
	
	inc	cx				; cx <- next region number
quit:

if _REGION_LIMIT
	clc
exit:
endif		
	.leave
	ret

;---
scanNextDIAX:
	xchg	si, di
	xchg	dx, ax
	call	ScanToNextRegion
	xchg	si, di
	xchg	dx, ax
	retn

;---

makeNext:

if _REGION_LIMIT
	;
	; cx = the current last region (numbered from 0)
	; We want to know if we can append a region after this one and
	; not exceed the limit on the number of regions.
	;
	call	GetRegionLimit				; ax <- max # regions
	tst	ax					; is there a limit?
	jz	continue				; no, continue.
	dec	ax					; ax <- last region #
	cmp	cx, ax					; cx < ax ?
	jb	continue				; yes, we can append
	stc						; no, we're at limit
	jmp	exit		

continue:	

endif
		
	; Add a flag telling ourselves that we've appended regions and
	; must send the IS_LAST message

	push	cx
	clr	cx
	mov	ax, TEMP_VIS_TEXT_FORCE_SEND_IS_LAST_REGION
	call	ObjVarAddData
	pop	cx

	push	di
	mov	di, 1000
	call	ThreadBorrowStackSpace
	push	di

        ProfilePoint 80
	push	cx, dx
	mov	ax, MSG_VIS_LARGE_TEXT_APPEND_REGION
	call	ObjCallInstanceNoLock
	pop	cx, dx
        ProfilePoint 81

	pop	di
	call	ThreadReturnStackSpace
	pop	di

if _REGION_LIMIT
	jc	exit
endif		
	jmp	tryAgain

LargeRegionMakeNextRegion	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetRegionLimit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the maximum number of regions

CALLED BY:	LargeRegionMakeNextRegion
PASS:		nothing
RETURN:		ax - max # regions, or 0 for no limit
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	4/22/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if _REGION_LIMIT

GetRegionLimit		proc	near
		uses	cx, es
		.enter

		segmov	es, dgroup, ax
		mov	ax, es:regionLimit
		
		cmp	ax, -1
		je	initialize
done:		
		.leave
		ret
initialize:
		call	TR_GetTextLimits	; ax <- region limit
		jmp	done
GetRegionLimit		endp

endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TR_GetTextLimits
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the maximum number of chars and regions allowed
		for the text object.

CALLED BY:	
PASS:		nothing
RETURN:		cx - character limit
		ax - region limit
DESTROYED:	ax, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	0xffff can't be used for a char limit or region limit, because
	that value is used to signify that the limit variables haven't
	been initializd. If 0xffff is read from the ini file, it will
	be changed to 0xfffe.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	4/21/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if _REGION_LIMIT or _CHAR_LIMIT

textcatString	char	"text",0

if _CHAR_LIMIT
charlimitKey	char	"charLimit",0
endif

if _REGION_LIMIT
regionlimitKey	char	"regionLimit",0
endif

TR_GetTextLimits	proc	far
	uses	ds,si,dx
	.enter

	segmov	es, dgroup, ax

	segmov	ds, cs, cx		
	mov	si, offset textcatString	;DS:SI <- category string

if _CHAR_LIMIT
	mov	es:charLimit, 0
	mov	dx, offset charlimitKey		;CX:DX <- key string
	call	InitFileReadInteger
	jc	noCharLimit
	cmp	ax, 0xffff
	jne	$10
	dec	ax
$10:
	mov	es:charLimit, ax

noCharLimit:
endif
		
if _REGION_LIMIT
	mov	es:regionLimit, 0
	mov	dx, offset regionlimitKey	;CX:DX <- key string
	call	InitFileReadInteger
	jc	noRegionLimit
	cmp	ax, 0xffff
	jne	$20
	dec	ax
$20:
	mov	es:regionLimit, ax

noRegionLimit:		
endif

	mov	cx, es:charLimit
	.leave
	ret
TR_GetTextLimits	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LargeRegionRegionIsLast
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify someone that the current region is the last one
		containing any data.

CALLED BY:	TR_RegionIsLast via CallRegionHandler
PASS:		*ds:si	= Instance
		cx	= Region number which is empty
RETURN:		bx.dx.ax= Sum of calc'd heights for nuked regions
		cx	= Number of non-empty regions deleted
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/12/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LargeRegionRegionIsLast	proc	far
	uses	bp, di, si
heightSum	local	DWFixed
lineSum		local	dword
charSum		local	dword
section		local	word
lastRegNum	local	word
nukedRegCount	local	word
elementSize	local	word
	ProfilePoint 28
	.enter
	;
	; Initialize some stuff
	;
	clr	bx			; bx <- current region
	clrdw	heightSum.DWF_int, bx
	clr	heightSum.DWF_frac
	
	clrdw	lineSum, bx
	clrdw	charSum, bx
	
	clr	nukedRegCount, bx

	; Check for the flag that tells us to always send the message

	push	bx
	mov	ax, TEMP_VIS_TEXT_FORCE_SEND_IS_LAST_REGION
	call	ObjVarFindData
	pop	bx
	jnc	noFlag
	call	ObjVarDeleteData
	jmp	forceUpdate
noFlag:

	call	TR_RegionIsLastInSection
	LONG jc quit			; Branch if already is last region
forceUpdate:

	;
	; Quick check to see if this is already the last region.
	;
	call	PointAtRegionElement	; ds:di <- data, ax <- size
	mov	elementSize, ax
	mov	lastRegNum, cx		; Save ptr to this region

	push	cx			; Save "last" region
	mov	ax, cx			; ax <- "last" region
	mov	dx, ds:[di].VLTRAE_section ; dx <- section of "last" region

	;
	; Now run through all the regions marking them as containing data
	; if they fall before or at this one and marking them as empty if they
	; fall after this one.
	;
	push	si, ax			; Save instance ptr, last region
	mov	ax, ds:[di].VLTRAE_section ; Save section of "last" region
	mov	section, ax

	;
	; lshields 04/19/00 
	; Find the first region with the same section
	; (or one before it).  It is usually faster to go backwards
	; through the list then to start at the beginning and walk
	; down.
	;
	tst	cx
	jz	backupDone
	mov	dx, ax
backupLoop:
	;
	; Compare region's section with this previous one
	; if the same, keep going back.
	; (unless we hit 0)
	;
	dec	cx
	call	PointAtRegionElement
	mov	elementSize, ax
	cmp	ds:[di].VLTRAE_section, dx
	jnz	backupDone
	inc	cx
	loop	backupLoop
backupDone:
	; cx = current region
	mov_tr	bx, cx
	call	VisLargeTextGetRegionCount	;cx = count
	sub	cx, bx
	; cx = number remaining regions.
	; bx = current region
	mov	dx, elementSize
	mov	ax, section

EC <	ERROR_C VIS_TEXT_LARGE_OBJECT_MUST_HAVE_REGION_ARRAY		>
	pop	si, ax			; Restore instance ptr, last region
regionLoop:
	;
	; *ds:si= Instance
	; ds:di	= Current region
	; dx	= Size of region data
	; cx	= Number left to process
	; bx	= Current region
	; ax	= Region number before which we mark regions as having data
	;	  and after which we mark as empty.
	;
	; Since this can only happen if recalculation occurs we can be
	; assured that the text object is dirty so we don't need to dirty it
	; ourselves.
	;
	; Check for out of our section.
	;
	push	ax
	mov	ax, section
	cmp	ds:[di].VLTRAE_section, ax
	pop	ax
	ja	quitNotifyChange	; Branch if out of our region
;vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
; Added this line  4/15/93 -jw
; This code is just plain wrong without this line. What it is doing is
;	foreach region
;	    if region is before current last region
;		mark region as not empty
;
; This is correct, assuming the whole document is the same section. If we have
; multiple sections, this is wrong wrong wrong... We carefully checked one
; case in the old code and quit before we started affecting bits in later
; sections, but didn't handle the same situation for previous sections.
;
; We only want to perform this operation in our own section.
;
	jb	next			; Branch if before our region
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

	cmp	bx, ax			; Check which part of list we're in
	ja	markEmpty		; Branch if beyond last entry

	;
	; The region falls before or at the first empty one
	;
	and	ds:[di].VLTRAE_flags, not mask VLTRF_EMPTY

	cmp	bx, ax			; Check for on the last entry
	jne	next

	mov	lastRegNum, bx

	jmp	next

markEmpty:
	;
	; The region falls at or after the first empty one.
	; If the region is making a transition from not-empty ==> empty then
	; we need to clear the region out.
	;
	test	ds:[di].VLTRAE_flags, mask VLTRF_EMPTY
	jnz	quitNotifyChange	; Quit if already empty
	
	;
	; The region used to have data and is now empty. Clear it out.
	;
	inc	nukedRegCount		; One more nuked non-empty region

	mov	ds:[di].VLTRAE_flags, mask VLTRF_EMPTY

	push	ax, dx
	movwbf	dxah, ds:[di].VLTRAE_calcHeight
	clr	al			; dx.ax <- calc'd height
	
	add	heightSum.DWF_frac, ax	; Update total change
	adc	heightSum.DWF_int.low, dx
	adc	heightSum.DWF_int.high, 0
	
	movdw	dxax, ds:[di].VLTRAE_lineCount
	adddw	lineSum, dxax

	movdw	dxax, ds:[di].VLTRAE_charCount
	adddw	charSum, dxax

	clrwbf	ds:[di].VLTRAE_calcHeight
	clrdw	ds:[di].VLTRAE_lineCount
	clrdw	ds:[di].VLTRAE_charCount

	call	ClearRegion
	
	pop	ax, dx

next:
	inc	bx			; Move to next region
	dec	cx
	jz	quitNotifyChange
	xchg	si, di
	call	ScanToNextRegion
	xchg	si, di
	jmp	regionLoop		; Loop to process it

quitNotifyChange:
		;
	; Ripple the line/character counts backwards from the newly empty
	; regions to the new last region.
	;
	push	ax
	mov	cx, lastRegNum
	call	PointAtRegionElement
	pop	ax
	call	ResetCachedLineIfLower

	pop	cx			; Restore "last" region
	
	adddw	ds:[di].VLTRAE_lineCount, lineSum, ax
	adddw	ds:[di].VLTRAE_charCount, charSum, ax

	;
	; Notify whoever might be managing the regions that this one
	; is the last one in the section. We need to do this after the
	; marking so that we don't nuke a region before we add it's calc'd
	; height to the total.
	;

	push	di
	mov	di, 1000
	call	ThreadBorrowStackSpace
	push	di

	push	bp			; Save frame ptr
	mov	ax, MSG_VIS_LARGE_TEXT_REGION_IS_LAST
	call	ObjCallInstanceNoLock
	pop	bp			; Restore frame ptr

	pop	di
	call	ThreadReturnStackSpace
	pop	di

	call	RecalcTotalSize
	call	SendLargeHeightNotify	
	
quit:
	movdwf	bxdxax, heightSum	; bx.dx.ax <- sum of calc'd heights
	mov	cx, nukedRegCount	; cx <- # of non-empty nuked regions
	.leave
	ret
LargeRegionRegionIsLast	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClearRegion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear an entire region.

CALLED BY:	LargeRegionRegionIsLast
PASS:		*ds:si	= Instance ptr
		ds:di	= Region
		bx	= Current region
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/ 4/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClearRegion	proc	near
	class	VisTextClass
	uses	ax, bx, cx, dx, di
	ProfilePoint 31
	.enter

	;
	; Save and restore the gstate if the region we want to draw in is
	; different than the current gstate-region.
	;
	call	TextRegion_DerefVis_DI	; ds:di <- instance
	mov	ax, ds:[di].VTI_gstateRegion
	mov	di, ds:[di].VTI_gstate	; di <- gstate

	cmp	bx, ax
	pushf				; Save "same region" flag
	je	afterSave
	call	GrSaveState
afterSave:

	;
	; Transform the gstate.
	;
	clr	dl			; No DrawFlags
	mov	cx, bx			; cx <- region
	call	LargeRegionTransformGState

	push	di			; Save gstate handle
	call	LargeRegionClearToBottom	
	pop	di			; Restore gstate handle

	;
	; Restore the gstate
	;
	popf				; Restore "same region" flag
	je	afterRestore
	call	GrRestoreState
afterRestore:
	
	.leave
	ProfilePoint 30
	ret
ClearRegion	endp

TextRegion	ends
