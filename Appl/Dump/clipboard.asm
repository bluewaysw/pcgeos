COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Screen Dumps -- Clipboard format
FILE:		clipboard.asm

AUTHOR:		Adam de Boor, Dec  4, 1989

ROUTINES:
	Name			Description
	----			-----------
	ClipboardPrologue	Initialize file
	ClipboardSlice		Write a bitmap slice to the file
	ClipboardEpilogue	Cleanup

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	12/ 4/89	Initial revision


DESCRIPTION:
	Output-dependent routines for creating a scrap in the clipboard.
		
	$Id: clipboard.asm,v 1.1 97/04/04 15:36:40 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	dump.def
include	file.def
include vm.def
include graphics.def
include gstring.def
include Objects/clipbrd.def

idata	segment

ClipboardProcs	DumpProcs	<
	0, ClipboardPrologue, ClipboardSlice, ClipboardEpilogue, <'scr'>, 0
>

idata	ends

MAX_SLICES	equ	256	; max number of slices we can handle

udata	segment

clipboardSlices		hptr	MAX_SLICES dup(?)
clipboardNextSlice	nptr.hptr
clipboardDrawSlice	nptr.hptr

clipboardGString	hptr
clipboardFile		hptr
clipboardGStringHead	word
clipboardItem		word
clipboardStartRow	word
clipboardHeight		word

udata	ends

ClipboardCode	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClipboardPrologue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize a clipboard thingummy

CALLED BY:	DumpScreen
PASS:		si	= BMFormat
		bp	= file handle
		cx	= dump width
		dx	= dump height
		ds	= dgroup
RETURN:		Carry set on error
DESTROYED:	not bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 4/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClipboardPrologue	proc	far
		uses	bp
		.enter
		mov	ds:[clipboardHeight], dx
	;
	; get hold of the clipboard file handle and open the gstring we'll
	; use once we've got all the slices.
	;
		push	cx, dx			; save width & height

		call	ClipboardGetClipboardFile	; bx = file handle
		mov	ds:[clipboardFile], bx	; save block & handle for later
	;
	; allocate a GString to write to...
	;
		mov	cx, GST_VMEM		; put it in a VM file
		call	GrCreateGString		; di = gstring
		mov	ds:[clipboardGStringHead], si
		mov	ds:[clipboardGString], di
	;
	; Allocate the ClipboardItemHeader block now as well
	; 
		mov	bx, ds:[clipboardFile]
		clr	ax			; UID
		mov	cx, size ClipboardItemHeader
		call	VMAlloc			;ax = block
		mov	ds:[clipboardItem], ax
		push	ds			; save our ds
		call	VMLock
		mov	ds, ax			; set ds to new block seg

		call	GeodeGetProcessHandle
		mov	ds:[CIH_owner].handle, bx
		mov	ds:[CIH_owner].chunk, 0
		mov	ds:[CIH_flags], 0
		mov	ds:[CIH_formatCount], 1
		mov	ds:[CIH_formats][0].CIFI_format.CIFID_manufacturer,
				MANUFACTURER_ID_GEOWORKS
		mov	ds:[CIH_formats][0].CIFI_format.CIFID_type,
				CIF_GRAPHICS_STRING
		mov	ax, es:[clipboardGStringHead]
		mov	ds:[CIH_formats][0].CIFI_vmChain.high, ax
		mov	ds:[CIH_formats][0].CIFI_vmChain.low, 0
	;
	;	Now set the 2 extra bytes to the width and height
	;
		pop	ax			; ax <- dgroup
		pop	ds:[CIH_formats][0].CIFI_extra1,	; width
			ds:[CIH_formats][0].CIFI_extra2	; height
		push	ax			; save it again...

		segmov	es,ds,di		;es:di - dest of scrap name
		mov	di, offset CIH_name	;

		mov	bx, handle Strings	; lock the strings resource
		call	MemLock
		mov	ds, ax	
		assume	ds:Strings
		mov	si, ds:[dumpScrapName]	; Dereference chunk
		ChunkSizePtr ds, si, cx
		rep	movsb			; move it on over...
		call	MemUnlock		; unlock the strings resource
		assume	ds:dgroup

		pop	ds			; restore our ds
		call	VMDirty
		call	VMUnlock
	;
	; Initialize slice array pointer.
	; 
		mov	ds:[clipboardNextSlice], offset clipboardSlices
		mov	ds:[clipboardStartRow], 0
	;
	; Happiness
	;
		clc
		.leave
		ret
ClipboardPrologue	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClipboardSlice
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a single Clipboard slice out to the file

CALLED BY:	DumpScreen
PASS:		bp	= file handle
		si	= Clipboard block handle
		cx	= size of bitmap (bytes)
		ds, es	= dgroup
RETURN:		Carry set on error
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 4/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClipboardSlice	proc	far
		uses 	dx, di, ds, es
		.enter
	;
	; Enlarge the Bitmap header to a CBitmap header, for later drawing.
	; 
		mov	ax, cx
		add	ax, size CBitmap - size Bitmap
		push	cx
		mov	ch, mask HAF_LOCK
		mov	bx, si
		call	MemReAlloc
		pop	si
		push	es
		mov	es, ax
		mov	ds, ax
		dec	si		; start move with last byte
		mov	di, si
		add	di, size CBitmap - size Bitmap	; make room for extra
							;  header data
		mov	cx, si
		sub	cx, size Bitmap-1	; cx <- # bytes to move
		std
		rep	movsb
		cld
		pop	es
	;
	; Initialize the complex bitmap header.
	; 
		mov	ax, es:[clipboardStartRow]
		mov	ds:[CB_startScan], ax
		mov	ax, es:[clipboardHeight]
		xchg	ds:[B_height], ax
		add	es:[clipboardStartRow], ax
		mov	ds:[CB_numScans], ax
		mov	ds:[CB_devInfo], 0
		mov	ds:[CB_data], size CBitmap
		mov	ds:[CB_palette], 0
		mov	ds:[CB_xres], 72
		mov	ds:[CB_yres], 72
		or	ds:[B_type], mask BMT_COMPLEX
		call	MemUnlock
		segmov	ds, es
	;
	; Just store the handle away in our array.
	; 
		mov	di, ds:[clipboardNextSlice]
		mov	ax, bx
		stosw
		mov	ds:[clipboardNextSlice], di
	
	;
	; Return carry set if slice array full (di is ae the end of the array)
	; 
		cmp	di, offset clipboardSlices+size clipboardSlices
		cmc		; need carry set if ae
		.leave
		ret
ClipboardSlice	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClipboardEpilogue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finish off a Clipboard scrap

CALLED BY:	DumpScreen
PASS:		bp	= file handle
		ds, es	= dgroup
RETURN:		Carry set on error
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 4/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClipboardEpilogue	proc	far
		uses	bp
		.enter
	;
	; Draw the bitmap slices as one big bitmap into the gstring
	; 
		mov	di, ds:[clipboardGString]
		mov	bx, ds:[clipboardSlices][0]
		mov	ds:[clipboardDrawSlice],
				offset clipboardSlices+type clipboardSlices
		push	ds
		call	MemLock
		mov	ds, ax
		clr	si
		mov	dx, cs
		mov	cx, offset ClipboardGetNextSlice
		clr	ax
		mov	bx, ax
		call	GrDrawBitmap
		pop	ds
	;
	; Finish off the string.
	; 
		call	GrEndGString
		mov	dl, GSKT_LEAVE_DATA
		xchg	di, si			; GString => SI, 0 => DI
		call	GrDestroyGString
	;
	; Set the result as the normal transfer item.
	; 
		mov	bx, ds:[clipboardFile]
		mov	ax, ds:[clipboardItem]
		clr	bp			; normal item
		call	ClipboardRegisterItem
	;
	; Happiness.
	; 
		clc
		.leave
		ret
ClipboardEpilogue	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClipboardGetNextSlice
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the next slice of the bitmap for drawling.

CALLED BY:	ClipboardEpilogue via GrDrawBitmap
PASS:		ds:si	= current slice
		dgroup:clipboardDrawSlice set to address of next handle
			to use
RETURN:		ds:si	= new slice
		carry set to stop drawing
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/17/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClipboardGetNextSlice		proc	far
		uses	ax, bx
		.enter
		segmov	ds, dgroup, si
		mov	si, ds:[clipboardDrawSlice]
	;
	; Free the previous slice.
	; 
		mov	bx, ds:[si-2]
		call	MemFree
	;
	; See if that's all she wrote...
	; 
		cmp	si, ds:[clipboardNextSlice]
		stc
		je	done
	;
	; Nope. Lock down the next one.
	; 
		lodsw
		mov	ds:[clipboardDrawSlice], si
		mov	bx, ax
		call	MemLock
		mov	ds, ax
		clr	si
done:
		.leave
		ret
ClipboardGetNextSlice		endp


ClipboardCode	ends
