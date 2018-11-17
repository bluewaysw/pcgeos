COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonUI/COpen (common code for specific UIs)
FILE:		copenSlider.asm

METHODS:
 Name			Description
 ----			-----------

ROUTINES:
 Name			Description
 ----			-----------


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/92		Initial revision

DESCRIPTION:
	$Id: copenSlider.asm,v 1.2 98/03/11 05:51:39 joon Exp $

-------------------------------------------------------------------------------@


CommonUIClassStructures segment resource

	OLSliderClass mask CLASSF_DISCARD_ON_SAVE or \
		      mask CLASSF_NEVER_SAVED

CommonUIClassStructures ends


Slider segment resource



COMMENT @----------------------------------------------------------------------

METHOD:		OLSliderSpecBuild -- 
		MSG_SPEC_BUILD for OLSliderClass

DESCRIPTION:	Builds a slider.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_BUILD
		bp	- SpecBuildFlags

RETURN:		nothing
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	8/24/92		Initial Version

------------------------------------------------------------------------------@

OLSliderSpecBuild	method dynamic	OLSliderClass, MSG_SPEC_BUILD
	;
	; Mark as a slider.  (If the default changes from immediate drag
	; notification to delayed drag notification, change hint that is
	; copied over in OpenAddScrollbar.)
	;
	or	ds:[di].OLSBI_attrs, mask OLSA_SLIDER or \
				     mask OLSA_UPDATE_DURING_DRAGS
	
	mov	di, offset OLSliderClass
	GOTO	ObjCallSuperNoLock

OLSliderSpecBuild	endm



COMMENT @----------------------------------------------------------------------

METHOD:		OLSliderSetNumIntervals -- 
		MSG_SPEC_SLIDER_SET_MAJOR_INTERVAL for OLSliderClass

DESCRIPTION:	Sets major interval.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_SLIDER_SET_MAJOR_INTERVAL
		cx	- major interval
		dx	- minor interval

RETURN:		nothing
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	10/10/92		Initial Version

------------------------------------------------------------------------------@

OLSliderSetNumIntervals	method dynamic	OLSliderClass, \
				MSG_SPEC_SLIDER_SET_NUM_INTERVALS
	tst	dx				;no minor interval, use major
	jnz	10$
	mov	dx, cx
10$:
	mov	ds:[di].OLSI_numMajorIntervals, cx
	mov	ds:[di].OLSI_numMinorIntervals, dx
	ret
OLSliderSetNumIntervals	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLSliderWantHashMarks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure out if we should be displaying hash marks.

CALLED BY:	(INTERNAL) OLSliderRecalcSize, OLSliderDraw
PASS:		*ds:si	= GenValue object
RETURN:		carry set if should show hash marks
DESTROYED:	ax, cx, dx, bp, di
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		For a slider that's not showing the value text, too, we
		were created by another GenValue that built to an OLSpinGadget
		and must ask that beastie whether to display hash marks.
		
		For a slider that's showing the value text, we are the lone
		GenValue and must look for the appropriate hint to decide.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 1/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLSliderWantHashMarks proc	near
		uses	bx
		.enter
		call	Slider_DerefVisDI
		test	ds:[di].OLSBI_attrs, mask OLSA_TEXT_TOO
		jnz	checkVardata
		
		mov	ax, MSG_SPEC_SPIN_GET_ATTRS
		call	VisCallParent
		test	cx, mask OLSGA_SHOW_HASH_MARKS
		jz	done
		stc
done:
		.leave
		ret
checkVardata:
		mov	ax, HINT_VALUE_DISPLAY_INTERVALS
		call	ObjVarFindData
		jmp	done
OLSliderWantHashMarks endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLSliderRecalcSize -- 
		MSG_VIS_RECALC_SIZE for OLSliderClass

DESCRIPTION:	Recalc's size

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_RECALC_SIZE
		cx, dx	- suggested size

RETURN:		cx, dx, - size
		ax, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	8/30/92		Initial Version

------------------------------------------------------------------------------@
MO_CGA_THUMB_HEIGHT	=	8	;minimum thumb height in CGA

OLSliderRecalcSize	method dynamic	OLSliderClass, \
				MSG_VIS_RECALC_SIZE

	mov	di, offset OLSliderClass
	call	ObjCallSuperNoLock

	pushdw	cxdx
	call	OLSliderWantHashMarks
	popdw	cxdx

	jnc	exit

	call	Slider_DerefVisDI
	call	SwapHoriz			;assume vertical

	;
	; If needed, widthwise add room for hash mark lengths.
	;
	add	cx, HASH_MARK_SIZE+2		;make room for hash marks

	;	
	; If needed, lengthwise leave at least (numHashMarks-1)*3+1.
	;
	mov	bp, ds:[di].OLSI_numMinorIntervals
	dec	bp
	mov	ax, bp
	add	ax, bp
	add	ax, bp
	inc	ax

	;
	; Leave room for a minimum thumb, too.
	;
	add	ax, MO_THUMB_HEIGHT
	test	ds:[di].OLSBI_attrs, mask OLSA_VERTICAL
	jz	10$
	call	OpenCheckIfCGA			
	jnc	15$				;vertical, smaller thumb
	jmp	short 12$			;  height on CGA
10$:
	call	OpenCheckIfNarrow			
	jnc	15$				;horizontal, smaller thumb
12$:
	sub	ax, MO_THUMB_HEIGHT - MO_CGA_THUMB_HEIGHT
	jmp	short 15$
15$:
	cmp	dx, ax
	jae	20$
	mov	dx, ax
20$:
	call	SwapHoriz
	jnz	30$				;was vertical, branch
	call	OpenCheckIfCGA
	jnc	exit
	sub	dx, 2				;CGA, subtract a little.
	jmp	short exit
30$:
	call	OpenCheckIfNarrow
	jnc	exit
	sub	cx, 2				;Narrow, subtract a little
exit:
	ret
OLSliderRecalcSize	endm

SwapHoriz	proc	near
	test	ds:[di].OLSBI_attrs, mask OLSA_VERTICAL ;see if horizontal
	jnz	10$					;no, branch
	xchg	cx, dx					;else xchg parameters
10$:
	ret
SwapHoriz	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLSliderDraw -- 
		MSG_VIS_DRAW for OLSliderClass

DESCRIPTION:	Draws an object.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_DRAW	
		cl	- DrawFlags
		bp 	- gstate

RETURN:		nothing
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	10/10/92		Initial Version

------------------------------------------------------------------------------@

	
OLSliderDraw	method dynamic	OLSliderClass, MSG_VIS_DRAW
	push	bp
	mov	di, offset OLSliderClass
	CallSuper	MSG_VIS_DRAW

	call	OLSliderWantHashMarks
	pop	di				;gstate
	jnc	exit
	call	DrawHashMarks
exit:
	ret
OLSliderDraw	endm




COMMENT @----------------------------------------------------------------------

ROUTINE:	DrawHashMarks

SYNOPSIS:	Draw some hash marks, dude.

CALLED BY:	OLSliderDraw

PASS:		*ds:si -- slider
		di -- gstate

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	10/10/92		Initial version

------------------------------------------------------------------------------@

DrawHashMarks	proc	near
	mov	ax, C_BLACK			;draw hashes in black
	call	GrSetLineColor

	push	di
	call	Slider_DerefVisDI		;no interval, forget it
	tstdw	ds:[di].OLSI_numMinorIntervals
	pop	di
	jz	exitNoPop

	clr	cx				;init current hash mark
hashLoop:
	push	di				;save gstate
	push	cx				;save current hash mark
	push	di				;save gstate yet again

	call	GetHashMarkLen			;ax <- hash mark length to use

	push	ax				;save the hash mark length
	call	CalcHashMarkOffset		;pixel position in cx
	pop	ax				;restore hash mark length
	pop	di				;restore gstate
	jc	exit				;past end, exit

	call	DrawHashMark			;draw the hash mark
	pop	cx				;restore current interval

	call	Slider_DerefVisDI			
	inc	cx				;next interval
	pop	di				;restore gstate
	jmp	short hashLoop
exit:
	add	sp, 4				;unload gstate, last interval
exitNoPop:
	ret
DrawHashMarks	endp






COMMENT @----------------------------------------------------------------------

ROUTINE:	GetHashMarkLen

SYNOPSIS:	Returns the hash mark length, basically seeing if the
		large hash mark interval divides neatly into the current
		hash value.

CALLED BY:	DrawHashMarks

PASS:		*ds:si -- slider
		cx -- current hash mark

RETURN:		ax -- hash mark length

DESTROYED:	bx, di

PSEUDO CODE/STRATEGY:
		Use hash mark if:
			hash * numMajorIntervals / numMinorIntervals has no 
			remainder.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	10/10/92	Initial version

------------------------------------------------------------------------------@

GetHashMarkLen	proc	near		uses	cx
	.enter
	call	Slider_DerefVisDI
	mov	ax, ds:[di].OLSI_numMajorIntervals
	mov	bx, SMALL_HASH_MARK_SIZE	;assume no major interval
	tst	ax
	jz	exit				;no major interval, use small

	mul	cx				;result in dx.ax
	mov	cx, ds:[di].OLSI_numMinorIntervals
	div	cx				;result in ax, remainder in dx
	mov	bx, SMALL_HASH_MARK_SIZE	;assume not at major internal
	tst	dx
	jnz	exit				;not evenly divisible, branch
	mov	bx, HASH_MARK_SIZE		;else use large size
exit:
	mov	ax, bx
	.leave
	ret
GetHashMarkLen	endp




COMMENT @----------------------------------------------------------------------

ROUTINE:	CalcHashMarkOffset

SYNOPSIS:	Calcs the pixel offset for this hash mark.

CALLED BY:	DrawHashMarks

PASS:		*ds:si -- slider
		cx -- the hash mark

RETURN:		carry set if past the allowable range, else:
			cx -- pixel offset

DESTROYED:	ax, bx, dx, bp

PSEUDO CODE/STRATEGY:
		offset = visible range * hash mark / numMinorIntervals

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	10/10/92		Initial version

------------------------------------------------------------------------------@
CalcHashMarkOffset	proc	near
	uses	si
	.enter
	;
	; Past the allowed range, exit with carry set.
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	bx, ds:[di].OLSI_numMinorIntervals
	cmp	cx, bx
	stc
	jg	exit

	mov	ax, ds:[di].OLSBI_elevLen		;start with -elevLen
	neg	ax

	test	ds:[di].OLSBI_attrs, mask OLSA_VERTICAL
	jz	horiz
	add	di, R_top - R_left			;vertical, get top/bot
horiz:
	add	ax, ds:[di].VI_bounds.R_right
	sub	ax, ds:[di].VI_bounds.R_left		;get distance 
	dec	ax					;Back off of edges
	dec	ax					

if	_ISUI
	call	CheckReadOnly
	jnz	5$
	sub	ax, (MO_ARROW_HEIGHT+1)*2		;gauge, avoid arrows
5$:
endif
							
	mul	cx					;result in dx.ax
	div	bx					;divide by numIntervals,
							;  result in ax.dx

	tst	dx					;round as needed
	jns	10$
	inc	ax
10$:
	mov	cx, ax
	clc						;successful...
exit:
	.leave
	ret
CalcHashMarkOffset	endp





COMMENT @----------------------------------------------------------------------

ROUTINE:	DrawHashMark

SYNOPSIS:	Draws a hash mark.

CALLED BY:	DrawHashMarks

PASS:		*ds:si -- slider
		cx -- pixel offset to hash mark
		ax -- length of hash mark
		di -- gstate

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	10/10/92	Initial version

------------------------------------------------------------------------------@

DrawHashMark	proc	near
	mov	bp, ax				;hash mark len in bp
	push	di				;push gstate 'til we need it
	call	Slider_DerefVisDI
	;
	; Assume horizontal for a sec and set some stuff up.
	; Offset already in cx, which we'll plan on using as left and right 
	; edge of hash mark.
	;
if	_MOTIF
	mov	bx, ds:[di].OLSBI_arrowSize				     
	add	bx, 3							     
else
	mov	bx, MO_SCROLLBAR_WIDTH+1	;top edge, leave a pixel margin

						;horizontal CGA, use CGA const.
	test	ds:[di].OLSBI_attrs, mask OLSA_VERTICAL
	jnz	3$
	call	OpenCheckIfCGA
	jnc	3$
	mov	bx, CGA_HORIZ_SCROLLBAR_WIDTH+1
3$:
endif

	mov	dx, bx				;bottom edge
	add	dx, bp
	mov	ax, cx				;left edge


if	_MOTIF
	;
	; Adjust so center of thumb even with hash mark.  (not if a read-only
	; gauge, though.)
	;
	call	CheckReadOnly
	jnz	5$
	mov	bp, ds:[di].OLSBI_arrowSize		;add arrow-size * 1.5
	shl	bp, 1
	add	bp, ds:[di].OLSBI_arrowSize
	shr	bp, 1
	add	ax, bp
	add	cx, bp
5$:
endif
if	_ISUI
	call	CheckReadOnly
	jnz	5$
	add	ax, MO_ARROW_HEIGHT+2
	add	cx, MO_ARROW_HEIGHT+2
5$:
endif

	test	ds:[di].OLSBI_attrs, mask OLSA_VERTICAL
	jz	10$
	xchgdw	axcx, bxdx			;flip X and Y stuff if vertical
10$:
	add	ax, ds:[di].VI_bounds.R_left	;make relative to object
	add	cx, ds:[di].VI_bounds.R_left
	add	bx, ds:[di].VI_bounds.R_top
	add	dx, ds:[di].VI_bounds.R_top
	pop	di
	call	GrDrawLine			;do it to it.
	ret
DrawHashMark	endp


CheckReadOnly	proc	near		;returns zero flag clear if true
	push	di
	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset
	test	ds:[di].GI_attrs, mask GA_READ_ONLY
	pop	di
	ret
CheckReadOnly	endp

Slider_DerefVisDI	proc	near
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	ret
Slider_DerefVisDI	endp
	
Slider		ends
