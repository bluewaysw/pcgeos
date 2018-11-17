COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	File Managers
MODULE:		Installable Tools -- Process Class Methods
FILE:		ctoolProcess.asm

AUTHOR:		Adam de Boor, Aug 25, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	8/25/92		Initial revision


DESCRIPTION:
	ProcessClass methods
		

	$Id: ctoolProcess.asm,v 1.3 98/06/03 13:47:11 joon Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ToolCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FMGetSelectedFiles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the files currently selected.

CALLED BY:	MSG_FM_GET_SELECTED_FILES
PASS:		ds	= dgroup
RETURN:		ax	= handle of quick transfer block (0 if couldn't alloc)
DESTROYED:	cx, dx, bp
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/25/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FMGetSelectedFiles method extern dynamic FileManagerClass, MSG_FM_GET_SELECTED_FILES
		.enter
	;
	; get current target folder object
	;
		mov	bx, ds:[targetFolder]		; bx:si = target folder
							;  object
		mov	si, FOLDER_OBJECT_OFFSET	; common offset
		tst	bx				; check if any target
if _NEWDESK or _FCAB or _ZMGR or not _TREE_MENU
		jz	none
else
		jnz	callCommon			; if target exists, use
							;  it
		tst	ds:[treeRelocated]
		jz	none				; no tree yet
		mov	bx, handle DesktopUI		; else, use tree object
		mov	si, offset DesktopUI:TreeObject
callCommon:
endif ; if _GMGR
		mov	ax, MSG_META_APP_GET_SELECTION
		call	ObjMessageCall
done:
		.leave
		ret

none:
	;
	; Nothing with the target, so return a block with nothing selected.
	; 
		mov	ax, size FileQuickTransferHeader
		mov	cx, ALLOC_DYNAMIC_LOCK or mask HF_SHARABLE or \
				(mask HAF_ZERO_INIT shl 8)
		call	MemAlloc
		jc	fail
	;
	; Initialize to be [SP_TOP] \ as a reasonable (and quick) default.
	; 
		mov	es, ax
		mov	es:[FQTH_diskHandle], SP_TOP
		mov	{word}es:[FQTH_pathname], '\\' or (0 shl 8)
		call	MemUnlock
		mov_tr	ax, bx
		jmp	done
fail:
	;
	; Couldn't alloc -- return 0.
	; 
		clr	ax
		jmp	done
FMGetSelectedFiles	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FMOpenFiles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open the files in the passed 

CALLED BY:	MSG_FM_OPEN_FILES
PASS:		cx 	= handle of first block with a FileQuickTransferHeader
			  and following array of FileOperationInfoEntry
			  structures. More than one block of files may be
			  passed by linking successive blocks through their
			  FQTH_nextBlock fields. The final block must have an
			  FQTH_nextBlock of 0.

RETURN: 	carry set on error (all things that could be opened will have
		    been opened, however)
		All blocks in the chain are freed, regardless of the success
		    of the operation.
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	lots

PSEUDO CODE/STRATEGY:
		Implement this when it becomes necessary.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/25/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FMOpenFiles	method extern dynamic FileManagerClass, MSG_FM_OPEN_FILES
		.enter
		.leave
		ret
FMOpenFiles	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FMDupAndAdd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Duplicate a resource from a tool library and make one of
		the objects in that resource a generic child of one of
		our own.

CALLED BY:	MSG_FM_DUP_AND_ADD
PASS:		^lcx:dx	= object to add as generic child, after its resource
			  has been duplicated
		bp	= FileManagerParent to which to add the duplicated
			  object
RETURN:		^lcx:dx	= duplicated object
DESTROYED:	ax, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/25/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if _NEWDESK
fmParents	optr	Desktop,		; FMP_APPLICATION
			Desktop			; FMP_DISPLAY_GROUP
else
fmParents	optr	Desktop,		; FMP_APPLICATION
			FileSystemDisplayGroup	; FMP_DISPLAY_GROUP
endif

FMDupAndAdd	method extern dynamic FileManagerClass, MSG_FM_DUP_AND_ADD
		.enter
EC <		cmp	bp, length fmParents				>
EC <		ERROR_A	INVALID_FM_PARENT				>
		CheckHack <type fmParents eq 4>
		shl	bp
		shl	bp
	;
	; Fetch and save generic parent.
	; 
		mov	bx, cs:[fmParents][bp].handle
		mov	si, cs:[fmParents][bp].chunk
		push	bx, si
	;
	; Figure thread running parent to use as thread to run duplicated
	; block.
	; 
		mov	ax, MGIT_EXEC_THREAD
		call	MemGetInfo
	;
	; Duplicate the resource itself.
	; 
		mov	bx, cx		; bx <- resource to duplicate
		mov_tr	cx, ax		; cx <- thread to run duplicate
		clr	ax		; owned by us, please
		call	ObjDuplicateResource
	;
	; Now add the indicated object within the duplicate as the last child
	; of the appropriate generic parent.
	; 
		mov	cx, bx		; ^lcx:dx <- new child
		pop	bx, si
		mov	bp, CCO_LAST or mask CCF_MARK_DIRTY
		mov	ax, MSG_GEN_ADD_CHILD
		call	ObjMessageCall
		
		.leave
		ret
FMDupAndAdd	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DesktopCallToolLibrary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call a particular routine in a tool library on the process
		thread of the file manager.

CALLED BY:	MSG_DESKTOP_CALL_TOOL_LIBRARY
PASS:		ds	= dgroup
		cx	= handle of library to call (will be replaced by the
			  handle of the process before the call is issued)
		si	= entry point to call
		dx, bp	= as appropriate to the call
RETURN:		nothing
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DesktopCallToolLibrary method extern dynamic DesktopClass, MSG_DESKTOP_CALL_TOOL_LIBRARY
		.enter
		mov	bx, cx		; bx <- library
		mov	cx, handle 0	; cx <- us

		mov	ax, GGIT_ATTRIBUTES
		call	GeodeGetInfo
		test	ax, mask GA_ENTRY_POINTS_IN_C
		jnz	callC

callCommon:
		mov_tr	ax, si		; ax <- entry #
		call	ProcGetLibraryEntry	; bx:ax <- virtual fptr
		call	ProcCallFixedOrMovable	; call it, dude
		.leave
		ret

callC:
		push	cx, dx, bp
		jmp	callCommon
DesktopCallToolLibrary endm

ToolCode	ends
