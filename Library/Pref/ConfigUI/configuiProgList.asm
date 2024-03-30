COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Designs in Light 2002 -- All Rights Reserved

FILE:		configuiProgList.asm

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ProgListCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LockArrayForList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock the array for the list, creating if necessary

CALLED BY:	UTILITY

PASS:		*ds:si - ConfigUIListClass object
		*ds:si - chunk array
		^lbx:si - chunk array
RETURN:		none
DESTROYED:	none

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LockArrayForList	proc	near
		class	ConfigUIListClass

		uses	ax, di
		.enter

		push	si
		call	getArray
		tst	bx			;any array?
		jz	createArray		;branch if not
		pop	ax			;throw away chunk
lockArray:
		call	MemLock
		mov	ds, ax

		.leave
		ret

getArray:
		mov	di, ds:[si]
		add	di, ds:[di].ConfigUIList_offset
		movdw	bxsi, ds:[di].CUILI_array
		retn

createArray:
		pop	si			;*ds:si <- list object
		push	cx, dx, bp
		mov	ax, MSG_PREF_DYNAMIC_LIST_BUILD_ARRAY
		call	ObjCallInstanceNoLock
		pop	cx, dx, bp
		call	getArray
		jmp	lockArray
LockArrayForList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConfigUIListInitUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the startup list UI

CALLED BY:	MSG_CUIL_INIT_UI

PASS:		*ds:si - ConfigUIListClass object
RETURN:		none
DESTROYED:	ax, cx, dx, di

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ConfigUIListInitUI	method	dynamic	ConfigUIListClass,
					MSG_CUIL_INIT_UI
		uses	bp

		.enter
	;
	; Initialize the list for how many items we found
	;
		push	ds, si
		call	LockArrayForList
		call	ChunkArrayGetCount		;cx <- # items
		call	MemUnlock
		pop	ds, si
		mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
		call	ObjCallInstanceNoLock
	;
	; set no selection, and update status
	;
		mov	ax, MSG_GEN_ITEM_GROUP_SET_NONE_SELECTED
		clr	dx				;dx <- not indtrmnt.
		call	ObjCallInstanceNoLock
		mov	ax, MSG_GEN_ITEM_GROUP_SEND_STATUS_MSG
		clr	cx				;cx <- not modifide
		call	ObjCallInstanceNoLock

		.leave
		ret
ConfigUIListInitUI	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConfigUIListMarkDirty, MarkNotDirty
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Mark the list dirty

CALLED BY:	MSG_CUIL_MARK_DIRTY

PASS:		*ds:si - ConfigUIListClass object
RETURN:		none
DESTROYED:	ax, cx, dx, di

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ConfigUIListMarkDirty	method	dynamic	ConfigUIListClass,
						MSG_CUIL_MARK_DIRTY
		mov	ds:[di].CUILI_dirty, TRUE
		ret
ConfigUIListMarkDirty	endm

ConfigUIListMarkNotDirty	method	dynamic	ConfigUIListClass,
						MSG_CUIL_MARK_NOT_DIRTY
		mov	ds:[di].CUILI_dirty, FALSE
		ret
ConfigUIListMarkNotDirty	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConfigUIListReset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset to our previous settings

CALLED BY:	PrefMgr

PASS:		*ds:si - ConfigUIListClass object
		ds:di - ConfigUIListClass object
RETURN:		none
DESTROYED:	bx, cx, dx, di, bp

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ConfigUIListReset	method dynamic ConfigUIListClass,
					MSG_GEN_RESET
	;
	; Free the old array, if any
	;
		clr	bx
		xchg	bx, ds:[di].CUILI_array.handle
		tst	bx				;any array?
		jz	rebuildArray			;branch if not
		call	MemFree
	;
	; Go rebuild a new one
	;
rebuildArray:
		mov	ax, MSG_PREF_DYNAMIC_LIST_BUILD_ARRAY
		GOTO	ObjCallInstanceNoLock
ConfigUIListReset	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConfigUIListHasStateChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return whether anything has changed

CALLED BY:	PrefMgr

PASS:		*ds:si - ConfigUIStartupListClass object
		ds:di - ConfigUIStartupListClass object
RETURN:		carry - set if changed
DESTROYED:	bx, cx, dx, di, bp

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ConfigUIListHasStateChanged	method dynamic ConfigUIListClass,
					MSG_PREF_HAS_STATE_CHANGED
		tst	ds:[di].CUILI_dirty		;clears carry
		jz	done				;branch if not dirty
		stc					;carry <- changed
done:
		ret
ConfigUIListHasStateChanged	endm

;--------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartupListBuildArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create the list of startup apps

CALLED BY:	PrefMgr

PASS:		*ds:si - ConfigUIStartupListClass object
		ds:di - ConfigUIStartupListClass object
RETURN:		none
DESTROYED:	bx, cx, dx, di, bp

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

uiCat2		char "ui", 0
startupKey	char "execOnStartup",0

StartupListBuildArray	method	dynamic	StartupListClass,
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
		mov	si, offset uiCat2		;ds:si <- category
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
		add	di, ds:[di].ConfigUIList_offset
		movdw	ds:[di].CUILI_array, dxax
	;
	; Initialize the list and mark not dirty
	;
		mov	ax, MSG_CUIL_INIT_UI
		call	ObjCallInstanceNoLock
		mov	ax, MSG_CUIL_MARK_NOT_DIRTY
		call	ObjCallInstanceNoLock

		.leave
		ret
StartupListBuildArray	endm

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
		StartupListGetMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a particular moniker

CALLED BY:	PrefMgr

PASS:		*ds:si - StartupListClass object
		ds:di - StartupListClass object
		ss:bp - GetItemMonikerParams
RETURN:		bp - # of chars returned
DESTROYED:	bx, cx, dx, di, bp

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

StartupListGetMoniker	method	dynamic	StartupListClass,
					MSG_PREF_ITEM_GROUP_GET_ITEM_MONIKER
		.enter

	;
	; Get the specified element
	;
		call	LockArrayForList
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
done:
		call	MemUnlock

		.leave
		ret

noItem:
		clr	bp				;bp <- item ignored
		jmp	done
StartupListGetMoniker	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartupListProgramSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A program has been selected

CALLED BY:	PrefMgr

PASS:		*ds:si - StartupListClass object
		ds:di - StartupListClass object
		bp - # of selections
RETURN:		none
DESTROYED:	bx, cx, dx, di, bp

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

StartupListProgramSelected	method dynamic StartupListClass,
					MSG_SL_STARTUP_PROGRAM_SELECTED
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
StartupListProgramSelected	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartupListDeleteProgram
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete the selected program

CALLED BY:	PrefMgr

PASS:		*ds:si - StartupListClass object
		ds:di - StartupListClass object
RETURN:		none
DESTROYED:	bx, cx, dx, di, bp

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

StartupListDeleteProgram	method dynamic StartupListClass,
					MSG_SL_DELETE_PROGRAM
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
		call	LockArrayForList
		mov	cx, 1				;cx <- delete 1 item
		call	ChunkArrayDeleteRange		;uses element #
		call	MemUnlock
		pop	ds, si
	;
	; Update the list and mark it dirty
	;
		mov	ax, MSG_CUIL_INIT_UI
		call	ObjCallInstanceNoLock
		mov	ax, MSG_CUIL_MARK_DIRTY
		call	ObjCallInstanceNoLock
	;
	; Indicate no selections -- disable the Remove trigger
	;
		clr	bp				;bp <- no selections
		mov	ax, MSG_SL_STARTUP_PROGRAM_SELECTED
		call	ObjCallInstanceNoLock
noneSelected:
		.leave
		ret
StartupListDeleteProgram	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartupListAddProgram
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a program from the file selector

CALLED BY:	PrefMgr

PASS:		*ds:si - StartupListClass object
		ds:di - StartupListClass object
RETURN:		none
DESTROYED:	bx, cx, dx, di, bp

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if ERROR_CHECK
LocalDefNLString clockString <"EC SysTray Clock", 0>
LocalDefNLString trayAppsString <"EC TrayApps", 0>
else
LocalDefNLString clockString <"SysTray Clock", 0>
LocalDefNLString trayAppsString <"TrayApps", 0>
endif


StartupListDeleteTaskbarApps	method dynamic StartupListClass,
					MSG_SL_DELETE_TASKBAR_APPS
		.enter
	;
	; Prepare
	;
		push	es, di, ds, si
		call	LockArrayForList

	;
	; NameArrayFind:
	; *ds:si - Name array.
	; es:di - Name to find.
	; cx - Length of name (0 for null-terminated).
	; dx:ax - Buffer to return data (or zero to not return data).
	;

		segmov	es, cs
		mov	di, offset trayAppsString	; es:di <- name
		clr	cx, dx, ax
		call	NameArrayFind			; return index in ax, CF - set if name found
		jnc	trayAppsNotFound
		mov	cx, 1				; cx <- delete 1 item
		call	ChunkArrayDeleteRange		; uses element #
trayAppsNotFound:

		segmov	es, cs
		mov	di, offset clockString		; es:di <- name
		clr	cx, dx, ax
		call	NameArrayFind			; return index in ax, CF - set if name found
		jnc	clockNotFound
		mov	cx, 1				; cx <- delete 1 item
		call	ChunkArrayDeleteRange		; uses element #

clockNotFound:
	;
	; finish
	;
		call	MemUnlock
		pop	es, di, ds, si
	;
	; Update the list and mark it dirty
	;
		mov	ax, MSG_CUIL_INIT_UI
		call	ObjCallInstanceNoLock
		mov	ax, MSG_CUIL_MARK_DIRTY
		call	ObjCallInstanceNoLock
	;
	; Indicate no selections -- disable the Remove trigger
	;
		clr	bp				;bp <- no selections
		mov	ax, MSG_SL_STARTUP_PROGRAM_SELECTED
		call	ObjCallInstanceNoLock

		.leave
		ret
StartupListDeleteTaskbarApps	endm


StartupListAddTaskbarApps	method dynamic StartupListClass,
					MSG_SL_ADD_TASKBAR_APPS
		.enter

		push	es, di, ds, si
		call	LockArrayForList

		segmov	es, cs
		mov	di, offset trayAppsString	; es:di <- name
		push	bx				; must be saved, has handle of block
		clr	cx				; cx <- NULL terminated
		clr	bx				; bx <- NameArrayAddFlag
		clr	dx				; dx:ax extra data
		clr	ax
		call	NameArrayAdd
		pop	bx

		segmov	es, cs
		mov	di, offset clockString		; es:di <- name
		push	bx				; must be saved, has handle of block
		clr	cx				; cx <- NULL terminated
		clr	bx				; bx <- NameArrayAddFlag
		clr	dx				; dx:ax extra data
		clr	ax
		call	NameArrayAdd
		pop	bx

		call	MemUnlock
		pop	es, di, ds, si
	;
	; Update the list and mark the list dirty
	;
		mov	ax, MSG_CUIL_INIT_UI
		call	ObjCallInstanceNoLock
		mov	ax, MSG_CUIL_MARK_DIRTY
		call	ObjCallInstanceNoLock

	;
	; Indicate no selections -- disable the Remove trigger
	;
		clr	bp				;bp <- no selections
		mov	ax, MSG_SL_STARTUP_PROGRAM_SELECTED
		call	ObjCallInstanceNoLock

		.leave
		ret

StartupListAddTaskbarApps	endm





StartupListAddProgram	method dynamic StartupListClass,
					MSG_SL_ADD_PROGRAM
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
		call	LockArrayForList
		push	bx
		clr	cx				;cx <- NULL terminated
		clr	bx				;bx <- NameArrayAddFlag
		call	NameArrayAdd
		pop	bx
		call	MemUnlock
		pop	ds, si
	;
	; Update the list and mark the list dirty
	;
		mov	ax, MSG_CUIL_INIT_UI
		call	ObjCallInstanceNoLock
		mov	ax, MSG_CUIL_MARK_DIRTY
		call	ObjCallInstanceNoLock
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
StartupListAddProgram	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartupListSaveOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save our settings to the .INI file

CALLED BY:	PrefMgr

PASS:		*ds:si - StartupListClass object
		ds:di - StartupListClass object
RETURN:		none
DESTROYED:	bx, cx, dx, di, bp

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

StartupListSaveOptions	method dynamic StartupListClass,
					MSG_META_SAVE_OPTIONS
		uses	si
		.enter

	;
	; Is there an array?
	;
		clr	bx
		xchg	bx, ds:[di].CUILI_array.handle
		tst	bx				;any array?
		jz	done				;branch if not
		mov	si, ds:[di].CUILI_array.chunk
	;
	; Delete the existing string section
	;
		push	si
		segmov	ds, cs, cx
		mov	si, offset uiCat2		;ds:si <- category
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
StartupListSaveOptions	endm

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
		mov	si, offset uiCat2		;ds:si <- category
		mov	dx, offset startupKey		;cx:dx <- key
		call	InitFileWriteStringSection

		.leave
		ret
SaveOptionsCallback	endp

ProgListCode	ends
