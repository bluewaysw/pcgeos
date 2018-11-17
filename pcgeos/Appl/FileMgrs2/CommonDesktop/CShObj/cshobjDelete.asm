COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		cshobjDelete.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/11/92   	Initial version.

DESCRIPTION:
	

	$Id: cshobjDelete.asm,v 1.2 98/06/03 13:45:58 joon Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ShellObjectDeleteEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	delete the current entry, putting up all kinds of
		dialog boxes, etc.

PASS:		*ds:si	= ShellObjectClass object
		ds:di	= ShellObjectClass instance data
		es	= segment of ShellObjectClass
		cx:dx	= FileOperationInfoEntry

RETURN:		carry SET to abort loop, carry clear otherwise

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/11/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ShellObjectDeleteEntry	method	dynamic	ShellObjectClass, 
					MSG_SHELL_OBJECT_DELETE_ENTRY
	.enter

	mov	ss:[howToHandleRemoteFiles], RFBT_NOT_DETERMINED
	mov	al, ds:[di].SOI_attrs

	movdw	dssi, cxdx
	call	PrepFilenameForError
	
	test	al, mask SOA_DELETABLE
	jz	notAllowed

	call	FileDeleteFileDir		; do it
	jnc	noError			; if no error, continue

	cmp	ax, YESNO_CANCEL
	je	cancel

	call	DesktopOKError
	jnc	done				; ignored error, continue

	mov	ss:[recurErrorFlag], 0		; clear flag for next file
	cmp	ax, DESK_DB_DETACH		; detaching?
	je	cancel

	; Because of file change notification, we can only grey out
	; this file if it was actually deleted.  This simplifies
	; things somewhat, since we only grey it out if there was no
	; error.


	cmp	ax, YESNO_CANCEL		; user-cancel operation
	je	cancel

	clc
	jmp	clearFlag

noError:
	mov	ax, DELETE_UPDATE_STRATEGY
	call	MarkWindowForUpdate		; update source window
	clc

clearFlag:
	mov	ss:[recurErrorFlag], 0		; clear flag for next file

done:

	.leave
	ret

cancel:
	stc
	jmp	clearFlag

		
	;
	; Deletion isn't allowed, so make sure we don't grey out the file
	;

notAllowed:
	mov	ax, ERROR_CANNOT_DELETE
	call	DesktopOKError
	clc
	jmp	clearFlag
	
ShellObjectDeleteEntry	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ShellObjectDelete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Delete a group of files

PASS:		*ds:si	= ShellObjectClass object
		ds:di	= ShellObjectClass instance data
		es	= segment of ShellObjectClass
		cx:0	- FileQuickTransferHeader

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
        chrisb	11/11/92   	Initial version.
	dloft	3/20/93		ba-specific check for student naughtiness
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ShellObjectDelete	method	dynamic	ShellObjectClass,
						MSG_SHELL_OBJECT_DELETE
	.enter
if _NEWDESKBA
	;
	; If we are a student, see if these are coming from a class folder or
	; below.  If so, bail out.
	;
		call	ShellObjectCheckStudentTransferFromClassFolder
		jnc	okay

		mov	ax, ERROR_DELETE_IN_THIS_FOLDER_NOT_ALLOWED
		call	DesktopOKError
		jmp	done
okay:
endif		; if _NEWDESKBA
	;
	; If OCDL_SINGLE, then put up a menu at the beginning to
	; verify deletion.
	;

	mov	ax, MSG_FM_START_DELETE
	call	VerifyMenuDeleteThrowAway
	jc	done

	call	ShellObjectChangeToFileQuickTransferDir
	jc	done

	call	SuspendFolders

	mov	ax, FOPT_DELETE
	call	SetFileOpProgressBox

	;
	; See how many files there are.  If there are none, then bail.
	; If there's only one, then don't bother putting up the
	; progress dialog box
	;

	mov	cx, ds:[FQTH_numFiles]
	mov	dx, offset FQTH_files
	jcxz	endDelete		
	cmp	cx, 1
	jne	deleteLoop
	mov	ss:[showDeleteProgress], FALSE

deleteLoop:
	;
	; Delete the next entry:  ds:dx - FileOperationInfoEntry
	;

	push	cx, dx		;  count, FOIE offset
	mov	cx, ds
	mov	si, dx
	mov	si, ds:[si].FOIE_info
	call	UtilGetDummyFromTable		; ^lbx:si - optr of dummy
	mov	ax, MSG_SHELL_OBJECT_DELETE_ENTRY
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	cx, dx			; count, FOIE offset
	jc	endDelete

	add	dx, size FileOperationInfoEntry
	loop	deleteLoop	

endDelete:

	call	UpdateMarkedWindows		; update source window
	call	UnsuspendFolders
done:

	.leave
	ret
ShellObjectDelete	endm


