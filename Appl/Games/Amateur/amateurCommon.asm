COMMENT @---------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All rights reserved

PROJECT:	Amateur Night
MODULE:		common
FILE:		amateurCommon.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------

DESCRIPTION:	common routines

	$Id: amateurCommon.asm,v 1.1 97/04/04 15:12:26 newdeal Exp $
-----------------------------------------------------------------------------@





AmateurCode	segment resource




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawDot
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a dot (peanut or pellet)

CALLED BY:

PASS:		cx, dx - position
		ax - color

RETURN:		nothing 

DESTROYED:	ax,bx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/11/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawDot	proc near	
	uses	di
	.enter
	mov	di, es:[gstate]
	call	GrSetAreaColor
	mov	ax, cx
	mov	bx, dx
	call	GrDrawPoint
	.leave
	ret
DrawDot		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetBackgroundColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the current background color

CALLED BY:	everywhere

PASS:		ds - segment of gameObjects

RETURN:		ax - background color

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	
	Just go in and look at the content's instance data w/o regard
	for object orientation, etc.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/ 7/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetBackgroundColor	proc near	
	uses	si
	class	AmateurContentClass 
	.enter
	assume	ds:GameObjects
	mov	si, ds:[ContentObject]
	add	si, ds:[si].Vis_offset
	mov	ax, ds:[si].ACI_colorInfo.CI_background
	assume	ds:dgroup
	.leave
	ret
GetBackgroundColor	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcClownSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	return the clown's size

CALLED BY:

PASS:		es - dgroup

RETURN:		cx, dx - clown size

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/26/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcClownSize	proc near
	.enter

	cmp	es:[displayType], CGA_DISPLAY_TYPE
	je	cga

	mov	cx, STANDARD_CLOWN_WIDTH
	mov	dx, STANDARD_CLOWN_HEIGHT
	jmp	done
cga:
	mov	cx, CGA_CLOWN_WIDTH
	mov	dx, CGA_CLOWN_HEIGHT
done:
	mov	es:[clownWidth], cx
	mov	es:[clownHeight], dx

	.leave
	ret
CalcClownSize	endp




AmateurCode	ends
