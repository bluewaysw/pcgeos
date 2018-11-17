COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) New Deal 1998 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		tweakuiProgList.asm

AUTHOR:		Gene Anderson

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	4/21/98		Initial revision


DESCRIPTION:
	Code for startup list of TweakUI module

	$Id: tweakuiProgList.asm,v 1.2 98/05/02 22:09:28 gene Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TweakUICode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TweakUIStartupListBuildArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create the list array

CALLED BY:	PrefMgr

PASS:		*ds:si - TweakUIStartupListClass object
		ds:di - TweakUIStartupListClass object
RETURN:		none
DESTROYED:	bx, cx, dx, di, bp

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/20/98   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

startupKey	char "execOnStartup",0

TweakUIStartupListBuildArray	method	dynamic	TweakUIStartupListClass,
					MSG_PREF_DYNAMIC_LIST_BUILD_ARRAY
		.enter
		push	ds:OLMBH_header.LMBH_handle
		push	si
	;
	; Create an lmem block for our array
	;
		mov	ax, LMEM_TYPE_GENERAL		;ax <- LMemType
		clr	cx				;cx <- default header
		call	MemAllocLMem
		call	MemLock
		mov	ds, ax				;ds <- seg addr
		push	bx				;save array block
	;
	; Create a chunk array
	;
		clr	bx				;bx <- extra data
		clr	cx				;cx <- default header
		clr	si				;si <- alloc block
		call	NameArrayCreate
		mov	bx, si				;*ds:bx <- chunkarray
		push	si				;save array chunk
	;
	; Enumerate the execOnStartup string section
	;
		segmov	es, ds				;es <- obj block
		segmov	ds, cs, cx
		mov	si, offset uiCategory		;ds:si <- category
		mov	dx, offset startupKey		;cx:dx <- key
		mov	di, cs
		mov	ax, offset StartupListBuildCallback
		mov	bp, InitFileReadFlags <IFCC_INTACT, 0, 0, 0>
		call	InitFileEnumStringSection
	;
	; Save the array optr for later
	;
		pop	ax				;ax <- array chunk
		pop	bx				;bx <- array block
		mov	dx, bx
		call	MemUnlock
		pop	si
		pop	bx				;^lbx:si <- object
		call	MemDerefDS
		mov	di, ds:[si]
		add	di, ds:[di].TweakUIStartupList_offset
		movdw	ds:[di].TUISLI_array, dxax
	;
	; Initialize the list
	;
		call	InitializeList
	;
	; Mark the list not dirty
	;
		mov	di, ds:[si]
		add	di, ds:[di].TweakUIStartupList_offset
		mov	ds:[di].TUISLI_dirty, FALSE

		.leave
		ret
TweakUIStartupListBuildArray	endm

;
; Pass:
;	ds:si - string section
;	dx - section #
;	cx - length of section
;	*es:bx - chunkarray

; Return:
;	carry - set to stop enum
;	es - fixed up
;
StartupListBuildCallback	proc	far
		uses	bx, di
		.enter

		segxchg	es, ds
		mov	di, si				;es:di <- name
		mov	si, bx				;*ds:si <- chunkarray
		clr	bx				;bx <- NameArrayAddFlag
		call	NameArrayAdd
		segmov	es, ds				;return updated es
		clc					;carry <- keep going

		.leave
		ret
StartupListBuildCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitializeList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the startup list

CALLED BY:	UTILITY

PASS:		*ds:si - TweakUIStartupListClass object
RETURN:		none
DESTROYED:	ax, cx, dx, di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/22/98   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

InitializeList	proc	near
		class	TweakUIStartupListClass
		uses	bp

		.enter
	;
	; Initialize the list for how many items we found
	;
		push	ds, si
		mov	di, ds:[si]
		add	di, ds:[di].TweakUIStartupList_offset
		movdw	bxsi, ds:[di].TUISLI_array
		call	MemLock
		mov	ds, ax
		call	ChunkArrayGetCount		;cx <- # items
		call	MemUnlock
		pop	ds, si
		mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
		call	ObjCallInstanceNoLock

		.leave
		ret
InitializeList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TweakUIStartupListGetMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a particular moniker

CALLED BY:	PrefMgr

PASS:		*ds:si - TweakUIStartupListClass object
		ds:di - TweakUIStartupListClass object
		ss:bp - GetItemMonikerParams
RETURN:		bp - # of chars returned
DESTROYED:	bx, cx, dx, di, bp

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/22/98   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

TweakUIStartupListGetMoniker	method	dynamic	TweakUIStartupListClass,
					MSG_PREF_ITEM_GROUP_GET_ITEM_MONIKER
		.enter

	;
	; Get the specified element
	;
		movdw	bxsi, ds:[di].TUISLI_array
		call	MemLock
		mov	ds, ax
		mov	ax, ss:[bp].GIMP_identifier
		call	ChunkArrayElementToPtr
		jc	noItem				;branch if not found
	;
	; Copy it into the buffer
	;
		sub	cx, (size RefElementHeader)
		cmp	cx, ss:[bp].GIMP_bufferSize
		ja	noItem				;branch if too large
		lea	si, ds:[di][RefElementHeader]	;ds:si <- name
		les	di, ss:[bp].GIMP_buffer		;es:di <- dest
		mov	bp, cx				;bp <- # chars
		rep	movsb				;copy me
		LocalClrChar ax
		LocalPutChar esdi, ax			;NULL terminate
	;
	; Unlock the array
	;
		call	MemUnlock
done:
		.leave
		ret

noItem:
		clr	bp				;bp <- item ignored
		jmp	done
TweakUIStartupListGetMoniker	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TweakUIStartupListProgramSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A program has been selected

CALLED BY:	PrefMgr

PASS:		*ds:si - TweakUIStartupListClass object
		ds:di - TweakUIStartupListClass object
		bp - # of selections
RETURN:		none
DESTROYED:	bx, cx, dx, di, bp

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/22/98   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

TweakUIStartupListProgramSelected	method dynamic TweakUIStartupListClass,
					MSG_TUISL_STARTUP_PROGRAM_SELECTED
	;
	; Enable the Remove trigger if anything is selected
	;
		mov	ax, MSG_GEN_SET_ENABLED
		tst	bp				;any selection?
		jnz	gotMessage			;branch if so
		mov	ax, MSG_GEN_SET_NOT_ENABLED
gotMessage:
		mov	si, offset RemoveAppTrigger
		mov	dl, VUM_NOW
		GOTO	ObjCallInstanceNoLock
TweakUIStartupListProgramSelected	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TweakUIStartupListDeleteProgram
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete the selected program

CALLED BY:	PrefMgr

PASS:		*ds:si - TweakUIStartupListClass object
		ds:di - TweakUIStartupListClass object
RETURN:		none
DESTROYED:	bx, cx, dx, di, bp

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/22/98   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

TweakUIStartupListDeleteProgram	method dynamic TweakUIStartupListClass,
					MSG_TUISL_DELETE_PROGRAM
		.enter
	;
	; Get the currently selected program, if any
	;
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjCallInstanceNoLock
		jc	noneSelected			;branch if no selection
	;
	; Delete the selected program
	;
		push	ds, si
		mov	di, ds:[si]
		add	di, ds:[di].TweakUIStartupList_offset
		movdw	bxsi, ds:[di].TUISLI_array
		push	ax
		call	MemLock
		mov	ds, ax
		pop	ax
		mov	cx, 1				;cx <- delete 1
		call	ChunkArrayDeleteRange		;uses element #
		call	MemUnlock
		pop	ds, si
	;
	; Update the list
	;
		call	InitializeList
	;
	; Indicate no selections -- disable the Remove trigger
	;
		clr	bp				;bp <- no selections
		mov	ax, MSG_TUISL_STARTUP_PROGRAM_SELECTED
		call	ObjCallInstanceNoLock
	;
	; Mark the list not dirty
	;
		mov	di, ds:[si]
		add	di, ds:[di].TweakUIStartupList_offset
		mov	ds:[di].TUISLI_dirty, TRUE
noneSelected:
		.leave
		ret
TweakUIStartupListDeleteProgram	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TweakUIStartupListAddProgram
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a program from the file selector

CALLED BY:	PrefMgr

PASS:		*ds:si - TweakUIStartupListClass object
		ds:di - TweakUIStartupListClass object
RETURN:		none
DESTROYED:	bx, cx, dx, di, bp

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/22/98   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

TweakUIStartupListAddProgram	method dynamic TweakUIStartupListClass,
					MSG_TUISL_ADD_PROGRAM
tailBuffer	local	PATH_BUFFER_SIZE+FILE_LONGNAME_BUFFER_SIZE dup (TCHAR)
pathBuffer	local	PATH_BUFFER_SIZE+FILE_LONGNAME_BUFFER_SIZE dup (TCHAR)
		.enter
	;
	; Get rid of the dialog
	;
		push	bp, si
		mov	cx, IC_DISMISS
		mov	ax, MSG_GEN_INTERACTION_ACTIVATE_COMMAND
		mov	si, offset AddAppDialog
		call	ObjCallInstanceNoLock
		pop	bp, si
	;
	; Get the full path of the selection
	;
		push	bp, si
		mov	si, offset AddAppSelector
		mov	cx, ss
		lea	dx, ss:tailBuffer
		mov	ax, MSG_GEN_FILE_SELECTOR_GET_FULL_SELECTION_PATH
		call	ObjCallInstanceNoLock
		mov	cx, bp		;cx <- GenFileSelectorEntryFlags
		pop	bp, si
	;
	; Make sure it is a program
	;
		andnf	cx, mask GFSEF_TYPE
		cmp	cx, GFSET_FILE shl offset GFSEF_TYPE
		jne	done				;branch if not
	;
	; See if it is a reasonable standard path where we might find
	; a program
	;
		lea	di, ss:tailBuffer		;di <- buffer
		segmov	es, ss				;es:di <- name
		cmp	ax, SP_APPLICATION
		je	gotDir
		cmp	ax, SP_SYS_APPLICATION
		je	gotDir
	;
	; Not a reasonable looking path -- construct the path representing
	; the disk handle and file
	;
		push	ds, si
		mov	bx, ax				;bx <- disk handle
		segmov	ds, ss, ax
		mov	es, ax
		lea	si, ss:tailBuffer		;ds:si <- tail
		lea	di, ss:pathBuffer		;es:di <- buffer
		mov	dx, 1				;dx <- include drive
		mov	cx, (size pathBuffer)		;cx <- size
		call	FileConstructFullPath
		pop	ds, si
		lea	di, ss:pathBuffer		;di <- path
		segmov	es, ss				;es:di <- name
	;
	; Add the selected program
	;
addProgram:
		push	ds, si
		mov	si, ds:[si]
		add	si, ds:[si].TweakUIStartupList_offset
		movdw	bxsi, ds:[si].TUISLI_array
		call	MemLock
		push	bx
		mov	ds, ax
		clr	cx				;cx <- NULL terminated
		clr	bx				;bx <- NameArrayAddFlag
		call	NameArrayAdd
		pop	bx
		call	MemUnlock
		pop	ds, si
	;
	; Update the list
	;
		call	InitializeList
	;
	; Mark the list dirty
	;
		mov	di, ds:[si]
		add	di, ds:[di].TweakUIStartupList_offset
		mov	ds:[di].TUISLI_dirty, TRUE
done:
		.leave
		ret

	;
	; Skip any leading backslash
	;
gotDir:
		cmp	{TCHAR}es:[di], '\\'		;leading backslash?
		jne	addProgram			;branch if not
		LocalNextChar esdi			;skip backslash
		jmp	addProgram
TweakUIStartupListAddProgram	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TweakUIStartupListSaveOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save our settings to the .INI file

CALLED BY:	PrefMgr

PASS:		*ds:si - TweakUIStartupListClass object
		ds:di - TweakUIStartupListClass object
RETURN:		none
DESTROYED:	bx, cx, dx, di, bp

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/22/98   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

TweakUIStartupListSaveOptions	method dynamic TweakUIStartupListClass,
					MSG_META_SAVE_OPTIONS
		uses	si
		.enter
	;
	; Is there an array?
	;
		clr	bx
		xchg	bx, ds:[di].TUISLI_array.handle
		tst	bx				;any array?
		jz	done				;branch if not
		mov	si, ds:[di].TUISLI_array.chunk
	;
	; Delete the existing string section
	;
		push	si
		segmov	ds, cs, cx
		mov	si, offset uiCategory		;ds:si <- category
		mov	dx, offset startupKey		;cx:dx <- key
		call	InitFileDeleteEntry
		pop	si
	;
	; See if there's anything to save
	;
		call	MemLock
		mov	ds, ax
		call	ChunkArrayGetCount
		jcxz	freeArray			;branch if nothing
	;
	; Loop through the strings in our array and add them
	;
		push	bx
		mov	bx, cs
		mov	di, offset SaveOptionsCallback
		call	ChunkArrayEnum
		pop	bx
	;
	; Free the array
	;
freeArray:
		call	MemFree
done:
		.leave
		ret
TweakUIStartupListSaveOptions	endm

SaveOptionsCallback	proc	far
		uses	di, si, es, ds
pathBuffer	local	PATH_BUFFER_SIZE+FILE_LONGNAME_BUFFER_SIZE dup (TCHAR)
		.enter
	;
	; Copy the silly path to a buffer so we can NULL-terminate it
	;
		mov	cx, ax				;cx <- size
		lea	si, ds:[di][RefElementHeader]
		sub	cx, (size RefElementHeader)	;cx <- # bytes
		lea	di, ss:pathBuffer
		segmov	es, ss				;es:di <- string
		rep	movsb				;copy me
		LocalClrChar ax
		LocalPutChar esdi, ax			;NULL terminate
	;
	; Write out the string
	;
		lea	di, ss:pathBuffer
		segmov	es, ss				;es:di <- string
		segmov	ds, cs, cx
		mov	si, offset uiCategory		;ds:si <- category
		mov	dx, offset startupKey		;cx:dx <- key
		call	InitFileWriteStringSection

		.leave
		ret
SaveOptionsCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TweakUIStartupListReset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset to our previous settings

CALLED BY:	PrefMgr

PASS:		*ds:si - TweakUIStartupListClass object
		ds:di - TweakUIStartupListClass object
RETURN:		none
DESTROYED:	bx, cx, dx, di, bp

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/22/98   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

TweakUIStartupListReset	method dynamic TweakUIStartupListClass,
					MSG_GEN_RESET
	;
	; Free the old array, if any
	;
		clr	bx
		xchg	bx, ds:[di].TUISLI_array.handle
		tst	bx				;any array?
		jz	rebuildArray			;branch if not
		call	MemFree
	;
	; Go rebuild a new one
	;
rebuildArray:
		mov	ax, MSG_PREF_DYNAMIC_LIST_BUILD_ARRAY
		GOTO	ObjCallInstanceNoLock
TweakUIStartupListReset	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TweakUIStartupListHasStateChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return whether anything has changed

CALLED BY:	PrefMgr

PASS:		*ds:si - TweakUIStartupListClass object
		ds:di - TweakUIStartupListClass object
RETURN:		carry - set if changed
DESTROYED:	bx, cx, dx, di, bp

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/30/98   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

TweakUIStartupListHasStateChanged	method dynamic TweakUIStartupListClass,
					MSG_PREF_HAS_STATE_CHANGED
		tst	ds:[di].TUISLI_dirty		;clears carry
		jz	done				;branch if not dirty
		stc					;carry <- changed
done:
		ret
TweakUIStartupListHasStateChanged	endm

TweakUICode	ends