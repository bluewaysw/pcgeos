COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		nontsStart.asm

AUTHOR:		Adam de Boor, May  9, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	5/ 9/92		Initial revision


DESCRIPTION:
	Code to handle a DR_TASK_START call.
		

	$Id: nontsStart.asm,v 1.1 97/04/18 11:58:16 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NTSMovableCode	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NTSStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start a new task by shutting the system down after building
		up the stuff we'll need to run the program in question.

CALLED BY:	DR_TASK_START
PASS:		ds	= segment of DosExecArgs block
		cx:dx	= boot-up path
RETURN:		carry set if couldn't start:
			ax	= FileError
		carry clear if task on its way:
			ax	= destroyed
DESTROYED:	bx, cx, dx, si, di, es, ds

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 9/92		Initial version
	dlitwin	8/12/93		ERROR_DOS_EXEC_IN_PROGRESS check

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NTSStart	proc	far
		uses	bp
		.enter
	;
	; Gain exclusive access to the NTSExecCode block and make sure another
	; DR_TASK_START isn't already in progress.
	; 
		segmov	es, dgroup, ax
		PSem	es, ntsStartSem, TRASH_AX_BX
		clr	bx		; set/clear nothing
		call	SysSetExitFlags
		test	bl, mask EF_RUN_DOS
		jz	doIt
		mov	ax, ERROR_DOS_EXEC_IN_PROGRESS
		stc
		jmp	done
doIt:

	;
	; Lock down the exec stub resource. Once brought in, it will not
	; be discarded, so we can resize it to our hearts' content.
	; 
		mov	bx, handle NTSExecCode
		call	MemLock
		mov	es, ax
	;
	; Copy all the arguments into the frame.
	; 
		push	cx
		clr	si
		mov	di, offset ntsExecFrame.NTSEF_args
		mov	cx, size DosExecArgs
		rep	movsb
		pop	cx
	;
	; Free the arguments, as we need them no longer.
	; 
		mov	bx, ds:[DEA_handle]
		call	MemFree
	;
	; Copy in the bootup path.
	; 
		mov	ds, cx
		mov	si, dx
		mov	di, offset ntsExecFrame.NTSEF_bootPath
		mov	cx, length NTSEF_bootPath
if DBCS_PCGEOS
	;
	; copy and convert drive letter to DOS
	;
findDrive:
		lodsw				; drive letter
		stosb
		cmp	al, ':'
		loopne	findDrive
		jcxz	noDrive
		mov	bx, di			; ds:bx = rest of path
		jmp	copyPath
		
noDrive:
		mov	bx, offset ntsExecFrame.NTSEF_bootPath
		mov	cx, length NTSEF_bootPath
	;
	; copy rest of path
	;
copyPath:
		rep	movsw			; copy rest of path
	;
	; convert rest to path to DOS
	;
		push	ds, es
		mov	ax, SGIT_SYSTEM_DISK
		call	SysGetInfo
		mov	si, ax			; si = system disk handle
		segmov	ds, es			; ds:dx = src path
		mov	dx, bx
		mov	bx, ds			; bx:cx = dest (same as src)
		mov	cx, dx
		call	FSDLockInfoShared
		mov	es, ax			; es = FSInfo
		mov	ax, FSPOF_MAP_VIRTUAL_NAME shl 8	; allow abort
		mov	di, DR_FS_PATH_OP
		push	bp
		push	si
		call	DiskLock
		call	es:[bp].FSD_strategy
		pop	si
		call	DiskUnlock
		pop	bp
		call	FSDUnlockInfoShared
		pop	ds, es
else
		rep	movsb
endif
	;
	; Locate the loader, if possible.
	; 
		mov	di, offset ntsExecFrame.NTSEF_loader
		call	DosExecLocateLoader
		jc	err
	;
	; Set up the environment for the thing.
	; 
		call	NTSSetupEnvironment		; di <- start for
							;  strings
		jc	insufficientMemory
	;
	; Now copy in the message strings.
	; 
		call	NTSSetupStrings
		jc	insufficientMemory
	;
	; Set up NTSEF_execBlock
	; 
		call	NTSSetupExecBlock
	;
	; All done with setup, so unlock the block with the code and data.
	; 
		mov	bx, handle NTSExecCode
		call	MemUnlock
	;
	; Now shut down the system.
	; 
		mov	bx, mask EF_RUN_DOS
		call	SysSetExitFlags
		mov	ax, SST_CLEAN
		clr	cx		; notify UI when done.
		call	SysShutdown
		clc
done:
		segmov	ds, dgroup, bx
		VSem	ds, ntsStartSem		; doesn't touch carry
		jnc	exit
	;
	; 8/12/93 dlitwin: Check to see if ax (the error code) is
	; ERROR_DOS_EXEC_IN_PROGRESS because if it is we don't need
	; to call NTSShutdownAborted, as we don't want to resize
	; NTSExecCode and abort our shelling to DOS (by clearing
	; EF_RUN_DOS from the exitFlag byte).
	;    This situation occurs when DosExec is called while a DosExec
	; is already in progress, and if we were to call NTSShutdownAborted
	; now it would exit GEOS instead of shelling to DOS and ignoring
	; the second DosExec.
	;
		cmp	ax, ERROR_DOS_EXEC_IN_PROGRESS
		je	carrySetExit
	;
	; Revert the NTSExecCode segment to its former beauty.
	;	
		push	ax
		mov	cx, TRUE		; flag called internally
		call	NTSShutdownAborted
		pop	ax
carrySetExit:
		stc
exit:
		.leave
		ret
insufficientMemory:
		mov	ax, ERROR_INSUFFICIENT_MEMORY
err:
		mov	bx, handle NTSExecCode
		call	MemUnlock
		stc
		jmp	done
NTSStart	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NTSSizeWithProductName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure the size of a string, including any replacements
		for the product name.

CALLED BY:	(INTERNAL) NTSSetupEnvironment, NTSSetupStrings
PASS:		ds:si	= string to size (DBCS)
RETURN:		cx	= length of string, including null
DESTROYED:	nothing
SIDE EFFECTS:	ntsProductName* will be filled in if they haven't been
		already.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/18/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
uiCategory	char	'ui', 0
productNameKey	char	'productName', 0

NTSSizeWithProductName proc	near
		uses	es, si, ax
		.enter
	;
	; See if we've already fetched the product name.
	; 
		segmov	es, dgroup, ax
		tst	es:[ntsProductNameLen]
		jnz	haveName
	;
	; Nope. Look for it in ui::productName in the ini file.
	; 
		push	ds, si, dx, bp, di, bx
		segmov	ds, cs, cx		; ds, cx <- cs
		mov	dx, offset productNameKey	; cx:dx <- key
		mov	si, offset uiCategory		; ds:si <- cat
		mov	di, offset ntsProductName	; es:di <- buffer
		mov	bp, length ntsProductName	; bp <- size + no cvt
		call	InitFileReadString
		jnc	popThingsStoreLen		; => got it
	;
	; Nothing in the .ini file, so we have to use the default string
	; stored in our own NTSStrings resource.
	; 
		mov	bx, handle NTSStrings
		call	MemLock
		mov	ds, ax
		assume	ds:NTSStrings
		mov	si, ds:[defaultProduct]		; (DBCS)
		mov	cx, length ntsProductName-1
copyDefProductLoop:
if DBCS_PCGEOS
		lodsw
		stosw
		tst	ax
		loopnz	copyDefProductLoop
		clr	ax
		stosw		; null-terminate
else
		lodsb
		stosb
		tst	al
		loopnz	copyDefProductLoop
		clr	al
		stosb		; null-terminate
endif
		sub	cx, length ntsProductName-1	; compute size w/o null
		not	cx
		call	MemUnlock
		assume	ds:nothing
popThingsStoreLen:
		mov	es:[ntsProductNameLen], cx
		pop	ds, si, dx, bp, di, bx

haveName:
		clr	cx
countNameLoop:
		inc	cx
countNameLoopNoInc:
if DBCS_PCGEOS
		lodsw
		cmp	ax, 1
else
		lodsb
		cmp	al, 1
endif
		ja	countNameLoop		; => neither done nor subst, so
						;  just count the thing
		jb	haveLength		; => al == 0, so done
		add	cx, es:[ntsProductNameLen]
		jmp	countNameLoopNoInc	; don't inc, to account for
						;  elimination of \1 that we
						;  already counted
haveLength:
		.leave
		ret
NTSSizeWithProductName endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NTSCopyWithProductName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy a string, coping with \1 substitution requests for the
		product name.

CALLED BY:	(INTERNAL) NTSSetupEnvironment, NTSSetupStrings
PASS:		ds:si	= string to copy (DBCS)
		es:di	= place to put it (SBCS)
RETURN:		es:di	= after null terminator
DESTROYED:	si, ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/18/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NTSCopyWithProductName proc	near
		uses	cx
		.enter
copyLoop:
if DBCS_PCGEOS	;=============================================================
		push	si
lengthLoop:
		lodsw
		cmp	ax, 1
		ja	lengthLoop		; stop at null or \1
		mov	cx, si
		pop	si			; ds:si = string
		push	cx			; save end of section
		sub	cx, si			; cx = #bytes
		shr	cx, 1			; # bytes -> # chars
		clr	bx, dx
		call	LocalGeosToDos		; (ignore error)
		add	di, cx			; advance dest ptr
		pop	si			; si = end of section
		cmp	{wchar} ds:[si-2], 0	; processed null?
		je	done			; yes, done
else	;=====================================================================
		lodsb
		stosb
		cmp	al, 1
		ja	copyLoop
		jb	done
endif	;=====================================================================
		dec	di
		push	ds, si
		segmov	ds, dgroup, si
		mov	si, offset ntsProductName
		mov	cx, ds:[ntsProductNameLen]
if DBCS_PCGEOS	;-------------------------------------------------------------
		push	bx, dx
		clr	bx, dx
		call	LocalGeosToDos		; (ignore error)
		pop	bx, dx
		add	di, cx			; advance dest ptr
else	;---------------------------------------------------------------------
		rep	movsb
endif	;---------------------------------------------------------------------
		pop	ds, si
		jmp	copyLoop
done:
		.leave
		ret
NTSCopyWithProductName endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NTSSetupEnvironment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up the environment for the child with the "Type exit
		to return to PC/GEOS" string in the prompt, regardless of
		the interactiveness of the child.

CALLED BY:	NTSStart
PASS:		es	= NTSExecCode
RETURN:		carry set on error
		carry clear if ok:
			es:di	= place to store first localizable message 
				  string.
		
DESTROYED:	ax, bx, cx, si, ds

PSEUDO CODE/STRATEGY:
		foreach variable in the environment:
			if it's PROMPT, record position after the =
		size required <- end pointer + size promptMessage
		if PROMPT not found:
			add size of promptVariable chunk+size defaultPrompt
			
		enlarge NTSExecCode to hold the environment
		copy env up to after the =
		if PROMPT not found:
			copy in promptVariable
		copy in promptMessage
		if PROMPT not found:
			copy in defaultPrompt
		else
			copy the rest of the env
		store final null

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NTSSetupEnvironment proc near
		.enter
		mov	bx, handle NTSStrings
		call	MemLock
		mov	ds, ax

		mov	es, es:[ntsExecFrame].NTSEF_args.DEA_psp
		mov	es, es:[PSP_envBlk]
		clr	di
		mov	si, ds:[promptVariable]
		ChunkSizePtr	ds, si, cx
		clr	dx
		mov	ax, dx		; al <- 0, for finding the end of
					;  things
lookForPromptLoop:
	;
	; es:di	= start of next envar
	; ds:si	= start of promptVariable
	; cx	= length of promptVariable (includes =)
	; dx	<- position in environment after PROMPT=
	; 
		push	cx, si
		repe	cmpsb
		pop	si
		je	foundPrompt
		dec	di		; in case mismatch was null...
	;
	; Scan to the end of the variable (the null-terminator)
	; 
		mov	cx, -1
		repne	scasb
		pop	cx		; cx <- promptVariable length
	;
	; If next char not null too, there's another variable to examine. Else
	; we've hit the end of the environment.
	; 
		cmp	es:[di], al
		jne	lookForPromptLoop
		ChunkSizeHandle	ds, defaultPrompt, ax
		add	cx, ax		; cx <- extra space needed b/c
					;  PROMPT variable not present
		jmp	enlargeNTSEC
foundPrompt:
	;
	; Found the PROMPT variable, and di is now the place at which we'll
	; want to insert our adorable little string. Record that position
	; in dx and skip to the end of the environment.
	; 
		inc	sp
		inc	sp		; discard saved CX
		mov	dx, di		; es:dx <- insertion point
findEnvEndLoop:
		mov	cx, -1
		repne	scasb		; skip to null
		scasb			; another null?
		jne	findEnvEndLoop	; => no, so not at end
		dec	di		; point back to final null
		clr	cx		; no extra space needed, beyond the
					;  adorable string itself
	;--------------------
enlargeNTSEC:
	; ds 	= NTSStrings
	; es:di	= null at end of the environment
	; cx	= number of extra bytes, beyond those required for the prompt
	;	  message itself
	; es:dx	= place at which to insert the prompt message.
	;
	; Enlarge NTSExecCode to hold the new environment.
	; 
		stc			; +1 to have room for final null
		adc	cx, di
		push	cx
		mov	si, ds:[promptMessage]
		call	NTSSizeWithProductName
		mov_tr	ax, cx
		pop	cx
		push	ax		; save length for conversion to DOS

DBCS <		shl	ax, 1		; # chars -> # bytes		>
		add	ax, cx		; ax <- amount needed.
		mov	cx, offset ntsEnvKindaStart+15
		andnf	cx, not 0xf
		add	ax, cx
		clr	cx		; no special flags
		mov	bx, handle NTSExecCode
EC <		push	es						>
EC <		segmov	es, ds		; avoid ec +segment death	>
		call	MemReAlloc
EC <		pop	es						>
		pop	cx		; cx <- length of promptMessage
		jc	done		; => can't enlarge, so can't exec

		mov	bx, ds		; bx <- NTSStrings
		segmov	ds, es		; ds <- environment
		mov	es, ax		; es <- NTSExecCode
		clr	si
		push	di		; save the end of the environment
		mov	di, offset ntsEnvKindaStart+15
		andnf	di, not 0xf
	;
	; Copy environment data up to the insertion point.
	; 
		xchg	cx, dx		; cx <- length up to var, dx <- length
					;  of promptMessage
		jcxz	storeNewPromptVar
		rep	movsb
	;
	; Copy in the promptMessage and convert it to the DOS character set.
	; 
		push	ds, si		; save environment pointer
		mov	ds, bx		; ds <- NTSStrings
		mov	si, ds:[promptMessage]	; ds:si <- promptMessage
		
SBCS <		push	di		; save start for conversion	>
					;  to DOS character set
		call	NTSCopyWithProductName
		dec	di		; point to null

if DBCS_PCGEOS
convertPromptMessageToDOS:
else
		pop	si
		mov	cx, dx		; cx <- # chars to convert

convertPromptMessageToDOS:
	; es:si	= string to convert
	; cx	= # chars to convert
	;
	; on_stack:	ds, si		; first byte of the rest of the env
	; 
		mov	ax, '?'		; what the heck. Use ? as the default
		segmov	ds, es		; ds:si <- string to convert
		call	LocalGeosToDos
endif
		pop	ds, si		; recover environment pointer

	; ds:si	= place from which to copy
	; es:di	= place to which to copy
		pop	cx		; cx <- end of environment
		sub	cx, si
		rep	movsb		; copy remaining bytes

		clr	al		; store second null byte to terminate
		stosb			;  the environment.

	;
	; All done, so unlock the strings block.
	; 
		clc			; success
done:
EC <		segmov	ds, es		; avoid ec +segment death	>
		mov	bx, handle NTSStrings
		call	MemUnlock
		.leave
		ret

storeNewPromptVar:
		push	ds, si
		mov	dx, di		; save starting point
		mov	ds, bx		; ds <- NTSStrings
		
		mov	si, ds:[promptVariable]	; (SBCS)
		ChunkSizePtr	ds, si, cx
		rep	movsb
		
		mov	si, ds:[promptMessage]
		call	NTSCopyWithProductName
		dec	di		; point to null

		mov	si, ds:[defaultPrompt]
		ChunkSizePtr	ds, si, cx
		rep	movsb
		
if not DBCS_PCGEOS
		mov	si, dx		; si <- start of strings just copied in
		mov	cx, di
		sub	cx, dx		; cx <- # chars to convert
endif
		jmp	convertPromptMessageToDOS
NTSSetupEnvironment endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NTSSetupStrings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy in the message strings from the NTSStrings block, and
		convert them to the DOS character set, pointing the various
		fields in nontsExecFrame to their respective strings.

CALLED BY:	NTSStart
PASS:		es:di	= place to store first string
RETURN:		carry set on error
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ntsStringChunks	word	DE_execError, DE_prompt, DE_failedReload, noMemError
ntsStringPtrs	word	ntsExecFrame.NTSEF_execError,
			ntsExecFrame.NTSEF_prompt,
			ntsExecFrame.NTSEF_failedReload,
			ntsExecFrame.NTSEF_noMemory
NTSSetupStrings	proc	near
		.enter
		mov	bx, handle NTSStrings
		call	MemLock
		mov	ds, ax
	;
	; First figure the number of bytes all these strings will require.
	; dx ends up with the # bytes
	; 
		mov	si, offset ntsStringChunks
		mov	cx, length ntsStringChunks
		clr	dx
figureLengthLoop:
		lodsw	cs:
		xchg	ax, si			; *ds:si <- string
		push	cx
		mov	si, ds:[si]		; ds:si <- string
		call	NTSSizeWithProductName	; cx <- length of same
		add	dx, cx			; add into total
		mov_tr	si, ax			; cs:si <- addr of next chunk
		pop	cx
		loop	figureLengthLoop
DBCS <		shl	dx, 1			; # chars -> # bytes	>
	;
	; Enlarge the NTSExecCode block to hold them all.
	; 
		mov	ax, di
		add	ax, dx			; ax <- size of block. no
						;  special flags to pass, and
						;  cx is already 0...
		mov	bx, handle NTSExecCode
		call	MemReAlloc
		jc	done
		mov	es, ax			; es <- new segment
	;
	; Now copy the chunks into the block and convert them to the DOS
	; character set.
	; 
		mov	si, offset ntsStringChunks
		mov	cx, length ntsStringChunks
copyStringLoop:
	;
	; Store the start of the string in the apropriate part of the
	; nontsExecFrame.
	; 
		mov	bx, cs:[si+(ntsStringPtrs-ntsStringChunks)]
		mov	es:[bx], di
	;
	; Copy the string into the block.
	; 
		lodsw	cs:
		push	ds, si, cx

		mov_tr	si, ax			; *ds:si <- string
		mov	si, ds:[si]		; ds:si <- string

SBCS <		push	di			; save start for conversion>
		call	NTSCopyWithProductName

if not DBCS_PCGEOS
		pop	si
		mov	cx, di
		stc
		sbb	cx, si			; cx <- # chars to convert (w/o
						;  null)
		segmov	ds, es			; ds:si <- string to convert
		mov	ax, '?'			; default char (foo)
		call	LocalGeosToDos
endif
	;
	; Loop to deal with the next string
	; 
		pop	ds, si, cx
		loop	copyStringLoop
		clc
done:
		mov	bx, handle NTSStrings
		call	MemUnlock
		.leave
		ret
NTSSetupStrings	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NTSSetupExecBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform all the piddly-hooey things we must do to run
		a DOS program, setting up the NTSEF_execBlock.

CALLED BY:	NTSStart
PASS:		es	= NTSExecCode
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, ds, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NTSSetupExecBlock proc	near
		.enter
		segmov	ds, es
		lea	si, ds:[ntsExecFrame].NTSEF_args.DEA_args
		lea	di, es:[ntsExecFrame].NTSEF_fcb1
		mov	ax, MSDOS_PARSE_FILENAME shl 8 or \
				DosParseFilenameControl <
					0,	; always set ext
					0,	; always set name
					0,	; always set drive
					1	; ignore leading space
				>
		call	FileInt21	; ds:si <- after first name

		lea	di, es:[ntsExecFrame].NTSEF_fcb2
		mov	ax, MSDOS_PARSE_FILENAME shl 8 or \
				DosParseFilenameControl <
					0,	; always set ext
					0,	; always set name
					0,	; always set drive
					1	; ignore leading space
				>
		call	FileInt21
		.leave
		ret
NTSSetupExecBlock endp

NTSMovableCode	ends
