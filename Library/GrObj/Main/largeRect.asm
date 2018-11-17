COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GrObj
FILE:		largeRect.asm

AUTHOR:		Steve Scholl

ROUTINES:
	Name			Description
	----			-----------
INT	GrObjDraw32BitRect	Draw rectangle with 32 bit bounds


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Steve	8/01/91		Initial revision


DESCRIPTION:
		

	$Id: largeRect.asm,v 1.1 97/04/04 18:05:17 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



GrObjRequiredExtInteractive2Code	segment resource




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjDraw32BitRect
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
DrawBigRectData	struct
	DBRD_maskBounds		RectDWord		;window mask bounds
	DBRD_gstate		hptr.GState	;gstate to draw through
	DBRD_horizMid		sdword		;horizontal midpoint of
						;top and bottom lines. used
						;as document offset
	DBRD_vertMid		sdword		;vertical midpoint of
						;left and right lines. used
						;as document offset
	DBRD_left		sword		;left of top and bottom lines
						;relative to horizMid
	DBRD_top		sword		;top of left and right lines
						;relative to vertMid
	DBRD_right		sword		;right of top and bottom lines
						;relative to horizMid
	DBRD_bottom		sword		;bottom of left and right lines
						;relative to vertMid

DrawBigRectData ends	


GrObjDraw32BitRect		proc	far

rectFrame	local	DrawBigRectData

	uses	ax,cx,dx,si,ds

	call	OrderRectDWord

	.enter


	mov	rectFrame.DBRD_gstate,di

	;    Fill part of local variables with window mask bounds
	;

	push	ds				;rect to draw seg
	segmov	ds,ss,ax
	lea	si,ss:[rectFrame.DBRD_maskBounds]
	call	GrGetMaskBoundsDWord
	pop	ds				;rect to draw seg
	jc	done				;jmp if null mask

	;    Do basic trivial reject
	;

	;    Bail if left rect > right bounds
	;

	mov	si,offset RD_left
	mov	di,(offset rectFrame) + offset (DBRD_maskBounds.RD_right)
	call	DWGSetCarry
	jc	done

	;    Bail if right rect < left bounds    
	;

	mov	si,offset RD_right
	mov	di,(offset rectFrame) + offset (DBRD_maskBounds.RD_left)
	call	DWLSetCarry
	jc	done

	;    Bail if top rect > bottom bounds
	;

	mov	si,offset RD_top
	mov	di,(offset rectFrame)+(offset DBRD_maskBounds.RD_bottom)
	call	DWGSetCarry
	jc	done

	;    jump to continue if bottom rect >= top bounds    
	;

	mov	si,RD_bottom
	mov	di,(offset rectFrame) + (offset DBRD_maskBounds.RD_top )
	call	DWGESetCarry
	jc	continue
	
done:
	mov	di, rectFrame.DBRD_gstate		;don't destroy

	.leave
	ret


continue:
	;   Calculate any info that may be needed in drawing the
	;   the lines.
	;

	;    Get max of lefts
	;

	mov	si,offset RD_left
	mov	di,(offset rectFrame) + (offset DBRD_maskBounds.RD_left )
	call	DWMax	
	push	dx,cx					;maxLeft

	;    Get min of rights 
	;

	mov	si,offset RD_right
	mov	di,(offset rectFrame) + (offset DBRD_maskBounds.RD_right )
	call	DWMin
	pop	si,di					;maxLeft
	push	dx,cx					;minRight

	;    Calc x of middle of horizontal line to be used as document offset
	;    ((right-left)/2)+left
	;

	sub	cx,di					;right.low - left.low
	sbb	dx,si					;right.high - left.high
	sar	dx,1
	rcr	cx,1
	add	cx,di					;add back left.low
	adc	dx,si					;add back left.high
	mov	rectFrame.DBRD_horizMid.low,cx
	mov	rectFrame.DBRD_horizMid.high,dx

	;    Subtract document offset from left of line
	;    and make the result into a word, if possible
	;

	sub	di,cx					;left.low-mid.low
	sbb	si,dx					;left.high-mid.high
	call	DWtoW
	mov	rectFrame.DBRD_left,di
	pop	si,di					;minRight
	jnc	done					;bail if left was
							;not a word

	;    Subtract document offset from right of line
	;    and make the result into a word, if possible
	;

	sub	di,cx				;right.low - mid.low
	sbb	si,dx				;right.high - mid.high
	call	DWtoW
	jnc	done				;bail if right not a word
	mov	rectFrame.DBRD_right,di

	;    Get max of tops
	;

	mov	si,offset RD_top
	mov	di,(offset rectFrame) + (offset DBRD_maskBounds.RD_top)
	call	DWMax	
	push	dx,cx					;maxTop

	;    Get min of bottom
	;

	mov	si,offset RD_bottom
	mov	di,(offset rectFrame) + (offset DBRD_maskBounds.RD_bottom)
	call	DWMin
	pop	si,di					;maxTop
	push	dx,cx					;minBottom

	;    Calc y of middle of vertical lines to be used as document offset
	;    ((bottom-top)/2)+top
	;

	sub	cx,di				;bottom.low - top.low
	sbb	dx,si				;bottom.high - top.high
	sar	dx,1
	rcr	cx,1
	add	cx,di				;add back top.low
	adc	dx,si				;add back top.high
	mov	rectFrame.DBRD_vertMid.low,cx
	mov	rectFrame.DBRD_vertMid.high,dx

	;    Subtract document offset from top of line
	;    and make the result into a word, if possible
	;

	sub	di,cx					;top.low-mid.low
	sbb	si,dx					;top.high-mid.high
	call	DWtoW
	mov	rectFrame.DBRD_top,di
	pop	si,di					;minBottom
	jnc	doneDone				;bail if top was
							;not a word

	;    Subtract document offset from bottom of line
	;    and make the result into a word, if possible
	;

	sub	di,cx				;bottom.low - mid.low
	sbb	si,dx				;bottom.high - mid.high
	call	DWtoW
	jnc	doneDone			;bail if bottom not a word
	mov	rectFrame.DBRD_bottom,di

	;    Draw whichever lines need to be drawn
	;


	call	DrawTopLine
	call	DrawBottomLine
	call	DrawLeftLine
	call	DrawRightLine
doneDone:
	jmp	done


GrObjDraw32BitRect		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OrderRectDWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Order the coordinates in a RectDWord

CALLED BY:	INTERNAL

PASS:		
		ds:bx - RectDWord

RETURN:		
		ds:bx - RectDWord with ordered coordinates

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/ 1/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OrderRectDWord		proc	near
	uses	ax,cx
	.enter

	mov	ax,ds:[bx].RD_left.low
	mov	cx,ds:[bx].RD_left.high
	cmp	cx,ds:[bx].RD_right.high
	jl	checkTopBottom
	jg	switchLeftRight
	cmp	ax,ds:[bx].RD_right.low
	ja	switchLeftRight

checkTopBottom:
	mov	ax,ds:[bx].RD_top.low
	mov	cx,ds:[bx].RD_top.high
	cmp	cx,ds:[bx].RD_bottom.high
	jl	done
	jg	switchTopBottom
	cmp	ax,ds:[bx].RD_bottom.low
	ja	switchTopBottom

done:
	.leave
	ret

switchLeftRight:
	xchg	ax,ds:[bx].RD_right.low
	xchg	cx,ds:[bx].RD_right.high
	mov	ds:[bx].RD_left.low,ax
	mov	ds:[bx].RD_left.high,cx
	jmp	short checkTopBottom

switchTopBottom:
	xchg	ax,ds:[bx].RD_bottom.low
	xchg	cx,ds:[bx].RD_bottom.high
	mov	ds:[bx].RD_top.low,ax
	mov	ds:[bx].RD_top.high,cx
	jmp	short done

OrderRectDWord		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawTopLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the top line of the 32 bit rect if need be

CALLED BY:	INTERNAL

PASS:		
		ds:[bx] - RectDWord to draw
		ss:[bp] - inherited DrawBigRectData

RETURN:		
		nothing

DESTROYED:	
		ax,cx,dx,di,si

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/ 1/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


DrawTopLine		proc	near

rectFrame	local	DrawBigRectData

	uses	bx
	.enter	inherit

	;    If top rect >= top bounds then draw top line
	;

	mov	si,offset RD_top
	mov	di,(offset rectFrame) + (offset DBRD_maskBounds.RD_top)
	call	DWGESetCarry
	jnc	done

	mov	di,rectFrame.DBRD_gstate
	call	GrSaveTransform

	mov	cx,rectFrame.DBRD_horizMid.low
	mov	dx,rectFrame.DBRD_horizMid.high
	mov	ax,ds:[bx].RD_top.low
	mov	bx,ds:[bx].RD_top.high
	call	GrApplyTranslationDWord

	;    Draw that line
	;

	call	DrawLineLeftToRight

	call	GrRestoreTransform
done:

	.leave
	ret
DrawTopLine		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawBottomLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the top line of the 32 bit rect if need be

CALLED BY:	INTERNAL

PASS:		
		ds:[bx] - RectDWord to draw
		ss:[bp] - inherited DrawBigRectData

RETURN:		
		nothing

DESTROYED:	
		ax,cx,dx,di,si

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/ 1/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


DrawBottomLine		proc	near

rectFrame	local	DrawBigRectData

	uses	bx
	.enter	inherit

	;    If bottom rect <= bottom bounds then draw bottom line
	;

	mov	si,offset RD_bottom
	mov	di,(offset rectFrame)+(offset DBRD_maskBounds.RD_bottom)
	call	DWLESetCarry
	jnc	done

	mov	di,rectFrame.DBRD_gstate
	call	GrSaveTransform

	;    Set extended translation to the middle of the line
	;

	mov	cx,rectFrame.DBRD_horizMid.low
	mov	dx,rectFrame.DBRD_horizMid.high
	mov	ax,ds:[bx].RD_bottom.low
	mov	bx,ds:[bx].RD_bottom.high
	call	GrApplyTranslationDWord

	;    Draw that line
	;
	
	call	DrawLineLeftToRight

	call	GrRestoreTransform
done:

	.leave
	ret
DrawBottomLine		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawLineLeftToRight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws a line from rectFrame.DBRD_left to DBRD_right at 0

CALLED BY:	INTERNAL

PASS:		
		ss:bp - inherited DrawBigRectData
		di - gstate
RETURN:		
		nothing

DESTROYED:	
		ax,bx,cx,dx

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/ 1/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


DrawLineLeftToRight		proc	near

rectFrame	local	DrawBigRectData

	.enter	inherit

	mov	ax,rectFrame.DBRD_left
	mov	cx,rectFrame.DBRD_right
	clr	bx				;top
	mov	dx,bx				;bottom
	call	GrDrawLine

	.leave
	ret
DrawLineLeftToRight		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawLeftLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the left line of the 32 bit rect if need be

CALLED BY:	INTERNAL

PASS:		
		ds:[bx] - RectDWord to draw
		ss:[bp] - inherited DrawBigRectData

RETURN:		
		nothing

DESTROYED:	
		ax,cx,dx,di,si

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/ 1/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


DrawLeftLine		proc	near

rectFrame	local	DrawBigRectData

	uses	bx
	.enter	inherit

	;    If left rect >= left bounds then draw left line
	;

	mov	si,offset RD_left
	mov	di,(offset rectFrame)+(offset DBRD_maskBounds.RD_left)
	call	DWGESetCarry
	jnc	done

	mov	di,rectFrame.DBRD_gstate
	call	GrSaveTransform

	mov	cx,ds:[bx].RD_left.low
	mov	dx,ds:[bx].RD_left.high
	mov	ax,rectFrame.DBRD_vertMid.low
	mov	bx,rectFrame.DBRD_vertMid.high
	call	GrApplyTranslationDWord

	;    Draw that line
	;

	call	DrawLineTopToBottom

	call	GrRestoreTransform
done:

	.leave
	ret
DrawLeftLine		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawRightLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the right line of the 32 bit rect if need be

CALLED BY:	INTERNAL

PASS:		
		ds:[bx] - RectDWord to draw
		ss:[bp] - inherited DrawBigRectData

RETURN:		
		nothing

DESTROYED:	
		ax,cx,dx,di,si

PSEUDO CODE/STRATEGY:
		none

]KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/ 1/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


DrawRightLine		proc	near

rectFrame	local	DrawBigRectData

	uses	bx
	.enter	inherit

	;    If right rect <= right bounds then draw bottom line
	;

	mov	si,offset RD_right
	mov	di,(offset rectFrame)+(offset DBRD_maskBounds.RD_right)
	call	DWLESetCarry
	jnc	done

	mov	di,rectFrame.DBRD_gstate
	call	GrSaveTransform

	;    Set extended translation to the middle of the line
	;

	mov	dx,ds:[bx].RD_right.high
	mov	cx,ds:[bx].RD_right.low
	mov	ax,rectFrame.DBRD_vertMid.low
	mov	bx,rectFrame.DBRD_vertMid.high
	call	GrApplyTranslationDWord

	;    Draw that line
	;
	
	call	DrawLineTopToBottom

	call	GrRestoreTransform
done:

	.leave
	ret
DrawRightLine		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawLineTopToBottom
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws a line from rectFrame.DBRD_top to DBRD_bottom at 0

CALLED BY:	INTERNAL

PASS:		
		ss:bp - inherited DrawBigRectData
		di - gstate
RETURN:		
		nothing

DESTROYED:	
		ax,bx,cx,dx

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/ 1/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


DrawLineTopToBottom		proc	near

rectFrame	local	DrawBigRectData

	.enter	inherit

	mov	bx,rectFrame.DBRD_top
	mov	dx,rectFrame.DBRD_bottom
	clr	ax				;left
	mov	cx,ax				;right
	call	GrDrawLine

	.leave
	ret
DrawLineTopToBottom		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DWtoW
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a dword to a word.

CALLED BY:	INTERNAL

PASS:		si:di - DWord

RETURN:		
		stc - successful
			di - word
		clc - cannot be converted
			
			
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/ 1/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DWtoW		proc	near
	uses	ax,dx
	.enter

	;    If the sign extension of the low word equals the high word
	;    then the value can correctly be represented by just one word
	;

	mov	ax,di
	cwd	
	cmp	si,dx
	jne	fail

	stc
done:
	.leave
	ret

fail:
	clc
	jmp	done

DWtoW		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DWGESetCarry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return carry set if the first passed dword is greater
		than or equal to the second

CALLED BY:	Internal

PASS:		
		ds:[bx][si] - first dword
		ss:[bp][di] - second dword

RETURN:		
		carry set if first dword is greater than or equal to
		the second dword		

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/ 1/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DWGESetCarry		proc	near
	uses	ax
	.enter

	mov	ax,ds:[bx][si].high
	cmp	ax,ss:[bp][di].high
	jg	setCarry
	jl	clearCarry
	mov	ax,ds:[bx][si].low
	cmp	ax,ss:[bp][di].low
	jae	setCarry
	
clearCarry:
	clc
done:
	.leave
	ret

setCarry:
	stc
	jmp	short done

DWGESetCarry		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DWLESetCarry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return carry set if the first passed dword is less
		than or equal to the second

CALLED BY:	Internal

PASS:		
		ss:[bp][si] - first dword
		ds:[bx][di] - second dword

RETURN:		
		carry set if first dword is less than or equal to
		the second dword		

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/ 1/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DWLESetCarry		proc	near
	.enter

	call	DWGSetCarry
	cmc

	.leave
	ret
DWLESetCarry		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DWGSetCarry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return carry set if the first passed dword is greater
		than the second

CALLED BY:	Internal

PASS:		
		ds:[bx][si] - first dword
		ss:[bp][di] - second dword

RETURN:		
		carry set if first dword is greater than 
		the second dword		

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/ 1/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DWGSetCarry		proc	near
	uses	ax
	.enter

	mov	ax,ds:[bx][si].high
	cmp	ax,ss:[bp][di].high
	jg	setCarry
	jl	clearCarry
	mov	ax,ds:[bx][si].low
	cmp	ax,ss:[bp][di].low
	ja	setCarry
	
clearCarry:
	clc
done:
	.leave
	ret

setCarry:
	stc
	jmp	short done

DWGSetCarry		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DWLSetCarry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return carry set if the first passed dword is less
		than the second

CALLED BY:	Internal

PASS:		
		ds:[bx][si] - first dword
		ss:[bp][di] - second dword

RETURN:		
		carry set if first dword is less than 
		the second dword		

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/ 1/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DWLSetCarry		proc	near
	.enter

	call	DWGESetCarry
	cmc

	.leave
	ret
DWLSetCarry		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DWMax
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the max of the two passed dwords

CALLED BY:	INTERNAL

PASS:		
		ds:[bx][si] - first dword
		ss:[bp][di] - second dword

RETURN:		
		dx:cx - max of passed dwords

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/ 1/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DWMax		proc	near
	.enter


	call	DWGESetCarry
	jc	useFirst

	mov	cx,ss:[bp][di].low
	mov	dx,ss:[bp][di].high

done:
	.leave
	ret

useFirst:
	mov	cx,ds:[bx][si].low
	mov	dx,ds:[bx][si].high
	jmp	short done

DWMax		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DWMin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the max of the two passed dwords

CALLED BY:	INTERNAL

PASS:		
		ds:[bx][si] - first dword
		ss:[bp][di] - second dword

RETURN:		
		dx:cx - max of passed dwords

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/ 1/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DWMin		proc	near
	.enter


	call	DWLESetCarry
	jc	useFirst

	mov	cx,ss:[bp][di].low
	mov	dx,ss:[bp][di].high

done:
	.leave
	ret

useFirst:
	mov	cx,ds:[bx][si].low
	mov	dx,ds:[bx][si].high
	jmp	short done

DWMin		endp


GrObjRequiredExtInteractive2Code	ends






