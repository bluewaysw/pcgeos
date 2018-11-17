COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	GrObj
MODULE:		GrObj
FILE:		grobjDraw.asm

AUTHOR:		Steve Scholl, Aug 21, 1992

ROUTINES:
	Name		
	----		
	GrObjCanDraw?
	GrObjApplyIncreaseResolutionScaleFactor
	GrObjCalcIncreasedResolutionCorners
	GrObjCalcCorners
	GrObjDrawBG	

METHODS:
	Name
	----
	GrObjDraw
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Steve	8/21/92		Initial revision


DESCRIPTION:
	
		

	$Id: grobjDraw.asm,v 1.1 97/04/04 18:07:25 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrObjDrawCode 	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjCanDraw?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if object can draw

CALLED BY:	INTERNAL (UTILITY)

PASS:		*ds:si - GrObj
		cl - DrawFlags
		dx - GrObjDrawFlags

RETURN:		
		stc - yes
		clc - no

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			object can draw its selection handles

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjCanDraw?		proc	far
	class	GrObjClass
	uses	ax,di,cx
	.enter

EC <	call	ECGrObjCheckLMemObject					>

	GrObjDeref	di,ds,si
	test	ds:[di].GOI_optFlags, mask GOOF_ATTRIBUTE_MANAGER
	jnz	fail

	test	ds:[di].GOI_optFlags, mask GOOF_GROBJ_INVALID
	jnz	fail

	tst	ds:[di].GOI_normalTransform
	jz	fail

	test	ds:[di].GOI_locks,mask GOL_DRAW
	jnz	fail

	test	ds:[di].GOI_locks,mask GOL_SHOW
	jnz	fail

	test	dx, mask GODF_DRAW_INSTRUCTIONS
	jz	noInstructions

checkWrap:
	test	dx, mask GODF_DRAW_WRAP_TEXT_INSIDE_ONLY
	jnz	wrapInsideOnly

	test	dx, mask GODF_DRAW_WRAP_TEXT_AROUND_ONLY
	jnz	wrapAroundOnly

	test	dx,mask GODF_DRAW_SELECTED_OBJECTS_ONLY
	jnz	selectedOnly

	test	cl,mask DF_PRINT
	jnz	printFlag

success:
	stc

done:
	.leave
	ret


selectedOnly:
	;    Objects in group do not have their selected bit set. 
	;    So we assume if an object in a group has received a
	;    message draw with GODF_DRAW_SELECTED_OBJECTS_ONLY set
	;    that the group was selected and that it is ok to draw.
	;

	test	ds:[di].GOI_optFlags, mask GOOF_IN_GROUP
	jnz	success
	test	ds:[di].GOI_tempState, mask GOTM_SELECTED
	jnz	success
	jmp	fail

noInstructions:
	test	ds:[di].GOI_attrFlags, mask GOAF_INSTRUCTION
	jz	checkWrap
	jmp	fail

printFlag:
	test	ds:[di].GOI_locks,mask GOL_PRINT
	jnz	fail
	test	dx, mask GODF_PRINT_INSTRUCTIONS
	jnz	success
	test	ds:[di].GOI_attrFlags, mask GOAF_INSTRUCTION
	jz	success
fail:
	clc
	jmp	done


wrapAroundOnly:
	mov	ax,ds:[di].GOI_attrFlags
	andnf	ax, mask GOAF_WRAP
	mov	cl, offset GOAF_WRAP
	shr	ax,cl
	cmp	ax, GOWTT_WRAP_AROUND_RECT
	je	success
	cmp	ax, GOWTT_WRAP_AROUND_TIGHTLY
	je	success
	jmp	fail

wrapInsideOnly:
	mov	ax,ds:[di].GOI_attrFlags
	andnf	ax, mask GOAF_WRAP
	mov	cl, offset GOAF_WRAP
	shr	ax,cl
	cmp	ax, GOWTT_WRAP_INSIDE
	je	success
	jmp	fail


GrObjCanDraw?		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws the background, foreground, line and area components
		of the grobject

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

		bp - GState with PARENT transformation in it.
		cl - DrawFlags
		dx - GrObjDrawFlags

RETURN:		
		nothing

DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SPEED over SMALL SIZE

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/16/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjDraw method dynamic GrObjClass, MSG_GO_DRAW
	class	GrObjClass
	.enter

	call	GrObjCanDraw?
	jnc	done

	mov	di,bp					;gstate
	test	dx,mask GODF_DRAW_CLIP_ONLY
	jnz	drawClip
	test	dx, mask GODF_DRAW_WRAP_TEXT_AROUND_ONLY
	jnz	wrapAround
	test	dx, mask GODF_DRAW_WRAP_TEXT_INSIDE_ONLY
	jnz	drawClip
	test	dx,mask GODF_DRAW_QUICK_VIEW
	jnz	quickView

drawNormal:
	call	GrSaveTransform
	call	GrObjApplyNormalTransform

	call	GrObjDrawDrawBackground
	call	GrObjDrawDrawForegroundArea
	call	GrObjDrawDrawForegroundLine

	call	GrRestoreTransform

done:
	.leave
	ret

wrapAround:
	call	GrObjDrawDrawWrapAround
	jmp	done

drawClip:
	call	GrObjDrawDrawClip
	jmp	done

quickView:
	call	GrObjDrawDrawQuickView
	jnc	drawNormal
	jmp	done


GrObjDraw		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjDrawDrawForegroundArea
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the area foreground

CALLED BY:	INTERNAL
		GrObjDraw

PASS:		*ds:si - object
		di - gstate with normal transform applied
		cl - DrawFlags
		dx - GrObjDrawFlags

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			GOMOF_DRAW_FG_AREA not set
			area mask is not null
			GrObjAreaAttrElementType is GOAAET_BASE

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/ 5/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjDrawDrawForegroundArea		proc	near
	class	GrObjClass
	uses	ax,bx,dx,bp
	.enter

EC <	call	ECGrObjCheckLMemObject			>

	;    Apply area attributes and get element type
	;    in one fell swoop
	;

	push	cx					;DrawFlags
	GrObjDeref	bx,ds,si
	mov	cx,ds:[bx].GOI_areaAttrToken
	sub	sp,size GrObjFullAreaAttrElement
	mov	bp,sp
	call	GrObjGetGrObjFullAreaAttrElement
	jnc	clearFrame
	mov	al,ss:[bp].GOBAAE_aaeType
	mov	ah,ss:[bp].GOGAAE_type
	mov	cl,ss:[bp].GOBAAE_mask
	call	GrObjApplyGrObjFullAreaAttrElement
	add	sp, size GrObjFullAreaAttrElement

	;    If GOMOF_DRAW_FG_AREA bit is set then skip
	;    check for a null mask
	;

	GrObjDeref	bx,ds,si
	test	ds:[bx].GOI_msgOptFlags,mask GOMOF_DRAW_FG_AREA
	mov	bl,cl					;area mask
	pop	cx					;DrawFlags
	jnz	checkType

	;    If mask is null then don't bother sending message
	;

	cmp	bl,SDM_0
	je	done

checkType:
	cmp	al, GOAAET_GRADIENT
	je	checkGradientType

drawBase:
	mov	ax,MSG_GO_DRAW_FG_AREA_HI_RES
	test	dx, mask GODF_DRAW_WITH_INCREASED_RESOLUTION 
	jnz	drawFGArea
	mov	ax,MSG_GO_DRAW_FG_AREA
drawFGArea:
	call	GrSaveTransform
	mov	bp,dx					;GrObjDrawFlags
	mov	dx,di					;gstate
	call	ObjCallInstanceNoLock
	call	GrRestoreTransform
done:
	.leave
	ret

clearFrame:
	add	sp, size GrObjFullAreaAttrElement
	pop	cx					;DrawFlags
	jmp	done


checkGradientType:
	cmp	ah, GOGT_NONE
	je	drawBase

	mov	ax,MSG_GO_DRAW_FG_GRADIENT_AREA
	test	dx, mask GODF_DRAW_WITH_INCREASED_RESOLUTION 
	jz	drawFGArea
	mov	ax,MSG_GO_DRAW_FG_GRADIENT_AREA_HI_RES
	jmp	drawFGArea

GrObjDrawDrawForegroundArea		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjDrawDrawForegroundLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the line foreground

		NOTE: This routine expects to inherit the MixMode
		that was applied in GrObjDrawDrawForegroundArea	

CALLED BY:	INTERNAL
		GrObjDraw

PASS:		*ds:si - object
		di - gstate with normal transform applied
		cl - DrawFlags
		dx - GrObjDrawFlags

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			GOMOF_DRAW_FG_LINE not set
			line mask is not null

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/ 5/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjDrawDrawForegroundLine		proc	near
	class	GrObjClass
	uses	ax,bx,dx,bp
	.enter

EC <	call	ECGrObjCheckLMemObject			>

	;    Apply line attributes and get line mask
	;    in one fell swoop
	;

	push	cx					;DrawFlags
	GrObjDeref	bx,ds,si
	mov	cx,ds:[bx].GOI_lineAttrToken
	sub	sp,size GrObjFullLineAttrElement
	mov	bp,sp
	call	GrObjGetGrObjFullLineAttrElement
	jnc	clearFrame
	mov	al,ss:[bp].GOBLAE_laeType
	mov	ah,ss:[bp].GOBLAE_mask
	call	GrObjApplyGrObjFullLineAttrElement
	add	sp, size GrObjFullLineAttrElement
	pop	cx					;DrawFlags

	;    If GOMOF_DRAW_FG_LINE bit is set then skip
	;    check for a null mask
	;

	GrObjDeref	bx,ds,si
	test	ds:[bx].GOI_msgOptFlags,mask GOMOF_DRAW_FG_LINE
	jnz	drawBase

	;    If mask is null then don't bother sending message
	;

	cmp	ah,SDM_0
	je	done

drawBase:	
	mov	ax,MSG_GO_DRAW_FG_LINE_HI_RES
	test	dx, mask GODF_DRAW_WITH_INCREASED_RESOLUTION 
	jnz	drawFGLine
	mov	ax,MSG_GO_DRAW_FG_LINE
drawFGLine:
	call	GrSaveTransform
	mov	bp,dx					;GrObjDrawFlags
	mov	dx,di					;gstate
	call	ObjCallInstanceNoLock
	call	GrRestoreTransform

done:

	.leave
	ret

clearFrame:
	add	sp, size GrObjFullLineAttrElement
	pop	cx					;DrawFlags
	jmp	done

GrObjDrawDrawForegroundLine		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjDrawDrawWrapAround
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We need to draw the objects in GOWTT_WRAP_AROUND_RECT
		or GOWTT_WRAP_AND_TIGHTLY. Figure out which one
		and do the right thing

CALLED BY:	INTERNAL
		GrObjDraw
				
PASS:		
		*ds:si - object
		di - gstate
		cl - DrawFlags
		dx - GrObjDrawFlags

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
	srs	9/ 5/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjDrawDrawWrapAround		proc	near
	class	GrObjClass
	uses	ax,bx,cx,dx,bp
	.enter

EC <	call	ECGrObjCheckLMemObject			>

	GrObjDeref	bx,ds,si
	push	cx					;DrawFlags
	mov	ax,ds:[bx].GOI_attrFlags
	andnf	ax, mask GOAF_WRAP
	mov	cl, offset GOAF_WRAP
	shr	ax,cl
	cmp	ax, GOWTT_WRAP_AROUND_RECT
	pop	cx					;DrawFlags
	je	wrapAroundRect

	mov	bp,dx					;GrObjDrawFlags
	call	GrObjDrawDrawClip

done:
	.leave
	ret

wrapAroundRect:
	mov	cx, 1
	mov	bp,di					;gstate
	mov	ax,MSG_GO_DRAW_PARENT_RECT
	call	ObjCallInstanceNoLock
	jmp	done


GrObjDrawDrawWrapAround		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjDrawDrawClip
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw clipping area

CALLED BY:	INTERNAL
		GrObjDrawDrawWrapAround
		GrObjDraw

PASS:		*ds:si - object
		di - gstate
		cl - DrawFlags
		dx - GrObjDrawFlags

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
	srs	9/ 5/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjDrawDrawClip		proc	near
	class	GrObjClass
	uses	ax,bx,cx,dx,bp
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	call	GrSaveTransform
	call	GrObjApplyNormalTransform

	or	cl, mask DF_PRINT

	;    Choose proper resolution
	;

	mov	ax,MSG_GO_DRAW_CLIP_AREA_HI_RES
	test	dx,mask GODF_DRAW_WITH_INCREASED_RESOLUTION
	jnz	drawClip
	mov	ax,MSG_GO_DRAW_CLIP_AREA
drawClip:
	mov	bp,dx					;GrObjDrawFlags
	mov	dx,di					;gstate
	call	ObjCallInstanceNoLock
	call	GrRestoreTransform

	.leave
	ret

GrObjDrawDrawClip		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjDrawDrawQuickView
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the quick view of the object

CALLED BY:	INTERNAL
		GrObjDraw

PASS:		*ds:si - object
		di - gstate
		cl - DrawFlags
		dx - GrObjDrawFlags

RETURN:		
		stc - drawn quickly
		clc - can't draw as quick view

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
	srs	9/ 5/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjDrawDrawQuickView		proc	near
	class	GrObjClass
	uses	ax,dx,bp
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	;    If object is being edited drawing it quickly
	;    makes it impossible to see what you are editing. 
	;    So don't draw it quick.
	;

	push	di					;gstate
	GrObjDeref	di,ds,si
	test	ds:[di].GOI_tempState,mask GOTM_EDITED
	pop	di					;gstate
	jnz	noQuick

	call	GrObjCheckGrObjTransMatrixForIdentity
	pushf
	jc	doDraw

	call	GrSaveTransform
	call	GrObjApplyNormalTransform

doDraw:
	mov	bp,dx					;GrObjDrawFlags

	clr	dx,ax
	call	GrSetLineWidth

	mov	ax,C_BLACK
	call	GrSetLineColor
	
	mov	al,SDM_100
	call	GrSetLineMask

	mov	ax,MSG_GO_DRAW_QUICK_VIEW
	mov	dx,di					;gstate
	call	ObjCallInstanceNoLock

	popf
	jc	done
	call	GrRestoreTransform
	stc

done:
	.leave
	ret

noQuick:
	clc
	jmp	done

GrObjDrawDrawQuickView		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjDrawDrawBackground
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine whether background should be drawn and if
		so send message to draw it.

CALLED BY:	INTERNAL
		GrObjDraw

PASS:		*ds:si - object
		di - gstate with normalTransform applied		
		cl - DrawFlags
		dx - GrObjDrawFlags

RETURN:		
		nothing

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
	srs	9/ 5/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjDrawDrawBackground		proc	near
	class	GrObjClass
	uses	ax,bx,dx,bp
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	;    Get foreground area attributes so that we can
	;    decide whether to draw the background.
	;

	push	cx					;DrawFlags
	GrObjDeref	bx,ds,si
	mov	cx,ds:[bx].GOI_areaAttrToken
	sub	sp,size GrObjFullAreaAttrElement
	mov	bp,sp
	call	GrObjGetGrObjFullAreaAttrElement
	jnc	clearFrame
	mov	al,ss:[bp].GOBAAE_areaInfo
	mov	ah,ss:[bp].GOBAAE_mask
	mov	bl,ss:[bp].GOBAAE_pattern.GP_type
	add	sp, size GrObjFullAreaAttrElement
	pop	cx					;DrawFlags

	;    If area is transparent, then jump to skip 
	;    drawing background
	;

	test	al,mask GOAAIR_TRANSPARENT
	jnz	done

	;    If foreground doesn't completely cover the background
	;    then don't try to optimize drawing of background
	;

	push	bx						;pattern
	GrObjDeref	bx,ds,si
	test	ds:[bx].GOI_msgOptFlags, mask GOMOF_DRAW_BG
	pop	bx						;pattern
	jnz	pickMessage

	;    If the pattern allows us to see through the foreground area
	;    then draw the background.
	;

	cmp	bl,PT_SOLID
	jne	pickMessage

	;    If area mask is solid, then jump to skip drawing background
	;

	cmp	ah, SDM_100
	je	done

pickMessage:
	mov	ax,MSG_GO_DRAW_BG_AREA_HI_RES
	test	dx,mask GODF_DRAW_WITH_INCREASED_RESOLUTION
	jnz	drawBackground
	mov	ax,MSG_GO_DRAW_BG_AREA
drawBackground:
	call	GrObjApplyBackgroundAttrs
	call	GrSaveTransform
	mov	bp,dx					;GrObjDrawFlags
	mov	dx,di					;gstate
	call	ObjCallInstanceNoLock
	call	GrRestoreTransform
done:

	.leave
	ret

clearFrame:
	add	sp, size GrObjFullAreaAttrElement
	pop	cx					;DrawFlags
	jmp	done

GrObjDrawDrawBackground		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjDrawBG
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Default handler draws a rectangle

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass
	
		cl - DrawFlags
		dx - gstate to draw through
		bp - GrObjDrawFlags

RETURN:		
		nothing
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SPEED over SMALL SIZE

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/11/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjDrawBG	method dynamic GrObjClass, MSG_GO_DRAW_BG_AREA
	uses	cx,dx
	.enter

	mov	di,dx
EC <	call	ECCheckGStateHandle				>
	CallMod	GrObjGetNormalOBJECTDimensions
	call	GrObjCalcCorners
	call	GrFillRect

	.leave
	ret

GrObjDrawBG		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjDrawBGHiRes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Default handler draws a rectangle

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass
	
		cl - DrawFlags
		bp - GrObjDrawFlags
		dx - gstate to draw through

RETURN:		
		nothing
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SPEED over SMALL SIZE

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/11/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjDrawBGHiRes	method dynamic GrObjClass, MSG_GO_DRAW_BG_AREA_HI_RES
	uses	cx,dx
	.enter

	mov	di,dx
EC <	call	ECCheckGStateHandle				>
	CallMod	GrObjApplyIncreaseResolutionScaleFactor
	CallMod	GrObjGetNormalOBJECTDimensions
	call	GrObjCalcIncreasedResolutionCorners
	call	GrFillRect

	.leave
	ret

GrObjDrawBGHiRes		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjDrawQuickView
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Default handler draws a rectangle

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass
	
		cl - DrawFlags
		dx - gstate to draw through
		bp - GrObjDrawFlags

RETURN:		
		nothing
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SPEED over SMALL SIZE

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/11/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjDrawQuickView	method dynamic GrObjClass, MSG_GO_DRAW_QUICK_VIEW
	uses	cx,dx
	.enter

	mov	di,dx
EC <	call	ECCheckGStateHandle				>
	CallMod	GrObjGetNormalOBJECTDimensions
	call	GrObjCalcCorners
	call	GrDrawRect

	.leave
	ret

GrObjDrawQuickView		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjApplyIncreaseResolutionScaleFactor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Apply fractional scale factor to allow passing of
		higher resolution points to graphic system

CALLED BY:	INTERNAL

PASS:		
		di - gstate

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/31/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjApplyIncreaseResolutionScaleFactor		proc	far
	uses	ax,bx,cx,dx
	.enter

	movnf	ax,INCREASE_RESOLUTION_SCALE_FACTOR_FRAC
	movnf	bx,INCREASE_RESOLUTION_SCALE_FACTOR_INT
	mov	cx,ax
	mov	dx,bx
	call	GrApplyScale

	.leave
	ret
GrObjApplyIncreaseResolutionScaleFactor		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjApplyDecreaseResolutionScaleFactor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Apply fractional scale factor to allow passing of
		higher resolution points to graphic system

CALLED BY:	INTERNAL

PASS:		
		di - gstate

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/31/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjApplyDecreaseResolutionScaleFactor		proc	far
	uses	ax,bx,cx,dx
	.enter

	clr	ax	
	movnf	bx,INCREASE_RESOLUTION_FACTOR
	mov	cx,ax
	mov	dx,bx
	call	GrApplyScale

	.leave
	ret
GrObjApplyDecreaseResolutionScaleFactor		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjCalcIncreasedResolutionCorners
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return rectangle -w/2,-h/2,w/2,h/2 that has been multiplied
		by the INCREASE_RESOLUTION_FACTOR

CALLED BY:	INTERNAL UTILITY

PASS:		
		dx:cx - WWFixed width
		bx:ax - WWFixed height

RETURN:		
		ax = -w/2 * INCREASE_RESOLUTION_FACTOR
		bx = -h/2 * INCREASE_RESOLUTION_FACTOR
		cx = w/2  * INCREASE_RESOLUTION_FACTOR
		dx = h/2  * INCREASE_RESOLUTION_FACTOR

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/22/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjCalcIncreasedResolutionCorners		proc	far

	;   Calc rect -w/2,-h/2,w/2,h/2
	;

	IncreaseResolutionShift	dx,cx
	IncreaseResolutionShift	bx,ax

	FALL_THRU	GrObjCalcCorners

GrObjCalcIncreasedResolutionCorners		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjCalcCorners
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Translates gstates and returns 0,0,width,height for drawing

CALLED BY:	GLOBAL

PASS:		
		dx:cx - WWFixed width
		bx:ax - WWFixed height
		di - gstate

RETURN:		
		ax,bx,cx,dx - coordinates to draw rect,ellipse,line,etc
		di - translation applied

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/22/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjCalcCorners		proc	far

EC <	call	ECCheckGStateHandle		>

	push	dx,cx,bx,ax

	sarwwf	dxcx
	negwwf	dxcx
	sarwwf	bxax
	negwwf	bxax
	call	GrApplyTranslation

	pop	cx,ax,dx,bx
	rndwwf	cxax
	rndwwf	dxbx
	clr	ax,bx

	ret

GrObjCalcCorners		endp


GrObjDrawCode	ends

GrObjMiscUtilsCode	segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjDrawPARENTRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw rectangle that bounds the object in PARENT coords

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

		cx - ammount to kick rectangle out left/top (in points)
		dx - ammount to kick rectangle out right/bottom (in points)
		bp - gstate with PARENT transformation in it

RETURN:		
		nothing
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/ 1/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjDrawPARENTRect	method dynamic GrObjClass, 
						MSG_GO_DRAW_PARENT_RECT
	uses	cx, dx
	.enter

	tst	cx
	pushf					;save bump out flag

	mov	di,bp
	call	GrSaveTransform

	call	GrObjApplyTranslationToNormalCenter
	call	GrObjGetNormalPARENTDimensions
	call	GrObjCalcCorners

	popf
	jz	noBumpOut

	sub	ax, 1
	sub	bx, 2
	add	cx, 1
	add	dx, 2

noBumpOut:

	call	GrFillRect

	call	GrRestoreTransform


	.leave
	ret
GrObjDrawPARENTRect		endm

GrObjMiscUtilsCode	ends





GrObjSpecialGraphicsCode	segment resource






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjDrawGradientFGArea
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

		dx -gstate with normalTransform applied
		cl - DrawFlags
		bp - GrObjDrawFlags

RETURN:		

	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/ 4/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjDrawFGGradientArea	method dynamic GrObjClass, 
					MSG_GO_DRAW_FG_GRADIENT_AREA,
					MSG_GO_DRAW_FG_GRADIENT_AREA_HI_RES
	uses	cx
	.enter

	mov	di,dx
EC <	call	ECCheckGStateHandle				>

	call	GrObjGetGradientType
	cmp	al, GOGT_NONE
	je	done
	cmp	al, GrObjGradientType
	jae	done

	call	GrSaveState
	call	GrObjDrawGradientClipToShape

	test	bp, mask GODF_DRAW_WITH_INCREASED_RESOLUTION
	jnz	hiRes

	call	GrObjDrawGradient

restoreState:
	call	GrRestoreState
done:
	.leave
	ret
hiRes:
	call	GrObjApplyIncreaseResolutionScaleFactor
	call	GrObjDrawGradient
	jmp	restoreState

GrObjDrawFGGradientArea		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjDrawGradientClipToShape
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set clip path to objects shape

CALLED BY:	INTERNAL
		GrObjDrawGradientFGArea	

PASS:		*ds:si - object
		di -gstate with normalTransform applied
		cl - DrawFlags
		bp - GrObjDrawFlags

RETURN:		

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
	srs	9/ 5/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjDrawGradientClipToShape		proc	near
	uses	ax,cx,dx
	.enter

	push	cx					;DrawFlags
	mov	cx,PCT_REPLACE
	call	GrBeginPath
	pop	cx					;DrawFlags

	;    Draw proper resolution clip shape to path
	;

	mov	ax,MSG_GO_DRAW_CLIP_AREA_HI_RES
	test	bp,mask GODF_DRAW_WITH_INCREASED_RESOLUTION
	jnz	drawClip
	mov	ax,MSG_GO_DRAW_CLIP_AREA
drawClip:

	; set the print flag so that we do not get selections highlighted

	push	cx
	or	cl, mask DF_PRINT
	call	ObjCallInstanceNoLock
	pop	cx

	call	GrEndPath

	mov	dl,RFR_ODD_EVEN
	mov	cx,PCT_INTERSECTION
	call	GrSetWinClipPath

	.leave
	ret
GrObjDrawGradientClipToShape		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjDrawGradient
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call proper gradient routine based on type

CALLED BY:	INTERNAL
		GrObjDrawFGGradientArea

PASS:	
		*ds:si - grobject
		dx - gstate
		cl - DrawFlags
		bp - GrObjDrawFlags
		al - GrObjGradientType

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
	srs	9/14/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjDrawGradient		proc	near
	uses	bx
	.enter

EC <	call	ECGrObjCheckLMemObject		>

	mov	bx,bp					;GrObjDrawFlags

	cmp	al,GOGT_NONE
	je	done
	cmp	al,GOGT_RADIAL_RECT
	je	radial
	cmp	al,GOGT_RADIAL_ELLIPSE
	je	radial
	call	GrObjDrawLinearGradient
done:
	.leave
	ret

radial:
	call	GrObjDrawRadialGradient
	jmp	done
	
GrObjDrawGradient		endp


BBFixedColor	struct
	BBFC_red	BBFixed
	BBFC_green	BBFixed
	BBFC_blue	BBFixed
BBFixedColor	ends

GradientData	struct
	GD_boundingRect		RectWWFixed
	GD_intervalRect		RectWWFixed
	GD_startColor		ColorQuad
	GD_endColor		ColorQuad
	GD_type			GrObjGradientType
	GD_grobjDrawFlags	GrObjDrawFlags
	GD_requestedIntervals	word
	GD_actualIntervals	word
	GD_intervalWidth 	WWFixed
	GD_intervalHeight 	WWFixed
	GD_intervalDeltaWidth	WWFixed
	GD_intervalDeltaHeight	WWFixed
	GD_colorDeltas		BBFixedColor
	GD_currentColor		BBFixedColor
GradientData	ends





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjDrawLinearGradient
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw series of rectangles for gradient fill into gstate
		

CALLED BY:	INTERNAL

PASS:		
		*ds:si - grobject
		dx - gstate
		cl - DrawFlags
		bx - GrObjDrawFlags
		al - GrObjGradientType
			supports GOGT_LEFT_TO_RIGHT and GOGT_TOP_TO_BOTTOM
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
	srs	9/ 4/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjDrawLinearGradient		proc	far

gradientLocal	local GradientData	
	.enter

	cmp	al,GOGT_LEFT_TO_RIGHT
	je	doIt
	cmp	al,GOGT_TOP_TO_BOTTOM
	jne	done

doIt:
	call	GrObjInitGradientData

	;    If the object is zero wide or high we will end up
	;    with 0 actualIntervals. The code will attempt to 
	;    draw 0xffff rects.
	;

	tst	gradientLocal.GD_actualIntervals
	jz	done

	call	GrObjApplyIntervalColor	
	jmp	draw

next:
	call	GrObjAdvanceIntervalRect
	call	GrObjTrimIntervalRect
	call	GrObjAdvanceIntervalColor
	call	GrObjApplyIntervalColor	
draw:
	call	GrObjDrawIntervalRect
	dec	gradientLocal.GD_actualIntervals
	jnz	next
done:
	.leave
	ret
GrObjDrawLinearGradient		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjDrawIntervalRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the interval rect

CALLED BY:	INTERNAL
		GrObjDrawLinearGradient

PASS:		
		dx - gstate
		bp - inherited GradientData

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
	srs	9/ 4/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjDrawIntervalRect		proc	far
	uses	di,ax,bx,cx,dx,si
	.enter inherit	GrObjDrawLinearGradient

	mov	di,dx					;gstate

	movwwf	axdx,gradientLocal.GD_intervalRect.RWWF_left
	rndwwf	axdx
	movwwf	bxdx,gradientLocal.GD_intervalRect.RWWF_top
	rndwwf	bxdx
	movwwf	cxdx,gradientLocal.GD_intervalRect.RWWF_right
	rndwwf	cxdx
	movwwf	dxsi,gradientLocal.GD_intervalRect.RWWF_bottom
	rndwwf	dxsi
	call	GrFillRect

	.leave
	ret
GrObjDrawIntervalRect		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjAdvanceIntervalColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the next interval color 

CALLED BY:	INTERNAL
		GrObjDrawLinearGradient

PASS:		
		bp - inherited GradientData

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
	srs	9/ 4/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjAdvanceIntervalColor		proc	far

gradientLocal	local GradientData	

	uses	ax,bx,cx,di
	.enter inherit

	mov	di,dx					;gstate

	cmp	gradientLocal.GD_actualIntervals,1
	je	lastInterval

	mov	ax,{word}gradientLocal.GD_colorDeltas.BBFC_red
	add	{word}gradientLocal.GD_currentColor.BBFC_red,ax
	mov	ax,{word}gradientLocal.GD_colorDeltas.BBFC_green
	add	{word}gradientLocal.GD_currentColor.BBFC_green,ax
	mov	ax,{word}gradientLocal.GD_colorDeltas.BBFC_blue
	add	{word}gradientLocal.GD_currentColor.BBFC_blue,ax

done:
	.leave
	ret

lastInterval:
	clr	al
	mov	ah,gradientLocal.GD_endColor.CQ_redOrIndex
	mov	ah,gradientLocal.GD_endColor.CQ_green
	mov	ah,gradientLocal.GD_endColor.CQ_blue
	mov	{word}gradientLocal.GD_currentColor.BBFC_red,ax
	mov	{word}gradientLocal.GD_currentColor.BBFC_green,ax
	mov	{word}gradientLocal.GD_currentColor.BBFC_blue,ax

	jmp	done

GrObjAdvanceIntervalColor		endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjApplyIntervalColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Apply current color  to the gstate

CALLED BY:	INTERNAL
		GrObjDrawLinearGradient

PASS:		
		dx - gstate
		bp - inherited GradientData

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
	srs	9/ 4/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjApplyIntervalColor		proc	far

gradientLocal	local GradientData	

	uses	ax,bx,cx,di
	.enter inherit

	mov	di,dx					;gstate

	cmp	gradientLocal.GD_actualIntervals,1
	je	lastInterval

	mov	ax,{word}gradientLocal.GD_currentColor.BBFC_red
	tst	al
	jns	10$
	inc	ah
10$:
	mov	al,ah					;red

	mov	bx,{word}gradientLocal.GD_currentColor.BBFC_green
	tst	bl
	jns	20$
	inc	bh
20$:
	mov	bl,bh					;green

	mov	cx,{word}gradientLocal.GD_currentColor.BBFC_blue
	tst	cl
	jns	30$
	inc	ch
30$:
	mov	bh,ch					;blue

apply:
	mov	ah, CF_RGB
	call	GrSetAreaColor


	.leave
	ret

lastInterval:
	mov	al,gradientLocal.GD_endColor.CQ_redOrIndex
	mov	bl,gradientLocal.GD_endColor.CQ_green
	mov	bh,gradientLocal.GD_endColor.CQ_blue
	jmp	apply

GrObjApplyIntervalColor		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjAdvanceIntervalRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Advance the interval rect by the interval deltas

CALLED BY:	INTERNAL 
		GrObjDrawLinearGradient

PASS:		bp - inherited GradientData

RETURN:		
		GD_intervalRect has moved		

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
	srs	9/ 4/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjAdvanceIntervalRect		proc	far

gradientLocal	local GradientData	

	uses	cx,dx
	.enter inherit

	movwwf	dxcx,gradientLocal.GD_intervalDeltaWidth
	addwwf	gradientLocal.GD_intervalRect.RWWF_left,dxcx
	addwwf	gradientLocal.GD_intervalRect.RWWF_right,dxcx

	movwwf	dxcx,gradientLocal.GD_intervalDeltaHeight
	addwwf	gradientLocal.GD_intervalRect.RWWF_top,dxcx
	addwwf	gradientLocal.GD_intervalRect.RWWF_bottom,dxcx

	.leave
	ret
GrObjAdvanceIntervalRect		endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjTrimIntervalRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If this is the last interval make sure that
		intervalRect right and bottom don't go beyond
		the boundingRect

CALLED BY:	INTERNAL
		GrObjDrawLinearGradient

PASS:		bp - inherited GradientData

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
	srs	9/ 4/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjTrimIntervalRect		proc	far

gradientLocal	local GradientData	

	uses	cx,dx
	.enter inherit

	cmp	gradientLocal.GD_actualIntervals,1
	je	lastInterval
done:
	.leave
	ret

lastInterval:
	movwwf	dxcx,gradientLocal.GD_boundingRect.RWWF_right
	movwwf	gradientLocal.GD_intervalRect.RWWF_right,dxcx
	movwwf	dxcx,gradientLocal.GD_boundingRect.RWWF_bottom
	movwwf	gradientLocal.GD_intervalRect.RWWF_bottom,dxcx
	jmp	done


GrObjTrimIntervalRect		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjInitGradientData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the GradientData structure for drawing 
		the interval rectangles

CALLED BY:	INTERNAL
		GrObjDrawLinearGradient

PASS:		*ds:si - grobject
		bp - inherited GradientData stack frame
		cl - DrawFlags
		bx - GrObjDrawFlags
		al - GrObjGradientType
RETURN:		
		GradientData filled in

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
	srs	9/ 4/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjInitGradientData		proc	far

gradientLocal	local GradientData	

	.enter inherit
	
EC <	call	ECGrObjCheckLMemObject				>

	mov	gradientLocal.GD_grobjDrawFlags,bx
	mov	gradientLocal.GD_type,al

	call	GrObjCalcGradientBoundingRect
	call	GrObjCalcIntervalDimensions

	call	GrObjGetNumberOfGradientIntervals
	mov	gradientLocal.GD_requestedIntervals,cx

	call	GrObjGetGradientColors
	call	GrObjCalcActualIntervals
	call	GrObjCalcColorDeltas
	call	GrObjCalcIntervalDeltas
	call	GrObjInitIntervalRect

	.leave

	ret
GrObjInitGradientData		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjCalcGradientBoundingRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return rectangle -w/2,-h/2,w/2,h/2 that bounds the
		object in its coordinate system.
		Multiply coords by INCREASE_RESOLUTION_FACTOR if
		drawing at a higher resolution

CALLED BY:	INTERNAL 
		GrObjInitGradientData

PASS:		
		*ds:si - object
		bp - inherited GradientData

RETURN:		
		GD_boundingRect


DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/22/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjCalcGradientBoundingRect		proc	far

gradientLocal	local GradientData	

	uses	ax,bx,cx,dx
	.enter inherit


	call	GrObjGetNormalOBJECTDimensions

	test	gradientLocal.GD_grobjDrawFlags,\
				 mask GODF_DRAW_WITH_INCREASED_RESOLUTION
	jz	calcCorners
	IncreaseResolutionShift	dx,cx
	IncreaseResolutionShift	bx,ax

calcCorners:
	sar	dx,1
	rcr	cx,1
	movwwf	gradientLocal.GD_boundingRect.RWWF_right,dxcx
	negwwf	dxcx
	movwwf	gradientLocal.GD_boundingRect.RWWF_left,dxcx

	sar	bx,1
	rcr	ax,1
	movwwf	gradientLocal.GD_boundingRect.RWWF_bottom,bxax
	negwwf	bxax
	movwwf	gradientLocal.GD_boundingRect.RWWF_top,bxax

	.leave
	ret

GrObjCalcGradientBoundingRect		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjCalcIntervalDimensions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate GD_intervalWidth and GD_intervalHeight
		

CALLED BY:	INTERNAL 
		GrObjInitGradientData

PASS:		
		*ds:si - object
		bp - inherited GradientData
		al - AreaAttrInfoRecord

RETURN:		
		GD_intervalWidth
		GD_intervalHeight


DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/22/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjCalcIntervalDimensions		proc	far

gradientLocal	local GradientData	

	uses	cx,dx
	.enter inherit

	cmp	gradientLocal.GD_type,GOGT_LEFT_TO_RIGHT
	jne	vertical

	movwwf	dxcx,gradientLocal.GD_boundingRect.RWWF_bottom
	subwwf	dxcx,gradientLocal.GD_boundingRect.RWWF_top
	movwwf	gradientLocal.GD_intervalHeight,dxcx
	clrwwf	dxcx
	movwwf	gradientLocal.GD_intervalWidth,dxcx

done:
	.leave
	ret

vertical:
	movwwf	dxcx,gradientLocal.GD_boundingRect.RWWF_right
	subwwf	dxcx,gradientLocal.GD_boundingRect.RWWF_left
	movwwf	gradientLocal.GD_intervalWidth,dxcx
	clrwwf	dxcx
	movwwf	gradientLocal.GD_intervalHeight,dxcx
	jmp	done	

GrObjCalcIntervalDimensions		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjInitIntervalRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize interval rect to first rect
		

CALLED BY:	INTERNAL 
		GrObjInitGradientData

PASS:		
		*ds:si - object
		bp - inherited GradientData

RETURN:		
		GD_intervalRect


DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/22/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjInitIntervalRect		proc	far

gradientLocal	local GradientData	

	uses	cx,dx
	.enter inherit

	movwwf	dxcx,gradientLocal.GD_boundingRect.RWWF_left
	movwwf  gradientLocal.GD_intervalRect.RWWF_left,dxcx
	addwwf	dxcx,gradientLocal.GD_intervalWidth
	addwwf	dxcx,gradientLocal.GD_intervalDeltaWidth
	movwwf  gradientLocal.GD_intervalRect.RWWF_right,dxcx

	movwwf	dxcx,gradientLocal.GD_boundingRect.RWWF_top
	movwwf  gradientLocal.GD_intervalRect.RWWF_top,dxcx
	addwwf	dxcx,gradientLocal.GD_intervalHeight
	addwwf	dxcx,gradientLocal.GD_intervalDeltaHeight
	movwwf  gradientLocal.GD_intervalRect.RWWF_bottom,dxcx

	.leave
	ret

GrObjInitIntervalRect		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGetGradientColors
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get colors from attribute element
		

CALLED BY:	INTERNAL 
		GrObjInitGradientData

PASS:		
		*ds:si - object
		bp - inherited GradientData

RETURN:		
		GD_startColor
		GD_endColor


DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/22/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGetGradientColors		proc	far

gradientLocal	local GradientData	

	uses	cx,dx
	.enter inherit

EC <	call	ECGrObjCheckLMemObject		>

	call	GrObjGetStartingGradientColor
	mov	gradientLocal.GD_startColor.CQ_redOrIndex,cl
	mov	gradientLocal.GD_startColor.CQ_green,ch
	mov	gradientLocal.GD_startColor.CQ_blue,dl

	mov	gradientLocal.GD_currentColor.BBFC_red.BBF_int,cl
	mov	gradientLocal.GD_currentColor.BBFC_green.BBF_int,ch
	mov	gradientLocal.GD_currentColor.BBFC_blue.BBF_int,dl
	clr	cl
	mov	gradientLocal.GD_currentColor.BBFC_red.BBF_frac,cl
	mov	gradientLocal.GD_currentColor.BBFC_green.BBF_frac,cl
	mov	gradientLocal.GD_currentColor.BBFC_blue.BBF_frac,cl

	call	GrObjGetEndingGradientColor
	mov	gradientLocal.GD_endColor.CQ_redOrIndex,cl
	mov	gradientLocal.GD_endColor.CQ_green,ch
	mov	gradientLocal.GD_endColor.CQ_blue,dl

	.leave
	ret

GrObjGetGradientColors		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjCalcActualIntervals
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the actual number of intervals
		Can't be more than the largest change in one of the
		color bytes.
		Can't be more than the bounding rect width or height
		depending on the direction.


CALLED BY:	INTERNAL 
		GrObjInitGradientData

PASS:		
		*ds:si - object
		bp - inherited GradientData

RETURN:		
		GD_actualInterval


DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/22/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjCalcActualIntervals		proc	far

gradientLocal	local GradientData	

	uses	ax,bx,cx,dx
	.enter inherit

	;    Get largest color change
	;

	clr	bh
	mov	bl,gradientLocal.GD_startColor.CQ_redOrIndex
	mov	cl,gradientLocal.GD_endColor.CQ_redOrIndex
	clr	ch
	sub	cx,bx
	jnc	10$
	neg	cx
10$:

	mov	bl,gradientLocal.GD_startColor.CQ_green
	mov	dl,gradientLocal.GD_endColor.CQ_green
	clr	dh
	sub	dx,bx
	jnc	20$
	neg	dx
20$:

	cmp	cx,dx
	ja	30$
	mov	cx,dx
30$:
	mov	bl,gradientLocal.GD_startColor.CQ_blue
	mov	dl,gradientLocal.GD_endColor.CQ_blue
	clr	dh
	sub	dx,bx
	jnc	40$
	neg	dx
40$:

	cmp	cx,dx
	ja	50$
	mov	cx,dx
50$:

	;    Set actualIntervals to min of requestedIntervals and
	;    the largest color change + 1
	;

	inc	cx					;num int color intervals
	mov	dx,gradientLocal.GD_requestedIntervals
	cmp	cx,dx
	ja	60$
	mov	dx,cx
60$:

	;    Make sure that the actualIntervals is not more than
	;    the width or height of the bounding rect. We don't	
	;    want to be drawing rects narrower than a pixel.
	;

	cmp	gradientLocal.GD_type,GOGT_RADIAL_RECT
	je	setActual
	cmp	gradientLocal.GD_type,GOGT_RADIAL_ELLIPSE
	je	setActual
	cmp	gradientLocal.GD_type,GOGT_LEFT_TO_RIGHT
	jne	vertical	

	movwwf	bxax,gradientLocal.GD_boundingRect.RWWF_right
	subwwf	bxax,gradientLocal.GD_boundingRect.RWWF_left
	tst	bx
	jns	70$
	neg	bx
70$:
	test	gradientLocal.GD_grobjDrawFlags,\
				 mask GODF_DRAW_WITH_INCREASED_RESOLUTION
	jz	compare
	mov	cl,INCREASE_RESOLUTION_SHIFT
	shr	bx,cl
compare:
	cmp	bx,dx				;width,num intervals
	jae	setActual
	mov	dx,bx				;set to width

setActual:
	mov	gradientLocal.GD_actualIntervals,dx

	.leave
	ret

vertical:
	movwwf	bxax,gradientLocal.GD_boundingRect.RWWF_bottom
	subwwf	bxax,gradientLocal.GD_boundingRect.RWWF_top
	tst	bx
	jns	70$
	neg	bx
	jmp	70$
	

GrObjCalcActualIntervals		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjCalcColorDeltas
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the color deltas
		

CALLED BY:	INTERNAL 
		GrObjInitGradientData

PASS:		
		*ds:si - object
		bp - inherited GradientData

RETURN:		
		GD_colorDeltas


DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/22/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjCalcColorDeltas		proc	far

gradientLocal	local GradientData	

	uses	ax,bx,cx,dx
	.enter inherit

	mov	bx,gradientLocal.GD_actualIntervals
	dec	bx
	clr	ax

	clr	ch,dh
	mov	cl,gradientLocal.GD_startColor.CQ_redOrIndex
	mov	dl,gradientLocal.GD_endColor.CQ_redOrIndex
	sub	dx,cx
	clr	cx
	call	GrSDivWWFixed	
	mov	gradientLocal.GD_colorDeltas.BBFC_red.BBF_int,dl
	mov	gradientLocal.GD_colorDeltas.BBFC_red.BBF_frac,ch

	clr	ch,dh
	mov	cl,gradientLocal.GD_startColor.CQ_green
	mov	dl,gradientLocal.GD_endColor.CQ_green
	sub	dx,cx
	clr	cx
	call	GrSDivWWFixed	
	mov	gradientLocal.GD_colorDeltas.BBFC_green.BBF_int,dl
	mov	gradientLocal.GD_colorDeltas.BBFC_green.BBF_frac,ch

	clr	ch,dh
	mov	cl,gradientLocal.GD_startColor.CQ_blue
	mov	dl,gradientLocal.GD_endColor.CQ_blue
	sub	dx,cx
	clr	cx
	call	GrSDivWWFixed	
	mov	gradientLocal.GD_colorDeltas.BBFC_blue.BBF_int,dl
	mov	gradientLocal.GD_colorDeltas.BBFC_blue.BBF_frac,ch

	.leave
	ret

GrObjCalcColorDeltas		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjCalcIntervalDeltas
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the interval deltas
		

CALLED BY:	INTERNAL 
		GrObjInitGradientData

PASS:		
		*ds:si - object
		bp - inherited GradientData


RETURN:		
		GD_intervalDeltaWidth
		GD_intervalDeltaHeight


DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/22/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjCalcIntervalDeltas		proc	far

gradientLocal	local GradientData	

	uses	ax,bx,cx,dx
	.enter inherit

	mov	bx,gradientLocal.GD_actualIntervals
	clr	ax

	cmp	gradientLocal.GD_type,GOGT_LEFT_TO_RIGHT
	jne	vertical

	movwwf	dxcx,gradientLocal.GD_boundingRect.RWWF_right
	subwwf	dxcx,gradientLocal.GD_boundingRect.RWWF_left
	call	GrSDivWWFixed
	movwwf	gradientLocal.GD_intervalDeltaWidth,dxcx
	clrwwf	dxcx
	movwwf	gradientLocal.GD_intervalDeltaHeight,dxcx

done:
	.leave
	ret

vertical:
	movwwf	dxcx,gradientLocal.GD_boundingRect.RWWF_bottom
	subwwf	dxcx,gradientLocal.GD_boundingRect.RWWF_top
	call	GrSDivWWFixed
	movwwf	gradientLocal.GD_intervalDeltaHeight,dxcx
	clrwwf	dxcx
	movwwf	gradientLocal.GD_intervalDeltaWidth,dxcx
	jmp	done

GrObjCalcIntervalDeltas		endp


ArrowheadData	struct
	AD_startLinePoint	Point
	AD_endLinePoint		Point
	AD_lineInfo		GrObjLineAttrInfoRecord
	AD_deflectionAngle	byte
	AD_length		byte
	AD_startArrowheadPoint	Point
	AD_endArrowheadPoint	Point
ArrowheadData	ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjDrawArrowhead
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw arrowhead at start of line.

CALLED BY:	INTERNAL UTILITY

PASS:		*ds:si - object
		di - gstate 
		ax,bx - start point of line
		cx,dx - end point of line

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
	srs	9/ 8/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjDrawArrowhead		proc	far

ahLocal	local	ArrowheadData

	.enter

EC <	call	ECGrObjCheckLMemObject				>
EC <	call	ECCheckGStateHandle			>

	mov	ahLocal.AD_startLinePoint.P_x,ax
	mov	ahLocal.AD_startLinePoint.P_y,bx
	mov	ahLocal.AD_endLinePoint.P_x,cx
	mov	ahLocal.AD_endLinePoint.P_y,dx
	call	GrObjInitArrowheadDataCommon
	call	GrObjCalcArrowheadPoints
	call	GrObjDrawOneArrowhead

	.leave
	ret
GrObjDrawArrowhead		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjInitArrowheadDataCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get common data from objects line attributes and
		put in Arrowhead on stack

CALLED BY:	INTERNAL UTILITY

PASS:		*ds:si
		bp - inherited ArrowheadData

RETURN:		
		AD_lineInfo
		AD_length
		AD_deflectionAngle

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
	srs	9/ 8/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjInitArrowheadDataCommon		proc	near
	uses	ax,bx,cx
	.enter inherit GrObjDrawArrowhead

EC <	call	ECGrObjCheckLMemObject			>

	call	GrObjGetArrowheadInfo

	mov	ahLocal.AD_lineInfo,al
	mov	ahLocal.AD_length,bl
	mov	ahLocal.AD_deflectionAngle,bh

	.leave
	ret
GrObjInitArrowheadDataCommon		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjCalcArrowheadPoints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the start and end arrow head points

CALLED BY:	INTERNAL UTILITY

PASS:		bp - inherited ArrowheadData

RETURN:		
		AD_startArrowheadPoint
		AD_endArrowheadPoint

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
	srs	9/ 8/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjCalcArrowheadPoints		proc	near
	uses	ax,bx,cx,dx
	.enter inherit GrObjDrawArrowhead

	;    Calc line angle
	;

	mov	ax,ahLocal.AD_startLinePoint.P_x
	mov	bx,ahLocal.AD_startLinePoint.P_y
	mov	cx,ahLocal.AD_endLinePoint.P_x
	mov	dx,ahLocal.AD_endLinePoint.P_y
	call	GrObjCalcLineAngle
	rndwwf	dxcx					;line angle

	;    Get deflection angle in signed word and length
	;

	mov	al,ahLocal.AD_deflectionAngle		;deflection low byte
	cbw						;deflection high byte
	mov	bl,ahLocal.AD_length
	clr	bh					;length int high byte

	;    Calc the arrowhead points
	;

	push	dx,ax					;line angle,defl angle
	add	dx,ax					;add deflection
	call	GrObjCalcArrowheadPoint
	add	cx,ahLocal.AD_startLinePoint.P_x
	add	dx,ahLocal.AD_startLinePoint.P_y
	mov	ahLocal.AD_startArrowheadPoint.P_x,cx
	mov	ahLocal.AD_startArrowheadPoint.P_y,dx
	pop	dx,ax					;line angle, defl angle
	
	sub	dx,ax					;sub deflection angle
	call	GrObjCalcArrowheadPoint	
	add	cx,ahLocal.AD_startLinePoint.P_x
	add	dx,ahLocal.AD_startLinePoint.P_y
	mov	ahLocal.AD_endArrowheadPoint.P_x,cx
	mov	ahLocal.AD_endArrowheadPoint.P_y,dx

	.leave
	ret
GrObjCalcArrowheadPoints		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjCalcArrowheadPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calc one arrowhead point

CALLED BY:	INTERNAL
		GrObjCalcArrowheadPoint

PASS:		
		dx - angle of arrowhead branch
		bx - length of arrowhead branch

RETURN:		
		cx,dx - arrowhead point

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
	srs	9/ 8/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjCalcArrowheadPoint		proc	near
	uses	ax,bx
	.enter


	push	dx					;angle
	clr	ax					;angle frac
	call	GrQuickCosine
	mov	cx,ax					;cosine frac
	clr	ax					;length frac
	call	GrMulWWFixed
	rndwwf	dxcx
	mov	cx,dx					;x
	pop	dx					;angle
	push	cx					;x

	call	GrQuickSine
	negwwf	dxax					;???
	mov	cx,ax					;sine frac
	clr	ax
	call	GrMulWWFixed
	rndwwf	dxcx					;y
	pop	cx					;x

	.leave
	ret
GrObjCalcArrowheadPoint		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjDrawOneArrowhead
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw that arrowhead. If it is unfilled just draw the line.
		If it is filled then draw polygon and line.

CALLED BY:	INTERNAL UTILITY

PASS:		bp - inherited ArrowheadData
		di - gstate
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
	srs	9/ 8/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjDrawOneArrowhead		proc	near
	uses	ax,bx,cx,dx,si,ds,di
	.enter 	inherit GrObjDrawArrowhead

EC <	call	ECCheckGStateHandle			>

	;   Set miter limit to a small angle so that most arrowheads
	;   will draw with a point, but won't stick out really far
	;

	mov	bx,10
	clr	ax
	call	GrSetMiterLimit

	mov	al, LS_SOLID
	clr	bl
	call	GrSetLineStyle

	;
	;   Push the points to the stack
	;
	push	ahLocal.AD_startArrowheadPoint.P_y
	push	ahLocal.AD_startArrowheadPoint.P_x
	push	ahLocal.AD_startLinePoint.P_y
	push	ahLocal.AD_startLinePoint.P_x
	push	ahLocal.AD_endArrowheadPoint.P_y
	push	ahLocal.AD_endArrowheadPoint.P_x

	mov	si,sp
	segmov	ds,ss
	mov	cx,3

	test	ahLocal.AD_lineInfo, mask GOLAIR_ARROWHEAD_FILLED
	jnz	filled


	call	GrDrawPolyline

clearStack:
	add	sp,12

	.leave
	ret

filled:
	;   Draw the filled arrowhead with the area attributes
	;

	test	ahLocal.AD_lineInfo, mask GOLAIR_ARROWHEAD_FILL_WITH_AREA_ATTRIBUTES
	jnz	doFill

	;
	;  User wants his arrowhead fill attributes to follow the line attrs
	;
	call	GrGetLineColor	
	mov	ah, CF_RGB
	call	GrSetAreaColor
	mov	al,GMT_ENUM
	call	GrGetLineMask
	call	GrSetAreaMask
	mov	al,PT_SOLID
	call	GrSetAreaPattern

doFill:
	mov	al,RFR_ODD_EVEN
	call	GrFillPolygon
	call	GrDrawPolygon
	jmp	clearStack
GrObjDrawOneArrowhead		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGetArrowheadPoints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the two point that end the  branches of the 
		arrowhead

CALLED BY:	INTERNAL UTILITY

PASS:		*ds:si - object
		ax,bx - start point of line
		cx,dx - end point of line

RETURN:		
		cx,dx - x,y of point 1
		ax,bx - x,y of point 2

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
	srs	9/ 9/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGetArrowheadPoints		proc	far

ahLocal	local	ArrowheadData

	.enter

EC <	call	ECGrObjCheckLMemObject				>

	mov	ahLocal.AD_startLinePoint.P_x,ax
	mov	ahLocal.AD_startLinePoint.P_y,bx
	mov	ahLocal.AD_endLinePoint.P_x,cx
	mov	ahLocal.AD_endLinePoint.P_y,dx
	call	GrObjInitArrowheadDataCommon
	call	GrObjCalcArrowheadPoints

	mov	cx,ahLocal.AD_startArrowheadPoint.P_x
	mov	dx,ahLocal.AD_startArrowheadPoint.P_y
	mov	ax,ahLocal.AD_endArrowheadPoint.P_x
	mov	bx,ahLocal.AD_endArrowheadPoint.P_y

	.leave
	ret
GrObjGetArrowheadPoints		endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjDrawRadialGradient
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw series of rectangles for gradient fill into gstate
		

CALLED BY:	INTERNAL

PASS:		
		*ds:si - grobject
		dx - gstate
		cl - DrawFlags
		bx - GrObjDrawFlags
		al - GrObjGradientType
			supports GOGT_RADIAL_ELLIPSE and GOGT_RADIAL_RECT
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
	srs	9/ 4/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjDrawRadialGradient		proc	far

gradientLocal	local GradientData	

	.enter

	cmp	al,GOGT_RADIAL_RECT
	je	doIt
	cmp	al,GOGT_RADIAL_ELLIPSE
	jne	done

doIt:
	call	GrObjInitRadialGradientData

	;    The first time we draw a rectangle to fill in the 
	;    corners
	;

	call	GrObjApplyIntervalColor	
	call	GrObjDrawIntervalRect
	jmp	decrement

next:
	call	GrObjAdvanceRadialIntervalRect
	call	GrObjAdvanceIntervalColor
	call	GrObjApplyIntervalColor	
	cmp	al, GOGT_RADIAL_RECT
	je	radialRect
	call	GrObjDrawRadialIntervalEllipse
decrement:
	dec	gradientLocal.GD_actualIntervals
	jnz	next
done:
	.leave
	ret
radialRect:
	call	GrObjDrawIntervalRect
	jmp	decrement
GrObjDrawRadialGradient		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjInitRadialGradientData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the GradientData structure for drawing 
		the radial gradient interval shapes

CALLED BY:	INTERNAL
		GrObjDrawLinearGradient

PASS:		*ds:si - grobject
		bp - inherited GradientData stack frame
		cl - DrawFlags
		bx - GrObjDrawFlags
		al - GrObjGradientType
RETURN:		
		GradientData filled in

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
	srs	9/ 4/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjInitRadialGradientData		proc	far

gradientLocal	local GradientData	

	.enter inherit
	
EC <	call	ECGrObjCheckLMemObject				>

	mov	gradientLocal.GD_grobjDrawFlags,bx
	mov	gradientLocal.GD_type,al

	call	GrObjCalcGradientBoundingRect

if 0
	;
	;  Bump the rectangle out by SQRT(2) so that we get the smallest
	;  ellipse that completely fills in the rectangle
	;

	push	ax, bx, cx, dx
	movwwf	bxax, 92682				;bxax <- sqrt 2

	movwwf	dxcx, ss:[gradientLocal].GD_boundingRect.RWWF_left
	call	GrMulWWFixed
	movwwf	ss:[gradientLocal].GD_boundingRect.RWWF_left, dxcx

	movwwf	dxcx, ss:[gradientLocal].GD_boundingRect.RWWF_top
	call	GrMulWWFixed
	movwwf	ss:[gradientLocal].GD_boundingRect.RWWF_top, dxcx

	movwwf	dxcx, ss:[gradientLocal].GD_boundingRect.RWWF_right
	call	GrMulWWFixed
	movwwf	ss:[gradientLocal].GD_boundingRect.RWWF_right, dxcx

	movwwf	dxcx, ss:[gradientLocal].GD_boundingRect.RWWF_bottom
	call	GrMulWWFixed
	movwwf	ss:[gradientLocal].GD_boundingRect.RWWF_bottom, dxcx

	pop	ax, bx, cx, dx
endif

	call	GrObjGetNumberOfGradientIntervals
	mov	gradientLocal.GD_requestedIntervals,cx

	call	GrObjGetGradientColors
	call	GrObjCalcActualIntervals
	call	GrObjCalcColorDeltas
	call	GrObjCalcRadialIntervalDeltas
	call	GrObjInitRadialIntervalRect

	.leave

	ret
GrObjInitRadialGradientData		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjCalcRadialIntervalDeltas
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the interval deltas
		

CALLED BY:	INTERNAL 
		GrObjInitRadialGradientData

PASS:		
		*ds:si - object
		bp - inherited GradientData


RETURN:		
		GD_intervalDeltaWidth
		GD_intervalDeltaHeight


DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		width of bounding rect/(# intervals * 2)
		height of bounding rect/(# intervals * 2)

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/22/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjCalcRadialIntervalDeltas		proc	far

gradientLocal	local GradientData	

	uses	ax,bx,cx,dx
	.enter inherit

	mov	bx,gradientLocal.GD_actualIntervals
	shl	bx,1
	clr	ax

	movwwf	dxcx,gradientLocal.GD_boundingRect.RWWF_right
	subwwf	dxcx,gradientLocal.GD_boundingRect.RWWF_left
	call	GrSDivWWFixed
	movwwf	gradientLocal.GD_intervalDeltaWidth,dxcx
	movwwf	dxcx,gradientLocal.GD_boundingRect.RWWF_bottom
	subwwf	dxcx,gradientLocal.GD_boundingRect.RWWF_top
	call	GrSDivWWFixed
	movwwf	gradientLocal.GD_intervalDeltaHeight,dxcx

	.leave
	ret

GrObjCalcRadialIntervalDeltas		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjInitRadialIntervalRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize interval rect to first shape size
		

CALLED BY:	INTERNAL 
		GrObjInitRadialGradientData

PASS:		
		*ds:si - object
		bp - inherited GradientData

RETURN:		
		GD_intervalRect


DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		Draw from larger to smaller shapes. Init to bounding rect.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/22/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjInitRadialIntervalRect		proc	far

gradientLocal	local GradientData	

	uses	cx,dx
	.enter inherit

	movwwf	dxcx,gradientLocal.GD_boundingRect.RWWF_left
	movwwf  gradientLocal.GD_intervalRect.RWWF_left,dxcx
	movwwf	dxcx,gradientLocal.GD_boundingRect.RWWF_right
	movwwf  gradientLocal.GD_intervalRect.RWWF_right,dxcx

	movwwf	dxcx,gradientLocal.GD_boundingRect.RWWF_top
	movwwf  gradientLocal.GD_intervalRect.RWWF_top,dxcx
	movwwf	dxcx,gradientLocal.GD_boundingRect.RWWF_bottom
	movwwf  gradientLocal.GD_intervalRect.RWWF_bottom,dxcx

	.leave
	ret

GrObjInitRadialIntervalRect		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjAdvanceRadialIntervalRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Advance the interval rect to next smaller size

CALLED BY:	INTERNAL 
		GrObjDrawRadialGradient

PASS:		bp - inherited GradientData

RETURN:		
		GD_intervalRect has moved		

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
	srs	9/ 4/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjAdvanceRadialIntervalRect		proc	far

gradientLocal	local GradientData	

	uses	cx,dx
	.enter inherit

	movwwf	dxcx,gradientLocal.GD_intervalDeltaWidth
	addwwf	gradientLocal.GD_intervalRect.RWWF_left,dxcx
	subwwf	gradientLocal.GD_intervalRect.RWWF_right,dxcx

	movwwf	dxcx,gradientLocal.GD_intervalDeltaHeight
	addwwf	gradientLocal.GD_intervalRect.RWWF_top,dxcx
	subwwf	gradientLocal.GD_intervalRect.RWWF_bottom,dxcx

	.leave
	ret
GrObjAdvanceRadialIntervalRect		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjDrawRadialIntervalEllipse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the interval ellipse

CALLED BY:	INTERNAL
		GrObjDrawLinearGradient

PASS:		
		dx - gstate
		bp - inherited GradientData

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
	srs	9/ 4/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjDrawRadialIntervalEllipse		proc	far
	uses	di,ax,bx,cx,dx,si
	.enter inherit GrObjDrawLinearGradient

	mov	di,dx					;gstate

	movwwf	axdx,gradientLocal.GD_intervalRect.RWWF_left
	rndwwf	axdx
	movwwf	bxdx,gradientLocal.GD_intervalRect.RWWF_top
	rndwwf	bxdx
	movwwf	cxdx,gradientLocal.GD_intervalRect.RWWF_right
	rndwwf	cxdx
	movwwf	dxsi,gradientLocal.GD_intervalRect.RWWF_bottom
	rndwwf	dxsi
	call	GrFillEllipse

	.leave
	ret
GrObjDrawRadialIntervalEllipse		endp

GrObjSpecialGraphicsCode	ends




