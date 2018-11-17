COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		amateurDisplay.asm

AUTHOR:		Chris Boyke

METHODS:
	Name			Description
	----			-----------

FUNCTIONS:

Scope	Name			Description
-----	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/ 7/92   	Initial version.

DESCRIPTION:
	

	$Id: amateurDisplay.asm,v 1.1 97/04/04 15:11:46 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AmateurContentGameOver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Stick the words "game over" in the middle of the screen

PASS:		*ds:si	= AmateurContentClass object
		ds:di	= AmateurContentClass instance data
		es	= Segment of AmateurContentClass.

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/ 3/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AmateurContentGameOver	method	dynamic	AmateurContentClass, 
					MSG_CONTENT_GAME_OVER
	uses	ax,cx,dx,bp
	.enter
	
	call	ContentStopTimer
	mov	ds:[di].ACI_status, AGS_OVER
	call	DisplayGameOverText

	.leave
	ret
AmateurContentGameOver	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisplayGameOverText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Display the game over text

CALLED BY:

PASS:		ds:di - content object
		es - dgroup

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/ 3/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DisplayGameOverText	proc near	
	uses	si
	.enter
	mov	si, offset GameOverText
	call	DisplayTextCentered
	.leave
	ret
DisplayGameOverText	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisplayPauseText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:

CALLED BY:

PASS:		

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/11/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisplayPauseText	proc near	
	uses	si
	.enter

	mov	si, offset GamePausedText
	call	DisplayTextCentered

	.leave
	ret
DisplayPauseText	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisplayTextCentered
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:

CALLED BY:

PASS:		

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	
	
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/11/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisplayTextCentered	proc near	
	uses	ax,bx,cx,dx,di,si,bp,ds,es
	class	AmateurContentClass 
	.enter

EC <	call	ECCheckContentDSDI		> 

	push	ds:[di].VCNI_viewWidth
	push	ds:[di].VCNI_viewHeight

	mov	di, es:[gstate]

	; Get width of game over string

	mov	bx, handle StringsUI
	call	MemLock
	mov	es, ax

	mov	si, es:[si]
	clr	cx
	segxchg	ds, es
	call	GrTextWidth
	segxchg	ds, es
	mov	bp, dx
	shr	bp
	add	bp, GAME_OVER_TEXT_MARGIN
	
	pop	bx		; view height
	pop	ax		; view width

	shr	ax, 1
	shr	bx, 1

	mov	cx, ax
	mov	dx, bx

	sub	ax, bp
	add	cx, bp

	sub	bx, GAME_OVER_TEXT_HEIGHT/2 + GAME_OVER_VERT_TEXT_MARGIN
	add	dx, GAME_OVER_TEXT_HEIGHT/2 + GAME_OVER_VERT_TEXT_MARGIN

	push	ax
	mov	ax, C_WHITE
	call	GrSetAreaColor
	pop	ax

	call	GrFillRect

	push	ax
	mov	ax, C_BLACK
	call	GrSetLineColor
	mov	dx, 2
	clr	ax
	call	GrSetLineWidth
	mov	ax, C_BLACK
	call	GrSetTextColor
	pop	ax
	call	GrDrawRect


	segxchg	ds, es
	add	ax, GAME_OVER_TEXT_MARGIN
	add	bx, GAME_OVER_VERT_TEXT_MARGIN
	clr	cx
	call	GrDrawText
	segxchg	ds, es

	mov	bx, handle StringsUI
	call	MemUnlock
	.leave
	ret
DisplayTextCentered	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ContentDisplayScore
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:

CALLED BY:

PASS:		ds:di - content
		dx - score to add

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/ 1/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ContentDisplayScore	proc near	
	uses	ax,dx,si,di
	class	AmateurContentClass 
	.enter

EC <	call	ECCheckContentDSDI		> 

	movdw	dxax, ds:[di].ACI_score
	mov	di, offset tempTextBuffer
	mov	si, offset ScoreDisplay
	call	DisplayTextCommon	
	.leave
	ret
ContentDisplayScore	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ContentDisplayPelletsLeft
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the "pellets left" counter

CALLED BY:

PASS:		ds:di - content

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/11/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ContentDisplayPelletsLeft	proc near	
	uses	di,si
	class	AmateurContentClass 
	.enter

EC <	call	ECCheckContentDSDI		> 

	clr	dx
	mov	ax, ds:[di].ACI_actInfo.AI_pellets
	mov	di, offset tempTextBuffer
	mov	si, offset PelletDisplay
	call	DisplayTextCommon	

	.leave
	ret
ContentDisplayPelletsLeft	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisplayAct
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Display the current act

CALLED BY:

PASS:		ds:di - content

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/ 7/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisplayAct	proc near	
	uses	ax,dx,si,di
	class	AmateurContentClass 
	.enter

EC <	call	ECCheckContentDSDI		> 

	clr	dx
	mov	ax, ds:[di].ACI_act
	mov	di, offset tempTextBuffer
	mov	si, offset ActDisplay
	call	DisplayTextCommon	

	.leave
	ret
DisplayAct	endp



COMMENT @---------------------------------------------------------------------
		DisplayTextCommon		
------------------------------------------------------------------------------

SYNOPSIS:	do all the nitty gritty to display numeric data as text

CALLED BY:	DisplayAct, ContentDisplayPelletsLeft, ContentDisplayScore

PASS:		dx:ax - 32-bit integer
		es:di - text buffer
		si - Gen object to display text
	
RETURN:		
DESTROYED:	
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	1/91		initial revision
---------------------------------------------------------------------------@


DisplayTextCommon	proc	near	
	uses	ax,cx,dx,di,bp
	.enter
	
	mov	cx,  mask UHTAF_NULL_TERMINATE
	call	UtilHex32ToAscii

	GetResourceHandleNS	Interface, bx
	clr	cx
	mov	dx, es
	mov	bp, di
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	di, mask MF_CALL
	call	ObjMessage
	.leave
	ret
DisplayTextCommon	endp
