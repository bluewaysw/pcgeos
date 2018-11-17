COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		taskmaxClipboard.asm

AUTHOR:		Adam de Boor, Oct  9, 1991

ROUTINES:
	Name			Description
	----			-----------
	TMCBInit
	TMCBExit

	TMCBImport
	TMCBExport
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	10/9/91		Initial revision


DESCRIPTION:
	Functions for supporting the TaskMax clipboard in rev 1.1 (or
	whatever) of TaskMax.
		

	$Id: taskmaxClipboard.asm,v 1.1 97/04/18 11:58:08 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

udata	segment

tmcbLastSerial	word		; serial number of last imported or exported
				;  clipboard
tmcbEnabled	word		; TRUE if clipboard support hooked in.

udata	ends

Movable		segment	resource

taskmaxCat	char	'taskmax', 0
clipboardKey	char	'clipboard', 0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TMCBInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize support for the TaskMax clipboard

CALLED BY:	TaskMaxAttach
PASS:		ds = es = dgroup
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/9/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TMCBInit	proc	near
		uses	cx, dx, ax, bx, si, bp
		.enter
	;
	; See if TaskMax supports the clipboard API calls.
	; 
		call	SysLockBIOS
		mov	ax, TMAPI_QUERY_CLIPBOARD_STATUS
		int	2fh
		call	SysUnlockBIOS

		tst	ax	; m.b.z. if they're supported
		jnz	done
	;
	; Since they're supported, enable the Clipboard Support list.
	; 
		mov	bx, handle CopyPasteList
		mov	si, offset CopyPasteList
		mov	ax, MSG_GEN_SET_ENABLED
		mov	dl, VUM_NOW
		clr	di
		call	ObjMessage
	;
	; See if we've saved a status to the ini file before. We assume
	; the user doesn't want the support enabled (principle of least
	; surprise) unless we've previously put something in the ini file
	; saying it should be on.
	; 
		push	ds
		segmov	ds, cs, cx		; ds, cx <- cs
		mov	si, offset taskmaxCat
		mov	dx, offset clipboardKey
		call	InitFileReadBoolean
		mov	cx, FALSE		; assume disabled
		jc	setListState
		mov_trash	cx, ax
setListState:
		pop	ds

		mov	ds:[tmcbEnabled], cx
		jcxz	done		; if disabled, do nothing		
	;
	; If it's actually enabled, hook in the generic clipboard support.
	; 
		mov	cx, offset TMCBImport
		mov	dx, offset TMCBExport
		call	TCBInit
done:
		.leave
		ret
TMCBInit	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TMCBExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Dismantle TaskMax clipboard support

CALLED BY:	TaskMaxDetach
PASS:		ds = es = dgroup
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/9/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TMCBExit	proc	near
		.enter
		tst	ds:[tmcbEnabled]
		jz	done
		call	TCBExit
done:
		.leave
		ret
TMCBExit	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TMCBImport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Import data from the TaskMax clipboard

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
	ardeb	10/9/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TMCBImport	proc	near
		uses	ax, dx, es, di
		.enter
	;
	; Snag the DOS lock for the duration, in case TM has to go to disk and
	; we don't have the system stopped...
	; 
		call	SysLockBIOS
		
doItBabe:
		mov	ax, TMAPI_QUERY_CLIPBOARD_STATUS
		clr	cx		; in case this version doesn't support
					;  this API
		int	2fh

		call	SysUnlockBIOS

		tst	ax		; call supported?
		jnz	doNothing	; no; AX must be zero...
		
		jcxz	doNothing	; no data => do nothing

		segmov	es, dgroup, di
		cmp	es:[tmcbLastSerial], dx
		je	doNothing
	;
	; Store the current serial number in case there's something screwy
	; and TaskMax returns us -1 for no apparent reason even though the
	; clipboard hasn't actually changed.
	; 
		mov	es:[tmcbLastSerial], dx
	;
	; Allocate a block that big
	;
		mov_tr	ax, cx
		mov	cx, (mask HAF_LOCK shl 8) or \
				mask HF_SHARABLE or mask HF_SWAPABLE
		call	MemAlloc
		jc	doNothing
		
		mov	ds, ax
	;
	; Fetch the data from TaskMax all at once.
	; 
		call	SysLockBIOS

		mov	es, ax
		clr	di
		mov	ax, TMAPI_FETCH_CLIPBOARD_DATA
		int	2fh

		call	SysUnlockBIOS
		
		cmp	cx, -1		; did we get the data?
		jne	haveData	; yes
	;
	; Clipboard changed, somehow, and we had too small a buffer for the
	; data. Free the block we allocated and try again.
	; 
		call	MemFree
		jmp	doItBabe

haveData:
	;
	; Compress CR-LF pairs into CR-only
	; 
		call	TCBConvertCRLFToCR
		call	MemUnlock
	;
	; Store the serial number of the data we actually got in our
	; tracking variable as well.
	; 
		segmov	es, dgroup, ax
		mov	es:[tmcbLastSerial], dx

done:		
		.leave
		ret

doNothing:
	;
	; We've already got the data, or the switcher doesn't support the call,
	; so do nothing further.
	; 
		clr	cx
		jmp	done
TMCBImport	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TMCBExport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Export the current geos clipboard item to the TaskMax
		clipboard.

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
	ardeb	10/9/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TMCBExport	proc	near
		uses	ax, si, dx
		.enter
	;
	; Expand CRs to CR-LF pairs within the block we've been given.
	; 
		call	TCBConvertCRToCRLF
		jc	done
	;
	; Grab DOS semaphore in case machine not frozen and TM needs to go
	; to disk.
	; 
		call	SysLockBIOS
	;
	; Ask TaskMax to store this data as its clipboard scrap.
	; 
		clr	si
		mov	ax, TMAPI_STORE_CLIPBOARD_DATA
		int	2fh
	;
	; Record its serial number so we don't try and import it when we resume.
	; 
		mov	es:[tmcbLastSerial], dx
	;
	; Release the DOS semaphore since we're done exporting.
	; 
		call	SysUnlockBIOS
done:
		.leave
		ret
TMCBExport	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TMSSetCBSupport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take note of a change in the state of the clipboard support
		list.

CALLED BY:	MSG_TM_SET_CB_SUPPORT
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
TMSetCBSupport	method dynamic TaskMaxClass, MSG_TM_SET_CB_SUPPORT
		.enter
		cmp	ds:[tmcbEnabled], cx
		je	done		; just being careful...

		push	ds
		mov	ds:[tmcbEnabled], cx
	;
	; Write the state out to the ini file so we remember it next time.
	; 
		xchg	ax, cx

		segmov	ds, cs, cx	; ds, cx <- code segment
		mov	si, offset taskmaxCat	; ds:si <- category
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
		mov	cx, offset TMCBImport
		mov	dx, offset TMCBExport
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
TMSetCBSupport	endm

Movable		ends
