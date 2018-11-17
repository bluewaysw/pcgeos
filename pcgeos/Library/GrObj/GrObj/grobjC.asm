COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Library/GrObj/GrObj
FILE:		grobjC.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	anna	7/22/92		Initial version

DESCRIPTION:
	This file contains C interface routines for the GrObj

	$Id: grobjC.asm,v 1.1 97/04/04 18:07:14 newdeal Exp $

------------------------------------------------------------------------------@

	SetGeosConvention

C_Code	segment resource

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrObjGetSpriteOBJECTDimensions

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	
C DECLARATION:	extern void
		_far _pascal GrObjGetSpriteOBJECTDimensions(
			optr spriteObject,
			WWFixed *width,
			WWFixed *height)
			
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	anna	7/22/92		Initial version
	
------------------------------------------------------------------------------@
GROBJGETSPRITEOBJECTDIMENSIONS proc	far spriteOD:optr,
					   spriteWidth:fptr,
					   spriteHeight:fptr
	uses	es, ds, di, si
	.enter

	movdw	bxsi, spriteOD
	call	MemDerefDS		; *ds:si <-instance data of object 

	call	GrObjGetSpriteOBJECTDimensions
		
	; Put return values into the right places.
	les	di, spriteHeight		; bx:ax = height
	stosw
	mov	ax, bx
	stosw

	les	di, spriteWidth		; dx:cx = width
	mov	ax, cx
	stosw
	mov	ax, dx
	stosw

	.leave
	ret

GROBJGETSPRITEOBJECTDIMENSIONS endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrObjGetAbsSpriteOBJECTDimensions

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	
C DECLARATION:	extern void
		_far _pascal GrObjGetAbsSpriteOBJECTDimensions(
			optr spriteObject,
			WWFixed *width,
			WWFixed *height)
			
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	anna	8/19/92		Initial version
	
------------------------------------------------------------------------------@
GROBJGETABSSPRITEOBJECTDIMENSIONS proc	far spriteOD:optr,
					   spriteWidth:fptr,
					   spriteHeight:fptr
	uses	es, ds, di, si
	.enter

	movdw	bxsi, spriteOD
	call	MemDerefDS		; *ds:si <-instance data of object 

	call	GrObjGetAbsSpriteOBJECTDimensions
		
	; Put return values into the right places.
	les	di, spriteHeight		; bx:ax = height
	stosw
	mov	ax, bx
	stosw

	les	di, spriteWidth		; dx:cx = width
	mov	ax, cx
	stosw
	mov	ax, dx
	stosw

	.leave
	ret

GROBJGETABSSPRITEOBJECTDIMENSIONS endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrObjGetNormalOBJECTDimensions

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	
C DECLARATION:	extern void
		_far _pascal GrObjGetNormalOBJECTDimensions(
			optr normalObject,
			WWFixed *normalWidth,
			WWFixed *normalHeight)
			
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	anna	7/22/92		Initial version
	
------------------------------------------------------------------------------@
GROBJGETNORMALOBJECTDIMENSIONS proc	far normalOD:optr,
					   normalWidth:fptr,
					   normalHeight:fptr
	uses	es, ds, di, si
	.enter

	movdw	bxsi, normalOD
	call	MemDerefDS		; *ds:si <-instance data of object 

	call	GrObjGetNormalOBJECTDimensions
		
	; Put return values into the right places.
	les	di, normalHeight		; bx:ax = height
	stosw
	mov	ax, bx
	stosw

	les	di, normalWidth		; dx:cx = width
	mov	ax, cx
	stosw
	mov	ax, dx
	stosw

	.leave
	ret

GROBJGETNORMALOBJECTDIMENSIONS endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrObjCalcCorners

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	
C DECLARATION:	extern void
		_far _pascal GrObjCalcCorners(
			WWFixed width,
			WWFixed height,
			word *negWidthOver2,
			word *negHeightOver2,
			word *posWidthOver2,
			word *posHeightOver2,
			GStateHandle gstate)
			
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	anna	7/22/92		Initial version
	
------------------------------------------------------------------------------@
GROBJCALCCORNERS proc	far objectWidth:dword,
					   objectHeight:dword,
					   negWidthOver2:fptr,
					   negHeightOver2:fptr,
					   posWidthOver2:fptr,
					   posHeightOver2:fptr,
					   gstate:hptr
	uses	es, di
	.enter

	mov	cx, objectWidth.low
	mov	dx, objectWidth.high
	mov	ax, objectHeight.low
	mov	bx, objectHeight.high
	mov	di, gstate

	call	GrObjCalcCorners
		
	; Put return values into the right places.
	les	di, negWidthOver2		; ax = -w/2
	stosw
	les	di, negHeightOver2		; bx = -h/2
	mov	ax, bx
	stosw
	les	di, posWidthOver2		; cx = w/2
	mov	ax, cx
	stosw
	les	di, posHeightOver2		; dx = h/2
	mov	ax, dx
	stosw

	.leave
	ret

GROBJCALCCORNERS endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrObjResizeSpriteRelativeToSprite

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	
C DECLARATION:	extern void
		_far _pascal GrObjResizeSpriteRelativeToSprite(
			optr spriteObject,
			word grObjHandleSpec,
			PointDWFixed *objectDeltaResize)
			
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	anna	8/19/92		Initial version
	
------------------------------------------------------------------------------@
GROBJRESIZESPRITERELATIVETOSPRITE proc	far spriteOD:optr,
					   grObjHandleSpec:word,
					   objectDeltaResize:fptr
	uses	ds, si
	.enter

	movdw	bxsi, spriteOD
	call	MemDerefDS		; *ds:si <-instance data of object 

EC <	mov	ax, ss							>
EC <	cmp	ax, objectDeltaResize.high				>
EC <	ERROR_NE GROBJ_POINTER_SEGMENT_NOT_SAME_AS_STACK_FRAME		>

	mov	cx, grObjHandleSpec

   	mov	bp, objectDeltaResize.low	; ss:bp <- pointer to 
						; PointDWFixed

	call	GrObjResizeSpriteRelativeToSprite
		
	.leave
	ret

GROBJRESIZESPRITERELATIVETOSPRITE endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrObjMessageToBody

		This function sends a message to a GrObject's body.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
		Unlike the assembly version, only messages can be
		sent off, with no MessageFlags.

		(It trashes ax, too).

C DECLARATION:	extern void
		_far _pascal GrObjMessageToBody(
			Segment grobjSeg,
			Message msg,
			word cx_param,
			word dx_param,
			word bp_param)
			
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jeremy	10/6/92		Initial version
	
------------------------------------------------------------------------------@
GROBJMESSAGETOBODY proc	far grobjSeg:word,
		   	    msg:word,
		   	    cx_param:word,
		   	    dx_param:word,
		   	    bp_param:word
	uses	ds, di
	.enter

	mov	ds, grobjSeg
	mov	ax, msg
	clr	di			; No MessageFlags
	mov	cx, cx_param		; cx, dx, bp - parameters to message
	mov	dx, dx_param
	mov	bp, bp_param		; No looking at locals now...
	
	call	GrObjMessageToBody

	.leave
	ret

GROBJMESSAGETOBODY endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrObjGetBodyOD

		This function returns the OD (optr) of the body a
		GrObject is a member of.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

C DECLARATION:	extern otpr
		_far _pascal GrObjGetBodyOD(Segment grobjSeg)
			
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jeremy	1/27/93		Initial version
	
------------------------------------------------------------------------------@
GROBJGETBODYOD proc	far grobjSeg:word

	uses	ds, si
	.enter

	mov	ds, grobjSeg

	GrObjGetBodyOD			; bx:si <- OD of body

	mov	dx, bx			; dx:ax <- OD of body
	mov	ax, si

	.leave
	ret

GROBJGETBODYOD endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GROBJGETCURRENTHANDLESIZE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the current width and height of handle size

CALLED BY:	INTERNAL

PASS:		
		ds - segment of object block

RETURN:		
		ax - max line width
		bl - current handle width
		bh - current handle height

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/21/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GROBJGETCURRENTHANDLESIZE		proc	far	grobjSeg:word
	uses	ds
	.enter

	mov	ds, grobjSeg

	call	GrObjGetCurrentHandleSize

	mov	dx, bx			

	.leave
	ret
GROBJGETCURRENTHANDLESIZE		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GROBJDRAWONEHANDLE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw one of the selection handles.

CALLED BY:	GLOBAL

PASS:		
		*ds:si - GrObject
		cl - GrObjHandleSpecification		
		di - gstate
		bl - handle width in DOCUMENT coords
		bh - handle height in DOCUMENT coords

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
	srs	4/ 2/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GROBJDRAWONEHANDLE	proc	far	grobjOD:optr,
					handleSpec:word,
					gstate:hptr.GState,
					handleWidth:word,
					handleHeight:word
	uses	ds, si, di
	.enter

	movdw	bxsi, grobjOD
	call	MemDerefDS

	mov	cl, handleSpec.low
	mov	di, gstate
	mov	bl, handleWidth.low
	mov	bh, handleHeight.low

	call	GrObjDrawOneHandle

	.leave
	ret
GROBJDRAWONEHANDLE	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GROBJGETCURRENTNUDGEUNITS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the current width and height of handle size

CALLED BY:	INTERNAL

PASS:		
		ds - segment of object block

RETURN:		
		ax - max line width
		bl - current handle width
		bh - current handle height

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/21/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GROBJGETCURRENTNUDGEUNITS		proc	far	grobjSeg:word
	uses	ds
	.enter

	mov	ds, grobjSeg

	call	GrObjGetCurrentNudgeUnits

	mov	dx, bx

	.leave
	ret
GROBJGETCURRENTNUDGEUNITS		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GROBJDRAW32BITRECT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a rectangle from 32 bit coordinates

CALLED BY:	INTERNAL

PASS:		ds:bx - RectDWord
		di - gstate

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		This rarely used piece of functionality is pissing me off. 
		I have slapped it together attempting to trade off speed
		for the sake of size. So I always calculate any data that
		might be used more than once and stick it in a stack frame.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This will only work for lines of thickness one

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/ 1/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GROBJDRAW32BITRECT	proc	far	rect:fptr.RectDWord,
					gstate:hptr.GState
	uses	ds, di

	.enter

	lds	bx, rect
	mov	di, gstate

	call	GrObjDraw32BitRect

	.leave
	ret
GROBJDRAW32BITRECT	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GROBJBODYPARSEGSTRING
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Just take the whole gstring and cram it into one gstring object

		NOTE:******
		The caller must
		have explicity set or cleared ATTR_GB_PASTE_CALL_BACK 
		before calling this routine.

CALLED BY:	INTERNAL
		GrObjBodyImport
		GrObjBodyPasteCommon
		
PASS:		
		*ds:si = GrObjBody
		bx - VM file handle of gstring
		ax - vm block handle of gstring
		ss:[bp] - PointDFixed position to center the gstring on.

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
	srs	9/23/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GROBJBODYPARSEGSTRING		proc	far	bodyOD:optr,
						gstringFile:hptr,
						gstringBlock:word,
						origin:fptr.PointDWFixed
	uses	ds, si
	.enter

	movdw	bxsi, bodyOD
	call	MemDerefDS

	mov	bx, gstringFile
	mov	ax, gstringBlock
	lea	bp, origin

	call	GrObjBodyParseGString

	.leave
	ret
GROBJBODYPARSEGSTRING	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineGuardianTransformSplinePoints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Transform spline points by the scale factor from the
		vis bounds to the object dimensions.
		
CALLED BY:	INTERNAL
		SplineGuardianCompleteTransform

PASS:		
		*ds:si - SplineGuardianClass

RETURN:		
		Spline has been converted

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		WARNING - may cause block to move or object to move within block

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	1/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SPLINEGUARDIANTRANSFORMSPLINEPOINTS	proc	far	guardianOD:optr

	uses	ds, si
	.enter

	movdw	bxsi, guardianOD
	call	MemDerefDS

	call	SplineGuardianTransformSplinePoints

	.leave
	ret
SPLINEGUARDIANTRANSFORMSPLINEPOINTS	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GROBJAPPLYNORMALTRANSFORM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Apply normal transform information  to passed gstate

CALLED BY:	INTERNAL
		GrObjCalcDWFixedMappedCorners

PASS:		
		*(ds:si) - instance data
		di - gstate
RETURN:		
		di - gstate with transforms applied
		carry set if passed GrObjTransMatrix = I

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		set documentOffset from 32 integer bits draw pt 
		apply fractional translation of draw pt
		rotate object
		apply scale factor

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/20/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GROBJAPPLYNORMALTRANSFORM	proc	far	grobjOD:optr,
						gstate:hptr.GState

	uses	ds, si, di
	.enter

	movdw	bxsi, grobjOD
	call	MemDerefDS

	mov	di, gstate

	call	GrObjApplyNormalTransform

	.leave
	ret
GROBJAPPLYNORMALTRANSFORM	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GROBJTESTSUPPORTEDTRANSFERFORMATS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Tests for "pasteable" formats on the clipboard

Pass:		bp - ClipboardItemFlags (CIF_QUICK)

Return:		carry set if pasteable format exists
			^lcx:dx - owner
		carry clear if no pasteable format exists
			cx,dx - 0

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jul 20, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GROBJTESTSUPPORTEDTRANSFERFORMATS	proc	far	cif:ClipboardItemFlags
	.enter

	mov	bp, cif

	call	GrObjTestSupportedTransferFormats

	mov_tr	ax, cx
	jc	done

	clr	cx, dx

done:
	.leave
	ret
GROBJTESTSUPPORTEDTRANSFERFORMATS	endp

C_Code	ends

	SetDefaultConvention

