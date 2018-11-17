COMMENT @---------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All rights reserved

PROJECT:	Amateur Night
MODULE:		Clouds
FILE:		amateurCloud.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	2/1/91		Initial rev
DESCRIPTION:

	$Id: amateurCloud.asm,v 1.1 97/04/04 15:12:30 newdeal Exp $
-----------------------------------------------------------------------------@


COMMENT @-------------------------------------------------------------------
		CloudStart		
----------------------------------------------------------------------------

SYNOPSIS:	Set up the variables for this cloud object
CALLED BY:	MSG_MOVE_START (ContentEndPellet)
PASS:		cx, dx = x and y position of cloud
RETURN:		nothing
DESTROYED:	nothing
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	1/91		initial revision
---------------------------------------------------------------------------@

CloudStart	method		AmateurCloudClass, MSG_MOVE_START

	mov	ds:[di].MOI_curPos.PF_x.WWF_int, cx
	mov	ds:[di].MOI_curPos.PF_y.WWF_int, dx

	mov	ds:[di].ACLI_count, 0
	mov	ds:[di].ACLI_freq, EXPL_FREQ_MIN
	mov	ds:[di].ACLI_size, EXPL_SIZE_MIN
	ret
CloudStart	endm



COMMENT @-------------------------------------------------------------------
		Cloud
----------------------------------------------------------------------------

SYNOPSIS:	continue an cloud until its size reaches max size
CALLED BY:	???

PASS:		*ds:si - cloud object
		ds:di - instance data
		es - dgroup

RETURN:		carry set iff cloud finished
		cx, dx - position
		ax - size

		
DESTROYED:	di
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	1/91		initial revision
---------------------------------------------------------------------------@

Cloud		proc near
	class	AmateurCloudClass
	.enter

	mov	di, ds:[si]

	; Position in cx, dx

	mov	cx, ds:[di].MOI_curPos.PF_x.WWF_int
	mov	dx, ds:[di].MOI_curPos.PF_y.WWF_int

	cmp	ds:[di].ACLI_count, EXPL_COUNT_MAX
	jl	stillGoing
	call	CloudEnd
	stc
	jmp	done

stillGoing:
	add	ds:[di].ACLI_size, EXPL_SIZE_INCR


	; Get the current offset to the circle table

	mov	bl, ds:[di].ACLI_count
	clr	bh
	shl	bx
	inc	ds:[di].ACLI_count	; for next time
	
	mov	si, es:CircleTable[bx]

	
	mov	ax, es:CloudColorTable[bx]
	mov	bl, es:[displayType]
	andnf	bl, mask DT_DISP_CLASS
	cmp	bl, DC_GRAY_1 shl offset DT_DISP_CLASS
	jne	color

	; display is black and white, make AX white
	mov	ax, C_WHITE
color:

	push	di
	mov	di, es:[gstate]
	call	GrSetAreaColor
	call	DrawCircle			
	pop	di


done:
	mov	ax, ds:[di].ACLI_size
	.leave
	ret

Cloud	endp
	

COMMENT @-------------------------------------------------------------------
		CloudEnd		
----------------------------------------------------------------------------

SYNOPSIS:	erase the cloud from the screen
CALLED BY:	Cloud
PASS:		di - cloud instance data

RETURN:	

DESTROYED:	ax
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	1/91		initial revision
---------------------------------------------------------------------------@

CloudEnd	proc	near 
	uses  si, di
	class	AmateurCloudClass
	.enter

	call	GetBackgroundColor

	mov	di, es:[gstate]
	call	GrSetAreaColor
	mov	si, offset CircleErase
	call	DrawCircle

	.leave
	ret

CloudEnd	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawCircle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a circle (region definition)

CALLED BY:

PASS:		cx, dx - location
		si - region to draw

RETURN:		nothing 

DESTROYED:	cx, dx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/ 7/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawCircle	proc near	
	uses	ax,bx,cx,dx,ds
	.enter
	segmov	ds, es
	clr	ax, bx
	xchg	ax, cx
	xchg	bx, dx
	call	GrDrawRegion

	.leave
	ret
DrawCircle	endp



