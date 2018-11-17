COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		gfsMapPath.asm

AUTHOR:		Adam de Boor, Apr 14, 1993

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	4/14/93		Initial revision


DESCRIPTION:
	The biggest part of this whole thing: mapping a path to a directory
	entry.
		

	$Id: gfsMapPath.asm,v 1.1 97/04/18 11:46:27 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Movable	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSMapPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Map a path name to a GFSDirEntry

CALLED BY:	EXTERNAL
PASS:		ds:dx	= path to map
		exclusive access to the device
RETURN:		carry set on error:
			ax	= FileError
			ds	= destroyed
		carry clear if ok:
			ds		= dgroup
			gfsDirEntry	= set to entry of thing found
			gfsExtAttrs	= set to address of extended attrs
					  of thing found
			ax	= destroyed
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	if first char of path is \
		dir offset = root dir offset
		num ents = # root dir ents
		path++
	else
		lock cur path
		dir offset = FP_private.GPP_dirEnts
		num ents = FP_private.GPP_size
		unlock cur path
	fi

	while (*path != '\0') {
		find end of component
		if component is valid DOS name, map to 8/3 space-padded,
		    upcased form (XXX: need call in primary IFS driver to
		    perform this)
		GFSDevMapDir(diroffset, num ents)
		foreach entry:
			if component valid DOS name and matches GDE_dosName,
				break
			if GDE_longName matches component,
				break
		hcaerof
		if not found,
			GFSDevUnmapDir()
			return PATH_NOT_FOUND if components left or looking
			    for dir, or FILE_NOT_FOUND if no components left
		fi
		if components left,
			if found entry is link,
				build FSPathLinkData
				GFSDevUnmapDir()
				return LINK_ENCOUNTERED
			else if found entry not dir,
				GFSDevUnmapDir()
				return PATH_NOT_FOUND
			else
				dir offset = GDE_data
				num ents = GDE_size
			fi
		else
			copy GFSDirEntry to global var & compute location
			of its extended attributes, storing that in a global
			var.
		fi
		GFSDevUnmapDir()
		path = componentEnd + (*componentEnd ? 1 : 0)
	}


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/14/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSMapPath	proc	far
component	local	fptr.TCHAR	; start of current component \
		push	ds, dx
componentEnd	local	word		; offset of end of current component
componentLen	local	word		; number of chars, excluding backslash
					;  or null
dirOffset	local	dword		; address of entries for dir being
					;  searched
numEnts		local	word		; number of entries in the dir being
					;  searched
dosName		local	GFSDosName	; component name mapped to DOS
					;  character set, w/o ., space padded,
					;  and all uppercase.
		uses	bx, cx, dx, si, di, es
		.enter

if ERROR_CHECK
	;
	; Validate that the path is not in a movable code segment
	;
FXIP<	push	bx, si							>
FXIP<	mov	bx, ds							>
FXIP<	mov	si, dx							>
FXIP<	call	ECAssertValidFarPointerXIP				>
FXIP<	pop	bx, si							>
endif

	;------------------------------------------------------------
	;			SETUP
	;
	;
	; See if passed path is absolute or relative.
	; 
		mov	si, dx
		LocalCmpChar	ds:[si], C_BACKSLASH	; absolute?
		jne	getCurDir
	;
	; Absolute. Start mapping from the root directory, skipping over the
	; initial backslash.
	;

		segmov	es, dgroup, ax
if _PCMCIA
	;
	; The PCMCIA driver doesn't keep the root directory in dgroup,
	; so read it in now 
	;
		lea	di, ss:[gfsLastFound]
		mov	ax, size GFSFileHeader
		mov	cx, size GFSDirEntry
		cwd
		call	GFSDevRead
		movdw	ss:[dirOffset], es:[gfsLastFound].GDE_data, ax
		mov	ax, es:[gfsLastFound].GDE_size.low
		mov	ss:[numEnts], ax
else
		movdw	ss:[dirOffset], es:[gfsRootDir].GDE_data, ax
		mov	ax, es:[gfsRootDir].GDE_size.low
		mov	ss:[numEnts], ax
endif
		LocalNextChar	dssi
		LocalIsNull	ds:[si]
		jne	componentLoop
	;
	; Looking for the root directory, so copy the relevant data on it to
	; the global vars we use for return.
	; 
		segmov	ds, es			; dgroup
if _PCMCIA
	;
	; The offset to the root EA isn't stored in dgroup, so
	; calculate it now.  Also, we already read the root dir information
	; into gfsLastFound, so no need to do it here.
	;
		mov	ds:[gfsLastFoundEA].low,
			size GFSFileHeader+size GFSDirEntry
		clr	ds:[gfsLastFoundEA].high
else
		mov	si, offset gfsRootDir
		mov	di, offset gfsLastFound
		mov	cx, size GFSDirEntry
		rep	movsb
		movdw	ds:[gfsLastFoundEA], ds:[gfsRootEA], ax
endif
		clc
		jmp	done

mapAsCurrentDir:
		call	GFSMPMapAsCurrentDir
		jmp	done
	
getCurDir:
	;
	; Path is relative, so fetch the directory offset and size from the
	; private data we stored in the current path block.
	; 
		mov	bx, ss:[TPD_curPath]
		call	MemLock
		mov	es, ax

		LocalIsNull	ds:[si]		; handle special case of
						;  null path, interpreting
						;  it to mean the current
						;  directory
		je	mapAsCurrentDir

		movdw	ss:[dirOffset], \
			({GFSPathPrivate}es:[FP_private]).GPP_dirEnts, \
			ax
		mov	ax, ({GFSPathPrivate}es:[FP_private]).GPP_size
		mov	ss:[numEnts], ax
		call	MemUnlock

	;------------------------------------------------------------
	;		ISOLATE AND LOCATE CURRENT COMPONENT
componentLoop:
	;
	; Find the end of the next component (null or path separator).
	; 
		mov	dx, si			; save component start
findEndLoop:
		LocalGetChar	ax, dssi
		LocalCmpChar	ax, C_BACKSLASH
		je	foundEnd
		LocalIsNull	ax
		jnz	findEndLoop
foundEnd:
		LocalPrevChar	dssi		; back up to term char
EC <		cmp	dx, si			; anything in the component?>
EC <		ERROR_E CANNOT_MAP_ZERO_LENGTH_NAME			>
	;
	; Try and map the component to a DOS name via the primary FS driver
	; 
		mov	cx, si
		sub	cx, dx			; cx <- # chars
DBCS <		shr	cx			; cx <- # chars		>
		mov	ss:[component].offset, dx	; segment never changes
		mov	ss:[componentEnd], si
		mov	ss:[componentLen], cx
		segmov	es, ss
		lea	si, ss:[dosName]	; store in dosName var
		mov	di, DR_DPFS_MAP_TO_DOS
		push	bp
		call	GFSCallPrimary
		pop	bp
		jnc	mapDir
		mov	ss:[dosName], '\0'	; ensure no match, as not DOS
						;  name
mapDir:
	;
	; Map/load the entries for the current directory.
	; 
		movdw	dxax, ss:[dirOffset]
		mov	cx, ss:[numEnts]
		jcxz	notFoundNotMapped	; don't map empty directory.
		call	GFSDevMapDir		; es:di <- first entry
		jc	done

entryLoop:
		push	cx			; save # entries left
	;
	; First check the longnames since we have es:di pointing to the one
	; in the dir entry. Recall that GDE_longName is only null-terminated
	; if it contains fewer than 32 characters.
	; 
		push	di
		CheckHack <offset GDE_longName eq 0>
		lds	si, ss:[component]
		mov	cx, ss:[componentLen]	; cx <- # chars to compare
compareLongNameLoop:
		LocalGetChar	ax, dssi
SBCS <		scasb							>
DBCS <		scasw							>
		loope	compareLongNameLoop
	;
	; Hit end of component or mismatch.
	; 
		jne	compareLongNameDone	; => mismatch

	    ; end of component. See if there's supposed to be a null at es:di
		cmp	ss:[componentLen], length GFSLongName
		je	compareLongNameDone

	    ; there is supposed to be, so see if there is one.
		LocalIsNull	es:[di]
compareLongNameDone:
		pop	di
		je	foundIt
	;
	; Didn't match in the long name, so try the DOS name. Easier here, as
	; everything's space padded...
	; 
		push	di
		add	di, offset GDE_dosName
		mov	cx, length GDE_dosName
		segmov	ds, ss
		lea	si, ss:[dosName]
		repe	cmpsb
		pop	di
		je	foundIt
	;
	; This isn't the one.
	; 
		pop	cx			; cx <- # entries
		add	di, size GFSDirEntry
		loop	entryLoop
	;
	; Not found. Belch.
	; 
notFound:
		call	GFSDevUnmapDir

notFoundNotMapped:
		mov	ds, ss:[component].segment
		mov	si, ss:[componentEnd]
		mov	ax, ERROR_PATH_NOT_FOUND
		cmp	{char}ds:[si], 0
		jne	returnErr
		mov	ax, ERROR_FILE_NOT_FOUND
returnErr:
		stc
done:
		.leave
		ret

	;------------------------------------------------------------
	;			COMPONENT FOUND
	;
	; on stack: # entries left in dir, including this one
foundIt:
	; Found this component. Now deal with it.
	; 
		mov	ds, ss:[component].segment
		mov	si, ss:[componentEnd]
		LocalIsNull	ds:[si]
		je	finalComponent
	;
	; Component is internal, not the final one of the path.
	; If the found thing is a link, build up the requisite structure and
	; return an error.
	; 
		test	es:[di].GDE_attrs, mask FA_LINK
		jz	ensureDirectory
		call	GFSMPReadLink		; bx <- locked block
		call	GFSDevUnmapDir		; release current dir
		mov	ax, ERROR_LINK_ENCOUNTERED
		jmp	returnErr

ensureDirectory:
	;
	; Make sure inner component is a directory.
	; 
		test	es:[di].GDE_attrs, mask FA_SUBDIR
		jz	notFound	; pretend it's not found, as that's
					;  what DOS does...
	;
	; Load our variables from the parameters for the directory.
	; 
		movdw	ss:[dirOffset], es:[di].GDE_data, ax
		mov	ax, es:[di].GDE_size.low
		mov	ss:[numEnts], ax
		pop	cx		; discard # entries left in this dir
	;
	; Unmap current dir, advance the component pointer, and loop
	; 
		call	GFSDevUnmapDir
		mov	ds, ss:[component].segment
		mov	si, ss:[componentEnd]
		LocalNextChar	dssi	; skip backslash
		jmp	componentLoop

	;------------------------------------------------------------
	; 		FOUND FINAL COMPONENT
	;
	; on stack: # entries left in dir, including this one
finalComponent:
	;
	; Hit the final component in the path. Copy its data into global
	; vars.
	; 
		segmov	ds, es
		mov	si, di			; ds:si <- dir entry
		segmov	es, dgroup, di
		mov	di, offset gfsLastFound	; es:di <- global var
		mov	cx, size GFSDirEntry
		rep	movsb
	    ;
	    ; Compute the location of the extended attributes for the file.
	    ; 
	    	pop	bx			; bx <- # entries left
		mov	cx, ss:[numEnts]
		sub	bx, cx
		neg	bx			; bx <- entry # for this one
		movdw	dxax, ss:[dirOffset]
		call	GFSDevLocateEA		; dxax <- ea address
		
		movdw	es:[gfsLastFoundEA], dxax
		segmov	ds, es			; ds <- dgroup (for return)
		call	GFSDevUnmapDir
		clc
		jmp	done
GFSMapPath	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSMPMapAsCurrentDir
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Received a null path, which we treat as asking for the
		current dir, for one reason or another (e.g. trying to
		get the attributes of a standard path requires it)

CALLED BY:	(INTERNAL) GFSMapPath
PASS:		es	= locked current path block
		bx	= handle of same
		ss:bp	= inherited stack frame
RETURN:		carry set on error
			ax	= FileError
		carry clear if gfsLastFound/gfsLastFoundEA setup
			ax	= destroyed
		path block unlocked
		ds	= dgroup
DESTROYED:	si, di, es, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/21/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSMPMapAsCurrentDir proc	near
		.enter	inherit GFSMapPath
	;
	; Manufacture the GFSDirEntry for the thing from its extended attributes
	; 
		segmov	ds, dgroup, ax
	;
	; Store the offset of the thing's data in gfsLastFound.GDE_data
	; 
		movdw	ds:[gfsLastFound].GDE_data, \
			({GFSPathPrivate}es:[FP_private]).GPP_dirEnts, \
			ax
	;
	; Store the address of its extended attributes in gfsLastFoundEA, then
	; map them into memory.
	; 
		movdw	dxax, ({GFSPathPrivate}es:[FP_private]).GPP_attrs
		movdw	ds:[gfsLastFoundEA], dxax
		call	GFSDevMapEA		; es:di <- the ea
		jc	done
	;
	; Now copy in the bulk of the stuff: the longname, dosname, and file
	; attributes.
	; 
			CheckHack <GDE_longName eq GEA_longName>
			CheckHack <GDE_dosName eq GEA_dosName>
			CheckHack <GDE_attrs eq GEA_attrs>
			CheckHack <GDE_data eq GDE_attrs + size GDE_attrs>
		segxchg	ds, es		; es <- dgroup, ds <- ea
		mov	si, di
		mov	di, offset gfsLastFound
		mov	cx, offset GDE_data
		rep	movsb
	;
	; Now set up the size.
	; 
		segmov	ds, es		; ds <- dgroup again
		mov	ax, ss:[numEnts]
		mov	ds:[gfsLastFound].GDE_size.low, ax
		mov	ds:[gfsLastFound].GDE_size.high, 0
	;
	; Finally, the file type, which we know to be GFT_DIRECTORY.
	; 
		mov	ds:[gfsLastFound].GDE_fileType, GFT_DIRECTORY
	;
	; Release the extattrs and return carry clear with ds = dgroup
	; 
		call	GFSDevUnmapEA
		clc
done:
	;
	; Unlock the current path block. For better or for worse, we're done.
	; 
		call	MemUnlock
		.leave
		ret
GFSMPMapAsCurrentDir endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSMPReadLink
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read the data for a link into a FSPathLinkData block for
		return to the kernel

CALLED BY:	EXTERNAL
       		GFSMapPath
PASS:		es:di	= GFSDirEntry for the link
		ds:si	= char after link component (null or backslash)
RETURN:		carry clear if ok:
			bx	= handle of locked block
			ax	= destroyed
		carry set if not:
			ax	= FileError
DESTROYED:	cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/14/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSMPReadLink	proc	near
		uses	ds
tail		local	fptr	push	ds, si
tailSize	local	word
		uses	ds, si, es, di
		.enter
		clr	cx
computeTailSizeLoop:
		LocalGetChar	ax, dssi
		LocalIsNull	ax
		loopne	computeTailSizeLoop
		neg	cx		; include null, as that's not already
					;  in GLD_pathSize
DBCS <		shl	cx		; cx <- size			>
		mov	ss:[tailSize], cx

		call	GFSReadEntireLink
		jc	done
	;
	; Now convert the thing to an FSPathLinkData block. First, discard
	; the extra data, as we don't need it.
	; 
		mov	ax, ds:[GLD_diskSize]
		add	ax, ds:[GLD_pathSize]
		add	ax, ss:[tailSize]
		add	ax, size FSPathLinkData
		clr	cx
		call	MemReAlloc
		mov	ds, ax		; in case it moved...
		mov	es, ax

		mov	ax, ds:[GLD_diskSize]
		mov	cx, ds:[GLD_pathSize]	; remember this...
		mov	ds:[FPLD_targetSavedDiskSize], ax
			CheckHack <FPLD_targetSavedDisk eq GLD_savedDisk>
		add	ax, offset FPLD_targetSavedDisk
		movdw	ds:[FPLD_targetPath], dsax
	;
	; Copy the tail in.
	; 
		mov	di, ds:[FPLD_targetPath].offset
		add	di, cx
		lds	si, ss:[tail]
		LocalGetChar	ax, dssi
		LocalIsNull	ax
		jz	nullTerm	; nothing to copy in
EC <		LocalCmpChar	ax, C_BACKSLASH				>
EC <		ERROR_NE	TAIL_DOESNT_START_WITH_BACKSLASH	>
		LocalPrevChar	esdi
SBCS <		scasb			; does link target end in bs?	>
DBCS <		scasw			; does link target end in bs?	>
		je	copyTail	; yes -- don't add another
		LocalPutChar	esdi, ax	; no -- hand-copy separator
copyTail:
		mov	cx, ss:[tailSize]; cx <- size of remaining, including
DBCS <		shr	cx		; cx <- length			>
		dec	cx		 ;  null
		LocalCopyNString
		clc			; happy happy happy
done:
		.leave
		ret
nullTerm:
		LocalPutChar	esdi, ax
		jmp	done
GFSMPReadLink	endp

Movable	ends
