COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Task-switching Common Code -- Clipboard Interface
FILE:		taskClipboard.asm

AUTHOR:		Adam de Boor, Oct  6, 1991

ROUTINES:
	Name			Description
	----			-----------
	TCBInit			Initialize the clipboard interface
	TCBExit			Finish with the clipboard interface
	TCBImport		Import data from the switcher to pc/geos
	TCBExport		Export data from pc/geos to the switcher
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	10/6/91		Initial revision


DESCRIPTION:
	Common code for switchers that support data import/export between
	tasks. This basically interfaces with the UI's clipboard file/
	transfer mechanism, allowing the switcher-specific code to deal
	with its own cruft in a simple way.
		
	Notes on creating a clipboard entry:
		* This has been greatly-simplified in 2.0, as there are
		  utility routines that allow us to create a text object
		  within the clipboard file and just set its text to be
		  that obtained from the switcher's clipboard.

	$Id: taskClipboard.asm,v 1.1 97/04/18 11:58:15 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;
; Procedure vectors filled from args passed to TCBInit. Procedures are
; near procedures in the Movable resource segment.
; 

udata	segment

ssExport	nptr.near	; switcher-specific export routine. Called:
				; 	Pass:	ds	= buffer holding chars
				;			  to export (in DOS
				;			  character set)
				;		cx	= # chars in buffer
				;		bx	= handle of buffer
				;		es	= dgroup
				;	Return:	nothing
				;	Notes:	buffer may be mangled to the
				;		exporter's heart's content. si
				;		is always 0.
				;

ssImport	nptr.near	; switcher-specific import routine. Called:
				; 	Pass:	nothing
				;	Return:	bx	= handle of block
				;			  holding the text (in
				;			  the DOS character set;
				;			  HF_SHARABLE set)
				;		cx	= # bytes in block. 0
				;			  if import unsuccessful
				;			  or unnecessary (the
				;			  switcher's clipboard
				;			  hasn't changed)

udata	ends

idata	segment

cbChanged	byte	TRUE	; set when pc/geos clipboard has changed and
				;  we didn't do the changing. Set true
				;  initially to handle item being left on
				;  pc/geos clipboard. XXX: should import when
				;  first started up, yes?

idata	ends

Movable	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TCBInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize clipboard interface.

CALLED BY:	EXTERNAL
PASS:		cx	= switcher-specific import routine
		dx	= switcher-specific export routine
		ds	= dgroup
RETURN:		nothing
DESTROYED:	cx, dx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TCBInit		proc	near
		.enter
	;
	; Save the procedure vectors
	; 
		mov	ds:[ssImport], cx
		mov	ds:[ssExport], dx
	;
	; Put ourselves in the transfer-notification list.
	;
		mov	cx, handle 0
		clr	dx
		call	ClipboardAddToNotificationList

	;
	; import initial T/S clipboard contents, if viable and we're not
	; just restarting (might have something reasonable in our own
	; clipboard then...)
	;
		call	SysGetConfig
		test	al, mask SCF_RESTARTED
		jnz	done

		call	TCBImport
done:
		.leave
		ret
TCBInit		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TCBExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close down the clipboard interface.

CALLED BY:	EXTERNAL
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Perhaps should forcibly export current clipboard contents
		here, so item doesn't get biffed if user reloads the system?

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TCBExit		proc	near
		uses	cx, dx
		.enter
		clr	dx
	;
	; Zero our various state variables, just in case.
	; 
		mov	ds:[ssImport], dx
		mov	ds:[ssExport], dx
		mov	ds:[cbChanged], dl
	;
	; And tell the UI to leave us alone (dx already 0).
	; 
		mov	cx, handle 0
		call	ClipboardRemoveFromNotificationList
		.leave
		ret
TCBExit		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TCBTransferItemChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take note that the normal transfer item has changed. We'll
		see if the thing's transferrable just before suspending
		the system.

CALLED BY:	METHOD_NOTIFY_NORMAL_TRANSFER_ITEM_CHANGED
PASS:		ds = es = dgroup
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TCBTransferItemChanged method dynamic TaskDriverClass,
				      MSG_META_CLIPBOARD_NOTIFY_NORMAL_TRANSFER_ITEM_CHANGED
		.enter
		mov	ds:[cbChanged], TRUE
		.leave
		ret
TCBTransferItemChanged endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TCBImport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Import data from the switcher's clipboard.

CALLED BY:	EXTERNAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TCB_FREE_SPACE	equ	128		; just for the hell of it.

TCBImport	proc	near
		uses	ax, bx, cx, dx, bp, ds, es, si, di
		.enter
		segmov	es, dgroup, ax		
		tst	es:[ssImport]
		jz	fail
	;
	; Call the switcher-specific import routine to do its thing.
	; 
		call	es:[ssImport]
		jcxz	fail
	;
	; Convert the text from the DOS character set to the pc/geos one.
	; 
		call	MemLock
		mov	ds, ax
		clr	si		; ds:si <- text
		mov	ax, '.'		; ax <- default char
		call	LocalDosToGeos
		call	MemUnlock
	;
	; Set the block as the normal transfer item.
	; 
		call	TCBDefineNormalItem
done:
		.leave
		ret
fail:
		stc
		jmp	done
TCBImport	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TCBDefineNormalItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the passed block as the normal transfer item.

CALLED BY:	TCBImport
PASS:		bx	= handle of block holding the text
		cx	= # of chars in the block
RETURN:		carry clear if everything's ok.
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TCBDefineNormalItem proc near
		.enter
	;
	; Allocate a text object within the clipboard file.
	; 
		push	bx		; save the handle
		clr	bx		; create w/in UI clipboard file
		clr	ax		; default stuff
		call	TextAllocClipboardObject
	;
	; Set the entire block as the text for the object.
	; 
		pop	dx		; ^hdx <- block (cx = # chars)
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_BLOCK
		mov	di, mask MF_CALL
		push	dx
		call	ObjMessage
		pop	dx
	;
	; Register the transfer item
	; 
		push	dx
		mov	cx, handle 0			; make the transfer
		clr	dx				; owned by our process
		mov	di, -1				; use the standard name
		mov	ax, TCO_COPY
		call	TextFinishWithClipboardObject
		pop	dx
	;
	; Free the block of text we got back from the switcher.
	; 
		mov	bx, dx
		call	MemFree
		clc
		.leave
		ret
TCBDefineNormalItem endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TCBExport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Export the current PC/GEOS clipboard normal transfer item
		to the switcher's clipboard if it's changed and it's text.

CALLED BY:	EXTERNAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TCBExport	proc	near
vmFile		local	hptr
vmBlock		local	word
		uses	ax, bx, cx, dx, si, di, bp, es, ds
		.enter
	;
	; If either the clipboard hasn't changed, or we don't have an export
	; routine, we do nothing.
	; 
		segmov	ds, dgroup, ax
		tst	ds:[cbChanged]
		jz	done
		tst	ds:[ssExport]
		jz	done
	;
	; Find the formats that are available from the clipboard's normal
	; transfer item and make sure one of them is text.
	; 
		push	bp
		clr	bp		; normal item, please
		call	ClipboardQueryItem
		pop	bp

		mov	ss:[vmFile], bx
		mov	ss:[vmBlock], ax
	;
	; If we own the item, there's no point in exporting it to the
	; switcher clipboard, since it should already be there, it having
	; come from there...
	; 
		cmp	cx, handle 0
		je	finishedWithTransferItem
	;
	; Ensure there's a block of text we can export.
	; 
		mov	cx, MANUFACTURER_ID_GEOWORKS
		mov	dx, CIF_TEXT
		call	ClipboardTestItemFormat
		jc	finishedWithTransferItem	; => not supported
	;
	; Fetch the text data from the item in the proper format.
	; 
		call	TCBFetchDataToExport
		jc	finishedWithTransferItem
	;
	; Registers loaded, so call the export routine to do what it needs to.
	; 
		segmov	es, dgroup, dx
		call	es:[ssExport]
	;
	; Flag clipboard item as not different from switcher's clipboard.
	; 
		mov	es:[cbChanged], FALSE
	;
	; Free the copy block.
	; 
		call	MemFree

finishedWithTransferItem:
	;
	; Tell the UI we're done with its precious transfer item.
	; 
		mov	bx, ss:[vmFile]
		mov	ax, ss:[vmBlock]
		clr	cx		; normal transfer item.
		call	ClipboardDoneWithItem
done:
		.leave
		ret
TCBExport	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TCBFetchDataToExport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the text transfer item from the clipboard and prep
		it for exporting.

CALLED BY:	TCBExport
PASS:		^vbx:ax	= ClipboardItemHeader structure for normal transfer
			  item
RETURN:		carry clear if successful:
			ds:si	= text to export in DOS character set
			cx	= # chars at ds:si to export
			bx	= handle holding text that should be
				  freed when export complete.
		carry set if unsuccessful
DESTROYED:	ax, di, es

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/9/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TCBFetchDataToExport proc	near
		uses	bp
		.enter
	;
	; Create a text object into which we will be able to paste the current
	; transfer item.
	; 
		clr	bx, ax
		call	TextAllocClipboardObject
	;
	; Do so.
	; 
		mov	ax, MSG_META_CLIPBOARD_PASTE
		mov	di, mask MF_CALL
		call	ObjMessage
	;
	; Make sure it's not more than we can handle.
	; 
		mov	ax, MSG_VIS_TEXT_GET_TEXT_SIZE
		mov	di, mask MF_CALL
		call	ObjMessage
		tst	dx		; >= 64K?
		jnz	tooBig
	;
	; Ask it to return all the text in a single block on the heap.
	; 
		mov	ax, MSG_VIS_TEXT_GET_ALL_BLOCK
		clr	dx		; alloc new block
		mov	di, mask MF_CALL
		call	ObjMessage
	;
	; Biff the text object
	; 
		push	cx, ax
		mov	ax, TCO_RETURN_NOTHING
		call	TextFinishWithClipboardObject
		pop	bx, cx		; bx <- block, cx <- # chars
	;
	; Now convert the text from the PC/GEOS to the DOS character set
	; and return a pointer to the text.
	; 
		call	MemLock
		mov	ds, ax
		clr	si
		mov	ax, '.'
		call	LocalGeosToDos
		clc			; signal success
done:
		.leave
		ret
tooBig:
	;
	; Text was too large for a block of memory, so we can't export it.
	; Just biff the text object we used to find this out and return
	; an error.
	; 
		mov	ax, TCO_RETURN_NOTHING
		call	TextFinishWithClipboardObject
		stc
		jmp	done
TCBFetchDataToExport endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TCBConvertCRToCRLF
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert all carriage returns within a block of text to
		be carriage return/line feed pairs.

CALLED BY:	EXTERNAL
PASS:		ds	= segment of locked block holding the text
		bx	= handle of same
		cx	= number of chars in it
RETURN:		carry set if couldn't expand (not enough memory)
		carry clear if expansion successful:
			ds	= updated
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/25/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TCBConvertCRToCRLF proc	near
		uses	es, di, si, dx
		.enter
	;
	; Expand carriage-returns to CR-LF pairs. Stage 1: count the number
	; of \r characters in the buffer to be copied out. This tells us by how
	; much we need to expand the thing.
	; 
		push	cx
		clr	di
		segmov	es, ds
		mov	al, '\r'
		mov	si, -1
expandCountLoop:
		inc	si
		repne	scasb
		je	expandCountLoop

		pop	cx		
		tst	si
		jz	done
		
	;
	; There are actually some carriage returns, so figure new size for the
	; block whose handle is in BX and expand the whole thing.
	; 
		push	cx
		add	cx, si
		mov_tr	ax, cx
		inc	ax		; leave room for null byte, too
		clr	cx
		call	MemReAlloc
		pop	cx
		jc	done

		mov	ds, ax
		mov	es, ax
	;
	; Set pointers to the end of the new buffer and the existing text,
	; pointing to the last character since even with DF set, it's post-
	; decrement.
	; 
		
		mov	di, si		; di <- # chars extra
		add	di, cx		; di <- # chars when done
		mov	dx, di		; save combined total for later
		mov	si, cx
		inc	cx		; copy the null byte, too
		std
expandCRLoop:
		lodsb
		cmp	al, '\r'
		jne	storeIt
		mov	al, '\n'
		stosb
		mov	al, '\r'
storeIt:
		stosb
		loop	expandCRLoop
	;
	; Return cx being the number of chars now in the buffer.
	; 
		cld
		mov	cx, dx
		clc
done:
		.leave
		ret
TCBConvertCRToCRLF endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TCBConvertCRLFToCR
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compress CR-LF pairs into single carriage returns, as used
		by our text object.

CALLED BY:	EXTERNAL
PASS:		ds	= segment of block holding the chars
		bx	= handle of same
		cx	= # of chars in the block (ds:[cx] is a null byte)
RETURN:		cx	= # of chars now in the block (ds:[cx] is again
			  a null byte)
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/25/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TCBConvertCRLFToCR proc	near
		uses	es, si, di
		.enter
	;
	; Strictly speaking, this loop just removes LFs wherever it finds
	; them, rather than detecting CR-LF pairs. The effect is much the
	; same, however.
	; 
		clr	si, di
		segmov	es, ds

compressCheckCXLoop:
		jcxz	compressComplete
compressCRLFLoop:
		lodsb
		stosb
		cmp	al, '\n'
		loopne	compressCRLFLoop
		jne	compressComplete	; => last char processed
	;
	; Char just stored was a newline, so back up our storage pointer to
	; overwrite it with the next char.
	; 
		dec	di
		jmp	compressCheckCXLoop
compressComplete:
	;
	; Null-terminate the thing.
	; 
		clr	al
		stosb
	;
	; Shrink the block down to fit the new size.
	; 
		mov	ax, di
		clr	cx
		call	MemReAlloc
	;
	; And return the number of chars, w/o the null...
	; 
		lea	cx, ds:[di-1]
		.leave
		ret
TCBConvertCRLFToCR endp

Movable		ends
