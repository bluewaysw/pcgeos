COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		FSelSamp (File Selector Sample application)
FILE:		fselsamp.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/91		Initial version

DESCRIPTION:
	This file source code for the FSelSamp application. This code will
	be assembled by ESP, and then linked by the GLUE linker to produce
	a runnable .geo application file.

	File Browser demonstrates File Selector usage.

RCS STAMP:
	$Id: fselsamp.asm,v 1.1 97/04/04 16:32:39 newdeal Exp $

------------------------------------------------------------------------------@

;------------------------------------------------------------------------------
;			Include files
;------------------------------------------------------------------------------

include	geos.def
include	heap.def
include geode.def
include	resource.def
include	ec.def

include object.def
include	graphics.def
include lmem.def
include	file.def
include char.def
include localize.def


;------------------------------------------------------------------------------
;			Libraries used
;------------------------------------------------------------------------------

UseLib	ui.def
UseLib Objects/vTextC.def

;------------------------------------------------------------------------------
;			Macros
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;			Constants
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;			Definitions
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;			Object Class include files
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;			Class & Method Definitions
;------------------------------------------------------------------------------

;Here we define "FSelSampProcessClass" as a subclass of the system provided
;"GenProcessClass". As this application is launched, an instance of
;will be created, and will handle all application-related events (methods).
;The application thread will be responsible for running this object,
;meaning that whenever this object handles a method, we will be executing
;in the application thread.

FSelSampProcessClass	class	GenProcessClass

;METHOD DEFINITIONS: these methods are defined for FSelSampProcessClass.

;Note: instances of FSelSampProcessClass are actually hybrid objects.
;Instead of allocating a chunk in an Object Block to contain the instance data
;for this object, we use the application's DGROUP resource. This resource
;contains both idata and udata sections. Therefore, to create instance data
;for this object (such as textColor), we define a variable in idata,
;instead of defining an instance data field here.

MSG_FILEBROW_SELECTOR_ACTION	message
MSG_FILEBROW_FILENAME_ACTION	message
MSG_FILEBROW_VIEW		message
MSG_FILEBROW_VIEW_TYPES	message
MSG_FILEBROW_APPLY		message
MSG_FILEBROW_OPEN		message

FSelSampProcessClass	endc	;end of class definition


;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------
;The "fselsamp.ui" file, which contains user-interface descriptions for this
;application, is written in a language called Espire. That file gets compiled
;by UIC, and the resulting assembly statements are written into the
;fselsamp.rdef file. We include that file here, so that these descriptions
;can be assembled into our application.
;
;Precisely, we are assembling .byte and .word statements which comprise the
;exact instance data for each generic object in the .ui file. When this
;application is launched, these resources (such as MenuResource) will be loaded
;into the Global Heap. The objects in the resource can very quickly become
;usable, as they are pre-instantiated.

include		fselsamp.rdef		;include compiled UI definitions


;------------------------------------------------------------------------------
;		Initialized variables and class structures
;------------------------------------------------------------------------------

idata	segment

;Class definition is stored in the application's idata resource here.

	FSelSampProcessClass	mask CLASSF_NEVER_SAVED

;initialized variables (In a sense, these variables can be considered
;instance data for the FSelSampProcessClass object. See above.)

idata	ends

;------------------------------------------------------------------------------
;		Uninitialized variables
;------------------------------------------------------------------------------

udata	segment

udata	ends

;------------------------------------------------------------------------------
;		Code for FSelSampProcessClass
;------------------------------------------------------------------------------

CommonCode	segment	resource	;start of code resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSelSampSelectorAction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle notification from File Selector that user has selected
		an entry in the file list - display complete pathname of
		current selection

CALLED BY:	MSG_FILEBROW_SELECTOR_ACTION (notification method from
		File Selector)

PASS:		cx:dx - OD of file selector
		bp - GenFileSelectorEntryFlags

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	04/08/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSelSampSelectorAction	method	FSelSampProcessClass, \
					MSG_FILEBROW_SELECTOR_ACTION
						; allocate room for path and
						;	selection
	sub	sp, PATH_BUFFER_SIZE+FILE_LONGNAME_BUFFER_SIZE
	GetResourceHandleNS	FSelSampFileSelector, bx
	mov	si, offset FSelSampFileSelector
	mov	cx, ss				; cx:dx = buffer for path
	mov	dx, sp
	mov	ax, MSG_GEN_FILE_SELECTOR_GET_FULL_SELECTION_PATH
	mov	di, mask MF_CALL
	call	ObjMessage

	GetResourceHandleNS	FSelSampFileName, bx
	mov	si, offset FSelSampFileName
	mov	dx, cx
	mov	bp, sp
	clr	cx
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	di, mask MF_CALL
	call	ObjMessage
	add	sp, PATH_BUFFER_SIZE+FILE_LONGNAME_BUFFER_SIZE
	ret
FSelSampSelectorAction	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSelSampFileNameAction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle <CR> in filename entry field - switch to corresponding
		path and select corresponding item in file selector

CALLED BY:	MSG_FILEBROW_FILENAME_ACTION - notification from
		filename entry text object

PASS:		nothing

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	04/08/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSelSampFileNameAction	method	FSelSampProcessClass,
					MSG_FILEBROW_FILENAME_ACTION
	sub	sp, PATH_BUFFER_SIZE+FILE_LONGNAME_BUFFER_SIZE

	mov	dx, ss				; dx:bp = buffer for text
	mov	bp, sp
	GetResourceHandleNS	FSelSampFileName, bx
	mov	si, offset FSelSampFileName
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	mov	di, mask MF_CALL
	call	ObjMessage

	jcxz	done				; if no text, done
	mov	bp, sp
	cmp	{byte} ss:[bp][1], ':'		; drive letter colon?
	je	done				; yes, exit now as this is not
						;	supported by the below
						;	message 
	mov	cx, ss				; cx:dx = buffer for text
	mov	dx, sp
	clr	bp				; keep current disk handle
	GetResourceHandleNS	FSelSampFileSelector, bx
	mov	si, offset FSelSampFileSelector
	mov	ax, MSG_GEN_FILE_SELECTOR_SET_FULL_SELECTION_PATH
	mov	di, mask MF_CALL
	call	ObjMessage			; switch to desired path
done:
	add	sp, PATH_BUFFER_SIZE+FILE_LONGNAME_BUFFER_SIZE
	ret
FSelSampFileNameAction	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSelSampOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle "Open" trigger - if selection is volume or directory,
		tell FileSelector to open it, else, beep

CALLED BY:	MSG_FILEBROW_OPEN

PASS:		nothing

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	04/10/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSelSampOpen	method	FSelSampProcessClass, MSG_FILEBROW_OPEN
	GetResourceHandleNS	FSelSampFileSelector, bx
	mov	si, offset FSelSampFileSelector
	clr	cx				; return just flags & entry #
	mov	ax, MSG_GEN_FILE_SELECTOR_GET_SELECTION
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			; ax = entry #,
						; bp = GenFileSelectorEntryFlags
	test	bp, mask GFSEF_NO_ENTRIES
	jnz	error
	andnf	bp, mask GFSEF_TYPE
	cmp	bp, GFSET_FILE shl offset GFSEF_TYPE
	je	error
	;
	; volume or subdirectory, open it
	;	bx:si = file selector
	;	ax = entry #
	;
	mov	cx, ax				; cx = entry #
	mov	ax, MSG_GEN_FILE_SELECTOR_OPEN_ENTRY
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	jnc	done				; opened successfully
error:
	mov	ax, SST_ERROR
	call	UserStandardSound		; signal error
done:
	ret
FSelSampOpen	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSelSampView
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	bring up View options dialog box - set gadgets in dialog
		box to reflect current file selector settings

CALLED BY:	MSG_FILEBROW_VIEW - "View" menu item

PASS:		nothing

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	04/08/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSelSampView	method	FSelSampProcessClass, MSG_FILEBROW_VIEW
	;
	; get file classes from file selector
	;
	GetResourceHandleNS	FSelSampFileSelector, bx
	mov	si, offset FSelSampFileSelector
	mov	ax, MSG_GEN_FILE_SELECTOR_GET_FILE_CRITERIA
	mov	di, mask MF_CALL
	call	ObjMessage			; cx = FileSelectorCriteria
	clr	dx				; no indeterminate ones
	;
	; show file classes in View dialog box
	;
	GetResourceHandleNS	TypeList, bx
	mov	si, offset TypeList
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
	call	ObjMessage
	;
	; get DOS attributes from file selector
	;
	GetResourceHandleNS	FSelSampFileSelector, bx
	mov	si, offset FSelSampFileSelector
	mov	ax, MSG_GEN_FILE_SELECTOR_GET_FILE_ATTRS
	mov	di, mask MF_CALL
	call	ObjMessage			; cl = FileAttrs that must be
						;  set
						; ch = FileAttrs that must not
						;  be set
	push	cx
	clr	dx				; no indeterminate ones
	;
	; show set DOS attributes in View dialog box
	;
	GetResourceHandleNS	DosAttrSetList, bx
	mov	si, offset DosAttrSetList
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
	call	ObjMessage
	
	;
	; show unset DOS attributes in View dialog box.
	; 
	pop	cx
	mov	cl, ch
	clr	ch
	clr	dx
	GetResourceHandleNS	DosAttrUnsetList, bx
	mov	si, offset DosAttrUnsetList
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
	call	ObjMessage

	;
	; get DOS filemask from file selector
	;
	sub	sp, VOLUME_NAME_LENGTH+1
	GetResourceHandleNS	FSelSampFileSelector, bx
	mov	si, offset FSelSampFileSelector
	mov	ax, MSG_GEN_FILE_SELECTOR_GET_MASK
	mov	cx, ss				; cx:dx = buffer for mask
	mov	dx, sp
	mov	di, mask MF_CALL
	call	ObjMessage
	jc	haveMask
	; mask not defined, so make it empty.
	mov	di, dx
	mov	{char}ss:[di], 0
haveMask:
	;
	; show DOS filemask in View dialog box
	;
	mov	bp, dx
	mov	dx, cx
	clr	cx
	GetResourceHandleNS	MaskEntry, bx
	mov	si, offset MaskEntry
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	di, mask MF_CALL
	call	ObjMessage
	add	sp, VOLUME_NAME_LENGTH+1
	;
	; bring up dialog box
	;
	GetResourceHandleNS	OptionsBox, bx
	mov	si, offset OptionsBox
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	mov	di, mask MF_CALL
	call	ObjMessage
	ret
FSelSampView	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSelSampApply
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle "Apply" button in "View" dialog box - set selected
		attributes in File Selector

CALLED BY:	MSG_FILEBROW_APPLY - "Apply" button in "View" dialog box

PASS:		nothing

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	04/08/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSelSampApply	method	FSelSampProcessClass, MSG_FILEBROW_APPLY
	;
	; first, suspend rescanning so we can set multiple attributes
	; without seeing multiple rescans
	;
	GetResourceHandleNS	FSelSampFileSelector, bx
	mov	si, offset FSelSampFileSelector
	mov	ax, MSG_GEN_FILE_SELECTOR_SUSPEND
	mov	di, mask MF_CALL
	call	ObjMessage
	;
	; get selected file classes from View dialog box
	;
	GetResourceHandleNS	TypeList, bx
	mov	si, offset TypeList
	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
	mov	di, mask MF_CALL
	call	ObjMessage		; ax = file criteria
	mov	cx, ax

	;
	; set selected file classes in file selector
	;
	GetResourceHandleNS	FSelSampFileSelector, bx
	mov	si, offset FSelSampFileSelector
	mov	ax, MSG_GEN_FILE_SELECTOR_SET_FILE_CRITERIA
	mov	di, mask MF_CALL
	call	ObjMessage

	;
	; get selected set file attributes from View dialog box
	;
	GetResourceHandleNS	DosAttrSetList, bx
	mov	si, offset DosAttrSetList
	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
	mov	di, mask MF_CALL
	call	ObjMessage		; ax = set Dos Attrs
	push	ax

	;
	; get selected unset file attributes from View dialog box
	;
	GetResourceHandleNS	DosAttrUnsetList, bx
	mov	si, offset DosAttrUnsetList
	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
	mov	di, mask MF_CALL
	call	ObjMessage		; ax = unset Dos Attrs
	;
	; set selected DOS file attributes in file selector
	;
	pop	dx
	mov	ch, al		; ch <- attrs to not be set
	mov	cl, dl		; cl <- attrs to be set

	GetResourceHandleNS	FSelSampFileSelector, bx
	mov	si, offset FSelSampFileSelector
	mov	ax, MSG_GEN_FILE_SELECTOR_SET_FILE_ATTRS
	mov	di, mask MF_CALL
	call	ObjMessage

	;
	; get selected file mask from View dialog box
	;
	GetResourceHandleNS	MaskEntry, bx
	mov	si, offset MaskEntry
	mov	ax, MSG_VIS_TEXT_GET_ALL_BLOCK
	mov	di, mask MF_CALL
	clr	dx
	call	ObjMessage			;ax = size, cx = block
	mov	bx, cx
	tst	ax
	jz	deleteMask
	call	MemLock
	push	cx				; save text block handle

	mov_tr	cx, ax				; cx:dx = new filemask
	clr	dx
	GetResourceHandleNS	FSelSampFileSelector, bx
	mov	si, offset FSelSampFileSelector
	mov	ax, MSG_GEN_FILE_SELECTOR_SET_MASK
	mov	di, mask MF_CALL
	call	ObjMessage

	pop	cx			; recover text block
	xchg	bx, cx
	call	MemFree
	mov	bx, cx
done:
	;
	; finally, unsuspend rescanning so we can see our changes
	; (automatically rescans with new attributes)
	;
	GetResourceHandleNS	FSelSampFileSelector, bx
	mov	si, offset FSelSampFileSelector
	mov	ax, MSG_GEN_FILE_SELECTOR_END_SUSPEND
	mov	di, mask MF_CALL
	call	ObjMessage
	ret

deleteMask:
	GetResourceHandleNS	FSelSampFileSelector, bx
	mov	si, offset FSelSampFileSelector
	mov	cx, ATTR_GEN_FILE_SELECTOR_NAME_MASK
	mov	ax, MSG_META_DELETE_VAR_DATA
	mov	di, mask MF_CALL
	call	ObjMessage
	jmp	done
FSelSampApply	endm

CommonCode	ends		;end of CommonCode resource
