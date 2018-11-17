COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	Jedi
MODULE:		GadgetsLibrary
FILE:		mainVisMonikerUtil.asm

AUTHOR:		Jennifer Wu, Jun 10, 1993

ROUTINES:

				
    INT CreateGStringForVisualMoniker 
				Creates a gstring that will be used to draw
				a VisMoniker string into.

    INT CreateVisMonikerFromGString 
				Creates the VisMoniker from a gstring you
				pass it.

    INT InsertVisMonikerHeader  Prepends a VisMoniker structure header to
				the gstring chunk.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	6/10/93		Initial revision
	pb	9/1/93		Changed to work on PExpo project
	epw	10/18/93	Changed to work on Expo project
	JAG	2/ 1/95		Nuked a bunch of stuff that we don't use

DESCRIPTION:

   	You can also call routines like CreateGStringForVisualMoniker and
   	CreateVisMonikerFromGString to draw your own monikers using
   	graphics routines.   	
	
	$Id: mainVisMonikerUtil.asm,v 1.1 97/04/04 17:59:53 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VisMonikerUtilsCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateGStringForVisualMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates a gstring that will be used to draw a VisMoniker
		string into.

CALLED BY:	CreateMessageLogVisMoniker

PASS:		nothing

RETURN:		bx	<- block containing gstring
		si	<- chunk containing gstring
		di	<- gstring handle

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		(stolen from Email app)
REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	6/10/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateGStringForVisualMoniker	proc	far
	uses	ax,cx,bp
	.enter
	;
	; First get a global block to create the moniker in.
	;
		mov	ax, LMEM_TYPE_GENERAL
		clr	cx
		call	MemAllocLMem		; bx <- block handle
	;
	; Then create a GString .. bx has block handle in which to store GS
	; pass: bx = block handle
	;
		mov	cl, GST_CHUNK		; alloc a chunk for the gstring
		call	GrCreateGString		; di <- gstring handle
						; si <- gstring chunk
	.leave
	ret
CreateGStringForVisualMoniker	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateVisMonikerFromGString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates the VisMoniker from a gstring you pass it.

CALLED BY:	CreateMessageLogVisMoniker

PASS:		bx	-> gstring block
		si	-> gstring chunk
		di	-> gstring handle
		cx	-> VisMoniker height
		dx	-> VisMoniker width

RETURN:		^lcx:dx	<- VisMoniker

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		(stolen from Email app)
REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	6/10/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateVisMonikerFromGString	proc	far
	uses	ax,bx,si,di
	.enter

		call	GrEndGString	; end the gstring
	;
	; Then nuke the GState, as we don't need it anymore.
	;
		push	si, dx			; save gstring chunk
		mov	si, di			; use gstring handle for destroy
		mov	dl, GSKT_LEAVE_DATA	; leave our data intact
		call	GrDestroyGString	; but get rid of the GString-GS
		pop	si, dx			; restore gstring chunk and 
						;  VM width
	;	
	; Prepend GString with header needed for VisMoniker.
	;
		call	InsertVisMonikerHeader
	;
	; Return ^lcx:dx = moniker.
	;
		mov	cx, bx
		mov	dx, si

	.leave
	ret
CreateVisMonikerFromGString	endp

VM_gstringData	equ	size	VisMoniker


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InsertVisMonikerHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Prepends a VisMoniker structure header to the gstring chunk.

CALLED BY:	CreateGStringVisualMoniker

PASS:		bx	-> block containing gstring
		si	-> chunk containing gstring
		cx	-> Height of VisMoniker
		dx	-> Width of VisMoniker

RETURN:		bx, si unchanged

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	6/10/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InsertVisMonikerHeader	proc	near
	uses	ax,bx,cx,dx,si,di,ds
	.enter

		call	MemLock		; lock gstring block
		mov	ds, ax		; segment of block containingg gstring
		push	bx, cx

		mov	ax, si		; ax <- gstring chunk
		clr	bx		; offset into chunk at which to insert
		mov	cx, size VisMoniker + size VisMonikerGString
		call	LMemInsertAt	; puts vismoniker header in front of
					; gstring
		
		pop	bx, cx		; restore block handle
	;
	; Stuff the VisMoniker header structure to make this a valid
	; GString Moniker.
	;
		mov	di, ds:[si]	; Deref to get ptr to chunk in ds:di
		mov	ds:[di].VM_type, (mask VMT_GSTRING) or DC_GRAY_4
		mov	ds:[di].VM_width, dx
		mov	ds:[di].VM_gstringData.VMGS_height, cx

		call	MemUnlock
	
	.leave
	ret
InsertVisMonikerHeader	endp

VisMonikerUtilsCode	ends
