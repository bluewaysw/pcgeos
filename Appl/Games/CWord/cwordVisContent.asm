COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		cwordVisContent.asm

AUTHOR:		Steve Scholl, Jul 27, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Steve	7/27/94		Initial revision


DESCRIPTION:
	
		

	$Id: cwordVisContent.asm,v 1.1 97/04/04 15:14:06 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


CwordCode	segment resource

if	0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CwordVisContentMetaContentViewSizeChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Let the board know that the view size has changed

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object
		es - segment of CwordVisContent
		bp - handle of pane window
		cx - new window width in document coords
		dx - new window height in document coords

RETURN:		
		nothing
	
DESTROYED:	
		ax,cx,dx,bp

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	7/27/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CwordVisContentMetaContentViewSizeChanged method dynamic CwordVisContentClass, 
					MSG_META_CONTENT_VIEW_SIZE_CHANGED
	.enter

	call	VisSendToChildren

	mov	di,offset CwordVisContentClass
	call	ObjCallSuperNoLock	

	.leave

	Destroy ax,cx,dx,bp
	ret

CwordVisContentMetaContentViewSizeChanged		endm

endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CwordVisContentMetaQueryIfPressIsInk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets up the gesture callback routine and replies with
		an IRV_DESIRES_INK always.

CALLED BY:	MSG_META_QUERY_IF_PRESS_IS_INK
PASS:		*ds:si	= CwordGenViewClass object
		ds:di	= CwordGenViewClass instance data
		ds:bx	= CwordGenViewClass object (same as *ds:si)
		es 	= segment of CwordGenViewClass
		ax	= message #
		cx, dx 	= position of START_SELECT

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	8/ 1/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CwordVisContentMetaQueryIfPressIsInk	method dynamic CwordVisContentClass, 
					MSG_META_QUERY_IF_PRESS_IS_INK
	uses	ax,cx, dx, bp
	.enter

	clr	bp			;BP <- gstate to draw through
	clr	ax			;Default width/height
	mov	cx, handle Board
	mov	dx, offset Board	;^lCX:DX - send ink to Board

	mov	bx, vseg HwrCheckIfCwordGesture
	mov	di, offset HwrCheckIfCwordGesture
	call	UserCreateInkDestinationInfo
	mov	ax,IRV_NO_INK			;assume in case of bp=0
	tst	bp
	jz	sendReply

	;    Nuke the highlight so that the user can see their ink
	;

	movdw	bxsi, cxdx				;Board OD
	mov	ax,MSG_CWORD_BOARD_ERASE_HIGHLIGHTS
	mov	di,mask MF_FIXUP_DS
	call	ObjMessage

	mov	ax, IRV_INK_WITH_STANDARD_OVERRIDE

sendReply:
	mov	cx,ax					;InkReturnValue
	mov	ax, MSG_GEN_APPLICATION_INK_QUERY_REPLY
	clr	bx					;current thread
	call	GeodeGetAppObject
	mov	di,mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret

CwordVisContentMetaQueryIfPressIsInk	endm


CwordCode	ends


