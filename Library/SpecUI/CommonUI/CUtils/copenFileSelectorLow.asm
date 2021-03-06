COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonUI/COpen
FILE:		copenFileSelectorLow.asm

ROUTINES:
	Name			Description
	----			-----------
    INT OLFSNotifyUserOfDiskError 
				Tell the user we were unable to register
				the disk when trying to switch out of
				volume mode.

    INT OLFSDerefIndexBuffer    Fetch the offset of the given list entry in
				the file buffer.

    INT OLFSSendAD              send notification of file being selected to
				action descriptor of GenFileSelector

    INT OLFSCopySelection       copy current selection to generic instance
				data

    MTD MSG_GEN_FILE_SELECTOR_RESCAN 
				rebuilds list using current volume, path
				(in generic instance data)

    INT OLFSSelectHomeFolder    Select the home folder

    INT OLFSRescanLow           Rebuild the list of things to display and
				display them.

    INT OLFSBuildEntryFlagsAndSendAD 
				build GenFileSelectorEntryFlags and send to
				AD

    INT OLFSBuildEntryFlagsAndSendADLow 
				Really low-level routine shared by
				OLFSBuildEntryFlagsAndSendAD and
				OLFileSelectorListMethod to accomplish the
				same thing.

    INT OLFSResolveSelection    set current selection

    MTD MSG_GEN_FILE_SELECTOR_UP_DIRECTORY 
				go up one directory

    MTD MSG_OL_FILE_SELECTOR_DOCUMENT_BUTTON 
				go to document directory and turn on "can't
				navigate above current directory" mode, if
				requested

    MTD MSG_GEN_FILE_SELECTOR_OPEN_ENTRY 
				Open entry specified.  This should be used
				to manually open a directory or a volume,
				as needed when user clicks a "Open"-type
				button that is in the same dialog box as
				the GenFileSelector.  Has no effect if
				entry is a file.

				Typically, the entry number passed will
				have been extracted from the
				GenFileSelectorEntryFlags sent to the
				action descriptor, or returned from
				MSG_GEN_FILE_SELECTOR_GET_SELECTION.

				Only valid after GenFileSelector is made
				visible, as the file list is destroyed when
				the File Selector is brought off the
				screen.

    MTD MSG_GEN_FILE_SELECTOR_SUSPEND 
				Begin suspension of file selector
				rescanning to allow changing mulitple
				attributes with having multiple rescans.
				Only the following attribute setting
				methods are affect:
				MSG_GEN_FILE_SELECTOR_SET_SELECTION
				MSG_GEN_FILE_SELECTOR_SET_PATH
				MSG_GEN_FILE_SELECTOR_SET_MASK
				MSG_GEN_FILE_SELECTOR_SET_FILE_ATTRS
				MSG_GEN_FILE_SELECTOR_SET_TOKEN
				MSG_GEN_FILE_SELECTOR_SET_CREATOR
				MSG_GEN_FILE_SELECTOR_SET_GEODE_ATTR
				MSG_GEN_FILE_SELECTOR_SET_ATTRS
				MSG_GEN_FILE_SELECTOR_SET_FILE_CRITERIA

    MTD MSG_GEN_FILE_SELECTOR_END_SUSPEND 
				End suspension of file selector rescanning.
				File selector is rescanned with current
				attributes.

    INT OLFSMemLock_ES          Looks at its vis moniker to see if its
				mnemonic matches that key currently
				pressed.

    INT OLFSDeref_SI_Gen_DI     Looks at its vis moniker to see if its
				mnemonic matches that key currently
				pressed.

    INT OLFSDeref_SI_Spec_DI    Looks at its vis moniker to see if its
				mnemonic matches that key currently
				pressed.

    INT OLFSFindTempData        Looks at its vis moniker to see if its
				mnemonic matches that key currently
				pressed.

    INT OLFSReplaceVisMonikerText 
				Looks at its vis moniker to see if its
				mnemonic matches that key currently
				pressed.

    INT OLFSGetFileListSelection 
				Looks at its vis moniker to see if its
				mnemonic matches that key currently
				pressed.

    INT OLFSUpdateChangeDrivePopupMoniker 
				Looks at its vis moniker to see if its
				mnemonic matches that key currently
				pressed.

    INT OLFSGetCurrentDrive     Looks at its vis moniker to see if its
				mnemonic matches that key currently
				pressed.

    INT OLFSDisableCloseAndChangeDirectoryButtonsIfFirstEntryAndIsRoot 
				Looks at its vis moniker to see if its
				mnemonic matches that key currently
				pressed.

    INT OLFSDisableDocButtonIfDocDir 
				Looks at its vis moniker to see if its
				mnemonic matches that key currently
				pressed.

    INT OLFSSetFileTableSelection 
				Looks at its vis moniker to see if its
				mnemonic matches that key currently
				pressed.

    INT OLFSSetGenItemSelection Looks at its vis moniker to see if its
				mnemonic matches that key currently
				pressed.

    INT OLFSCallUIBlockGadget   Looks at its vis moniker to see if its
				mnemonic matches that key currently
				pressed.

    INT OLFSStuffDriveAndVolumeName 
				Looks at its vis moniker to see if its
				mnemonic matches that key currently
				pressed.

    INT OLFSSelectCurrentDriveInChangeDrivePopup 
				Looks at its vis moniker to see if its
				mnemonic matches that key currently
				pressed.

    INT OLFSTurnOffGadgetry     Looks at its vis moniker to see if its
				mnemonic matches that key currently
				pressed.

    INT OLFSSetUsableOnFlags    Looks at its vis moniker to see if its
				mnemonic matches that key currently
				pressed.

    INT OLFSIsCurDirVirtualRoot Looks at its vis moniker to see if its
				mnemonic matches that key currently
				pressed.

    INT OLFSIsCurDirVirtualRootOrUnderVirtualRoot 
				Looks at its vis moniker to see if its
				mnemonic matches that key currently
				pressed.

    INT OLFSGetVirtualRoot      Looks at its vis moniker to see if its
				mnemonic matches that key currently
				pressed.

    INT OLFSHaveVirtualRoot     Looks at its vis moniker to see if its
				mnemonic matches that key currently
				pressed.

    INT OLFSGetCurDir           Looks at its vis moniker to see if its
				mnemonic matches that key currently
				pressed.

    INT HandleScalableUIData    Looks at its vis moniker to see if its
				mnemonic matches that key currently
				pressed.

    MTD MSG_VIS_RECALC_SIZE     Recalc's size.

    MTD MSG_VIS_POSITION_BRANCH Recalc's size.

    MTD MSG_META_KBD_CHAR       Handle the keyboard input.

    MTD MSG_META_KBD_CHAR       handle keyboard navigation

    MTD MSG_OL_FILE_SELECTOR_SET_HEADING

    MTD MSG_META_DELETE         Delete the selected file in the List
				Screen.

    MTD MSG_TABLE_QUERY_DRAW    Draw the table entry.

    INT DrawDatePrefix		Draw the Symbol gutter if necessary.

    MTD MSG_TABLE_SELECT        We use this method handler to handle double
				press.

    MTD MSG_TABLE_NOTIFY_SELECTION_CHANGED 
				Notify the file selector about the change
				of the selection.

    MTD MSG_TABLE_STRING_LOCATE Locate the string in the table object which
				matches the given string.

    MTD MSG_TABLE_CHAR_LOCATE   Given the character, locate the file entry
				in the file listing.

    MTD MSG_OLFS_TABLE_HEADING_SET_HEADING 
				Set the string which will be displayed in
				the file list heading of the List Screen.

    MTD MSG_TABLE_QUERY_DRAW    Draw the file selector heading.

    MTD MSG_VIS_COMP_GET_CHILD_SPACING 
				Don't want any space between children.

    MTD MSG_GEN_VIEW_SCROLL_UP  pass scrolling onto table object

    MTD MSG_META_CHECK_IF_INTERACTABLE_OBJECT 
				This is called when a UserDoDialog is on
				the screen, to see if the passed object can
				get events.

    MTD MSG_OL_FILE_SELECTOR_DISK_ERROR_RESPONSE 
				Response from the user on a disk error.

    MTD MSG_OL_FILE_SELECTOR_RENAME 
				Rename the file listed in the file
				selector.

    INT OLFileSelectorContinueRename 
				Continue the rename procedure.

    MTD MSG_OL_FILE_SELECTOR_COPY 
				Duplicate the selected file.

    INT OLFileSelectorContinueCopy 
				Continue the duplicating file operation.

    MTD MSG_OL_FILE_SELECTOR_CREATE_TEMPLATE 
				Create a template file from the selected
				file.

    INT OLFileSelectorContinueCreateTemplate 
				Continue to create the template file.

    MTD MSG_OL_FILE_SELECTOR_DELETE 
				Delete the current selected file in the
				file selector.

    INT OLFileSelectorContinueDelete 
				Continue the process of deleting the file.

    INT CallErrorDialog         Inform the user of the error occured during
				the operation.

    INT OLFileSelectorGetFileName 
				Get the name of the selected file in the
				FileSelector

    MTD MSG_OL_FILE_SELECTOR_GET_ENTRY_NAME

    MTD MSG_OL_FILE_SELECTOR_GET_NUM_OF_ENTRIES

    MTD MSG_OL_FILE_SELECTOR_SET_FILE_PATH 
				Set the path which is stored in OL file
				selector.

    MTD MSG_VIS_OPEN            Init. the its instance data

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/10/94	Broken out of copenFileSelector.asm

DESCRIPTION:

	$Id: copenFileSelectorLow.asm,v 1.3 98/03/08 17:01:15 gene Exp $

-------------------------------------------------------------------------------@

FileSelector	segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFileSelectorListMethod
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle click on file/directory or volume name

CALLED BY:	INTERNAL

PASS:		*ds:si - OLFileSelector instance
		cx = entry #
			(OLFS_UP_DIRECTORY_ENTRY_NUM to go up a directory)

RETURN:

DESTROYED:

		NOTE:  invalidates any chunk pointers, dereference them
			again or die

PSEUDO CODE/STRATEGY:
		single click on first item --> send notification
		single click on any other item --> send notification
		double click on directory --> send notification & open
		double click on first item --> up directory

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	01/29/90	Initial version
	brianc	4/91		Completed 2.0 revisions

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLFileSelectorDoublePress	method	OLFileSelectorClass, \
					MSG_OL_FILE_SELECTOR_DOUBLE_PRESS

	mov	bp, -1				;say is double press
	GOTO	HandleFileSelectorUserAction

OLFileSelectorDoublePress	endm


OLFileSelectorListMethod	method	OLFileSelectorClass, \
					MSG_OL_FILE_SELECTOR_LIST_MESSAGE
	clr	bp				;no double press

if _DUI
	;
	; if selecting already selected item, open it
	;
	mov	ax, TEMP_GEN_FILE_SELECTOR_DATA
	call	ObjVarFindData
	jnc	noOpen
	cmp	cx, ds:[bx].GFSTDE_selectionNumber	; same?
	je	openIt
noOpen:
endif

	mov	di, segment olFileSelectorSingleClickToOpen
	mov	es, di
	tst	es:[olFileSelectorSingleClickToOpen]
	jz	HandleFileSelectorUserAction

	call	OLFSDeref_SI_Spec_DI
	test	ds:[di].OLFSI_state, mask OLFSS_SINGLE_ACTION
	jz	HandleFileSelectorUserAction

	;
	; Fake a double press.
	;
openIt::
	mov	bx, ds:[LMBH_handle]
	mov	ax, MSG_OL_FILE_SELECTOR_DOUBLE_PRESS
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage

HandleFileSelectorUserAction	label 	far
	doublePressFlag	local	word	\
			push	bp
	fsChunk		local	word	\
			push	si
	genAttrs	local	FileSelectorAttrs

	.enter

	call	OLFSDeref_SI_Gen_DI		; save attrs for easy perusal
	mov	ax, ds:[di].GFSI_attrs
	mov	genAttrs, ax

	call	OLFSDeref_SI_Spec_DI		; ds:di = specific instance
						; showing parent dir?
	test	ds:[di].OLFSI_state, mask OLFSS_SHOW_PARENT_DIR
	jz	skipFirstEntryCheck		; nope, no special first entry
						;	handling
	LONG	jcxz	firstEntry
skipFirstEntryCheck:
	cmp	cx, OLFS_UP_DIRECTORY_ENTRY_NUM
	LONG je	upDirectory
	;
	; handle click on any other item
	;	single click --> send notification
	;	double click --> send notification & open if directory
	;
	;	*ds:si = OLFileSelector
	;	cx = entry number (non-zero if OLFSS_SHOW_PARENT_DIR)
	;
	call	OLFSDeref_SI_Spec_DI		; ds:di = specific instance
	push	bp
	tst	doublePressFlag
	mov	bp, 0				; (preserve flags)
	jz	haveEntryFlags			; not double-press
	mov	bp, mask GFSEF_OPEN		; else, signal open
haveEntryFlags:

	call	OLFSBuildEntryFlagsAndSendADLow	; es:si = locked entry buffer
						; bx = file buffer handle
						; (or bx=0 and es:si invalid,
						; if no entries or first entry)

	pop	bp

	tst	bx				; this shouldn't happen!
	LONG jz	done

	tst	doublePressFlag
	jz	updateCurDirPopupAndDoneUnlock	; single click, that's all

	;
	; double-click, if directory open it
	; (file buffer will be nuked by rescan in MSG_OL_FILE_SELECTOR_PATH_SET)
	;
	test	genAttrs, mask FSA_ALLOW_CHANGE_DIRS
	jz	doneUnlock			; no directory changing!



	test	es:[si].OLFSE_fileAttrs, mask FA_SUBDIR	; directory?
	jz	doneUnlock
	mov	cx, es				; cx:dx = name of dir to open
	lea	dx, es:[si].OLFSE_name
	mov	si, fsChunk			; *ds:si = OLFileSelector
	push	bp

	clr	bp				; set relative to current dir.

	mov	ax, MSG_OL_FILE_SELECTOR_PATH_SET
	call	ObjCallInstanceNoLock
	pop	bp
	LONG jnc done

	call	OLFSNotifyUserOfDiskError	; report error and leave
	jmp	done

updateCurDirPopupAndDoneUnlock:
	push	bx
	mov	si, fsChunk			; *ds:si = OLFileSelector

if not SINGLE_DRIVE_DOCUMENT_DIR and FSEL_HAS_CHANGE_DIRECTORY_POPUP
	call	OLFSShowCurrentDir
endif
	pop	bx

doneUnlock:
	call	MemUnlock			; unlock file buffer
	jmp	done

firstEntry:
	tst	doublePressFlag			; double-press --> up directory
	jnz	checkAndUpDirectory
	;
	; single click on current directory entry
	;
	mov	si, fsChunk			; *ds:si = OLFileSelector
	push	bp
	clr	bp				; first entry
	call	OLFSBuildEntryFlagsAndSendAD	; send notification about click
	pop	bp
if not SINGLE_DRIVE_DOCUMENT_DIR and FSEL_HAS_CHANGE_DIRECTORY_POPUP
	call	OLFSShowCurrentDir		; update for selection change
endif
	jmp	done

checkAndUpDirectory:
	test	genAttrs, mask FSA_ALLOW_CHANGE_DIRS
	LONG jz	done				; no changing directories
upDirectory:
	call	OLFSIsCurDirVirtualRoot		; are we at v.root?
	LONG jc	done				; yes, do nothing
	;
	; Need to determine the last component of the current path so we can
	; set it as the suggested selection when we rescan for the parent
	; directory. This is made more interesting by the kernel's tendency
	; to return a StandardPath + tail for any directory in the PC/GEOS
	; tree, thus often giving us a root GFP_path.
	; 
	push	bp
	mov	bp, sp			; bp <- current sp for clearing once
					;  final component is found.
	mov	cx, PATH_BUFFER_SIZE
	sub	sp, cx

if HAVE_FAKE_FILE_SYSTEM
	call	OLFSDeref_SI_Gen_DI
	test	ds:[di].GFSI_fileCriteria, mask FSFC_USE_FAKE_FILE_SYSTEM
	jnz	useFakeFS
endif
	mov	ax, ATTR_GEN_PATH_DATA
	mov	dx, TEMP_GEN_PATH_SAVED_DISK_HANDLE
	call	GenPathFetchDiskHandleAndDerefPath
	mov	si, bx			; ds:si <- GenFilePath

	mov	di, sp
	segmov	es, ss
	mov	bx, ds:[si].GFP_disk	; bx <- current disk
	push	si			; save base of GenFilePath
	add	si, offset GFP_path	; ds:si <- path tail (empty, but
					;  this is convenient)
	clr	dx			; don't add drive name, thanks.
	call	FileConstructFullPath
	pop	si			; ds:si <- GenFilePath
	mov	cx, ss			; cx:dx <- path from which to get
	mov	dx, sp			;  final component.
	
	mov	di, sp
havePath::
	cmp	{word}ss:[di], C_BACKSLASH or (0 shl 8)	; really root?
DBCS <	jne	notRoot							>
DBCS <	cmp	{wchar}ss:[di][2], 0					>
	je	clearStackAndGoUp	; yes, don't bother with search
DBCS <notRoot:								>
	;
	; Find the end of the whole thing. cx:dx = string to scan
	; 
	mov	es, cx
	mov	di, dx
	mov	cx, -1
SBCS <	clr	al							>
DBCS <	clr	ax							>
	LocalFindChar		; get to the end, first  repne scasb/w
	;
	; Now scan backwards for the first backslash.
	; 
	not	cx		; cx <- count, including null
	LocalLoadChar ax, C_BACKSLASH ; search for first backslash
	LocalPrevChar esdi	;  starting with null
	std
	LocalFindChar 		; repne scasb/scasw
	cld
	jne	atBackslash	; => no backslash, so DI is just before the
				;  start of the string, meaning we want to
				;  do only a single-increment
	LocalNextChar esdi	; else point di at backslash
atBackslash:
	LocalNextChar esdi	; skip over backslash
	mov	si, di
	mov	di, ss:[bp]	; di <- frame pointer
	mov	di, ss:[di+offset fsChunk]	; *ds:di <- GenFileSelector
	mov	di, ds:[di]
	add	di, ds:[di].Gen_offset		; ds:di = Gen instance
	segxchg	ds, es		; ds:si <- tail, es:di <- GFSI_selection
SBCS <	mov	cx, size GFSI_selection					>
DBCS <	mov	cx, (size GFSI_selection)/2				>
DBCS <			CheckHack <((size GFSI_selection) and 1) eq 0>	>
	add	di, offset GFSI_selection
	LocalCopyNString	; rep movsb/movsw
	segmov	ds, es		; ds <- object segment, again

clearStackAndGoUp:
	;
	; Clear the stack of any path buffer we created.
	; 
	mov	sp, bp
	pop	bp
	mov	si, fsChunk			; *ds:si = GenFileSelector
	
	;
	; Now be easy and just set the path to be ".." relative to the current
	; one. This will cause a rescan, etc. etc. etc.
	; 
	push	bp

NOFXIP<	mov	cx, cs							>
NOFXIP<	mov	dx, offset dotdotString					>

FXIP <	push	ds							>
FXIP <	segmov	ds, cs, dx						>
FXIP <	mov	dx, offset dotdotString					>
FXIP <	clr	cx							>
FXIP <	call	SysCopyToStackDSDX					>
FXIP <	mov	cx, ds				; cx:dx = string	>
FXIP <	pop	ds							>

	clr	bp				; relative to current dir.
setPath:	
	mov	ax, MSG_GEN_PATH_SET		; re-use GFI_selection
	call	ObjCallInstanceNoLock
FXIP <	call	SysRemoveFromStack					>

popDone:	
	pop	bp
done:
	.leave
	ret
if HAVE_FAKE_FILE_SYSTEM
	;
	; OK, we need to get the path (so we can pick out the last
	; element and set the selector appropriately).
	;
useFakeFS:
	mov	dx, sp
	mov	cx, ss
	mov	ax, MSG_GEN_FILE_SELECTOR_FAKE_PATH_GET
	call	ObjCallInstanceNoLock
	mov	di, dx
	dec	di			; if the last char is a
					; backslash then we are at
					; root.  See havePath..
	mov	dx, sp
	jmp	havePath
endif ; HAVE_FAKE_FILE_SYSTEM
OLFileSelectorListMethod	endp

LocalDefNLString dotdotString <"..", 0>
LocalDefNLString rootPath <C_BACKSLASH, 0>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFSNotifyUserOfDiskError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tell the user we were unable to register the disk when
		trying to switch out of volume mode.

CALLED BY:	OLFileSelectorListMethod
PASS:		*ds:si -- file selector
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/29/92		Initial version
	chris	7/20/93		Mucked up

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLFSNotifyUserOfDiskError proc	near
		uses	bp, es
		.enter

if HAVE_FAKE_FILE_SYSTEM
	;
	; If the file selector is using a FAKE_FILE_SYSTEM, then it's
	; expected to handle its own errors and not rely on the
	; default file selector error handling.
	;
		call	OLFSDeref_SI_Gen_DI
		test	ds:[di].GFSI_fileCriteria, mask FSFC_USE_FAKE_FILE_SYSTEM
		jnz	done
endif
	
	;
	; Set up the parameters to notify the user of our inability to open
	; the disk volume, with no one needing to be notified when the user
	; has acknowledged.
	; 
		mov	dx, size GenAppDoDialogParams
		sub	sp, dx
		mov	bp, sp

if SINGLE_DRIVE_DOCUMENT_DIR
		mov	ss:[bp].GADDP_finishOD.chunk, si
		mov	ax, ds:[LMBH_handle]
		mov	ss:[bp].GADDP_finishOD.handle, ax
		mov	ss:[bp].GADDP_message, \
				MSG_OL_FILE_SELECTOR_DISK_ERROR_RESPONSE
		clr	ax
		mov	ss:[bp].GADDP_dialog.SDP_helpContext.segment, ax
		mov	ss:[bp].GADDP_dialog.SDP_customFlags, \
	  CustomDialogBoxFlags <TRUE, CDT_ERROR, GIT_MULTIPLE_RESPONSE, 0, 0>
if _FXIP
		mov	cx, (size StandardDialogResponseTriggerEntry * 2) \
				+ size word		 ; cx = size of table
		segmov	es, cs, di
		mov	di, offset DNF_Triggers	; es:di = table
		call	SysCopyToStackESDI
		movdw	ss:[bp].GADDP_dialog.SDP_customTriggers, esdi	
else
		mov	ax, offset DNF_Triggers				
		movdw	ss:[bp].GADDP_dialog.SDP_customTriggers, csax	
endif


else
 		clr	ax
 		mov	ss:[bp].GADDP_finishOD.chunk, ax
		mov	ss:[bp].GADDP_finishOD.handle, ax
		mov	ss:[bp].GADDP_message, ax
		mov	ss:[bp].GADDP_dialog.SDP_helpContext.segment, ax
		mov	ss:[bp].GADDP_dialog.SDP_customFlags, \
	  CustomDialogBoxFlags <FALSE, CDT_ERROR, GIT_NOTIFICATION, 0, 0>
		movdw	ss:[bp].GADDP_dialog.SDP_customTriggers, axax
endif

		mov	bx, handle DiskNotFoundString
		call	MemLock
		push	bx
		mov	es, ax
		mov	bx, offset DiskNotFoundString
		mov	ax, es:[bx]
		movdw	ss:[bp].SDP_customString, esax

	;
	; Call the application object, passing the requisite data on the stack
	; 
		mov	ax, MSG_GEN_APPLICATION_DO_STANDARD_DIALOG
		mov	di, mask MF_STACK or mask MF_CALL or mask MF_FIXUP_DS
		clr	bx
		call	GeodeGetAppObject
		call	ObjMessage

		pop	bx
		call	MemUnlock
	;
	; Done...
	; 
if SINGLE_DRIVE_DOCUMENT_DIR and _FXIP
		call	SysRemoveFromStack
endif
		add	sp, size GenAppDoDialogParams
done::
		.leave
		ret
OLFSNotifyUserOfDiskError endp

if SINGLE_DRIVE_DOCUMENT_DIR
DNF_Triggers	label	StandardDialogResponseTriggerTable
	word	2				; SDRTT_numTriggers
	StandardDialogResponseTriggerEntry	<
		DiskNotFound_OK,	;	 SDRTE_moniker
		IC_OK				; SDRTE_responseValue
	>
	StandardDialogResponseTriggerEntry	<
		DiskNotFound_Cancel,		; SDRTE_moniker
		IC_DISMISS			; SDRTE_responseValue
	>
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFSDerefIndexBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the offset of the given list entry in the file buffer.

CALLED BY:	INTERNAL
PASS:		ds:di	= OLFileSelectorInstance
		cx	= entry # (0-origin)
RETURN:		si	= offset of OLFileSelectorEntry in file buffer
DESTROYED:	bx, es

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	?/?/?		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLFSDerefIndexBuffer	proc	near
	class	OLFileSelectorClass
EC <	cmp	cx, ds:[di].OLFSI_numFiles				>
EC <	ERROR_AE	OL_FILE_SELECTOR_BAD_ENTRY_NUMBER		>
	mov	si, cx
	shl	si, 1				; si = offset in index buffer
	mov	bx, ds:[di].OLFSI_indexBuffer
	call	OLFSMemLock_ES			; lock index buffer
	mov	si, es:[si]			; si = offset in file buffer
	call	MemUnlock			; unlock index buffer
	ret
OLFSDerefIndexBuffer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFSSendAD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	send notification of file being selected to action
		descriptor of GenFileSelector

CALLED BY:	INTERNAL
			OLFileSelectorListMethod
			OLFileSelectorRescan

PASS:		*ds:si = OLFileSelector
		ax = entry # clicked on
		cx = GenFileSelectorEntryFlags (see genFileSelector.asm)
			GFSEF_TYPE - type of entry clicked on
				GFSET_FILE - if clicked on file
				GFSET_SUBDIR - if clicked on subdirectory
				GFSET_VOLUME - if clicked on volume
			GFSEF_OPEN - if double-clicked to open
			GFSEF_NO_ENTRIES - if no entries in list
			GFSEF_ERROR - set if error occured reading file list
			GFSEF_TEMPLATE - set if file is a template (from
				 GFHF_TEMPLATE)
			GFSEF_SHARED_MULTIPLE - set if file is shared with
					multiple writers (from
					GFHF_SHARED_MULTIPLE)
			GFSEF_SHARED_SINGLE - set if file is shared with single
				      writer (from GFHF_SHARED_SINGLE)
			GFSEF_READ_ONLY - set if file is read-only (from
					  FA_RDONLY)
			GFSEF_PARENT_DIR - set if current selection is the
					parent directory entry (first entry)
		if RUDY & non-exclusive,
		   bp = GenFileSelectorEntryFlags mask
		   ax = number of selections
		   dx = handle of block containing selections

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		send to AD:
			cx - entry # of selection
			bp - GenFileSelectorEntryFlags
				GFSEF_TYPE - type of entry clicked on
					GFSET_FILE - click on file
					GFSET_SUBDIR - click on subdirectory
					GFSET_VOLUME - click on volume
				GFSEF_OPEN - if double click
				GFSEF_NO_ENTRIES - if no entries in list
				GFSEF_ERROR - set if error occured reading
						file list
				GFSEF_TEMPLATE - set if file is a template (from
					 GFHF_TEMPLATE)
				GFSEF_SHARED_MULTIPLE - set if file is shared
						with multiple writers (from
						GFHF_SHARED_MULTIPLE)
				GFSEF_SHARED_SINGLE - set if file is shared with
					      single writer (from
					      GFHF_SHARED_SINGLE)
				GFSEF_READ_ONLY - set if file is read-only (from
						  FA_RDONLY)
				GFSEF_PARENT_DIR - set if current selection is
						the parent directory entry
						(first entry)

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	02/14/90	Initial version
	brianc	4/91		Completed 2.0 revisions

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLFSSendAD	proc	near
	uses	ax, bx, cx, dx, si, di, bp
	class	GenFileSelectorClass
	.enter

	call	OLFSCopySelection		; copy selection into Gen


	mov	bp, cx				; pass flags in bp

	mov	cx, ax				; cx = entry #

	call	OLFSDeref_SI_Gen_DI		; ds:di = generic instance

	pushdw	ds:[di].GFSI_destination	; push OD to which to send
	mov	ax, ds:[di].GFSI_notificationMsg; ax = message to send

						; force queue, in case output
						;	is obj run by UI thread
	mov	di, mask MF_FORCE_QUEUE		;If we do not clear the queue
						; before sending this, it is
						; possible that the file 
						; selector will not be in a
						; valid state.
	call	GenProcessAction		;use standard utility to ship
						; it

	.leave
	ret
OLFSSendAD	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFSCopySelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	copy current selection to generic instance data

CALLED BY:	INTERNAL
			OLFSSendAD

PASS:		*ds:si - file selector instance
		ax = entry # clicked on
		cx = GenFileSelectorEntryFlags (see genFileSelector.asm)
			GFSEF_TYPE - type of entry clicked on
				GFSET_FILE - if clicked on file
				GFSET_SUBDIR - if clicked on subdirectory
				GFSET_VOLUME - if clicked on volume
			GFSEF_OPEN - if double-clicked to open
			GFSEF_NO_ENTRIES - if no entries in list
			GFSEF_ERROR - if error occurred (this is cleared
					before storing in generic instance
					data as
					MSG_GEN_FILE_SELECTOR_GET_SELECTION
					never returns this bit)
			GFSEF_TEMPLATE - set if file is a template (from
				 GFHF_TEMPLATE)
			GFSEF_SHARED_MULTIPLE - set if file is shared with
					multiple writers (from
					GFHF_SHARED_MULTIPLE)
			GFSEF_SHARED_SINGLE - set if file is shared with single
				      writer (from GFHF_SHARED_SINGLE)
			GFSEF_READ_ONLY - set if file is read-only (from
					  FA_RDONLY)
			GFSEF_PARENT_DIR - set if current selection is the
					parent directory entry (first entry)
		if RUDY & non-exclusive,
		   bp = GenFileSelectorEntryFlags mask
		   ax = number of selections
		   dx = handle of block containing selections (can be
			0 if no selections)

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	For the Rudy version, if the file selector is non-exclusive,
	do something similar to what we did in
	OLFSBuildEntryFlagsAndSendADLow, and insert a loop around
	the code that processes one file.  And instead of copying
	to GFSI_selection, copy to the buffer at EFSI_selections

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	03/02/90	Initial version
	brianc	4/91		Completed 2.0 revisions

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLFSCopySelection	proc	near
	uses	ax, bx, cx, dx, si, es, di, bp

	class	OLFileSelectorClass
	.enter


	andnf	cx, not mask GFSEF_ERROR	; clear error flag
	call	OLFSFindTempData		; ds:bx = GFS temp data
						; MAY CAUSE OBJ BLOCK MOTION!
	mov	ds:[bx].GFSTDE_selectionFlags, cx	; save selection flags
	mov	ds:[bx].GFSTDE_selectionNumber, ax	; save selection #
	mov	bx, ax				; bx = entry #

skipTempShme::
	segmov	es, ds
	call	OLFSDeref_SI_Gen_DI		; ds:di = generic instance
	add	di, GFSI_selection		; es:di = selection field
SBCS <	mov	{byte} es:[di], 0		; in case no files, etc. >
DBCS <	mov	{wchar}es:[di], 0		; in case no files, etc. >

	;
	; use entry number to get filename from buffer
	;	bx = entry #
	;	es:di = dest buffer for selection
	;	*ds:si = OLFileSelector
	;
	push	di				; save dest buffer offset
	call	OLFSDeref_SI_Spec_DI		; ds:di = specific instance
						; showing parent dir?
	test	ds:[di].OLFSI_state, mask OLFSS_SHOW_PARENT_DIR
	pop	di				; restore dest buffer offset
	jz	actualBufferEntry		; not showing parent dir,
						;	use actual buffer entry

	tst	bx				; first entry?
	jnz	bufferEntry			; no, is buffer entry
	;
	; use '.' to indicate current directory selected
	;
	mov	ax, '.' or (0 shl 8)
	stosw					; stuff '.'
DBCS <	clr	ax							>
DBCS <	stosw								>
	jmp	short oneFileEnd

bufferEntry:
	dec	bx				; convert to buffer entry #
actualBufferEntry:
	push	di				; save dest buffer offset
	call	OLFSDeref_SI_Spec_DI		; ds:di = specific instance
	tst	ds:[di].OLFSI_numFiles		; any files?
	pop	di				; restore dest buffer offset
	jz	oneFileEnd			; nope, nothing to copy
EC <	push	cx							>
	mov	cx, bx
	push	es, di				; save selection dest buffer
	call	OLFSDeref_SI_Spec_DI		; ds:di = specific instance
	call	OLFSDerefIndexBuffer		; si = file buffer offset
	mov	bx, ds:[di].OLFSI_fileBuffer	; lock file buffer
	pop	es, di				; restore selection dest buffer

	call	MemLock
	mov	ds, ax				; ds:si = entry to get
	;
	; get file/directory selection
	;
EC <	pop	cx							>
EC <	andnf	cx, mask GFSEF_TYPE					>
EC <	mov	ax, GFSET_SUBDIR shl offset GFSEF_TYPE			>
EC <	test	ds:[si].OLFSE_fileAttrs, mask FA_SUBDIR			>
EC <	jnz	checkType
EC <	mov	ax, GFSET_VOLUME shl offset GFSEF_TYPE			>
EC <	test	ds:[si].OLFSE_fileAttrs, mask FA_VOLUME			>
EC <	jnz	checkType						>
EC <	mov	ax, GFSET_FILE shl offset GFSEF_TYPE			>
EC <checkType:								>
EC <	cmp	ax, cx							>
EC <	ERROR_NE OL_FILE_SELECTOR_BAD_ENTRY_TYPE			>

   	add	si, offset OLFSE_name
SBCS <	mov	cx, FILE_LONGNAME_BUFFER_SIZE	; cx = size of buffer for name>
DBCS <	mov	cx, FILE_LONGNAME_BUFFER_SIZE/2	; cx = size of buffer for name>
SBCS <	rep movsb							>
DBCS <	rep movsw							>
	call	MemUnlock			; unlock file buffer

	segmov	ds, es			; ds <- object segment, again

oneFileEnd:

exit::
	.leave
	ret
OLFSCopySelection	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFSResetSearch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the search text to nil, and restores all items

CALLED BY:	MSG_EFS_RESET_SEARCH
PASS:		*ds:si	= OLFileSelectorClass object
		ds:di	= OLFileSelectorClass instance data
		ds:bx	= OLFileSelectorClass object (same as *ds:si)
		es 	= segment of OLFileSelectorClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cthomas	12/23/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFileSelectorRescan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	rebuilds list using current volume, path (in generic
		instance data)

CALLED BY:	MSG_GEN_FILE_SELECTOR_RESCAN

PASS:		*ds:si - instance of OLFileSelector
		ax = MSG_GEN_FILE_SELECTOR_RESCAN

RETURN:		nothing

DESTROYED:

		NOTE:  invalidates any chunk pointers, dereference them
			again or die

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	02/01/90	Initial version
	brianc	4/91		Completed 2.0 revisions

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLFileSelectorRescan	method	dynamic OLFileSelectorClass,
						MSG_GEN_FILE_SELECTOR_RESCAN

	;
	; mark busy
	;
	mov	ax, MSG_GEN_APPLICATION_MARK_APP_COMPLETELY_BUSY
	call	UserCallApplication


	call	OLFSRescanLow


	;
	; mark not busy
	;	carry - error flag
	;
	mov	ax, MSG_GEN_APPLICATION_MARK_APP_NOT_COMPLETELY_BUSY
	call	UserCallApplication
	ret
OLFileSelectorRescan	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFSSelectHomeFolder
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Select the home folder

CALLED BY:	
PASS:		*ds:si	= instance data
RETURN:		carry set if home folder found
DESTROYED:	ax, bx, cx, dx, di, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	10/18/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFSRescanLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Rebuild the list of things to display and display them.

CALLED BY:	INTERNAL
		OLFileSelectorRescan,
PASS:		*ds:si	= GenFileSelector
RETURN:		nothing
		NOTE:  invalidates any chunk pointers, dereference them
			again or die
DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	?/?/?		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLFSRescanLow	proc	near
	class	OLFileSelectorClass

	mov	di, 1000
	call	ThreadBorrowStackSpace
	push	di


	;
	; start by setting OLFSS_SHOW_PARENT_DIR based on FSFC_DIRS
	; (In Rudy, we never show the parent dir, up-directory is up to caller)
	;
	call	OLFSDeref_SI_Spec_DI		; ds:di = specific instance

if not _DUI
	ornf	ds:[di].OLFSI_state, mask OLFSS_SHOW_PARENT_DIR
	push	di				; save spec offset
	call	OLFSDeref_SI_Gen_DI
	test	ds:[di].GFSI_fileCriteria, mask FSFC_DIRS
	pop	di				; restore spec offset
	jnz	haveParentDirFlag		; showing dirs, leave parent dir
						; else, clear
endif

	andnf	ds:[di].OLFSI_state, not mask OLFSS_SHOW_PARENT_DIR
haveParentDirFlag:


	call	OLFSFreeBuffers
	push	si				; save our chunk

	call	OLFSReadList			; read new directory
	;
	; determine entry to select
	;


	call	OLFSDeref_SI_Gen_DI		; ds:di = generic instance
	mov	si, ds:[si]
	add	si, ds:[si].Vis_offset		; ds:si = specific instance
	call	OLFSResolveSelection		; dx = entry # to select
						;	(destroys nothing)
gotSelection:
	;
	; tell list to use new stuff
	;	dx = entry to select in new list
	;
	mov	cx, ds:[si].OLFSI_numFiles	; cx = number of files/dirs
						; showing parent dir?

	test	ds:[si].OLFSI_state, mask OLFSS_SHOW_PARENT_DIR
	jz	noParentDir			; nope, use actual file count
	inc	cx				; make room for cur dir entry
noParentDir:
	mov	bx, ds:[si].OLFSI_uiBlock
	mov	si, offset OLFileSelectorFileList

	push	dx				; save new entry selected
if _FILE_TABLE
	mov	ax, MSG_TABLE_SET_ROW_COUNT
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	mov	ax, MSG_TABLE_REDRAW_TABLE
else

	mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE

endif
	mov	di, mask MF_FIXUP_DS
if _DUI
	push	cx				; save file count
endif
	call	ObjMessage
if _DUI
	;
	; set file count in header
	;	bx = UI block
	;
	pop	ax				; ax = file count
	sub	sp, UHTA_NULL_TERM_BUFFER_SIZE
	segmov	es, ss, di
	mov	di, sp
	clr	dx
	mov	cx, mask UHTAF_NULL_TERMINATE
	call	UtilHex32ToAscii
	push	di
	mov	cx, -1
	LocalLoadChar	ax, C_NULL
	LocalFindChar	esdi
	LocalPrevChar	esdi			; es:di = null
	LocalLoadChar	ax, C_SPACE
	LocalPutChar	esdi, ax
	LocalLoadChar	ax, C_NULL
	LocalPutChar	esdi, ax
	pop	di
	mov	dx, ss
	mov	bp, di
	mov	si, offset OLFileSelectorFileCount
	clr	cx				; null-terminated
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	add	sp, UHTA_NULL_TERM_BUFFER_SIZE

	pop	ax				; ax = entry #
	pop	si				; si = FS chunk
	push	si				; put it all back
	push	ax
;always use default name as we don't want to overload template dir
;though we still copy template dir into vis moniker as flag to enable
;file count (yes, a bad thing)
;-- brianc 3/1/97
;	mov	ax, MSG_VIS_TEXT_APPEND_PTR	; assume using moniker
;	mov	di, ds:[si]
;	add	di, ds:[di].Gen_offset
;	mov	di, ds:[di].GI_visMoniker
;	tst	di
;	jnz	haveMoniker
	;
	; use default name (not really needed as we set the file count
	; not usable if there's no moniker, but it is used for gstring
	; monikers...)
	;
noMoniker:
	mov	ax, MSG_VIS_TEXT_APPEND_OPTR
	mov	dx, handle FSFileCountDefaultName
	mov	bp, offset FSFileCountDefaultName
	jmp	short setMoniker

haveMoniker:
	mov	di, ds:[di]			; ds:di = VisMoniker
	test	ds:[di].VM_type, mask VMT_MONIKER_LIST or mask VMT_GSTRING
	jnz	noMoniker
	mov	bp, di
	add	bp, offset VM_data.VMT_text	; dx:bp = text moniker
	mov	dx, ds
setMoniker:
	clr	cx				; null-terminated
	mov	si, offset OLFileSelectorFileCount
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	mov	si, offset OLFileSelectorFileList	; set ^lbx:si = list
endif ; _DUI
	pop	dx
	;
	; force list to make selected entry visible
	;
	push	dx				; save entry selected for later
	mov	cx, dx				; cx = entry to select
if _FILE_TABLE
	cmp	cx, -1				;any entry?
	je	noneSelected
	call	OLFSSetFileTableSelection
	push	dx, di, si
	call	ObjBlockGetOutput		;^lbx:si = DocCtrl obj
	mov	cx, MSG_GEN_SET_ENABLED
	mov	ax, MSG_OLDC_NOTIFY_EDIT
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	dx, di, si
	jmp	alreadyVisible
noneSelected:
	;
	; If cx = -1, that means there is no document, so we need to disable
	; the "Title" button.
	;
	push	dx, di, si
	call	ObjBlockGetOutput
	mov	cx, MSG_GEN_SET_NOT_ENABLED
	mov	dl, VUM_NOW
	mov	ax, MSG_OLDC_ENABLE_DISABLE_RENAME
	mov	di, mask MF_FIXUP_DS	
	call	ObjMessage
	pop	dx, di, si
	jmp	alreadyVisible
else
	call	OLFSSetGenItemSelection
endif
alreadyVisible:
	;
	; show current directory
	;	*ds:si = OLFileSelector instance
	;
	pop	bp				; bp = new entry selected
	pop	si				; *ds:si = OLFileSelector inst.
	push	si				; save again
if not SINGLE_DRIVE_DOCUMENT_DIR and FSEL_HAS_CHANGE_DIRECTORY_POPUP
	call	OLFSShowCurrentDir		; preserves bp
endif
						; (invalidates chunk pointers)
	;
	; update selected item in "Change Drive" popup list
	;
if not SINGLE_DRIVE_DOCUMENT_DIR and FSEL_HAS_CHANGE_DRIVE_POPUP
	call	OLFSSelectCurrentDriveInChangeDrivePopup
endif
	;
	; notify AD of new selection or that there are no files
	;	bp = new entry selected
	;
	pop	si				; *ds:si = OLFileSelector
	;
	; build GenFileSelectorEntryFlags for new entry and send to AD
	;	*ds:si = file selector
	;	bp = entry #
	;
	call	OLFSBuildEntryFlagsAndSendAD

	pop	di
	call	ThreadReturnStackSpace

	;
	; If file selector has focus, give focus to list, as that is what the
	; user normally wants
	;	*ds:si = file selector
	;
	mov	ax, MSG_VIS_VUP_QUERY_FOCUS_EXCL
	call	ObjCallInstanceNoLock		; ^lcx:dx = focus object
	call	OLFSDeref_SI_Spec_DI
	cmp	ds:[di].OLFSI_uiBlock, cx	; is it one of ours?
	jne	done				; nope, we don't have focus
	mov	bx, cx				; else, give focus to list

	;
	; This part is commented out for Jedi because we don't want the table
	; object get the focus. There are some weird behaviors on the function
	; keys (bug #33634) when the table object gets the focus.
	;

	mov	si, offset OLFileSelectorFileList
grabFocus::
	mov     ax, MSG_META_GRAB_FOCUS_EXCL
	mov	di, mask MF_FORCE_QUEUE or mask MF_FIXUP_DS
	call    ObjMessage

done:

	ret
OLFSRescanLow	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFSBuildEntryFlagsAndSendAD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	build GenFileSelectorEntryFlags and send to AD

CALLED BY:	INTERNAL
			OLFSRescanLow
			OLFileSelectorSetSelection

PASS:		*ds:si = file selector
		bp = entry #

RETURN:		nothing

DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	03/05/90	broken out for general use
	brianc	4/91		Completed 2.0 revisions

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLFSBuildEntryFlagsAndSendAD	proc	near
	class	OLFileSelectorClass
	uses	es, si
	.enter
	call	OLFSDeref_SI_Spec_DI
	mov	cx, bp			; cx <- entry #
	clr	bp			; no additional flags
	call	OLFSBuildEntryFlagsAndSendADLow
	tst	bx
	jz	done
	call	MemUnlock
done:
	.leave
	ret
OLFSBuildEntryFlagsAndSendAD	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFSBuildEntryFlagsAndSendADLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Really low-level routine shared by OLFSBuildEntryFlagsAndSendAD
		and OLFileSelectorListMethod to accomplish the same thing.

CALLED BY:	INTERNAL
		OLFSBuildEntryFlagsAndSendAD, OLFileSelectorListMethod
PASS:		ds:di	= OLFileSelectorInstance
		cx	= entry # (-1 if no entries)
		bp	= initial GenFileSelectorEntryFlags
RETURN:		es:si	= locked OLFileSelectorEntry
				(not valid if bx = 0)
		bx	= handle of file buffer
				(0 if no buffer)
DESTROYED:	ax, bp, cx, dx
		si if RUDY and non-exclusive file selector

PSEUDO CODE/STRATEGY:

	For non-exclusive file selectors (Rudy), we ignore the
	passed in entry, and query for the list of selected
	files.  Then, place a loop around the code that fetches a
	single file's information.  The code reads sort of like this:

	    setup
	  #if NON_EXCLUSIVE
	    get selections
	    for (n=0; n<numSelections; n++) {
	       set up for calculating flags of N'th selected file
	  #endif

	       compute flags for file

	  #if NON_EXCLUSIVE
	       combine file's flags in with group
	    }
	  #endif

	    send notification message


KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/13/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


OLFSBuildEntryFlagsAndSendADLow proc	near
	class	OLFileSelectorClass
	.enter
	mov	dx, si				; preserve our chunk
	mov	ax, cx				; ax = entry #

						; showing parent dir?
	test	ds:[di].OLFSI_state, mask OLFSS_SHOW_PARENT_DIR
	jz	actualBufferEntry		; no, use actual buffer entry
	tst	ax				; first entry?
	jnz	bufferEntry			; no, is buffer entry
	;
	; build entry flags for first entry (current directory)
	;	bp = initial GenFileSelectorEntryFlags
	;
	ornf	bp, GFSET_SUBDIR shl offset GFSEF_TYPE	; update initial flags
	;XXX set READ_ONLY bit?
noBuffer:
	mov	cx, bp				; cx - initial flags
	mov	bx, 0				; no buffer to unlock
	jmp	checkNoEntries

bufferEntry:
	dec	cx				; adjust to buffer entry #
actualBufferEntry:

	;
	; if no files, skip flag setting via buffer
	;
	tst	ds:[di].OLFSI_numFiles		; any files?
	jz	noBuffer			; nope

doMultiple::
	;
	; Point es:si to the OLFileSelectorEntry for the passed entry number
	;
	call	OLFSDerefIndexBuffer		; si = offset into file buffer
	mov	bx, ds:[di].OLFSI_fileBuffer	; lock file buffer
	call	OLFSMemLock_ES			; es:si = entry to open


	;
	; Now go through the involved process of constructing the GFSEF
	; flags for the beast. Start by determining the type of entry
	; we've got.
	; 
	mov	cx, bp				; cx <- initial flags


	CheckHack <GFSET_VOLUME eq GFSET_SUBDIR+1 and \
		   GFSET_SUBDIR eq GFSET_FILE+1>

	;
	; If it's a disk drive (FA_VOLUME is set), there are no other flags to
	; set besides the type.
	; 
	ornf	cx, GFSET_VOLUME shl offset GFSEF_TYPE	; assume showing volume
	test	es:[si].OLFSE_fileAttrs, mask FA_VOLUME
	jnz	endSettingFlags
	
	;
	; Assume it's a directory instead. If so, we have only the 
	; read-only flag to check.
	; 
	sub	cx, 1 shl offset GFSEF_TYPE	; assume click on subdir
	test	es:[si].OLFSE_fileAttrs, mask FA_SUBDIR	; a directory?
	jnz	checkReadOnly			; yes

	;
	; Else the thing is a regular file, so adjust the type...
	; 
	sub	cx, 1 shl offset GFSEF_TYPE	; is file

	;
	; And merge in the document flags from OLFSE_fileFlags.
	; 
	CheckHack <offset GFHF_TEMPLATE eq 15 and \
		   offset GFHF_SHARED_MULTIPLE eq 14 and \
		   offset GFHF_SHARED_SINGLE eq 13 and \
		   offset GFSEF_TEMPLATE eq 10 and \
		   offset GFSEF_SHARED_MULTIPLE eq 9 and \
		   offset GFSEF_SHARED_SINGLE eq 8>
	mov	cl, es:[si].OLFSE_fileFlags.high
	andnf	cl, (mask GFHF_TEMPLATE or mask GFHF_SHARED_MULTIPLE or \
		     mask GFHF_SHARED_SINGLE) shr 8
	rol	cl		; rotate the GFHF flags into their
	rol	cl		;  corresponding positions in the GFSEF
	rol	cl		;  record
	ornf	ch, cl		; and merge them into same
	clr	cl		; no flags in low byte, yet...

if FSEL_DISABLES_FILTERED_FILES
	;
	; Check if the entry is in the rejected list (entry is filtered out)
	; if this is the case then add GFSEF_DISABLED to cx.	
	;
	call	OLFSCheckIfDisabled	; cx <- GenFileSelectoryEntryFlags
endif	; FSEL_DISABLES_FILTERED_FILES
		
checkReadOnly:
	;
	; If entry is read-only, set the appropriate flag.
	; 
	test	es:[si].OLFSE_fileAttrs, mask FA_RDONLY
	jz	endSettingFlags
	ornf	cx, mask GFSEF_READ_ONLY

endSettingFlags:



checkNoEntries:
	;
	; If no files, set GFSEF_NO_ENTRIES
	;
	tst	ds:[di].OLFSI_numFiles
	jnz	haveFiles
	ornf	cx, mask GFSEF_NO_ENTRIES
haveFiles:

	;
	; If the entry # is 0, then this is the parent directory entry
	;
	test	ds:[di].OLFSI_state, mask OLFSS_SHOW_PARENT_DIR
	jz	notParentDir		; no, don't set flag
	tst	ax
	jnz	notParentDir
	ornf	cx, mask GFSEF_PARENT_DIR
notParentDir:

	;
	; If error signaled, set the appropriate flag and clear the error,
	; unless handling MSG_GEN_FILE_SELECTOR_OPEN_ENTRY, as error flag
	; will be returned by that message's handler instead.
	; 
	test	ds:[di].OLFSI_state, mask OLFSS_FORCE_OPEN
	jnz	sendAD
	test	ds:[di].OLFSI_state, mask OLFSS_RESCAN_ERROR
	jz	sendAD
	ornf	cx, mask GFSEF_ERROR
	andnf	ds:[di].OLFSI_state, not mask OLFSS_RESCAN_ERROR

sendAD:
	; *ds:dx = file selector
	; ax	 = entry #
	; cx	 = GenFileSelectorEntryFlags
	; es:si	 = OLFileSelectorEntry
	; bx	 = fileBuffer handle.
	; if RUDY & non-exclusive,
	;   bp = GenFileSelectorEntryFlags mask
	;   ax = number of selections
	;   si = handle of selections block

	xchg	si, dx				; *ds:si = OLFileSelector
	call	OLFSSendAD			; destroys nothing

	mov	si, dx				; es:si <- entry again

	.leave
	ret
OLFSBuildEntryFlagsAndSendADLow		endp

if FSEL_DISABLES_FILTERED_FILES

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFSCheckIfDisabled
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks if the entry is in the reject list, if the
		GFSEF_DISABLED flag is set.

CALLED BY:	(INTERNAL) OLFSBuildEntryFlagsAndSendADLow
PASS:		ds:di = OLFileSelectorInstance
		es:si = OLFileSelectorEntry
		cx = GenFileSelectorEntryFlags
RETURN:		cx = GenFileSelectorEntryFlags
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	10/ 6/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLFSCheckIfDisabled	proc	near
	uses	ax,bx,dx,si,di,es
	.enter
	;
	; see if file was rejected by filter routine
	;
	mov	dx, ds:[di].OLFSI_numRejects
	tst	dx
	jz	noRejects
	mov	ax, ds:[di].OLFSI_rejectList
	tst	ax
	jz	noRejects
	mov_tr	bx, ax
	call	MemLock
	jc	noRejects		; bail if lock error
	push	cx
	pushdw	es:[si].OLFSE_id		
	mov	es, ax			; es:di = first FileID in reject list
	clr	di
	mov	cx, dx			; cx <- number of rejects	
	popdw	dxax	
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
	pop	cx
	;
	; If the the carry is not set then we have a disabled file and we
	; set the appropriate flag.
	;
	jc	noRejects
	ornf	cx, mask GFSEF_DISABLED	
noRejects:
	.leave
	ret
OLFSCheckIfDisabled	endp
endif	;FSEL_DISABLES_FILTERED_FILES


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFSResolveSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	set current selection

CALLED BY:	INTERNAL
			OLFileSelectorSetSelection
			OLFSRescanLow

PASS:		ds:di = generic instance
		ds:si = specific instance

RETURN:		dx = entry number to select
		carry clear if selection passed AND found
		carry set otherwise

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Resolving '.' (the current directory first entry) will fail
		to find a match in the file buffer, causing the first entry
		to be selected.  This is the desired result.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	03/02/90	Initial version
	brianc	4/91		Completed 2.0 revisions

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

OLFSResolveSelection	proc	near

	uses	ax, bx, cx, ds, si, es, di

	class	OLFileSelectorClass

	matchString	local	fptr
	matchFound	local	byte
	.enter

	mov	matchFound, 0			; no match

	mov	dx, 0				; assume no files
						; (assume select first entry)
						; showing parent directory?
	test	ds:[si].OLFSI_state, mask OLFSS_SHOW_PARENT_DIR
	jnz	haveDefaultSelection		; yes, use dx=0
	dec	dx				; else, use dx=-1 (no selection)

haveDefaultSelection:

	cmp	ds:[si].OLFSI_numFiles, 0	; any files?
	LONG je	exit				; no, select first entry
						;	current dir (dx = 0)
	add	di, offset GFSI_selection	; ds:di = match string
SBCS <	cmp	{byte} ds:[di], 0		; null string?		>
DBCS <	cmp	{wchar}ds:[di], 0		; null string?		>
	LONG je	exitWithFirstEntry		; yes, select first entry

	mov	matchString.segment, ds		; save string to match
	mov	matchString.offset, di

	mov	di, si				; ds:di = specific instance

	mov	bx, ds:[di].OLFSI_indexBuffer	; lock index buffer
	tst	bx
	jz	exitWithFirstEntry		; no buffer, select first entry
	push	ds, di				; save specific instance
	push	ds:[di].OLFSI_fileBuffer	; get file buffer
	mov	cx, ds:[di].OLFSI_numFiles	; cx = file count
	call	MemLock
	mov	ds, ax				; ds:si = index buffer
	clr	si
	pop	bx
	call	OLFSMemLock_ES			; lock file buffer
	mov	ss:[matchFound], 1
fileLoop:
	inc	dx				; advance counter to next entry
	lodsw					; ax = file buffer offset
	mov	di, ax				; es:di = entry
	push	ds, si, di, cx			; save stuff
	lds	si, matchString			; ds:si = string to match
	add	di, offset OLFSE_name		; offset to name
if DBCS_PCGEOS
	call	LocalStringLength		;cx <- length w/o NULL
	inc	cx				;cx <- length w/ NULL
else
	push	di				; save entry name
	mov	cx, -1
	clr	al				; find null-terminator
	repne scasb
	not	cx				; cx = entry name length + null
	pop	di				; retrieve entry name
endif
SBCS <	repe cmpsb				; does it match desired name?>
DBCS <	repe cmpsw				; does it match desired name?>
	pop	ds, si, di, cx			; retrieve stuff
	loopne	fileLoop
	je	unlockBuffers
	clr	dx				; select first entry
	mov	ss:[matchFound], 0

unlockBuffers:
	pop	ds, di				; retrieve specific instance
	mov	bx, ds:[di].OLFSI_fileBuffer
	call	MemUnlock			; unlock file buffer
	mov	bx, ds:[di].OLFSI_indexBuffer
	call	MemUnlock			; unlock index buffer
exit:
	cmp	matchFound, 1			; matchFound = 0 if not found
						; matchFound = 1 if found
						; -> C set if not found
						; -> C clear if found
	.leave
	ret			; <<--- EXIT HERE

exitWithFirstEntry:

	mov	dx, 0				; select first entry
	mov	ss:[matchFound], 1		; indicate selection found
	jmp	short exit

OLFSResolveSelection	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFileSelectorUpDirectory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	go up one directory

CALLED BY:	MSG_GEN_FILE_SELECTOR_UP_DIRECTORY

PASS:		*ds:si - instance of OLFileSelector
		ax = MSG_OL_FILE_SELECTOR_PATH_BUTTON

RETURN:

DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	01/31/90	Initial version
	brianc	4/91		Completed 2.0 revisions

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLFileSelectorUpDirectory	method	dynamic OLFileSelectorClass, \
					MSG_GEN_FILE_SELECTOR_UP_DIRECTORY,
					MSG_OL_FILE_SELECTOR_CLOSE_DIR_BUTTON

						; showing parent dir entry?
	test	ds:[di].OLFSI_state, mask OLFSS_SHOW_PARENT_DIR
	jz	reallyGoUp			; nope, go really up

	push	si				; save OLFileSelector chunk
	mov	bx, ds:[di].OLFSI_uiBlock	; ^lbx:si = dynamic list
	mov	si, offset OLFileSelectorFileList
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			; ax = current selection
	pop	dx				; restore OLFileSelector chunk
	tst	ax				; first entry selected?
	jz	goUp				; if so, then really go up
	;
	; just move selection to first entry
	;
	push	dx				; save OLFileSelector chunk
	clr	cx				; set first entry
if _FILE_TABLE
	call	OLFSSetFileTableSelection
else
	call	OLFSSetGenItemSelection
endif
	clr	bp				; bp = first entry
	pop	si				; *ds:si = OLFileSelector
	call	OLFSBuildEntryFlagsAndSendAD
if not SINGLE_DRIVE_DOCUMENT_DIR and FSEL_HAS_CHANGE_DIRECTORY_POPUP
	call	OLFSShowCurrentDir		; update to reflect new
						;	selection
endif
	jmp	short done

goUp:
	mov	si, dx				; *ds:si = OLFileSelector
reallyGoUp:
	mov	cx, OLFS_UP_DIRECTORY_ENTRY_NUM	; else, go up one level
	call	OLFileSelectorListMethod
done:
	ret
OLFileSelectorUpDirectory	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFileSelectorDocumentButtonHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	go to document directory and turn on "can't navigate
		above current directory" mode, if requested

CALLED BY:	MSG_OL_FILE_SELECTOR_DOCUMENT_BUTTON

PASS:		*ds:si - instance of OLFileSelector
		ax = MSG_OL_FILE_SELECTOR_DOCUMENT_BUTTON

RETURN:

DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLFileSelectorDocumentButtonHandler	method	dynamic OLFileSelectorClass, \
					MSG_OL_FILE_SELECTOR_DOCUMENT_BUTTON

if SINGLE_DRIVE_DOCUMENT_DIR
	mov	al, DOCUMENT_DRIVE_NUM		; brute force disk check, 
	call	DiskRegisterDisk		;   to avoid weird DOS problems
	jc	error				;   with the disk not being in
						;   the drive on startup, and
						;   to speed things up. 1/21/94
endif
	;
	; Change to the document directory
	;
NOFXIP<	mov	cx, cs							>
NOFXIP<	mov	dx, offset rootPath					>
	
FXIP <	push	ds							>
FXIP <	segmov	ds, cs, dx						>
FXIP <	mov	dx, offset rootPath					>
FXIP <  clr	cx							>
FXIP <	call	SysCopyToStackDSDX					>
FXIP <	mov	cx, ds			; cx:dx = string		>
FXIP <	pop	ds							>

	mov	bp, SP_DOCUMENT
	mov	ax, MSG_OL_FILE_SELECTOR_PATH_SET
	call	ObjCallInstanceNoLock
FXIP <	call	SysRemoveFromStack					>
	jc	error				; error
	;
	; update "Change Drive" popup moniker to show DOCUMENT drive
	;
	mov	dx, FALSE			; set back to "Change Drives"
if not SINGLE_DRIVE_DOCUMENT_DIR and FSEL_HAS_CHANGE_DRIVE_POPUP
	call	OLFSUpdateChangeDrivePopupMoniker
endif
	;
	; update selected item in "Change Drive" popup list
	;
updateDrive:
if not SINGLE_DRIVE_DOCUMENT_DIR and FSEL_HAS_CHANGE_DRIVE_POPUP
	call	OLFSSelectCurrentDriveInChangeDrivePopup
endif
	jmp	short done

error:
	push	si				; save FS chunk
	call	OLFSNotifyUserOfDiskError	; report error and leave
						;	current filelist
	pop	si				; restore FS chunk

if	not SINGLE_DRIVE_DOCUMENT_DIR
	jmp	short updateDrive		; restore selected drive
endif

done:
	ret
OLFileSelectorDocumentButtonHandler	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFileSelectorOpenEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open entry specified.  This should be used to manually open
		a directory or a volume, as needed when user clicks a
		"Open"-type button that is in the same dialog box as the
		GenFileSelector.  Has no effect if entry is a file.

		Typically, the entry number passed will have been extracted
		from the GenFileSelectorEntryFlags sent to the action
		descriptor, or returned from MSG_GEN_FILE_SELECTOR_GET_SELECTION.

		Only valid after GenFileSelector is made visible, as the file
		list is destroyed when the File Selector is brought off the
		screen.

CALLED BY:	MSG_GEN_FILE_SELECTOR_OPEN_ENTRY

PASS:		*ds:si = OLFileSelector instance
		cx = entry #

RETURN:		carry clear if no error
		carry set if error

DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	02/21/90	Initial version
	brianc	4/91		Completed 2.0 revisions

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLFileSelectorOpenEntry		method	dynamic OLFileSelectorClass, \
						MSG_GEN_FILE_SELECTOR_OPEN_ENTRY

						; showing parent dir?
	test	ds:[di].OLFSI_state, mask OLFSS_SHOW_PARENT_DIR
	jz	skipParentDirCheck		; nope, skip special check
	jcxz	done				; no effect on first entry
skipParentDirCheck:
	mov	ax, ds:[di].OLFSI_numFiles	; ax = number of files
	tst	ax
	jz	error				; no files -> indicate error

	cmp	cx, ax							
;if there are X files and OLFSS_SHOW_PARENT_DIR is set, then the maximum entry
;number is X because of first entry for current directory.  If
;OLFSS_SHOW_PARENT_DIR is not set, then the maximum entry number is X-1, as
;entry numbers are 0-based.  OLFileSelectorDoublePress deals with this before
;accessing file buffer
EC <	ERROR_A	OL_FILE_SELECTOR_BAD_ENTRY_NUMBER			>
EC <	test	ds:[di].OLFSI_state, mask OLFSS_SHOW_PARENT_DIR		>
EC <	jnz	validEntry						>
EC <	cmp	cx, ax							>
EC <	ERROR_AE	OL_FILE_SELECTOR_BAD_ENTRY_NUMBER		>
NEC <	ja	error							>
NEC <	test    ds:[di].OLFSI_state, mask OLFSS_SHOW_PARENT_DIR         >
NEC <	jnz	validEntry						>
NEC <	cmp	cx, ax							>
NEC <	jae	error							>
validEntry:
						; force opening of dirs/vols
	ornf	ds:[di].OLFSI_state, mask OLFSS_FORCE_OPEN

	push	si				; save instance handle
						; simulate double-click
	call	OLFileSelectorDoublePress	; (may set OLFSS_RESCAN_ERROR)
	pop	si				; retrieve instance handle

	call	OLFSDeref_SI_Spec_DI		; ds:di = specific instance
	andnf	ds:[di].OLFSI_state, not mask OLFSS_FORCE_OPEN
						; assume no error
	test	ds:[di].OLFSI_state, mask OLFSS_RESCAN_ERROR
	jz	done				; no error (carry clear)
						; else, clear error flag...
	andnf	ds:[di].OLFSI_state, not mask OLFSS_RESCAN_ERROR
error:
	stc					; ...and indicate error
done:
	ret
OLFileSelectorOpenEntry		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFileSelectorSuspend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Begin suspension of file selector rescanning to allow
		changing mulitple attributes with having multiple rescans.
		Only the following attribute setting methods are affect:
			MSG_GEN_FILE_SELECTOR_SET_SELECTION
			MSG_GEN_FILE_SELECTOR_SET_PATH
			MSG_GEN_FILE_SELECTOR_SET_MASK
			MSG_GEN_FILE_SELECTOR_SET_FILE_ATTRS
			MSG_GEN_FILE_SELECTOR_SET_TOKEN
			MSG_GEN_FILE_SELECTOR_SET_CREATOR
			MSG_GEN_FILE_SELECTOR_SET_GEODE_ATTR
			MSG_GEN_FILE_SELECTOR_SET_ATTRS
			MSG_GEN_FILE_SELECTOR_SET_FILE_CRITERIA

CALLED BY:	MSG_GEN_FILE_SELECTOR_SUSPEND

PASS:		*ds:si - OLFileSelector instance

RETURN:		carry clear if successful
		carry set if already suspended

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	04/08/91	Initial version
	brianc	4/91		Completed 2.0 revisions

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLFileSelectorSuspend	method	dynamic OLFileSelectorClass, \
					MSG_GEN_FILE_SELECTOR_SUSPEND
	test	ds:[di].OLFSI_state, mask OLFSS_SUSPENDED
	stc					; assume already suspended
	jnz	done
						; else, suspend
	ornf	ds:[di].OLFSI_state, mask OLFSS_SUSPENDED
done:
	ret
OLFileSelectorSuspend	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFileSelectorEndSuspend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	End suspension of file selector rescanning.  File selector
		is rescanned with current attributes.

CALLED BY:	MSG_GEN_FILE_SELECTOR_END_SUSPEND

PASS:		*ds:si - OLFileSelector instance

RETURN:		carry clear if successful (file list rescanned)
		carry set if not suspended

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	04/08/91	Initial version
	brianc	4/91		Completed 2.0 revisions

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLFileSelectorEndSuspend	method	dynamic OLFileSelectorClass, \
					MSG_GEN_FILE_SELECTOR_END_SUSPEND
	test	ds:[di].OLFSI_state, mask OLFSS_SUSPENDED
	stc					; assume not suspended
	jz	done
						; else, end suspension
	mov	ax, ds:[di].OLFSI_state
	andnf	ds:[di].OLFSI_state, not (mask OLFSS_SUSPENDED or \
					  mask OLFSS_RESCAN_NEEDED)
	test	ax, mask OLFSS_RESCAN_NEEDED
	jz	done
	mov	ax, MSG_GEN_FILE_SELECTOR_RESCAN
	call	ObjCallInstanceNoLock
done:
	ret
OLFileSelectorEndSuspend	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLFileSelectorActivateObjectWithMnemonic --
		MSG_SPEC_ACTIVATE_OBJECT_WITH_MNEMONIC handler

DESCRIPTION:	Looks at its vis moniker to see if its mnemonic matches
		that key currently pressed.

PASS:		*ds:si	= instance data for object
		ax = MSG_SPEC_ACTIVATE_OBJECT_WITH_MNEMONIC
		cx = charValue
		dl = CharFlags
			CF_RELEASE - set if release
			CF_STATE - set if shift, ctrl, etc.
			CF_TEMP_ACCENT - set if accented char pending
		dh = ShiftState
		bp low = ToggleState (unused)
		bp high = scan code (unused)

RETURN:		carry set if found, clear otherwise

DESTROYED:	bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/92		Initial version

------------------------------------------------------------------------------@

OLFileSelectorActivateObjectWithMnemonic	method	OLFileSelectorClass, \
					MSG_SPEC_ACTIVATE_OBJECT_WITH_MNEMONIC
	call	VisCheckIfFullyEnabled
	jnc	noActivate
	;XXX: skip if menu?
	call	VisCheckMnemonic
	jnc	noFSMatch
	;
	; mnemonic matches, give focus to list
	;
	call	OLFSDeref_SI_Spec_DI		; ds:di = OLFSI_*
	mov	bx, ds:[di].OLFSI_uiBlock
	mov	si, offset OLFileSelectorFileList
	mov     ax, MSG_META_GRAB_FOCUS_EXCL
sendMessage:
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call    ObjMessage
done:
	stc				;handled
	jmp	short exit

noFSMatch:
;
; remove hidden keyboard mnenonics, too easily conflicts with other mnemonics
; in window containing file selector - brianc 3/4/93
;
if 0
	;
	; check if mnemonic matches "Open" or "Close" mnemonics
	;	cl = character
	;
	; XXX: update this if mnemonic for "Close" changes
	; XXX: update this if mnemonic for "Open" changes
	;
	cmp	cl, 'r'
	je	open
	cmp	cl, 'R'
	jne	notOpen
open:
	mov	ax, MSG_OL_FILE_SELECTOR_OPEN_DIR_BUTTON
	jmp	short sendButtonMessage

notOpen:
	cmp	cl, 'l'
	je	close
	cmp	cl, 'L'
	jne	notClose
close:
	mov	ax, MSG_OL_FILE_SELECTOR_CLOSE_DIR_BUTTON
sendButtonMessage:
	call	ObjCallInstanceNoLock
	jmp	short done

notClose:
endif

;
; add in hidden mnemonic for drive popup, which loses mnemonic when changed
; to drive letter:[drive name] - brianc 3/28/93
;
; no ChangeDrivePopup for WIZARDBA
;
if not SINGLE_DRIVE_DOCUMENT_DIR and FSEL_HAS_CHANGE_DRIVE_POPUP
	call	OLFSDeref_SI_Gen_DI		; ds:di = GFSI_*
	test	ds:[di].GFSI_attrs, mask FSA_HAS_CHANGE_DRIVE_LIST
	jz	notDrivePopup
	LocalCmpChar cx, 'v'
	je	openDrivePopup
	LocalCmpChar cx, 'V'
	jne	notDrivePopup
openDrivePopup:
	mov	ax, MSG_GEN_ACTIVATE
	mov	di, offset OLFileSelectorChangeDrivePopup
	call	OLFSCallUIBlockGadget		;ax = entry number
	jmp	short done
notDrivePopup:
endif

noActivate:
	;
	; let superclass call children, since either were are not fully
	; enabled, or our mnemonic doesn't match, superclass won't be
	; activating us, just calling our children
	;
	mov	ax, MSG_SPEC_ACTIVATE_OBJECT_WITH_MNEMONIC
	mov	di, offset OLFileSelectorClass
	call	ObjCallSuperNoLock
exit:
	Destroy	ax, cx, dx, bp
	ret
OLFileSelectorActivateObjectWithMnemonic	endm

;
; miscellaneous byte-saving routines
;
OLFSMemLock_ES	proc	near
	push	ax
	call	MemLock
	mov	es, ax
	pop	ax
	ret
OLFSMemLock_ES	endp

OLFSDeref_SI_Gen_DI	proc	near
EC <	call	ECCheckObject						>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	ret
OLFSDeref_SI_Gen_DI	endp

OLFSDeref_SI_Spec_DI	proc	near
EC <	call	ECCheckObject						>
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	ret
OLFSDeref_SI_Spec_DI	endp


;
; pass:		*ds:si = OLFileSelector
; return:	ds:bx = GFS temp data
;
OLFSFindTempData	proc	near
	uses	ax
	.enter
EC <	call	ECCheckObject						>
	mov	ax, TEMP_GEN_FILE_SELECTOR_DATA
	call	ObjVarDerefData		; ds:bx = var data entry
	.leave
	ret
OLFSFindTempData	endp

;
; pass:		^lbx:si = gen object
;		cx;dx = moniker text
; return:	nothing
;
if not SINGLE_DRIVE_DOCUMENT_DIR and (FSEL_HAS_CHANGE_DRIVE_POPUP or FSEL_HAS_CHANGE_DIRECTORY_POPUP)

OLFSReplaceVisMonikerText	proc	near
	uses	bp
	.enter
	mov	bp, VUM_DELAYED_VIA_UI_QUEUE
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_TEXT
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	.leave
	ret
OLFSReplaceVisMonikerText	endp

endif

;
; pass:
;	*ds:si = OLFileSelector
; return:
;	cx = selection number
; destroyed:
;	ax, bx, dx, di
;
OLFSGetFileListSelection	proc	near
	uses	bp				;save OLFileSelector chunk
	.enter
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, offset OLFileSelectorFileList
	call	OLFSCallUIBlockGadget		;ax = entry number
	mov	cx, ax				;cx = entry number
	.leave
	ret
OLFSGetFileListSelection	endp

;
; pass:
;	*ds:si = OLFileSelector
;	dx = TRUE to use current drive, FALSE to use "Change Drive"
; return:
;	nothing
; destroyed:
;	ax, bx, cx, dx, di
;



if not SINGLE_DRIVE_DOCUMENT_DIR and FSEL_HAS_CHANGE_DRIVE_POPUP

OLFSUpdateChangeDrivePopupMoniker	proc	near
	uses	es
driveBuffer	local	FileLongName
	.enter
	;
	; don't bother if no change drive list
	;
	call	OLFSDeref_SI_Gen_DI
	test	ds:[di].GFSI_attrs, mask FSA_HAS_CHANGE_DRIVE_LIST
	LONG jz	done

	mov	cx, segment olFileSelectorStaticDrivePopupMoniker
	mov	es, cx
	tst	es:[olFileSelectorStaticDrivePopupMoniker]
	LONG jnz	useChangeDrive			; force "Change Drive"
	tst	dx
	LONG jz	useChangeDrive
	;
	; get moniker from current drive
	;
if HAVE_FAKE_FILE_SYSTEM
	test	ds:[di].GFSI_fileCriteria, mask FSFC_USE_FAKE_FILE_SYSTEM
	LONG_EC	jnz	getFakeVolName
endif

	call	OLFSGetCurrentDrive		; bx = disk handle
						; al = drive #
	segmov	es, ss
	lea	di, driveBuffer
	mov	cx, size driveBuffer
	mov	dx, mask SDAVNF_PASS_DISK_HANDLE
	call	OLFSStuffDriveAndVolumeName
	;
	; before actually setting the moniker, let's see if the current
	; moniker is already what we're going to set
	;
haveVolName:
	push	si, es
	call	OLFSDeref_SI_Spec_DI
	mov	bx, ds:[di].OLFSI_uiBlock
	tst	bx
	jz	noUIBlock			; skip with match
	call	ObjSwapLock
	mov	ax, MSG_GEN_GET_VIS_MONIKER
	mov	si, offset OLFileSelectorChangeDrivePopup
	push	bp
	call	ObjCallInstanceNoLock		; *ds:ax = moniker chunk
	pop	bp
	tst	ax
	jz	haveResult			; no moniker, no match
	mov	si, ax
	mov	si, ds:[si]			; ds:si = VisMoniker
	test	ds:[si].VM_type, mask VMT_GSTRING
	jnz	haveResult			; is gstring, no match
	ChunkSizePtr	ds, si, cx		; cx = VisMoniker size
						; cx = size of text
	sub	cx, size VisMoniker + size VMT_mnemonicOffset
	lea	si, ds:[si].VM_data.VMT_text	; ds:si = null term'ed text
	segmov	es, ss				; es:di = desired moniker
	lea	di, driveBuffer
	repe cmpsb				; compare (Z set if match)
haveResult:
	call	ObjSwapUnlock			; preserves flags
noUIBlock:
	pop	si, es
	je	afterSet			; match, don't set again

	mov	cx, ss				; cx:dx = drive name vol name
	lea	dx, driveBuffer
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_TEXT
	push	bp
	mov	bp, VUM_DELAYED_VIA_UI_QUEUE
	mov	di, offset OLFileSelectorChangeDrivePopup
	call	OLFSCallUIBlockGadget
	pop	bp
afterSet:
	call	OLFSDeref_SI_Spec_DI
	ornf	ds:[di].OLFSI_state, mask OLFSS_SHOWING_DRIVE_LETTER
	jmp	short done

if HAVE_FAKE_FILE_SYSTEM
getFakeVolName:
	mov	ax, MSG_GEN_FILE_SELECTOR_FAKE_VOLUME_NAME_GET
	mov	dx, ss
	push	bp
	lea	bp, driveBuffer		; dx:bp = driveBuffer
	clr	cx			; get the current drives volname
	call	ObjCallInstanceNoLock
	pop	bp
	tst	ax
	jnz	done		; this would be a minor failure..  do nothing
	mov	es, dx
	jmp	haveVolName
endif	;HAVE_FAKE_FILE_SYSTEM

useChangeDrive:
	call	OLFSDeref_SI_Spec_DI
	test	ds:[di].OLFSI_state, mask OLFSS_SHOWING_DRIVE_LETTER
	jz	done				; already showing change drive
	mov	cx, handle ChangeDriveMoniker
	mov	dx, offset ChangeDriveMoniker	; ^lcx:dx = "Change Drive" mkr
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_OPTR
	push	bp
	mov	bp, VUM_DELAYED_VIA_UI_QUEUE
	mov	di, offset OLFileSelectorChangeDrivePopup
	call	OLFSCallUIBlockGadget
	pop	bp
	call	OLFSDeref_SI_Spec_DI
	andnf	ds:[di].OLFSI_state, not mask OLFSS_SHOWING_DRIVE_LETTER
done:

	.leave
	ret
OLFSUpdateChangeDrivePopupMoniker	endp

endif


;
; pass:
;	*ds:si = OLFileSelector
; returned:
;	bx = disk handle
;	al = drive number
; destroyed:
;	ah
;
if not SINGLE_DRIVE_DOCUMENT_DIR and (FSEL_HAS_CHANGE_DRIVE_POPUP or FSEL_HAS_CHANGE_DIRECTORY_POPUP)
OLFSGetCurrentDrive	proc	near
	mov	ax, ATTR_GEN_PATH_DATA
	mov	dx, TEMP_GEN_PATH_SAVED_DISK_HANDLE
	call	GenPathFetchDiskHandleAndDerefPath	; ax = disk handle
							; ds:bx = GenFilePath
	mov	bx, ax				; bx = disk handle
	call	DiskGetDrive			; al = drive #
	ret
OLFSGetCurrentDrive	endp
endif

;
; pass:
;	*ds:si = OLFileSelector
;	dx = TRUE if at root, FALSE if not
; return:
;	nothing
; destroyed:
;	ax, bx, cx, dx, di
;
if not SINGLE_DRIVE_DOCUMENT_DIR and FSEL_HAS_CHANGE_DIRECTORY_POPUP

OLFSDisableCloseAndChangeDirectoryButtonsIfFirstEntryAndIsRoot	proc	near
	uses	bp
	.enter

	call	OLFSDeref_SI_Spec_DI		; ds:di = spec instance
						; showing parent dir?
	test	ds:[di].OLFSI_state, mask OLFSS_SHOW_PARENT_DIR
	jz	firstEntry			; no, always check root
	push	dx
	call	OLFSGetFileListSelection	; cx = entry number
	pop	dx
	jcxz	firstEntry
enableClose:
	mov	ax, MSG_GEN_SET_ENABLED
	jmp	short haveMessage

firstEntry:
	;
	; first selected, disable if either at root or at virtual root
	; (possible failure to set 'atRoot' correctly in the case where
	; we have a virtual root (in the OLFSShowCurrentDir routine) requires
	; us to check for the virtual root case first)
	;
	call	OLFSIsCurDirVirtualRoot		; at virtual root?
	jc	disableClose			; yes, disable
	tst	dx				; at root?
	jz	enableClose			; no, enable
disableClose:
	mov	ax, MSG_GEN_SET_NOT_ENABLED
haveMessage:
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	di, offset OLFileSelectorChangeDirectoryPopup
	call	OLFSCallUIBlockGadget
	.leave
	ret
OLFSDisableCloseAndChangeDirectoryButtonsIfFirstEntryAndIsRoot	endp

endif

;
; pass:
;	*ds:si = file selector
;	dx = current path disk handle
;	es:di = current path tail
; return:
;	nothing
; destroyed:
;	ax, bx, cx, dx, di, es
;

if not SINGLE_DRIVE_DOCUMENT_DIR and FSEL_HAS_DOCUMENT_BUTTON

OLFSDisableDocButtonIfDocDir	proc	near
	uses	bp
	.enter
	push	ds, si


	mov	cx, SP_DOCUMENT			; cx = document disk handle
; changed to work for both xip and not xip 
;	segmov	ds, cs				; ds:si = document path
;	mov	si, offset nullPath					
	clr	si
	mov	ds, si				; ds = 0 means nullPath
compare:
if _ISUI
	call	OLFSFileComparePathsEvalLinks
else
	call	FileComparePaths		; al = PathCompareType
endif
	pop	ds, si
	cmp	al, PCT_EQUAL			; document dir?
	mov	ax, MSG_GEN_SET_ENABLED		; assume not doc dir
	jne	haveMessage			; nope --> enable
	mov	ax, MSG_GEN_SET_NOT_ENABLED	; else, disable
haveMessage:
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	di, offset OLFileSelectorDocumentButton
	call	OLFSCallUIBlockGadget
	.leave
	ret
OLFSDisableDocButtonIfDocDir	endp


endif

LocalDefNLString nullPath <0>

if _FILE_TABLE
;
; pass:
;	^lbx:si = Table object
;	cx = selection number
; return:
;	nothing
; destroyed:
;	ax, di (bx, cx, dx allowed)
;
OLFSSetFileTableSelection	proc	near
	mov	ax, MSG_JTABLE_SCROLL_SELECT_ROW
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	ret
OLFSSetFileTableSelection	endp
endif

;
; pass:
;	^lbx:si = GenItemGroup
;	cx = selection number
;	(if RUDY, *ds:dx = OLFileSelector)
; return:
;	nothing
; destroyed:
;	ax, cx, bx, dx, di
;
OLFSSetGenItemSelection	proc	near
	uses	bp				;save whatever is in bp
	.enter
	;	Assert  objectOD bxsi, GenItemGroupClass
	clr	dx				;not indeterminate
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	call	ObjMessage

	
	.leave
	ret
OLFSSetGenItemSelection	endp


;
; pass:
;	*ds:si = OLFileSelector
;	di = chunk handle of OLFSI_uiBlock gadget to call
;	ax, cx, dx, bp = message data
; return:
;	ax, cx, dx, bp = message return values
; destroyed:
;	bx, di
; 
OLFSCallUIBlockGadget	proc	near
	uses	si
	.enter
	push	di
	call	OLFSDeref_SI_Spec_DI
	mov	bx, ds:[di].OLFSI_uiBlock	; ^lbx:si = gadget
	pop	si
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	.leave
	ret
OLFSCallUIBlockGadget	endp

StuffDriveAndVolumeNameFlags	record
	SDAVNF_PASS_DISK_HANDLE:1		; set if disk handle is passed
						; clear to generate disk handle
	SDAVNF_VOLUME_ONLY_FOR_FIXED:1		; set if volume names should
						;	only be generated for
						;	non-removable media
	SDAVNF_TRAILING_SLASH:1			; set to add trialing slash
StuffDriveAndVolumeNameFlags	end
;
; pass:
;	es:di = buffer for drive and volume name
;	cx = size of buffer
;	al = drive #
;	dx = StuffDriveAndVolumeNameFlags
;	ah = DriveStatus (if SDAVNF_VOLUME_ONLY_FOR_FIXED)
;	bx = disk handle (if SDAVNF_PASS_DISK_HANDLE)
; return:
;	es:di = points at null-terminator at end of as much info as will fit
;		into buffer
; destroyed:
;	ax, cx
;
OLFSStuffDriveAndVolumeName	proc	near
	uses	bx
	.enter
SBCS <	mov	{byte} es:[di], 0		; in case not enough room >
DBCS <	mov	{wchar}es:[di], 0		; in case not enough room >
if SINGLE_DRIVE_DOCUMENT_DIR
SBCS <	dec	cx				; for the NULL            >
DBCS <	sub	cx, size wchar			; for the NULL            >
else
	call	DriveGetName			; fill in drive name
						; es:di = points at null
						; cx = bytes remaining in buffer
	jc	noMoreRoom			; not enough room
SBCS <	cmp	cx, 2				; want to put ':' and null >
DBCS <	cmp	cx, 2*(size wchar)		; want to put ':' and null >
	jb	noMoreRoom
SBCS <	mov	{byte} es:[di], ':'		; (preserve al)		>
DBCS <	mov	{wchar} es:[di], ':'		; (preserve ax)		>
	LocalNextChar esdi
SBCS <	mov	{byte} es:[di], 0		; leave di at null	>
DBCS <	mov	{wchar}es:[di], 0		; leave di at null	>
SBCS <	sub	cx, 2							>
DBCS <	sub	cx, 2*(size wchar)					>
endif

	test	dx, mask SDAVNF_VOLUME_ONLY_FOR_FIXED	; only for fixed disks?
	jz	stuffVolume			; no, for all
	test	ah, mask DS_MEDIA_REMOVABLE	; fixed disk?
	jnz	afterVolumeName			; no, skip volume name
	;
	; Even if it's not removable, we don't want to get the volume
	; name unless it's a medium we're sure about (Interlink
	; drives, for example are DRIVE_UNKNOWN).
	;
	andnf	ah, mask DS_TYPE
	cmp	ah, DRIVE_FIXED shl offset DS_TYPE
	jne	afterVolumeName
stuffVolume:
	test	dx, mask SDAVNF_PASS_DISK_HANDLE ; do we have disk handle?
	jnz	haveDiskHandle
	call	DiskRegisterDiskSilently
	jc	afterVolumeName			; error, just skip volume name
haveDiskHandle:
SBCS <	cmp	cx, VOLUME_NAME_LENGTH+3	; '[' + name + ']' + null >
DBCS <	cmp	cx, (VOLUME_NAME_LENGTH+3)*2	; '[' + name + ']' + null >
	jb	noMoreRoom
	LocalLoadChar ax, '['
	LocalPutChar esdi, ax
	call	DiskGetVolumeName		; leaves es:di at beginning
						; leaves cx alone
SBCS <	clr	al				; find null-terminator	>
DBCS <	clr	ax				; find null-terminator	>
	LocalFindChar				; repne scasb/scasw
	LocalPrevChar esdi			; point at null
	LocalLoadChar ax, ']'
	LocalPutChar esdi, ax
SBCS <	mov	{byte} es:[di], 0		; leave di at null	>
DBCS <	mov	{wchar}es:[di], 0		; leave di at null	>
SBCS <	sub	cx, 3				; account for '[', ']', etc. >
DBCS <	sub	cx, 3*(size wchar)		; account for '[', ']', etc. >
afterVolumeName:
	test	dx, mask SDAVNF_TRAILING_SLASH
	jz	done
SBCS <	cmp	cx, 2				; want to put '\' and null >
DBCS <	cmp	cx, 2*(size wchar)		; want to put '\' and null >
	jb	noMoreRoom
	mov	{word} es:[di], '\\' or (0 shl 8)	; leave di at null
DBCS <	mov	{wchar}es:[di][2], 0					>
noMoreRoom:
done:
	.leave
	ret
OLFSStuffDriveAndVolumeName	endp
;
; pass:
;	*ds:si = OLFileSelector
; return:
;	nothing
; destroyed:
;	ax, bx, cx, dx, di
;

if not SINGLE_DRIVE_DOCUMENT_DIR and FSEL_HAS_CHANGE_DRIVE_POPUP

OLFSSelectCurrentDriveInChangeDrivePopup	proc	near
	uses	bp
	.enter
	;
	; don't bother if no change drive list
	;
	call	OLFSDeref_SI_Gen_DI
	test	ds:[di].GFSI_attrs, mask FSA_HAS_CHANGE_DRIVE_LIST
	jz	done

	call	OLFSGetCurrentDrive		; bx = disk handle
						; al = drive #
	call	DriveGetStatus			; ah = DriveStatus
;EC <	ERROR_C	OL_ERROR						>
;if the drive is invalid, just leave whatever we have on the assumption
;that this could only occur if the drive was removed since the last time
;we built the change-drive popup list and that we'll be getting a
;META_REMOVING_DISK soon that will clean things up - brianc 6/16/93
	jc	done

	mov	cx, ax				; cx = cur drive identifier
	push	cx				; save it
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	dx				; not indeterminate
	mov	di, offset OLFileSelectorChangeDrivePopup
	call	OLFSCallUIBlockGadget
	pop	cx				; cx = cur drive identifier
	jnc	done				; item not found, give up
	;
	; set moniker correctly
	;
	call	OLFSDeref_SI_Spec_DI		; ds:di = specific instance
	mov	dx, TRUE			; assume using current drive
	test	ds:[di].OLFSI_state, mask OLFSS_SHOWING_DRIVE_LETTER
	jnz	haveFlag
	mov	dx, FALSE
haveFlag:
	call	OLFSUpdateChangeDrivePopupMoniker
done:
	.leave
	ret
OLFSSelectCurrentDriveInChangeDrivePopup	endp

endif

;
; pass:
;	*ds:si = OLFileSelector
;	bx = ui block
; return:
;	nothing
; destroys:
;	ax, cx, dx, bp, di
;


OLFSTurnOffGadgetry	proc	near
	uses	si
	.enter


	call	OLFSDeref_SI_Gen_DI		; ds:di = generic instance
	mov	ax, ds:[di].GFSI_attrs		; ax = FileSelectorAttrs

if FSEL_HAS_DOCUMENT_BUTTON
	test	ax, mask FSA_HAS_DOCUMENT_BUTTON
	mov	si, offset OLFileSelectorDocumentButton
	call	OLFSSetUsableOnFlags
endif

if not SINGLE_DRIVE_DOCUMENT_DIR and FSEL_HAS_CHANGE_DIRECTORY_POPUP
	test	ax, mask FSA_HAS_CHANGE_DIRECTORY_LIST
	mov	si, offset OLFileSelectorChangeDirectoryPopup
	call	OLFSSetUsableOnFlags
endif

if not SINGLE_DRIVE_DOCUMENT_DIR and FSEL_HAS_CHANGE_DRIVE_POPUP
	test	ax, mask FSA_HAS_CHANGE_DRIVE_LIST
	mov	si, offset OLFileSelectorChangeDrivePopup
	call	OLFSSetUsableOnFlags
endif
	test	ax, mask FSA_HAS_FILE_LIST
	mov	si, offset OLFileSelectorFileList
	call	OLFSSetUsableOnFlags

	.leave
	ret
OLFSTurnOffGadgetry	endp

;
; pass:
;	^lbx:si = gadget to set usable/not usable
;	Z flag = 0 to set usable, 1 to set not usable
; return:
;	nothing
; destroyed:
;	cx, dx, di, bp
;

OLFSSetUsableOnFlags	proc	near
	uses	ax
	.enter
	mov	ax, MSG_GEN_SET_USABLE
	jnz	haveUsableMsg
	mov	ax, MSG_GEN_SET_NOT_USABLE
haveUsableMsg:
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	.leave
	ret
OLFSSetUsableOnFlags	endp


;
; pass:
;	*ds:si = OLFileSelector
; return:
;	carry set if current directory is virtual root
; destroyed:
;	nothing
;
OLFSIsCurDirVirtualRoot	proc	near

if 0		;this code isn't working right
	uses	ax, bx, cx, ds, si
	curPathStart	local	2 dup (char)
else
	uses	ax
endif
	.enter

if 0		
	;
	; The normal version of this routine takes up to 10 seconds to complete
	; on Redwood, apparently because B: and A: are being compared and some
	; (slow?) BIOS calls happen.   Anyway, in Redwood we know we're always
	; on the B: drive, and that the root is SP_DOCUMENT, so we'll check for
	; that instead.  6/ 4/94 cbh  (Nuked code, maybe not necessary and 
	; doesn't work right.)
	;
	mov	cx, size curPathStart
	segmov	ds, ss, si
	lea	si, curPathStart
	call	FileGetCurrentPath
	cmp	curPathStart+1, 0		;no path length, done (z=1)
else
	call	OLFSIsCurDirVirtualRootOrUnderVirtualRoot
	jnc	done				; not v.root nor under v.root
	cmp	al, PCT_EQUAL
endif
	stc					; assumme is v.root
	je	done				; yes, done
	clc					; else, indicate not
done:
	.leave
	ret
OLFSIsCurDirVirtualRoot	endp

;
; pass:
;	*ds:si = OLFileSelector
; return:
;	carry set if current directory is virtual root or a subdirectory
;		under the virtual root
;	al = PCT_EQUAL or PCT_SUBDIR
; destroyed:
;	ah
;
OLFSIsCurDirVirtualRootOrUnderVirtualRoot	proc	near
	uses	bx, cx, dx, es, di, si, bp
	.enter
	call	OLFSHaveVirtualRoot
	jnc	done				; no virtual root
	call	OLFSGetCurDir			; dx = cur dir StdPath
						; es:di = cur dir tail
						; (do 1st b/c obj block motion)
	call	OLFSGetVirtualRoot		; cx = v.root StdPath
						; ds:si = v.root tail
EC <	ERROR_NC	OL_ERROR		; no virtual root!??	>
if _ISUI
	call	OLFSFileComparePathsEvalLinks
else
	call	FileComparePaths		; al = PathCompareType
endif
	cmp	al, PCT_EQUAL
	stc					; assume so
	je	done
	cmp	al, PCT_SUBDIR
	stc					; assume so
	je	done
	clc					; else, indicate cur dir is not
						;	v.root or a subdir of
done:
	.leave
	ret
OLFSIsCurDirVirtualRootOrUnderVirtualRoot	endp

;
; pass:
;	*ds:si = OLFileSelector
; return:
;	carry clear if no virtual path
;	carry set if virtual path found
;		cx = best virtual root standard path
;		ds:si = best virtual root tail
; destroyed:
;	nothing
;
OLFSGetVirtualRoot	proc	near
	uses	ax, bx, dx, di, es
	.enter
	call	OLFSHaveVirtualRoot
	jnc	done				; not found, no virtual root
	mov	cx, ds:[bx].GFP_disk		; cx = virtual root StdPath
	lea	si, ds:[bx].GFP_path		; ds:si virtual root tail
	stc					; indicate have virtual root
done:
	.leave
	ret
OLFSGetVirtualRoot	endp

;
; pass:
;	*ds:si = OLFileSelector
; return:
;	carry set if have virtual root
;		ds:bx = GenFilePath
; destroyed:
;	bx - if carry clear
;
OLFSHaveVirtualRoot	proc	near
	uses	ax, di
	.enter
	call	OLFSDeref_SI_Gen_DI		; ds:di = generic instance
	test	ds:[di].GFSI_attrs, mask FSA_USE_VIRTUAL_ROOT
	jz	done				; exit w/ carry clear
	mov	ax, ATTR_GEN_FILE_SELECTOR_VIRTUAL_ROOT
	call	ObjVarFindData			; carry set if found
done:
	.leave
	ret
OLFSHaveVirtualRoot	endp

;
; pass:
;	*ds:si = OLFileSelector
; return:
;	dx = best current directory standard path
;	es:di = current directory path tail w/best standard path
; destroyed:
;	nothing (can cause object block motion)
;
OLFSGetCurDir	proc	near
	uses	ax, bx, cx
	.enter
	mov	ax, ATTR_GEN_PATH_DATA
	mov	dx, TEMP_GEN_PATH_SAVED_DISK_HANDLE
	call	GenPathFetchDiskHandleAndDerefPath	; ax = disk handle
							; ds:bx = GenFilePath
	segmov	es, ds				; es:di = path tail
	lea	di, ds:[bx].GFP_path
	mov	dx, ax				; dx = disk handle
	.leave
	ret
OLFSGetCurDir	endp

;
; pass:
;	*ds:si = OLFileSelector
; return:
;	nothing
; destroyed:
;	ax, cx, dx, di, bp
;
HandleScalableUIData	proc	near
	uses	bx, si
	.enter
	mov	ax, HINT_FILE_SELECTOR_SCALABLE_UI_DATA
	call	ObjVarFindData			; ds:bx = data
	jnc	done				; no hint
	VarDataSizePtr	ds, bx, di		; di = size
	mov	ax, MSG_GEN_APPLICATION_GET_APP_FEATURES
	call	GenCallApplication		; ax = features, dx = UI level
	mov	si, ds:[si]
	add	si, ds:[si].Gen_offset		; ds:si = generic instance
	;
	; evaluate
	;	ax = features in application
	;	dx = UI level
	;	ds:bx = ptr to current GenFileSelectorScalableUIEntry
	;	di = size of all GenFileSelectorScalableUIEntry
	;	ds:si = generic instance
	;
scanLoop:
	push	ax				; save app features
	mov	cl, ds:[bx].GFSSUIE_command	; ax = command
	cmp	cl, GFSSUIC_SET_FEATURES_IF_APP_FEATURE_OFF
	je	setIfAppFeatureOff
	cmp	cl, GFSSUIC_ADD_FEATURES_IF_APP_FEATURE_ON
	je	addIfAppFeatureOn
	cmp	cl, GFSSUIC_SET_FEATURES_IF_APP_LEVEL
	je	setIfAppLevel
	cmp	cl, GFSSUIC_ADD_FEATURES_IF_APP_LEVEL
	je	addIfAppLevel
	cmp	cl, GFSSUIC_SET_FEATURES_IF_APP_FEATURE_ON
EC <	ERROR_NE	OL_ERROR					>
NEC <	jne	short next						>

setIfAppFeatureOn:
	test	ax, ds:[bx].GFSSUIE_appFeature
	jz	next
setFeature:
	mov	ax, ds:[bx].GFSSUIE_fsFeatures
	mov	ds:[si].GFSI_attrs, ax
	jmp	short next

setIfAppFeatureOff:
	test	ax, ds:[bx].GFSSUIE_appFeature
	jz	setFeature
	jmp	short next

addIfAppFeatureOn:
	test	ax, ds:[bx].GFSSUIE_appFeature
	jz	next
addFeature:
	mov	ax, ds:[bx].GFSSUIE_fsFeatures
	ornf	ds:[si].GFSI_attrs, ax
	jmp	short next

setIfAppLevel:
	cmp	dx, ds:[bx].GFSSUIE_appFeature
	jae	setFeature
	jmp	short next

addIfAppLevel:
	cmp	dx, ds:[bx].GFSSUIE_appFeature
	jae	addFeature

next:
	pop	ax				; restore app features
	add	bx, size GenFileSelectorScalableUIEntry
	sub	di, size GenFileSelectorScalableUIEntry
	jnz	scanLoop

done:
	.leave
	ret
HandleScalableUIData	endp



		

;
; handlers for OLFSDynamicListClass
;




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFSDynamicListKbdChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle keyboard navigation

CALLED BY:	MSG_META_KBD_CHAR, MSG_META_FUP_KBD_CHAR

PASS:		*ds:si	= OLFSDynamicListClass object
		ds:di	= OLFSDynamicListClass instance data
		es 	= segment of OLFSDynamicListClass
		ax	= MSG_META_KBD_CHAR, MSG_META_FUP_KBD_CHAR

		cx = character value
		dl = CharFlags
		dh = ShiftState
		bp low = ToggleState
		bp high = scan code

RETURN:		nothing

ALLOWED TO DESTROY:	
		ax, cx, dx, bp
		bx, si, di, ds, es

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/29/93  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLFSDynamicListKbdChar	method	dynamic	OLFSDynamicListClass,
				MSG_META_KBD_CHAR, MSG_META_FUP_KBD_CHAR

						; don't want this stuff
	test	dl, mask CF_RELEASE or mask CF_STATE_KEY or mask CF_TEMP_ACCENT
	jnz	callSuper


SBCS <	cmp	cx, (CS_BSW shl 8) or VC_BLANK	; space?		>
DBCS <	cmp	cx, C_SPACE			; space?		>
	jne	callSuper			; nope, don't care about it
	;
	; space -> like double-clicking on focus item
	;
doSelect:: 
	push	ax, cx, dx, bp
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	call	ObjCallInstanceNoLock		; ax = identifier
	mov	di, ax				; di = identifier
	pop	ax, cx, dx, bp
	cmp	di, GIGS_NONE
	je	callSuper			; no selection, skip
	push	si
	mov	cx, di				; cx = selection
	mov	ax, MSG_OL_FILE_SELECTOR_DOUBLE_PRESS
	mov	bx, segment OLFileSelectorClass
	mov	si, offset OLFileSelectorClass
	mov	di, mask MF_RECORD
	call	ObjMessage			; di = event
	pop	si
	mov	cx, di				; cx = event
	mov	ax, MSG_GEN_GUP_CALL_OBJECT_OF_CLASS
	GOTO	ObjCallInstanceNoLock

callSuper:
	mov	di, offset OLFSDynamicListClass
	GOTO	ObjCallSuperNoLock

OLFSDynamicListKbdChar	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFSCheckIfInteractableObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This is called when a UserDoDialog is on the screen, to see
		if the passed object can get events.

CALLED BY:	GLOBAL
PASS:		cx:dx - object
RETURN:		carry set if in child block
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/22/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLFSCheckIfInteractableObject	method dynamic OLFileSelectorClass,
				MSG_META_CHECK_IF_INTERACTABLE_OBJECT
	.enter
	cmp	cx, ds:[di].OLFSI_uiBlock
	stc
	je	exit

	mov	di, offset OLFileSelectorClass
	call	ObjCallSuperNoLock
exit:
	.leave
	ret
OLFSCheckIfInteractableObject	endm





COMMENT @----------------------------------------------------------------------

METHOD:		OLFileSelectorDiskErrorResponse -- 
		MSG_OL_FILE_SELECTOR_DISK_ERROR_RESPONSE for OLFileSelectorClass

DESCRIPTION:	Response from the user on a disk error.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_OL_FILE_SELECTOR_DISK_ERROR_RESPONSE

		cx 	- InteractionCommand

RETURN:		nothing
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	8/ 2/93         	Initial Version

------------------------------------------------------------------------------@

if SINGLE_DRIVE_DOCUMENT_DIR

OLFileSelectorDiskErrorResponse	method dynamic	OLFileSelectorClass, \
				MSG_OL_FILE_SELECTOR_DISK_ERROR_RESPONSE
	cmp	cx, IC_OK
	jne	cancel
	;
	; User pressed "OK"; rescan drive.
	;
	mov	ax, MSG_OL_FILE_SELECTOR_DOCUMENT_BUTTON
	GOTO	ObjCallInstanceNoLock
cancel:

	; Don't do this for NIKE, as the file selector contains a
	; "New" button which doesn't require having a disk in the drive
		
	;
	; User pressed "Cancel," attempt to dismiss the dialog containing
	; the file selector.
	;
	push	si
	mov	bx, segment VisClass	;set to the base class that can handle 
	mov	si, offset VisClass	;  the message in ax
	mov     cx, (CS_CONTROL shl 8) or VC_ESCAPE
	mov	dl, mask CF_FIRST_PRESS
	mov	ax, MSG_META_KBD_CHAR
	mov	di, mask MF_RECORD
	call	ObjMessage	
	pop	si
	mov	cx, di
	mov	ax, MSG_VIS_VUP_CALL_WIN_GROUP
	call	VisCallParent
	ret

OLFileSelectorDiskErrorResponse	endm

endif


if _DUI
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFileSelectorRename
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Rename the file listed in the file selector.

CALLED BY:	MSG_OL_FILE_SELECTOR_RENAME
PASS:		*ds:si	= OLFileSelectorClass object
		ds:di	= OLFileSelectorClass instance data
		es 	= segment of OLFileSelectorClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	12/ 1/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLFileSelectorRename	method dynamic OLFileSelectorClass, 
					MSG_OL_FILE_SELECTOR_RENAME
		uses	cx, dx, bp
		.enter
	;
	; Get the selected file name
	;
		call	OLFileSelectorGetFileName	;^hbx = filename block
							;es:di = filename
		push	si				;save self lptr
		tst	bx				;Got filename?
		LONG	jz	done
		push	bx				;save for unlock later
	;
	; Create the dialog so that the user can rename the file.
	;
		push	ds:[LMBH_handle]
		mov	bx, handle RenameDialog
		mov	si, offset RenameDialog
		call	UserCreateDialog
		mov	ax, bx				;ax = dup block
		pop	bx
		call	MemDerefDS			;STOFFT uses FIXUP_DS
		mov	bx, ax				;bx = dup block
		mov	si, offset RenameText
		mov	ax, mask GDCA_VM_FILE
		call	SetTextObjectForFileType

	;
	; Put the original file name into the dialog box, and bring it up.
	;
		movdw	dxbp, esdi
		clr	cx
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
		mov	di, mask MF_FIXUP_DS or mask MF_CALL
		call	ObjMessage
		mov	ax, MSG_VIS_TEXT_SELECT_ALL
		mov	di, mask MF_FIXUP_DS or mask MF_CALL
		call	ObjMessage

		mov	si, bx
		pop	bx				;^hbx = file buff block
		call	MemUnlock
		mov	bx, si

		push	ds:[LMBH_handle]
		mov	si, offset RenameDialog
		call	UserDoDialog
		mov	bp, bx				;^hbp = dialog block
		pop	bx				;^hbx= FileSelector blk
		call	MemDerefDS
	;
	; Get the new file name if any
	;
		mov	bx, bp				;^hbx = dialog block
		
		cmp	ax, IC_APPLY			;Really rename?
		stc					;assume not
		jnz	destroyAndDone
		sub	sp, size FileLongName
		mov	bp, sp
		mov	dx, ss				;dx:bp = filename buff
		mov	cx, size FileLongName
		mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
		mov	si, offset RenameText
		mov	di, mask MF_FIXUP_DS or mask MF_CALL
		call	ObjMessage			;dx:bp = new name
							;ax,cx trashed
		clc					;continue operation
destroyAndDone:
	;
	; Destroy the dialog because we don't need it anymore.
	;	carry set to skip operation
	;
		pushf					;save continue flag
		push	ds:[LMBH_handle]
		mov	si, offset RenameDialog
		call	UserDestroyDialog
		pop	bx				;^hbx= FileSelector blk
		call	MemDerefDS
		popf
		jc	done
	;
	; Start rename
	;
		mov	si, ss:[bp + size FileLongName]	; *ds:si = self
			Assert	objectPtr, dssi, OLFileSelectorClass
		call	OLFileSelectorContinueRename
		add	sp, FileLongName		;restore stack
	;
	; Rescan the dir becuase the name of the file has changed.
	;
;no need for this as file change notification handles it
;		mov	ax, MSG_GEN_FILE_SELECTOR_RESCAN
;		Assert  objectPtr dssi, OLFileSelectorClass
;		call	ObjCallInstanceNoLock
done:
		pop	si			; pop self lptr (not used)
		.leave
		ret
OLFileSelectorRename		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFileSelectorContinueRename
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Continue the rename procedure.

CALLED BY:	OLFileSelectorRename
PASS:		*ds:si	= instance data of OLFileSelectorClass
		ss:bp	= new file name string (null-terminated)
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	12/ 1/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLFileSelectorContinueRename	proc	near
		uses	ax, bx, cx, dx, si, bp
		.enter
		Assert  objectPtr dssi, GenFileSelectorClass
	;
	; Go to the correct dir. before we rename the file.
	;
if TURN_OFF_BUSY_ON_DOC_CTRL_DIALOG
		call	OLDocMarkBusyOnly
else
		call	OLDocMarkBusy
endif
		call	FilePushDir
if DC_DISALLOW_SPACES_FILENAME
		;
		; check for trailing or leading spaces
		;
		call	CheckSpacesFilename
		jnc	noError
		mov	ax, SDBT_FILE_ILLEGAL_NAME	; in case error
		mov	cx, ss				; cx:dx = name
		mov	dx, bp
		call	CallUserStandardDialog
		jmp	short continue

noError:
endif
		mov	ax, ATTR_GEN_PATH_DATA
		mov	dx, TEMP_GEN_PATH_SAVED_DISK_HANDLE
		call	GenPathSetCurrentPathFromObjectPath
EC <		ERROR_C	ERROR_DISK_UNAVAILABLE				>
	;
	; Get the filename that we want to change, and rename it.
	;
		call 	OLFileSelectorGetFileName	;es:di = old filename
							;^hbx =filename block
EC <		tst	bx						>
EC <		ERROR_Z	-1						>
		push	bx			;save for unlock later
		push	ds, si
		segmov	ds, es
		mov	dx, di			;ds:dx = old name
		segmov	es, ss
		mov	di, bp			;es:di = new name
		call	FileRename
		pop	ds, si
		pop	bx
		call	MemUnlock
		jc	error

;;		call	SendCompleteUpdateToDC

continue:
if TURN_OFF_BUSY_ON_DOC_CTRL_DIALOG
		call	OLDocMarkNotBusyOnly
else
		call	OLDocMarkNotBusy
endif
		call	FilePopDir
		.leave
		ret

error:
		cmp	ax, ERROR_FILE_EXISTS
		mov	ax, SDBT_RENAME_FILE_EXISTS
		jz	gotErrorCode
		mov	ax, SDBT_RENAME_ERROR
gotErrorCode:

		movdw	cxdx, esdi			;cxdx = file name
		call	CallUserStandardDialog
		jmp	continue

OLFileSelectorContinueRename		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFileSelectorCopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Duplicate the selected file.

CALLED BY:	MSG_OL_FILE_SELECTOR_COPY
PASS:		*ds:si	= OLFileSelectorClass object
		ds:di	= OLFileSelectorClass instance data
		es 	= segment of OLFileSelectorClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/ 7/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLFileSelectorCopy	method dynamic OLFileSelectorClass, 
					MSG_OL_FILE_SELECTOR_COPY
		uses	cx, dx, bp
		.enter
	;
	; Get the selected file name
	;
		call	OLFileSelectorGetFileName	;^hbx = filename block
							;es:di = filename
		push	si				; save self lptr
		tst	bx				;Got filename?
		LONG	jz	done
		push	bx				;save for unlock later
	;
	; Create the dialog so that the user can rename the file.
	;
		push	ds:[LMBH_handle]
		mov	bx, handle CopyDialog
		mov	si, offset CopyDialog
		call	UserCreateDialog
		mov	ax, bx				;ax = dup block
		pop	bx
		call	MemDerefDS			;STOFFT uses FIXUP_DS
		mov	bx, ax				;bx = dup block
		mov	si, offset CopyText
		mov	ax, mask GDCA_VM_FILE
		call	SetTextObjectForFileType

	;
	; Put the original file name into the dialog box, and bring it up.
	;
		movdw	dxbp, esdi
		clr	cx
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
		mov	di, mask MF_FIXUP_DS or mask MF_CALL
		call	ObjMessage
		mov	ax, MSG_VIS_TEXT_SELECT_ALL
		mov	di, mask MF_FIXUP_DS or mask MF_CALL
		call	ObjMessage
	;
	; Have to unlock this block here.  Otherwise, a detach could occur
	; during the UserDoDialog, whish would free the block.  Then we'd
	; try to free it later.
	;
		mov	si, bx				;^hsi <- copy db handle
		pop	bx				;^hbx = file buff block
		call	MemUnlock
		mov	bx, si				;^hbx <- copy db handle

		push	ds:[LMBH_handle]
		mov	si, offset CopyDialog
		call	UserDoDialog
		mov	bp, bx				;^hbp = dialog block
		pop	bx				;^hbx= FileSelector blk
		call	MemDerefDS
	;
	; Get the new file name if any
	;
		mov	bx, bp				;^hbx = dialog block
		
		cmp	ax, IC_APPLY			;Really rename?
		stc					;assume not
		jnz	destroyAndDone
		sub	sp, FileLongName
		mov	bp, sp
		mov	dx, ss				;dx:bp = filename buff
		mov	cx, FileLongName
		mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
		mov	si, offset CopyText
		mov	di, mask MF_FIXUP_DS or mask MF_CALL
		call	ObjMessage			;dx:bp = new name
							;ax,cx trashed
		clc					;continue operation
destroyAndDone:
	;
	; Destroy the dialog because we don't need it anymore.
	;	carry set to skip operation
	;
		pushf					;save continue flag
		push	ds:[LMBH_handle]
		mov	si, offset CopyDialog
		call	UserDestroyDialog
		pop	bx				;^hbx= FileSelector blk
		call	MemDerefDS
		popf
		jc	done
	;
	; Start rename
	;
		mov	si, ss:[bp + size FileLongName]	; *ds:si = self
			Assert	objectPtr, dssi, OLFileSelectorClass
		call	OLFileSelectorContinueCopy
		add	sp, FileLongName		;restore stack
	;
	; Rescan the dir becuase the name of the file has changed.
	;
;no need for this as file change notification handles it
;		mov	ax, MSG_GEN_FILE_SELECTOR_RESCAN
;		Assert  objectPtr dssi, OLFileSelectorClass
;		call	ObjCallInstanceNoLock
done:
		pop	si			; pop self lptr (not used)
		.leave
		ret
OLFileSelectorCopy		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFileSelectorContinueCopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Continue the duplicating file operation.

CALLED BY:	OLFileSelectorCopy
PASS:		*ds:si	= instance data of OLFileSelectorClass
		ss:bp	= new file name string (null-terminated)
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/ 7/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLFileSelectorContinueCopy	proc	near
		uses	ax, bx, cx, dx, si, bp
		.enter
		Assert  objectPtr dssi, GenFileSelectorClass
	;
	; Go to the correct dir. before we duplicate the file.
	;
if TURN_OFF_BUSY_ON_DOC_CTRL_DIALOG
		call	OLDocMarkBusyOnly
else
		call	OLDocMarkBusy
endif
		call	FileBatchChangeNotifications
		call	FilePushDir
if DC_DISALLOW_SPACES_FILENAME
		;
		; check for trailing or leading spaces
		;
		call	CheckSpacesFilename
		jnc	noError
		mov	ax, SDBT_FILE_ILLEGAL_NAME	; in case error
		mov	cx, ss				; cx:dx = name
		mov	dx, bp
		call	CallUserStandardDialog
		clc					; already reported
		jmp	short afterError

noError:
endif
		mov	ax, ATTR_GEN_PATH_DATA
		mov	dx, TEMP_GEN_PATH_SAVED_DISK_HANDLE
		call	GenPathSetCurrentPathFromObjectPath
EC <		ERROR_C	ERROR_DISK_UNAVAILABLE				>
	;
	; Get the filename that we want to change, and duplicate it.
	;
		call 	OLFileSelectorGetFileName	;es:di = old filename
							;^hbx =filename block
EC <		tst	bx						>
EC <		ERROR_Z	OL_ERROR					>
		push	bx			;save for unlock later
		push	ds, si
	;
	; Before we do the FileCopy, we need to make sure that the new name
	; doesn't equal to any of the existing files.
	;
		segmov	ds, ss, ax
		mov	dx, bp			;ds:dx = new name
		call	FileGetAttributes	;carry set -> file not found
						;ax,cx trashed
		cmc
		jc	afterCopy
	;
	; now copy is safe.
	;
		segmov	ds, es
		mov	si, di			;ds:si = old name
		segmov	es, ss
		mov	di, bp			;es:di = new name
		clr	cx, dx			;default disk handle
		call	FileCopy
afterCopy:
		pop	ds, si
		pop	bx
		call	MemUnlock
afterError::
if TURN_OFF_BUSY_ON_DOC_CTRL_DIALOG
		call	OLDocMarkNotBusyOnly	;flags preserved
else
		call	OLDocMarkNotBusy	;flags preserved
endif
		jc	error

continue:
		call	FileFlushChangeNotifications
		call	FilePopDir
		.leave
		ret

error:
		mov	ax, offset copyFailed
		clr	cx, di
		call	CallErrorDialog
		jmp	continue

OLFileSelectorContinueCopy		endp

endif ; _JEDIMOTIF or _DUI


if _DUI


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFileSelectorDeleteSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete the current selected file in the file selector.

CALLED BY:	MSG_GEN_FILE_SELECTOR_DELETE_SELECTION
PASS:		*ds:si	= OLFileSelectorClass object
		ds:di	= OLFileSelectorClass instance data
		es 	= segment of OLFileSelectorClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	1/19/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLFileSelectorDeleteSelection	method dynamic OLFileSelectorClass, 
					MSG_GEN_FILE_SELECTOR_DELETE_SELECTION
		uses	cx, dx, bp
		.enter

	;
	; Set the correct path before executing the delete file operations
	;
		call	FilePushDir
		mov	ax, ATTR_GEN_PATH_DATA
		mov	dx, TEMP_GEN_PATH_SAVED_DISK_HANDLE
		call	GenPathSetCurrentPathFromObjectPath
	;
	; Do we have any files?
	;
		tst	ds:[di].OLFSI_numFiles
		jz	done				;done if none

	;
	; Check to see if we are trying to delete the file in ROM.
	;
		call	IsDeletingROMFile
		jc	done
	;
	; Create the dialog to ask user for confirmation.
	;
		push	ds:[LMBH_handle], si
		mov	bx, handle DeleteDialog
		mov	si, offset DeleteDialog
		call	UserCreateDialog
		mov	ax, SST_WARNING
		call	UserStandardSound
		call	UserDoDialog
		call	UserDestroyDialog
		pop	bx, si				;^lbx:si = self
		call	MemDerefDS
		cmp	ax, IC_APPLY
		jnz	done

	;
	; Start delete. After it is done, rescan the directory again.
	;
		call	OLFileSelectorContinueDelete

;no need for this as file change notification handles it
;		mov	ax, MSG_GEN_FILE_SELECTOR_RESCAN
;		Assert  objectPtr dssi, OLFileSelectorClass
;		call	ObjCallInstanceNoLock
done:
		call	FilePopDir
		.leave
		ret
OLFileSelectorDeleteSelection		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFileSelectorContinueDelete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Continue the process of deleting the file.

CALLED BY:	OLFileSelectorDelete
PASS:		*ds:si	= instance data of OLFileSelectorClass
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	1/19/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLFileSelectorContinueDelete	proc	near
		uses	ax, bx, cx, dx, bp, di, es
		.enter
		Assert  objectPtr dssi, GenFileSelectorClass
if TURN_OFF_BUSY_ON_DOC_CTRL_DIALOG
		call	OLDocMarkBusyOnly
else
		call	OLDocMarkBusy
endif
	;
	; Get the name of the selected file which we wanted to delete.
	;
		call 	OLFileSelectorGetFileName	;es:di = old filename
							;^hbx = filename block
EC <		tst	bx						>
EC <		ERROR_Z	-1						>
		push	bx				;save for unlock later
		push	ds, si
		segmov	ds, es, ax
		mov	dx, di				;ds:dx = old name
		call	FileDelete
		pop	ds, si
if TURN_OFF_BUSY_ON_DOC_CTRL_DIALOG
		call	OLDocMarkNotBusyOnly		;preserves flags
else
		call	OLDocMarkNotBusy		;preserves flags
endif
		jc	error

continue:
	;
	; Ready to exit, unlock the block and reset the cursor.
	;
		pop	bx
		call	MemUnlock

		.leave
		ret
	;
	; This part is to handle any error happened during deleting the file.
	;
error:
;;		movdw	cxdx, esdi			;cxdx = file name
		mov_tr	cx, ax				;cx = error msg

		mov	ax, offset fileNotFound
		cmp	cx, ERROR_FILE_NOT_FOUND
		je	gotErrorMsg

		mov	ax, offset fileInUse
		cmp	cx, ERROR_FILE_IN_USE
		je	gotErrorMsg

		mov	ax, offset fileAccessDenied
		cmp	cx, ERROR_WRITE_PROTECTED
		je	gotErrorMsg
		
		cmp	cx, ERROR_ACCESS_DENIED
		je	gotErrorMsg
	;
	;  Jeez, what the heck happened?
	;
		mov	ax, offset deleteFailed
gotErrorMsg:
		mov	cx, es
		call	CallErrorDialog			;trashed ax
		jmp	continue

OLFileSelectorContinueDelete		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsDeletingROMFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if we are trying to delete the file in ROM.

CALLED BY:	OLFileSelectorDeleteSelection
PASS:		*ds:si	= instance data of OLFileSelectorClass
RETURN:		carry set = the selected file is in ROM
				or no selection
		carry clear = the selected file is not in ROM
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	1/11/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IsDeletingROMFile	proc	near
		uses	ax, bx, cx, dx, di, es
		.enter
		Assert  objectPtr dssi, GenFileSelectorClass
	;
	; Get the name of the selected file which we wanted to delete.
	;
		call 	OLFileSelectorGetFileName	;es:di = filename
							;^hbx = filename block
		tst	bx
		stc					;assume no selection
		jz	done
		push	bx				;save for unlock later
		push	ds, si

		mov	dx, di
		segmov	ds, es, ax			;ds:dx = filename
		push	ax				;creating buffer
		segmov	es, ss, ax
		mov	di, sp				;es:di = buffer
		mov	ax, FEA_FILE_ATTR
		mov	cx, size FileAttrs
		call	FileGetPathExtAttributes
EC <		ERROR_C	-1						>
		pop	ax				;ax = FileAttrs
		pop	ds, si				;*ds:si = file selector
		pop	bx				;^hbx = filename block
		call	MemUnlock
	;
	; If it is the file in ROM, then inform the user.
	;
		test	ax, mask FA_RDONLY
		jz	done				;jump if writable
	;
	; Bring the dialog box to inform the user.
	;
		push	ds:[LMBH_handle], si
		mov	bx, handle DeleteRomDialog
		mov	si, offset DeleteRomDialog
		call	UserCreateDialog
		mov	ax, SST_WARNING
		call	UserStandardSound
		call	UserDoDialog
		call	UserDestroyDialog
		pop	bx, si
		call	MemDerefDS			;ds = updated
		stc
done:
		.leave
		ret
IsDeletingROMFile		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallErrorDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Inform the user of the error occured during the operation.

CALLED BY:	OLFileSelectorContinueDelete()
PASS:		ax	= chunk handle of the error string.
		cx:di	= file name to be displayed OR cx = di = 0
RETURN:		nothing
DESTROYED:	ax, di, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	1/23/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CallErrorDialog	proc	near
		uses	bx 
		.enter
	;
	; Create an error dialog.
	;
		clr	bx
		xchg	bx, ax				;bx = chunk handle of str
		push	ax, ax				;SDP_helpContext
		push	ax, ax				;SDP_customTriggers
		push	ax, ax				;SDP_stringArg2
		pushdw	cxdi				;SDP_stringArg1

		mov	di, bx				
		mov	bx, handle DocumentStringsUI	;^lbx:di = error str
		call	MemLock				;ax = str block
		mov	es, ax
		mov	di, es:[di]			;es:di = str
		pushdw	esdi				;SDP_customString
		mov	ax, CustomDialogBoxFlags<0, CDT_ERROR, GIT_NOTIFICATION,0>
		push	ax				;SDP_customFlags
		call	UserStandardDialog
		call	MemUnlock
		.leave
		ret

CallErrorDialog		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFileSelectorGetFileName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the name of the selected file in the FileSelector

CALLED BY:	INTERNAL
PASS:		*ds:si	= instance of OLFileSelectorClass
RETURN:		es:di	= filename str (null terminated)
		^hbx	= block which contains the filename pointed by es:di
DESTROYED:	nothing
SIDE EFFECTS:	
		The caller is supposed to unlock the block that contains the
		string.
		ds may be updated.
PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	12/ 1/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLFileSelectorGetFileName	proc	near
		uses	ax, cx, dx, bp, si
		.enter
		Assert	objectPtr dssi, OLFileSelectorClass
	;
	; Find out  which file is selected. If there is no file selected,
	; in the meantime, we just quit.
	;
if _DUI
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
else
		mov	ax, MSG_TABLE_GET_CURRENT_SELECTION
endif
		mov	di, offset OLFileSelectorFileList
		call	OLFSCallUIBlockGadget		;ax = row selection
							;cx,dx,bp trashed
	;
	; Having found the selected file, we need to get its name
	;
if _DUI
		mov	bx, 0				;assume null blockH
							;(preserves flags)
		jc	quit				; none selected
		cmp	ax, GIGS_NONE
		je	quit				; none selected
		mov	cx, ax				; cx = current sel.
else
		clr	bx				;assume null blockH
endif
		mov	di, ds:[si]
		add	di, ds:[di].OLFileSelector_offset
		cmp	cx, ds:[di].OLFSI_numFiles	;beyond end of file?
		jae	quit
		tst	ds:[di].OLFSI_fileBuffer	;null block handle?
		jz	quit
		call	OLFSDerefIndexBuffer		;si= offset in file buf
		mov	bx, ds:[di].OLFSI_fileBuffer	;^bx = file buff block
		call	MemLock
		mov	es, ax				;es:si = file buf entry
		add	si, offset OLFSE_name		;es:si = file name
		mov	di, si				;es:di = file name
quit:
		.leave
		ret
OLFileSelectorGetFileName		endp

endif ; _JEDIMOTIF or _DUI

if _ISUI

;
; taken from shell library
;

COMMENT @-------------------------------------------------------------------
		FileComparePathsEvalLinks
----------------------------------------------------------------------------

DESCRIPTION:	Takes two paths that may contain links and evaluates both
		before calling FileComparePaths on them.

CALLED BY:	GLOBAL


PASS:		cx - disk handle of path 1
		ds:si - pathname #1

		dx - disk handle of path #2
		es:di - pathname #2

RETURN:		carry:
			- set on error,
			  ax = FileError or PCT_ERROR
					(if failed in FileComparePaths)

			- clear if completed,
			  al - PathCompareType

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	11/1/92		Initial version

---------------------------------------------------------------------------@
OLFSFileComparePathsEvalLinks	proc	near
	uses	bx, cx, dx, si, di, ds, es

path2	local	fptr	push	es, di
diskHandle2	local	word	push	dx
diskHandle1	local	word

	.enter

if ERROR_CHECK
	;
	; Validate that path 1 is not in a movable code segment
	;
FXIP<	push	bx, si						>
FXIP<	mov	bx, ds						>
FXIP<	call	ECAssertValidFarPointerXIP			>
	;
	; Validate that path 2 is not in a movable code segment
	;
FXIP<	mov	bx, es						>
FXIP<	mov	si, di						>
FXIP<	call	ECAssertValidFarPointerXIP			>
FXIP<	pop	bx, si						>
endif

	call	OLFSShellAlloc2PathBuffers
	mov	di, offset PB2_path1

	clr	dx				; no <drivename:> neccessary
	mov	bx, cx				; bx, ds:si is path to evaluate
	mov	cx, size PathName
	call	FileConstructActualPath
	jc	done

	mov	ss:[diskHandle1], bx

	mov	bx, ss:[diskHandle2]
	lds	si, ss:[path2]
	mov	di, offset PB2_path2
	push	di
	call	FileConstructActualPath
	pop	di
	jc	done

	mov	dx, bx				; dx, es:di is path 2

	mov	cx, ss:[diskHandle1]
	segmov	ds, es
	mov	si, offset PB2_path1
	call	FileComparePaths

done:
	call	OLFSShellFreePathBuffer
	.leave
	ret
OLFSFileComparePathsEvalLinks	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ShellFreePathBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free a path buffer allocated by either
		ShellAllocPathBuffer or ShellAlloc2PathBuffers

CALLED BY:	

PASS:		es - segment of path buffer

RETURN:		nothing 

DESTROYED:	nothing, flags preserved 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/11/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLFSShellFreePathBuffer	proc near
	uses	bx
	.enter
	pushf
	mov	bx, es:[PB_handle]
	call	MemFree
	popf

	.leave
	ret
OLFSShellFreePathBuffer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ShellAlloc2PathBuffers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a buffer for 2 paths on the heap

CALLED BY:	

PASS:		nothing 

RETURN:		es:0 - PathBuffer2 structure (es:0 is the handle)

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/11/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

OLFSPathBuffer	struct
	PB_handle	hptr.PathBuffer
	PB_path		PathName		<>
OLFSPathBuffer	ends

OLFSPathBuffer2	struct
	PB2_handle	hptr.PathBuffer2
	PB2_path1	PathName		<>
	PB2_path2	PathName		<>
OLFSPathBuffer2	ends

OLFSShellAlloc2PathBuffers	proc near
	uses	ax
	.enter
	mov	ax, size OLFSPathBuffer2
	call	OLFSAllocCommon
	.leave
	ret
OLFSShellAlloc2PathBuffers	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common routine to allocate the desired buffer

CALLED BY:	ShellAllocPathBuffer, ShellAlloc2PathBuffers

PASS:		

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/11/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLFSAllocCommon	proc near
	uses	bx, cx	
	.enter

	mov	cx, (mask HAF_ZERO_INIT shl 8) or ALLOC_DYNAMIC_NO_ERR_LOCK
	call	MemAlloc
	mov	es, ax
	mov	es:[PB_handle], bx
	.leave
	ret
OLFSAllocCommon	endp

endif

FileSelector ends

