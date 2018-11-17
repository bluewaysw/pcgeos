COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	File Manager Tools -- 1.X Document Conversion
MODULE:		File Manager Tool Interface
FILE:		convertTool.asm

AUTHOR:		Adam de Boor, Aug 26, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	8/26/92		Initial revision


DESCRIPTION:
	The aspects of this here library that constitute the installable
	tool facet of its personality.
		

	$Id: linktoolTool.asm,v 1.2 98/07/20 12:19:30 joon Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LinktoolFetchTools
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the table o' tools

CALLED BY:	File Manager
PASS:		nothing
RETURN:		es:di	= table of FMToolStruct structures
		cx	= length of same
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
		public	LinktoolFetchTools
LinktoolFetchTools proc	far
		.enter
		segmov	es, <segment tools>, di
		mov	di, offset tools
		mov	cx, length tools
		.leave
		ret
LinktoolFetchTools endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LinktoolToolActivated
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deal with our tool entry having been activated by the user.

CALLED BY:	File Manager
PASS:		cx	= handle of file manager process
		dx	= tool number within library (= 0, here)
RETURN:		nothing
DESTROYED:	anything
SIDE EFFECTS:	lots

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
		public	LinktoolToolActivated
LinktoolToolActivated proc	far
		.enter
	;
	; Get the list of selected files from the file manager using the
	; process handle we were given.
	;
		mov	bx, cx
		mov	ax, MSG_FM_GET_SELECTED_FILES
		mov	di, mask MF_CALL
		push	bp
		call	ObjMessage
		pop	bp
		tst	ax
		jz	exit		; => nothing selected
		
		call	LinktoolToolActivatedLow
exit:
		.leave
		ret
LinktoolToolActivated endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LinktoolToolActivatedLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a link

CALLED BY:	(INTERNAL) LinktoolToolActivated
PASS:		^hax	= FileQuickTransferHeader
		bx	= handle of calling process (FileManagerClass)
RETURN:		carry set on error
		transfer block always freed
DESTROYED:	ax, bx, cx, dx, si, di, ds, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/18/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LinktoolToolActivatedLow proc	near

fqthBlock	local	hptr	push	ax
		
		.enter

		segmov	es, dgroup, ax
		tst	es:[linktoolUI].handle
		jnz	doDialog

	    ;
	    ; First duplicate the resource and add it as a child of the app
	    ; 
		push	bp
		mov	cx, handle LinktoolBox
		mov	dx, offset LinktoolBox
		mov	bp, FMP_APPLICATION
		mov	ax, MSG_FM_DUP_AND_ADD
		mov	di, mask MF_CALL
		call	ObjMessage
		pop	bp
		
		movdw	es:[linktoolUI], cxdx
		
	    ;
	    ; Set it usable
	    ; 
		movdw	bxsi, cxdx
		mov	ax, MSG_GEN_SET_USABLE
		mov	dl, VUM_MANUAL
		clr	di
		call	ObjMessage
		
doDialog:
	;
	; Fill in the name of the target file, if there's only one link
	; being created, and select the whole thing so the user can change
	; it easily. If more than one file, then disable the thing.
	;
		push	ds
		
		mov	bx, ss:[fqthBlock]
		call	MemLock
		mov	ds, ax
		
		mov	bx, es:[linktoolUI].handle
		mov	si, offset LinktoolDestName
		
		mov	ax, MSG_GEN_SET_NOT_ENABLED
		cmp	ds:[FQTH_numFiles], 1
		jne	enableDisable

		mov	dx, ds
		clr	cx
		
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
		mov	di, mask MF_CALL
		push	bp
		mov	bp, offset FQTH_files.FOIE_name
		call	ObjMessage

		mov	ax, MSG_VIS_TEXT_SELECT_ALL
		mov	di, mask MF_CALL
		call	ObjMessage

		pop	bp

		mov	ax, MSG_GEN_SET_ENABLED

enableDisable:
		push	bp
		mov	dl, VUM_NOW
		mov	di, mask MF_CALL
		call	ObjMessage
		pop	bp
		
		mov	bx, ss:[fqthBlock]
		call	MemUnlock
		
	;
	; Finally, tell it to come on screen.
	;
		movdw	bxsi, es:[linktoolUI]
		
		call	ShellAllocPathBuffer	; es - PathBuffer struct
		call	FileBatchChangeNotifications

		call	UserDoDialog
		cmp	ax, IC_OK
		jne	done

afterDialog::		
	;
	; Change to the destination directory.
	; 
		push	bp
		mov	dx, es
		mov	bp, offset PB_path
		mov	cx, size PB_path
		mov	ax, MSG_GEN_FILE_SELECTOR_GET_DESTINATION_PATH
		mov	si, offset LinktoolFileSelector
		mov	di, mask MF_CALL
		call	ObjMessage
		pop	bp
		
		jc	error

		mov	bx, cx
		segmov	ds, es
		mov	dx, offset PB_path
		call	FileSetCurrentPath
		jc	error

		mov	bx, ss:[fqthBlock]
		call	MemLock
		mov	ds, ax
		mov	si, offset FQTH_pathname
		mov	di, offset PB_path	; es:di - source path
		LocalCopyString

		dec	di
DBCS <		dec	di						>
		mov	si, offset FQTH_files
		mov	cx, ds:[FQTH_numFiles]
fileLoop:
	;
	; Form target path in our path buffer.
	; 
		push	ds, si, di, cx		; save end of source path
						;  for truncation at end of
						;  loop + other loop vars
		
		mov	di, offset PB_path
		lea	dx, ds:[si].FOIE_name
		call	ShellCombineFileAndPath

		mov	bx, ds:[FQTH_diskHandle]
	;
	; If only one link being created, get name from text object.
	; 
		cmp	ds:[FQTH_numFiles], 1
		je	fetchNameFromText

	;
	; Finally, create the thing
	;
haveParams:
		mov	di, offset PB_path	; source of link
		push	ds
		segmov	ds, es, dx
		mov	dx, di
	; edigeron 11/10/00 - Don't allow a link to a link.
		call	FILEPUSHDIR
		mov	ax, bx
		call	FileSetStandardPath
		call	FileGetAttributes
		pushf
		call	FILEPOPDIR
		popf
		pop	ds
		jc	attributesError
		test	cx, mask FA_LINK
		stc	; dunno what state carry is, so set it in case
		jnz	attributesError
		lea	dx, ds:[si].FOIE_name
		clr	cx			; fetch attrs from target
		call	FileCreateLink
attributesError:
		pop	ds, si, di, cx
		jc	error
	;
	; Truncate the target path to just the directory, again, advance to
	; the next file entry and loop if more to do.
	; 
SBCS <		mov	{char}es:[di], 0				>
DBCS <		mov	{wchar}es:[di], 0				>
		add	si, size FileOperationInfoEntry
		loop	fileLoop
done:
		call	FileFlushChangeNotifications
		call	ShellFreePathBuffer
		
		mov	bx, ss:[fqthBlock]
		call	MemFree
		
		.leave
		ret

error:
		push	bp
		sub	sp, size StandardDialogOptrParams
		mov	bp, sp
		mov	ss:[bp].SDOP_customFlags, \
				CustomDialogBoxFlags \
					<0, CDT_ERROR, GIT_NOTIFICATION,0>
		mov	ss:[bp].SDOP_customString.handle, handle LinkError
		mov	ss:[bp].SDOP_customString.offset, offset LinkError
		clr	ax
		mov	ss:[bp].SDOP_stringArg1.handle, ax
		mov	ss:[bp].SDOP_stringArg2.handle, ax
		mov	ss:[bp].SDOP_helpContext.handle, ax
		call	UserStandardDialogOptr
		pop	bp
		jmp	done

fetchNameFromText:
	;
	; Fetch the link name from the text object the user mangled. We store
	; the result in the FileOperationInfoEntry, since we have no other
	; use for the stuff in there, the name having already been copied
	; to the target path buffer..
	; 
		push	bx, si, bp, ds
		mov	dx, ds
		mov	bp, si
		segmov	ds, dgroup, ax
		mov	bx, ds:[linktoolUI].handle
		mov	si, offset LinktoolDestName
		mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
		mov	di, mask MF_CALL
		call	ObjMessage
		pop	bx, si, bp, ds 
		jmp	haveParams

LinktoolToolActivatedLow endp


