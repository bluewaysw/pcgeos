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
		

	$Id: cvttoolTool.asm,v 1.1 97/04/04 18:00:46 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CommonCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertFetchTools
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
		public	ConvertFetchTools
ConvertFetchTools proc	far
		.enter
		segmov	es, <segment tools>, di
		mov	di, offset tools
		mov	cx, length tools
		.leave
		ret
ConvertFetchTools endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertToolProcessBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process a FileQuickTransferBlock full of files/dirs to
		convert.

CALLED BY:	(INTERNAL) ConvertToolActivated, self
PASS:		bx	= handle of block of things to convert
		ss:bp	= frame inherited from ConvertToolActivated
		es	= dgroup
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di, ds
SIDE EFFECTS:	block is freed

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/28/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
recurseReturnAttrs	FileExtAttrDesc \
	<FEA_NAME,	FOIE_name,	size FOIE_name>,
	<FEA_FILE_TYPE,	FOIE_type,	size FOIE_type>,
	<FEA_FILE_ATTR,	FOIE_attrs,	size FOIE_attrs>,
	<FEA_FLAGS,	FOIE_flags,	size FOIE_flags>,
	<FEA_CREATOR,	FOIE_creator,	size FOIE_creator>,
	<FEA_END_OF_LIST>

if 0
; This CheckHack doesn't seem to be necessary.  We're just ignoring
; the FOIE_info field here - chrisb
CheckHack <FOIE_creator+size FOIE_creator eq size FileOperationInfoEntry>
endif

idata	segment
recurseMatchFileType	GeosFileType	GFT_OLD_VM
idata	ends

recurseMatchAttrs	FileExtAttrDesc \
	<FEA_FILE_TYPE, recurseMatchFileType, 	size GeosFileType>,
	<FEA_END_OF_LIST>

recurseParams	FileEnumParams <
	mask FESF_DIRS or mask FESF_GEOS_NON_EXECS or mask FESF_LEAVE_HEADER,
	recurseReturnAttrs,		; FEP_returnAttrs
	size FileOperationInfoEntry,	; FEP_returnSize
	recurseMatchAttrs,		; FEP_matchAttrs
	FE_BUFSIZE_UNLIMITED,		; FEP_bufSize
	0,				; FEP_skipCount
	0,				; FEP_callback
	0,				; FEP_callbackAttrs
	0,				; FEP_cbData1
	0,				; FEP_cbData2
	size FileQuickTransferHeader	; FEP_headerSize
>

nullStr		char	0

ConvertToolProcessBlock proc	near
		.enter	inherit ConvertToolActivatedLow
	;
	; Lock down the list and push to the directory indicated in the block.
	; 
		call	MemLock
		mov	ds, ax
		
		call	FilePushDir
		push	bx
		mov	bx, ds:[FQTH_diskHandle]
		mov	dx, offset FQTH_pathname
		call	FileSetCurrentPath
		LONG jc	done
	;
	; We have no further need of FQTH_pathname, and it's of just the right
	; size for constructing the full path of each file we're abusing,
	; so construct the full path of the cwd and remember where to append
	; each file.
	;
		segmov	es, ds
		clr	bx			; relative to current dir
		segmov	ds, cs
		mov	si, offset nullStr	; null tail => construct
						;  path for cwd
		mov	dx, TRUE		; add drive spec, please
		mov	di, offset FQTH_pathname; es:di <- buffer
		mov	cx, size FQTH_pathname	; cx <- size of same
		call	FileConstructFullPath
		mov	al, '\\'
		dec	di			; es:di <- byte before null
		scasb				; already path separator?
		je	pathConstructed		; yes -- no need to add one
		stosb				; no -- add one; no need for
						;  null-term, as it'll be
						;  overwritten anyway.
pathConstructed:
		segmov	ds, es			; ds <- FQTH block again
	;
	; Now convert each file in turn.
	; 
		mov	cx, ds:[FQTH_numFiles]
		mov	dx, offset FQTH_files
fileLoop:
		push	es
		segmov	es, dgroup, ax
		tst	es:[cancelConvert]
		pop	es
		jnz	done
	;
	; Put the name into the feedback box.
	; 
		push	dx, bp, cx, di

CTRecurseStack	struct
    CTRS_di	word		; place for tail in feedback path
    CTRS_cx	word		; loop counter
    CTRS_bp	word		; inherited frame
    CTRS_dx	word		; FOIE offset
    CTRS_bx	hptr		; handle of block we were passed
CTRecurseStack	ends

		CheckHack <offset FOIE_name eq 0>
		mov	si, dx
		mov	cx, size FOIE_name	; XXX: might get close
						;  here...
		rep	movsb

		push	ss:[convertLib]		; save while still have
						;  frame pointer

		mov	bx, ss:[feedbackBox].handle
		mov	si, offset ConvertText
		mov	bp, offset FQTH_pathname
		mov	dx, ds
		clr	cx		; null-terminated
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
		mov	di, mask MF_CALL
		call	ObjMessage
	;
	; Now convert the file in-place.
	; 
		pop	bx			; bx <- library handle
		mov	bp, sp
		mov	si, ss:[bp].CTRS_dx
		cmp	ds:[si].FOIE_type, GFT_OLD_VM
		jne	notToBeConverted

		clr	cx		; path is relative
		mov	ax, enum ConvertVMFile
		lea	dx, ds:[si].FOIE_name
		call	ProcGetLibraryEntry
		call	ProcCallFixedOrMovable
	;
	; Advance to the next entry.
	;	carry = set if error
	;		ax = error code
	; 
nextEntry:
		pop	dx, bp, cx, di
		LONG jc	handleError
continueAfterError:
		add	dx, size FileOperationInfoEntry
		loop	fileLoop
done:
	;
	; Free the block of files and boogie.
	; 
		pop	bx
		call	MemFree
		call	FilePopDir
		.leave
		ret

notToBeConverted:
		cmp	ds:[si].FOIE_type, GFT_DIRECTORY
		je	recurse
		test	ds:[si].FOIE_attrs, mask FA_SUBDIR
		jz	nextEntry 	; XXX: generate an error here.
					; (currently 'test' clears carry)
		
	;
	; Enumerate the directory and recurse.
	; 
recurse:
	; Save registers for the next file in our current directory.
	; On Stack -> di
	;	      cx
	;	      bp
	;	      dx
	;	      bx
	;

	;
	; Push to the directory to enumerate.
	;
		call	FilePushDir
		lea	dx, ds:[si].FOIE_name
		clr	bx
		call	FileSetCurrentPath
	;
	; Unlock the block for the current directory, so we're not taking up
	; precious memory during the enumeration of the next directory to
	; process.
	;
		mov	bp, sp
		mov	bx, ss:[bp].CTRS_bx
		call	MemUnlock

	;
	; Now enumerate the subdirectory.
	;
		segmov	ds, cs
		mov	si, offset recurseParams
		call	FileEnumPtr

		jc	recurseSkipped
		jcxz	recurseFreeBlock

	;
	; Actually something to process there, so lock the returned block
	; down (FileEnum left us room for a FileQuickTransferHeader, as we
	; asked it to...).
	;
		call	MemLock
		push	bx
		mov	ds, ax
	;
	; Store the number of files/dirs seen and fetch the current directory
	; in all its glory.
	;
		mov	ds:[FQTH_numFiles], cx
		mov	si, offset FQTH_pathname
		mov	cx, size FQTH_pathname
		call	FileGetCurrentPath
		mov	ds:[FQTH_diskHandle], bx
		pop	bx
		
		call	FilePopDir
		mov	bp, ss:[bp].CTRS_bp		; pass original bp...
		call	ConvertToolProcessBlock
		
recurseDone:
	;
	; Lock down the block we were originally given, restore registers for
	; looping, and go finish off this entry in the block.
	;
		mov	bp, sp
		mov	bx, ss:[bp].CTRS_bx
		call	MemLock
		mov	ds, ax
		mov	es, ax
		clc				; indicate no error
		jmp	nextEntry

recurseFreeBlock:
	;
	; Nothing found during enumeration, but we still get a block back, as
	; we asked for a non-zero-sized header on the block. Since there's no
	; point in recursing, we need to free the block ourselves.
	;
		call	MemFree

recurseSkipped:
		call	FilePopDir
		jmp	recurseDone

handleError:
	;
	; Report error
	;	ax = error code
	;
		push	bx, si, bp
		mov	bx, handle ConvertStrings
		call	MemLock
		push	ds
		mov	ds, ax
		mov	si, offset ConvertErrorString
		mov	si, ds:[si]
		pop	ds
		sub	sp, size StandardDialogParams
		mov	bp, sp
		mov	ss:[bp].SDP_customFlags, \
				CustomDialogBoxFlags \
					<0, CDT_ERROR, GIT_NOTIFICATION,0>
		mov	ss:[bp].SDP_customString.segment, ax
		mov	ss:[bp].SDP_customString.offset, si
		mov	ss:[bp].SDP_stringArg1.segment, ds
		mov	ss:[bp].SDP_stringArg1.offset, offset FQTH_pathname
		clr	ss:[bp].SDP_helpContext.segment
		call	UserStandardDialog
		mov	bx, handle ConvertStrings
		call	MemUnlock
		pop	bx, si, bp
		jmp	continueAfterError	; continue
ConvertToolProcessBlock endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertToolActivated
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
		public	ConvertToolActivated
ConvertToolActivated proc	far
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
		
		call	ConvertToolActivatedLow
exit:
		.leave
		ret
ConvertToolActivated endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertToolActivatedLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do all the setup work, given the handle of a FQTH block, then
		call the recursive routine to convert everything.

CALLED BY:	(INTERNAL) ConvertToolActivated, 
			   ConvertToolActivatedNoFileManager
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
ConvertToolActivatedLow proc	near
feedbackBox	local	optr
fqthBlock	local	hptr
convertLib	local	hptr		; handle of loaded library
		.enter

		mov	ss:[fqthBlock], ax
	;
	; Load in the library that does the actual work.
	;
		call	ConvertToolLoadConverter
		jc	nukeFQTH
		mov	ss:[convertLib], ax
	;
	; Put up the progress box we use after clearing the cancel flag for the
	; whole process.
	; 
		segmov	es, dgroup, ax
		mov	es:[cancelConvert], FALSE

	    ;
	    ; First duplicate the resource and add it as a child of the app
	    ; 
		push	bp
		mov	cx, handle ConvertFeedback
		mov	dx, offset ConvertFeedback
		mov	bp, FMP_APPLICATION
		mov	ax, MSG_FM_DUP_AND_ADD
		mov	di, mask MF_CALL
		call	ObjMessage
		pop	bp
		movdw	ss:[feedbackBox], cxdx	; store optr of duplicate
	    ;
	    ; Set the beastie usable (else it won't come up on screen)
	    ; 
		movdw	bxsi, cxdx
		mov	ax, MSG_GEN_SET_USABLE
		mov	dl, VUM_MANUAL
		clr	di
		push	bp
		call	ObjMessage
	    ;
	    ; Finally, tell it to come on screen.
	    ; 
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		mov	di, mask MF_CALL
		call	ObjMessage
		pop	bp

	;
	; Convert the first block o' stuff. Batch up change notifications,
	; as we could well be doing a passel o' things here, all on the
	; file-manager's thread.
	; 
		call	FileBatchChangeNotifications
		mov	bx, ss:[fqthBlock]
		call	ConvertToolProcessBlock
		call	FileFlushChangeNotifications

	;
	; Bring down and destroy the duplicated feedback box.
	; 
		call	ConvertToolDestroyFeedback
	;
	; Unload the convert library.
	; 
		mov	bx, ss:[convertLib]
		call	GeodeFreeLibrary
exit:
		.leave
		ret

nukeFQTH:
		mov	bx, ss:[fqthBlock]
		call	MemFree
		jmp	exit
ConvertToolActivatedLow endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertToolActivatedNoFileManager
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deal with our tool entry having been activated via
		Graphical Setup, before a FileManager has been loaded.

CALLED BY:	Setup
PASS:		cx	= handle of calling process
		dx	= handle of FileQuickTransferHeader block

RETURN:		nothing
DESTROYED:	anything
SIDE EFFECTS:	lots

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	4/15/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
		public	ConvertToolActivatedNoFileManager
ConvertToolActivatedNoFileManager proc	far
		mov_tr	ax, dx
		mov	bx, cx
		call	ConvertToolActivatedLow
		ret
ConvertToolActivatedNoFileManager endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertToolDestroyFeedback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy the duplicated feedback box that's up on-screen

CALLED BY:	(INTERNAL) ConvertToolActivated
PASS:		ss:bp	= inherited stack frame
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di
SIDE EFFECTS:	the duplicated block holding the box is destroyed

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/31/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertToolDestroyFeedback proc	near
		uses	bp
		.enter	inherit ConvertToolActivatedLow
	;
	; First bring the box off-screen.
	; 
		movdw	bxsi, ss:[feedbackBox]
		mov	ax, MSG_GEN_INTERACTION_ACTIVATE_COMMAND
		mov	cx, IC_DISMISS
		clr	di
		call	ObjMessage
	;
	; Tell the child to remove itself from the tree, after setting itself
	; not-usable.
	; 
		mov	ax, MSG_GEN_REMOVE
		mov	dl, VUM_NOW
		mov	di, mask MF_CALL
		mov	bp, mask CCF_MARK_DIRTY
		call	ObjMessage
	;
	; Now tell the object to nuke the block in which it sits.
	; 
		mov	ax, MSG_META_BLOCK_FREE
		mov	di, mask MF_CALL
		call	ObjMessage
	;
	; Phew. All done.
	; 
		.leave
		ret
ConvertToolDestroyFeedback endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertToolLoadConverter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load the converter library.

CALLED BY:	ConvertToolActivated
PASS:		nothing
RETURN:		carry set on error:
			ax	= GeodeLoadError
		carry clear on success:
			ax	= handle of library
DESTROYED:	nothing else
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/25/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
libDir		char	CONVERT_LIB_DIR
libPath		char	CONVERT_LIB_PATH

ConvertToolLoadConverter proc	near
		uses	ds, dx, si, bx
		.enter
	;
	; Push to the directory that holds the library.
	; 
		call	FilePushDir
		mov	bx, CONVERT_LIB_DISK_HANDLE
		segmov	ds, cs
		mov	dx, offset libDir
		call	FileSetCurrentPath
		mov	ax, GLE_FILE_NOT_FOUND
		jc	done
	;
	; Load the library.
	; 
		mov	si, offset libPath
		mov	ax, CONVERT_PROTO_MAJOR
		mov	bx, CONVERT_PROTO_MINOR
		call	GeodeUseLibrary
		jc	done
		mov_tr	ax, bx
done:
	;
	; Return to previous directory.
	; 
		call	FilePopDir
		.leave
		ret
ConvertToolLoadConverter endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CCTStop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deal with the trigger being activated.

CALLED BY:	MSG_CCT_STOP
PASS:		*ds:si	= ConvertCancelTrigger object
		es	= dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	convertCancel is set non-zero. The box will eventually be
     			taken down.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CCTStop 	method dynamic ConvertCancelTriggerClass, MSG_CCT_STOP
		.enter
		mov	es:[cancelConvert], TRUE
		.leave
		ret
CCTStop		endm

CommonCode	ends
