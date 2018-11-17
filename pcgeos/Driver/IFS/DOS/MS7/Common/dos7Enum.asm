COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		driEnum.asm

AUTHOR:		Adam de Boor, Oct 31, 1991

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	10/31/91	Initial revision


DESCRIPTION:
	Implementation of DR_FS_FILE_ENUM
		

	$Id: dos7Enum.asm,v 1.1 97/04/10 11:55:29 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


ExtAttrs	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSFileEnum
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enumerate all files/dirs in the thread's current directory
		calling the kernel back for each one after gathering whatever
		extended file attributes are requested.

CALLED BY:	DR_FS_FILE_ENUM
PASS:		cx:dx	= vfptr of routine to call back
		ds	= segment of FileEnumCallbackData
		es:si	= DiskDesc of current path, with FSIR and drive locked
			  shared. Disk is locked into drive.
		ss:bx	= stack frame to pass to callback
RETURN:		carry set if no files/dirs to enumerate:
			ax	= ERROR_NO_MORE_FILES
		else carry & registers as set by callback routine.
DESTROYED:	ax, bx, cx, dx may all be nuked before the callback is
		called, but not if it returns carry set.
		bp may be destroyed before & after the callback.

PSEUDO CODE/STRATEGY:
		The callback function is called as:
			Pass:	ds	= segment of FileEnumCallbackData.
					  Any attribute descriptor for which
					  the file has no corresponding
					  attribute should have the
					  FEAD_value.segment set to 0. All
					  others must have FEAD_value.segment
					  set to DS when their value is stored.
				ss:bp	= ss:bx passed to FSD
			Return:	carry set to stop enumerating files:
					ax	= error code
			Destroy:es, bx, cx, dx, di, si

		If the filesystem supports the "." and ".." special directories,
		they must *not* be passed to the callback routine.
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/31/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSFileEnum	proc	far
		uses	di, si, es, ds
		.enter
		mov	ax, size FileGetExtAttrData
		push	cx, bx
		mov	cx, mask HF_FIXED
		call	MemAlloc
		pop	cx, bp
		jnc	haveDataBlock
		mov	ax, ERROR_INSUFFICIENT_MEMORY
		jmp	exit

haveDataBlock:
	;
	; Make sure our thread has the CWD installed in DOS, now we've actually
	; been able to allocate the block.
	; 
		call	DOSEstablishCWD
		jnc	haveCWD
		call	DOSUnlockCWD
		jmp	exit
haveCWD:
	;
	; Fill in the various pieces of our data block.
	; 
		push	cx, bx
			CheckHack <offset FECD_attrs eq 0>
		clr	bx
		mov	cx, -1
countAttrsLoop:
		inc	cx
		cmp	ds:[bx].FEAD_attr, FEA_END_OF_LIST
		lea	bx, ds:[bx+size FileExtAttrDesc]
		jne	countAttrsLoop

		pop	bx
		push	ds			; push FECD
		mov	ds, ax
		pop	ds:[FGEAD_attrs].segment; to pop it into place
		mov	ds:[FGEAD_attrs].offset, 0
		mov	ds:[FGEAD_numAttrs], cx
		mov	ds:[FGEAD_block], bx
		clr	ds:[FGEAD_spec].FGEASD_enum.FED_enumFlags
		pop	cx
	    ;
	    ; Fetch the DirPathInfo from the thread's current path.
	    ; 
		mov	bx, ss:[TPD_curPath]
		call	MemLock
		mov	es, ax
		mov	ax, es:[FP_pathInfo]
		call	MemUnlock
		mov	ds:[FGEAD_pathInfo], ax
	    ;
	    ; Store away the callback routine, so we can call it easily.
	    ; 
		mov	ds:[FGEAD_spec].FGEASD_enum.FED_callback.offset, dx
		mov	ds:[FGEAD_spec].FGEASD_enum.FED_callback.segment, cx
	    ;
	    ; Save the frame the kernel expects.
	    ; 
		mov	ds:[FGEAD_spec].FGEASD_enum.FED_kernelFrame, bp
	    ;
	    ; Pattern is always *.* for this, as we want to see everything.
	    ; We make no judgements on our own, save the exclusion of . and ..
	    ; 
		mov	{word}ds:[FGEAD_spec].FGEASD_enum.FED_pattern[0],
				'*' or ('.' shl 8)
		mov	{word}ds:[FGEAD_spec].FGEASD_enum.FED_pattern[2],
				'*' or (0 shl 8)

	    ;
	    ; Set things for DOSVirtGetExtAttrsLow
	    ; 
	    	mov	ds:[FGEAD_disk], si
		mov	ds:[FGEAD_flags], mask FGEAF_CLEAR_VALUE_SEG_IF_ABSENT
					; remaining flags filled in by
					;  DOSVirtGetExtAttrsLow
if _MS7
		mov	ds:[FGEAD_fd].segment, ds
		mov	ds:[FGEAD_fd].offset,
				offset FGEAD_spec.FGEASD_enum.FED_fd
		clr	ds:[FGEAD_fdSearchHandle]
else

		mov	ds:[FGEAD_dta].segment, ds
		mov	ds:[FGEAD_dta].offset, 
				offset FGEAD_spec.FGEASD_enum.FED_dta
endif
	;
	; Set DOS function to invoke to get the next file/dir/whatever to
	; actually get the first one.
	; 
if _MS7
	;
	; It's easier to do the FindFirst outside of the loop as we
	; need to be sure to store the search handle here, but not
	; after FindNexts.
	;
		mov	ax,MSDOS7F_FIND_FIRST
		les	di, ds:[FGEAD_fd]	; es:di <- FindData
		mov	ds:[FGEAD_spec].FGEASD_enum.FED_fd.\
				W32FD_fileName.MSD7GN_shortName, 0
		mov	si, DOS7_DATE_TIME_MS_DOS_FORMAT
		mov	dx, offset FGEAD_spec.FGEASD_enum.FED_pattern
		mov	cx, mask FA_HIDDEN or mask FA_SYSTEM or mask FA_SUBDIR
		call	DOSUtilInt21
		ERROR_C	-1
		mov	ds:[FGEAD_fdSearchHandle], ax
		jmp	afterInt21
else
		mov	ah, MSDOS_FIND_FIRST
endif
findLoop:
	;
	; ds	= FileGetExtAttrData
	; ah	= DOS function to call to find the first/next beast
	; 		(ax if MS7)

if not _MS7
	;
	; Snag BIOS lock so we can set the DTA w/o worry, then do that.
	; 
		call	SysLockBIOS
		push	ax
		mov	dx, offset FGEAD_spec.FGEASD_enum.FED_dta
		mov	ah, MSDOS_SET_DTA
		call	DOSUtilInt21
		pop	ax
endif
	;
	; Enumerate *all* files, including hidden and system ones; the kernel
	; will filter as appropriate.
	;
if _MS7		
		mov	bx, ds:[FGEAD_fdSearchHandle]
		les	di, ds:[FGEAD_fd]	; es:di <- FindData
		mov	ds:[FGEAD_spec].FGEASD_enum.FED_fd.\
				W32FD_fileName.MSD7GN_shortName, 0
		mov	si, DOS7_DATE_TIME_MS_DOS_FORMAT
endif
		mov	dx, offset FGEAD_spec.FGEASD_enum.FED_pattern
		mov	cx, mask FA_HIDDEN or mask FA_SYSTEM or mask FA_SUBDIR
		call	DOSUtilInt21

if not _MS7
		call	SysUnlockBIOS
endif
		jc	checkComplete	; error => complete for one reason or
					;  another
	;
	; We're not supposed to pass . or .. to the callback. Since these are
	; the only files that start with . in the DOS universe, we have only
	; to check the first char for being . and bail if so.
	;
if _MS7
afterInt21:
		cmp	ds:[FGEAD_spec].FGEASD_enum.FED_fd.W32FD_fileName.MSD7GN_longName, '.'
else
		cmp	ds:[FGEAD_spec].FGEASD_enum.FED_dta.FFD_name, '.'
endif
		je	endFindLoop
	;
	; Deal with some unknown public-domain utility program Brian Chin
	; just told me about that likes to create entries with no name.
	; 
if _MS7
		cmp	ds:[FGEAD_spec].FGEASD_enum.FED_fd.W32FD_fileName.MSD7GN_longName, 0
else
		cmp	ds:[FGEAD_spec].FGEASD_enum.FED_dta.FFD_name, 0
endif
		je	endFindLoop
	;
	; Initialize the header state to indicate we haven't loaded it yet.
	; 
		andnf	ds:[FGEAD_flags], 
			not (mask FGEAF_NOT_GEOS or mask FGEAF_HAVE_HEADER or mask FGEAF_HAVE_LONG_NAME_ATTRS)
	;
	; See if this might be a special directory file that we should
	; manifestly not be passing to the callback.
	; 
if _MS7
		test	ds:[FGEAD_spec].FGEASD_enum.FED_fd.\
				W32FD_fileAttrs.low.low, mask FA_SUBDIR
else
		test	ds:[FGEAD_spec].FGEASD_enum.FED_dta.FFD_attributes,
				mask FA_SUBDIR
endif
		jnz	fillFECD	; actually a dir, so we don't care
					;  about name or file type
if _MS7
		cmp	ds:[FGEAD_spec].FGEASD_enum.FED_fd.W32FD_fileName.MSD7GN_longName[0], '@'
else
		cmp	ds:[FGEAD_spec].FGEASD_enum.FED_dta.FFD_name[0], '@'
endif
		jne	fillFECD
	;
	; Begins with an at-sign, which is a good start... See if it's got
	; a header.
	; 
		call	DOSVirtGetExtAttrsEnsureHeader
		jc	fillFECD		; nope => not dir special
		cmp	ds:[FGEAD_header].GFH_type, GFT_DIRECTORY
		jne	fillFECD
	;
	; It's the special @DIRNAME.000 file.  Set a flag, so that
	; we'll open it later and read links. XXX: Maybe we should
	; just read them now.
	;
		ornf	ds:[FGEAD_spec].FGEASD_enum.FED_enumFlags, 
						mask DFEF_DIRECTORY_FILE
		jmp	endFindLoop

fillFECD:
	;
	; Assume all attributes will be there...
	; 
		call	DOSEnumInitAttrs

	;
	; Check to see if we have attributes in the long name and set the
	; flag if so.  We can also tell if this is a geos file
	;
MS7<	 	call	DOS7SetLongNameFlags				>
	;
	; Now try and fetch them.
	; 
		call	DOSVirtGetExtAttrsLow
	;
	; All the extended attributes have been filled in, or not, as
	; appropriate, and we're ready now to call the kernel back.
	;
		call	DOSEnumCallCallback
		jc	done			; => stop enumerating and don't
						;  biff any registers
endFindLoop:		
	;
	; Switch to the "find next" call and go for the next file.
	; 
if _MS7
		mov	ax, MSDOS7F_FIND_NEXT
else
		mov	ah, MSDOS_FIND_NEXT
endif
		jmp	findLoop		

	;--------------------
checkComplete:
	;
	; Got an error back from DOSUtilInt21. If it's "no more files,
	; bozo", we don't actually count it an error.  XXX: aren't we
	; supposed to return this error if there were no files period?
	; 
		cmp	ax, ERROR_NO_MORE_FILES
		je	enumLinks		; (carry clear if ==)
		stc
done:
	;
	; Free our data block and restore the FECD segment.
	;
		pushf

if _MS7
		push	bx
		mov	bx, ds:[FGEAD_fdSearchHandle]
		tst	bx
		jz	freeFGEAD

		mov	ax, MSDOS7F_FIND_CLOSE
		call	DOSUtilInt21 
freeFGEAD:
else
		push	bx		
endif		
		mov	bx, ds:[FGEAD_block]
		mov	ds, ds:[FGEAD_attrs].segment	; return ds = FECD
		call	MemFree
		pop	bx
	;
	; Release the working directory lock and boogie.
	;
		call	DOSUnlockCWD
		popf

exit:
		.leave
		ret

enumLinks:
	
	;
	; Now, enumerate the links, if we noticed before that the
	; dirname file exists.  There are some systems (on NOVELL),
	; where we're actually able to open a DIRNAME file, even when
	; one doesn't exist in the CWD.  Hopefully, using this flag
	; will prevent such things. -chrisb
	;

		test	ds:[FGEAD_spec].FGEASD_enum.FED_enumFlags, 
				mask DFEF_DIRECTORY_FILE
		jz	done

NOFXIP<		push	cs						>
FXIP<		mov	dx, SEGMENT_CS					>
FXIP<		push	dx						>
		mov	dx, offset DOSFileEnumLinks
		push	dx
		call	DOSLinkEnum
		jmp	done

DOSFileEnum	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOS7SetLongNameFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the current file has attributes in the long name, and
		whether or not it is a geos file.  Set flags appropriately.

CALLED BY:	DOSFileEnum

PASS:		es:di	= FindData containing the name
		ds	= FGEAD
RETURN:		nothing
DESTROYED:	ax, cx, di

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimw	1/22/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
nativeString	char	MSDOS7_NATIVE_SIGNATURE, 0

DOS7SetLongNameFlags	proc	near
		.enter
	;
	; First check the short name to see if this is in fact a long name.
	; The short name field will be zero if not a long name.  If that's
	; true, then we don't set any flags; no long name, and we can't be
	; sure about whether or not it's a geos file.
	;
		tst	es:[di].W32FD_fileName.MSD7GN_shortName
		jz	done
	;
	; Now check for the NATIVE string in signature space.  If NATIVE, then
	; we don't have a geos file.  If not, then we have a valid long name.
	; But if this is a subdir, don't do it.
	;
		clr	ax
		test	es:[di].W32FD_fileAttrs.low.low, mask FA_SUBDIR
		jnz	doFlags

		push	ds, si
		lea	di, es:[di].W32FD_fileName.MSD7GN_signature
		segmov	ds, cs
		mov	si, offset nativeString
		mov	cx, size nativeString
		repe	cmpsb
		mov	ax, mask FGEAF_NOT_GEOS
		jz	doFlags

		mov	ax, mask FGEAF_HAVE_LONG_NAME_ATTRS
doFlags:
	; Set the appropriate flag.
		pop	ds, si
		or	ds:[FGEAD_flags], ax
done:
		.leave
		ret
DOS7SetLongNameFlags	endp



		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSEnumInitAttrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the array of attributes on the assumption that
		all requested attrs are present.

CALLED BY:	(INTERNAL) DOSFileEnum, DOSFileEnumLinks
PASS:		ds	= FECD segment
RETURN:		nothing
DESTROYED:	es, di, cx
		MS7, cx only
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/16/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSEnumInitAttrs proc	near
MS7<		uses	es, di				>
		.enter
	;
	; Assume all attributes will be there...
	; 
		les	di, ds:[FGEAD_attrs]
		mov	cx, ds:[FGEAD_numAttrs]
setSegment:
		mov	es:[di].FEAD_value.segment, es
EC <		push	ds, si					>
EC <		lds	si, es:[di].FEAD_value			>
EC <		call	ECCheckBounds				>
EC <		pop	ds, si					>
		add	di, size FileExtAttrDesc
		loop	setSegment
		.leave
		ret
DOSEnumInitAttrs endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSEnumCallCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the passed in callback function

CALLED BY:	(INTERNAL) DOSEnum, DOSFileEnumLinks
PASS:		ds	= FECD
RETURN:		carry set:
			all registers from callback except ds
		carry clear:
			all registers from callback except ds & bp
DESTROYED:	es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/16/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSEnumCallCallback proc	near
		.enter
		push	bp
	;
	; Reload frame pointer from original caller.
	; 
		mov	bp, ds:[FGEAD_spec].FGEASD_enum.FED_kernelFrame
							; restore its stack
							;  frame
		push	ds				; it can biff ES, so
							; save our data segment
							;  now
		segmov	es, ds				; es <- our data
		mov	ds, es:[FGEAD_attrs].segment	; ds <- FECD

;	We use ProcCallFixedOrMovable in all cases, so we can call callbacks
;	in XIP kernels, even if we aren't the "XIP" version.

		mov	ss:[TPD_dataAX], ax				
		mov	ss:[TPD_dataBX], bx				
		movdw	bxax, es:[FGEAD_spec].FGEASD_enum.FED_callback	
		call	ProcCallFixedOrMovable				
;		call	es:[FGEAD_spec].FGEASD_enum.FED_callback	
		pop	ds
		jc	aborted
	;
	; Restore BP, in case needed by DOSLinkEnum, for example.
	; 
		pop	bp
done:
		.leave
		ret

aborted:
		inc	sp		; discard saved bp
		inc	sp
		jmp	done
DOSEnumCallCallback endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSFileEnumLinks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take care of one link.

CALLED BY:	DOSFileEnum via DOSLinkEnum
PASS:		bx	= handle of link directory file
		ds	= FECD segment
RETURN:		carry set if kernel callback returns carry set

DESTROYED:	ax,cx,dx

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		The link has already been read into the FGEAD segment
		by our caller...
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/16/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSFileEnumLinks proc	far

		uses	es, di

		.enter

		mov	ds:[FGEAD_fileHandle], bx
		ornf	ds:[FGEAD_flags], mask FGEAF_HAVE_HANDLE

		call	DOSEnumInitAttrs
	;
	; Now try and fetch them.
	;
		call	DOSLinkGetExtAttrsLow
	;
	; All the extended attributes have been filled in, or not, as
	; appropriate, and we're ready now to call the kernel back.
	;
		call	DOSEnumCallCallback
		jc	done
	;
	; Return link directory file handle if callback didn't return
	; carry set.
	; 
		mov	bx, ds:[FGEAD_fileHandle]
done:
		.leave
		ret
DOSFileEnumLinks endp

ExtAttrs	ends


