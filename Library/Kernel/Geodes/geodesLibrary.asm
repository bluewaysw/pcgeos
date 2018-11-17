COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Geode
FILE:		geodeLibrary.asm

ROUTINES:
	Name			Description
	----			-----------
    GLB GeodeFreeLibrary	Free a library given its handle

    INT CallLibraryEntry	Call a library's entry routine

    INT GeodeNotifyLibraries	Notify all libraries of the passed geode of
				something momentous happening. This
				function must reside in kcode so DispatchSI
				can return to it after a thread has been
				spawned.

    INT ProcessLibraryTable	Process a library table for GeodeLoad

    INT TryOpenEC		Try and open the EC version of the library,
				forming the name of the beast in
				useLibraryBuffer, with ec.geo tacked onto
				the end.

    INT TryOpenLib		Try and open the .geo version of the
				library, forming the name of the beast in
				useLibraryBuffer, with .geo tacked onto the
				end.

    INT TryOpenCommon		Common code to open a library's .geo file
				once the permanent name has been properly
				copied and truncated.

    INT BuildFullLibraryTable	Build up a table of the core blocks of all
				libraries used by the given geode, either
				explicitly (it imports them itself) or
				implicitly (they are imported by libraries
				imported by it), for use in startup/exit
				notifications

    GLB GeodeUseLibrary		Use the given library.	If it is not
				loaded, find it on disk and load it.  If it
				is loaded, increment its reference count.

    INT UseLibraryDriverCommon	Common code for GeodeUseLibraryCommon and
				GeodeUseDriverCommon

    INT UseLibraryLow		Use the given library.	If it is not
				loaded, find it on disk and load it.  If it
				is loaded, increment its reference count.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/88		Initial version

DESCRIPTION:
	This file contains routines to handle libraries.

	$Id: geodesLibrary.asm,v 1.1 97/04/05 01:11:59 newdeal Exp $

-------------------------------------------------------------------------------@


COMMENT @----------------------------------------------------------------------

FUNCTION:	GeodeFreeLibrary

DESCRIPTION:	Free a library given its handle

CALLED BY:	GLOBAL

PASS:
	bx - library handle

RETURN:
	carry set if library was exited

DESTROYED:
	bx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		----------
	Tony	9/88		Initial version
------------------------------------------------------------------------------@



GeodeFreeLibrary	proc	far call
InternalFreeLibrary	label	far
EC <	call	ECCheckGeodeHandle					>
	call	PushAll

	;
	; Tell any dynamically acquired extra libraries that this thread is
	; exiting, as far as they're concerned. Anything already known as an
	; extra or imported library we leave alone, of course, as when this
	; thread goes away, it'll eventually be told.
	; 
	mov	di, LCT_CLIENT_THREAD_EXIT
	call	NotifyNewLibraries

	LoadVarSeg	ds

	call	NearLockES
	test	es:[GH_geodeAttr], mask GA_LIBRARY
	jz	freeTheThing
	;
	; Figure the geode that's doing the freeing by seeing who owns
	; the segment from which we were called...
	;
	mov	bp, sp
	mov	cx, ss:[bp].PAF_fret.segment

	push	bx
	call	SegmentToHandle
EC <	ERROR_NC	GEODE_FREE_LIBRARY_CALLER_UNKNOWN		>
	mov	bx, cx
	mov	cx, ds:[bx].HM_owner
	;
	; Now tell the library a client is biffing it, thank you very much.
	;
	call	SwapESDS		; ds <- core block, es <- idata
	mov	di, LCT_CLIENT_EXIT
	call	CallLibraryEntry
	call	SwapESDS		; es <- core block, ds <- idata
	pop	bx
	
freeTheThing:
	call	NearUnlock
EC <	call	NullES							>
	call	FreeGeode
	call	PopAll
	ret

GeodeFreeLibrary	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	CallLibraryEntry

DESCRIPTION:	Call a library's entry routine

CALLED BY:	INTERNAL
		UseLibrary

PASS:
	ds - core block for library
	di - flag to pass to LibraryEntry (LibraryCallType)
	cx - handle of client geode, if not LCT_ATTACH or LCT_DETACH

RETURN:
	carry - returned from routine

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

	Pass to library entry (asm):
		ds = dgroup

	Pass to library entry (C):
		LibraryEntry(LibraryCallType ty, GeodeHandle client);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		----------
	Tony	9/88		Initial version
------------------------------------------------------------------------------@

CallLibraryEntry	proc	far
	call	PushAll
	mov	ax,ds:[GH_libEntryOff]		;pass offset in ax
	mov	bx,ds:[GH_libEntrySegment]	;segment/handle in bx

	; if no entry routine then don't call

	tst	bx
	jz	done			;carry will be clear

	test	ds:[GH_geodeAttr], mask GA_ENTRY_POINTS_IN_C
	mov	si,ds:[GH_resHandleOff]
	mov	si,ds:[si][2]			;si = handle of dgroup
	LoadVarSeg	ds
	mov	ds,ds:[si].HM_addr		;pass dgroup
	jz	notC

	; C API -- push client and type

	push	di
	push	cx
	call	ProcCallFixedOrMovable		;returns ax = result
	tst	ax
	jz	done
	stc
	jmp	done

notC:
	call	ProcCallFixedOrMovable

done:
	call	PopAll
	ret

CallLibraryEntry	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeodeNotifyLibraries
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify all libraries of the passed geode of something
		momentous happening. This function must reside in kcode
		so DispatchSI can return to it after a thread has been
		spawned.

CALLED BY:	INTERNAL
PASS:		di	= LibraryCallType
		si	= handle of geode (0 => current thread's owner)
RETURN:		carry set if any library returned carry set. All libraries
		will have been called.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Must be far as it's used by CreateThreadCommon to get to
		the initial cs:ip for the thread

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeodeNotifyLibraries proc	far
		uses	ax, bx, cx, dx, si, ds, es
		.enter
	;
	; Use owner of current thread if SI passed as 0.
	; 
		tst	si
		jnz	haveCoreBlock
		mov	si, ss:[TPD_processHandle]
haveCoreBlock:
	;
	; Lock down the core block first.
	; 
		mov	bx, si
		call	NearLockES
	;
	; Notify the things in the extra table first, on the assumption that
	; the farthest-away geodes should be notified first, as being the
	; most client-ridden, as it were, from the current geode's
	; perspective.
	; 
		clr	al		; flag no error yet
		mov	cx, es:[GH_extraLibCount]
		jcxz	doExplicitLibs
		mov	si, es:[GH_extraLibOffset]
		call	notifyTable
doExplicitLibs:
		mov	cx, es:[GH_libCount]
		jcxz	done
		mov	si, es:[GH_libOffset]
		call	notifyTable
done:
	;
	; Set carry if we received carry set from any library we called.
	; 
		mov	ah, al
		sahf

		call	MemUnlock
		.leave
		ret

	;
	; Internal routine to notify a bunch of libraries, given the base
	; and length of the table of their core block handles.
	; Pass:
	; 	es:si	= table of core block handles
	; 	cx	= number of entries in same
	; 	bx	= handle of current thread's geode
	; 	di	= LibraryCallType to pass to library
	; 	al	= flags from previous call to notifyTable (initialized
	;		  to 0.
	; Return:
	; 	al	= updated so if moved to ah and sahf done, the carry
	;		  will be set if an error was returned by any library.
	; 
notifyTable:
		push	ax
		lodsw	es:
		push	cx
		mov	cx, bx
		mov_tr	bx, ax
		call	NearLockDS
		call	CallLibraryEntry
		call	MemUnlock
EC <		call	NullDS						>
		mov	bx, cx
		pop	cx
		pop	ax
		lahf
		or	al, ah
		loop	notifyTable
		retn
GeodeNotifyLibraries endp


GLoad	segment resource

if 	FULL_EXECUTE_IN_PLACE

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProcessXIPLibraryTable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Processes the table of XIP geodes, and loads any libraries that
		need to be loaded.

CALLED BY:	LoadXIPGeodeWithHandle
PASS:		ds - coreblock of geode
RETURN:		nada
DESTROYED:	ax, bx, cx, dx, di, si
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	4/ 7/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ProcessXIPLibraryTable	proc	near	uses	es
	.enter
	clr	cx			;Clears carry
	xchg	cx, ds:[GH_libCount]
	jcxz	exit			;Exit w/carry clear if the geode does
					; not use any libraries
	mov	si, ds:[GH_libOffset]	;DS:SI <- ptr into table of library
					; handles.
loopTop:
;
; DS:SI <- ptr to current place in GH_libOffset table
; CX <- # libraries still to load
;
	lodsw
	push	cx
	mov	cx, ds:[GH_geodeHandle]	;CX <- client handle

;	Pass a pointer to a fake ImportedLibraryEntry structure - the XIP tool
;	already made sure that the protocols were OK, so don't bother here.

	segmov	es, cs
	mov	di, offset fakeILE

	call	UseXIPLibrary
	pop	cx
	jc	error

	inc	ds:[GH_libCount]
	loop	loopTop
exit:
	.leave
	ret
error:

;	Map the library error code, and free up any geodes that we've loaded
;	already...

	call	TranslateLibraryErrorCode

	push	ds, ax
	segmov	es, ds
	LoadVarSeg	ds, bx
	call	FrGL_FreeLibraryUsages	
	pop	ds, ax
	stc
	jmp	exit
	
ProcessXIPLibraryTable	endp
;
; A fake ImportedLibraryEntry structure, with a protocol number of 0,0
;
fakeILE ImportedLibraryEntry	<"FAKE    ",,<0,0>>



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UseXIPLibrary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adds a reference to a library in the XIP image, loading it
		first if necessary.

CALLED BY:	GLOBAL
PASS:		ax - coreblock handle of library
		cx - client handle
		es:di - ptr to ImportedLibraryEntry structure
RETURN:		carry set if error (ax = GeodeLoadError)
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	4/11/94   	Initial version
	lester	12/20/95	modified to check for the desired GeodeAttrs

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UseXIPLibrary	proc	near
	.enter
	push	si, di
	mov	dx, es:[di].ILE_attrs	; DX <- GeodeAttrs to match
	clr	bx			; traverse entire geodes list
	mov	di, vseg FindGeodeByHandle
	mov	si, offset FindGeodeByHandle
	call	GeodeForEach
	pop	si, di
	jc	alreadyLoaded

;	The geode is not loaded already, so load it ourselves

	push	cx		;Save client handle
	mov_tr	bx, ax		;BX <- coreblock handle of geode to load
	mov	ax, PRIORITY_STANDARD
	mov	cx, dx		; CX <- GeodeAttrs to match
	clr	dx		; DX <- GeodeAttrs to NOT match
				;(BP and DI are undefined in this case)
	call	LoadXIPGeodeWithHandle
	pop	cx		;Restore geode handle of client
	jc	exit
alreadyLoaded:
	clr	dx		;DX=0 means no file open for this library
	call	UseLibraryLow
exit:
	.leave
	ret
UseXIPLibrary	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindGeodeByHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if a geode is loaded and has the desired 
		attributes.

CALLED BY:	INTERNAL
		UseXIPLibrary via GeodeForEach

PASS:		ax - handle of geode we are trying to find
		dx - GeodeAttrs to match
		bx - handle of geode being processed
		es - segment of geode's core block

RETURN:		carry set if the handles match and desired attrs are present
DESTROYED:	si

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	4/ 7/94   	Initial version
	lester	12/20/95	modified to check for the desired GeodeAttrs

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindGeodeByHandle	proc	far
	.enter

;	Check if this is the right geode.

	cmp	ax, bx
	clc
	jne	noMatch

;	Check if the geode has the desired attributes.

	mov	si, es:[GH_geodeAttr]
	not	si
	test	si, dx		; any desired attrs missing? (clears carry)
	jnz	noMatch		; at least one was 0 before...

	stc			; signal match (stop processing)
noMatch:
	.leave
	ret
FindGeodeByHandle	endp

endif


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ProcessLibraryTable

DESCRIPTION:	Process a library table for GeodeLoad

CALLED BY:	LoadGeodeAfterFileOpen

PASS:
	file pointing at library table
	ss:bp-GEODEH_SIZE - GeodeHeaderStruct variables for new GEODE
	ds - core block for new GEODE (locked)
	es - kernel variables

RETURN:
	carry - set if error
	if error:
		ax - error code (GeodeLoadError):
			GLE_FILE_READ_ERROR
			GLE_LIBRARY_NOT_FOUND
			GLE_LIBRARY_PROTOCOL_ERROR
			GLE_LIBRARY_LOAD_ERROR

DESTROYED:
	ax, bx, cx, dx, si, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	allocate stack space for library names
	read in library name table
	for (i = 0; i < GH_libCount; i++) begin
		UseLibrary( libraryName[i] )
	end
	free stack space

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/88		Initial version
-------------------------------------------------------------------------------@

ProcessLibraryTable	proc	near

	push	bp

	; Calculate offset for imported library table.

	mov	ax,size GeodeHeader		; Assume not a process
	test	ds:[GH_geodeAttr],mask GA_PROCESS	; CLEARS CARRY TOO
	jz	notProcess
	mov	ax,size ProcessHeader
notProcess:
	mov	ds:[GH_libOffset],ax	; Record offset in GeodeHeader.

	; Is the table empty?

	mov	cx,ds:[GH_libCount]		; cx = entries in table.
	jcxz	PLT_ret

	; Calculate the table size.

	mov	si,cx				;si = counter for later
	mov	ax,size ImportedLibraryEntry	;compute table size
	mul	cx
	mov	cx,ax				;cx = table size
	push	es

	; Read in library name table.

	mov	bx,ds:[GH_geoHandle]		;file handle
	mov	dx,ds:[GH_extraLibOffset]
	mov	di, dx				; save for loop...
	clr	al
	call	FileReadFar
	jnc	processTable
	mov	ax,GLE_FILE_READ_ERROR

done:
	pop	es
	jc	PLT_ret

	call	BuildFullLibraryTable
PLT_ret:
	pop	bp

	ret

processTable:
	;
	; Table successfully read in, so now we get to process it:
	; 	- foreach ImportedLibraryEntry:
	; 		- search for library using permanent name
	;		- if not found, try and open it as a file
	;		- call UseLibraryLow to load the thing or
	;		  up its reference count, as appropriate
	;
	clr	bp				; not pushed to SP_SYSTEM yet

	mov	bx,ds:[GH_libOffset]
	segmov	es,ds				;for UseLibraryLow...
PLT_loop:
	push	bx		; Remember Imported Lib Handle Table offset.
	mov	ax, size ILE_name
	mov	cx, ds:[di].ILE_attrs
	clr	dx
	call	GeodeFind
	jc	useLibrary

if	FULL_EXECUTE_IN_PLACE and LOAD_GEODES_FROM_XIP_IMAGE_FIRST

	call	LoadXIPLibrary
	jnc	useLibrary

endif

	;
	; Push to SP_SYSTEM if we've not done that yet, as that's where all
	; libraries reside....
	; 
	tst	bp
	jnz	tryOpenFile
	
	call	FilePushDir
	mov	ax, SP_SYSTEM
	call	FileSetStandardPath
	
	dec	bp				; flag having pushed to system

tryOpenFile:

	clr	bx
EC <	call	TryOpenEC						>
EC <	jnc	useLibrary						>

	call	TryOpenLib

if 	FULL_EXECUTE_IN_PLACE and not LOAD_GEODES_FROM_XIP_IMAGE_FIRST
	jnc	useLibrary

;	Look for the library in the XIP image

	call	LoadXIPLibrary
	jc	error
else
	mov	ax, GLE_FILE_NOT_FOUND
	jc	error
   
endif

useLibrary:

	mov	cx,ds:GH_geodeHandle		; cx <- client geode
	call	UseLibraryLow			;use library at es:di
	jc	error

	mov	ax, bx				;ax = handle of library

	; Save the handle into the core block's Imported Library
	; Handle Table.

	pop	bx		; Offset for this handle into the table.			
	mov	ds:[bx],ax			; Copy handle to table.
	add	di,size ImportedLibraryEntry
	add	bx,2		; Increment Handle table offset. 
	dec	si
	jnz	PLT_loop
	clc

popDirDone:
	pushf
	tst	bp
	jz	dirPopped
	call	FilePopDir
dirPopped:
	popf
	jmp	done

	; error - return correct code and undo previously used libraries

error:
	call	TranslateLibraryErrorCode

	pop	bx			; recover offset at which library
					;  handle would have been stored
	push	ax			; save error code

	sub	ds:[GH_libCount], si	; Reduce library count by number not
					;  yet loaded
	jz	errorDone		; => none loaded, so bail

	push	ds
	segmov	es, ds
	LoadVarSeg	ds		; ds <- idata
	call	FrGL_FreeLibraryUsages	; Use standard routine to (a) save bytes
					;  and (b) make sure LibraryEntry gets
					;  called with LCT_CLIENT_EXIT
	pop	ds

errorDone:
	pop	ax
	stc
	jmp	popDirDone

ProcessLibraryTable	endp


if	FULL_EXECUTE_IN_PLACE

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoadXIPLibrary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Looks for a library in the XIP image, given an 
		ImportedLibraryEntry structure

CALLED BY:	GLOBAL
PASS:		es:di = ImportedLibraryEntry for the library/driver whose
			file is to be opened
RETURN:		carry set if could not be loaded (ax = GeodeLoadError)
		else bx - handle of library
		     dx - 0
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	4/ 8/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoadXIPLibrary	proc	near	uses	cx, di, si, ds, es
	.enter
	mov	cx, es:[di].ILE_attrs
if	ERROR_CHECK

	push	es, di
	push	cx			;CX <- attrs to match for geode
	call	CreateECName
	pop	cx

	call	LoadXIPLibraryCommon
	pop	es, di
	jnc	exit

endif
	push	cx
	call	CreateNonECName
	pop	cx
	call	LoadXIPLibraryCommon
EC <exit:								>
   	mov	dx, 0
	.leave
	ret
LoadXIPLibrary	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoadXIPLibraryCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Looks for a library in the XIP image

CALLED BY:	GLOBAL
PASS:		cx - geode attrs to match
		es:di - ptr after end of filename (in useLibraryBuffer)
RETURN:		carry set if error (ax = GeodeLoadError)
		else bx = geode handle
DESTROYED:	dx, di, si, ds
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	4/ 8/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoadXIPLibraryCommon	proc	far
	.enter

	;
	; Append the requisite suffix.
	; 
if	DBCS_PCGEOS
	LocalLoadChar	ax, C_PERIOD
	LocalPutChar	esdi, ax
	LocalLoadChar	ax, C_LATIN_SMALL_LETTER_G
	LocalPutChar	esdi, ax
	LocalLoadChar	ax, C_LATIN_SMALL_LETTER_E
	LocalPutChar	esdi, ax
	LocalLoadChar	ax, C_LATIN_SMALL_LETTER_O
	LocalPutChar	esdi, ax
	LocalClrChar	ax
	LocalPutChar	esdi, ax
else
	mov	ax, '.' or ('g' shl 8)
	stosw
	mov	ax, 'e' or ('o' shl 8)
	stosw
	clr	al
	stosb
endif	; DBCS_PCGEOS

	clr	dx
	mov	ax, PRIORITY_STANDARD
	segmov	ds, es				;DS:SI <- ptr to filename
	mov	si, offset useLibraryBuffer
	call	LoadXIPGeode
	.leave
	ret
LoadXIPLibraryCommon	endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TranslateLibraryErrorCode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Maps the GeodeLoadError returned when loading a library to
		an appropriate value to be returned to the caller
		(i.e. GLE_FILE_NOT_FOUND -> GLE_LIBRARY_NOT_FOUND)

CALLED BY:	GLOBAL
PASS:		ax - error code to map
RETURN:		ax - mapped error code
DESTROYED:	bx
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	4/ 7/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TranslateLibraryErrorCode	proc	near
	.enter
	mov	bx,ax

	;
	; let translated errors go through
	;
	cmp	bx, GLE_LIBRARY_PROTOCOL_ERROR
	je	foundErrorCode
	cmp	bx, GLE_LIBRARY_NOT_FOUND
	je	foundErrorCode
	cmp	bx, GLE_LIBRARY_LOAD_ERROR
	je	foundErrorCode

	mov	ax,GLE_LIBRARY_PROTOCOL_ERROR
	cmp	bx,GLE_PROTOCOL_IMPORTER_TOO_RECENT
	jz	foundErrorCode
	cmp	bx,GLE_PROTOCOL_IMPORTER_TOO_OLD
	jz	foundErrorCode

	mov	ax,GLE_LIBRARY_NOT_FOUND
	cmp	bx,GLE_FILE_NOT_FOUND
	jz	foundErrorCode

	mov	ax,GLE_LIBRARY_LOAD_ERROR
foundErrorCode:
	.leave
	ret
TranslateLibraryErrorCode	endp


if ERROR_CHECK


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TryOpenEC
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Try and open the EC version of the library, forming the
		name of the beast in useLibraryBuffer, with ec.geo tacked
		onto the end.

CALLED BY:	ProcessLibraryTable
PASS:		es:di	= ImportedLibraryEntry for the library/driver whose
			  file is to be opened.
RETURN:		carry set on error
		carry clear if successful:
			dx	= file handle
DESTROYED:	ax, cx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TryOpenEC	proc	near
		uses	ds, si, es, di
		.enter
		call	CreateECName
		call	TryOpenCommon
		.leave
		ret
TryOpenEC	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateECName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given an ImportedLibraryEntry structure, creates a filename
		in useLibraryBuffer and returns a ptr to it.

CALLED BY:	GLOBAL
PASS:		es:di - ImportedLibraryEntry structure
RETURN:		es:di - ptr after string copied into useLibraryBuffer
DESTROYED:	ds, si, cx, al
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	4/ 8/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateECName	proc	near
		.enter
	;
	; Quick check to determine if we're any different from TryOpenLib:
	; If the last character of the permanent name isn't a space, we've
	; no room to insert the differentiating "ec" before the ".", so
	; there's no point in doing anything here.
	; 
	; since we are limited to 8.3 on the PC SDK, if we have an 8 letter
	; permenent name then try changing the last letter to an 'e' and see
	; if that geode exists, by just removing the code it looks like this
	; is what happens
;		cmp	es:[di].ILE_name[GEODE_NAME_SIZE-1], ' '
;		je	addEC
;		stc
;		jne	done

		segmov	ds, es
		lea	si, ds:[di].ILE_name
		LoadVarSeg	es
		mov	di, offset useLibraryBuffer
		mov	cx, size ILE_name
DBCS <		clr	ah						>
copyLoop:
		lodsb
		LocalPutChar	esdi, ax
		cmp	al, ' '
		loopne	copyLoop
		LocalPrevChar	esdi	; es:di <- space char or final char
					;  in name
		mov	al, 'e'
		LocalPutChar	esdi, ax
		jcxz 	done
		mov	al, 'c'
		LocalPutChar	esdi, ax
done:
		.leave
		ret
CreateECName	endp


endif	; ERROR_CHECK



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TryOpenLib
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Try and open the .geo version of the library, forming the
		name of the beast in useLibraryBuffer, with .geo tacked
		onto the end.

CALLED BY:	ProcessLibraryTable
PASS:		es:di	= ImportedLibraryEntry for the library/driver whose
			  file is to be opened.
RETURN:		carry set on error
		carry clear if successful:
			dx	= file handle
DESTROYED:	ax, cx

PSEUDO CODE/STRATEGY:
		Just copy the permanent name into useLibraryBuffer, truncating
		it at the first space, then call TryOpenCommon to append the
		suffix and attempt the open.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TryOpenLib	proc	near
		uses	ds, si, es, di
		.enter
		call	CreateNonECName

		call	TryOpenCommon
		.leave
		ret
TryOpenLib	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateNonECName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given an ImportedLibraryEntry structure, creates a filename
		in useLibraryBuffer and returns a ptr to it.

CALLED BY:	GLOBAL
PASS:		es:di - ImportedLibraryEntry structure
RETURN:		es:di - ptr after string copied into useLibraryBuffer
DESTROYED:	ds, si, cx, al
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	4/ 8/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateNonECName	proc	near
		.enter
		segmov	ds, es
		lea	si, ds:[di].ILE_name
		LoadVarSeg	es
		mov	di, offset useLibraryBuffer
		mov	cx, size ILE_name
DBCS <		clr	ah						>
copyLoop:
		lodsb
		LocalPutChar	esdi, ax
		cmp	al, ' '
		loopne	copyLoop
		jnz	noBackup
		LocalPrevChar	esdi
noBackup:
		.leave
		ret
CreateNonECName	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TryOpenCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code to open a library's .geo file once the permanent
		name has been properly copied and truncated.

CALLED BY:	TryOpenEC, TryOpenLib
PASS:		es:di	= char after last useful char in the permanent name;
			  points into useLibraryBuffer
RETURN:		carry set on error
		carry clear if file opened:
			dx	= file handle
DESTROYED:	ax, cx, ds, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TryOpenCommon	proc	near
		.enter
	;
	; Append the requisite suffix.
	; 
if DBCS_PCGEOS
		clr	ah
		mov	al, '.'
		LocalPutChar	esdi, ax
		mov	al, 'g'
		LocalPutChar	esdi, ax
		mov	al, 'e'
		LocalPutChar	esdi, ax
		mov	al, 'o'
		LocalPutChar	esdi, ax
		clr	al
		LocalPutChar	esdi, ax
else
		mov	ax, '.' or ('g' shl 8)
		stosw
		mov	ax, 'e' or ('o' shl 8)
		stosw
		clr	al
		stosb
endif
	;
	; Point ds:dx to the start of the name and try and open the beast.
	; 
		segmov	ds, es
		mov	dx, offset useLibraryBuffer

TOC_openFile label near	;*** REQUIRED BY SHOWCALL -L COMMAND IN SWAT ***
ForceRef	TOC_openFile
		mov	al, FileAccessFlags <FE_DENY_WRITE, FA_READ_ONLY>
		call	FileOpen
		mov	dx, ax
		.leave
		ret
TryOpenCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BuildFullLibraryTable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Build up a table of the core blocks of all libraries used
		by the given geode, either explicitly (it imports them
		itself) or implicitly (they are imported by libraries
		imported by it), for use in startup/exit notifications

CALLED BY:	ProcessLibraryTable
PASS:		ds	= segment of core block
RETURN:		ds:[GH_extraLibCount] = set
		ds:[GH_extraLibOffset] = set if GH_extraLibCount non-zero
DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BuildFullLibraryTable proc	near
		uses	si, di, es, cx, dx, bp
		.enter
		clr	bx		; no extra library to mess with
		call	FindExtraLibraries
	;
	; 4/1/92: need to perform this ReAlloc always, even if the number of
	; extra libraries is 0, to eliminate the extra space allocated for
	; the table of ImportedLibraryEntry structures -- ardeb
	; 
		mov	ds:[GH_extraLibCount], cx
		mov	ax, ds:[GH_extraLibOffset]
		shl	cx		; # extra libs * 2
		add	ax, cx
		mov	bx, ds:[GH_geodeHandle]
		clr	cx		; no special flags for realloc
		call	MemReAlloc
		mov	es, ax		; es <- new core block segment
		mov	si, di		; si <- start of table to copy
		mov	di, es:[GH_extraLibOffset]
		segmov	ds, ss		; ds:si <- table
		mov	cx, es:[GH_extraLibCount]
		rep	movsw
		mov	ds, ax		; ds <- new core block segment

		lea	sp, ss:[bp+4]	; clear all handles and saved core
					;  block segment (since it could have
					;  moved during the realloc), and
					;  return address back to us.
done::
		.leave
		ret
BuildFullLibraryTable endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindExtraLibraries
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find any libraries that aren't already in the normal or
		extra library table for the passed geode.

CALLED BY:	(INTERNAL) BuildFullLibraryTable, NotifyNewLibraries
PASS:		ds	= core block of client geode
		bx	= handle of library that may not be in the table
			  already (0 if none)
RETURN:		cx	= number of libraries unknown already
		bp	= pointer to saved core block segment above
			  end of table of all known libraries. This is just
			  below the return address back to the caller, so
			  lea sp, ss:[bp+4] will clear the stack to what
			  it was before the call.
		ss:sp	= points to first library not already known
DESTROYED:	es, di, si, ds, bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/17/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindExtraLibraries proc	near
	;
	; Copy initial library handles onto the stack. These are the ones
	; we know the geode is using and we won't copy them to the extra-
	; library table we'll be sticking at the end of the core block.
	; 
		push	ds		; save core block of geode
					;  for which we're building this table
		mov	bp, sp
		mov	cx, ds:[GH_libCount]
		jcxz	copyExtraLibs

		shl	cx
		sub	sp, cx
		mov	di, sp
		segmov	es, ss
		mov	si, ds:[GH_libOffset]
		shr	cx
		rep	movsw
copyExtraLibs:
		mov	cx, ds:[GH_extraLibCount]
		jcxz	checkPassedHandle

		shl	cx
		sub	sp, cx
		mov	di, sp
		segmov	es, ss
		mov	si, ds:[GH_extraLibOffset]
		shr	cx
		rep	movsw

checkPassedHandle:
	;
	; Now for each library on the stack, we lock down its core block and
	; go through its table of imported libraries, comparing each handle
	; against the ones we've already got. If it's not there, we push it.
	;
	; The loop ends when our source pointer reaches the bottom of the table.
	; 
		lea	si, ss:[bp-2]
		tst	bx
		jz	startLoop
	;
	; Passed a handle to use in the search. Apply an extra lock to the
	; locked core block, so we can just MemUnlock bx without worry, and
	; pretend we got the handle from the core block, and it's the last
	; library there.
	; 
		cmp	sp, bp		; any libraries on stack?
		je	passedHandleNotSeenYet	; no 

		mov	di, sp		; di <- table bottom
		push	si		; save offset of next lib to examine
					;  in table on stack
		push	bx
		mov	bx, ds:[GH_geodeHandle]
		call	MemLock
		pop	ax		; ax <- library to check
		mov	cx, 1		; => this is last library in this block
		jmp	checkLibrary

passedHandleNotSeenYet:
	;
	; Current core block has no libraries in it, so it can't have seen
	; the passed one yet, so push it on the stack; we'll start looking
	; from there.
	; 
		push	bx
startLoop:
	;
	; Make sure there are libraries to check.
	; 
		cmp	sp, bp
		je	done		
libraryLoop:
	;
	; Fetch the next library from the table we're building and shift our
	; focus to the word below it for the next time through.
	;
		std
		lodsw	ss:
		cld
		mov	di, sp		; di <- base of table
		tst	ax		; cope with library being freed while
					;  another geode is being freed. If
		jz	nextLibrary	;  handle on stack is 0, ignore the
					;  entry.
	;
	; Now lock down the library's core block and process all of its
	; imported libraries.
	; 
		mov_tr	bx, ax
		call	MemLock
		mov	ds, ax
		push	si		; save table position for next time

		mov	cx, ds:[GH_libCount]
		jcxz	libraryDone
		mov	si, ds:[GH_libOffset]
impLibLoop:
		lodsw			; ax <- next lib to check
checkLibrary:
		mov	dx, cx		; save count of libraries left to
					;  process for this library
		mov	cx, bp
		sub	cx, di
		shr	cx		; cx <- # libraries already known
		push	di
		or	di, di		; in case cx == 0, make sure je won't
					;  be taken (if di is 0, we're in
					;  trouble...)
		repne	scasw
		pop	di
		mov	cx, dx		; cx <- # libs left
		je	impLibNext	; => already there

		pop	dx		; recover position in full table
		push	ax		; push this library
		mov	di, sp		; di <- new start of table
		push	dx		; push position in full table again
impLibNext:
		loop	impLibLoop
libraryDone:
		call	MemUnlock	; release this library's core block
EC <		call	NullDS						>
		pop	si
nextLibrary:
		cmp	si, di		; passed the start of the table
					;  (finally)?
		jae	libraryLoop	; nope -- keep looping
		
done:
		mov	ds, ss:[bp]	; recover original geode's core block
		mov	cx, bp
		sub	cx, di
		shr	cx
		sub	cx, ds:[GH_libCount] 	    ; cx <- # of libraries
		sub	cx, ds:[GH_extraLibCount]   ; imported by the geode's
						    ; imported libraries

		jmp	{word}ss:[bp+2]	; return to caller without mangling
					;  what we've built on the stack.
FindExtraLibraries endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	GeodeUseLibrary

DESCRIPTION:	Use the given library.  If it is not loaded, find it on disk
		and load it.  If it is loaded, increment its reference count.

		WARNING: The standard method for using libraries is or the
			 GEODE to include the .def file so that the library is
			 automatically loaded.  Use GeodeUseLibrary only if
			 necessary.

CALLED BY:	GLOBAL

PASS:
	ax - protocol number expected, major (0 => any ok)
	bx - protocol number expected, minor
	ds:si - library file name
		(file name *can* be in movable XIP code resource)

RETURN:
	carry - set if error (library not found)
	if error:
		ax - error code (GeodeLoadError):
	if no error:
		bx - handle of library

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/88		Initial version
-------------------------------------------------------------------------------@

FXIP <CopyStackCodeXIP	segment						>

GeodeUseLibrary	proc	far
	push	dx
	clr	dx				; indicate ds:si is file name
	FALL_THRU	GeodeUseLibraryCommon, dx
GeodeUseLibrary	endp

GeodeUseLibraryCommon	proc	far
	push	cx
	mov	cx, mask GA_LIBRARY
	call	UseLibraryDriverCommon
	pop	cx
	FALL_THRU_POP	dx
	ret
GeodeUseLibraryCommon	endp

FXIP <CopyStackCodeXIP	ends						>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeodeUseLibraryPermName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Use the library identified by the given permanent name.  If
		it is loaded, increment its reference count and send
		out new client notification, etc.  If it is not loaded,
		return an error so the user can then use GeodeUseLibrary.

CALLED BY:	GLOBAL

PASS:
	ax - protocol number expected, major (0 => any ok)
	bx - protocol number expected, minor

	ds:si - library permanent geode name (GEODE_NAME_SIZE)
		(*can* be in movable XIP code resource)

RETURN:
	carry - set if error (library not loaded)
	if error:
		ax - error code (GeodeLoadError):
	if no error:
		bx - handle of library

DESTROYED:
	none

PSEUDO CODE/STRATEGY:
	Call UseLibraryDriverCommon, passing dx = nonzero

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dhunter	8/10/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FXIP <CopyStackCodeXIP	segment						>

GeodeUseLibraryPermName	proc	far
	push	dx
	mov	dx, TRUE		; indicate ds:si is permanent name
	GOTO	GeodeUseLibraryCommon, dx
GeodeUseLibraryPermName	endp

FXIP <CopyStackCodeXIP	ends						>

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UseLibraryDriverCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code for GeodeUseLibrary and GeodeUseDriver

CALLED BY:	GeodeUseLibraryCommon, GeodeUseDriverCommon
PASS:		if dx is zero,
			ds:si	= file name of library/driver
		else,
			ds:si	= permanent name of library/driver
		ax	= expected major protocol number (0 => any ok)
		bx	= expected minor protocol number
		cx	= geode attributes for UseLibraryLow to match
			  (GA_LIBRARY or GA_DRIVER)
RETURN:		if carry set:
			ax = GeodeLoadError describing problem
		else
			bx = handle of library/driver
DESTROYED:	ax, cx, dx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/ 3/90		Initial version
	ardeb	2/19/92		changed to use file name

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	FULL_EXECUTE_IN_PLACE

CopyStackCodeXIP	segment

UseLibraryDriverCommon	proc	near
	mov	ss:[TPD_dataBX], handle UseLibraryDriverCommonReal
	mov	ss:[TPD_dataAX], offset UseLibraryDriverCommonReal
	call	SysCallMovableXIPWithDSSI
	ret
UseLibraryDriverCommon	endp

CopyStackCodeXIP	ends

else
UseLibraryDriverCommon	proc	near
	FALL_THRU	UseLibraryDriverCommonReal
UseLibraryDriverCommon	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UseLibraryDriverCommonReal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	UseLibraryDriverCommon after any pointers to XIP-movable
		memory have been dealt with. Now have to deal with any
		pointers on the stack while we borrow enough stack space to
		load the thing.

CALLED BY:	(INTERNAL) UseLibraryDriverCommon
PASS:		ds:si	= library/driver to load
		cx	= GeodeAttrs to match
		ax.bx	= protocol number to match
		dx	= zero if ds:si is file name, else permanent name
RETURN:		carry set on error:
			ax	= GeodeLoadError
		carry clear if ok:
			bx	= geode handle
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	geode may be loaded (thus added to the end of the geode
     			list)

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 9/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UseLibraryDriverCommonReal	proc	xipfar
	push	di, ds, si
	
	xchg	dx, si			; ds:dx <- pointer for checking
					;  if on stack
	mov	di, 900			; di <- # bytes we think we need
	call	ThreadBorrowStackDSDX	; di <- token
	xchg	si, dx
	call	UseLibraryDriverCommonAfterStackBorrow
	call	ThreadReturnStackSpace
	pop	di, ds, si
	ret
UseLibraryDriverCommonReal	endp

UseLibraryDriverCommonAfterStackBorrow proc near
libEntry	local	ImportedLibraryEntry
	uses	es, di, ds
	.enter
	mov	ss:[libEntry].ILE_attrs, cx
	mov	ss:[libEntry].ILE_protocol.PN_major, ax
	mov	ss:[libEntry].ILE_protocol.PN_minor, bx

	call	FarPGeode

if	FULL_EXECUTE_IN_PLACE

	; It isn't valid to pass far pointers in other XIP resources, so
	; complain if they are passed in.

EC <	mov	cx, ds							>
EC <	mov	dx, cs							>
EC <	cmp	cx, dx							>
EC <	je	thisResource						>
EC <	push	bx							>
EC <	mov	bx, ds							>
EC <	call	ECAssertValidFarPointerXIP				>
EC <	pop	bx							>
EC <thisResource:							>
endif
	;
	; Need to figure the geode doing the loading. We assume the name lies
	; in a segment owned by the loading geode, so find its handle and from
	; that obtain the geode handle.
	;
	clr	ax			; Assume failure
	mov	cx, ds
	call	MemSegmentToHandle	; Locate handle with segment
	jnc	clientUnknown

					; Find owner of the segment's handle.
	LoadVarSeg es			;  This gives us the client's
	mov	bx, cx			;  geode handle, as required
	mov	ax, es:[bx].HM_owner	;  by UseLibraryLow
		
	
clientUnknown:
	push	ax			;Save client handle

	;
	; If dx is non-zero, then ds:si contains the permanent name of the
	; geode.  Copy the string into libEntry.ILE_name and skip ahead
	; to see if it's already loaded.
	;

	tst	dx			;have permanent name?
	jz	loadFromFile		;nope, got file name instead

	segmov	es, ss
	lea	di, ss:[libEntry].ILE_name	; es:di <- ptr to ILE_name
	CheckHack <(size ILE_name and 1) eq 0>
	mov	cx, (size ILE_name) / 2	;cx = # words in name
	rep	movsw			;copy the full permanent name

	clr	bx			; bx <- no file handle 
	lea	di, ss:[libEntry]	; es:di <- ptr to ImportedLibraryEntry
	jmp	checkLoaded

	;
	; Now need to fetch the permanent name from the file and see if the
	; thing is already loaded.
	;
loadFromFile:
if FULL_EXECUTE_IN_PLACE and LOAD_GEODES_FROM_XIP_IMAGE_FIRST

	call	MapFileNameToCoreblockHandle
	jnc	loadXIP		;Branch if geode is in the XIP image

endif

	mov	dx, si
	mov	al, FileAccessFlags <FE_DENY_WRITE, FA_READ_ONLY>
	call	FileOpen
	jc	openError
	mov_tr	bx, ax			; 

if	FULL_EXECUTE_IN_PLACE and not LOAD_GEODES_FROM_XIP_IMAGE_FIRST

;	On XIP systems, we want to make sure we aren't trying to open one
;	of those little stubs that the elyom tool produces.

	call	FileSize	;DX:AX <- file size
	tst_clc	dx
	jnz	noCheckSize	;If we have a >64K file, branch

;	If the file is too small, close the file and act as if the file
;	couldn't be opened...

	cmp	ax, size GeosFileHeader+1	;Sets carry if file only
						; contains GeosFileHeader
	jnc	noCheckSize
	mov	al, FILE_NO_ERRORS
	call	FileCloseFar
	jmp	openError
noCheckSize:
endif

	clr	cx			;seek to the permanent name in
					; the header
	mov	dx, offset GFH_coreBlock.GH_geodeName
	mov	al, FILE_POS_START
	call	FilePosFar

	lea	dx, ss:[libEntry].ILE_name	; read the permanent name into
	segmov	ds, ss			;  our buffer on the stack
	mov	cx, size ILE_name
	clr	al
	call	FileReadFar
	jc	readError

		CheckHack <offset ILE_name eq 0>
	mov	di, dx			;ES:DI <- ptr to ImportedLibraryEntry
	segmov	es, ss

	;
	; Now we've got the permanent name, see if the thing's already loaded.
	;
checkLoaded:
	push	bx			; save file handle
	mov	cx, ss:[libEntry].ILE_attrs
	clr	dx
	mov	ax, size ILE_name
	call	GeodeFind
	pop	dx			; dx <- file handle
	jc	callCommonCode
	clr	bx			; signal not resident
	tst	dx			; need file handle to open library
	jz	needFileError		; branch if no file
callCommonCode:
	pop	cx			; cx <- client geode
	call	UseLibraryLow
FXIP <afterUseLibraryLow:						>
	jc	done
	mov	di, LCT_NEW_CLIENT_THREAD
	call	NotifyNewLibraries
done:
	call	FarVGeode
	.leave
	ret

openError:
if	FULL_EXECUTE_IN_PLACE and not LOAD_GEODES_FROM_XIP_IMAGE_FIRST

;	Try to lookup the filename to see if the geode is in the XIP image

	call	MapFileNameToCoreblockHandle
	jnc	loadXIP		;Branch if geode is in the XIP image
else
	mov	ax, GLE_FILE_NOT_FOUND
endif

errorCommon:
	pop	cx
	jmp	done

readError:
	clr	al
	call	FileCloseFar
	mov	ax, GLE_FILE_READ_ERROR
	stc
	jmp	errorCommon

needFileError:
	mov	ax, GLE_LIBRARY_NOT_FOUND
	stc
	jmp	errorCommon

if	FULL_EXECUTE_IN_PLACE
loadXIP:

;	Now, check if the geode is loaded - if so, just call UseLibraryLow
;	on it - otherwise, we have to load it first.

	mov_tr	ax, bx			;AX <- handle of geode to load
	pop	cx			;CX <- client handle

	segmov	es, ss
	lea	di, libEntry
	call	UseXIPLibrary
	jmp	afterUseLibraryLow
endif

UseLibraryDriverCommonAfterStackBorrow	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	UseLibraryLow

DESCRIPTION:	Use the given library.  If it is not loaded, find it on disk
		and load it.  If it is loaded, increment its reference count.

CALLED BY:	ProcessLibraryTable, ProcessXIPLibraryTable, 
       		UseLibraryDriverCommon

PASS:
	es:di	= ImportedLibraryEntry, containing protocol
	bx	= handle of already-loaded library, if found (0 if not
		  loaded yet
	cx	= handle of client geode
	dx	= handle of file open to library to be loaded (0 if not
		  open)

RETURN:
	carry - set if error (library not found)
	if error:
		ax - error code (GeodeLoadError)
	if no error:
		bx - handle of library

DESTROYED:
	?

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	if (library is not in memory) begin
		load library from disk
	end
	library->GH_geodeRefCount++
	return(segment address of library)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/88		Initial version
-------------------------------------------------------------------------------@

UseLibraryLow	proc	near	uses cx, si, di, ds
	.enter

	push	cx		; save client handle

	;
	; If caller knows the library's not in memory, go load it.
	; 
	tst	bx
	jz	loadIt
	
	;
	; If caller opened the file before it found the library was already
	; loaded, close the file again before we go deal with the library
	; being in memory.
	; 
	tst	dx
	jz	inMemory

	xchg	bx, dx
	clr	al		; allow errors on close, even though we
	call	FileCloseFar	;  ignore them
	mov	bx, dx
	jmp	inMemory

loadIt:
EC <	tst	dx							>
EC <	ERROR_Z	CANNOT_LOAD_LIBRARY_WITHOUT_AN_OPEN_FILE		>

	mov	cx, es:[di].ILE_attrs	; cx <- attrs to match
	mov	bx, dx			; bx <- open file handle
	clr	dx			; any attributes are just fine.
	mov	ax, PRIORITY_STANDARD	; in case also a process, ah MBZ
	push	bp
	clr	bp			; pass BP as 0 to allow app-libraries
					;  to distinguish between when
					;  they're loaded as an app and when
					;  as just a library -- ardeb 10/6/94
	call	LoadGeodeAfterFileOpen
	pop	bp
	jc	error

inMemory:
	;
	; Geode is now resident. Lock down its core block and add a reference
	; to it.
	; 
	call	MemLock
	mov	ds, ax
AXIP <	cmp	bx, handle 0		; check against kernel's core block >
AXIP <	je	checkProtocol		; if XIP, can't alter core block    >
	inc	ds:[GH_geodeRefCount]

checkProtocol::
	;
	; Make sure the expected protocol number matches the actual.
	;
	mov	ax, es:[di].ILE_protocol.PN_major
	mov	bx, es:[di].ILE_protocol.PN_minor
	tst	ax
	jz	anyProtocol

	mov	cx,ds:[GH_geodeProtocol].PN_major
	mov	dx,ds:[GH_geodeProtocol].PN_minor
	call	TestProtocolNumbers		;ax = error (if any)
	jc	ULL_protoError
anyProtocol:

	; tell library it's got another client, if it is indeed a library

	pop	cx			;recover client handle
	test	ds:[GH_geodeAttr], mask GA_LIBRARY
	jz	notLibrary

	mov	di, LCT_NEW_CLIENT		;call type
	call	CallLibraryEntry

notLibrary:
	mov	bx, ds:[GH_geodeHandle]
	call	MemUnlock

ULL_done label near
	.leave
	ret

	; protocol error -- remove the geode

ULL_protoError label near
;*** IMPORTANT: on stack: cx = handle of client geode. showcall command
;*** in swat depends upon this.

	mov	bx, ds:[GH_geodeHandle]
	call	MemUnlock
EC <	call	NullDS							>

	push	ax
	LoadVarSeg	ds		;ds = idata
	call	FreeGeodeLow
	pop	ax
	stc
error:
	pop	cx			;recover client geode
	jmp	ULL_done

UseLibraryLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NotifyNewLibraries
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify the libraries this thread hasn't notified before (or
		won't notify before the end) of a new client thread (or exit)
		after having explicitly loaded or unloaded a library/driver.

CALLED BY:	(INTERNAL) UseLibraryDriverCommon, GeodeFreeLibrary
PASS:		di	= LibraryCallType
		bx	= handle of geode just loaded
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Build a table of all the libraries used by the one just
			loaded.
		For each one, see if it's known to the current geode.
		If not, call it.
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/17/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NotifyNewLibraries proc	far
		call	PushAllFar
	;
	; Lock down the just-loaded geode's core block for FindExtraLibraries
	; to use.
	; 
		call	MemLock
		mov	ds, ax
		push	di			; save call type
		test	ds:[GH_geodeAttr], mask GA_LIBRARY
		jz	findLibs
		push	bx			; make room for handle of just-
						;  loaded geode at the end of
						;  the table.
findLibs:
	;
	; Find all the libraries of the thing just loaded.
	; 
		call	FindExtraLibraries
		test	ds:[GH_geodeAttr], mask GA_LIBRARY
		call	MemUnlock
EC <		call	NullDS						>
		jz	processTable
	;
	; If just-loaded geode is a library, shift its handle to the end of
	; the table.
	;
	; ss:bp	-> ds passed to FindExtraLibraries
	; 	   ret addr
	; 	   handle of loaded geode
	;	   LibraryCallType
	; want
	;	   handle of loaded geode
	; ss:bp -> ds passed to FindExtraLibraries
	;	   ret addr
	;	   LibraryCallType
	;
		mov	ax, ss:[bp]		; ax <- ds
		xchg	ax, ss:[bp+2]		; store ds, get ret addr
		xchg	ax, ss:[bp+4]		; store ret addr, get handle
		mov	ss:[bp], ax		; store handle
		inc	bp			; point bp beyond handle
		inc	bp			;  ...
processTable:
	;
	; Now loop through the handles of all the libraries found, seeing if
	; they're known to the current geode.
	; 
		push	bx
		mov	bx, ss:[TPD_processHandle]
		call	MemLock
		mov	es, ax
		pop	bx
		mov	si, sp
libraryLoop:
		lodsw	ss:			; ax <- handle to check
		mov	cx, es:[GH_libCount]
		mov	di, es:[GH_libOffset]
		or	ax, ax			; ensure ne in case cx==0
		repne	scasw
		je	nextLibrary

		; not a normal library. see if it's an extra library
		mov	cx, es:[GH_extraLibCount]
		mov	di, es:[GH_extraLibOffset]
		repne	scasw
		je	nextLibrary

		; not a known library. lock down the core block and call it
		mov_tr	bx, ax
		call	MemLock
		mov	ds, ax
		mov	di, ss:[bp+4]	; di <- LCT
		call	CallLibraryEntry
		call	MemUnlock
EC <		call	NullDS						>
nextLibrary:
		cmp	si, bp
		jb	libraryLoop

		lea	sp, ss:[bp+6]	; remove library table, saved core
					;  block segment, return address
					;  from FindExtraLibraries, and saved
					;  LibraryCallType value. bp points
					;  to the saved core block segment
		mov	bx, ss:[TPD_processHandle]
		call	MemUnlock
		call	PopAllFar
		ret
NotifyNewLibraries endp
GLoad	ends
