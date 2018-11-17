COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	GeoDex
MODULE:		File		
file:		FIleDocument.asm

AUTHOR:		Ted H. Kim, 5/11/90

ROUTINES:
	Name			Description
	----			-----------
	FileInitialize		Intialize a new data file
	FileCreateUI		Enable some GeoDex objects
	FileAttachUI		Display the record
	ReInitIndexList		Redraw the index list
	ClearPhoneStuff		Clear the text objects in Dial Options box
	RestorePhoneStuff	Read in area code and prefix number
	FileReadData		Read in some variables from the map block
	SetSortOption		Update the sorting option dialog box
	CheckLanguage		Get the current language constant
	FileDestroyUI		Disable some GeoDex objects
	FileDetachUI		Clear the fileHandle variable
	FileWriteData		Write out some variables to the map block
	FileSave		Save the currently displayed record
	SavePhoneStuff		Save out area code and prefix number
	FileSaveAsDone		Save the new file handle
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	5/11/90		Initial revision
	ted	8/29/91		Revamped for V2.0
	ted	3/5/92		Complete restructuring for 2.0

DESCRIPTION:
	Contains all method handlers for file menu items.

	$Id: fileDocument.asm,v 1.1 97/04/04 15:49:56 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

File	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileInitialize 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize a new database file for address book.

CALLED BY:	(GLOBAL) MSG_META_DOC_OUTPUT_INITIALIZE_DOCUMENT_FILE

PASS:		cx:dx - document object
		bp - file handle

RETURN:		carry - set if error

DESTROYED:	ax, bx, cx, dx, si, di, bp, es 

PSEUDO CODE/STRATEGY:
	Initialize database file handle and group number
	Create a map block
	Initialize some variables

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	3/22/90		Initial version
	Ted	8/28/91		Uses V2.0 doc control

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileInitialize	proc	far
	class	RolodexClass		; (blanks lines around this line)

	mov	bx, bp			; bx - file handle
	mov	ds:[fileHandle], bx	; save file handle

	; mark document dirty when file is marked dirty

	clr	ah			; no bits to reset
	mov	al, mask VMA_NOTIFY_DIRTY ; notify when file is dirty 
	call	VMSetAttributes		; setup the attribute

	call	DBGroupAllocNO		; allocate a group(same for all records)
	mov	ds:[groupHandle], ax	; save group handle
	mov	cx, (size GeodexMapBlock) ; cx - size of map block
	call	DBAllocNO		; di - allocate a block
	call	DBSetMapNO		; set this block as a map block

	; initialize udata
	;  (reg di have precious a value; using stosb is awkward)

	mov	cx, (size GeodexMapBlock)/2 ; cx - size of udata
	mov	si, offset gmb		; ds:si - ptr to beg of udata
	clr	ax
udataLoop:
	mov	{word} ds:[si], ax	; initialize GMB to all zeroes
	inc	si
	inc	si
	loop	udataLoop
if (size GeodexMapBlock) mod 2
	mov	{byte} ds:[si], al
endif

	; initialize some variables

	clr	ds:[curCharSet]
	clr	ds:[searchFlag]		; clear the filter flag
	clr	ds:[curRecord]		; no record to display
	clr	ds:[curOffset]		; display the 1st record 
	clr	ds:[curLetter]		; no letter tab to invert
	clr	ds:[phoneFlag]		; no phone flags
	clr	ds:[undoItem]		; nothing to undo

	; default sort option is ignore spaces and punctuations

	mov	ds:[gmb.GMB_sortOption], mask SF_IGNORE_SPACE

	; get current language value 

	call	LocalGetLanguage	; ax - StandardLanguage
	mov	ds:[gmb.GMB_curLanguage], ax

	; allocate some DB items

	mov	cx, size TableEntry	; cx - size of data block
	call	DBAllocNO		; allocate the main table
	mov	ds:[gmb.GMB_mainTable], di	; save the handle

	mov	cx, size QuickViewEntry	; cx - size of data block
	call	DBAllocNO		; allocate the frequency table
	mov	ds:[gmb.GMB_freqTable], di	; save the handle

	mov	cx, size QuickViewEntry	; cx - size of data block
	call	DBAllocNO		; allocate the history table
	mov	ds:[gmb.GMB_histTable], di	; save the handle

	call	ClearPhoneStuff		; initialize dial options dialog box
	mov	ds:[recStatus], mask RSF_NEW or mask RSF_EMPTY ; new record
	mov	ds:[curPhoneType], PTI_HOME	; initial phone type name is home
	call	CreatePhoneTypeTable	; create phone name type table

	call	DBLockMapNO		; lock the map block
	mov	di, es:[di]		; es:di - destination (map block)
	mov	si, offset gmb		; ds:si - source (udata)
	copybuf	<size GeodexMapBlock>	; read map block into udata

	call	DBDirty			; mark the map block dirty
	call	DBUnlock		; close up map block
	clc				;no error
	ret
FileInitialize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileCreateUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enable various GeoDex objects for display.

CALLED BY:	(GLOBAL) MSG_META_DOC_OUTPUT_CREATE_UI_FOR_DOCUMENT

PASS:		cx:dx - document object
		bp - file handle

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, di, bp, es 

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	8/28/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileCreateUI		proc	far

	class	RolodexClass

	; enable the main object

	GetResourceHandleNS	BothView, bx
	mov	si, offset BothView	; bx:si - OD of Both View
	call	EnableObject		; enable the Both View

	; enable some menu items

	GetResourceHandleNS	MenuResource, bx
	mov	si, offset EditUndo
	call	EnableObject		
	mov	si, offset EditDeleteRecord	
	call	EnableObject		
	mov	si, offset EditCopyRecord	
	call	EnableObject	
	;mov	si, offset EditPasteRecord	
	;call	EnableObject		
	mov	si, offset RolPrintControl 
	call	EnableObject		
	mov	si, offset ShowCard	
	call	EnableObject		
	mov	si, offset ShowBrowse	
	call	EnableObject	
	mov	si, offset ShowBoth	
	call	EnableObject		
if _QUICK_DIAL
	mov	si, offset QuickDial	
	call	EnableObject		
endif
	mov	si, offset SortOptions	
	call	EnableObject		
if _QUICK_DIAL
	mov	si, offset PhoneOptions	
	call	EnableObject		
endif

if _QUICK_DIAL
	; now clear the monikers of GenTriggers from Quick Dial Window 

	mov	bx, 19			; clear twenty monikers
	shl	bx, 1			; bx - offset into quick dial tables 
mainLoop:
	mov	di, ds:SpeedDialTable[bx]	; di - offset to genTrigger
	call	ClearMoniker			; clear this button
	jc	exit				; if error, exit
	sub	bx, (size nptr)			; update the index 
	jns	mainLoop			; if not done, clear the next
exit:
endif ;if _QUICK_DIAL
	clc				; return with no error
	ret	
FileCreateUI		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileAttachUI 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Display the data from the file just opened.

CALLED BY:	(GLOBAL) MSG_META_DOC_OUTPUT_ATTACH_UI_TO_DOCUMENT

PASS:		cx:dx - document object
		bp - file handle

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, di, bp, es 

PSEUDO CODE/STRATEGY:
	If data file empty, disable some objects
	Give the focus to index field of card view
	Display the record for GeoDex

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	8/28/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileAttachUI		proc	far

	class	RolodexClass

	; copy the data from map block into udata

	mov	ds:[fileHandle], bp	; save the file handle

	call	RolodexNotifyNormalTransferItemChanged

	tst	ds:[startFromScratch]	; started from state file?
	LONG	js	notEmpty	; if so, skip

	tst     ds:[gmb.GMB_numMainTab]         ; is data file empty?
	jne	dontDisable		; if not, skip

	; if database empty, clear the record fields and disable some objects

	call	ClearRecord

	GetResourceHandleNS	MenuResource, bx
	mov	si, offset RolPrintControl ; bx:si - OD of print menu
	call	DisableObject		; disable print menu
	mov	si, offset SortOptions	; bx:si - OD of Sorting Options menu
	call	DisableObject		; disable sort options menu


	call	DisableCopyRecord	; disable copy record menu
	jmp	search
dontDisable:
	call	EnableCopyRecord
search:

if _QUICK_DIAL
	; enable quick dial icon if quick dial tables are not empty
	; and disable it if they are empty

	GetResourceHandleNS	QuickDial, bx
	mov	si, offset QuickDial	; bx:si - OD of quick dial button
	mov	dx, ds:[gmb.GMB_numFreqTab]	; dx - number of entries in freq table
	add	dx, ds:[gmb.GMB_numHistTab]	; add number of entries in hist table 

	tst	dx			; are quick dial tables empty?
	je	disable			; if so, exit

	call	EnableObject		; enable quick dial button
	jmp	common
disable:
	call	DisableObject		; disable quick dial button
common:
endif ;if _QUICK_DIAL

	cmp	ds:[displayStatus], BROWSE_VIEW	; browse view?
	je	skip
	call	FocusSortField		; give focus to index field

	; now display the record for GeoDex
skip:
	tst	ds:[gmb.GMB_numMainTab]		; is database empty?
	jne	notEmpty		; if not, skip
	call	DisplayPhoneType	; display phone type name
	jmp	drawList		; and exit
notEmpty:
	tst	ds:[startFromScratch]	; started from state file?
	jns	display			; if not, skip

	mov	si, ds:[curRecord]	; si - current record handle
	tst	si			; is record blank?
	je	dontRead		; if so, skip
	call	GetLastName		; read index field into sortBuffer
dontRead:
	call	UpdateLetterButton	; invert the correct letter tab
	call	SetUserModifiedState	; set user modified state of objects
	jmp	drawList
display:
	; display the first record of database

	mov	di, ds:[gmb.GMB_mainTable]	; di - handle of main table
	call	FindFirst		; find the handle of the 1st entry
ifdef GPC
	tst	ds:[openApp]		; make it easier for SimulateNoRecord
	jnz	skipInitialDisplay
endif
	call	DisplayCurRecord	; put up contents of the 1st entry
skipInitialDisplay::
	call	DisplayPhoneType	; display phone type name
drawList:
	call	ReInitIndexList		; make the selection
ifdef GPC
	tst	ds:[openApp]
	jnz	skipUpdatePrevNext
	call	UpdatePrevNext
skipUpdatePrevNext:
endif

	clr	ds:[phoneFlag]		; no phone flags
	clr	ds:[searchFlag]		; clear search flag
	clr	ds:[startFromScratch]	; clear the flag
	clr	ds:[ignoreInput]
ifdef GPC
	tst	ds:[openApp]
	jz	notOpenApp
	call	SimulateNoRecord	; do everything as if there is no
					; active record
notOpenApp:
	clr	ds:[openApp]
endif
	clc				; return with no error
	ret
FileAttachUI		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetUserModifiedState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Restores the user modified states of all text objects.

CALLED BY:	(INTERNAL) FileAttachUI

PASS:		dirtyFields

RETURN:		nothing

DESTROYED:	ax, bx, di 

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK 	12/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetUserModifiedState	proc	near
	; check to see if index field was modified before exiting to DOS

	test	ds:[dirtyFields], mask DFF_INDEX 
	je	addr				; if not, check the next field
	GetResourceHandleNS	LastNameField, bx	
	mov	si, offset LastNameField 	; bx:si - OD of LastNameField 
	call	MarkUserModified		; make object user modified 
addr:
	; check to see if address field was modified before exiting to DOS

	test	ds:[dirtyFields], mask DFF_ADDR 
NPZ <	je	note				; if not, check the next field>
PZ <	je	phonetic			; if not, check the next field>
	GetResourceHandleNS	AddrField, bx	
	mov	si, offset AddrField	 	; bx:si - OD of AddrField 
	call	MarkUserModified		; make object user modified 

if PZ_PCGEOS
phonetic:
	; check to see if phonetic field was modified before exiting to DOS
	test	ds:[dirtyFields], mask DFF_PHONETIC
	je	zip				; if not, check the next field
	GetResourceHandleNS	PhoneticField, bx
	mov	si, offset PhoneticField	; bx:si - OD of PhoneticField
	call	MarkUserModified		; make object user modified
zip:
	; check to see if zip field was modified before exiting to DOS
	test	ds:[dirtyFields], mask DFF_ZIP
	je	note				; if not, check the next field
	GetResourceHandleNS	ZipField, bx
	mov	si, offset ZipField		; bx:si - OD of ZipField
	call	MarkUserModified		; make object user modified
endif

note:
	; check to see if notes field was modified before exiting to DOS

	test	ds:[dirtyFields], mask DFF_NOTE 
	je	phoneType			; if not, check the next field
	GetResourceHandleNS	NoteText, bx	
	mov	si, offset NoteText 		; bx:si - OD of NoteText 
	call	MarkUserModified		; make object user modified 
phoneType:
	; check to see if phone type field was modified before exiting to DOS

	test	ds:[dirtyFields], mask DFF_PHONE_TYPE 
	je	phoneNo				; if not, check the next field
	GetResourceHandleNS	PhoneNoTypeField, bx	
	mov	si, offset PhoneNoTypeField 	; bx:si-OD of PhoneNoTypeField 
	call	MarkUserModified		; make object user modified 
phoneNo:
	; check to see if phone no. field was modified before exiting to DOS

	test	ds:[dirtyFields], mask DFF_PHONE_NO 
	je	exit				; if not, exit

	GetResourceHandleNS	PhoneNoField, bx	
	mov	si, offset PhoneNoField 	; bx:si - OD of PhoneNoField 
	call	MarkUserModified		; make object user modified 
exit:
	ret
SetUserModifiedState	endp

MarkUserModified	proc	near

	; mark the text object user modified

	mov	ax, MSG_VIS_TEXT_SET_USER_MODIFIED
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage		
	ret
MarkUserModified	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReInitIndexList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Re-initialize the index list for GeoDex.

CALLED BY:	(GLOBAL)

PASS:		displayStatus - current view mode

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, di

SIDE EFFECTS:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	10/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReInitIndexList		proc	far
	cmp	ds:[displayStatus], CARD_VIEW	; card view only?
	je	done				; if so, exit

	; redraw the index list

	mov	si, offset SearchList 		; bx:si - OD of SearchList 
	GetResourceHandleNS	SearchList, bx	
	mov	cx, ds:[gmb.GMB_numMainTab]	; cx - # of entries in database
	mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
	mov	di, mask MF_FIXUP_DS or mask MF_CALL 
	call	ObjMessage			; redraw the dynamic list

	; select an entry in the index list

	mov	ax, MSG_GEN_ITEM_GROUP_SET_NONE_SELECTED ; assume no selection
	clr	dx				; dx - no indeterminate
	mov	cx, ds:[curOffset]		; offset to the current record
	TableEntryOffsetToIndex	cx		; cx - entry # to select 

	tst	ds:[curRecord]			; is there a blank record?
	je	blank				; if so, skip	
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
blank:
	mov	di, mask MF_FIXUP_DS or mask MF_CALL 
	call	ObjMessage			; make the selection
done:
	ret
ReInitIndexList		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClearPhoneStuff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear text objects in Dial Options box.

CALLED BY:	FileInitialize

PASS:		nothing

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp, di

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClearPhoneStuff	proc	near
	mov	si, offset CurrentAreaCodeField	; OD of text object
	GetResourceHandleNS	CurrentAreaCodeField, bx
	call	ClearTextField		; clear this text object
	mov	si, offset PrefixField	; bx:si - OD of area code text object
	call	ClearTextField		; clear this text object 
	mov	si, offset AssumedAreaCodeField	; bx:si - OD of text object
	call	ClearTextField		; clear this text object
	ret
ClearPhoneStuff	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RestorePhoneStuff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reads in area code and prefix numbers.

CALLED BY:	RestoreData

PASS:		es - segment address of core block

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp, si, di

PSEUDO CODE/STRATEGY:
	If neither area code nor prefix number exit
	If prefix number 
		turn on prefix check box
	If area code exits
		turn on area code check box
	Copy the strings to objects

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	3/22/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RestorePhoneStuff	proc	near

	; display the prefix string inside the PrefixField

	mov	bp, offset ds:gmb.GMB_prefix
	mov     dx, es				; dx:bp - ptr to string
	clr	cx				; the string is null terminated
	mov	si, offset PrefixField 		; bx:si - OD of prefix string
	GetResourceHandleNS	PrefixField, bx	
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	di, mask MF_CALL or mask MF_FIXUP_ES or mask MF_FIXUP_DS
	call	ObjMessage			; copy the string to object

	; display the area code string inside the CurrentAreaCodeField

	mov	bp, offset gmb.GMB_curAreaCode
	mov     dx, es				; dx:bp - points to aread code
	clr	cx				; cx - null terminated
	mov	si, offset CurrentAreaCodeField ; bx:si - OD of area code field
	GetResourceHandleNS	CurrentAreaCodeField, bx	
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	di, mask MF_CALL or mask MF_FIXUP_ES or mask MF_FIXUP_DS
	call	ObjMessage			; copy the string to object

	; display the assumed area code string inside the AssumedAreaCodeField

	mov	bp, offset gmb.GMB_assumedAreaCode
	mov     dx, es				; dx:bp - points to aread code
	clr	cx				; cx - null terminated
	mov	si, offset AssumedAreaCodeField ; bx:si - OD of area code field
	GetResourceHandleNS	AssumedAreaCodeField, bx	
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	di, mask MF_CALL or mask MF_FIXUP_ES or mask MF_FIXUP_DS
	call	ObjMessage			; copy the string to object
	ret
RestorePhoneStuff	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileDestroyUI 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Disable the GeoDex objects before closing 	

CALLED BY:	MSG_META_DOC_OUTPUT_DESTROY_UI_FOR_DOCUMENT

PASS:		cx:dx - document object
		bp - file handle

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, di

PSEUDO CODE/STRATEGY:
	Close some dialog boxes
	Clear all text edit fields
	Disable everything

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	3/22/90		Initial version
	Ted	8/29/91		Revamped for V2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileDestroyUI	proc	far

	class	RolodexClass

	; close any independently displayable GenInteractions

	mov	si, offset NotesBox	; bx:si - OD of note field
	GetResourceHandleNS	NotesBox, bx
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND	
	mov	cx, IC_DISMISS
	mov	di, mask MF_FIXUP_DS	; di - set flags 
	call	ObjMessage		; close down this window if it was up

if _QUICK_DIAL
	mov	si, offset QuickDialWindow  ; bx:si - OD of quick dial window
	GetResourceHandleNS	QuickDialWindow, bx
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND	
	mov	cx, IC_DISMISS
	mov	di, mask MF_FIXUP_DS	; di - set flags 
	call	ObjMessage		; close down this window if it was up
endif ;if _QUICK_DIAL

	cmp	ds:[displayStatus], CARD_VIEW	; card view only?
	je	skip				; if so, exit

	; clear the dynamic list of any entries

	mov	si, offset SearchList 		; bx:si - OD of SearchList 
	GetResourceHandleNS	SearchList, bx	
	clr	cx			; cx - # of entries in database
	mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
	mov	di, mask MF_FIXUP_DS or mask MF_CALL 
	call	ObjMessage			
skip:
	; clear all of text edit fields

	mov	cx, NUM_TEXT_EDIT_FIELDS+1	; cx - number of text fields to clear
	clr	si			; si - points to table of field handles 
	call	ClearTextFields		

	; clear any inverted letter tab

	mov	si, offset MyLetters	; bx:si - OD of Letters gadget 
	GetResourceHandleNS	MyLetters, bx
	mov	ax, MSG_LETTERS_CLEAR
	mov	di, mask MF_CALL or mask MF_FIXUP_DS	
	call	ObjMessage		

	; disable some menus

	GetResourceHandleNS	MenuResource, bx
	mov	si, offset EditUndo
	call	DisableObject		
	mov	si, offset EditDeleteRecord	
	call	DisableObject		
	mov	si, offset EditCopyRecord	
	call	DisableObject	
	mov	si, offset EditPasteRecord	
	call	DisableObject		
	mov	si, offset RolPrintControl 
	call	DisableObject		
	mov	si, offset ShowCard	
	call	DisableObject		
	mov	si, offset ShowBrowse	
	call	DisableObject	
	mov	si, offset ShowBoth	
	call	DisableObject		
if _QUICK_DIAL
	mov	si, offset QuickDial	
	call	DisableObject		
endif ;if _QUICK_DIAL
	mov	si, offset RolPrintControl ; bx:si - OD of print menu
	call	DisableObject		; disable print menu
	mov	si, offset SortOptions	; bx:si - OD of Sorting Options menu
	call	DisableObject		; disable sort options menu
if _QUICK_DIAL
	mov	si, offset PhoneOptions	; bx:si - OD of Dialing Options menu
	call	DisableObject		; disable phone options menu
endif

	mov	si, offset BothView	; bx:si - OD of both view object
	GetResourceHandleNS	BothView, bx
	call	DisableObject		; disable the entire object
	clc				; return with no error
	ret
FileDestroyUI	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileDetachUI 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Just clear the file handle variable

CALLED BY:	MSG_META_DOC_OUTPUT_DETACH_UI_FROM_DOCUMENT

PASS:		cx:dx - document object
		bp - file handle

RETURN:		nothing

DESTROYED:	nothing

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	8/29/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileDetachUI		proc	far

	class	RolodexClass

	clr	ds:[fileHandle]		; clear the file handle
	ret
FileDetachUI		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileReadData 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read in some variables from the map block

CALLED BY:	MSG_META_DOC_OUTPUT_READ_CACHED_DATA_FROM_FILE

PASS:		cx:dx - document object
		bp - file handle

RETURN:		nothing

DESTROYED:	ax, bx, cx, si, di, es

PSEUDO CODE/STRATEGY:
	Read in some variables
	Initialize some more variables

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	8/29/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileReadData		proc	far
	
	class	RolodexClass

	; copy the data from map block into udata

	mov	bx, bp			; bx - file handle
	mov	ds:[fileHandle], bx	; save file handle
	call	DBGetMapNO		; get the map block
	mov	ds:[groupHandle], ax	; save group handle
	call	DBLockNO		; lock the map block
	mov	si, es:[di]		; si - offset to map block data
	push	es			; save seg addr of map block
	push	ds			; save seg addr of core block
	segmov	ds, es			; ds:si - source (map block)
	mov	di, offset gmb
	pop	es			; es:di - destination (udata)
	push	es			; save seg addr of core block
	copybuf	<size GeodexMapBlock>	; read map block into udata

	call	RestorePhoneStuff	; read in area codes and prefix number

	pop	ds			; restore seg addr of core block
	pop	es			; restore seg addr of data block
	call	DBUnlock		; unlock the map block

	; check the language and resort if necessary

	call	CheckLanguage
	call	SetSortOption		; read in sort option
	call	DisableUndo
	clr	ds:[undoItem]		; nothing to undo

	tst	ds:[startFromScratch]	; started from state file?
	jns	skip			; if not, skip 

	; If the user exited to DOS with GeoDex running and then came
	; back up and crashed after modifying GeoDex file, the next
	; time he runs GEOS, he might be restored to the state before 
	; the crash, thereby causing an inconsistency between the state
	; file block data and the actual state of GeoDex file. 

	; check to see if there was a system crash

	call	SysGetConfig
	test	al, mask SCF_CRASHED
	jne	skip			; if crash, reset everything

	; check to see if 'curOffset' is a valid offset

	mov	ax, ds:[curOffset]
	cmp	ax, ds:[gmb.GMB_endOffset]
	jg	skip			; skip to reset if invalid offset

	tst	ds:[curRecord]		; current record blank?
	je	exit			; if so, skip

	; check to see if this is a valid db item handle

	mov	di, ds:[gmb.GMB_mainTable]
	call	DBLockNO		; lock the handle block
	mov	di, es:[di]
	add	di, ds:[curOffset]
	mov	ax, es:[di].TE_item	; ax - current record handle
	call	DBUnlock
	cmp	ax, ds:[curRecord]	; do db item handles match?
	je	exit			; if they do, exit
skip:
	clr	ds:[dirtyFields]
	clr	ds:[curRecord]		; no record to display
	clr	ds:[curOffset]		; display the 1st record
	clr	ds:[curLetter]		; no letter tab to invert
	clr	ds:[curLetterLen]
	clr	ds:[curCharSet]		; current character set
	mov	ds:[recStatus], mask RSF_NEW or mask RSF_EMPTY  ; set flags
	mov	ds:[curPhoneType], PTI_HOME ; initial phone type name is home
	call	ClearRecord		; clear the record
exit:
	ret
FileReadData		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetSortOption
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the sort option DB with the current sort option.	

CALLED BY:	(GLOBAL)

PASS:		gmb.GMB_sortOption - sort option to set

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, di

SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK			Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetSortOption	proc	far
	clr	dx				; dx - not indeterminate 	
	clr	cx				; assume don't ignore spaces 
	test	ds:[gmb.GMB_sortOption], mask SF_IGNORE_SPACE
	je	skip
	inc	cx				; cx - identifier
skip:
	GetResourceHandleNS	SortOptionList, bx
	mov	si, offset SortOptionList	; bx:si - OD of GenItem
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage			; set the selection
	ret
SetSortOption	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckLanguage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the current language constant and resorts the database
		if necessary.

CALLED BY:	(INTERNAL) FileReadData

PASS:		nothing

RETURN:		gmb.GMB_curLanguage - updated

DESTROYED:	ax, bx, cx, dx, si, di

SIDE EFFECTS:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	10/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckLanguage	proc	near
	call	LocalGetLanguage		; get current language

	; check to see if the file was created in different langauge 

	cmp	ds:[gmb.GMB_curLanguage], ax		
	je	exit				; if not, skip

	; if so, we have to resort the database file

	call	ResortDataFile
exit:
	ret
CheckLanguage	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileWriteData 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out some variables to map block

CALLED BY:	MSG_META_DOC_OUTPUT_WRITE_CACHED_DATA_TO_FILE

PASS:		cx:dx - document object
		bp - file handle

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, di, es

PSEUDO CODE/STRATEGY:
	Save the currently displayed record if SAVE or SAVE_AS
	Otherwise, copy out some variables to map block

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	8/29/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileWriteData	proc	far

	class	RolodexClass

	; get what operation is calling this routine

	mov	bx, cx
	mov	si, dx
	mov	ax, MSG_GEN_DOCUMENT_GET_OPERATION	
	mov	di, mask MF_FIXUP_DS or mask MF_CALL	
	call	ObjMessage		

	cmp	ax, GDO_DETACH		; called by DETACH_UI?
	je	dontSave		; if so, skip

	cmp	ax, GDO_AUTO_SAVE	; called by AUTO_SAVE?
	je	dontSave		; if so, skip

	call	FileSave		; save the current record
	;jc	exit
dontSave:
	; copy some variables from udata into map block

	call	DBLockMapNO		; lock the map block
	mov	di, es:[di]		; es:di - destination (map block)
	mov	si, offset gmb		; ds:si - source (udata)
	copybuf	<size GeodexMapBlock>	; read map block into udata

	;call	SavePhoneStuff	; save area code and prefix numbers
	call	DBUnlock		; close up map block
	clc
;exit:
	ret
FileWriteData	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileSave 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Saves the current database file.

CALLED BY:	MSG_META_DOC_OUTPUT_PHYSICAL_SAVE

PASS:		cx:dx - document object
		bp - file handle

RETURN:		carry set if there is an error

DESTROYED:	ax, bx, cx, dx, si, di, es

PSEUDO CODE/STRATEGY:
	Update any changes to the current record
	Copy udata into map block

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	3/22/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileSave	proc	near

	; update the current record if it is modified

	andnf	ds:[recStatus], not mask RSF_WARNING ; clear warning box flag
	ornf	ds:[recStatus], mask RSF_FILE_SAVE	
	call	SaveCurRecord		
	pushf
	andnf	ds:[recStatus], not mask RSF_FILE_SAVE ; clear warning box flag
	popf
	jc	exit			; exit if error
	test	ds:[recStatus], mask RSF_WARNING ; is warning box up?
	stc
	jne	exit			; if so, skip
	test	ds:[recStatus], mask RSF_NEW	; new record?
	je	notNew			; if not, skip
	call	DisableCopyRecord	; disable copy record menu
	jmp	common
notNew:
	call	EnableCopyRecord	; enable copy record menu
common:
	mov	bx, NUM_TEXT_EDIT_FIELDS+1  ; bx - number of fields to compare
	clr	bp			; bp - offset into FieldTable
	call	CompareRecord		; get dirty fields
	clc				; return with no error
exit:
	pushf
	call	DisableUndo		; disable undo menu
	popf
	ret
FileSave	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileSaveAsDone 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Store away the new file handle

CALLED BY:	MSG_META_DOC_OUTPUT_SAVE_AS_COMPLETED

PASS:		cx:dx - document object
		bp - file handle

RETURN:		nothing

DESTROYED:	nothing

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	3/22/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileSaveAsDone	proc	far

	class	GeoDexClass

	mov	ds:[fileHandle], bp 	; user close has not been called
	ret
FileSaveAsDone	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileIncompatibleDoc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert documents w/ old protocol to the current version.

CALLED BY:	MSG_META_DOC_OUTPUT_UPDATE_EARLIER_INCOMPATIBLE_DOCUMENT

PASS:		cx:dx - document object
		bp - file handle

RETURN:		carry - set if error
		ax - non-zero to up protocol

DESTROYED:	cx, dx, bp

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	10/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if not DBCS_PCGEOS
convertLibDir	char	CONVERT_LIB_DIR
convertLibPath	char	CONVERT_LIB_PATH
endif

FileIncompatibleDoc	proc	far

if DBCS_PCGEOS
	stc		;don't load conversion library; return error
else
	class	GeoDexClass

	;  load the conversion library

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
	mov	ax, enum ConvertOldGeoDexDocument
	call	ProcGetLibraryEntry
	call	ProcCallFixedOrMovable
	pop	bx
	call	GeodeFreeLibrary

	mov	ax, -1				; up protocol, please
	clc					; indicate no error
done:

endif
	ret
FileIncompatibleDoc	endp

FileUpdate	proc	far

	class	GeoDexClass

	ret
FileUpdate	endp

File	ends
