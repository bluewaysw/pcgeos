COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GrObj
FILE:		globalUtils.asm

AUTHOR:		Steve Scholl

ROUTINES:
	Name			Description
	----			-----------
	GrObjGlobalCheckForMetaTextMessages
	GrObjGlobalCheckForMetaSearchSpellMessages
	GrObjGlobalCheckForMetaSuspendUnsuspendMessages
INT	GrObjGlobalUpdateControllerLow
INT	GrObjGlobalAllocNotifyBlock
INT	GrObjIsRectDWordInsideRectDWord?
INT	GrObjIsRectDWordOverlappingRectDWord?
INT	GrObjCombineRectDWords
INT	GrObjGlobalCombineRectDWFixeds
INT	GrObjGlobalMinDWF
INT	GrObjGlobalMaxDWF
INT	GrObjGlobalCopyDWF
INT	GrObjGlobalExpandRectWWFixedByWWFixed
INT	GrObjGlobalAsymetricExpandRectWWFixedByWWFixed
INT	GrObjGlobalIsPointWWFixedInsideRectWWFixed?
INT	GrObjGlobalExpandRectDWFixedByDWFixed
INT	GrObjGlobalIsPointDWFixedInsideRectDWFixed?
INT	GrObjGlobalInitRectDWFixedWithPointDWFixed
INT	GrObjGlobalCombineRectDWFixedWithPointDWFixed
INT	GrObjGlobalCombineRectWWFixedWithPointWWFixed
INT	GrObjGlobalSetRectDWFixedFromFourPointDWFixeds

INT	GrObjGlobalGetWWFixedDimensionsFromRectDWFixed
INT	GrObjCheckWWFixedDimensionOfRectDWFixed

INT	GrObjGlobalConvertSystemMouseMessage
INT	GrObjConvertGrObjMouseMessageToLarge
INT	GrObjConvertGrObjMouseMessageToSmall

INT	GrObjSetGrObjBaseAreaAttrElementToDefaults
INT	GrObjSetGrObjBaseLineAttrElementToDefaults

	GrObjGlobalInitGrObjTransMatrix		
	GrObjGlobalSetActionNotificationOutput
	GrObjGlobalSuspendActionNotification
	GrObjGlobalUnsuspendActionNotification
	GrObjGlobalCopyRectDWFixed
	GrObjGlobalCompleteHitDetectionWithAreaAttrCheck		
	GrObjGlobalGetLineWidthPlusSlopHitDetectionAdjust
	GrObjGlobalGetLineWidthPlusSlopHitDetectionAdjustInPARENT
	GrObjGlobalInitRectWWFixedWithPointWWFixed


	GrObjGlobalAddVMChainUndoAction
	GrObjGlobalAddFlagsUndoAction
	GrObjGlobalStartUndoChainNoText
	GrObjGlobalStartUndoChain
	GrObjGlobalEndUndoChain
	GrObjGlobalAllocUndoDBItem
	GrObjGlobalUndoIgnoreActions
	GrObjGlobalUndoAcceptActions



REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Steve	8/01/91		Initial revision


DESCRIPTION:
		

	$Id: globalUtils.asm,v 1.1 97/04/04 18:05:11 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrObjMiscUtilsCode	segment resource








COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGlobalInitTransMatrix
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize a TransMatrix to 
		10
		01
		00

CALLED BY:	INTERNAL UTILITY

PASS:		
		ds:si - TransMatrix

RETURN:		
		ds:si - TransMatrix inited

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/ 1/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGlobalInitTransMatrix		proc	far
	uses	ax,es,di
	.enter

	segmov	es,ds,ax
	mov	di,si
	clr	ax
	StoreConstantNumBytes <size TransMatrix>
	mov	ds:[si].TM_e11.WWF_int,1
	mov	ds:[si].TM_e22.WWF_int,1

	.leave
	ret
GrObjGlobalInitTransMatrix		endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjCombineRectDWords
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Expand primary RectDWord to encompass secondary RectDWord

CALLED BY:	INTERNAL

PASS:		
		ds:si - Primary RectDWord
		es:di - Secondary RectDWord

RETURN:		
		Primary RectDWord may have been modified

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/30/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjCombineRectDWords		proc	far
	uses	ax,bx
	.enter

	;    If left of secondary rect is less than left of primary rect
	;    then new left
	;

	mov	ax,es:[di].RD_left.low
	mov	bx,ds:[di].RD_left.high
	jlDW	bx,ax,ds:[si].RD_left.high,ds:[si].RD_left.low,newLeft

checkRight:
	;    If right of secondary rect is greater than right of primary rect
	;    then new right
	;

	mov	ax,es:[di].RD_right.low
	mov	bx,es:[di].RD_right.high
	jgDW	bx,ax,ds:[si].RD_right.high,ds:[si].RD_right.low,newRight

checkTop:
	;    If top of secondary rect is less than top of primary rect
	;    then not inside
	;

	mov	ax,es:[di].RD_top.low
	mov	bx,es:[di].RD_top.high
	jlDW	bx,ax,ds:[si].RD_top.high,ds:[si].RD_top.low,newTop

checkBottom:
	;    If bottom of secondary rect is greater than bottom of primary rect
	;    then not inside
	;

	mov	ax,es:[di].RD_bottom.low
	mov	bx,es:[di].RD_bottom.high
	jgDW	bx,ax,ds:[si].RD_bottom.high,ds:[si].RD_bottom.low,newBottom

done:
	.leave
	ret

newLeft:
	mov	ds:[si].RD_left.low,ax
	mov	ds:[si].RD_left.high,bx
	jmp	checkRight

newRight:
	mov	ds:[si].RD_right.low,ax
	mov	ds:[si].RD_right.high,bx
	jmp	checkTop

newTop:
	mov	ds:[si].RD_top.low,ax
	mov	ds:[si].RD_top.high,bx
	jmp	checkBottom

newBottom:
	mov	ds:[si].RD_bottom.low,ax
	mov	ds:[si].RD_bottom.high,bx
	jmp	done

GrObjCombineRectDWords		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGlobalCombineRectDWFixeds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Expand primary RectDWFixed to encompass secondary RectDWFixed

CALLED BY:	INTERNAL

PASS:		
		ds:si - Primary RectDWFixed
		es:di - Secondary RectDWFixed

RETURN:		
		Primary RectDWFixed may have been modified

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/30/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGlobalCombineRectDWFixeds	proc	far
	uses	ax, di, si
	.enter

	;    imitating Steve's coding style by scratching myself
	;    as I type...
	;

	;    check left
	;    

CheckHack	<offset RDWF_left eq 0>
	call	GrObjGlobalMinDWF

	;    Check top
	;

	mov	ax, offset RDWF_top
	add	di, ax					;es:di = top 2
	add	si, ax					;ds:si = top 1

	call	GrObjGlobalMinDWF

	;    Check right
	;

	mov	ax, offset RDWF_right - offset RDWF_top
	add	di, ax					;es:di = right 2
	add	si, ax					;ds:si = right 1

	call	GrObjGlobalMaxDWF

	;    Check bottom
	;

	mov	ax, offset RDWF_bottom - offset RDWF_right
	add	di, ax					;es:di = bottom 2
	add	si, ax					;ds:si = bottom 1

	call	GrObjGlobalMaxDWF

	.leave
	ret
GrObjGlobalCombineRectDWFixeds		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGlobalMinDWF
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the minimum of 2 DWF's

CALLED BY:	INTERNAL

PASS:		ds:si = primary DWFixed
		es:di = secondary DWFixeddd

RETURN:		
		ds:si = minimum of the two passed DWFixed's

DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	11 Nov 1991	Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGlobalMinDWF	proc	near

	;    check high words
	;

	mov	ax, es:[di].DWF_int.high
	cmp	ax, ds:[si].DWF_int.high
	je	checkLow
	jg	done

doChange:
	call	GrObjGlobalCopyDWF
done:
	ret

	;     high words were equal, so compare low words.
	;

checkLow:
	mov	ax, es:[di].DWF_int.low
	cmp	ax, ds:[si].DWF_int.low
	jb	doChange
	ja	done

	;    int's equal, so check fracs
	;

	mov	ax, es:[di].DWF_frac
	cmp	ax, ds:[si].DWF_frac
	jae	done
	jmp	doChange
GrObjGlobalMinDWF	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGlobalMaxDWF
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the maximum of 2 DWF's

CALLED BY:	INTERNAL

PASS:		ds:si = primary DWFixed
		es:di = secondary DWFixeddd

RETURN:		
		ds:si = maximum of the two passed DWFixed's

DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	11 Nov 1991	Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGlobalMaxDWF	proc	near

	;    check high words
	;

	mov	ax, es:[di].DWF_int.high
	cmp	ax, ds:[si].DWF_int.high
	je	checkLow
	jl	done

doChange:
	call	GrObjGlobalCopyDWF
done:
	ret

	;     high words were equal, so compare low words.
	;     the cmp will set the carry iff old < new
	;

checkLow:
	mov	ax, es:[di].DWF_int.low
	cmp	ax, ds:[si].DWF_int.low
	ja	doChange
	jb	done

	;    int's equal, so check fracs
	;

	mov	ax, es:[di].DWF_frac
	cmp	ax, ds:[si].DWF_frac
	jbe	done
	jmp	doChange	
GrObjGlobalMaxDWF	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGlobalCopyDWF
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copies a DWFixed number

CALLED BY:	INTERNAL

PASS:		ds:si = dest DWFixed
		es:di = source DWFixed

RETURN:		
		ds:si = source DWFixed

DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	11 Nov 1991	Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGlobalCopyDWF	proc	far
	mov	ax, es:[di].DWF_frac
	mov	ds:[si].DWF_frac, ax
	mov	ax, es:[di].DWF_int.low
	mov	ds:[si].DWF_int.low, ax
	mov	ax, es:[di].DWF_int.high
	mov	ds:[si].DWF_int.high, ax
	ret
GrObjGlobalCopyDWF	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjIsRectDWordInsideRectDWord?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if Secondary RectDWord is inside Primary RectDWord.
		If edges match rect is considered inside.

CALLED BY:	INTERNAL

PASS:		
		ds:si - Primary RectDWord
		es:di - Secondary RectDWord

RETURN:		
		stc - yes
		clc - no

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/30/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjIsRectDWordInsideRectDWord?		proc	far
	uses	ax,bx
	.enter

	;    If left of secondary rect is less than left of primary rect
	;    then not inside
	;

	mov	ax,ds:[si].RD_left.low
	mov	bx,ds:[si].RD_left.high
	jlDW	es:[di].RD_left.high,es:[di].RD_left.low,bx,ax,notInside

	;    If right of secondary rect is greater than right of primary rect
	;    then not inside
	;

	mov	ax,ds:[si].RD_right.low
	mov	bx,ds:[si].RD_right.high
	jgDW	es:[di].RD_right.high,es:[di].RD_right.low,bx,ax,notInside

	;    If top of secondary rect is less than top of primary rect
	;    then not inside
	;

	mov	ax,ds:[si].RD_top.low
	mov	bx,ds:[si].RD_top.high
	jlDW	es:[di].RD_top.high,es:[di].RD_top.low,bx,ax,notInside

	;    If bottom of secondary rect is greater than bottom of primary rect
	;    then not inside
	;

	mov	ax,ds:[si].RD_bottom.low
	mov	bx,ds:[si].RD_bottom.high
	jgDW	es:[di].RD_bottom.high,es:[di].RD_bottom.low,bx,ax,notInside

	stc
done:
	.leave
	ret

notInside:
	clc
	jmp	short done


GrObjIsRectDWordInsideRectDWord?		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGlobalExpandRectWWFixedByWWFixed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Increase size of RectWWFixed by WWFixed in each 
		direction

CALLED BY:	INTERNAL

PASS:		
		ds:si - Ordered RectWWFixed
		dx:cx - WWFixed
		
RETURN:		
		RectWWFixed potentially expanded

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/ 9/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGlobalExpandRectWWFixedByWWFixed		proc	far
	.enter

	subwwf	ds:[si].RWWF_left, dxcx
	subwwf	ds:[si].RWWF_top, dxcx

	addwwf	ds:[si].RWWF_right, dxcx
	addwwf	ds:[si].RWWF_bottom, dxcx

	.leave
	ret

GrObjGlobalExpandRectWWFixedByWWFixed		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGlobalAsymetricExpandRectWWFixedByWWFixed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Increase size of RectWWFixed by WWFixed in each 
		direction

CALLED BY:	INTERNAL

PASS:		
		ds:si - Ordered RectWWFixed
		dx:cx - WWFixed x adjust
		bx:ax - WWFixed y adjust
		
RETURN:		
		RectWWFixed potentially expanded

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/ 9/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGlobalAsymetricExpandRectWWFixedByWWFixed		proc	far
	.enter

	subwwf	ds:[si].RWWF_left, dxcx
	subwwf	ds:[si].RWWF_top, bxax

	addwwf	ds:[si].RWWF_right, dxcx
	addwwf	ds:[si].RWWF_bottom, bxax

	.leave
	ret

GrObjGlobalAsymetricExpandRectWWFixedByWWFixed		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGlobalCompleteHitDetectionWithAreaAttrCheck
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do a bunch of wacky checks on the area attributes
		to complete the hit detection

CALLED BY:	INTERNAL UTILITY

PASS:		*ds:si - grobject
		clc - if point not in inner rect (was on line)
		stc - if point was in inner rect

RETURN:		
		al - EvaluatePositionRating
		dx - EvaluatePositionNotes

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SPEED over SMALL SIZE  

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	5/29/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGlobalCompleteHitDetectionWithAreaAttrCheck		proc	far
	class	GrObjClass
	uses	di
	.enter

EC <	call	ECGrObjCheckLMemObject			>

	;    Assume no EvaluatePositionNotes and
	;    DON`T muck up the flags.
	;

	mov	dx,0					;don't muck flags
	jnc	highNothing

	;    At this time we know that the point is inside the
	;    object and not on the edge. So the evaluation
	;    depends on the attributes of the object
	;

	call	GrObjGetAreaInfoAndMask

	;    This is kind of a hack. If an object has this bit set
	;    it means that the object draws non-area type things
	;    on the draw area messages. So it probably should
	;    still be selected even if the area mask is 0
	;

	GrObjDeref	di,ds,si
	test	ds:[di].GOI_msgOptFlags,mask GOMOF_DRAW_FG_AREA
	jnz	checkTransparent

	;    If the object is not filled then the user clicked in the
	;    middle of a hollow object. Evaluate med and signal that
	;    object doesn't block out lower objects
	;

	cmp	ah,SDM_0
	je	medNothing

checkTransparent:
	;    We know the object is filled, in some manner.
	;    If it is not transparent then it probably blocks out
	;    object underneath it.
	;

	test	al, mask GOAAIR_TRANSPARENT
	jz	checkDrawMode

	;    The object is filled, but transparent.
	;    It still may block out objects underneath it
	;    if the mask is 100.
	;

	cmp	ah,SDM_100
	je	checkDrawMode

	;    The object is filled with a transparent pattern.
	;

highNothing:
	;    Point evaluates high but requires no special command
	;    for the priority list
	;

	movnf	al,EVALUATE_HIGH
	
	;   Because we haven't added code to cycle through
	;   the selection list, make the processing of
	;   objects stop on all high objects anyway
	;

	mov	dx,mask EPN_BLOCKS_LOWER_OBJECTS

done:
	.leave
	ret

medNothing:
	;    User clicked inside an object with only a frame,
	;
	mov	al,EVALUATE_MEDIUM
	jmp	done


checkDrawMode:
	;   If draw mode is not solid then should jump to 
	;   high nothing.
	;   But this won't matter unless we add ability to
	;   cycle through priority list.
	;

	;    Point evaluates high and object blots out
	;    out any other objects beneath it that might 
	;    be interested in the point.
	;

	movnf	al,EVALUATE_HIGH
	mov	dx,mask EPN_BLOCKS_LOWER_OBJECTS
	jmp	done

GrObjGlobalCompleteHitDetectionWithAreaAttrCheck		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGlobalGetLineWidthPlusSlopHitDetectionAdjust
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	For hit detection we want to allow the user to click within
		one device pixel of the object and still get it.
		We also must include the line width of the object in
		doing the hit detection.
		This routine converts the one device pixel coordinate axes
		vectors into OBJECT coordinates, chooses the max x and max
		y from the resulting vectors and adds in half the line
		width.

CALLED BY:	INTERNAL

PASS:		
		*ds:si - grobject

RETURN:		
		dx:cx - WWFixed x to expand/contract each 
			vertical edge of bounds
		bx:ax - WWFixed y to expand/contract each 
			horizontal edge of bounds

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SPEED over SMALL SIZE

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	5/28/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGlobalGetLineWidthPlusSlopHitDetectionAdjust		proc	far

xOBJDevice	local	PointWWFixed
yOBJDevice	local	PointWWFixed

	uses	di,si
	.enter

EC <	call	ECGrObjCheckLMemObject					>

	;    Get device units in WWF
	;

	call	GrObjGetCurrentNudgeUnitsWWFixed

	;    Convert device unit vectors 1,0 and 0,1 into OBJECT
	;    and get the absolute values.
	;

	push	bx,ax					;y device unit
	clr	ax,bx
	call	GrObjConvertNormalWWFVectorPARENTToOBJECT
	tst	dx
	jns	10$
	negwwf	dxcx
10$:
	movwwf	xOBJDevice.PF_x,dxcx
	tst	bx
	jns	20$
	negwwf	bxax
20$:
	movwwf	xOBJDevice.PF_y,bxax
	pop	bx,ax					;y device unit
	clr	dx,cx
	call	GrObjConvertNormalWWFVectorPARENTToOBJECT
	tst	dx
	jns	30$
	negwwf	dxcx
30$:
	movwwf	yOBJDevice.PF_x,dxcx
	tst	bx
	jns	40$
	negwwf	bxax
40$:
	movwwf	yOBJDevice.PF_y,bxax

	;    Get (width+2)/2. To include the line width in the
	;    hit detection we should really be using width/2.
	;    However weird cases crop up because one thick lines
	;    really draw 1/2 a pixel out of place and when zoomed
	;    out lines may draw much thicker than they are supposed
	;    to be. (One thick lines draw even though a pixel is
	;    actually several points thick). So we use the above
	;    formula because it works.
	;

	push	bp				;locals
	call	GrObjGetLineWidth
	mov	si,bp				;line width frac
	pop	bp				;locals
	add	di,2				;line width int
	shrwwf	disi

	;    Get max x and max y of vectors and add in line
	;    width adjustment.
	;

	movwwf	dxcx,xOBJDevice.PF_x
	jgewwf	dxcx,yOBJDevice.PF_x,getMaxY
	movwwf	dxcx,yOBJDevice.PF_x
getMaxY:
	movwwf	bxax,xOBJDevice.PF_y
	jgewwf	bxax,yOBJDevice.PF_y,addLineAdjust
	movwwf	bxax,yOBJDevice.PF_y

addLineAdjust:
	addwwf	dxcx,disi
	addwwf	bxax,disi

	.leave
	ret
GrObjGlobalGetLineWidthPlusSlopHitDetectionAdjust		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGlobalGetLineWidthPlusSlopHitDetectionAdjustInPARENT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	For hit detection we want to allow the user to click within
		one device pixel of the object and still get it.
		We also must include the line width of the object in
		doing the hit detection.
		This routine takes the one device pixel coordinate axes
		vectors and adds in half the line
		width.

CALLED BY:	INTERNAL

PASS:		
		*ds:si - grobject

RETURN:		
		dx:cx - WWFixed x
		bx:ax - WWFixed y

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SPEED over SMALL SIZE

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	5/28/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGlobalGetLineWidthPlusSlopHitDetectionAdjustInPARENT	proc	far

	uses	di,si
	.enter

EC <	call	ECGrObjCheckLMemObject					>

	;    Get device units in WWF
	;

	call	GrObjGetCurrentNudgeUnitsWWFixed

	;    Get (width+2)/2. To include the line width in the
	;    hit detection we should really be using width/2.
	;    However weird cases crop up because one thick lines
	;    really draw 1/2 a pixel out of place and when zoomed
	;    out lines may draw much thicker than they are supposed
	;    to be. (One thick lines draw even though a pixel is
	;    actually several points thick). So we use the above
	;    formula because it works.
	;

	push	bp				;locals
	call	GrObjGetLineWidth
	mov	si,bp				;line width frac
	pop	bp				;locals
	add	di,2				;line width int
	shrwwf	disi

	;    Add line width to device units.
	;

	addwwf	dxcx,disi
	addwwf	bxax,disi

	.leave
	ret
GrObjGlobalGetLineWidthPlusSlopHitDetectionAdjustInPARENT		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGlobalIsPointWWFixedInsideRectWWFixed?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if PointWWFixed is inside a RectWWFixed
		If edges match rect is considered inside.

CALLED BY:	INTERNAL

PASS:		
		ds:si - RectWWFixed
		es:di - PointWWFixed

RETURN:		
		stc - inside
		clc - punt

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/15/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGlobalIsPointWWFixedInsideRectWWFixed?		proc	far
	uses	bx,ax
	.enter

	MovWWF	bx,ax, es:[di].PF_x

	;    If x of point is less than left of rect
	;    then not inside
	;

	jlWWFPtr	bx,ax, ds:[si].RWWF_left, notInside

	;    If x of point is greater than right of rect
	;    then not inside
	;

	jgWWFPtr	bx,ax, ds:[si].RWWF_right, notInside


	MovWWF	bx,ax, es:[di].PF_y

	;    If y of point is less than top of rect
	;    then not inside
	;

	jlWWFPtr	bx,ax,ds:[si].RWWF_top, notInside

	;    If y of point is greater than bottom of rect
	;    then not inside
	;

	jgWWFPtr	bx,ax,ds:[si].RWWF_bottom, notInside

	stc
done:
	.leave
	ret

notInside:
	clc
	jmp	short done

GrObjGlobalIsPointWWFixedInsideRectWWFixed?		endp








COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGlobalIsPointDWFixedInsideRectDWFixed?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if PointDWFixed is inside a RectDWFixed
		If edges match rect is considered inside.

CALLED BY:	INTERNAL

PASS:		
		ds:si - RectDWFixed
		es:di - PointDWFixed

RETURN:		
		stc - inside
		clc - punt

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/15/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGlobalIsPointDWFixedInsideRectDWFixed?		proc	far
	uses	cx,bx,ax
	.enter

	MovDWF	cx,bx,ax, es:[di].PDF_x

	;    If x of point is less than left of rect
	;    then not inside
	;

	jlDWFPtr	cx,bx,ax, ds:[si].RDWF_left, notInside

	;    If x of point is greater than right of rect
	;    then not inside
	;

	jgDWFPtr	cx,bx,ax, ds:[si].RDWF_right, notInside


	MovDWF	cx,bx,ax, es:[di].PDF_y

	;    If y of point is less than top of rect
	;    then not inside
	;

	jlDWFPtr	cx,bx,ax,ds:[si].RDWF_top, notInside

	;    If y of point is greater than bottom of rect
	;    then not inside
	;

	jgDWFPtr	cx,bx,ax,ds:[si].RDWF_bottom, notInside

	stc
done:
	.leave
	ret

notInside:
	clc
	jmp	short done

GrObjGlobalIsPointDWFixedInsideRectDWFixed?		endp










COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGlobalCheckWWFixedDimensionsOfRectDWFixed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify that the width and height of the based RectDWFixed 
		are less than or equal the passed WWFixed value.

CALLED BY:	INTERNAL

PASS:		
		ss:bp - ordered RectDWFixed
		dx:cx - WWFixed max dimensions

RETURN:		
		stc - ok
		clc - hosed

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/19/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGlobalCheckWWFixedDimensionsOfRectDWFixed		proc	far
	uses	ax,bx,cx,dx,di,si
	.enter

	mov	di,dx				;max int
	mov	si,cx				;max frac

	;    Get dimensions of rect, bail if dimensions don't fit
	;    in WWFixed
	;

	CallMod	GrObjGlobalGetWWFixedDimensionsFromRectDWFixed
	jnc	done

	;    Compare width and height to max dimensions, jump if either
	;    is too big
	;

	jaWWF	dx,cx,di,si,tooBig
	jaWWF	bx,ax,di,si,tooBig

	stc

done:
	.leave
	ret

tooBig:
	clc
	jmp	done

GrObjGlobalCheckWWFixedDimensionsOfRectDWFixed		endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjGlobalCopyRectDWFixed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy a RectDWFixed to another

CALLED BY:	Global

PASS:		
		ds:si - Dest RectDWFixed
		es:di - Source RectDWFixed

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/ 8/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGlobalCopyRectDWFixed 	proc	far
	uses	di,si,cx
	.enter

	segxchg	ds,es
	xchg	di,si
	MoveConstantNumBytes	<size RectDWFixed>,cx
	segxchg	ds,es

	.leave
	ret
GrObjGlobalCopyRectDWFixed endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBorrowStackSpaceWithData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Operates like ThreadBorrowStackSpace except that it
		copies data from the "old" stack onto the "new" stack.  Only
		the specified data may be accessed by code after calling this
		routine.  Note that the data will be copied back into the
		old stack when it is restored so be sure not to deallocate it.
		
		Call GrObjReturnStackSpaceWithData to restore the stack space.
		
		See all notes and cautions associated with
		ThreadBorrowStackSpace.

CALLED BY:	GrObj Library
PASS:		di	- amount of stack space needed, or 0 to always save
			  of the current stack regardless of how much space
			  is available on the stack.
	        ss:bp	- pointer to data that will be copied
		
		pushed on stack:
		    (word) size of data to be copied.
		
RETURN:		di	- "Token" to pass to GrObjReturnStackSpaceWithData

		ss:sp	- if stack space borrowed, this will be changed to
			  point to the new stack whose only contents will be
			  the data that was copied over.  Caller must call
			  GrObjReturnStackSpaceWithData before returning or
			  accessing OTHER data previous placed on the stack.
		
		ss:bp	- pointer to the data that was copied.
		      
	        NOTE: the size of the data that was pushed onto the stack
		before calling this routine will be removed by this routine.
			  
DESTROYED:	nothing
SIDE EFFECTS:	
	See all notes and cautions associated with
	ThreadBorrowStackSpace.

PSEUDO CODE/STRATEGY:
	I use some dgroup variables here because we have to manage some
	information that cannot be placed anywhere else (like the stack or
	in registers).  Therefore, a semaphore is needed to allow exclusive
	access to these variables in dgroup (see mainVariable.def for more
	info).
	
	I go through a lot of effort to preserve ES because there is no way
	for someone who calls this to preserve ES around a call to this routine
	if a borrow actually takes place.
	
	1) Save ES (used for dgroup), the return address, and the data size
	   all in dgroup.
	
        2) Store extra information (GrObjBorrowStackSpaceData) on the current
	   stack.
       
        3) Call ThreadBorrowStackSpace
    	    A) If no space borrowed:
    	    	1) Restore bp and pop off GrObjBorrowStackSpaceData.
		2) Restore return address and ES.
		3) Return.
	    
	    B) If space WAS borrowed:
	    	1) Allocate space for the data on the new stack.
		2) Push return address and offset to 1st word in old stack
		   block onto stack.
	        3) Copy data from old stack block into space allocated on
		   new stack.
	        4) Set bp to point to the data on the new stack.
		
		The stack returned to the user will look like:
		
				----------------------  <top of stack>
				| Empty stack space  |
				|		     |
				+--------------------+
			SP =>	| Offset to 1st word |	(2 bytes)
				| in old stack block |
				+--------------------+
			BP =>	| Data copied from   |
				| old stack	     |
				+--------------------+
				| StackFooter	     |
				----------------------  <bottom of stack>

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	6/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBorrowStackSpaceWithData	proc	far
	
	; Get exclusive access to our magic variables in dgroup
	push	es
	push	ax
NOFXIP<	segmov	es, <segment grobjStackSem>, ax				>
FXIP<	mov_tr	ax, bx							>
FXIP<	mov	bx, handle dgroup					>
FXIP<	call	MemDerefES			;es = dgroup		>
FXIP<	mov_tr	bx, ax							>
	pop	ax
	PSem	es, grobjStackSem		; Begin CRITICAL SECTION
	pop	es:[grobjStackSavedES]		; save ES in dgroup
	
	; Store our return address and the data size (passed on stack) in dgroup
	popdw	es:[grobjStackReturnAddress]
	pop	es:[grobjStackDataSize]
	
	; Check to see if the size of the data (on top of stack) is reasonable,
	; that is, data size <= di.
EC <	tst	di				;if di=0, this test is	>
EC <	jz	sizeIsValid			;not valid, so skip it.	>
EC <	cmp	es:[grobjStackDataSize], di				>
EC <	ERROR_G	GROBJ_BORROW_STACK_SPACE_DATA_SIZE_TOO_BIG		>
EC <sizeIsValid:							>

	; Ensure that the GrObjBorrowStackSpaceData structure is on the top
	; of the stack.  Be sure to push items in the correct order.
	; IF we actually borrow space, this information will be saved off in
	; the "old stack" block and freed upon calling
	; GrObjReturnStackSpaceWithData, otherwise, it will be freed here
	; before we return.
	
	; store bp offset from sp + size of the extra structure we are adding
	sub	bp, sp
	add	bp, size GrObjBorrowStackSpaceData
	push	es:[grobjStackDataSize]
	push	bp
	
	; Do the business: attempt to borrow stack space.
	call	ThreadBorrowStackSpace
	tst	di				; di = 0 means no space borrowed
	jnz	stackSpaceBorrowed
	
	; No stack space was actually borrowed.  Get rid of our structure
	; from the stack, restore the return address and es, and return.
	
	add	bp, sp
	add	sp, size GrObjBorrowStackSpaceData
	pushdw	es:[grobjStackReturnAddress]
	push	es:[grobjStackSavedES]
	VSem	es, grobjStackSem		; End CRITICAL SECTION
	
	pop	es				; restore es
	
exit:
	ret					; <<< RETURN
	
stackSpaceBorrowed:				; Still in CRITICAL SECTION
    	; Okay.. stack space was actually borrowed.  We need to access the
	; old stack and copy over the data.  BUT, we have to play a delicate
	; game to preserve the registers without screwing up the stack.
	; When we are done, the new stack should look as described in the
	; comment block for this routine.
	
	; We can trash bp because it will be fixed up before we return.
	
	; Note that we now have a "clean" stack.  So we are pointing right
	; at the StackFooter.  So, before we do anything to the stack, get
	; the offset to the first word in the old stack block that is stored
	; in our stack footer.
	mov	bp, sp				; bp <= offset to first word
	mov	bp, ss:[bp].SL_savedStackPointer; on "old stack" block
	
	; Allocate space on new stack for data.
	sub	sp, es:[grobjStackDataSize]
	
	; NOTE: The number of items pushed here is used below to calculate
	; where to put the new data.
	push	bp				; store offset to 1st word
						; on "old stack" block
						; (used to restore stack).
						
	pushdw	es:[grobjStackReturnAddress]	; Put our return address on the
						; stack.
	
	push	es:[grobjStackSavedES]		; save es
	
	VSem	es, grobjStackSem		; End CRITICAL SECTION
	
	push	ax, bx, cx, ds, si, di		; preserve caller's regs
	
	; TOTAL EXTRA ITEMS ON STACK BEFORE THE DATA:
	; bp (2), return addr (4), es, ax, bx, cx, ds, si, di (14) == 20 bytes
	
	mov	bx, di
	call	MemLock				; lock down old stack block
	mov	ds, ax
	mov	si, bp				; ds:si <= 1st word on old stack
	
	; Get the offset from the beginning of the old stack to where the
	; data begins (bpOffset).  Also get the size of the data for the rep
	; counter.
	mov	bx, ds:[si].GOBSSD_bpOffset
	mov	cx, ds:[si].GOBSSD_dataSize	; initialize counter
	add	si, bx				; ds:si <= data on old stack
	segmov	es, ss, di
	mov	di, sp				; set up di for copy
	add	di, 20				; es:di <= dest on new stack
						; (which is the current stack)
	shr	cx, 1
	rep	movsw				; copy words!
	jnc	doneWithCopy			; if the data size was odd
	movsb					; than copy the extra byte

doneWithCopy:
	pop	ax, bx, cx, ds, si, di
	pop	es				; es is now restored!
	
	; Stack now looks like this (each line is a word):
	;  sp-> return address offset
	;	return address segment
	;	offset to 1st word in old stack black
	;	DATA				<= bp should point here
	;	...
	;	StackFooter
	
	xchg	bx, di
	call	MemUnlock
	xchg	bx, di
	mov	bp, sp
	add	bp, 6				; set bp = sp+6 .. see previous
	jmp	exit				; comments
	
GrObjBorrowStackSpaceWithData	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjReturnStackSpaceWithData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Restores stack to where it was before
		GrObjBorrowStackSpaceWithData was called.  Copies data that
		was transfered to the new stack back to the old stack.
		
		Must be used with GrObjBorrowStackSpaceWithData.

CALLED BY:	GrObj Library
PASS:		di	- "Token" returned from GrObjBorrowStackSpaceWithData.
RETURN:		ss:bp	- points to correct spot passed to 
			  GrObjBorrowStackSpaceWithData
			  
DESTROYED:	di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Be sure to see the comments in GrObjBorrowStackSpaceWithData -
	they are very informative.
	
	If di = 0 (meaning no stack was borrowed) we return immediately,
	otherwise:
	
	1) Save ES (used for dgroup), the return address, and the offset to
	   the 1st item in the "old stack" block into dgrop.
        
	2) Copy data from current stack to "old stack" block.
	
	3) Clean up current stack (including deallocating copied data).
	
	4) Call ThreadReturnStackSpace.  This will copy our data BACK onto
	   the real stack.
	
	5) Set bp to point to the data on old (now current) stack.
	
	6) Pop off additional data (GrObjBorrowStackSpaceData).
	
	7) Push return address onto stack and restore ES.
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	6/30/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjReturnStackSpaceWithData	proc	far
	tst	di
	jnz	doTheWork
	ret					; <<< RETURN (1 of 2)
	
doTheWork: 	
	; Get exclusive access to our magic variables in dgroup
	push	es
	push	ax
NOFXIP<	segmov	es, <segment grobjStackSem>, ax	; es = dgroup		>
FXIP<	mov_tr	ax, bx							>
FXIP<	mov	bx, handle dgroup					>
FXIP<	call	MemDerefES			;es = dgroup		>
FXIP<	mov_tr	bx, ax							>
	pop	ax
	PSem	es, grobjStackSem		; Begin CRITICAL SECTION
	pop	es:[grobjStackSavedES]		; save ES in dgroup
	
	popdw	es:[grobjStackReturnAddress]
	pop	es:[grobjStackDataSize]		; REALLY is offset to 1st
						; word on old stack.. just
						; using the same place in
						; memory
	
	; Copy the data from our stack to the old stack stored away in some
	; memory block.  This will be copied back onto our stack by
	; ThreadReturnStackSpace.
	push	si			; PUSH	; si now pointer to the
	mov	si, sp				; place on the stack where
	add	si, 2				; the data is
	
	push	ax, bx, cx, ds, di	; PUSH
	
	mov	bx, di
	call	MemLock				; ax <= locked seg of old stack
	mov	di, es:[grobjStackDataSize]	; load di with offset to 1st
						; word on old stack.
	segmov	ds, es				; ds <= dgroup
	mov	es, ax				; es <= segment of old stack blk
	
	mov	cx, es:[di].GOBSSD_dataSize	; initialize counter
	mov	ds:[grobjStackDataSize], cx	; save size in dgroup for later
	mov	bp, es:[di].GOBSSD_bpOffset
	add	di, bp				; es:di <= ptr to correct
						; position in old stack blk
	
	; TOTAL EXTRA ITEMS ON STACK BEFORE THE DATA:
	; si (2), ax, bx, cx, ds, si (10) == 12 bytes
	
	segmov	ds, ss				; ds:si <= ptr to data
	mov	si, sp
	add	si, 12				; si = stack AFTER registers
						; pushed above.
	
	shr	cx, 1
	rep	movsw				; copy words
	jnc	doneWithCopy			; if the data size was odd
	movsb					; than copy the extra byte

doneWithCopy:
	call	MemUnlock
	
NOFXIP<	segmov	es, <segment grobjStackSem>, ax	; es <= dgroup		>
FXIP<	mov	bx, handle dgroup					>
FXIP<	call	MemDerefES			; es = dgroup		>
	
	; Restore caller's registers.
	pop	ax, bx, cx, ds, di	
	pop	si
	
	add	sp, es:[grobjStackDataSize]	; deallocate data
	
	; Stack *SHOULD* now be empty (just the StackFooter should remain).
	; TheadReturnStackSpace will check this (EC).
	call	ThreadReturnStackSpace
	
	; bp contains the offset from sp.. add sp back to get the real bp
	add	bp, sp	
	
	; Take off our additional data added to the old (now current) stack.
	add	sp, size GrObjBorrowStackSpaceData
	
	pushdw	es:[grobjStackReturnAddress]
	push	es:[grobjStackSavedES]
	VSem	es, grobjStackSem		; End CRITICAL SECTION
	
	pop	es				; restore es

	ret					; <<< RETURN (2 of 2)
GrObjReturnStackSpaceWithData	endp




GrObjMiscUtilsCode ends



GrObjRequiredCode	segment resource




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGlobalCheckForMetaTextMessages
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determines if passed message number is a MetaTextMessage

CALLED BY:	GLOBAL

PASS:		ax - message number

RETURN:		stc - is a MetaTextMessage
		clc - NOT

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			the message is not a MetaTextMessages
			the message number is greater than any MetaTextMessages

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	5/11/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGlobalCheckForMetaTextMessages		proc	far
	.enter

	cmp	ax,MetaTextMessages	;last MetaTextMessage + 1
	jb	checkFirst

done:
	.leave
	ret

checkFirst:
	cmp	ax,first MetaTextMessages
	cmc
	jmp	done
GrObjGlobalCheckForMetaTextMessages		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGlobalCheckForClassedMetaTextMessages
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determines if passed message number is a MetaTextMessage

CALLED BY:	GLOBAL

PASS:		cx - classed event handle

RETURN:		stc - is a MetaTextMessage
		clc - NOT

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			the message is not a MetaTextMessages
			the message number is greater than any MetaTextMessages

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	5/11/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGlobalCheckForClassedMetaTextMessages		proc	far
	uses	ax,bx,cx,si
	.enter

	mov	bx,cx			;event handle
	call	ObjGetMessageInfo
	cmp	ax,MetaTextMessages	;last MetaTextMessage + 1
	jb	checkFirst

done:
	.leave
	ret

checkFirst:
	cmp	ax,first MetaTextMessages
	cmc
	jmp	done
GrObjGlobalCheckForClassedMetaTextMessages		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGlobalCheckForClassedMetaStylesMessages
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determines if passed message number is a MetaStylesMessage

CALLED BY:	GLOBAL

PASS:		cx - classed event handle

RETURN:		stc - is a MetaStylesMessage
		clc - NOT

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			the message is not a MetaStylesMessages
			the message number is greater than any MetaStylesMessages

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	5/11/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGlobalCheckForClassedMetaStylesMessages		proc	far
	uses	ax,bx,cx,si
	.enter

	mov	bx,cx			;event handle
	call	ObjGetMessageInfo
	cmp	ax,MetaStylesMessages	;last MetaStylesMessage + 1
	jb	checkFirst

done:
	.leave
	ret

checkFirst:
	cmp	ax,first MetaStylesMessages
	cmc
	jmp	done
GrObjGlobalCheckForClassedMetaStylesMessages		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGlobalCheckForMetaSearchSpellMessages
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determines if passed message number is a MetaSearchSpellMessage

CALLED BY:	GLOBAL

PASS:		ax - message number

RETURN:		stc - is a MetaSearchSpellMessage
		clc - NOT

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			the message is not a MetaSearchSpellMessages
			the message number is greater than any MetaSearchSpellMessages

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	5/11/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGlobalCheckForMetaSearchSpellMessages		proc	far
	.enter

	cmp	ax,MetaSearchSpellMessages	;last MetaSearchSpellMessage + 1
	jb	checkFirst

done:
	.leave
	ret

checkFirst:
	cmp	ax,first MetaSearchSpellMessages
	cmc
	jmp	done
GrObjGlobalCheckForMetaSearchSpellMessages		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGlobalCheckForMetaSuspendUnsuspendMessages
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determines if passed message number is
		MSG_META_SUSPEND or MSG_META_UNSUSPEND

CALLED BY:	GLOBAL

PASS:		ax - message number

RETURN:		stc - is MSG_META_SUSPEND or MSG_META_UNSUSPEND

DESTROYED:	nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	11/ 1/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGlobalCheckForMetaSuspendUnsuspendMessages	proc	far
	.enter

	cmp	ax,MSG_META_SUSPEND
	je	done				; carry is clear
	cmp	ax,MSG_META_UNSUSPEND
	je	done				; carry is clear

	stc
done:
	cmc

	.leave
	ret


GrObjGlobalCheckForMetaSuspendUnsuspendMessages	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGlobalAddVMChainUndoAction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a vm chain undo action.
		
		
CALLED BY:	INTERNAL UTILITY

PASS:		
		ax - message to perform undo
		di - message to perform freeing undo action
		dx - db group or 0
		cx - db item or vm block handle
		bp - vm file handle
		bx - AddUndoActionFlags

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/ 3/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGlobalAddVMChainUndoAction		proc	far
	uses	ax,bx,cx,dx,di,bp
	.enter

EC <	call	ECGrObjCheckLMemObject			>

	sub	sp,size AddUndoActionStruct
	push	bp					;vm file
	mov	bp,sp
	add	bp,2					;offset of AddUndoAction
	pop	ss:[bp].AUAS_data.UAS_data.UADU_vmChain.UADVMC_file 
	mov	({GrObjUndoAppType}ss:[bp].AUAS_data.UAS_appType).\
						GOUAT_freeMessage,di
	mov	({GrObjUndoAppType}ss:[bp].AUAS_data.UAS_appType).\
						GOUAT_undoMessage,ax
	mov	ss:[bp].AUAS_data.UAS_dataType,UADT_VM_CHAIN
	mov	ss:[bp].AUAS_data.UAS_data.UADU_vmChain.UADVMC_vmChain.low,cx 
	mov	ss:[bp].AUAS_data.UAS_data.UADU_vmChain.UADVMC_vmChain.high,dx 
	mov	ss:[bp].AUAS_flags, bx			
	mov	bx,ds:[LMBH_handle]
	mov	ss:[bp].AUAS_output.handle,bx
	mov	ss:[bp].AUAS_output.chunk,si
	mov	di,mask MF_FIXUP_DS
	call	GeodeGetProcessHandle
	mov	ax,MSG_GEN_PROCESS_UNDO_ADD_ACTION
	call	ObjMessage
	add	sp,size AddUndoActionStruct

	.leave
	ret
GrObjGlobalAddVMChainUndoAction		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGlobalAddFlagsUndoAction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a flags undo action.
		

CALLED BY:	INTERNAL UTILITY

PASS:		
		*ds:si - object
		ax - message to perform undo
		di - message to perform freeing undo action
		dx - high word of flags
		cx - low word of flags
		bp - extra word of flags
		bx - AddUndoActionFlags

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/ 3/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGlobalAddFlagsUndoAction		proc	far
	uses	ax,bx,cx,dx,di,bp
	.enter

EC <	call	ECCheckObject			>

	sub	sp,size AddUndoActionStruct
	push	bp					;extra high word
	mov	bp,sp
	add	bp,2					;offset of AddUndoAction
	pop	ss:[bp].AUAS_data.UAS_data.UADU_flags.UADF_extraFlags
	mov	ss:[bp].AUAS_data.UAS_dataType,UADT_FLAGS
	mov	({GrObjUndoAppType}ss:[bp].AUAS_data.UAS_appType).\
						GOUAT_freeMessage,di
	mov	({GrObjUndoAppType}ss:[bp].AUAS_data.UAS_appType).\
						GOUAT_undoMessage,ax
	mov	ss:[bp].AUAS_data.UAS_data.UADU_flags.UADF_flags.low,cx 
	mov	ss:[bp].AUAS_data.UAS_data.UADU_flags.UADF_flags.high,dx 
	mov	ss:[bp].AUAS_flags, bx			
	mov	bx,ds:[LMBH_handle]
	mov	ss:[bp].AUAS_output.handle,bx
	mov	ss:[bp].AUAS_output.chunk,si
	mov	di,mask MF_FIXUP_DS
	call	GeodeGetProcessHandle
	mov	ax,MSG_GEN_PROCESS_UNDO_ADD_ACTION
	call	ObjMessage
	add	sp,size AddUndoActionStruct

	.leave
	ret
GrObjGlobalAddFlagsUndoAction		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGlobalStartUndoChainNoText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start an undo chain with no text string

CALLED BY:	INTERNAL UTILITY

PASS:		*ds:si - object

RETURN:		
		clc - if not ignoring
		stc - if ignorning - chain was not started

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/ 6/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGlobalStartUndoChainNoText		proc	far
	uses	cx,dx
	.enter

	clrdw	cxdx
	call	GrObjGlobalStartUndoChain

	.leave
	ret

GrObjGlobalStartUndoChainNoText		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGlobalStartUndoChain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start an undo chain for this object. Even if actions are
		being ignored must still start the chain. Otherwise I
		might end up with unbalanced start/ends.
PASS:		
		*(ds:si) - instance data of object

		cx:dx - optr of undo text string

RETURN:		
		clc - if not ignoring
		stc - if ignorning - 
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/ 3/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGlobalStartUndoChain	proc	far
	uses	ax,bx,cx,dx,bp,di
	.enter

EC <	call	ECCheckObject				>

	sub	sp,size StartUndoChainStruct
	mov	bp,sp
	movdw	ss:[bp].SUCS_title,cxdx
	mov	dx,ds:[LMBH_handle]
	mov	ss:[bp].SUCS_owner.handle,dx
	mov	ss:[bp].SUCS_owner.chunk,si
	call	GeodeGetProcessHandle
	mov	dx,size StartUndoChainStruct
	mov	di,mask MF_FIXUP_DS or mask MF_STACK
	mov	ax,MSG_GEN_PROCESS_UNDO_START_CHAIN
	call	ObjMessage
	add	sp,size StartUndoChainStruct	;implied clc

	call	GenProcessUndoCheckIfIgnoring
	tst	ax
	jnz	fail
	clc	
done:

	.leave
	ret

fail:
	stc
	jmp	done

GrObjGlobalStartUndoChain		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGlobalEndUndoChain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	End undo chain. Must always end undo chain even if
		ignoring. If this wasn't done then would get unbalanced
		start/end chains. Particularly when overflowing the
		undo action table which automatically switches to
		ignore, potentially between a start and end chain.

PASS:		nothing

RETURN:		
		nothing
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/ 3/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGlobalEndUndoChain		proc 	far
	uses	ax,bx,cx,dx,bp,di
	.enter

	mov	cx,sp					;non zero
	call	GeodeGetProcessHandle
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_GEN_PROCESS_UNDO_END_CHAIN
	call	ObjMessage

	.leave
	ret
GrObjGlobalEndUndoChain		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGlobalAllocUndoDBItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	    Alloc db item for storing undo item


CALLED BY:	INTERNAL UTILITY

PASS:		cx - size of db item

RETURN:		
		ax - group
		di - item
		bx - undo vm file 

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	7/30/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGlobalAllocUndoDBItem		proc	far
	uses	dx,bp
	.enter

	mov	di,mask MF_FIXUP_DS or mask MF_CALL
	call	GeodeGetProcessHandle
	push	cx					;size
	mov	ax,MSG_GEN_PROCESS_UNDO_GET_FILE
	call	ObjMessage
	pop	cx					;size
	mov	bx,ax					;undo file handle
	mov	ax,DB_UNGROUPED
	call	DBAlloc

	.leave
	ret
GrObjGlobalAllocUndoDBItem		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGlobalUndoIgnoreActions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send MSG_GEN_PROCESS_UNDO_IGNORE_ACTIONS to the 
		process

CALLED BY:	INTERNAL UTILITY

PASS:		nothing

RETURN:		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/ 6/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGlobalUndoIgnoreActions		proc	far
	uses	ax,bx,cx,dx,bp,di
	.enter

	clr	cx				;don't flush
	mov	di, mask MF_FIXUP_DS
	call	GeodeGetProcessHandle
	mov	ax,MSG_GEN_PROCESS_UNDO_IGNORE_ACTIONS
	call	ObjMessage

	.leave
	ret
GrObjGlobalUndoIgnoreActions		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGlobalUndoAcceptActions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send MSG_GEN_PROCESS_UNDO_ACCEPT_ACTIONS to the 
		process. Don't flush undo chain.

CALLED BY:	INTERNAL UTILITY

PASS:		nothing

RETURN:		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/ 6/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGlobalUndoAcceptActions		proc	far
	uses	ax,cx,dx,bx,bp,di
	.enter

	mov	di, mask MF_FIXUP_DS
	call	GeodeGetProcessHandle
	mov	ax,MSG_GEN_PROCESS_UNDO_ACCEPT_ACTIONS
	call	ObjMessage

	.leave
	ret
GrObjGlobalUndoAcceptActions		endp

GrObjRequiredCode	ends

GrObjDrawCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjGlobalGetVMFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Returns the vm file handle of the passed segment

Pass:		ds - segment

Return:		bx - vm file handle

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Apr 20, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGlobalGetVMFile	proc	far
	uses	ax
	.enter

	mov	bx,ds:[LMBH_handle]		
	mov	ax, MGIT_OWNER_OR_VM_FILE_HANDLE
	call	MemGetInfo		
	mov_tr	bx, ax

	.leave
	ret
GrObjGlobalGetVMFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjIsRectDWordOverlappingRectDWord?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determines if one RectDWord is overlapping another.

CALLED BY:	INTERNAL

PASS:		
		ds:si - RectDWord
		es:di - RectDWord

RETURN:		
		stc - yes
		clc - no

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/30/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjIsRectDWordOverlappingRectDWord?		proc	far
	uses	ax,bx
	.enter

	;    If left of one rect is greater than or equal to right
	;    of other rect then not overlapping
	;

	mov	ax,ds:[si].RD_left.low
	mov	bx,ds:[si].RD_left.high
	jgeDW	bx,ax,es:[di].RD_right.high,es:[di].RD_right.low,notOverlapping

	mov	ax,es:[di].RD_left.low
	mov	bx,es:[di].RD_left.high
	jgeDW	bx,ax,ds:[si].RD_right.high,ds:[si].RD_right.low,notOverlapping

	;    If top of one rect is greater than or equal to bottom
	;    of other rect then not overlapping
	;

	mov	ax,ds:[si].RD_top.low
	mov	bx,ds:[si].RD_top.high
	jgeDW	bx,ax,es:[di].RD_bottom.high,es:[di].RD_bottom.low,\
								notOverlapping

	mov	ax,es:[di].RD_top.low
	mov	bx,es:[di].RD_top.high
	jgeDW	bx,ax,ds:[si].RD_bottom.high,ds:[si].RD_bottom.low,\
								notOverlapping
	stc
done:
	.leave
	ret

notOverlapping:
	clc
	jmp	short	done

GrObjIsRectDWordOverlappingRectDWord?		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGlobalCombineRectWWFixedWithPointWWFixed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Increase size of RectWWFixed to include the passed point

CALLED BY:	INTERNAL

PASS:		
		ds:si - Ordered RectWWFixed
		es:di - PointWWFixed

RETURN:		
		RectWWFixed potentially expanded

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/ 9/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGlobalCombineRectWWFixedWithPointWWFixed		proc	far
	uses	ax,bx,cx
	.enter

	;    If x of point is less than left of rect, then jump to set
	;    new left
	;

	movwwf	bxax,es:[di].PF_x
	jlwwf	bxax, ds:[si].RWWF_left,newLeft

	;    If x of point is greater than right of rect, then jump to set
	;    new right
	;

	jgwwf	bxax, ds:[si].RWWF_right,newRight

checkTopBottom:
	;    If y of point is less than top of rect, then jump to set
	;    new top
	;

	movwwf	bxax,es:[di].RWWF_top
	jlwwf	bxax, ds:[si].RWWF_top,newTop

	;    If y of point is greater than bottom of rect, then jump to set
	;    new bottom
	;

	jgwwf	bxax, ds:[si].RWWF_bottom,newBottom

done:
	.leave
	ret

newLeft:
	movwwf	ds:[si].RWWF_left,bxax
	jmp	checkTopBottom

newRight:
	movwwf	ds:[si].RWWF_right,bxax
	jmp	checkTopBottom


newTop:
	movwwf	ds:[si].RWWF_top,bxax
	jmp	done

newBottom:
	movwwf	ds:[si].RWWF_bottom,bxax
	jmp	done


GrObjGlobalCombineRectWWFixedWithPointWWFixed		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGlobalInitRectWWFixedWithPointWWFixed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the top,left and bottom, right of the
		RectDWord to the passed PointWWFixed

CALLED BY:	INTERNAL

PASS:		
		ds:si - RectWWFixed
		es:di - PointWWFixed

RETURN:		
		ds:si - RectDWord - initialized

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/12/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGlobalInitRectWWFixedWithPointWWFixed		proc	far
	uses	cx,di,si,ds,es
	.enter

	push	ds				;Rect seg
	push	es				;Point seg
	pop	ds				;Source seg
	pop	es				;Dest seg
	xchg	di,si				;di <- dest offset
						;si <- source offset

	;    Copy point to left,top
	;

	mov	cx,size PointWWFixed/2
	rep	movsw

	;    Copy point to right, bottom

	sub	si,size PointWWFixed		;source offset
	mov	cx,size PointWWFixed/2
	rep	movsw

	.leave
	ret
GrObjGlobalInitRectWWFixedWithPointWWFixed		endp

GrObjDrawCode	ends


GrObjAlmostRequiredCode	segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGlobalExpandRectDWFixedByDWFixed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Increase size of RectDWFixed by DWFixed in each 
		direction

CALLED BY:	INTERNAL

PASS:		
		ds:si - Ordered RectDWFixed
		di:dx:cx - DWFixed
		
RETURN:		
		RectDWFixed potentially expanded

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/ 9/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGlobalExpandRectDWFixedByDWFixed		proc	far
	.enter

	SubDWF	ds:[si].RDWF_left, di,dx,cx
	SubDWF	ds:[si].RDWF_top, di,dx,cx

	AddDWF	ds:[si].RDWF_right, di,dx,cx
	AddDWF	ds:[si].RDWF_bottom, di,dx,cx

	.leave
	ret

GrObjGlobalExpandRectDWFixedByDWFixed		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGlobalGetWWFixedDimensionsFromRectDWFixed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate a WWFixed width and height of the 
		RectDWFixed. If either of the the dimensions
		won't fit in a WWFixed then return an error

CALLED BY:	INTERNAL

PASS:		
		ss:bp - ordered RectDWFixed

RETURN:		
		stc - both dimensions are WWFixed
			dx:cx - width
			bx:ax - height
		clc - one or both of dimensions is not WWFixed
			dx,cx,bx,ax - destroyed

DESTROYED:	
		see RETURN

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/ 9/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGlobalGetWWFixedDimensionsFromRectDWFixed		proc	far
	.enter

	MovDWF	cx,bx,ax, ss:[bp].RDWF_right
	SubDWF	cx,bx,ax, ss:[bp].RDWF_left

	tst	cx						
	jnz	error

	push	bx,ax					;width

	MovDWF	cx, bx, ax, ss:[bp].RDWF_bottom
	SubDWF	cx, bx, ax, ss:[bp].RDWF_top

	tst	cx						
	jnz	errorPop

	pop	dx,cx					;width

	stc

done:
	.leave
	ret

errorPop:
	add	sp,4
error:
	clc
	jmp	done

GrObjGlobalGetWWFixedDimensionsFromRectDWFixed		endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGlobalSetActionNotificationOutput
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Store the passed info in the var data of the
		passed object. Setting the output will clear
		any suspension.

CALLED BY:	Utility

PASS:		
		*ds:si -  object
		ax - vardata type
		cx:dx - optr
			passing cx=0 will clear the data


RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			passed handle is not zero

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	3/26/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGlobalSetActionNotificationOutput		proc	far
	uses	ax,bx,cx,di
	.enter

	mov	di,cx					;passed handle
	mov	cx,size GrObjActionNotificationStruct
	call	ObjVarAddData

	tst	di					;passed handle
	jz	clear

	mov	ds:[bx].GOANS_optr.handle,di
	mov	ds:[bx].GOANS_optr.chunk,dx

	;   We are storing an OD in the vardata so it must be
	;   relocated and unrelocted. Bad things will happen
	;   if the caller provides an OD that is not in the file
	;   or in a resource.
	;

	mov	ax,si					;body chunk		
	mov	bl, mask OCF_VARDATA_RELOC		;set
	clr	bh					;reset
	call	ObjSetFlags

done:
	.leave
	ret

clear:
	;    Free the data
	;

	call	ObjVarDeleteData
	jmp	done

GrObjGlobalSetActionNotificationOutput		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGlobalSuspendActionNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Increment the suspendCount in the 
		GrObjActionNotificationStruct in the vardata if it exists

CALLED BY:	Utility

PASS:		
		*ds:si - object
		ax - vardata type

RETURN:		
		nothing
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	3/26/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGlobalSuspendActionNotification		proc	far
	uses	bx,cx
	.enter

	call	ObjVarFindData
	jnc	done

	inc	ds:[bx].GOANS_suspendCount

done:
	.leave
	ret


GrObjGlobalSuspendActionNotification		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGlobalUnsuspendActionNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Decremnt the suspendCount in the 
		GrObjActionNotificationStruct in the vardata

CALLED BY:	Utility

PASS:		
		*ds:si - object
		ax - vardata type
	
RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	3/26/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGlobalUnsuspendActionNotification		proc	far
	uses	bx
	.enter

	;    If no data the bail
	;

	call	ObjVarFindData
	jnc	done

	;    If suspendedCount is already zero then bail
	;

	tst	ds:[bx].GOANS_suspendCount
	jz	done

	;    If the suspendedCount geos to zero see if the 
	;    data space can be freed up. 
	;

	dec	ds:[bx].GOANS_suspendCount
	jz	deleteData?

done:
	.leave
	ret

deleteData?:
	;    If the OD is clear then free up the space.
	;    This can happen if the action notification was 
	;    suspended and then unsuspend without any output 
	;    ever being set.

	tst	ds:[bx].GOANS_optr.handle
	jnz	done
	call	ObjVarDeleteData
	jmp	done

GrObjGlobalUnsuspendActionNotification		endp

GrObjAlmostRequiredCode	ends

GrObjInitCode	segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGlobalUpdateControllerLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Low-level routine to update a UI controller

CALLED BY:

PASS:		bx - Data block to send to controller, or 0 to send
		null data (on LOST_SELECTION) 
		cx - GenAppGCNListType
		dx - NotifyStandardNotificationTypes

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/30/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGlobalUpdateControllerLow	proc far
	uses	ax,bx,cx,dx,di,si,bp
	.enter

	; create the event

	call	MemIncRefCount			;one more reference
	push	bx, cx, si
	mov	ax, MSG_META_NOTIFY_WITH_DATA_BLOCK
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	bp, bx				; data block
	clr	bx, si
	mov	di, mask MF_RECORD
	call	ObjMessage			; di is event
	pop	bx, cx, si

	; Create messageParams structure on stack

	mov	dx, size GCNListMessageParams	; create stack frame
	sub	sp, dx
	mov	bp, sp
	mov	ss:[bp].GCNLMP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLMP_ID.GCNLT_type, cx
	push	bx				; data block
	mov	ss:[bp].GCNLMP_block, bx
	mov	ss:[bp].GCNLMP_event, di
	
	; If data block is null, then set the IGNORE flag, otherwise
	; just set the SET_STATUS_EVENT flag

	mov	ax,  mask GCNLSF_SET_STATUS
	tst	bx
	jnz	gotFlags
	ornf	ax, mask GCNLSF_IGNORE_IF_STATUS_TRANSITIONING
gotFlags:
	mov	ss:[bp].GCNLMP_flags, ax
	mov	ax, MSG_META_GCN_LIST_SEND
	clr	bx
	call	GeodeGetAppObject
	mov	di, mask MF_STACK or mask MF_FIXUP_DS
	call	ObjMessage
	pop	bx				; data block
	
	add	sp, size GCNListMessageParams	; fix stack
	call	MemDecRefCount			; we're done with it 
	.leave
	ret
GrObjGlobalUpdateControllerLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGlobalAllocNotifyBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate the block of memory that will be used to
		update the UI.

CALLED BY:

PASS:		bx - size to allocate

RETURN:		bx - block handle
		carry set if unable to allocate

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:
	Initialize to zero 	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/ 2/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGlobalAllocNotifyBlock	proc far
	uses	ax, cx
	.enter
	mov	ax, bx			; size
	mov	cx, ALLOC_DYNAMIC or mask HF_SHARABLE or \
			(mask HAF_ZERO_INIT) shl 8
	call	MemAlloc
	jc	done
	mov	ax, 1
	call	MemInitRefCount
	clc
done:
	.leave
	ret
GrObjGlobalAllocNotifyBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGlobalCombineRectDWFixedWithPointDWFixed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Increase size of RectDWFixed to include the passed point

CALLED BY:	INTERNAL

PASS:		
		ds:si - Ordered RectDWFixed
		es:di - PointDWFixed

RETURN:		
		RectDWFixed potentially expanded

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/ 9/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGlobalCombineRectDWFixedWithPointDWFixed		proc	far
	uses	ax,bx,cx
	.enter

	;    If x of point is less than left of rect, then jump to set
	;    new left
	;

	mov	ax,es:[di].PDF_x.DWF_frac
	mov	bx,es:[di].PDF_x.DWF_int.low
	mov	cx,es:[di].PDF_x.DWF_int.high
	jlDWF	cx,bx,ax, \
		ds:[si].RDWF_left.DWF_int.high,\
		ds:[si].RDWF_left.DWF_int.low,\
		ds:[si].RDWF_left.DWF_frac, \
		newLeft

	;    If x of point is greater than right of rect, then jump to set
	;    new right
	;

	jgDWF	cx,bx,ax, \
		ds:[si].RDWF_right.DWF_int.high,\
		ds:[si].RDWF_right.DWF_int.low,\
		ds:[si].RDWF_right.DWF_frac, \
		newRight

checkTopBottom:
	;    If y of point is less than top of rect, then jump to set
	;    new top
	;

	mov	ax,es:[di].PDF_y.DWF_frac
	mov	bx,es:[di].PDF_y.DWF_int.low
	mov	cx,es:[di].PDF_y.DWF_int.high
	jlDWF	cx,bx,ax, \
		ds:[si].RDWF_top.DWF_int.high,\
		ds:[si].RDWF_top.DWF_int.low,\
		ds:[si].RDWF_top.DWF_frac, \
		newTop

	;    If y of point is greater than bottom of rect, then jump to set
	;    new bottom
	;

	jgDWF	cx,bx,ax, \
		ds:[si].RDWF_bottom.DWF_int.high,\
		ds:[si].RDWF_bottom.DWF_int.low,\
		ds:[si].RDWF_bottom.DWF_frac, \
		newBottom

done:
	.leave
	ret

newLeft:
	mov	ds:[si].RDWF_left.DWF_int.high,cx
	mov	ds:[si].RDWF_left.DWF_int.low,bx
	mov	ds:[si].RDWF_left.DWF_frac,ax
	jmp	checkTopBottom

newRight:
	mov	ds:[si].RDWF_right.DWF_int.high,cx
	mov	ds:[si].RDWF_right.DWF_int.low,bx
	mov	ds:[si].RDWF_right.DWF_frac,ax
	jmp	checkTopBottom


newTop:
	mov	ds:[si].RDWF_top.DWF_int.high,cx
	mov	ds:[si].RDWF_top.DWF_int.low,bx
	mov	ds:[si].RDWF_top.DWF_frac,ax
	jmp	done

newBottom:
	mov	ds:[si].RDWF_bottom.DWF_int.high,cx
	mov	ds:[si].RDWF_bottom.DWF_int.low,bx
	mov	ds:[si].RDWF_bottom.DWF_frac,ax
	jmp	done


GrObjGlobalCombineRectDWFixedWithPointDWFixed		endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGlobalSetRectDWFixedFromFourPointDWFixeds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the RectDWFixed to surround the all the points
		in the FourPointDWFixeds structure

CALLED BY:	INTERNAL

PASS:		
		ds:si - RectDWFixed
		es:di - FourPointDWFixeds

RETURN:		
		ds:si - RectDWFixed

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/12/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGlobalSetRectDWFixedFromFourPointDWFixeds		proc	far
	.enter

	call	GrObjGlobalInitRectDWFixedWithPointDWFixed

	add	di,size PointDWFixed
	call	GrObjGlobalCombineRectDWFixedWithPointDWFixed
	add	di,size PointDWFixed
	call	GrObjGlobalCombineRectDWFixedWithPointDWFixed
	add	di,size PointDWFixed
	call	GrObjGlobalCombineRectDWFixedWithPointDWFixed

	.leave
	ret
GrObjGlobalSetRectDWFixedFromFourPointDWFixeds		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGlobalInitRectDWFixedWithPointDWFixed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the top,left and bottom, right of the
		RectDWFixed to the passed PointDWFixed

CALLED BY:	INTERNAL

PASS:		
		ds:si - RectDWFixed
		es:di - PointDWFixed

RETURN:		
		ds:si - RectDWFixed - initialized

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/12/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGlobalInitRectDWFixedWithPointDWFixed		proc	far
	uses	cx,di,si,ds,es
	.enter

	push	ds				;Rect seg
	push	es				;Point seg
	pop	ds				;Source seg
	pop	es				;Dest seg
	xchg	di,si				;di <- dest offset
						;si <- source offset

	;    Copy point to left,top
	;

	mov	cx,size PointDWFixed/2
	rep	movsw

	;    Copy point to right, bottom

	sub	si,size PointDWFixed		;source offset
	mov	cx,size PointDWFixed/2
	rep	movsw

	.leave
	ret
GrObjGlobalInitRectDWFixedWithPointDWFixed		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGlobalInitGrObjTransMatrix
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize a GrObjTransMatrix to 
		10
		01

CALLED BY:	INTERNAL UTILITY

PASS:		
		ds:si - GrObjTransMatrix

RETURN:		
		ds:si - GrObjTransMatrix inited

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/ 1/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGlobalInitGrObjTransMatrix		proc	far
	uses	ax
	.enter

	clr	ax
	mov	ds:[si].GTM_e11.WWF_int,1
	mov	ds:[si].GTM_e22.WWF_int,1
	mov	ds:[si].GTM_e12.WWF_int,ax
	mov	ds:[si].GTM_e21.WWF_int,ax
	mov	ds:[si].GTM_e11.WWF_frac,ax
	mov	ds:[si].GTM_e12.WWF_frac,ax
	mov	ds:[si].GTM_e21.WWF_frac,ax
	mov	ds:[si].GTM_e22.WWF_frac,ax

	.leave
	ret
GrObjGlobalInitGrObjTransMatrix		endp

GrObjInitCode	ends





GrObjVisGuardianCode	segment resource

GrObjGlobalMouseMessageList	label	word
	word	MSG_GO_LARGE_PTR
	word	MSG_GO_LARGE_START_SELECT
	word	MSG_GO_LARGE_DRAG_SELECT
	word	MSG_GO_LARGE_END_SELECT
	word	MSG_GO_LARGE_START_MOVE_COPY
	word	MSG_GO_LARGE_DRAG_MOVE_COPY
	word	MSG_GO_LARGE_END_MOVE_COPY
GrObjGlobalMouseMessageListEnd label word

SystemLargeMouseMessageList	label	word
	word	MSG_META_LARGE_PTR
	word	MSG_META_LARGE_START_SELECT
	word	MSG_META_LARGE_DRAG_SELECT
	word	MSG_META_LARGE_END_SELECT
	word	MSG_META_LARGE_START_MOVE_COPY
	word	MSG_META_LARGE_DRAG_MOVE_COPY
	word	MSG_META_LARGE_END_MOVE_COPY
SystemLargeMouseMessageListEnd label word

SystemSmallMouseMessageList	label	word
	word	MSG_META_PTR
	word	MSG_META_START_SELECT
	word	MSG_META_DRAG_SELECT
	word	MSG_META_END_SELECT
	word	MSG_META_START_MOVE_COPY
	word	MSG_META_DRAG_MOVE_COPY
	word	MSG_META_END_MOVE_COPY
SystemSmallMouseMessageListEnd label word



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGlobalConvertSystemMouseMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Converts System Mouse Message to a GrObj Mouse Message

CALLED BY:	INTERNAL

PASS:		
		cx - system mouse message

RETURN:		
		ax - grobj message

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	12/ 7/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGlobalConvertSystemMouseMessage		proc	far
	uses cx,di,es
	.enter

	;    Try to find message in large system list
	;

	segmov	es,cs,ax
	mov_tr	ax,cx
	mov	di, offset SystemLargeMouseMessageList
	mov	cx, 	(SystemLargeMouseMessageListEnd - \
			 SystemLargeMouseMessageList) / 2
	repne	scasw
	jnz	trySmall

	;     Extract grobj message using large system list offset
	;

	add	di,	( offset GrObjGlobalMouseMessageList - \
			offset SystemLargeMouseMessageList - 2 )
done:
	mov	ax,es:[di]

	.leave
	ret

trySmall:
	mov	di, offset SystemSmallMouseMessageList
	mov	cx, 	(SystemSmallMouseMessageListEnd - \
			 SystemSmallMouseMessageList) / 2
	repne	scasw
EC <	ERROR_NZ	NOT_A_SYSTEM_MOUSE_MESSAGE			>

	;     Extract grobj message using small system list offset
	;

	add	di,	( offset GrObjGlobalMouseMessageList - \
			offset SystemSmallMouseMessageList - 2 )
	jmp	done

GrObjGlobalConvertSystemMouseMessage		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjConvertGrObjMouseMessageToLarge
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Converts GrObj Mouse Message to a Large System Mouse Message

CALLED BY:	INTERNAL

PASS:		
		cx - grobj mouse message

RETURN:		
		ax - system message

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	12/ 7/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjConvertGrObjMouseMessageToLarge		proc	far
	uses cx,di,es
	.enter

	;    Find message in grobj list
	;

	segmov	es,cs,ax
	mov	di, offset GrObjGlobalMouseMessageList
	mov	ax,cx
	mov	cx, (GrObjGlobalMouseMessageListEnd-GrObjGlobalMouseMessageList)/2
	repne	scasw
EC <	ERROR_NZ	NOT_A_GROBJ_MOUSE_MESSAGE			>

	;     Extract system message using grobj list offset
	;

	add	di,	( offset SystemLargeMouseMessageList - \
			offset GrObjGlobalMouseMessageList - 2 )
	mov	ax,es:[di]

	.leave
	ret

GrObjConvertGrObjMouseMessageToLarge		endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjConvertGrObjMouseMessageToSmall
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Converts GrObj Mouse Message to a Small System Mouse Message

CALLED BY:	INTERNAL

PASS:		
		cx - grobj mouse message

RETURN:		
		ax - system message

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	12/ 7/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjConvertGrObjMouseMessageToSmall		proc	far
	uses cx,di,es
	.enter

	;    Find message in grobj list
	;

	segmov	es,cs,ax
	mov	di, offset GrObjGlobalMouseMessageList
	mov	ax,cx
	mov	cx, (GrObjGlobalMouseMessageListEnd-GrObjGlobalMouseMessageList)/2
	repne	scasw
EC <	ERROR_NZ	NOT_A_GROBJ_MOUSE_MESSAGE			>

	;     Extract system message using grobj list offset
	;

	add	di,	( offset SystemSmallMouseMessageList - \
			offset GrObjGlobalMouseMessageList - 2 )
	mov	ax,es:[di]

	.leave
	ret

GrObjConvertGrObjMouseMessageToSmall		endp

GrObjVisGuardianCode	ends





GrObjRequiredExtInteractive2Code	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGlobalCheckForPointOverAHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if point is over a handle of a selected object

CALLED BY:	INTERNAL UTILITY

PASS:		
		*(ds:si) - instance data of object

		ss:bp - PointDWFixed
		ax - message to use
			MSG_GO_EVALUATE_PARENT_POINT_FOR_HANDLE
			MSG_GO_EVALUATE_PARENT_POINT_FOR_HANDLE_MOVE_RESIZE
			MSG_GO_EVALUATE_PARENT_POINT_FOR_HANDLE_MOVE_ROTATE


RETURN:		
		stc - if over a handle
			al - GrObjHandleSpecification
			first object in priority list is the object 
			that had its handle hit
		clc - not over a handle
			al - destroyed

DESTROYED:	
		ah, see RETURN

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/26/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGlobalCheckForPointOverAHandle	proc far
	uses	cx,dx,di
	.enter

	call	GrObjGlobalGetChildrenWithHandleHit

	mov	ax,MSG_GB_PRIORITY_LIST_GET_NUM_ELEMENTS
	mov	di,mask MF_CALL or mask MF_FIXUP_DS
	call	GrObjGlobalMessageToBody
	jz	fail				;jmp if no body
	tst	cx
	jnz	hit
fail:
	clc
done:
	.leave
	ret

hit:
	;    Get handle hit from data in priority list
	;

	clr	cx				;first child
	mov	ax,MSG_GB_PRIORITY_LIST_GET_ELEMENT
	mov	di,mask MF_CALL or mask MF_FIXUP_DS
	call	GrObjGlobalMessageToBody
	jz	fail				;jmp if no body
	mov	al,ah					;GrObjHandleSpec
	stc
	jmp	done

GrObjGlobalCheckForPointOverAHandle		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGlobalGetChildrenWithHandleHit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fill prioirty list with list of children whose handle
		was hit by point.
		
CALLED BY:	INTERNAL

PASS:		
		*(ds:si) - GrObj or GrObjBody
		ss:bp - PointDWFixed
		ax - message to use
			MSG_GO_EVALUATE_PARENT_POINT_FOR_HANDLE
			MSG_GO_EVALUATE_PARENT_POINT_FOR_HANDLE_MOVE_RESIZE
			MSG_GO_EVALUATE_PARENT_POINT_FOR_HANDLE_MOVE_ROTATE


RETURN:		
		PriorityList changed

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/25/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGlobalGetChildrenWithHandleHit		proc	far
	class	GrObjClass
	uses	cx,dx
	.enter

EC <	call	ECCheckLMemObject	>

	mov	cx, 1
	mov	dl, mask PLI_ONLY_PROCESS_SELECTED or \
			mask PLI_STOP_AT_FIRST_HIGH or \
			mask PLI_ONLY_INSERT_HIGH or \
			mask PLI_CHECK_SELECTION_HANDLE_BOUNDS

	call	GrObjGlobalInitAndFillPriorityListNoClass

	.leave
	ret
GrObjGlobalGetChildrenWithHandleHit		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGlobalCheckForPointOverBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if point is over the bounds of any grobjects

CALLED BY:	INTERNAL UTILITY

PASS:		
		*(ds:si) - instance data of object

		ss:bp - PointDWFixed

RETURN:		
		stc - yes
		clc - no

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/26/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGlobalCheckForPointOverBounds	proc far
	uses	ax,cx,dx,di
	.enter

	call	GrObjGlobalGetChildrenBoundingPoint

	mov	ax,MSG_GB_PRIORITY_LIST_GET_NUM_ELEMENTS
	mov	di,mask MF_CALL or mask MF_FIXUP_DS
	call	GrObjGlobalMessageToBody
	jz	miss				;jmp if no body
	jcxz	miss

	stc
done:
	.leave
	ret

miss:
	clc
	jmp	done

GrObjGlobalCheckForPointOverBounds		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGlobalGetChildrenBoundingPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fill prioirty list with list of children whose 
		bounds surround point
		
CALLED BY:	INTERNAL

PASS:		
		*(ds:si) - GrObj or GrObjBody
		ss:bp - PointDWFixed

RETURN:		
		PriorityList changed

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/25/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGlobalGetChildrenBoundingPoint		proc	far
	class	GrObjClass
	uses	ax,cx,dx
	.enter

EC <	call	ECCheckLMemObject	>

	mov	ax, PRIORITY_LIST_EVALUATE_PARENT_POINT_FOR_BOUNDS
	mov	cx, 1
	mov	dl, mask PLI_STOP_AT_FIRST_HIGH

	call	GrObjGlobalInitAndFillPriorityListNoClass

	.leave
	ret
GrObjGlobalGetChildrenBoundingPoint		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGlobalInitAndFillPriorityListNoClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize PriorityList and send message to body
		to fill it with objects

CALLED BY:	INTERNAL UTILITY

PASS:		
		*(ds:si) - GrObj or GrObjBody
		ss:bp - PointDWFixed
		ax - method
		cx - max elements
		dl - PriorityListInstructions

RETURN:		
		PriorityListChanged
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	6/10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGlobalInitAndFillPriorityListNoClass		proc	far
	uses	bx,di
	.enter

EC <	call	ECCheckLMemObject	>

	clr	bx,di
	call	GrObjGlobalInitAndFillPriorityList

	.leave
	ret
GrObjGlobalInitAndFillPriorityListNoClass		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGlobalInitAndFillPriorityList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize PriorityList and send message to body
		to fill it with objects

CALLED BY:	INTERNAL UTILITY
PASS:		
		*(ds:si) - GrObj or GrObjBody
		ss:bp - PointDWFixed
		ax - method
		cx - max elements
		dl - PriorityListInstructions
		bx:di - class

RETURN:		
		PriorityListChanged
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	6/10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGlobalInitAndFillPriorityList		proc	far
	uses	ax,bx,cx,dx,bp
	.enter

EC <	call	ECCheckLMemObject	>


	;    Fill priority list init structure with necessary 
	;    access information
	;

	push	bx,di					;class into stack frame
	sub	sp, size PLInit-4
	mov	bx,bp					;orig stack frame
	mov	bp,sp
	mov	ss:[bp].PLI_message, ax
	mov	ss:[bp].PLI_maxElements, cx
	mov	ss:[bp].PLI_instructions, dl
	mov	ax,ss:[bx].PDF_x.DWF_int.high
	mov	ss:[bp].PLI_point.PDF_x.DWF_int.high,ax
	mov	ax,ss:[bx].PDF_x.DWF_int.low
	mov	ss:[bp].PLI_point.PDF_x.DWF_int.low,ax
	mov	ax,ss:[bx].PDF_x.DWF_frac
	mov	ss:[bp].PLI_point.PDF_x.DWF_frac,ax
	mov	ax,ss:[bx].PDF_y.DWF_int.high
	mov	ss:[bp].PLI_point.PDF_y.DWF_int.high,ax
	mov	ax,ss:[bx].PDF_y.DWF_int.low
	mov	ss:[bp].PLI_point.PDF_y.DWF_int.low,ax
	mov	ax,ss:[bx].PDF_y.DWF_frac
	mov	ss:[bp].PLI_point.PDF_y.DWF_frac,ax


	;    Point cx:dx at PLInit structure that is on stack
	;

	mov	cx,ss
	mov	dx,bp

	;    Send grup to initialize priority list, then clear
	;    stack of PLInit structure and reset bp to original stack frame
	;

	mov	ax,MSG_GB_PRIORITY_LIST_INIT
	mov	di,mask MF_CALL or mask MF_FIXUP_DS
	call	GrObjGlobalMessageToBody
	add	sp, size PLInit

	;    Send method to build the list
	;

	mov	ax,MSG_GB_FILL_PRIORITY_LIST
	mov	di,mask MF_CALL or mask MF_FIXUP_DS
	call	GrObjGlobalMessageToBody


	.leave
	ret
GrObjGlobalInitAndFillPriorityList		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGlobalMessageToBody
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends a message to the body from either the body
		or from a grobject.

CALLED BY:	INTERNAL UTILITY

PASS:		*ds:si - GrObj or GrObjBody
		ax - message
		cx,dx,bp - message data
		di - MessageFlags

RETURN:		
		if no body return
			zero flag set
		else
			zero flag cleared
			if MF_CALL
				ax,cx,dx,bp
				no flags except carry
			otherwise 
				nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/ 2/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGlobalMessageToBody		proc	far
	uses	bx,es
	.enter

EC <	call	ECCheckLMemObject			>

	push	di				;MessageFlags
	mov	di, segment GrObjBodyClass
	mov	es,di
	mov	di, offset GrObjBodyClass
	call	ObjIsObjectInClass
	pop	di				;MessageFlags
	jc	body

	call	GrObjMessageToBody

done:
	.leave
	ret

body:
	ornf	di,mask MF_FIXUP_DS
	mov	bx,ds:[LMBH_handle]
	call	ObjMessage
	ClearZeroFlagPreserveCarry	bx
	jmp	done

GrObjGlobalMessageToBody		endp

GrObjRequiredExtInteractive2Code	ends
