COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonUI/COpen
FILE:		copenFileSelectorHigh.asm

ROUTINES:
	Name			Description
	----			-----------
    INT OLFSProcessHints        Copies hints chunk to dynamic list, adding
				any hints needed for the list.

    INT OLFSSize                Copies hints chunk to dynamic list, adding
				any hints needed for the list.

    INT OLFSWidth               Copies hints chunk to dynamic list, adding
				any hints needed for the list.

    INT OLFSExpandWidth         Copies hints chunk to dynamic list, adding
				any hints needed for the list.

    INT OLFSExpandHeight        Copies hints chunk to dynamic list, adding
				any hints needed for the list.

    INT OLFSCopyHint            Copies hints chunk to dynamic list, adding
				any hints needed for the list.

    INT OLFSSingleAction        Copies hints chunk to dynamic list, adding
				any hints needed for the list.

    INT OLFSSetAvailSection     Sets available Responder sections.

    MTD MSG_VIS_NOTIFY_GEOMETRY_VALID 
				Notifies file selector that its geometry is
				valid.

    INT SendFileSelectedToTabComp 
				Sends message to tab composite to update
				itself.

    INT OLFSSetDefaultWizardDirectory 
				Set the default directory for Wizard to be
				SP_TOP/DESKTOP

    INT CheckDirectoryVarData   Set the default directory for Wizard to be
				SP_TOP/DESKTOP

    INT SetDirectoryVarData     Set the default directory for Wizard to be
				SP_TOP/DESKTOP

    INT GetDesktopSlashHomeDir  Set the default directory for Wizard to be
				SP_TOP/DESKTOP

    INT ConvertStandardPathToWizardPath 
				Convert standard paths into
				SP_TOP:\DESKTOP\<Home Dir>\...

    MTD MSG_SPEC_UNBUILD_BRANCH Unbuild this file selector visually,
				unbuilding duplicated UI block.

    INT DestroyBlockAndRemoveFromActiveList 
				destroy

    INT OLFSNotifyCommon        Handle being set enabled or not enabled
				(since we have generic children that are
				connected via one-way links).

    MTD MSG_VIS_DRAW            Draw the file selector.

    INT OLFSFreeBuffers         File Selector is being visually closed,
				free buffers.

    MTD MSG_META_ADD_VAR_DATA   Deal with programmer adjusting scanning
				criteria by manipulating our vardata.

    INT OLFileSelectorCheckRemovable 
				See if the passed path is on a removable
				drive.  If so, the user may have switched
				disks, so make sure our disk handle is up
				to date.

    INT OLFileSelectorGetIDs    Get the IDs for the path we have set and
				store them in our vardata.

    INT OLFileSelectorWizardChangeDir 
				Update ATTR_GEN_PATH_DATA to be under
				SP_TOP:\Desktop\<Home directory>

    MTD MSG_NOTIFY_DRIVE_CHANGE Take note of the addition or deletion of a
				drive

    MTD MSG_META_REMOVING_DISK  Take note of the deletion of a drive

    MTD MSG_NOTIFY_FILE_CHANGE  Take note of a change in the filesystem

    INT OLFileSelectorNotifyFileChangeLow 
				Take note of a change in the filesystem

    INT OLFileSelectorFetchIDFromNotificationBlock 
				Fetch the three words of ID from the
				notification block

    INT OLFileSelectorCheckIDIsOurs 
				See if the FCND_disk:FCND_id is one of
				those for our folder

    INT OLFileSelectorCheckIDIsAncestor 
				See if the FCND_disk as a StandardPath is
				the ancestor of one of those for our
				folder.

    INT OLFileSelectorCloseIfIDIsOurs 
				Close this folder, if the ID in the
				notification is for this folder.

    INT OLFileSelectorCloseForNotify 
				Retreat to the virtual root, if possible,
				or SP_DOCUMENT, if not, in response to
				having our current directory or disk nuked
				from under us.

    INT OLFileSelectorCheckIDIsKids 
				See if the affected file is one of our
				kiddies.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/10/94	Broken out of copenFileSelector.asm

DESCRIPTION:

	$Id: copenFileSelectorHigh.asm,v 1.36 97/01/20 21:28:10 reza Exp $

-------------------------------------------------------------------------------@


CommonUIClassStructures segment resource

	OLFileSelectorClass	mask CLASSF_NEVER_SAVED or \
				mask CLASSF_DISCARD_ON_SAVE

	OLFSDynamicListClass	mask CLASSF_DISCARD_ON_SAVE

if _JEDIMOTIF
	OLFSTableClass		mask CLASSF_DISCARD_ON_SAVE

	OLFSTableHeadingClass	mask CLASSF_DISCARD_ON_SAVE

	OLFSFileLocatorClass	mask CLASSF_DISCARD_ON_SAVE

	OLFSTableViewClass	mask CLASSF_DISCARD_ON_SAVE

	OLFSFileContentClass	mask CLASSF_DISCARD_ON_SAVE
endif
CommonUIClassStructures ends


udata segment

udata ends

;---------------------------------------------------

FileSelector segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLFileSelectorInitialize -- MSG_META_INITIALIZE for
						OLFileSelectorClass

DESCRIPTION:	Initialize object

PASS:
	*ds:si - instance data
	es - segment of OLFileSelectorClass

	ax - MSG_META_INITIALIZE

	cx - ?
	dx - ?
	bp - ?

RETURN:
	carry - ?
	ax - ?
	cx - ?
	dx - ?
	bp - ?

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

OLFileSelectorInitialize	method OLFileSelectorClass, MSG_META_INITIALIZE
	call	ObjMarkDirty			; gen instance data will change
	;
	; call superclass to start
	;
	mov	di, offset OLFileSelectorClass
	call	ObjCallSuperNoLock
	;
	; make sure stuff is zero'ed
	;
	call	OLFSDeref_SI_Spec_DI		; ds:di = specific instance
	clr	ax
	mov	ds:[di].OLFSI_fileBuffer, ax
	mov	ds:[di].OLFSI_indexBuffer, ax
	mov	ds:[di].OLFSI_numFiles, ax
if FSEL_DISABLES_FILTERED_FILES
	mov	ds:[di].OLFSI_numRejects, ax
	mov	ds:[di].OLFSI_rejectList, ax
endif
if HANDLE_CREATE_GEOS_FILE_NOTIFICATION
	mov	ds:[di].OLFSI_geosFileIDList, ax
endif
	;
	; start off showing files/directories
	;
	mov	ds:[di].OLFSI_state, ax
	ret

OLFileSelectorInitialize	endm

	

COMMENT @----------------------------------------------------------------------

ROUTINE:	OLFSProcessHints

SYNOPSIS:	Copies hints chunk to dynamic list, adding any hints needed
		for the list.

CALLED BY:	OLFileSelectorSpecBuild

PASS:		*ds:si -- file selector object

RETURN:		nothing

DESTROYED:	ax, cx

		NOTE:  invalidates any chunk pointers, dereference them
			again or die

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	6/25/91		Initial version
	Chris	12/ 4/92	Changed to work for expand width/height

------------------------------------------------------------------------------@

OLFSProcessHints	proc	near		uses	si, di, bx, dx, bp
	class	OLFileSelectorClass
	.enter
	call	OLFSDeref_SI_Spec_DI
	mov	bx, ds:[di].OLFSI_uiBlock
	call	ObjLockObjBlock
	mov_tr	dx, ax
	;
	; set our OLFSI_listSize value and copy whatever hints are
	;  appropriate to the dynamic list
	;
	; Each handler receives:
	; 	*ds:si	= object
	; 	ds:bx	= vardata extra data offset
	; 	cl	= number of children that'll be shown, so far	
	;	ch	= fixed width argument that we'll use, so far
	; 	bp	= GenVarData tag from which the number came
	; 	dx	= segment of associated UI block
	;
	push	es
	segmov	es, cs
	mov	di, offset cs:OLFSHintHandlers
	mov	ax, length (cs:OLFSHintHandlers)
	mov	cx, OLFS_DEFAULT_FILES_SHOWN or \
		    (FILE_LONGNAME_LENGTH+7) shl 8
						; in case no hint

	call	OpenCheckIfCGA
	jnc	10$
	mov	cl, OLFS_CGA_DEFAULT_FILES_SHOWN
10$:
	push	cx, dx
	call	OpenGetScreenDimensions	; cx = width, dx = height
	cmp	cx, TINY_SCREEN_WIDTH_THRESHOLD
	pop	cx, dx
	ja	20$
	mov	ch, FILE_LONGNAME_LENGTH+2	; smaller screen width
20$:

	call	ObjVarScanData			; cx = number of children
	pop	es

	;
	; Set a HINT_FIXED_SIZE on the list, with the width set to display
	; a longname, height set to 0, and the count set to the number we want
	; to display.
	; 
	push	ds
	mov	ds, dx			; ds <- uiBlock
	mov	si, offset OLFileSelectorFileList
if _JEDIMOTIF
	;
	; set row count in table object
	;	*ds:si = Table object
	;	cl = file count
	;
	push	cx			; just in case
	clr	ch
	jcxz	leaveDefault		; if zero, use default
	mov	ax, MSG_TABLE_SET_VISIBLE_ROW_COUNT
	call	ObjCallInstanceNoLock
leaveDefault:
	pop	cx			; cl = file count
endif
	mov	ax, HINT_FIXED_SIZE
	push	cx			; save file count
	mov	cx, size CompSizeHintArgs
	call	ObjVarAddData
	pop	ax			; ah = width argument
	push	ax
	mov	al, ah
	clr	ah
	ornf	ax, SpecWidth <SST_AVG_CHAR_WIDTHS, 0>
	mov	ds:[bx].CSHA_width, ax
	pop	ax			; al = count
	clr	ah
	mov	ds:[bx].CSHA_count, ax
	ornf	ax, SpecHeight <SST_LINES_OF_TEXT, 0>
	mov	ds:[bx].CSHA_height, ax
	mov	bx, ds:[LMBH_handle]
	pop	ds			; ds <- our block

	;
	; Release the duplicated block, now everything's been copied.
	; 
	call	MemUnlock
	.leave
	ret
OLFSProcessHints	endp

if _RUDY
OLFSHintHandlers	VarDataHandler \
	<HINT_FILE_SELECTOR_NUMBER_OF_FILES_TO_SHOW, offset OLFSSize>,
	<HINT_FILE_SELECTOR_FILE_LIST_WIDTH, offset OLFSWidth>,
	<HINT_DEFAULT_FOCUS, offset OLFSCopyHint>,
	<HINT_AN_ADVANCED_FEATURE, OLFSCopyHint>,
	<HINT_GENERAL_CONSUMER_MODE, OLFSCopyHint>,
	<HINT_EXPAND_WIDTH_TO_FIT_PARENT, OLFSExpandWidth>,
	<HINT_EXPAND_HEIGHT_TO_FIT_PARENT, OLFSExpandHeight>,
	<HINT_FILE_SELECTOR_SINGLE_ACTION, offset OLFSSingleAction>,
	<HINT_FILE_SELECTOR_SHOW_SELECTION_EVEN_WHEN_NOT_FOCUS, \
					offset OLFSAlwaysShowSelection>,
	<HINT_EFS_SHORT_SEARCH_MONIKER, offset OLFSShortMoniker>
else
OLFSHintHandlers	VarDataHandler \
	<HINT_FILE_SELECTOR_NUMBER_OF_FILES_TO_SHOW, offset OLFSSize>,
	<HINT_FILE_SELECTOR_FILE_LIST_WIDTH, offset OLFSWidth>,
	<HINT_DEFAULT_FOCUS, offset OLFSCopyHint>,
	<HINT_AN_ADVANCED_FEATURE, OLFSCopyHint>,
	<HINT_GENERAL_CONSUMER_MODE, OLFSCopyHint>,
	<HINT_EXPAND_WIDTH_TO_FIT_PARENT, OLFSExpandWidth>,
	<HINT_EXPAND_HEIGHT_TO_FIT_PARENT, OLFSExpandHeight>,
	<HINT_FILE_SELECTOR_SINGLE_ACTION, offset OLFSSingleAction>
endif

OLFSSize	proc	far
	mov	cl, {byte} ds:[bx]	; cl <- number of files to show	
	ret
OLFSSize	endp

OLFSWidth	proc	far
	mov	ch, {byte} ds:[bx]	; ch <- number of avg width chars
	ret
OLFSWidth	endp

OLFSExpandWidth	proc	far
	clr	ch			; don't use a fixed width
	GOTO	OLFSCopyHint
OLFSExpandWidth	endp

OLFSExpandHeight	proc	far
	clr	cl			; don't use a fixed height
	GOTO	OLFSCopyHint
OLFSExpandHeight	endp

; copy the current hint to the file list
OLFSCopyHint	proc	far
	mov	es, dx
	push	cx, bp			; save # children & source of same
	mov	bp, offset OLFileSelectorFileList	; *es:bp <- dest
	mov	cx, ax			; cx <- start of range to copy
	mov_tr	dx, ax			; dx <- end of range to copy
	call	ObjVarCopyDataRange
	mov	dx, es			; dx <- updated uiBlock segment
	pop	cx, bp
	ret
OLFSCopyHint	endp

OLFSSingleAction	proc	far
	call	OLFSDeref_SI_Spec_DI
	ORNF	ds:[di].OLFSI_state, mask OLFSS_SINGLE_ACTION
	ret
OLFSSingleAction	endp

if _RUDY
OLFSAlwaysShowSelection	proc	far
	push	ds:[LMBH_handle], cx
	mov	ds, dx
	mov	si, offset OLFileSelectorFileList
	mov	ax, HINT_ITEM_GROUP_SHOW_SELECTION_EVEN_WHEN_NOT_FOCUS
	clr	cx
	call	ObjVarAddData
	mov	dx, ds				; Must return dx pointing
						;  to ui block
	pop	bx, cx
	call	MemDerefDS
	ret
OLFSAlwaysShowSelection	endp

OLFSShortMoniker	proc	far
	;
	; Remove the text portion of the "Search" moniker
	;
	push	ds
	mov	ds, dx
	mov	si, offset OLFileSelectorSearchTextGroup
	mov	si, ds:[si]
	add	si, ds:[si].ComplexMoniker_offset
	mov	ax, offset OLFSNullSearchText
	mov	ds:[si].CMI_topText, ax
	pop	ds

	ret
OLFSShortMoniker	endp

endif


COMMENT @----------------------------------------------------------------------

METHOD:		OLFileSelectorSpecBuild -- MSG_SPEC_BUILD
			for OLFileSelectorClass

DESCRIPTION:	Build out this file selector visually, adding a
		GenDynamicList, reading files to display, etc.

PASS:
	*ds:si - instance data
	es - segment of OLFileSelectorClass (OL dgroup)

	ax - MSG_SPEC_BUILD

	cx - ?
	dx - ?
	bp - SpecBuildFlags

RETURN:
	carry - ?
	ax, cx, dx, bp - ?

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
	chris	6/25/91		A couple geometry changes

------------------------------------------------------------------------------@

OLFileSelectorSpecBuild	method	OLFileSelectorClass, MSG_SPEC_BUILD
	push	bp				; save SpecBuildFlags
	;
	; call superclass to do Vis Build
	;
	mov	di, offset OLFileSelectorClass
	call	ObjCallSuperNoLock
	;
	; Duplicate the UI block with our various funky components in it,
	; owned by the same thing that owns us. The block is marked
	; notDetachable, so it won't go to state (which is good).
	;
	mov	bx, ds:[LMBH_handle]
	call	MemOwner
	mov_trash	ax, bx
	mov	bx, handle FileSelectorUI
	clr	cx				; have current thread run block
	call	ObjDuplicateResource
	;
	; Save that handle away.
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	ds:[di].OLFSI_uiBlock, bx

if _RUDY
	or	ds:[di].VI_geoAttrs, mask VGA_NOTIFY_GEOMETRY_VALID

	mov	di, segment ExtendedFileSelectorClass
	mov	es, di
	mov	di, offset ExtendedFileSelectorClass
	call	ObjIsObjectInClass
	pushf
	call	OLFSDeref_SI_Spec_DI
	popf
	jnc	notExtended
	ORNF	ds:[di].OLFSI_state, mask OLFSS_IS_EXTENDED
notExtended:
endif

if _DUI
	;
	; we use the moniker for the file count indicator, so never display
	; it in the usual way
	;
	andnf	ds:[di].OLCI_optFlags, not mask OLCOF_DISPLAY_MONIKER
endif

	;
	; since we duplicated a block, we add ourselves to active so we can
	; get MSG_META_DETACH and destroy the block.  We, of course, remove
	; ourselves from the active list when we unbuild (as we then no longer
	; need MSG_META_DETACH).
	;
	mov	dx, size GCNListParams
	sub	sp, dx
	mov	bp, sp
	mov	ss:[bp].GCNLP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLP_ID.GCNLT_type, MGCNLT_ACTIVE_LIST or \
						mask GCNLTF_SAVE_TO_STATE
	mov	ax, ds:[LMBH_handle]
	mov	ss:[bp].GCNLP_optr.handle, ax
	mov	ss:[bp].GCNLP_optr.chunk, si
	mov	ax, MSG_META_GCN_LIST_ADD
	call	OpenCallApplicationWithStack
	add	sp, size GCNListParams

	;
	; Make sure we have the IDs for our path.
	; 
	call	OLFileSelectorGetIDs
	;
	; Make sure we're on the file-system change notification list.
	; 
	push	bx
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GCNSLT_FILE_SYSTEM
	call	GCNListAdd
	pop	bx
	;
	; Point all the appropriate things to the file selector.
	;	^hbx = duplicated block
	;	*ds:si = OLFileSelector
	;
if _JEDIMOTIF
	;
	; part one of HINT_MINIMIZE_CHILD_SPACING handling
	;
	push	bx
	mov	ax, HINT_MINIMIZE_CHILD_SPACING
	call	ObjVarFindData
	pop	bx
	pushf				; save minimize size flag
	;
	; part one of HINT_FILE_SELECTOR_SHOW_FILE_SIZE handling
	;
	push	bx
	mov	ax, HINT_FILE_SELECTOR_SHOW_FILE_SIZE
	call	ObjVarFindData
	pop	bx
	pushf				; save show file size flag
endif
if _RUDY
	; If file selector should be non-exclusive, set the list's
	; behavior type accordingly.

	call	OLFSIsNonExclusive
	pushf
endif ; _RUDY

	call	ObjSwapLock		; ^lbx:si = OLFileSelector
					; ds = duplicated block
	call	ObjBlockSetOutput

if _RUDY
	popf
	jnc	exclusive
	push	si
	mov	si, offset OLFileSelectorFileList
	call	OLFSDeref_SI_Gen_DI
	mov	ds:[di].GIGI_behaviorType, GIGBT_NON_EXCLUSIVE
	pop	si
exclusive:
endif ; _RUDY

if _JEDIMOTIF
	;
	; while we have the duplicate block locked,
	; handle HINT_FILE_SELECTOR_SHOW_FILE_SIZE
	;	ds = duplicated block
	;	^lbx:si = OLFileSelector
	;
	popf				; show file size?
	jnc	noSize			; nope
	push	si			; save file selector
.warn -private
.assert (FILE_TABLE_SIZE_COL eq FILE_TABLE_NAME_COL+1)
	mov	si, offset OLFileSelectorFileList
	mov	di, ds:[si]
	add	di, ds:[di].Table_offset
EC <	cmp	ds:[di].TI_columns, FILE_TABLE_NAME_COL+1		>
EC <	ERROR_NE	0						>
	inc	ds:[di].TI_columns
	mov	ds:[di].TI_columnDefinitions, offset FileSizeTableDefs
	mov	si, offset OLFileSelectorFileHeading
	mov	di, ds:[si]
	add	di, ds:[di].Table_offset
EC <	cmp	ds:[di].TI_columns, FILE_TABLE_NAME_COL+1		>
EC <	ERROR_NE	0						>
	inc	ds:[di].TI_columns
	mov	ds:[di].TI_columnDefinitions, offset FileSizeTableHeaderDefs
.warn @private
	pop	si			; ^lbx:si = file selector
noSize:
	;
	; handle HINT_MINIMIZE_CHILD_SPACING
	;
	popf
	jnc	noMinimize
	push	si			; save file selector
	mov	si, offset OLFileSelectorFileContent
	mov	cx, ds:[LMBH_handle]
	mov	dx, offset OLFileSelectorFileLocator
	mov	bp, mask CCF_MARK_DIRTY
	mov	ax, MSG_VIS_REMOVE_CHILD
	call	ObjCallInstanceNoLock
.warn -private
	mov	si, offset OLFileSelectorFileList
	mov	di, ds:[si]
	add	di, ds:[di].Table_offset
	mov	si, ds:[di].TI_columnDefinitions
	mov	di, ds:[si]		; ds:di = table column defs
					; reduce name column width
	sub	ds:[di][(size TableColumnDefinition)].TCD_width, FILE_SELECTOR_MINIMIZE_ADJUSTMENT
	mov	si, offset OLFileSelectorFileHeading
	mov	di, ds:[si]
	add	di, ds:[di].Table_offset
	mov	si, ds:[di].TI_columnDefinitions
	mov	di, ds:[si]		; ds:di = header column defs
					; reduce name column width
	sub	ds:[di][(size TableColumnDefinition)].TCD_width, FILE_SELECTOR_MINIMIZE_ADJUSTMENT
.warn @private
	pop	si			; ^lbx:si = file selector
noMinimize:
endif

	call	ObjSwapUnlock		; *ds:si = OLFileSelector
	;
	; handle HINT_FILE_SELECTOR_SCALABLE_UI_DATA
	;	*ds:si = OLFileSelector
	;
	call	HandleScalableUIData	; sets GFSI_attrs
	;
	; set gadgetry that we don't need NOT_USABLE (if we destroy them, we'll
	; need to check for their existence elsewhere in the code when we
	; reference them - though this would be more efficient)
	;	*ds:si = OLFileSelector
	;	bx = ui block
	;

	call	OLFSTurnOffGadgetry
if _DUI
	;
	; set file count state based on moniker existance
	;
	push	si
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	tst	ds:[di].GI_visMoniker
	mov	si, offset OLFileSelectorFileCount
	call	OLFSSetUsableOnFlags
	pop	si
endif
	;
	; attach group as visual child of us
	;	*ds:si = OLFileSelector
	;	^hbx = duplicate block
	;
	mov	cx, bx				; ^lcx:dx = top of tree
	mov	dx, offset OLFileSelectorGroup
	push	cx				; save block handle
	call	GenAddChildUpwardLinkOnly

	;
	; copy our hint chunk to the dynamic list, as appropriate, and get
	; our own information out as well.
	;
	call	OLFSProcessHints		; deal with hints chunk
	;
	; For Wizard, we want the default directory to be SP_TOP/DESKTOP
	;
ifdef WIZARDBA	;--------------------------------------------------------------
	call	OLFSSetDefaultWizardDirectory	; set default directory
endif		;--------------------------------------------------------------
	;
	; Vis Build the group, after determining if the FS itself is enabled,
	; so we can pass the SBF_VIS_PARENT_FULLY_ENABLED flag to the kid
	;
	pop	bx				; bx <- UI block
	pop	bp				; restore SpecBuildFlags

	andnf	bp, not mask SBF_UPDATE_MODE

CheckHack< VUM_MANUAL eq 0 >
; As long as VUM_MANUAL is zero this 'ornf' instruction serves no purpose,
; and in general just outputs a warning.  Should VUM_MANUAL ever change
; to a non-zero value, put this instruction back in.	dlitwin 5/20/94
;	ornf	bp, VUM_MANUAL shl offset SBF_UPDATE_MODE

	call	OLFSDeref_SI_Gen_DI		; ds:di = fs generic instance
	test	ds:[di].GI_states, mask GS_ENABLED	
	jnz	10$				;object is enabled, branch
	andnf	bp, not mask SBF_VIS_PARENT_FULLY_ENABLED
10$:
	
	mov	si, offset OLFileSelectorGroup	; ^lbx:si <- fs ui group
	mov	ax, MSG_SPEC_BUILD_BRANCH
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	GOTO	ObjMessage

OLFileSelectorSpecBuild	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFSSpecScanGeometryHints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	make sure we turn off OLCOF_DISPLAY_MONIKER

CALLED BY:	MSG_SPEC_SCAN_GEOMETRY_HINTS
PASS:		*ds:si	= OLFileSelectorClass object
		ds:di	= OLFileSelectorClass instance data
		ds:bx	= OLFileSelectorClass object (same as *ds:si)
		es 	= segment of OLFileSelectorClass
		ax	= message #
RETURN:		nothing
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/24/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if _DUI
OLFSSpecScanGeometryHints	method dynamic OLFileSelectorClass, 
					MSG_SPEC_SCAN_GEOMETRY_HINTS
	mov	di, offset OLFileSelectorClass
	call	ObjCallSuperNoLock
	call	OLFSDeref_SI_Spec_DI
	andnf	ds:[di].OLCI_optFlags, not mask OLCOF_DISPLAY_MONIKER
	ret
OLFSSpecScanGeometryHints	endm
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFSSetDefaultWizardDirectory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the default directory for Wizard to be SP_TOP/DESKTOP

CALLED BY:	OLFileSelectorSpecBuild
PASS:		*ds:si	= instance data
		es = segment of OLFileSelectorClass
RETURN:		nothing
DESTROYED:	ax, bx, cx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	10/18/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef WIZARDBA	;--------------------------------------------------------------

desktopDirectory	char	"DESKTOP"
DESKTOP_NAME_LENGTH	equ	($ - offset desktopDirectory)
nullChar		char	C_NULL

OLFSSetDefaultWizardDirectory	proc	near
	; KEEP homeFolder AND desktopFolder IN THIS ORDER!!!
homeFolder	local	PathName
separator	local	char
desktopFolder	local	DESKTOP_NAME_LENGTH dup (char)
	uses	es
	.enter
	;
	; Check ATTR_GEN_FILE_SELECTOR_VIRTUAL_ROOT
	;
	mov	ax, ATTR_GEN_FILE_SELECTOR_VIRTUAL_ROOT
	call	CheckDirectoryVarData
	LONG jc	done
	;
	; Fill in desktopFolder and homeFolder names.
	;
	segmov	es, ss
	lea	di, ss:[desktopFolder]
	call	GetDesktopSlashHomeDir
	;
	; save full home folder name in TEMP_GEN_FILE_SELECTOR_HOME_DIRECTORY
	;
	call	LocalStringSize
	inc	cx			; add one for NULL at end of string

	mov	ax, TEMP_GEN_FILE_SELECTOR_HOME_DIRECTORY
	call	ObjVarAddData

	push	ds, si
	segmov	es, ds
	mov	di, bx
	segmov	ds, ss
	lea	si, ss:[desktopFolder]
	LocalCopyNString
	pop	ds, si
	;
	; We will be using a virtual root.
	;
	call	OLFSDeref_SI_Gen_DI
	ORNF	ds:[di].GFSI_attrs, mask FSA_USE_VIRTUAL_ROOT
	call	OLFSDeref_SI_Spec_DI
	ORNF	ds:[di].OLFSI_state, mask OLFSS_USING_WIZARD_VIRTUAL_ROOT
	;
	; Check to see if we want DESKTOP with Home Dir selected to be "Home"
	;
	mov	ax, HINT_FILE_SELECTOR_USE_DESKTOP_HOME
	call	ObjVarFindData
	jnc	afterDesktopHome
	;
	; Home dir will be the DESKTOP and we will need to select the home dir.
	;
	ORNF	ds:[di].OLFSI_state, mask OLFSS_USING_DESKTOP_HOME or \
				     mask OLFSS_SELECT_HOME
	mov	ss:[separator], C_NULL

afterDesktopHome:
	;
	; Setup virtual root and path data.
	;
	mov	ax, ATTR_GEN_FILE_SELECTOR_VIRTUAL_ROOT
	mov	cx, cs
	mov	dx, offset cs:[desktopDirectory]
	call	SetDirectoryVarData

	mov	ax, ATTR_GEN_PATH_DATA
	call	ObjVarFindData
	jnc	done

	test	ds:[bx].GFP_disk, DISK_IS_STD_PATH_MASK
	jz	done

	mov	cx, ss
	lea	dx, ss:[desktopFolder]
	call	ConvertStandardPathToWizardPath
	jc	updatePathData

	call	OLFSDeref_SI_Spec_DI
	test	ds:[di].OLFSI_state, mask OLFSS_USING_DESKTOP_HOME
	jz	updatePathData

	movdw	esdi, cxdx
	mov	al, '\\'
	mov	cx, -1
	repne	scasb
	mov	{byte} es:[di-1], C_NULL
	mov	cx, es

updatePathData:
	mov	ax, ATTR_GEN_PATH_DATA
	call	SetDirectoryVarData
done:
	.leave
	ret
OLFSSetDefaultWizardDirectory	endp

;
; Pass:		*ds:si	- instance data
;		ax	- ATTR_GEN_PATH_DATA or
;			  ATTR_GEN_FILE_SELECTOR_VIRTUAL_ROOT
; Return:	carry set if we should not use WIZARD_VIRTUAL_ROOT
;
CheckDirectoryVarData	proc	near
EC <	cmp	ax, ATTR_GEN_PATH_DATA					>
EC <	je	ok							>
EC <	cmp	ax, ATTR_GEN_FILE_SELECTOR_VIRTUAL_ROOT			>
EC <	ERROR_NE	OL_ERROR					>
EC <ok:									>
	;
	; Check directory info in vardata
	;
	call	ObjVarFindData
	jnc	done
	;
	; If vardata is found, we check to see if it is just SP_(TOP/DOCUMENT)
	;
	cmp	{byte} ds:[bx].GFP_path[0], C_NULL
	je	checkDisk
	cmp	{word} ds:[bx].GFP_path[0], '\\'
	jne	setCarry
checkDisk:
	cmp	ds:[bx].GFP_disk, SP_DOCUMENT
	je	done
	cmp	ds:[bx].GFP_disk, SP_TOP
	je	done
setCarry:
	stc
done:
	ret
CheckDirectoryVarData	endp

;
; Pass:		*ds:si	- instance data
;		ax	- ATTR_GEN_PATH_DATA or
;			  ATTR_GEN_FILE_SELECTOR_VIRTUAL_ROOT
;		cx:dx	- path to store in vardata
; Return:	nothing
;
SetDirectoryVarData	proc	near
	.enter	inherit OLFSSetDefaultWizardDirectory
EC <	cmp	ax, ATTR_GEN_PATH_DATA					>
EC <	je	ok							>
EC <	cmp	ax, ATTR_GEN_FILE_SELECTOR_VIRTUAL_ROOT			>
EC <	ERROR_NE	OL_ERROR					>
EC <ok:									>
	;
	; Add the data to the object.
	;
	push	cx
	mov	cx, size GenFilePath
	call	ObjVarAddData
	pop	cx
	;
	; Initialize it to SP_TOP/DESKTOP
	;
	push	es, ds, si
	segmov	es, ds
	mov	di, bx
	movdw	dssi, cxdx
	mov	ax, SP_TOP
	stosw
	LocalCopyString
	pop	es, ds, si
	.leave
	ret
SetDirectoryVarData	endp

;
; Pass:		es:di = PathName
; Return:	es:di filled with DESKTOP/<Home dir>
; Destroy:	nothing
;
GetDesktopSlashHomeDir	proc	near
	uses	ax, cx, dx, di, ds
	.enter

	mov	ax, 'DE'
	stosw
	mov	ax, 'SK'
	stosw
	mov	ax, 'TO'
	stosw
	mov	ax, 'P\\'
	stosw
	movdw	cxdx, esdi
	call	IclasGetUserFullName

	mov	ds, cx				; ds:dx = userFullName
	call	IclasFilterLongname

	.leave
	ret
GetDesktopSlashHomeDir	endp

endif		;--------------------------------------------------------------



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertStandardPathToWizardPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert standard paths into SP_TOP:\DESKTOP\<Home Dir>\...

CALLED BY:	INTERNAL
PASS:		ds:bx	= GenFilePath to convert
		cx:dx	= PathName buffer to store converted path
RETURN:		cx:dx	= filled with 'DESKTOP\<Home Dir>\...'
		carry clear if passed GenFilePath == SP_TOP:\ or SP_DOCUMENT:\
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	5/29/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef WIZARDBA	;--------------------------------------------------------------

ConvertStandardPathToWizardPath	proc	near
genFilePath	local	fptr		push	ds, bx
fullPath	local	PathName
sptopPath	local	PathName
	uses	ax, bx, cx, dx, si, di, ds, es
	.enter

EC <	call	OLFSDeref_SI_Spec_DI					 >
EC <	test	ds:[di].OLFSI_state, mask OLFSS_USING_WIZARD_VIRTUAL_ROOT>
EC <	ERROR_Z -1			; This should never happen	 >
EC <	test	ds:[bx].GFP_disk, 1	; StandardPaths are odd		 >
EC <	ERROR_Z	-1							 >

	;
	; Copy 'DESKTOP\<Home Dir>' to destination buffer
	;
	movdw	esdi, cxdx
	call	GetDesktopSlashHomeDir
	;
	; Compare the path with SP_TOP to get path relative to SP_TOP
	;
	push	cx, dx			; save fptr
	segmov	es, ss
	lea	di, ss:[fullPath]
	mov	cx, size PathName
	lea	si, ds:[bx].GFP_path
	mov	bx, ds:[bx].GFP_disk
	clr	dx
	call	FileConstructFullPath

	segmov	ds, cs
	mov	si, offset cs:[rootPath]
	lea	di, ss:[sptopPath]
	mov	bx, SP_TOP
	call	FileConstructFullPath

	segmov	ds, ss
	lea	si, ss:[fullPath]	; ds:si = fullPath
	lea	di, ss:[sptopPath]	; es:di = sptopPath
	mov	cx, size PathName
	repe	cmpsb
	mov	al, ds:[si-2]		; Check to see if the last characters
	or	al, es:[di-2]		;  that matched were C_NULL's.
	pop	es, di
	jz	done			; If last characters that matched were
					;  C_NULL's then we have perfect match.
	;
	; Check to see if the path was already under the DESKTOP directory.
	;
	push	si
	lodsw
	cmp	ax, 'DE'
	jne	popSI
	lodsw
	cmp	ax, 'SK'
	jne	popSI
	lodsw
	cmp	ax, 'TO'
	jne	popSI
	lodsw
	cmp	ax, 'P\\'
	je	popSI
	cmp	ax, 'P'
popSI:	pop	si
	jne	notUnderDesktop

underDesktop:
	lds	si, ss:[genFilePath]	; don't alter path data
	lea	si, ds:[si].GFP_path
	jmp	copyString

notUnderDesktop:
	; 
	; Copy difference between path and SP_TOP
	;
	mov	al, C_NULL
	mov	cx, -1
	repne	scasb
	dec	di			; es:di = end of Desktop/<Home dir>
	dec	si			; ds:si = fullPath relative to SP_TOP

copyString:
	LocalCopyString
	stc				; path was not SP_TOP: or SP_DOCUMENT:
done:
	.leave
	ret
ConvertStandardPathToWizardPath	endp

endif		;--------------------------------------------------------------



COMMENT @----------------------------------------------------------------------

METHOD:		OLFileSelectorSpecUnbuild -- MSG_SPEC_UNBUILD
			for OLFileSelectorClass

DESCRIPTION:	Unbuild this file selector visually, destroying
		duplicated UI block.

PASS:
	*ds:si - instance data
	es - segment of OLFileSelectorClass (OL dgroup)

	ax - MSG_SPEC_UNBUILD

	cx - ?
	dx - ?
	bp - SpecBuildFlags

RETURN:
	carry - ?
	ax, cx, dx, bp - ?

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	6/16/92		Initial version

------------------------------------------------------------------------------@

OLFileSelectorSpecUnbuild	method	OLFileSelectorClass, MSG_SPEC_UNBUILD
	;
	; call superclass to do unbuild
	;
	mov	di, offset OLFileSelectorClass
	call	ObjCallSuperNoLock
	;
	; Destroy the duplicated block (the tree points at us with an upward
	; generic link and visual links were severed above, so no need to futz
	; with any linkage).
	;
						; preserves ax, cx, dx, bp
	call	DestroyBlockAndRemoveFromActiveList
	ret
OLFileSelectorSpecUnbuild	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLFileSelectorSpecUnbuildBranch -- MSG_SPEC_UNBUILD_BRANCH
			for OLFileSelectorClass

DESCRIPTION:	Unbuild this file selector visually, unbuilding
		duplicated UI block.

PASS:
	*ds:si - instance data
	es - segment of OLFileSelectorClass (OL dgroup)

	ax - MSG_SPEC_UNBUILD_BRANCH

	cx - ?
	dx - ?
	bp - SpecBuildFlags

RETURN:
	carry - ?
	ax, cx, dx, bp - ?

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/17/92		Initial version

------------------------------------------------------------------------------@

OLFileSelectorSpecUnbuildBranch	method	dynamic OLFileSelectorClass,
						MSG_SPEC_UNBUILD_BRANCH

	;
	; unbuild group, destroyed in SPEC_UNBUILD handler
	;
	push	ax, bp, si		; save message, SpecBuildFlags
	mov	bx, ds:[di].OLFSI_uiBlock
	mov	si, offset OLFileSelectorGroup
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	ax, bp, si		; restore message, SpecBuildFlags
	;
	; call superclass to finish up
	;
	mov	di, offset OLFileSelectorClass
	call	ObjCallSuperNoLock
	ret
OLFileSelectorSpecUnbuildBranch	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLFileSelectorDetach -- MSG_META_DETACH for OLFileSelectorClass

DESCRIPTION:	Destroy duplicated UI block.

PASS:
	*ds:si - instance data
	es - segment of OLFileSelectorClass (OL dgroup)

	ax - MSG_META_DETACH

	cx - ack ID
	^ldx:bp - ack OD

RETURN:
	carry - ?
	ax, cx, dx, bp - ?

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/13/92		Initial version

------------------------------------------------------------------------------@

OLFileSelectorDetach	method	OLFileSelectorClass, MSG_META_DETACH
	;
	; Destroy the duplicated block and remove from active list
	;
						; preserves ax, cx, dx, bp
	call	DestroyBlockAndRemoveFromActiveList
	;
	; call superclass to finish
	;
	mov	di, offset OLFileSelectorClass
	call	ObjCallSuperNoLock
	ret
OLFileSelectorDetach	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DestroyBlockAndRemoveFromActiveList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	destroy

CALLED BY:	INTERNAL
			OLFileSelectorSpecUnbuild
			OLFileSelectorDetach

PASS:		*ds:si = file selector

RETURN:		nothing

DESTROYED:	bx, si, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	07/28/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DestroyBlockAndRemoveFromActiveList	proc	near
	push	ax, cx, dx, bp
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
if HANDLE_CREATE_GEOS_FILE_NOTIFICATION
	;
	; nuke GEOS File FileID list
	;
	clr	bx
	xchg	ds:[di].OLFSI_geosFileIDList, bx
	tst	bx
	jz	noGEOSFileIDList
	call	MemFree
noGEOSFileIDList:
endif
if FSEL_DISABLES_FILTERED_FILES
	;
	; nuke file reject list
	;
	clr	bx
	mov	ds:[di].OLFSI_numRejects, bx
	xchg	ds:[di].OLFSI_rejectList, bx
	tst	bx
	jz	freed
	call	MemFree
freed:
endif
	clr	bx
	xchg	ds:[di].OLFSI_uiBlock, bx	; ^lbx:si = an object in block
	tst	bx
	jz	done
	push	si				; save FileSelector chunk
	mov	si, offset OLFileSelectorGroup
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	bp, 0				; no dirtying cause we have
						;	just an upward link
	mov	ax, MSG_GEN_DESTROY
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	mov	ax, MSG_META_BLOCK_FREE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	si				; restore FileSelector chunk
done:
	;
	; Remove ourselves from the file-system change notification list.
	; 
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GCNSLT_FILE_SYSTEM
	call	GCNListRemove
	;
	; remove ourselves from active list
	;
	mov	dx, size GCNListParams
	sub	sp, dx
	mov	bp, sp
	mov	ss:[bp].GCNLP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLP_ID.GCNLT_type, MGCNLT_ACTIVE_LIST
	mov	ax, ds:[LMBH_handle]
	mov	ss:[bp].GCNLP_optr.handle, ax
	mov	ss:[bp].GCNLP_optr.chunk, si
	mov	ax, MSG_META_GCN_LIST_REMOVE
	call	OpenCallApplicationWithStack
	add	sp, size GCNListParams
	pop	ax, cx, dx, bp
	ret
DestroyBlockAndRemoveFromActiveList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFileSelectorNotifyEnabled
		OLFileSelectorNotifyNotEnabled
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle being set enabled or not enabled (since we have
		generic children that are connected via one-way links).

CALLED BY:	MSG_SPEC_NOTIFY_ENABLED, MSG_SPEC_NOTIFY_NOT_ENABLED

PASS:		*ds:si - object
		es - segment of OLFileSelectorClass
		ax - MSG_SPEC_NOTIFY_ENABLED
		     MSG_SPEC_NOTIFY_NOT_ENABLED
		dl - update flags
		dh - NotifyEnabledFlags

RETURN:		carry set if indicate visual state changed

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLFileSelectorNotifyEnabled	method	OLFileSelectorClass,
						MSG_SPEC_NOTIFY_ENABLED
	mov	cx, MSG_GEN_NOTIFY_ENABLED
	GOTO	OLFSNotifyCommon
OLFileSelectorNotifyEnabled	endm

OLFileSelectorNotifyNotEnabled	method	OLFileSelectorClass,
						MSG_SPEC_NOTIFY_NOT_ENABLED
	mov	cx, MSG_GEN_NOTIFY_NOT_ENABLED
	FALL_THRU	OLFSNotifyCommon
OLFileSelectorNotifyNotEnabled	endm

OLFSNotifyCommon	proc	far
	push	ax, cx, dx		; save method data
	mov	di, offset OLFileSelectorClass
	call	ObjCallSuperNoLock
	pop	ax, cx, dx		; retrieve method data
	jnc	exit			; if nothing changed, done
	;
	; State changed.  We need to disable the various gadgetry that
	; makes up a GenFileSelector.  These are connected to the
	; GenFileSelector via one-way links, but are full visible children.
	;
	mov	ax, cx			; send generic enable/not-enable method
	and	dh, not mask NEF_STATE_CHANGING
	call	VisSendToChildren
	stc				; indicate something changed
exit:
	ret
OLFSNotifyCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFileSelectorVisOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	File Selector is being visually opened, build buffers.

CALLED BY:	MSG_VIS_OPEN

PASS:		*ds:si = OLFileSelector instance
		es - segment of OLFileSelectorClass (OL dgroup)
		ax - MSG_VIS_OPEN

RETURN:		nothing

DESTROYED:	ax,cx,dx,bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	02/13/90	Initial version
	brianc	4/91		Completed 2.0 revisions

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLFileSelectorVisOpen	method	OLFileSelectorClass, MSG_VIS_OPEN

	;
	; let superclass do its work
	;
	mov	di, offset OLFileSelectorClass	; call superclass
	call	ObjCallSuperNoLock

if _RUDY or _DUI
	;
	; The Rudy file selector displays dates/times of files,
	; we should be notified when the date/time formats change,
	; so that we can redisplay the file times.
	;
	; But if we don't display date/time, then we don't care about this
	; notification.
	;
		mov	ax, HINT_FILE_SELECTOR_MINIMIZE_WIDTH
		call	ObjVarFindData
		jc	afterNotify

		mov	cx, ds:[LMBH_handle]
		mov	dx, si
		mov	bx, MANUFACTURER_ID_GEOWORKS
		mov	ax, GCNSLT_NOTIFY_INIT_FILE_CHANGE
		call	GCNListAdd
afterNotify:
endif ; _RUDY or _DUI

if _DUI
	;
	; Add ourselves to secret mode change notification list, so
	; that we can rescan when the secret mode changes.
	;	^lcx:dx = ourselves
	;
	mov	bx, MANUFACTURER_ID_NEC
	mov	ax, NECGCNSLT_NOTIFY_SECRET_MODE_CHANGE
	call	GCNListAdd
endif
		
if _JEDIMOTIF
	;
	; If JFileSelectorClass, have the table object grab the target
	; (not pretty, but it works).
	;
	push	es
	mov	di, segment JFileSelectorClass
	mov	es, di
	mov	di, offset JFileSelectorClass
	call	ObjIsObjectInClass
	pop	es
	jnc	notTarget
	call	OLFSDeref_SI_Spec_DI
	mov	bx, ds:[di].OLFSI_uiBlock
	tst	bx
	jz	notTarget
	push	si
	mov	si, offset OLFileSelectorFileView
	mov	ax, MSG_META_GRAB_TARGET_EXCL
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	mov	si, offset OLFileSelectorFileList
	mov	ax, MSG_META_GRAB_TARGET_EXCL
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	si
notTarget:
endif

if HAVE_FAKE_FILE_SYSTEM
	push	di
	call	OLFSDeref_SI_Gen_DI
	test	ds:[di].GFSI_fileCriteria, mask FSFC_USE_FAKE_FILE_SYSTEM
	jz	notFake
	mov	ax, MSG_GEN_FILE_SELECTOR_FAKE_FLUSH_CACHES
	call	ObjCallInstanceNoLock
notFake:
	pop	di
endif


	;
	; make sure our path is valid, if not, use default
	;
	mov	ax, ATTR_GEN_PATH_DATA
	mov	dx, TEMP_GEN_PATH_SAVED_DISK_HANDLE
	call	GenPathFetchDiskHandleAndDerefPath	; ax = disk handle
							;	0 if needed to
							;	restore and
							;	couldn't
							; ds:bx = GenFilePath
	tst	ax
	jnz	pathValid
	mov	ax, ATTR_GEN_PATH_DATA			; nuke path
	call	ObjVarDeleteData
	mov	ax, TEMP_GEN_PATH_SAVED_DISK_HANDLE	; nuke saved path
	call	ObjVarDeleteData
	
pathValid:
	;
	; Build drive popup list
	;
if not SINGLE_DRIVE_DOCUMENT_DIR and FSEL_HAS_CHANGE_DRIVE_POPUP
	call	OLFSBuildChangeDrivePopup
endif

if not SINGLE_DRIVE_DOCUMENT_DIR	
			;was moved to VIS_DRAW in Redwood to improve drawing.
			;  Removed from general use 7/ 5/94 cbh.   Seem to be 
			;  problems in the VIS_DRAW
			;  code that prevent this from being a general
			;  improvement.
	;
	; Tell ourselves to rescan the current directory.
	; 
	call	OLFSDeref_SI_Spec_DI		; clear error flag
	andnf	ds:[di].OLFSI_state, not mask OLFSS_VIS_OPEN_ERROR

	mov	ax, MSG_GEN_FILE_SELECTOR_RESCAN
	call	ObjCallInstanceNoLock
	;
	; If error, just set to SP_TOP
	;
	call	OLFSDeref_SI_Spec_DI		; ds:di = specific instance
	test	ds:[di].OLFSI_state, mask OLFSS_VIS_OPEN_ERROR
	jz	done
	mov	bp, SP_TOP

NOFXIP<	mov	cx, cs						>
NOFXIP<	mov	dx, offset nullPath				>

FXIP <	; copy path to stack					>
FXIP <	clr	cx						>
FXIP <	push	cx						>
FXIP <	mov	cx, ss						>
FXIP <	mov	dx, sp			; cx:dx = nullPath	>
	
	mov	ax, MSG_OL_FILE_SELECTOR_PATH_SET
	call	ObjCallInstanceNoLock

FXIP <	pop	cx		; restore stack, ignore value	>	
	
	; XXX: ignore error -- shouldn't be any
else
	; Delay rescanning until after we draw, in Redwood.

	call	OLFSDeref_SI_Spec_DI		; ds:di = specific instance
	or	ds:[di].OLFSI_state, mask OLFSS_RESCAN_AFTER_DRAW
endif

done:
	ret
OLFileSelectorVisOpen	endm




COMMENT @----------------------------------------------------------------------

METHOD:		OLFileSelectorDraw -- 
		MSG_VIS_DRAW for OLFileSelectorClass

DESCRIPTION:	Draw the file selector.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_DRAW
		some stuff.

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
	chris	11/ 1/93        Initial Version

------------------------------------------------------------------------------@

if SINGLE_DRIVE_DOCUMENT_DIR
				;can't yet use generally, until the change
				;  to the document dir is removed!  7/ 5/94 cbh

OLFileSelectorDraw	method dynamic	OLFileSelectorClass, \
				MSG_VIS_DRAW


				;can't yet use generally, until the change
				;  to the document dir is removed!  7/ 5/94 cbh
	;
	; let superclass do its work
	;
	mov	di, offset OLFileSelectorClass	; call superclass
	call	ObjCallSuperNoLock

	;
	; Tell ourselves to rescan the current directory, if this is the
	; initial draw after the MSG_VIS_OPEN.
	; 
	call	OLFSDeref_SI_Spec_DI		; clear error flag
	test	ds:[di].OLFSI_state, mask OLFSS_RESCAN_AFTER_DRAW
	jz	exit

	andnf	ds:[di].OLFSI_state, not mask OLFSS_RESCAN_AFTER_DRAW

	andnf	ds:[di].OLFSI_state, not mask OLFSS_VIS_OPEN_ERROR
	;
	; Attempt to force the file selector to the document dir.  Queue
	; it so the file selector gets up before the error message does.
	;
	push	ax, bp
	mov	bx, ds:[LMBH_handle]
	mov	ax, MSG_OL_FILE_SELECTOR_DOCUMENT_BUTTON
	mov	di, mask MF_FORCE_QUEUE or mask MF_INSERT_AT_FRONT
	call	ObjMessage
	pop	ax, bp

	;
	; If error, just set to SP_TOP
	;
	call	OLFSDeref_SI_Spec_DI		; ds:di = specific instance
	test	ds:[di].OLFSI_state, mask OLFSS_VIS_OPEN_ERROR
	jz	exit
	mov	bp, SP_TOP

NOFXIP<	mov	cx, cs						>
NOFXIP<	mov	dx, offset nullPath				>
	
FXIP <	; copy path to stack					>
FXIP <	clr	cx						>
FXIP <	push	cx						>
FXIP <	mov	cx, ss						>
FXIP <	mov	dx, sp			; cx:dx = nullPath	>
	
	mov	ax, MSG_OL_FILE_SELECTOR_PATH_SET
	call	ObjCallInstanceNoLock

FXIP< 	pop	cx		; restore stack, ignore value	>	
	
	; XXX: ignore error -- shouldn't be any
exit:
	ret
OLFileSelectorDraw	endm

endif	;if SINGLE_DRIVE_DOCUMENT_DIR


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFileSelectorVisClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	File Selector is being visually closed, free buffers.

CALLED BY:	MSG_VIS_CLOSE

PASS:		*ds:si = OLFileSelector instance
		es - segment of OLFileSelectorClass (OL dgroup)
		ax - MSG_VIS_CLOSE

RETURN:		nothing

DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	02/13/90	Initial version
	brianc	4/91		Completed 2.0 revisions

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLFileSelectorVisClose	method	OLFileSelectorClass, MSG_VIS_CLOSE
	call	ObjMarkDirty			; gen instance data changes
	;
	; let superclass do its work
	;
	mov	di, offset OLFileSelectorClass	; call superclass
	call	ObjCallSuperNoLock
if _RUDY or _DUI
	;
	; Get off of the list that notified us when we had to redisplay
	; file times.  If we weren't on it, no harm done.
	;
		mov	cx, ds:[LMBH_handle]
		mov	dx, si
		mov	bx, MANUFACTURER_ID_GEOWORKS
		mov	ax, GCNSLT_NOTIFY_INIT_FILE_CHANGE
		call	GCNListRemove
endif ; _RUDY or _DUI

if _DUI
	;
	; Remove ourselves from secret mode change list.
	;	^lcx:dx = ourselves
	;
	mov	bx, MANUFACTURER_ID_NEC
	mov	ax, NECGCNSLT_NOTIFY_SECRET_MODE_CHANGE
	call	GCNListRemove
endif

	;
	; free our buffers
	;
	call	OLFSFreeBuffers
	ret
OLFileSelectorVisClose	endm

;
; pass:
;	*ds:si = file selector
; destroys:
;	nothing
;
OLFSFreeBuffers	proc	near
	uses	bx, di
	class	OLFileSelectorClass
	.enter
	call	OLFSDeref_SI_Spec_DI		; ds:di = specific instance
	clr	bx
	mov	ds:[di].OLFSI_numFiles, bx	; This used to be in
						; OLFileSelectorVisClose, 
						; but moved here so
						; all callers have
						; nuked numFiles
	xchg	bx, ds:[di].OLFSI_fileBuffer
	tst	bx
	jz	30$
	call	MemFree
30$:
	clr	bx
	xchg	bx, ds:[di].OLFSI_indexBuffer
	tst	bx
	jz	60$
	call	MemFree
60$:
	.leave
	ret
OLFSFreeBuffers	endp

if _RUDY or _DUI

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFSMetaNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Listens for notifications we care about.

CALLED BY:	MSG_META_NOTIFY
PASS:		*ds:si	= OLFileSelectorClass object
		ds:di	= OLFileSelectorClass instance data
		ds:bx	= OLFileSelectorClass object (same as *ds:si)
		es 	= segment of OLFileSelectorClass
		ax	= message #
		cx:dx - NotificationType
			cx - NT_manuf
			dx - NT_type
		bp - change specific data
		
RETURN:		nothing
DESTROYED:	everything
SIDE EFFECTS:	Could cause file selector to rescan

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	12/22/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLFSMetaNotify	method dynamic OLFileSelectorClass, 
					MSG_META_NOTIFY
	.enter

if _DUI
	cmp	cx, MANUFACTURER_ID_NEC
	jne	notSecret
	cmp	dx, NECNT_SECRET_MODE_CHANGE
	je	secretChange
notSecret:
endif

	cmp	cx, MANUFACTURER_ID_GEOWORKS
	jne	notDTFChange
	cmp	dx, GWNT_INIT_FILE_CHANGE
	jne	notDTFChange
	cmp	bp, IFE_DATE_TIME_FORMAT
	jne	notDTFChange

if 1
;
; all we really need to do is redraw -- brianc 3/11/95
;
	;	
	; get current selection for resetting later
	;	*ds:si = file selector
	;
if _RUDY
	mov	ax, -1				; selection negative if we
	call	OLFSIsNonExclusive		; are non-exclusive
	jnc	useTempData
	call	OLFSGetMultipleSelectionsInBlock  ; cx = #, bx = block
	push	bx				; put block on stack
	mov	ax, cx				; ax = # of selections
	jmp	doReset
useTempData:
	clr	dx				; put null block on stack
	push	dx
endif
	call	OLFSFindTempData		; ds:bx = var data entry
	mov	ax, ds:[bx].GFSTDE_selectionNumber ; ax = current selection
doReset:
	;
	; reset list with current number of files
	;
	call	OLFSDeref_SI_Spec_DI
	mov	bx, ds:[di].OLFSI_uiBlock
	tst	bx
NRUDY <	jz	done							>
RUDY <	jz	freeSelections						>

if _FILE_TABLE
PrintMessage<Make _RUDY support _FILE_TABLE>
endif
	push	ax				; save current selection
	mov	si, offset OLFileSelectorFileList
	mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
	mov	cx, GDLI_NO_CHANGE		; same number of items
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	;
	; reset current selection, we shouldn't need apply message to go
	; out as this is just a time/date format change
	;	^lbx:si = list object
	;
	pop	cx				; cx = current selection
	clr	dx				; not indeterminate

if _RUDY
	; If exclusive file selector, use exclusive selection
	;
	mov	ax, MSG_FILTER_LIST_SET_SINGLE_SELECTION
	pop	di				; get selection block
	tst	di				; no selection block?
	jz	setSelection			; is exclusive => single
						; selection

	; Else lock down the selection block and set multiple selections

	mov	bp, cx				; bp = # of selections
	push	bx				; save child block
	mov	bx, di
	call	MemLock				; ax = segment
	mov	cx, ax				; cx:dx = selections
	pop	bx				; restore child block
	mov	ax, MSG_FILTER_LIST_SET_MULTIPLE_SELECTIONS
setSelection:
	push	di				; save selection block
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

freeSelections:
	pop	bx				; restore selection block
	tst	bx
	jz	done
	call	MemFree				; and free

else ; not _RUDY

	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	di, mask MF_FIXUP_DS

	call	ObjMessage

endif ; not _RUDY

else ; rescan on date/time format change

	;
	; The user has changed date/time formats on us, so we should
	; redisplay our files with the new format.
	;
	mov	ax, MSG_GEN_FILE_SELECTOR_RESCAN
	call	ObjCallInstanceNoLock

endif ; rescan on date/time format change

notDTFChange:
	;
	; Other types of notifications go here.
	;
done:
	.leave
	ret

if _DUI
secretChange:
	;
	; just rescan
	;
	mov	ax, MSG_GEN_FILE_SELECTOR_RESCAN
	call	ObjCallInstanceNoLock
	jmp	short done
endif

OLFSMetaNotify	endm

endif ; _RUDY or _DUI


COMMENT @----------------------------------------------------------------------

METHOD:		OLFileSelectorSetSomething

DESCRIPTION:	Take note of a change in some file-selector attribute that
		can affect things displayed

PASS:
	*ds:si - instance data
	es - segment of OLFileSelectorClass

	ax - MSG_GEN_FILE_SELECTOR_SET_ATTRS
	     MSG_GEN_FILE_SELECTOR_SET_FILE_ATTRS
	     MSG_GEN_FILE_SELECTOR_SET_FILE_CRITERIA
	     MSG_GEN_FILE_SELECTOR_SET_FILE_MASK
	     MSG_GEN_FILE_SELECTOR_SET_FILE_GEODE_ATTRS
	     MSG_GEN_FILE_SELECTOR_SET_FILE_TOKEN
	     MSG_GEN_FILE_SELECTOR_SET_FILE_CREATOR

	cx - FileSelectorAttrs

RETURN:
	Nothing

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
	ardeb	12/91		changed to field all attribute-changes

------------------------------------------------------------------------------@

OLFileSelectorSetSomething method	OLFileSelectorClass,
				MSG_GEN_FILE_SELECTOR_SET_FILE_ATTRS,
				MSG_GEN_FILE_SELECTOR_SET_FILE_CRITERIA,
				MSG_GEN_FILE_SELECTOR_SET_MASK,
				MSG_GEN_FILE_SELECTOR_SET_GEODE_ATTRS,
				MSG_GEN_FILE_SELECTOR_SET_TOKEN,
				MSG_GEN_FILE_SELECTOR_SET_CREATOR
					

	call	OLFSMarkDirtyAndRescanIfRealized

	ret

OLFileSelectorSetSomething	endm

OLFileSelectorSetAttrs	method	OLFileSelectorClass,
				MSG_GEN_FILE_SELECTOR_SET_ATTRS
	call	OLFSDeref_SI_Spec_DI
	mov	bx, ds:[di].OLFSI_uiBlock
	tst	bx
	jz	done

if not SINGLE_DRIVE_DOCUMENT_DIR
	call	OLFSTurnOffGadgetry		; for any changes in FSA_HAS_*
if FSEL_HAS_CHANGE_DRIVE_POPUP
	call	OLFSBuildChangeDrivePopup	; update in case change in
						; FSA_SHOW_FIXED_DISKS_ONLY
				; for change in FSA_SHOW_FILES_DISABLED
endif
endif

	call	OLFSMarkDirtyAndRescanIfRealized
done:
	ret
OLFileSelectorSetAttrs	endm

if _RUDY
OLFileSelectorSetEFSAttrs	method	OLFileSelectorClass,
				MSG_EFS_SET_ATTRS

	call	OLFSDeref_SI_Spec_DI
	mov	bx, ds:[di].OLFSI_uiBlock
	tst	bx
	jz	done

	;
	; If file selector child has focus, restore focus to correct child
	; object afterward.
	;

	mov	ax, MSG_VIS_VUP_QUERY_FOCUS_EXCL
	call	ObjCallInstanceNoLock		; ^lcx:dx = focus object
	push	cx

	;
	; Enable/disable search box as appropriate.
	;

if not SINGLE_DRIVE_DOCUMENT_DIR
	call	OLFSTurnOffGadgetry		; for any changes in FSA_HAS_*
if FSEL_HAS_CHANGE_DRIVE_POPUP
	call	OLFSBuildChangeDrivePopup	; update in case change in
						; FSA_SHOW_FIXED_DISKS_ONLY
				; for change in FSA_SHOW_FILES_DISABLED
endif
endif
	;
	; Now restore focus to correct child, if we had the focus
	; to begin with.
	;

	pop	cx				; get child focus block
	call	OLFSDeref_SI_Spec_DI
	cmp	ds:[di].OLFSI_uiBlock, cx	; is it one of ours?
	jne	done				; nope, we don't have focus
	mov	bx, cx				; else, give focus to child

	; If there is a search text box, give focus to that.

	call	OLFSIsSearchable
	mov	si, offset OLFileSelectorSearchText
	jc	grabFocus

	; Else give focus to list

	mov	si, offset OLFileSelectorFileList
grabFocus::
	mov     ax, MSG_META_GRAB_FOCUS_EXCL
	mov	di, mask MF_FORCE_QUEUE or mask MF_FIXUP_DS
	call    ObjMessage
done:
	ret
OLFileSelectorSetEFSAttrs	endm
endif ; _RUDY


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFileSelectorAddVarData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deal with programmer adjusting scanning criteria by
		manipulating our vardata.

CALLED BY:	MSG_META_ADD_VAR_DATA
PASS:		*ds:si	= OLFileSelector object
		dx	= size AddVarDataEntryParams
		ss:bp	= AddVarDataEntryParams
			XIP : ADVP_data not used here so don't worry about fptr
RETURN:		nothing
DESTROYED:	?

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 4/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLFileSelectorAddVarData method dynamic OLFileSelectorClass, MSG_META_ADD_VAR_DATA
		mov	cx, ss:[bp].AVDP_dataType
		FALL_THRU	OLFileSelectorDeleteVarData
OLFileSelectorAddVarData endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFileSelectorDeleteVarData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deal with programmer adjusting scanning criteria by
		manipulating our vardata

CALLED BY:	MSG_META_DELETE_VAR_DATA
PASS:		*ds:si	= OLFileSelector object
		cx	= vardata type to delete
RETURN:		nothing
DESTROYED:	?

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 4/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLFileSelectorDeleteVarData method OLFileSelectorClass, MSG_META_DELETE_VAR_DATA
	;
	; Let MetaClass deal with the actual data manipulation.
	; 
		push	cx
		mov	di, offset OLFileSelectorClass
		call	ObjCallSuperNoLock
		pop	cx

	;
	; See if it's one of the types that affect what we display.
	; 
CheckHack <(ATTR_GEN_FILE_SELECTOR_NAME_MASK eq \
	    ATTR_GEN_FILE_SELECTOR_GEODE_ATTR+4) and \
	   (ATTR_GEN_FILE_SELECTOR_GEODE_ATTR eq \
	    ATTR_GEN_FILE_SELECTOR_FILE_ATTR+4) and \
	   (ATTR_GEN_FILE_SELECTOR_FILE_ATTR eq \
	    ATTR_GEN_FILE_SELECTOR_CREATOR_MATCH+4) and \
	   (ATTR_GEN_FILE_SELECTOR_CREATOR_MATCH eq \
	    ATTR_GEN_FILE_SELECTOR_TOKEN_MATCH+4)>

		pushf		; save "data existed" return flag

		cmp	cx, ATTR_GEN_FILE_SELECTOR_TOKEN_MATCH
		jb	done
		cmp	cx, ATTR_GEN_FILE_SELECTOR_NAME_MASK
		ja	done
		
		call	OLFSMarkDirtyAndRescanIfRealized
done:
		popf
		ret
OLFileSelectorDeleteVarData endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFileSelectorCheckRemovable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the passed path is on a removable drive.  If
		so, the user may have switched disks, so make sure our
		disk handle is up to date.

CALLED BY:	OLFileSelectorInternalSetPath

PASS:		cx:dx - path
		bp - disk handle

RETURN:		bp - updated if changed

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/12/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLFileSelectorCheckRemovable	proc near
		uses	ax,bx

		.enter

	;
	; This test is necessary, as the top-level path could actually
	; be on a removable disk! (doublespace drives are listed as
	; "removable")
	;
		
		test	bp, DISK_IS_STD_PATH_MASK
		jnz	done

		mov	bx, bp
		call	DiskGetDrive
		call	DriveGetStatus
		jc	done
		test	ah, mask DS_MEDIA_REMOVABLE
		jz	done
	;
	; If error registering this disk, then just return the old
	; disk, on the assumption that the user will be asked to
	; re-insert it.
	;

		call	DiskRegisterDiskSilently
		jc	done
		mov	bp, bx
done:
		.leave
		ret
OLFileSelectorCheckRemovable	endp



COMMENT @----------------------------------------------------------------------

METHOD:		OLFileSelectorInternalSetPath -- MSG_OL_FILE_SELECTOR_PATH_SET
		for OLFileSelectorClass

DESCRIPTION:	Internal set path for a file selector -- clear selection
		then set path normally

PASS:
	*ds:si - instance data
	es - segment of OLFileSelectorClass

	ax - MSG_OL_FILE_SELECTOR_PATH_SET

	cx:dx - new path (null-terminated)  
		(if null, uses root directory to disk specified by disk handle)
		
		XIP: path must not be in a movable code resource

	bp - disk handle
		(if 0, use current disk handle; if none, use top-level)

RETURN:
	cx - ?
	dx - ?
	bp - ?
	carry - clear - no error
	ax - ?

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/2/92		Initial version

------------------------------------------------------------------------------@
OLFileSelectorInternalSetPath	method	OLFileSelectorClass,
						MSG_OL_FILE_SELECTOR_PATH_SET

FXIP <	push	bx, si							>
FXIP <	mov	bx, cx							>
FXIP <	mov	si, dx							>
FXIP <	call	ECAssertValidFarPointerXIP				>
FXIP <	pop	bx, si							>

	push	cx, dx, bp
	mov	ax, MSG_GEN_APPLICATION_MARK_APP_COMPLETELY_BUSY
	call	UserCallApplication
	pop	cx, dx, bp

	;
	; we are doing an internal MSG_OL_FILE_SELECTOR_PATH_SET,
	; we want to have the current directory (first entry) selected when
	; we rescan, so we clear the GFSI_selection field
	;
	call	OLFSDeref_SI_Gen_DI
SBCS <	clr	bl							>
DBCS <	clr	bx							>
SBCS <	xchg	bl, ds:[di].GFSI_selection				>
DBCS <	xchg	bx, {wchar}ds:[di].GFSI_selection			>

if HAVE_FAKE_FILE_SYSTEM
	;
	; Check if we are using a fake file system or are using the
	; real thing
	;
	test	ds:[di].GFSI_fileCriteria, mask FSFC_USE_FAKE_FILE_SYSTEM
	jnz	continue
endif
	; 
	; If the pased path is on a removable disk, then re-register
	; the disk now, in case the user just swapped disks.
	;
	call	OLFileSelectorCheckRemovable
continue:
	mov	ax, MSG_GEN_PATH_SET		;generic class may do something
						;	before we handle it
						;	below
	call	ObjCallInstanceNoLock
	pushf
	jnc	done
	;
	; An error occurred.  Restore previous selection.
	;
	call	OLFSDeref_SI_Gen_DI
SBCS <	mov	ds:[di].GFSI_selection, bl				>
DBCS <	mov	ds:[di].GFSI_selection, bx				>
	stc
done:
	mov	ax, MSG_GEN_APPLICATION_MARK_APP_NOT_COMPLETELY_BUSY
	call	UserCallApplication

	popf
	ret

OLFileSelectorInternalSetPath	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFileSelectorGetIDs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the IDs for the path we have set and store them in our
		vardata.

CALLED BY:	(INTERNAL) OLFileSelectorSetPath
PASS:		*ds:si	= GenFileSelector object
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 4/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLFileSelectorGetIDs proc	near
	class	OLFileSelectorClass
	uses	ax, bx, cx, dx, di, es
	.enter
	;
	; Fetch our new IDs.
	; 
	call	FilePushDir
	mov	ax, ATTR_GEN_PATH_DATA
	mov	dx, TEMP_GEN_PATH_SAVED_DISK_HANDLE
	call	GenPathSetCurrentPathFromObjectPath
	jc	bleah

	call	FileGetCurrentPathIDs
	jc	bleah
	
	;
	; Now copy the chunk into vardata, so we don't have the extra
	; chunk lying around.
	; 
	mov_tr	di, ax				; save handle
	ChunkSizeHandle ds, di, cx		; cx <- # bytes needed to
						;  store the thing
	
	mov	ax, TEMP_GEN_FILE_SELECTOR_DIR_IDS
						; don't save to state, as we
						;  need to build this for each
						;  session
	call	ObjVarAddData			; ds:bx <- place to store ids
	push	si, di, es
	mov	si, ds:[di]			; ds:si <- source
	mov	di, bx
	segmov	es, ds				; es:di <- dest
	rep	movsb
	pop	si, ax, es
	call	LMemFree			; free array
bleah:
	call	FilePopDir
	.leave
	ret
OLFileSelectorGetIDs		endp



COMMENT @----------------------------------------------------------------------

METHOD:		OLFileSelectorSetPath -- MSG_GEN_PATH_SET
		for OLFileSelectorClass

DESCRIPTION:	Set the path for a file selector

PASS:
	*ds:si - instance data
	es - segment of OLFileSelectorClass

	ax - MSG_GEN_PATH_SET

	cx:dx - new path (null-terminated)
		(if null, uses root directory to disk specified by disk handle)
		XIP: path must not be in a movable code resource

	bp - disk handle
		(if 0, use current disk handle; if none, use top-level)

RETURN:
	cx - ?
	dx - ?
	bp - ?
	carry - clear - no error
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

OLFileSelectorSetPath	method	OLFileSelectorClass, MSG_GEN_PATH_SET

FXIP <		push	bx, si						>
FXIP <		mov	bx, cx						>
FXIP <		mov	si, dx						>
FXIP <		call	ECAssertValidFarPointerXIP			>
FXIP <		pop	bx, si						>

ifdef WIZARDBA
	;
	; This is a hack for WizardBA:
	;	Upate ATTR_GEN_PATH_DATA to suit our needs.
	;
		test	ds:[di].OLFSI_state, mask OLFSS_USING_WIZARD_VIRTUAL_ROOT
		jz	noHack

		test	bp, DISK_IS_STD_PATH_MASK	; StandardPaths are odd.
		jz	noHack				; Skip if not StandardPath

		call	OLFileSelectorWizardChangeDir
noHack:
endif

	;
	; Check if we are using a fake file system or are using the
	; real thing
	;
if HAVE_FAKE_FILE_SYSTEM
		call	OLFSDeref_SI_Gen_DI
		test	ds:[di].GFSI_fileCriteria, mask FSFC_USE_FAKE_FILE_SYSTEM
		jnz	continue
endif ;HAVE_FAKE_FILE_SYSTEM

		call	OLFileSelectorGetIDs
	;
	; If we're not visible, no need to rescan
	; 
continue::
		call	OLFSDeref_SI_Spec_DI
		test	ds:[di].VI_attrs, mask VA_REALIZED
		jz	done

		call	OLFSMarkDirtyAndRescanIfRealized
done:
		clc				; all we can do is report no error
		ret

OLFileSelectorSetPath	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFileSelectorWizardChangeDir
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update ATTR_GEN_PATH_DATA to be under
			SP_TOP:\Desktop\<Home directory>

CALLED BY:	OLFileSelectorSetPath
PASS:		*ds:si	- instance data
		cx:dx	- new path (null-terminated)
		bp	- disk handle
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	5/30/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef WIZARDBA	;--------------------------------------------------------------

OLFileSelectorWizardChangeDir	proc	near
tempPath	local	PathName
	uses	ax,bx,cx,dx,si,di,es
	.enter

	mov	ax, ATTR_GEN_PATH_DATA
	call	ObjVarFindData
	jnc	done			; Abort if no ATTR_GEN_PATH_DATA

	mov	cx, ss
	lea	dx, ss:[tempPath]
	call	ConvertStandardPathToWizardPath
	jc	updatePathData

	call	OLFSDeref_SI_Spec_DI
	test	ds:[di].OLFSI_state, mask OLFSS_USING_DESKTOP_HOME
	jz	updatePathData

	ORNF	ds:[di].OLFSI_state, mask OLFSS_SELECT_HOME

	push	cx
	movdw	esdi, cxdx
	mov	al, '\\'
	mov	cx, -1
	repne	scasb
	mov	{byte} es:[di-1], C_NULL
	pop	cx

updatePathData:
	mov	ax, ATTR_GEN_PATH_DATA
	mov	cx, size GenFilePath
	call	ObjVarAddData
	mov	ds:[bx].GFP_disk, SP_TOP

	push	ds
	segmov	es, ds
	lea	di, ds:[bx].GFP_path
	segmov	ds, ss
	lea	si, ss:[tempPath]
	LocalCopyString
	pop	ds
done:
	.leave
	ret
OLFileSelectorWizardChangeDir	endp

endif	;----------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFileSelectorNotifyDriveChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take note of the addition or deletion of a drive

CALLED BY:	MSG_NOTIFY_DRIVE_CHANGE
PASS:		*ds:si	= file selector
		cx	= GCNDriveChangeNotificationType
		dx	= number of affected drive
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 8/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if not SINGLE_DRIVE_DOCUMENT_DIR and FSEL_HAS_CHANGE_DRIVE_POPUP

OLFileSelectorNotifyDriveChange method dynamic OLFileSelectorClass, MSG_NOTIFY_DRIVE_CHANGE
		.enter
	;
	; Give superclass its crack at it.
	; 
		mov	di, offset OLFileSelectorClass
		call	ObjCallSuperNoLock
	;
	; Now rebuild the change-drive popup list to add or remove drives, as
	; appropriate.
	; 
		call	OLFSBuildChangeDrivePopup
		.leave
		ret
OLFileSelectorNotifyDriveChange		endm

endif

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFileSelectorRemovingDisk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take note of the deletion of a drive

CALLED BY:	MSG_META_REMOVING_DISK
PASS:		*ds:si	= file selector
		cx	= disk handle
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	6/10/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLFileSelectorRemovingDisk method dynamic OLFileSelectorClass, MSG_META_REMOVING_DISK
	;
	; Locate the array of IDs in our vardata.
	; 
		mov	ax, TEMP_GEN_FILE_SELECTOR_DIR_IDS
		call	ObjVarFindData
		jnc	done		; ya never know, ya know?
	;
	; Figure the offset past the last entry.
	; 
   		VarDataSizePtr	ds, bx, ax
		add	ax, bx		; ds:ax <- end
compareLoop:
	;
	; See if this entry matches the removing disk
	; 
		cmp	cx, ds:[bx].FPID_disk
		je	goToDocumentDir
next:
	;
	; Nope -- advance to next, please.
	; 
		add	bx, size FilePathID
		cmp	bx, ax
		jb	compareLoop
done:
		ret

goToDocumentDir:
;shouldn't need this, though the intent is that it'll prevent trying to switch
;to the removing disk before setting the document dir
;		mov	ax, ATTR_GEN_PATH_DATA
;		call	ObjVarDeleteData
;		mov	ax, TEMP_GEN_PATH_SAVED_DISK_HANDLE
;		call	ObjVarDeleteData
		mov	ax, MSG_OL_FILE_SELECTOR_DOCUMENT_BUTTON
		call	ObjCallInstanceNoLock
		jmp	short done

OLFileSelectorRemovingDisk		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFileSelectorNotifyFileChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take note of a change in the filesystem

CALLED BY:	MSG_NOTIFY_FILE_CHANGE
PASS:		*ds:si	= GenFileSelector
		dx	= FileChangeNotificationType
		^hbp	= FileChangeNotificationData
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	selector may rescan

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/11/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLFileSelectorNotifyFileChange method dynamic OLFileSelectorClass, 
					MSG_NOTIFY_FILE_CHANGE
		mov	bx, bp
		call	MemLock
		push	es, dx, bp
		mov	es, ax
		clr	di
		call	OLFileSelectorNotifyFileChangeLow
		pop	es, dx, bp
		call	MemUnlock
		mov	ax, MSG_NOTIFY_FILE_CHANGE
		mov	di, offset OLFileSelectorClass
		GOTO	ObjCallSuperNoLock
OLFileSelectorNotifyFileChange endm

OLFileSelectorNotifyFileChangeLow proc near
		class	GenFileSelectorClass
		uses	bx
		.enter
		mov	bx, dx
		shl	bx
		call	cs:[notificationTable][bx]
		.leave
		ret

notificationTable	nptr.near	\
	notifyCreate,			; FCNT_CREATE
	notifyRename,			; FCNT_RENAME
	notifyOpen,			; FCNT_OPEN
	notifyDelete,			; FCNT_DELETE
	notifyContents,			; FCNT_CONTENTS
	notifyAttributes,		; FCNT_ATTRIBUTES
	notifyFormat,			; FCNT_DISK_FORMAT
	notifyClose,			; FCNT_CLOSE
	notifyBatch,			; FCNT_BATCH
	notifySPAdd,			; FCNT_ADD_SP_DIRECTORY
	notifySPDelete,			; FCNT_DELETE_SP_DIRECTORY
	notifyUnread,			; FCNT_FILE_UNREAD
	notifyRead			; FCNT_FILE_READ	
.assert ($-notificationTable)/2 eq FileChangeNotificationType

notifyCreate:
		call	OLFileSelectorCheckIDIsOurs
if HANDLE_CREATE_GEOS_FILE_NOTIFICATION
		jc	rescanForCreate
else
		jc	rescan
endif
		retn

notifyDelete:
	; *ds:si = OLFileSelector
	; dx = FileChangeNotificationType
	; es:di = FileChangeNotificationData

notifyRename:
if _JEDIMOTIF
;
; since JEDI file selector shows file size, we need to update here
;
notifyContents:
endif
		call	OLFileSelectorCloseIfIDIsOurs
		jc	renameDone
		call	OLFileSelectorCheckIDIsKids
if _RUDY
	;
	; In Rudy, preserve selection on delete and rename.
	;
		jnc	dontPerserve
		mov	ax, TEMP_GEN_FILE_SELECTOR_PRESERVE_SELECTION
		clr	cx			;no extra data
		call	ObjVarAddData
		stc
dontPerserve:
endif				
		jc	rescanKid
renameDone:
		retn

notifyOpen:
notifyClose:
if (not _JEDIMOTIF)
notifyContents:
endif
		retn

notifyAttributes:
if HANDLE_CREATE_GEOS_FILE_NOTIFICATION
		push	di			; save data offset
		call	OLFileSelectorCheckIDIsKids
		pop	ax
		jc	rescanKid
		mov	di, ax			; es:di = data
		call	CheckGEOSFileIDList
else
		call	OLFileSelectorCheckIDIsKids
endif
if _RUDY
	;
	; In Rudy, preserve selection on attribute changes
	;
		jnc	dontPerserveAttr
		mov	ax, TEMP_GEN_FILE_SELECTOR_PRESERVE_SELECTION
		clr	cx			;no extra data
		call	ObjVarAddData
		stc
dontPerserveAttr:
endif				
		jc	rescanKid
		retn
		
rescanKid:
rescan:
		push	dx, bp
		call	OLFSMarkDirtyAndRescanIfRealized
		pop	dx, bp
		retn

if HANDLE_CREATE_GEOS_FILE_NOTIFICATION
rescanForCreate:
		push	dx, bp
		call	OLFSMarkDirtyAndRescanIfRealized
		jnc	noScan			; not scanned, just
						;	hope that when we do
						;	we'll be okay
		call	BuildGEOSFileIDList
noScan:
		pop	dx, bp
		retn
endif

	;--------------------
notifyFormat:
	; go back to virtual root if disk is ours?
		mov	cx, es:[di].FCND_disk

		mov	ax, TEMP_GEN_FILE_SELECTOR_DIR_IDS
		call	ObjVarFindData
		jnc	notifyFormatDone
	;
	; Figure the offset past the last entry.
	; 
   		VarDataSizePtr	ds, bx, ax
		add	ax, bx		; ds:ax <- end
formatCompareLoop:
	;
	; See if this entry matches the stuff in the notification block
	; 
		cmp	cx, ds:[bx].FPID_disk
		je	diskFormatted
	;
	; Nope -- advance to next, please.
	; 
		add	bx, size FilePathID
		cmp	bx, ax
		jb	formatCompareLoop
notifyFormatDone:
		retn

diskFormatted:
		GOTO	OLFileSelectorCloseForNotify
	;--------------------

	;
	; A directory has been added or delete as a StandardPath.  If our
	; folder is a descendant of that StandardPath, then force a rescan.
	;
notifySPAdd:
notifySPDelete:
		call	OLFileSelectorCheckIDIsAncestor
		jc	rescan
		retn

	;--------------------
notifyBatch:
	;
	; Process the batch o' notifications one at a time after suspending
	; the selector.
	; 
		push	bp
		mov	ax, MSG_GEN_FILE_SELECTOR_SUSPEND
		call	ObjCallInstanceNoLock
		pop	bp
		pushf

		mov	bx, es:[FCBND_end]
		mov	di, offset FCBND_items
batchLoop:
		cmp	di, bx		; done with all entries?
		jae	batchLoopDone
	;
	; Perform another notification. Fetch the type out
	; 
		mov	dx, es:[di].FCBNI_type
		push	di, dx
	;
	; Point to the start of the stuff that resembles a
	; FileChangeNotificationData structure and recurse
	; 
		add	di, offset FCBNI_disk
		call	OLFileSelectorNotifyFileChangeLow
		pop	di, dx
	;
	; Advance pointer, accounting to variable-sized nature of the thing.
	; 
		add	di, size FileChangeBatchNotificationItem
	CheckHack <FCNT_CREATE eq 0 and FCNT_RENAME eq 1>
		cmp	dx, FCNT_RENAME
		ja	batchLoop		; => no name
		add	di, size FileLongName
		jmp	batchLoop
batchLoopDone:
		popf
		jc	unsuspended		; => was already suspended,
						;  so don't unsuspend
		push	bp
		mov	ax, MSG_GEN_FILE_SELECTOR_END_SUSPEND
		call	ObjCallInstanceNoLock
		pop	bp
unsuspended:
		retn

notifyUnread:
if _RUDY
	;	
	; If we get the FCNT_FILE_UNREAD notification we clear the set
	; bit in the file selector and redraw the items.
	;	
		mov	ax, -1			; set the unread bit
		call	OLFileSelectorUpdateUnreadIfIDIsKids
endif
		retn
notifyRead:
if _RUDY
	;	
	; If we get the FCNT_FILE_READ notification we clear the unread
	; bit in the file selector and redraw the items.
	;	
		mov	ax, 0			; clear the unread bit
		call	OLFileSelectorUpdateUnreadIfIDIsKids
endif
		retn
	
OLFileSelectorNotifyFileChangeLow endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFileSelectorFetchIDFromNotificationBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the three words of ID from the notification block

CALLED BY:	(INTERNAL) OLFileSelectorCheckIDIsKids, 
			   OLFileSelectorCheckIDIsOurs
PASS:		es:di	= FileChangeNotificationData
RETURN:		cxdx	= FileID
		bp	= disk handle
DESTROYED:	bx, ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/11/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLFileSelectorFetchIDFromNotificationBlock proc near
		movdw	cxdx, es:[di].FCND_id
		mov	bp, es:[di].FCND_disk
		ret
OLFileSelectorFetchIDFromNotificationBlock endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFileSelectorCheckIDIsOurs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the FCND_disk:FCND_id is one of those for our folder

CALLED BY:	(INTERNAL) OLFileSelectorNotifyFileChange
PASS:		*ds:si	= OLFileSelector object
		es:di	= FileChangeNotificationData
RETURN:		carry set if the ID is one of ours
DESTROYED:	bx, ax, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/11/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLFileSelectorCheckIDIsOurs proc	near
		class	OLFileSelectorClass
		uses	cx, dx, bp
		.enter
	;
	; Extract the three pertinent words from the block
	;
		call	OLFileSelectorFetchIDFromNotificationBlock
	;
	; Locate the array of IDs in our vardata.
	; 
		mov	ax, TEMP_GEN_FILE_SELECTOR_DIR_IDS
		call	ObjVarFindData
		jnc	done		; ya never know, ya know?
	;
	; Figure the offset past the last entry.
	; 
   		VarDataSizePtr	ds, bx, ax
		add	ax, bx		; ds:ax <- end
compareLoop:
	;
	; See if this entry matches the stuff in the notification block
	; 
		cmp	bp, ds:[bx].FPID_disk
		jne	next
		cmp	cx, ds:[bx].FPID_id.high
		jne	next
		cmp	dx, ds:[bx].FPID_id.low
		je	done
next:
	;
	; Nope -- advance to next, please.
	; 
		add	bx, size FilePathID
		cmp	bx, ax
		jb	compareLoop
		stc
done:
		cmc		; return carry *set* if found
		.leave
		ret
OLFileSelectorCheckIDIsOurs		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFileSelectorCheckIDIsAncestor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the FCND_disk as a StandardPath is the ancestor of
		one of those for our folder.

CALLED BY:	(INTERNAL) OLFileSelectorNotifyFileChange
PASS:		*ds:si	= OLFileSelector object
		es:di	= FileChangeNotificationData
RETURN:		carry set if the ID is one of ours
DESTROYED:	bx, ax, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	 4/19/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLFileSelectorCheckIDIsAncestor proc	near
		class	OLFileSelectorClass
		uses	cx, dx, bp
		.enter
	;
	; Extract the pertinent word from the block
	; 
		call	OLFileSelectorFetchIDFromNotificationBlock
	;
	; Get our current path
	;
		mov	ax, ATTR_GEN_PATH_DATA
		mov	dx, TEMP_GEN_PATH_SAVED_DISK_HANDLE
		call	GenPathFetchDiskHandleAndDerefPath
		test	ax, DISK_IS_STD_PATH_MASK
		jz	done			;branch (carry clear)
	;
	; Are we below the StandardPath or at it?
	;
		cmp	ax, bp			;at path?
		je	isOurs			;branch if at path
		mov	bx, ax			;bx <- our StandardPath
		call	FileStdPathCheckIfSubDir
		tst	ax			;subdirectory?
		jnz	done			;branch (carry clear)
isOurs:
		stc				;carry <- is changed
done:

		.leave
		ret
OLFileSelectorCheckIDIsAncestor		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFileSelectorCloseIfIDIsOurs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close this folder, if the ID in the notification is for this
		folder.

CALLED BY:	(INTERNAL) OLFileSelectorNotifyFileChange
PASS:		*ds:si	= OLFileSelector object
		dx	= FileChangeNotificationType
		es:di	= FileChangeNotificationData
RETURN:		carry set if close under way
		carry clear if ID wasn't for us
DESTROYED:	ax, bx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/11/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLFileSelectorCloseIfIDIsOurs proc	near
		class	OLFileSelectorClass
		uses	dx, bp
		.enter
		call	OLFileSelectorCheckIDIsOurs
		jnc	done

		call	OLFileSelectorCloseForNotify
done:
		.leave
		ret
OLFileSelectorCloseIfIDIsOurs		endp

		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFileSelectorCloseForNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Retreat to the virtual root, if possible, or SP_DOCUMENT,
		if not, in response to having our current directory
		or disk nuked from under us.

CALLED BY:	(INTERNAL) OLFileSelectorCloseIfIDIsOurs,
			   OLFileSelectorNotifyFileChange
PASS:		*ds:si	= GenFileSelector object
RETURN:		nothing
DESTROYED:	ax, bp, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/17/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLFileSelectorCloseForNotify proc	near
		class	OLFileSelectorClass
		uses	bp, dx
		.enter
	;
	; We can't go up a directory if the directory we were in no longer
	; exists, so retreat to the virtual root, if we have one, or to
	; the document directory, if not.
	; 
		push	si
		call	OLFSGetVirtualRoot
		jnc	popGotoDocument
		
	;
	; Copy virtual root onto the stack (it's in our vardata, currently),
	; so we can actually set it.
	; 
		mov	bp, cx		; bp <- disk handle
		pop	bx		; *ds:bx <- object
		sub	sp, size PathName
		mov	di, sp
		segmov	es, ss, cx	; es, cx <- path segment
copyTailLoop:
		LocalGetChar ax, dssi
		LocalPutChar esdi, ax
		LocalIsNull ax
		jnz	copyTailLoop

		mov	dx, sp		; cx:dx <- path
		mov	si, bx		; *ds:si <- object
		
		mov	ax, MSG_GEN_PATH_SET
		call	ObjCallInstanceNoLock
		mov	bx, sp		; clear the stack
		lea	sp, [bx+size PathName]

		jc	gotoDocument		; failed
done:
		.leave
		ret

popGotoDocument:
		pop	si
gotoDocument:
	;
	; Either no virtual root, or virtual root doesn't exist anymore.
	; Get back to document, if possible.
	; 
		mov	ax, MSG_OL_FILE_SELECTOR_DOCUMENT_BUTTON
		call	ObjCallInstanceNoLock
		jmp	done
OLFileSelectorCloseForNotify		endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFileSelectorCheckIDIsKids
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the affected file is one of our kiddies.

CALLED BY:	(INTERNAL) OLFileSelectorNotifyFileChange
PASS:		*ds:si	= OLFileSelector object
		dx	= FileChangeNotificationType
		es:di	= FileChangeNotificationData
RETURN:		carry set if it belongs to a kiddie:
			di	= offset of OLFileSelectorRecord
		carry clear if it's none of ours:
			di	= destroyed
DESTROYED:	ax, bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/11/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLFileSelectorCheckIDIsKids proc	near
		class	OLFileSelectorClass
		uses	cx, dx, bp, es
		.enter
		call	OLFileSelectorFetchIDFromNotificationBlock

		call	OLFSDeref_SI_Spec_DI
		mov	bx, ds:[di].OLFSI_fileBuffer
		tst	bx
		jz	done		; (carry clear)
		call	MemLock
		mov	es, ax
		mov	ax, ds:[di].OLFSI_numFiles
		mov	di, -size OLFileSelectorEntry
searchLoop:
		add	di, size OLFileSelectorEntry
		dec	ax
		js	notFound
		cmp	es:[di].OLFSE_disk, bp
		jne	searchLoop
		cmp	es:[di].OLFSE_id.low, dx
		jne	searchLoop
		cmp	es:[di].OLFSE_id.high, cx
		je	found
		jmp	searchLoop
notFound:
		stc
found:
		cmc
		call	MemUnlock
done:
		.leave
		ret
OLFileSelectorCheckIDIsKids endp

if _RUDY

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFileSelectorUpdateUnreadIfIDIsKids
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the affected file is one of our kiddies, set/clear the
		GFHF_UNREAD bit.  This will save us a rescan of the file
		selector which can take a long time on a flash device.

CALLED BY:	(INTERNAL) OLFileSelectorNotifyFileChange
PASS:		*ds:si	= OLFileSelector object
		ax	= 0 to clear the GFHF_UNREAD bit.
		dx	= FileChangeNotificationType
		es:di	= FileChangeNotificationData
RETURN:		carry set if it belongs to a kiddie:
			di	= offset of OLFileSelectorRecord
		carry clear if it's none of ours:
			di	= destroyed
DESTROYED:	ax, bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	05/31/96	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLFileSelectorUpdateUnreadIfIDIsKids	proc	near
		class	OLFileSelectorClass
clearFlag	local	word	push ax
memHandle	local	hptr
diskHandle	local	word		
		uses	cx, dx, si, bp, es
		.enter
	;
	; For Rudy the only attribute change we are worried about is
	; GFHF_UNREAD of the GeosFileHeaderFlags.  So in order to remove the
	; FileEnum which is associated with the file selector rescan we are
	; going to set/clear the GFHF_UNREAD bit of the OLFileSelectorEntry. 
	;
		push	bp
		call	OLFileSelectorFetchIDFromNotificationBlock
		mov	ax, bp			; ax <- disk handle
		pop	bp
		mov	ss:[diskHandle], ax
		call	OLFSDeref_SI_Spec_DI
		mov	bx, ds:[di].OLFSI_fileBuffer
		tst	bx
		jz	done		; (carry clear)
		mov	ss:[memHandle], bx
		call	MemLock
		mov	es, ax
		mov	ax, ds:[di].OLFSI_numFiles
		mov	di, -size OLFileSelectorEntry
		mov	bx, ss:[diskHandle]
searchLoop:
		add	di, size OLFileSelectorEntry
		dec	ax
		js	notFound
		cmp	es:[di].OLFSE_disk, bx
		jne	searchLoop
		cmp	es:[di].OLFSE_id.low, dx
		jne	searchLoop
		cmp	es:[di].OLFSE_id.high, cx
		je	found
		jmp	searchLoop
found:
	;
	; Clear or set the unread bit.
	;
		push	di
		tst	ss:[clearFlag]
		jnz	setUnread
		BitClr	es:[di].OLFSE_fileFlags, GFHF_UNREAD
		jmp	redrawList
setUnread:
		BitSet	es:[di].OLFSE_fileFlags, GFHF_UNREAD
redrawList:		
	;
	; Redraw the list of files, retaining the selection.
	;
		call	OLFSDeref_SI_Spec_DI		
		mov	cx, ds:[di].OLFSI_uiBlock
		tst	cx
		pop	di
		jz	unlock
		push	bp, di
		mov	bx, cx				; bx <- block handle
		mov	si, offset OLFileSelectorFileList
NRUDY <		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION		>
RUDY  <		mov	ax, MSG_FILTER_LIST_GET_SELECTION		>
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage			; ax <- current sel
		push	ax		
		mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
		mov	cx, GDLI_NO_CHANGE		; same number of items
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
		pop	cx				; cx <- selection
		cmp	cx, GIGS_NONE
		je	noneSelected
		clr	dx				; determinate
NRUDY <		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION	>
RUDY  <		mov	ax, MSG_FILTER_LIST_SET_SINGLE_SELECTION	>
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
noneSelected:				
		pop	bp, di
		clc
unlock:
		mov	bx, ss:[memHandle]
		call	MemUnlock		
done:
		.leave
		ret
notFound:
		stc
		jmp	unlock

OLFileSelectorUpdateUnreadIfIDIsKids	endp
endif	; _RUDY


if HANDLE_CREATE_GEOS_FILE_NOTIFICATION

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BuildGEOSFileIDList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	build list of all GEOS file FileIDs

CALLED BY:	OLFileSelectorNotifyFileChangeLow
PASS:		*ds:si = file selector
RETURN:		nothing
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		The problem we are fixing is that when we get CREATE
		notification of a new GEOS file, it's extended attributes
		are not set yet, so the file selector may not accept it
		when rescanning for the CREATE notification.  So,
		additionally, we create a list of all GEOS files in the
		directory.  When we get ATTR notification, we check if the
		affected file is in our list.  If so, we do a complete
		rescan, as by this time, the extended attributes are there
		and we should be able to use them to correctly accept or
		reject the file.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	4/27/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GEOSFileIDListHeader	struct
	GFIDLH_numFiles		word
GEOSFileIDListHeader	ends

GEOSFileIDListItem	struct
	GFIDLI_id	FileID
	GFIDLI_disk	hptr
GEOSFileIDListItem	ends

BuildGEOSFileIDList	proc	near
	class	OLFileSelectorClass

	call	FilePushDir
	mov	ax, ATTR_GEN_PATH_DATA
	mov	dx, TEMP_GEN_PATH_SAVED_DISK_HANDLE
	call	GenPathSetCurrentPathFromObjectPath

	sub	sp, size FileEnumParams + (size FileExtAttrDesc)*3
	mov	bp, sp
	add	bp, size FileEnumParams
	mov	ax, bp				; ax = offset of ext attrs
	mov	ss:[bp].FEAD_attr, FEA_FILE_ID
	mov	ss:[bp].FEAD_value.segment, 0
	mov	ss:[bp].FEAD_value.offset, offset GFIDLI_id
	mov	ss:[bp].FEAD_size, size GFIDLI_id
	add	bp, size FileExtAttrDesc
	mov	ss:[bp].FEAD_attr, FEA_DISK
	mov	ss:[bp].FEAD_value.segment, 0
	mov	ss:[bp].FEAD_value.offset, offset GFIDLI_disk
	mov	ss:[bp].FEAD_size, size GFIDLI_disk
	add	bp, size FileExtAttrDesc
	mov	ss:[bp].FEAD_attr, FEA_END_OF_LIST
	sub	bp, (size FileEnumParams)+((size FileExtAttrDesc)*2)
	mov	ss:[bp].FEP_searchFlags, mask FESF_GEOS_EXECS or \
				mask FESF_GEOS_NON_EXECS or \
				mask FESF_LEAVE_HEADER
	mov	ss:[bp].FEP_returnAttrs.segment, ss
	mov	ss:[bp].FEP_returnAttrs.offset, ax
	mov	ss:[bp].FEP_returnSize, size GEOSFileIDListItem
	mov	ss:[bp].FEP_matchAttrs.segment, 0
	mov	ss:[bp].FEP_bufSize, FE_BUFSIZE_UNLIMITED
	mov	ss:[bp].FEP_skipCount, 0
	mov	ss:[bp].FEP_headerSize, (size GEOSFileIDListHeader)
	call	FileEnum		; removes (size FileEnumParms)
	mov	bp, sp			; remove the rest
	lea	sp, ss:[bp][(size FileExtAttrDesc)*3]
	jc	done			; error, just forget it
	tst	bx
	jz	done			; nothing found
	call	MemLock
	mov	es, ax
	mov	es:[GFIDLH_numFiles], cx	; store count
	call	MemUnlock
	call	OLFSDeref_SI_Spec_DI
	xchg	ds:[di].OLFSI_geosFileIDList, bx
	tst	bx
	jz	done
	call	MemFree			; free previous one
done:

	call	FilePopDir
	ret
BuildGEOSFileIDList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckGEOSFileIDList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	check if changed file is in list

CALLED BY:	OLFileSelectorNotifyFileChangeLow
PASS:		*ds:si	= file selector
		dx	= FileChangeNotificationType
		es:di	= FileChangeNotificationData
RETURN:		carry set if file found in list
DESTROYED:	ax, bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	4/27/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckGEOSFileIDList	proc	near
	class	OLFileSelectorClass
	uses	cx, dx, bp, es
	.enter
	call	OLFileSelectorFetchIDFromNotificationBlock	; cx, dx, bp

	call	OLFSDeref_SI_Spec_DI
	mov	bx, ds:[di].OLFSI_geosFileIDList
	tst	bx
	jz	done		; (carry clear)
	call	MemLock
	mov	es, ax
	mov	ax, es:[GFIDLH_numFiles]
	mov	di, (size GEOSFileIDListHeader) - (size GEOSFileIDListItem)
searchLoop:
	add	di, size GEOSFileIDListItem
	dec	ax
	js	notFound
	cmp	es:[di].GFIDLI_disk, bp
	jne	searchLoop
	cmp	es:[di].GFIDLI_id.low, dx
	jne	searchLoop
	cmp	es:[di].GFIDLI_id.high, cx
	je	found
	jmp	searchLoop
notFound:
	stc
found:
	cmc
	call	MemUnlock
done:
	.leave
	ret
CheckGEOSFileIDList	endp

endif

FileSelector	ends
