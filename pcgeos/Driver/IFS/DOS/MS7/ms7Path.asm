COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	(c) Copyright Geoworks 1996.  All rights reserved.
			GEOWORKS CONFIDENTIAL

PROJECT:	
MODULE:		
FILE:		ms7Path.asm

AUTHOR:		Jim Wood, Dec 17, 1996

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimw	12/17/96   	Initial revision


DESCRIPTION:
		
	

	$Id: ms7Path.asm,v 1.1 97/04/10 11:55:40 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PathOps 	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSAllocOpCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a new file of the passed long name, probably with a
		geos header, but optionally not.

		This version of Create constructs the long name with
		embedded attributes whether or not the caller wants a
		native file.  In ms7, every file must have a long name.

CALLED BY:	DOSAllocOp
PASS:		ds:dx	= name of file to create
		es:si	= DiskDesc on which operation is being performed
		ch	= FileCreateFlags
		cl	= FileAttrs
		al	= FileAccessFlags
RETURN:		carry set if couldn't create:
			ax	= error code
		carry clear if ok:
			al	= SFN
			ah	= 0 (not device)
			dx	= data private to the FSD
DESTROYED:	ds, bx, cx (assumed preserved by DOSAllocOp)

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSAllocOpCreate proc	near
accessFlags		local 	word	push	ax		
diskSegment		local	word	push	es
diskHandle		local 	word	push	si		
sfn			local	word
privateData		local	word
		
		uses 	es, di, si
		.enter
if ERROR_CHECK
	;
	; Validate that the name string is not in a movable code segment
	;
FXIP<		push	bx, si						>
FXIP<		mov	bx, ds						>
FXIP<		mov	si, dx						>
FXIP<		call	ECAssertValidFarPointerXIP			>
FXIP<		pop	bx, si						>
endif

		clr	ss:[sfn]
		clr	ss:[privateData]
	;
	; Map the path name to a DOS file, if possible. If the mapping
	; succeeds, it's an error. In the normal case, it'll map all the
	; way to the final component and return ERROR_FILE_NOT_FOUND.
	; 
		call	DOSVirtMapFilePath
		jc	checkMapError
		mov	ax, ERROR_FILE_EXISTS
returnError:
		stc
		jmp	done
checkMapError:
		cmp	ax, ERROR_FILE_NOT_FOUND
		jne	returnError	; => couldn't map intervening
					;  directories, so can't create
	;
	; We don't create files with 8.3 names anymore.  Even a native file
	; must be have a name that contains a NATIVE signature, so we can
	; always quickly tell that there is no extended attribute info.
	; 
		test	ch, mask FCF_NATIVE
		LONG jz	handleGeosCreate
	;
	; Create the native file.  Generate the special long native name and
	; create it.  Don't add the GeosFileHeader.
	;
		call	PathOps_LoadVarSegES		; es <- dgroup
		lds	dx, es:[dosFinalComponent]
		call	DOS7GenerateNativeLongName	; dos7LongName filled
		mov_tr	ax, ss:[accessFlags]		; al <- FileAccessFlags
		push	es				; save dgroup
		segmov	es, ss:[diskSegment]
		call	DOSCreateNativeFile
		pop	ds				; ds dgroup
		jc	createNativeError

		mov	ss:[sfn], ax
		mov	ss:[privateData], dx
generateNotify:
	;
	; Figure the ID for the file (don't do this in DOSCreateNativeFile,
	; as that's used for creating @DIRNAME.000 and the like, where we don't
	; want to waste the time).
	;
	; dos7LongName has the long name already.
	;
		segmov	es, ds
	;
	; First get the path ID, which is used as the base of the file ID.
	;
		call	DOSFileChangeGetCurPathID	; cxdx <- path ID
		mov	ax, cx				; save high ID word
		mov	di, offset dos7LongName.MSD7GN_shortName
		mov	si, di				; es:di = ds:si
EC <		Assert	ne ax, 0					>
		call	DOS7UnPadShortName		; es:di fake dos name
		mov	cx, ax				; cxdx <- path ID
		push	cx, dx				; save for later
		call	DOSFileChangeCalculateIDLow
		mov	bx, ss:[privateData]		; ds:bx <-DFE
		movdw	ds:[bx].DFE_id, cxdx		; store file ID
	;
	; Generate a file-change notification for everyone to see.
	;
		pop	ax, dx				; ax:dx <- path ID
		mov	di, offset dos7LongName		; ds:bx <- file name
		mov	bx, di
EC <		Assert	ne ax, 0					>
		call	DOS7UnPadLongName
		mov	cx, ax				; cx:dx <- dirID
		mov	ax, FCNT_CREATE
		mov	si, ss:[diskHandle]
		call	FSDGenerateNotify
		clc					; happy
if _SFN_CACHE
	;
	; If we're creating this thing, then it needs to have its
	; path cached.
	;
		mov	bx, ss:[sfn]
		call	DOS7CachePathForSFN
		mov	ax, bx				; return the goodies
		mov	dx, ss:[privateData]
		clc
endif
done:
		.leave
		ret

createNativeError:
	;
	; Clean up private data after error, if we've initialized it
	;
		tst	ss:[privateData]
		jz	noPrivateData
		mov	bx, ss:[privateData]
		mov	ds:[bx].DFE_disk, 0
		mov	ds:[bx].DFE_flags, 0
noPrivateData:
		stc
		jc	done
		.UNREACHED

handleGeosCreate:
;;EC <		test	ch, mask FCF_NATIVE_WITH_EXT_ATTRS		>
;;EC <		ERROR_NZ MSDOS7_ERROR_UNSUPPORTED_FUNCTION		>
;;		jnz	validateLongNameAsNative
	;
	; Create the long name.  Results in dos7LongName set up for the kill.
	;
		call	PathOps_LoadVarSegES
		lds	dx, es:[dosFinalComponent]
		mov	ax, GFT_DATA
		call	DOS7GenerateGeosLongName	
	;
	; Now create and initialize the file.
	; 
		push	es			; save dgroup
		mov	es, ss:[diskSegment]
		mov	si, ss:[diskHandle]	; es:di DiskDesc
		mov	ax, ss:[accessFlags]	; ax <- FileAccessFlags
		call	DOSCreateNativeFile
		pop	ds			; ds <- dgroup
		jc	createNativeError	; => couldn't create, so bail
	;
	; (ds = dgroup)
	; Initialize the file as just regular data, until we're told otherwise.
	;
		mov	ss:[sfn], ax
		mov	ss:[privateData], dx
		les	di, ds:[dosFinalComponent]	; es:di geos longname
		mov	bx, dx
		ornf	ds:[bx].DFE_flags, mask DFF_GEOS
		mov	dx, GFT_DATA
		call	DOSInitGeosFile
		LONG 	jnc	generateNotify
		jmp	createNativeError	; => error during init

if 0
validateLongNameAsNative:
	;
	; Make sure the longname passed is identical to the DOS name. If it's
	; not, it doesn't cut the mustard. We allow differences in case,
	; though.
	; 
		call	PathOps_LoadVarSegDS
		tst	ds:[dosNativeFFD].FFD_name[0]
		
		jnz	createGeosUsingNativeName
		mov	ax, ERROR_INVALID_NAME
		stc
		jmp	done
endif
		
DOSAllocOpCreate endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOS7AllocOpOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Try to open the file using the passed longname (or short...).

CALLED BY:	DOSAllocOpOpen

PASS:		dos7FindData filled with complete longname
		es:si	= DiskDesc on which operation is being performed
		al	= FullFileAccessFlags
		bx	= 0 if we need to allocate a JFT slot,
 			  non-zero if we already have one allocated, in
			  which case we let the caller release it.
RETURN:	 	carry clear if success
			al	= SFN
			ah	= non-zero if open to device
			dx	= FSD-private data for the file
 		carry set if fail
			al 	= same FullFileAccessFlags

DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimw	12/16/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSAllocOpOpen	proc	near
		diskSeg		local	word push	es
		disk		local	word push	si
		access		local	word push	ax
		namePtrOffset 	local	word push	dx
		uses	bx,cx,si,di,bp,es,ds
		.enter
	
	;
	; Map the geos name to a DOS name.
	;
		call	DOSVirtMapFilePath
		WARNING_C MSDOS7_OPEN_FAILED
		LONG jc	done
	;
	; Map the passed name to the actual long name.  We could have
	; a Geos LongName or a DOS 8.3 name.  Either way, DOS7MapComponent
	; will find it.
	;
		call	PathOps_LoadVarSegES	; es <- dgroup
		segmov	ds, es			; ds, es <- dgroup
		mov	si, offset dos7FindData.W32FD_fileName
						; ds:si <- the file name
	;
	; Make sure there's a JFT slot open for us by allocating one. We pass
	; NIL as the SFN so it stays free, but we will have P'ed jftEntries, so
	; we're content.
	;
		mov	bx, NIL
		call	DOSAllocDosHandleFar
		mov	bx, ss:[access]		; bl <- access flags
		andnf	bl, not FAF_GEOS_BITS	; clr the bits we don't deal
		clr	cx			; attributes
		clr	di			; no alias hint
		mov	dx, MSDOS7COOA_OPEN	; there's gotta be a better...
		mov	ax, MSDOS7F_CREATE_OR_OPEN
		call	DOSUtilInt21			; ax <- handle
		jc	doneReleaseJFTSlot
	;
	; Do the equivalent of DOSAllocOpFinishOpen.  Heck.  let's just CALL
	; it.  We set this up so that it looks at the header to see what
	; it is.  In practice, we might be able to just use the other shme in
	; the longname to do the same thing.
	;
		mov	bx, ss:[access]				; access flags
	;
	; Set up the file type, which we can get from the long name...
	;
		lea	di, ds:[dos7FindData].W32FD_fileName.MSD7GN_type
		mov	dx, GFT_VM
		cmp	{word} ds:[di], GFT_VM_ASCII
		je	storeFlag

		mov	dx, GFT_DATA
		cmp	{word}ds:[di], GFT_DATA_ASCII
		je	storeFlag
		
		mov	dx, GFT_NOT_GEOS_FILE
storeFlag:
		mov	ds:[dosFileType], dx
		mov	es, ss:[diskSeg]
		mov	si, ss:[disk]
		call	DOSAllocOpFinishOpen
		jc	doneReleaseJFTSlot
		WARNING MSDOS7_OPEN_SUCCEEDED
		
done:		
		.leave
		ret


doneReleaseJFTSlot:
	;
	; Release the JFT slot we allocated.  Don't trash AX or BX. Leave
	; things in order for DOSVirtual* do give this a try.
	;
		push	ds
		call	PathOps_LoadVarSegDS
		VSem	ds, jftEntries
		pop	ds

		mov	dx, ss:[namePtrOffset]	; restore name so virt works
		mov	ax, ss:[access]
		stc
		jmp	done		
		
DOSAllocOpOpen	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOS7PathOpRenameFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Rename the file, if we can.

CALLED BY:	DOSPathOpRenameFile in MS7

PASS:		ds	= dgroup
		es:di	= name to which to rename it
		si	= disk handle
		dos7FindData filled with mapped source name
		CWD grabbed
RETURN:		carry set on error
			ax = error code
		carry clear on success
DESTROYED:	ax, dx


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimw	12/20/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSPathOpRenameFile	proc	far

		mov	dx, di
		mov	di, 1000
		call	ThreadBorrowStackSpace
		push	di
		mov	di, dx
		
diskHandle		local 	word 	push si
renameName		local 	MSDOS7GeosName
srcName			local	MSDOS7GeosName
srcAttrs		local	FileAttrs

		uses	bx,cx,dx,si,di,bp, ds, es
		.enter
	;
	; bail if file is read-only
	;
		mov	ax, ERROR_ACCESS_DENIED
		test	ds:[dos7FindData].W32FD_fileAttrs.low.low,\
								 mask FA_RDONLY
		clc
		LONG	jnz	error
		
		mov	al, ds:[dos7FindData].W32FD_fileAttrs.low.low
		mov	ss:[srcAttrs], al
	;
        ; Copy source file info locally.  Mapping the destination may
        ; dork the find data, so we copy now.
        ;
		push    es, di
		mov     si, offset dos7FindData.W32FD_fileName
		lea     di, ss:[srcName]
		segmov  es, ss
		mov     cx, size srcName
		rep     movsb
	;
	; See if the file name already exists.  Do nothing if it does.
	;
		segmov	es, ds			; es <- dgroup
		pop	ds, dx
		call	DOS7MapComponent
		LONG 	jnc	error
	;
	; Are we dealing with a directory?
	;
		test	ss:[srcAttrs], mask FA_SUBDIR
		jz	doFile
	;
	; Well well.  If we have stinky characters in the long name then
	; we'll need to store the stinkiness in an @dirname file.
	;
		segmov	es, ss
		lea	di, ss:[srcName]	; es:di <- source name
		mov	si, ss:[diskHandle]
		call	DOS7DealWithDirnameFile
		segxchg	ds, es
		xchg	di, dx
		jmp	doRename
doFile:
	;
	; Construct the new long name, which requires dosFinalComponent to
	; be set up.  Also check for attemp to rename dos file with a longname.
	;
		mov	di, dx			; es:di <- new name
		segxchg	es, ds			; ds <- dgroup
		LocalStrLength

		test	ss:[srcAttrs], FA_GEOS_FILE
		jnz	storeComponent

		mov	ax, ERROR_INVALID_NAME
		cmp	cx, DOS_DOT_FILE_NAME_LENGTH
		LONG	ja	error
		
storeComponent:
		segmov	ds:[dosFinalComponent].high, es
		mov	ds:[dosFinalComponent].low, dx
		mov	ds:[dosFinalComponentLength], cx	; length of str
		mov	bx, ds				; bx<- dgroup
		segmov	ds, ss
		segmov	es, ss
		lea	si, ss:[srcName]		
		lea	di, ss:[renameName]		; es:di <- long name
		call	DOS7CreateDestName
		segmov	ds, ss
		segmov	es, ss
		lea	dx, ss:[srcName]
		lea	di, ss:[renameName]
		call	DOS7BadCharReplace
doRename:
	;		
	; Now rename the damn thing. We have ds:dx <- old, es:di <- new.
	;
		mov	ax, MSDOS7F_RENAME_FILE
		call	DOSUtilInt21
		LONG jc	done

generateNotify::
	;
	; Generate a file change notification and rename the long name in
	; the geos file  header.
	;
		call	DOSFileChangeGetCurPathID	; cxdx <- path ID
		segmov	ds, ss				
		lea	si, ss:[srcName]		; ds:si <- source name
		mov	al, ss:[srcAttrs]
		test	al, mask FA_SUBDIR
		jnz	calcID
		
		call	DOS7GetGeosDOSName		; ds:si <- dos name
		segmov	es, ds
		mov	di, si
		mov	ah, -1				; Null it
		call	DOS7UnPadShortName
		mov	si, di
calcID:
		push	ax
		call	DOSFileChangeCalculateIDLow	; cxdx <- ID
		pop	ax
		test	al, mask FA_SUBDIR
		jz	renameFileHeader

		segmov	ds, es
		mov	bx, di
		jmp	doNotify
		
renameFileHeader:
		call	PathOps_LoadVarSegES		; es <- dgroup
		lea	si, ss:[renameName]	; ds:si <- longlong name
		call	DOS7RenameGeosFileHeader	; don't trash cx,dx
		lds	bx, es:[dosFinalComponent]		
doNotify:

		mov	si, ss:[diskHandle]
		mov	ax, FCNT_RENAME
		call	FSDGenerateNotify
		clc
		jmp	done
error:
		stc
done:
		.leave

		pop	dx
		pushf			; save carry
		tst	dx
		jz	afterStackReturn
		push	di
		mov	di, dx
		call	ThreadReturnStackSpace
		pop	di
afterStackReturn:
		popf			; restore carry
		ret
DOSPathOpRenameFile	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOS7DealWithDirnameFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deal with all the cruft associated with the at-dirname
		file that may or may not already exist for this directory,
		and that may or may not need to exist for the renamed
		directory.

CALLED BY:	DOSPathOpRenameFile

PASS:		es:di <- source name
		ds:dx <- rename name
		si    <- disk han
RETURN:		ds:dx <- rename name with illegal characters replaced
		carry clear if successful,
		carry set if failure

DESTROYED:	ax, bx, cx, si

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimw	2/21/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOS7DealWithDirnameFile	proc	near
sPtrSeg			local	word	push	es		
sPtrOff			local	word	push	di	; source name ptr
dPtrSeg			local	word	push	ds		
dPtrOff			local	word	push	dx	; dest name ptr
diskHan			local	word	push	si
realDestName		local	MSDOS7LongNameType
illegalDestName		local	word			; flag
		uses	es, di, ds, dx
		.enter
	;
	; Copy the dest name now in case it has illegal characters.
	; We need to keep the original name to put inside the header.
	;
		mov	ss:[illegalDestName], FALSE	; not yet
		mov	si, dx				; ds:si <- dest name
		segmov	es, ss
		lea	di, ss:[realDestName]
		LocalCopyString
	;
	; DOS7BadCharReplace will fix up bad chars in the dest, and let
	; us know if there were.
	;
		segmov	es, ss:[dPtrSeg]
		mov	di, ss:[dPtrOff]		; es:di <- dest name
		call	DOS7BadCharReplace	
		jnz	checkForDirnameFile

		mov	ss:[illegalDestName], TRUE	; bad chars!
		
checkForDirnameFile:
	; 
	; See if the source directory already has an @dirname file.  If it does
	; then we _have_ to copy the name to it, as it may have other
	; extended attributes in it.
	;
		mov	bx, NIL				; snag a dos handle
		call	DOSAllocDosHandleFar
		call	PathOps_LoadVarSegDS		; ds <- dgroup
		mov	dx, offset dos7FindData		; ds:dx <- find data
		mov	al, FA_WRITE_ONLY	
		call	DOSVirtOpenSpecialDirectoryFile	
		LONG jnc dirnameFileExists
	;
	; Nope.  Free the dos handle, then see if the dest name requires
	; an @dirname file. 
	;
		call	DOSFreeDosHandleFar
		cmp	ss:[illegalDestName], FALSE
		clc	
		je	done
	;
	; The dest file name requires an @dirname file.  CD to the dir
	; then create it.
	;
		push	ds				; dgroup
		mov	ds, ss:[sPtrSeg]
		mov	dx, ss:[sPtrOff]		; ds:dx <- source dir
		call	DOSInternalSetDir
		pop	ds				; dgroup
		
		call	FSDDerefInfo			; ax <- disk seg
		mov	es, ax
		mov	si, ss:[diskHan]		; es:si <- DiskDesc
		call	DOSPathCreateDirectoryFileCommon 	; al <- SFN
EC <		ERROR_C MSDOS7_CANT_CREATE_DIRNAME_FILE			>
NEC <		jc	popBack
	;
	; Initialize it.
	;
		mov	dx, GFT_DIRECTORY
		segmov	es, ss
		lea	di, ss:[realDestName]		
		call	DOSInitGeosFile
	;
 	; Close the file and release the DOS handle.
	;
		mov	bx, ax				; bx <- SFN
		call	DOSAllocDosHandleFar
		mov	ah, MSDOS_CLOSE_FILE
		call	DOSUtilInt21
		mov	bx, NIL
		call	DOSFreeDosHandleFar
		
NEC <popBack:								>
	;
	; Pop back up.
	;
		pushf
		segmov	ds, cs
		mov	dx, offset cs:poDotDotPath
FXIP<		clr	cx						>
FXIP<		call	SysCopyToStackDSDX				>
		call	DOSInternalSetDir
FXIP<		call	SysRemoveFromStack				>
EC <		ERROR_C	GASP_CHOKE_WHEEZE				>
		popf
done:
		.leave
		ret

dirnameFileExists:
	;
	; Position and write the name out. ax is the DOS handle.
	;
		mov_tr	bx, ax			bx <- file handle
		clr	cx
		mov	dx, offset GFH_longName
		mov	ax, (MSDOS_POS_FILE shl 8) or FILE_POS_START
		call	DOSUtilInt21

		segmov	es, ss
		lea	di, ss:[realDestName]
		mov	dx, di
		LocalStrSize
		inc	cx
		segmov	ds, es		; ds:dx <- name, cx <- length
		mov	ah, MSDOS_WRITE_FILE
		call	DOSUtilInt21
	;
	; Close the file again, being careful to save any error flag & code
	; from the write.
	; 
		pushf
		push	ax
		mov	ah, MSDOS_CLOSE_FILE
		call	DOSUtilInt21
		pop	ax
		popf

		mov	bx, NIL		; release the JFT slot (already nilled
					;  out by DOS itself during the close)
		call	DOSFreeDosHandleFar		
		jmp	done

DOS7DealWithDirnameFile	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSCreateNativeFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a file in the current directory with the long
		name found in dos7LongName, returning all the
		appropriate things for DR_FS_ALLOC_OP

CALLED BY:	DOSAllocOpCreate, DOSPathCreateDirectoryFileCommon
PASS:		dos7LongName set
		es:si	= DiskDesc on which the operation is being performed
		cl	= attributes for the file
		al	= FileAccessFlags
RETURN:		carry set on error:
			ax	= error code
			dx	= private data if we initialize it
				  0 if we haven't initialized it
		carry clear on success:
			al	= SFN
			ah	= 0 (not open to device)
			dx	= private data
		

DESTROYED:	ds, cx, bx (assumed saved by DOSAllocOp), di

		(ds:dx points to DOSFileEntry for this file)

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSCreateNativeFile proc far

		.enter

	;
	; Create the file whose name is in dos7LongName.
	; 
		call	PathOps_LoadVarSegDS
		tst	{byte}ds:[dos7LongName]
		jz	invalidName

		mov	bx, NIL			; allocate a DOS handle
		call	DOSAllocDosHandleFar	;  for our use

		mov	dx, offset dos7LongName	; ds:dx <- long name
	;
	; Use the long name create DOS function.
	; 
		push	cx			; save FileAttrs
		push	si
		mov	si, dx			; ds:si <- filename
		mov	dx, MSDOS7COOA_CREATE	; dx <- create only
		mov	bl, al			; bx <- ExtendedFileAccessFlags
		and	bl, 0xf9		; make sure we're r/w
		or	bl, FA_READ_WRITE
		clr	bh
		andnf	bl, not FAF_GEOS_BITS
		mov	ax, MSDOS7F_CREATE_OR_OPEN 
		call	DOSUtilInt21
		mov	dx, si			; ds:dx <- filename, again
		pop	si			; restore SI
		;
		; restore FileAttrs as MSDOS_EXTENDED_OPEN_FILE returns
		; action-taken in CL - brianc 4/29/94
		;
		pop	cx			; cl = FileAttrs
		jc	errorFreeJFTSlot
	;
	; No error during the creation, so now we get to do the regular
	; stuff.
	; 
		mov_tr	bx, ax
		call	DOSFreeDosHandleFar		; bl <- SFN
		clr	bh				; not a device
		mov	ax, bx
		CheckHack <type dosFileTable eq 10>
		shl	bx
		mov	dx, bx
		shl	bx
		shl	bx
		add	bx, dx			; *8+*2=*10, of course
		add	bx, offset dosFileTable
		mov	dx, bx			; return private data offset
						;  in dx, please...

		mov	ds:[bx].DFE_index, -1		; index not gotten yet
		mov	ds:[bx].DFE_attrs, cl		; attributes are as
							;  we created them
		mov	ds:[bx].DFE_flags, 0		; neither geos nor
							;  dirty...
		mov	ds:[bx].DFE_disk, si
		mov	di, si

		clc
;; Since we didn't do this in OS 2 for the following reason, we'll assume
;; we can't do it in M7 either:
;;
;; We've no access to the SFT under OS2, so just pretend the disk isn't
;; ours and the SFT isn't valid...
;;		call	DOSCheckDiskIsOurs
;;		jnc	done
;;		ornf	ds:[bx].DFE_flags, mask DFF_OURS; (clears carry)
		
done:
		.leave
		ret
invalidName:
		mov	ax, ERROR_INVALID_NAME
		jmp	noPrivateDataError
errorFreeJFTSlot:
		mov	bx, NIL
		call	DOSFreeDosHandleFar
noPrivateDataError:
		mov	dx, 0				; no private data
		stc
		jmp	done
DOSCreateNativeFile endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOS7CreateDestName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Function to create a complex long name from the passed
		data.

CALLED BY:	utility for rename and move

PASS:		ds:si	= source long name whole thing
		es:di 	= destination for new long name
		bx	= dgroup
		dosFinalComponent has the new GeosLongName info

RETURN:		es:di	 = new long file name
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimw	2/12/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOS7CreateDestName	proc	far
sourceSeg	local	word	push	ds
sourceOff	local	word	push	si
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	; Copy the long name from dosFinalComponent and space pad.
	;
		mov	ds, bx			; ds <- dgroup
		mov	cx, ds:[dosFinalComponentLength]
		lds	si, ds:[dosFinalComponent]
		mov	ax, size MSD7GN_longName
		sub	ax, cx			; ax <- space pad amount
		rep	movsb
		mov	cx, ax			; cx <- space pad amount
		mov	al, ' '
		rep	stosb
	;
	; Generate a unique short name and copy to dest, space padding.
	;
		call	DOSVirtGenerateDosName		; ds:dx <- dos7LongName
		mov	si, dx				
		add	si, offset MSD7GN_shortName	; ds:si <- short name

		push	di
		segxchg	ds, es
		mov	di, offset dos7LongName.MSD7GN_shortName
		LocalStrLength
		segxchg	ds, es
		pop	di
		mov	ax, cx
		mov	si, offset dos7LongName.MSD7GN_shortName
		rep	movsb
		mov	cx, size MSD7GN_shortName
EC <		Assert	ge cx, ax					>
		sub	cx, ax
DBCS <		shr	cx						>
		LocalLoadChar	ax, ' '
SBCS <		rep	stosb						>
DBCS <		rep	stosw						>
	;
	; Copy the non-name related source stuff.
	;
		mov	ds, ss:[sourceSeg]
		mov	si, ss:[sourceOff]
		add	si, offset MSD7GN_signature  ; ds:si <- past short name
		mov	cx, (size MSDOS7GeosName) - \
			(size MSD7GN_longName + size MSD7GN_shortName)
		rep	movsb
		
	.leave
	ret
DOS7CreateDestName	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSPathOpCreateDir
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a directory with its long-directory file inside it.

CALLED BY:	DOSPathOp

PASS:		ds:dx	= name of directory to create.
		es:si	= DiskDesc for disk on which to perform it
		CWD lock grabbed, with all that implies.
RETURN:		carry set on error:
			ax	= error code
			if AX = ERROR_LINK_ENCOUNTERED
				bx = handle of link data

		carry clear if happy.
DESTROYED:	ds, dx (assumed saved by DOSPathOp)

PSEUDO CODE/STRATEGY:
		
				

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSPathOpCreateDir	proc	far
diskSeg local	word	push es
diskHan	local	word	push si
dirName	local	MSDOS7LongNameTypeWithNull

		uses	cx, es, si
	
		.enter
		push	bx	; return unchanged if not a link
	;
	; First map the virtual to the native.  If the file already
	; exists, or a link was encountered, then exit.
	; 
		call	DOSVirtMapDirPath
 		jc	checkError
	;
	; If mapping successful, the name is already taken, so bail.
	;
fileExists:
		mov	ax, ERROR_FILE_EXISTS
bail:
		stc
		jmp	done

checkError:
		cmp	ax, ERROR_LINK_ENCOUNTERED
		jne	notLink
	;
	; If a link was encountered, and it's the final component,
	; then return ERROR_FILE_EXISTS
	;
		call	DOSPathCheckMappedToEnd
		je	fileExists		
	;
	; Otherwise, return the link data in BX
	;
		add	sp, 2
		stc
		jmp	doneNoPop

notLink:
		cmp	ax, ERROR_PATH_NOT_FOUND
		jne	bail		; this is the only acceptable error,
					;  as it might mean the final component
					;  doesn't exist.
		call	DOSPathCheckMappedToEnd
		jne	bail
	;
	; Make sure the combination of the current dir and the native
	; name doesn't result in a path that's too long...
	;
		call	DOSPathEnsurePathNotTooLong
		LONG	jc	done
	;
	; Figure the ID of the containing directory while we've still got
	; it.
 	; 
		mov	bx, dx
		call	DOSFileChangeGetCurPathID	; load current 
		push	cx, dx
		mov	dx, bx
	;
	; The directory name could have illegal DOS characters in it.
	; If it does, we have to
	; 	1: fix up the name for dir creation
	;	2: create an at-dirname file
	;	3: put the bad name in that file
	;
		mov	si, dx			; ds:si <- intended name
		segmov	es, ss			
		lea	di, ss:[dirName]	; es:di <- buffer for mucking
		LocalCopyString
		lea	di, ss:[dirName]
		call	DOS7BadCharReplace	; dirName ready
		
		segxchg	ds, es
		xchg	dx, di			; ds:dx <- prepped dirname
		mov	ax, MSDOS7F_CREATE_DIR
		call	DOSUtilInt21
		jc	donePopID
	;
	; If we do not have a direct match then we must create the dir file.
	;
		mov	si, dx
		call	DOSPathCheckExactMatch
		jc	generateNotify
	;
	; Change to that directory so we can create the @DIRNAME.000 file.
	; 
		call	DOSInternalSetDir
EC <		ERROR_C	GASP_CHOKE_WHEEZE				>
	;
	; Call the common routine to create the file
	; 
		mov	es, ss:[diskSeg]		
		mov	si, ss:[diskHan]		
		call	PathOps_LoadVarSegDS
		call	DOSPathCreateDirectoryFileCommon
		ERROR_C -1
;;		jc	deleteDir

		mov	dx, GFT_DIRECTORY
		push	es
		les	di, ds:[dosFinalComponent]
		call	DOSInitGeosFile
		pop	es
		ERROR_C -1
;;		jc	deleteDir		; file closed on error
	;
	; Close down the special file.
	; 
   		mov	bl, al
		call	DOSAllocDosHandleFar
		mov	ah, MSDOS_CLOSE_FILE
		call	DOSUtilInt21
		mov	bx, NIL
		call	DOSFreeDosHandleFar
generateNotify:
	;
	; Generate notification 
	; 
		mov	ax, FCNT_CREATE
		pop	cx, dx			; cxdx <- dir ID
		segmov	ds, ss
		lea	bx, ss:[dirName]	; ds:bx <- prepped name
		mov	si, ss:[diskHan]		
		mov	es, ss:[diskSeg]
		call	FSDGenerateNotify
	;
	; Much happiness.
	; 
		clc
done:
		pop	bx
doneNoPop:
		.leave
		ret
donePopID:
		add	sp, 4		; discard saved cur-dir ID
		stc
		jmp	done

PrintMessage < Deal with failure to create dirname file here>
if not _MS7
deleteDir:
		add	sp, 4		; discard saved cur-dir ID
	;
	; Bleah. Couldn't initialize the @DIRNAME.000 file, so we need to
	; biff the directory. This is made more complex by our having wiped
	; out the DOS name of the directory that formerly was in the
	; dosNativeFFD.FFD_name. Happily, DOS can tell us what it is, as it's
	; the final component of the current directory.
	; 
		push	ax
		push	si
		mov	si, offset dosPathBuffer
		mov	ah, MSDOS_GET_CURRENT_DIR
		call	DOSUtilInt21
	;
	; Retreat to the parent directory.
	; 
		push	ds
		segmov	ds, cs
		mov	dx, offset cs:poDotDotPath
FXIP<		push	cx						>
FXIP<		clr	cx						>
FXIP<		call	SysCopyToStackDSDX				>
FXIP<		pop	cx						>
		call	DOSInternalSetDir
FXIP<		call	SysRemoveFromStack				>
		pop	ds
EC <		ERROR_C	GASP_CHOKE_WHEEZE				>
	;
	; Find the start of the last component. Recall that GET_CURRENT_DIR
	; doesn't return an absolute path...
	; 
findFinalComponentLoop:
		mov	dx, si		; record first char after last b.s.
inComponentLoop:
		lodsb
		cmp	al, '\\'
		je	findFinalComponentLoop
		tst	al
		jnz	inComponentLoop
	;
	; ds:dx is name of the final component, so biff it.
	; 
		mov	ah, MSDOS_DELETE_DIR
		call	DOSUtilInt21
		pop	si
	;
	; Recover initial error code, set carry and boogie.
	; 
		pop	ax
		stc
		jmp	done
endif

DOSPathOpCreateDir endp
poDotDotPath	char	'..', 0

PathOps		ends


PathOpsRare	segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSPathOpMoveFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move a file.

CALLED BY:	DOSPathOp

PASS:		ds	= dgroup
		ss:bx	= FSMoveFileData
		es:si	= dest disk desc (same disk as source)
		source name mapped and not-in-use; dos name in dos7FindData
		CWD lock grabbed
RETURN:		carry set on error:
			ax	= error code
		carry clear on success
DESTROYED:	ds, dx (saved by DOSPathOp), di (always nukable)

		- copy src long name locally
		- fail if file is read-only
		- fail if file is a directory
		- construct full src path from CWD and dos7LongName
		- switch to thread's directory (dest)
		- map geos long name
		- fail if mapping succeed
		- copy dest long name to dest to local name
		- generate a new short name

		- rename file
		
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimw	2/11/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSPathOpMoveFile	proc	far
diskSeg			local	word	push	es
diskHandle		local	word	push	si		
srcAttrs		local	word
srcPath			local	MSDOS7_MAX_PATH_SIZE dup (char)
srcLongName		local	nptr.char
destName		local	MSDOS7_MAX_PATH_SIZE+2  dup (char)
srcFileType		local	GeosFileType
		uses		ax,bx,cx,si,bp, es
		.enter
	;
	; Get the source file type if it's a geos file.
	;
		mov	ax, ds:[dos7FindData].W32FD_fileAttrs.low
		mov	ss:[srcAttrs], ax
		test	ax, FA_GEOS_FILE
		jz	testSource
		
		mov	si, offset dos7FindData.W32FD_fileName.MSD7GN_type
		segmov	es, ss
		lea	di, ss:[srcFileType]
		mov	cx, size srcFileType
		call	DOS7MapAsciiToBytes

testSource:
	;
	; Read only or directory?
	;
		mov	ax, ERROR_ACCESS_DENIED
		test	ds:[dos7FindData].W32FD_fileAttrs.low.low, \
							mask FA_RDONLY
		LONG jnz	fail

		mov	ax, ERROR_CANNOT_MOVE_DIRECTORY
		test 	ds:[dos7FindData].W32FD_fileAttrs.low.low, \
							mask FA_SUBDIR
		LONG jnz	fail
	;
	; Get the whole path to the src file.  Mapping the destination later
	; may clobber the info in dos7FindData.
	;
		push	ds			; dgroup
		segmov	ds, ss
		mov	ss:[srcPath], '\\'	; DOS doesn't give us this
		lea	si, ss:[srcPath][1]
		clr	dl
		mov	ax, MSDOS7F_GET_CURRENT_DIR
		call	DOSUtilInt21
		pop	ds
		segmov	es, ss
		lea	di, ss:[srcPath]
		clr	al
		mov	cx, size srcPath-1
		repne	scasb
		dec	di			; point to last char
		dec	di
		mov	al, '\\'
		scasb
		je	srcSeparatorAdded
		stosb
srcSeparatorAdded:
		mov	si, offset dos7FindData.W32FD_fileName
		cmp	cx, size MSDOS7GeosName
		jle	copyName
		mov	cx, size MSDOS7GeosName
copyName:
		mov	ss:[srcLongName], di
		rep	movsb
	;
	; Switch back to thread's directory and attempt to map the destination.
	;
		mov	es, ss:[diskSeg]
		mov	si, ss:[diskHandle]
		lds	dx, ss:[bx].FMFD_dest	; ds:dx <- dest name
		call	DOSEstablishCWDLow

EC <		ERROR_C	GASP_CHOKE_WHEEZE 	; was established before so>
		call	DOSVirtMapFilePath
		jc	checkDestMapError
		mov	ax, ERROR_FILE_EXISTS
fail:
		stc
		jmp	done

checkDestMapError:
		cmp	ax, ERROR_FILE_NOT_FOUND
		jne	fail
	;
	; Set up es:di to point to the final component of the destination.
	; 
		segmov	es, ds
		mov	di, dx				; es:di full dest path
		mov	cx, MSDOS7_MAX_PATH_SIZE
		clr	al
		repne	scasb				; es:di <- end of path
	;
	; Search backward for the first backslash.
	;
		INT_OFF
		std
		mov	al, '\\'
		mov	cx, FILE_LONGNAME_LENGTH 
		repne	scasb
		cld
		INT_ON
		inc	di
		inc	di			; es:di <- dest file name

		mov	bx, di
		LocalStrLength			; cx <- dest file name length
		mov	di, bx
	;
	; See if we have a geos file or not.
	;
		call	PathOpsRare_LoadVarSegDS
		test	ss:[srcAttrs], FA_GEOS_FILE
		LONG	jz	notGeos
	;
	; Figure out if we're moving an executable .geo file.
	;
		segmov	ds:[dosFinalComponent].high, es
		mov	ds:[dosFinalComponent].low, di
		mov	ds:[dosFinalComponentLength], cx
		cmp	ss:[srcFileType], GFT_EXECUTABLE
		je	dealWithExecutable
geosFile::
	;
	; Copy the destination geos long name to dosFinalComponent, so
	; we can generate a decent dos name for the thing.
	;
		mov	bx, ds
		segmov	ds, ss
		segmov	es, ss
		mov	si, ss:[srcLongName]	; ds:si <- source long name
		lea	di, ss:[destName]	; es:di <- destination
		call	DOS7CreateDestName	
		call	DOS7BadCharReplace
rename:
	;
	; Rename.
	;
		lea	dx, ss:[srcPath]
		lea	di, ss:[destName]
		mov	ax, MSDOS7F_RENAME_FILE
		call	DOSUtilInt21
		jc	done
	;
	; Must generate two notifications.  Deletion first.
	;
		lea	si, ss:[srcPath]		; ds:si <- src path
		call	DOSFileChangeCalculateID	; cxdx <- ID
		mov	si, ss:[diskHandle]
		mov	ax, FCNT_DELETE
		call	FSDGenerateNotify
	;
	; And a create for the destination.  The called routine works with
	; dosFinalComponent and dosPathBuffer.  No setup required.
	;
		mov	ax, FCNT_CREATE
		call	DOSFileChangeGenerateNotifyWithName
	;
	; Finally, update the GeosFileHeader if it's a geos file
	;
		test	ss:[srcAttrs], FA_GEOS_FILE
		jz	done

		segmov	es, ss
		lea	si, ss:[destName]
		call	PathOpsRare_LoadVarSegDS
		segxchg	es, ds
		call	DOS7RenameGeosFileHeader		
done:
		
		.leave
		ret
dealWithExecutable:

	;
	; Executable.  We know we'll only be changing one of the names, so
	; copy the whole source to start.
	;
		mov	bx, ds				; bx <- dgroup
		segmov	ds, ss
		segmov	es, ss
		mov	si, ss:[srcLongName]		; ds:si <- source name
		lea	di, ss:[destName]		; es:di <- dest 
		mov	cx, size MSDOS7GeosName
		rep	movsb
	;
	; Now we need to know what the destination name looks like.
	; Are we renaming the long name or the dos name? 
	;
		mov	ds, bx				; ds <- dgroup
		cmp	ds:[dosFinalComponentLength], size DosDotFileName
		ja	renameExecLong

		mov	cx, ds:[dosFinalComponentLength]
		les	di, ds:[dosFinalComponent]	; es:di <- dest name
		mov	al, '.'
		repne	scasb			; locate extension
		jne	renameExecLong		; no extension 

		call	DOSVirtCheckNumericExtension
		jc	renameExecLong		; carry set if numeric

renameExecShort::
	;
	; Executable source with a dos dest name with a non-numeric extention.
	; Copy the destination name as the dos name.
	;
		segmov	es, ss
		lea	di, ss:[destName]
		add	di, offset MSD7GN_shortName
		mov	cx, ds:[dosFinalComponentLength]
		cmp	cx, DOS_DOT_FILE_NAME_LENGTH
		LONG	ja	fail
		lds	si, ds:[dosFinalComponent]
		mov	bx, cx
		rep	movsb
	;
	; Space pad.
	;
		mov	cx, size MSD7GN_shortName
		sub	cx, bx
		mov	al, ' '
		rep	stosb
		segmov	ds, ss
		jmp	rename

renameExecLong:
	;
	; Executable source with a longname dest.  Copy the destination as
	; the long name.  es:di is the dest buffer, cx length of the name.
	;
		segmov	es, ss
		lea	di, ss:[destName]
		add	di, offset MSD7GN_longName	   ; es:di <- dest
		mov	cx, ds:[dosFinalComponentLength]
		lds	si, ds:[dosFinalComponent]	; ds:si <- source
		mov	bx, cx
		rep	movsb
		mov	cx, size  MSD7GN_longName
EC <		Assert	ge cx, bx					>
		sub	cx, bx
		mov	al, ' '
		rep	stosb
		segmov	ds, ss
		jmp	rename

notGeos:
	;
	; Non-geos.  Copy the source name to both long and short places.
	; Space padding, of cource.  es:di is the dest file name and cx
	; is its length.  long name first.
	;
		mov	ax, ERROR_INVALID_NAME
		cmp	cx, DOS_DOT_FILE_NAME_LENGTH
		LONG	ja	fail
		
		push	ds			; dgroup
		segmov	ds, es
		mov	si, di			; ds:si <- dest name source
		segmov	es, ss			
		lea	di, ss:[destName]	; es;di <- destination
		mov	ax, cx			; ax <- dest name length
		mov	bx, si			; bx <- dest source start
		mov	dx, di			; dx <- dest name dest start
		rep	movsb
		mov	cx, size MSD7GN_longName
		sub	cx, ax
		push	ax
		mov	al, ' '
		rep	stosb		
		pop	cx
	;
	; Now the short name part.
	;
		mov	si, bx			; ds:si dest name source again
		mov	ax, cx			; ax = cx = dest source length 
		mov	di, dx			; es:di <- dest dest start
		add	di, offset MSD7GN_shortName	; dest short name
		rep	movsb
		mov	cx, size MSD7GN_shortName
EC <		Assert	ge cx, ax					>
		sub	cx, ax
		mov	al, ' '
		rep	stosb
	;
	; Add the NATIVE signature and set up for renaming.
	;
		pop	ds
		mov	si, offset nativeSignature
		mov	cx, size nativeSignature
		rep	movsb
		segmov	ds, ss		
		jmp	rename

DOSPathOpMoveFile	endp



PathOpsRare ends

