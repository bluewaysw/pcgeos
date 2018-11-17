COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		bitmapC.asm

AUTHOR:		jimmy lefkowitz

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	11/11/93		Initial version.

DESCRIPTION:
	C stubs for the exported routines in the bitmap library

	$Id: bitmapC.asm,v 1.1 97/04/04 17:43:19 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include geos.def
include heap.def
UseLib bitmap.def

Bitmap_C	segment resource
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ToolStubCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	do some common code for tool C stubs

CALLED BY:	tool C stubs

PASS:		optr to tool on stack

RETURN:		*ds:si = pointer to tool

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	11/11/93		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ToolStubCommon	macro
	mov	bx, tool.handle
	call	MemDerefDS		; ds = segment of tool
	mov	si, tool.offset
	mov	si, ds:[si]		; si = offset of tool
endm

	SetGeosConvention	; define stubs in pscal calling convention

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TOOLGRABMOUSE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C stub for ToolGrabMouse

Description:	Utility routine for grabbing the mouse for a tool.

CALLED BY:	GLOBAL

PASS:		void ToolGrabMouse(optr	tool);

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	11/11/93		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TOOLGRABMOUSE	proc	far tool:optr
	uses	ds, si, bx
	.enter
	ToolStubCommon	; *ds:si = tool
	call	ToolGrabMouse
	.leave
	ret
TOOLGRABMOUSE	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TOOLSENDALLPTREVENTS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C stub for ToolSendAllPtrEvents

Description:	Utility routine for sending all ptr events to the tool.

CALLED BY:	GLOBAL

PASS:		void ToolSendAllPtrEvents(optr	tool);		

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	11/11/93		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TOOLSENDALLPTREVENTS	proc	far	tool:optr
	uses	ds, si, bx
	.enter
	ToolStubCommon	; *ds:si = tool
	call	ToolSendAllPtrEvents
	.leave
	ret
TOOLSENDALLPTREVENTS	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TOOLRELEASEMOUSE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C stub for ToolReleaseMouse

Description:	Tool utility routine to release the mouse grab

CALLED BY:	GLOBAL

PASS:		void ToolReleaseMouse(optr	tool);

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	11/11/93		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TOOLRELEASEMOUSE	proc	far	tool:optr
	uses	ds, si, bx
	.enter
	ToolStubCommon	; *ds:si = tool
	call	ToolReleaseMouse
	.leave
	ret
TOOLRELEASEMOUSE	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TOOLCALLBITMAP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C stub to ToolCallBitmap

Description:	Utility routine for sending a message to the tool's bitmap

CALLED BY:	GLOBAL

PASS:		void ToolCallBitmap(	optr 	tool,
					word	message,
					void	*params,
					void	*retVal);
			params is a pointer to a structure for parameters
				to the particular message
			retVal is a pointer to a structure for the return
			values of the particular message

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	11/11/93		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if 0
TOOLCALLBITMAP	proc	far	tool:optr, 	; tool to send message to
				message:word,	; message to send
				params:fptr,	; parameters to message
				retVals:fptr	; return values
	uses	es, ds, si, bx, di
	.enter
	ToolStubCommon		; *ds:si = tool
	mov	ax, message
	les	di, params
	mov	cx, es:[di]		; drag out the parameters
	mov	dx, es:[di][2]		; from the arbitrary structure
	mov	bp, es:[di][4]
	call	ToolCallBitmap

	; since we don't know what the possible returns values for the
	; specific message are, return everything and let the user get
	; the relevant information
	pushf				; save the carry flag
	les	di, retVals
	mov	es:[di], ax
	mov	es:[di][2], cx
	mov	es:[di][4], dx
	mov	es:[di][6], bp		; store ax, cx, dx, bp
	clr	ax
	popf
	adc	ax, 0			; ax = 1 if carry set else ax = 0
	mov	es:[di][8], ax
	.leave
	ret
TOOLCALLBITMAP	endp
endif

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DRAWBITMAPTOGSTATE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C stub for DrawBitMapToGState

Description:	Draws a bitmap into the passed gstate

CALLED BY:	GLOBAL

PASS:		void DrawBitmapToGState(GStateHandle 	gstate,
					   VMFileHandle 	vmFile,
					   VMBlockHandle 	vmBlock,
					   word			xcoord,
					   word			ycoord);

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	11/11/93		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DRAWBITMAPTOGSTATE	proc	far	gstate:word,
					vmFile:word,
					vmBlock:word,
					xcoord:word,
					ycoord:word
	uses	di, bx, cx, dx
	.enter
	mov	di, gstate
	mov	bx, vmFile
	mov	ax, vmBlock
	mov	cx, xcoord
	mov	dx, ycoord
	call	DrawBitmapToGState
	.leave
	ret
DRAWBITMAPTOGSTATE	endp


Bitmap_C	ends

	SetDefaultConvention
