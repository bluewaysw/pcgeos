COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel/Geodes
FILE:		geodesC.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

DESCRIPTION:
	This file contains C interface routines for the geode routines

	$Id: geodesC.asm,v 1.1 97/04/05 01:12:03 newdeal Exp $

------------------------------------------------------------------------------@

	SetGeosConvention

C_Common	segment resource

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GeodeDuplicateResource

C DECLARATION:	extern MemHandle
		    GeodeDuplicateResource(MemHandle mh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GEODEDUPLICATERESOURCE	proc	far	; mh:hptr
	C_GetOneWordArg	bx,  ax, dx	;bx = handle

	call	GeodeDuplicateResource
	mov_tr	ax, bx
	ret

GEODEDUPLICATERESOURCE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GeodeGetOptrNS

C DECLARATION:	extern optr
			_far _pascal GeodeGetOptrNS(_near word * _far obj);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GEODEGETOPTRNS	proc	far
	C_GetOneDWordArg	bx, dx,   cx,ax	;bx = id, dx = chunk

	call	GeodeGetResourceHandle	;bx = resource handle
	mov_trash	ax, dx		;ax = chunk
	mov	dx, bx			;dx = handle

	ret

GEODEGETOPTRNS	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GeodeFindResource

C DECLARATION:	extern word
			_far _pascal GeodeFindResource(FileHandle file,
				word resNum, word resOffset, far dword *base)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	11/91		Initial version

------------------------------------------------------------------------------@
GEODEFINDRESOURCE	proc	far	file:hptr, resNum:word,
					resOffset:word, base:fptr.dword
	uses	ds
	.enter

	mov	bx, file
	mov	cx, resNum
	mov	dx, resOffset	
	call	GeodeFindResource	; resource size => AX
					; base position offf resource => CX:DX
	mov	ds, base.high
	mov	bx, base.low
	mov	ds:[bx].low, cx		; store the resource offset
	mov	ds:[bx].high, dx			

	.leave
	ret
GEODEFINDRESOURCE	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	GeodeSnatchResource

C DECLARATION:	extern MemHandle
			_far _pascal GeodeSnatchResource(FileHandle file,
				word resNum, word resOffset)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PJC	2/95		Initial version

------------------------------------------------------------------------------@
GEODESNATCHRESOURCE	proc	far	file:hptr, resNum:word,
					resOffset:word
	.enter

	mov	bx, file
	mov	cx, resNum
	mov	dx, resOffset	
	call	GeodeSnatchResource	; address of locked resource block => AX
					; handle of block => BX
	mov_tr	ax, bx
	jnc	done
	clr	ax

done:
	.leave
	ret
GEODESNATCHRESOURCE	endp



COMMENT @----------------------------------------------------------------------

C FUNCTION:	GeodeSetGeneralPatchPath

C DECLARATION:	extern Boolean
			_far _pascal GeodeSetGeneralPatchPath()

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PJC	2/95		Initial version

------------------------------------------------------------------------------@
GEODESETGENERALPATCHPATH	proc	far	
	.enter

	call	GeodeSetGeneralPatchPath
	mov	ax, 0
	jc	done				; No error.
	dec	ax
done:
	.leave
	ret
GEODESETGENERALPATCHPATH	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	GeodeSetLanguagePatchPath

C DECLARATION:	extern Boolean
			_far _pascal GeodeSetLanguagePatchPath()

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PJC	2/95		Initial version

------------------------------------------------------------------------------@
GEODESETLANGUAGEPATCHPATH	proc	far	
	.enter

	call	GeodeSetLanguagePatchPath
	mov	ax, 0
	jc	done				; No error.
	dec	ax
done:
	.leave
	ret
GEODESETLANGUAGEPATCHPATH	endp



COMMENT @----------------------------------------------------------------------

C FUNCTION:	GeodeSetLanguageStandardPath

C DECLARATION:	extern Boolean
			_far _pascal GeodeSetLanguagePatchPath(StandardPath stdPath)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PJC	2/95		Initial version

------------------------------------------------------------------------------@
GEODESETLANGUAGESTANDARDPATH	proc	far

	C_GetOneWordArg		ax, cx, dx	; ax = stdPath

	call	GeodeSetLanguageStandardPath
	mov	ax, 0
	jc	done				; No error.
	dec	ax
done:
	ret
GEODESETLANGUAGESTANDARDPATH	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	IsMultiLanguageModeOn

C DECLARATION:	extern Boolean
			_far _pascal IsMultiLanguageModeOn()

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PJC	2/95		Initial version

------------------------------------------------------------------------------@
ISMULTILANGUAGEMODEON	proc	far	
	.enter

	call	IsMultiLanguageModeOn
	mov	ax, 0
	jc	done				; No error.
	dec	ax
done:
	.leave
	ret
ISMULTILANGUAGEMODEON	endp




C_Common	ends

C_System	segment resource

if FULL_EXECUTE_IN_PLACE
C_System	ends
GeosCStubXIP	segment	resource
endif

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GeodeLoad

C DECLARATION:	extern GeodeHandle
		    _far _pascal GeodeLoad(const char _far *name,
					    word attrMatch, word attrNoMatch,
					    word priority, dword appInfo,
					    GeodeLoadError *err);
			Note: "name" *can* be pointing to the XIP movable 
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version
	jimmy	8/92		added err parameter
------------------------------------------------------------------------------@
GEODELOAD	proc	far	fname:fptr.char, attrMatch:word,
				attrNoMatch:word, priority:word, appInfo:dword,
				err:fptr

				uses si, di, ds
	.enter

	push	bp
	lds	si, fname
	mov	ax, priority
	mov	cx, attrMatch
	mov	dx, attrNoMatch
	mov	di, appInfo.high
	mov	bp, appInfo.low
	call	GeodeLoad
	pop	bp
	jc	error
	mov_tr	ax, bx		; mov handle into ax for C routines
done:
	.leave
	ret
error:
	lds	si, err
	mov	ds:[si], ax
	jmp	done
GEODELOAD	endp

if FULL_EXECUTE_IN_PLACE
GeosCStubXIP	ends
C_System	segment	resource
endif

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GeodeFind

C DECLARATION:	extern GeodeHandle
		    _far _pascal GeodeFind(const char _far *name,
						word numChars, word attrMatch,
						word attrNoMatch);
			Note: "name" *cannot* be pointing to the XIP movable 
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GEODEFIND	proc	far	fname:fptr.char, numChars:word, attrMatch:word,
				attrNoMatch:word
				uses di, es
	.enter

	les	di, fname
	mov	ax, numChars
	mov	cx, attrMatch
	mov	dx, attrNoMatch
	call	GeodeFind

	mov_trash	ax, bx			;return handle

	.leave
	ret

GEODEFIND	endp



COMMENT @----------------------------------------------------------------------

C FUNCTION:	GeodeGetInfo

C DECLARATION:	extern word
		    _far _pascal GeodeGetInfo(GeodeHandle gh,
					GeodeGetInfoType info, void _far *buf);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GEODEGETINFO	proc	far	gh:hptr, info:GeodeGetInfoType, buf:fptr
					uses di, es
	.enter

	les	di, buf
	mov	ax, info
	mov	bx, gh
	call	GeodeGetInfo

	.leave
	ret

GEODEGETINFO	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GeodeGetAppObject

C DECLARATION:	extern optr
			_far _pascal GeodeGetAppObject(GeodeHandle gh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GEODEGETAPPOBJECT	proc	far
	C_GetOneWordArg	bx   cx,dx	;bx = geode

	push	si
	call	GeodeGetAppObject
	mov	dx, bx			;dx = handle
	mov	ax, si			;ax = chunk
	pop	si
	ret

GEODEGETAPPOBJECT	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GeodeGetUIData

C DECLARATION:	extern word
			_far _pascal GeodeGetUIData(GeodeHandle gh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GEODEGETUIDATA	proc	far
	C_GetOneWordArg	bx   cx,dx	;bx = geode

	call	GeodeGetUIData
	mov_trash	ax, bx
	ret

GEODEGETUIDATA	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GeodeSetUIData

C DECLARATION:	extern word
			_far _pascal GeodeSetUIData(GeodeHandle gh, word data)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GEODESETUIDATA	proc	far
	C_GetTwoWordArgs	bx, ax   cx,dx	;bx = geode, ax = data

	GOTO	GeodeSetUIData

GEODESETUIDATA	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ProcInfo

C DECLARATION:	extern ThreadHandle
			_far _pascal ProcInfo(GeodeHandle gh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
PROCINFO	proc	far
	C_GetOneWordArg	bx   cx,dx	;bx = geode

	call	ProcInfo
	mov_trash	ax, bx
	ret

PROCINFO	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ProcGetLibraryEntry

C DECLARATION:	extern void *
		    ProcGetLibraryEntry(GeodeHandle library, word entryNumber);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
PROCGETLIBRARYENTRY	proc	far
	C_GetTwoWordArgs	bx, ax   cx,dx	;bx = geode, ax = entry #

	call	ProcGetLibraryEntry
	mov	dx, bx
	ret
PROCGETLIBRARYENTRY	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GeodeAllocQueue

C DECLARATION:	extern QueueHandle
			_far _pascal GeodeAllocQueue();

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GEODEALLOCQUEUE	proc	far
	call	GeodeAllocQueue
	mov_trash	ax, bx
	ret

GEODEALLOCQUEUE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GeodeFreeQueue

C DECLARATION:	extern void
			_far _pascal GeodeFreeQueue(QueueHandle qh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GEODEFREEQUEUE	proc	far
	C_GetOneWordArg	bx   cx,dx	;bx = queue

	call	GeodeFreeQueue
	ret

GEODEFREEQUEUE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GeodeInfoQueue

C DECLARATION:	extern word
			_far _pascal GeodeInfoQueue(QueueHandle qh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GEODEINFOQUEUE	proc	far
	C_GetOneWordArg	bx   cx,dx	;bx = queue

	GOTO	GeodeInfoQueue

GEODEINFOQUEUE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ObjDuplicateMessage

C DECLARATION:	extern EventHandle
			ObjDuplicateMessage(EventHandle msg);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
OBJDUPLICATEMESSAGE	proc	far
	C_GetOneWordArg	bx   cx,dx	;bx = message

	call	ObjDuplicateMessage
	ret

OBJDUPLICATEMESSAGE	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	QueuePostMessage

C DECLARATION:	extern void
		    _far _pascal QueuePostMessage(QueueHandle qh,
						EventHandle event,
						MessageFlags flags);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	8/92		Initial version

------------------------------------------------------------------------------@

QUEUEPOSTMESSAGE	proc	far	qh:hptr, event:hptr,
					flags:MessageFlags
					uses si, di
	.enter

	mov	bx, qh
	mov	ax, event
	mov	di, flags
	clr	si
	call	QueuePostMessage

	.leave
	ret

QUEUEPOSTMESSAGE	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	QueueGetMessage

C DECLARATION:	extern EventHandle
		    _far _pascal QueueGetMessage(QueueHandle qh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	8/92		Initial version

------------------------------------------------------------------------------@

QUEUEGETMESSAGE		proc	far	qh:hptr
	.enter

	mov	bx, qh
	call	QueueGetMessage

	.leave
	ret

QUEUEGETMESSAGE	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	GeodeFlushQueue

C DECLARATION:	extern void
		    _far _pascal GeodeFlushQueue(QueueHandle source,
						QueueHandle dest,
						MemHandle objHan,
						ChunkHandle objCh
						word flags);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GEODEFLUSHQUEUE	proc	far	source:hptr, dest:hptr, objHan:hptr,
				objCh:word, flags:word
				uses si, di
	.enter

	mov	bx, source
	mov	si, dest
	mov	cx, objHan
	mov	dx, objCh
	mov	di, flags
	call	GeodeFlushQueue

	.leave
	ret

GEODEFLUSHQUEUE	endp


if FULL_EXECUTE_IN_PLACE
C_System	ends
GeosCStubXIP	segment	resource
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GEODEUSEDRIVER_OLD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Exported in the position of the old, buggy GEODEUSEDRIVER

CALLED BY:	EXTERNAL (old)
PASS:		see GEODEUSEDRIVER
RETURN:		see GEODEUSEDRIVER
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	9/13/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GEODEUSEDRIVER_OLD	proc	far
	REAL_FALL_THRU	GEODEUSEDRIVER
GEODEUSEDRIVER_OLD	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GeodeUseDriver

C DECLARATION:	extern GeodeHandle
		    _far _pascal GeodeUseDriver(const char _far *name,
					word protMajor, word protMinor,
					GeodeLoadError *err);
			Note: "name" *can* be pointing to the XIP movable
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	Note that the returned GeodeHandle will indicate whether or not an
	error occurred (NULL == error).

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version
	jimmy	8/92		added err parameter
	JDM	93.07.21	Fixed error handling.
------------------------------------------------------------------------------@
GEODEUSEDRIVER	proc	far	fname:fptr, protMajor:word, protMinor:word,
				err:fptr
				uses si, ds
	.enter

	lds	si, fname
	mov	ax, protMajor
	mov	bx, protMinor
	call	GeodeUseDriver
	jc	error
	mov_tr	ax, bx   ; move handle into ax for C routines to get at
done:
	.leave
	ret
error:			; load error in err variable for C users to get at
	lds	si, err
	mov	ds:[si], ax
	clr	ax				; Indicate error!
	jmp	done
GEODEUSEDRIVER	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GEODEUSEDRIVERPERMNAME
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	GeodeUseDriverPermName

C DECLARATION:	extern GeodeHandle
		    _far _pascal GeodeUseDriverPermName(
					const char _far *pname,
					word protMajor, word protMinor,
					GeodeLoadError *err);
			Note: "name" *can* be pointing to the XIP movable
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	Note that the returned GeodeHandle will indicate whether or not an
	error occurred (NULL == error).

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dhunter	8/10/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GEODEUSEDRIVERPERMNAME	proc	far	pname:fptr, protMajor:word,
					protMinor:word,
					err:fptr
	uses si, ds
	.enter

	lds	si, pname
	mov	ax, protMajor
	mov	bx, protMinor
	call	GeodeUseDriverPermName
	jc	error
	mov_tr	ax, bx   ; move handle into ax for C routines to get at
done:
	.leave
	ret
error:			; load error in err variable for C users to get at
	lds	si, err
	mov	ds:[si], ax
	clr	ax				; Indicate error!
	jmp	done
GEODEUSEDRIVERPERMNAME	endp

if FULL_EXECUTE_IN_PLACE
GeosCStubXIP	ends
C_System	segment	resource
endif


COMMENT @----------------------------------------------------------------------

C FUNCTION:	GeodeInfoDriver

C DECLARATION:	extern DriverInfoStruct _far *
			_far _pascal GeodeInfoDriver(GeodeHandle gh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GEODEINFODRIVER	proc	far
	C_GetOneWordArg	bx   cx,dx	;bx = geode

	push	si, ds
	call	GeodeInfoDriver
	mov	dx, ds
	mov_trash	ax, si
	pop	si, ds
	ret

GEODEINFODRIVER	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GeodeGetDefaultDriver

C DECLARATION:	extern GeodeHandle
			_far _pascal GeodeGetDefaultDriver(
						GeodeDefaultDriverType type);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GEODEGETDEFAULTDRIVER	proc	far
	C_GetOneWordArg	ax   cx,dx	;ax = type

	GOTO	GeodeGetDefaultDriver

GEODEGETDEFAULTDRIVER	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GeodeSetDefaultDriver

C DECLARATION:	extern void
			_far _pascal GeodeSetDefaultDriver(
				GeodeDefaultDriverType type, GeodeHandle gh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GEODESETDEFAULTDRIVER	proc	far
	C_GetTwoWordArgs	ax, bx,   cx,dx	;ax = type, bx = handle

	call	GeodeSetDefaultDriver
	ret

GEODESETDEFAULTDRIVER	endp

if FULL_EXECUTE_IN_PLACE
C_System	ends
GeosCStubXIP	segment	resource
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GEODEUSELIBRARY_OLD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Exported in the position of the old, buggy GEODEUSELIBRARY

CALLED BY:	EXTERNAL (old)
PASS:		see GEODEUSELIBRARY
RETURN:		see GEODEUSELIBRARY
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	12/13/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global GEODEUSELIBRARY_OLD:far
GEODEUSELIBRARY_OLD	proc	far
	REAL_FALL_THRU	GEODEUSELIBRARY
GEODEUSELIBRARY_OLD	endp

	ForceRef GEODEUSELIBRARY_OLD

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GeodeUseLibrary

C DECLARATION:	extern GeodeHandle
		    _far _pascal GeodeUseLibrary(const char _far *name,
					word protMajor, word protMinor,
					GeodeLoadError *err);
			Note: "name" *can* be pointing to the movable XIP code
				resource.			
KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	Note that the returned GeodeHandle will indicate whether or not an
	error occurred (NULL == error).

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version
	jimmy	8/92		added err parameter
	cassie	12/93		fixed error handling
------------------------------------------------------------------------------@
GEODEUSELIBRARY	proc	far	fname:fptr, protMajor:word, protMinor:word,
				err:fptr

				uses si, ds
	.enter

	lds	si, fname
	mov	ax, protMajor
	mov	bx, protMinor
	call	GeodeUseLibrary
	jc	error
	mov_tr	ax, bx		; mov return value into ax for C routines
done:
	.leave
	ret
error:
	; put the error into the variable passed in
	lds	si, err
	mov	ds:[si], ax
	clr	ax
	jmp	done
GEODEUSELIBRARY	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GEODEUSELIBRARYPERMNAME
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	GeodeUseLibraryPermName

C DECLARATION:	extern GeodeHandle
		    _far _pascal GeodeUseLibraryPermName(
					const char _far *pname,
					word protMajor, word protMinor,
					GeodeLoadError *err);
			Note: "name" *can* be pointing to the movable XIP code
				resource.			

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	Note that the returned GeodeHandle will indicate whether or not an
	error occurred (NULL == error).

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dhunter	8/10/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GEODEUSELIBRARYPERMNAME	proc	far	pname:fptr, protMajor:word,
					protMinor:word,
					err:fptr
	uses si, ds
	.enter

	lds	si, pname
	mov	ax, protMajor
	mov	bx, protMinor
	call	GeodeUseLibraryPermName
	jc	error
	mov_tr	ax, bx		; mov return value into ax for C routines
done:
	.leave
	ret
error:
	; put the error into the variable passed in
	lds	si, err
	mov	ds:[si], ax
	clr	ax
	jmp	done
GEODEUSELIBRARYPERMNAME	endp

if FULL_EXECUTE_IN_PLACE
GeosCStubXIP	ends
C_System	segment	resource
endif

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GeodeFreeLibrary

C DECLARATION:	extern void
			_far _pascal GeodeFreeLibrary(GeodeHandle gh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GEODEFREELIBRARY	proc	far
	C_GetOneWordArg	bx   cx,dx	;bx = geode

	; must jump for routine to work correctly

	jmp	InternalFreeLibrary

GEODEFREELIBRARY	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ObjProcBroadcastMessage

C DECLARATION:	extern void
			_far _pascal ObjProcBroadcastMessage(EventHandle event);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
OBJPROCBROADCASTMESSAGE	proc	far
	C_GetOneWordArg	bx   cx,dx	;bx = message

	call	ObjProcBroadcastMessage
	ret

OBJPROCBROADCASTMESSAGE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GeodePrivAlloc

C DECLARATION:	extern word
		    _far _pascal GeodePrivAlloc(GeodeHandle gh,
					word numWords);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GEODEPRIVALLOC	proc	far	
	.enter
	C_GetTwoWordArgs	bx, cx,		ax,dx
	call	GeodePrivAlloc
	xchg	ax, bx			;AX <- return value
	.leave
	ret

GEODEPRIVALLOC	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GeodePrivFree

C DECLARATION:	extern void
		    _far _pascal GeodePrivFree(word offset,
					word numWords);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GEODEPRIVFREE	proc	far	
	.enter
	C_GetTwoWordArgs	bx, cx,		ax,dx
	call	GeodePrivFree
	.leave
	ret

GEODEPRIVFREE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GEODEPRIVREAD_OLD

C DECLARATION:	extern void
		    _far _pascal GeodePrivRead(GeodeHandle gh, word offset
					word numWords, word *dest);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	This routine is exported in place of the old, buggy version of
	GEODEPRIVREAD.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	9/93		Initial version

------------------------------------------------------------------------------@
GEODEPRIVREAD_OLD	proc	far
	REAL_FALL_THRU	GEODEPRIVREAD
GEODEPRIVREAD_OLD	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GeodePrivRead

C DECLARATION:	extern void
		    _pascal GeodePrivRead(GeodeHandle gh, word offset
					word numWords, word *dest);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GEODEPRIVREAD	proc	far	geodeHandle:hptr,
				privOffset:word,
				numWords:word,
				dest:fptr
	uses	di, si, ds
	.enter
	mov	bx, geodeHandle
	mov	di, privOffset
	mov	cx, numWords
	lds	si, dest		
	call	GeodePrivRead
	.leave
	ret

GEODEPRIVREAD	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GEODEPRIVWRITE_OLD

C DECLARATION:	extern Boolean
		    _far _pascal GeodePrivWrite(GeodeHandle gh, word offset
					word numWords, word *src);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	This routine is exported in place of the old, buggy version of
	GEODEPRIVWRITE.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	9/93		Initial version

------------------------------------------------------------------------------@
GEODEPRIVWRITE_OLD	proc	far
	REAL_FALL_THRU	GEODEPRIVWRITE
GEODEPRIVWRITE_OLD	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GeodePrivWrite

C DECLARATION:	extern Boolean
		    _pascal GeodePrivWrite(GeodeHandle gh, word offset
					word numWords, word *src);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GEODEPRIVWRITE	proc	far	geodeHandle:hptr, 
				privOffset:word,
				numWords:word,
				src:fptr
	uses	di, si, ds
	.enter
	mov	bx, geodeHandle
	mov	di, privOffset
	mov	cx, numWords
	lds	si, src
	call	GeodePrivWrite
    	mov 	ax, FALSE    	; Assume failure.
    	jc 	done
    	mov 	ax, TRUE    	; success
done:
	.leave
	ret

GEODEPRIVWRITE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GeodeAddReference

C DECLARATION:	extern void
		    _far _pascal GeodeAddReference(GeodeHandle gh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GEODEADDREFERENCE	proc	far
	C_GetOneWordArg	bx, cx, dx	; bx <- geode handle
	call	GeodeAddReference
	ret

GEODEADDREFERENCE	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	GeodeRemoveReference

C DECLARATION:	extern Boolean
		    _far _pascal GeodeRemoveReference(GeodeHandle gh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GEODEREMOVEREFERENCE	proc	far
	C_GetOneWordArg	bx, cx, dx	; bx <- geode handle
	call	GeodeRemoveReference
	mov	ax, 0
	jnc	done
	dec	ax
done:
	ret
GEODEREMOVEREFERENCE	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	ECCheckEventHandle

C DECLARATION:	extern void
			 ECCheckEventHandle(EventHandle eh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/93		Initial version

------------------------------------------------------------------------------@
ECCHECKEVENTHANDLE	proc	far
EC <	C_GetOneWordArg	bx,   ax,cx	;bx = handle			>
EC <	GOTO	ECCheckEventHandle					>
NEC <	ret	2							>

ECCHECKEVENTHANDLE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GeodeRequestSpace

C DECLARATION:	extern ReservationHandle
			 GeodeRequestSpace(int amount, GeodeHandle gh);

		return 0 on error

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Robertg	2/95		Initial version

------------------------------------------------------------------------------@
GEODEREQUESTSPACE	proc	far
	C_GetTwoWordArgs	cx, bx,		ax, dx
	call	GeodeRequestSpace
	jc	error
	mov	ax, bx
	ret
error:
	clr	ax
	ret
GEODEREQUESTSPACE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GeodeReturnSpace

C DECLARATION:	extern void
			 GeodeReturnSpace(ReservationHandle resv);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Robertg	2/95		Initial version

------------------------------------------------------------------------------@
GEODERETURNSPACE	proc	far
	C_GetOneWordArg		bx, cx, dx
	call	GeodeReturnSpace
	ret
GEODERETURNSPACE	endp



COMMENT @----------------------------------------------------------------------

C FUNCTION:	GeodeGetGeodeResourceHandle

C DECLARATION:	
extern MemHandle
    _pascal GeodeGetGeodeResourceHandle(GeodeHandle geode, word resourceID)


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	3/12/96		Initial Revision

------------------------------------------------------------------------------@
GEODEGETGEODERESOURCEHANDLE	proc	far
		.enter

		C_GetTwoWordArgs	bx, ax, cx, dx	; bx <- GeodeHandle
							; ax <- resource id
		call	GeodeGetGeodeResourceHandle	; ax <- resource handle

		mov_tr	ax, bx
		
		.leave
		ret
GEODEGETGEODERESOURCEHANDLE	endp

C_System	ends

	SetDefaultConvention


