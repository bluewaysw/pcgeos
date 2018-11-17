COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		fileFile.asm

AUTHOR:		Adam de Boor, Apr  5, 1990

ROUTINES:
	Name			Description
	----			-----------
    GLB FileCreateDir		Create a directory.

    GLB FileCreateDirWithNativeShortName
				Create a directory with native short name.

    GLB FileDeleteDir		Delete a directory.

    GLB FileDelete		Delete a file.

    GLB FileRename		Rename a file. NOTE: NO LONGER SUPPORTS
				MOVING TO ANOTHER DIRECTORY ON THE DISK.
				USE FileMove FOR THAT.

    GLB FileGetAttributes	Get a file's attributes.

    GLB FileSetAttributes	Set a file's attributes.

    GLB FileGetPathExtAttributes Get one or more extended attribute for a
				file whose path is given.

    GLB FileSetPathExtAttributes Set one or more extended attribute for a
				file whose path is given.

    INT FileCopyGenerateCreateFlags Generate the FileCreateFlags and
				FileAccessFlags for creating the
				destination.

    INT FileCopyAllocBuf	Allocate the buffer for the copy, based on
				the amount of heap space around, and the
				size of the file itself.

    INT FileCopyDealWithExecutables Hacked function to deal with funky
				mapping of virtual to native names for
				executables.

    EXT FileCopy		Copies source file to destination file.
				Destination file will be created. An
				existing file with the same name will be
				truncated.

    INT PushToRoot		Push to the root directory of the given
				volume. Just does a FilePushDir if the
				passed handle is 0

    GLB FileMove		Move a file or directory from one place to
				another. For some file systems, it will be
				possible to move directories from one drive
				to another, while for others an error will
				be returned. If the thing being moved is a
				file, it will always be moved properly by
				this function, so long as the destination
				name doesn't already exist and its
				directory is writable.

    INT FileMoveLocateDest	Locate the physical destination directory
				and make sure the destination file doesn't
				already exist.

    INT FileMoveBuildPath	Build the real physical path for the given
				path.

    INT FMBP_callback		Callback routine to see if the destination
				path exists in the current directory and
				build an absolute representation of it into
				the given buffer, getting its disk handle,
				etc.

    INT FMBP_nearCB		Callback function for FileMoveBuildPath to
				call the real callback function in
				Filemisc.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	4/ 5/90		Initial revision


DESCRIPTION:
	Functions for toying with (as opposed to accessing) files on disk.
		

	$Id: fileFile.asm,v 1.1 97/04/05 01:11:53 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FileSemiCommon segment resource

COMMENT @-----------------------------------------------------------------------

FUNCTION:	FileGetAttributes

DESCRIPTION:	Get a file's attributes.

CALLED BY:	GLOBAL

PASS:
	ds:dx - filename

RETURN:
	carry - set if error
	ax - error code (if an error)
		ERROR_FILE_NOT_FOUND
		ERROR_PATH_NOT_FOUND
	cx - attributes (FileAttrs record)

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
	Todd	4/23/94		XIP'ed
-------------------------------------------------------------------------------@
if	FULL_EXECUTE_IN_PLACE
CopyStackCodeXIP	segment	resource
FileGetAttributes	proc	far
	mov	ss:[TPD_dataBX], handle FileGetAttributesReal
	mov	ss:[TPD_dataAX], offset FileGetAttributesReal
	GOTO	SysCallMovableXIPWithDSDX
FileGetAttributes	endp
CopyStackCodeXIP	ends

else

FileGetAttributes	proc	far
	FALL_THRU	FileGetAttributesReal
FileGetAttributes	endp
endif

FileGetAttributesReal	proc	far
	mov	ah, FSPOF_GET_ATTRIBUTES
	call	FileRPathOpOnPath
	ret
FileGetAttributesReal	endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	FileCreateDir
		FileCreateDirWithNativeShortName

DESCRIPTION:	Create a directory.
		Create a directory with native short name.

CALLED BY:	GLOBAL

PASS:		ds:dx - fptr to pathname to create (FileCreateDir)

RETURN:		if error
			carry set
			ax - FileError
		else
			carry clear

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
	Todd	4/23/94		XIP'ed
-------------------------------------------------------------------------------@
if	FULL_EXECUTE_IN_PLACE
CopyStackCodeXIP	segment	resource

FileCreateDir		proc	far
	mov	ss:[TPD_dataBX], handle FileCreateDirReal
	mov	ss:[TPD_dataAX], offset FileCreateDirReal
	GOTO	SysCallMovableXIPWithDSDX
FileCreateDir		endp

CopyStackCodeXIP	ends

else

FileCreateDir		proc	far
	FALL_THRU	FileCreateDirReal
FileCreateDir		endp
endif

FileCreateDirReal	proc	far
	;
	; If creating dir in std path, make sure local components exist, so
	; dir is created *locally*
	; 
	call	FileEnsureLocalPath
	jc	done
	mov	ah,FSPOF_CREATE_DIR
	call	FileWPathOpOnPath
done:
	ret
FileCreateDirReal	endp

if	FULL_EXECUTE_IN_PLACE
CopyStackCodeXIP	segment	resource

FileCreateDirWithNativeShortName	proc	far
	mov	ss:[TPD_dataBX], handle FileCreateDirWithNativeShortNameReal
	mov	ss:[TPD_dataAX], offset FileCreateDirWithNativeShortNameReal
	GOTO	SysCallMovableXIPWithDSDX
FileCreateDirWithNativeShortName	endp

CopyStackCodeXIP	ends

else

FileCreateDirWithNativeShortName	proc	far
	FALL_THRU	FileCreateDirWithNativeShortNameReal
FileCreateDirWithNativeShortName	endp
endif

FileCreateDirWithNativeShortNameReal	proc	far
	;
	; If creating dir in std path, make sure local components exist, so
	; dir is created *locally*
	; 
	call	FileEnsureLocalPath
	jc	done
	mov	ah, FSPOF_CREATE_DIR_WITH_NATIVE_SHORT_NAME
	call	FileWPathOpOnPath
done:
	ret
FileCreateDirWithNativeShortNameReal	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PushToRoot
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Push to the root directory of the given volume. Just does
		a FilePushDir if the passed handle is 0

CALLED BY:	FileCopy, FileMove
PASS:		cx	= handle of disk volume to which to push
RETURN:		carry set if can't change to root:
			ax = error code
		carry clear if change successful:
			original working directory saved on directory stack.
			ax = destroyed
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/10/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LocalDefNLString rootDir <C_BACKSLASH, 0>
PushToRoot	proc	far	uses ds, dx
		.enter
	;
	; Push a directory so we don't mangle the thread's current dir
	;
		call	FilePushDir
		clc
		jcxz	exit
	;
	; Now call FileSetCurrentPath to go to the root of the passed volume.
	;
		segmov	ds, cs
		mov	dx, offset rootDir
		xchg	bx, cx
		call	FileSetCurrentPath
		jnc	done
	;
	; Yrg. Root doesn't exist. Pop the pushed directory and return carry
	; set (ax untouched).
	;
		call	FilePopDir
		stc
done:
		xchg	bx, cx
exit:
		.leave
		ret
PushToRoot	endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	FileDelete

DESCRIPTION:	Delete a file.

CALLED BY:	GLOBAL

PASS:
	ds:dx - filename to delete

RETURN:
	carry - set if error
	ax - error code
		ERROR_FILE_NOT_FOUND
		ERROR_ACCESS_DENIED
		ERROR_FILE_IN_USE

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
	Cheng	4/89		Added support for PC/GEOS file handles
	Cheng	9/89		Code to handle swapping of floppy disks
	Todd	4/23/94		XIP'ed
-------------------------------------------------------------------------------@
if	FULL_EXECUTE_IN_PLACE
CopyStackCodeXIP	segment	resource

FileDelete	proc	far
	mov	ss:[TPD_dataBX], handle FileDeleteReal
	mov	ss:[TPD_dataAX], offset FileDeleteReal
	GOTO	SysCallMovableXIPWithDSDX
FileDelete	endp

CopyStackCodeXIP	ends

else

FileDelete	proc	far
	FALL_THRU	FileDeleteReal
FileDelete	endp

endif
FileDeleteReal	proc	far
	mov	ah,FSPOF_DELETE_FILE
	call	FileWPathOpOnPath
	ret
FileDeleteReal	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileGetPathExtAttributes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get one or more extended attribute for a file whose
		path is given.

CALLED BY:	GLOBAL
PASS:		ds:dx	= file/dir whose extended attribute(s) is(are)
			  desired
		ax	= FileExtendedAttribute
		es:di	= buffer into which to fetch the attribute, or
			  array of FileExtAttrDesc structures, if
			  ax is FEA_MULTIPLE. Note that custom attributes
			  can only be fetched by passing FEA_MULTIPLE
			  in ax, and an appropriate FileExtAttrDesc
			  structure in this buffer.
		cx	= size of buffer, or number of entries if
			  FEA_MULTIPLE
RETURN:		carry set if one or more attribute could not be fetched,
		    either because the filesystem doesn't support it,
		    or because the file/dir doesn't have it (them).
		    those attributes that exist/are supported will have
		    been fetched.
			ax	= ERROR_FILE_NOT_FOUND
				= ERROR_ATTR_NOT_SUPPORTED (file/dir cannot
				  have ext attrs, or an FEA_CUSTOM attribute
				  was given and the filesystem doesn't support
				  custom attributes)
				= ERROR_ATTR_SIZE_MISMATCH
				= ERROR_ATTR_NOT_FOUND
		carry clear if everything's fine.
			ax	= destroyed
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/14/92		Initial version
	Todd	04/23/94	XIP'ed

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	FULL_EXECUTE_IN_PLACE
CopyStackCodeXIP	segment	resource
FileGetPathExtAttributes proc	far
	mov	ss:[TPD_dataBX], handle FileGetPathExtAttributesReal
	mov	ss:[TPD_dataAX], offset FileGetPathExtAttributesReal
	GOTO	SysCallMovableXIPWithDSDX
FileGetPathExtAttributes endp
CopyStackCodeXIP	ends
else

FileGetPathExtAttributes	proc	far
	FALL_THRU	FileGetPathExtAttributesReal
FileGetPathExtAttributes	endp
endif

FileGetPathExtAttributesReal	proc	far
		uses	bx
		.enter
		push	es, di, ax
		mov	bx, sp
		mov	ah, FSPOF_GET_EXT_ATTRIBUTES
		call	FileRPathOpOnPath
		lea	sp, ss:[bx+6]	; clear stack w/o biffing carry
		.leave
		ret
FileGetPathExtAttributesReal endp





FileSemiCommon ends

;------------------------------------------------------

Filemisc	segment	resource


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FileDeleteDir

DESCRIPTION:	Delete a directory.

CALLED BY:	GLOBAL

PASS:
	ds:dx - pathname to delete

RETURN:
	carry - set if error
	ax - FileError (if an error)
		ERROR_PATH_NOT_FOUND
		ERROR_IS_CURRENT_DIRECTORY
		ERROR_ACCESS_DENIED
		ERROR_DIRECTORY_NOT_EMPTY

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
	Todd	04/23/94	XIP'ed
-------------------------------------------------------------------------------@
if	FULL_EXECUTE_IN_PLACE
CopyStackCodeXIP		segment	resource
FileDeleteDir		proc	far
	mov	ss:[TPD_dataBX], handle FileDeleteDirReal
	mov	ss:[TPD_dataAX], offset FileDeleteDirReal
	GOTO	SysCallMovableXIPWithDSDX
FileDeleteDir		endp
CopyStackCodeXIP		ends

else

FileDeleteDir		proc	far
	FALL_THRU	FileDeleteDirReal
FileDeleteDir		endp
endif

FileDeleteDirReal	proc	far
	mov	ah,FSPOF_DELETE_DIR
	call	FileWPathOpOnPath
	ret
FileDeleteDirReal	endp



COMMENT @-----------------------------------------------------------------------

FUNCTION:	FileRename

DESCRIPTION:	Rename a file. NOTE: NO LONGER SUPPORTS MOVING TO ANOTHER
		DIRECTORY ON THE DISK. USE FileMove FOR THAT.

CALLED BY:	GLOBAL

PASS:
	ds:dx - current file name
	es:di - new file name

RETURN:
	carry - set if error
	ax - error code
		ERROR_FILE_NOT_FOUND
		ERROR_PATH_NOT_FOUND
		ERROR_ACCESS_DENIED
		ERROR_INVALID_NAME

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
	Cheng	4/89		Added support for PC/GEOS file handles
	Cheng	9/89		Code to handle swapping of floppy disks
	Todd	4/23/94		XIP'ed
-------------------------------------------------------------------------------@
if	FULL_EXECUTE_IN_PLACE
CopyStackCodeXIP	segment	resource

FileRename	proc	far
	push	cx
	clr	cx
	call	SysCopyToStackESDI
	pop	cx

	mov	ss:[TPD_dataBX], handle FileRenameReal
	mov	ss:[TPD_dataAX], offset FileRenameReal
	call	SysCallMovableXIPWithDSDX

	call	SysRemoveFromStack
	ret
FileRename	endp
CopyStackCodeXIP	ends

else
FileRename		proc	far
	FALL_THRU FileRenameReal
FileRename		endp
endif
FileRenameReal	proc	far
	uses	bx, cx
	.enter
EC <	push	ax, si							>
EC <	mov	si, di							>
EC <checkDestLoop:							>
EC <SBCS <lodsb	es:							>>
EC <DBCS <lodsw	es:							>>
EC <	LocalCmpChar  ax, C_BACKSLASH					>
EC <	ERROR_E	RENAME_DESTINATION_MAY_NOT_BE_A_PATH			>
EC <	LocalIsNull ax							>
EC <	jnz	checkDestLoop						>
EC <	pop	ax, si							>

	mov	bx, es
	mov	cx, di
	mov	ah,FSPOF_RENAME_FILE
	call	FileWPathOpOnPath
	.leave
	ret
FileRenameReal	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FileSetAttributes

DESCRIPTION:	Set a file's attributes.

CALLED BY:	GLOBAL

PASS:
	cx - new attribute (FileAttrs)
		normal file (FILE_ATTR_NORMAL)
		read-only (FILE_ATTR_READ_ONLY)
		hidden (FILE_ATTR_HIDDEN)
		system (FILE_ATTR_SYSTEM)
	ds:dx - filename

RETURN:
	carry - set if error
	ax - error code (if an error)
		ERROR_FILE_NOT_FOUND
		ERROR_PATH_NOT_FOUND
		ERROR_ACCESS_DENIED

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
	Todd	03/23/94	XIP'ed
-------------------------------------------------------------------------------@
if	FULL_EXECUTE_IN_PLACE
CopyStackCodeXIP	segment	resource
FileSetAttributes	proc	far
	mov	ss:[TPD_dataBX], handle FileSetAttributesReal
	mov	ss:[TPD_dataAX], offset FileSetAttributesReal
	GOTO	SysCallMovableXIPWithDSDX
FileSetAttributes	endp
CopyStackCodeXIP	ends

else
FileSetAttributes	proc	far
	FALL_THRU	FileSetAttributesReal
FileSetAttributes	endp

endif
FileSetAttributesReal	proc	far
EC <	test	cx, not (mask FA_RDONLY or mask FA_HIDDEN or \
   			 mask FA_SYSTEM or mask FA_ARCHIVE)		>
EC <	ERROR_NZ	INVALID_ATTRIBUTES	; any but above set => error>

	mov	ah, FSPOF_SET_ATTRIBUTES
	call	FileWPathOpOnPath
	ret
FileSetAttributesReal	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileSetPathExtAttributes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set one or more extended attribute for a file whose
		path is given.

CALLED BY:	GLOBAL
PASS:		ds:dx	= file/dir the setting of whose extended attribute(s) 
			  is desired
		ax	= FileExtendedAttribute
		es:di	= buffer from which to set the attribute, or
			  array of FileExtAttrDesc structures, if
			  ax is FEA_MULTIPLE. Note that custom attributes
			  can only be set by passing FEA_MULTIPLE
			  in ax, and an appropriate FileExtAttrDesc
			  structure in this buffer.
		cx	= size of buffer, or number of entries if
			  FEA_MULTIPLE
RETURN:		carry set if one or more attribute could not be set,
		    either because the filesystem doesn't support it,
		    or because the file cannot have extended attributes.
		    those attributes that are supported will have
		    been set.
			ax	= ERROR_FILE_NOT_FOUND
				= ERROR_ATTR_NOT_SUPPORTED (file/dir cannot
				  have ext attrs, or an FEA_CUSTOM attribute
				  was given and the filesystem doesn't support
				  custom attributes)
				= ERROR_ATTR_SIZE_MISMATCH
				= ERROR_ACCESS_DENIED (file/dir is read-only)
		carry clear if everything's fine.
			ax	= destroyed
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/14/92		Initial version
	Todd	04/23/94	XIP'ed

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	FULL_EXECUTE_IN_PLACE
CopyStackCodeXIP		segment	resource
FileSetPathExtAttributes	proc	far
	mov	ss:[TPD_dataBX], handle FileSetPathExtAttributesReal
	mov	ss:[TPD_dataAX], offset FileSetPathExtAttributesReal
	GOTO	SysCallMovableXIPWithDSDX
FileSetPathExtAttributes	endp
CopyStackCodeXIP		ends

else
FileSetPathExtAttributes	proc	far
	FALL_THRU	FileSetPathExtAttributesReal
FileSetPathExtAttributes	endp
endif
FileSetPathExtAttributesReal	proc	far
		uses	bx
		.enter
		push	es, di, ax
		mov	bx, sp
		mov	ah, FSPOF_SET_EXT_ATTRIBUTES
		call	FileWPathOpOnPath
		lea	sp, ss:[bx+6]	; clear stack w/o biffing carry
		.leave
		ret
FileSetPathExtAttributesReal	 endp

Filemisc	ends

Filemisc	segment
;------------------------------------------------------------------------------
;
;			      File Copy
;
;------------------------------------------------------------------------------
FileCopyFlags	record		; flags stored in variable local to FileCopy
				;  and set/read by various utility routines
				;  it calls.
    FCF_FREE_DEST_NAME:1
    ; set non-zero by FileCopyDealWithExecutables if it allocated a
    ; block to hold the native name that should be used when copying
    ; an executable

    FCF_CLOSE_SOURCE_FILE:1
    ; set if had to open the source file ourselves

    FCF_FIX_OLD_LONGNAME:1
    ; set if copying a 1.X VM file and need to fix up the
    ; GFHO_longName field of the dest before closing it

    FCF_FLUSH_BATCH:1
    ; Flush the FileBatchChangeNotifications at the end of the file
    ; copy.  Only necessary if we created a batch block at the beginning

    FCF_COPY_DONE:1
    ; Set when the last buffer is copied
FileCopyFlags	end





COMMENT @-----------------------------------------------------------------------

FUNCTION:	FileCopyCommon

DESCRIPTION:	Copies source file to destination file. Destination file
		will be created. An existing file with the same name will
		be truncated.

CALLED BY:	GLOBAL

PASS:		ds:si - source file name
		  OR  - ds = 0 and si = file handle to copy from
		cx - source disk handle
		es:di - destination file name
		dx - destination disk handle
		ax - Override remote boolean
		     If TRUE then
			copy file to local standard path directory even
		        if a file of the same name exists in remote directory.
		     If FALSE then 
			complain to the user about replacing
		     	the aforementioned remote file and remove it if
		     	the user chooses to replace it.

		Either one of the disk handles may be 0, in which case 
		the disk handle in the thread's current path will be used.

		If a disk handle is provided, the corresponding path *must*
		be absolute (begin with a backslash).

RETURN:		carry set if error
		ax = error code
			0 if no error
			ERROR_FILE_NOT_FOUND
			ERROR_PATH_NOT_FOUND
			ERROR_TOO_MANY_OPEN_FILES
			ERROR_ACCESS_DENIED
			ERROR_SHORT_READ_WRITE (insufficient space on
				destination disk)

DESTROYED:	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	4/90		Initial version
	Todd	04/23/94	XIP'ed

------------------------------------------------------------------------------@
if	FULL_EXECUTE_IN_PLACE
CopyStackCodeXIP		segment	resource
FileCopyCommon	proc	near
	uses	si, di, ds, es
	.enter
	push	cx
	mov	cx, ds
	jcxz	sourceIsHandle

	pop	cx

	mov	ss:[TPD_dataBX], handle FileCopyCommonReal
	mov	ss:[TPD_dataAX], offset FileCopyCommonReal
	call	SysCallMovableXIPWithDSSIAndESDI

done:
	.leave
	ret

sourceIsHandle:
	call	SysCopyToStackESDI
	pop	cx
	call	FileCopyCommonReal
	call	SysRemoveFromStack
	jmp	short	done
FileCopyCommon	endp
CopyStackCodeXIP		ends

else
FileCopyCommon		proc	near
	FALL_THRU	FileCopyCommonReal
FileCopyCommon		endp
endif

	;
	;  Yes, this routine really is far in one instance,
	;  and near in the other.  It stays in the same resource,
	;  but the two callers move from movable to fixed...
	;
	;			-- todd 03/24/94
if	FULL_EXECUTE_IN_PLACE
FileCopyCommonReal	proc	far
else
FileCopyCommonReal	proc	near
endif
		uses	bx,cx,dx,di,si,ds,es

destFileName	local	fptr.char	push	es, di
destDiskHan	local	word		push	dx
overrideRemote	local	word		push	ax

sourceFileHan	local	hptr
destFileHan	local	hptr
copyBufMemHan	local	hptr
copyBufSize	local	word
fileAttrsHandle	local	hptr
numFileAttrs	local	word
createFlags	local	word
destFinalComp	local	fptr.char	; set to address of final component in
					;  original destFileName if
					;  FCF_FIX_OLD_LONGNAME or
					;  FCF_FREE_DEST_NAME set
flags		local	FileCopyFlags

ForceRef	overrideRemote

	.enter

	call	FileCopyCheckLink
	jnc	checkLink

realExitJmp:
	jmp	realExit

checkLink:

	;
	; If AL is nonzero, then we copied a link, so exit.
	;

	tst	al
	jnz	realExitJmp


	; Initialize some local variables, now that we have a zero
	; register.

	mov	ss:[flags], al
	cbw
	mov	ss:[destFileHan], ax
	mov	ss:[fileAttrsHandle], ax
	mov	ss:[copyBufMemHan], ax

	;----------------------------------------
	; Open the source file first.
	;

	; test for file handle passed (segment of name is non-zero)

	mov	ax, ds
	tst	ax
	jnz	fileHandleNotPassed

	mov	bx, si			; file handle passed
	clrdw	cxdx			;  make sure it's positioned at
	mov	al, FILE_POS_START	;  its start, so we get the whole
	call	FilePosFar		;  thing.
	mov_tr	ax, bx			;ax = file handle
	clc
	jmp	sourceError?

fileHandleNotPassed:
	ornf	ss:[flags], mask FCF_CLOSE_SOURCE_FILE
	jcxz	sourceRelative

	call	PushToRoot		; Push to root of source volume
	jc	sourceError?

sourceRelative:
	call	FileCopyDealWithExecutables
	jc	sourceOpenDone

	mov	dx, si			; ds:dx = file name
	call	FileOpen

sourceOpenDone:
	jcxz	sourceError?
	call	FilePopDir		; Restore thread's path

sourceError?:
	jc	exitJmp			;quit if error
	mov	ss:[sourceFileHan], ax

	;----------------------------------------
	; allocate a copy buffer

	call	FileCopyAllocBuf		; ds:dx - copy buffer
	LONG jc	error

	;----------------------------------------
	; Fetch the source file's extended attributes, and squirrel
	; them away

	mov	bx, ss:[sourceFileHan]
	mov	ax, FSHOF_GET_ALL_EXT_ATTRIBUTES shl 8
	call	FileLockHandleOpFar
	mov	ss:[fileAttrsHandle], ax
	mov	ss:[numFileAttrs], cx

	; Fetch the FileCreateFlags, etc. that we'll need when
	; creating the dest file

	call	FileCopyGenerateCreateFlags
	mov	ss:[createFlags], ax

	;----------------------------------------
	; Start the copy loop.  If the file is small enough, we'll be
	; able to read the entire file, and thus only have 1 disk swap.

copyLoop:
	clr	al			; give me errors
	mov	bx, ss:[sourceFileHan]
	mov	cx, ss:[copyBufSize]	; Try for full buffer...
	jcxz	lastRead
	call	FileReadFar		; cx - number of bytes read
	jnc	doWrite
	cmp	ax, ERROR_SHORT_READ_WRITE
	LONG jne error

lastRead:
	;we are done - last write.  Close the source file now, to
	;prevent disk swaps later

	ornf	ss:[flags], mask FCF_COPY_DONE
	call	closeSource

doWrite:
	tst	ss:[destFileHan]
	jnz	writeDest
		
	;----------------------------------------
	; Create the destination file.
	;

	test	ss:[flags], mask FCF_FREE_DEST_NAME
	jz	usingLongName

	;
	; FileCopy is copying a GEOS executable so it is using the 
	; DOS name, but we want the FCN to have the longname.  We batch
	; up FCNs so we get the creation FCN in a block we can edit before
	; it is sent off.
	;
	tst	ss:[TPD_fsNotifyBatch]
	jnz	usingLongName

	ornf	ss:[flags], mask FCF_FLUSH_BATCH
	call	FileBatchChangeNotifications

usingLongName:
	push	cx
	mov	cx, ss:[destDiskHan]
	call	FileCopyCreateDest	; leaves us pushed to the destination
	pop	cx			;  directory, for extended attribute
					;  copy & possible deletion on error,
					;  when all is done.
	jnc	destOpen

	;
	; Couldn't create dest, but have to close source before leaving
	;
	call	closeSource
	stc
exitJmp:
	pushf
	push	ax
	jmp	popDirErrorAndExit

destOpen:
	mov	ss:[destFileHan], ax

	test	ss:[flags], mask FCF_FREE_DEST_NAME
	jz	writeDest

	;
	; We are dealing with the DOS name because it is a geos executable, so
	; look at the last batched FCN and update its name to be a longname.
	;
	call	FileStuffLongNameIntoFCBNI

writeDest:
	;
	; If need to fix up the 1.x longname, copy it in now.
	;
	test	ss:[flags], mask FCF_FIX_OLD_LONGNAME
	jnz	fixLongName

writeBuffer:
	; Write the data, unless there is none
	clr	ax
	jcxz	done

	mov	bx, ss:[destFileHan]
	call	FileWriteFar
	jc	done
		
	test	ss:[flags], mask FCF_COPY_DONE
	jz	copyLoop

	clr	ax			;no error
	jmp	done

fixLongName:
	;
	; Copying an old VM file and this is the first buffer, so copy the
	; final component of the destination name into the GFHO_longName
	; field of the old header. We can't wait until the end to do this, as
	; there might be an error writing the destination and we wouldn't be
	; able to delete the file, as it'd have the source file's longname
	; in its header. Blech, again...
	; 
	CheckHack <COPY_FILE_BUF_SIZE ge \
			offset GFHO_longName + size GFHO_longName>
	push	cx
	segmov	es, ds
	mov	di, dx
	add	di, offset GFHO_longName
	lds	si, ss:[destFinalComp]
	mov	cx, size GFHO_longName
	rep	movsb
	;
	; Recover registers from before (cx <- bytes read, ds:dx <- buffer)
	; and clear the FCF_FIX_OLD_LONGNAME flag so we don't do this again.
	; 
	pop	cx
	segmov	ds, es
	andnf	ss:[flags], not mask FCF_FIX_OLD_LONGNAME
	jmp	writeBuffer

error:
	stc
done:
	;----------------------------------------
	; Close destination file and free the copy buffer. Regardless
	; of whether the copy succeeded, we'll need the dest closed
	; (either to set its extended attributes or to delete it), and
	; we don't need the copy buffer any more...
	; 

	pushf
	push	ax

	;
	; 4/16/93: if FCF_FREE_DEST_NAME is set, it means we're copying an
	; executable or directory and need to fix up the longname for the
	; beast. -- ardeb
	; 
	mov	bx, ss:[destFileHan]
	tst	bx
	jz	afterCloseDest	

	test	ss:[flags], mask FCF_FREE_DEST_NAME
	jz	closeDest

	mov	ax, FEA_NAME
	mov	cx, size FileLongName
	les	di, ss:[destFinalComp]
	call	FileSetHandleExtAttributes
	
closeDest:
	clr	al
	call	FileCloseFar
	jnc	afterCloseDest
	;
	; Error during close, so make sure we return an error now,
	; regardless of whether there was one before.
	; 
	add	sp, 4
	stc
	pushf
	push	ax

afterCloseDest:

	pop	ax
	popf
	jc	deleteDest		; => error during copy, so nuke dest

	;----------------------------------------
	; Destination is properly closed, copy buffer is freed, so now we
	; need to transfer all extended attributes from the source to the
	; destination. We've kept our working directory appropriate to the
	; destination expressly for this purpose...
	; 
	
	mov	ax, FEA_MULTIPLE
	mov	cx, ss:[numFileAttrs]
	mov	bx, ss:[fileAttrsHandle]
	call	MemDerefES
	clr	di
	lds	dx, ss:[destFileName]
	call	FileSetPathExtAttributes

	;
	; 4/15/93: if the source filesystem supports more attributes for the
	; file than the destination filesystem, don't penalize it... -- ardeb
	; 
	jnc	flushBatch
	cmp	ax, ERROR_ATTR_NOT_FOUND
	je	ignoreError
	cmp	ax, ERROR_ATTR_NOT_SUPPORTED
	stc
	jne	flushBatch
ignoreError:
	clr	ax
flushBatch:

	pushf
	push	ax


closeSourcePopDirErrorAndExit:
	call	closeSource

popDirErrorAndExit:
	;
	; Return to the thread's original directory, if necessary.
	; 
	tst	ss:[destDiskHan]
	jz	memFreeAndExit

	call	FilePopDir

memFreeAndExit:
	mov	bx, ss:[fileAttrsHandle]
	call	fileCopyMemFree

	mov	bx, ss:[copyBufMemHan]
	call	fileCopyMemFree

	test	ss:[flags], mask FCF_FREE_DEST_NAME
	jz	exit

	mov	ds, ss:[destFileName].segment
	mov	bx, ds:[0]
	call	MemFree
exit:
	;
	; Flush batch change notifications, NOW, after the
	; FileCopyExtAttributes, if we started a batch.
	;
	test	ss:[flags], mask FCF_FLUSH_BATCH
	jz	afterFlush

	call	FileFlushChangeNotifications

afterFlush:

	pop	ax
	popf

realExit:
	.leave
	ret

deleteDest:
	;----------------------------------------
	; Something went wrong during the copy, so delete the destination
	; file before we return. As noted above, we've kept the thread's
	; working directory appropriate for just this sort of thing.
	; 
	pushf
	push	ax
	lds	dx, ss:[destFileName]
	call	FileDelete
	jmp	closeSourcePopDirErrorAndExit


closeSource:
	;----------------------------------------
	; Close down the source file, if necessary
	; 

	test	ss:[flags], mask FCF_CLOSE_SOURCE_FILE
	jz	closeSourceDone

	push	ax
	clr	al
	mov	bx, ss:[sourceFileHan]
	call	FileCloseFar
	pop	ax
	andnf	ss:[flags], not mask FCF_CLOSE_SOURCE_FILE
closeSourceDone:
	retn

	;----------------------------------------
	; Call MemFree if the passed block is nonzero
fileCopyMemFree:
	tst	bx
	jz	fcmfDone
	call	MemFree
fcmfDone:
	retn

FileCopyCommonReal	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileCopyGenerateCreateFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate the FileCreateFlags and FileAccessFlags for
		creating the destination.

CALLED BY:	FileCopyCommonReal

PASS:		bx	= open source file handle
RETURN:		ah	= FileCreateFlags
		al	= FileAccessFlags
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileCopyGenerateCreateFlags proc near
		uses	cx
		.enter	inherit FileCopyCommonReal
	;
	; See if the source file is in native mode.
	; 
		mov	cx, (mask FCF_NATIVE or FILE_CREATE_TRUNCATE) shl 8 or \
				FileAccessFlags <FE_DENY_WRITE, FA_WRITE_ONLY>
		mov	ah, FSHOF_CHECK_NATIVE
		call	FileHandleOpFar
		jc	done
	;
	; File isn't native, so clear FCF_NATIVE from the high byte...
	; 
		andnf	ch, not mask FCF_NATIVE
	;
	; Cope with executables etc. by creating the dest using a native name,
	; but extended attributes. We'll set the longname when we're done.
	; 
		test	ss:[flags], mask FCF_FREE_DEST_NAME
		jz	done
		ornf	ch, mask FCF_NATIVE_WITH_EXT_ATTRS
done:
	;
	; Return proper flags in ax
	; 
		mov_tr	ax, cx
		.leave
		ret
FileCopyGenerateCreateFlags endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileCopyAllocBuf
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate the buffer for the copy, based on the amount of
		heap space around, and the size of the file itself.

CALLED BY:	FileCopy
PASS:		ss:bp 	= inherited stack frame
RETURN:		carry set on error:
			ax	= ERROR_INSUFFICIENT_MEMORY
		carry clear on success:
			ss:[copyBufMemHan]	= set
			ss:[copyBufSize]	= set
			ds:dx			= locked buffer address
DESTROYED:	ax, bx, cx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileCopyAllocBuf proc	near
		.enter	inherit FileCopyCommonReal

if not PRINT_FILE_COPY_BUFFER

	;
	; First find how big a block exists in the system.
	; 
		mov	ax, SGIT_LARGEST_FREE_BLOCK
		call	SysGetInfo		; ax = size of largest block
						;	in paragraphs
	;
	; If it's too small to be useful, we'll just have to be pushy.
	; 
		shl	ax, 1
		shl	ax, 1
		shl	ax, 1
		shl	ax, 1				; ax = size in bytes
		cmp	ax, COPY_FILE_BUF_SIZE		; smallest useful buffer
		ja	compareToFileSize
		mov	ax, COPY_FILE_BUF_SIZE

compareToFileSize:
		mov_tr	cx, ax
		mov	bx, ss:[sourceFileHan]
		call	FileSize
		
		tst	dx			; > 64K?
		jnz	setCopySize		; yes -- what we've got is what
						;  we'll get...

		cmp	ax, cx			; > buf size?
		ja	setCopySize		; yes, use largest block avail
						; else, use file size
		mov_tr	cx, ax

	; Observation:  if we allocate a buffer that's exactly the
	; size of the file, then we'll have more disk accesses than if
	; we make it a TEENY bit larger -- the reason being that in
	; the former case the first read will read the entire file,
	; and the second read will be zero bytes.  Better to only read
	; the file once, get a "short read" error, and then continue
	; on our merry way.

		jcxz	setCopySize
		inc	cx
setCopySize:
		mov	ss:[copyBufSize], cx	; save buffer size

		clc				; zero-sized file not an error..
		jcxz	setZeroBuffer		; use no buffer if empty
		
		mov_tr	ax, cx			; ax <- bytes to alloc
		mov	cx, ALLOC_DYNAMIC_LOCK
		call	MemAllocFar
		jnc	setBuffer
		mov	ax, ERROR_INSUFFICIENT_MEMORY ; error

setZeroBuffer:
		mov	bx, 0			; don't biff carry...

setBuffer:
		mov	ss:[copyBufMemHan], bx	; save copy buffer handle
		jc	done
		mov	ds, ax
		clr	dx
done:

else 	; PRINT_FILE_COPY_BUFFER
	;
	; Requires that the system not be printing at the same time
	; that file copies happen, which is true as long as the print
	; dialog stays system modal.   If it doesn't, some hairy crash
	; will get us back to this point and we'll have to install a
	; semaphore on the buffer.
	;
		mov	ax, PRINT_FILE_COPY_BUFFER_SEGMENT
		mov	ds, ax
		clr	dx
		mov	ss:[copyBufMemHan],0	; not a handle (don't free)
		mov	ss:[copyBufSize], PRINT_FILE_COPY_BUFFER_SIZE
		clc				; return OK
endif
		.leave
		ret
FileCopyAllocBuf endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileCopyDealWithExecutables
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Hacked function to deal with funky mapping of virtual
		to native names for executables, and DIRNAME.000 files.

CALLED BY:	FileCopy
PASS:		ds:si	= source name
		es:di	= destination name
		ss:bp	= inherited frame
RETURN:		carry clear if copy should proceed:
			al	= FullFileAccessFlags to use in FileOpen
				  of source
		carry set if copy should not proceed:
			ax	= FileError
DESTROYED:	dx, es, di
SIDE EFFECTS:	ss:[destFinalComp] points to start of final component in
			destFileName


PSEUDO CODE/STRATEGY:
		FileCopy and FileMove can cause problems for the system
		when they copy executable files around, especially those for
		filesystem drivers, where the normal virtual -> native mapping
		cannot take place.

		To deal with this in a filesystem-independent manner, we
		take the following steps:
		    - if the source and destination names have the
		      same final components:
			- fetch the DOS name and geos file type of the
			  source.
			- if not ERROR_ATTR_NOT_FOUND,
			    and the file is GFT_EXECUTABLE or GFT_DIRECTORY:
			    - allocate a block to hold the new dest name
			    - store its handle at word 0
			    - copy the leading components of the destination
			      to offset 2
			    - copy the source name at the end of the dest
			    - set freeDestFileName TRUE
			    - return with FFAF_RAW set in FullFileAccessFlags
		    - return without FFAF_RAW

		In the case of a DOS-based filesystem, copying the file in
		raw mode will copy all the extended attributes other than
		the modification stamp and the DOS attributes, which is what
		we'll get back from the GET_ALL_EXT_ATTRIBUTES since the thing
		is seen as a non-geos file.
		
		In the case of a non-DOS-based filesystem, copying the file in
		raw mode will have no effect, and all the extended attributes
		will be returned by the GET_ALL_EXT_ATTRIBUTES anyway.
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/20/92		Initial version
	eric	1/13/93		Added test for DIRNAME.000 files
	Todd	04/23/94	XIP'ed

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	.assert	offset FileCopyCommonReal eq offset FileCopyCommonReal
FileCopyDealWithExecutables proc near
	uses	si, bx, cx
	.enter inherit FileCopyCommonReal
	.assert	offset FileCopyCommonReal eq offset FileCopyCommonReal

if	FULL_EXECUTE_IN_PLACE
EC<	push	bx, si					>
EC<	mov	bx, ds					>
EC<	call	ECAssertValidTrueFarPointerXIP		>
EC<	movdw	bxsi, esdi				>
EC<	call	ECAssertValidTrueFarPointerXIP		>
EC<	pop	bx, si					>
endif
	;
	; Find the start of the final component of the source name
	; 
		mov	dx, si		; save src name start for getting
					;  attributes, if necessary
saveSrcFinalStart:
		mov	bx, si
findSrcFinalLoop:
		LocalGetChar ax, dssi
		LocalCmpChar ax, C_BACKSLASH
		je	saveSrcFinalStart
		LocalIsNull	ax
		jnz	findSrcFinalLoop

		mov	si, di		; es:si <- dest name
		mov	di, bx		; ds:di <- first component of src
					;  (temporary storage)
	;
	; Find the start of the final component of the dest name
	; 
saveDestFinalStart:
		mov	bx, si
findDestFinalLoop:
SBCS <		lodsb	es:						>
DBCS <		lodsw	es:						>
		LocalCmpChar ax, C_BACKSLASH
		je	saveDestFinalStart
		LocalIsNull ax
		jnz	findDestFinalLoop

		mov	ss:[destFinalComp].offset, bx
		mov	ss:[destFinalComp].segment, es
	;
	; Compare the two final components.
	; 
		mov	cx, si
		sub	cx, bx		; cx <- length of final dest piece,
					;  including null
DBCS <		shr	cx, 1						>
		mov	si, di		; ds:si <- final source piece
		mov	di, bx		; es:di <- final dest piece
		
SBCS <		repe	cmpsb						>
DBCS <		repe	cmpsw						>
		jne	normalCopyJmp
	;
	; Final components match. Joy. Fetch the FEA_DOS_NAME and FEA_FILE_TYPE
	; attributes for the source (current directory properly set up, to allow
	; us to do this, by our gracious caller).
	;
	; If the file is missing FEA_FILE_TYPE, it can't be an executable, so
	; we're happy.
	;
	; If the file is missing FEA_DOS_NAME, we have no DOS name to preserve.
	; 
FCDWE_STACK_SIZE	equ  ((size FileDosName + size GeosFileType + \
				2 * size FileExtAttrDesc)+1) and 0xfffe
		sub	sp, FCDWE_STACK_SIZE
		mov	di, sp
		push	bp
		mov	bp, di
		mov	ss:[bp][0*FileExtAttrDesc].FEAD_attr, FEA_FILE_TYPE
		lea	ax, ss:[bp+2*FileExtAttrDesc]
		mov	ss:[bp][0*FileExtAttrDesc].FEAD_value.offset, ax
		mov	ss:[bp][0*FileExtAttrDesc].FEAD_value.segment, ss
		mov	ss:[bp][0*FileExtAttrDesc].FEAD_size,
				size GeosFileType

		mov	ss:[bp][1*FileExtAttrDesc].FEAD_attr, FEA_DOS_NAME
		lea	ax, ss:[bp+2*FileExtAttrDesc+size GeosFileType]
		mov	ss:[bp][1*FileExtAttrDesc].FEAD_value.offset, ax
		mov	ss:[bp][1*FileExtAttrDesc].FEAD_value.segment, ss
		mov	ss:[bp][1*FileExtAttrDesc].FEAD_size,
				size FileDosName
		segmov	es, ss			; es:di <- attr desc array
		mov	ax, FEA_MULTIPLE	; get multiple attrs
		mov	cx, 2			;  2, to be precise
		call	FileGetPathExtAttributes
		jnc	checkType		; => got both, so look at them

clearStackAndDoNormalCopy:
		pop	bp
		lea	sp, ss:[di+FCDWE_STACK_SIZE]
normalCopyJmp:
		jmp	normalCopy

couldntAllocNewDest:
		pop	bx
		lea	sp, ss:[di+FCDWE_STACK_SIZE]
		mov	ax, ERROR_INSUFFICIENT_MEMORY
		stc
		jmp	exit

checkType:
		cmp	{GeosFileType}ss:[bp+2*FileExtAttrDesc],
				GFT_EXECUTABLE
		je	handleAsRaw

		cmp	{GeosFileType}ss:[bp+2*FileExtAttrDesc],
				GFT_DIRECTORY
		jne	clearStackAndDoNormalCopy

handleAsRaw:
	;
	; Source file is executable and has a DOS name. Allocate a block to
	; hold the destination name.
	; 
		pop	bp
		push	bx		; save start of final dest
					;  component for copy
		sub	bx, ss:[destFileName].offset	; bx <- length of
							;  leading dest
							;  components
SBCS <		add	bx, size FileDosName + size hptr		>
DBCS <		add	bx, (size FileDosName)*(size wchar) + size hptr	>
		mov	ax, bx			; ax <- size
		mov	cx, ALLOC_DYNAMIC_LOCK
		call	MemAllocFar
		jc	couldntAllocNewDest

		mov	es, ax
		mov	es:[0], bx	; save dest handle for later free
		ornf	ss:[flags], mask FCF_FREE_DEST_NAME
	;
	; Copy the leading components of the dest name into the buffer.
	; 
		pop	bx		; bx <- start of final dest component
		push	ds
		lds	si, ss:[destFileName]	; ds:si <- source for copy
		mov	cx, bx
		sub	cx, si		; cx <- # bytes to copy
		mov	di, size hptr	; store new name after block handle
		rep	movsb
	;
	; Tack on the DOS name of the source. It's above the attribute
	; descriptors, file type, and saved DS on the stack.
	; 
		segmov	ds, ss
		mov	si, sp
		add	si, size word + 2*FileExtAttrDesc + size GeosFileType
		mov	cx, size FileDosName
if DBCS_PCGEOS
		push	bx, dx
		clr	bx, dx			; bx <- use current DosCodePage
		call	LocalDosToGeos
		pop	cx, dx
else
		rep	movsb
endif


		pop	ds
	;
	; Set new name as the dest name to use.
	; 
		mov	ss:[destFileName].segment, es
		mov	ss:[destFileName].offset, size hptr
		add	sp, FCDWE_STACK_SIZE
	;
	; Tell FileOpen to open the thing in raw mode.
	; 
		mov	al, FullFileAccessFlags <
			0,		; FFAF_RAW
			FE_NONE,	; FFAF_EXCLUDE
			0,		; FFAF_EXCLUSIVE
			1,		; FFAF_OVERRIDE
			FA_READ_ONLY
		>
		jmp	done
normalCopy:
		; used to be DENY_WRITE/ACCESS_R, but that nails the copying
		; of certain useful files, like geos.ini, in GeoManager. One
		; must simply trust, here...
		mov	al, FullFileAccessFlags <
			0,		; FFAF_RAW
			FE_NONE,	; FFAF_EXCLUDE
			0,		; FFAF_EXCLUSIVE
			1,		; FFAF_OVERRIDE
			FA_READ_ONLY
		>
done:
		clc
exit:
		.leave
		ret
FileCopyDealWithExecutables endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileCopyCheckLink
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the file being copied is a link, and if so,
		copy it without opening the file.

CALLED BY:	(INTERNAL) FileCopy

PASS:		ds:si - source filename, or DS=0, si=file handle (not
			a link)
		cx - source disk
		es:di - dest filename
		dx - dest disk

RETURN:		If error:
			carry set
			ax = FileError
		Else
			if LINK:
				al = TRUE
				Link will have been copied
			else
				al = FALSE

DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	8/11/92   	Initial version.
	Todd	04/23/94	XIP'ed

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileCopyCheckLink	proc near

	uses	es, di, cx, dx, ds, si

sourceDisk		local	word	push	cx
destDisk		local	word	push	dx
sourcePath		local	fptr	push	ds, si
destPath		local	fptr	push	es, di
targetPath		local	PathName
targetDiskHandle	local	word
extraDataHandle		local	hptr
extraDataSegment	local	sptr
extraDataSize		local	word

	.enter
if	FULL_EXECUTE_IN_PLACE
EC<	push	bx, si						>
EC<	movdw	bxsi, esdi					>
EC<	call	ECAssertValidTrueFarPointerXIP			>
EC<	pop	bx, si						>
endif
	;
	; Make sure we weren't passed a file handle (ds = 0)
	;
	
	mov	ax, ds
	tst	ax
		CheckHack <FALSE eq 0>
	jz	doneJMP		; if zero, AL = FALSE, and carry clear

if	FULL_EXECUTE_IN_PLACE
EC<	push	bx						>
EC<	mov	bx, ds						>
EC<	call	ECAssertValidTrueFarPointerXIP			>
EC<	pop	bx						>
endif
	;
	; Make the source disk the current directory.
	;

	call	PushToRoot
	jnc	continue
doneJMP:
	jmp	done
continue:

	;
	; See if we're dealing with a link, by fetching the FileAttrs of
	; the source file
	;

	mov	dx, si
	call	FileGetAttributes
	jnc	checkFlag
	
popDirJMP:
	jmp	popDir

checkFlag:
	mov	al, FALSE
	test	cx, mask FA_LINK
	jz	popDirJMP

	;
	; It's a link, so read the target
	;

	lds	dx, ss:[sourcePath]
	segmov	es, ss
	lea	di, ss:[targetPath]
	mov	cx, size targetPath
	call	FileReadLink
	jc	popDirJMP

	mov	ss:[targetDiskHandle], bx

	;
	; Also, read the extra data.  Assume there is none...
	;
EC <	mov	ss:[extraDataSegment], NULL_SEGMENT	>
	clr	ss:[extraDataHandle]
	call	FileGetLinkExtraData
	mov	ss:[extraDataSize], cx
	jcxz	afterExtraData

	;
	; There is some extra data.  Allocate a buffer to hold it
	;
	push	cx
	mov_tr	ax, cx
	mov	cx, ALLOC_DYNAMIC_LOCK
	call	MemAllocFar
	pop	cx

	jnc	gotBuffer
	mov	ax, ERROR_INSUFFICIENT_MEMORY
	jmp	popDir

gotBuffer:
	mov	ss:[extraDataHandle], bx
	mov	ss:[extraDataSegment], ax
	mov	es, ax
	clr	di
	call	FileGetLinkExtraData
	jc	freeBufferPopDir

afterExtraData:
	
	call	FilePopDir

	;
	; Move to the destination directory, and create the link.
	; Pass the "skip attrs" flag, because we'll be copying
	; attributes from the first link.
	;

	mov	cx, ss:[destDisk]
	call	PushToRoot
	jc	freeBuffer

	lds	dx, ss:[destPath]
	segmov	es, ss
	lea	di, ss:[targetPath]
	mov	bx, ss:[targetDiskHandle]
	mov	cx, -1			
	call	FileCreateLink
	jc	freeBufferPopDir

	;
	; Copy the extra data
	;

	mov	es, ss:[extraDataSegment]
	clr	di
	mov	cx, ss:[extraDataSize]
	call	FileSetLinkExtraData
	jc	freeBufferPopDir

	;
	; Copy the extended attributes
	;

	lds	si, ss:[sourcePath]
	les	di, ss:[destPath]
	mov	cx, ss:[sourceDisk]
	mov	dx, ss:[destDisk]
	call	FileCopyPathExtAttributes
	jc	freeBufferPopDir

	mov	al, TRUE		; signal that we copied a link

freeBufferPopDir:
	call	freeBufferCommon

popDir:
	call	FilePopDir
	
done:
	.leave
	ret

freeBuffer:
	call	freeBufferCommon
	jmp	done

freeBufferCommon:

	;
	; Mini internal procedure to free the buffer
	;

	pushf
	mov	bx, ss:[extraDataHandle]
	tst	bx
	jz	afterFree
	call	MemFree
afterFree:
	popf
	retn

FileCopyCheckLink	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileStuffLongNameIntoFCBNI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Edit the FileChangeNotification batch block's last entry
		to contain the longname of a file that has had its DOS
		name put in because FileCopyCommon uses the DOS name when 
		copying GEOS executables.  If a create notification isn't
		present or isn't the last notification, do nothing.   The
		file probably already existed so the create wasn't sent.

CALLED BY:	FileCopyCommon

PASS:		ss:bp	- inherited stack frame from FileCopyCommon
RETURN:		nothing
DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	11/11/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileStuffLongNameIntoFCBNI	proc	near
	uses	ax,bx,cx,si,di,ds,es
	.enter inherit FileCopyCommonReal


	mov	bx, ss:[TPD_fsNotifyBatch]
	call	MemLock
	mov	es, ax

	;
	; Loop through the entries until the last.  If it is a create,
	; then replace its old DOS name with the new longname
	;

	mov	di, offset FCBND_items
	mov	ax, (not FCNT_CREATE)		; make sure ax *doesn't*
						;   match FCNT_CREATE
						;   by default
batchItemLoop:
	cmp	di, es:[FCBND_end]
	je	checkLastNotificationType

	mov	ax, es:[di].FCBNI_type
	add	di, size FileChangeBatchNotificationItem
	cmp	ax, FCNT_CREATE
	je	addFileLongName
	cmp	ax, FCNT_RENAME
	jne	batchItemLoop
addFileLongName:			; only FCNT_CREATE and FCNT_RENAME
	add	di, size FileLongName	;  have FileLongNames at the end
	jmp	batchItemLoop

checkLastNotificationType:
	cmp	ax, FCNT_CREATE
	jne	exit

	lds	si, ss:[destFinalComp]	; ds:si is our longname
	mov	cx, size FileLongName
	sub	di, cx			; es:di is our destination
	rep	movsb			; replace the DOS name with
					; our longname

exit:
	call	MemUnlock		; unlock the batch block

	.leave
	ret
FileStuffLongNameIntoFCBNI	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileCopyCreateDest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create the destination file for FileCopy, dealing carefully
		with old VM files. Blech.

CALLED BY:	FileCopyCommonReal

PASS:		ss:bp	= inherited frame
		cx	= disk handle for destination file (0 if relative to
			  current dir)
RETURN:		carry set on error:
			ax	= error code
		carry clear on success:
			ax	= file handle
		if cx non-zero, thread remains pushed to the root of that disk
DESTROYED:	es, di, bx, ax, cx, si
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileCopyCreateDest proc	near
	uses	ds, dx

	.enter inherit FileCopyCommonReal
	jcxz	destRelative
	call	PushToRoot		; Push to root of dest volume
	jc	done
destRelative:
	lds	dx, ss:[destFileName]	; ds:dx <- dest name
	mov	ax, ss:[createFlags]
	test	ah, mask FCF_NATIVE
	jnz	checkOldVM

createFile:
	push	ax		; save FileCreateFlags from potential biffing
				;  if overriding remote (easiest to do it here,
				;  and not very costly to do all the time)
	tst	ss:[overrideRemote]
	jnz	noRemote

reallyCreateFile:
	pop	ax
	mov	cx, FILE_ATTR_NORMAL
	call	FileCreate

	;
	; If we started a path enumeration to deal with ignoring files in
	; remote directories, finish it now before we act on an error
	; returned by FileCreate
	;
	pushf
	tst	ss:[overrideRemote]
	jz	checkCreateError
	call	FinishWithPathEnum
checkCreateError:
	popf
	jc	done	

	test	ss:[flags], mask FCF_FIX_OLD_LONGNAME
	jz	done

	;
	; File is an old VM file, so we need to close the file, now we've
	; created it with the appropriate longname, and reopen it again in
	; raw mode, so we can overwrite the header with the old header.
	; Blech.
	; 
	mov_tr	bx, ax
	clr	al
	call	FileCloseFar
	mov	al, FullFileAccessFlags <
			1,		; FFAF_RAW
			FE_DENY_WRITE,	; FFAF_EXCLUDE
			0,		; FFAF_EXCLUSIVE
			0,		; FFAF_OVERRIDE
			FA_WRITE_ONLY
		>
	call	FileOpen
done:
	; leave us pushed to the destination directory, for extended attribute
	; copy & possible deletion on error, when all is done.


	.leave
	ret

checkOldVM:
	;
	; The source file is a DOS file, which means it might be a 1.x VM
	; file. Try and get the FEA_FILE_TYPE attribute from the beast to
	; confirm or deny this nasty rumor.
	;
	; Since we've already fetched the attrs, just look through the
	; list, since the source file may have already been closed by
	; this point

	mov	bx, ss:[fileAttrsHandle]
	call	MemDerefES
	clr	di
	mov	cx, ss:[numFileAttrs]
searchLoop:
	cmp	es:[di].FEAD_attr, FEA_FILE_TYPE
	je	attrFound
	add	di, size FileExtAttrDesc
	loop	searchLoop
	jmp	createFile

attrFound:
	les	di, es:[di].FEAD_value
	mov	cx, es:[di]
	cmp	cx, GFT_OLD_VM
	jne	createFile
	;
	; Oh, joy. Set the FCF_FIX_OLD_LONGNAME bit in our inherited frame.
	; 
	ornf	ss:[flags], mask FCF_FIX_OLD_LONGNAME
	andnf	ah, not mask FCF_NATIVE	; create with longname first time,
					;  please
	jmp	createFile


noRemote:
	;
	; Determine if file will be created in a std directory.
	;
	clr	bx				; bx <- parse std path, please
	push	dx
	call	FileGetDestinationDisk		; bx <- disk handle/StandardPath
	mov_tr	ax, dx
	pop	dx
	mov	ss:[overrideRemote], FALSE	; assume not std path (so no
						;  need to do anything special,
						;  as remote files not possible)
	test	bx, DISK_IS_STD_PATH_MASK
	jz	reallyCreateFile		; assumption correct

	mov	ss:[overrideRemote], TRUE
	;
	; In a std path, so first make sure the local version of the std
	; path exists, so we end up there when we do the SetDirOnPath
	;
	push	ax
	call	FileEnsureLocalPath
	pop	dx			; ds:dx <- path w/o drive specifier
					;  or leading components that make up
					;  the std path whose value is in BX
	;
	; Set up to enumerate the std path.
	;
	mov	cx, TRUE		; cx <- ds:dx *is* path being operated
					;  on
	call	InitForPathEnum
	;
	; Change to the first (i.e. local) directory of the std path
	;
	call	SetDirOnPath
	;
	; ds:dx is now the proper path below the std path, while the current
	; dir is the first directory of the std path, in which we want
	; to create the file.
	;
	jmp	reallyCreateFile



FileCopyCreateDest endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	FileCopy

DESCRIPTION:	Copies source file to destination file. Destination file
		will be created. An existing file with the same name will
		be truncated.

CALLED BY:	GLOBAL

PASS:		ds:si - source file name
		  OR  - ds = 0 and si = file handle to copy from
		cx - source disk handle
		es:di - destination file name
		dx - destination disk handle
		
		Either one of the disk handles may be 0, in which case 
		the disk handle in the thread's current path will be used.

		If a disk handle is provided, the corresponding path *must*
		be absolute (begin with a backslash).

RETURN:		carry set if error
		ax = error code
			0 if no error
			ERROR_FILE_NOT_FOUND
			ERROR_PATH_NOT_FOUND
			ERROR_TOO_MANY_OPEN_FILES
			ERROR_ACCESS_DENIED
			ERROR_SHORT_READ_WRITE (insufficient space on
				destination disk)

DESTROYED:	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	4/90		Initial version
	Todd	04/23/94	XIP'ed

------------------------------------------------------------------------------@
FXIP<CopyStackCodeXIP		segment	resource	>

FileCopy	proc	far	
	clr	ax			;don't override remote copies of file
	call	FileCopyCommon	
	ret
FileCopy	endp

FXIP<CopyStackCodeXIP		ends			>

COMMENT @-----------------------------------------------------------------------

FUNCTION:	FileCopyLocal

DESCRIPTION:	Copies source file to destination file. Destination file
		will be created. An existing file with the same name will
		be truncated.

		Copy file to local standard path directory even
		if a file of the same name exists in remote directory.

CALLED BY:	GLOBAL

PASS:		ds:si - source file name
		  OR  - ds = 0 and si = file handle to copy from
		cx - source disk handle
		es:di - destination file name
		dx - destination disk handle
		
		Either one of the disk handles may be 0, in which case 
		the disk handle in the thread's current path will be used.

		If a disk handle is provided, the corresponding path *must*
		be absolute (begin with a backslash).

RETURN:		carry set if error
		ax = error code
			0 if no error
			ERROR_FILE_NOT_FOUND
			ERROR_PATH_NOT_FOUND
			ERROR_TOO_MANY_OPEN_FILES
			ERROR_ACCESS_DENIED
			ERROR_SHORT_READ_WRITE (insufficient space on
				destination disk)

DESTROYED:	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	4/90		Initial version
	Todd	04/23/94	XIP'ed

------------------------------------------------------------------------------@
FXIP<CopyStackCodeXIP		segment	resource	>

FileCopyLocal	proc	far	
	
	mov	ax,TRUE			
	call	FileCopyCommon	
	ret

FileCopyLocal	endp

FXIP<CopyStackCodeXIP		ends			>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileMove
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move a file or directory from one place to another. For some
		file systems, it will be possible to move directories from
		one drive to another, while for others an error will be
		returned. If the thing being moved is a file, it will
		always be moved properly by this function, so long as the
		destination name doesn't already exist and its directory
		is writable.

CALLED BY:	GLOBAL
PASS:		ds:si	= source file name
		cx	= source disk handle
		es:di	= destination file name
		dx	= destination disk handle
		
		Either one of the disk handles may be 0, in which case 
		thread's current path will be used and the associated file
		name (either source or destination) may be relative.
		
		If a disk handle is provide, the corresponding path *must*
		be absolute (begin with a backslash).
RETURN:		carry set if errror:
			ax	= ERROR_FILE_NOT_FOUND
				= ERROR_PATH_NOT_FOUND
				= ERROR_TOO_MANY_OPEN_FILES
				= ERROR_ACCESS_DENIED
				= ERROR_SHORT_READ_WRITE (insufficient space
				  on destination disk)
				= ERROR_DIFFERENT_DEVICE
				= ERROR_INSUFFICIENT_MEMORY
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	11/ 9/94    	Initial version (moved original code to
				FileMoveCommon)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FXIP <	CopyStackCodeXIP	segment	resource			>

FileMove	proc	far
	clr	ax			; don't override remote
	FALL_THRU	FileMoveCommon
FileMove	endp

FXIP <	CopyStackCodeXIP	ends					>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileMoveCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move a file or directory from one place to another. For some
		file systems, it will be possible to move directories from
		one drive to another, while for others an error will be
		returned. If the thing being moved is a file, it will
		always be moved properly by this function, so long as the
		destination name doesn't already exist and its directory
		is writable.

CALLED BY:	(INTERNAL) FileMove, FileMoveLocal
PASS:		ds:si	= source file name
		cx	= source disk handle
		es:di	= destination file name
		dx	= destination disk handle
		ax	= override remote boolean
			If TRUE then
				move file to local standard path directory
				even if a file of the same name exists in
				remote directory.  Any existing local file
				is overwritten.
			If FALSE then
				move file to local standard path direcory
				if no file of the same name exists.  If file
				exists in local or remote directory, returns
				error.
		
		Either one of the disk handles may be 0, in which case 
		thread's current path will be used and the associated file
		name (either source or destination) may be relative.
		
		If a disk handle is provide, the corresponding path *must*
		be absolute (begin with a backslash).
RETURN:		carry set if errror:
			ax	= ERROR_FILE_NOT_FOUND
				= ERROR_PATH_NOT_FOUND
				= ERROR_TOO_MANY_OPEN_FILES
				= ERROR_ACCESS_DENIED
				= ERROR_SHORT_READ_WRITE (insufficient space
				  on destination disk)
				= ERROR_DIFFERENT_DEVICE
				= ERROR_INSUFFICIENT_MEMORY
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		first generate the real name and disk of the source name,
		once standard path b.s. has been done away with
		if (srcDisk != 0)
			push to root of src disk
		if cur dir is S.P.:
			enum path and call FSPOF_GET_ATTRIBUTES on src name
				until found, or hit end of path
		build full src name from cur dir & src name
		finish path enum if cur dir was S.P.
		if (srcDisk != 0)
			pop dir

		; now deal with the destination. we need to both find where the
		; destination will reside and ensure, if it's in a S.P., that
		; the necessary local components have been created.
		if (destDisk != 0)
			push to root of dest disk
		else
			push dir

		FileEnsureLocalPath(ds:dx <- es:di)

		generate absolute path & disk for leading components
		of dest
		pop dir

		If dest file exists and override remote boolean is FALSE
			return ERROR_FILE_EXISTS.
		Else if dest file exists and override remote boolean is TRUE,
			push to root of dest disk
			call InitForPathEnum/SetDirOnPath to set out current
			dir to the local dir.
			call FileDelete to delete dest file in local dir.
				If ERROR_FILE_NOT_FOUND, it mean dest file
				exists in remote dir.  Ignore error.
				If any other error, return error code.

		; deal with move within the same filesystem, also giving the
		; FSD to effect a move between different filesystems that
		; it manages, in case it can do something (e.g. Novell
		; moving files within the same volume, but different logical
		; drives...)
		if disks same or (both run by same FSD and in different drives)
			call FSPOF_MOVE_FILE
			if it's happy, we're happy

		if any links are encountered, just do FileCopy &
		delete.  

		if src is directory, return ERROR_DIFFERENT_DEVICE
		
		call FileCopy & delete source

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/27/92		Initial version
	chrisb	11/92		modified for links
	Todd	04/23/94	XIP'ed
	AY	11/9/94		Changed from FileMove to FileMoveCommon

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	FULL_EXECUTE_IN_PLACE
CopyStackCodeXIP		segment	resource
FileMoveCommon		proc	far
	mov	ss:[TPD_dataBX], handle	FileMoveCommonReal
	mov	ss:[TPD_dataAX], offset	FileMoveCommonReal
	GOTO	SysCallMovableXIPWithDSSIAndESDI
FileMoveCommon		endp
CopyStackCodeXIP		ends

else
FileMoveCommon		proc	far
	FALL_THRU	FileMoveCommonReal
FileMoveCommon		endp
endif

FileMoveData	struct
    FMD_srcActualDisk		word
    FMD_srcActualPath		PathName
    FMD_destActualDisk 		word
    FMD_destActualPath		PathName
FileMoveData	ends

FileMoveCommonReal	proc	far

destPath	local	fptr.char	push	es, di
destDiskHandle	local	word		push	dx
overrideRemote	local	word		push	ax
pathBuffer	local	hptr.FileMoveData
pathBufferSeg	local	sptr.FileMoveData
cleanupPathEnum	local	BooleanByte
cleanupPushDir	local	BooleanByte
destFileExists	local	BooleanByte

		uses	bx,cx,dx,di,si,ds,es
		.enter
		clr	ax
			CheckHack <offset cleanupPushDir + size byte \
				eq offset cleanupPathEnum \
				and size cleanupPathEnum eq size byte>
		mov	{word} ss:[cleanupPushDir], ax	; clear both
		czr	al, ss:[destFileExists]
	;
	; Allocate a buffer into which the two full paths will be built.
	; 
		mov	ax, size FileMoveData
		push	cx
		mov	cx, ALLOC_DYNAMIC_LOCK
		call	MemAllocFar
		pop	cx
		jnc	haveBuffer
		mov	ax, ERROR_INSUFFICIENT_MEMORY
		jmp	done
haveBuffer:
		mov	ss:[pathBuffer], bx
		mov	ss:[pathBufferSeg], ax
	;
	; If src disk given, push to its root.
	; 
		jcxz	afterPush
		call	PushToRoot
afterPush:
	;
	; If the source file is a link -- skip right to the
	; Copy/Delete code
	;
		push	cx			; disk handle
		mov	dx, si			; ds:dx <- src path
		call	FileGetAttributes
		mov_tr	ax, cx
		pop	cx
		jcxz	afterPop
		call	FilePopDir
afterPop:
		jc	notALink
		test	ax, mask FA_LINK
		jz	notALink
	;
	; It's a link.  Set up regs for FileCopy.
	; cx = source disk, ds:si - source path
	;
		les	di, ss:[destPath]
		mov	dx, ss:[destDiskHandle]
		jmp	doCopy

	;
	; It's not a link.  Construct the actual path of the source,
	; so that we know exactly which disk its on, and we can be
	; sure that there are no links in the path.
	;

notALink:
		call	FileMoveLocateSource
		jnc	locateDestination
error:
		stc
		jmp	cleanUp

locateDestination:
		lds	dx, ss:[destPath]
		mov	cx, ss:[destDiskHandle]
		call	FileMoveLocateDest	; ds <- pathBufferSeg
		jnc	noError
	;
	; It's an error if dest file exists and we're not doing a local move.
	;
		tst	ss:[overrideRemote]
		jz	error			; return whatever error it is
						;  if we're not doing local
						;  move
		cmp	ax, ERROR_FILE_EXISTS
		jne	error			; return any other error
		mov	ss:[destFileExists], BB_TRUE

noError:
		mov	bx, ds:[FMD_srcActualDisk]
		mov	si, ds:[FMD_destActualDisk]
		cmp	bx, si
		je	doMove			; same disk => ok

		call	FileLockInfoSharedToES
		mov	di, es:[bx].DD_drive
		cmp	di, es:[si].DD_drive
		LONG je	useFileCopy		; different disk but same
						;  drive, so FS can't possibly
						;  take care of it.
		mov	ax, es:[di].DSE_fsd
		mov	di, es:[si].DD_drive
		cmp	ax, es:[di].DSE_fsd
		LONG jne useFileCopy		; different FSDs, so FS can't
						;  possibly take care of it.

		call	FSDUnlockInfoShared	; 'cuz FileGetDestinationDisk
						;  doesn't like it locked

doMove:
	;
	; If destination file does not exist, the FSD will move the file to
	; the right place (either local or remote) by itself.
	;
		tst	ss:[destFileExists]
		jz	callFSD
	;
	; The file already exists but we want to do a local move (or else we
	; would have returned an error earlier).  First see if file will be
	; moved to a standard path.
	;
		mov	cx, ds:[FMD_destActualDisk]
		call	PushToRoot
		mov	ss:[cleanupPushDir], BB_TRUE
		mov	dx, offset FMD_destActualPath	; ds:dx = dest path
		clr	bx			; parse std path
		call	FileGetDestinationDisk	; bx = disk handle / std path
		test	bx, DISK_IS_STD_PATH_MASK
		jz	delDestFile
	;
	; We are moving to a standard path.  Make sure the local version
	; of the std path exists, then chdir to the first (i.e. local)
	; directory of the std path.
	;
		call	FileEnsureLocalPath
		jc	error
		mov	cx, TRUE
		call	InitForPathEnum		; ds:dx advanced to skip any
						;  backslash
		mov	ax, ERROR_PATH_NOT_FOUND	; (or should it be
							;  something else?)
		jc	errorJMP
		mov	ss:[cleanupPathEnum], BB_TRUE
		call	SetDirOnPath

delDestFile:
	;
	; Delete the existing destination file, but only try it in the local
	; dir.  If we get ERROR_FILE_NOT_FOUND, it means the existing file
	; is in the remote dir, which is okay.
	;
		call	FileDelete
		jnc	callFSD
		cmp	ax, ERROR_FILE_NOT_FOUND
		jne	errorJMP

callFSD:
		call	FileLockInfoSharedToES
		push	bp
		clr	al			; lock may be aborted
		call	DiskLockFar		; lock dest disk
		jc	moveError
		
		mov	cx, si			; es:cx <- dest disk
		mov	si, ds:[FMD_srcActualDisk]	; es:si <- src disk

			CheckHack <offset FMFD_dest eq 0 and \
					size FSMoveFileData eq size fptr>
		push	ds
		mov	ax, offset FMD_destActualPath
		push	ax
		mov	bx, sp			; ss:bx <- FSMoveFileData

		mov	di, DR_FS_PATH_OP
		mov	ax, FSPOF_MOVE_FILE shl 8; al clear so disk lock
						 ;  may be aborted
		mov	dx, offset FMD_srcActualPath
		push	bx
		call	DiskLockCallFSD
		pop	bp
		lea	sp, ss:[bp+size FSMoveFileData]
		
		mov	si, cx
		call	DiskUnlockFar		; unlock destination disk
moveError:
		pop	bp
		call	FSDUnlockInfoShared	; unlock the FSIR

		jnc	cleanUp
	;
	; If any error but ERROR_DIFFERENT_DEVICE (including
	; ERROR_CANNOT_MOVE_DIRECTORY), return now.
	; 
		cmp	ax, ERROR_DIFFERENT_DEVICE
		je	ensureSrcNotDir
errorJMP:
		jmp	error
useFileCopy:
		call	FSDUnlockInfoShared
ensureSrcNotDir:
	;
	; If source is a directory, we can't do recursive moves (besides,
	; caller could well want to provide feedback, and we wouldn't want
	; to steal its thunder...)
	; 
	; XXX: FileGetAttributes could return an error here, but it
	; seems highly unlikely
	;
		mov	cx, ds:[FMD_srcActualDisk]
		mov	dx, offset FMD_srcActualPath
		call	PushToRoot
		call	FileGetAttributes
		call	FilePopDir
		test	cx, mask FA_SUBDIR
		mov	ax, ERROR_DIFFERENT_DEVICE
		jnz	errorJMP
	;
	; Copy the file over, aborting if there's any error in the copy.
	; 
		segmov	es, ds
		mov	si, offset FMD_srcActualPath
		mov	di, offset FMD_destActualPath
		mov	cx, ds:[FMD_srcActualDisk]
		mov	dx, ds:[FMD_destActualDisk]
doCopy:
		mov	ax, ss:[overrideRemote]
		call	FileCopyCommonReal
		jc	cleanUp
	;
	; Now delete the source file after pushing to the root of the disk on
	; which it resides. We declare the move a success even if the delete
	; fails....is this right? The alternative is to delete the dest and
	; declare it a failure, possibly after the caller has deleted the
	; dest after an earlier call had failed because it already existed...
	;
	; XXX: NEED TO OVERRIDE READ-ONLY ATTRIBUTE OF SOURCE BEFORE DELETE
	; 
		call	PushToRoot

		xchg	dx, si
		call	FileDelete
		jc	cantDeleteSource
sourceNuked:
		xchg	dx, si
		call	FilePopDir
		clc
cleanUp:
		pushf
		mov	bx, ss:[pathBuffer]
		call	MemFree
	;
	; If we started a path enumeration to deal with ignoring files in
	; remote directories, finish it now.
	;
		tst	ss:[cleanupPathEnum]
		jz	cleanupDirStack
		call	FinishWithPathEnum
cleanupDirStack:
		tst	ss:[cleanupPushDir]
		jz	popFlags
		call	FilePopDir
popFlags:
		popf
done:		
		.leave
		ret

cantDeleteSource:
	;
	; Unable to delete the source. If anything but ACCESS_DENIED (which
	; implies the source is read-only), nuke the dest and return that
	; error. Else try clearing FA_RDONLY and doing it again.
	; 
		cmp	ax, ERROR_SHARING_VIOLATION	;for baseband nets
		jz	hack10
		cmp	ax, ERROR_ACCESS_DENIED
		jne	moveFailed
hack10:
		
		push	cx
		call	FileGetAttributes		
		test	cx, mask FA_RDONLY
		jz	popCXMoveFailed	; not read-only, so we just can't do it
		
		andnf	cx, not mask FA_RDONLY
		call	FileSetAttributes
		jc	popCXMoveFailed
	    ;
	    ; (don't loop back to the other FileDelete, to protect against
	    ; any weird setup where FA_RDONLY can't be cleared, but it doesn't
	    ; tell us this; if we fail the delete after clearing RDONLY, just
	    ; return ACCESS_DENIED and live with it)
	    ; 
		call	FileDelete
		jnc	sourceNuked
popCXMoveFailed:
		pop	cx
		mov	ax, ERROR_ACCESS_DENIED
moveFailed:
	;
	; Either not ACCESS_DENIED, or it was, but the thing isn't marked
	; read-only, or it was, the thing is read-only, and we can't change
	; it. In any case, we want to declare the move a failure (I guess)
	; and return carry set, with ax = error code, after nuking the
	; successfully-copied destination.
	; ax	= error code to return
	; cx	= src disk handle
	; ds:dx	= src name
	; si	= dest disk handle
	; es:di	= dest name
	; 
		call	FilePopDir	; get out of src directory
		push	ax		; save error code
		mov	cx, si		; cx <- dest disk handle
		segmov	ds, es
		mov	dx, di		; ds:dx <- dest path
		call	PushToRoot
		call	FileDelete
		call	FilePopDir
		pop	ax
		stc
		jmp	cleanUp
FileMoveCommonReal	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileMoveLocateSource
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Locate the source for a file move

CALLED BY:	FileMove

PASS:		ds:si - source path
		cx - source disk

RETURN:		if error
			carry set
		else
			carry clear
			FMD_srcActualPath and FMD_srcActualDisk filled in

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:
	Since we know the thing's not a link, just call
	FileConstructActualPath.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/18/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileMoveLocateSource	proc near
	uses	bx,cx,dx
	.enter	inherit	FileMoveCommonReal

	;
	; Construct the actual path of the source, and store the disk
	; handle in the DAP_disk field.
	;

	mov	es, ss:[pathBufferSeg]
	mov	di, offset FMD_srcActualPath	; put in src area

	mov	bx, cx
	mov	cx, size PathName
	clr	dx
	call	FileConstructActualPath
	mov	es:[FMD_srcActualDisk], bx

	.leave
	ret
FileMoveLocateSource	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileMoveLocateDest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Locate the actual destination directory and make sure
		the destination file doesn't already exist.

CALLED BY:	FileMove
PASS:		ds:dx	= destination name
		cx	= destination disk handle (0 => current path)
		ss:bp	= inherited frame
RETURN:		carry set if dest dir doesn't exist, or destination does
			ax	= error code
		carry clear if ok:
			ds, es	= pathBufferSeg

DESTROYED:	ax, bx, cx, dx, si, di

PSEUDO CODE/STRATEGY:
	Special cases to watch for:

	<0>, "\filename"	- file is in root of drive on which
				current directory sits

	<disk handle>, "\leading components\filename"
		- we need to make sure all links in "leading
		components" are resolved, and then tack on the
		filename to the actual path constructed.


KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/28/92		Initial version
	chrisb	11/92		changed to work with links

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LocalDefNLString destPathDot <".", 0>
LocalDefNLString destPathRoot <C_BACKSLASH, 0>

FileMoveLocateDest proc	near
		.enter	inherit FileMoveCommonReal
	;
	; Since we might need to modify the destination name. First
	; create a copy of it on the stack. Wow all of this just to 
	; copy the string to the stack.
	;
		mov_tr	ax, cx
		mov	bx, es
		mov	di, dx
		segmov	es, ds
		call	LocalStringSize		; cx = size w/o null	5 bytes
		inc	cx			; cx = size w/ null	1 byte
	DBCS <	inc	cx			; cx = size w/ null	1 byte	>
		sub 	sp, cx
		mov	di, sp
		segmov	es, ss			;es:di = buffer on stack
		push	cx
		push	ax
		mov	si, dx
		push	di
DBCS <		shr	cx			; convert bytes to chars >
		LocalCopyNString
		pop	dx
		push	es		
		mov	es, bx
		pop	ds			;ds:dx points to new
						;string on stack
		pop	cx			;restore disk handle
	;
	; Now deal with the destination.
	; 
		call	PushToRoot		; else push to disk, or just
						;  pushdir
		call	FileEnsureLocalPath
		LONG jc	done
	;
	; Scan for the final component of the destination name,
	; stopping at the last backslash before it
	; 
		push	cx			; dest disk handle
		mov	cx, length PathName
		mov	si, dx
saveBSPosition:
		mov	bx, si			
		loop	searchLoop
EC <		ERROR	FILE_MOVE_PATH_TOO_LONG				>
searchLoop:
		LocalGetChar ax, dssi
		LocalCmpChar ax, C_BACKSLASH
		je	saveBSPosition
		LocalIsNull	ax
		loopne	searchLoop
EC <		ERROR_NE FILE_MOVE_PATH_TOO_LONG			>

	;
	; BX is now one character AFTER the last backslash, or DX if
	; no backslashes were seen.  If no backslash was seen, then
	; use "." to construct the actual path of the current directory
	;

afterSearch::
		mov	si, bx			; position of last BS+1
		pop	bx			; bx <- dest disk handle

		push	ds, si			; filename
		cmp	si, dx			; no BS in path?
		jne	checkFirst
		segmov	ds, cs
		mov	si, offset destPathDot
		jmp	getActual
	;
	; If the last backslash is the first character of the
	; destination path, then fetch the actual path of the root
	; dir.  This is necessary if the passed disk handle is zero, 
	; and the path name contains a leading backslash.
	;
checkFirst:
		mov	di, dx
SBCS <		add	di, 2						>
DBCS <		add	di, 2*(size wchar)				>
		cmp	si, di
		jne	nukeBackslash
		segmov	ds, cs
		mov	si, offset destPathRoot
		jmp	getActual

	;
	; There are leading components.  Convert the final backslash
	; to a NULL, and construct the actual path of the leading
	; components. 
	;

nukeBackslash:
SBCS <		mov	{char}ds:[si-1], 0	; nuke backslash	>
DBCS <		mov	{wchar}ds:[si-2], 0	; nuke backslash	>
		mov	si, dx
getActual:
		mov	es, ss:[pathBufferSeg]
		mov	di, offset FMD_destActualPath
		mov	cx, size PathName
		clr	dx, bx
		call	FileConstructActualPath
		pop	ds, si			; ds:si - filename
		jc	done

	;
	; CD to the root of the ACTUAL disk 
	;
		push	ds
		segmov	ds, cs
		mov	dx, offset destPathRoot
		call	FileSetCurrentPath
		pop	ds
		jc	done

	;
	; Now, tack on the filename to the end of the actual path
	;
		mov	es:[FMD_destActualDisk], bx
		call	FileAppendFilenameToPath

	;
	; es:di = Actual path of destination file.  See if it exists.
	; If it does, or if the error is any other than
	; ERROR_FILE_NOT_FOUND, then quit.
	; 

		mov	dx, di
		segmov	ds, es		
		call	FileGetAttributes
		jnc	destExists

		cmp	ax, ERROR_FILE_NOT_FOUND
		jne	destError
done:
		call	FilePopDir
	;
	; Remove the buffer allocated for the destination name from
	; the stack
	;
		pop	si			; si = size of string on stack
		mov	bx, sp			; ss:bx = beginning of string
		lea	sp, ss:[bx + si]	; pop string off stack

		.leave
		ret

destExists:
		mov	ax, ERROR_FILE_EXISTS
destError:
		stc
		jmp	done
FileMoveLocateDest endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileAppendFilenameToPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Append a filename to the end of a path, dealing with
		all the various cases that need to be dealt with

CALLED BY:	FileMoveLocateDest

PASS:		ds:si - filename
		es:di - buffer containing either a null string or a
			path, possibly with or without a trailing
			backslash. 
			buffer MUST be of size PathName or greater

RETURN:		carry SET if error (path too long)

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:
	Passed path can be:
		empty
		contain a trailing backslash
		contain NO trailing backslash	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/18/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileAppendFilenameToPath	proc near
	uses	ax,bx,cx,di,si
	.enter

	;
	; Scan to the end of the path
	;

	mov	bx, di			; start of dest
	mov	cx, length PathName
SBCS <	clr	al							>
DBCS <	clr	ax							>
	LocalFindChar			; repne scasb/scasw
	stc
	jne	done
	LocalPrevChar esdi		; point at NULL
	cmp	di, bx
	je	addNameAtESDI

	;
	; See if the last char's a backslash
	;
SBCS <	cmp	{byte} es:[di-1], C_BACKSLASH				>
DBCS <	cmp	{wchar} es:[di-2], C_BACKSLASH				>
	je	addNameAtESDI

	;
	; Store a backslash at es:[di], overwriting the NULL, and
	; increment the dest ptr.
	;

	LocalLoadChar ax, C_BACKSLASH
	LocalPutChar esdi, ax

addNameAtESDI:
	LocalGetChar ax, dssi
	LocalPutChar esdi, ax
	LocalIsNull ax
	loopnz	addNameAtESDI
	tst	cx
	jnz	done
	stc

done:
	.leave
	ret
FileAppendFilenameToPath	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileMoveLocal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move a file or directory from one place to another. For some
		file systems, it will be possible to move directories from
		one drive to another, while for others an error will be
		returned. If the thing being moved is a file, it will
		always be moved properly by this function, so long as the
		destination name doesn't already exist and its directory
		is writable.

		Move file to local standard path directory even if a file of
		the same name exists in remote directory.  Any file of the
		same name in local directory is overwritten.

CALLED BY:	GLOBAL
PASS:		ds:si	= source file name
		cx	= source disk handle
		es:di	= destination file name
		dx	= destination disk handle
		
		Either one of the disk handles may be 0, in which case 
		thread's current path will be used and the associated file
		name (either source or destination) may be relative.
		
		If a disk handle is provide, the corresponding path *must*
		be absolute (begin with a backslash).
RETURN:		carry set if errror:
			ax	= ERROR_FILE_NOT_FOUND
				= ERROR_PATH_NOT_FOUND
				= ERROR_TOO_MANY_OPEN_FILES
				= ERROR_ACCESS_DENIED
				= ERROR_SHORT_READ_WRITE (insufficient space
				  on destination disk)
				= ERROR_DIFFERENT_DEVICE
				= ERROR_INSUFFICIENT_MEMORY
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	11/ 8/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FXIP <	CopyStackCodeXIP	segment	resource			>

FileMoveLocal	proc	far
	mov	ax, TRUE
	GOTO	FileMoveCommon
FileMoveLocal	endp

FXIP <	CopyStackCodeXIP	ends					>

Filemisc	ends



