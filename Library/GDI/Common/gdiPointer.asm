COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		GDI Library - Common code
FILE:		gdiPointer.asm

AUTHOR:		Todd Stumpf, Apr 29, 1996

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	4/29/96   	Initial revision


DESCRIPTION:
	
		

	$Id: gdiPointer.asm,v 1.1 97/04/04 18:03:57 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitCode		segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GDIPointerInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize Pointer module of GDI library

CALLED BY:	GLOBAL
PASS:		nothing
RETURN:		carry set on error
		ax	<-	PointerErrorCode
DESTROYED:	flags only

SIDE EFFECTS:
		Initializes hardware

PSEUDO CODE/STRATEGY:
		Call common initialization routine

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	4/29/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GDIPointerInit	proc	far
if HAS_POINTER_HARDWARE
	uses	dx, si
	.enter

	;
	;  Activate Pointer interface
	.assert segment HWPointerInit eq segment GDIPointerInit
	mov	dx, mask IMF_POINTER			; dx <- interface mask
	mov	si, offset HWPointerInit		; si <- actual HW rout.
	call	GDIInitInterface		; carry set on error
						; ax <- ErrorCode

	.leave
else
	;
	;  Let caller know, no pointer is present
	mov	ax, EC_INTERFACE_NOT_SUPPORTED
	stc

endif
	ret
GDIPointerInit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GDIPointerInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return necessary pointer info

CALLED BY:	GLOBAL
PASS:		cx:dx	= fptr.PointerInfo
RETURN:		PointerInfo filled in
		ax	<- PointerErrorCode
		carry set on error (bx,cx,dx,si,di preserved)
		
DESTROYED:	flags only

SIDE EFFECTS:
		None

PSEUDO CODE/STRATEGY:
		Return pointers to needed tables		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	4/29/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GDIPointerInfo	proc	far
if HAS_POINTER_HARDWARE
	uses	ds, si
	.enter
	segmov	ds, dgroup
	mov	ax, ds:[numButtons]
	movdw	dssi, cxdx
	mov	ds:[si].PI_numButtons, ax
	mov	ds:[si].PI_hiCount, HARD_ICON_REGION_COUNT

	mov	bx, segment hirTable			; bx:si <- hirTable
	mov	di, offset hirTable
	movdw	ds:[si].PI_hirTable, bxdi

	mov	bx, segment hiaTable			; dx:di <- hiaTable
	mov	di, offset hiaTable
	movdw	ds:[si].PI_hiaTable, bxdi

	mov	ax, EC_NO_ERROR
	clc
	.leave
else

	mov	ax, EC_INTERFACE_NOT_SUPPORTED
	stc

endif
	ret

GDIPointerInfo	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GDIPointerRegister
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Register a Pointer callback with the library

CALLED BY:	GLOBAL
PASS:		dx:si	-> fptr of fixed routine to call
RETURN:		carry set on error
		ax	<- PointerErrorCode
DESTROYED:	flags only

SIDE EFFECTS:
		Adds callback to list of pointer callbacks

PSEUDO CODE/STRATEGY:
		Call common registration routine

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	4/29/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GDIPointerRegister	proc	far
if HAS_POINTER_HARDWARE
	uses	bx
	.enter

	;
	;  Try to add callback to list of Pointer callbacks
							; dx:si -> callback
	mov	bx, offset pointerCallbackTable		; bx -> callback table
	call	GDIRegisterCallback		; carry set on error
						; ax <- ErrorCode

	.leave
else
	mov	ax, EC_INTERFACE_NOT_SUPPORTED
	stc
endif
	ret
GDIPointerRegister	endp

InitCode			ends


ShutdownCode			segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GDIPointerUnregister
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove previously registered callback

CALLED BY:	GLOBAL
PASS:		dx:si	-> fptr for callback
RETURN:		carry set on error
		ax	<- PointerErrorCode
DESTROYED:	nothing

SIDE EFFECTS:
		Removes callback from list

PSEUDO CODE/STRATEGY:
		Call common de-registration routine

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	4/29/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GDIPointerUnregister	proc	far
if HAS_POINTER_HARDWARE
	uses	bx
	.enter
	;
	;  Try to add callback to list of Pointer callbacks
							; dx:si -> callback
	mov	bx, offset pointerCallbackTable		; bx -> callback table
	call	GDIUnregisterCallback		; carry set on error
						; ax <- ErrorCode
	.leave
else
	mov	ax, EC_INTERFACE_NOT_SUPPORTED
	stc
endif
	ret
GDIPointerUnregister	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GDIPointerShutdown
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:

CALLED BY:	GLOBAL
PASS:		nothing
RETURN:		carry set on error
		ax	<- Error code
DESTROYED:	nothing

SIDE EFFECTS:
		Shuts down hardware interface

PSEUDO CODE/STRATEGY:
		Call common shutdown routine

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	4/29/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GDIPointerShutdown	proc	far
if HAS_POINTER_HARDWARE

	;
	;  Deactivate Pointer interface
	mov	dx, mask IMF_POINTER			; dx <- interface mask
	mov	bx, offset pointerCallbackTable
	mov	si, offset HWPointerShutdown		; si <- actual HW rout.
	call	GDIShutdownInterface		; carry set on error
						; ax <- ErrorCode

else
	mov	ax, EC_INTERFACE_NOT_SUPPORTED
	stc
endif
	ret
GDIPointerShutdown	endp

ShutdownCode		ends
