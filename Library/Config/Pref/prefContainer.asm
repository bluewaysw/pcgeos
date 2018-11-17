COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	Config Library
MODULE:		PrefContainerClass
FILE:		prefContainer.asm

AUTHOR:		Adam de Boor, Dec  3, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	12/ 3/92	Initial revision


DESCRIPTION:
	Implementation of the PrefContainerClass, an interaction that
	manages a tree of Generic UI stored in a VM file or in a
	Preferences submodule.
		

	$Id: prefContainer.asm,v 1.1 97/04/04 17:50:44 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


EC<include	Internal/heapInt.def>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PC_DerefDI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Point ds:di to the PrefContainerInstance for the object.

CALLED BY:	(INTERNAL)
PASS:		*ds:si	= PrefContainer object
RETURN:		ds:di	= PrefContainerInstance
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 4/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PC_DerefDI	proc	near
		class	PrefContainerClass
		mov	di, ds:[si]
		add	di, ds:[di].PrefContainer_offset
		ret
PC_DerefDI	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefContainerReloc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Required relocation/unrelocation stuff for supporting
		GenPath mechanism.

CALLED BY:	MSG_META_RELOCATE, MSG_META_UNRELOCATE
PASS:		*ds:si	= instance
		ds:di	= PrefContainerInstance
		dx	= VMRelocType
		bp	= frame to pass to ObjRelocOrUnRelocSuper
RETURN:		carry set if error
		bp	= preserved
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 3/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefContainerReloc method dynamic PrefContainerClass, reloc
		uses	dx, bp
		.enter
		cmp	ax, MSG_META_UNRELOCATE
		jne	done

		mov	ds:[di].PCI_handle, 0	; so we don't get
							;  confused on restore

		mov	ax, ATTR_GEN_PATH_DATA
		mov	dx, TEMP_GEN_PATH_SAVED_DISK_HANDLE
		call	GenPathUnrelocObjectPath
done:
		.leave
		mov	di, offset PrefContainerClass
		call	ObjRelocOrUnRelocSuper
		ret
PrefContainerReloc endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefContainerCloseActiveFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close the active file, if such there be.

CALLED BY:	(INTERNAL) PrefContainerGenPathSet,
			   PrefContainerNotifyDialogChange
PASS:		*ds:si	= PrefContainer object
RETURN:		nothing
DESTROYED:	ax, es, bx, di, cx, dx
SIDE EFFECTS:	PCI_handle is set to 0 and tree is detached

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 3/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefContainerCloseActiveFile proc	near
		class	PrefContainerClass
		uses	si, bp
		.enter
		call	PC_DerefDI
		
		clr	bx
		xchg	bx, ds:[di].PCI_handle
		tst	bx
	LONG	jz	done
		
		movdw	cxdx, ds:[di].PCI_dupRoot
		jcxz	unhookVM

		mov	ds:[di].PCI_dupRoot.handle, 0	; so we don't think
							;  the next thing loaded
							;  is a library unless
							;  it is...

		push	bx, si
		movdw	bxsi, cxdx
		mov	ax, MSG_GEN_REMOVE
		mov	dl, VUM_NOW
		clr	bp
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage

		mov	ax, MSG_META_BLOCK_FREE
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		mov	dx, bx			; flag handle as library
		pop	cx, si
		jmp	closeHandle
		
unhookVM:
	;
	; Locate the root of the tree in the current file.
	; 
		push	si
		call	VMGetMapBlock
		call	VMLock
		mov	es, ax
		movdw	axsi, es:[PVMMB_root]
		call	VMUnlock
		call	VMVMBlockToMemBlock	; ax <- handle
	;
	; Remove the root from our own generic tree.
	; 

		push	bx
		mov_tr	bx, ax
		mov	ax, MSG_GEN_REMOVE
		mov	dl, VUM_NOW
		clr	bp			; don't mark dirty
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
	;
	; Close the file it's in.
	; 
		pop	cx
		pop	si		; *ds:si <- us
		clr	dx		; flag VM file
closeHandle:
	;
	; Now flush all the queues before sending ourselves a message to close
	; the handle in whatever way is appropriate. Note that even if the
	; block in which we sit is going away, the META_BLOCK_FREE sent to
	; the dialog in which we sit will also be routing things through the
	; same event queues, so we are guaranteed to receive the message to
	; close the file/unload the library before we bite the big one.
	; 
		mov	ax, MSG_PC_CLOSE_HANDLE
		mov	bx, ds:[LMBH_handle]
		mov	di, mask MF_RECORD
		call	ObjMessage		; record message to send back

		mov	dx, bx			; dx <- block for which flush
						;  is to occur
		mov	cx, di			; cx <- event
		clr	bp			; bp <- start at the beginning
		mov	ax, MSG_META_OBJ_FLUSH_INPUT_QUEUE
		call	ObjCallInstanceNoLock
done:
		.leave
		ret
PrefContainerCloseActiveFile endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefContainerCloseHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close a handle we opened, as appropriate to its type.

CALLED BY:	MSG_PC_CLOSE_HANDLE
PASS:		*ds:si	= PrefContainer object
		cx	= affected handle
		dx	= non-zero if it's a library handle. 0 if it's a
			  VM file
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 6/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefContainerCloseHandle method dynamic PrefContainerClass, MSG_PC_CLOSE_HANDLE
		.enter
		mov	bx, cx

		tst	dx
		jnz	isLibrary

		mov	al, FILE_NO_ERRORS
		call	VMClose
done:
		.leave
		ret

isLibrary:
		call	GeodeFreeLibrary
		jmp	done
PrefContainerCloseHandle endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefContainerGenPathSet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Field a command to open another file.

CALLED BY:	MSG_GEN_PATH_SET
PASS:		*ds:si	= PrefContainer object
		cx:dx	= null-terminated pathname
		bp	= disk handle of path
RETURN:		carry set if path couldn't be set
			ax	= FileError
		carry clear if path successfully set
			ax	= destroyed
DESTROYED:	cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 4/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefContainerGenPathSet method dynamic PrefContainerClass, MSG_GEN_PATH_SET
diskHandle	local	word	push	bp
pathBuf		local	PathName
fileName	local	fptr
	ForceRef	fileName	; manipulated by subroutines
		.enter
	;
	; Split the path into leading components and final component.
	; 
		call	PrefContainerSplitAndComparePath

		cmp	al, PCT_EQUAL
		je	done		; => no need to do anything, as file
					;  is already open (carry clear)
	;
	; Change to the directory holding the file.
	; 
		push	bp
		mov	cx, ss
		lea	dx, ss:[pathBuf]
		mov	bp, ss:[diskHandle]
		mov	ax, MSG_GEN_PATH_SET
		mov	di, offset PrefContainerClass
		call	ObjCallSuperNoLock
		pop	bp
		jc	done
	;
	; Close the old file, if any, as we're pretty much committed.
	; 
		call	PrefContainerCloseActiveFile
	;
	; Now open the new one.
	; 
		call	PrefContainerOpenNewFile
		jc	done
	;
	; Set our moniker, if appropriate.
	; 
		call	PrefContainerBuildMoniker
	;
	; Hook the tree in as our only generic child.
	; 
		call	PrefContainerLoadTree
done:		
		.leave
		ret
PrefContainerGenPathSet endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefContainerSplitAndComparePath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Split the passed path into leading components and filename
		and see if it's the same as what we've already got open, as
		we'd rather avoid excessive flashing.

CALLED BY:	(INTERNAL) PrefContainerGenPathSet
PASS:		*ds:si	= PrefContainer object
		ss:bp	= inherited stack frame
		cx:dx	= path being set
RETURN:		al	= PCT_EQUAL if same path being set
			= PCT_UNRELATED if different path being set
		ss:[pathBuf] = leading components
		ss:[fileName] = points to final component of path
DESTROYED:	bx, cx, dx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 4/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefContainerSplitAndComparePath proc	near
		class	PrefContainerClass
		uses	es
		.enter	inherit	PrefContainerGenPathSet
	;
	; First split the thing into two pieces.
	; 
		push	ds, si
		movdw	dssi, cxdx	; ds:si <- source path
		segmov	es, ss
		lea	di, ss:[pathBuf]; es:di <- dest buffer
saveCompStart:
		mov	bx, si		; ds:bx <- start of this component
getChar:
		LocalGetChar ax, dssi
		LocalPutChar esdi, ax
		LocalCmpChar ax, '\\'	; end of component?
		je	saveCompStart	; yes -- record start of next
		LocalIsNull ax		; end of path?
		jnz	getChar		; no -- keep looping
	;
	; Record the start of the final component in ss:[fileName] for
	; later use.
	; 
		movdw	ss:[fileName], dsbx
	;
	; Terminate the leading components before the final component, being
	; careful about name being in root directory.
	; 
		dec	bx		; point to presumed backslash
DBCS <		dec	bx						>
		sbb	bx, si		; bx <- negative distance to final
					;  separator
		pop	ds, si		; *ds:si <- object

		lea	bx, es:[di][bx]	; bx <- corresponding place in pathBuf
		lea	di, ss:[pathBuf]; di <- start again, so...
		cmp	bx, di		;  ...we can compare the two
		jb	compareFileNames ; => no backslash
		ja	nullTermAndComparePaths	; => not root
		inc	bx		; leave leading backslash, please
DBCS <		inc	bx						>
nullTermAndComparePaths:
SBCS <		mov	{char}es:[bx], 0				>
DBCS <		mov	{wchar}es:[bx], 0				>
	;
	; Now the path is split, make sure we've actually got a file open,
	; which is the only thing that makes this comparison worthwhile (this
	; also ensures we've actually got a path set.
	; 
		mov	bx, ds:[si]
		add	bx, ds:[bx].PrefContainer_offset
		tst	ds:[bx].PCI_handle
		jz	setNew
	;
	; Now fetch path currently bound to the object.
	; 
		mov	ax, ATTR_GEN_PATH_DATA
		mov	dx, TEMP_GEN_PATH_SAVED_DISK_HANDLE
		call	GenPathFetchDiskHandleAndDerefPath
		tst	ax
		jz	setNew
	;
	; Compare that path with the one we've now got in pathBuf
	; (es:di = pathBuf).
	; 
		push	si
		lea	si, ds:[bx].GFP_path	; ds:si <- path
		mov_tr	cx, ax			; cx <- disk handle
		
		mov	dx, ss:[diskHandle]	; dx <- disk for es:di
		call	FileComparePaths
		pop	si
		
		cmp	al, PCT_EQUAL
		jne	setNew

compareFileNames:
	;
	; Paths match. Check up on the filename.
	; 
		push	si
		call	PC_DerefDI
		lea	si, ds:[di].PCI_fileName	; ds:si <- src string
		les	di, ss:[fileName]		; es:di <- dst string
compareNameLoop:
		LocalGetChar ax, dssi
SBCS <		scasb							>
DBCS <		scasw							>
		jne	popSISetNew
		LocalIsNull ax			; end of string?
		jnz	compareNameLoop		; nope.
			CheckHack <PCT_EQUAL eq 0>
		pop	si
done:
		.leave
		ret
popSISetNew:
		pop	si
setNew:
		mov	al, PCT_UNRELATED
		jmp	done
PrefContainerSplitAndComparePath endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefContainerOpenNewFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy the name into our instance data and open the beast.

CALLED BY:	(INTERNAL) PrefContainerGenPathSet
PASS:		*ds:si	= PrefContainer object
		ss:bp	= inherited stack frame
RETURN:		carry set on error:
			ax	= FileError
			bx	= destroyed
		carry clear on success:
			bx	= VM file handle
			ax	= destroyed
DESTROYED:	cx, dx, di
SIDE EFFECTS:	PCI_handle set on success
     		PCI_fileName set on success or failure
		object added to the PDGCNLT_DIALOG_CHANGE list

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 4/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefContainerOpenNewFile proc	near
		class	PrefContainerClass
		.enter	inherit	PrefContainerGenPathSet
	;
	; Copy the new name in. Even if the open fails, PCI_handle is
	; 0, so we'll overwrite the data the next time someone tells us to
	; open the thing.
	; 
		push	si, ds
		segmov	es, ds
		call	PC_DerefDI
		add	di, offset PCI_fileName
		mov	dx, di			; save for open
		lds	si, ss:[fileName]
		mov	cx, length PCI_fileName
nameCopyLoop:
		LocalGetChar ax, dssi
		LocalPutChar esdi, ax
		LocalIsNull ax
		loopnz	nameCopyLoop
		pop	si, ds
		jnz	badName		; => name too long
	;
	; Push to the directory we set, please.
	; 
		call	FilePushDir
		push	dx
		mov	ax, ATTR_GEN_PATH_DATA
		mov	dx, TEMP_GEN_PATH_SAVED_DISK_HANDLE
		call	GenPathSetCurrentPathFromObjectPath
		pop	dx
	;
	; Now open the file read-only.
	; 
		mov	ax,  (VMO_OPEN shl 8) or mask VMAF_FORCE_READ_ONLY or \
				mask VMAF_FORCE_DENY_WRITE
		call	VMOpen
		jc	checkLibrary
	;
	; Make sure the protocol is ok.
	; 
		mov	cx, size ProtocolNumber
		sub	sp, cx
		segmov	es, ss
		mov	di, sp
		mov	ax, FEA_PROTOCOL
		call	FileGetHandleExtAttributes
		pop	ax, cx
		CheckHack <PN_major eq 0 and PN_minor eq 2 and \
			   ProtocolNumber eq 4>
		cmp	cx, PREFVM_DOC_PROTO_MAJOR
		jne	closeFail
		cmp	ax, PREFVM_DOC_PROTO_MINOR
		ja	closeFail
	;
	; Everything peachy. Save the handle away and add ourselves to the
	; dialog's GCN list.
	; 
		call	PC_DerefDI
fileOpen:
		mov	ds:[di].PCI_handle, bx
		
		mov	ax, MSG_META_GCN_LIST_ADD
		call	PrefContainerManipGCNList
		clc
done:
		call	FilePopDir
		.leave
		ret

closeFail:
		mov	al, FILE_NO_ERRORS
		call	VMClose
		mov	ax, ERROR_FILE_FORMAT_MISMATCH
error:
		stc
		jmp	done
badName:
		mov	ax, ERROR_INVALID_NAME
		jmp	error
checkLibrary:
		cmp	ax, VM_OPEN_INVALID_VM_FILE
		je	tryLibraryLoad

		mov_tr	bx, ax
		mov	ax, ERROR_SHARING_VIOLATION
		cmp	bx, VM_SHARING_DENIED
		je	error
		
		mov	ax, ERROR_FILE_NOT_FOUND
		cmp	bx, VM_FILE_NOT_FOUND
		je	error

		mov	ax, ERROR_FILE_FORMAT_MISMATCH
		cmp	bx, VM_FILE_FORMAT_MISMATCH
		je	error
		
		mov	ax, ERROR_GENERAL_FAILURE
		jmp	error

tryLibraryLoad:
	;
	; Kernel didn't think much of that supposed VM file, so see if it'll
	; load the beastie as a library.
	; 
		push	si
		mov	si, dx			; ds:si <- lib name
		mov	ax, PREF_MODULE_PROTO_MAJOR
		mov	bx, PREF_MODULE_PROTO_MINOR
		call	GeodeUseLibrary		; bx <- geode handle, if ok
		pop	si

		mov	ax, ERROR_GENERAL_FAILURE
		jc	error			; nope.
	;
	; Note that we've got a library, by setting the handle portion of the
	; dupRoot variable non-zero, so we know to query the beast for its
	; UI tree, rather than looking at the map block.
	; 
		call	PC_DerefDI
		mov	ds:[di].PCI_dupRoot.handle, 1
		jmp	fileOpen
PrefContainerOpenNewFile endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefContainerBuildMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Build a moniker for ourselves from the template provided.

CALLED BY:	(INTERNAL) PrefContainerGenPathSet
PASS:		*ds:si	= PrefContainer
RETURN:		nothing
DESTROYED:	ax, cx, dx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 4/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefContainerBuildMoniker proc near
		class	PrefContainerClass
		uses	bx
		.enter
		call	PC_DerefDI
		mov	bx, ds:[di].PCI_templateMon
		tst	bx
		LONG jz	done
	;
	; Duplicate the template moniker.
	; 
		push	si
		ChunkSizeHandle	ds, bx, cx		
		mov	al, mask OCF_DIRTY
		call	LMemAlloc
		segmov	es, ds
		mov	si, ds:[bx]
		mov_tr	bx, ax
		mov	di, ds:[bx]
		rep	movsb
		pop	si
	;
	; Find the length of the text in the filename.
	; 
		call	PC_DerefDI
		add	di, offset PCI_fileName
		call	LocalStringSize	; cx = length w/o null
		push	cx
	;
	; Locate the \1 in the template moniker.
	; 
		mov	di, ds:[bx]
		test	ds:[di].VM_type, mask VMT_GSTRING
		jnz	popHaveNewMoniker
		mov	ax, 1		; ax <- 1
		mov	ds:[di].VM_width, 0	; nuke cached width while we've
						;  got the pointer
		ChunkSizePtr ds, di, cx
		add	di, offset VM_data + offset VMT_text
		sub	cx, offset VM_data + offset VMT_text
		
DBCS <		shr	cx, 1						>
		LocalFindChar

popHaveNewMoniker:
		pop	cx		; cx <- length of file name
		jne	haveNewMoniker	; => no \1, so nothing to insert
					;  (also jumps if moniker is gstring,
					;  not text)
	;
	; Insert enough room there in the moniker for the file name
	; 
		LocalPrevChar	esdi	; point to \1
		sub	di, ds:[bx]	; figure offset from base of chunk
					;  for insertion
		mov_tr	ax, di		; ax <- offset
		xchg	ax, bx		; ax <- chunk, bx <- offset
		dec	cx		; reduce by 1 to account for
					;  overwriting \1
DBCS <		dec	cx						>
		call	LMemInsertAt
	;
	; Now copy the text from the file name into the new moniker
	; 
		mov	di, bx
		mov_tr	bx, ax
		add	di, ds:[bx]	; es:di <- insertion point

		push	si
		mov	si, ds:[si]
		add	si, ds:[si].PrefContainer_offset
		add	si, offset PCI_fileName
DBCS <		shr	cx, 1						>
		inc	cx		; account for previous reduction
		LocalCopyNString
		pop	si
haveNewMoniker:
	;
	; Fetch the current moniker so we can free it once we've set
	; the new one.
	; 
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		push	ds:[di].GI_visMoniker
	;
	; And set the new one as the vis moniker for the beast.
	; 
		mov	cx, bx
		mov	dl, VUM_NOW
		mov	ax, MSG_GEN_USE_VIS_MONIKER
		push	bp
		call	ObjCallInstanceNoLockES
		pop	bp
	;
	; Now free the old moniker.
	; 
		pop	ax
		tst	ax
		jz	oldMonikerFreed
		call	LMemFree
oldMonikerFreed:
done:		
		.leave
		ret
PrefContainerBuildMoniker endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefContainerLoadTree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load the tree as our only generic child.

CALLED BY:	(INTERNAL) PrefContainerGenPathSet
PASS:		*ds:si	= PrefContainer object
		bx	= VM file handle of open file
RETURN:		nothing
DESTROYED:	ax, es, dx, cx, bx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 4/92 Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefContainerLoadTree proc	near
		class	PrefContainerClass
		uses	bp, si
		.enter
		call	PC_DerefDI
		tst	ds:[di].PCI_dupRoot.handle
		jnz	askLibrary
	;
	; Get the optr of the root object of the tree.
	; 
		call	VMGetMapBlock
		call	VMLock
		mov	es, ax
		movdw	axdx, es:[PVMMB_root]
		call	VMUnlock
		call	VMVMBlockToMemBlock
	;
	; Add the root as our first child.
	; 
		mov_tr	cx, ax
addChild:
		mov	bp, CCO_FIRST
		mov	ax, MSG_GEN_ADD_CHILD
		call	ObjCallInstanceNoLock
		movdw	bxsi, cxdx
	;
	; Tell it to initialize itself and load its options.
	; 
		mov	ax, MSG_PREF_INIT
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
	;
	; Release20X EC dies because es never gets set to NULL_SEGMENT.  Do it
	; here to make things work.
	;
EC <		segmov	es, NULL_SEGMENT, ax				>

		mov	ax, MSG_META_LOAD_OPTIONS
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
	;
	; Set the root usable, finally. (done after init/load_options so
	; the child has a chance to add any hairy controllers to various
	; GCN lists in the application object before they get set usable.)
	; 
		mov	ax, MSG_GEN_SET_USABLE
		mov	dl, VUM_NOW
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		.leave
		ret

askLibrary:
	;
	; Call the library to get its tree of UI.
	; 
		mov	ax, PMET_FETCH_UI
		call	ProcGetLibraryEntry
		call	ProcCallFixedOrMovable	; ^ldx:ax <- root
	;
	; Now duplicate the resource it returned.
	; 
		push	ax			; save chunk handle

		call	GeodeGetProcessHandle
		mov_tr	ax, bx			; ax <- owner
		mov	bx, dx			; bx <- block to duplicate
		clr	cx			; run by this thread
		call	ObjDuplicateResource	; bx <- new block
		mov	cx, bx
		pop	dx			; ^lcx:dx <- root of tree
	;
	; Save the thing so we know we need to destroy it when we go away.
	; 
		call	PC_DerefDI
		movdw	ds:[di].PCI_dupRoot, cxdx
		jmp	addChild
PrefContainerLoadTree endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefContainerManipGCNList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Manipulate our containing PrefDialog object's notification
		list, so we know to close the VM file before the box
		gets destroyed.

CALLED BY:	(INTERNAL) PrefContainerOpenNewFile,
			   PrefContainerCloseActiveFile
PASS:		*ds:si	= PrefContainer object
		ax	= message to send (MSG_META_GCN_LIST_ADD or
			  MSG_META_GCN_LIST_REMOVE)
RETURN:		nothing
DESTROYED:	ax, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 4/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefContainerManipGCNList proc near
		class	PrefContainerClass
		uses	bx, cx, dx, bp
		.enter
	;
	; Record message for the PrefDialog object.
	; 
		mov	dx, size GCNListParams
		sub	sp, dx
		mov	bp, sp
		mov	bx, ds:[LMBH_handle]
		movdw	ss:[bp].GCNLP_optr, bxsi
		mov	ss:[bp].GCNLP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
		mov	ss:[bp].GCNLP_ID.GCNLT_type, PDGCNLT_DIALOG_CHANGE
		mov	bx, segment PrefDialogClass
		push	si
		mov	si, offset PrefDialogClass
		mov	di, mask MF_RECORD or mask MF_STACK
		call	ObjMessage
		pop	si
		add	sp, size GCNListParams
	;
	; Now ship the thing up the tree.
	; 
		mov	cx, di
		mov	ax, MSG_GEN_GUP_CALL_OBJECT_OF_CLASS
		call	GenCallParent
		.leave
		ret
PrefContainerManipGCNList endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefContainerNotifyDialogChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take note that the dialog in which we're located is
		changing state

CALLED BY:	MSG_PREF_NOTIFY_DIALOG_CHANGE
PASS:		*ds:si	= PrefContainer object
		cx	= PrefDialogChangeType
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		if change type is PDCT_DESTROY, PDCT_SHUTDOWN or PDCT_RESTART,
		we need to close the VM file and uproot its tree.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 4/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefContainerNotifyDialogChange method dynamic PrefContainerClass, 
				  	MSG_PREF_NOTIFY_DIALOG_CHANGE
		.enter
		cmp	cx, PDCT_DESTROY
		jb	done

		CheckHack <PDCT_SHUTDOWN gt PDCT_DESTROY and \
			   PDCT_RESTART gt PDCT_DESTROY and \
			   PrefDialogChangeType eq PDCT_SHUTDOWN+1>
		call	PrefContainerCloseActiveFile
done:
		.leave
		ret
PrefContainerNotifyDialogChange endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefContainerMakeApplyable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If dialog box is sitting inside another dialog, forcibly
		continue the travel of a MSG_GEN_MAKE_APPLYABLE message
		to the parent object.

CALLED BY:	MSG_GEN_MAKE_APPLYABLE
PASS:		*ds:si	= PrefContainer object
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefContainerMakeApplyable method dynamic PrefContainerClass, MSG_GEN_MAKE_APPLYABLE
	.enter
	mov	di, offset PrefContainerClass
	call	ObjCallSuperNoLock

	;
	; If we're a dialog, we need to forcibly pass the thing to our parent,
	; as our superclass won't...
	; 
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	cmp	ds:[di].GII_visibility, GIV_DIALOG
	jne	done
	
	mov	ax, MSG_GEN_MAKE_APPLYABLE
	call	GenCallParent
done:
	.leave
	ret
PrefContainerMakeApplyable endm

