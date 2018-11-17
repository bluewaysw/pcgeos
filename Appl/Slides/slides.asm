COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		scrapbk
FILE:		scrapbk.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	2/90		Initial version

DESCRIPTION:
	This file contains the scrapbook application

	$Id: scrapbk.asm,v 1.1 97/04/04 16:49:45 newdeal Exp $

------------------------------------------------------------------------------@

;------------------------------------------------------------------------------
;		Conditional Assembly Flags
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;			Common GEODE stuff
;------------------------------------------------------------------------------

;
; Standard include files
;
include	geos.def
include	heap.def
include geode.def
include	resource.def
include	ec.def
include	vm.def

include object.def
include	graphics.def
include	win.def
include lmem.def
include timer.def
include file.def
include char.def

include localize.def	; for Resources file
include win.def

include gstring.def

include Objects/winC.def
include initfile.def	; for .ini file routines

include library.def
include Objects/inputC.def

;------------------------------------------------------------------------------
;			Libraries used
;------------------------------------------------------------------------------

UseLib	ui.def
UseLib	Objects/vTextC.def
UseLib	impex.def
UseLib	Internal/convert.def	; for conversion of 1.2 documents

UseLib  saver.def
UseLib	Objects/colorC.def

; Testing scan library

;------------------------------------------------------------------------------
;			Feature Flags
;------------------------------------------------------------------------------

; Options:
;
; HEADER_SIZE_CHECKING:
;	try to keep a lid on document's VM header size
;
; NO_BACKUP:
;	Turn off backup blocks in the Scrapbook data file. This helps
;	with header size, but you lose "revert-on-close" functionality
;	We save before closing to avoid the "revert-on-close" dialog, and
;	auto-save will also be doing a non-revertable save. (if set, make
;	sure .gp file exports ScrapDocumentClass and declares NoBackupUI)
;
; _SLIDE_SHOW:
;	Turn On/Off "Slide Show" feature
;

HEADER_SIZE_CHECKING	=       1
NO_BACKUP               =       0
_SLIDE_SHOW		=	1

include Internal/im.def

;------------------------------------------------------------------------------
;			Resource Definitions
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;			Macros
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;			Constants
;------------------------------------------------------------------------------

ScrapBookIndexHeader	struct
	SBIH_numScraps	word		; number of scraps in this scrapbook
ScrapBookIndexHeader	ends

ScrapBookIndexEntry	struct
	SBIE_vmBlock	word		; VM block handle of transfer item
					;	header of this scrap
	SBIE_extra1	word		; for future expansion
	SBIE_extra2	word		; for future expansion
ScrapBookIndexEntry	ends

ScrapBookExtraState	struct
	SBES_currentPage	word
ScrapBookExtraState	ends

;UI level stuff

ScrapbookFeatures	record
	SF_GOTO_PAGE_DIALOG:1
	SF_PASTE_AT_END:1
	SF_IMPORTING:1
	:13
ScrapbookFeatures	end

BEGINNING_FEATURES = mask SF_GOTO_PAGE_DIALOG or mask SF_IMPORTING or \
			mask SF_PASTE_AT_END

DEFAULT_FEATURES = BEGINNING_FEATURES


;
; Size of text scraps above which we just so a small portion of it
;
SBCS<SHOWABLE_TEXT_SIZE_THRESHOLD	=	8192	; 8K		>
DBCS<SHOWABLE_TEXT_SIZE_THRESHOLD	=	8192*(size wchar)	>

if HEADER_SIZE_CHECKING
;
; warning and error size thresholds for document's VM header
;
HEADER_WARNING_SIZE	=	16384
HEADER_ERROR_SIZE	=	50000
endif

;------------------------------------------------------------------------------
;			Definitions
;------------------------------------------------------------------------------

ScrapBookClass	class GenProcessClass

;
;  *** MUST BE FIRST MESSAGE ***
;
MSG_SCRAPBOOK_PASTE_APPEND_TO_FILE	message
;
; Pass: cx = handle of block with:
;		FileLongName
;		DiskHandle
;		PathName
;

MSG_SCRAPBOOK_PREVIOUS		message
MSG_SCRAPBOOK_NEXT		message

MSG_SCRAPBOOK_PASTE_AT_END	message

MSG_SCRAPBOOK_NAMEBOX		message
MSG_SCRAPBOOK_SHOW_SCRAP	message
MSG_SCRAPBOOK_SHOW_SCRAP_STATUS	message

MSG_SCRAPBOOK_SCRAPNAME_CR	message

MSG_SCRAPBOOK_SCRAP_LIST_REQUEST_ENTRY_MONIKER	message

MSG_SCRAPBOOK_IMPORT		message

MSG_SCRAPBOOK_TOGGLE_PAGE_LIST	message

MSG_SCRAPBOOK_SET_SELECTION	message

MSG_SCRAPBOOK_SEND_PASTE	message

if _SLIDE_SHOW

MSG_SCRAPBOOK_DRAW_SLIDE_WINDOW		message

endif

ScrapBookClass	endc

ScrapbookApplicationClass	class	GenApplicationClass

if NO_BACKUP
MSG_SCRAPBOOK_APPLICATION_CANCEL_COMPRESS	message
endif

ScrapbookApplicationClass	endc

ScrapBookListClass	class	GenDynamicListClass
ScrapBookListClass	endc

if NO_BACKUP
ScrapBookDocumentClass	class	GenDocumentClass

MSG_SCRAPBOOK_DOCUMENT_COMPRESS			message
MSG_SCRAPBOOK_DOCUMENT_COMPRESS_PART2		message

ScrapBookDocumentClass	endc
endif

if _SLIDE_SHOW

SlideShowTransitionType	etype word, 0, 2
SSTT_CLEAR		enum SlideShowTransitionType
SSTT_CORNER_WIPE	enum SlideShowTransitionType
SSTT_EDGE_WIPE		enum SlideShowTransitionType
SSTT_FADE		enum SlideShowTransitionType

SlideShowClass	class	VisClass

MSG_SLIDE_SHOW_START			message

MSG_SLIDE_SHOW_END			message

MSG_SLIDE_SHOW_SET_TRANSITION		message

MSG_SLIDE_SHOW_PREVIOUS			message

MSG_SLIDE_SHOW_NEXT			message


	SSI_window		hptr.Window
	SSI_trans		SlideShowTransitionType
	SSI_color		ColorQuad

SlideShowClass	endc

endif

;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------

include		slides.rdef

;------------------------------------------------------------------------------
;			Variables
;------------------------------------------------------------------------------

idata	segment

	ScrapBookClass	mask CLASSF_NEVER_SAVED

	ScrapbookApplicationClass

	ScrapBookListClass

if NO_BACKUP
	ScrapBookDocumentClass
endif

if _SLIDE_SHOW
	SlideShowClass
endif

if HEADER_SIZE_CHECKING
;shared
scrapMaxCat	char	"scrapbook",0
warningSizeKey	char	"warningSize",0
errorSizeKey	char	"errorSize",0
endif

if _SLIDE_SHOW
	ssKbdMon	Monitor <>
	ssUIHan		hptr
endif

idata	ends

;---------------------------------------------------

udata	segment

;
; VM file handle of current scrapbook
;
currentScrapFile	hptr.HandleFile
currentDoc		optr

;
; 0-based # of currently displayed scrap
;
currentScrap	word

;
; current format being displayed in scrapbook
;
currentFormat	ClipboardItemFormat

;
; window for GenView that displays GStrings
;
gStringWindow	hptr.Window

;
; buffer for "20000) scrap-name"
;
SBCS<scrapNameMonikerBuffer	char	7 + CLIPBOARD_ITEM_NAME_LENGTH+1 dup (?)	>
DBCS<scrapNameMonikerBuffer	wchar	7 + CLIPBOARD_ITEM_NAME_LENGTH+1 dup (?)	>

; SCRAP_NAME_MONIKER_BUFFER_SIZE equ ($-scrapNameMonikerBuffer)

;
; flag indicating whether paste is possible
;
canPaste	word

;
; last viewed page, used for saving page number across shutdown
;
; lastViewedPage's life story:
;	initialized to 0 in OPEN_APPLICATION
;	set to value in extra state block, if restoring from state
;	used for currentScrap value in DC_FILE_OPEN handler
;	set to currentScrap value in DC_FILE_DETACH handler
;	set to 0 in DC_FILE_CLOSE handler
;	store to extra state block in CLOSE_APPLICATION handler
;
lastViewedPage	word

callerAppName	char GEODE_NAME_SIZE + GEODE_NAME_EXT_SIZE + 1 dup (?)
callerAppToken	word

;
; most recently pasted in CIF_TEXT VMChain (for PASTE_APPEND_TO_FILE)
;
pastedTextFormat	dword

if HEADER_SIZE_CHECKING
warningSize	word
errorSize	word
endif

udata	ends

;------------------------------------------------------------------------------
;			Code
;------------------------------------------------------------------------------



AppInitExit segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScrapBookOpenApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	open application...

CALLED BY:	MSG_GEN_PROCESS_OPEN_APPLICATION

PASS:		cx - AppAttachFlags
		dx - AppLaunchBlock, if any
		bp - extra state block

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScrapBookOpenApplication	method	ScrapBookClass, \
					MSG_GEN_PROCESS_OPEN_APPLICATION
if HEADER_SIZE_CHECKING
	;
	; read limits
	;
	push	ax, cx, dx, si
	mov	cx, ds
	mov	si, offset scrapMaxCat
	mov	dx, offset warningSizeKey
	mov	ax, HEADER_WARNING_SIZE	; default warning level (16K)
	call	InitFileReadInteger
	mov	ss:[warningSize], ax
	mov	dx, offset errorSizeKey
	mov	ax, HEADER_ERROR_SIZE	; default error level (50K)
	call	InitFileReadInteger
	mov	ss:[errorSize], ax
	pop	ax, cx, dx, si
endif
	;
	; restore extra data from state file
	;
	push	ax, bx, cx, ds, es
	mov	ss:[lastViewedPage], 0		; default is first scrap
	tst	bp
	jz	noState
	mov	bx, bp
	call	MemLock				; ax - segment of extra data
	push	ds
	mov	ds, ax
	mov	ax, ds:[SBES_currentPage]	; restore last viewed page
	mov	ss:[lastViewedPage], ax
	pop	ds
	call	MemUnlock
noState:
	;
	;  Check for appLaunchBlock, since the original scrapbook app
	;  doesn't use ALB_dataFile.  Here I used it as a storage of
	;  the caller application's GeodeToken, if the scrapbook is called
	;  by any caller app.
	;
	tst	dx
	jz	noAppLaunchBlock
	mov	bx, dx
	call	MemLock			; ax - segment of launch block
	mov	ds, ax
	tst	ds:[ALB_dataFile]
	jnz	noCallerApp		;	
	lea	si, ds:[ALB_dataFile]
	inc	si
	tst	{byte}ds:[si]
	jz	noCallerApp
	call	ScrapbookCopyCallerApp
	call	ScrapbookChangeIcon	; change the icon moniker
	call	ScrapbookAddGCNList
noCallerApp:
	call	MemUnlock		; unlock the app launch block
noAppLaunchBlock:
	pop	ax, bx, cx, ds, es

	mov	ss:[currentScrapFile], 0
	mov	ss:[currentFormat], CIF_TEXT
	mov	ss:[gStringWindow], 0
	mov	ss:[canPaste], FALSE
	;
	; call superclass to start up
	;
	mov	di, offset ScrapBookClass
	call	ObjCallSuperNoLock
	;
	; set up text object
	;
	call	ClipboardGetClipboardFile
	mov	cx, bx
	GetResourceHandleNS	ScrapText, bx
	mov	si, offset ScrapText
	mov	ax, MSG_VIS_TEXT_SET_VM_FILE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	;
	; sync what we think the current view content is
	;
	mov	cx, MANUFACTURER_ID_GEOWORKS		; force change
	mov	dx, CIF_TEXT
	call	SetScrapViewContent
EC <	ERROR_C	0				; CIF_TEXT not known?!?	>
	;
	; we want to be notified about normal transfer item
	;
	call	GeodeGetProcessHandle
	mov	cx, bx				; cx:dx = our process
	clr	dx
	call	ClipboardAddToNotificationList
	;
	; disable stuff, opening a file will re-enable
	;
	call	DisableScrapBook
	ret
ScrapBookOpenApplication	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScrapBookCloseApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	close application...

CALLED BY:	MSG_GEN_PROCESS_CLOSE_APPLICATION

PASS:		

RETURN:		cx - handle of extra state block
			0 if none

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	05/02/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScrapBookCloseApplication	method	ScrapBookClass, \
					MSG_GEN_PROCESS_CLOSE_APPLICATION
if NO_BACKUP
	;
	; remove status dialog
	;
	push	ax, cx, dx, bp, si
	GetResourceHandleNS	CompressStatus, bx
	mov	si, offset CompressStatus
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_NOW
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	ax, cx, dx, bp, si
endif

	;
	; make sure the slide show window is closed
	;
	push	ax, cx, dx, bp, si
	GetResourceHandleNS SlideControl, bx
	mov	si, offset SlideControl
	mov	ax, MSG_SLIDE_SHOW_END
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	ax, cx, dx, bp, si
	;
	; remove from transfer notification
	;
	push	bx, cx, dx
	call	GeodeGetProcessHandle
	mov	cx, bx
	clr	dx
	call	ClipboardRemoveFromNotificationList
	pop	bx, cx, dx
	;
	; call superclass
	;
	mov	di, offset ScrapBookClass
	call	ObjCallSuperNoLock
	;
	; save extra data to state block
	;
	mov	ax, size ScrapBookExtraState
	mov	cx, ALLOC_DYNAMIC_LOCK or mask HF_SHARABLE
	call	MemAlloc
	mov	cx, 0				; assume error - no extra state
						; (preserve flags)
	jc	done				; error
	mov	cx, bx				; cx - handle of extra state
	mov	ds, ax				; ds - segment of extra state
	mov	ax, ss:[lastViewedPage]
	mov	ds:[SBES_currentPage], ax	; save current page
	call	MemUnlock			; unlock before returning it
done:
	tst	ss:[callerAppName]
	jz	noApp
	call	ScrapbookRemoveGCNList
noApp:
	ret
ScrapBookCloseApplication	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScrapBookInstallToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Install tokens
CALLED BY:	MSG_GEN_PROCESS_INSTALL_TOKEN

PASS:		none
RETURN:		none
DESTROYED:	ax, cx, dx, si, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	2/19/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScrapBookInstallToken	method ScrapBookClass, MSG_GEN_PROCESS_INSTALL_TOKEN
	;
	; Call our superclass to get the ball rolling...
	;
	mov	di, offset ScrapBookClass
	call	ObjCallSuperNoLock

	; install datafile token

	mov	ax, ('s') or ('l' shl 8)	; ax:bx:si = token used for
	mov	bx, ('i') or ('d' shl 8)	;	datafile
	mov	si, MANUFACTURER_ID_GEOWORKS
	call	TokenGetTokenInfo		; is it there yet?
	jnc	done				; yes, do nothing
						; cx:dx = OD of moniker list
	GetResourceHandleNS	DatafileMonikerList, cx
	mov	dx, offset DatafileMonikerList
	clr	bp				; in data resource, so no
						;  relocation
	call	TokenDefineToken		; add icon to token database
done:
	ret

ScrapBookInstallToken	endm

AppInitExit	ends


CommonCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScrapBookNotifyNormalTransferItemChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	enable Paste button if a transfer item exists

CALLED BY:	MSG_META_CLIPBOARD_NOTIFY_NORMAL_TRANSFER_ITEM_CHANGED

PASS:		

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	05/02/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScrapBookNotifyNormalTransferItemChanged	method	ScrapBookClass, \
			MSG_META_CLIPBOARD_NOTIFY_NORMAL_TRANSFER_ITEM_CHANGED
	cmp	ss:[canPaste], TRUE		; possible to paste?
	jne	done				; nope, don't even check
	clr	bp				; normal transfer
	call	ClipboardQueryItem
	tst	bp				; any transfer item?
	pushf					; save answer
	call	ClipboardDoneWithItem
	popf					; retrieve answer
	mov	ax, MSG_GEN_SET_NOT_ENABLED	; assume no paste
	jz	50$				; if no transfer item, no paste
	mov	ax, MSG_GEN_SET_ENABLED	; else, allow paste
50$:
	GetResourceHandleNS	PasteTrigger, bx
	mov	si, offset PasteTrigger
	push	ax				; save method
	call	SendAbleMessage
	pop	ax				; retrieve method
	GetResourceHandleNS	PasteAtEndTrigger, bx
	mov	si, offset PasteAtEndTrigger
	call	SendAbleMessage
done:
	ret
ScrapBookNotifyNormalTransferItemChanged	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScrapBookExposed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	draw gstring, if needed

CALLED BY:	MSG_META_EXPOSED

PASS:		cx  - window handle

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	01/02/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScrapBookDrawSlideShow	method ScrapBookClass, MSG_SCRAPBOOK_DRAW_SLIDE_WINDOW
	jcxz	done
	call	DrawScrap
done:
	ret
ScrapBookDrawSlideShow	endm

ScrapBookExposed	method	ScrapBookClass, MSG_META_EXPOSED
	mov	ss:[gStringWindow], cx
	FALL_THRU	DrawScrap
ScrapBookExposed	endm

DrawScrap	proc	far
	mov	di, cx
	call	GrCreateState
	call	GrBeginUpdate
	call	GetNumScraps			; cx = number of scraps
	cmp	cx, ss:[currentScrap]
	LONG jbe done				; bogus scrap, don't draw

	mov	bx, ss:[currentScrapFile]
	tst	bx				; no file (closed)
	LONG jz	done
	;
	;	bx = current scrap file
	;
	call	VMGetMapBlock			; get index block
	call	VMLock				; ax = segment; bp = handle
	mov	es, ax
	mov	ax, ds:[currentScrap]		; ax = current scrap index
	call	GetThisScrapIndexOffset		; si = offset in header
	mov	ax, es:[si].SBIE_vmBlock	; ax = transfer item VM block
	call	VMUnlock			; unlock map block
	call	VMLock				; lock transfer item
	mov	es, ax

	clr	si
	mov	cx, es:[CIH_formatCount]
startLoop:
	cmp	es:[CIH_formats][si].CIFI_format.CIFID_manufacturer,
					MANUFACTURER_ID_GEOWORKS
	jne	next
	cmp	es:[CIH_formats][si].CIFI_format.CIFID_type,
					CIF_GRAPHICS_STRING
	je	foundGString
	cmp	es:[CIH_formats][si].CIFI_format.CIFID_type,
					CIF_BITMAP
	je	foundBitmap
next:
	add	si, size ClipboardItemFormatInfo
	loop	startLoop
	call	VMUnlock		
	jmp	done

foundBitmap:
	mov	cx, es:[CIH_formats][si].CIFI_vmChain.high
	mov	dx, bx
	call	VMUnlock
	clr	ax, bx
	call	GrDrawHugeBitmap
	jmp	done
		
foundGString:
	mov	si, es:[CIH_formats][si].CIFI_vmChain.high
	call	VMUnlock			; unlock transfer item

	;
	;	bx - VM file
	; 	si - GString VM block
	;
	mov	cx, GST_VMEM			; gstring in VM format
	call	GrLoadGString			; si = handle of gstring
	;
	; deal with GeoDraw TIF_GSTRING scraps that are centered on 0,0
	;
	clr	dx
	call	GrGetGStringBounds		; ax, bx, cx, dx = bounds
	neg	ax				; convert to draw position
	neg	bx
	push	ax				; save X position
	mov	al, GSSPT_BEGINNING		; reposition to beginning
	call	GrSetGStringPos
	pop	ax				; restore X position
	clr	dx
	call	GrDrawGString			; draw gstring
	mov	dl, GSKT_LEAVE_DATA		; clobber only header,
						; 	LEAVE VM BLOCKS ALONE!
	call	GrDestroyGString		; destory gstring handle
done:
	call	GrEndUpdate
	call	GrDestroyState
	ret
DrawScrap	endp


ScrapBookViewWinClosed	method	ScrapBookClass,
				MSG_META_CONTENT_VIEW_WIN_CLOSED
	mov	ss:[gStringWindow], 0
	mov	di, offset ScrapBookClass
	call	ObjCallSuperNoLock
	ret
ScrapBookViewWinClosed	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScrapBookNameBox
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	bring up scrap name list dialog box

CALLED BY:	MSG_SCRAPBOOK_NAMEBOX

PASS:		

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	04/23/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScrapBookNameBox	method	ScrapBookClass, MSG_SCRAPBOOK_NAMEBOX
	call	SaveCurrentScrapName
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	GetResourceHandleNS	ScrapNameBox, bx
	mov	si, offset ScrapNameBox
	clr	di
	call	ObjMessage
	ret
ScrapBookNameBox	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScrapBookShowScrap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	show scrap selected from list

CALLED BY:	MSG_SCRAPBOOK_SHOW_SCRAP

PASS:		

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	03/13/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScrapBookShowScrapStatus	method	ScrapBookClass, MSG_SCRAPBOOK_SHOW_SCRAP_STATUS
	;
	; if list is in primary, show scrap
	;
	GetResourceHandleNS	ScrapBody, bx
	mov	si, offset ScrapBody
	GetResourceHandleNS	ScrapNameList, cx
	mov	dx, offset ScrapNameList
	mov	ax, MSG_GEN_FIND_CHILD
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			; C set if not found
	jc	done				; in dialog, ignore
	call	ScrapBookShowScrap
done:
	ret
ScrapBookShowScrapStatus	endm
		
ScrapBookShowScrap	method	ScrapBookClass, MSG_SCRAPBOOK_SHOW_SCRAP
	;
	; get selected scrap from list
	;
	GetResourceHandleNS	ScrapNameList, bx
	mov	si, offset ScrapNameList
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			; ax = entry selected
	cmp	ax, GIGS_NONE
	je	done				; no selection
	;
	; show specified scrap
	;
	mov	cx, ax				; cx = entry selected
	call	SaveCurrentScrapName		; save name of current scrap
						;	before changing to
						;	new scrap
						; (returns flag in ax)
	mov	ss:[currentScrap], cx		; assume in-bounds
	call	ShowCurrentScrap
done:
	ret
ScrapBookShowScrap	endm

GetNumScraps	proc	near
	uses	bx, ax, es, bp
	.enter
	GetResourceSegmentNS	dgroup, es
	mov	bx, es:[currentScrapFile]
	mov	cx, bx				; in case no scrap file
	jcxz	done
	call	VMGetMapBlock
	call	VMLock
	mov	es, ax
	mov	cx, es:[SBIH_numScraps]		; cx = number of scraps
	call	VMUnlock
done:
	.leave
	ret
GetNumScraps	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScrapBookRequestMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	request for entry in scrap name list

CALLED BY:	MSG_SCRAPBOOK_SCRAP_LIST_REQUEST_ENTRY_MONIKER

PASS:		cx:dx = OD of list
		bp = entry to get

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	03/13/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScrapBookRequestMoniker	method	ScrapBookClass, \
				MSG_SCRAPBOOK_SCRAP_LIST_REQUEST_ENTRY_MONIKER
	mov	ax, bp
	mov	di, ax				; di = entry to get
	call	GetThisScrapIndexOffset		; si = index offset
	mov	bx, ss:[currentScrapFile]
	tst	bx
	LONG jz	done
	call	VMGetMapBlock
	call	VMLock				; lock index block
	mov	es, ax
	cmp	di, es:[SBIH_numScraps]		; beyond last scrap?
						; (check results later)
	mov	ax, es:[si].SBIE_vmBlock
	call	VMUnlock			; unlock index block
						; (preserves flags)
	LONG jae	done			; yes beyond last one, do nada
	call	VMLock				; lock item block
	push	bp
	push	di				; save entry # to get
	;
	; copy over scrap name into our buffer so we can tack on scrap number
	;
	push	ds
	push	ax				; save scrap segment
	mov	ax, di				; ax = entry #
	inc	ax				; 1-based
	GetResourceSegmentNS	scrapNameMonikerBuffer, es	; es:di = buffer
	mov	di, offset scrapNameMonikerBuffer
	call	ASCIIizeWordAX			; store ASCII number into es:di
if DBCS_PCGEOS
	LocalLoadChar	ax, C_PERIOD
	LocalPutChar	esdi, ax
	LocalLoadChar	ax, C_SPACE
	LocalPutChar	esdi, ax
else
	mov	ax, '.' or (' ' shl 8)		; seperator
	stosw
endif
	pop	ds				; ds:si = scrap name
	mov	si, offset CIH_name
	mov	cx, length CIH_name
	LocalCopyNString			; copy over scrap name&C_NULL
	pop	ds
	;
	; clip moniker, if necessary
	; scrapNameMonikerBuffer = moniker
	; es = scrapNameMonikerBuffer segment
	;
	GetResourceHandleNS	ScrapNameList, bx
	mov	si, offset ScrapNameList
	mov	ax, MSG_VIS_VUP_CREATE_GSTATE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			; bp = gstate
	jnc	noClip
	mov	di, offset scrapNameMonikerBuffer	; es:di = moniker
	call	LocalStringLength		; cx = length
	mov	di, bp
	push	ds
	segmov	ds, ss, si
	mov	si, offset scrapNameMonikerBuffer
	call	GrTextWidth
	mov	bx, dx				; bx = text width
	mov	si, GFMI_ROUNDED or GFMI_AVERAGE_WIDTH
	call	GrFontMetrics			; dx
	mov	ax, 25				; match hint in ScrapNameList
	mul	dl				; ax = available width
	cmp	bx, ax
	jbe	haveRoom
	push	ax
	mov	ax, C_ELLIPSIS
	call	GrCharWidth			; dx = ellipsis width
	pop	ax
	sub	ax, dx				; ax = target width
	mov	si, offset scrapNameMonikerBuffer
	dec	cx
truncateLoop:
	call	GrTextWidth			; dx = width
	cmp	dx, ax
	jbe	truncated
	loop	truncateLoop
truncated:
	push	di
	mov	di, offset scrapNameMonikerBuffer
	add	di, cx				; es:di = position for ellipsis
DBCS <	add	di, cx						>
	LocalLoadChar	ax, C_ELLIPSIS
	LocalPutChar	esdi, ax
	LocalLoadChar	ax, C_NULL
	LocalPutChar	esdi, ax
	pop	di
haveRoom:
	call	GrDestroyState
	pop	ds
noClip:
	;
	; set up params for MSG_GEN_LIST_SET_ENTRY_MONIKER
	;
	pop	bp				; bp = entry # to get
	push	bp				; save again
	mov	cx, es
	mov	dx, offset scrapNameMonikerBuffer
	mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_TEXT
	GetResourceHandleNS	ScrapNameList, bx
	mov	si, offset ScrapNameList
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	;
	; set this entry as the exclusive if it is the current scrap
	;
	pop	ax				; ax = entry #
	cmp	ax, ss:[currentScrap]		; is it the current one?
	jne	afterCurrent			; nope
	call	SetCurrentScrapInScrapNameList	; else, set as exclusive
afterCurrent:
	;
	; finish up
	;
	pop	bp
	call	VMUnlock
done:
	ret
ScrapBookRequestMoniker	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScrapBookNext
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	advance to next scrap in current scrapbook

CALLED BY:	MSG_SCRAPBOOK_NEXT

PASS:		

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	02/28/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScrapBookNext	method	ScrapBookClass, MSG_SCRAPBOOK_NEXT
	call	SaveCurrentScrapName
	mov	bx, ss:[currentScrapFile]
	tst	bx
	jz	done
	call	VMGetMapBlock			; ax = map block
	call	VMLock				; lock map block
	push	bp
	mov	ds, ax				; ds = map block segment
EC <	cmp	ds:[SBIH_numScraps], 0		; any scraps? 	>
EC <	je	exit				; nope		>
	mov	ax, ss:[currentScrap]		; ax = current scrap #
	inc	ax				; move to next scrap
	cmp	ax, ds:[SBIH_numScraps]		; at last scrap?
	jne	haveNextScrap			; no, use it
	mov	ax, 0				; else, wrap-around to first
						;	scrap
haveNextScrap:
	mov	ss:[currentScrap], ax		; store new current scrap
exit::
	pop	bp				; unlock map block
	call	VMUnlock
	call	ShowCurrentScrap		; show new current scrap
done:
	ret
ScrapBookNext	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScrapBookPrevious
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	advance to previous scrap in current scrapbook

CALLED BY:	MSG_SCRAPBOOK_PREVIOUS

PASS:		

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	02/28/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScrapBookPrevious	method	ScrapBookClass, MSG_SCRAPBOOK_PREVIOUS
	call	SaveCurrentScrapName
	mov	bx, ss:[currentScrapFile]
	tst	bx
	jz	done
	call	VMGetMapBlock			; ax = map block
	call	VMLock				; lock map block
	push	bp
	mov	ds, ax				; ds = map block segment

EC <	cmp	ds:[SBIH_numScraps], 0		; any scraps?	>
EC <	je	exit				; nope		>
	mov	ax, ss:[currentScrap]		; ax = current scrap #
	dec	ax
	cmp	ax, -1				; beyond first scrap?
	jne	havePrevScrap			; no, use it
	mov	ax, ds:[SBIH_numScraps]		; else, wrap-around to
	dec	ax				;	last scrap
havePrevScrap:
	mov	ss:[currentScrap], ax		; store new current scrap
exit::
	pop	bp				; unlock map block
	call	VMUnlock
	call	ShowCurrentScrap		; show new current scrap
done:
	ret
ScrapBookPrevious	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScrapBookVMFileDirty
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	current scrapbook dirtied, notify document control

CALLED BY:	MSG_META_VM_FILE_DIRTY

PASS:		cx - file handle

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	04/11/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScrapBookVMFileDirty	method	ScrapBookClass, MSG_META_VM_FILE_DIRTY
	uses	ax, bx, cx, dx, es, di, ds, si, bp
	.enter

	tst	ss:[currentDoc].handle			; engine mode?
	jz	done
	GetResourceHandleNS	ScrapAppDocControl, bx
	mov	si, offset ScrapAppDocControl
	mov	ax, MSG_GEN_DOCUMENT_GROUP_MARK_DIRTY_BY_FILE
	clr	di
	call	ObjMessage
done:
	.leave
	ret
ScrapBookVMFileDirty	endm

ScrapBookTextUserModified	method	ScrapBookClass,
					MSG_META_TEXT_USER_MODIFIED
	GetResourceHandleNS	ScrapName, bx
	cmp	cx, bx
	jne	done
	cmp	dx, offset ScrapName
	jne	done
	;
	; we need to ensure that the text object is actually dirty as the
	; SET_TEXT-followed-by-SET_CLEAN sequence will queue up a USER_MODIFIED
	; but the text object is actually clean
	;
	mov	si, dx				; bx:si = text object
	mov	ax, MSG_VIS_TEXT_GET_USER_MODIFIED_STATE
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage			; cx = 0 if clean
	jcxz	done				; clean, do nothing
	;
	; text is genuinely dirty
	;
if 0
	mov	cx, ss:[currentScrapFile]	; cx = file handle
	jcxz	done
	call	ScrapBookVMFileDirty
else
	mov	bx, ss:[currentScrapFile]	; bx = file handle
	tst	bx
	jz	done
	call	VMGetMapBlock
	call	VMLock				; bp = mem handle
	call	VMDirty			; this generates MSG_META_VM_FILE_DIRTY
	call	VMUnlock
endif
done:
	ret
ScrapBookTextUserModified	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScrapBookDocOutputInitializeDocumentFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	ScrapBookDocOutputInitializeDocumentFile

CALLED BY:	MSG_META_DOC_OUTPUT_INITIALIZE_DOCUMENT_FILE

PASS:		cx:dx = document object
		bp = file handle of new file

RETURN:		carry clear for no error

DESTROYED:	

PSEUDO CODE/STRATEGY:
		remove current scrapbook from memory

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	02/27/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScrapBookDocOutputInitializeDocumentFile	method	ScrapBookClass,
				MSG_META_DOC_OUTPUT_INITIALIZE_DOCUMENT_FILE
	mov	ss:[currentScrapFile], bp	; use new file
	movdw	ss:[currentDoc], cxdx
	;
	; We want to be notified when the block is dirty, and we also want
	; the block to be asynchronously updated, so set/clear those bits...
	;
	mov	bx, bp
if NO_BACKUP
	mov	ax, mask VMA_NOTIFY_DIRTY or ((mask VMA_SYNC_UPDATE or mask VMA_BACKUP) shl 8)
else
	mov	ax, mask VMA_NOTIFY_DIRTY or (mask VMA_SYNC_UPDATE shl 8)
endif
	call	VMSetAttributes
	;
	; create index block
	;
	mov	cx, size ScrapBookIndexHeader
	call	VMAlloc
	call	VMSetMapBlock			; use as index block
	call	VMLock
	mov	es, ax
	mov	es:[SBIH_numScraps], 0		; no scraps yet
	call	VMDirty
	call	VMUnlock
	call	VMSave				; save initial stuff (now
						;	that we have a
						;	consistent file)
	tst	ss:[currentDoc].handle
	jz	done				; that's all for engine mode
	;
	; set up stuff for new scrapbook file
	;
	mov	ss:[currentScrap], 0		; no current scrap
	call	ClearScrapView			; no scrap to show
	;
	; active previous, next buttons
	;
	call	EnableScrapBook
done:
	clc					; return no error
	ret
ScrapBookDocOutputInitializeDocumentFile	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScrapBookDocOutputAttachUItoDocument
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	ScrapBookDocOutputAttachUItoDocument

CALLED BY:	MSG_META_DOC_OUTPUT_ATTACH_UI_TO_DOCUMENT

PASS:		cx:dx = document object
		bp = file handle of file

RETURN:		carry clear for no error

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	02/27/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScrapBookDocOutputAttachUItoDocument	method	ScrapBookClass,
				MSG_META_DOC_OUTPUT_ATTACH_UI_TO_DOCUMENT
	mov	ss:[currentScrapFile], bp	; use new file
	movdw	ss:[currentDoc], cxdx
	mov	bx, bp
	;
	; check if valid scrapbook file
	;
	call	VMGetMapBlock
	tst	ax				; any map block?
	jz	error				; no, bad file
	;
	; other checks
	;
	jmp	short fileOK

error:
	mov	es:[currentScrap], 0		; no current scrap
	mov	es:[currentScrapFile], 0
	mov	bp, offset InvalidScrapBookFileString
	call	ScrapError
if 0
	;
	; after reporting bad scrapbook file error, close the scrapbook file
	;
	mov	ax, MSG_GEN_APP_DOCUMENT_CONTROL_CLOSE_DOC
	clr	cx				; only one file
	mov	dx, cx
	GetResourceHandleNS	ScrapAppDocControl, bx
	mov	si, offset ScrapAppDocControl
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	jmp	short done
else
; let document control handle the error -- brianc 4/17/91
	stc					; indicate error
	jmp	short exit
endif

fileOK:
	;
	; display first scrap; or last viewed page, if restoring from state
	;
	mov	ax, ss:[lastViewedPage]
	mov	ss:[currentScrap], ax
	call	ShowCurrentScrap
	;
	; active previous, next buttons
	;
	call	EnableScrapBook
	;
	; reset scrap name list
	;
	mov	di, mask MF_CALL
	call	ResetScrapNameList
;done:
	clc					; return no error
exit:
	ret
ScrapBookDocOutputAttachUItoDocument	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScrapBookDocOutputWriteCachedDataToFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	ScrapBookDocOutputWriteCachedDataToFile

CALLED BY:	MSG_META_DOC_OUTPUT_WRITE_CACHED_DATA_TO_FILE

PASS:		cx:dx = document control object
		bp = file handle of file to save to

RETURN:		carry clear for no error
		ax = 0 to queue remainder of save
		ax <> 0 to NOT queue remainder of save

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	01/02/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScrapBookDocOutputWriteCachedDataToFile	method	ScrapBookClass,
				MSG_META_DOC_OUTPUT_WRITE_CACHED_DATA_TO_FILE
	call	SaveCurrentScrapName		; returns ax = 0 if name saved
						;	--> queue save
	clc					; return no error
	;
	; nothing specific for us to do, document control handles it
	;
	ret
ScrapBookDocOutputWriteCachedDataToFile	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScrapBookDocOutputSaveAsCompleted
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	ScrapBookDocOutputSaveAsCompleted

CALLED BY:	MSG_META_DOC_OUTPUT_SAVE_AS_COMPLETED

PASS:		cx:dx = document
		bp = new file handle

RETURN:		carry clear for no error

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	04/20/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScrapBookDocOutputSaveAsCompleted	method	ScrapBookClass, \
					MSG_META_DOC_OUTPUT_SAVE_AS_COMPLETED
	mov	ss:[currentScrapFile], bp	; use new file
	;
	; nothing specific for us to do, document control handles it
	;
	clc					; return no error
	ret
ScrapBookDocOutputSaveAsCompleted	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScrapBookDocOutputReadCachedDataFromFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	ScrapBookDocOutputReadCachedDataFromFile

CALLED BY:	MSG_META_DOC_OUTPUT_READ_CACHED_DATA_FROM_FILE

PASS:		

RETURN:		carry clear for no error

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	04/20/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScrapBookDocOutputReadCachedDataFromFile	method	ScrapBookClass, \
				MSG_META_DOC_OUTPUT_READ_CACHED_DATA_FROM_FILE
	;
	; save scrap name, if needed
	; (this shouldn't be needed as revert will undo this change, if this
	;  change is actually made?)
	;
	call	SaveCurrentScrapName
	;
	; clear stuff, in case we revert to nothing, we will open the revert
	; file again later, anyway
	;
	mov	es:[currentScrapFile], 0
	mov	es:[currentScrap], 0		; no current scrap
	call	ClearScrapView
	clc					; return no error
	ret
ScrapBookDocOutputReadCachedDataFromFile	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScrapBookDocOutputDestroyUIForDocument
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	ScrapBookDocOutputDestroyUIForDocument

CALLED BY:	MSG_META_DOC_OUTPUT_DESTROY_UI_FOR_DOCUMENT

PASS:		cx:dx - document control object
		bp - file handle of file being closed

RETURN:		carry clear for no error

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	02/28/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScrapBookDocOutputDestroyUIForDocument	method	ScrapBookClass,
				MSG_META_DOC_OUTPUT_DESTROY_UI_FOR_DOCUMENT
	mov	bx, 0				; assume not detach -- set
						;	lastViewedPage to 0
	mov	ax, MSG_GEN_APPLICATION_GET_STATE
	call	GenCallApplication		; al - ApplicationStates
	test	al, mask AS_DETACHING		; check if detaching
	jz	notDetach			; nope
	mov	bx, es:[currentScrap]		; if so, save last viewed page
						;	as current page
notDetach:
	mov	es:[lastViewedPage], bx
	mov	es:[currentScrapFile], 0
	mov	es:[currentScrap], 0		; no current scrap
	call	ClearScrapView
	;
	; de-active previous, next buttons
	;
	call	DisableScrapBook
	clc					; return no error
	ret
ScrapBookDocOutputDestroyUIForDocument	endm

ScrapBookDocOutputDetachUI	method	ScrapBookClass,
				MSG_META_DOC_OUTPUT_DETACH_UI_FROM_DOCUMENT
	mov	bx, es:[currentScrap]		; save last viewed page
	mov	es:[lastViewedPage], bx		; ...to be the current page
	mov	es:[currentScrapFile], 0
	mov	es:[currentScrap], 0		; no current scrap
	call	ClearScrapView
	;
	; de-active previous, next buttons
	;
	call	DisableScrapBook
	clc					; return no error
	ret
ScrapBookDocOutputDetachUI	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScrapBookDocOutputUpdateEarlierIncompatibleDocument
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a 1.X document to 2.0

CALLED BY:	MSG_META_DOC_OUTPUT_UPDATE_EARLIER_INCOMPATIBLE_DOCUMENT

PASS:		ds = es = dgroup
		bp = VM file handle

RETURN:		carry clear for no error
		ax - non-zero to up protocol

DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/28/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if not DBCS_PCGEOS
convertLibDir	char	CONVERT_LIB_DIR
convertLibPath	char	CONVERT_LIB_PATH
endif

ScrapBookDocOutputUpdateEarlierIncompatibleDocument	method ScrapBookClass,
		MSG_META_DOC_OUTPUT_UPDATE_EARLIER_INCOMPATIBLE_DOCUMENT

if DBCS_PCGEOS
	stc		;don't load conversion library; return error
else

	;  Load the conversion library

	segmov	ds, cs
	mov	bx, CONVERT_LIB_DISK_HANDLE
	mov	dx, offset convertLibDir
	call	FileSetCurrentPath

	mov	si, offset convertLibPath
	mov	ax, CONVERT_PROTO_MAJOR
	mov	bx, CONVERT_PROTO_MINOR
	call	GeodeUseLibrary			; bx = library
	jc	done

	push	bx				; save library handle

	mov	ax, enum ConvertOldScrapbookDocument
	call	ProcGetLibraryEntry
	call	ProcCallFixedOrMovable

	pop	bx
	call	GeodeFreeLibrary

	mov	ax, -1				; up protocol, please
	clc					; indicate no error

done:

endif
	ret

ScrapBookDocOutputUpdateEarlierIncompatibleDocument	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SaveCurrentScrapName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	save user-entered name for current scrap

CALLED BY:	INTERNAL

PASS:		ds - object block

RETURN:		ax = 0 if name changed and saved
		ax = -1 if name unchanged and NOTHING saved

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	03/01/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SaveCurrentScrapName	proc	near
	uses	bx, cx, dx, si, es, di, bp
	.enter
	;
	; check if any scraps; if none, no name to save
	;
	call	GetNumScraps			; cx = number of scraps
	jcxz	clean				; no scraps -> no name to save
	;
	; check if name was dirtied
	;
	GetResourceHandleNS	ScrapName, bx
	mov	si, offset ScrapName
	mov	ax, MSG_VIS_TEXT_GET_USER_MODIFIED_STATE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			; cx = 0 if object is clean
	jcxz	clean				; text clean, don't save again
	;
	; get scrap name, if any
	;
	mov	ax, MSG_VIS_TEXT_GET_ALL_BLOCK
	clr	dx				; allocate new block
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
;if name is null, clear old name - 8/13/90
;	tst	cx				; any name?
;	jz	clean				; no
	;
	; name changed, save in scrap block
	;
	call	SaveNameInScrap
	;
	; mark text as being clean again
	;
	GetResourceHandleNS	ScrapName, bx
	mov	si, offset ScrapName
	mov	ax, MSG_VIS_TEXT_SET_NOT_USER_MODIFIED
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	;
	; reset scrap name list
	;
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ResetScrapNameList
	mov	ax, 0				; indicate name saved
	jmp	short done

clean:
	mov	ax, -1				; indicate no name saved
done:
	.leave
	ret
SaveCurrentScrapName	endp

;
; Pass:
;	cx = block handle of new name
;	ax = length w/o null
;
SaveNameInScrap	proc	near
	uses	ds
	.enter
	push	cx				; save name block handle
	GetResourceSegmentNS	dgroup, es
	call	ScrapBookLockMap
	mov	es, ax
	call	GetCurrentScrapIndexOffset
	mov	di, si				; es:di = index entry for scrap
	mov	ax, es:[di].SBIE_vmBlock	; ax = transfer header block
	call	VMUnlock			; unlock map block
	call	VMLock				; lock transfer header block
	call	VMDirty				; mark as dirty - new name
	mov	es, ax				; es = name field in transfer
	mov	di, offset CIH_name		;	header block
SBCS<	mov	{char} es:[di], 0		; in case no name	>
DBCS<	mov	{wchar} es:[di], 0		; in case no name	>
	pop	bx
	tst	bx				; any name?
	jz	afterName
	call	MemLock				; lock name block
	mov	ds, ax				; ds:si = null-term'ed name
	clr	si
	mov	cx, length CIH_name		; plus null
	LocalCopyNString
	call	MemUnlock			; unlock handle bx
afterName:
	call	VMUnlock			; unlock handle bp
	.leave
	ret
SaveNameInScrap	endp

;
; di = ObjMessage flags
;
ResetScrapNameList	proc	near
	GetResourceHandleNS	ScrapNameList, bx
	mov	si, offset ScrapNameList
	mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
	call	GetNumScraps			; cx = number of scraps
	push	di				; save MessageFlags
	call	ObjMessage
	pop	di				; retrieve MessageFlags
	mov	cx, ss:[currentScrap]		; select current scrap
	cmp	cx, -1
	je	exit				; no current scrap
	clr	dx				; not indeterminate
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	call	ObjMessage
exit:
	ret
ResetScrapNameList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScrapBookScrapNameCR
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User pressed <CR> in scrap name entry field, save current
		scrap name.

CALLED BY:	MSG_SCRAPBOOK_SCRAPNAME_CR

PASS:		

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	04/24/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScrapBookScrapNameCR	method	ScrapBookClass, MSG_SCRAPBOOK_SCRAPNAME_CR
	call	SaveCurrentScrapName
	ret
ScrapBookScrapNameCR	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		{Enable,Disable}ScrapBook
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	enable or disable "previous" and "next" controls

CALLED BY:	INTERNAL

PASS:		nothing

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	02/28/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EnableScrapBook	proc	near
	mov	ss:[canPaste], TRUE
	mov	ax, MSG_GEN_SET_ENABLED
	call	AbleCommon
	;
	; disable scrap name field if there are no scraps
	;
	call	GetNumScraps			; cx = number of scraps
	cmp	cx, 1
	je	disableOne			; disable one scrap items
	ja	skipName		; if > 1 scraps exist, don't disable

	call	DisableNoScrapItems
	jmp	short skipName
disableOne:
	call	DisableOneScrapItems
	
skipName:
	;
	; enable paste button if there is something to paste
	;
	call	ScrapBookNotifyNormalTransferItemChanged
	ret
EnableScrapBook	endp

DisableNoScrapItems	proc	near
	GetResourceHandleNS	ScrapName, bx
	mov	si, offset ScrapName
	call	SendDisableMessage
	GetResourceHandleNS	DeleteTrigger, bx
	mov	si, offset DeleteTrigger
	call	SendDisableMessage
	GetResourceHandleNS	CutTrigger, bx
	mov	si, offset CutTrigger
	call	SendDisableMessage
	GetResourceHandleNS	CopyTrigger, bx
	mov	si, offset CopyTrigger
	call	SendDisableMessage
	GetResourceHandleNS	ScrapNameControlShow, bx
	mov	si, offset ScrapNameControlShow
	call	SendDisableMessage
	GetResourceHandleNS	ScrapPrevious, bx
	mov	si, offset ScrapPrevious
	call	SendDisableMessage
	GetResourceHandleNS	ScrapNext, bx
	mov	si, offset ScrapNext
	call	SendDisableMessage
	GetResourceHandleNS	ScrapNameBoxTrigger, bx
	mov	si, offset ScrapNameBoxTrigger
	call	SendDisableMessage
	ret
DisableNoScrapItems	endp

DisableOneScrapItems 	proc	near
	GetResourceHandleNS	ScrapPrevious, bx
	mov	si, offset ScrapPrevious
	call	SendDisableMessage
	GetResourceHandleNS	ScrapNext, bx
	mov	si, offset ScrapNext
	call	SendDisableMessage
	GetResourceHandleNS	ScrapNameBoxTrigger, bx
	mov	si, offset ScrapNameBoxTrigger
	call	SendDisableMessage
	ret
DisableOneScrapItems	endp

SendDisableMessage	proc	near
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	call	SendAbleMessage
	ret
SendDisableMessage	endp

SendAbleMessage	proc	near
	push	ax
	mov	dl, VUM_NOW
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	ax
	ret
SendAbleMessage	endp

DisableScrapBook	proc	far
	mov	ss:[canPaste], FALSE
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	call	AbleCommon
	;
	; disable these also
	;
	GetResourceHandleNS	PasteTrigger, bx
	mov	si, offset PasteTrigger
	call	SendAbleMessage
	GetResourceHandleNS	PasteAtEndTrigger, bx
	mov	si, offset PasteAtEndTrigger
	call	SendAbleMessage
	ret
DisableScrapBook	endp

;
; ax = method to send
;
AbleCommon	proc	near
	GetResourceHandleNS	ScrapNext, bx
	mov	si, offset ScrapNext
	call	SendAbleMessage
	GetResourceHandleNS	ScrapPrevious, bx
	mov	si, offset ScrapPrevious
	call	SendAbleMessage
	GetResourceHandleNS	ScrapNameBox, bx
	mov	si, offset ScrapNameBox
	call	SendAbleMessage
	GetResourceHandleNS	ScrapNameBoxTrigger, bx
	mov	si, offset ScrapNameBoxTrigger
	call	SendAbleMessage
	GetResourceHandleNS	ScrapNameControlShow, bx
	mov	si, offset ScrapNameControlShow
	call	SendAbleMessage
	GetResourceHandleNS	ScrapName, bx
	mov	si, offset ScrapName
	call	SendAbleMessage
	GetResourceHandleNS	ScrapNumber, bx
	mov	si, offset ScrapNumber
	call	SendAbleMessage
	GetResourceHandleNS	CutTrigger, bx
	mov	si, offset CutTrigger
	call	SendAbleMessage
	GetResourceHandleNS	DeleteTrigger, bx
	mov	si, offset DeleteTrigger
	call	SendAbleMessage
	GetResourceHandleNS	CopyTrigger, bx
	mov	si, offset CopyTrigger
	call	SendAbleMessage
	GetResourceHandleNS	ScrapBody, bx
	mov	si, offset ScrapBody
	call	SendAbleMessage
	GetResourceHandleNS	ScrapBookImporter, bx
	mov	si, offset ScrapBookImporter
	call	SendAbleMessage
	ret
AbleCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClearScrapView
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	clear scrapbook display

CALLED BY:	INTERNAL
			ScrapBookFileNew
			ScrapBookFileClose
			ScrapBookFileRevertPart1

PASS:

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	02/27/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClearScrapView	proc	near
	GetResourceHandleNS	ScrapName, bx
	mov	si, offset ScrapName
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	call	SendAbleMessage
	;
	; clear whatever mode we are in
	;
	cmp	ss:[currentFormat], CIF_TEXT
	je	clearText
	;
	; clear gstring view
	;
	call	InvalViewWindow
	jmp	afterClear

clearText:
	;
	; clear text view
	;
	call	ClearTextArea
afterClear:
	;
	; clear scrap number
	;
	GetResourceHandleNS	EmptyScrapbookString, bx
	push	bx
	call	MemLock
	push	ds
	mov	dx, ax				; dx = segment of string
	mov	ds, ax
	mov	si, offset EmptyScrapbookString
	mov	bp, ds:[si]			; deref. string chunk
	pop	ds
	clr	cx				; null-terminated
	GetResourceHandleNS	ScrapNumber, bx
	mov	si, offset ScrapNumber
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	bx
	call	MemUnlock			; unlock string block
	;
	; clear scrap name area
	;
	mov	dx, cs
	mov	bp, offset nullString
	clr	cx				; null-terminated
	GetResourceHandleNS	ScrapName, bx
	mov	si, offset ScrapName
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	di, mask MF_CALL
	call	ObjMessage
	;
	; clear scrap name list
	;
	GetResourceHandleNS	ScrapNameList, bx
	mov	si, offset ScrapNameList
	mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
	mov	cx, 0				; no entries
	mov	di, mask MF_CALL
	call	ObjMessage
	ret
ClearScrapView	endp

InvalViewWindow	proc	near

	mov	di, ss:[gStringWindow]
	tst	di
	jz	done

	clr	ax, bx, bp
	mov	cx, MAX_COORD
	mov	dx, cx
	call	WinInvalReg			; clear it (forces redraw)
done:
	ret
InvalViewWindow	endp

;
; pass:
;	di = ObjMessage flags
;
ClearTextArea	proc	near
	;
	; first, clear any old text
	;
	GetResourceHandleNS	ScrapText, bx
	mov	si, offset ScrapText
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	dx, cs
	mov	bp, offset nullString
	clr	cx				; null-terminated
	mov	di, mask MF_CALL
	call	ObjMessage
;turned back on - brianc 2/25/93
if 1
	;
	; second, clear any old style and ruler info
	;
	mov	ax, MSG_VIS_TEXT_SET_PARA_ATTR_BY_DEFAULT	; clear ruler
	mov	dx, size VisTextSetParaAttrByDefaultParams
	sub	sp, dx
	mov	bp, sp
	mov	ss:[bp].VTSPABDP_range.VTR_start.low, 0
	mov	ss:[bp].VTSPABDP_range.VTR_start.high, 0
	mov	ss:[bp].VTSPABDP_range.VTR_end.low, TEXT_ADDRESS_PAST_END_LOW
	mov	ss:[bp].VTSPABDP_range.VTR_end.high, TEXT_ADDRESS_PAST_END_HIGH
	mov	ss:[bp].VTSPABDP_paraAttr, VIS_TEXT_INITIAL_PARA_ATTR
	mov	di, mask MF_CALL or mask MF_STACK
	call	ObjMessage
	add	sp, size VisTextSetParaAttrByDefaultParams

	mov	ax, MSG_VIS_TEXT_SET_CHAR_ATTR_BY_DEFAULT	; clear styles
	mov	dx, size VisTextSetCharAttrByDefaultParams
	sub	sp, dx
	mov	bp, sp
	mov	ss:[bp].VTSPABDP_range.VTR_start.low, 0
	mov	ss:[bp].VTSPABDP_range.VTR_start.high, 0
	mov	ss:[bp].VTSPABDP_range.VTR_end.low, TEXT_ADDRESS_PAST_END_LOW
	mov	ss:[bp].VTSPABDP_range.VTR_end.high, TEXT_ADDRESS_PAST_END_HIGH
NPZ <	mov	ss:[bp].VTSCABDP_charAttr, (VTDS_10 shl offset VTDCA_SIZE) or (VTDF_BERKELEY) >
PZ <	mov	ss:[bp].VTSCABDP_charAttr, (VTDS_16 shl offset VTDCA_SIZE) or (VTDF_PIZZA_KANJI) >
	mov	di, mask MF_CALL or mask MF_STACK
	call	ObjMessage
	add	sp, size VisTextSetCharAttrByDefaultParams
endif
	ret
ClearTextArea	endp

LocalDefNLString nullString	<0>


; Pass:		ss: dgroup
; Return: 	ax - segment of map block
;		bx - scrapbook file handle
;		bp - handle of map block
ScrapBookLockMap	proc	near
		mov	bx, ss:[currentScrapFile]
		call	VMGetMapBlock
		call	VMLock
		ret
ScrapBookLockMap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ShowCurrentScrap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	displays current scrap of opened scrapbook

CALLED BY:	INTERNAL
			ScrapBookNext
			ScrapBookPrevious
			ScrapBookFileOpen

PASS:		nothing

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	02/28/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ShowCurrentScrap	proc	near

	call	ScrapBookLockMap
	push	bp
	mov	ds, ax				; ds = segment of index block
	mov	dx, ds:[SBIH_numScraps]		; any scraps?
	tst	dx
	LONG jz	exit				; no, nothing to draw
	cmp	ss:[currentScrap], dx		; deal with bogus scrap numbers
	jb	curScrapOK
	mov	ss:[currentScrap], 0
curScrapOK:
	call	GetCurrentScrapIndexOffset	; ds:si = entry for current
						;	scrap in index block
	;
	; get scrap from index block
	;
	mov	bx, ss:[currentScrapFile]
	mov	ax, ds:[si].SBIE_vmBlock
	call	VMLock
	push	bp			
	mov	ds, ax
	;
	; show scrap number
	;	dx = number of scraps
	;
	call	ShowScrapNumber
	;
	; show name of scrap
	;
	call	ShowScrapName
	;
	; set the appropriate view contents to show the scrap
	;
	mov	ax, MANUFACTURER_ID_GEOWORKS
	mov	dx, CIF_BITMAP
	call	findFormat
	jnc	found

	mov	dx, CIF_GRAPHICS_STRING
	call	findFormat
	jnc	found

	mov	dx, CIF_TEXT
	call	findFormat
	jnc	found
	;
	; no gstring or text found, use first format, and report error
	;
	mov	cx, ds:[CIH_formats].CIFI_format.CIFID_manufacturer
	mov	dx, ds:[CIH_formats].CIFI_format.CIFID_type
	call	SetScrapViewContent
	jmp	done
		
found:
	mov	cx, ax				; cx,dx = format
	push	bx, dx				; save offset, type found
	call	SetScrapViewContent
	pop	bx, dx				; restore offset, type found
EC <	ERROR_C	-1						>
	; ax = most appropriate item
	mov	ax, ds:[CIH_formats][bx].CIFI_vmChain.high
		
	;
	; we know formatManufacturer = MANUFACTURER_ID_GEOWORKS
	;	bx = offset
	;	dx = CIF_TEXT, CIF_GRAPHICS_STRING, or CIF_BITMAP
	;
	cmp	dx, CIF_TEXT			; text?
	je	showText			; yes
	cmp	dx, CIF_GRAPHICS_STRING
	je	showGString

showBitmap::
	push	ax
	mov	bx, ss:[currentScrapFile]
	mov	di, ax
	call	GrGetHugeBitmapSize
	mov_tr	cx, ax
	mov	dx, bx
	pop	ax
	jmp	checkSizes
		
showGString:
	;
	; set document size for this gstring
	;	bx = offset
	;
	mov	cx, ds:[CIH_formats][bx].CIFI_extra1	; width
	mov	dx, ds:[CIH_formats][bx].CIFI_extra2	; height
checkSizes:
	cmp	cx, 7fffh			; 16 bit max
	jbe	widthOkay			; unsigned compare
	mov	cx, 7fffh
widthOkay:
	cmp	dx, 7fffh			; 16 bit max
	jbe	heightOkay			; unsigned compare
	mov	dx, 7fffh
heightOkay:
	GetResourceHandleNS	ScrapGString, bx
	mov	si, offset ScrapGString
	push	ds
	clr	di
	call	GenViewSetSimpleBounds
	pop	ds
	jmp	done
showText:
	push	ax				; save VM block handle of scrap
	;
	; clear any old text and style and ruler
	;
	call	ClearTextArea
	pop	ax
	;
	; Determine if there is little enough text that we can just do a
	; MSG_VIS_TEXT_REPLACE_WITH_TEXT_TRANSFER_ITEM.  If not, we'll
	; just show some of the text with MSG_VIS_TEXT_REPLACE_ALL_PTR.
	;	ax = VM block handle of scrap item (TextTransferBlockHeader)
	;
	push	ds, ax
	mov	bx, ss:[currentScrapFile]
	call	VMLock				; bp = mem handle, ax = seg
	mov	ds, ax
	mov	di, ds:[TTBH_text].high
	call	HugeArrayGetCount		; dx:ax = count
	mov	cx, ax				; dx:cx = count
	call	VMUnlock
	pop	ds, ax
	tst	dx				; if > 64K, too big
	jnz	tooBig
	cmp	cx, SHOWABLE_TEXT_SIZE_THRESHOLD
	jbe	smallEnough
tooBig:
	;
	; use MSG_VIS_TEXT_REPLACE_ALL_PTR with some of the text
	;	di = HA text block
	;
	push	ds
	mov	bx, ss:[currentScrapFile]
	mov	ax, 0				; start at first element
	mov	dx, ax
	call	HugeArrayLock			; ds:si = element, ax = count
EC <SBCS <	cmp	dx, 1						>>
EC <DBCS <	cmp	dx, (size wchar)				>>
EC <	ERROR_NE 0							>
	movdw	dxbp, dssi			; dxbp = ptr
	mov	cx, ax				; cx = count
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	GetResourceHandleNS	ScrapText, bx
	mov	si, offset ScrapText
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	call	HugeArrayUnlock
	;
	; add reminder to end
	;
	mov	si, offset TextOverflowString
	GetResourceHandleNS	ScrapStrings, bx
	push	bx
	call	MemLock				; ax = string segment
	mov	dx, ax				; dx:bp = error string
	mov	ds, ax
	mov	bp, ds:[si]
	GetResourceHandleNS	ScrapText, bx	; then set error message
	mov	si, offset ScrapText
	mov	ax, MSG_VIS_TEXT_APPEND_PTR
	clr	cx				; null-terminated
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	bx
	call	MemUnlock
	pop	ds
	jmp	short done

smallEnough:
	;
	; set up params for MSG_VIS_TEXT_REPLACE_WITH_TEXT_TRANSFER_ITEM
	;	ax = VM block handle of scrap item
	;
	mov	dx, size CommonTransferParams
	sub	sp, dx
	mov	bp, sp
	mov	ss:[bp].CTP_range.VTR_start.low, 0
	mov	ss:[bp].CTP_range.VTR_start.high, 0
	movdw	ss:[bp].CTP_range.VTR_end, TEXT_ADDRESS_PAST_END
	mov	ss:[bp].CTP_pasteFrame, 0
	mov	ss:[bp].CTP_vmBlock, ax
	mov	ax, ss:[currentScrapFile]
	mov	ss:[bp].CTP_vmFile, ax
	GetResourceHandleNS	ScrapText, bx
	mov	si, offset ScrapText
	mov	ax, MSG_VIS_TEXT_REPLACE_WITH_TEXT_TRANSFER_FORMAT
	mov	di, mask MF_CALL or mask MF_STACK
	call	ObjMessage
	add	sp, size CommonTransferParams
done:
	pop	bp				; unlock transfer item block
	call	VMUnlock
exit:
	pop	bp				; unlock map block
	call	VMUnlock
	ret

;--------------------
findFormat:
	; ax:dx - format to find
	;
	clr	bx
	mov	cx, ds:[CIH_formatCount]	; cx = num formats
findLoop:
	cmp	ds:[CIH_formats][bx].CIFI_format.CIFID_manufacturer, ax
	jne	findNext
	cmp	ds:[CIH_formats][bx].CIFI_format.CIFID_type, dx
	je	findDone
		
findNext:
	add	bx, size ClipboardItemFormatInfo
	loop	findLoop
	stc
findDone:
	retn
		
ShowCurrentScrap	endp

ShowScrapName	proc	near
	mov	dx, ds				; dx:bp = scrap name
	mov	bp, offset CIH_name
	clr	cx				; null-terminated
	GetResourceHandleNS	ScrapName, bx
	mov	si, offset ScrapName
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	di, mask MF_CALL
	call	ObjMessage
	mov	ax, MSG_VIS_TEXT_SELECT_START
	mov	di, mask MF_CALL
	call	ObjMessage			; reposition to beginning
	ret
ShowScrapName	endp

;
; pass: dx = number of scraps
;	ss:bp = important struct ptr with [currentScrap].
; hose: ax, bx, cx, dx, es
;
ShowScrapNumber	proc	near
FORMAT_BUFFER_LENGTH	equ	38		; (doesn't included NULL)

	uses	ds
	.enter
SBCS<	sub	sp, FORMAT_BUFFER_LENGTH+2	; plenty of room	>
DBCS<	sub	sp, (FORMAT_BUFFER_LENGTH+1)*(size wchar)		>
	segmov	es, ss
	mov	di, sp				; es:di = buffer

	GetResourceHandleNS	PageNumberString, bx
	call	MemLock
	mov	ds, ax				; ds = string segment
	mov	si, offset PageNumberString
	mov	si, ds:[si]			; ds:si = page number string
	clr	cx
charLoop:
	LocalGetChar	ax, dssi
	LocalIsNull	ax			; end of string?
	jz	stringDone			; yes
	LocalCmpChar	ax, 01h			; current page param?
	jne	notCurPage			; nope
	mov	ax, ss:[currentScrap]		; 0-base current scrap
	inc	ax				; ax = scrap #
	cmp	cx, FORMAT_BUFFER_LENGTH - 6	; enough room? (6=len("65536"))
	ja	nextChar			; nope, skip
	call	ASCIIizeWordAX			; place ASCII # in buffer
	add	cx, 6				; bump char count
	jmp	short nextChar
notCurPage:
	LocalCmpChar	ax, 02h			; num pages param?
	jne	notNumPage			; nope
	mov	ax, dx				; ax = number of pages
	cmp	cx, FORMAT_BUFFER_LENGTH - 6	; enough room? (6=len("65536"))
	ja	nextChar			; nope, skip
	call	ASCIIizeWordAX			; (points di past end)
	add	cx, 6				; bump char count
	jmp	short nextChar
notNumPage:
	cmp	cx, FORMAT_BUFFER_LENGTH	; enough room?
	ja	nextChar			; nope, skip
	LocalPutChar	esdi, ax		; copy character verbatim
	inc	cx
nextChar:
	jmp	short charLoop

stringDone:
	LocalPutChar	esdi, ax		; store null-terminator
	call	MemUnlock			; unlock string resource

	mov	dx, ss				; dx:bp = scrap number
	mov	bp, sp
	clr	cx				; null-terminated
	GetResourceHandleNS	ScrapNumber, bx
	mov	si, offset ScrapNumber
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	di, mask MF_CALL
	call	ObjMessage

SBCS<	add	sp, FORMAT_BUFFER_LENGTH+2	; remove stack buffer	>
DBCS<	add	sp, (FORMAT_BUFFER_LENGTH+1)*(size wchar) ; remove stack buffer	>
	;
	; select current scrap in scrap name list
	;
	call	SetCurrentScrapInScrapNameList
	;
	; enable or disable the previous and next triggers based on the
	; current scrap shown.   -- jwu 11/3/93
	;
	call	ScrapbookSetPreviousAndNext
	.leave
	ret
ShowScrapNumber	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScrapbookSetPreviousAndNext
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enable the previous/next triger only if there is a 
		previous/next scrap, else disable it.  Wraparound is  
		allowed.  Also, "Go To Page" trigger is disabled here
		if there is only one scrap in the scrapbook, and enabled
		otherwise.

CALLED BY:	ShowScrapNumber

PASS:		nothing

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, di, si

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	11/ 3/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScrapbookSetPreviousAndNext	proc	near
	
	;
	; If the number of scraps is two, it may mean that a new scrap was
	; just added, in which case we want to make sure that the triggers
	; are enabled.  If there are more than 2, then we know that the
	; triggers are already enabled so we don't have to do anything.
	;
	call	GetNumScraps			; cx <- number of scraps
	cmp	cx, 2				

	ja	done				
	;
	; If there is only one scrap, then disable the previous and
	; next triggers and the "Go To Page" trigger.
	;
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	jb	sendMessage
	
	mov	ax, MSG_GEN_SET_ENABLED

sendMessage:
	GetResourceHandleNS	ScrapNameBoxTrigger, bx
	mov	si, offset ScrapNameBoxTrigger
	call	SendAbleMessage
	
	GetResourceHandleNS	ScrapPrevious, bx
	mov	si, offset ScrapPrevious
	call	SendAbleMessage
	
	GetResourceHandleNS	ScrapNext, bx
	mov	si, offset ScrapNext
	call	SendAbleMessage

done:	
	ret
ScrapbookSetPreviousAndNext	endp

SetCurrentScrapInScrapNameList	proc	near
	GetResourceHandleNS	ScrapNameList, bx
	mov	si, offset ScrapNameList
	mov	cx, ss:[currentScrap]		; cx = 0-based current scrap
	clr	dx				; not indeterminate
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	di, mask MF_CALL
	call	ObjMessage
	ret
SetCurrentScrapInScrapNameList	endp

;
;	PASS:	ax	= unsigned value to convert
;		es:di	= buffer to store string.
;	RETURN:	es:di	= pointing after last character
;	HOSED:	ax
;
ASCIIizeWordAX	proc	near
	push	bx, cx, dx
	mov	bx, 10				; print in base ten
	clr	cx
AWA_nextDigit:
	clr	dx
	div	bx
	add	dl, '0'				; convert to ASCII
	push	dx				; save resulting character
	inc	cx				; bump character count
	tst	ax				; check if done
	jnz	AWA_nextDigit			; if not, do next digit
AWA_nextChar:
	pop	ax				; retrieve character (in AL)
	LocalPutChar	esdi, ax		; stuff in buffer	>
	loop	AWA_nextChar			; loop to stuff all
	pop	bx, cx, dx
	ret
ASCIIizeWordAX	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetScrapViewContent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	sets correct object in scrapbook window to draw specified
		scrap

CALLED BY:	INTERNAL
			ShowCurrentScrap

PASS:		cx:dx = transfer item format
			(cx - format manufacturer, dx - format type)

RETURN:		carry clear if successful
		carry set if error (unsupported format)

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	02/27/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetScrapViewContent	proc	far

	cmp	cx, MANUFACTURER_ID_GEOWORKS
	jne	unknownFormat
	cmp	dx, CIF_GRAPHICS_STRING
	je	tifGString
	cmp	dx, CIF_BITMAP
	je	tifBitmap
	cmp	dx, CIF_TEXT
	jne	unknownFormat

	call	SetTifText
	jmp	noError

unknownFormat:
	pushdw	cxdx				; save format
	mov	bp, offset UnsupportedScrapFormatString
	call	ScrapError
	call	SetTifText			; then switch to text mode
	popdw	cxdx				; cxdx = type
						; then set status message
						;	based on type
	cmp	cx, MANUFACTURER_ID_GEOWORKS
	jne	unsupportedType
	mov	bp, offset SpreadsheetTypeString
	cmp	dx, CIF_SPREADSHEET
	je	haveTypeString
	mov	bp, offset InkTypeString
	cmp	dx, CIF_INK
	je	haveTypeString
	mov	bp, offset GrObjTypeString
	cmp	dx, CIF_GROBJ
	je	haveTypeString
	mov	bp, offset GeodexTypeString
	cmp	dx, CIF_GEODEX
	je	haveTypeString
unsupportedType:
	mov	bp, offset UnsupportedTypeString
haveTypeString:
	GetResourceHandleNS	ScrapStrings, dx	; ^ldx:bp - string
	GetResourceHandleNS	ScrapText, bx	; then set error message
	mov	si, offset ScrapText
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_OPTR
	clr	cx, di
	call	ObjMessage
	stc					; indicate unsupported format
	jmp	done

tifBitmap:
	mov	ss:[currentFormat], CIF_BITMAP
	jmp	bitmapGStringCommon

tifGString:
	mov	ss:[currentFormat], CIF_GRAPHICS_STRING

bitmapGStringCommon:
	GetResourceHandleNS	ScrapText, bx
	mov	si, offset ScrapText
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_DELAYED_VIA_APP_QUEUE
	clr	di
	call	ObjMessage

	GetResourceHandleNS	ScrapGString, bx
	mov	si, offset ScrapGString
	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_DELAYED_VIA_APP_QUEUE
	clr	di
	call	ObjMessage

	mov	ax, MSG_META_GRAB_TARGET_EXCL
	clr	di
	call	ObjMessage
	;
	; if no focus yet, grab it
	;	^lbx:si = ScrapView
	;
	call	GrabFocusIfNone

	call	InvalViewWindow			; clear it (forces redraw)

noError:
	clc					; indicate no error
done:
	ret		; <-- EXIT HERE


SetScrapViewContent	endp

SetTifText	proc	near
	cmp	ss:[currentFormat], CIF_TEXT
	je	alreadyTifText
	mov	ss:[currentFormat], CIF_TEXT
	mov	ss:[gStringWindow], 0
	GetResourceHandleNS	ScrapGString, bx
	mov	si, offset ScrapGString
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_DELAYED_VIA_APP_QUEUE
	mov	di, mask MF_CALL
	call	ObjMessage
	GetResourceHandleNS	ScrapText, bx
	mov	si, offset ScrapText
	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_DELAYED_VIA_APP_QUEUE
	mov	di, mask MF_CALL
	call	ObjMessage
	;
	; set up text object
	;
	call	ClipboardGetClipboardFile
	mov	cx, bx
	GetResourceHandleNS	ScrapText, bx
	mov	si, offset ScrapText
	mov	ax, MSG_VIS_TEXT_SET_VM_FILE
	mov	di, mask MF_CALL
	call	ObjMessage
alreadyTifText:
	;
	; if no focus yet, grab it
	;
	GetResourceHandleNS	ScrapText, bx
	mov	si, offset ScrapText
	call	GrabFocusIfNone
	ret
SetTifText	endp

;
; pass:
;	^lbx:si = object to grab focus if none
;
GrabFocusIfNone	proc	near
	push	bx, si
	GetResourceHandleNS	ScrapBookPrimary, bx
	mov	si, offset ScrapBookPrimary
	mov	ax, MSG_META_GET_FOCUS_EXCL
	mov	di, mask MF_CALL
	call	ObjMessage		; carry set if response, ^lcx:dx
	pop	bx, si			; ^lbx:si = object to grab focus
	jnc	grabFocus		; no response, grab focus
	tst	cx
	jnz	done			; have focus already, leave it
grabFocus:
	mov	ax, MSG_META_GRAB_FOCUS_EXCL
	mov	di, mask MF_CALL
	call	ObjMessage
done:
	ret
GrabFocusIfNone	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScrapBookDelete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	delete current scrap

CALLED BY:	MSG_META_DELETE

PASS:		

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	06/19/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScrapBookDelete	method ScrapBookClass, MSG_META_DELETE
	mov	ax, FALSE		; no copying scrap
	call	DeleteCutCommon		; common handling
	ret
ScrapBookDelete	endm

if HEADER_SIZE_CHECKING
;
; check file size, warning if getting too big
; pass: nothing
; return: carry set to abort operation
;
FileSizeWarning	proc	near
	uses	ax, bx, cx, dx
	.enter
	mov	bx, ss:[currentScrapFile]
	tst	bx
	jz	abortOp			; no file, abort
	call	VMGetHeaderInfo		; cx = byte size
	cmp	cx, ss:[warningSize]
	cmc				; C set if cx < warningSize
	jnc	done			; C clear if ...
	cmp	cx, ss:[errorSize]	; this is just too big
	ja	abortWithError
	tstdw	ss:[currentDoc]
	jz	engineMode
	push	bp
	mov	bp, offset ScrapSizeWarning
	call	ScrapQuery		; ax = IC_
	pop	bp
	cmp	ax, IC_YES
	je	done			; C clear to continue
abortOp:
	stc				; else, abort operation
done:
	.leave
	ret

abortWithError:
	push	bp
	mov	bp, offset ScrapTooBigError
	call	ScrapError
	pop	bp
	jmp	short abortOp

engineMode:
	; if engine mode, just beep and cancel operation
	mov	ax, SST_ERROR
	call	UserStandardSound
	jmp	short abortOp
FileSizeWarning	endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScrapBookCut
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	cut current scrap to clipboard

CALLED BY:	MSG_META_CLIPBOARD_CUT

PASS:		

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	02/27/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScrapBookCut	method	ScrapBookClass, MSG_META_CLIPBOARD_CUT
	mov	ax, TRUE			; copy to scrap
	call	DeleteCutCommon			; common handling
	ret
ScrapBookCut	endm

;
; pass:
;	ax = TRUE to copy current scrap to clipboard
;	ax = FALSE to not copy
;
DeleteCutCommon	proc	near
if HEADER_SIZE_CHECKING
if NO_BACKUP
	; delete won't enlarge header if no backup
else
	call	FileSizeWarning
	jc	exit
endif
endif
	;
	; check if any scraps
	;
	push	ax				; save flag
	call	GetNumScraps			; cx = number of scraps
	pop	ax				; restore flag
	jcxz	exit				; no scraps to delete
	;
	; copy current scrap to system clipboard item, if needed
	;
	cmp	ax, TRUE			; do we need to?
	jne	noCopy				; nope, skip
	call	ScrapBookCopy			; copy text to scrap
noCopy:
	;
	; delete current scrap from scrapbook
	;
	call	DeleteCurrentScrap
	;
	; show the new current scrap
	;
	call	GetNumScraps			; cx = number of scraps
	jcxz	noScrap				; deleted only scrap
	cmp	cx, ss:[currentScrap]		; did we delete last scrap?
	jne	showIt
	dec	ss:[currentScrap]		; yes, show new last scrap
showIt:
	call	ShowCurrentScrap
	jmp	short done

	;
	; delete last scrap
	;
noScrap:
	call	ClearScrapView			; no more scraps, clear view
	call	DisableNoScrapItems		; turn off cut, copy trigger
						; 	and scrap name field
done:
	;
	; reset scrap name list to reflect deleted scrap
	;
	mov	di, mask MF_CALL
	call	ResetScrapNameList
if NO_BACKUP
	;
	; shrink file if needed
	;
	movdw	bxsi, ss:[currentDoc]
	tst	bx				; no delete should occur
						; when in engine mode, anyway
	jz	exit
	mov	ax, MSG_SCRAPBOOK_DOCUMENT_COMPRESS
	mov	di, mask MF_FORCE_QUEUE		; to let name list queries
						; get handled first
	call	ObjMessage
endif
exit:
	ret
DeleteCutCommon	endp

DeleteCurrentScrap	proc	near
	call	ScrapBookLockMap
	call	VMDirty
	mov	bx, bp				; bx = scrapbk map VM mem block
	mov	ds, ax				; ds = scrapbk map block segment
	mov	es, ax
	call	GetCurrentScrapIndexOffset	; ds:si = entry for current
						;	scrap in index block
	mov	ax, ds:[si].SBIE_vmBlock	; bx:ax = scrap VM block for
						;	entry to delete
	push	ax				; save it
	;
	; remove transfer item from map block
	;
	mov	ax, ds:[SBIH_numScraps]
	call	GetThisScrapIndexOffset		; ds:cx = end of current last
	mov	cx, si				;	scrap entry
	push	cx

	call	GetCurrentScrapIndexOffset	; ds:si = current scrap
	mov	di, si				; ds:di = current scrap
	add	si, size ScrapBookIndexEntry	; ds:si = next scrap
	sub	cx, si				; cx = bytes to move
	pop	dx				; dx = current size of index
	push	si, di, cx			; save, in case of error
	rep	movsb				; remove old scrap entry

	xchg	ax, dx				; ax = index size (1 byte inst.)
	sub	ax, size ScrapBookIndexEntry	; ax = new size
	clr	ch				; keep locked
	call	MemReAlloc			; remove space taken by deleted
						;	scrap
	pop	di, si, cx			; retrieve in case of error
						;	di = destination
						;	si = source
	jnc	noMemErr
	;
	; error, restore index block
	;
	add	di, cx				; point at correct places
	dec	di				;	for undo-ing
	add	si, cx
	dec	si
	std					; restore space for deleted
	rep movsb				;	scrap
	cld
	pop	ds:[si+1].SBIE_vmBlock		; restore scrap block handle
	stc					; indicate error
noMemErr:
	jc	noUpdateCount			; if error, don't update count
	mov	ds, ax				; (in case block moved)
	dec	ds:[SBIH_numScraps]		; one less scrap
noUpdateCount:
	call	VMUnlock			; unlock scrapbk map block
						;	(preserves flags)
	jnc	noError				; if no error, continue

	mov	bp, offset NoCutErrorString	; report error after unlocking
	call	ScrapError
	jmp	short done			; if error, don't free scrap
						;	(item already pop'ed)
noError:
	;
	; now that its unhooked, free transfer item
	;
	mov	bx, ss:[currentScrapFile]
	pop	ax				; ax = transfer item to delete
	call	FreeTransferItem		; free it
done:
	ret
DeleteCurrentScrap	endp

;
; pass:
;	bx:ax = transfer item
;
FreeTransferItem	proc	near
	uses	cx, si, di, bp
	.enter
	push	ax
	call	VMLock
	mov	ds, ax
;	test	ds:[CIH_flags], mask TIF_RAW
;	jnz	raw
	mov	si, offset CIH_formats
	mov	cx, ds:[CIH_formatCount]
	push	bp
freeLoop:
	push	cx
	movdw	axbp, ds:[si].CIFI_vmChain
	call	VMFreeVMChain

	pop	cx
	add	si, size ClipboardItemFormatInfo
	loop	freeLoop
	pop	bp
;raw:
	call	VMUnlock
	pop	ax
	call	VMFree
	.leave
	ret
FreeTransferItem	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScrapBookCopyBitmapToGString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the clipboard item only contains one format, and
		that format is a bitmap, then create a gstring in the
		clipboard file as well.

CALLED BY:	ScrapBookCopy

PASS:		dx - clipboard file handle
		es - segment of ClipboardItemHeader

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/31/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CIH_bitmapFormat equ <CIH_formats>
CIH_gstringFormat equ <CIH_formats + size ClipboardItemFormatInfo>

ScrapBookCopyBitmapToGString	proc near
		uses	ax,bx,cx,dx,di,si
		.enter
		
		cmp	es:[CIH_formatCount], 1
		jne	done

		cmp	es:[CIH_bitmapFormat].CIFI_format.CIFID_manufacturer,
				MANUFACTURER_ID_GEOWORKS
		jne	done

		cmp	es:[CIH_bitmapFormat].CIFI_format.CIFID_type,
				CIF_BITMAP
		jne	done
		
		mov	cl, GST_VMEM
		mov	bx, dx			; clipboard file
		call	GrCreateGString
		mov	es:[CIH_gstringFormat].CIFI_vmChain.high,si
		clr	es:[CIH_gstringFormat].CIFI_vmChain.low


		clr	ax, bx				;draw coordinate
		mov	cx, es:[CIH_bitmapFormat].CIFI_vmChain.high
		call	GrDrawHugeBitmap
		call	GrEndGString

		mov	si, di				;gstring handle
		clr	di				;no gstate
		push	dx			; clipboard file
		mov	dl, GSKT_LEAVE_DATA
		call	GrDestroyGString
		pop	bx			; clipboard file
		

		mov	di, es:[CIH_bitmapFormat].CIFI_vmChain.high
		call	GrGetHugeBitmapSize
		mov_tr	cx, ax				;width
		mov	dx, bx				;height
		mov	ax,CIF_GRAPHICS_STRING
		mov	di, size ClipboardItemFormatInfo
		call	ScrapBookInitializeClipboardItemFormatInfo

		inc	es:[CIH_formatCount]
done:
		.leave
		ret
ScrapBookCopyBitmapToGString	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScrapBookCopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	copy current scrap to clipboard

CALLED BY:	MSG_META_CLIPBOARD_COPY

PASS:		

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	02/27/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScrapBookCopy	method	ScrapBookClass, MSG_META_CLIPBOARD_COPY
	uses	ds
	.enter
	call	SaveCurrentScrapName
	call	ScrapBookLockMap
	push	bp
	mov	ds, ax				; ds = segment of index block
	cmp	ds:[SBIH_numScraps], 0		; any scraps?
	LONG je	exit				; nope
	call	GetCurrentScrapIndexOffset	; ds:si = entry for current
						;	scrap in index block
	;
	; create transfer item block from current scrap
	;
	call	ClipboardGetClipboardFile
	mov	dx, bx				; clipboard file
	mov	bx, ss:[currentScrapFile]
	mov	ax, ds:[si].SBIE_vmBlock	; bx:ax = scrap VM block for
						;	current entry
	clr	cx				; preserve user id's
	call	VMCopyVMBlock			; ax = transfer VM block handle
	push	ax				; save transfer VM block handle
	mov	bx, dx				; clipboard file
	call	VMLock				; ax = segment, bp = mem handle
	push	bp				; save transfer item hdr handle
	mov	es, ax				; es = segment of TIH
	;
	; fill in transfer item info
	;	keep CIH_flags, CIH_formatCount
	;
	call	GeodeGetProcessHandle		; bx = our handle
	mov	es:[CIH_owner].handle, bx
	mov	es:[CIH_owner].chunk, 0
	mov	es:[CIH_sourceID].handle, 0	; no associated document
	mov	es:[CIH_sourceID].chunk, 0
	;
	; create mem blocks for each transfer item format block in scrap
	;
	mov	cx, es:[CIH_formatCount]	; cx = number of formats
	mov	di, offset CIH_formats		; es:di = first format
	mov	si, 0				; null-terminate chain
	mov	bx, ss:[currentScrapFile]	; bx = source VM file
formatLoop:
	movdw	axbp, es:[di].CIFI_vmChain	; ax = src scrap VM
						; block handle
	push	cx
	clr	cx				; preserve user id's
	call	VMCopyVMChain			; ax = transfer VM block handle
	pop	cx
	movdw	es:[di].CIFI_vmChain, axbp	; store new scrap VM block han.
	add	di, size ClipboardItemFormatInfo	; move to next format
	loop	formatLoop

	call	ScrapBookCopyBitmapToGString

	pop	bp				; retrieve transfer item
						;	header handle
	push	es:[CIH_flags]			; save transfer flags
	call	VMUnlock			; unlock built-up transfer item
	pop	bp				; bp = transfer flags
	andnf	bp, not (mask CIF_QUICK)	; make sure not quick item
	pop	ax				; ax = VM block handle of
						;	transfer item
	;
	; register newly created transfer item
	;	bp = flags
	;	ax = VM handle
	;
	mov	bx, dx 				; clipboard file
	call	ClipboardRegisterItem		; pass bx:ax, bp
	jnc	exit

	; Not enough disk space

	mov	bp, offset NoCopyErrorString
	call	ScrapError
exit:
	pop	bp				; unlock scrapbook map block
	call	VMUnlock
	.leave
	ret
ScrapBookCopy	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScrapBookPaste
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	paste current system clipboard item into scrapbook, inserts
		new scrap before current scrap

CALLED BY:	MSG_META_CLIPBOARD_PASTE

PASS:		

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	02/28/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScrapBookPaste	method	ScrapBookClass, MSG_META_CLIPBOARD_PASTE
	mov	ax, FALSE			; paste at current scrap
	call	PasteCommon
	ret
ScrapBookPaste	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScrapBookPasteAtEnd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	paste current system clipboard item into scrapbook, inserts
		new scrap at end of scrapbook

CALLED BY:	MSG_SCRAPBOOK_PASTE_AT_END

PASS:		

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	06/19/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScrapBookPasteAtEnd	method	ScrapBookClass, MSG_SCRAPBOOK_PASTE_AT_END
	mov	ax, TRUE			; paste at end
	call	PasteCommon
	ret
ScrapBookPasteAtEnd	endm

;
; ax = TRUE to paste at end
; ax = FALSE to paste BEFORE current scrap
;
PasteCommon	proc	near
if HEADER_SIZE_CHECKING
	call	FileSizeWarning
	LONG jc	exit
endif
	push	ax				; save paste flag
	tst	ss:[currentDoc].handle
	jz	engineMode
	call	SaveCurrentScrapName
engineMode:
	;
	; get current transfer item
	;
	clr	bp				; get normal item
	call	ClipboardQueryItem		; bx:ax = transfer item
						;	VM file/block handle
						; bp = number of formats
	pop	di				; retreive paste flag
	tst	bp				; check number of formats
	LONG jz	exit				; no transfer item, exit
	tst	ss:[currentScrapFile]
	LONG jz exit				; no file, exit
	push	bx, ax				; save header block

	mov	dx, ss:[currentScrapFile]	; copy to scrap file
	clr	cx				; preserve user id's
	call	VMCopyVMBlock			; ax = scrap VM block
	push	ax				; save scrap VM block handle
	push	di				; save paste flag
	push	bx				; save transfer item VM file
	mov	bx, ss:[currentScrapFile]
	call	VMLock				; lock scrap VM block
	pop	bx				; bx = transfer item VM file
	mov	es, ax				; es = VM transfer item
	push	bp				; save mem handle
	mov	di, offset CIH_formats		; *es:di = formats
	mov	cx, es:[CIH_formatCount]	; cx = number of formats
	mov	si, 0				; null-term. chain of VM blocks
	mov	dx, ss:[currentScrapFile]	; copy to scrap file
formatLoop:
	movdw	axbp, es:[di].CIFI_vmChain	; bx:ax = transfer VM data block
	push	cx
	clr	cx				; preserve user id's
	call	VMCopyVMChain			; ax = new scrap VM data block
	pop	cx
	movdw	es:[di].CIFI_vmChain, axbp	; store new scrap VM block han.
	cmp	es:[di].CIFI_format.CIFID_type, CIF_TEXT
	jne	notText
	cmp	es:[di].CIFI_format.CIFID_manufacturer, MANUFACTURER_ID_GEOWORKS
	jne	notText
	movdw	ss:[pastedTextFormat], axbp	; store text format for
						; PASTE_APPEND_TO_FILE
notText:
	add	di, size ClipboardItemFormatInfo	; move to next format
	loop	formatLoop			; loop to do all formats
	pop	bp
	call	VMDirty
	call	VMUnlock			; unlock scrap VM block
	;
	; add transfer item to map block
	;
	pop	bp				; bp = paste flag
	pop	ax				; ax = item VM block handle
	call	AddItemToMapBlock
	;
	; finish with transfer item
	;
	pop	bx, ax
	pushf					; save error status
	call	ClipboardDoneWithItem
	popf					; retrieve error status
	call	PostPaste			; handle error, clean-up
exit:
	ret
PasteCommon	endp

SendEnableMessage	proc	near
	mov	ax, MSG_GEN_SET_ENABLED
	call	SendAbleMessage
	ret
SendEnableMessage	endp

;
; pass:
;	ax = VM block handle of new transfer item
;	bp = TRUE to paste at end
;	bp = FALSE to paste before current scrap
; return:
;	carry clear if ok
;	carry set if error
;
AddItemToMapBlock	proc	near
	push	ax				; save VM block handle
	push	bp				; save paste flag
	call	ScrapBookLockMap
	call	VMDirty
	mov	ds, ax				; ds = scrapbk map block segment
	mov	bx, bp				; bx = scrapbk map VM mem block
	mov	ax, ds:[SBIH_numScraps]
	mov	cx, size ScrapBookIndexEntry
	mul	cx
	add	ax, size ScrapBookIndexHeader	; ax = current size
	add	ax, size ScrapBookIndexEntry	; ax = new size
	clr	ch				; keep locked
	call	MemReAlloc			; make space for new entry
	jnc	noMemErr			; if no error, continue
	;
	; handle error adding scrap to index block
	;	(index block unchanged, we hope)
	;
	pop	ax				; throw away paste flag
	pop	ax				; retrieve scrap block
	mov	bx, ss:[currentScrapFile]
	call	FreeTransferItem		; free the scrap as it was
						;	not added to index
	stc					; indicate error
	jmp	short afterErr

noMemErr:
	mov	ds, ax				; ds = es = map block segment
	mov	es, ax
	mov	ax, ds:[SBIH_numScraps]		; ds:si = position of new
	call	GetThisScrapIndexOffset		;		last scrap
	pop	ax				; retrieve paste flag
	cmp	ax, TRUE			; paste at end?
	je	haveNewScrapEntry		; yes, do it
EC <	cmp	ax, FALSE						>
EC <	ERROR_NZ	0						>
	dec	si				; ds:si = end of current last
						;	scrap entry
	mov	di, si
	add	di, size ScrapBookIndexEntry	; es:di = end of new last entry
	mov	cx, ds:[SBIH_numScraps]		; cx = number of scrap
	sub	cx, ss:[currentScrap]		; cx = num scraps to move
	mov	ax, size ScrapBookIndexEntry
	mul	cx
	mov	cx, ax				; cx = # bytes to move
	std
	rep movsb				; make room for new entry
	cld
	call	GetCurrentScrapIndexOffset	; ds:si = new scrap's entry
haveNewScrapEntry:
	inc	ds:[SBIH_numScraps]		; one more scrap
	pop	ax
	mov	ds:[si].SBIE_vmBlock, ax	; store VM block handle
	clr	ax				; clears carry (no error)
	mov	ds:[si].SBIE_extra1, ax		; zero extra data for now
	mov	ds:[si].SBIE_extra2, ax		; zero extra data for now
afterErr:
	call	VMUnlock			; unlock scrapbk map block
						;	(preserves flags)
	ret
AddItemToMapBlock	endp

;
; pass:
;	carry clear if no error
;	carry set if error adding scrap
; return:
;	nothing
PostPaste	proc	near
	jnc	noError				; if no error, continue

	mov	bp, offset NoPasteErrorString	; report error
	call	ScrapError
	jmp	exit				; if error, not pasted, so no
						;	need to update
noError:
;
;	We are now asynchronous update - to shrink the window in which the
;	document on disk is in an inconsistent state, we do an autosave after
;	each paste... (9/13/93 - atw)
;

	mov	ax, MSG_GEN_DOCUMENT_AUTO_SAVE
	movdw	bxsi, ss:[currentDoc]
	tst	bx
	jz	exit				; that's all for engine mode
	clr	di
	call	ObjMessage
	
	;
	; display newly pasted in scrap
	;
	call	ShowCurrentScrap
	;
	; reset scrap name list
	;
	mov	di, mask MF_CALL
	call	ResetScrapNameList
	;
	; be sure scrap name entry is enabled
	;
	GetResourceHandleNS	ScrapName, bx
	mov	si, offset ScrapName
	call	SendEnableMessage
	GetResourceHandleNS	DeleteTrigger, bx
	mov	si, offset DeleteTrigger
	call	SendEnableMessage
	GetResourceHandleNS	CutTrigger, bx
	mov	si, offset CutTrigger
	call	SendEnableMessage
	GetResourceHandleNS	CopyTrigger, bx
	mov	si, offset CopyTrigger
	call	SendEnableMessage
	GetResourceHandleNS	ScrapNameControlShow, bx
	mov	si, offset ScrapNameControlShow
	call	SendEnableMessage
;  
;	ScrapPrevious and ScrapNext are set in ShowCurrentScrap so that
;	they will be disabled if there is no previous/next scrap.  
;	Don't enable them here!		-- jwu 11/3/93
;
;	GetResourceHandleNS	ScrapPrevious, bx
;	mov	si, offset ScrapPrevious
;	call	SendEnableMessage
;	GetResourceHandleNS	ScrapNext, bx
;	mov	si, offset ScrapNext
;	call	SendEnableMessage

exit:
	ret
PostPaste	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScrapBookPasteAppendToFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Paste scrap to end of specified file

CALLED BY:	MSG_SCRAPBOOK_PASTE_APPEND_TO_FILE

PASS:		cx = block containing:
			FileLongName
			DiskHandle
			PathName

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	09/30/99	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScrapBookPasteAppendToFile	method	ScrapBookClass, MSG_SCRAPBOOK_PASTE_APPEND_TO_FILE
if HEADER_SIZE_CHECKING
	;
	; make sure we have limits set
	;
	push	ax, cx, dx, si
	mov	cx, ds
	mov	si, offset scrapMaxCat
	mov	dx, offset warningSizeKey
	mov	ax, HEADER_WARNING_SIZE	; default warning level (16K)
	call	InitFileReadInteger
	mov	ss:[warningSize], ax
	mov	dx, offset errorSizeKey
	mov	ax, HEADER_ERROR_SIZE	; default error level (50K)
	call	InitFileReadInteger
	mov	ss:[errorSize], ax
	pop	ax, cx, dx, si
endif
	;
	; if specified file is currently opened, just paste at end
	;
	sub	sp, size DocumentCommonParams
	mov	bp, sp
	mov	bx, cx
	push	ds
	call	MemLock
	mov	ds, ax
	clr	si
	segmov	es, ss
	mov	di, bp
	mov	cx, size FileLongName + size word + size PathName
	rep	movsb
	call	MemUnlock
	pop	ds
	mov	ss:[bp].DCP_docAttrs, 0
	mov	ss:[bp].DCP_flags, 0
	mov	ss:[bp].DCP_connection, 0
	mov	dx, size DocumentCommonParams
	push	bx
	GetResourceHandleNS	ScrapAppDocControl, bx
	mov	si, offset ScrapAppDocControl
	mov	ax, MSG_GEN_DOCUMENT_GROUP_SEARCH_FOR_DOC
	mov	di, mask MF_CALL or mask MF_STACK
	push	bp
	call	ObjMessage
	pop	bp
	pop	bx				; bx = file info block
	lea	sp, ss:[bp][size DocumentCommonParams]	; (preserves flags)
	jnc	notOpen
	call	MemFree				; free file info block
	call	ScrapBookPasteAtEnd
	jmp	exit

notOpen:
	;
	; save current document, if any
	;
	push	ss:[currentScrapFile]
	pushdw	ss:[currentDoc]
	;
	; open or create passed file
	;
	call	FilePushDir
	push	bx				; save file info block
	push	ds
	call	MemLock
	mov	ds, ax
	mov	dx, size FileLongName + size word	; ds:dx = path
	mov	bx, ds:[(size FileLongName)]		; bx = disk handle
	call	FileSetCurrentPath
	jc	noFilePop
	mov	dx, 0				; ds:dx = filename
	mov	ah, VMO_CREATE
	mov	al, 0				; access flags
	clr	cx				; default VM compression
	call	VMOpen
noFilePop:
	pop	ds
	jc	noFile
	mov	ss:[currentScrapFile], bx
	clrdw	ss:[currentDoc]
	cmp	ax, VM_CREATE_OK
	jne	opened
	call	SetFileAttrs
	mov	bp, bx				; bp = VM file handle
	clr	cx, dx				; indicate engine mode
	call	ScrapBookDocOutputInitializeDocumentFile
opened:
	;
	; paste at end
	;
	movdw	ss:[pastedTextFormat], 0
	mov	ax, TRUE
	call	PasteCommon			; handles engine mode
	;
	; fix up stuff in the text format
	;
	tstdw	ss:[pastedTextFormat]
	jz	noFixup
	call	FixupTextFormat
noFixup:
	;
	; save and close file
	;
	mov	bx, ss:[currentScrapFile]
	call	VMSave				; ignore error?
	mov	al, 0
	call	VMClose				; ignore error?
noFile:
	pop	bx				; free file info block
	call	MemFree
	call	FilePopDir
	;
	; restore current document
	;
	popdw	ss:[currentDoc]
	pop	ss:[currentScrapFile]
exit:
	ret
ScrapBookPasteAppendToFile	endm

;
; this is taken from SPUI to set up initial VM-based document file
;

OLDocExtAttrs	struct		; extended attributes we set for a new file
    OLDEA_protocol	ProtocolNumber
    OLDEA_release	ReleaseNumber
    OLDEA_token		GeodeToken
    OLDEA_creator	GeodeToken
OLDocExtAttrs	ends

SetFileAttrs	proc	near
	push	bx
	mov	ax, MSG_GEN_DOCUMENT_GROUP_GET_PROTOCOL
	GetResourceHandleNS	ScrapAppDocControl, bx
	mov	si, offset ScrapAppDocControl
	mov	di, mask MF_CALL
	call	ObjMessage			;cx, dx = protocol
	pop	bx
	
	sub	sp, size OLDocExtAttrs
	mov	bp, sp				;ss:bp <- buffer for new
						; attrs
	mov	ss:[bp].OLDEA_protocol.PN_major, cx
	mov	ss:[bp].OLDEA_protocol.PN_minor, dx

	segmov	es, ss
	push	bx				;save VM file handle

	; get release # of application

	clr	bx
	lea	di, ss:[bp].OLDEA_release
	mov	ax, GGIT_GEODE_RELEASE
	call	GeodeGetInfo

	; get the token and creator

	mov	cx, es
	lea	dx, ss:[bp].OLDEA_token
	mov	ax, MSG_GEN_DOCUMENT_GROUP_GET_TOKEN
	push	bp
	GetResourceHandleNS	ScrapAppDocControl, bx
	mov	si, offset ScrapAppDocControl
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	bp

	lea	dx, ss:[bp].OLDEA_creator
	mov	ax, MSG_GEN_DOCUMENT_GROUP_GET_CREATOR
	push	bp
	GetResourceHandleNS	ScrapAppDocControl, bx
	mov	si, offset ScrapAppDocControl
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	bp

	pop	bx				; bx <- file handle

	;
	; Now set up the array of extended attribute descriptors for the
	; actual setting.
	; 
	sub	sp, 4 * size FileExtAttrDesc
	mov	di, bp
	mov	bp, sp
	
	mov	ss:[bp][0*FileExtAttrDesc].FEAD_attr, FEA_PROTOCOL
	mov	ss:[bp][0*FileExtAttrDesc].FEAD_value.segment, ss
	lea	ax, ss:[di].OLDEA_protocol
	mov	ss:[bp][0*FileExtAttrDesc].FEAD_value.offset, ax
	mov	ss:[bp][0*FileExtAttrDesc].FEAD_size, size OLDEA_protocol

	mov	ss:[bp][1*FileExtAttrDesc].FEAD_attr, FEA_RELEASE
	mov	ss:[bp][1*FileExtAttrDesc].FEAD_value.segment, ss
	lea	ax, ss:[di].OLDEA_release
	mov	ss:[bp][1*FileExtAttrDesc].FEAD_value.offset, ax
	mov	ss:[bp][1*FileExtAttrDesc].FEAD_size, size OLDEA_release

	mov	ss:[bp][2*FileExtAttrDesc].FEAD_attr, FEA_TOKEN
	mov	ss:[bp][2*FileExtAttrDesc].FEAD_value.segment, ss
	lea	ax, ss:[di].OLDEA_token
	mov	ss:[bp][2*FileExtAttrDesc].FEAD_value.offset, ax
	mov	ss:[bp][2*FileExtAttrDesc].FEAD_size, size OLDEA_token

	mov	ss:[bp][3*FileExtAttrDesc].FEAD_attr, FEA_CREATOR
	mov	ss:[bp][3*FileExtAttrDesc].FEAD_value.segment, ss
	lea	ax, ss:[di].OLDEA_creator
	mov	ss:[bp][3*FileExtAttrDesc].FEAD_value.offset, ax
	mov	ss:[bp][3*FileExtAttrDesc].FEAD_size, size OLDEA_creator

	;
	; Finally, set the attributes for the file.
	; 
	mov	cx, 4
	mov	di, bp
	mov	ax, FEA_MULTIPLE
	call	FileSetHandleExtAttributes

	;
	; Clear the stack of the descriptors and the attributes themselves.
	; 
	add	sp, 4*size FileExtAttrDesc + size OLDocExtAttrs
	ret
SetFileAttrs	endp

;
; this is taken from text object to fix up copied text transfer item
;

FixupTextFormat	proc	near

	; lock the header block

	mov	ax, ss:[pastedTextFormat].high	; VM block
	mov	bx, ss:[currentScrapFile]	; VM file
	call	VMLock				;ax = segment, bp = handle
	mov	es, ax				;es <- seg addr of transfer.

	; We have to take care of a slight problem here.  The various run
	; arrays contain the VM block handle of the corresponding elements
	; in their huge array header.  Unfortunately this VM block handle
	; could be wrong, since VMCopyVMChain could have been used to copy
	; the transfer item.  We need to go into each run array and fix
	; the element block if needed.

	mov	di, es:[TTBH_charAttrRuns].high
	mov	cx, es:[TTBH_charAttrElements].high
	call	fixElementVMBlock
	mov	di, es:[TTBH_paraAttrRuns].high
	mov	cx, es:[TTBH_paraAttrElements].high
	call	fixElementVMBlock
	mov	di, es:[TTBH_typeRuns].high
	mov	cx, es:[TTBH_typeElements].high
	call	fixElementVMBlock
	mov	di, es:[TTBH_graphicRuns].high
	mov	cx, es:[TTBH_graphicElements].high
	call	fixElementVMBlock

	; The problem, sad to say, is worse than that described above.  The
	; graphics element array also contains references to VM blocks that
	; are likely out of date.  We must fix them up also

	mov	ax, es:[TTBH_graphicElements].high
	mov	di, size TextTransferBlockHeader
	call	TT_RelocateGraphics

	call	VMUnlock
	ret

;---

	; di = runs, cx = elements, bx = file

fixElementVMBlock:
	push	ds
	tst	di
	jz	fixDone
	call	HugeArrayLockDir
	mov	ds, ax
	cmp	cx, ds:[TLRAH_elementVMBlock]
	jz	fixUnlock
	mov	ds:[TLRAH_elementVMBlock], cx
	call	HugeArrayDirty
fixUnlock:
	call	HugeArrayUnlockDir
fixDone:
	pop	ds
	retn

FixupTextFormat	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	TT_RelocateGraphics

DESCRIPTION:	Relocate graphics in a run array after they have been possibly
		mangled

CALLED BY:	INTERNAL

PASS:
	ax - VM block containing graphics element array
	bx - VM file
	es:di - array of dwords of correct VM trees

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/29/92		Initial version

------------------------------------------------------------------------------@
TT_RelocateGraphics	proc	near	uses ax, cx, dx, si, di, bp, ds
	.enter

	tst	ax
	jz	exit
	call	VMLock
	mov	ds, ax
	mov	si, VM_ELEMENT_ARRAY_CHUNK	;*ds:si = element array

	mov	si, ds:[si]
	mov	cx, ds:[si].CAH_count
	jcxz	done
	mov	dx, ds:[si].CAH_elementSize
	add	si, ds:[si].CAH_offset
relocateLoop:
	cmp	ds:[si].REH_refCount.WAAH_high, EA_FREE_ELEMENT
	jz	next

	tstdw	ds:[si].VTG_vmChain		;does it have a vmChain?
;;
;; Don't jump to next, as that will skip the incrementing of the ptr 
;; into the fix-up table, and skipping an element in the fix-up table
;; means that the wrong values will be stored in the VisTextGraphic 
;; element's vmChain field from this element on.  (cassie - 7/94)
;;
;;	jz	next
	jz	afterCopy			 ;no, don't do the fix up
	cmpdw	ds:[si].VTG_vmChain, es:[di], ax ;has the value changed?
	jz	afterCopy			 ;no, don't need to do fix up
	movdw	ds:[si].VTG_vmChain, es:[di], ax ;do the fix up
	call	VMDirty			
afterCopy:
	add	di, size dword			 ;point to next fix up VMChain
next:
	add	si, dx				 ;point to next graphic element
	loop	relocateLoop

done:
	call	VMUnlock

exit:
	.leave
	ret

TT_RelocateGraphics	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScrapBookImport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Import into current page

CALLED BY:	MSG_SCRAPBOOK_IMPORT

PASS:		ss:bp = ImpexTranslationParams

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	07/21/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScrapBookImport	method	ScrapBookClass, MSG_SCRAPBOOK_IMPORT

	call	SaveCurrentScrapName		; in case current name modified
if HEADER_SIZE_CHECKING
	call	FileSizeWarning
	jc	exit
endif

	test	ss:[bp].ITP_dataClass, mask IDC_TEXT or mask IDC_GRAPHICS
EC <	ERROR_Z	0							>

	mov	ax, MSG_GEN_APPLICATION_MARK_BUSY
	call	CallApp

	call	ScrapBookCreateAndInitClipboardItemHeader

	cmp	ss:[bp].ITP_clipboardFormat,CIF_GRAPHICS_STRING
	je	itsAGString

	cmp	ss:[bp].ITP_clipboardFormat,CIF_BITMAP
	je	itsBitmap
	
	clr	di					;first CIFI
	call	ScrapBookCreateTextClipboardItemFormatInfo

unlockHeader:
	;
	; unlock transfer item header
	;
	push	bp				; ImpexTranslationParams
	mov	bp, cx				; VM block mem handle
	call	VMUnlock
	pop	bp				; ImpexTranslationParams

	; we're finished with the impex data structure now, so let it know
	;
	call	ImpexImportExportCompleted
	;
	; add new transfer item to datafile map block, effectively putting it
	; into our datafile
	;
	mov	bp, FALSE			; add before current scrap
	call	AddItemToMapBlock		; (returns error, if any)

	call	PostPaste			; handle error, clean-up

	mov	ax, MSG_GEN_APPLICATION_MARK_NOT_BUSY
	call	CallApp
exit:
	ret

itsBitmap:
	;    This guy creates two ClipboardItemFormatInfos 
	;

	clr	di					;1st and 2nd CIFIs
	call	ScrapBookCreateBitmapClipboardItemFormatInfo
	jmp	unlockHeader

itsAGString:
	clr	di					;first CIFI
	call	ScrapBookCreateGStringClipboardItemFormatInfo
	jmp	unlockHeader


ScrapBookImport	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScrapBookTogglePageList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Toggle the page list

CALLED BY:	

PASS:		

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	07/21/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScrapBookTogglePageList	method	ScrapBookClass, MSG_SCRAPBOOK_TOGGLE_PAGE_LIST
	uses	ax, bx, cx, dx, di, si, bp
	.enter

	GetResourceHandleNS	ViewPageToggle, bx
	mov	si, offset ViewPageToggle
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, mask MF_CALL
	call	ObjMessage
	jc	noneSelected

	call	HidePageListToTrigger
	jmp	done
noneSelected:
	call	ShowPageListOnScreen
done:
	.leave
	ret
ScrapBookTogglePageList endm

ScrapBookSetSelection	method	ScrapBookClass, MSG_SCRAPBOOK_SET_SELECTION
	uses	ax, bx, cx, dx, bp
	.enter
	call	SaveCurrentScrapName
	mov	bx, ss:[currentScrapFile]
	tst	bx
	jz	done
	call	VMGetMapBlock			; ax = map block
	call	VMLock				; lock map block
	push	bp
	mov	ds, ax				; ds = map block segment
EC <	cmp	ds:[SBIH_numScraps], 0		; any scraps? 	>
EC <	je	exit				; nope		>

	mov	ss:[currentScrap], cx		; store new current scrap
exit::
	pop	bp				; unlock map block
	call	VMUnlock
	call	ShowCurrentScrap		; show new current scrap
done:
	.leave
	ret
ScrapBookSetSelection endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScrapBookTogglePageList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy the currently visible clip art to either the clip
                board or the caller application.

CALLED BY:	

PASS:		

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	edwin	01/12/99	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScrapBookSendPaste	method	ScrapBookClass, MSG_SCRAPBOOK_SEND_PASTE
	uses	ax, bx, cx, dx, bp, di, si
	.enter

	call	GeodeGetProcessHandle
	clr	si
	mov	ax, MSG_META_CLIPBOARD_COPY
	mov	di, mask MF_CALL
	call	ObjMessage
		
	tst	ss:[callerAppName]
	jz	copyToClipboard
	;
	;  Copy the clip art to the parent application.
	;
	segmov	es, ss
	mov	di, offset callerAppName
	mov	ax, (GEODE_NAME_SIZE + GEODE_NAME_EXT_SIZE)
	clrdw	cxdx
	call	GeodeFind		; return bx - handle of GEODE
	jnc	done
	call	GeodeGetAppObject

	push	bx, si
	clr	bx, si
	mov	ax, MSG_META_CLIPBOARD_PASTE
	mov	di, mask MF_RECORD
	call	ObjMessage			; di = handle of msg to send
	mov	bx, di
	mov	ax, handle ui
	call	HandleModifyOwner		; make it stays around
	pop	bx, si

	mov	cx, di
	mov	ax, MSG_META_SEND_CLASSED_EVENT
	mov	dx, TO_TARGET
	mov	di, mask MF_CALL
	call	ObjMessage

	mov	ax, MSG_META_QUIT
	call	CallApp

copyToClipboard:
done:
	.leave
	ret
ScrapBookSendPaste endm
		
		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScrapBookCreateAndInitClipboardItemHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create vm block to hold ClipboardItemHeader
		and initialize the header

CALLED BY:	INTERNAL
		ScrapBookImport

PASS:		
		nothing

RETURN:		
		ax - vm block handle of header
		cx - vm mem handle of header
		es - segment of header
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	3/10/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScrapBookCreateAndInitClipboardItemHeader		proc	near
	uses	bx,bp,si,ds,di
	.enter

	;
	; create transfer item header in our datafile
	;
	mov	bx, ss:[currentScrapFile]
	clr	ax				; user ID
	mov	cx, size ClipboardItemHeader
	call	VMAlloc				;
	push	ax				; vm block handle
	call	VMLock				
	push	bp				; vm mem handle
	mov	es, ax
	;
	; zero some fields
	;
	clr	ax
	mov	es:[CIH_owner].handle, ax
	mov	es:[CIH_owner].chunk, ax
	mov	es:[CIH_flags], ax
	mov	es:[CIH_sourceID].handle, ax
	mov	es:[CIH_sourceID].chunk, ax
	mov	es:[CIH_reserved].high, ax
	mov	es:[CIH_reserved].low, ax
	mov	es:[CIH_formatCount],ax
	;
	; store scrap name
	;
	mov	di, offset CIH_name
	mov	cx, length CIH_name
	GetResourceHandleNS	ScrapStrings, bx
	call	MemLock		; ax = string segment
	mov	ds, ax
	mov	si, offset DefaultScrapName
	mov	si, ds:[si]
	LocalCopyNString
	call	MemUnlock

	pop	cx				;vm mem handle
	pop	ax				;vm block handle

	.leave
	ret
ScrapBookCreateAndInitClipboardItemHeader		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScrapBookInitializeClipboardItemFormatInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the data in a ClipboardItemFormatInfo

CALLED BY:	INTERNAL
		ScrapBookImport

PASS:		es - segment of ClipboardItemHeader
		di - offset of ClipboardItemFormatInfo to initalize
		cx - extra1
		dx - extra2
		ax - type (ie CIF_TEXT)

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	3/10/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScrapBookInitializeClipboardItemFormatInfo		proc	near
	uses	cx
	.enter

	mov	es:[CIH_formats][di][CIFI_extra1], cx	
	mov	es:[CIH_formats][di][CIFI_extra2], dx

	clr	cl
	mov	es:[CIH_formats][di][CIFI_renderer].GT_chars[0], cl
	mov	es:[CIH_formats][di][CIFI_renderer].GT_chars[1], cl
	mov	es:[CIH_formats][di][CIFI_renderer].GT_chars[2], cl
	mov	es:[CIH_formats][di][CIFI_renderer].GT_chars[3], cl

	mov	es:[CIH_formats][di][CIFI_format].CIFID_manufacturer, \
						MANUFACTURER_ID_GEOWORKS
	mov	es:[CIH_formats][di][CIFI_format].CIFID_type,ax

	.leave
	ret
ScrapBookInitializeClipboardItemFormatInfo		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScrapBookCopyChainToClipboardItemFormatInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy VMChain scrapbooks vm file

CALLED BY:	INTERNAL
		ScrapBookImport

PASS:		es - segment of ClipboardItemHeader
		di - offset of ClipboardItemFormatInfo to initalize
		bx - vm file
		ax:cx - vm chain

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	3/10/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScrapBookCopyChainToClipboardItemFormatInfo		proc	near
	uses	dx,bp
	.enter

	mov	bp,cx				; low word of vm chain
	mov	dx, ss:[currentScrapFile]	; destination vm file handle
	call	VMCopyVMChain			; 
	movdw	es:[CIH_formats][di][CIFI_vmChain], axbp; dest vm chain

	.leave
	ret
ScrapBookCopyChainToClipboardItemFormatInfo		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScrapBookCreateTextClipboardItemFormatInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fills out the ClipboardItemFormatInfo for a text
		scrap. 

CALLED BY:	INTERNAL
		ScrapBookImport

PASS:		ss:bp - ImpexTranslationParams
			must be CIF_TEXT
		es - segment of ClipboardItemHeader
		di - offset to CIFI to use in header

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	3/10/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScrapBookCreateTextClipboardItemFormatInfo		proc	near
	uses	ax,bx,cx,dx
	.enter

	clr	cx,dx				;extra data
	mov	ax,CIF_TEXT
	call	ScrapBookInitializeClipboardItemFormatInfo
	mov	bx,ss:[bp].ITP_transferVMFile
	movdw	axcx,ss:[bp].ITP_transferVMChain
	call	ScrapBookCopyChainToClipboardItemFormatInfo
	inc	es:[CIH_formatCount]

	.leave
	ret
ScrapBookCreateTextClipboardItemFormatInfo		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScrapBookCreateGStringClipboardItemFormatInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fills out the ClipboardItemFormatInfo for a gstring
		scrap. 

CALLED BY:	INTERNAL
		ScrapBookImport

PASS:		ss:bp - ImpexTranslationParams
			must be CIF_GRAPHICS_STRING
		es - segment of ClipboardItemHeader
		di - offset to CIFI to use in header

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	3/10/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScrapBookCreateGStringClipboardItemFormatInfo		proc	near
	uses	ax,bx,cx,dx,di,si
	.enter

	push	di				;ClipboardItemFormat offset
	mov	bx,ss:[bp].ITP_transferVMFile
	mov	si,ss:[bp].ITP_transferVMChain.high
	mov	cx,GST_VMEM
	call	GrLoadGString
	clr	di,dx				;no gstate, no flags
	call	GrGetGStringBounds
	sub	cx,ax				;width
	sub	dx,bx				;height
	pop	di				;ClipboardItemFormat offset
	mov	ax,CIF_GRAPHICS_STRING
	call	ScrapBookInitializeClipboardItemFormatInfo

	mov	bx,ss:[bp].ITP_transferVMFile
	movdw	axcx,ss:[bp].ITP_transferVMChain
	call	ScrapBookCopyChainToClipboardItemFormatInfo
	inc	es:[CIH_formatCount]

	clr	di				;no gstate
	mov	dl,GSKT_LEAVE_DATA
	call	GrDestroyGString

	.leave
	ret
ScrapBookCreateGStringClipboardItemFormatInfo		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScrapBookCreateBitmapClipboardItemFormatInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Currently the scrapbook doesn't display bitmap format
		stuff. So if we get a bitmap import create a gstring
		scrap also so the scrapbook can display something.
		This functionality may still be useful once the
		scrapbook can display bitmaps.

		Since this creates to ClipboardItemFormatInfo structures
		the first is created at the passed offset and the
		second one is create at the offset after the passed one.

CALLED BY:	INTERNAL
		ScrapBookImport

PASS:		ss:bp - ImpexTranslationParams
		es - segment of ClipboardItemHeader
		di - offset to first CIFI to use in header
		     
RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	3/10/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScrapBookCreateBitmapClipboardItemFormatInfo		proc	near
	uses	ax,bx,cx,dx,di,si
	.enter

	clr	cx,dx				;extra data
	mov	ax,CIF_BITMAP
	call	ScrapBookInitializeClipboardItemFormatInfo
	mov	bx,ss:[bp].ITP_transferVMFile
	movdw	axcx,ss:[bp].ITP_transferVMChain
	call	ScrapBookCopyChainToClipboardItemFormatInfo
	inc	es:[CIH_formatCount]

	.leave
	ret
ScrapBookCreateBitmapClipboardItemFormatInfo		endp



;
; Pass:
;	nothing
; Returns:
;	si - offset to index entry for current scrap
; Destroys:
;	nothing
GetCurrentScrapIndexOffset	proc	near
	uses	ax
	.enter
	mov	ax, ss:[currentScrap]
	call	GetThisScrapIndexOffset
	.leave
	ret
GetCurrentScrapIndexOffset	endp

;
; Pass:
;	ax - scrap entry to get offset for
; Returns:
;	si - offset to index entry for this scrap
; Destroys:
;	nothing
GetThisScrapIndexOffset	proc	near
	uses	cx, dx
	.enter
	mov	cx, size ScrapBookIndexEntry
	mul	cx				; ax = offset to current entry
	mov	si, ax
	add	si, size ScrapBookIndexHeader
	.leave
	ret
GetThisScrapIndexOffset	endp

ScrapError	proc	near
	uses	ax, bx, di, es, bp
	.enter
	GetResourceHandleNS	ScrapStrings, bx
	call	MemLock		; ax = string segment
	mov	es, ax
	mov	ax, es:[bp]			; es:ax - error string
	sub	sp, size StandardDialogParams
	mov	bp, sp
	mov	ss:[bp].SDP_customFlags, \
			(CDT_ERROR shl offset CDBF_DIALOG_TYPE) or \
			(GIT_NOTIFICATION shl offset CDBF_INTERACTION_TYPE)
	mov	ss:[bp].SDP_customString.high, es
	mov	ss:[bp].SDP_customString.low, ax
	clr	ss:[bp].SDP_helpContext.segment
	call	UserStandardDialog
	call	MemUnlock			; unlock string resource
	.leave
	ret
ScrapError	endp

if HEADER_SIZE_CHECKING
ScrapQuery	proc	near
	uses	bx, di, es, bp
	.enter
	GetResourceHandleNS	ScrapStrings, bx
	call	MemLock		; ax = string segment
	mov	es, ax
	mov	ax, es:[bp]			; es:ax - error string
	sub	sp, size StandardDialogParams
	mov	bp, sp
	mov	ss:[bp].SDP_customFlags, \
			(CDT_WARNING shl offset CDBF_DIALOG_TYPE) or \
			(GIT_AFFIRMATION shl offset CDBF_INTERACTION_TYPE)
	mov	ss:[bp].SDP_customString.high, es
	mov	ss:[bp].SDP_customString.low, ax
	clr	ss:[bp].SDP_helpContext.segment
	call	UserStandardDialog
	call	MemUnlock			; unlock string resource
	.leave
	ret
ScrapQuery	endp
endif

CallApp	proc	near
	uses	ax, cx, dx, bp, bx, si, di
	.enter
	GetResourceHandleNS	ScrapBookApp, bx
	mov	si, offset ScrapBookApp
	mov	di, mask MF_CALL
	call	ObjMessage
	.leave
	ret
CallApp	endp


ShowPageListOnScreen proc far
params		local	AddVarDataParams
sizeArg		local	CompSizeHintArgs
	.enter
	push	bp
	;
	;  Set the "GO TO PAGE..." trigger usble
	;
	GetResourceHandleNS	ScrapNameBoxTrigger, bx
	mov	si, offset ScrapNameBoxTrigger
	clr	dx
	mov	dl, VUM_NOW	
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	di, mask MF_CALL
	call	ObjMessage
	;
	;  Set the NEXT and PREVIOUS button usable
	;
	GetResourceHandleNS	ScrapPreviousAndNext, bx
	mov	si, offset ScrapPreviousAndNext
	clr	dx
	mov	dl, VUM_NOW	
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	di, mask MF_CALL
	call	ObjMessage
	;
	;  Set the GenDynamic List not usable
	;
	GetResourceHandleNS	ScrapNameList, bx
	mov	si, offset ScrapNameList
	clr	dx
	mov	dl, VUM_NOW	
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	di, mask MF_CALL
	call	ObjMessage
	;
	;  Remove the GenDynamic list from a dialog box
	;
	GetResourceHandleNS	ScrapNameBox, bx
	mov	si, offset ScrapNameBox
	GetResourceHandleNS	ScrapNameList, cx
	mov	dx, offset ScrapNameList
	mov	ax, MSG_GEN_REMOVE_CHILD
	mov	bp, mask CCF_MARK_DIRTY
	call	ObjMessage

	;
	;  Add the GenDynamic list to a different parent
	;
	GetResourceHandleNS	ScrapBody, bx
	mov	si, offset ScrapBody
	GetResourceHandleNS	ScrapNameList, cx
	mov	dx, offset ScrapNameList
	mov	ax, MSG_GEN_ADD_CHILD
	mov	bp, mask CCF_MARK_DIRTY
	call	ObjMessage

	pop	bp
	;
	;  Add a var data
	;
	mov	sizeArg.CSHA_width, SST_AVG_CHAR_WIDTHS shl offset SW_TYPE or 25
	mov	sizeArg.CSHA_height, 0 ; SST_LINES_OF_TEXT shl offset SH_TYPE or 9
	mov	sizeArg.CSHA_count, 9
	lea	ax, sizeArg
	movdw	params.AVDP_data, ssax
	mov	params.AVDP_dataSize, size CompSizeHintArgs
	mov	params.AVDP_dataType, HINT_FIXED_SIZE
	GetResourceHandleNS	ScrapNameList, bx
	mov	si, offset ScrapNameList
	mov	ax, MSG_META_ADD_VAR_DATA
	mov	dx, size AddVarDataParams
	mov	di, mask MF_STACK or mask MF_CALL
	push	bp
	lea	bp, params
	call	ObjMessage
	;
	;  Set the GenDynamic List usable
	;
	GetResourceHandleNS	ScrapNameList, bx
	mov	si, offset ScrapNameList
	clr	dx
	mov	dl, VUM_NOW	
	mov	ax, MSG_GEN_SET_USABLE
	mov	di, mask MF_CALL
	call	ObjMessage

	pop	bp
	.leave
	ret
ShowPageListOnScreen endp

HidePageListToTrigger proc far
params		local	AddVarDataParams
sizeArg		local	CompSizeHintArgs
	.enter
	push	bp
	;	GetResourceHandleNS	ScrapNameBoxTrigger, bx
	;	mov	si, offset ScrapNameBoxTrigger
	;	clr	dx
	;	mov	dl, VUM_NOW	
	;	mov	ax, MSG_GEN_SET_NOT_USABLE
	;	mov	di, mask MF_CALL
	;	call	ObjMessage
	;
	;  Set the GenDynamic List not usable
	;
	GetResourceHandleNS	ScrapNameList, bx
	mov	si, offset ScrapNameList
	clr	dx
	mov	dl, VUM_NOW	
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	di, mask MF_CALL
	call	ObjMessage
	;
	;  Remove the GenDynamic list from a dialog box
	;
	GetResourceHandleNS	ScrapBody, bx
	mov	si, offset ScrapBody
	GetResourceHandleNS	ScrapNameList, cx
	mov	dx, offset ScrapNameList
	mov	ax, MSG_GEN_REMOVE_CHILD
	mov	bp, mask CCF_MARK_DIRTY
	call	ObjMessage
	;
	;  Add the GenDynamic list to a different parent
	;
	GetResourceHandleNS	ScrapNameBox, bx
	mov	si, offset ScrapNameBox
	GetResourceHandleNS	ScrapNameList, cx
	mov	dx, offset ScrapNameList
	mov	ax, MSG_GEN_ADD_CHILD
	mov	bp, mask CCF_MARK_DIRTY
	call	ObjMessage
	;
	;  Set the GenDynamic List usable
	;
	GetResourceHandleNS	ScrapNameList, bx
	mov	si, offset ScrapNameList
	clr	dx
	mov	dl, VUM_NOW	
	mov	ax, MSG_GEN_SET_USABLE
	mov	di, mask MF_CALL
	call	ObjMessage

	pop	bp
	;
	;  Add a var data
	;
	mov	sizeArg.CSHA_width, SST_AVG_CHAR_WIDTHS shl offset SW_TYPE or 32
	mov	sizeArg.CSHA_height, SST_LINES_OF_TEXT shl offset SH_TYPE or 5
	mov	sizeArg.CSHA_count, 5
	lea	ax, sizeArg
	movdw	params.AVDP_data, ssax
	mov	params.AVDP_dataSize, size CompSizeHintArgs
	mov	params.AVDP_dataType, HINT_FIXED_SIZE
	GetResourceHandleNS	ScrapNameList, bx
	mov	si, offset ScrapNameList
	mov	ax, MSG_META_ADD_VAR_DATA
	mov	dx, size AddVarDataParams
	mov	di, mask MF_STACK or mask MF_CALL
	push	bp
	lea	bp, params
	call	ObjMessage
	;
	;  Set the "GO TO PAGE.." trigger usable
	;
	GetResourceHandleNS	ScrapNameBoxTrigger, bx
	mov	si, offset ScrapNameBoxTrigger
	clr	dx
	mov	dl, VUM_NOW	
	mov	ax, MSG_GEN_SET_USABLE
	mov	di, mask MF_CALL
	call	ObjMessage
	;
	;  Set the NEXT and PREVIOUS button usable
	;
	GetResourceHandleNS	ScrapPreviousAndNext, bx
	mov	si, offset ScrapPreviousAndNext
	clr	dx
	mov	dl, VUM_NOW	
	mov	ax, MSG_GEN_SET_USABLE
	mov	di, mask MF_CALL
	call	ObjMessage
		
	pop	bp
	.leave
	ret
HidePageListToTrigger endp

ScrapbookCopyCallerApp	proc	far
	uses	ax, bx, dx, cx, es, di, si
	.enter
	segmov	es, ss
	lea	di, ss:[callerAppName]
	mov	cx, (GEODE_NAME_SIZE + GEODE_NAME_EXT_SIZE)
	rep movsb

	lea	di, ss:[callerAppName]
	mov	ax, (GEODE_NAME_SIZE + GEODE_NAME_EXT_SIZE)
	clrdw	cxdx
	call	GeodeFind		; return bx - handle of GEODE
	mov	ss:[callerAppToken], bx
		
	.leave
	ret
ScrapbookCopyCallerApp	endp


;	Change the ScrapInsert moniker from "Copy to Clipboard" to
;	"Insert into Document"
; Pass:
;	
; Returns:
;	
; Destroys:
;	nothing
ScrapbookChangeIcon	proc	far
	uses	ax, bx, si, cx, dx, bp, di, es
	.enter

	GetResourceHandleNS	ScrapStrings, bx
	push	bx
	call	MemLock		; ax = string segment
	mov	es, ax
	mov	si, offset NewMonikerString
	mov	dx, es:[si]
	mov	cx, es		; cx:dx - string
	GetResourceHandleNS	ScrapInsert, bx
	mov	si, offset ScrapInsert
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_TEXT
	mov	bp, VUM_NOW
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	bx
	call	MemUnlock

	.leave
	ret
ScrapbookChangeIcon	endp

ScrapbookChangeIconBack	proc	far
	uses	ax, bx, si, cx, dx, bp, di, es
	.enter

	GetResourceHandleNS	ScrapStrings, bx
	push	bx
	call	MemLock		; ax = string segment
	mov	es, ax
	mov	si, offset OldMonikerString
	mov	dx, es:[si]
	mov	cx, es		; cx:dx - string
	GetResourceHandleNS	ScrapInsert, bx
	mov	si, offset ScrapInsert
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_TEXT
	mov	bp, VUM_NOW
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	bx
	call	MemUnlock

	.leave
	ret
ScrapbookChangeIconBack	endp



;	Add to the GCNList so that when the parent app quits,
;	scrapbook get notified and change its moniker.
; Pass:		none
; Returns:	none
;	
; Destroys:
;	nothing
ScrapbookAddGCNList	proc	far
	uses	ax, bx, cx, dx
	.enter

	call	GeodeGetProcessHandle
	mov	cx, bx
	clr	dx
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GCNSLT_APPLICATION
	call	GCNListAdd
		
	.leave
	ret
ScrapbookAddGCNList	endp


;	Remove scrapbook app from the GCN list.  It's no longer need
;	to be notified.
; Pass:		none
; Returns:	none
;	
; Destroys:
;	nothing
ScrapbookRemoveGCNList	proc	far
	uses	ax, bx, cx, dx
	.enter

	call	GeodeGetProcessHandle
	mov	cx, bx
	clr	dx
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GCNSLT_APPLICATION
	call	GCNListRemove
		
	.leave
	ret
ScrapbookRemoveGCNList	endp



;	Some app is quitting.  Check to see if it's the parent application.
;	If so, change scrapbook moniker.
; Pass:		none
; Returns:	none
;	
; Destroys:
;	nothing
ScrapBookNotifyExit	method	dynamic	ScrapBookClass, MSG_NOTIFY_APP_EXITED
	.enter

	cmp	dx, ss:[callerAppToken]
	jne	done
	;
	;  The parent app exited, scrapbook no longer needs to be notified.
	;
	call	ScrapbookRemoveGCNList
	mov	ss:[callerAppName], 0
	call	ScrapbookChangeIconBack
done:
	.leave
	ret
ScrapBookNotifyExit	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScrapBookKbdChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle keys from view by FUP'ing them back to the view

CALLED BY:	MSG_META_KBD_CHAR

PASS:		ds	= ScrapBookClass segment
		es 	= segment of ScrapBookClass
		ax	= MSG_META_KBD_CHAR

		cx	= character value
		dl	= CharFlags
		dh	= ShiftState
		bp low	= ToggleState
		bh high	= scan code

RETURN:		nothing

ALLOWED TO DESTROY:	
		ax, cx, dx, bp
		bx, si, di, ds, es

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Handled, so that TAB navigation works

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/21/93  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScrapBookKbdChar	method	dynamic	ScrapBookClass, MSG_META_KBD_CHAR
	;
	; Our view has 'sendAllKbdChars', so send everything back up
	;
	GetResourceHandleNS	ScrapGString, bx
	mov	si, offset ScrapGString
	mov	ax, MSG_META_FUP_KBD_CHAR
	mov	di, mask MF_CALL
	call	ObjMessage
	ret
ScrapBookKbdChar	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScrapBookBringUpHelp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bring up TOC help, we get this because we are the content
		of the view and the HELP stuff goes to TO_FOCUS.

CALLED BY:	MSG_META_BRING_UP_HELP

PASS:		ds	= dgroup of ScrapBookClass
		es 	= segment of ScrapBookClass
		ax	= MSG_META_BRING_UP_HELP

RETURN:		nothing

ALLOWED TO DESTROY:	
		ax, cx, dx, bp
		bx, si, di, ds, es

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/2/93  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScrapBookBringUpHelp	method	ScrapBookClass, MSG_META_BRING_UP_HELP
	;
	; let primary bring up TOC help
	;
	GetResourceHandleNS	ScrapBookPrimary, bx
	mov	si, offset ScrapBookPrimary
	mov	di, mask MF_CALL
	call	ObjMessage
	ret
ScrapBookBringUpHelp	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Intercept the C_ENTER event and load the clip art.

CALLED BY:	MSG_META_BRING_UP_HELP

PASS:		ds	= dgroup of ScrapBookClass
		es 	= segment of ScrapBookClass
		ax	= MSG_META_BRING_UP_HELP

RETURN:		nothing

ALLOWED TO DESTROY:	
		ax, cx, dx, bp
		bx, si, di, ds, es

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/2/93  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MyDynamicListSetSelection	method	ScrapBookListClass, MSG_META_FUP_KBD_CHAR
		.enter
	push	cx
	mov	di, offset ScrapBookListClass
	call	ObjCallSuperNoLock
	pop	cx

	cmp	cl, C_ENTER
	jne	exit
	cmp	dl, mask CF_RELEASE
	jne	exit

	GetResourceHandleNS	ScrapNameList, bx
	mov	si, offset ScrapNameList
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, mask MF_CALL
	call	ObjMessage

	mov	cx, ax
	call	GeodeGetProcessHandle
	mov	ax, MSG_SCRAPBOOK_SET_SELECTION
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
exit:
	.leave
	ret
MyDynamicListSetSelection	endm



if NO_BACKUP

;
; ScrapBookDocumentClass code
;

;
; save before closing, so we don't get the "revert" dialog, as we have
; nothing to revert, UNLESS it is untitled, in which case, we'll let the
; "revert" dialog allow the user to option of throwing away the document
;
ScrapBookDocumentClose	method	ScrapBookDocumentClass, MSG_GEN_DOCUMENT_CLOSE
	push	bp
	mov	ax, MSG_GEN_DOCUMENT_GET_FILE_HANDLE
	call	ObjCallInstanceNoLock
	tst	ax
	jz	close
	mov	bx, ax
	call	VMGetAttributes
	test	al, mask VMA_BACKUP
	jnz	close			; normal close if in backup mode
	mov	ax, MSG_GEN_DOCUMENT_GET_ATTRS
	call	ObjCallInstanceNoLock
	test	ax, mask GDA_UNTITLED
	jnz	close
	mov	ax, MSG_GEN_DOCUMENT_SAVE
	call	ObjCallInstanceNoLock
	;how to handle error? let DOCUMENT_CLOSE handle it...
close:
	pop	bp
	mov	ax, MSG_GEN_DOCUMENT_CLOSE
	mov	di, offset ScrapBookDocumentClass
	call	ObjCallSuperNoLock
	ret
ScrapBookDocumentClose	endm

;
; try to reduce size of VM header
;

scrapDir	TCHAR	"Scrap"
SCRAP_DIR_LEN	= $-scrapDir
.warn -unref
scrapDirNull	TCHAR	0	; null-terminator
.warn @unref

udata	segment
scrapTempName	TCHAR (SCRAP_DIR_LEN+1) dup (?)		; "Scrap\"
tempName	FileLongName
scrapDocName	TCHAR (SCRAP_DIR_LEN+1) dup (?)		; "Scrap\"
docName		FileLongName
curFile		word
newFile		word
newSBIHMem	word
newCIHMem	word
numScraps	word
docObj		optr
waitForAck	byte
cancelCompress	byte
udata	ends

VMSaveAsHeader	struct
    VMSAH_flags		GeosFileHeaderFlags
    VMSAH_release 	ReleaseNumber
    VMSAH_protocol 	ProtocolNumber
    VMSAH_token		GeodeToken
    VMSAH_creator	GeodeToken
    VMSAH_notes		FileUserNotes
VMSaveAsHeader	ends

VMSAH_NUM_ATTRS	equ	6

VMSaveAsTransferHeader proc	near
		uses	es, di
headerCopy	local	VMSaveAsHeader	; Buffer for copying relevant pieces of
					;  the header when done.
headerAttrs	local	VMSAH_NUM_ATTRS dup(FileExtAttrDesc)
		.enter
	;
	; Copy the important pieces of the header from the source to the dest.
	;
		mov	ss:[headerAttrs][0*FileExtAttrDesc].FEAD_attr, FEA_FLAGS
		mov	ss:[headerAttrs][0*FileExtAttrDesc].FEAD_value.segment,
				ss
		lea	ax, ss:[headerCopy].VMSAH_flags
		mov	ss:[headerAttrs][0*FileExtAttrDesc].FEAD_value.offset,
				ax
		mov	ss:[headerAttrs][0*FileExtAttrDesc].FEAD_size,
				size VMSAH_flags

		mov	ss:[headerAttrs][1*FileExtAttrDesc].FEAD_attr, 
				FEA_RELEASE
		mov	ss:[headerAttrs][1*FileExtAttrDesc].FEAD_value.segment,
				ss
		lea	ax, ss:[headerCopy].VMSAH_release
		mov	ss:[headerAttrs][1*FileExtAttrDesc].FEAD_value.offset,
				ax
		mov	ss:[headerAttrs][1*FileExtAttrDesc].FEAD_size,
				size VMSAH_release

		mov	ss:[headerAttrs][2*FileExtAttrDesc].FEAD_attr, 
				FEA_PROTOCOL
		mov	ss:[headerAttrs][2*FileExtAttrDesc].FEAD_value.segment,
				ss
		lea	ax, ss:[headerCopy].VMSAH_protocol
		mov	ss:[headerAttrs][2*FileExtAttrDesc].FEAD_value.offset,
				ax
		mov	ss:[headerAttrs][2*FileExtAttrDesc].FEAD_size,
				size VMSAH_protocol

		mov	ss:[headerAttrs][3*FileExtAttrDesc].FEAD_attr,
				FEA_TOKEN
		mov	ss:[headerAttrs][3*FileExtAttrDesc].FEAD_value.segment,
				ss
		lea	ax, ss:[headerCopy].VMSAH_token
		mov	ss:[headerAttrs][3*FileExtAttrDesc].FEAD_value.offset,
				ax
		mov	ss:[headerAttrs][3*FileExtAttrDesc].FEAD_size,
				size VMSAH_token

		mov	ss:[headerAttrs][4*FileExtAttrDesc].FEAD_attr, 
				FEA_CREATOR
		mov	ss:[headerAttrs][4*FileExtAttrDesc].FEAD_value.segment,
				ss
		lea	ax, ss:[headerCopy].VMSAH_creator
		mov	ss:[headerAttrs][4*FileExtAttrDesc].FEAD_value.offset,
				ax
		mov	ss:[headerAttrs][4*FileExtAttrDesc].FEAD_size,
				size VMSAH_creator

		mov	ss:[headerAttrs][5*FileExtAttrDesc].FEAD_attr,
				FEA_USER_NOTES
		mov	ss:[headerAttrs][5*FileExtAttrDesc].FEAD_value.segment,
				ss
		lea	ax, ss:[headerCopy].VMSAH_notes
		mov	ss:[headerAttrs][5*FileExtAttrDesc].FEAD_value.offset,
				ax
		mov	ss:[headerAttrs][5*FileExtAttrDesc].FEAD_size,
				size VMSAH_notes
	

		segmov	es, ss
		lea	di, ss:[headerAttrs]
		mov	cx, length headerAttrs
		

		mov	bx, ss:[curFile]
		mov	ax, FEA_MULTIPLE
		call	FileGetHandleExtAttributes
		jc	headerTransferred

		andnf	ss:[headerCopy].VMSAH_flags,
				not (mask GFHF_TEMPLATE or \
				     mask GFHF_SHARED_MULTIPLE or \
				     mask GFHF_SHARED_SINGLE)

		mov	bx, ss:[newFile]
		mov	ax, FEA_MULTIPLE
		call	FileSetHandleExtAttributes

headerTransferred:
		.leave
		ret
VMSaveAsTransferHeader endp

ScrapBookDocumentCompress	method dynamic ScrapBookDocumentClass,
					MSG_SCRAPBOOK_DOCUMENT_COMPRESS
	mov	ss:[waitForAck], BB_FALSE
	mov	ss:[cancelCompress], BB_FALSE
	;
	; only do if beyond warning size, and if free handles is a
	; significant
	;
	mov	ax, MSG_GEN_DOCUMENT_GET_FILE_HANDLE
	call	ObjCallInstanceNoLock
	tst	ax
	LONG jz	exit
	mov	ss:[curFile], ax
	mov	bx, ax
	call	VMGetHeaderInfo
	cmp	cx, ss:[warningSize]
	LONG jb	exit
	;
	; display status dialog
	;
	push	si
	mov	ax, MSG_GEN_APPLICATION_MARK_BUSY
	call	GenCallApplication
	GetResourceHandleNS	CompressStatus, bx
	mov	si, offset CompressStatus
	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_NOW
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	clr	dx, cx, bp
	mov	ax, MSG_GEN_VALUE_SET_VALUE
	GetResourceHandleNS	CompressStatusProgress, bx
	mov	si, offset CompressStatusProgress
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	si
	;
	; save to get everything out onto disk
	;
	mov	ax, ds:[LMBH_handle]
	mov	ss:[docObj].handle, ax
	mov	ss:[docObj].chunk, si
	mov	bx, ss:[curFile]
	call	VMSave
	LONG jc	errExit
	tst	ss:[cancelCompress]
	stc
	LONG jnz	errExit
	;
	; create new compressed version of file with unique name
	;
	call	FilePushDir
	; ensure our work directory exists
	mov	ax, SP_PRIVATE_DATA
	call	FileSetStandardPath
	segmov	ds, cs, dx
	mov	dx, offset scrapDir
	call	FileCreateDir
	jnc	createOK
	cmp	ax, ERROR_FILE_EXISTS
	je	createOK
	stc				; indicate error
errPopDirFar:
	jmp	errPopDir

createOK:
	; switch to our work directory
	mov	bx, SP_PRIVATE_DATA
	call	FileSetCurrentPath
	jc	errPopDirFar
	; set up our temp file's path
	segmov	ds, cs, si
	mov	si, offset scrapDir
	segmov	es, ss, di
	mov	di, offset scrapTempName
	mov	cx, SCRAP_DIR_LEN
	LocalCopyNString
	LocalLoadChar	ax, '\\'
	LocalPutChar	esdi, ax
	; create temp file
	mov	di, offset tempName
	clr	ax
	mov	cx, length FileLongName
SBCS <	rep	stosb						>
DBCS <	rep	stosw						>
	segmov	ds, ss, dx
	mov	dx, offset tempName
	mov	ax, (VMO_TEMP_FILE shl 8)
	mov	cx, 0			; default compression
	call	VMOpen			; bx = VM file handle
	jc	errPopDirFar		; couldn't create temp file
	mov	ss:[newFile], bx
	mov	ax, mask VMA_SINGLE_THREAD_ACCESS or ((mask VMA_SYNC_UPDATE or mask VMA_BACKUP or mask VMA_NOTIFY_DIRTY) shl 8)
	call	VMSetAttributes
	call	VMSaveAsTransferHeader
	LONG jc	closeNew
	call	VMSave
	LONG jc	closeNew
	tst	ss:[cancelCompress]
	stc
	LONG jnz	closeNew
	;
	; get our working copy of SBIH
	;
	mov	bx, ss:[curFile]
	call	VMGetMapBlock
	mov	dx, ss:[newFile]
	call	VMCopyVMBlock		; ax = new SBIH
	mov	bx, dx
	call	VMSetMapBlock
	push	ax
	call	VMSave
	pop	ax
	LONG jc	closeNew
	tst	ss:[cancelCompress]
	stc
	LONG jnz	closeNew
	call	VMLock			; ax = segment, bp = handle
	mov	ss:[newSBIHMem], bp
	mov	es, ax
	mov	ax, es:[SBIH_numScraps]
	mov	ss:[numScraps], ax
	; initialize status
	mov	dx, ax
	clr	cx
	mov	ax, MSG_GEN_VALUE_SET_MAXIMUM
	GetResourceHandleNS	CompressStatusProgress, bx
	mov	si, offset CompressStatusProgress
	mov	di, mask MF_CALL
	call	ObjMessage
	mov	di, size ScrapBookIndexHeader	; es:di = first scrap
	;
	; copy all scraps over, saving in between each to ensure compressed
	;
scrapLoop:
	tst	ss:[numScraps]
	LONG jz	doneScraps
	mov	bx, ss:[curFile]
	mov	ax, es:[di].SBIE_vmBlock	; bx:ax = CIH block
	mov	dx, ss:[newFile]
	clr	cx				; preserve user id's
	call	VMCopyVMBlock			; ax = new CIH block
	mov	es:[di].SBIE_vmBlock, ax	; update CIH in new SBIH
	mov	bx, dx				; bx = newFile
	call	VMSave
	LONG jc	unlockSBIH
	tst	ss:[cancelCompress]
	stc
	LONG jnz	unlockSBIH
	mov	ax, es:[di].SBIE_vmBlock
	call	VMLock				; ax = segment, bp = mem handle
	mov	ss:[newCIHMem], bp
	mov	ds, ax				; ds = segment of CIH
	; copy each format's VMChain
	mov	cx, ds:[CIH_formatCount]	; cx = number of formats
	mov	si, offset CIH_formats		; ds:si = first format
	mov	bx, ss:[curFile]		; bx = source file
	mov	dx, ss:[newFile]		; dx = dest file
formatLoop:
	movdw	axbp, ds:[si].CIFI_vmChain	; ax = cur item chain
	push	cx
	clr	cx				; preserve user id's
	call	VMCopyVMChain			; ax = transfer VM block handle
	pop	cx
	jc	unlockCIH
	push	ax
	call	VMSave
	pop	ax
	jc	unlockCIH
	tst	ss:[cancelCompress]
	stc
	LONG jnz	unlockCIH
	movdw	ds:[si].CIFI_vmChain, axbp	; store new item chain
	add	si, size ClipboardItemFormatInfo ; move to next format
	loop	formatLoop
	mov	bp, ss:[newCIHMem]		; retrieve new CIH mem handle
	call	VMDirty
	clc					; all formats copied
unlockCIH:
	mov	bp, ss:[newCIHMem]		; retrieve new CIH mem handle
	call	VMUnlock			; unlock new CIH (preserves C)
	jc	unlockSBIH
	mov	bx, ss:[newFile]
	call	VMSave				; commit new CIH
	jc	unlockSBIH
	tst	ss:[cancelCompress]
	stc
	LONG jnz	unlockSBIH
	add	di, size ScrapBookIndexEntry
	dec	ss:[numScraps]
	; update status
	push	di
	mov	ax, MSG_GEN_VALUE_INCREMENT
	GetResourceHandleNS	CompressStatusProgress, bx
	mov	si, offset CompressStatusProgress
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	di
	jmp	scrapLoop

doneScraps:
	mov	bp, ss:[newSBIHMem]		; retrieve new SBIH mem handle
	call	VMDirty
	clc					; all scraps copied
unlockSBIH:
	mov	bp, ss:[newSBIHMem]		; retrieve new SBIH mem handle
	call	VMUnlock			; unlock new SBIH (preserves C)
	jc	closeNew
	mov	bx, ss:[newFile]
	call	VMSave
	jc	closeNew
	mov	ax, mask VMA_NOTIFY_DIRTY
	call	VMSetAttributes			; set when we're clean
	clc					; no error
closeNew:
	lahf
	push	ax
	mov	bx, ss:[newFile]
	mov	al, 0
	call	VMClose
	pop	ax
	LONG jc	deleteNew			; close error
	sahf
	LONG jc	deleteNew			; save error
	tst	ss:[cancelCompress]
	stc
	LONG jnz	deleteNew
	;
	; close old file, continue when ack'ed
	;
	mov	bx, ss:[docObj].handle
	call	MemDerefDS
	mov	si, ss:[docObj].chunk
	clr	bp
	mov	ax, MSG_GEN_DOCUMENT_CLOSE_FILE
	call	ObjCallInstanceNoLock
	; wait for MSG_GEN_APPLICATION_CLOSE_FILE_ACK
	mov	ss:[waitForAck], BB_TRUE
	call	FilePopDir
exit:
	ret			; <-- EXIT HERE

deleteNew:
	; delete temporary new document
	mov	ax, SP_PRIVATE_DATA
	call	FileSetStandardPath
	segmov	ds, ss, dx
	mov	dx, offset scrapTempName
	call	FileDelete
errPopDir:
	call	FilePopDir
errExit:
	mov	bx, ss:[docObj].handle
	call	MemDerefDS
	mov	si, ss:[docObj].chunk
	clr	cx			; cleanup after error
	mov	ax, MSG_SCRAPBOOK_DOCUMENT_COMPRESS_PART2
	call	ObjCallInstanceNoLock
	ret			; <-- EXIT HERE

ScrapBookDocumentCompress	endm

ScrapBookApplicationCloseFileAck	method	dynamic	ScrapbookApplicationClass, MSG_GEN_APPLICATION_CLOSE_FILE_ACK
	; es = dgroup
	tst	es:[waitForAck]
	jz	done
	movdw	bxsi, es:[docObj]
	mov	ax, MSG_SCRAPBOOK_DOCUMENT_COMPRESS_PART2
	mov	cx, -1			; do real work
	clr	di
	call	ObjMessage
done:
	ret
ScrapBookApplicationCloseFileAck	endm
	
;
;continuing when GenApp gets MSG_GEN_APPLICATION_CLOSE_FILE_ACK
;
ScrapBookDocumentCompressPart2	method	dynamic ScrapBookDocumentClass,
					MSG_SCRAPBOOK_DOCUMENT_COMPRESS_PART2
	tst	cx
	LONG jz	cleanUp
	call	FilePushDir
	; get current document name
	mov	cx, ss
	mov	dx, offset docName
	mov	ax, MSG_GEN_DOCUMENT_GET_FILE_NAME
	call	ObjCallInstanceNoLock
	; build the name of document in our work directory
	segmov	es, ss, di
	mov	di, offset scrapDocName
	segmov	ds, cs, si
	mov	si, offset scrapDir
	mov	cx, SCRAP_DIR_LEN
	LocalCopyNString
	LocalLoadChar	ax, '\\'
	LocalPutChar	esdi, ax
	; switch to document directory
	mov	bx, ss:[docObj].handle
	call	MemDerefDS
	mov	si, ss:[docObj].chunk
	mov	ax, ATTR_GEN_PATH_DATA
	mov	dx, TEMP_GEN_PATH_SAVED_DISK_HANDLE
	call	GenPathSetCurrentPathFromObjectPath
	tst	ss:[cancelCompress]
	LONG jnz	deleteNew
	; copy original document to our work directory (in case of problems?)
	segmov	ds, ss, si
	mov	si, offset docName
	mov	cx, 0				; in current directory
	mov	di, offset scrapDocName
	mov	dx, SP_PRIVATE_DATA		; in work directory
	call	FileCopy
	jc	deleteNew
	tst	ss:[cancelCompress]
	LONG jnz	deleteNew
	; copy new document (in work directory) over(write) original document,
	segmov	ds, ss, si
	mov	si, offset scrapTempName
	mov	cx, SP_PRIVATE_DATA		; in work directory
	segmov	es, ss, di
	mov	di, offset docName
	mov	dx, 0				; in current directory
	call	FileCopy
	; if error here, hopefully original document wasn't clobbered,
	; so we'll just re-open it
deleteNew:
	; delete temporary new document
	mov	ax, SP_PRIVATE_DATA
	call	FileSetStandardPath
	segmov	ds, ss, dx
	mov	dx, offset scrapTempName
	call	FileDelete			; ignore error
	; delete copy of old document (in work directory)
	mov	dx, offset scrapDocName
	call	FileDelete			; ignore error
	; reopen new compressed document
	mov	bx, ss:[docObj].handle
	call	MemDerefDS
	mov	si, ss:[docObj].chunk
	mov	ax, MSG_GEN_DOCUMENT_REOPEN_FILE
	call	ObjCallInstanceNoLock
	call	FilePopDir
cleanUp:
	;
	; remove status dialog
	;
	GetResourceHandleNS	CompressStatus, bx
	mov	si, offset CompressStatus
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_DISMISS
	clr	di
	call	ObjMessage
	mov	ax, MSG_GEN_APPLICATION_MARK_NOT_BUSY
	call	GenCallApplication
	;
	; all done
	;
	mov	ss:[waitForAck], BB_FALSE
	mov	ss:[cancelCompress], BB_FALSE
	ret
ScrapBookDocumentCompressPart2	endm

ScrapbookApplicationCancelCompress	method	dynamic	ScrapbookApplicationClass,
				MSG_SCRAPBOOK_APPLICATION_CANCEL_COMPRESS
	; es = dgroup
	mov	es:[cancelCompress], BB_TRUE
	ret
ScrapbookApplicationCancelCompress	endm

endif

CommonCode	ends

CommonCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlideShowSetColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the color

CALLED BY:	MSG_SLIDE_SHOW_SET_TRANSITION

PASS:		*ds:si - SlideShowClass object
		ds:di - SlideShow instance
		dxcx - ColorQuad

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	08/01/00	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScrapbookApplicationQuit method ScrapbookApplicationClass, MSG_META_QUIT
		mov	ax, MSG_META_SAVE_OPTIONS
		mov	di, offset ScrapbookApplicationClass
		call	ObjCallSuperNoLock
		mov	ax, MSG_META_QUIT
		mov	di, offset ScrapbookApplicationClass
		GOTO	ObjCallSuperNoLock
ScrapbookApplicationQuit endm

CommonCode	ends

SlideCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlideShowStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open a full-screen window for a slide show

CALLED BY:	MSG_SLIDE_SHOW_START

PASS:		*ds:si - SlideShowClass object
		ds:di - SlideShow instance

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	07/28/00	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SlideShowStart	method SlideShowClass,	MSG_SLIDE_SHOW_START
		push	si
	;
	; get the field dimensions
	;
		push	si
		mov	ax, MSG_GEN_GUP_QUERY
		mov	cx, GUQT_FIELD
		GetResourceHandleNS	ScrapBookApp, bx
		mov	si, offset ScrapBookApp
		mov	di, mask MF_CALL
		call	ObjMessage
		pop	si
	;
	; stack parameters for WinOpen
	; 
		clr	ax
		push	ax		;layer ID (not used)

		call	GeodeGetProcessHandle
		push	bx		;owner for window (us)
		push	bp		;parent window = field

		push	ax		;region = rectangular
		push	ax		;region = rectangular

		mov	di, bp				;di <- field window
		call	WinGetWinScreenBounds		;(ax,bx,cx,dx) <- bnds
		push	dx				;bottom
		push	cx				;right
		push	bx				;top
		push	ax				;left
		mov	di, ds:[LMBH_handle]
		mov	bp, si		;^ldi:bp <- expose OD (us)
		mov	cx, di
		mov	dx, si		;^lcx:dx <- input OD (us)
		mov	si, ds:[si]
		add	si, ds:[si].SlideShow_offset
		mov	al, ds:[si].SSI_color.CQ_redOrIndex
		mov	bx, {word}ds:[si].SSI_color.CQ_green
		mov	ah, WinColorFlags <
			0,		; WCF_RGB: using color index
			0,		; WCF_TRANSPARENT: has background
			0,		; WCF_PLAIN: window requires exposes
			0,		; WCF_MASKED
			0,		; WCF_DRAW_MASK
			ColorMapMode <	; WCF_MAP_MODE
				0,		; CMM_ON_BLACK: black is our
						;  background color, always.
				CMT_CLOSEST	; CM_MAP_TYPE: map to
						;  solid, never pattern or
						;  dither, please.
			>
		>
		cmp	ds:[si].SSI_color.CQ_info, CF_INDEX
		je	gotColor
		ornf	ah, mask WCF_RGB
gotColor:
		mov	si, WinPriorityData <
				LAYER_PRIO_ON_TOP,
				WIN_PRIO_ON_TOP
		>			;si <- WinPassFlags
		call	WinOpen
	;
	; save the window handle for later
	;

		pop	si
		mov	di, ds:[si]
		add	di, ds:[di].SlideShow_offset
		mov	ds:[di].SSI_window, bx			;save for later
	;
	; add a keyboard monitor
	;
		GetResourceHandleNS idata, bx
		call	MemDerefDS
		mov	bx, offset ssKbdMon
		mov	al, ML_DRIVER
		mov	cx, segment SlideShowKbdMon
		mov	dx, offset SlideShowKbdMon
		call	ImAddMonitor
		GetResourceHandleNS SlideControl, bx
		mov	es:ssUIHan, bx

		ret
SlideShowStart	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlideShowEnd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close the full-screen window for a slide show

CALLED BY:	MSG_SLIDE_SHOW_END

PASS:		*ds:si - SlideShowClass object
		ds:di - SlideShow instance

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	07/28/00	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SlideShowEnd	method SlideShowClass,	MSG_SLIDE_SHOW_END
	;
	; close the window
	;
		clr	cx
		xchg	ds:[di].SSI_window, cx
		jcxz	done
		mov	di, cx
		call	WinClose
	;
	; remove the keyboard monitor
	;
		GetResourceHandleNS idata, bx
		call	MemDerefDS
		mov	bx, offset ssKbdMon		;ds:bx <- monitor
		mov	al, mask MF_REMOVE_IMMEDIATE
		call	ImRemoveMonitor
done:
		ret
SlideShowEnd	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlideShowDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw to the full-screen window

CALLED BY:	MSG_META_EXPOSED

PASS:		*ds:si - SlideShowClass object
		ds:di - SlideShow instance

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	07/28/00	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SlideShowDraw	method SlideShowClass,	MSG_META_EXPOSED
		mov	cx, ds:[di].SSI_window
		call	GeodeGetProcessHandle
		mov	di, mask MF_FIXUP_DS
		mov	ax, MSG_SCRAPBOOK_DRAW_SLIDE_WINDOW
		GOTO	ObjMessage
SlideShowDraw	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlideShowNext, SlideShowPrev
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle mouse input for the slide show

CALLED BY:	MSG_META_START_SELECT

PASS:		*ds:si - SlideShowClass object
		ds:di - SlideShow instance

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	07/28/00	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SlideShowPrev	method SlideShowClass, MSG_META_START_MOVE_COPY,
					MSG_SLIDE_SHOW_PREVIOUS
		mov	ax, MSG_SCRAPBOOK_PREVIOUS
		GOTO	ChangeSlide
SlideShowPrev	endm

SlideShowNext	method SlideShowClass,	MSG_META_START_SELECT,
					MSG_SLIDE_SHOW_NEXT
		mov	ax, MSG_SCRAPBOOK_NEXT
		FALL_THRU	ChangeSlide
SlideShowNext	endm

ChangeSlide	proc	far
		class	SlideShowClass
	;
	; clear the window as desired
	;
		mov	di, ds:[si]
		add	di, ds:[di].SlideShow_offset
		mov	di, ds:[di].SSI_window		;di <- window
		tst	di				;any window?
		jz	done				;branch if not
		push	ax, si
		call	WinGetWinScreenBounds
		inc	cx
		inc	dx
		call	GrCreateState
		mov	si, ds:[si]
		add	si, ds:[si].SlideShow_offset
		push	ax, bx
		movdw	bxax, ds:[si].SSI_color
		call	GrSetAreaColor
		pop	ax, bx
		mov	si, ds:[si].SSI_trans
		call	cs:slideShowProcs[si]
		call	GrDestroyState
		pop	ax, si
	;
	; change the current scrap
	;
		call	GeodeGetProcessHandle
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
	;
	; invalidate our window to force redraw
	;
		mov	di, ds:[si]
		add	di, ds:[di].SlideShow_offset
		mov	di, ds:[di].SSI_window		;di <- window
		clr	ax, bx, bp
		mov	cx, MAX_COORD
		mov	dx, cx
		call	WinInvalReg			;force redraw
done:
		mov	ax, mask MRF_PROCESSED
		ret
ChangeSlide	endp

slideShowProcs	nptr.near \
	SlideShowClear,
	SlideShowCornerWipe,
	SlideShowEdgeWipe,
	SlideShowFade

CheckHack <size slideShowProcs eq SlideShowTransitionType>

SlideShowClear		proc	near
		ret
SlideShowClear		endp

SlideShowCornerWipe	proc	near		
		mov	si, SAVER_FADE_FAST_SPEED
		mov	bp, mask SWT_RIGHT or mask SWT_BOTTOM
		call	SaverFadeWipe
		ret
SlideShowCornerWipe	endp

SlideShowEdgeWipe	proc	near		
		mov	si, SAVER_FADE_FAST_SPEED
		mov	bp, mask SWT_RIGHT
		call	SaverFadeWipe
		ret
SlideShowEdgeWipe	endp

SlideShowFade	proc	near
		mov	si, SAVER_FADE_FAST_SPEED
		call	SaverFadePatternFade
		ret
SlideShowFade	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlideShowQuit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Quit if both buttons pressed

CALLED BY:	MSG_META_START_OTHER

PASS:		*ds:si - SlideShowClass object
		ds:di - SlideShow instance

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	07/31/00	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SlideShowMouseQuit	method SlideShowClass, MSG_META_START_OTHER
		mov	ax, MSG_SLIDE_SHOW_END
		call	ObjCallInstanceNoLock
		mov	ax, mask MRF_PROCESSED
		ret
SlideShowMouseQuit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlideShowSetTransition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the transition type

CALLED BY:	MSG_SLIDE_SHOW_SET_TRANSITION

PASS:		*ds:si - SlideShowClass object
		ds:di - SlideShow instance
		cx - SlideShowTransitionType

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	08/01/00	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SlideShowSetTransition	method SlideShowClass, MSG_SLIDE_SHOW_SET_TRANSITION
		mov	ds:[di].SSI_trans, cx
		ret
SlideShowSetTransition	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlideShowSetColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the color

CALLED BY:	MSG_SLIDE_SHOW_SET_TRANSITION

PASS:		*ds:si - SlideShowClass object
		ds:di - SlideShow instance
		dxcx - ColorQuad

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	08/01/00	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SlideShowSetColor	method SlideShowClass,
					MSG_META_COLORED_OBJECT_SET_COLOR
		movdw	ds:[di].SSI_color, dxcx
		ret
SlideShowSetColor	endm

SlideCode	ends

FixedSlideCode	segment	


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlideShowKbdMon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Monitor keyboard input

CALLED BY:	im::ProcessUserInput

PASS:		al	= mask MF_DATA
		di	= event type
		MSG_META_KBD_CHAR:
			cx	= character value
			dl	= CharFlags
			dh	= ShiftState
			bp low	= ToggleState
			bp high = scan code
		si	= event data
		ds 	= seg addr of monitor (idata)

RETURN:		al	= mask MF_DATA if event is to be passed through
			  0 if we've swallowed the event

DESTROYED:	ah, bx, ds, es (possibly)
		cx, dx, si, bp (if event swallowed)
		
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	11/3/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ssKbdShortcuts KeyboardShortcut \
	<0, 0, 0, 0, 0x0, C_SPACE>,		;<spacebar>
	<0, 0, 0, 0, 0xf, VC_ESCAPE>,		;<Esc>
	<0, 0, 0, 0, 0xf, VC_LEFT>,		;<left arrow>
	<0, 0, 0, 0, 0xf, VC_DOWN>,		;<down arrow>
	<0, 0, 0, 0, 0xf, VC_RIGHT>		;<right arrow>

ssMessages word \
	MSG_SLIDE_SHOW_NEXT,			;<spacebar>
	MSG_SLIDE_SHOW_END,			;<Esc>
	MSG_SLIDE_SHOW_PREVIOUS,		;<left arrow>
	MSG_SLIDE_SHOW_END,			;<down arrow>
	MSG_SLIDE_SHOW_NEXT			;<right arrow>

SlideShowKbdMon	proc	far
		.enter

		test	al, mask MF_DATA
		jz	done
	;
	; only track keypresses
	;
		cmp	di, MSG_META_KBD_CHAR
		jne	done
		test	dl, mask CF_RELEASE
		jnz	done
	;
	; see if it's one of ours and handle it
	;
		push	bx, si, di, ds
		mov	bx, ds:ssUIHan
	CheckHack <length ssKbdShortcuts eq length ssMessages>
		mov	ax, (length ssKbdShortcuts)
		segmov	ds, cs
		mov	si, offset ssKbdShortcuts
		call	FlowCheckKbdShortcut
		jnc	consumeMe			;branch if not shortcut
		mov	ax, cs:ssMessages[si]
		mov	si, offset SlideControl		;^lbx:si <- object
		clr	di				;di <- send, no fixup
		call	ObjMessage
	;
	; We don't want the keypress handled elsewhere, so consume the event
	; 
consumeMe:
		clr	al				;gulp...
		pop	bx, si, di, ds
done:

		.leave
		ret
SlideShowKbdMon	endp

FixedSlideCode	ends

end
