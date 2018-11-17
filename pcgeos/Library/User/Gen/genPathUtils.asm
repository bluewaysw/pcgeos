COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		genPathUtils.asm

AUTHOR:		Adam de Boor, Jan  7, 1992

ROUTINES:
	Name			Description
	----			-----------
	GenPathSet		Set the object's current path.
	GenPathGet		Fetch the path bound to the given object.
	GenPathGetDiskHandle	Fetch the disk handle for the path bound to
				the given object.
	GenPathRestoreDiskPrompt  Ask the user to insert the disk whose
				handle we're trying to restore.
	UserDiskRestore		Front-end for DiskRestore that automatically
				passes a callback function to prompt for the
				disk, if DiskRestore can't do it by itself.
	UserDiskRestoreCallback	Callback function to ask the user to insert
				a disk.
	GenPathInitPathData	Handle the initialization of
				ATTR_GEN_PATH_DATA.  Note that we've placed
				a hook in the GenClass handler of
				MSG_META_INITIALIZE_VAR_DATA to call this
				routine, over here in this resource, if cx =
				ATTR_GEN_PATH_DATA.
	GenPathFetchDiskHandleAndDerefPath  Locate the GenFilePath for the
				object under the given vardata type, restore
				its disk handle, if necessary.
	GenPathRestoreDiskCallback  Callback function for
				GenPathFetchDiskHandleAndDerefPath when disk
				can't immediately be restored.
	GenPathDiskRestoreError	Put up an explanation for the failure to
				restore the disk.
	GenPathSetObjectPath	Change the path stored in the indicated
				vardata entry to match that passed.
	GenPathSetObjectPathXIP	Change the path stored in the indicated
				vardata entry to match that passed.
	CheckPathAbsolute	See if the passed path is absolute.
	GenPathGetObjectPath	Fetch the path bound to the given object
				under the given vardata tag.
	GenPathConstructFullObjectPath  Constructs a full path from the
				object's path stored under the passed
				vardata type.
	GenPathSetCurrentPathFromObjectPath  Set the thread's current path
				from the value stored in a GenFilePath in
				the object's vardata.
	GenPathUnrelocObjectPath  Flag the bound GenFilePath as needing to
				have its disk handle restored when it's next
				referenced.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	1/ 7/92		Initial revision


DESCRIPTION:
	Utility routines and messages for maintaining one or more filesystem
	paths associated with a generic object.
		

	$Id: genPathUtils.asm,v 1.1 97/04/07 11:45:16 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include Internal/prodFeatures.def

GEN_PATH_DISK_HANDLE_INVALID	equ	-1	; value stored in GFP_disk when
						; object is unrelocated, so
						; we know to call DiskRestore
						; when next we need the disk
						; handle.

GenPath	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenPathSet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the object's current path.

CALLED BY:	MSG_GEN_PATH_SET
PASS:		*ds:si	= generic object
		cx:dx	= null-terminated pathname
		(cx:dx *cannot* be pointing into the movable XIP code resource.)
		bp	= disk handle of path, or StandardPath constant, or 0
RETURN:		carry set if path couldn't be set:
			ax = error code (FileError)
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenPathSet	method dynamic GenClass, MSG_GEN_PATH_SET
		.enter
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr (cx:dx) passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, cxdx					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif
	;
	; Set the object's primary path (ATTR_GEN_PATH_DATA) to that passed.
	; 
		push	cx, dx, es
		mov	es, cx
		mov	di, dx
		mov	ax, ATTR_GEN_PATH_DATA
		mov	dx, TEMP_GEN_PATH_SAVED_DISK_HANDLE
		call	GenPathSetObjectPath
		pop	cx, dx, es
		jc	done
	;
	; If the object is specifically built, pass the message on.
	;
		call	GenCheckIfSpecGrown
		jnc	done
		mov	ax, MSG_GEN_PATH_SET
		mov	di, offset GenClass
		call	ObjCallSuperNoLock
done:
		.leave
		ret
GenPathSet	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenPathGet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the path bound to the given object

CALLED BY:	MSG_GEN_PATH_GET
PASS:		*ds:si	= generic object
		dx:bp	= address to which to copy. if dx is 0, the path is
			  copied to a block allocated on the global heap and
			  cx is ignored
		cx	= size of buffer (may be zero, but DX should be non-
			  zero if it is)
RETURN:		carry set if error (path won't fit in the passed buffer or is
		      	invalid):
			ax	= number of bytes required (0 => path is
				  invalid)
			cx	= disk handle of path
		carry clear if ok:
			if dx:bp passed as far pointer:
				dx:bp - filled with path
			if dx 0:
				dx 	= handle of block holding the path
			cx	= disk handle of path
			ax	= destroyed
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenPathGet	method dynamic GenClass, MSG_GEN_PATH_GET
		.enter
		mov	es, dx
		mov	di, bp
		mov	ax, ATTR_GEN_PATH_DATA
		mov	dx, TEMP_GEN_PATH_SAVED_DISK_HANDLE
		call	GenPathGetObjectPath
		mov	dx, es		; restore possible fptr
		jc	done
		tst	dx		; fptr passed?
		jnz	done		; yes -- buffer filled and registers
					;  are now set up for return
		mov_tr	dx, ax		; no -- shift memory handle into dx
					;  for return
done:
		.leave
		ret
GenPathGet	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenPathGetDiskHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the disk handle for the path bound to the given object

CALLED BY:	MSG_GEN_PATH_GET_DISK_HANDLE
PASS:		*ds:si	= generic object
RETURN:		cx	= disk handle (0 if path is invalid)
DESTROYED:	ax, dx, bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenPathGetDiskHandle	method dynamic GenClass, MSG_GEN_PATH_GET_DISK_HANDLE
		.enter
		mov	ax, ATTR_GEN_PATH_DATA
		mov	dx, TEMP_GEN_PATH_SAVED_DISK_HANDLE
		clr	cx		; don't copy path out; es already
					;  non-zero, since it points to
					;  GenClass
		call	GenPathGetObjectPath
		.leave
		ret
GenPathGetDiskHandle	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenPathRestoreDiskPrompt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ask the user to insert the disk whose handle we're trying
		to restore.

CALLED BY:	MSG_META_GEN_PATH_RESTORE_DISK_PROMPT
PASS:		*ds:si	= generic object
		ss:bp	= GenPathDiskRestoreArgs
		(For XIP'ed geodes, the fptrs passed in GenPathDiskRestoreArgs
			*cannot* be pointing into the movalbe XIP code seg.)
		dx	= size GenPathDiskRestoreArgs
		cx	= DiskRestoreError that will be returned to DiskRestore
RETURN:		carry set if message handled:
			ax	= DiskRestoreError (may be DRE_DISK_IN_DRIVE)
		bp	= unchanged
		ds	= possibly destroyed (fixed up by object system)
DESTROYED:	cx, dx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenPathRestoreDiskPrompt method dynamic GenClass,
				MSG_META_GEN_PATH_RESTORE_DISK_PROMPT
		.enter
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptrs passed in GenPathDiskRestoreArgs are valid
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, ss:[bp].GPDRA_driveName			>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		movdw	bxsi, ss:[bp].GPDRA_diskName			>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif
		call	GenCheckIfSpecGrown
		jnc	handleItOurselves
		
		mov	di, offset GenClass
		call	ObjCallSuperNoLock
		jc	done		; => handled by spui

handleItOurselves:
	;
	; Call UserStandardDialog to put up a box asking the user to insert
	; the disk in the drive. USD takes two argument strings, and that's
	; what we've got, so we're golden.
	;
	; Copy the drive and disk name onto the stack so we can use
	; the callback for UserDiskRestore without fear of things moving.
	; 
		sub	sp, size VolumeName + DRIVE_NAME_MAX_LENGTH
		segmov	es, ss
		mov	di, sp
		lds	si, ss:[bp].GPDRA_driveName
		mov	cx, DRIVE_NAME_MAX_LENGTH
		mov	dx, di		; save drive name start
		rep	movsb

		lds	si, ss:[bp].GPDRA_diskName
		mov	cx, size VolumeName
		push	di		; save disk name start
		rep	movsb
		pop	di
		segmov	ds, ss		; ds:di <- disk name
					; ds:dx <- drive name
		mov	ax, ss:[bp].GPDRA_errorCode
		call	UserDiskRestoreCallback

		mov	di, sp		; clear the stack
		lea	sp, ss:[di+size VolumeName+DRIVE_NAME_MAX_LENGTH]
		jc	done
		mov	ax, DRE_DISK_IN_DRIVE	; ensure meaningful status code
done:
		stc			; signal message handled
		.leave
		ret
GenPathRestoreDiskPrompt endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UserDiskRestore
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Front-end for DiskRestore that automatically passes a callback
		function to prompt for the disk, if DiskRestore can't do it
		by itself.

CALLED BY:	(GLOBAL)
PASS:		ds:si	= buffer to which the disk handle was saved
RETURN:		carry set if disk could not be restored:
			ax	= DiskRestoreError
		carry clear if disk restored:
			ax	= handle of disk for this invocation of
				  PC/GEOS
DESTROYED:	nothing
SIDE EFFECTS:
	WARNING:  This routine MAY resize the LMem block in which the
		  application object sits, moving it on the heap and
		  invalidating stored segment pointers to it.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/19/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UserDiskRestore	proc	far
		uses	cx, dx
		.enter
		mov	cx, SEGMENT_CS
		mov	dx, offset UserDiskRestoreCallback
		call	DiskRestore
		.leave
		ret
UserDiskRestore	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UserDiskRestoreCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback function to ask the user to insert a disk.

CALLED BY:	(INTERNAL) UserDiskRestore, GenPathRestoreDiskPrompt
PASS:		ds:dx	= drive name
		ds:di	= disk name
		(For XIP'ed geodes, the drive name and disk name *cannot* be
			pointing into the movable XIP code resource.)
RETURN:		carry set if user canceled the restore:
			ax	= DRE_USER_CANCELED_RESTORE
		carry clear if user claims the disk is there:
			ax	= DRE_DISK_IN_DRIVE
DESTROYED:	bx, si, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/19/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
genPathDiskRestoreTriggerTable	StandardDialogResponseTriggerTable \
	<length genPathDiskRestoreTriggers>
genPathDiskRestoreTriggers	StandardDialogResponseTriggerEntry \
	<diskInDriveMoniker, 		IC_YES>,
	<cancelDiskRestoreMoniker, 	IC_NO>

UserDiskRestoreCallback proc	far
		uses	bp
diskName	local	VolumeName
		uses	es, ds, cx
		.enter
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptrs passed in are valid
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, dsdx					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		movdw	bxsi, dsdi					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif
	;
	; Copy the disk name into a local buffer so we can trim the trailing
	; spaces from its end.
	; 
		mov	si, di
		segmov	es, ss
		lea	di, ss:[diskName]
		mov	cx, size VolumeName
		rep	movsb
		lea	si, ss:[diskName]
		mov	di, si
findLastNonSpaceLoop:
		lodsb	ss:
		tst	al			; end of string?
		jz	findSpaceLoopDone
		cmp	al, ' '			; space?
		je	findLastNonSpaceLoop	; then don't record position
		mov	di, si			; else record addr of byte
		jmp	findLastNonSpaceLoop	; after non-space

findSpaceLoopDone:		
	;
	; ss:di is the byte after the last non-space char in the name. Store
	; a null there, as we don't like to see all the extra spaces at the end.
	; 
		mov	{char}ss:[di], 0
		lea	ax, ss:[diskName]
		push	bp

		sub	sp, size StandardDialogParams
		mov	bp, sp
		mov	ss:[bp].SDP_customFlags, CustomDialogBoxFlags <
			0,		; CDBF_SYSTEM_MODAL
			CDT_ERROR,
			GIT_MULTIPLE_RESPONSE,
			0
		>
	;
	; Store disk name (\1) and drive name (\2)
	; 
		mov	ss:[bp].SDP_stringArg1.segment, ss
		mov	ss:[bp].SDP_stringArg1.offset, ax
		movdw	ss:[bp].SDP_stringArg2, dsdx
	;
	; Lock down the format string.
	; 
		mov	bx, handle Strings
		call	MemLock
		mov	ds, ax
		assume	ds:Strings
		mov	di, ds:[diskRestorePrompt]
		movdw	ss:[bp].SDP_customString, axdi
	;
	; Set up the custom triggers, since there doesn't seem to be an
	; OK/Cancel standard dialog box anymore.
	; 
		mov	ss:[bp].SDP_customTriggers.segment, cs
		mov	ss:[bp].SDP_customTriggers.offset, 
				offset genPathDiskRestoreTriggerTable
		clr	ss:[bp].SDP_helpContext.segment
		call	UserStandardDialog
		pop	bp
		call	MemUnlock
		assume	ds:nothing
	;
	; If response was yes, return carry clear and DRE_DISK_IN_DRIVE.
	; Else return carry set and DRE_USER_CANCELED_RESTORE
	; 
		cmp	ax, IC_YES
		mov	ax, DRE_DISK_IN_DRIVE
		je	done			; (carry clear)
		mov	ax, DRE_USER_CANCELED_RESTORE
		stc
done:
		.leave
		ret
UserDiskRestoreCallback endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenPathInitPathData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle the initialization of ATTR_GEN_PATH_DATA.  Note
		that we've placed a hook in the GenClass handler of
		MSG_META_INITIALIZE_VAR_DATA to call this routine, over
		here in this resource, if cx = ATTR_GEN_PATH_DATA.

CALLED BY:	GenInitializeVarData (GenClass MSG_META_INITIALIZE_VAR_DATA
		handler)
PASS:		*ds:si	= generic object
		cx	= ATTR_GEN_PATH_DATA
RETURN:		ax	= offset to extra data created
DESTROYED:	cx, dx, bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/ 8/92		Initial version
	doug	5/92		Moved base MSG_META_INITIALIZE_VAR_DATA handler
				to genClass.asm, in Build resource

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenPathInitPathData	proc far
	;
	; Add the data to the object.
	; 
		mov	ax, ATTR_GEN_PATH_DATA or mask VDF_SAVE_TO_STATE
		mov	cx, size GenFilePath
		call	ObjVarAddData
	;
	; Initialize it to SP_TOP
	; 
		mov	ds:[bx].GFP_disk, SP_TOP
		mov	ds:[bx].GFP_path[0], 0
	;
	; Return offset in ax
	; 
		mov_tr	ax, bx
		ret
GenPathInitPathData	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenPathFetchDiskHandleAndDerefPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Locate the GenFilePath for the object under the given
		vardata type, restore its disk handle, if necessary.

CALLED BY:	INTERNAL
PASS:		*ds:si	= object
		ax	= vardata type under which the GenFilePath is stored
		dx	= vardata type under which the disk handle was saved
RETURN:		ax	= disk handle (0 if needed to restore the disk but
			  couldn't)
		ds:bx	= GenFilePath
DESTROYED:	nothing?

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenPathFetchDiskHandleAndDerefPath proc	far
		uses	dx
		.enter
	;
	; "Dereference" the path vardata item. This will cause it to be created
	; and properly initialized if it wasn't there before.
	; 
		call	ObjVarDerefData
	;
	; See if we need to restore the disk handle.
	; 
		cmp	ds:[bx].GFP_disk, GEN_PATH_DISK_HANDLE_INVALID
		jne	done
	;
	; Yup. We need to restore the disk handle. Go find the vardata in
	; which the data to perform this bit of magic resides.
	; 
		xchg	ax, dx		; save GFP tag, as we'll need it
					;  after the restore
					; ax <- saved disk tag
		call	ObjVarFindData
EC <		ERROR_NC	GEN_PATH_DISK_HANDLE_NOT_SAVED		>
	;
	; Set up a frame as a convenient way to pass the path and saved-disk
	; tags to our callback and to the handler of
	; MSG_GEN_PATH_DISK_RESTORE_PROMPT.
	; 
		push	bp, cx
		sub	sp, size GenPathDiskRestoreArgs
		mov	bp, sp
		mov	ss:[bp].GPDRA_pathType, dx
		mov	ss:[bp].GPDRA_savedDiskType, ax
	;
	; Pass our callback our optr in *ds:bx and the frame in ss:bp
	; 
		xchg	bx, si		; ds:si <- saved disk handle buffer
					; *ds:bx <- object
	;
	; Ask the kernel to restore the disk handle, passing our callback
	; routine, of course.
	; 
		mov	cx, SEGMENT_CS
		mov	dx, offset GenPathRestoreDiskCallback
		call	DiskRestore
		jnc	restoredOK
		cmp	ax, DRE_USER_CANCELED_RESTORE
		je	zeroDiskHandle
		
		call	GenPathDiskRestoreError

zeroDiskHandle:
	;
	; DiskRestore failed. We don't much care about the error code here,
	; so 0 what would otherwise be the disk handle.
	; 
		clr	ax

restoredOK:
	;
	; Find the path vardata again, as it could have moved during the
	; callback.
	; 
		mov_tr	dx, ax			; dx <- disk handle
		mov	ax, ss:[bp].GPDRA_pathType
		lea	sp, [bp+size GenPathDiskRestoreArgs]	; clear the
		pop	bp, cx					;  stack

		mov	si, bx			; *ds:si <- object
		call	ObjVarFindData
	;
	; XXX: make sure the path actually exists and tell user of its
	; demise if it's gone, then return 0 disk handle.
	; 

	;
	; Save the disk handle away.
	; 
		mov	ds:[bx].GFP_disk, dx

done:
	;
	; Return the disk handle to our caller.
	; 
		mov	ax, ds:[bx].GFP_disk
		.leave
		ret
GenPathFetchDiskHandleAndDerefPath endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenPathRestoreDiskCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback function for GenPathFetchDiskHandleAndDerefPath
		when disk can't immediately be restored.

CALLED BY:	GenPathFetchDiskHandleAndDerefPath via DiskRestore
PASS:		ds:dx	= drive name (null-terminated, with trailing ':')
		ds:di	= disk name (null-terminated)
		ds:si	= buffer to which the disk handle was saved with
			  DiskSave
		ax	= DiskRestoreError that would be returned if
			  callback weren't being called.
		bx, bp	= as passed to DiskRestore
		
		*ds:bx	= object whose path is being resurrected
		ss:bp	= GenPathDiskRestoreArgs buffer, partially filled in
RETURN:		carry clear if disk should be in the drive
			ds:si	= new position of buffer, if it moved.
		carry set if user canceled the restore:
			ax	= error code (usually DRE_USER_CANCELED_RESTORE)
DESTROYED:	cx, dx, bx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/19/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenPathRestoreDiskCallback proc	far
		.enter
	;
	; Finish loading up the fields of the GenPathDiskRestoreArgs
	; 
		movdw	ss:[bp].GPDRA_driveName, dsdx
		movdw	ss:[bp].GPDRA_diskName, dsdi
		mov	ss:[bp].GPDRA_errorCode, ax
	;
	; Call the object to do what it feels necessary.
	; 
		mov	si, bx
		mov	ax, MSG_META_GEN_PATH_RESTORE_DISK_PROMPT
		call	ObjCallInstanceNoLock	; preserves bp
		jnc	notAnswered
	;
	; Locate the saved disk data again
	; 
		push	ax
		mov	ax, ss:[bp].GPDRA_savedDiskType
		call	ObjVarFindData
EC <		ERROR_NC	GEN_PATH_DISK_HANDLE_NOT_SAVED	>
  		xchg	bx, si		; ds:si <- saved data, *ds:bx <- object
	;
	; Recover the returned error code and set carry if it's not
	; DRE_DISK_IN_DRIVE
	; 
		pop	ax
		cmp	ax, DRE_DISK_IN_DRIVE
		je	done
doneError:
		stc
done:
		.leave
		ret
notAnswered:
	;
	; If no one answered the call, return the original error code back
	; again.
	; 
		mov	ax, ss:[bp].GPDRA_errorCode
		jmp	doneError
GenPathRestoreDiskCallback endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenPathDiskRestoreError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Put up an explanation for the failure to restore the disk

CALLED BY:	(INTERNAL) GenPathFetchDiskHandleAndDerefPath,
       			   GenFieldRestoreNextApp
			   
PASS:		ax	= DiskRestoreError
		ds	= lmem block
RETURN:		ds	= fixed up
DESTROYED:	flags
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/19/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenPathDiskRestoreError proc	far
		uses	ax, bp, di, bx
		.enter
	;
	; Figure the message to use.
	; 
EC <		cmp	ax, length diskRestoreErrorTable		>
EC <		ERROR_AE	GEN_PATH_UNHANDLED_DISK_RESTORE_ERROR	>

		mov	di, ax
		shl	di
	;
	; hack for PDA - brianc 7/14/93
	;
		call	UserCheckIfPDA
		jnc	notPDA
		mov	ax, cs:[diskRestoreErrorTablePDA][di]
		tst	ax
		jz	notPDA
		mov	di, ax
		jmp	short haveErrStr
notPDA:
		mov	di, cs:[diskRestoreErrorTable][di]
		tst	di		; no need for message?
		jz	done		; right
haveErrStr:

	;
	; Setup parameters for UserStandardDialogOptr
	; 
		push	ds:[LMBH_handle]
		sub	sp, size StandardDialogOptrParams
		mov	bp, sp
		mov	ss:[bp].SDOP_customFlags, CustomDialogBoxFlags <
				0,
				CDT_ERROR,
				GIT_NOTIFICATION,
				0
			>
		mov	ax, handle Strings
		movdw	ss:[bp].SDOP_stringArg1, axdi
		mov	ss:[bp].SDOP_customString.handle, ax
		mov	ss:[bp].SDOP_customString.chunk, offset diskRestoreError
		clr	ax
		mov	ss:[bp].SDOP_stringArg2.handle, ax
		mov	ss:[bp].SDOP_customTriggers.handle, ax
		clr	ss:[bp].SDOP_helpContext.segment
		call	UserStandardDialogOptr
		pop	bx
		call	MemDerefDS
done:
		.leave
		ret

diskRestoreErrorTable	word	\
	0,				; DRE_DISK_IN_DRIVE
	dreDriveNoLongerExists,		; DRE_DRIVE_NO_LONGER_EXISTS
	0,				; DRE_REMOVABLE_DRIVE_DOESNT_HOLD_DISK
	0,				; DRE_USER_CANCELED_RESTORE
	dreCouldntCreateNewDiskHandle,	; DRE_COULDNT_CREATE_NEW_DISK_HANDLE
	dreRemovableDriveIsBusy, 	; DRE_REMOVABLE_DRIVE_IS_BUSY
	dreNotAttachedToServer,	 	; DRE_NOT_ATTACHED_TO_SERVER
	drePermissionDenied,		; DRE_PERMISSION_DENIED
	dreAllDrivesUsed		; DRE_ALL_DRIVES_USED

NUM_DISK_RESTORE_ERRORS = ($-diskRestoreErrorTable)/2

diskRestoreErrorTablePDA	word	\
	0,				; DRE_DISK_IN_DRIVE
	dreDriveNoLongerExistsPDA,	; DRE_DRIVE_NO_LONGER_EXISTS
	0,				; DRE_REMOVABLE_DRIVE_DOESNT_HOLD_DISK
	0,				; DRE_USER_CANCELED_RESTORE
	0,				; DRE_COULDNT_CREATE_NEW_DISK_HANDLE
	0, 				; DRE_REMOVABLE_DRIVE_IS_BUSY
	0,	 			; DRE_NOT_ATTACHED_TO_SERVER
	drePermissionDeniedPDA,		; DRE_PERMISSION_DENIED
	dreAllDrivesUsedPDA		; DRE_ALL_DRIVES_USED
.assert (($-diskRestoreErrorTablePDA)/2) eq NUM_DISK_RESTORE_ERRORS
GenPathDiskRestoreError endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenPathSetObjectPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the path stored in the indicated vardata entry to
		match that passed.

CALLED BY:	GLOBAL and GenPathSetObjectPathXIP()
PASS:		*ds:si	= object
		es:di	= path to set (may not be in same block as object)
		(es:di *can* be pointing into any movable XIP code resource.)
		ax	= vardata type under which the path is stored
		dx	= vardata type under which the disk handle should
			  be saved for shutdown
		bp	= disk handle (or StandardPath)
RETURN:		carry set if passed path is invalid:
			ax	= error code
		ds	- pointing to the same block as the "ds" passed.
DESTROYED:	bx, cx, dx

	WARNING: This routine MAY resize LMem and/or object blocks, moving
		 then on the heap and invalidating stored segment pointers
		 to them.

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenPathSetObjectPath proc	far
		uses	es, di
		.enter
EC <		mov	cx, es						>
EC <		mov	bx, ds						>
EC <		cmp	cx, bx						>
EC <		ERROR_E	GEN_PATH_PATH_TO_SET_MAY_NOT_BE_IN_SAME_BLOCK_AS_OBJECT>
   
if FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid for XIP version
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, esdi					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif

		call	FilePushDir
		push	ax		; save path vardata in case we can't
					;  save the disk handle away...

	; EC: ES may be pointing to a different object block, and thus may get
	; biffed by the ObjVarDerefData performed in GenPathFetchDiskHandleAnd-
	; DerefPath, which doesn't do an ObjCallInstanceNoLockES. We know,
	; however, that the block ain't going to move, so we just save es
	; around the call, gross as that seems -- ardeb 1/13/95
EC <		push	es						>
		call	GenPathFetchDiskHandleAndDerefPath
EC <		pop	es						>
		
		tst	ax			; disk handle not restored?
		jz	changeToPassedPath	; yes -- hope the new path
						;  is absolute...

	;
	; Switch the thread's working directory to match the current setting
	; of the path vardata, unless the new path is on a different disk than
	; the current, or is under a standard path, in which case setting to
	; the current value could cause an unnecessary (and unwanted) prompting
	; for a disk the user has just taken out of the drive...
	;
	; New: regardless of disk handle, if passed path is absolute, skip
	; setting current value.  Necessary as current value could be
	; invalid (i.e. deleted directory) - brianc 5/7/93
	;
		call	CheckPathAbsolute	; passed path absolute?
		tst	cx
		jnz	changeToPassedPath	; yes, just use passed path
		
		test	bp, DISK_IS_STD_PATH_MASK
		jnz	changeToPassedPath

		tst	bp			; new path definitely relative?
		jz	setCurrentPath		; yes

		cmp	ax, bp			; different disk from current?
		jne	changeToPassedPath	; yes -- don't bother

setCurrentPath:
	;
	; Path might be relative, and it's worth our while to set the current
	; path to the current value.
	; 
		push	dx, bx
		lea	dx, ds:[bx].GFP_path
		mov_tr	bx, ax
		call	FileSetCurrentPath
		pop	dx, bx
		jnc	changeToPassedPath
		inc	sp
		inc	sp
		jmp	popDirAndExit

changeToPassedPath:
	;
	; Now change to the path we were given.
	; 
		push	bx, ds, dx	; save path vardata, obj block, and
					;  saved-disk-handle tag
		mov	bx, bp
		segmov	ds, es
		mov	dx, di		; ds:dx <- path to set
		call	FileSetCurrentPath
		pop	bx, ds, dx
		pop	cx		; cx <- path vardata tag
		
		pushf		; save any error code
		push	ax
		push	cx		; save path vardata tag
	;
	; Fetch the fully-qualified form into the buffer.
	; 
		push	si, bx		; save path base and object chunk
		lea	si, ds:[bx].GFP_path
		mov	cx, size GFP_path
		call	FileGetCurrentPath
		mov_tr	ax, bx
		pop	si, bx
		mov	ds:[bx].GFP_disk, ax
		tst	ax
		jz	deleteSavedDisk
		
	;
	; Save the (new) disk handle in a more permanent form.
	; 
saveDisk:
		mov_tr	bx, ax		; bx <- disk handle
		clr	cx		; => fetch # bytes required to save
		call	DiskSave
		jcxz	changeToDefault	; 0 => you can't save it no matter
					;  how much space you give me.
					;  neener neener neener
	    ;
	    ; Now know how many bytes it'll take, so add the vardata to the
	    ; object, marking it as going to state, of course.
	    ; 
		mov	ax, dx		; (not mov_tr, as may need tag again,
					; if the save fails)
		ornf	ax, mask VDF_SAVE_TO_STATE
		mov	di, bx
		call	ObjVarAddData
	    ;
	    ; Ask the kernel to really save the handle this time.
	    ; 
		xchg	di, bx
		segmov	es, ds
		call	DiskSave
		jc	changeToDefault	; error now => same thing as 0 bytes
					;  before
	;
	; Restore possible error code and flag.
	; 
done:
		inc	sp
		inc	sp		; discard path vardata tag
		pop	ax
		popf
	;
	; Restore original working directory.
	; 
popDirAndExit:
		call	FilePopDir
		.leave
		ret

changeToDefault:
	;
	; Unable to save the current disk, for some reason, so pretend the
	; path is being created for the first time by sending ourselves a
	; MSG_META_INITIALIZE_VAR_DATA for the thing.
	; 
		pop	cx		; cx <- path vardata tag
		push	cx, dx, bp
		mov	ax, MSG_META_INITIALIZE_VAR_DATA
		call	ObjCallInstanceNoLock
		pop	ax, dx, bp
		push	ax		; save vardata tag on the stack again
		call	ObjVarFindData	;  and locate the data so we can get
		mov	ax, ds:[bx].GFP_disk	; the disk handle to save
		jmp	saveDisk

deleteSavedDisk:
	;
	; No disk handle in the current path(!), so delete the data for the
	; saved disk and boogie.
	; 
		mov	ax, dx		; ax <- saved-disk-handle tag
		call	ObjVarDeleteData
		jmp	done
GenPathSetObjectPath endp

if FULL_EXECUTE_IN_PLACE

GenPath	ends

ResidentXIP	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenPathSetObjectPathXIP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the path stored in the indicated vardata entry to
		match that passed.

CALLED BY:	GLOBAL and GenPathSetObjectPathXIP()
PASS:		*ds:si	= object
		es:di	= path to set (may not be in same block as object)
		(es:di *can* be pointing into any movable XIP code resource.)
		ax	= vardata type under which the path is stored
		dx	= vardata type under which the disk handle should
			  be saved for shutdown
		bp	= disk handle (or StandardPath)
RETURN:		carry set if passed path is invalid:
			ax	= error code
		ds	- pointing to the same block as the "ds" passed.
DESTROYED:	bx, cx, dx

	WARNING: This routine MAY resize LMem and/or object blocks, moving
		 then on the heap and invalidating stored segment pointers
		 to them.

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenPathSetObjectPathXIP	proc	far
		.enter
	;
	; Copy the path into the stack
	;
		push	es, di
		segxchg	ds, es
		xchg	si, di			;ds:si = path str
		clr	cx			;cx = null-terminated str
		call	SysCopyToStackDSSI	;ds:si = path str on stack
		segxchg	ds, es
		xchg	si, di			;es:di = path str on stack
	;
	; Call the real function
	;
		call	GenPathSetObjectPath

	;
	; Restore the stack
	;
		call	SysRemoveFromStack
		pop	es, di
		
	.leave
	ret
GenPathSetObjectPathXIP	endp

ResidentXIP	ends

GenPath	segment	resource

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckPathAbsolute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the passed path is absolute.

CALLED BY:	INTERNAL (GenPathSetObjectPath)
PASS:		es:di	= path to check
RETURN:		cx	= 0 if path relative, non-0 if path absolute
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/ 2/91		Initial version
	brianc	5/7/93		Copied from kernel for use in
					GenPathSetObjectPath
					(changed param from ds:dx to es:di)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckPathAbsolute proc	near
		uses	ax, si
		.enter
		mov	cx, 1
		mov	si, di
scanLoop:
SBCS <		lodsb	es:						>
DBCS <		lodsw	es:						>
		LocalIsNull ax
		jz	seenNullTerm
		LocalCmpChar ax, ':'
		je	seenColon
		LocalCmpChar ax, C_BACKSLASH
		je	seenBackslash
EC <		jcxz	malformed	; drive spec *must* be followed	>
EC <					;  by backslash (absolute) in	>
EC <					;  this system, no matter what	>
EC <					;  the path is for. If cx is 0,	>
EC <					;  we've seen the colon...	>
NEC <		jcxz	done		; malformed, but pretend it's	>
NEC <					;  relative so as to provoke	>
NEC <					;  an error from DOS when	>
NEC <					;  concatenated with cur path	>
		jmp	scanLoop
seenNullTerm:
		dec	cx		; cx <- 0 as neither drive spec nor
					;  backslash seen (or we would
					;  have been outta here long since)
EC <		ERROR_S	UI_MALFORMED_PATH ; => ended with drive spec	>
NEC <		js	malformed	;  pretend path is relative	>
NEC <					;  so we provoke DOS		>

done:
		.leave
		ret
seenColon:
		dec	cx
		jz	scanLoop	; => first colon, so ok
		; can't have more than one colon in a path, bub
malformed:
EC <		ERROR	UI_MALFORMED_PATH				>
NEC <		clr	cx	; pretend it's relative, in the hope	>
NEC <		jmp	done	;  that it's even less likely to be 	>
NEC <				;  found by DOS				>

seenBackslash:
		dec	cx	; if no colon before this, cx is 1 and path
				;  is relative...unless backslash is the first
				;  thing, of course :)
				; if colon before this, cx is 0 and decrement
				;  makes it non-zero, signalling absolute
		LocalPrevChar essi ; back up to actual backslash position
		cmp	si, di	; backslash at start?
		jne	done	; no -- leave cx as-is
		dec	cx	; yes -- cx must be 0 now, so make it -1 to
				;  signal path absolute
		jmp	done
CheckPathAbsolute endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenPathGetObjectPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the path bound to the given object under the
		given vardata tag.

CALLED BY:	GLOBAL
PASS:		*ds:si	= object
		es:di	= buffer in which to store the path. If es is 0, a
			  block will be allocated for the path and the handle
			  returned.
		cx	= number of bytes in the buffer (ignored if es is 0)
		ax	= vardata type under which the path is stored.
		dx	= vardata type under which the disk handle should
			  be saved for shutdown
RETURN:		carry set if passed buffer is too small or path is invalid:
			ax	= number of bytes required (0 => path is
				  invalid)
			cx	= disk handle for path
		carry clear if ok:
			cx	= disk handle for path
			es:di	= filled, null-terminated buffer, unless es
				  was 0
			ax	= handle of block containing the path, if
				  es was 0
DESTROYED:	dx, bx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenPathGetObjectPath proc	far
		uses	si, bp, es, di
		.enter
	;
	; Make sure the path vardata exists and its disk handle is valid.
	; 
		call	GenPathFetchDiskHandleAndDerefPath
		tst	ax
		jnz	haveDiskHandle
		stc
		jmp	done
haveDiskHandle:
	;
	; Find how long the stored path is.
	; 
		clr	bp		; flag no block allocated
		
		push	es, di, cx
		lea	di, ds:[bx].GFP_path
		segmov	es, ds
SBCS <		clr	al						>
DBCS <		clr	ax						>
		mov	cx, -1
SBCS <		repne	scasb						>
DBCS <		repne	scasw						>
		not	cx
		mov_tr	ax, cx		; ax <- path length, including null
DBCS <		shl	ax, 1		; ax <- path size, w/NULL	>
		pop	es, di, cx

	;
	; See if a buffer was passed or if we're expected to allocate one.
	; 
		mov	si, es
		tst	si
		jz	allocBlock
	;
	; Buffer given. Is it large enough?
	; 
		cmp	cx, ax
		jb	done		; no (jb taken => carry set)
		
		mov_tr	cx, ax		; cx <- count
copyPath:
	;
	; Copy the path from the vardata into the destination buffer.
	; 
		lea	si, ds:[bx].GFP_path
		rep	movsb

		tst	bp		; in a block we allocated?
		jz	done		; no => done (carry cleared by tst)

		xchg	bx, bp
		call	MemUnlock	; (carry unmolested)
		mov_tr	ax, bp		; ax <- vardata offset
		xchg	bx, ax		; ax <- block holding path,
					; bx <- vardata offset
done:
	;
	; Always return the disk handle.
	; 
		mov	cx, ds:[bx].GFP_disk
		.leave
		ret

allocBlock:
	;
	; Caller wants us to allocate a block for it.
	; 
		push	bx
		push	ax		; save actual path size
		mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK or mask HF_SHARABLE
		call	MemAlloc
		pop	cx
		pop	bp
		jc	done
	;
	; Point to the durn thing and save its handle in BP for return and
	; unlock, etc.
	; 
		mov	es, ax
		clr	di
		xchg	bp, bx		; bp <- block handle, bx <- GFP offset
		jmp	copyPath
GenPathGetObjectPath endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenPathConstructFullObjectPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Constructs a full path from the object's path stored under
		the passed vardata type. 

CALLED BY:	GLOBAL
PASS:		*ds:si - object
 		ax - vardata type under which the path is stored
 		dx - vardata type under which the disk handle is saved for
		     shutdown
		es:di - buffer in which to place constructed path
		cx - size of this buffer
		bp - non-zero to place drive specifier before the absolute
		     path that's returned.
RETURN:		carry set if whole path won't fit
		carry clear if whole path in buffer:
			es:di - points at null
			bx - disk handle for path
DESTROYED:	ax, dx, bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenPathConstructFullObjectPath	proc	far
		uses	si
		.enter
		call	GenPathFetchDiskHandleAndDerefPath
		tst	ax
		jz	fail
		lea	si, ds:[bx].GFP_path
		mov_tr	bx, ax
		mov	dx, bp		; dx <- drive specifier wanted
		call	FileConstructFullPath
done:
		.leave
		ret
fail:
		stc
		jmp	done
GenPathConstructFullObjectPath	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenPathSetCurrentPathFromObjectPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the thread's current path from the value stored in
		a GenFilePath in the object's vardata

CALLED BY:	GLOBAL
PASS:		*ds:si	= object
		ax	= vardata type under which the path is stored
		dx	= vardata type under which the disk handle is saved
RETURN:		carry set if current path couldn't be set:
			ax	= error code
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/10/92		Initial version
	pjc	5/23/95		Added multi-language support.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenPathSetCurrentPathFromObjectPath proc	far
		uses	bx, dx
		.enter
		call	GenPathFetchDiskHandleAndDerefPath
		tst	ax
		jz	fail
		lea	dx, ds:[bx].GFP_path

if MULTI_LANGUAGE
	; If we are in multi-language mode, look at the file links in
	; PRIVDATA\LANGUAGE\<Current Language>\WORLD, which have the correct
	; translated names.

		cmp	ax, SP_APPLICATION
		jne	normalStandardPath
		call	IsMultiLanguageModeOn
		jc	normalStandardPath
		call 	GeodeSetLanguageStandardPath
		clr	bx
		jmp	setPath
normalStandardPath:
endif
		mov_tr	bx, ax
setPath::
		call	FileSetCurrentPath
done:
		.leave
		ret
fail:
		mov	ax, ERROR_DISK_UNAVAILABLE
		stc
		jmp	done
GenPathSetCurrentPathFromObjectPath endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenPathUnrelocObjectPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Flag the bound GenFilePath as needing to have its disk
		handle restored when it's next referenced.

CALLED BY:	GLOBAL
PASS:		*ds:si	= object
		ax	= vardata type under which the path is stored
		dx	= vardata type under which the disk handle is saved
RETURN:		carry clear
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenPathUnrelocObjectPath proc	far
		uses	bx
		.enter
	;
	; See if the path is even defined for the object. If it's not, there's
	; no need to save anything away...it'll get initialized to its default
	; when first used.
	; 
		call	ObjVarFindData
		jnc	done
	;
	; Make sure that there is a disk handle saved
	;
		push	bx			; save path vardata offset
		xchg	ax, dx			; ax = disk handle vardata
						; dx = path vardata
		call	ObjVarFindData
		xchg	ax, dx			; ax = path vardata
						; dx = disk handle vardata
		pop	bx			; restore path vardata offset
NEC <		jnc	done			; no disk handle saved, don't >
NEC <						;	mark as invalid	      >
EC <		jc	invalidateDiskHandle				>
EC <		test	ds:[bx].GFP_disk, DISK_IS_STD_PATH_MASK		>
EC <		jnz	done			; must be standard path	>
EC <		ERROR	GEN_PATH_CANT_UNRELOCATE_DISK_HANDLE		>
EC <invalidateDiskHandle:						>
	;
	; Set disk-handle field to special value that indicates it must be
	; restored from the paired disk-handle vardata.
	;
		mov	ds:[bx].GFP_disk, GEN_PATH_DISK_HANDLE_INVALID
		clc
done:
		.leave
		ret
GenPathUnrelocObjectPath endp

GenPath	ends
