COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	Copyright (c) blueway.Softworks 2026 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		OS/2 (DOSBox/BASEBOX) IFS Driver
FILE:		os2Lfn.asm

ROUTINES:
	Name			Description
	----			-----------
    INT DOSLfnEmulate		Run an INT 21h AX=71xxh call through DOS, or
				with 8.3 names
    INT LfnFindFirst		714Eh through 4Eh
    INT LfnFindNext		714Fh through 4Fh
    INT LfnFindClose		71A1h
    INT LfnDtaToFindData	Convert a find DTA to WIN32_FIND_DATA
    INT OS2LfnOptions		HIF_FS_ENABLE options for long file names
    INT OS2LfnInit		See whether DOS offers the LFN API
    INT OS2LfnWanted		[os2] lfn

DESCRIPTION:
	The OS2 driver is built with the long file name code (_LFN), which
	uses the MS-DOS 7 API (INT 21h AX=71xxh) throughout. The calls are
	served, in this order, by:

	1. the pcgeos-basebox host (HIF_API_FS version 2, see
	   os2HostFs.asm), with names in the GEOS character set;
	2. DOS itself, when it offers the LFN API (dosemu2, DOSBox-X with
	   lfn=true, DOSLFN, the Windows 9x DOS box): passed through, names
	   in the DOS code page as usual;
	3. emulation here with the classic calls, i.e. with 8.3 names, the
	   way the driver has always worked - on DOS without LFN, and on
	   drives where DOS answers a call with AX = 7100h.

	[os2] lfn = false in GEOS.INI turns 1 and 2 off.

	Most calls map one to one onto a classic call with the same
	registers; those only get AX rewritten and then go through
	DOSUtilInt21's normal path, including its extended error code
	handling. Find needs a DTA per search handle, kept in lfnFinds.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _LFN

;
; Search handles of emulated finds: kept apart from DOS's own LFN search
; handles, so 714Fh and 71A1h find the right owner when DOS serves some
; drives and the emulation others.
;
LFN_HANDLE_BASE		equ	0ef00h

Resident	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSLfnEmulate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Emulate an MS-DOS 7 long file name call with 8.3 names.

CALLED BY:	DOSUtilInt21 (BIOS lock held), for AH = 71h calls the host
		didn't execute
PASS:		registers for INT 21h AX=71xxh
RETURN:		ZF clear:
			ax	= classic INT 21h call to issue instead (the
				  other registers already fit it)
		ZF set: the call is done
			carry and registers as DOS would return them
			ax	= error code if carry set
DESTROYED:	nothing else

PSEUDO CODE/STRATEGY:
	7139 7141 713A 713B 7147 7156 7160 716C use the registers of the
	classic call: AH = AL. 7143 takes BL as the classic AL.
	Find (714E 714F 71A1) is emulated here. Anything else is not
	supported without long file names.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	FR	11/22/26	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSLfnEmulate	proc	near
	;
	; If DOS offers the LFN API, let it do the call. AX = 7100h back
	; means DOS doesn't do it (for this drive): emulate. Searches the
	; emulation started stay with it.
	;
		push	ds
		segmov	ds, dgroup
		tst	ds:[lfnDos]
		pop	ds
		jz	emulate
		cmp	al, MSDOS_FIND_NEXT
		je	checkHandle
		cmp	al, 0a1h		; find close
		jne	tryDos
checkHandle:
		call	LfnIsOwnHandle
		jc	emulate
tryDos:
	;
	; Some LFN implementations (DOSBox-X) also write classic search data
	; into the current DTA, which may point anywhere by now: give them
	; the driver's own scratch DTA for find first/next.
	;
		cmp	al, MSDOS_FIND_FIRST
		je	privateDTA
		cmp	al, MSDOS_FIND_NEXT
		jne	callDos
privateDTA:
		call	LfnScratchDTA
callDos:
		push	ax
		stc
		call	FileInt21
		jc	dosFailed
		cmp	ax, 7100h		; older DOS: no carry for unknown
		je	notByDos		;  functions
		inc	sp			; drop the saved ax (keeps CF)
		inc	sp
		clc
		jmp	handled
dosFailed:
		cmp	ax, 7100h
		je	notByDos
		inc	sp
		inc	sp
		stc				; ax = DOS's error code
		jmp	handled
notByDos:
		pop	ax			; registers are as passed again

emulate:
		cmp	al, MSDOS_CREATE_DIR
		je	sameRegs
		cmp	al, MSDOS_DELETE_DIR
		je	sameRegs
		cmp	al, MSDOS_SET_CURRENT_DIR
		je	sameRegs
		cmp	al, MSDOS_DELETE_FILE
		je	sameRegs
		cmp	al, MSDOS_GET_CURRENT_DIR
		je	sameRegs
		cmp	al, MSDOS_RENAME_FILE
		je	sameRegs
		cmp	al, 60h			; truename: canonical 8.3 path
		je	sameRegs
		cmp	al, MSDOS_EXTENDED_OPEN_FILE
		je	sameRegs
		cmp	al, MSDOS_GET_SET_ATTRIBUTES
		je	attributes

		cmp	al, MSDOS_FIND_FIRST
		jne	notFirst
		call	LfnFindFirst
		jmp	handled
notFirst:
		cmp	al, MSDOS_FIND_NEXT
		jne	notNext
		call	LfnFindNext
		jmp	handled
notNext:
		cmp	al, 0a1h		; find close
		jne	unsupported
		call	LfnFindClose
		jmp	handled

unsupported:
		mov	ax, ERROR_UNSUPPORTED_FUNCTION
		stc
		jmp	handled

attributes:
		mov	ah, MSDOS_GET_SET_ATTRIBUTES
		mov	al, bl			; 0 = get, 1 = set
		jmp	issue

sameRegs:
		mov	ah, al
		clr	al
issue:
		or	ah, ah			; ah is never 0 here: ZF clear
		ret

handled:
	;
	; Set ZF, keeping the carry and all registers.
	;
		push	bp
		mov	bp, sp
		pushf
		or	{word} ss:[bp-2], mask CPU_ZERO
		popf
		pop	bp
		ret
DOSLfnEmulate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LfnFindFirst
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Emulate 714Eh (find first) with 4Eh.

CALLED BY:	DOSLfnEmulate
PASS:		cl	= allowed attributes
		ch	= required attributes
		ds:dx	= file spec
		es:di	= Win32FindData to fill
RETURN:		carry clear:
			ax	= search handle
			cx	= 0
		carry set:
			ax	= error code
DESTROYED:	nothing else

PSEUDO CODE/STRATEGY:
	Take a free slot of lfnFinds (or the least recently used one if
	all are taken: a search the caller never closed), point the DTA
	at it for the classic find and skip entries without the required
	attributes.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LfnFindFirst	proc	near
callerDS	local	sptr	push	ds
callerDX	local	word	push	dx
allowed		local	byte
		uses	bx, dx, si, di, ds, es
		.enter
		mov	ss:[allowed], cl
		mov	ah, ch			; ah <- required attributes
		push	es, di
		call	LoadVarSegDS
	;
	; Find a slot: a free one, else the least recently used.
	;
		mov	si, offset lfnFinds
		mov	bx, si			; bx <- LRU candidate
		mov	cx, LFN_MAX_FINDS
slotLoop:
		tst	ds:[si].LF_inUse
		jz	haveSlot
		mov	dx, ds:[si].LF_used
		cmp	dx, ds:[bx].LF_used
		jae	nextSlot
		mov	bx, si
nextSlot:
		add	si, size LfnFind
		loop	slotLoop
		mov	si, bx
haveSlot:
		mov	ds:[si].LF_inUse, BB_TRUE
		mov	ds:[si].LF_required, ah
		inc	ds:[lfnFindClock]
		mov	dx, ds:[lfnFindClock]
		mov	ds:[si].LF_used, dx

		call	LfnSetDTA
	;
	; Classic find first, with the allowed attributes.
	;
		push	ds
		mov	ds, ss:[callerDS]
		mov	dx, ss:[callerDX]
		clr	ch
		mov	cl, ss:[allowed]
		mov	ah, MSDOS_FIND_FIRST
		call	FileInt21
		pop	ds
		jc	error
		call	LfnFilterRequired	; skip entries without CH
		jc	error

		pop	es, di
		call	LfnDtaToFindData
	;
	; Search handle = LFN_HANDLE_BASE + slot number + 1.
	;
		mov	ax, si
		sub	ax, offset lfnFinds
		mov	cl, size LfnFind
		div	cl
		clr	ah
		add	ax, LFN_HANDLE_BASE + 1
		clr	cx
		clc
		jmp	done

error:
		pop	es, di
		mov	ds:[si].LF_inUse, BB_FALSE
		stc
done:
		.leave
		ret
LfnFindFirst	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LfnFindNext
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Emulate 714Fh (find next) with 4Fh.

CALLED BY:	DOSLfnEmulate
PASS:		bx	= search handle
		es:di	= Win32FindData to fill
RETURN:		carry clear: cx = 0
		carry set: ax = error code
DESTROYED:	nothing else

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LfnFindNext	proc	near
		uses	bx, dx, si, di, ds, es
		.enter
		push	es, di
		call	LoadVarSegDS
		call	LfnSlotForHandle	; ds:si <- slot
		jc	badHandle
		inc	ds:[lfnFindClock]
		mov	dx, ds:[lfnFindClock]
		mov	ds:[si].LF_used, dx

		call	LfnSetDTA
		mov	ah, MSDOS_FIND_NEXT
		call	FileInt21
		jc	error
		call	LfnFilterRequired
		jc	error

		pop	es, di
		call	LfnDtaToFindData
		clr	cx
		clc
		jmp	done

error:
badHandle:
		pop	es, di
		mov	ax, ERROR_NO_MORE_FILES
		stc
done:
		.leave
		ret
LfnFindNext	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LfnFindClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Emulate 71A1h (find close): free the search's slot.

CALLED BY:	DOSLfnEmulate
PASS:		bx	= search handle
RETURN:		carry clear (an unknown handle is ignored)
DESTROYED:	nothing

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LfnFindClose	proc	near
		uses	si, ds
		.enter
		call	LoadVarSegDS
		call	LfnSlotForHandle
		jc	done
		mov	ds:[si].LF_inUse, BB_FALSE
done:
		clc
		.leave
		ret
LfnFindClose	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LfnSlotForHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Slot of a search handle.

PASS:		bx	= search handle
		ds	= dgroup
RETURN:		carry clear: ds:si = slot in use
		carry set: no such search
DESTROYED:	nothing

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LfnSlotForHandle proc	near
		uses	ax, dx
		.enter
		mov	ax, bx
		sub	ax, LFN_HANDLE_BASE + 1
		cmp	ax, LFN_MAX_FINDS
		jae	bad			; also catches DOS's handles
		mov	dx, size LfnFind
		mul	dx
		add	ax, offset lfnFinds
		mov_tr	si, ax
		tst	ds:[si].LF_inUse
		jz	bad
		clc
		jmp	done
bad:
		stc
done:
		.leave
		ret
LfnSlotForHandle endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LfnIsOwnHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Is a search handle one of the emulation's?

PASS:		bx	= search handle
RETURN:		carry set if it is
DESTROYED:	nothing

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LfnIsOwnHandle	proc	near
		uses	si, ds
		.enter
		segmov	ds, dgroup, si
		call	LfnSlotForHandle	; carry clear if it is ours
		cmc
		.leave
		ret
LfnIsOwnHandle	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LfnScratchDTA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Point DOS's DTA at the driver's scratch DTA before a find
		passed through to DOS.

PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	DOSBox-X's LFN finds write classic search data into the current
	DTA too; without this they overwrote whatever buffer the driver
	last used as DTA (KS_ILLEGAL_HANDLE at boot). The driver sets its
	DTA itself before every classic find, so nothing needs restoring.

	(DOSBox-X also takes an entry of the program's JFT for every open
	LFN search, behind the driver's JFT accounting. The driver only
	holds JFT entries during single operations, so this only matters
	if a search is open while all other entries are in use.)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LfnScratchDTA	proc	near
		uses	ax, dx, ds
		.enter
		segmov	ds, dgroup, ax
		mov	dx, offset lfnScratchDTA
		mov	ah, MSDOS_SET_DTA
		call	FileInt21
		.leave
		ret
LfnScratchDTA	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LfnSetDTA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Point DOS's DTA at a slot for a classic find.

PASS:		ds:si	= slot
RETURN:		nothing
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
	The caller's DTA is not restored afterwards (and not read with
	2Fh): every classic find in the driver sets its DTA first, as the
	driver has always done, and reading the DTA back is something DPMI
	hosts don't all translate.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LfnSetDTA	proc	near
		uses	dx
		.enter
		lea	dx, ds:[si].LF_dta
		mov	ah, MSDOS_SET_DTA
		call	FileInt21
		.leave
		ret
LfnSetDTA	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LfnFilterRequired
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Skip found entries that lack the required attributes
		(CH of 714Eh), which the classic find doesn't know.

PASS:		ds:si	= slot, with the DTA of the entry just found
		DOS's DTA pointing at it
RETURN:		carry clear: an entry with the required attributes
		carry set: ax = error code (no more files)
DESTROYED:	ax

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LfnFilterRequired proc	near
checkEntry:
		mov	al, ds:[si].LF_dta.FFD_attributes
		and	al, ds:[si].LF_required
		cmp	al, ds:[si].LF_required
		je	ok
		mov	ah, MSDOS_FIND_NEXT
		call	FileInt21
		jnc	checkEntry
		ret				; carry set, ax = error
ok:
		clc
		ret
LfnFilterRequired endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LfnDtaToFindData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fill WIN32_FIND_DATA (DOS date/time format) from a find
		DTA. The 8.3 name is the file name; there is no alias.

PASS:		ds:si	= slot
		es:di	= Win32FindData
RETURN:		nothing
DESTROYED:	nothing

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LfnDtaToFindData proc	near
		uses	ax, bx, cx, si, di
		.enter
		mov	bx, di
		clr	ax
		mov	cx, size Win32FindData / 2
		rep	stosw
CheckHack <(size Win32FindData and 1) eq 0>

		mov	al, ds:[si].LF_dta.FFD_attributes
		mov	{byte} es:[bx].W32FD_fileAttrs, al
		mov	ax, {word} ds:[si].LF_dta.FFD_modTime
		mov	{word} es:[bx].W32FD_created.MSD7DT_time, ax
		mov	{word} es:[bx].W32FD_accessed.MSD7DT_time, ax
		mov	{word} es:[bx].W32FD_modified.MSD7DT_time, ax
		mov	ax, {word} ds:[si].LF_dta.FFD_modDate
		mov	{word} es:[bx].W32FD_created.MSD7DT_date, ax
		mov	{word} es:[bx].W32FD_accessed.MSD7DT_date, ax
		mov	{word} es:[bx].W32FD_modified.MSD7DT_date, ax
		movdw	axcx, ds:[si].LF_dta.FFD_fileSize
		movdw	es:[bx].W32FD_fileSizeLow, axcx

		lea	si, ds:[si].LF_dta.FFD_name
		lea	di, es:[bx].W32FD_fileName
		mov	cx, DOS_DOT_FILE_NAME_LENGTH_ZT
copyName:
		lodsb
		stosb
		tst	al
		loopnz	copyName
		.leave
		ret
LfnDtaToFindData endp

Resident	ends


Init		segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OS2LfnOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Options for HIF_FS_ENABLE regarding long file names.

CALLED BY:	OS2HostFsInit
PASS:		ax	= HIF_API_FS version of the host
		di	= options so far
RETURN:		di	= options, with HOSTFS_OPT_LFN if the host offers
			  long file names and GEOS.INI [os2] lfn isn't false
DESTROYED:	nothing

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
os2CatStr	char	'os2', 0
lfnKeyStr	char	'lfn', 0

OS2LfnOptions	proc	near
		.enter
		cmp	ax, HOSTFS_API_VERSION_LFN
		jb	done
		call	OS2LfnWanted
		jc	done
		ornf	di, HOSTFS_OPT_LFN
done:
		.leave
		ret
OS2LfnOptions	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OS2LfnWanted
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Are long file names wanted? GEOS.INI [os2] lfn, default on.

PASS:		nothing
RETURN:		carry set if [os2] lfn = false
DESTROYED:	nothing

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OS2LfnWanted	proc	near
		uses	ax, cx, dx, si, ds
		.enter
		segmov	ds, cs, cx		; ds:si <- category
		mov	si, offset os2CatStr	; cx:dx <- key
		mov	dx, offset lfnKeyStr
		call	InitFileReadBoolean	; carry set if not there
		jc	wanted			; default: on
		tst	ax
		jnz	wanted
		stc				; lfn = false
		jmp	done
wanted:
		clc
done:
		.leave
		ret
OS2LfnWanted	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OS2LfnInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See whether DOS itself offers the long file name API, for
		when the BASEBOX host doesn't provide long file names.

CALLED BY:	OS2Init, after OS2HostFsInit
PASS:		nothing
RETURN:		nothing (lfnDos set)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Ask for the volume information (71A0h) of the default drive's
	root. A DOS without the API answers AX = 7100h (older ones without
	setting the carry); any other answer, even an error for that drive,
	means the API is there.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OS2LfnInit	proc	near
rootName	local	4 dup(char)
fsName		local	16 dup(char)
		uses	ax, bx, cx, dx, di, ds, es
		.enter
		segmov	ds, dgroup, ax
		tst	ds:[lfnAvail]
		jnz	done			; the host serves them
		call	OS2LfnWanted
		jc	done

		mov	ah, MSDOS_GET_DEFAULT_DRIVE
		call	FileInt21		; al <- drive (0 = A)
		add	al, 'A'
		mov	ss:[rootName][0], al
		mov	ss:[rootName][1], ':'
		mov	ss:[rootName][2], '\\'
		mov	ss:[rootName][3], 0

		segmov	ds, ss, ax
		lea	dx, ss:[rootName]
		segmov	es, ss, ax
		lea	di, ss:[fsName]
		mov	cx, size fsName
		mov	ax, 71a0h		; get volume information
		stc
		call	FileInt21
		cmp	ax, 7100h
		je	done			; DOS doesn't know the API
	;
		segmov	ds, dgroup, ax
		mov	ds:[lfnDos], BB_TRUE
done:
		.leave
		ret
OS2LfnInit	endp

Init		ends

endif	; _LFN
