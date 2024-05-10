COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonUI/COpen
FILE:		copenFileSelectorMiddle.asm

ROUTINES:
	Name			Description
	----			-----------
    INT OLFSMarkDirtyAndRescanIfRealized
				React to a change in some attribute of the
				file selector by marking it dirty and
				rescanning the thing if it's currently
				visible.

    INT OLFSCheckIfRealized     See if the passed GenFileSelector is
				on-screen

    INT OLFSBuildChangeDrivePopup
				build list of volumes for Change Drive
				popup list

    INT OLFSCreateAndInitGenItem
				Create and initialize a GenItem.

    INT OLFSReadList            build list of volumes or list of
				files/directories

    MTD MSG_GEN_FILE_SELECTOR_GET_FILTER_ROUTINE
				Default handler to deal with goofballs that
				set FSFC_FILTER_FILE but don't intercept
				this message....

    MTD MSG_GEN_FILE_SELECTOR_GET_RESCAN_ROUTINE
				Default handler to deal with goofballs
				that set FSFC_USE_FAKE_FILE_SYSTEM but
				don't intercept this message...

    INT OLFSBuildFileList       read directory and build list of files and
				directories

    INT ExpandListToHoldSections
				Expands file list to leave room for section
				"directories".

    INT SetSectionHeaderListItem
				Creates a fake directory entry for a
				section header.

    INT OLFSFileEnumCallback    Check the suitability of a file for
				inclusion in a file selector.

    INT OLFSCompareFiles        Compare two entries for sorting the
				displayed files

    INT OLFSCompareFilesAlphabetically
				If HINT_FILE_SELECTOR_ALWAYS_SORT_
				ALPHABETICALLY, then this routine is
				used to compare entries for sorting
				the displayed files.

    INT OLFSSortList            sorts file or volume list (usually
				alphabetically)

    INT OLFSShowCurrentDir      Create and initialize children for the
				Change Directory Popup, setting the
				children's monikers, etc.

    INT OLFSCreateCurDirItem    Create a child of the
				OLFileSelectorChangeDirectoryPopup, unless
				a child already exists that can be reused.

    INT OLFSSelectGenItem       Create a child of the
				OLFileSelectorChangeDirectoryPopup, unless
				a child already exists that can be reused.

    INT OLFSDestroyListChildren clobber all children

    MTD MSG_OL_FILE_SELECTOR_ITEM_QUERY
				dynamic list wants a moniker

    MTD MSG_OL_FILE_SELECTOR_ITEM_QUERY
				Table object wants to draw its entry. So
				tell it what to draw

    INT GetSectionAndItem       Returns current item and the section it's
				in.

    MTD MSG_OL_FILE_SELECTOR_CHANGE_DRIVE_POPUP
				switch to root directory of specified drive

    MTD MSG_OL_FILE_SELECTOR_CHANGE_DIRECTORY_POPUP
				switch to choosen directory in change
				directory popup

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/10/94	Broken out of copenFileSelector.asm

DESCRIPTION:

	$Id: copenFileSelectorMiddle.asm,v 1.2 98/02/09 21:07:59 gene Exp $

-------------------------------------------------------------------------------@
FileSelector	segment resource



COMMENT @----------------------------------------------------------------------

METHOD:		OLFileSelectorSetSelection --
			MSG_GEN_FILE_SELECTOR_SET_SELECTION
		for OLFileSelectorClass

DESCRIPTION:	Set the current selection for a file selector.

PASS:
	*ds:si - instance data
	es - segment of OLFileSelectorClass

	ax - MSG_GEN_FILE_SELECTOR_SET_SELECTION

	cx:dx - new selection (null-terminated)
		XIP: new selection must not be in a movable code resource
RETURN:
	cx - ?
	dx - ?
	bp - ?
	carry - clear if selection passed and found (or if suspended)
		set otherwise
	ax - ?

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/90		Initial version
	brianc	4/91		Completed 2.0 revisions

------------------------------------------------------------------------------@

OLFileSelectorSetSelection	method	OLFileSelectorClass, \
					MSG_GEN_FILE_SELECTOR_SET_SELECTION

FXIP <	push	bx, si							>
FXIP <	mov	bx, cx							>
FXIP <	mov	si, dx							>
FXIP <	call	ECAssertValidFarPointerXIP				>
FXIP <	pop	bx, si							>

	call	OLFSCheckIfRealized		; vis built yet?
	jc	scanNow				; yes, use new selection
	stc					; indicate selection not found
	jmp	short done

scanNow:
	mov	bx, si				; *ds:bx = file selector
	call	OLFSDeref_SI_Gen_DI		; ds:di = generic instance
	mov	si, ds:[si]
	add	si, ds:[si].Vis_offset		; ds:si = spec instance

	;
	; if suspended, don't update selection - will be updated on the
	; suggested MSG_GEN_FILE_SELECTOR_RESCAN when unsuspended
	;
	test	ds:[si].OLFSI_state, mask OLFSS_SUSPENDED
	jnz	setRescanNeeded

	call	OLFSResolveSelection		; dx = entry #
	jnc	selectionOK			; selection found
	mov	si, bx				; *ds:si = file selector
	call	OLFSFindTempData		; ds:bx = GFS temp data
	mov	cx, ds:[bx].GFSTDE_selectionFlags ; cx = selection flags of
						  ;	previous selection
	mov	ax, ds:[bx].GFSTDE_selectionNumber ; ax = # of prev. sel.
	call	OLFSCopySelection		; restore previous selection
						;	in gen instance data
	stc					; indicate selection not found
	jmp	short done

selectionOK:
	push	bx				; save file selector chunk
	push	dx				; save entry #
	mov	bx, ds:[si].OLFSI_uiBlock	; bx:si - GenItemGroup
	mov	si, offset OLFileSelectorFileList
	mov	cx, dx				; cx = entry #
if _FILE_TABLE
	call	OLFSSetFileTableSelection
else
	call	OLFSSetGenItemSelection
endif ; not _FILE_TABLE

	pop	bp				; bp = entry #
	pop	si				; *ds:si = file selector
	call	OLFSBuildEntryFlagsAndSendAD
if not SINGLE_DRIVE_DOCUMENT_DIR and FSEL_HAS_CHANGE_DIRECTORY_POPUP
	call	OLFSShowCurrentDir		; update to reflect new
						;	selection
endif
	clc					; indicate selection found
done:
	ret

setRescanNeeded:
	ornf	ds:[si].OLFSI_state, mask OLFSS_RESCAN_NEEDED	; clears carry
	jmp	done

OLFileSelectorSetSelection	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFSMarkDirtyAndRescanIfRealized
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	React to a change in some attribute of the file selector
		by marking it dirty and rescanning the thing if it's
		currently visible.

CALLED BY:	OLFileSelectorSetSomething
PASS:		*ds:si	= GenFileSelector object
RETURN:		carry set if scanned
DESTROYED:

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	?/?/?		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLFSMarkDirtyAndRescanIfRealized	proc	near
	class	OLFileSelectorClass
	call	ObjMarkDirty

	call	OLFSCheckIfRealized		; vis built yet?
	jnc	done				; no, don't rescan (C clear)

	;
	; if suspended, don't rescan
	;
	push	si
	mov	si, ds:[si]
	add	si, ds:[si].Vis_offset
	test	ds:[si].OLFSI_state, mask OLFSS_SUSPENDED
	jnz	setRescan
	pop	si

	mov	ax, MSG_GEN_FILE_SELECTOR_RESCAN		; use new attrs
	call	ObjCallInstanceNoLock
	stc					; scanned
done:
	ret
setRescan:
	ornf	ds:[si].OLFSI_state, mask OLFSS_RESCAN_NEEDED
	pop	si
	clc					; not scanned
	jmp	done
OLFSMarkDirtyAndRescanIfRealized	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFSCheckIfRealized
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the passed GenFileSelector is on-screen

CALLED BY:	INTERNAL
PASS:		*ds:si	= OLFileSelector
RETURN:		carry set if selector is on-screen
		carry clear if selector is not on-screen
DESTROYED:

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	?/?/?		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLFSCheckIfRealized	proc	near
	class	VisClass
	push	si
	mov	si, ds:[si]
	add	si, ds:[si].Vis_offset
	test	ds:[si].VI_attrs, mask VA_REALIZED	; realized?
	pop	si
	jz	done			;no, carry cleared by test
	stc				;yes, set carry
done:
	ret
OLFSCheckIfRealized	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFSBuildChangeDrivePopup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	build list of volumes for Change Drive popup list

CALLED BY:	INTERNAL
			OLFileSelectorVisOpen

PASS:		*ds:si - instance of OLFileSelector

RETURN:

DESTROYED:	ax, bx, cx, dx, di, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Optimize list handling by reusing existing list items and
		destroying surfeit or creating shortage.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if not SINGLE_DRIVE_DOCUMENT_DIR and FSEL_HAS_CHANGE_DRIVE_POPUP

OLFSBuildChangeDrivePopup	proc	far
	uses	si, es
	.enter
	;
	; don't bother if no change drive list
	;
	call	OLFSDeref_SI_Gen_DI
	test	ds:[di].GFSI_attrs, mask FSA_HAS_CHANGE_DRIVE_LIST
	LONG jz	done
	;
	; first, empty the current drive list
	;	*ds:si = OLFileSelector
	;
	call	OLFSDeref_SI_Spec_DI
	mov	bx, ds:[di].OLFSI_uiBlock
	tst	bx
	; I'm not sure what this is supposed to accomplish, bx == null
	; causes a crash down the line
	;jz	afterChange
	LONG jz	done
	push	si
	mov	si, offset OLFileSelectorChangeDrivePopup
	clr	cx				; destroy all kids
	call	OLFSDestroyListChildren		; (preserves bp)
	pop	si
afterChange::
	;
	; now for each desired drive, create an item in popup list
	;	*ds:si = OLFileSelector
	;	bx = popup list block
	;
	call	OLFSDeref_SI_Gen_DI		; ds:di = generic instance
	mov	bp, ds:[di].GFSI_attrs		; bp <= FileSelectorAttrs
	clr	dh
	test	ds:[di].GFSI_attrs, mask FSA_SHOW_FIXED_DISKS_ONLY
	jz	driveLoopEntry
	mov	dh, mask DS_MEDIA_REMOVABLE
driveLoopEntry:
	mov	cx, DRIVE_MAX_DRIVES
	clr	al

if HAVE_FAKE_FILE_SYSTEM
	test	ds:[di].GFSI_fileCriteria, mask FSFC_USE_FAKE_FILE_SYSTEM
	jnz	getFakeVolumeName
endif
driveLoop:


	test	bp, mask FSA_SHOW_WRITABLE_DISKS_ONLY
	jz	getStatus

	mov_tr	dl, al
	call	DriveGetExtStatus
	mov_tr	al, dl
	jc	driveLoopNext

	test	ax, mask DES_READ_ONLY
	jnz	driveLoopNext

getStatus:

	call	DriveGetStatus			; is drive present?
	jc	driveLoopNext			; no, skip it
	test	ah, dh				; media removable and we care?
	jnz	driveLoopNext			; yes to both, so skip
	;
	; found an interesting drive, create an item for it in the popup list
	;	bx = popup list block
	;	al = drive #
	;	ah = DriveStatus
	;	cx = drive counter
	;	dh = DriveStatus flags
	;
	push	dx				; save DriveStatus flags
	push	cx				; save drive counter
	push	ax				; save drive #, DriveStatus

	mov	cx, ax				; cl = drive #, ch = DriveStatus
						; (use as idenitifer)
						; ^lbx:si = popup list
	mov	si, offset OLFileSelectorChangeDrivePopup
	call	OLFSCreateAndInitGenItem	; ^lbx:si = new GenItem
	;
	; use volume name as identifier
	;	^lbx:si = new GenItem
	;	al = drive #
	;	ah = DriveStatus
	;
	mov	cx, FILE_LONGNAME_BUFFER_SIZE
	sub	sp, cx
	segmov	es, ss
	mov	dx, mask SDAVNF_VOLUME_ONLY_FOR_FIXED

	mov	di, sp				; es:di = name buffer
	call	OLFSStuffDriveAndVolumeName
	;
	; set drive name as moniker of new GenItem
	;	^lbx:si = new GenItem
	;	ss:sp = drive name buffer (null-terminated)
	;
	mov	cx, ss				; ^lcx:dx = drive name
	mov	dx, sp
	call	OLFSReplaceVisMonikerText
	add	sp, FILE_LONGNAME_BUFFER_SIZE	; free stack buffer

	pop	ax				; restore drive #, DriveStatus
	pop	cx				; restore drive counter
	pop	dx				; restore DriveStatus flags
driveLoopNext:
	inc	al				; advance to next drive
	loop	driveLoop

done:
	.leave
	;
	; select current drive in change drive popup list
	;	*ds:si = OLFileSelector
	;
	call	OLFSSelectCurrentDriveInChangeDrivePopup
	ret
if HAVE_FAKE_FILE_SYSTEM
getFakeVolumeName:
	inc	ax				; 0 is current drv, 1
						; is 1st, etc
	clr	ah
	mov	bp, si				; preserve obj lmem chunk
	push	ax
	mov	ax, MSG_GEN_FILE_SELECTOR_FAKE_ASSERT_HAVE_VOLUME_DATA
	call	ObjCallInstanceNoLock
	tst	ax
	pop	ax
	jnz	done

fakeLoop:
	push	dx				; save DriveStatus flags
	push	cx				; save drive counter
	push	ax				; save drive #, DriveStatus
	push	si

	mov	cx, ax				; cl = drive #, ch = DriveStatus
						; (use as idenitifer)


	sub	sp, FILE_LONGNAME_BUFFER_SIZE
	segmov	es, ss

	mov	ax, MSG_GEN_FILE_SELECTOR_FAKE_VOLUME_NAME_GET
	mov	dx, ss
	mov	bp, sp
	call	ObjCallInstanceNoLock
	tst	ax
	jnz	failCase

						; ^lbx:si = popup list
	mov	si, offset OLFileSelectorChangeDrivePopup
	call	OLFSCreateAndInitGenItem	; ^lbx:si = new GenItem
	;
	; use volume name as identifier
	;	^lbx:si = new GenItem
	;	al = drive #
	;	ah = DriveStatus
	;

	;
	; set drive name as moniker of new GenItem
	;	^lbx:si = new GenItem
	;	ss:sp = drive name buffer (null-terminated)
	;
	mov	cx, ss				; ^lcx:dx = drive name
	mov	dx, sp
	call	OLFSReplaceVisMonikerText
failCase:
	add	sp, FILE_LONGNAME_BUFFER_SIZE	; free stack buffer

	pop	si
	pop	ax				; restore drive #, DriveStatus
	pop	cx				; restore drive counter
	pop	dx				; restore DriveStatus flags
	inc	al				; advance to next drive
	loop	fakeLoop
	jmp	done
endif
OLFSBuildChangeDrivePopup	endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFSCreateAndInitGenItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create and initialize a GenItem.

CALLED BY:	INTERNAL
			OLFSBuildChangeDrivePopup
			OLFSShowCurrentDir

PASS:		^lbx:si - parent popup list
		cx - identifier for new GenItem
		ds - fixupable block

RETURN:		^lbx:si - new GenItem

DESTROYED:	di, though for a long time this said nothing..  since
			things worked before, I guess I'll just fix
			the header.

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if not SINGLE_DRIVE_DOCUMENT_DIR and (FSEL_HAS_CHANGE_DRIVE_POPUP or FSEL_HAS_CHANGE_DIRECTORY_POPUP)

OLFSCreateAndInitGenItem	proc	near
	uses	ax, cx, dx, bp, es
	.enter
	push	si				; save popup list chunk
	mov	di, segment GenItemClass
	mov	es, di
	mov	di, offset GenItemClass
	call	GenInstantiateIgnoreDirty	; ^lbx:si = new GenItem
	mov	ax, MSG_GEN_ITEM_SET_IDENTIFIER
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	mov	cx, bx				; ^lcx:dx = new GenItem
	mov	dx, si
	pop	si				; ^lbx:si = popup list
	mov	ax, MSG_GEN_ADD_CHILD
	mov	bp, CCO_LAST			; add at end of list, not dirty
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			; (preserves cx, dx)
	mov	si, dx				; ^lbx:si = new GenItem
	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	.leave
	ret
OLFSCreateAndInitGenItem	endp

endif

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFSReadList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	build list of volumes or list of files/directories

CALLED BY:	INTERNAL
			OLRescanLow

PASS:		*ds:si - instance of OLFileSelector

RETURN:

DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	01/02/90	Initial version
	brianc	4/91		Completed 2.0 revisions

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLFSReadList	proc	far
	uses	si, es, di, bp
	class	OLFileSelectorClass
	.enter
	call	OLFSDeref_SI_Spec_DI		; ds:di = specific instance
	call	OLFSBuildFileList		; else, build file/dir list
	jnc	done				; no error, done
						; else, set error flag
	call	OLFSDeref_SI_Spec_DI		; ds:di = specific instance
	ornf	ds:[di].OLFSI_state, mask OLFSS_RESCAN_ERROR or \
					mask OLFSS_VIS_OPEN_ERROR
done:
	.leave
	ret
OLFSReadList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFileSelectorGetFilterRoutine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Default handler to deal with goofballs that set FSFC_FILTER_FILE
		but don't intercept this message....

CALLED BY:	MSG_GEN_FILE_SELECTOR_GET_FILTER_ROUTINE
PASS:		*ds:si	= object
RETURN:		ax:cx	= filter routine (ax = 0 => none)
		bp:dx	= extra attributes (bp = 0 => none)
DESTROYED:	none

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLFileSelectorGetFilterRoutine		method dynamic OLFileSelectorClass, MSG_GEN_FILE_SELECTOR_GET_FILTER_ROUTINE
		.enter
	;
	; Check to see if they put one in vardata...
	;
		mov	ax, ATTR_GEN_FILE_SELECTOR_FILE_ENUM_FILTER
		call	ObjVarFindData
		jnc	noVardata

		mov	cx, ds:[bx].segment
		mov	ax, ds:[bx].offset
		clr	bp
		jmp	done
noVardata:
	;
	; Neither a borrower nor a lender be...
	;
		clr	ax, cx, bp
done:
		.leave
		ret
OLFileSelectorGetFilterRoutine		endm

if HAVE_FAKE_FILE_SYSTEM

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFileSelectorGetFileEnumRoutine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Default handler to deal with goofballs that set
		FSFC_USE_FAKE_FILE_SYSTEM but don't intercept this
		message....

CALLED BY:	MSG_GEN_FILE_SELECTOR_GET_FILE_ENUM_ROUTINE
PASS:		*ds:si	= object
RETURN:		cx:ax	= FileEnum-like routine (cx = 0 => none)
DESTROYED:	none

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	robertg	5/15/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLFileSelectorGetFileEnumRoutine	method dynamic OLFileSelectorClass, MSG_GEN_FILE_SELECTOR_GET_FILE_ENUM_ROUTINE
		.enter
	;
	; Neither a borrower nor a lender be...
	;
		clr	cx
		.leave
		ret
OLFileSelectorGetFileEnumRoutine	endm
endif	;HAVE_FAKE_FILE_SYSTEM


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFSBuildFileList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	read directory and build list of files and directories

CALLED BY:	INTERNAL
			OLFSReadList

PASS:		*ds:si - instance of OLFileSelector

RETURN:		carry clear if no error
		carry set otherwise

DESTROYED:	bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:
	Attribute			Use
	====================================================================
	TOKEN_MATCH			ma.FEA_TOKEN (ptr to value)
	CREATOR_MATCH			ma.FEA_CREATOR (ptr to value)
	FILE_ATTR			ma.FEA_FILE_ATTR (bits in value halves)
	GEODE_ATTR			ma.FEA_GEODE_ATTR (bits in value halves)
	NAME_MASK			cbData1
	FILTER_ATTRS			cba (with FEA_NAME added, if NAME_MASK
					present)
	FSFC_DIRS			FESF_DIRS
	FSFC_NON_GEOS_FILES		FESF_NON_GEOS_FILES
	FSFC_GEOS_EXECUTABLES		FESF_GEOS_EXECUTABLES
	FSFC_GEOS_NON_EXECUTABLES	FESF_GEOS_NON_EXECUTABLES
	FSFC_FILE_FILTER		determines whether callback sends
					MSG_GEN_FILE_SELECTOR_FILTER_FILE
					to itself
	FSFC_TOKEN_NO_ID		reduces size for FEA_TOKEN and
					FEA_CREATOR to size GT_chars
	FSFC_USE_MASK_FOR_DIRS		determines whether callback wildcards
					directories, too
	FSFC_MASK_CASE_INSENSITIVE	determines cbData2 when calling
					FileEnum*Wildcard

	This all means:
		- at most 5 entries in matchAttrs array
		- returnAttrs are constant (for OLFileSelectorEntry)
		- callbackAttrs may need to have an attribute added to them
		  if they're given.
		- cbData1 is name mask, or 0:0
		- cbData2 is the object

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	01/29/90	Initial version
	brianc	4/91		Completed 2.0 revisions
	ardeb	12/91		Changed for new FileEnum interface

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
olfsReturnAttrs	FileExtAttrDesc	\
	<FEA_FILE_ATTR, offset OLFSE_fileAttrs, size OLFSE_fileAttrs>,
	<FEA_FLAGS, 	offset OLFSE_fileFlags, size OLFSE_fileFlags>,
	<FEA_NAME,	offset OLFSE_name, size OLFSE_name>,
	<FEA_FILE_ID,	offset OLFSE_id, size OLFSE_id>,
	<FEA_DISK,	offset OLFSE_disk, size OLFSE_disk>

if	SORT_FILE_SELECTOR_ENTRIES_BY_CREATION_DATE
if	SORT_FILE_SELECTOR_ENTRIES_BY_MODIFICATION_DATE
	ErrMessage <Cannot sort by both creation date and modification date>
endif

FileExtAttrDesc	<FEA_CREATION, offset OLFSE_fileDate, size OLFSE_fileDate>

elif SORT_FILE_SELECTOR_ENTRIES_BY_MODIFICATION_DATE

FileExtAttrDesc	<FEA_MODIFICATION, offset OLFSE_fileDate, size OLFSE_fileDate>

endif

if _ISUI or _MOTIF
;; Most of the "big app" file selectors need this, since Impex has been
;; merged with the docctrl, so we just grab them here for convenience.
FileExtAttrDesc <FEA_DOS_NAME, offset OLFSE_dosName, size OLFSE_dosName>
FileExtAttrDesc <FEA_FILE_TYPE, offset OLFSE_fileType, size OLFSE_fileType>
FileExtAttrDesc <FEA_TOKEN, offset OLFSE_token, size OLFSE_token>
endif

if _DUI
FileExtAttrDesc <FEA_FILE_TYPE, offset OLFSE_fileType, size OLFSE_fileType>
FileExtAttrDesc <FEA_MODIFICATION, offset OLFSE_modification, size OLFSE_modification>
endif

FileExtAttrDesc	<FEA_END_OF_LIST>

SIZE_OF_RETURN_ATTRS_TO_COPY =	$-olfsReturnAttrs

OLFSEnumParams	struct
    OLFSEP_common	FileEnumParams
    OLFSEP_filter	vfptr.far		; locked filter routine
    OLFSEP_rawFilterSeg	sptr.far		; segment of same, as returned
						;  from message
    OLFSEP_rawCBAttrsSeg sptr			; segment of extra callback
						;  attributes, as returned from
						;  message
    OLFSEP_matchAttrs	FileExtAttrDesc	5 dup(<>)	; need at most 6 of
							; these beasties (see
							; header, above)
    OLFSEP_filesDisabled byte			; non-zero if files are to be
						;  shown disabled
    OLFSEP_fileAttrsMismatch FileAttrs
	; This data is also stored here so that, in the callback
	; routine, we don't show files that have the GFHF_HIDDEN flag
	; set.  We can't just have FileEnum do this for us, since it
	; will automatically disqualify any files that don't have such
	; an attribute (ie, all DOS files).

    OLFSEP_fileHeaderFlags GenFileSelectorFileHeaderFlags
	; GeosFileHeaderFlags to match or mismatch

	even

OLFSEnumParams	ends

OLFSBuildFileList	proc	near
	class	OLFileSelectorClass
	uses	si
	.enter

	;
	; Start by ensuring that the drive we are about to read contains a
	; disk, and if it does that it is the disk that we think is there.
	; If it contains no disk, return carry set.  If it contains a
	; different disk than what we think is there, use the root directory
	; of the new disk.
	;
	clr	cx				; no buffer, please
	mov	ax, ATTR_GEN_PATH_DATA
	mov	dx, TEMP_GEN_PATH_SAVED_DISK_HANDLE
	call	GenPathGetObjectPath		; cx = disk handle
	jnc	havePath
	tst	ax				; path invalid?
	stc					; assume so
	LONG jz	done				; exit with error
havePath:
	mov	bx, cx				; bx = disk handle
	call	DiskGetDrive			; al = drive number
	call	DiskRegisterDiskSilently	; bx = disk handle or error
						;	(should give real disk
						;	 handle)
	LONG jc	done				; error, exit
	test	cx, DISK_IS_STD_PATH_MASK	; is saved disk StandardPath?
	jz	compareRealDiskHandles		; no, compare real disk handles
	mov	ax, SGIT_SYSTEM_DISK
	call	SysGetInfo			; ax = system disk
	mov	cx, ax				; cx = real disk handle
compareRealDiskHandles:
	cmp	cx, bx				; same disk?
	je	continueOnOurMerryWay		; yes
	; different disk, stuff in root directory
	;	bx = disk handle
	push	es
	mov	bp, bx				; bp = disk handle

	segmov	es, cs				; es:di = root path
	mov	di, offset rootPath

FXIP <	push	cx							>
FXIP <	clr	cx							>
FXIP <	call	SysCopyToStackESDI					>
FXIP <	pop	cx							>

	mov	ax, ATTR_GEN_PATH_DATA
	mov	dx, TEMP_GEN_PATH_SAVED_DISK_HANDLE
	call	GenPathSetObjectPath

FXIP <	call	SysRemoveFromStack					>

	pop	es
	LONG jc	done				; invalid, just give up

continueOnOurMerryWay:
	;
	; Push to the object's current directory so any block motion caused
	; by initializing the ATTR_GEN_PATH_DATA, if such there be, happens
	; before we point the FileEnumParams into the object.
	;
	call	FilePushDir
	mov	ax, ATTR_GEN_PATH_DATA
	mov	dx, TEMP_GEN_PATH_SAVED_DISK_HANDLE
	call	GenPathSetCurrentPathFromObjectPath

	sub	sp, size OLFSEnumParams
	mov	bp, sp
	mov	ss:[bp].OLFSEP_filesDisabled, FALSE

if FSEL_DISABLES_FILTERED_FILES	;---------------------------------------------
	;
	; initialize reject list for callback routine
	;	*ds:si = file selector
	;
	call	OLFSDeref_SI_Spec_DI
	clr	bx
	mov	ds:[di].OLFSI_numRejects, bx
	xchg	bx, ds:[di].OLFSI_rejectList
	tst	bx
	jz	freed
	call	MemFree
freed:



endif	;---------------------------------------------------------------------

	;
	; Set up constant portion of the parameters.
	;
	call	OLFSDeref_SI_Gen_DI
	;
	; Transfer the file types from our fileCriteria to the searchFlags.
	; "Happily", the four bits in our criteria "just happen" to line up
	; nicely with the four bits in the search flags, so just snag the
	; high byte of the criteria, clear out all but those four bits, and
	; OR in the CALLBACK bit, since we always have a callback
	;

CheckHack <\
    offset FSFC_DIRS eq 15 and offset FESF_DIRS eq 7 and \
    offset FSFC_NON_GEOS_FILES eq 14 and offset FESF_NON_GEOS eq 6 and \
    offset FSFC_GEOS_EXECUTABLES eq 13 and offset FESF_GEOS_EXECS eq 5 and \
    offset FSFC_GEOS_NON_EXECUTABLES eq 12 and offset FESF_GEOS_NON_EXECS eq 4\
>
	mov	al, ds:[di].GFSI_fileCriteria.high
	andnf	al, mask FESF_DIRS or mask FESF_NON_GEOS or \
		    mask FESF_GEOS_EXECS or mask FESF_GEOS_NON_EXECS
	ornf	al, mask FESF_CALLBACK
	;
	; If SHOW_FILES_DISABLED, then show all files, regardless of search
	; criteria, as the intent is to indicate to the user what names
	; are already taken.
	;
	test	ds:[di].GFSI_attrs, mask FSA_SHOW_FILES_DISABLED
	jz	setSearchFlags
	mov	ss:[bp].OLFSEP_filesDisabled, TRUE
	ornf	al, mask FESF_NON_GEOS or \
		    mask FESF_GEOS_EXECS or mask FESF_GEOS_NON_EXECS
setSearchFlags:
	mov	ss:[bp].OLFSEP_common.FEP_searchFlags, al

	;
	; The returnAttrs are constant and specify the offsets and attributes
	; for our OLFileSelectorEntry structure.
	;
if _FXIP
	;
	; Pointers into our code segment are bad on XIP systems, so copy
	; the return attrs to the stack
	;
	push	ds, si, cx
	segmov	ds, cs, si
	mov	si, offset olfsReturnAttrs
	mov	cx, SIZE_OF_RETURN_ATTRS_TO_COPY
	call	SysCopyToStackDSSI
	mov	ss:[bp].OLFSEP_common.FEP_returnAttrs.offset, si
	mov	ss:[bp].OLFSEP_common.FEP_returnAttrs.segment, ds
	pop	ds, si, cx
else
	mov	ss:[bp].OLFSEP_common.FEP_returnAttrs.offset,
		offset olfsReturnAttrs
	mov	ss:[bp].OLFSEP_common.FEP_returnAttrs.segment, cs
endif

	mov	ss:[bp].OLFSEP_common.FEP_returnSize, size OLFileSelectorEntry
	;
	; matchAttrs come immediately after the parameters; we'll fill in the
	; array itself in a moment.
	;
	lea	ax, ss:[bp].OLFSEP_matchAttrs
	mov	ss:[bp].OLFSEP_common.FEP_matchAttrs.offset, ax
	mov	ss:[bp].OLFSEP_common.FEP_matchAttrs.segment, ss
	;
	; We accept as many files/directories/etc. as we can get.
	;
	mov	ss:[bp].OLFSEP_common.FEP_bufSize, FE_BUFSIZE_UNLIMITED
	;
	; We skip over none of them.
	;
	clr	ax
	mov	ss:[bp].OLFSEP_common.FEP_skipCount, ax
	;
	; Set the address of our callback routine and zero the segment of the
	; object's filter routine, so we can easily find if there is one....
	;
	mov	ss:[bp].OLFSEP_common.FEP_callback.offset,
		offset OLFSFileEnumCallback
	mov	ss:[bp].OLFSEP_common.FEP_callback.segment, SEGMENT_CS
	mov	ss:[bp].OLFSEP_filter.segment, ax
	mov	ss:[bp].OLFSEP_rawCBAttrsSeg, ax
	mov	ss:[bp].OLFSEP_rawFilterSeg, ax
	;
	; cbData2 holds the address of our object, as we may need to
	; consult it during the callback.
	;
	mov	ss:[bp].OLFSEP_common.FEP_cbData2.low, si
	mov	ss:[bp].OLFSEP_common.FEP_cbData2.high, ds
	;
	; cbData1 holds the pattern against which to compare names, if
	; one is specified. For now, we zero it out, in case there's no pattern.
	;
	mov	ss:[bp].OLFSEP_common.FEP_cbData1.low, ax
	mov	ss:[bp].OLFSEP_common.FEP_cbData1.high, ax

	;
	; Start out with no callback attributes. We'll deal with this later.
	;
	mov	ss:[bp].OLFSEP_common.FEP_callbackAttrs.segment, ax

	;
	; Now fill in the matchAttrs array.
	; 	ds:di = GenFileSelectorInstance, still
	;
	mov	dx, ds:[di].GFSI_fileCriteria	; dx <- file criteria, as we'll
						;  need it several places later
	lea	di, ss:[bp].OLFSEP_matchAttrs	; and we need DI to point
						; to the current matchAttrs
						; element

	;
	; Start with the name mask. This doesn't actually go in the
	; matchAttrs array, but what the heck. I like it here.
	;
	mov	ax, ATTR_GEN_FILE_SELECTOR_NAME_MASK
	call	ObjVarFindData
	jnc	checkToken

	;
	; Attribute exists. Overwrite null pointer with its address. No need
	; for cbAttrs, as we know our return attrs contain FEA_NAME, and that's
	; all we'll need in the callback to perform this wildcarding.
	;
	mov	ss:[bp].OLFSEP_common.FEP_cbData1.offset, bx
	mov	ss:[bp].OLFSEP_common.FEP_cbData1.segment, ds

checkToken:
	tst	ss:[bp].OLFSEP_filesDisabled	; (clears carry)
	jnz	setDefaultFileAttrs		; ignore everything if files are
						;  to be shown disabled. We
						;  still want to mask out
						;  hidden files, though...

	;
	; See if a file token is specified for the object.
	;
	mov	ax, ATTR_GEN_FILE_SELECTOR_TOKEN_MATCH
	call	ObjVarFindData
	jnc	checkCreator

	;
	; Yes. Point the next matchAttrs entry to the value, shortening the
	; usual size by 2 if FSFC_TOKEN_NO_ID is specified in the criteria.
	;
	mov	ss:[di].FEAD_attr, FEA_TOKEN
	mov	ss:[di].FEAD_value.offset, bx
	mov	ss:[di].FEAD_value.segment, ds
	mov	ax, size GeodeToken
	test	dx, mask FSFC_TOKEN_NO_ID
	jz	setTokenSize
	mov	ax, size GT_chars
setTokenSize:
	mov	ss:[di].FEAD_size, ax
	add	di, size FileExtAttrDesc

checkCreator:
	;
	; See if a creator token is specified for the object.
	;
	mov	ax, ATTR_GEN_FILE_SELECTOR_CREATOR_MATCH
	call	ObjVarFindData
	jnc	checkGeodeAttr
	;
	; Yes. Point the next matchAttrs entry to the value, shortening the
	; usual size by 2 if FSFC_TOKEN_NO_ID is specified in the criteria.
	;
	mov	ss:[di].FEAD_attr, FEA_CREATOR
	mov	ss:[di].FEAD_value.offset, bx
	mov	ss:[di].FEAD_value.segment, ds
	mov	ax, size GeodeToken
	test	dx, mask FSFC_TOKEN_NO_ID
	jz	setCreatorSize
	mov	ax, size GT_chars
setCreatorSize:
	mov	ss:[di].FEAD_size, ax
	add	di, size FileExtAttrDesc

checkGeodeAttr:
	;
	; Check for geode attributes.
	;
	mov	ax, ATTR_GEN_FILE_SELECTOR_GEODE_ATTR
	call	ObjVarFindData
	jnc	checkFileAttr
	;
	; They're given, so store the match/mismatch words in the value pointer.
	;
	mov	ss:[di].FEAD_attr, FEA_GEODE_ATTR
	mov	ax, ds:[bx].GFSGA_match
	mov	ss:[di].FEAD_value.offset, ax
	mov	ax, ds:[bx].GFSGA_mismatch
	mov	ss:[di].FEAD_value.segment, ax
	mov	ss:[di].FEAD_size, size GeodeAttrs
	add	di, size FileExtAttrDesc

checkFileAttr:
	;
	; Check for file attributes. This is a little different, as we've got
	; a default value (to screen out hidden and system files) if there's
	; no attribute specified for the object.
	;
	mov	ax, ATTR_GEN_FILE_SELECTOR_FILE_ATTR
	call	ObjVarFindData

setDefaultFileAttrs:
	jnc	figureDefaultFileAttrs
	mov	ax, {word}ds:[bx]	; load actual attributes
	jmp	storeFileAttr

figureDefaultFileAttrs:

	mov	ax, (mask FA_HIDDEN or mask FA_SYSTEM) shl 8	; ax <- default
if _DUI
	push	cx
	call	SecretModeGetState
	cmp	cl, SM_OFF
	pop	cx
	je	gotFileAttr
	mov	ax, (mask FA_SYSTEM) shl 8		; allow hidden (secret)
gotFileAttr:
endif
	test	ss:[bp].OLFSEP_common.FEP_searchFlags, mask FESF_DIRS
	jnz	storeFileAttr		; => wants to see dirs
	ornf	ah, mask FA_SUBDIR	; directories don't match

storeFileAttr:
	mov	ss:[di].FEAD_attr, FEA_FILE_ATTR
	mov	ss:[di].FEAD_value.offset, ax	; store bits to match (don't
						;  need to worry about AH b/c
						;  FEAD_size will be 1)
	mov	al, ah
	mov	ss:[di].FEAD_value.segment, ax	; store bits to mismatch
	mov	ss:[di].FEAD_size, size FileAttrs

	;
	; Also store it at a fixed location in the stack frame, so our
	; callback can get to it easier.
	;

	mov	ss:[bp].OLFSEP_fileAttrsMismatch, al
	add	di, size FileExtAttrDesc

	;
	; Terminate the array of attributes to match.
	;
	mov	ss:[di].FEAD_attr, FEA_END_OF_LIST

checkFileHeaderFlags::
	;
	; Check for file header flags.
	;
	mov	ax, ATTR_GEN_FILE_SELECTOR_FILE_HEADER_FLAGS
	call	ObjVarFindData
	mov	ax, 0			; no file header flags to match
	mov	cx, 0			; no file header flags to mismatch
	jnc	storeFileHeaderFlags
	mov	ax, ds:[bx].GFSFHF_match
	mov	cx, ds:[bx].GFSFHF_mismatch

storeFileHeaderFlags:
	mov	ss:[bp].OLFSEP_fileHeaderFlags.GFSFHF_match, ax
	mov	ss:[bp].OLFSEP_fileHeaderFlags.GFSFHF_mismatch, cx

	;
	; Look for extra callback attributes required by FSFC_FILE_FILTER
	;
	test	dx, mask FSFC_FILE_FILTER
	jz	doItBabe

	mov	ax, MSG_GEN_FILE_SELECTOR_GET_FILTER_ROUTINE
	push	dx, bp
	call	ObjCallInstanceNoLock
	mov	bx, bp
	mov	di, dx
	pop	dx, bp

	jcxz	doItBabe		; no routine returned -- ignore filter

EC <	Assert	vfptr,	cxax					>
	mov	ss:[bp].OLFSEP_rawFilterSeg, cx
	mov	ss:[bp].OLFSEP_filter.offset, ax
if	FULL_EXECUTE_IN_PLACE
	mov	ss:[bp].OLFSEP_filter.segment, cx

;	On Full-XIP systems, don't lock down code resources in the XIP image,
;	just call the callback using ProcCallFixedOrMovable

	cmp	ch, high MAX_SEGMENT		;Is this a vfptr
	jb	noLock				;Nope, it's fixed, so don't
						; bother locking it
	shl	cx, 1
	shl	cx, 1
	shl	cx, 1
	shl	cx, 1
	cmp	cx, LAST_XIP_RESOURCE_HANDLE	;An XIP handle?
	jbe	noLock				;Branch if so, else lock it
	push	bx
	mov	bx, cx
	call	MemLock
	pop	bx
	mov	ss:[bp].OLFSEP_filter.segment, ax
noLock:
else
	push	bx
	mov_tr	bx, cx
	call	MemLockFixedOrMovable
	mov	ss:[bp].OLFSEP_filter.segment, ax
	pop	bx
endif

	tst	bx			; extra attributes given?
	jz	doItBabe		; no -- leave callbackAttrs alone

EC <	Assert	vfptr, bxdi					>
	;
	; Additional attributes given, so store the pointer to them.
	;
	mov	ss:[bp].OLFSEP_common.FEP_callbackAttrs.offset, di
	mov	ss:[bp].OLFSEP_rawCBAttrsSeg, bx
	call	MemLockFixedOrMovable
	mov	ss:[bp].OLFSEP_common.FEP_callbackAttrs.segment, ax

doItBabe:
	;
	; Call FileEnum to get everything at once. It'll allocate as big a
	; buffer as we need, etc. etc. etc.
	;
if HAVE_FAKE_FILE_SYSTEM
	;
	; Look to see if we should use a fake file enum..
	;
	test	dx, mask FSFC_USE_FAKE_FILE_SYSTEM
	jz	reallyDoItBabe

	mov	ax, MSG_GEN_FILE_SELECTOR_GET_FILE_ENUM_ROUTINE
	call	ObjCallInstanceNoLock

	jcxz	reallyDoItBabe		; no routine returned -- use FileEnum

EC <	Assert	vfptr,	cxax					>
	mov	bx, cx
	call	ProcCallFixedOrMovable
	jmp	reallyDoneItNow

reallyDoItBabe:
endif	;HAVE_FAKE_FILE_SYSTEM

	call	FileEnum
reallyDoneItNow:
FXIP <	call	SysRemoveFromStack				>


	;
	; Unlock the filter routine and extra callback attributes, if they
	; were given.
	;
	pushf
	push	bx
	mov	bx, ss:[bp].OLFSEP_rawCBAttrsSeg
	tst	bx
	jz	unlockFilterRoutine
	call	MemUnlockFixedOrMovable

unlockFilterRoutine:
	mov	bx, ss:[bp].OLFSEP_rawFilterSeg
	tst	bx
	jz	clearStack

if	FULL_EXECUTE_IN_PLACE

;	Unlock the filter resource, if it wasn't fixed or in an XIP resource

	cmp	bh, high MAX_SEGMENT
	jb	noUnlock

	shl	bx, 1
	shl	bx, 1
	shl	bx, 1
	shl	bx, 1
	cmp	bx, LAST_XIP_RESOURCE_HANDLE
	jbe	noUnlock
	call	MemUnlock
noUnlock:

else
	call	MemUnlockFixedOrMovable
endif

clearStack::
	pop	bx

	popf


	lea	sp, ss:[bp+size OLFSEnumParams]	; clear the rest of the stack
						; (FileEnum cleared its part,
						; but we still had the
						; matchAttrs array there)

	call	FilePopDir
	jc	done

	;
	; Record the buffer handle and the number of files we actually got back.
	;
	call	OLFSDeref_SI_Spec_DI
	mov	ds:[di].OLFSI_numFiles, cx
	mov	ds:[di].OLFSI_fileCount, cx	; assume all files, for now
	mov	ds:[di].OLFSI_fileBuffer, bx
	jcxz	setDirCount

	;
	; Figure the number of directories in that array of "files"
	;
	clr	dx
	call	OLFSMemLock_ES
	mov	bp, dx
dirCountLoop:
;DBCS <	mov	es:[bp].OLFSE_nullTerm, 0	; ensure name null-termed >
	test	es:[bp].OLFSE_fileAttrs, mask FA_SUBDIR
	jz	nextFileEntry
	inc	dx
nextFileEntry:
	add	bp, size OLFileSelectorEntry
	loop	dirCountLoop
	call	MemUnlock

setDirCount:
	;
	; Store the number of directories and reduce the number of files by
	; that amount.
	;
	mov	ds:[di].OLFSI_dirCount, dx
	sub	ds:[di].OLFSI_fileCount, dx

	;
	; sort file list
	;	*ds:si = OLFileSelector instance
	;
	call	OLFSSortList			; sort files
	clc					; indicate no error
done:

	.leave
	ret
OLFSBuildFileList	endp







COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddNoFilesIfNeeded
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adds a "no files" item if needed.

CALLED BY:	OLFSBuildFileList

PASS:		*ds:si -- file selector
		bx -- file list block
		cx -- current num files

RETURN:		cx -- updated num files
		bx -- file list block, possibly updated

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/30/94       	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFSFileEnumCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check the suitability of a file for inclusion in a
		file selector.

CALLED BY:	OLFSBuildFileList via FileEnum
PASS:		ds	= segment of FileEnumCallbackData
		ss:bp	= inherited stack frame
RETURN:		carry clear to accept the file
		carry set to reject the file
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/13/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLFSFileEnumCallback proc far params:OLFSEnumParams
		uses	ax, bx, cx, dx, ds, si, es, di
		.enter	inherit	far


	;
	; See if this is a GEOS hidden file, and if we're masking out
	; hidden files.  If it's not a GEOS file (signified by the
	; FEAD_value.segment being zero), then we skip this test.
	;
		mov	ax, FEA_FLAGS
		call	FileEnumLocateAttr
		jc	afterFileHeaderFlags
		tst	es:[di].FEAD_value.segment
		jz	afterFileHeaderFlags
		les	di, es:[di].FEAD_value ; es:di - GeosFileHeaderFlags
		test	ss:[params].OLFSEP_fileAttrsMismatch, mask FA_HIDDEN
		jz	afterHidden
		test	{GeosFileHeaderFlags} es:[di], mask GFHF_HIDDEN
		stc
		LONG jnz done

afterHidden:
	;
	; Do we need to check file header flags on files
	;
		mov	ax, ss:[params].OLFSEP_fileHeaderFlags.GFSFHF_match
		or	ax, ss:[params].OLFSEP_fileHeaderFlags.GFSFHF_mismatch
		jz	afterFileHeaderFlags

		mov	bx, {GeosFileHeaderFlags}es:[di]
	;
	; Get file attributes because we need to skip file header checks
	; if subdir
	;
		mov	ax, FEA_FILE_ATTR
		mov	si, offset FECD_attrs
		call	FileEnumLocateAttr
EC <		ERROR_C	OLFS_FILE_ATTR_MISSING_FROM_CALLBACK_DATA	>
EC <		tst	es:[di].FEAD_value.segment			>
EC <		ERROR_Z	OLFS_FILE_ATTR_MISSING_FROM_CALLBACK_DATA	>
		les	di, es:[di].FEAD_value ; es:di - FileAttrs
		test	{FileAttrs} es:[di], mask FA_SUBDIR
		jnz	afterFileHeaderFlags
	;
	; Check file header flags on files
	;
		mov	cx, ss:[params].OLFSEP_fileHeaderFlags.GFSFHF_match
		jcxz	noMatchFlags
		test	bx, cx
		stc				;assume reject
		LONG jz done			;reject this file is no match
noMatchFlags:
		test	bx, ss:[params].OLFSEP_fileHeaderFlags.GFSFHF_mismatch
		stc				;assume reject
		LONG jnz done

afterFileHeaderFlags:
	;
	; Get GFSI_fileCriteria into DX for use in various places throughout
	; this here function.
	;
		les	bx, ss:[params].OLFSEP_common.FEP_cbData2
		mov	di, es:[bx]
		add	di, es:[di].Gen_offset
		mov	dx, es:[di].GFSI_fileCriteria
	;
	; If no mask passed, then skip wildcard check.
	;
		tst	ss:[params].OLFSEP_common.FEP_cbData1.segment
		jz	wildcardCheckComplete
	;
	; Fetch the file attributes first.
	;
		mov	ax, FEA_FILE_ATTR
		mov	si, offset FECD_attrs
		call	FileEnumLocateAttr
EC <		ERROR_C	OLFS_FILE_ATTR_MISSING_FROM_CALLBACK_DATA	>
EC <		tst	es:[di].FEAD_value.segment			>
EC <		ERROR_Z	OLFS_FILE_ATTR_MISSING_FROM_CALLBACK_DATA	>

		mov	di, es:[di].FEAD_value.offset
		mov	cl, {FileAttrs}es:[di]

	;
	; If the file is actually a directory, only use the mask if the
	; FSFC_USE_MASK_FOR_DIRS flag is set.
	;
		test	cl, mask FA_SUBDIR
		jz	doWildcard

		test	dx, mask FSFC_USE_MASK_FOR_DIRS
		jz	wildcardCheckComplete

doWildcard:
	;
	; Performing wildcard check on the beast, so determine what to store
	; in cbData2.low and which routine to call.
	;
		clr	ax		; assume case-sensitive
		test	dx, mask FSFC_MASK_CASE_INSENSITIVE
		jz	callWildcard
		dec	ax		; non-zero => case-insensitive
callWildcard:
		mov	ss:[params].OLFSEP_common.FEP_cbData2.low, ax
		call	FileEnumWildcard
finishWildcard:
	;
	; restore chunk portion of cbData2 for next time...
	;
		mov	ss:[params].OLFSEP_common.FEP_cbData2.low, bx
		LONG jc	done

wildcardCheckComplete:
	;
	; Our check is now done, but we may need to call ourselves to allow
	; a subclass to have a say in the matter.
	;
		test	dx, mask FSFC_FILE_FILTER	; (clears carry)
		LONG jz	done

		tst	ss:[params].OLFSEP_filter.segment	; any routine
								; given?
		LONG jz	done				; no (carry clear)
	;
	; Call filter routine now.
	;
		segmov	es, ds			; es <- FECD
if FSEL_DISABLES_FILTERED_FILES
		push	es			; save for post-filtering
endif
		lds	si, ss:[params].OLFSEP_common.FEP_cbData2
						; *ds:si <- object

		push	bp			; preserve frame
EC <		push	ds:[si]	; save object base for EC		>

   		test	dx, mask FSFC_FILTER_IS_C
		LONG jnz	doCFilter

		pushdw	ss:[params].OLFSEP_filter
		call	PROCCALLFIXEDORMOVABLE_PASCAL
finishFilter:
EC <		pop	di						>
		pop	bp
if FSEL_DISABLES_FILTERED_FILES
		pop	ds			; ds <- FECD
endif

EC <		pushf							>
EC <		push	ds						>
EC <		lds	si, ss:[params].OLFSEP_common.FEP_cbData2	>
EC <		cmp	di, ds:[si]					>
EC <		ERROR_NE	OLFS_FILTER_METHOD_CAUSED_OBJECT_TO_MOVE>
EC <		pop	ds						>
EC <		popf							>

if FSEL_DISABLES_FILTERED_FILES	;---------------------------------------------
	;
	; If filtered file, don't filter, just mark for disabling.
	; Filtered directories get filtered.
	;	ds = FileEnumCallbackData
	;
		LONG jnc	haveResult		; file is accepted

		mov	ax, FEA_FILE_ATTR
		mov	si, offset FECD_attrs
		call	FileEnumLocateAttr
EC <		ERROR_C	OLFS_FILE_ATTR_MISSING_FROM_CALLBACK_DATA	>
EC <		tst	es:[di].FEAD_value.segment			>
EC <		ERROR_Z	OLFS_FILE_ATTR_MISSING_FROM_CALLBACK_DATA	>
		mov	di, es:[di].FEAD_value.offset
		test	{FileAttrs}es:[di], mask FA_SUBDIR
		stc				; assume subdir, reject
		LONG jnz haveResult		; yes, really reject subdirs


		mov	ax, FEA_FILE_ID
		mov	si, offset FECD_attrs
		call	FileEnumLocateAttr
EC <		ERROR_C	OLFS_FILE_ATTR_MISSING_FROM_CALLBACK_DATA	>
EC <		tst	es:[di].FEAD_value.segment			>
EC <		ERROR_Z	OLFS_FILE_ATTR_MISSING_FROM_CALLBACK_DATA	>
		mov	di, es:[di].FEAD_value.offset
		mov	cx, ({FileID}es:[di]).high	;cx:dx = FileID
		mov	dx, ({FileID}es:[di]).low
		lds	si, ss:[params].OLFSEP_common.FEP_cbData2
		mov	si, ds:[si]		; ds:di = file selector
		add	si, ds:[si].Vis_offset
		mov	bx, ds:[si].OLFSI_rejectList
		tst	bx
		jnz	haveList
		mov	ax, size FileID
		push	cx
		mov	cx, ALLOC_DYNAMIC_LOCK
		call	MemAlloc		; bx = handle, ax = segment
		pop	cx
		jc	haveResult		; couldn't alloc, really reject
		mov	ds:[si].OLFSI_rejectList, bx
		mov	es, ax			; es:di = loc for new FileID
		clr	di
		jmp	short storeReject

haveList:
		mov	ax, ds:[si].OLFSI_numRejects
.assert (size FileID eq 4)
		shl	ax, 1
		shl	ax, 1
		mov	di, ax			; offset for new FileID
		add	ax, size FileID		; room for new one
		push	cx
		mov	ch, mask HAF_LOCK
		call	MemReAlloc
		pop	cx
		jc	haveResult		; couldn't resize, reject
		mov	es, ax			; es:di = loc for new FileID
storeReject:
		mov	({FileID}es:[di]).high, cx	; store new reject
		mov	({FileID}es:[di]).low, dx
		call	MemUnlock
		inc	ds:[si].OLFSI_numRejects
		clc				; ACCEPT file
haveResult:
endif	;---------------------------------------------------------------------

done:
		.leave
		ret

doCFilter:
	;
	; Call a filter routine written in C:
	; 	Boolean	_pascalFileSelectorCallback(_optr self,
	;				     FileEnumCallbackData *attributes,
	;				     word frame);
	; THIS ROUTINE MUST BE DECLARED AS A PASCAL ROUTINE!!!
	; it should return TRUE to reject the file, and FALSE to accept it.
	;
		push	ds:[LMBH_handle]	; self.handle
		push	si			; self.chunk
		push	es			; attributes.segment
		clr	ax
		push	ax			; attributes.offset
		push	bp			; frame
		call	ThreadGetDGroupDS	; must pass ds = dgroup for C
		pushdw	ss:[params].OLFSEP_filter
		call	PROCCALLFIXEDORMOVABLE_PASCAL
		tst	ax		; return FALSE (i.e. accept)?
		LONG jz	finishFilter	; yes -- carry already clear
		stc
		jmp	finishFilter

OLFSFileEnumCallback endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFSCompareFiles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare two entries for sorting the displayed files

CALLED BY:	OLFSSortList via ArrayQuickSort
PASS:		ds:si	= address of first entry's offset in file buffer
		ds:di	= address of second entry's offset in file buffer
		bx	= segment of file buffer.
RETURN:		flags set so caller can jl, je, or jg according as first
		    element is less than, equal to, or greater than the second
DESTROYED:	allowed: ax, bx, cx, dx, di, si

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/12/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	SORT_FILE_SELECTOR_ENTRIES

;
; a few bytes of duplicated code, here...
;
CheckDirState	proc	near
		uses	ax, si, di, es, ds
		.enter
	;
	; Point ds:si and es:di to the strings for the two entries.
	;
		mov	di, ds:[di]
		mov	si, ds:[si]
		mov	es, bx
		mov	ds, bx

	;
	; Get attrs for file/subdir check
	;
		mov	al, ds:[si].OLFSE_fileAttrs
		andnf	al, mask FA_SUBDIR		; FA_SUBDIR of #1
		mov	ah, ds:[di].OLFSE_fileAttrs
		andnf	ah, mask FA_SUBDIR		; FA_SUBDIR of #2
		cmp	ah, al
		.leave
		ret
CheckDirState	endp

OLFSCompareFilesReverse	proc	far
	;
	; check if both aren't files or dirs, if so, no reverse
	;
		call	CheckDirState
		jne	noReverse
	;
	; reverse sense of the comparison
	;
		xchg	si, di
noReverse:
		FALL_THRU	OLFSCompareFiles
OLFSCompareFilesReverse	endp

OLFSCompareFiles proc	far
		uses	es, ds
		.enter
	;
	; Point ds:si and es:di to the strings for the two entries.
	; Since these are files and drives and the like, we know there can't
	; be two with the same name, so we don't have to worry about how the
	; result would be pretty random, given that garbage follows the
	; null-terminators in the two names.
	;
		mov	di, ds:[di]
		mov	si, ds:[si]
		mov	es, bx
		mov	ds, bx

if	_DUI
	;
	; Horrible hack to deal with dos files, which don't have creation
	; dates - just make them have really early creation dates, but ones
	; that come after the directories that lie at the end of the list,
	; so these DOS files lie at the bottom of the list of files, but
	; before the faux directories...
	;
		tst	ds:[si].OLFSE_fileDate.FDAT_date
		jnz	10$
		tst	ds:[si].OLFSE_fileDate.FDAT_time
		jnz	10$
if _DUI
		mov	ds:[si].OLFSE_fileDate.FDAT_time, 1
else
		mov	ds:[si].OLFSE_fileDate.FDAT_time, NUM_SECTION_HEADERS+1
endif
10$:

		tst	es:[di].OLFSE_fileDate.FDAT_date
		jnz	20$
		tst	es:[di].OLFSE_fileDate.FDAT_time
		jnz	20$
if _DUI
		mov	es:[di].OLFSE_fileDate.FDAT_time, 1
else
		mov	es:[di].OLFSE_fileDate.FDAT_time, NUM_SECTION_HEADERS+1
endif
20$:
endif


		mov	al, ds:[si].OLFSE_fileAttrs
		andnf	al, mask FA_SUBDIR		; FA_SUBDIR of #1
		mov	ah, ds:[di].OLFSE_fileAttrs
		andnf	ah, mask FA_SUBDIR		; FA_SUBDIR of #2

	;
	; First, make any directories come before any files
	;
		cmp	ah, al
		jne	done				; if #1 is subdir, and
							; #2 is not, #1 < #2
							; and vice versa...


		; if both are files or both are subdirs, use name
if	SORT_FILE_SELECTOR_ENTRIES_BY_MODIFICATION_DATE or SORT_FILE_SELECTOR_ENTRIES_BY_CREATION_DATE
		push	bp
		mov	bp, offset OLFSE_fileDate
		call	compDateTime
		pop	bp
if _DUI
		jne	done
		; if same creation date, use mod date
		push	bp
		mov	bp, offset OLFSE_modification
		call	compDateTime
		pop	bp
endif
if _DUI
		jne	done
		; if same dates, use name
		mov	cx, length OLFSE_name
		add	si, offset OLFSE_name
		add	di, offset OLFSE_name
		xchg	di, si			; names in ascending order
		call	LocalCmpStringsNoCase
		xchg	di, si			; preserves flags
endif	; _DUI
else
	;
	; Compare the two strings in the usual manner. Flags are left as
	; appropriate
	;
		mov	cx, length OLFSE_name
		add	si, offset OLFSE_name
		add	di, offset OLFSE_name
		call	LocalCmpStrings
endif
done:
		.leave
		ret

if	SORT_FILE_SELECTOR_ENTRIES_BY_MODIFICATION_DATE or SORT_FILE_SELECTOR_ENTRIES_BY_CREATION_DATE
;
; since an array sort callback must return a signed
; comparison result, we must futz around a bit to correctly
; compare unsigned values
;
compDateTime	label	near
		mov	ax, es:[di][bp].FDAT_date
		mov	cx, ax
		shr	ax, 1			; convert to 15-bit signed
		mov	bx, ds:[si][bp].FDAT_date
		mov	dx, bx
		shr	bx, 1			; convert to 15-bit signed
		cmp	ax, bx
		jne	compDateTimeDone
		andnf	cx, 1			; check low bit
		andnf	dx, 1
		cmp	cx, dx
		jne	compDateTimeDone
		mov	ax, es:[di][bp].FDAT_time
		mov	cx, ax
		shr	ax, 1			; convert to 15-bit signed
		mov	bx, ds:[si][bp].FDAT_time
		mov	dx, bx
		shr	bx, 1			; convert to 15-bit signed
		cmp	ax, bx
		jne	compDateTimeDone
		andnf	cx, 1			; check low bit
		andnf	dx, 1
		cmp	cx, dx
compDateTimeDone:
		retn
endif

OLFSCompareFiles endp
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFSCompareFilesAlphabetically
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Alphabetically compare two entries for sorting the
		displayed files.  Subdirectories come before files.

CALLED BY:	OLFSSortList via ArrayQuickSort
PASS:		ds:si	= address of first entry's offset in file buffer
		ds:di	= address of second entry's offset in file buffer
		bx	= segment of file buffer.
RETURN:		flags set so caller can jl, je, or jg according as first
		    element is less than, equal to, or greater than the second
DESTROYED:	allowed: ax, bx, cx, dx, di, si

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 11/10/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	SORT_FILE_SELECTOR_ENTRIES
OLFSCompareFilesAlphabeticallyReverse	proc	far
	;
	; check if both aren't files or dirs, if so, no reverse
	;
		call	CheckDirState
		jne	noReverse
	;
	; reverse sense of the comparison
	;
		xchg	si, di
noReverse:
		FALL_THRU	OLFSCompareFilesAlphabetically
OLFSCompareFilesAlphabeticallyReverse	endp

OLFSCompareFilesAlphabetically	proc	far
		uses	es, ds
		.enter
	;
	; Point ds:si and es:di to the strings for the two entries.
	; Since these are files and drives and the like, we know there can't
	; be two with the same name, so we don't have to worry about how the
	; result would be pretty random, given that garbage follows the
	; null-terminators in the two names.
	;
		mov	di, ds:[di]
		mov	si, ds:[si]
		mov	es, bx
		mov	ds, bx

	;
	; Get attrs for file/subdir check (at cmp ah, al).
	;
		mov	al, ds:[si].OLFSE_fileAttrs
		andnf	al, mask FA_SUBDIR		; FA_SUBDIR of #1
		mov	ah, ds:[di].OLFSE_fileAttrs
		andnf	ah, mask FA_SUBDIR		; FA_SUBDIR of #2

	;
	; First, make any directories come before any files
	;
		cmp	ah, al
		jne	done				; if #1 is subdir, and
							; #2 is not, #1 < #2
							; and vice versa...

	;
	; Compare the two strings in the usual manner. Flags are left as
	; appropriate
	;
		mov	cx, length OLFSE_name
		add	si, offset OLFSE_name
		add	di, offset OLFSE_name
		call	LocalCmpStrings
done:
		.leave
		ret
OLFSCompareFilesAlphabetically	endp
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFSSortList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	sorts file or volume list

CALLED BY:	INTERNAL
			OLFSBuildFileList
			OLFSBuildVolumeList

PASS:		*ds:si - OLFileSelector

RETURN:

DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	02/08/90	Initial version
	brianc	4/91		Completed 2.0 revisions
	ardeb	12/12/91	Changed to use ArrayQuickSort and build the
				index table, since volumes and files are
				stored in the same structures now.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLFSSortList	proc	near
params			local	QuickSortParameters
shouldWeSort		local	word
compareRoutineOffset	local	word
	class	OLFileSelectorClass
	uses	ds, si
	.enter

	;
	; If we've got HINT_FILE_SELECTOR_DONT_SORT, then we'll
	; make a note to ourselves not to sort.  BUT, we still make
	; the OLFSI_indexBuffer, which is used in various places.
	;
	mov	ss:[shouldWeSort], FALSE	; Assume no sort.
	mov	ax, HINT_FILE_SELECTOR_DONT_SORT
	call	ObjVarFindData
	jc	gotComparisonRoutine
	mov	ss:[shouldWeSort], TRUE		; We should sort.

	;
	; if we've got HINT_FILE_SELECTOR_REVERSE_SORT, we must reverse
	; the sort
	;
if _DUI
	mov	cx, 1				; assume reversed for _DUI
else
	mov	cx, 0				; assume no reverse
endif
	mov	ax, HINT_FILE_SELECTOR_REVERSE_SORT
	call	ObjVarFindData
	jnc	haveReverseFlag
if _DUI
	dec	cx				; else, need to reverse
else
	inc	cx				; else, need to reverse
endif
haveReverseFlag:
	;
	; If we've got HINT_FILE_SELECTOR_ALWAYS_SORT_ALPHABETICALLY,
	; then we must do an alphabetical sort.
	;
	mov	ax, HINT_FILE_SELECTOR_ALWAYS_SORT_ALPHABETICALLY
	call	ObjVarFindData
	mov	ss:[compareRoutineOffset], offset OLFSCompareFiles
	jcxz	haveCompFiles
	mov	ss:[compareRoutineOffset], offset OLFSCompareFilesReverse
haveCompFiles:
	jnc	gotComparisonRoutine
	mov	ss:[compareRoutineOffset],
			offset OLFSCompareFilesAlphabetically
	jcxz	gotComparisonRoutine
	mov	ss:[compareRoutineOffset],
			offset OLFSCompareFilesAlphabeticallyReverse
gotComparisonRoutine:

	call	OLFSDeref_SI_Spec_DI		; ds:di <- specific instance
	;
	; build index table for files that we can sort more quickly than
	; the OLFileSelectorEntry structures themselves.
	;
	mov	ax, ds:[di].OLFSI_numFiles	; ax <- number of files
	tst	ax
	jz	done				; no files => no buffer
if 0
; if _RUDY
; See below...
;
	push	si
endif
	mov	si, ds:[di].OLFSI_fileBuffer	; si <- file buffer, for sort
	push	ax				; save for index creation
	push	ax				;  and sorting.
	shl	ax				; table made of words...
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK or mask HF_SHARABLE
	call	MemAlloc
	mov	ds:[di].OLFSI_indexBuffer, bx
	mov	es, ax
	pop	cx				; cx <- number of entries
	clr	di
	clr	ax
indexLoop:
	stosw					; save entry offset
	add	ax, size OLFileSelectorEntry	; ax = next entry
	loop	indexLoop

	pop	cx				; cx <- number of entries

	;
	; Now that we've made our index table, let's see whether we
	; determined that we would sort or not.
	; CAUTION:  The commented-out _RUDY code above pushes si.
	; If the push is ever uncommented, the je done below will
	; need to be modified.
	;
	cmp	ss:[shouldWeSort], FALSE	; Should we not sort?
	je	done				; Nope, so bail.

if SORT_FILE_SELECTOR_ENTRIES

if 0
; if _RUDY
; It turns out that we want to sort the SP_DOCUMENT directory after all,
; in order to place the subdirectories before the files.  The original
; reason for not sorting SP_DOCUMENT was that quick-sort was pseudo-randomly
; ordering the directories in SP_DOCUMENT, since they are created at almost
; the same time, and thus have the same FileTime and FileDate.  We solve
; this problem by explicitly setting the creation time and date so that,
; when sorted by newest creation date first, the directories will be in the
; desired order.  Code to set the FEA_CREATION attributes of the directories
; is in InitDocumentDirs in Library/Foam/Foam/Entry/entry.asm.
; -Chung 8/3/95
;

	;
	; If the current path is SP_DOCUMENT we do not want to sort.  This
	; is because we want to preserve the DOS order of the sub-directories.
	; ArrayQuickSort will not preserve the order of the given list if all
	; the entries are identical - like they are in our case.
	;
	pop	di
	push	bx, si
	mov	si, di				; *ds:si <- Object
	mov	ax, ATTR_GEN_PATH_DATA
	call	ObjVarFindData
	mov	di, bx
	pop	bx, si
	cmp	ds:[di].GFP_disk, SP_DOCUMENT
	jne	notDocument
	LocalIsNull ds:[di].GFP_path
	jz	done
notDocument:
endif

	push	bx, si				; save index and file buffer
						;  handles
	mov	bx, si
	call	MemLock
	mov_tr	bx, ax				; bx <- file buffer segment
						;  for comparison
	segmov	ds, es
	clr	si				; ds:si <- array start
	;
	; Set comparison callback routine.
	;
	mov	ss:[params].QSP_compareCallback.segment, SEGMENT_CS
	mov	ax, ss:[compareRoutineOffset]
	mov	ss:[params].QSP_compareCallback.offset, ax
	;
	; There's neither a lock nor an unlock callback.
	;
	mov	ss:[params].QSP_lockCallback.segment, si
	mov	ss:[params].QSP_unlockCallback.segment, si
	;
	; We've no special requirements for the insert or median limits.
	;
	mov	ss:[params].QSP_insertLimit, DEFAULT_INSERTION_SORT_LIMIT
	mov	ss:[params].QSP_medianLimit, DEFAULT_MEDIAN_LIMIT

	mov	ax, size word
	call	ArrayQuickSort

	pop	bx
	call	MemUnlock			; unlock file buffer
	pop	bx
endif	;SORT_FILE_SELECTOR_ENTRIES

	call	MemUnlock			; unlock index buffer
done:
	.leave
	ret
OLFSSortList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFSShowCurrentDir
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create and initialize children for
		the Change Directory Popup,  setting the children's
		monikers, etc.

CALLED BY:	INTERNAL
			OLFileSelectorSetSelection
			OLFileSelectorChangeDirectoryPopupHandler
			OLFileSelectorListMethod
			OLFSRescanLow
			OLFSUpDirectory

PASS:		*ds:si - instance of OLFileSelector

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, di

		NOTE:  invalidates any chunk pointers, dereference them
			again or die

PSEUDO CODE/STRATEGY:

		Added code 1/94 to only destroy/create children when
		necessary, to fix bug 28291.


KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Don't actually build list unless popup list is being
		opened (though we do need to do the other fluff in
		here to get buttons disabled and enabled correctly).

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	01/29/90	Initial version
	brianc	4/91		Completed 2.0 revisions
	brianc	9/92		2.0 usability revisions

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


if not SINGLE_DRIVE_DOCUMENT_DIR and FSEL_HAS_CHANGE_DIRECTORY_POPUP

OLFSShowCurrentDir	proc	far
	class	OLFileSelectorClass

	uses	si, es

fsChunk			local	word		push	si
uiBlock			local	word
identifier		local	word
pathBuffer		local	PathName
atRoot			local	word
fcfpDiskHandle		local	word
curDirIsVirtualRoot	local	word
virtualRootSeen		local	word
mostRecentGenItem	local	optr
childCount		local	word
;Number of children we've added.  May be different than identifer if
;file selector has a virtual root

	.enter

	clr	identifier
	clr	childCount

	;
	; empty the current path list
	;
	call	OLFSDeref_SI_Spec_DI
	mov	bx, ds:[di].OLFSI_uiBlock	; ^lbx:si = popup list
	mov	uiBlock, bx
if HAVE_FAKE_FILE_SYSTEM
	;
	; check to see if we are using a fake file system
	;
	call	OLFSDeref_SI_Gen_DI
	test	ds:[di].GFSI_fileCriteria, mask FSFC_USE_FAKE_FILE_SYSTEM
	jz	useRealFS
	;
	; yep..  get the path.  If it doesn't end with a slash, add
	; one.
	;
	mov	ax, MSG_GEN_FILE_SELECTOR_FAKE_PATH_GET
	mov	cx, ss
	mov	es, cx
	lea	dx, pathBuffer
	mov	es:[pathBuffer], C_BACKSLASH
	inc	dx
	call	ObjCallInstanceNoLock
	mov	curDirIsVirtualRoot, FALSE
	mov	si, dx
	tst	ax			; on error, just polish return root
	jnz	needSlash
	cmp	{byte}es:[si].-1, '\\'
	je	haveSlash
needSlash:
	mov	{word}es:[si], '\\'
haveSlash:
	jmp	makeList
endif ;HAVE_FAKE_FILE_SYSTEM
	;
	; if the current directory is the virtual root or a subdirectory of
	; the virtual root, we want the popup list to start from that
	; virtual root, so we skip this "drive-name:[volume-name]/" nonsense
	; (note that that we still bump identifier for any elements we skip
	; because we depend on them when we figure out which directory to
	; switch to when the change directory popup is used by the user)
	;
useRealFS:
	mov	curDirIsVirtualRoot, TRUE	; assume so
	mov	si, fsChunk			; *ds:si = OLFileSelector
	call	OLFSIsCurDirVirtualRootOrUnderVirtualRoot
	jc	afterRootElement		; yes, skip root element
	mov	curDirIsVirtualRoot, FALSE	; no virtual root
	;
	; get current drive from OLFileSelector
	;	*ds:si = OLFileSelector
	;
	call	OLFSGetCurrentDrive		; bx = disk handle
						; al = drive #
	;
	; create a popup list item for the root
	; we want "drive-name:[volume-name]/"
	;	al = drive #
	;	bx = disk handle
	;	on stack: ui block
	;
	segmov	es, ss				; es:di = path buffer
	lea	di, pathBuffer
	mov	cx, size pathBuffer
	mov	dx, mask SDAVNF_PASS_DISK_HANDLE or mask SDAVNF_TRAILING_SLASH
	call	OLFSStuffDriveAndVolumeName
	mov	bx, uiBlock			; ^lbx:si = popup list
	mov	si, offset OLFileSelectorChangeDirectoryPopup
	mov	cx, identifier		; identifier for root item
	mov	ax, childCount
	call	OLFSCreateCurDirItem		; ^lbx:si = new GenItem
						; (destroys nothing)
	inc	childCount

	movdw	mostRecentGenItem, bxsi
	mov	cx, ss				; cx:dx = root item moniker
	lea	dx, pathBuffer
	call	OLFSReplaceVisMonikerText	; (preserves bp)
	call	OLFSSelectGenItem
afterRootElement:
	inc	identifier			; bump for next path element
	;
	; get disk handle and path from OLFileSelector and build full path
	;
	mov	si, fsChunk			; *ds:si = OLFileSelector
	mov	atRoot, TRUE			; assume at root
						; (clear when we find path)
	mov	ax, ATTR_GEN_PATH_DATA
	mov	dx, TEMP_GEN_PATH_SAVED_DISK_HANDLE
	call	GenPathFetchDiskHandleAndDerefPath	; ax = disk handle
							; ds:bx = GenFilePath
	lea	si, ds:[bx].GFP_path		; ds:si = path tail
	mov	bx, ax				; bx = disk handle
	mov	cx, size pathBuffer
	segmov	es, ss				; es:di = path buffer
	lea	di, pathBuffer
	mov	dx, 0				; no drive name
	call	FileConstructFullPath		; build full text of path
EC <	ERROR_C	OL_ERROR			; should not overflow	>
	;
	; now for each element in the path, create an item in popup list
	;	pathBuffer = path buffer
	;	bx = disk handle
	;
makeList:
	mov	virtualRootSeen, FALSE		; init flag
	mov	fcfpDiskHandle, bx		; save full path disk handle
						;	for later
	lea	di, pathBuffer			; es:di = path buffer
if DBCS_PCGEOS
	call	LocalStringLength		;cx <- length w/o NULL
else
	push	di
	mov	cx, -1
	mov	al, 0				; find null-terminator
	repne scasb
	not	cx				; cx = length
	dec	cx				; cx = length w/o null
	pop	di				; es:di = remaining path buffer
endif
	jcxz	doneWithCurDirJCXZ		; null-path (root?)
if ERROR_CHECK
SBCS <	cmp	{byte} es:[di], C_BACKSLASH				>
DBCS <	cmp	{wchar} es:[di], C_BACKSLASH				>
	ERROR_NE	OL_ERROR
endif
	LocalNextChar esdi			; skip leading '\'
	dec	cx				; skip leading '\'
doneWithCurDirJCXZ:
;	jcxz	doneWithCurDir
;too far away :(
	tst	cx
	LONG jz	doneWithCurDir
	mov	mostRecentGenItem.handle, 0	; no GenItem created yet
showCDElementLoop:
	;
	; extract path element
	;	es:di = remaining path buffer to look at
	;	cx = remaining #chars in path buffer (w/o null)
	;	mostRecentGenItem = previously created GenItem
	;
;	jcxz	doneWithCurDirSetSelection	; no more chars to check
;too far away
	tst	cx
	LONG jz	doneWithCurDirSetSelection
	mov	dx, di				; dx = start of element
	LocalLoadChar ax, C_BACKSLASH		; find root slash	>
	LocalFindChar				; repne scasb/scasw
	pushf					; save flag: Z=0 -> last element
	jnz	10$				; no '\' to skip on last element
	LocalPrevChar esdi			; backup to '\'
10$:
	push	es:[di]				; save character
	pushdw	esdi				; save character offset
	push	cx				; save remaining char count
SBCS <	mov	{byte} es:[di], 0		; temporarily null-terminate >
DBCS <	mov	{wchar} es:[di], 0		; temporarily null-terminate >
	;
	; create popup list item and add to popup list
	;	es:dx = this element in path buffer (null-terminated)
	;
	; first, if we have a virtual path, check if this element is at or
	; below that virtual path in the directory tree.  If not, don't create
	; an item for it
	;	es:dx = this element in path buffer (null-terminated)
	;
	tst	curDirIsVirtualRoot		; is cur dir under virtual root?
	jz	createThisElement		; nope, create this element
	mov	si, fsChunk			; *ds:si = OLFileSelector
	call	OLFSHaveVirtualRoot		; ds:bx = GenFilePath
EC <	ERROR_NC	OL_ERROR					>
	mov	cx, ds:[bx].GFP_disk		; cx = virtual root StdPath
	lea	si, ds:[bx].GFP_path		; ds:si = virtual root tail
	tst	virtualRootSeen			; have we seen virtual root
						;	pass by yet?
	jnz	createThisElement		; yes, create this element
	lea	di, pathBuffer			; es:di = full path up to this
						;	element (null-term'ed)
	push	dx
	mov	dx, fcfpDiskHandle		; dx = disk handle for full path
if _ISUI
	call	OLFSFileComparePathsEvalLinks
else
	call	FileComparePaths		; al = PathCompareType
endif
	pop	dx
	cmp	al, PCT_EQUAL
	jne	skipThisElement
	mov	virtualRootSeen, TRUE		; else, set flag to create
						;	subsequent path elements
						;	and fall through to
						;	create this one
createThisElement:
	;
	; now, really create the item
	;	es:dx = this element in path buffer (null-terminated)
	;
	push	es, dx				; save path element
	mov	bx, uiBlock			; ^lbx:si = popup list
	mov	si, offset OLFileSelectorChangeDirectoryPopup
	mov	cx, identifier		; use identifier as ident
	mov	ax, childCount
	call	OLFSCreateCurDirItem		; ^lbx:si = new GenItem
	inc	childCount
	movdw	mostRecentGenItem, bxsi
	pop	cx, dx				; cx:dx = path element
	call	OLFSReplaceVisMonikerText	; (preserves bp)
skipThisElement:
	pop	cx				; restore remaining char count
	popdw	esdi				; restore character offset
	pop	es:[di]				; restore character
	LocalNextChar esdi			; skip back over '\'
	inc	identifier			; bump element cnt for next time
	popf					; restore all-done flag
	LONG jz	showCDElementLoop		; if not done, continue
doneWithCurDirSetSelection:
	movdw	bxsi, mostRecentGenItem
EC <	call	ECCheckLMemOD						>
	call	OLFSSelectGenItem		; make this the current
						;	selection
	tst	bx
	jz	doneWithCurDir			; no further path elements found
	mov	atRoot, FALSE

doneWithCurDir:
	;
	; tack on another item for the currently selected directory, if any
	;
	mov	si, fsChunk			; *ds:si = OLFileSelector
	call	OLFSGetFileListSelection	; cx = selection number
	jcxz	done				; first entry selected, done
	cmp	cx, GIGS_NONE			; no selection , done
	je	done
	call	OLFSDeref_SI_Spec_DI		; ds:di = specific instance
	dec	cx				; adjust to file buffer index
	call	OLFSDerefIndexBuffer		; si = offset into file buffer
	mov	bx, ds:[di].OLFSI_fileBuffer	; lock file buffer
	call	OLFSMemLock_ES			; es:si = file entry
						; (ds would be quicker, but we
						; need fixupable DS in
						; OLFSCreateAndInitGenItem)
	test	es:[si].OLFSE_fileAttrs, mask FA_SUBDIR
	jz	doneUnlock			; not subdir, done
	lea	dx, es:[si].OLFSE_name		; dx = offset to dir name
	push	bx
	mov	bx, uiBlock			; ^lbx:si = parent popup list
	mov	si, offset OLFileSelectorChangeDirectoryPopup
	mov	cx, identifier
	mov	ax, childCount
	call	OLFSCreateCurDirItem		; ^lbx:si = new GenItem
	inc	childCount
	inc	identifier

	mov	cx, es				; cx:dx = directory name
	call	OLFSReplaceVisMonikerText	; (preserves bp)
	call	OLFSSelectGenItem		; make this the current
						;	selection
	pop	bx				; restore file buffer
doneUnlock:
	call	MemUnlock			; unlock file buffer
done:
	mov	cx, childCount
	mov	bx, uiBlock
	mov	si, offset OLFileSelectorChangeDirectoryPopup
	call	OLFSDestroyListChildren

	;
	; disable document button if current directory is document directory
	;
	mov	si, fsChunk
if FSEL_HAS_DOCUMENT_BUTTON
	mov	dx, fcfpDiskHandle		; dx = cur disk handle
	segmov	es, ss				; es:di = cur path
	lea	di, pathBuffer
	call	OLFSDisableDocButtonIfDocDir
endif
	;
	; disable close-directory button if current directory is root and
	; root entry (first entry) is selected
	;
	mov	dx, atRoot
	call	OLFSDisableCloseAndChangeDirectoryButtonsIfFirstEntryAndIsRoot
	.leave
	ret
OLFSShowCurrentDir	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFSCreateCurDirItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a child of the
		OLFileSelectorChangeDirectoryPopup, unless a child
		already exists that can be reused.

CALLED BY:	OLFSShowCurrentDir

PASS:		ax - child count for item
		cx - identifier of item
		ds - fixupable block
		^lbx:si - GenItemGroup (OLFileSelectorChangeDirectoryPopup)

RETURN:		ds - fixed up
		^lbx:si - new GenItem

DESTROYED:	ax,cx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/ 3/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLFSCreateCurDirItem	proc near
		uses	dx

itemGroup	local	optr	push	bx, si
identifier	local	word	push	cx
childCount	local	word	push	ax

		.enter

	;
	; If a child already exists at this position, then see if we
	; can reuse it.
	;
		mov_tr	cx, ax		; child position
		mov	ax, MSG_GEN_FIND_CHILD_AT_POSITION
		call	objMessageCallFixupDS

		jnc	reuse

create:
		mov	cx, ss:[identifier]
		call	OLFSCreateAndInitGenItem
done:
		.leave
		ret
reuse:

	;
	; Make sure the child at this position has the right
	; identifier.  Otherwise, the list has probably changed,
	; and we should nuke everything from this child onwards.
	;
		mov	bx, cx
		mov	si, dx
		mov	ax, MSG_GEN_ITEM_GET_IDENTIFIER
		call	objMessageCallFixupDS
		cmp	ax, ss:[identifier]

		je	done

	;
	; There's a mismatch.  Nuke everything from this child
	; onwards, and then create this one fresh.
	;
		mov	cx, ss:[childCount]
		movdw	bxsi, ss:[itemGroup]
		call	OLFSDestroyListChildren
		jmp	create

objMessageCallFixupDS:
		push	bp
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		pop	bp
		retn

OLFSCreateCurDirItem	endp


OLFSSelectGenItem	proc	near
	uses	bp
	.enter
	mov	ax, MSG_GEN_ITEM_GET_IDENTIFIER
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			; ax = identifier
	mov_tr	cx, ax				; cx = identifier
	mov	si, offset OLFileSelectorChangeDirectoryPopup
	call	OLFSSetGenItemSelection
	.leave
	ret
OLFSSelectGenItem	endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFSDestroyListChildren
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	clobber all children

CALLED BY:	INTERNAL
			OLFSShowCurrentDir
			OLFSBuildChangeDrivePopup

PASS:		^lbx:si - object whose children should be clobbered
		cx - position at which to start destroying

RETURN:		nothing

DESTROYED:	ax, cx, dx, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/25/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	not SINGLE_DRIVE_DOCUMENT_DIR and (FSEL_HAS_CHANGE_DRIVE_POPUP or FSEL_HAS_CHANGE_DIRECTORY_POPUP)

OLFSDestroyListChildren	proc	near
	uses	bp
	.enter

destroyLoop:
	push	cx				; position
	mov	ax, MSG_GEN_FIND_CHILD_AT_POSITION
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			; ^lcx:dx = child
	jc	done
	push	bx, si
	mov	bx, cx				; ^lbx:si = child
	mov	si, dx
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	clr	bp
	mov	ax, MSG_GEN_DESTROY
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	bx, si				; ^lbx:si = popup list
	pop	cx				; position
	jmp	destroyLoop
done:
	pop	cx
	.leave
	ret
OLFSDestroyListChildren	endp

endif



if not _FILE_TABLE
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFileSelectorRequestMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	dynamic list wants a moniker

CALLED BY:	MSG_META_GEN_LIST_REQUEST_ENTRY_MONIKER

PASS:		*ds:si - instnace of OLFileSelector
		ds:di - OLFileSelectorInstance
		^lcx:dx - dynamic list
		bp - position of moniker needed

RETURN:

DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	01/26/90	Initial version
	brianc	4/91		Completed 2.0 revisions
	chris	4/ 2/92		Rewritten for GenItemGroup
	brianc	9/92		Usability changes for 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLFileSelectorRequestMoniker	method	dynamic OLFileSelectorClass, \
					MSG_OL_FILE_SELECTOR_ITEM_QUERY

if _DUI
	mov	ax, di
	mov	di, 1500
	call	ThreadBorrowStackSpace
	push	di
	mov	di, ax
endif

listEntryNum	local	word	push	bp
fsChunk		local	word	push	si
fileEntry	local 	OLFileSelectorEntry
gstringOptr	local	optr
rimf		local	ReplaceItemMonikerFrame
olfsState	local	OLFileSelectorState
if _DUI
gstate		local	hptr
dateTime	local	DATE_TIME_BUFFER_SIZE dup (TCHAR)
endif

	.enter

	;
	; make sure we have some UI, could be none if we've been unbuilt
	; immediately after coming up on screen (and generating moniker
	; requests) - brianc 6/28/93
	;
	tst	ds:[di].OLFSI_uiBlock
	LONG jz	done

EC <	cmp	cx, ds:[di].OLFSI_uiBlock				>
EC <	ERROR_NZ	OL_FILE_SELECTOR_OBJECT_MISMATCH		>
EC <	cmp	dx, offset OLFileSelectorFileList			>
EC <	ERROR_NZ	OL_FILE_SELECTOR_OBJECT_MISMATCH		>

	mov	ax, ds:[di].OLFSI_state
	mov	olfsState, ax			; save flags for later


	mov	cx, listEntryNum		; cx = entry number requested
						; showing parent dir?
	test	olfsState, mask OLFSS_SHOW_PARENT_DIR
	LONG jz	useActualBufferEntry		; no, then always use buffer
	tst	cx				; looking for first entry?
	LONG jnz	useBufferEntry
	;
	; first entry will be current directory, stuff our local buffer
	; with the current directory's info (may be root, in which case, we
	; use FA_VOLUME flag to get a drive icon)
	;
if HAVE_FAKE_FILE_SYSTEM
	call	OLFSDeref_SI_Gen_DI
	test	ds:[di].GFSI_fileCriteria, mask FSFC_USE_FAKE_FILE_SYSTEM
	jnz	useFakeFS
endif
	mov	ax, ATTR_GEN_PATH_DATA
	mov	dx, TEMP_GEN_PATH_SAVED_DISK_HANDLE
	call	GenPathFetchDiskHandleAndDerefPath	; ax = disk handle
	lea	si, ds:[bx].GFP_path		; ds:si = path tail
	mov	bx, ax				; bx = disk handle
	mov	cx, PATH_BUFFER_SIZE
	sub	sp, cx
	segmov	es, ss				; es:di = path buffer
	mov	di, sp
	mov	dx, 0				; no drive name
	call	FileConstructFullPath		; build full text of path
EC <	ERROR_C	OL_ERROR			; should not overflow	>

havePath:
						; es:di = null at end

	; was a bug because cx = # chars but es:di pointed to null so
	; it wouldn't check the very first char in the path. --JimG 10/21/99
	LocalPrevChar esdi			; es:di now pts at last char
	LocalLoadChar ax, C_BACKSLASH
	std					; search backwards
	LocalFindChar				; es:di = points at char before
						;	'\' that starts
						;	current directory's
						;	path element
	cld					; restore direction
EC <	ERROR_NE	OL_ERROR >		; must be found as '\' starts
						;	path

	; (es:di may point to char BEFORE string if no \ or the \ was the
	; first char.. but that's ok since we advance to next char here.)
	;  --JimG
	LocalNextChar esdi			; point to '\'
	LocalNextChar esdi			; point to start of current
						;	directory's path element
SBCS <	tst	{byte}es:[di]			; if null, cur dir is root >
DBCS <	tst	{wchar}es:[di]			; if null, cur dir is root >
	jz	buildRootEntry			; build root entry
	push	ds
	segmov	ds, es				; ds:si = name of cur dir
	mov	si, di
	segmov	es, ss				; es:di = name field in local
	lea	di, fileEntry.OLFSE_name	;		buffer
	mov	cx, length fileEntry.OLFSE_name
	LocalCopyNString			; copy over name  rep movsb/w
	pop	ds
haveFirstEntryName::
	mov	fileEntry.OLFSE_fileAttrs, mask FA_SUBDIR
	;OLFSE_fileFlags not used for FA_SUBDIR
haveFirstEntry:
	add	sp, PATH_BUFFER_SIZE
	jmp	haveFileEntry

if HAVE_FAKE_FILE_SYSTEM
	;
	; get the fake path.  We may be getting a volume name, or the
	; dir name.  We know it's a volname if it is backslash
	; terminated
	;
useFakeFS:
	mov	ax, MSG_GEN_FILE_SELECTOR_FAKE_PATH_GET
	sub	sp, PATH_BUFFER_SIZE
	mov	cx, ss
	mov	dx, sp
	call	ObjCallInstanceNoLock
	movdw	esdi,cxdx
	clr	bx

SBCS<	cmp	{byte}es:[di].-1, C_BACKSLASH				>
DBCS<	cmp	es:[di].-2. C_BACKSLASH				>
	jne	havePath
	jmp	getFakeVolume
endif

buildRootEntry:
	;
	; build '<drive name>:<volume name>\' entry for root
	;	bx = disk handle
	;
						; just in case
	mov	{word} fileEntry.OLFSE_name, '\\' or (0 shl 8)
DBCS <	mov	{wchar}fileEntry.OLFSE_name[2], 0			>
	mov	fileEntry.OLFSE_fileAttrs, mask FA_VOLUME
	call	DiskGetDrive			; al = drive #
	call	DriveGetStatus			; ah = status

;EC <	ERROR_C	OL_ERROR			; not present!?		>
	LONG jc	done

	mov	fileEntry.OLFSE_fileFlags.high, ah
	segmov	es, ss				; es:di = buffer
	lea	di, fileEntry.OLFSE_name
	mov	cx, size fileEntry.OLFSE_name	; cx = buffer size
	mov	dx, mask SDAVNF_PASS_DISK_HANDLE or mask SDAVNF_TRAILING_SLASH
	call	OLFSStuffDriveAndVolumeName
	jmp	short haveFirstEntry

if HAVE_FAKE_FILE_SYSTEM
getFakeVolume:
	;
	; Ok, that pathname work was wasted..  put the volume name in
	; the OLFSE_name thing manually..  also must set some bits so
	; people know its a volume
	;
	mov	{word} fileEntry.OLFSE_name, '\\'
	mov	fileEntry.OLFSE_fileAttrs, mask FA_VOLUME
	push	cx, bp
	mov	ax, MSG_GEN_FILE_SELECTOR_FAKE_VOLUME_NAME_GET
	clr	cx				; get current drive
	mov	dx, ss
	lea	bp, fileEntry.OLFSE_name
	call	ObjCallInstanceNoLock
	pop	cx, bp
	mov	fileEntry.OLFSE_fileFlags.high, DRIVE_FIXED or mask DS_PRESENT
	tst	ax
	jz	haveFirstEntry
	add	sp, PATH_BUFFER_SIZE
	jmp	done
endif ;HAVE_FAKE_FILE_SYSTEM

useBufferEntry:
	dec	cx				; convert to buffer entry #
useActualBufferEntry:

	cmp	cx, ds:[di].OLFSI_numFiles
	LONG jae	done			; beyond end of files, done

	tst	ds:[di].OLFSI_fileBuffer	; don't ask - brianc 6/29/93
	LONG jz	done

	;
	; get entry from buffer and copy into our local buffer
	;	cx = buffer entry desired
	;	ds:[di] = OLFileSelectorInstance
	;
	push	ds
	call	OLFSDerefIndexBuffer		; si = offset in file buffer
	mov	bx, ds:[di].OLFSI_fileBuffer	; lock file buffer
	call	MemLock
	mov	ds, ax				; ds:si = entry to get
	segmov	es, ss				; es:di = local buffer
	lea	di, fileEntry
	mov	cx, size fileEntry
	rep movsb				; copy over
	call	MemUnlock			; unlock file buffer
	pop	ds
haveFileEntry:
	;
	; allocate a LMem block to hold the gstring chunk we are going to
	; create
	;
	mov	ax, LMEM_TYPE_GENERAL
	mov	cx, 0				; default header
	call	MemAllocLMem			; bx = block handle
	mov	gstringOptr.handle, bx
	mov	cl, GST_CHUNK
	call	GrCreateGString			; di = gstring handle
	mov	gstringOptr.chunk, si		; si = chunk
if _DUI	;=====================================================================
	;
	; skip the file index number if minimizing width
	;
	push	ds				; must have DS on stack
						;	if we branch out
	mov	si, fsChunk			; *ds:si = file selector
	mov	ax, HINT_FILE_SELECTOR_MINIMIZE_WIDTH
	call	ObjVarFindData
	segmov	ds, ss				; need ds = locals for
	LONG jc	afterColumnation		;	afterColumnation
	;
	; inset
	;
	mov	dx, OLFS_ITEM_X_INSET
	clr	cx
	clrdw	bxax
	call	GrRelMoveTo
	;
	; draw entry number
	;	(for simplicity, we assume there'll be 99 or less files,
	;	 as spec'ed)
	;
	push	ds, es
	mov	dx, listEntryNum		; 0-based
	inc	dx				; 1-based
	sub	sp, UHTA_NULL_TERM_BUFFER_SIZE
	mov	si, di				; si = gstate
	segmov	es, ss, di
	mov	di, sp				; es:di = buffer
	push	di				; save buffer start
	cmp	dx, 100
	jae	havePadding
	LocalLoadChar	ax, C_SPACE
	LocalPutChar	esdi, ax
	cmp	dx, 10
	jae	havePadding
	LocalPutChar	esdi, ax
havePadding:
	mov	ax, dx
	clr	dx				; dxax = number
	mov	cx, mask UHTAF_NULL_TERMINATE
	call	UtilHex32ToAscii
	mov	di, si				; di = gstate
	segmov	ds, es, si
	pop	si				; ds:si = buffer start
	clr	cx				; null-terminated
	call	GrDrawTextAtCP
	add	sp, UHTA_NULL_TERM_BUFFER_SIZE
	pop	ds, es
	;
	; draw secret icon, if needed
	;
	mov	dx, GFS_ICON_SPACING
	clr	cx
	clrdw	bxax
	call	GrRelMoveTo
	mov	dx, GFS_SECRET_ICON_WIDTH	; in case not secret
	test	fileEntry.OLFSE_fileFlags, mask GFHF_HIDDEN
	jnz	hidden
						; must have DS on stack
	add	dx, GFS_ICON_SPACING		; spacing btwn icon and name
	jmp	afterBitmap

hidden:
	pop	ds				; don't need DS on stack
	mov	si, offset secretIconBitmap
else ;========================================================================
	;
	; draw in bitmap and name
	;
	mov	si, offset narrowFolderIconBitmap

	test	olfsState, mask OLFSS_SHOW_PARENT_DIR	; showing parent dir?
	jz	haveFolderBitmap		; nope, use bland folder
	mov	si, offset folderIconBitmap	; else indented folder
	tst	listEntryNum			; first entry?
	jnz	haveFolderBitmap		; nope, got correct bitmap
	mov	si, offset openFolderIconBitmap	; else, use open folder
haveFolderBitmap:
	test	fileEntry.OLFSE_fileAttrs, mask FA_SUBDIR

	jnz	haveBitmap
useDefault::
	mov	si, offset narrowFileIconBitmap
	test	olfsState, mask OLFSS_SHOW_PARENT_DIR	; showing parent dir?
	jz	haveFileBitmap			; nope, use bland file
	mov	si, offset fileIconBitmap	; else, use indented file
haveFileBitmap:
	test	fileEntry.OLFSE_fileAttrs, mask FA_VOLUME
	jz	haveBitmap			; not subdir nor volume, file
	;
	; handle volume (DriveStatus is in high byte of OLFSE_fileFlags)
	;
	mov	al, fileEntry.OLFSE_fileFlags.high
	andnf	al, mask DS_TYPE
.assert (offset DS_TYPE eq 0)
	mov	si, offset disk525IconBitmap
	cmp	al, DRIVE_5_25
	je	haveBitmap
	mov	si, offset disk35IconBitmap
	cmp	al, DRIVE_3_5
	je	haveBitmap
	mov	si, offset diskPCMCIAIconBitmap
	cmp	al, DRIVE_PCMCIA
	je	haveBitmap
	mov	si, offset diskHDIconBitmap
	cmp	al, DRIVE_FIXED
	je	haveBitmap
	cmp	al, DRIVE_CD_ROM
	je	haveBitmap
	mov	si, offset diskRamIconBitmap
EC <	cmp	al, DRIVE_RAM						>
EC <	ERROR_NZ	OL_FILE_SELECTOR_DRIVE_TYPE_UNKNOWN		>

haveBitmap:
endif ; _DUI ================================================================
	push	ds

NOFXIP<	segmov	ds, cs				; ds:si = bitmap	>

FXIP <	push	bx, ax							>
FXIP <	mov	bx, handle RegionResourceXIP				>
FXIP <	call	MemLock							>
FXIP <	mov	ds, ax				; ds:si = bitmap	>
FXIP <	pop	bx, ax							>



	clr	dx				; no bitmap-drawing callback

	; di - Handle of the GState used for drawing.
	; ds:si - Address of the bitmap to be drawn.
	; dx:cx - Address of the callback routine. If you are not supplying a
	; callback, pass zero in **dx**. It is unusual to use your own
	; callback routine.
	; call	GrFillBitmapAtCP		; draw into chunk

	; di - Handle of the GState used for drawing.
	; ax, bx - X, Y coordinates to begin drawing at.
	; ds:si - Address of the bitmap.
	; dx:cx - Address of the callback routine. If you are not supplying a
	; callback, pass zero in **dx**.
	; mov	ax, 0
	; mov	bx, 0
	call	GrDrawBitmapAtCP

	mov	dx, ds:[si].B_width
	add	dx, GFS_ICON_SPACING		; spacing btwn icon and name

FXIP <	mov	bx, handle RegionResourceXIP				>
FXIP <	call	MemUnlock						>

afterBitmap::			; MUST have DS on stack
	clr	cx

	clrdw	bxax

	call	GrRelMoveTo			; space between bitmap and name

if _DUI
	;
	; If we've got HINT_FILE_SELECTOR_MINIMIZE_WIDTH, then don't
	; columnate the date/time info.  (jmagasin 9/18/95)
	;
	pop	ds				; DS must be on stack
	push	ds
	mov	si, fsChunk			; *ds:si = file selector
	mov	ax, HINT_FILE_SELECTOR_MINIMIZE_WIDTH
	call	ObjVarFindData
endif	;_RUDY or _DUI

	segmov	ds, ss

if _DUI

	LONG	jc	afterColumnation	; Hint -> don't columnate.

	;
	; The following code will draw a modifiaction date and time column
	; for the Rudy spui.  The file selector entry will look something
	; like this:
	;
	;	This is a file name		12.12.95   12.12

	;
	; If we are dealing with a subdir, a read-only file or a hidden file
	; then we don't need to display the modification date and time.
	;
	test	ss:[fileEntry].OLFSE_fileAttrs, \
		mask FA_SUBDIR or mask FA_RDONLY or mask FA_HIDDEN
	LONG jnz afterColumnation

	;
	; We only want to display the modification column for document files
	; so we bail if the current file is a GEOS executable.
	;
	cmp	ss:[fileEntry].OLFSE_fileType, GFT_EXECUTABLE
	LONG je	afterColumnation

	;
	; Get the modification date, if it's zero we are dealing with a
	; file that we can't display the modification date/time for.
	;
	mov	ax, ss:[fileEntry].OLFSE_modification.FDAT_date
	tst	ax
	LONG jz	afterColumnation

if _DUI	;------------------------------------------------------------------

	;
	; Create a modification date buffer.
	;	ax = FDAT_date
	;
	mov	bx, ss:[fileEntry].OLFSE_modification.FDAT_time
	push	es, di
	segmov	es, ss
	lea	di, ss:[dateTime]
	mov	si, DTF_ZERO_PADDED_SHORT
	call	LocalFormatFileDateTime
	pop	es, di				; di <- gstate
	;
	; Find out how wide the date column is.
	;
	clr	cx				; null-terminated
	lea	si, ss:[dateTime]
	call	GrTextWidth			; dx <- width
	;
	; We need to clip the file name to prevent it from overwriting the
	; the modification date column.
	;
	push	dx
	mov	si, GFMI_MAX_ADJUSTED_HEIGHT
	call	GrFontMetrics	; dx <- height, ah <- frac
	call	GrGetCurPos	; ax <- x pos, bx <- y pos
	clr	ax		; for some reason x pos clips the first char
	add	dx, bx		; dx <- bottom
	mov	cx, OLFS_DATE_COLUMN_RIGHT_OFFSET
	sub	cx, GFS_ICON_SPACING		; some spacing
	pop	si				; si = date width
	sub	cx, si				; cx = name right
	push	cx				; save name right
	mov	si, PCT_REPLACE
	call	GrSetClipRect
	;
	; Draw the file name first.
	;
	lea	si, ss:[fileEntry].OLFSE_name	; ds:si = filename
	clr	cx				; null-terminated
	call	GrDrawTextAtCP
	;
	; Reset the clip rect.
	;
	mov	si, PCT_NULL
	call	GrSetClipRect
	;
	; Draw the modification time column.
	;
	call	GrGetCurPos			; bx = y pos
	pop	ax				; ax = name right
	add	ax, GFS_ICON_SPACING		; ax = date left
	call	GrMoveTo
	lea	si, ss:[dateTime]
	clr	cx				; null-terminated
	call	GrDrawTextAtCP			; draw date/time

else	;------------------------------------------------------------------

	;
	; We need to clip the file name to prevent it from overwriting the
	; the modification date/time column.
	;
	push	ax
	mov	si, GFMI_MAX_ADJUSTED_HEIGHT
	call	GrFontMetrics	; dx <- height, ah <- frac
	call	GrGetCurPos	; ax <- x pos, bx <- y pos
	add	dx, bx		; dx <- bottom
	mov	cx, OLFS_DATE_COLUMN_LEFT_OFFSET - \
		    RUDY_FILE_SELECTOR_TEXT_X_OFFSET
	mov	si, PCT_REPLACE
	call	GrSetClipRect
	pop	ax

	;
	; Draw the file name first, underlining the first <matchLength>
	; characters.
	;
	call	drawUnderlinedName

	;
	; Reset the clip rect.
	;
	mov	si, PCT_NULL
	call	GrSetClipRect

	;
	; Change the font for the modification date/time column.
	;
	push	dx
	clr	cx
	clr	ax
	mov	dx, RUDY_FILE_SELECTOR_FONT_SIZE; dx.ah = font size
	call	GrSetFont
	pop	dx

	;
	; Create a modification date buffer.
	;
	mov	ax, ss:[fileEntry].OLFSE_modification.FDAT_date
	mov	bx, ss:[fileEntry].OLFSE_modification.FDAT_time
	push	es, di
	segmov	es, ss
	lea	di, ss:[dateTime]
	mov	si, DTF_ZERO_PADDED_SHORT
	call	LocalFormatFileDateTime
	pop	di				; di <- gstate

	;
	; Draw the modification date column.
	;
	push	ax, bx
	call	GrGetCurPos
	mov	ax, OLFS_DATE_COLUMN_LEFT_OFFSET
	call	GrMoveTo
	lea	si, ss:[dateTime]
	clr	cx				; null-terminated
	call	GrDrawTextAtCP			; draw date/time
	pop	ax, bx

	;
	; Get the modification time.
	;
	push	di				; save gstate
	lea	di, ss:[dateTime]
	mov	si, DTF_HM
	call	LocalFormatFileDateTime
	pop	es, di				; di <- gstate

	;
	; Find out how wide the time column is.
	;
	clr	cx				; null-terminated
	lea	si, ss:[dateTime]
	call	GrTextWidth			; dx <- width

	;
	; Draw the modification time column.
	;
	call	GrGetCurPos
	mov	ax, OLFS_TIME_COLUMN_RIGHT_OFFSET
	sub	ax, dx				; right edge is justified
	call	GrMoveTo
	lea	si, ss:[dateTime]
	clr	cx				; null-terminated
	call	GrDrawTextAtCP			; draw date/time

endif ; _DUI ---------------------------------------------------------------

	clc					; indicate name drawn
	jnc	afterName			; name was drawn

afterColumnation:
endif	; _RUDY or _DUI
	lea	si, fileEntry.OLFSE_name	; ds:si = filename
	clr	cx				; null-terminated
	call	GrDrawTextAtCP

afterName::
	call	GrEndGString			; end gstring
	mov	si, di				; si = gstring
	clr	di				; no gstate
	mov	dl, GSKT_LEAVE_DATA		; leave chunk
	call	GrDestroyGString
	pop	ds
	;
	; send gstring to item as it's moniker
	;
	mov	ax, gstringOptr.handle
	mov	rimf.RIMF_source.high, ax
	mov	ax, gstringOptr.chunk
	mov	rimf.RIMF_source.low, ax
	mov	rimf.RIMF_sourceType, VMST_OPTR
	mov	rimf.RIMF_dataType, VMDT_GSTRING
	mov	rimf.RIMF_length, 0		; use full chunk size
	mov	rimf.RIMF_width, 0		; let system compute size
	mov	rimf.RIMF_height, 0
	mov	ax, listEntryNum
	mov	rimf.RIMF_item, ax		; item #
	mov	rimf.RIMF_itemFlags, 0		; not disabled
	mov	si, fsChunk
	call	OLFSDeref_SI_Spec_DI		; ds:di = spec instance
	mov	bx, ds:[di].OLFSI_uiBlock	; bx = ui block
if FSEL_DISABLES_FILTERED_FILES	;---------------------------------------------
	;
	; see if file was rejected by filter routine
	;
	mov	cx, ds:[di].OLFSI_numRejects
	jcxz	noRejects
	mov	ax, ds:[di].OLFSI_rejectList
	tst	ax
	jz	noRejects
	push	bx, es
	mov_tr	bx, ax
	call	MemLock
	mov	es, ax			; es:di = first FileID in reject list
	clr	di
	mov	dx, fileEntry.OLFSE_id.high	; dx:ax = our FileID
	mov	ax, fileEntry.OLFSE_id.low
checkRejectLoop:
	cmp	({FileID}es:[di]).high, dx
	jne	tryNext
	cmp	({FileID}es:[di]).low, ax
	je	unlockDisable		; found in reject list, disable (C clr)
tryNext:
	add	di, size FileID		; move to next FileID
	loop	checkRejectLoop
	stc				; not in reject list
unlockDisable:
	call	MemUnlock		; unlock reject list (saves flags)
	pop	bx, es
	jnc	disable
noRejects:
endif	;---------------------------------------------------------------------
	call	OLFSDeref_SI_Gen_DI		; ds:di = gen instance
	test	ds:[di].GFSI_attrs, mask FSA_SHOW_FILES_DISABLED
	jz	haveItemFlags
	test	fileEntry.OLFSE_fileAttrs, mask FA_SUBDIR or mask FA_VOLUME
	jnz	haveItemFlags			; not file, leave enabled
						; else file, disable it
disable:
	mov	rimf.RIMF_itemFlags, mask RIMF_NOT_ENABLED
haveItemFlags:
	push	bp
	lea	bp, rimf
	mov	dx, size rimf
	mov	si, offset OLFileSelectorFileList ; ^lbx:si = dynamic list
	mov	di, mask MF_CALL or mask MF_STACK
	mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_MONIKER
	call	ObjMessage
	pop	bp
	;
	; free gstring block
	;
	mov	bx, gstringOptr.handle
	call	MemFree
done:
	.leave

if _DUI
	pop	di
	call	ThreadReturnStackSpace
endif

	ret


OLFileSelectorRequestMoniker	endm
else

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFileSelectorRequestMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Table object wants to draw its entry. So tell it what to draw

CALLED BY:	OLFSTableQueryDraw

PASS:		*ds:si - instnace of OLFileSelector
		ds:di - OLFileSelectorInstance
		bp - position of moniker needed
RETURN:
		^hcx	= OLFileSelectorEntry (The table object is suppose to
				free this block.)
DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	01/26/90	Initial version
	brianc	4/91		Completed 2.0 revisions
	chris	4/ 2/92		Rewritten for GenItemGroup
	brianc	9/92		Usability changes for 2.0
	clee	11/18/94	modified for Jedi
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLFileSelectorRequestMoniker	method	dynamic OLFileSelectorClass, \
					MSG_OL_FILE_SELECTOR_ITEM_QUERY

listEntryNum	local	word	push	bp
fsChunk		local	word	push	si
				clr	cx
fsEntryBH	local	hptr	push	cx
fileEntry	local	OLFileSelectorEntry
olfsState	local	OLFileSelectorState
	uses	dx, bp
	.enter

	;
	; make sure we have some UI, could be none if we've been unbuilt
	; immediately after coming up on screen (and generating moniker
	; requests) - brianc 6/28/93
	;
	tst	ds:[di].OLFSI_uiBlock
	LONG jz	done
EC <	cmp	cx, ds:[di].OLFSI_uiBlock				>
EC <	ERROR_NZ	OL_FILE_SELECTOR_OBJECT_MISMATCH		>
EC <	cmp	dx, offset OLFileSelectorFileList			>
EC <	ERROR_NZ	OL_FILE_SELECTOR_OBJECT_MISMATCH		>
	mov	ax, ds:[di].OLFSI_state
	mov	olfsState, ax			; save flags for later

	mov	cx, listEntryNum		; cx = entry number requested
						; showing parent dir?
	test	olfsState, mask OLFSS_SHOW_PARENT_DIR
	LONG jz	useActualBufferEntry		; no, then always use buffer
	tst	cx				; looking for first entry?
	LONG jnz	useBufferEntry
	;
	; first entry will be current directory, stuff our local buffer
	; with the current directory's info (may be root, in which case, we
	; use FA_VOLUME flag to get a drive icon)
	;
	mov	ax, ATTR_GEN_PATH_DATA
	mov	dx, TEMP_GEN_PATH_SAVED_DISK_HANDLE
	call	GenPathFetchDiskHandleAndDerefPath	; ax = disk handle
	lea	si, ds:[bx].GFP_path		; ds:si = path tail
	mov	bx, ax				; bx = disk handle
	mov	cx, PATH_BUFFER_SIZE
	sub	sp, cx
	segmov	es, ss				; es:di = path buffer
	mov	di, sp
	mov	dx, 0				; no drive name
	call	FileConstructFullPath		; build full text of path
EC <	ERROR_C	OL_ERROR			; should not overflow	>
						; es:di = null at end
	mov	al, '\\'
	std					; search backwards
	repne scasb				; es:di = points at char before
						;	'\' that starts
						;	current directory's
						;	path element
	cld					; restore direction
EC <	ERROR_NE	OL_ERROR >		; must be found as '\' starts
						;	path
	inc	di				; point to '\'
	inc	di				; point to start of current
						;	directory's path element
	tst	{byte}es:[di]			; if null, cur dir is root
	jz	buildRootEntry			; build root entry
	push	ds
	segmov	ds, es				; ds:si = name of cur dir
	mov	si, di
	segmov	es, ss				; es:di = name field in local
	lea	di, fileEntry.OLFSE_name	;		buffer
	mov	cx, size fileEntry.OLFSE_name
	rep movsb				; copy over name
	pop	ds
	mov	fileEntry.OLFSE_fileAttrs, mask FA_SUBDIR
	;OLFSE_fileFlags not used for FA_SUBDIR
haveFirstEntry:
	add	sp, PATH_BUFFER_SIZE
	jmp	haveFileEntry

buildRootEntry:
	;
	; build '<drive name>:<volume name>\' entry for root
	;	bx = disk handle
	;
						; just in case
	mov	{word} fileEntry.OLFSE_name, '\\' or (0 shl 8)
	mov	fileEntry.OLFSE_fileAttrs, mask FA_VOLUME
	call	DiskGetDrive			; al = drive #
	call	DriveGetStatus			; ah = status

;EC <	ERROR_C	OL_ERROR			; not present!?		>
	LONG jc	done

	mov	fileEntry.OLFSE_fileFlags.high, ah
	segmov	es, ss				; es:di = buffer
	lea	di, fileEntry.OLFSE_name
	mov	cx, size fileEntry.OLFSE_name	; cx = buffer size
	mov	dx, mask SDAVNF_PASS_DISK_HANDLE or mask SDAVNF_TRAILING_SLASH
	call	OLFSStuffDriveAndVolumeName
	jmp	short haveFirstEntry

useBufferEntry:
	dec	cx				; convert to buffer entry #
useActualBufferEntry:

	cmp	cx, ds:[di].OLFSI_numFiles
	LONG jae	done			; beyond end of files, done

	tst	ds:[di].OLFSI_fileBuffer	; don't ask - brianc 6/29/93
	LONG jz	done

	;
	; get entry from buffer and copy into our local buffer
	;	cx = buffer entry desired
	;	ds:[di] = OLFileSelectorInstance
	;
	call	OLFSDerefIndexBuffer		; si = offset in file buffer
	mov	bx, ds:[di].OLFSI_fileBuffer	; lock file buffer
	push	bx				; save it for unlock later
	call	MemLock
	mov	ds, ax				; ds:si = entry to get
	call	createFileTableStruct		; es = block seg. addr (locked)
						; ^hbx = allocated block
	clr	di				; es:di = beginning of block
	mov	cx, size OLFileSelectorEntry
	rep movsb				; copy over
	call	MemUnlock			; unlock allocated block
	mov	fsEntryBH, bx
	pop	bx				; ^hbx = file buffer
	call	MemUnlock			; unlock file buffer
haveFileEntry:
done:
	mov	cx, fsEntryBH			; ^hcx = allocated block

	.leave
	ret

createFileTableStruct:
	;
	; Alloc. a mem block to hold the OLFileSelectorEntry
	; PASS: nothing
	; RETURN: es	= seg. addr of the allocated block. (locked)
	;	  ^hbx  = allocated block
	;
	push	ax, cx
	mov	ax, size OLFileSelectorEntry
	clr	cl
	mov	ch, mask HAF_ZERO_INIT or mask HAF_LOCK or mask HAF_NO_ERR
	call	MemAlloc			;^hbx = allocated block
						;ax = block seg. addr.
						;cx trashed
	mov	es, ax				;es = block seg. addr.
	pop	ax, cx
	retn
OLFileSelectorRequestMoniker	endm
endif		; if not _FILE_TABLE

;
; icons for to distinguish files/directories and drive types
;

    GFS_NARROW_ICON_WIDTH = 16
    GFS_ICON_HEIGHT = 12		; note blank top line for aesthetics

GFS_WIDE_ICON_WIDTH = 32
if _DUI
GFS_ICON_SPACING = 5
else
GFS_ICON_SPACING = 2
endif

if _FXIP
FileSelector		ends
RegionResourceXIP	segment resource
endif

if not _DUI
fileIconBitmap	label	byte
		Bitmap <16,16,BMC_PACKBITS,BMF_4BIT or mask BMT_MASK>
	db	0x01, 0x00, 0x00
	db	0xf9, 0xdd
	db	0x01, 0x00, 0x00
	db	0xf9, 0xdd
	db	0x01, 0x1f, 0xf8
	db	0x01, 0xdd, 0xd1, 0xfd, 0x11, 0x01, 0x1d, 0xdd
	db	0x01, 0x1f, 0xf8
	db	0x01, 0xdd, 0xd1, 0xfd, 0xff, 0x01, 0x1d, 0xdd
	db	0x01, 0x1f, 0xf8
	db	0x01, 0xdd, 0xd1, 0xfd, 0xff, 0x01, 0x1d, 0xdd
	db	0x01, 0x1f, 0xf8
	db	0x01, 0xdd, 0xd1, 0xfd, 0xff, 0x01, 0x1d, 0xdd
	db	0x01, 0x1f, 0xf8
	db	0x01, 0xdd, 0xd1, 0xfd, 0xff, 0x01, 0x1d, 0xdd
	db	0x01, 0x1f, 0xf8
	db	0x01, 0xdd, 0xd1, 0xfd, 0xff, 0x01, 0x1d, 0xdd
	db	0x01, 0x1f, 0xf8
	db	0x01, 0xdd, 0xd1, 0xfd, 0xff, 0x01, 0x1d, 0xdd
	db	0x01, 0x1f, 0xf8
	db	0x01, 0xdd, 0xd1, 0xfd, 0xff, 0x01, 0x1d, 0xdd
	db	0x01, 0x1f, 0xf8
	db	0x01, 0xdd, 0xd1, 0xfd, 0xff, 0x01, 0x1d, 0xdd
	db	0x01, 0x1f, 0xf8
	db	0x01, 0xdd, 0xd1, 0xfd, 0xff, 0x01, 0x1d, 0xdd
	db	0x01, 0x1f, 0xf8
	db	0x01, 0xdd, 0xd1, 0xfd, 0xff, 0x01, 0x1d, 0xdd
	db	0x01, 0x1f, 0xf8
	db	0x01, 0xdd, 0xd1, 0xfd, 0x11, 0x01, 0x1d, 0xdd
	db	0x01, 0x00, 0x00
	db	0xf9, 0xdd
	db	0x01, 0x00, 0x00
	db	0xf9, 0xdd
endif

if	not _DUI
folderIconBitmap	label	byte
		Bitmap <15,13,0,BMF_4BIT or mask BMT_MASK>
	db	0x00, 0x00
	db	0xdd, 0xdd, 0xdd, 0xdd, 0xdd, 0xdd, 0xdd, 0xd8
	db	0x00, 0xf0
	db	0xdd, 0xdd, 0xdd, 0xdd, 0x88, 0x88, 0xdd, 0xd8
	db	0x01, 0xf8
	db	0xdd, 0xdd, 0xdd, 0xd8, 0xff, 0xff, 0x8d, 0xd8
	db	0x3f, 0xfc
	db	0xdd, 0x88, 0x88, 0x8f, 0xee, 0xee, 0xe8, 0xd8
	db	0x7f, 0xfc
	db	0xd8, 0xff, 0xff, 0xf7, 0x77, 0x77, 0x78, 0xd8
	db	0x7f, 0xfc
	db	0xd8, 0xfe, 0xee, 0xee, 0xee, 0xe7, 0x78, 0xd8
	db	0x7f, 0xfc
	db	0xd8, 0xfe, 0xee, 0xee, 0xee, 0x77, 0x78, 0xd8
	db	0x7f, 0xfc
	db	0xd8, 0xfe, 0xee, 0xee, 0xe7, 0x77, 0x78, 0xd8
	db	0x7f, 0xfc
	db	0xd8, 0xfe, 0xee, 0xee, 0xe7, 0x77, 0x78, 0xd8
	db	0x7f, 0xfc
	db	0xd8, 0xee, 0xee, 0xee, 0x77, 0x77, 0x78, 0xd8
	db	0x7f, 0xfc
	db	0xd8, 0x77, 0x77, 0x77, 0x77, 0x77, 0x78, 0xd8
	db	0x3f, 0xf8
	db	0xdd, 0x88, 0x88, 0x88, 0x88, 0x88, 0x8d, 0xd8
	db	0x00, 0x00
	db	0xdd, 0xdd, 0xdd, 0xdd, 0xdd, 0xdd, 0xdd, 0xd8
endif

if not _DUI
narrowFileIconBitmap	label	byte
	Bitmap <GFS_NARROW_ICON_WIDTH, GFS_ICON_HEIGHT, 0, BMF_MONO>
	byte	00000000b, 00000000b
	byte	00011111b, 11110000b
        byte    00010000b, 00010000b
        byte    00010111b, 11010000b
	byte    00010000b, 00010000b
	byte    00010111b, 11010000b
	byte    00010000b, 00010000b
	byte    00010111b, 11010000b
	byte    00010000b, 00010000b
	byte    00010111b, 11010000b
	byte    00010000b, 00010000b
	byte    00011111b, 11110000b
endif

if not _DUI

narrowFolderIconBitmap	label	byte
		Bitmap <15,13,0,BMF_4BIT or mask BMT_MASK>
	db	0x00, 0x00
	db	0xdd, 0xdd, 0xdd, 0xdd, 0xdd, 0xdd, 0xdd, 0xd8
	db	0x00, 0x78
	db	0xdd, 0xdd, 0xdd, 0xdd, 0xd8, 0x88, 0x8d, 0xd8
	db	0x00, 0xfc
	db	0xdd, 0xdd, 0xdd, 0xdd, 0x8f, 0xff, 0xf8, 0xd8
	db	0x1f, 0xfe
	db	0xdd, 0xd8, 0x88, 0x88, 0xfe, 0xee, 0xee, 0x88
	db	0x3f, 0xfe
	db	0xdd, 0x8f, 0xff, 0xff, 0x77, 0x77, 0x77, 0x88
	db	0x3f, 0xfe
	db	0xdd, 0x8f, 0xee, 0xee, 0xee, 0xee, 0x77, 0x88
	db	0x3f, 0xfe
	db	0xdd, 0x8f, 0xee, 0xee, 0xee, 0xe7, 0x77, 0x88
	db	0x3f, 0xfe
	db	0xdd, 0x8f, 0xee, 0xee, 0xee, 0x77, 0x77, 0x88
	db	0x3f, 0xfe
	db	0xdd, 0x8f, 0xee, 0xee, 0xee, 0x77, 0x77, 0x88
	db	0x3f, 0xfe
	db	0xdd, 0x8e, 0xee, 0xee, 0xe7, 0x77, 0x77, 0x88
	db	0x3f, 0xfe
	db	0xdd, 0x87, 0x77, 0x77, 0x77, 0x77, 0x77, 0x88
	db	0x1f, 0xfc
	db	0xdd, 0xd8, 0x88, 0x88, 0x88, 0x88, 0x88, 0xd8
	db	0x00, 0x00
	db	0xdd, 0xdd, 0xdd, 0xdd, 0xdd, 0xdd, 0xdd, 0xd8

openFolderIconBitmap	label	byte
		Bitmap <15,13,BMC_PACKBITS,BMF_4BIT or mask BMT_MASK>
	db	0x01, 0x00, 0x00
	db	0xfa, 0xdd, 0x00, 0xd8
	db	0x01, 0x00, 0x78
	db	0xfd, 0xdd, 0x03, 0xd8, 0x88, 0x8d, 0xd8
	db	0x01, 0x00, 0xfc
	db	0xfd, 0xdd, 0x03, 0x8f, 0xff, 0xf8, 0xd8
	db	0x01, 0x1f, 0xfe
	db	0x07, 0xdd, 0xd8, 0x88, 0x88, 0xfe, 0xee, 0xe7,
		0x88
	db	0x01, 0x3f, 0xfe
	db	0x07, 0xdd, 0x8f, 0xff, 0xff, 0xee, 0xee, 0x77,
		0x88
	db	0x01, 0x3f, 0xfe
	db	0x01, 0xdd, 0x8f, 0xfd, 0xee, 0x01, 0x77, 0x88
	db	0x01, 0x3f, 0xfe
	db	0x01, 0xdd, 0x8f, 0xfe, 0xee, 0x02, 0xe7, 0x77,
		0x88
	db	0x01, 0xff, 0xfe
	db	0xfb, 0x88, 0x01, 0x87, 0x88
	db	0x01, 0xff, 0xfe
	db	0x00, 0x87, 0xfc, 0x77, 0x01, 0x87, 0x88
	db	0x01, 0x7f, 0xfe
	db	0x00, 0xd8, 0xfc, 0x77, 0x01, 0x78, 0x88
	db	0x01, 0x7f, 0xfe
	db	0x00, 0xd8, 0xfc, 0x77, 0x01, 0x78, 0x88
	db	0x01, 0x3f, 0xfc
	db	0x00, 0xdd, 0xfb, 0x88, 0x00, 0xd8
	db	0x01, 0x00, 0x00
	db	0xfa, 0xdd, 0x00, 0xd8

disk525IconBitmap	label	byte
	Bitmap <GFS_NARROW_ICON_WIDTH, GFS_ICON_HEIGHT, 0, BMF_MONO>
	byte	00000000b, 00000000b
        byte    00011111b, 11111100b
	byte    00010000b, 11111100b
	byte    00011111b, 11111000b
	byte    00011111b, 11111100b
	byte    00011111b, 01111100b
	byte    00011110b, 00111100b
	byte    00011111b, 01111100b
	byte    00011111b, 11111100b
	byte    00011111b, 01111100b
	byte    00011111b, 01111100b
	byte    00011111b, 11111100b

disk35IconBitmap	label	byte
	Bitmap <GFS_NARROW_ICON_WIDTH, GFS_ICON_HEIGHT, 0, BMF_MONO>
	byte	00000000b, 00000000b
        byte    00011111b, 11111000b
	byte    00011101b, 01011000b
	byte    00011010b, 10111000b
	byte    00011101b, 01011000b
	byte    00011010b, 10111000b
	byte    00011111b, 11111000b
	byte    00011100b, 00011000b
	byte    00011101b, 00011000b
	byte    00011101b, 00011000b
	byte    00011100b, 00011000b
	byte    00001111b, 11111000b

diskHDIconBitmap	label	byte
	Bitmap <GFS_NARROW_ICON_WIDTH, GFS_ICON_HEIGHT, 0, BMF_MONO>
	byte	00000000b, 00000000b
        byte    00000111b, 11111110b
	byte    00001010b, 10101110b
	byte    00010101b, 01011110b
	byte    00101010b, 10111110b
	byte    01111111b, 11111110b
	byte    01000000b, 00111110b
	byte    01000000b, 00111110b
	byte    01000000b, 00111100b
	byte    01011000b, 00111000b
	byte    01000000b, 00110000b
	byte    01111111b, 11100000b

diskRamIconBitmap	label	byte
	Bitmap <GFS_NARROW_ICON_WIDTH, GFS_ICON_HEIGHT, 0, BMF_MONO>
	byte	00000000b, 00000000b
        byte    11111111b, 00000000b
        byte    10001111b, 00001110b
	byte    11111110b, 00011111b
	byte    11100111b, 00100111b
	byte    11100111b, 01111101b
	byte    11111110b, 10011101b
	byte    11100101b, 11110100b
	byte    11111101b, 11110100b
	byte    00000001b, 01010000b
	byte    00000001b, 01010000b
        byte    00000000b, 01000000b

diskPCMCIAIconBitmap	label	byte
	Bitmap <GFS_NARROW_ICON_WIDTH, GFS_ICON_HEIGHT, 0, BMF_MONO>
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
        byte    00000111b, 11100000b
	byte    00001000b, 00010000b
	byte    00001000b, 00010000b
	byte    00010000b, 00001000b
	byte    00010000b, 00001000b
	byte    00100000b, 00000100b
	byte    00111111b, 11111100b
	byte    00100000b, 00000100b
	byte    00111111b, 11111100b
        byte    00000000b, 00000000b
endif		; if ((not _JEDIMOTIF) and (not _DUI))

if _DUI

GFS_SECRET_ICON_WIDTH = 11
GFS_SECRET_ICON_HEIGHT = 11
secretIconBitmap	label	byte
	Bitmap <GFS_SECRET_ICON_WIDTH, GFS_SECRET_ICON_HEIGHT, 0, BMF_MONO>
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00110000b, 00000000b
	byte	01001010b, 10000000b
	byte	10000111b, 11000000b
	byte	10100000b, 01100000b
	byte	10110111b, 01100000b
	byte	10100000b, 11000000b
	byte	10000111b, 10000000b
	byte	01001000b, 00000000b
	byte	00110000b, 00000000b

endif

if _FXIP
RegionResourceXIP	ends
FileSelector		segment resource
endif





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFileSelectorChangeDrivePopupHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	switch to root directory of specified drive

CALLED BY:	INTERNAL

PASS:		*ds:si - OLFileSelector instance
		ax = MSG_OL_FILE_SELECTOR_CHANGE_DRIVE_POPUP
		cl = drive #
		ch = DriveStatus

RETURN:

DESTROYED:

		NOTE:  invalidates any chunk pointers, dereference them
			again or die

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/30/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if not SINGLE_DRIVE_DOCUMENT_DIR and FSEL_HAS_CHANGE_DRIVE_POPUP

OLFileSelectorChangeDrivePopupHandler	method	dynamic OLFileSelectorClass, \
					MSG_OL_FILE_SELECTOR_CHANGE_DRIVE_POPUP
if HAVE_FAKE_FILE_SYSTEM
	call	OLFSDeref_SI_Gen_DI
	test	ds:[di].GFSI_fileCriteria, mask FSFC_USE_FAKE_FILE_SYSTEM
	jz	continue

	;
	; We are changing drives..  we need to flush cached stuff
	; (like path and perhaps volume names) and do the change
	;
	sub	sp, PATH_BUFFER_SIZE
	mov	dx, sp
	mov	bp, ss
	mov	ax, MSG_GEN_FILE_SELECTOR_FAKE_DRIVE_CHANGE
	call	ObjCallInstanceNoLock
	tst	ax
	jnz	localError
	;
	; ok, now actually change
	;
	mov	cx, ss
	mov	ax, MSG_OL_FILE_SELECTOR_PATH_SET
	call	ObjCallInstanceNoLock
	jc	localError

	add	sp, PATH_BUFFER_SIZE
	jmp	pathSet
localError:
	add	sp, PATH_BUFFER_SIZE
	jmp	error

continue:
endif	;HAVE_FAKE_FILE_SYSTEM

	mov	al, cl				; al = drive #
		;don't inform as name is visible in file selector
	call	DiskRegisterDiskSilently	; bx = disk handle
	jc	error			; handle error


	;
	; Change to the root path of the disk.
	;
NOFXIP<	mov	cx, cs							>
NOFXIP<	mov	dx, offset rootPath					>

FXIP <	push	ds							>
FXIP <	segmov	ds, cs, dx						>
FXIP <	mov	dx, offset rootPath					>
FXIP <	clr	cx							>
FXIP <	call	SysCopyToStackDSDX					>
FXIP <	mov	cx, ds				; cx:dx = string	>
FXIP <	pop	ds							>

	mov	bp, bx
setPath:
	mov	ax, MSG_OL_FILE_SELECTOR_PATH_SET
	call	ObjCallInstanceNoLock

FXIP <	call	SysRemoveFromStack					>
pathSet:
	jc	error				; error
	mov	dx, TRUE			; set to current drive
	call	OLFSUpdateChangeDrivePopupMoniker	; update moniker
	jmp	short done

error:
	push	si				; save FS chunk
	call	OLFSNotifyUserOfDiskError	; report error and leave
						;	current filelist
	pop	si				; restore FS chunk
						; restore selected drive
	call	OLFSSelectCurrentDriveInChangeDrivePopup
done:
	ret
OLFileSelectorChangeDrivePopupHandler	endm

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFileSelectorChangeDirectoryPopupHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	switch to choosen directory in change directory popup

CALLED BY:	INTERNAL

PASS:		*ds:si - OLFileSelector instance
		ax = MSG_OL_FILE_SELECTOR_CHANGE_DIRECTORY_POPUP
		cx = path element number
			0 - root
			1 - 1st path element
			etc.

RETURN:

DESTROYED:

		NOTE:  invalidates any chunk pointers, dereference them
			again or die

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/30/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if not SINGLE_DRIVE_DOCUMENT_DIR

OLFileSelectorChangeDirectoryPopupHandler	method	dynamic OLFileSelectorClass, \
				MSG_OL_FILE_SELECTOR_CHANGE_DIRECTORY_POPUP

if HAVE_FAKE_FILE_SYSTEM
	mov	ax, ATTR_GEN_PATH_DATA
	mov	dx, TEMP_GEN_PATH_SAVED_DISK_HANDLE
	call	GenPathFetchDiskHandleAndDerefPath	; ax = disk handle
							; ds:bx =
							; GenFilePath
	call	OLFSDeref_SI_Gen_DI
	test	ds:[di].GFSI_fileCriteria, mask FSFC_USE_FAKE_FILE_SYSTEM
	jnz	useFakeFS
endif
	;
	; handle simple case of going to root
	;	cx = path element number
	;
	tst	cx
	jnz	checkElements
	;
	; Change to the root path of the current disk.
	;
if HAVE_FAKE_FILE_SYSTEM
	mov	bx, ax
	call	DiskGetDrive
else
	call	OLFSGetCurrentDrive
endif
	mov	cl, al				; cl = drive number
						; use this convenient entry pt
goRoot:
	mov	ax, MSG_OL_FILE_SELECTOR_CHANGE_DRIVE_POPUP
	call	ObjCallInstanceNoLock
	ret

if HAVE_FAKE_FILE_SYSTEM
	;
	; fetch path - but strip off everything including first '\\'
	;
useFakeFS:
	jcxz	goRoot

	mov	bx, ax				; bx= diskhandle
	sub	sp, PATH_BUFFER_SIZE
	mov	dx, sp
	push	cx
	mov	cx, ss
	mov	ax, MSG_GEN_FILE_SELECTOR_FAKE_PATH_GET
	call	ObjCallInstanceNoLock
	mov	es, cx
	mov	di, dx
	cmp	{byte}es:[di].-1, '\\'
	je	haveRoot
	mov	{word}es:[di], '\\'
haveRoot:
	pop	dx
	tst	ax
	LONG_EC	jnz	error
	mov	al, '\\'
	mov	di, sp
	repne	scasb				; find first '\\',
						; advancing starting pointer
	dec	di
	mov	bp, di
	jmp	havePath
endif	;HAVE_FAKE_FILE_SYSTEM

checkElements:
	;
	; construct full path so that we can play with the path elements
	;	*ds:si = OLFileSelector
	;	cx = path element number
	;
	mov	bp, si				; bp = OLFileSelector chunk
	mov	di, cx				; di = path element number
if not HAVE_FAKE_FILE_SYSTEM
	mov	ax, ATTR_GEN_PATH_DATA
	mov	dx, TEMP_GEN_PATH_SAVED_DISK_HANDLE
	call	GenPathFetchDiskHandleAndDerefPath	; ax = disk handle
							; ds:bx = GenFilePath
endif
	lea	si, ds:[bx].GFP_path		; ds:si = path tail
	mov	bx, ax				; bx = disk handle
	mov	ax, di				; ax = path element number
	mov	cx, PATH_BUFFER_SIZE		; cx = buffer size
	sub	sp, cx
	segmov	es, ss				; es:di = buffer
	mov	di, sp
	clr	dx				; no drive name, please
	call	FileConstructFullPath
EC <	ERROR_C	OL_ERROR			; should not overflow	>
	mov	dx, ax				; dx = path element count
	mov	si, bp				; si = OLFileSelector chunk
	;
	; cycle through elements until we get past the one we want
	;
	mov	di, sp				; es:di = path buffer
if HAVE_FAKE_FILE_SYSTEM
	mov	bp, sp
havePath:
endif
if DBCS_PCGEOS
	call	LocalStringLength		; cx <- length w/o NULL
else
	mov	cx, -1
	clr	al
	repne scasb
	not	cx
	dec	cx				; cx = length w/o null
endif
	jcxz	done				; null path?
if HAVE_FAKE_FILE_SYSTEM
	mov	di, bp				; es:di = path buffer
else
	mov	di, sp				; es:di = path buffer
endif

if ERROR_CHECK
SBCS <	cmp	{byte} es:[di], C_BACKSLASH				>
DBCS <	cmp	{wchar}es:[di], C_BACKSLASH				>
	ERROR_NE	OL_ERROR
endif
	LocalNextChar esdi			; skip initial '\'
	dec	cx				; skip initial '\'
	jcxz	goToSelectedDirectory		; if selected element is not
						;	the first, AND the cur
						;	dir is root, then we
						;	must want to go to the
						;	selected path element
doCDElementLoop:
	LocalLoadChar ax, C_BACKSLASH		; find end of element
	LocalFindChar				; repne scasb/scasw
	jne	notFound			; not found, handle below
	dec	dx				; dec element count
	jnz	doCDElementLoop			; haven't found desired element
						;	go back for more
	;
	; desired element found
	;	es:di = pointing past '\' after desired element
	;	*ds:si = OLFileSelector
	;	bx = current disk handle
	;
	LocalPrevChar esdi			; step back to '\'
SBCS <	mov	{byte} es:[di], 0		; place null-terminator there >
DBCS <	mov	{wchar}es:[di], 0		; place null-terminator there >
	mov	cx, ss				; cx:dx = desired path to set
if HAVE_FAKE_FILE_SYSTEM
	mov	dx, bp
else
	mov	dx, sp
endif
	call	DiskGetDrive			; al = current drive #
	call	DiskRegisterDiskSilently	; bx = current disk handle
	jc	error				; if error, report it
	mov	bp, bx				; bp = current disk handle
	mov	ax, MSG_OL_FILE_SELECTOR_PATH_SET
	call	ObjCallInstanceNoLock
	jnc	done				; success!
error:
	call	OLFSNotifyUserOfDiskError	; report error and leave
done:
	add	sp, PATH_BUFFER_SIZE
	ret				; <--- EXIT HERE

notFound:
	;
	; handle situation where desired element is not found
	; this could be the user clicking on the path element for the
	; current directory itself or one after that (i.e. the path element
	; for a selected directory)
	;	dx = number of path elements remaining to skip ( >= 1)
	;	*ds:si = OLFileSelector
	;
	cmp	dx, 1				; desired element is cur dir?
	jne	goToSelectedDirectory		; no, must be a selected path
						;	element
	;
	; click on current parent directory, just move selection to there
	; (first entry)
	;	*ds:si = OLFileSelector
	;
	mov	di, offset OLFileSelectorFileList
	mov	cx, 0				; select first entry
	mov	dx, cx				; not indeterminate
	call	OLFSCallUIBlockGadget

if not SINGLE_DRIVE_DOCUMENT_DIR and FSEL_HAS_CHANGE_DIRECTORY_POPUP
	call	OLFSShowCurrentDir		; update to reflect new select
endif
	clr	bp				; select first entry
	call	OLFSBuildEntryFlagsAndSendAD	; send AD
	jmp	short done

goToSelectedDirectory:
	;
	; must be click on path element of selected directory
	;	*ds:si = OLFileSelector
	;
	call	OLFSGetFileListSelection	; cx = current selection
						; use this convenient entry pt
	call	OLFileSelectorDoublePress
	jmp	short done

OLFileSelectorChangeDirectoryPopupHandler	endm

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFileSelectorOpenDirButtonHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle click on file/directory or volume name

CALLED BY:	INTERNAL

PASS:		*ds:si - OLFileSelector instance
		ax = MSG_OL_FILE_SELECTOR_OPEN_DIR_BUTTON

RETURN:

DESTROYED:

		NOTE:  invalidates any chunk pointers, dereference them
			again or die

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLFileSelectorOpenDirButtonHandler	method	OLFileSelectorClass, \
					MSG_OL_FILE_SELECTOR_OPEN_DIR_BUTTON
	call	OLFSGetFileListSelection	;cx = entry number
	cmp	cx, GIGS_NONE
	je	done				;no selection, done
	mov	bp, -1				;say is double press
	call	HandleFileSelectorUserAction
done:
	ret
OLFileSelectorOpenDirButtonHandler	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFileSelectorGrabFocusExcl --
		MSG_META_GRAB_FOCUS_EXCL for OLFileSelectorClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Handles grabbing the focus.   If we're given the
		focus, at least in Rudy, we'll pass it to the list
		so that it can display the selection properly.

PASS:		*ds:si 	- instance data
		es     	- segment of OLFileSelectorClass
		ax 	- MSG_META_GRAB_FOCUS_EXCL

RETURN:		nothing
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	7/26/95         Initial Version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



FileSelector	ends
