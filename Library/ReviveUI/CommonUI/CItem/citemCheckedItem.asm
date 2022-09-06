COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonUI/COpen (common code for specific UIs)
FILE:		copenCheckedItem.asm

METHODS:
 Name			Description
 ----			-----------
 OLCheckedItemDraw		Draws the CheckedItem on the screen
 OLCheckedItemRerecalcSize	Calculates the width and height of the child
 OLCheckedItemGetExtraSize Returns the non-moniker size of the CheckedItem.
 OLCheckedItemMkrPos	Returns position of the moniker.	
 OLCheckedItemLostGadgetExcl Handler for method.

ROUTINES:
 Name			Description
 ----			-----------
 GetCheckedItemBounds	Returns the coordinates of the CheckedItem itself
 DrawBWCheckedItem		Draws the CheckedItem in B & W.
 BWCheckedItemBackground	Erases the CheckedItem in a background color
 DrawColorCheckedItem	Draws the CheckedItem in color


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Clayton	8/89		Initial version
	Eric	4/90		New USER/ACTUAL exclusives, drawing
					state separation work.

DESCRIPTION:
	$Id: citemCheckedItem.asm,v 1.13 95/11/29 19:16:08 cthomas Exp $

-------------------------------------------------------------------------------@


CommonUIClassStructures segment resource

	OLCheckedItemClass		mask CLASSF_DISCARD_ON_SAVE or \
				mask CLASSF_NEVER_SAVED

CommonUIClassStructures ends


;-----------------------

Build	segment	resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLItemInitialize -- MSG_META_INITIALIZE for OLItemClass

DESCRIPTION:	Initialize an item object.

PASS:		*ds:si - instance data
		ax - MSG_META_INITIALIZE

RETURN:		ds, si, bx, di, es = same

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	4/90		Initial version

------------------------------------------------------------------------------@

OLCheckedItemInitialize	method private static	OLCheckedItemClass, \
							MSG_META_INITIALIZE
	uses	bx, di, es		; To comply w/static call requirements
	.enter				; that bx, si, di, & es are preserved.
					; NOTE that es is NOT segment of class

	;call superclass to set default attributes

	mov	di, segment OLCheckedItemClass
	mov	es, di
	mov	di, offset OLCheckedItemClass
	CallSuper	MSG_META_INITIALIZE

	;set a flag which allows the OLItemClass MSG_VIS_DRAW handler
	;to draw object correctly.

	call	Build_DerefVisSpecDI
	ORNF	ds:[di].OLII_state, mask OLIS_IS_CHECKBOX

if _RUDY
	; turn off centering optimization -- almost certainly we're going
	; to be centering by monikers in a properties box.

	ANDNF	ds:[di].VI_geoAttrs, not mask VGA_USE_VIS_CENTER
endif
	.leave
	ret
OLCheckedItemInitialize	endp

Build	ends

;-------------------------

ItemGeometry segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLCheckedItemRerecalcSize -- MSG_VIS_RECALC_SIZE for OLCheckedItemClass

DESCRIPTION:	Returns the size of the CheckedItem.

PASS:
	*ds:si - instance data
	es - segment of OLCheckedItemClass
	di - MSG_VIS_GET_SIZE
	cx - width info for choosing size
	dx - height info

RETURN:
	cx - width to use
	dx - height to use

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/15/89		Initial version

------------------------------------------------------------------------------@



OLCheckedItemRerecalcSize	method	OLCheckedItemClass, MSG_VIS_RECALC_SIZE
	test	ds:[di].OLBI_moreAttrs, mask OLBMA_IN_TOOLBOX
	jz	CheckedItem			;not a toolbox, do normal
	mov	di, offset OLCheckedItemClass	;else handle as regular item
	GOTO	ObjCallSuperNoLock
			
CheckedItem:
if _CUA_STYLE	;---------------------------------------------------------------

	mov	di, offset OLCheckedItemClass
	CallSuper	MSG_VIS_RECALC_SIZE
	mov	ax, CHECK_BOX_WIDTH			;use as minimum width
							;use as minimum height
	mov	bx, CHECK_HEIGHT + CHECK_TOP_BORDER + CHECK_BOTTOM_BORDER
	clr	bp			;do not optionally expand items
					;and desired is minimum

	;
	; In menu, leave room in the minimum height for an outline. -cbh 1/30/93
	;
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLBI_specState, mask OLBSS_IN_MENU
	jz	10$
	add	bx, 2
10$:

if _RUDY
	;
	; Rudy, if we're centering by monikers, use the left-of-moniker value
	; in our parent to determine our size.   Otherwise we use the width
	; of the moniker.  Then we add the yes/no space.
	;
	call	GetParentMonikerSpace		
	tst	ax				
	jz	20$
	mov	cx, ax
20$:
	push	ax
	call	RudyGetCheckedItemYesNoSpace	; ax <- yes/no width
	add	cx, ax
	pop	ax
endif
	call	VisHandleMinResize
	ret

endif		;---------------------------------------------------------------

if _OL_STYLE	;---------------------------------------------------------------
	segmov	es,ds
EC <	call	GenCheckGenAssumption	; Make sure gen data exists 	>
	mov	di, ds:[si]			; ptr to instance data
	add	di,ds:[di].Gen_offset		; ds:di = GenInstance
	mov	di,ds:[di].GI_visMoniker	; fetch moniker
	push	cx
	push	dx
	clr	bp			;get have no GState...
	call	SpecGetMonikerSize	;get size of moniker
					; Compensate for the CheckedItem
	add	cx, CHECK_WIDTH_REAL+CHECK_LEFT_BORDER+ \
			CHECK_REAL_RIGHT_BORDER + CHECK_BOX_OFFSET
	mov	ax,cx			;use as minimum width
	mov	bx,dx			;use as minimum height

	cmp	ax, CHECK_WIDTH
	jae	10$
	mov	ax, CHECK_WIDTH
10$:
	cmp	bx, CHECK_HEIGHT+2
	jae	20$
	mov	bx, CHECK_HEIGHT+2	
20$:

	pop	dx
	pop	cx

	; if the CheckedItem has a mark in it add size for the mark

	clr	bp			;do not optionally expand CheckedItems
	call	VisHandleMinResize
	ret
endif		;---------------------------------------------------------------
       
OLCheckedItemRerecalcSize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RudyGetCheckedItemYesNoSpace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the amount of space needed to render
		the "off"/"on" strings of a Rudy checked item.

CALLED BY:	OLCheckedItemRerecalcSize
PASS:		nothing
RETURN:		ax = horizontal space (in pixels)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	11/29/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _RUDY

RUDY_CHECKED_ITEM_BASIC_YES_NO_SPACE	equ	RUDY_RIGHT_MARK_WIDTH + \
						MO_CONTROL_MKR_X_SPACING + 3

RudyGetCheckedItemYesNoSpace	proc	near
	uses	bx,ds,cx,dx,si,di
	.enter

	mov	bx, handle dgroup					
	call	MemDerefDS						

	;
	; If we've calculated this before, just return the value
	;

	mov	ax, ds:[checkboxWidth]
	tst	ax
	jnz	done

	;
	; Figure out how long the monikers are going to be
	;

	push	ds				; +1 dgroup

	mov	bx, handle StandardMonikers
	call	MemLock				; moniker resource -> ax
	mov	ds, ax

	;
	; Set up a GState to calculate width in
	;

	clr	di
	call	GrCreateState			; di <- state

	;
	; Get sizes of off/on monikers, and choose the largest
	;

	mov	si, offset StandardOnMoniker
	call	figureWidth			; dx <- width
	mov	bx, dx
	mov	si, offset StandardOffMoniker
	call	figureWidth
	cmp	dx, bx
	jae	haveSize
	mov_tr	dx, bx
haveSize:
	call	GrDestroyState

	add	dx, RUDY_CHECKED_ITEM_BASIC_YES_NO_SPACE

	mov	bx, ds:[LMBH_handle]
	call	MemUnlock

	;
	; Cache the max-width for future generations
	;
	pop	ds				; -1 dgroup
	mov	ds:[checkboxWidth], dx
	mov	ax, dx
done:
	.leave
	ret


figureWidth		label	near		; *ds:si = moniker to figure
						; di = GState
	mov	si, ds:[si]

	mov	dx, ds:[si].VM_width		; assume GString, with
	test	ds:[si].VM_type, mask VMT_GSTRING ; a cached width
	jnz	figuredWidth

	add	si, offset VM_data + offset VMT_text
	clr	cx
	call	GrTextWidth			; dx <- points

figuredWidth:
	ret					; dx = width
						; si, cx destroyed

RudyGetCheckedItemYesNoSpace	endp

endif
			

COMMENT @----------------------------------------------------------------------

METHOD:		OLCheckedItemGetExtraSize -- 
		MSG_SPEC_GET_EXTRA_SIZE for OLCheckedItemClass

DESCRIPTION:	Returns the non-moniker size of the CheckedItem.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_GET_EXTRA_SIZE

RETURN:		cx, dx  - extra size

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	11/ 7/89	Initial version

------------------------------------------------------------------------------@

OLCheckedItemGetExtraSize	method	OLCheckedItemClass, MSG_SPEC_GET_EXTRA_SIZE
	test	ds:[di].OLBI_moreAttrs, mask OLBMA_IN_TOOLBOX
	jz	CheckedItem			;not a toolbox, do normal
	mov	di, offset OLCheckedItemClass	;else handle as regular item
	GOTO	ObjCallSuperNoLock
			
CheckedItem:
OLS <	mov	cx, CHECK_WIDTH_REAL+CHECK_RIGHT_BORDER			>
OLS <	mov	dx, 18-12			;BUTTON_MIN_HEIGHT-2	>

CUAS <	mov	cx, MO_BUTTON_INSET_X*2					>
CUAS <	cmp	dx, 18-12			;BUTTON_MIN_HEIGHT-2	>

	ret
OLCheckedItemGetExtraSize	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLCheckedItemMkrPos -- 
		MSG_GET_FIRST_MKR_POS for OLCheckedItemClass

DESCRIPTION:	Returns position of the moniker.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GET_FIRST_MKR_POS

RETURN:		carry set if handled, with:
			ax, cx  - position of moniker

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	11/ 1/89		Initial version

------------------------------------------------------------------------------@

OLCheckedItemMkrPos	method	OLCheckedItemClass, MSG_GET_FIRST_MKR_POS
	test	ds:[di].OLBI_moreAttrs, mask OLBMA_IN_TOOLBOX
	jz	CheckedItem			;not a toolbox, do normal
	mov	di, offset OLCheckedItemClass	;else handle as regular item
	GOTO	ObjCallSuperNoLock
			
CheckedItem:
	mov	di, ds:[si]			; ptr to instance data
	add	di,ds:[di].Gen_offset		; ds:di = GenInstance
	mov	bx,ds:[di].GI_visMoniker	; fetch moniker
	tst	bx				; no moniker, message not
	jz	exit				;   handled, exit (C=0)

	segmov	es, ds
	sub	sp, size DrawMonikerArgs
	mov	bp, sp
	mov	cl, (J_LEFT shl offset DMF_X_JUST) or \
		    (J_CENTER shl offset DMF_Y_JUST)
OLS <	clr	dx	; dh=yoffset, dl=xoffset	>
CUAS <					; dh=yoffset, dl=xoffset	      >
CUAS <	mov	dx, CHECK_WIDTH_REAL + CHECK_LEFT_BORDER + CHECK_RIGHT_BORDER >
        clr	ss:[bp].DMA_yInset		; y inset
	mov	ss:[bp].DMA_xInset, dx
	clr	ss:[bp].DMA_gState
	call	SpecGetMonikerPos		; return position of moniker

if _MOTIF or _PM
	;
	; It appears that the x offset is bogus at this point (or, rather, not
	; really representing reality for some reason :), so let's stuff
	; the correct thing in for these purposes.  -cbh 11/16/92
	;

	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLBI_specState, mask OLBSS_IN_MENU
	jnz	20$
	mov	ax, ds:[di].VI_bounds.R_left	;get left edge
	add	ax, CHECK_BOX_WIDTH		;<256.  I guarantee it.
	test	ds:[di].OLII_state, mask OLIS_DRAW_AS_TOOLBOX
	jz	20$
	add	ax, TOOLBOX_INSET_X		;only a byte, anyway.
20$:
endif

	add	sp, size DrawMonikerArgs
	mov	cx, bx				; return y pos in cx
	stc					; return carry set
exit:
	ret
OLCheckedItemMkrPos	endp

ItemGeometry	ends

;-----------------------

ItemCommon segment resource



COMMENT @----------------------------------------------------------------------

FUNCTION:	OLCheckedItemLostGadgetExclusive -- MSG_VIS_LOST_GADGET_EXCL handler

DESCRIPTION:	This method is received when some other object has grabbed
		the GADGET exclusive for this level in the visual tree.

PASS:		*ds:si 	- instance data
		es     	- segment of OLCheckedItemClass
		ax 	- method number

RETURN:		Nothing

DESTROYED:	di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Clayton	6/89		Initial version

------------------------------------------------------------------------------@

OLCheckedItemLostGadgetExcl	method dynamic OLCheckedItemClass, \
							MSG_VIS_LOST_GADGET_EXCL
	test	ds:[di].OLBI_moreAttrs, mask OLBMA_IN_TOOLBOX
	jz	CheckedItem			;not a toolbox, do normal
	mov	di, offset OLCheckedItemClass	;else handle as regular item
	GOTO	ObjCallSuperNoLock
			
CheckedItem:
	;may already be reset. Save bytes: go ahead and reset and redraw
	;if necessary. Motif: reset BORDERED in case is in menu.

OLS<	ANDNF	ds:[di].OLBI_specState, not (mask OLBSS_DEPRESSED)	>
NOT_MO<	ANDNF	ds:[di].OLBI_specState, not (mask OLBSS_DEPRESSED)	>
MO <	ANDNF	ds:[di].OLBI_specState, not (mask OLBSS_DEPRESSED or \
					     mask OLBSS_BORDERED)	>
PMAN <	ANDNF	ds:[di].OLBI_specState, not (mask OLBSS_DEPRESSED or \
					     mask OLBSS_BORDERED)	>
	call	OLButtonDrawNOWIfNewState ;Redraw immediately if necessary

	call	VisReleaseMouse		; Release mouse, if we haven't done so
					;	already.
	ret
OLCheckedItemLostGadgetExcl	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLCheckedItemVisGetCenter -- 
		MSG_VIS_GET_CENTER for OLCheckedItemClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Returns the center of the object.

PASS:		*ds:si 	- instance data
		es     	- segment of OLCheckedItemClass
		ax 	- MSG_VIS_GET_CENTER

RETURN:		cx -- minimum space needed to the left of center
		dx -- minimum space needed to the right of center
		ax -- minimum space needed above center
		bp -- minimum space needed below center

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	1/ 9/95         Initial Version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _RUDY

OLCheckedItemVisGetCenter	method dynamic	OLCheckedItemClass, \
				MSG_VIS_GET_CENTER
	.enter

	;
	; First, assume normal
	;
	mov	di, offset OLCheckedItemClass
	call	ObjCallSuperNoLock

	;
	; Now, if we're center-by-monikers, use that the parent's left-
	; of-center as our left-of-center.
	;
	call	GetParentMonikerSpace		
	tst	ax				
	jz	exit				;not centering, done

	mov	cx, ax				;use this as left-of-center
exit:
	.leave
	ret
OLCheckedItemVisGetCenter	endm

endif





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLCheckedItemGetLargestCenter -- 
		MSG_SPEC_CTRL_GET_LARGEST_CENTER for OLCheckedItemClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Gets the largest left-of-center.   We subclass this
		to ensure that items have a say in the width of
		a properties box.

PASS:		*ds:si 	- instance data
		es     	- segment of OLCheckedItemClass
		ax 	- MSG_SPEC_CTRL_GET_LARGEST_CENTER
		cx	- largest moniker found so far
		bp	- set if any child with valid geometry found

RETURN:		cx, bp	- possibly updated
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	7/ 3/95         Initial Version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _RUDY

OLCheckedItemGetLargestCenter	method dynamic	OLCheckedItemClass, \
				MSG_SPEC_CTRL_GET_LARGEST_CENTER
	.enter

	;	
	; Update valid-geometry flag as appropriate.
	;
	tst	bp
	jnz	10$
	test	ds:[di].VI_optFlags, mask VOF_GEOMETRY_INVALID
	jnz	10$
	dec	bp
10$:

	push	cx, bp
	sub	sp, size OpenMonikerArgs
	mov	bp, sp				;set up args on stack
	call	OLItemSetupMkrArgs		;set up arguments for moniker
	call	OpenGetMonikerSize		;get size of moniker
EC <	call	ECVerifyOpenMonikerArgs		;make structure still ok >

	add	cx, CHECK_MAGIC_EXTRA_SPACE + CHECK_LEFT_BORDER + \
					      CHECK_RIGHT_BORDER

	add	sp, size OpenMonikerArgs	;dump args
	pop	ax, bp

	cmp	cx, ax				;return largest in ax
	ja	exit
	mov	cx, ax
exit:
	.leave
	ret
OLCheckedItemGetLargestCenter	endm

endif


ItemCommon ends
