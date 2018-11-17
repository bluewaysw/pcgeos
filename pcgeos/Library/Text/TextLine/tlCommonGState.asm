COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		tlCommonGState.asm

AUTHOR:		John Wedgwood, Jan  3, 1992

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	 1/ 3/92	Initial revision

DESCRIPTION:
	GState stuff...

	$Id: tlCommonGState.asm,v 1.1 97/04/07 11:20:40 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextFixed	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CommonFieldSetupGState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up a gstate for drawing.

CALLED BY:	CommonFieldTextPosition
PASS:		*ds:si	= Instance ptr
		es:di	= Field
		ax	= LineFlags for the line containing this field
		dx.bx	= Space-padding for this field
RETURN:		di	= GState
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/ 3/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CommonFieldSetupGState	proc	near
	class	VisTextClass
	uses	ax, bx, cx
	.enter
	;
	; Set the space padding correctly.
	;
	call	TextFixed_DerefVis_DI		; ds:di <- instance ptr
	mov	di, ds:[di].VTI_gstate		; di <- gstate handle.

	mov	bl, bh				; dx.bl <- space padding
	call	GrSetTextSpacePad		; Set text space padding.
	
	;
	; We are going to set up:
	;	al	= Bits to set in the gstate's TextMode
	;	ah	= Bits to clear in the gstate's TextMode
	; The default situation has no bits to set and optional-hyphens cleared.
	;
	mov	cx, ax				; cx <- LineFlags

	clr	al				; al/ah <- value for TextMode
	mov	ah, mask TM_DRAW_OPTIONAL_HYPHENS

	test	cx, mask LF_ENDS_IN_OPTIONAL_HYPHEN
	jz	setTextMode
	xchg	al, ah				; Want optional-hyphens
setTextMode:

	;
	; al	= Bits to set in TextMode
	; ah	= Bits to clear in TextMode
	;
	call	GrSetTextMode			; Set the mode
	.leave
	ret
CommonFieldSetupGState	endp


TextFixed	ends
