COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	NewDesk
MODULE:		CommonND/CFolder
FILE:		cfolderDriveClass.asm

ROUTINES:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	11/92		Initial version

DESCRIPTION:
	This file contains code to handle disk copy and disk format from
	the NewDesk popup menus.

	$Id: cndfolderDriveClass.asm,v 1.5 98/08/18 16:24:13 joon Exp $

------------------------------------------------------------------------------@

NDFolderCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDDriveSetup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set our drop down menu's CopyDisk and FormatDisk menu items
		not-usable if we are not removable.  Set the drop down menu
		"Help" button's context according to the drive

CALLED BY:	MSG_ND_FOLDER_SETUP

PASS:		*ds:si - NDDriveClass object handle
		^lcx:dx - NDPrimary object therefore:
		cx     - segment of the drop down menu of the drive folder.

RETURN:		none
DESTROYED:	all but bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	11/21/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDDriveSetup	method	NDDriveClass, MSG_ND_FOLDER_SETUP
	uses	bp
	.enter

	mov	al, ds:[bx].NDDOI_driveNumber
	call	NDGetDriveTypeFromDriveNumber	

	push	ax				; save drive number

	mov	bx, cx
	mov	si, offset NDDriveWindowTemplate:NDDriveMenuHelp

	segmov	es, cs, di
	mov	di, cs:[driveHelpContextTable][bp]	; help context offset
	call	LocalStringSize
	LocalNextChar	escx

	mov	dx, size AddVarDataParams
	sub	sp, dx				; allocate this on the stack
	mov	bp, sp				; ss:bp points to stack
	mov	ss:[bp].AVDP_data.segment, es
	mov	ss:[bp].AVDP_data.offset, di
	mov	ss:[bp].AVDP_dataSize, cx
	mov	ss:[bp].AVDP_dataType, ATTR_GEN_HELP_CONTEXT
	mov	ax, MSG_META_ADD_VAR_DATA
	mov	di, mask MF_CALL or mask MF_FIXUP_DS or mask MF_STACK
	call	ObjMessage
	add	sp, size AddVarDataParams	; pop structure off stack

	pop	ax				; restore drive number
	call	DriveGetExtStatus

	test	ax, mask DES_FORMATTABLE
	jnz	done

	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	si, offset NDDriveWindowTemplate:NDDriveMenuCopyDisk
	mov	dl, VUM_NOW
	call	ObjMessageCall

	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	si, offset NDDriveWindowTemplate:NDDriveMenuFormatDisk
	mov	dl, VUM_NOW
	call	ObjMessageCall

done:
	.leave
	ret
NDDriveSetup	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDDriveBringUpDriveBox
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bring up a DiskFormat, DiskCopy or DiskRename dialog box by
		getting the drive's number then its media descriptor, setting
		the defaults of the dialog and then bringing it up.

CALLED BY:	MSG_DRIVE_FORMAT
		MSG_DRIVE_COPY,
		MSG_DRIVE_RENAME

PASS:		*ds:si - NDDriveClass object handle

RETURN:		none

DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	11/13/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDDriveBringUpDriveBox	method	NDDriveClass,	MSG_ND_DRIVE_FORMAT,
						MSG_ND_DRIVE_COPY,
						MSG_ND_DRIVE_RENAME
	.enter

	push	ax					; save message id
	mov	al, ds:[bx].NDDOI_driveNumber		; al is drive number
	call	DriveGetDefaultMedia			; ah is drive media
	mov	ss:[ndClickedOnDrive], ax		; remember drive
	mov	cx, ax					; cx is drive and media

	pop	si					; restore message id
	push	si					; save it again
	mov	ax, MSG_DISK_FORMAT_SOURCE_DRIVE
	cmp	si, MSG_ND_DRIVE_FORMAT			; format?
	je	gotMessage
	mov	ax, MSG_DISK_COPY_SOURCE_DRIVE
	cmp	si, MSG_ND_DRIVE_COPY			; copy?
	je	gotMessage
	mov	ax, MSG_DISK_RENAME_DRIVE		; ...else its rename

gotMessage:						; set UI for this drive
	mov	bx, handle 0				; send to process
	call	ObjMessageCall
	pop	ax					; restore message id
	jc	done					; if we failed to set UI
							; then don't bring it up
	;						
	; bring up box
	;
	mov	bx, handle DiskFormatBox
	mov	si, offset DiskFormatBox
	cmp	ax, MSG_ND_DRIVE_FORMAT			; format?
	je	gotDestObj
	mov	bx, handle DiskCopyBox
	mov	si, offset DiskCopyBox
	cmp	ax, MSG_ND_DRIVE_COPY			; copy?
	je	gotDestObj
	mov	bx, handle DiskRenameBox
	mov	si, offset DiskRenameBox		; else its rename

gotDestObj:
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	call	ObjMessageFixup
done:
	.leave
	ret
NDDriveBringUpDriveBox	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDDriveFolderSetPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	If this is a dummy object we want to be careful.
		Since a drive might have an unformatted disk in it, we
		don't want to try to set its GenPath (which tries to
		verify the path).  Instead we will determine the drive
		that this path corresponds to and set the special Drive
		object instance data to that drive

		If it is a real folder object (has a GenPrimary) then it
		was opened by someone double clicking on it (or some other
		way) and any errors would have been handled already, so
		set the path like normal.

PASS:		*ds:si	- FolderClass object
		ds:bx	- FolderClass instance data
		es	- dgroup
		
		cx:dx	- fptr to path
		bp	- disk handle

RETURN:		carry	- set on error
			- clear if OK

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	11/14/92	initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDDriveFolderSetPath	method dynamic NDDriveClass, MSG_FOLDER_SET_PATH
	.enter

	tst	ds:[bx].FOI_windowBlock		; are we a dummy?
	jz	setDriveNumber			; if we are, skip path setting

	push	ax, bx, cx, dx, bp, di, es
	mov	di, offset NDDriveClass
	call	ObjCallSuperNoLock		; set path like normal

	segmov	es, cs
	mov	di, offset root			; es:di is a root string
	mov	bx, ds:[si]			; dereference FolderObject
	mov	bp, ds:[bx].FOI_actualDisk	; bp is actual disk handle
	mov	ax, ATTR_FOLDER_PATH_DATA
	mov	dx, TEMP_FOLDER_SAVED_DISK_HANDLE
	call	GenPathSetObjectPath
	pop	ax, bx, cx, dx, bp, di, es

setDriveNumber:
	push	ds, si				; save object pointer
	movdw	dssi, cxdx			; ds:si is the filename
	mov	bx, bp				; bx is the diskhandle
	mov	cx, size PathName
	sub	sp, cx				; allocate stack buffer
	segmov	es, ss, di
	mov	di, sp				; es:di is the buffer
	mov	dx, sp				; non-zero to add drive name
	call	FileConstructActualPath
	jc	error

	segmov	ds, es
	mov	dx, di				; ds:dx is link target
	call	FSDLockInfoShared
	mov	es, ax
	call	DriveLocateByName
	add	sp, size PathName		; pop buffer off stack 
	mov	al, es:[si].DSE_number
	call	FSDUnlockInfoShared
	pop	ds, si				; restore object pointer

	mov	si, FOLDER_OBJECT_OFFSET
	mov	bx, ds:[si]
	mov	ds:[bx].NDDOI_driveNumber, al
	call	NDDriveSetHelpContextUtil
exit:
	.leave
	ret					; <---- EXIT HERE

error:
	add	sp, cx				; pop stack
	pop	ds, si
	stc
	jmp	exit

NDDriveFolderSetPath	endm

root	byte	'\\', 0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDDriveGetToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the token characters associated with a
		NDDriveClass.

CALLED BY:	GLOBAL

PASS:		*ds:si	- NDDriveClass object

RETURN:		ax, cx, dx TokenCharacters

DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	01/02/93	initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDDriveGetToken	method dynamic NDDriveClass, MSG_ND_FOLDER_GET_TOKEN
	uses bp
	.enter

	mov	si, ds:[si]			; dereference folder object
	mov	al, ds:[si].NDDOI_driveNumber
	call	NDGetDriveTypeFromDriveNumber
CheckHack< size GeodeToken eq 6 >
	mov	ax, bp
	shl	bp, 1				; double WDT
	add	bp, ax				; triple WDT for GeodeToken size
	movdw	cxax, cs:[driveTokenTable][bp].GT_chars
	mov	dx, cs:[driveTokenTable][bp].GT_manufID

	.leave
	ret
NDDriveGetToken	endm

driveTokenTable	label	GeodeToken
	GeodeToken <'FL52', MANUFACTURER_ID_GEOWORKS>	; WDT_FLOPPY5_25
	GeodeToken <'FL35', MANUFACTURER_ID_GEOWORKS>	; WDT_FLOPPY3_5
	GeodeToken <'HDSK', MANUFACTURER_ID_GEOWORKS>	; WDT_HARDDISK
	GeodeToken <'CDRM', MANUFACTURER_ID_GEOWORKS>	; WDT_CD_ROM
	GeodeToken <'NDSK', MANUFACTURER_ID_GEOWORKS>	; WDT_NETDISK
	GeodeToken <'RDSK', MANUFACTURER_ID_GEOWORKS>	; WDT_RAMDISK
	GeodeToken <'VDSK', MANUFACTURER_ID_GEOWORKS>	; WDT_REMOVABLE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDDriveSetHelpContext
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the help context for a NDDriveClass object

CALLED BY:	GLOBAL

PASS:		*ds:si	- NDDriveClass object
		bp	- drive number

RETURN:		none

DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/06/00	initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDDriveSetHelpContext	method dynamic	NDDriveClass,
					MSG_ND_DRIVE_SET_HELP_CONTEXT
	uses	ax
	.enter

	mov	ax, bp
	call	NDDriveSetHelpContextUtil

	.leave
	ret
NDDriveSetHelpContext	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDDriveSetHelpContextUtil
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the help context of a NDDriveObject from its drive
		number.

CALLED BY:	NDDriveFolderSetPath, NDDriveSetHelpContext

PASS:		*ds:si	- NDDriveObject
		al - drive number
RETURN:		nothing
DESTROYED:	nothing

SIDE EFFECTS:	
		ds may move (but it will be updated when returned)

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	2/10/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDDriveSetHelpContextUtil	proc	near
	uses	ax, bx, cx, bp, di, si, es
	.enter

	call	NDGetDriveTypeFromDriveNumber

	segmov	es, cs, di
	mov	di, cs:[driveHelpContextTable][bp]	; es:di is help context
	call	LocalStringSize
	LocalNextChar	escx

	mov	ax, ATTR_FOLDER_HELP_CONTEXT
	call	ObjVarAddData
	mov	ax, ds					; save new segment

	mov	si, bx					; ds:si is var data
	xchg	di, si
	segxchg	ds, es					; swap es:di with ds:si
	rep	movsb

	mov	ds, ax					; restore segment

	.leave
	ret
NDDriveSetHelpContextUtil	endp

driveHelpContextTable	label	word
	word	offset FloppyDriveHelpContext	; WDT_FLOPPY5_25
	word	offset FloppyDriveHelpContext	; WDT_FLOPPY3_5
	word	offset HardDriveHelpContext	; WDT_HARDDISK
	word	offset CDROMDriveHelpContext	; WDT_CD_ROM
	word	offset NetDriveHelpContext	; WDT_NETDISK
	word	offset RamDriveHelpContext	; WDT_RAMDISK
	word	offset FloppyDriveHelpContext	; WDT_REMOVABLE

FloppyDriveHelpContext	char "oFloppy", 0
HardDriveHelpContext	char "oFixed", 0
CDROMDriveHelpContext	char "oCD", 0
NetDriveHelpContext	char "oFixed", 0
RamDriveHelpContext	char "oRAM", 0



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDGetDriveTypeFromDriveNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the NewDeskDriveType from a drive number.  This
		WDT is the index, which is used for tables of drive info

CALLED BY:	NDCreateDriveLinks, NDDriveSetHelpContextUtil

PASS:		al	- drive number

RETURN:		bp - NewDeskDriveType

DESTROYED:	ah

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/09/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDGetDriveTypeFromDriveNumber	proc	far
	.enter

	call	DriveGetStatus
	andnf	ah, mask DS_TYPE or mask DS_NETWORK or mask DS_MEDIA_REMOVABLE
	mov	bp, WDT_REMOVABLE
	cmp	ah, DRIVE_FIXED shl offset DS_TYPE or mask DS_MEDIA_REMOVABLE
	je	gotType
	andnf	ah, mask DS_TYPE or mask DS_NETWORK
	mov	bp, WDT_FLOPPY5_25
	cmp	ah, DRIVE_5_25 shl offset DS_TYPE	; 5.25 floppy?
	je	gotType
	mov	bp, WDT_FLOPPY3_5
	cmp	ah, DRIVE_3_5 shl offset DS_TYPE	; 3.5 floppy?
	je	gotType
	mov	bp, WDT_HARDDISK
	cmp	ah, DRIVE_FIXED shl offset DS_TYPE
	je	gotType
	mov	bp, WDT_CD_ROM
	cmp	ah, DRIVE_CD_ROM shl offset DS_TYPE
	je	gotType
	mov	bp, WDT_NETDISK
	cmp	ah, DRIVE_FIXED shl offset DS_TYPE or mask DS_NETWORK
	je	gotType
	mov	bp, WDT_RAMDISK
	cmp	ah, DRIVE_RAM shl offset DS_TYPE
	je	gotType
	mov	bp, WDT_NETDISK				; unknown - use netdisk
gotType:
	.leave
	ret
NDGetDriveTypeFromDriveNumber	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDDriveCheckDriveNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if the passed in drive number is the same as
		that stored in its instance data.

CALLED BY:	MSG_ND_DRIVE_CHECK_DRIVE_NUMBER

PASS:		*ds:si	= NDDriveClass object
		ds:di	= NDDriveClass instance data
		bp	= drive number to check against

RETURN:		carry	set if the passed in drive is the drive in instance data
			clear if they are different
DESTROYED:	none

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	3/14/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDDriveCheckDriveNumber	method dynamic NDDriveClass, 
					MSG_ND_DRIVE_CHECK_DRIVE_NUMBER
	uses	ax
	.enter

	mov	ax, bp
	cmp	al, ds:[di].NDDOI_driveNumber
	clc
	jne	done

	stc
done:
	.leave
	ret
NDDriveCheckDriveNumber	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        NDDShellObjectCopyEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:    Copies the drive link, then changes the WOT of the new link
        to be a standard link rather than a drive object. This allows
        having links to drives on the desktop, without requiring
        the ability to move/delete drive objects.

CALLED BY:    MSG_SHELL_OBJECT_COPY_ENTRY

PASS:        *ds:si    = NDDriveClass object
        ds:di    = NDDriveClass instance data
        ds:bx    = NDDriveClass object (same as *ds:si)
        es     = segment of NDDriveClass
        ax    = message #
RETURN:        
DESTROYED:    
SIDE EFFECTS:    

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
    Name    Date        Description
    ----    ----        -----------
    ed    4/10/02       Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDDShellObjectCopyEntry    method dynamic NDDriveClass, 
                    MSG_SHELL_OBJECT_COPY_ENTRY
    .enter

    .assert ((offset FOIE_name) eq 0)

    push    cx, dx
    mov    di, offset NDDriveClass
    call    ObjCallSuperNoLock
    ; Was passed in cx:dx, but we need filename pointer in ds:dx
    pop    ds, dx

    segmov    es, cs, ax
    mov    di, offset copiedFolderWOT
    mov    ax, FEA_DESKTOP_INFO
    mov    cx, size NewDeskObjectType
    call    FileSetPathExtAttributes
    .leave
    ret
NDDShellObjectCopyEntry    endm

copiedFolderWOT    NewDeskObjectType    WOT_FOLDER

NDFolderCode	ends
