COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		bnfClipboard.asm

AUTHOR:		Adam de Boor, Oct  7, 1991

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	10/7/91		Initial revision


DESCRIPTION:
	Functions to deal with B&F's clipboard file..
		
	Characters are stored out in straight ASCII. I don't know whether
	lines are \r\n-terminated or just \r-terminated. We'll see.

	$Id: bnfClipboard.asm,v 1.1 97/04/18 11:58:09 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BNF_DEFAULT_CHAR	equ	'.'

udata	segment

cbEnabled	word	0

;
; Modification time of clipboard when last read in.
; 
cbLastModified		FileDateAndTime

udata	ends

Movable	segment	resource

bnfCat		char	'back & forth', 0
clipboardKey	char	'clipboard', 0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BNFCBInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize our manhandling of the B&F clipboard.

CALLED BY:	BNFAttach
PASS:		ds = es = dgroup
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/7/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BNFCBInit	proc	near
		uses	cx, dx, ax, bx, si, bp
		.enter
	;
	; See if we've saved a status to the ini file before. We assume
	; the user doesn't want the support enabled (principle of least
	; surprise) unless we've previously put something in the ini file
	; saying it should be on.
	; 
		push	ds
		segmov	ds, cs, cx		; ds, cx <- cs
		mov	si, offset bnfCat
		mov	dx, offset clipboardKey
		call	InitFileReadBoolean
		mov	cx, FALSE		; assume disabled
		jc	setListState
		mov_tr	cx, ax
setListState:
		pop	ds

		mov	ds:[cbEnabled], cx
		jcxz	done		; if disabled, do nothing		
	;
	; If it's actually enabled, hook in the generic clipboard support.
	; 
		mov	cx, offset BNFCBImport
		mov	dx, offset BNFCBExport
		call	TCBInit
done:
		.leave
		ret
BNFCBInit	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BNFCBExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close down our clipboard support.

CALLED BY:	BNFDetach
PASS:		ds = es	= dgroup
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/7/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BNFCBExit	proc	near
		.enter
		tst	ds:[cbEnabled]
		jz	done
		
		call	TCBExit

done:
		.leave
		ret
BNFCBExit	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BNFCBImport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Import the current data from tbe B&F clipboard, if it's
		changed.

CALLED BY:	TCBImport
PASS:		nothing
RETURN:		bx	= handle of sharable block holding the text, in
			  the DOS character set.
		cx	= # bytes (0 if nothing imported; excludes null-term)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/7/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BNFCBImport	proc	near
modified	local	FileDateAndTime
fileSize	local	dword
attrs		local	2 dup(FileExtAttrDesc)
fileName	local	PathName
		uses	ax, dx, di, es
		.enter
	;
	; Fetch the modification date (so we can decide whether to import
	; the text) and the size (so we know how big a buffer to allocate to
	; get it) of the current cliboard file.
	; 
		mov	ss:[attrs][0*FileExtAttrDesc].FEAD_attr, 
				FEA_MODIFICATION
		lea	ax, ss:[modified]
		mov	ss:[attrs][0*FileExtAttrDesc].FEAD_value.offset, ax
		mov	ss:[attrs][0*FileExtAttrDesc].FEAD_value.segment, ss
		mov	ss:[attrs][0*FileExtAttrDesc].FEAD_size, 
				size modified

		mov	ss:[attrs][1*FileExtAttrDesc].FEAD_attr, 
				FEA_SIZE
		lea	ax, ss:[fileSize]
		mov	ss:[attrs][1*FileExtAttrDesc].FEAD_value.offset, ax
		mov	ss:[attrs][1*FileExtAttrDesc].FEAD_value.segment, ss
		mov	ss:[attrs][1*FileExtAttrDesc].FEAD_size, 
				size fileSize
		
		lea	di, ss:[fileName]
		segmov	es, ss
		mov	bx, BNFAPI_GET_CLIPBOARD_NAME
		call	BNFCall			; dx:ax <- filename

		mov	ds, dx
		mov_tr	dx, ax			; ds:dx <- filename
		mov	ax, FEA_MULTIPLE
		segmov	es, ss
		lea	di, ss:[attrs]		; es:di <- attr array
		mov	cx, length attrs	; cx <- # of attrs
		call	FileGetPathExtAttributes
		jc	returnNothing
	;
	; Now see if the file's been modified since last we checked. Because
	; of how the records are laid out, if we compare the current FDAT_date
	; to the last-known and it's greater, or if the current FDAT_time is
	; greater than the last-known, the file has been modified.
	; 
		segmov	ds, dgroup, ax
		mov	ax, ss:[modified].FDAT_date
		mov	bx, ss:[modified].FDAT_time
		cmp	ax, ds:[cbLastModified].FDAT_date
		ja	import
		
		cmp	bx, ds:[cbLastModified].FDAT_time
		jbe	returnNothing

import:
	;
	; We've decided to import the stuff in the clipboard, so record its
	; modification stamp for next time.
	; 
		segmov	es, dgroup, di
		mov	es:[cbLastModified].FDAT_date, ax
		mov	es:[cbLastModified].FDAT_time, bx
	;
	; If it's > 64Kb, there's nothing we can do.
	; 
		tst	ss:[fileSize].high
		jnz	returnNothing
	;
	; Allocate a sharable block that big.
	; 
		mov	ax, ss:[fileSize].low
		inc	ax			; room for null-terminator
		mov	cx, ALLOC_DYNAMIC_LOCK or mask HF_SHARABLE
		call	MemAlloc
		jc	returnNothing
	;
	; Now open the file itself.
	; 
		push	bx, ax
		mov	al, FileAccessFlags <FE_NONE, FA_READ_ONLY>
		call	FileOpen
		pop	ds
		jc	returnNothingAfterFreeingBuffer
	;
	; Read the whole file into the buffer.
	; 
		mov_tr	bx, ax
		clr	dx
		mov	cx, ss:[fileSize].low
		clr	al
		call	FileRead
		jc	returnNothingAfterClosingFileAndFreeingBuffer
	;
	; Close the beast.
	; 
		clr	al
		call	FileClose
	;
	; Null-terminate the buffer and compress its CR-LF pairs to CRs
	; 
		mov	bx, cx
		mov	{char}ds:[bx], 0
		pop	bx
		call	TCBConvertCRLFToCR
		call	MemUnlock
done:
		.leave
		ret
	;--------------------
returnNothingAfterClosingFileAndFreeingBuffer:
		clr	al
		call	FileClose

returnNothingAfterFreeingBuffer:
		pop	bx
		call	MemFree

returnNothing:
		clr	cx
		jmp	done
BNFCBImport	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BNFCBExport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Export the contents of the pc/geos clipboard to B&F

CALLED BY:	TCBExport
PASS:		ds	= text string to copy to clipboard converted to
			  DOS code page
		bx	= handle of block to which DS points
		cx	= # chars to copy
		es	= dgroup
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/7/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BNFCBExport	proc	near
fileName	local	PathName
		uses	bx, ax, cx, dx, di
		.enter
	;
	; Expand CRs to CR-LF pairs. XXX: necessary?
	; 
		call	TCBConvertCRToCRLF
		jc	done
		
	;
	; Fetch the name of the clipboard file we want to modify.
	; 
		push	ds, es
		lea	di, ss:[fileName]
		segmov	es, ds
		mov	bx, BNFAPI_GET_CLIPBOARD_NAME
		call	BNFCall
	;
	; Open it and truncate it.
	; 
		mov	ds, dx
		mov_tr	dx, ax
		mov	ax, (mask FCF_NATIVE or FILE_CREATE_TRUNCATE) shl 8 or \
				FileAccessFlags <FE_DENY_WRITE, FA_WRITE_ONLY>
		call	FileCreate
		jc	couldntCreate
	;
	; Now write all the bytes to it. We don't much care if we run out of
	; disk space here. After all, all we can do is truncate the thing, and
	; B&F would probably spit-up at that...
	; 
		mov	bx, ds
		pop	ds, es
		push	bx, dx		; save name for getting FEA_MODIFICATION
		mov_tr	bx, ax
		clr	dx		; ds:dx <- buffer from which to write
		clr	al		; allow errors
		call	FileWrite
	;
	; Close the file down. Note that some DOSes will actually change the
	; modification time during a close, even if we hadn't modified the
	; thing, so we always wait until after the close to get the modification
	; stamp, which we can usually get w/o opening the darn thing up...
	; 
		clr	al
		call	FileClose
	;
	; Now fetch the modification stamp for the file, so we know whether it's
	; changed when we come back.
	; 
		pop	ds, dx
		mov	ax, FEA_MODIFICATION
		mov	di, offset cbLastModified
		mov	cx, size cbLastModified
		call	FileGetPathExtAttributes
done:
		.leave
		ret

couldntCreate:
	;
	; Just clear the stack and return...
	; 
		pop	ds
		jmp	done
BNFCBExport	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BNFSSetCBSupport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take note of a change in the state of the clipboard support
		list.

CALLED BY:	MSG_BNF_SET_CB_SUPPORT
PASS:		ds = es = dgroup
		cx	= TRUE to turn clipboard support on
			= FALSE to turn clipboard support off.
RETURN:		nothing
DESTROYED:	anything

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/24/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BNFSetCBSupport	method dynamic BNFClass, MSG_BNF_SET_CB_SUPPORT
		.enter
		cmp	ds:[cbEnabled], cx
		je	done		; just being careful...

		push	ds
		mov	ds:[cbEnabled], cx
	;
	; Write the state out to the ini file so we remember it next time.
	; 
		xchg	ax, cx

		segmov	ds, cs, cx	; ds, cx <- code segment
		mov	si, offset bnfCat	; ds:si <- category
		mov	dx, offset clipboardKey	; cx:dx <- key
		call	InitFileWriteBoolean
		xchg	ax, cx		; cx <- enable state again, as this
					;  is smaller & shorted than testing
					;  ax...
		pop	ds
		jcxz	disable
	;
	; User wants to turn the beastie on, so hook in the generic support.
	; 
		mov	cx, offset BNFCBImport
		mov	dx, offset BNFCBExport
		call	TCBInit
done:
		.leave
		ret
disable:
	;
	; User wants to turn the beastie off, so unhook the generic support.
	; 
		call	TCBExit
		jmp	done
BNFSetCBSupport	endm

Movable		ends
