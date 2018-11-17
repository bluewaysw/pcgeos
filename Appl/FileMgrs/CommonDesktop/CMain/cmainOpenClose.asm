COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		cmainOpenClose.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	7/15/92   	Initial version.

DESCRIPTION:
	Routines to handle the opening/closing of windows

	$Id: cmainOpenClose.asm,v 1.2 98/06/03 13:44:29 joon Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	
UtilCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DesktopFolderClosing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	handle notification that a window has closed

PASS:		*ds:si	= DesktopClass object
		ds:di	= DesktopClass instance data
		es	= segment of DesktopClass
		^lcx:dx = OD of folder object

RETURN:		

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	7/13/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DesktopFolderClosing	method	dynamic	DesktopClass, 
					MSG_DESKTOP_FOLDER_CLOSING
		.enter
	
	;
	; remove folder object from global folder object list
	;
		clr	di

startLoop:
						; check if this is its entry
		cmp	cx, ss:[folderTrackingTable][di].FTE_folder.handle
		je	foundIt
		add	di, size FolderTrackingEntry	; move to next entry
		cmp	di, MAX_NUM_FOLDER_WINDOWS * (size FolderTrackingEntry)
		je	notThere
		jmp	startLoop

foundIt:
		clr	ss:[folderTrackingTable][di].FTE_folder.handle	
		dec	ss:[numFolderWindows]		; open window count
	
notThere:

	;
	; Pass a MSG_NOTIFY_FILE_CHANGE to all folders with the File
	; ID of this folder.
	;
		movdw	bxsi, cxdx
		mov	ax, MSG_FOLDER_GET_FILE_ID
		mov	di, mask MF_CALL
		call	ObjMessage

		pushdw	cxdx

		mov	ax, size FileChangeNotificationData
		mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK or mask HF_SHARABLE
		call	MemAlloc
		mov	ds, ax

		popdw	ds:[FCND_id]
		mov	ds:[FCND_disk], bp
		call	MemUnlock

		mov	ax, 1
		call	MemInitRefCount

		mov	bp, bx
		mov	dx, FCNT_CLOSE
		mov	ax, MSG_NOTIFY_FILE_CHANGE
		mov	di, mask MF_RECORD
		call	ObjMessage
		mov	cx, di		; event to send

		mov	dx, bp		; extra data block
		mov	bx, MANUFACTURER_ID_GEOWORKS
		mov	ax, GCNSLT_FILE_SYSTEM
		clr	bp
		call	GCNListSend

		.leave
		ret
DesktopFolderClosing	endm


if _NEWDESKBA


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DesktopConfirmLogout
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Confirm before logout.

CALLED BY:	MSG_DESKTOP_CONFIRM_LOGOUT
PASS:		*ds:si	= DesktopClass object
		ds:di	= DesktopClass instance data
		ds:bx	= DesktopClass object (same as *ds:si)
		es 	= segment of DesktopClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	7/ 6/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DesktopConfirmLogout	method dynamic DesktopClass, 
					MSG_DESKTOP_CONFIRM_LOGOUT
	call	NDSpecialAbortSpooler
	jc	done

	call	IclasQueryForLogout
	cmp	ax, IC_YES
	jne	done

	mov	ss:[loggingOut], TRUE
	mov	ax, MSG_EMPTY_WASTEBASKET
	mov	bx, handle 0			; send to process
	call	ObjMessageCall

	mov	ax, MSG_APP_LOGOUT
	GOTO	UserCallApplication
done:
	ret
DesktopConfirmLogout	endm



COMMENT @----------------------------------------------------------------------

FUNCTION:	NDSpecialAbortSpooler

DESCRIPTION:	In Wizard we want to bail out specially

CALLED BY:	INTERNAL

PASS:
	none

RETURN:
	carry - set to abort logout

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/31/93		Initial version

------------------------------------------------------------------------------@
NDSpecialAbortSpooler	proc	near

	; first see if anything is printing

	mov	cx, SIT_QUEUE_INFO
	mov	dx, -1
	call	SpoolInfo
	cmp	ax, SPOOL_QUEUE_EMPTY
	clc
	jz	done

	; something is printing, put up our dialog box

	clr	ax
	pushdw	axax			;help context
	pushdw	axax			;custom triggers
	pushdw	axax			;arg 2
	pushdw	axax			;arg 1
	mov	cx, handle CannotQuitWhilePrintingString
	mov	dx, offset CannotQuitWhilePrintingString
	pushdw	cxdx			;string
	mov	ax, CustomDialogBoxFlags <1, CDT_ERROR, GIT_NOTIFICATION,0>
	push	ax			;flags
	call	UserStandardDialogOptr
	stc
done:
	ret
NDSpecialAbortSpooler	endp

endif	; if _NEWDESKBA


if _NEWDESKBA


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DesktopChangePassword
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calls the Change Password application.

CALLED BY:	MSG_DESKTOP_CHANGE_PASSWORD
PASS:		nothing

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	11/16/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DesktopChangePassword	method dynamic DesktopClass, 
					MSG_DESKTOP_CHANGE_PASSWORD
	uses	ax, cx, dx, bp
	.enter
	mov	ah, 0
        mov     cx, MSG_GEN_PROCESS_OPEN_APPLICATION
        clr     dx                      ;no AppLaunchBlock
        segmov  ds, cs
        mov     si, offset ChangePasswordAppName
        mov     bx, SP_SYS_APPLICATION
        call    UserLoadApplication
	jnc	exit
	mov	ax, ERROR_UNABLE_TO_CHANGE_PASSWORD
	call	DesktopOKError	
exit:
	.leave
	ret
DesktopChangePassword	endm
EC 	< ChangePasswordAppName	char	"EC Change Password", 0 >
NEC 	< ChangePasswordAppName	char	"changepw.geo", 0 >

endif		; if _NEWDESKBA

UtilCode	ends
