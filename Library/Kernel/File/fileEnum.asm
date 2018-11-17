COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		fileEnum.asm

AUTHOR:		Adam de Boor, Apr  9, 1990

ROUTINES:
	Name			Description
	----			-----------
    GLB FileEnum		Application-level interface
    GLB FileEnumLocateAttr	Utility routine for application-level
				callbacks from FileEnum to locate an
				attribute in those passed.    

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	4/ 9/90		Initial revision


DESCRIPTION:
	Functions for enumerating files.
		

     $Id: fileEnum.asm,v 1.1 97/04/05 01:11:46 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FileenumCode segment resource

FileEnumLocals	struct
    FEL_retBufHandle	hptr		; handle of buffer being returned
    FEL_curRetOff	word		; offset of place to store next return
					;  value
    FEL_numFound	word		; number of files found that match
    FEL_numMissed	word		; number of files that wouldn't fit,
					;  if a limit was set by the caller.
    FEL_realSkipCount	word		; count of files to skip regardless of
					;  whether they match. Starts at the
					;  initial real skip count and
					;  decrements once for each file found,
					;  up until output buffer is full.
					;  Buffer starts filling when this goes
					;  < 0.
    FEL_fecdHandle	hptr		; handle of FileEnumCallbackData block
    FEL_valueSpaceReqd	word		; number of bytes of space needed
					;  after the attribute array in the
					;  FECD block.
    FEL_fecdAttrSize	word		; current size of attribute array,
					;  including EOL
    FEL_filesSeen	hptr		; buffer containing the names of all
					;  the files given to us by the FSD
					;  so far, so we can detect duplicate
					;  files found in different directories
					;  along the search path for a logical
					;  directory.
    FEL_fsFree		word		; Offset into FEL_filesSeen of first
					;  free byte.
    FEL_fsdCallback	word		; Offset of callback FSD should call
					;  within FileenumCode (for use by
					;  FEEnumCurrentPath)
FileEnumLocals	ends

FE_FILES_SEEN_INITIAL_SIZE	equ	512
FE_FILES_SEEN_INCR_SIZE		equ	512
FECD_INITIAL_SIZE		equ	256	; initial # bytes for FECD


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FEFetchCurPathDisk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the disk handle for the thread's current path.

CALLED BY:	INTERNAL
PASS:		nothing
RETURN:		bx	= the disk handle
		carry set if disk is StandardPath member, not real disk
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/26/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FEFetchCurPathDisk proc	near
		uses	ds
		.enter
		LoadVarSeg	ds, bx
		mov	bx, ss:[TPD_curPath]
		mov	bx, ds:[bx].HM_otherInfo

		test	bx, DISK_IS_STD_PATH_MASK	; (clears carry)
		jnz	isStdPath
done:
		.leave
		ret
isStdPath:
		stc
		jmp	done
FEFetchCurPathDisk endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FESetCallbackEtc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the callback function FEEnumCurrentPath should use and
		adjust the FECD as necessary based on the current path,
		whether it's a standard path, and whether it has any
		directories beyond the local one to deal with.

CALLED BY:	FileEnum
PASS:		es	= segment of FECD
		ss:bp	= inherited stack frame
RETURN:		carry clear if ok:
			FEL_fsdCallback set up
			FEL_filesSeen allocated if nec'y, or 0 if not
		carry set if error:
			ax	= ERROR_INSUFFICIENT_MEMORY
DESTROYED:	ax, bx, cx, dx, si, di, ds

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/26/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
;
; Array of extended attributes that gets merged in when enumerating along a
; standard path to ensure we get the virtual name of all the files from the
; FSD.
; 
feNameAttr	FileExtAttrDesc \
	<FEA_NAME, 0, FILE_LONGNAME_BUFFER_SIZE>,
	<FEA_END_OF_LIST>

FESetCallbackEtc proc	near
		.enter	inherit FileEnum
	;
	; Assume we can use the fast callback.
	; 
		clr	ax
		mov	ss:[locals].FEL_filesSeen, ax
		mov	ss:[locals].FEL_fsFree, ax
		mov	ss:[locals].FEL_fsdCallback, offset FEEnumCallback

		call	FEFetchCurPathDisk
		jnc	done		; not std path => use faster callback
					;  that doesn't check for duplicates
	;
	; See if there are any paths defined. If not, there can only be
	; one directory so we can use the faster callback.
	; 
		LoadVarSeg	ds
		cmp	ds:[loaderVars].KLV_stdDirPaths, 0
		jz	done
	;
	; Must use the slow method, so ensure that FEA_NAME is in the list
	; of attributes the FSD will provide us.
	; 
		mov	ss:[locals].FEL_fsdCallback, offset FESlowEnumCallback

		segmov	ds, cs
		mov	si, offset feNameAttr
		call	FEAddAttrs
		jc	done		; => error, code in AX
	;
	; Allocate the initial buffer to hold the file names we've seen.
	; 
		mov	ax, FE_FILES_SEEN_INITIAL_SIZE
		mov	cx, mask HF_SWAPABLE
		call	MemAllocFar
		mov	ss:[locals].FEL_filesSeen, bx
		jnc	done
	;
	; Couldn't alloc => couldn't enum, so return error and carry set
	; 
		mov	ax, ERROR_INSUFFICIENT_MEMORY
done:
		.leave
		ret
FESetCallbackEtc endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FELocateAttr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Locate the passed attribute in the passed attribute array.

CALLED BY:	FEAddAttrs, FECmpAttrs, FECopyAttrs
PASS:		ds:si	= FileExtAttrDesc (or FileExtCustomAttrDesc) that we
			  want to find.
		es:di	= start of array of attributes in which to search.
RETURN:		ax	= FileExtendedAttribute in ds:si
		carry set if attribute found:
			es:di	= descriptor in destination array
		carry clear if attribute not found
DESTROYED:	dx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/20/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FELocateAttr	proc	near
		.enter
		mov	ax, ds:[si].FEAD_attr
lookForAttr:
	;
	; Fetch the attribute from the FECD, as we've got two comparisons we
	; might need to make...
	; 
		mov	dx, es:[di].FEAD_attr
		cmp	ax, dx		; same as attribute being merged?
		je	attrMatched	; yes -- go deal with FEA_CUSTOM before
					;  deciding to drop this one.

		cmp	dx, FEA_END_OF_LIST	; end of the dest array?
		je	done			; yes -- attr ain't there, so 
						;  return with carry clear
nextAttr:
	;
	; Advance to the next attribute in the destination array.
	; 
		add	di, size FileExtAttrDesc
		jmp	lookForAttr

attrMatched:
	;
	; FEAD_attr matched, but the thing might be a custom attribute, which
	; requires more work....
	; 
		cmp	ax, FEA_CUSTOM
		je	checkCustom
	;
	; Nope. not custom, so signal that we found the attribute and be done.
	; 
match:
		stc
done:
		.leave
		ret

	;--------------------
checkCustom:
	;
	; Attribute being sought is FEA_CUSTOM, so we have to compare the
	; null-terminated name strings as well before declaring a match.
	; 
		push	ds, si, es, di, ax	; save affected registers
		lds	si, ds:[si].FEAD_name
		les	di, es:[di].FEAD_name
checkCustomLoop:
		lodsb
		scasb
		jne	checkCustomEnd
		tst	al			; done with both?
		jnz	checkCustomLoop		; nope -- keep looping
checkCustomEnd:
		pop	ds, si, es, di, ax	; recover affected registers
		jne	nextAttr
		jmp	match
FELocateAttr	endp
		
;
; Table of extended-attribute sizes for those that are of a fixed size
; (i.e. that aren't null-terminated strings)
; If the value is zero, then the caller can request return values of
; any size
; 
extAttrSizes	byte	size FileDateAndTime,	; FEA_MODIFIED
			size FileAttrs,		; FEA_FILE_ATTR
			size dword,		; FEA_SIZE
			size GeosFileType,	; FEA_FILE_TYPE
			size GeosFileHeaderFlags,; FEA_FLAGS
			size ReleaseNumber,	; FEA_RELEASE
			size ProtocolNumber,	; FEA_PROTOCOL
			size GeodeToken,	; FEA_TOKEN
			size GeodeToken,	; FEA_CREATOR
			0,			; FEA_USER_NOTES
			0,			; FEA_NOTICE
			size FileDateAndTime,	; FEA_CREATED
			0,			; FEA_PASSWORD
			0,			; FEA_CUSTOM
			0,			; FEA_NAME
			size GeodeAttrs,	; FEA_GEODE_ATTR
			size DirPathInfo,	; FEA_PATH_INFO
			size FileID,		; FEA_FILE_ID
			0,			; FEA_DESKTOP_INFO
			size DriveExtendedStatus,; FEA_DRIVE_STATUS
			size word,		; FEA_DISK
			0,			; FEA_DOS_NAME
			0,			; FEA_OWNER
			0,			; FEA_RIGHTS
			size FileID		; FEA_TARGET_FILE_ID
.assert (length extAttrSizes) eq (FEA_LAST_VALID+1)

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FEAddAttrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Merge an array of attribute descriptors into the
		FileEnumCallbackData block being built, being certain
		not to duplicate one.

CALLED BY:	FileEnum
PASS:		ds:si	= array of attributes to merge in
		es	= segment of FileEnumCallbackData
		ss:bp	= inherited stack frame et al
RETURN:		carry set on error:
			ax	= ERROR_INSUFFICIENT_MEMORY
		carry clear if ok:
			es	= adjusted for any needed reallocations
DESTROYED:	si, ax, cx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/20/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FEAddAttrs	proc	near
		uses	bx
		.enter	inherit FileEnum
		sub	si, size FileExtAttrDesc
attrLoop:
	;
	; Advance to the next attribute to merge in.
	; 
		add	si, size FileExtAttrDesc
nextAttr:
	;
	; Fetch next attribute to merge in.
	; 
		mov	ax, ds:[si].FEAD_attr
		cmp	ax, FEA_END_OF_LIST
		je	done

	;
	; See if it already exists in the destination array.
	; 
		clr	di
		call	FELocateAttr
EC <		jnc	addAttr						>
EC <		mov	bx, ax						>
EC <		tst	cs:[extAttrSizes][bx]	; fixed size?		>
EC <		jnz	attrLoop		; yes -- no point in comparing>
EC <		mov	ax, ds:[si].FEAD_size	; make sure this descriptor>
EC <						;  has the same size as any>
EC <						;  previous descriptor	>
EC <		cmp	es:[di].FEAD_size, ax				>
EC <		je	attrLoop					>
EC <		ERROR	EXT_ATTR_VALUE_SIZES_DONT_MATCH			>
EC <addAttr:								>
NEC<		jc	attrLoop					>

	;
	; Attribute not there yet, so we must add it to the destination.
	; If the thing is of a fixed size (extAttrSizes[ax] != 0), we must
	; pass that size off to the IFS driver, else it is likely to complain.
	; We deal more gracefully with a size smaller than the fixed size
	; when we compare or return attributes.
	;
		mov_tr	bx, ax			; bx <- FileExtendedAttribute
		mov	al, cs:[extAttrSizes][bx]
		cbw				; clear ah (all sizes < 128)
		tst	ax
		jnz	haveSize		; => is fixed size
		mov	ax, ds:[si].FEAD_size	; note more bytes needed for
						;  value storage
haveSize:
		push	ax			; save attribute size for after
						;  the descriptor is copied
		add	ss:[locals].FEL_valueSpaceReqd, ax
	;
	; Enlarge the block if we need to.
	; 
		mov	bx, ss:[locals].FEL_fecdHandle
		mov	ax, MGIT_SIZE
		call	MemGetInfo
		mov_trash	cx, ax	; cx <- current size of FECD block

		mov	ax, ss:[locals].FEL_fecdAttrSize
		add	ax, size FileExtAttrDesc; figure size required
		cmp	ax, cx			; block big enough?
		jbe	copyItPlease		; yup -- just copy

		shl	cx		; double the block size, as there
					;  will also be attribute values to
					;  deal with, so we might as well
					;  allocate all the space at once...
		mov_trash	ax, cx
		clr	cx
		call	MemReAlloc
		jc	error

	; XXX: check for errors
		mov	es, ax		; point ES to the block's new location
copyItPlease:
	;
	; Copy the attribute descriptor to the block and terminate the
	; array properly.
	; 
		mov	di, ss:[locals].FEL_fecdAttrSize
		mov	cx, size FileExtAttrDesc
		sub	di, size FEAD_attr
		rep	movsb
	    ;
	    ; Fetch the size the IFS driver should use off the stack...
	    ; 
		pop	es:[di-size FileExtAttrDesc].FEAD_size

				CheckHack <offset FEAD_attr eq 0>
		mov	ax, FEA_END_OF_LIST
		stosw
		mov	ss:[locals].FEL_fecdAttrSize, di		
		jmp	nextAttr		; si already moved to next
						;  attr, so just go to
						;  nextAttr, not attrLoop

done:
		.leave
		ret
error:
		pop	ax			; clear size-to-use
		mov	ax, ERROR_INSUFFICIENT_MEMORY
		jmp	done
FEAddAttrs	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FEAllocValueSpace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate the space required to hold the file's attribute
		values, apportioning that space among the attributes
		in the array passed.

CALLED BY:	FileEnum
PASS:		es	= segment of FileEnumCallbackData block
		ss:bp	= inherited local frame
RETURN:		carry set on error:
			ax	= ERROR_INSUFFICIENT_MEMORY
		carry clear if successful:
			es	= adjusted
			all entries in the attribute array given space.
DESTROYED:	ax, cx, si

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/20/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FEAllocValueSpace proc	near
		uses	bx
		.enter	inherit	FileEnum
		mov	bx, ss:[locals].FEL_fecdHandle
		mov	ax, ss:[locals].FEL_fecdAttrSize
		add	ax, ss:[locals].FEL_valueSpaceReqd
		clr	cx
		call	MemReAlloc
		jc	error

		mov	es, ax

		mov	cx, ss:[locals].FEL_fecdAttrSize
		clr	si
allocLoop:
		cmp	es:[si].FEAD_attr, FEA_END_OF_LIST
		je	done
	;
	; Point the descriptor at its alloted space. ax = block segment,
	; cx = offset of next free byte in block.
	; 
		mov	es:[si].FEAD_value.offset, cx
		mov	es:[si].FEAD_value.segment, ax
	;
	; Adjust the free offset by the size of the attribute's value, and
	; shift our attention to the next attribute.
	; 
		add	cx, es:[si].FEAD_size
		add	si, size FileExtAttrDesc
		jmp	allocLoop
done:
		.leave
		ret

error:
		mov	ax, ERROR_INSUFFICIENT_MEMORY
		jmp	done
FEAllocValueSpace endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FECompareAttrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare the values required by the source array of
		extended attributes against those actually found for
		the file.

CALLED BY:	FileEnumCallback
PASS:		ds:si	= file's actual attributes
		es:di	= attributes against which to match.
RETURN:		carry set if mismatch.
DESTROYED:	ax, cx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/20/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FECompareAttrs	proc	near
		uses	si, di, dx, bx
		.enter
		xchg	si, di
		segxchg	ds, es
compareLoop:
	;
	; If made it to the end of the list, all our conditions are met.
	; 
		mov	bx, ds:[si].FEAD_attr
		cmp	bx, FEA_END_OF_LIST
		je	done
	;
	; See if we can find this attribute in those we've got for the file.
	; 
		push	di
		call	FELocateAttr
EC <		ERROR_NC	MATCH_ATTRIBUTE_NOT_IN_FILE_ATTRIBUTE_ARRAY>
		cmp	es:[di].FEAD_value.segment, 0
		jz	mismatch	; if FSD has marked file as not
					;  having such an attribute, it can't
					;  possibly match what was specified...
		mov	cx, ds:[si].FEAD_size
		shl	bx
		jmp	cs:[extAttrCompares][bx]

extAttrCompares	nptr	compareBinary,		; FEA_MODIFICATION
			compareBits,		; FEA_FILE_ATTR
			compareBinary,		; FEA_SIZE
			compareBinary,		; FEA_FILE_TYPE
			compareBits,		; FEA_FLAGS
			compareBinary,		; FEA_RELEASE
			compareBinary,		; FEA_PROTOCOL
			compareBinary,		; FEA_TOKEN
			compareBinary,		; FEA_CREATOR
			compareString,		; FEA_USER_NOTES
			compareString,		; FEA_NOTICE
			compareBinary,		; FEA_CREATION
			compareString,		; FEA_PASSWORD
			compareBinary,		; FEA_CUSTOM
			compareString,		; FEA_NAME
			compareBits,		; FEA_GEODE_ATTR
			compareBits,		; FEA_PATH_INFO
			compareBinary,		; FEA_FILE_ID
			compareBinary,		; FEA_DESKTOP_INFO
			compareBits,		; FEA_DRIVE_STATUS
			compareBinary,		; FEA_DISK
			compareString,		; FEA_DOS_NAME
			compareString,		; FEA_OWNER
			compareString,		; FEA_RIGHTS
			compareBinary		; FEA_TARGET_FILE_ID
.assert (length extAttrCompares) eq (FEA_LAST_VALID+1)
compareString:
	;
	; Compare two null-terminated strings for equality.
	; 
		push	ds, si
		lds	si, ds:[si].FEAD_value
		mov	di, es:[di].FEAD_value.offset
compareStringLoop:
		lodsb				; al <- attr char
		scasb				; matches value char?
		jne	stringCompareFail	; nope => bail
		tst	al			; end of string?
		loopne	compareStringLoop	; loop if non-zero

		pop	ds, si			; recover match attr
nextAttr:
		pop	di			; recover file attr base
		add	si, size FileExtAttrDesc
		jmp	compareLoop

stringCompareFail:
		pop	ds, si
mismatch:
		pop	di
		stc
done:
		segxchg	ds, es
		.leave
		ret

compareBinary:
	;
	; Compare two sets of binary data for equality.
	; 
		push	si, ds
		lds	si, ds:[si].FEAD_value
		mov	di, es:[di].FEAD_value.offset
		repe	cmpsb
		pop	si, ds
		jne	mismatch
		jmp	nextAttr

compareBits:
	;
	; Perform bitmask comparisons.
	; 	ax <- bits that should be set
	; 	dx <- bits that should *not* be set
	; 	cx <- actual value for the attribute.
	; 
		mov	ax, ds:[si].FEAD_value.offset
		mov	dx, ds:[si].FEAD_value.segment
		cmp	cx, 1		; single byte value?
		mov	di, es:[di].FEAD_value.offset
		mov	cx, es:[di]
		jne	checkWord	; no -- use entire registers

		test	cl, dl		; any set that shouldn't be?
		jnz	mismatch	; yup -- honk
		not	cl		; invert file value so any that should
					;  be set but aren't end up set...
		test	cl, al		; any not set that should be?
		jnz	mismatch	; yup -- honk
		jmp	nextAttr

checkWord:
		test	cx, dx		; any set that shouldn't be?
		jnz	mismatch	; yup -- honk
		not	cx		; invert file value so any that should
					;  be set but aren't end up set...
		test	cx, ax		; any not set that should be?
		jnz	mismatch	; yup -- honk
		jmp	nextAttr
FECompareAttrs	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FECopyAttrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy the extended attributes from the array of file attributes
		to the new entry in the return buffer.

CALLED BY:	FileEnumCallback
PASS:		ds:si	= array of file's attributes
		es:di	= base of entry in return buffer to fill in
		ss:bp	= inherited stack frame

RETURN:		nothing
DESTROYED:	ax, cx, dx, si

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/20/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FECopyAttrs	proc	near
		uses	bx, ds
		.enter	inherit FileEnum

		push	es, di
		mov	di, si
		mov	si, ss:[params].FEP_returnAttrs.offset
attrLoop:
	;
	; Reload segment registers as we need them for locating the next
	; attribute in the file attrs array.
	; 
		segmov	es, ds
		mov	ds, ss:[params].FEP_returnAttrs.segment
	;
	; If we hit the end of the returnAttrs array, we're done.
	;
		cmp	ds:[si].FEAD_attr, FEA_END_OF_LIST
		je	done		
	;
	; Nope. Find the attribute in the FECD segment (it'd better be there...)
	; 
		push	di
		call	FELocateAttr
EC <		ERROR_NC	RETURN_ATTRIBUTE_NOT_IN_FILE_ATTRIBUTE_ARRAY>
		mov	bx, di
		pop	di
	;
	; Recover the base of the entry in the return buffer.
	; 
		pop	ax, cx
	;
	; Save the attribute array offsets.
	; 
		push	si, di
	;
	; Play with things to prepare for the copy...this is ugly
	; 
		mov	dx, ds:[si].FEAD_value.offset
		mov	di, ds:[si].FEAD_size
		mov	si, es:[bx].FEAD_value.offset
		; ax:cx = base of return entry
		; ds:si = value for file
		; ds:bx = attribute found for file
		; di 	= size of return area
		; dx    = offset into return entry at which to store result
		add	dx, cx		; dx <- offset to store value
		xchg	di, dx		; di <- offset to store, dx <- size of
					;  destination
		segmov	ds, es		; ds <- FECD segment

EC <		cmp	dx, ds:[bx].FEAD_size				>
EC <		ERROR_B	RETURN_AREA_TOO_SMALL_FOR_ATTRIBUTE		>

		mov	es, ax		; es <- return buffer segment
		xchg	cx, dx		; cx <- size of return area,
					; dx <- base of return buffer entry

		cmp	ds:[bx].FEAD_value.segment,0	; any value for file?
		jz	zeroAttr			; no -- zero return

		; ds:si = value for file
		; es:di = return area for attribute
		; cx    = size of return area for attribute
		rep	movsb
nextAttr:
		pop	si, di		; si <- return attr, di <- file attr
					;  base
		push	es, dx		; save return entry base for next loop
	;
	; Advance to next entry in returnAttrs array.
	;
		add	si, size FileExtAttrDesc
		jmp	attrLoop
done:
		pop	es, di
		.leave
		ret
	;--------------------
zeroAttr:
	;
	; No value for that attribute in the file, so just zero the return area.
	; 
		clr	al
		rep	stosb
		jmp	nextAttr
FECopyAttrs	endp


if	ERROR_CHECK

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FECheckReturnAttrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	EC-only function to make sure the passed returnAttrs array
		makes sense.

CALLED BY:	FileEnum
PASS:		ss:bp	= inherited stack frame
RETURN:		only if array is valid
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/23/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FECheckReturnAttrs proc	near
		uses	ds, si, ax, bx
		.enter	inherit	FileEnum
		
		lds	si, ss:[params].FEP_returnAttrs
checkLoop:
		mov	bx, ds:[si].FEAD_attr
		cmp	bx, FEA_END_OF_LIST
		je	done
		cmp	bx, FEA_MULTIPLE
		ERROR_E	FEA_MULTIPLE_MAY_NOT_BE_PART_OF_AN_ATTRIBUTE_ARRAY
		cmp	bx, FEA_LAST_VALID
		ERROR_A	ILLEGAL_EXTENDED_ATTRIBUTE
		mov	al, cs:extAttrSizes[bx]
		tst	al		; variable-sized?
		jz	checkBounds	; yes -- don't check
		cbw
		cmp	ax, ds:[si].FEAD_size
		ERROR_NE	EXT_ATTR_SIZE_DOESNT_MATCH_DEFINED_SIZE
checkBounds:
		mov	ax, ds:[si].FEAD_value.offset
		add	ax, ds:[si].FEAD_size
		cmp	ax, ss:[params].FEP_returnSize
		ERROR_A		RETURN_AREA_EXTENDS_PAST_RETURN_ENTRY_SIZE
		add	si, size FileExtAttrDesc
		jmp	checkLoop

done:
		.leave
		ret
FECheckReturnAttrs		endp
endif

fileEnumStandardReturnArrays	nptr.FileExtAttrDesc \
	fesrtaCountOnly,	; FESRT_COUNT_ONLY
	fesrtaDosInfo,		; FESRT_DOS_INFO
	fesrtaName,		; FESRT_NAME
	fesrtaNameAndAttr	; FESRT_NAME_AND_ATTR

fesrtaCountOnly FileExtAttrDesc \
	<FEA_END_OF_LIST>

fesrtaDosInfo	FileExtAttrDesc \
	<FEA_FILE_ATTR, FEDI_attributes, size FEDI_attributes>,
	<FEA_MODIFICATION, FEDI_modified, size FEDI_modified>,
	<FEA_SIZE, FEDI_fileSize, size FEDI_fileSize>,
	<FEA_NAME, FEDI_name, size FEDI_name>,
	<FEA_PATH_INFO, FEDI_pathInfo, size FEDI_pathInfo>,
	<FEA_END_OF_LIST>

fesrtaName FileExtAttrDesc \
	<FEA_NAME, 0, size FileLongName>,
	<FEA_END_OF_LIST>

fesrtaNameAndAttr FileExtAttrDesc \
	<FEA_FILE_ATTR, FENAA_attr, size FENAA_attr>,
	<FEA_NAME, FENAA_name, size FENAA_name>,
	<FEA_END_OF_LIST>

fileEnumStandardCallbacks	nptr.far	\
	FileEnumWildcard	; FESC_WILDCARD

fileEnumStandardCallbackAttrs	nptr.FileExtAttrDesc \
	fescaName		; FESC_WILDCARD

fescaName	FileExtAttrDesc \
	<FEA_NAME, 0, FILE_LONGNAME_BUFFER_SIZE>,
	<FEA_END_OF_LIST>

;
; Additional attribute arrays needed for dealing with FESF bits.
; 
feFileTypeAttr	FileExtAttrDesc \
	<FEA_FILE_TYPE, 0, size GeosFileType>,
	<FEA_END_OF_LIST>

feFileAttrAttr	FileExtAttrDesc \
	<FEA_FILE_ATTR, 0, size FileAttrs>,
	<FEA_END_OF_LIST>



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FEFinishParams
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finish filling out the FileEnumParams, dealing with the
		receipt of FileEnumStandardReturnType and
		FileEnumStandardCallback constants.

CALLED BY:	FileEnum
PASS:		inherited stack frame with parameters and locals set up.
RETURN:		nothing
DESTROYED:	ax, si

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/21/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FEFinishParams	proc	near
		.enter	inherit FileEnum
	;
	; If caller wants standard return structure, replace FEP_returnAttrs
	; with a far pointer to one of the arrays we define.
	; 
		cmp	ss:[params].FEP_returnAttrs.segment, 0
		jnz	haveRetAttrs
		mov	si, ss:[params].FEP_returnAttrs.offset
EC <		cmp	si, FileEnumStandardReturnType			>
EC <		ERROR_AE	INVALID_STANDARD_RETURN_TYPE		>
		shl	si
		mov	si, cs:[fileEnumStandardReturnArrays][si]
		mov	ss:[params].FEP_returnAttrs.offset, si
		mov	ss:[params].FEP_returnAttrs.segment, cs

haveRetAttrs:
EC <		call	FECheckReturnAttrs				>

		test	ss:[params].FEP_searchFlags, mask FESF_CALLBACK
		jz	done
		cmp	ss:[params].FEP_callback.segment, 0
		jnz	done

		mov	si, ss:[params].FEP_callback.offset
EC <		cmp	si, FileEnumStandardCallback			>
EC <		ERROR_AE	INVALID_STANDARD_CALLBACK_TYPE		>

		shl	si
		mov	ax, cs:[fileEnumStandardCallbacks][si]
		mov	ss:[params].FEP_callback.offset, ax
		mov	ss:[params].FEP_callback.segment, SEGMENT_CS

		mov	ss:[params].FEP_callbackAttrs.segment, 0
		mov	ax, cs:[fileEnumStandardCallbackAttrs][si]
		tst	ax
		jz	done
		
		mov	ss:[params].FEP_callbackAttrs.offset, ax
		mov	ss:[params].FEP_callbackAttrs.segment, cs
done:
		.leave
		ret
FEFinishParams	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FEFormFECD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Form the FileEnumCallbackData segment for the whole
		operation.

CALLED BY:	FileEnum
PASS:		inherited stack frame set up
RETURN:		carry set if error
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/21/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FEFormFECD	proc	near
		.enter	inherit	FileEnum
	;
	; Zero-initialize the buffer handle so caller knows if we allocated
	; the beast or not.
	; 
		mov	ss:[locals].FEL_fecdHandle, 0
	;
	; Allocate initial space for the FileEnumCallbackData block we use
	; to talk about files being enumerated.
	; 
		mov	ax, FECD_INITIAL_SIZE
		mov	cx, mask HAF_LOCK shl 8 or mask HF_SWAPABLE
		call	MemAllocFar
		jc	done
	;
	; Set up local variables for the creation of the FECD block.
	; fecdAttrSize is 2 b/c that's all that FEAD_attr requires, and that's
	; all we store for the end-of-list descriptor. This is depended on
	; in FEAddAttrs, so don't get any ideas... :)
	; 
		mov	es, ax
		mov	ss:[locals].FEL_fecdHandle, bx
		mov	ss:[locals].FEL_valueSpaceReqd, 0
		mov	ss:[locals].FEL_fecdAttrSize, 2
		mov	es:[0].FEAD_attr, FEA_END_OF_LIST
	;
	; Copy the attribute descriptors needed for the return buffer into the
	; FECD.
	; 
		lds	si, ss:[params].FEP_returnAttrs
		call	FEAddAttrs
		jc	done
	;
	; If caller has provided attributes we're to match (caller might not
	; have provided any, as it might want all files, or might be leaving
	; the decision up to its own callback routine), merge them into the
	; FECD as well.
	; 
		cmp	ss:[params].FEP_matchAttrs.segment, 0
		jz	checkCallbackAttrs
		lds	si, ss:[params].FEP_matchAttrs
		call	FEAddAttrs
		jc	done

checkCallbackAttrs:
	;
	; If caller has specified a callback routine and additional attributes
	; that are to be fetched for the callback to use, merge them into the
	; FECD as well.
	; 
		test	ss:[params].FEP_searchFlags, mask FESF_CALLBACK
		jz	checkSearchFlags
		cmp	ss:[params].FEP_callbackAttrs.segment, 0
		jz	checkSearchFlags
		lds	si, ss:[params].FEP_callbackAttrs
		call	FEAddAttrs
		jc	done

checkSearchFlags:
	;
	; See if we need to get the geos file type for every file. It depends
	; on the search flags. If all the bits FESF_NON_GEOS, FESF_GEOS_EXECS,
	; and FESF_GEOS_NON_EXECS are set, we can forego the file type, as all
	; files will match.
	; 
		mov	al, ss:[params].FEP_searchFlags
		andnf	al, FILE_ENUM_ALL_FILE_TYPES
		cmp	al, FILE_ENUM_ALL_FILE_TYPES
		je	ensureFileAttr
		
		segmov	ds, cs
		mov	si, offset feFileTypeAttr
		call	FEAddAttrs
		jc	done

ensureFileAttr:
	;
	; We always need to get FEA_FILE_ATTR so we can skip comparing
	; the attributes of a directory against the matchAttrs, thus allowing
	; directories to be displayed in a file selector that's matching
	; based on the file token.
	; 
		segmov	ds, cs
		mov	si, offset feFileAttrAttr
		call	FEAddAttrs
		jc	done

	;
	; First deal with our callback and the possible need for another
	; buffer for file names, etc.
	; 
		call	FESetCallbackEtc
		jc	done
	;
	; All file attributes we'll be wanting, either for comparison,
	; for return, or for our callback, are now stored in the FECD array
	; pointed to by ES. Allocate the appropriate number of bytes after
	; the array and point the individual FEAD entries to their allotted
	; locations within the block.
	; 
		call	FEAllocValueSpace
done:
		.leave
		ret
FEFormFECD	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FEAllocReturnBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate the initial return buffer.

CALLED BY:	FileEnum
PASS:		inherited stack frame
RETURN:		carry set if buffer couldn't be allocated
DESTROYED:	ax, bx, cx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/21/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FEAllocReturnBuffer proc near
		.enter	inherit FileEnum
		mov	ss:[locals].FEL_retBufHandle, 0
	;
	; Allocate the initial return buffer. If the caller has placed a limit
	; on the number of entries we're allowed to return, just allocate that
	; many, as they've probably got a better idea than we of the number of
	; files to expect.
	;
	; If they've placed no limit, use a reasonable number to start off with.
	; 
		mov	ax, ss:[params].FEP_bufSize
		cmp	ax, FE_BUFSIZE_UNLIMITED
		jne	allocInitialBuffer
		mov	ax, FE_INITIAL_BUF_NUMBER
allocInitialBuffer:
		mov	dx, ss:[params].FEP_returnSize
		mul	dx
EC <		ERROR_C	INITIAL_BUFFER_SIZE_TOO_LARGE			>
		tst	ax		;
		jz 	noReturnValuesWanted
		
	;
	; See if the caller wants some space left at the front of the
	; block for a header of its own devising.
	; 
		test	ss:[params].FEP_searchFlags, mask FESF_LEAVE_HEADER
		jz	allocBlock
addHeaderIn:
	;
	; Yes! Add the header into the initial block size and set it as the
	; initial offset for the return buffer.
	; 
		mov	cx, ss:[params].FEP_headerSize
		add	ax, cx
		mov	ss:[locals].FEL_curRetOff, cx
allocBlock:
		mov	cx, (mask HAF_ZERO_INIT shl 8) or mask HF_SWAPABLE or \
				mask HF_SHARABLE
		call	MemAllocFar
		jc	done
			; XXX: could possibly have reduced our request, but
			; our request is usually going to be fairly small, and
			; if the system can't fulfill it, it's probably going
			; to die soon anyway, so...
		mov	ss:[locals].FEL_retBufHandle, bx
done:
		.leave
		ret

noReturnValuesWanted:
	;
	; Initialize appropriate things to 0.
	; 
		mov	ss:[params].FEP_bufSize, ax
		mov	ss:[params].FEP_returnSize, ax
		test	ss:[params].FEP_searchFlags, mask FESF_LEAVE_HEADER
		jnz	addHeaderIn
		jmp	done
FEAllocReturnBuffer endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FECleanup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clean up after a FileEnum and load registers for return

CALLED BY:	FileEnum
PASS:		inherited stack frame
RETURN:		bx	= handle of return buffer
		cx	= number of entries found
		dx	= number of entries missed
		di	= new real skip count, if FESF_REAL_SKIP, else
			  untouched
		flags, ax = as passed
		FECD freed
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/21/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FECleanup	proc	near
		uses	ax
		.enter	inherit FileEnum
		pushf			; save error flag
		push	ax

	;
	; Deal with FESF_REAL_SKIP, leaving DI as it was initially
	; passed in unless FESF_REAL_SKIP is set, in which case we return
	; an updated real skip count as set up by FEEnumCallback...unless
	; there were no missed files, of course...in which case it shouldn't
	; matter as the caller shouldn't call us back, but...
	; 
		test	ss:[params].FEP_searchFlags, mask FESF_REAL_SKIP
		jz	freeFECD
		mov	di, ss:[params].FEP_skipCount
		cmp	ss:[locals].FEL_numMissed, 0
		jnz	freeFECD	; => FEP_skipCount is correct

		sub	di, ss:[locals].FEL_realSkipCount
					; ... else we must adjust by the number
					; enumerated this time, whose negative
					; is in FEL_realSkipCount.
freeFECD:
	;
	; Now we're done, free up callback data segment.
	; 
		mov	bx, ss:[locals].FEL_fecdHandle
		call	MemFree
		
	;
	; Free up the filesSeen buffer, if it was allocated.
	; 
		mov	bx, ss:[locals].FEL_filesSeen
		tst	bx
		jz	checkReturnBuffer
		call	MemFree

checkReturnBuffer:
	;
	; If there's actually a return buffer, shrink it to fit the number
	; of entries we found.
	; 
		mov	bx, ss:[locals].FEL_retBufHandle
		tst	bx
		jz	loadRemainingRegisters
		mov	ax, ss:[locals].FEL_curRetOff
		tst	ax
		jz	noEntriesFound
		clr	cx
		call	MemReAlloc
loadRemainingRegisters:
	;
	; Load registers for return.
	; 
		mov	cx, ss:[locals].FEL_numFound
		mov	dx, ss:[locals].FEL_numMissed

if	TEST_FILE_ENUM_SPEED
		push	bx
		call	TimerGetCount
		sub	ax, cs:[fileEnumTime]
		mov	cs:[fileEnumTime], ax
		pop	bx
endif

done::
		pop	ax
		popf
		jnc	exit
	;
	; Don't return any buffer on error.
	; 
		add	dx, cx			; indicate number missed,
						;  owing to error
		clr	cx			; no files found
		tst	bx			; any buffer to free
		jz	error			; no
		call	MemFree
		clr	bx			; return handle of 0
error:
		stc				; signal error again
exit:
		.leave
		ret

noEntriesFound:
	;
	; If no entries were found, free the return buffer and return bx==0
	; 
		call	MemFree
		clr	bx
		jmp	loadRemainingRegisters
FECleanup	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	FileEnum

DESCRIPTION:	Enumerate files in a directory.

CALLED BY:	GLOBAL

PASS:
	FileEnumParams structure on stack:
	(note: ss:sp *must* be pointing to FileEnumParams)

	stack parameter passing example:

	sub	sp, size FileEnumParams
	mov	bp, sp
	mov	ss:[bp].FEP_*			; fill in params...
	...
	call	FileEnum
	jc	error				; handle error
	<use FileEnum results>			; success!!

RETURN:
	carry - set if error
	ax - error code (if an error)
	bx - handle of buffer created, if any. If no files found, or if
	     error occurred, no buffer is returned (bx is 0)
	cx - number of matching files returned in buffer
	dx - number of matching files that would not fit in buffer
		(given maximum of FEP_bufSize)
		(If FEP_bufSize is set to 0, this is a count of the matching
		 files in the directory)

	(in buffer) - structures (of type requested by FEP_returnAttrs) for
			files found (if filesystem is case-insensitive,
			native names returned in UPPER case)
	if FESF_REAL_SKIP bit set:
		di - updated real skip count (matching file or not)
	if FESF_REAL_SKIP bit clear:
		di - preserved
	FileEnumParams popped off the stack

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
	Adam	4/89		Added skip count
	brianc	1/90		support for GEOS files
------------------------------------------------------------------------------@

if	TEST_FILE_ENUM_SPEED
include timedate.def
fileEnumTime	word	0
endif

FileEnum	proc	far	params:FileEnumParams
locals		local	FileEnumLocals
		uses	ds, si, es
		.enter

if	TEST_FILE_ENUM_SPEED
		push	ax, bx
		call	TimerGetCount
		mov	cs:[fileEnumTime], ax
		pop	ax, bx
endif
	;
	; Save DI in case !FESF_REAL_SKIP
	; 
		push	di
	;------------------------------------------------------------
	;
	;		    FLESH OUT PARAMETERS
	;
	;------------------------------------------------------------
		call	FEFinishParams
	;------------------------------------------------------------
	;
	;	 MERGE EXTENDED ATTRIBUTE DESCRIPTORS
	;
	;------------------------------------------------------------
		call	FEFormFECD
		LONG jc	insufficientMemoryFreeFECD

		clr	ax
		mov	ss:[locals].FEL_numFound, ax
		mov	ss:[locals].FEL_numMissed, ax
		mov	ss:[locals].FEL_retBufHandle, ax
		mov	ss:[locals].FEL_curRetOff, ax
	;
	; Deal with FESF_REAL_SKIP, setting FEL_realSkipCount to 0 if
	; FESF_REAL_SKIP isn't set.
	; 
		test	ss:[params].FEP_searchFlags, mask FESF_REAL_SKIP
		jz	setRealSkip
		mov	ax, ss:[params].FEP_skipCount
setRealSkip:
		mov	ss:[locals].FEL_realSkipCount, ax		

		call	FEAllocReturnBuffer
		jc	insufficientMemoryFreeFECD
	;
	; If we're going to be using a callback, we need to lock
	; LocalUpCaseChar into memory.  This will prevent us from deadlocking
	; when the callback calls FileEnumWildcard while LocalUpCaseChar is
	; not resident in memory.  (FileEnumWildcard -> FEWildcard ->
	; FEStringMatch -> LocalUpCaseChar)
	;
NOFXIP <	test	ss:[params].FEP_searchFlags, mask FESF_CALLBACK	>
NOFXIP <	jz	doIt						>

NOFXIP <	mov	bx, vseg LocalUpcaseChar			>
NOFXIP <	mov	ax, offset LocalUpcaseChar			>
NOFXIP <	call	MemLockFixedOrMovable				>

	;------------------------------------------------------------
	;
	;		IMPLEMENTATION
	;
	;------------------------------------------------------------
doIt::
	;
	; Figure the disk handle for the current path. This will be a member
	; of the StandardPath enumerated type if the current path is in a
	; logical directory whose paths we must enumerate.
	; 
		segmov	ds, es			; ds <- FECD for the duration

		call	FEFetchCurPathDisk
		jc	enumAlongPath
		
		call	FEEnumCurrentPath
		jmp	done

enumAlongPath:
	;
	; Current path is a standard one, so we must do the usual traversal of
	; all the physical paths bound to this logical/standard one.
	; 
		push	cx
		clr	cx		; ds:dx isn't a path
		call	InitForPathEnum
		pop	cx
		jc	dealWithSpecials
		
pathLoop:
	;
	; Advance to the next directory on the path for this logical path.
	; 
		call	SetDirOnPath
		jc	finishPathEnumAndDealWithSpecials
		
		call	FEEnumCurrentPath
		jnc	pathLoop

		clc		; signal error...[sic]

finishPathEnumAndDealWithSpecials:
		call	FinishWithPathEnum
		cmc		; set error flag correctly...
		jc	done		; and skip specials if error
					;  during previous ordeal

dealWithSpecials:
		call	FEEnumSpecials

done:
	;------------------------------------------------------------
	;
	;		CLEAN UP
	;
	;------------------------------------------------------------

	;
	; If we used a callback function, we need to unlock LocalUpcaseChar
	; which we locked above.
	;
NOFXIP <	test	ss:[params].FEP_searchFlags, mask FESF_CALLBACK	>
NOFXIP <	jz	cleanUp						>

NOFXIP <	push	ax, bx						>
NOFXIP <	mov	bx, vseg LocalUpcaseChar			>
NOFXIP <	mov	ax, offset LocalUpcaseChar			>
NOFXIP <	call	MemUnlockFixedOrMovable				>
NOFXIP <	pop	ax, bx						>
NOFXIP <cleanUp:							>
		pop	di		; recover passed DI, in case not
					;  FESF_REAL_SKIP
		call	FECleanup
exit:
		.leave
		ret	@ArgSize


insufficientMemoryFreeFECD:
		mov	bx, ss:[locals].FEL_fecdHandle
		tst	bx
		jz	fecdFreed
		call	MemFree
fecdFreed:
		mov	bx, ss:[locals].FEL_filesSeen
		tst	bx
		jz	insufficientMemoryForFECD
		call	MemFree
insufficientMemoryForFECD:
		mov	ax, ERROR_INSUFFICIENT_MEMORY
		stc
		jmp	exit
FileEnum	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileEnumPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Performs the same function as FileEnum, but accepts a 
		pointer to a static FileEnumParams structure, taking
		care of locking down any virtual segments, etc.

CALLED BY:	GLOBAL
PASS:		ds:si	= FileEnumParams
RETURN:		carry clear if ok:
			bx	= buffer holding structures allocated (bogus
				  if no files found)
			cx	= number of files found
			dx	= number of matching files that wouldn't fit,
				  given maximum of FEP_bufSize (if FEP_bufSize
				  is 0, this is a count of the matching files
				  in the directory)
			if FESF_REAL_SKIP bit set:
				di	= updated real skip count (matching file
					  or not)
			if FESF_REAL_SKIP bit clear:
				di	= preserved
		carry set if error:
			ax	= error code
			bx, cx, dx = destroyed
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/22/92		Initial version
	sh	5/12/94		XIP'ed

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	FULL_EXECUTE_IN_PLACE
CopyStackCodeXIP		segment	resource
FileEnumPtr		proc	far
	;
	; Copy the whole structure onto the stack first.
	;
		push	ds, si
		mov	cx, size FileEnumParams
		call	SysCopyToStackDSSI
		call	FileEnumPtrReal
		call	SysRemoveFromStack
		pop	ds, si
		ret
FileEnumPtr		endp
CopyStackCodeXIP		ends

else

FileEnumPtr		proc	far
	FALL_THRU	FileEnumPtrReal
FileEnumPtr		endp
endif

FileEnumPtrReal	proc	far
		uses	bp
		.enter
	;
	; Copy the whole structure onto the stack first.
	; 
		sub	sp, size FileEnumParams
		mov	bp, sp
		push	es, di
		segmov	es, ss
		mov	di, bp
		mov	cx, size FileEnumParams
		push	si
		rep	movsb
		pop	si
		pop	es, di
	;
	; Now lock anything that needs locking. Note that 0 is less than
	; MAX_SEGMENT and so won't be touched by MemLockFixedOrMovable.
	; 
		mov	bx, ss:[bp].FEP_returnAttrs.segment
		call	MemLockFixedOrMovable
		mov	ss:[bp].FEP_returnAttrs.segment, ax

		mov	bx, ss:[bp].FEP_matchAttrs.segment
		call	MemLockFixedOrMovable
		mov	ss:[bp].FEP_matchAttrs.segment, ax

		test	ss:[bp].FEP_searchFlags, mask FESF_CALLBACK
		jz	callbackHandled

		mov	bx, ss:[bp].FEP_callback.segment

if	FULL_EXECUTE_IN_PLACE

	; On Full-XIP systems, don't lock down code resources in the XIP
	; image, just call the callback using ProcCallFixedOrMovable. 

		tst	bx
		jz	checkWildcard
		cmp	bh, high MAX_SEGMENT
		jb	noLock
		shl	bx, 1
		shl	bx, 1
		shl	bx, 1
		shl	bx, 1
		cmp	bx, LAST_XIP_RESOURCE_HANDLE
		jbe	noLock
		call	MemLock
		mov	ss:[bp].FEP_callback.segment, ax
noLock:
else

		call	MemLockFixedOrMovable
		mov	ss:[bp].FEP_callback.segment, ax
		
		tst	ax		; standard callback?
		jz	checkWildcard		; yes => no attrs, but cbData1
						;  might be wildcard pattern
endif
		mov	bx, ss:[bp].FEP_callbackAttrs.segment
		call	MemLockFixedOrMovable
		mov	ss:[bp].FEP_callbackAttrs.segment, ax
callbackHandled:
	;
	; Call FileEnum to perform the actual work.
	; 
		call	FileEnum
	;
	; Save the error flag and buffer handle and unlock the things we
	; locked before.
	; 
		pushf
		push	bx
		mov	bx, ds:[si].FEP_returnAttrs.segment
		call	MemUnlockFixedOrMovable

		mov	bx, ds:[si].FEP_matchAttrs.segment
		call	MemUnlockFixedOrMovable

		test	ds:[si].FEP_searchFlags, mask FESF_CALLBACK
		jz	callbackUnlockHandled

		mov	bx, ds:[si].FEP_callback.segment
if	FULL_EXECUTE_IN_PLACE

;	On Full-XIP systems, don't unlock the far pointer to the callback
;	routine, as it wasn't locked.

		tst	bx
		jz	checkWildcardUnlock
		cmp	bh, high MAX_SEGMENT
		jb	noUnlock
		shl	bx, 1
		shl	bx, 1
		shl	bx, 1
		shl	bx, 1
		cmp	bx, LAST_XIP_RESOURCE_HANDLE
		jbe 	noUnlock
		call	MemUnlock
noUnlock:
else
		call	MemUnlockFixedOrMovable
		
		tst	bx		; standard callback?
		jz	checkWildcardUnlock	; yes => no attrs, but cbData1
						;  might be wildcard pattern
endif
		mov	bx, ds:[si].FEP_callbackAttrs.segment
		call	MemUnlockFixedOrMovable
callbackUnlockHandled:
	;
	; Restore the buffer handle and error flag for return...
	; 
		pop	bx
		popf
		.leave
		ret

	;
	; Deal with locking and unlocking callback data for callbacks we
	; understand.
	; 
checkWildcard:
CheckHack <FESC_WILDCARD eq 0>
		cmp	ss:[bp].FEP_callback.offset, FESC_WILDCARD
		jbe	lockCBData1

		test	ss:[bp].FEP_searchFlags, mask FESF_LOCK_CB_DATA
		jz	callbackHandled
		
		mov	bx, ss:[bp].FEP_cbData2.segment
		call	MemLockFixedOrMovable
		mov	ss:[bp].FEP_cbData2.segment, ax

lockCBData1:
		mov	bx, ss:[bp].FEP_cbData1.segment
		call	MemLockFixedOrMovable
		mov	ss:[bp].FEP_cbData1.segment, ax
		jmp	callbackHandled

checkWildcardUnlock:
CheckHack <FESC_WILDCARD eq 0>
		cmp	ds:[si].FEP_callback.offset, FESC_WILDCARD
		jbe	unlockCBData1
		
		test	ds:[si].FEP_searchFlags, mask FESF_LOCK_CB_DATA
		jz	callbackUnlockHandled
		
		mov	bx, ds:[si].FEP_cbData2.segment
		call	MemUnlockFixedOrMovable

unlockCBData1:
		mov	bx, ds:[si].FEP_cbData1.segment
		call	MemUnlockFixedOrMovable
		jmp	callbackUnlockHandled

FileEnumPtrReal	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FEEnumCurrentPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ask the appropriate FSD to enumerate all the files in the
		current path.

CALLED BY:	FileEnum
PASS:		ds	= segment of FileEnumCallbackData
		ss:bp	= inherited local variables
RETURN:		carry set on error:
			ax	= error code
DESTROYED:	bx, cx, dx, si, es

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/24/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FEEnumCurrentPath proc	near
		.enter	inherit FileEnum
		call	FileLockInfoSharedToES	; es <- FSIR for the duration
	;
	; Extract the disk handle for the current path into SI for
	; DiskLockCallFSD to use.
	; 
		call	FEFetchCurPathDisk
		mov	si, bx
	;
	; Call the FSD's DR_FS_FILE_ENUM function to do all the hard work.
	; 
		mov	bx, bp		; pass inherited frame in BX since
					;  DiskLockCallFSD destroys BP
		push	bp
		mov	di, DR_FS_FILE_ENUM
		mov	cx, SEGMENT_CS
		mov	dx, ss:[locals].FEL_fsdCallback	; cx:dx <- our callback
		clr	al		; allow disk lock to be aborted
		call	DiskLockCallFSD
	;
	; Reload appropriate registers...
	; 
		pop	bp		; bp <- inherited frame (pushed so BX
					;  can safely be destroyed by the FSD
					;  and the callback)
		call	FSDUnlockInfoShared
		.leave
		ret
FEEnumCurrentPath endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FEEnumCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback function for FSD when it's found a file we're to
		examine.

CALLED BY:	FS Driver
PASS:		ds	= segment of FileEnumCallbackData
		ss:bp	= inherited stack frame
RETURN:		carry set to stop enumerating files:
			ax	= error code
DESTROYED:	es, ax, bx, cx, dx, di, si

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/24/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FEEnumCallback	proc	far
		.enter	inherit FileEnum
	;
	; If performing "real skip", skip this file while FEL_realSkipCount
	; remains non-negative.
	; 
		dec	ss:[locals].FEL_realSkipCount
		LONG jns	skipIt
	;
	; See if the thing is a directory. If it is and FESF_DIRS is set,
	; we accept it unconditionally, else we pass it through the same
	; matching process as a regular file.
	; 
		mov	ax, FEA_FILE_ATTR
		clr	si
		call	FileEnumLocateAttr
EC <		ERROR_C	MISSING_FILE_ATTR_ATTRIBUTE_IN_CALLBACK_DATA	>
EC <		cmp	es:[di].FEAD_value.segment, 0			>
EC <		ERROR_Z	MISSING_FILE_ATTR_ATTRIBUTE_IN_CALLBACK_DATA	>
		mov	di, es:[di].FEAD_value.offset
		test	{FileAttrs}es:[di], mask FA_SUBDIR
		jz	checkMatchAttrs	; not dir, so check matchAttrs array
		
	;
	; If a dir, bail if we're not looking for them. The reverse isn't
	; necessarily true (i.e., it's not a dir and we are looking for
	; them) as we might be looking for other stuff, too.
	;
isDir::
		test	ss:[params].FEP_searchFlags, mask FESF_DIRS
		jnz	checkCallback
		jmp	nomatch

checkMatchAttrs:
	;
	; See if we're supposed to check anything, as indicated by
	; FEP_matchAttrs.segment being non-zero.
	; 
		cmp	ss:[params].FEP_matchAttrs.segment, 0
		jz	checkSearchFlags
	;
	; Ja. Call our nice little utility routine to compare the two arrays
	; of attributes.
	; 
		les	di, ss:[params].FEP_matchAttrs	; es:di <- match attrs
		clr	si		; ds:si <- file attrs
		call	FECompareAttrs
		LONG jc	nomatch

checkSearchFlags:
	;
	; Now deal with the searchFlags, which can't be handled via matchAttrs
	; because they are a union of conflicting values.
	; 
		mov	al, ss:[params].FEP_searchFlags
		and	al, FILE_ENUM_ALL_FILE_TYPES
		cmp	al, FILE_ENUM_ALL_FILE_TYPES
		je	checkCallback
		
		clr	si
		mov	ax, FEA_FILE_TYPE
		call	FileEnumLocateAttr
EC <		ERROR_C	MISSING_FILE_TYPE_ATTRIBUTE_IN_CALLBACK_DATA	>
		mov	al, mask FESF_NON_GEOS
   		cmp	es:[di].FEAD_value.segment, 0
		jz	checkFileTypeOk
		
		mov	di, es:[di].FEAD_value.offset
		cmp	{GeosFileType}es:[di], GFT_NOT_GEOS_FILE
		je	checkFileTypeOk

		mov	al, mask FESF_GEOS_EXECS
		cmp	{GeosFileType}es:[di], GFT_EXECUTABLE
		je	checkFileTypeOk
		
		mov	al, mask FESF_GEOS_NON_EXECS
checkFileTypeOk:
		test	ss:[params].FEP_searchFlags, al
		jz	nomatch

checkCallback:
	;
	; File matched so far as we're concerned. See if there's a callback
	; routine we must consult.
	; 
		test	ss:[params].FEP_searchFlags, mask FESF_CALLBACK
		jz	match
FXIP<		mov	ss:[TPD_dataAX], ax			>
FXIP<		mov	ss:[TPD_dataBX], bx			>
FXIP<		movdw	bxax, ss:[params].FEP_callback		>
FXIP<		call	ProcCallFixedOrMovable			
NOFXIP<		call	ss:[params].FEP_callback		>
		jc	nomatch
match:
	;
	; File has passed all our rigorous tests. See if, after all that, we
	; should actually skip the beast.
	; 
		test	ss:[params].FEP_searchFlags, mask FESF_REAL_SKIP
		jnz	addIt
		dec	ss:[params].FEP_skipCount
		jns	skipIt
addIt:
	;
	; We need to add the file to the return buffer. Oh joy.
	; 
		mov	ax, ss:[locals].FEL_numFound
		cmp	ax, ss:[params].FEP_bufSize
		jae	bufferFull
	;
	; Haven't reached the limit set by FEP_bufSize, but perhaps the return
	; block isn't big enough to hold us?
	; 
		mov	si, ss:[locals].FEL_curRetOff
		mov	cx, ss:[params].FEP_returnSize
		add	cx, si		; cx <- required size of block

		mov	bx, ss:[locals].FEL_retBufHandle
		mov	ax, MGIT_SIZE
		call	MemGetInfo
		cmp	ax, cx
		jae	storeNew
	;
	; Right. Return block is too small. We know now our return size is
	; effectively unlimited, at least as far as the caller is concerned,
	; so we can just enlarge the block we've got. Add another FE_INCR_SIZE
	; entries to the buffer.
	; 
		mov_trash	cx, ax	; cx <- current size
		mov	ax, ss:[params].FEP_returnSize
		mov	dx, FE_INCR_SIZE
		mul	dx
		add	ax, cx
		jc	insufficientMemory	; => need more than 64K
		clr	cx		; no special flags...
		call	MemReAlloc
		jc	insufficientMemory	; => couldn't enlarge
storeNew:
	;
	; Now lock down the return buffer and copy the appropriate attributes
	; out to it.
	; 
		call	MemLock
		mov	es, ax
		mov	di, ss:[locals].FEL_curRetOff	; es:di <- return entry
							;  base
		clr	si				; ds:si <- file attrs
		call	FECopyAttrs
	;
	; Unlock the return buffer and adjust the various loop variables.
	; 
		call	MemUnlock
		add	di, ss:[params].FEP_returnSize
		mov	ss:[locals].FEL_curRetOff, di
		inc	ss:[locals].FEL_numFound
skipIt:
nomatch:
doneOK:
		clc
done::
		.leave
		ret
bufferFull:
	;
	; Not allowed to store this one that matched in the buffer, so up
	; the FEL_numMissed to record it. If this is the first missed file,
	; adjust FEP_skipCount by the current real skip count, which is the
	; negative-1 of the number of files we've been passed before we
	; filled up the buffer (and after we real-skipped all the files
	; the caller asked us to). The -1 is because we've already decremented
	; realSkipCount for this file we've got now.
	; 
	; 
		mov	ax, ss:[locals].FEL_numMissed
		test	ss:[params].FEP_searchFlags, mask FESF_REAL_SKIP
		jz	upNumMissed
		tst	ax
		jnz	upNumMissed
		mov	si, ss:[locals].FEL_realSkipCount
		; equivalent to "not si | add ss:[params].FEP_skipCount, si"
		; but requires fewer bytes and is only a little more obscure
		stc			; don't count this file...
		sbb	ss:[params].FEP_skipCount, si
upNumMissed:
		inc	ax
		mov	ss:[locals].FEL_numMissed, ax
		jmp	doneOK

insufficientMemory:
	;
	; Change the bufSize to be the number of files found so far so we
	; continue to think the thing is full, but also continue to tally
	; those files that won't fit.
	; 
		mov	ax, ss:[locals].FEL_numFound
		mov	ss:[params].FEP_bufSize, ax
		jmp	bufferFull
FEEnumCallback	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FEEnumSpecials
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call our standard callback with the individual subdirectories
		of the current logical path, if such there be, as there could
		well be paths for the logical subdirectories that actually
		exist where real directories of the same name exist nowhere
		on the path for the current logical subdirectory.
		
		For example, suppose we're in SP_PUBLIC_DATA and nowhere on
		the path for SP_PUBLIC_DATA is there a directory named "FONT",
		but there is an .ini file entry saying that FONT lives at
		g:\company\allfonts. We want the directory "FONT" to appear in
		the list for SP_PUBLIC_DATA so if the user navigates into it
		we will properly find the files in g:\company\allfonts.

CALLED BY:	FileEnum
PASS:		ds	= segment of FECD
		es	= segment of shared FSIR
		ss:bp	= inherited local variables
RETURN:		carry set on error:
			ax	= error code
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/25/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FEEnumSpecials	proc	near
		uses	es
		.enter
		segmov	es, ds		; es <- FECD
	;
	; If there's no std path block in the system, DON'T DO THIS, as
	; changing to one of these dirs won't get you anywhere (if there is
	; a std path block, at least there might be a path specified for the
	; thing...)
	; 
		LoadVarSeg	ds, bx
		tst	ds:[loaderVars].KLV_stdDirPaths
		jz	done
	;
	; Make sure we're in just a standard path, i.e. not a standard path
	; with a tail.
	; 
		mov	bx, ss:[TPD_curPath]
		call	MemLock
		mov	ds, ax			; ds <- FilePath
		mov	si, ds:[FP_path]
SBCS <		tst	{char}ds:[si]		; any tail?		>
DBCS <		tst	{wchar}ds:[si]		; any tail?		>
		jz	doItBuckwheat		; no -- do it buckwheat
		call	MemUnlock		; if there's a tail, there
						;  are no logical subdirs
		clc				; so just return ok.
		jmp	done

doItBuckwheat:
		mov	si, ds:[FP_stdPath]
		call	MemUnlock
		
		mov	bx, handle StandardPathStrings
		call	MemLock
		mov	ds, ax
		clr	cx
		push	si
childLoop:
		pop	si
		push	si
		push	cx
		call	StdPathPointAtNthChild
		pop	cx
		cmc
		jnc	doneChildren
		call	FEEnumOneSpecial
		inc	cx
		jnc	childLoop
doneChildren:
		pop	si
		mov	bx, handle StandardPathStrings
		call	MemUnlock
done:
		.leave
		ret
FEEnumSpecials	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FEEnumOneSpecial
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create the necessary attributes for a single logical
		subdirectory, passing it to our main callback for processing.

CALLED BY:	FEEnumSpecials
PASS:		ds:si	= logical subdir name
		es	= segment of FECD
		ss:bp	= inherited stack frame
RETURN:		carry set on error:
			ax	= error code
		carry clear if ok
DESTROYED:	ax, bx, dx, si, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/25/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FEEnumOneSpecial proc	near
		uses	cx, ds
		.enter
		clr	di
attrLoop:
		mov	bx, es:[di].FEAD_attr
		cmp	bx, FEA_END_OF_LIST	; check end-of-list first
						;  since it doesn't have a
						;  full FEAD
		je	eaEndOfList

EC <		cmp	bx, FEA_LAST_VALID				>
EC <		ERROR_A	ILLEGAL_EXTENDED_ATTRIBUTE			>

		mov	es:[di].FEAD_value.segment, es	; assume exists

		shl	bx
		call	cs:[extAttrHandlers][bx]
		add	di, size FileExtAttrDesc
		jmp	attrLoop

eaEndOfList:
	;
	; Hit the end of the list. Discard the return address to the attribute
	; loop and call our standard callback with the correct arguments.
	; 
		segmov	ds, es		; ds <- FECD
		call	FESlowEnumCallback
		segmov	es, ds		; es <- FECD
		.leave
		ret

extAttrHandlers	nptr.near	eaModified,	; FEA_MODIFICATION
			eaFileAttr,		; FEA_FILE_ATTR
			eaSize,			; FEA_SIZE
			eaNonExistent,		; FEA_FILE_TYPE
			eaNonExistent,		; FEA_FLAGS
			eaNonExistent,		; FEA_RELEASE
			eaNonExistent,		; FEA_PROTOCOL
			eaNonExistent,		; FEA_TOKEN
			eaNonExistent,		; FEA_CREATOR
			eaNonExistent,		; FEA_USER_NOTES
			eaNonExistent,		; FEA_NOTICE
			eaNonExistent,		; FEA_CREATION
			eaNonExistent,		; FEA_PASSWORD
			eaNonExistent,		; FEA_CUSTOM
			eaName,			; FEA_NAME
			eaNonExistent,		; FEA_GEODE_ATTR
			eaPathInfo,		; FEA_PATH_INFO
			eaFileID,		; FEA_FILE_ID
			eaNonExistent,		; FEA_DESKTOP_INFO
			eaDriveStatus,		; FEA_DRIVE_STATUS
			eaDisk,			; FEA_DISK
			eaName,			; FEA_DOS_NAME
			eaNonExistent,		; FEA_OWNER
			eaNonExistent,		; FEA_RIGHTS
			eaNonExistent		; FEA_TARGET_FILE_ID
.assert (length extAttrHandlers) eq (FEA_LAST_VALID+1)
eaModified:
	;
	; Current date & time? Ancient history? What?
	;
		;XXX
		retn

eaFileAttr:
	;
	; These logical subdirectories have only the FA_SUBDIR attribute.
	; They're not hidden or system, nor do they have longnames...
	; 
		mov	bx, es:[di].FEAD_value.offset
		mov	{FileAttrs}es:[bx], mask FA_SUBDIR
		retn
eaName:
	;
	; Copy ds:si into the value area.
	; 
		push	si, di
		mov	cx, es:[di].FEAD_size
		mov	di, es:[di].FEAD_value.offset
nameCopyLoop:
		LocalGetChar ax, dssi
		LocalPutChar esdi, ax
		LocalIsNull ax
		loopne	nameCopyLoop
		pop	si, di
		retn

eaSize:
	;
	; Store the size of the "directory". We say it's 0 for now...
	; 
		mov	bx, es:[di].FEAD_value.offset
		clr	ax
		mov 	({dword}es:[bx]).low, ax
		mov	({dword}es:[bx]).high, ax
		retn

eaPathInfo:
	;
	; Store the containing logical path with DPI_EXISTS_LOCALLY set false
	; so the caller knows this "directory" doesn't actually exist.
	; 
		call	FEFetchCurPathDisk
		mov_trash	ax, bx
		andnf	ax, mask DPI_STD_PATH
		mov	bx, es:[di].FEAD_value.offset
		mov	{DirPathInfo}es:[bx], ax
		retn

eaFileID:
	;
	; Store FILE_NO_ID for the beast, as it'll never change...
	; 
		mov	bx, es:[di].FEAD_value.offset
		mov	({dword}es:[bx]).low, FILE_NO_ID and 0xffff
		mov	({dword}es:[bx]).high, FILE_NO_ID shr 16
		retn

eaDisk:
	;
	; Store system disk, always
	; 
		mov	bx, es:[di].FEAD_value.offset
		push	ds
		LoadVarSeg	ds, ax
		mov	ax, ds:[topLevelDiskHandle]
		pop	ds
		mov	es:[bx], ax
		retn
		

eaNonExistent:
	;
	; Request for an attribute this "directory" doesn't have, so clear the
	; FEAD_value.segment to indicate its absence.
	; 
		mov	es:[di].FEAD_value.segment, 0
		retn

eaDriveStatus:
	;
	; Use extended status for top-level disk.
	; 
		push	ds
		LoadVarSeg	ds, ax
		mov	bx, ds:[topLevelDiskHandle]
		call	DiskGetDrive
		call	DriveGetExtStatus
		pop	ds
		mov	bx, es:[di].FEAD_value.offset
		mov	es:[bx], ax
		retn

FEEnumOneSpecial endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FESlowEnumCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Slower callback that's a front-end to FEEnumCallback and
		is responsible for remembering the names of all files
		we've been told about so far and not passing duplicates
		off to FEEnumCallback

CALLED BY:	FSD
PASS:		ds	= segment of FECD with current file's attributes
		ss:bp	= inherited stack frame
RETURN:		carry set to stop enumerating files:
			ax	= error code
DESTROYED:	es, ax, bx, cx, dx, di, si

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/26/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FESlowEnumCallback proc	far
		.enter	inherit	FileEnum
	;
	; Find the FEA_NAME attribute in the FECD.
	; 
		segmov	es, ds
		clr	di
		segmov	ds, cs
		mov	si, offset feNameAttr
		call	FELocateAttr
EC <		ERROR_NC	NAME_ATTRIBUTE_NOT_IN_FECD		>
EC <		cmp	es:[di].FEAD_value.segment, 0			>
EC <		ERROR_Z		NAME_ATTRIBUTE_NOT_IN_FECD		>
	;
	; Determine the length of the file's name, exclusive of its null
	; terminator.
	; 
if DBCS_PCGEOS
		push	di
		mov	di, es:[di].FEAD_value.offset
		call	LocalStringLength	;cx <- length of name w/o null
		pop	di
else
		clr	al
		push	di
		mov	cx, -1
		mov	di, es:[di].FEAD_value.offset
		repne	scasb
		not	cx
		dec	cx		; cx <- length of name w/o null
		pop	di
endif
	;
	; Now we need to see if the file is already listed in the filesSeen
	; block. First, we have to lock the beggar down.
	; 
		mov	bx, ss:[locals].FEL_filesSeen
		call	MemLock
		mov	ds, ax
		clr	si		; buffer starts at offset 0
		mov	di, es:[di].FEAD_value.offset	; es:di <- file name
compareLoop:
	;
	; See if we've made it to the end of the buffer. If so, the file
	; obviously hasn't been seen before.
	; 
		cmp	si, ss:[locals].FEL_fsFree
		jae	notSeen
	;
	; Compare this string to the file name, checking the size words first
	; as a first approximation.
	; 
		lodsw			; ax <- size
		cmp	cx, ax		; same?
		je	compare		; yes -- go perform the string compare
DBCS <		shl	ax, 1						>
		add	si, ax		; nope -- skip this entry and loop
		jmp	compareLoop

compare:
	;
	; Strings are of the same size, so use repe cmpsb to compare the two.
	;
		push	di
SBCS <		repe	cmpsb						>
DBCS <		repe	cmpsw						>
		pop	di
		je	found
	;
	; Strings didn't match, so advance SI to the next entry by adding the
	; count remaining in CX to it. Since the strings are the same size,
	; AX is also the length of the file's name, so we can restore CX from
	; there before we loop back.
	; 
DBCS <		shl	cx						>
		add	si, cx
		mov_trash	cx, ax
		jmp	compareLoop
found:
	;
	; File already seen, so release the filesSeen buffer and return
	; that everything's ok, but don't call our main callback with the file.
	; 
		call	MemUnlock
		segmov	ds, es		; ds <- FECD again
		clc
done:		
		.leave
		ret

	;--------------------
notSeen:
	;
	; The file's not been seen before, so see if its name will fit in
	; the filesSeen buffer as it currently stands. The current
	; register contents, for those who are keeping score, are:
	; 	ds:si	= place at which to store the filename
	; 	es:di	= the filename to store
	; 	cx	= the length of the filename to store
	; 	bx	= filesSeen block handle
	; 
		mov	ax, MGIT_SIZE
		call	MemGetInfo		; ax <- block size (bytes)
		lea	dx, [si+2]
		add	dx, cx			; dx <- fsFree after entry is
						;  added (string length + size
						;  word)
		cmp	ax, dx			; enough?
		jae	storeIt			; yes
	;
	; Not enough room in the filesSeen buffer, so add another
	; FE_FILES_SEEN_INCR_SIZE bytes to the block's current size.
	; 
		add	ax, FE_FILES_SEEN_INCR_SIZE
EC <		cmp	ax, dx						>
EC <		ERROR_B	PREPOSTEROUS_FILE_NAME_LENGTH			>
		push	cx			; save name length
		clr	cx			; no special allocation flags
		call	MemReAlloc		; enlarge...
		pop	cx
		jc	error			; => out o' memory
		mov	ds, ax			; ds <- new segment (since
						;  block is already locked)
storeIt:
	;
	; Copy the string into the filesSeen buffer. Alas, the registers
	; are in exactly the wrong order, so swap them.
	; 
		xchg	si, di
		segxchg	es, ds		; ds:si <- file name, es:di <- storage
		mov	ax, cx
		stosw			; store size word
SBCS <		rep	movsb		; and copy the file name	>
DBCS <		rep	movsw		; and copy the file name	>
	;
	; Record the new first-free byte in the local variables and unlock our
	; filesSeen buffer.
	; 
		mov	ss:[locals].FEL_fsFree, di
		call	MemUnlock
	;
	; Call the regular callback to finally deal with the file.
	; 
		call	FEEnumCallback
		jmp	done

error:
	;
	; Couldn't enlarge the filesSeen buffer, so this particular
	; enumeration is complete. Unlock the buffer, restore ds to the
	; FECD, in case anyone cares, and return the appropriate error.
	; 
		call	MemUnlock
		segmov	ds, es		; ds <- FECD
		mov	ax, ERROR_INSUFFICIENT_MEMORY
		stc
		jmp	done
FESlowEnumCallback endp

;------------------------------------------------------------------------------
;
;	       UTILITY ROUTINES FOR APPLICATIONS TO USE
;
;------------------------------------------------------------------------------



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileEnumWildcard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the virtual name for the current file matches
		the pattern in FEP_cbData1.

CALLED BY:	FileEnum, GLOBAL
PASS:		ds	= segment of FileEnumCallbackData
		ss:bp	= inherited stack frame:
			params.FEP_cbData1	= fptr to pattern to match
			params.FEP_cbData2.low	= non-zero if matching should
						  be case-insensitive
RETURN:		carry clear if FEA_NAME attribute matches passed pattern
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/14/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileEnumWildcard proc	far
		uses	ax
		.enter	inherit	FileEnum
		mov	ax, FEA_NAME
		call	FEWildcard
		.leave
		ret
FileEnumWildcard endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FEWildcard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common routine for FileEnumWildcard and FileEnumNativeWildcard
		to actually to the work they want to do.

CALLED BY:	FileEnumNativeWildcard, FileEnumWildcard
PASS:		ds	= segment of FileEnumCallbackData
		ax	= FileExtendedAttribute against which to compare
			  FEP_cbData1
		ss:bp	= inherited stack frame
			params.FEP_cbData1	= fptr to pattern to match
			params.FEP_cbData2.low	= non-zero if matching should
						  be case-insensitive
RETURN:		carry clear if attribute matches passed pattern.
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/14/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FEWildcard	proc	near
		uses	bx, cx, si, di, ds, es
		.enter	inherit FileEnum
		clr	si		; ds:si <- array in which to search
		call	FileEnumLocateAttr
EC <		ERROR_C	MISSING_NAME_ATTRIBUTE_IN_CALLBACK_DATA		>
NEC <		jc	done						>
		les	di, es:[di].FEAD_value
		lds	si, ss:[params].FEP_cbData1
		mov	cx, ss:[params].FEP_cbData2.low
		call	FEStringMatch
NEC <done:								>
		.leave
		ret
FEWildcard	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FEStringMatch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform UNIX-standard wildcard matching of a string against
		a pattern. In the pattern, the following characters have
		special meaning:
			*	= 0 or more of any character
			?	= any single character
			[..]	= a character range, where a single character
				  within the range matches.
			[^..]	= an inverse character range, where a single
				  character not within the range matches.
		The special meaning of these characters can be escaped by
		preceding them with a backslash.

CALLED BY:	FEWildcard
PASS:		ds:si	= pattern to match
		es:di	= string being matched
		cx	= non-zero if matching should be case-insensitive
RETURN:		carry clear if string matches the pattern.
DESTROYED:	si, di, ax, bx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Perhaps lock LocalUpcaseChar at the start? Requires another
		level, as locking it each recursion would be a waste of time.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/14/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FEStringMatch	proc	near
		.enter
compareChar:
	;
	; Get pattern character into AL and string character into BL. If
	; we're being insensitive to case, upcase both.
	; 
SBCS <		clr	ax						>
SBCS <		mov	bx, ax						>
SBCS <		mov	al, ds:[si]					>
SBCS <		mov	bl, es:[di]					>
DBCS <		mov	ax, ds:[si]					>
DBCS <		mov	bx, es:[di]					>
		jcxz	haveChars
		call	LocalUpcaseChar
		xchg	ax, bx
		call	LocalUpcaseChar
		xchg	ax, bx
haveChars:
	;
	; If at end of the pattern, only match if at the end of the string.
	; 
		LocalIsNull ax
		jnz	checkSubstring
		LocalIsNull bx
		jz	done
fail:
		stc
done:
		.leave
		ret

	;--------------------
checkSubstring:
	;
	; If pattern char is *, it matches any substring. We handle this quite
	; simply by recursing for each possible suffix of the string until
	; we either reach the end of the string without matching, or we
	; find one that matches. As a simple optimization, if * is the last
	; character in the pattern, we declare a match immediately.
	; 
		LocalCmpChar ax, '*'
		jne	checkSingle

		LocalNextChar dssi	; advance pattern pointer so we're
					;  matching against the rest of the
					;  pattern.
SBCS <		tst	{char}ds:[si]					>
DBCS <		tst	{wchar}ds:[si]					>
		jz	done
starLoop:
		push	si, di
		call	FEStringMatch	; check current suffix
		pop	si, di
		jnc	done		; match => happiness

	    ;
	    ; advance to next (shorter) suffix and loop if we're not at the
	    ; end of the string.
	    ;
		LocalNextChar esdi
SBCS <		tst	{char}es:[di]					>
DBCS <		tst	{wchar}es:[di]					>
		jnz	starLoop
	    ;
	    ; hit end of string w/o finding a suffix that matched, so declare
	    ; a mistrial.
	    ;
		jmp	fail

	;--------------------
checkSingle:
	;
	; If pattern char is ?, it matches any character in the string except
	; the null-terminator.
	; 
		LocalCmpChar ax, '?'
		jne	checkRange
		
		LocalIsNull bx
		jnz	nextChar

		jmp	fail

	;--------------------
checkRange:
	;
	; If pattern char is '[', it introduces a range of possible matches.
	; 
		LocalCmpChar ax, '['
		jne	checkBackslash
		
		push	dx
		clr	dx		; assume not inverse

		LocalNextChar dssi
SBCS <		cmp	{char}ds:[si], '^'	; inverse range?	>
DBCS <		cmp	{wchar}ds:[si], '^'	; inverse range?	>
		jne	rangeLoop
		not	dx		; flag inverse
rangeLoop:
	    ;
	    ; Fetch next char of range, upcasing as necessary.
	    ; 
		LocalGetChar ax, dssi
		jcxz	haveNextPatternChar
		call	LocalUpcaseChar
haveNextPatternChar:
	    ;
	    ; If pattern character is ] or the null-terminator, then the range
	    ; is complete (XXX: what about backslash to escape ]?)
	    ; 
		LocalCmpChar ax, ']'
		je	rangeCheckDone
		LocalIsNull ax		; XXX: unterminated range
		je	rangeCheckDone
SBCS <		cmp	al, bl						>
DBCS <		cmp	ax, bx						>
		je	rangeMatch
		ja	ignoreSubRange	; if pattern char above string char,
					;  we need to ignore any following
					;  subrange (as introduced via a - as
					;  the next character), as string can't
					;  possibly be in the subrange.

	    ;
	    ; If subrange indicated (next pattern char is -), fetch the end
	    ; of the subrange, upcase it as necessary, and see if the string
	    ; char falls under or at the end char, indicating it's in the
	    ; subrange, since we already know the string char is above
	    ; the start of the subrange.
	    ; 
SBCS <		cmp	{char}ds:[si], '-'				>
DBCS <		cmp	{wchar}ds:[si], '-'				>
		jne	rangeLoop

		LocalNextChar dssi
		LocalGetChar ax, dssi
		jcxz	haveSecondRangeChar
		call	LocalUpcaseChar
haveSecondRangeChar:
		LocalIsNull ax
		jz	rangeCheckDone	; XXX: unterminated range
SBCS <		cmp	al, bl						>
DBCS <		cmp	ax, bx						>
		jb	rangeLoop	; pattern below string, so string char
					; outside of range...
rangeMatch:
	    ;
	    ; String char matched the pattern char or fell within one of its
	    ; subranges. Invert our return value (DX) to indicate this, thus
	    ; giving us non-zero for a standard range and 0 for an inverse
	    ; range.
	    ; 
		not	dx
SBCS <		mov	al, 1	; so we don't decide the character on which >
DBCS <		mov	ax, 1	; so we don't decide the character on which >
				;  we stopped (which might be ]) is actually
				;  the end of the range...

rangeCheckDone:
	    ;
	    ; We've either gone through all the chars of the range, or have
	    ; decided the thing matched the range, so make sure ds:si points
	    ; past the range.
	    ;
		LocalCmpChar ax, ']'
		je	testRangeResult
		LocalIsNull ax
		jz	unterminatedRange
		LocalGetChar ax, dssi
		jmp	rangeCheckDone

ignoreSubRange:
	    ;
	    ; String char fell below first char of possible subrange, so we've
	    ; only to skip the subrange if we see it.
	    ; 
SBCS <		cmp	{char}ds:[si], '-'				>
DBCS <		cmp	{wchar}ds:[si], '-'				>
		jne	rangeLoop
		LocalNextChar dssi
		LocalGetChar ax, dssi
		LocalIsNull ax
		jnz	rangeLoop

unterminatedRange:
		LocalPrevChar dssi	; point back at null so we know we're
					;  done with the pattern

testRangeResult:
	    ;
	    ; DX contains the result of the comparison. 0 if string char isn't
	    ; in the range, and non-zero if it did. Because we initialize DX to
	    ; -1 if an inverse range was specified, and use "not dx" to flag
	    ; a match, we need only tst dx here to decide whether to accept
	    ; the string char as matching or not.
	    ; 
		tst	dx
		pop	dx
		jnz	nextStringChar	; si already advanced past range...
		jmp	fail

	;--------------------
checkBackslash:
	;
	; If pattern char is a backslash, it escapes special meaning for the
	; following character, unless following character is the null-
	; terminator, in which case the match fails.
	; 
		LocalCmpChar	ax, C_BACKSLASH
		jne	checkNormal
		LocalNextChar dssi
		LocalGetChar ax, dssi, NO_ADVANCE
		LocalIsNull ax
		LONG jz	fail
		jcxz	checkNormal
		call	LocalUpcaseChar
	;--------------------
checkNormal:
SBCS <		cmp	al, bl						>
DBCS <		cmp	ax, bx						>
		LONG jne	fail
nextChar:
		LocalNextChar dssi
nextStringChar:
		LocalNextChar esdi
		jmp	compareChar
FEStringMatch	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileEnumLocateAttr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Locate an extended attribute in an array of extended
		attribute descriptors.

CALLED BY:	GLOBAL
PASS:		ax	= FileExtendedAttribute (FEA_MULTIPLE not allowed)
		ds:si	= array in which to search
		es:di	= attribute name, if FEA_CUSTOM
RETURN:		carry set if attribute couldn't be found
			es, di destroyed
		carry clear if attribute found:
			es:di	= FileExtAttrDesc
			If the file doesn't have this attribute, then
			es:di.FEAD_value.segment will be zero.
DESTROYED:	es, di (if not returned)

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/27/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileEnumLocateAttr proc	far
attr		local	FileExtAttrDesc
		uses	dx, ds, si
		.enter
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptrs passed in are valid
	;
EC <		pushdw	bxsi						>
EC <		mov	bx, ds						>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		cmp	ax, FEA_CUSTOM					>
EC <		jne	xipSafe						>
EC <		movdw	bxsi, esdi					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <	xipSafe:							>
EC <		popdw	bxsi						>
endif
	;
	; Set up the attribute descriptor to pass to our internal routine.
	; 
		mov	ss:[attr].FEAD_attr, ax
		mov	ss:[attr].FEAD_name.offset, di
		mov	ss:[attr].FEAD_name.segment, es
	;
	; Adjust registers accordingly.
	; 
		segmov	es, ds
		mov	di, si
		segmov	ds, ss
		lea	si, ss:[attr]
	;
	; Go a-hunting.
	; 
		call	FELocateAttr
		cmc			; return carry set if *not* found
		.leave
		ret
FileEnumLocateAttr		endp

FileenumCode	ends
