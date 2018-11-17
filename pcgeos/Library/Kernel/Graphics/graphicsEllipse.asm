COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Graphics
FILE:		graphicsEllipse.asm

AUTHOR:		Ted H. Kim,  7/5/89

ROUTINES:
	Name			Description
	----			-----------
GLB	GrEllipse		draws an ellipse
GLB	GrFrameEllipse		draws a framed ellipse

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	3/89		Initial revision
	jim	8/89		moved support routines to kernel lib
	jim	1/91		moved stuff back from klib
	don	9/91		changed calls to low-level routines

DESCRIPTION:
	This file contains high-level routines that generate ellipses
	origin centered ellipses.

	$Id: graphicsEllipse.asm,v 1.1 97/04/05 01:12:48 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GraphicsArc	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrDrawEllipse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws a framed ellipse bounded by the rectangle described
		by the passed coordinates.

CALLED BY:	GLOBAL

PASS:		DI	= GState
		(AX,BX)	= Upper-left corner of bounding rectangle
		(CX,DX) = Lower-right corner of bounding rectangle

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	5/89		Initial version
	Don	9/91		Changed parameters to low-level routines

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrDrawEllipse	proc	far
		call	EnterGraphics
		call	SetDocPenPos		; update pen position
		jc	ellipseGSCommon		; if GString or Path, jump

		; Peform the normal screen drawing operations
		;
		call	TrivialRejectFar	; won't return if rejected
		mov	di, offset SetupEllipseLow
		call	DrawArcEllipseLow	; call low-level routine
		jmp	ExitGraphics
GrDrawEllipse	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrFillEllipse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws a filled ellipse bounded by the rectangle described
		by the passed coordinates.

CALLED BY:	GLOBAL

PASS:		DI	= GState
		(AX,BX)	= Upper-left corner of bounding rectangle
		(CX,DX) = Lower-right corner of bounding rectangle

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
	Uses Pitteway's algorithm for drawing ellipses
	(refer to p.266 of Fundamental Algorithms for Computer Graphics)

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	4/89		Initial version
	Ted	4/89		Does transformation and trivial rejects
	Don	9/91		Changed parameters to low-level routines

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrFillEllipse	proc	far
		call	EnterGraphicsFill
		call	SetDocPenPos		; update current position
		jc	doGString		; if segment...
		call	TrivialRejectFar	; won't return if rejected

		; Perform normal screen drawing tasks
		;
		mov	di, offset SetupEllipseLow
		call	FillArcEllipseLow	; call low-level routine
		jmp	ExitGraphics

		; Handle writing to graphics string
doGString:
		mov	ax, (GSSC_FLUSH shl 8) or GR_FILL_ELLIPSE
		jz	doGstring2		; if not Path, jump
ellipseGSCommon	label	near
		mov	ax, (GSSC_FLUSH shl 8) or GR_DRAW_ELLIPSE
doGstring2:
		segmov	ds, ss
		mov	si, bp
		add	si, offset EG_ax	; set ds:si => part of EGframe
		mov	cx, 8			; # of bytes on the stack => CX
		call	GSStore
		jmp	ExitGraphicsGseg
GrFillEllipse	endp

GraphicsArc	ends
