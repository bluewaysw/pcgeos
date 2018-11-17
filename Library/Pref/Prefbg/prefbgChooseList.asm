COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		prefbgChooseList.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/29/92   	Initial version.

DESCRIPTION:
	

	$Id: prefbgChooseList.asm,v 1.1 97/04/05 01:29:18 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

udata	segment

gstringToConvert	dword	; ^v<file>:<block> of graphics string to
				;  convert.

udata	ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefBGChooseListSaveOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	If item zero is selected, the background key is
		deleted instead of writing out "Standard Solid Background"

PASS:		*ds:si	= PrefBGChooseListClass object
		ds:di	= PrefBGChooseListClass instance data
		es	= dgroup

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/29/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefBGChooseListSaveOptions	method	dynamic	PrefBGChooseListClass, 
					MSG_GEN_SAVE_OPTIONS

	push	bp
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	call	ObjCallInstanceNoLock
	pop	bp

	tst	ax
	jnz	callSuper

deleteEntry:
	mov	cx, ss
	mov	ds, cx
	lea	si, ss:[bp].GOP_category
	lea	dx, ss:[bp].GOP_key
	call	InitFileDeleteEntry
	ret					; EXIT

callSuper:
	call	PrefBGChooseListUpgradeBGIfNecessary
	jc	deleteEntry

callSuperAfterUpgrade::
	mov	ax, MSG_GEN_SAVE_OPTIONS
	mov	di, offset PrefBGChooseListClass
	GOTO	ObjCallSuperNoLock		; EXIT


PrefBGChooseListSaveOptions	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefBGChooseListUpgradeBGIfNecessary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Possibly upgrade a 1.x background to 2.0.

CALLED BY:	(INTERNAL) PrefBGChooseListSaveOptions
PASS:		*ds:si	= PrefBGChooseList object
		ax	= selection number
RETURN:		carry set if couldn't upgrade
DESTROYED:	ax, cx, dx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 9/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefBGChooseListUpgradeBGIfNecessary proc near
	uses	bp, es, si
	.enter
	;
	; Change to the proper path.
	; 
	call	FilePushDir
	
	mov	ax, ATTR_GEN_PATH_DATA
	mov	dx, TEMP_GEN_PATH_SAVED_DISK_HANDLE
	call	GenPathSetCurrentPathFromObjectPath

	;
	; Fetch the name of the file from ourselves.
	; 
	mov	bp, size FileLongName
	sub	sp, bp
	mov	cx, ss
	mov	dx, sp
	mov	ax, MSG_PREF_ITEM_GROUP_GET_SELECTED_ITEM_TEXT
	call	ObjCallInstanceNoLock
	
	;
	; Fetch its protocol number. Easier to do it via the path than calling
	; VMOpen, opening the thing read-write (which might be denied, and
	; we might not even need it read-write, if it's up to snuff).
	; 
	mov	es, cx
	sub	sp, size ProtocolNumber
	mov	di, sp
	push	ds
	mov	ds, cx
	mov	cx, size ProtocolNumber
	mov	ax, FEA_PROTOCOL
	call	FileGetPathExtAttributes		; carry set on error
	pop	ds
	jc	fail					; an error occured...
	
	cmp	es:[di].PN_major, BG_PROTO_MAJOR
	jb	upgrade
	ja	fail
	cmp	es:[di].PN_minor, BG_PROTO_MINOR
	jb	upgrade
	
done:
	mov	di, sp
	lea	sp, ss:[di + size ProtocolNumber + size FileLongName]
	call	FilePopDir
	.leave
	ret
fail:
	stc
	jmp	done

closeAndFail:
	mov	al, FILE_NO_ERRORS
	call	VMClose
	stc
toBringDownNotice:
	jmp	bringDownNotice

upgrade:
	;
	; Put up a box telling the user what's going down.
	; 
	mov	si, offset BackgroundConvertNotice
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	push	dx
	call	ObjCallInstanceNoLock
	pop	dx
	push	ds
	segmov	ds, ss

	;
	; Has an incompatible version. For now, this just means it's a 1.x
	; graphics string (it must have already been converted to a 2.0
	; VM file for us to even have displayed it). Later, this might mean
	; other things.
	; 
	mov	ax, (VMO_OPEN shl 8) or \
			mask VMAF_USE_BLOCK_LEVEL_SYNCHRONIZATION or \
			mask VMAF_FORCE_DENY_WRITE or \
			mask VMAF_FORCE_READ_WRITE
	call	VMOpen
	pop	ds
	jc	toBringDownNotice
	
	;
	; Make sure it holds a graphics string, as that's the only thing we
	; understand how to convert.
	; 
	call	VMGetMapBlock
	call	VMLock
	mov	es, ax
	mov	di, es:[FBGMB_data]		; assume gstring..
	cmp	es:[FBGMB_type], FBGFT_STANDARD_GSTRING
	call	VMUnlock
	jne	closeAndFail		; don't know how to upgrade that...

	;
	; Spawn a thread to perform the conversion, so we can deal with
	; ui-related things (all this in the name of feedback. sheesh)
	; 
	segmov	es, dgroup, ax
	
	movdw	es:[gstringToConvert], bxdi

	mov	al, PRIORITY_STANDARD
	mov	cx, cs
	mov	dx, offset PrefBGConvertGString
	mov	di, 1000
	call	GeodeGetProcessHandle
	mov	bp, bx		; bp <- owner
	call	ThreadCreate
	jc	reloadFileCloseAndFail
	
	;
	; Now dispatch events until we receive the
	; MSG_PROCESS_NOTIFY_THREAD_EXIT for the thread.
	; 
	call	PrefBGWaitForThreadToExit
	mov	bx, es:[gstringToConvert].handle
	tst	ax
	jz	closeAndFail
	mov_tr	di, ax		; save block handle
	
	;
	; Point the map block to the new graphics string.
	; 
	call	VMGetMapBlock
	call	VMLock
	mov	es, ax
	mov	es:[FBGMB_data], di
	call	VMDirty
	call	VMUnlock
	
	;
	; Set the new protocol number to signal its up-to-datedness.
	; 
	mov	cx, size ProtocolNumber
	sub	sp, cx
	mov	di, sp
	segmov	es, ss
	mov	es:[di].PN_major, BG_PROTO_MAJOR
	mov	es:[di].PN_minor, BG_PROTO_MINOR
	mov	ax, FEA_PROTOCOL
	call	FileSetHandleExtAttributes
	add	sp, size ProtocolNumber
	;
	; Close the file and boogie with much happiness.
	; 
	mov	al, FILE_NO_ERRORS
	call	VMClose
	clc

bringDownNotice:
	;
	; Bring down the box saying what we're doing.
	; 
	mov	si, offset BackgroundConvertNotice
	mov	ax, MSG_GEN_INTERACTION_ACTIVATE_COMMAND
	mov	cx, IC_DISMISS
	pushf
	call	ObjCallInstanceNoLock
	popf
	jmp	done

reloadFileCloseAndFail:
	mov	bx, es:[gstringToConvert].handle
	jmp	closeAndFail
PrefBGChooseListUpgradeBGIfNecessary endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefBGWaitForThreadToExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Hang out dispatching messages until the thread spawned to
		convert the background exits.

CALLED BY:	(INTERNAL) PrefBGChooseListUpgradeBGIfNecessary
PASS:		bx	= handle of thread whose exit is awaited
		es	= dgroup
RETURN:		ax	= thread's exit code.
DESTROYED:	ax, bx, cx, dx, si, di
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 9/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefBGWaitForThreadToExit proc	near
	.enter
	mov	di, bx				; di <- thread for which we're
						;  waiting
	;
	; Fetch our thread's event queue handle so we can block on it awaiting
	; the next event.
	; 
	mov	ax, TGIT_QUEUE_HANDLE
	clr	bx
	call	ThreadGetInfo

	;
	; Fetch our process handle so we can tell when to check for
	; MSG_PROCESS_NOTIFY_THREAD_EXIT (can't do so unless handle of dest
	; optr is the process).
	; 
	call	GeodeGetProcessHandle
	mov	bp, bx				; need this to detect message

	mov_tr	bx, ax				; bx <- event queue for the loop
messageLoop:
	;
	; Wait for the next message to come in. Each time through this loop,
	; we will pluck the next message from the queue and set DX non-zero
	; if it's the MSG_PROCESS_NOTIFY_THREAD_EXIT for the thread in question.
	; 
	call	QueueGetMessage			; ax <- next message

	push	bx, bp				; save queue & process handle
	;
	; Find out for whom the message is destined.
	; 
	mov_tr	bx, ax
	call	ObjGetMessageInfo		; ax <- message, ^lcx:si <- dest
	clr	dx				; assume not right

	cmp	cx, bp				; to process?
	jne	dispatchIt			; no -- just dispatch it.

	cmp	ax, MSG_PROCESS_NOTIFY_THREAD_EXIT	; right message?
	jne	dispatchIt			; no -- just dispatch it.
	
	; right message to the right place. Make sure it's the right thread
	
	push	cs
	mov	si, offset checkThread	; si <- callback offset, and non-zero
					;  to say we want to preserve the
					;  event.
	push	si
	call	MessageProcess		; dx <- non-zero if message is for the
					;  right thread.
					; ax <- exit code, if this is the one

dispatchIt:
	;
	; Send the message we snagged off to its final destination.
	; 
	push	di, ax
	clr	di			; don't preserve it, but preserve ax,
					;  and dx (and, coincidentally, cx and
					;  bp)
	call	MessageDispatch
	pop	di, ax
	pop	bx, bp

	tst	dx
	jz	messageLoop
	
	.leave
	ret

	;--------------------
	; Callback routine for MessageProcess to see if the event tells us of
	; the desired thread having met its timely end.
	;
	; Pass:		cx	= thread that exited
	; 		dx	= exit code
	; 		di	= thread for which we're seeking
	; Return:	dx	= 0 if not the right thread
	;			= non-zero if thread handles match:
	;			  ax	= exit code
	;
checkThread:
	mov_tr	ax, dx		; ax <- exit code, in case
	clr	dx		; assume not thread
	cmp	cx, di		
	jne	checkThreadDone
	dec	dx		; flag exit seen
checkThreadDone:
	retf
PrefBGWaitForThreadToExit endp
	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefBGConvertGString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert the graphics string stored in a VM file.

CALLED BY:	PrefBGChooseListUpgradeBGIfNecessary via ThreadCreate
PASS:		ds = es = prefmgr::dgroup
		es:[gstringToConvert] = ^v<file>:<block> of gstring to
			   convert.
RETURN:		exit zero if conversion failed.
		else exit with the VM block handle of the new gstring
DESTROYED:	everything
SIDE EFFECTS:	old gstring is destroyed if conversion successful.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 9/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefBGConvertGString proc	far
	;
	; Load the convert library to do the work.
	; 
	call	PrefBGChooseListLoadConvertLibrary
	jc	checkError
	
	segmov	ds, dgroup, cx
	
	;
	; Ask it to do the work.
	; 
	movdw	cxdi, ds:[gstringToConvert]	; ^vcx:di <- gstring
	mov	dx, cx			; dx <- file in which to place
					;  new string
	mov	si, mask GSCO_FREE_ORIG_GSTRING

	mov	ax, enum ConvertGString
	push	bx
	call	ProcGetLibraryEntry
	call	ProcCallFixedOrMovable
	pop	bx

	;
	; Unload the library
	; 
	pushf
	call	GeodeFreeLibrary
	popf

checkError:
	mov	cx, di		; return block of new gstring as exit code
	jnc	done
	clr	cx		; zero exit code on failure
done:
	clr	dx, bp, si	; no MSG_META_ACK necessary
	jmp	ThreadDestroy
PrefBGConvertGString endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefBGChooseListLoadConvertLibrary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load the 1.x document conversion library.

CALLED BY:	(INTERNAL) PrefBGChooseListUpgradeBGIfNecessary
PASS:		nothing
RETURN:		carry set on error
		carry clear if loaded:
			bx	= geode handle for library
DESTROYED:	ds, ax, current directory
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 9/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SBCS <convertWD	char	CONVERT_LIB_DIR					>
SBCS <convertLib	char	CONVERT_LIB_PATH			>
DBCS <convertWD	wchar	CONVERT_LIB_DIR					>
DBCS <convertLib	wchar	CONVERT_LIB_PATH			>

PrefBGChooseListLoadConvertLibrary proc	near
	uses	si, dx, ds
	.enter
	segmov	ds, cs
	mov	dx, offset convertWD
	mov	bx, CONVERT_LIB_DISK_HANDLE
	call	FileSetCurrentPath
	jc	done
	
	mov	si, offset convertLib
	mov	ax, CONVERT_PROTO_MAJOR
	mov	bx, CONVERT_PROTO_MINOR
	call	GeodeUseLibrary
done:
	.leave
	ret
PrefBGChooseListLoadConvertLibrary endp
