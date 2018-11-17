COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	GeoDex
MODULE:		Dial		
FILE:		dialQuickDial.asm

AUTHOR:		Ted H. Kim, 12/5/89

ROUTINES:
	Name			Description
	----			-----------
	RolodexQuick		Method handler for quick window icon
	RolodexQuickButton	Method handler for any quick dial buttons
	UpdatePhoneCount	Updates number of times this number is called
	GetQuickButtonMoniker	Reads the moniker of selected quick button
	DeleteQuickViewEntry2	Same as DeleteQuickViewEntry but called by 
					RolodexQuickButton
	UpdateMonikers		Updates the monikers for GenTriggers
	UpdateFreqTable		Updates the frequency table
	UpdateHistTable		Updates the history table
	ClearMoniker		Erases a moniker for a GenTrigger
	CreateMoniker		Creates monikers for GenTriggers
	InsertQuickDial		Inserts one phone entry to both tables 
	InsertAllQuickViewEntry	Inserts all phone entries to both tables
	InsertQuickViewEntry	Low level routine for previous two routines
	DeleteQuickDial		Deletes all phone entries from both tables
	DeleteQuickViewEntry	Deletes one phone entry from both tables
	ClearMonikerAndDeleteQuickDialEntry
				Clears the moniker and deletes quick dial entry
	CheckForInsertability	Checks to see this entry can be inserted
	AssertGlobalVars	
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	12/5/89		Initial revision
	ted	3/92		Complete restructuring for 2.0

DESCRIPTION:
	Contains routines that manage frequency and history tables.

	$Id: dialQuickDial.asm,v 1.1 97/04/04 15:49:48 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EC < include assert.def >

QuickDialCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RolodexQuick
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Brings up Quick Dial window.

CALLED BY:	(GLOBAL) MSG_ROLODEX_QUICK_DIAL

PASS:		ds - segment address of core block

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, es, si, di, bp 

PSEUDO CODE/STRATEGY:
	If database empty, exit
	Otherwise,
		Update the monikers for buttons
		Initiate the window

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	12/8/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RolodexQuick	proc	far

	class	RolodexClass

	tst	ds:[serialHandle]		; was serial driver loaded?
	jne	noError				; if so, skip

	; if no serial driver loaded, put up a message

	mov	bp, ERROR_NO_SERIAL_DRIVER	; bp - error constant
	call	DisplayErrorBox			; put up the error box
	jmp	short	exit			; jump to exit

noError:
	mov	dx, ds:[gmb.GMB_numFreqTab]	; dx - number of entries in freq table
	add	dx, ds:[gmb.GMB_numHistTab]	; add number of entries in hist table 

	tst	dx			; are quick dial tables empty?
	je	exit			; if so, exit

	ornf	ds:[phoneFlag], mask PF_TABLE_DIRTY	; update monikers
	call	UpdateMonikers		; update the monikers for buttons
	jc	exit			; exit if error

	; mark the quick dial window usable

	mov	si, offset QuickDialWindow ; bx:si - OD of quick window
	GetResourceHandleNS	QuickDialWindow, bx	
	mov	ax, MSG_GEN_SET_USABLE
	mov	di, mask MF_FIXUP_DS	; di - set flags 
	mov	dl, VUM_NOW		; do it right now
	call	ObjMessage		; make the window usable

	; bring up the quick dial window

	mov	ax, MSG_GEN_INTERACTION_INITIATE
	mov	di, mask MF_FIXUP_DS	; di - set flags 
	call	ObjMessage		; display the window
exit:
	ret
RolodexQuick	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RolodexQuickButton
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Called when one of the speed dial buttons on "Quick View"
		is pressed to make a phone call.

CALLED BY:	MSG_ROLODEX_QUICK_BUTTON

PASS:		cx - button number (0 through 19)
		cx = -1 means called by confirm box dial button

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, es, si, di, bp

PSEUDO CODE/STRATEGY:
	Delete the old phone entry
	Update phone call count
	Re-insert the new phone entry

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	12/11/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RolodexQuickButton	proc	far

	class	RolodexClass

	tst	cx			; called by confirm box dial button?
	LONG	js	dial		; if so, skip

	; figure out which button has been pressed

EC <	call	AssertGlobalVars					>
	mov	ds:[quickButtonNo], cx	; save the button number
	cmp	cx, COUNT_QUICK_PHONE_NUMBERS	; is it a frequency button?
	jl	freq			; if so, skip
	mov	dx, ds:[gmb.GMB_numHistTab]	; dx - # of entries in history table
	add	dx, COUNT_QUICK_PHONE_NUMBERS	; check other side
	cmp	cx, dx			; is it a blank button?
	jl	common			; if not, jump
	jmp	exit
freq:
	cmp	cx, ds:[gmb.GMB_numFreqTab]	; is it a blank button?
	LONG	jge	exit		; if so, exit

common:
	call	OpenComPort		; open up the serial port
	LONG	jc	exit		; if error, exit

	; copy the moniker of the button into a memory block
	mov	cx, ds:[quickButtonNo]
	call	GetQuickButtonMoniker	

	andnf	ds:[phoneFlag], not mask PF_CONFIRM ; clear confirm box flag 

	; check to see if 'confirm before dialing' option has been set

	mov	si, offset DialingOptions	; bx:si - OD of check box
	GetResourceHandleNS	DialingOptions, bx
	mov	ax, MSG_GEN_BOOLEAN_GROUP_IS_BOOLEAN_SELECTED	
	mov	cx, mask DOF_CONFIRM		; cx - identifier
	mov	di, mask MF_CALL or mask MF_FIXUP_DS	
	call	ObjMessage			; get the state of check box 
	LONG	jnc	off			; if off, skip

	mov	bx, ds:fieldHandles[TEFO_PHONE_NO]	; bx - handle of data block
	tst	bx				; no data block?
	LONG	je	exit			; if none, just exit

	; if on, get the phone number to display in confirm box

	call	GetPhoneNumber		; grab the phone number to display 

EC <	call	AssertGlobalVars					>

	mov	dx, ds:[phoneNoBlk]	; dx - seg address of phone number
	mov	di, ds:[phoneOffset]
	LocalPrevChar	esdi		; di - total number chars in string

	mov	es, dx
	LocalClrChar	es:[di]		; null terminate the string

	; display the string inside the confirm dialog box

	clr	bp			; dx:bp - ptr to string
	clr	cx			; the string is null terminated
	mov	si, offset ConfirmEditBox2 	; bx:si - OD of text edit obj
	GetResourceHandleNS	ConfirmEditBox2, bx	
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			; display the instruction

	; bring up the confirm dial dialog box

	mov	si, offset ConfirmBox2	; bx:si - OD of dialog box
	GetResourceHandleNS	ConfirmBox2, bx 
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage		; make the dialogue box appear

	mov	bx, ds:fieldHandles[TEFO_PHONE_NO]	; bx - handle of data block
	tst	bx			; no mem block to delete?
	LONG	je	exit		; if none, exit
	call	MemFree			; delete it
	clr	ds:fieldHandles[TEFO_PHONE_NO]	; clear the handle in table

	mov	bx, ds:[phoneHandle]	; bx - handle of phone number block
	call	MemFree			; delete it
	jmp	exit			; and exit
dial:
	; copy the phone number inside the confirm box into a memory block

	ornf	ds:[phoneFlag], mask PF_CONFIRM ; confirm box was up 
	GetResourceHandleNS	ConfirmEditBox2, bx
	mov	si, offset ConfirmEditBox2	; bx:di - OD of area code field
	call	GetTextInMemBlock		; read in text string, cx=len
	tst	cx				; no text?
	LONG	je	exit			; exit then
DBCS<	shl	cx, 1				; cx - string size	>
	mov	ds:[phoneHandle], ax		; save the handle
	mov	ds:[phoneOffset], cx		; save # of bytes in string

	mov	bx, ax				; handle of data block
	call	MemLock				; lock this block
	mov	es, ax
	mov	di, cx				; es:di - ptr to end of data
SBCS <	mov	{char} es:[di], C_CR		; terminate the string w/ CR>
DBCS <	mov	{wchar} es:[di], C_CR		; terminate the string w/ CR>
	call	MemUnlock			; unlock the data block
	LocalNextChar	ds:[phoneOffset]	; add one for CR

off:
	call	DialUp			; call this number
	LONG	jc	exit		; if error, exit

	mov	cx, ds:[quickButtonNo]	; save the button number
	ornf	ds:[phoneFlag], mask PF_QUICK_BUTTON ;set quick button flag 
	mov	di, ds:[gmb.GMB_freqTable]	; assume frequency table 
	cmp	cx, 10			; is it a frequency button?
	jl	delete			; if so, skip

	; delete the entry that was clicked upon from the history table

	mov	di, ds:[gmb.GMB_histTable]	; di - history table is searched
	sub	cx, 10			; cx - button number
	call	DeleteQuickViewEntry2	; delete the old phone entry

EC <	call	AssertGlobalVars					>

	dec	ds:[gmb.GMB_numHistTab]		; if so, update the count 
EC <	ERROR_S	ILLEGAL_HIST_TABLE_ENTRY_NUMBER				>
	sub	ds:[gmb.GMB_offsetHistTab], size QuickViewEntry	; update the offset

	; and update the history table with a new entry

	mov	cl, al			; cl - phone number type name ID #

	call	UpdatePhoneCount	; update phone call counter

EC <	call	AssertGlobalVars					>

	call	UpdateHistTable		; update history table

EC <	call	AssertGlobalVars					>

	andnf	ds:[phoneFlag], not mask PF_QUICK_BUTTON ; clear the flag
	ornf	ds:[phoneFlag], mask PF_DONT_CLEAR	; don't clear moniker
	call	UpdateFreqTable		; update frequency table

EC <	call	AssertGlobalVars					>

	jmp	short	update
delete:
	; delete the entry that was clicked upon from the frequency table

	call	DeleteQuickViewEntry2	; delete the old phone entry
	dec	ds:[gmb.GMB_numFreqTab]		; if so, update the count 
EC <	ERROR_S	ILLEGAL_FREQ_TABLE_ENTRY_NUMBER				>
	sub	ds:[gmb.GMB_offsetFreqTab], size QuickViewEntry	; update the offset

	; and update the frequency table with a new entry

	mov	cl, al			; cl - phone number type name ID #

EC <	call	AssertGlobalVars					>

	call	UpdatePhoneCount	; update phone call counter

EC <	call	AssertGlobalVars					>

	call	UpdateFreqTable		; update frequency table

EC <	call	AssertGlobalVars					>

	andnf	ds:[phoneFlag], not mask PF_QUICK_BUTTON ; clear the flag
	ornf	ds:[phoneFlag], mask PF_DONT_CLEAR	; don't clear moniker
	call	UpdateHistTable		; update history table
update:
	; update the monikers inside the quick dial window

	andnf	ds:[phoneFlag], not mask PF_DONT_CLEAR	; clear the flag
	ornf	ds:[phoneFlag], mask PF_TABLE_DIRTY	; update monikers

EC <	call	AssertGlobalVars					>

	call	UpdateMonikers		; update the monikers
	mov	bx, ds:fieldHandles[TEFO_PHONE_NO]	; bx - handle of text data block
	tst	bx			; is it already freed?
	je	exit			; if so, exit
	call	MemFree			; if not, delete it
	clr	ds:fieldHandles[TEFO_PHONE_NO]	; clear the handle in table
exit:
	ret
RolodexQuickButton	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdatePhoneCount
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Increments the number of times this phone number is called
		in database.

CALLED BY:	RolodexQuickButton, RolodexDial

PASS:		cl - phone number type name ID number
		bx - handle of record that contains the phone number

RETURN:		cl - phone number type name ID number
		bp - # of times this phone number is called

DESTROYED:	ax, di, es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	5/7/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdatePhoneCount	proc	far

	push	dx
	mov	al, cl			; al - phone number type name ID 
	mov	di, bx			; di - record handle of data block 

	; lock the current record entry and go to the beg. of phone entries

	call	DBLockNO
	mov	di, es:[di]		; di - ptr to beg of data
	mov	cx, es:[di].DBR_noPhoneNo	; cx - # of phone entries
	add	di, es:[di].DBR_toPhone	; di - ptr to beg of phone entries
miniLoop:
	; find the phone entry that needs to be updated

	cmp	al, es:[di].PE_type	; is this the # we are looking for?
	je	found			; if so, exit the loop
if DBCS_PCGEOS
	mov	dx, es:[di].PE_length	; length of phone string
	shl	dx, 1			; size of phone string in bytes
	add	di, dx
else
	add	di, es:[di].PE_length	
endif
	add	di, size PhoneEntry	; di - points to the next phone entry
	loop	miniLoop
found:
	; increment the phone count

	mov	cl, al			; cl - phone number type name ID #
	mov	bp, es:[di].PE_count	; bp - # of times called
	inc	es:[di].PE_count	; update the phone call count
	call	DBUnlock
	pop	dx
	ret
UpdatePhoneCount	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetQuickButtonMoniker		
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reads the moniker of the quick button that is selected into
		a global memory block

CALLED BY:	RolodexQuickButton

PASS:		cx - button number that is pressed
		ds - dgroup

RETURN:		nothing 

DESTROYED:	ax, bx, dx. di, si, es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	4/16/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetQuickButtonMoniker	proc	near

	; figure out which table to search

	mov	di, ds:[gmb.GMB_freqTable]	; assume frequency table 
	cmp	cx, COUNT_QUICK_PHONE_NUMBERS	; is it a frequency button?
	jl	common				; if so, skip
	mov	di, ds:[gmb.GMB_histTable]	; di - history table is searched
	sub	cx, COUNT_QUICK_PHONE_NUMBERS	; cx - button number
common:
	; get the handle of DB item and phone name ID for this button 

	call	DBLockNO		; es:di <- ptr to item
	mov	di, es:[di]		; open up frequency table
	mov	dx, cx
	shl	dx, 1
	shl	dx, 1			; dx - button number * 4
	add	dx, cx 			; dx - button number * 5
CheckHack < (size QuickViewEntry) eq 5 >
	add	di, dx			; di - pointer to this phone entry
	mov	bx, es:[di].QVE_item	; bx - record handle of this entry
	mov	al, es:[di].QVE_phoneID	; al - phone number type name ID number
	call	DBUnlock

	; lock the record entry with this phone number

	mov	di, bx			; handle of record w/ the phone number
	call	DBLockNO
	mov	di, es:[di]		; open up this record
	mov	cx, es:[di].DBR_noPhoneNo ; cx - number of phone type names
	add	di, es:[di].DBR_toPhone	; di - points to beg. of phone data
loop1:
	; loop until we get to this phone entry

	cmp	al, es:[di].PE_type	; al - phone name type ID
	je	found
notFound:
if DBCS_PCGEOS
	push	ax
	mov	ax, es:[di].PE_length
	shl	ax, 1			; ax - phone string size
	add	di, ax			; advance record ptr
	pop	ax
else
	add	di, es:[di].PE_length	; advance record ptr
endif
	add	di, size PhoneEntry	; di - points to the next phone number
	loop	loop1			; continue
	jmp	short	noError
found:
	tst	es:[di].PE_length	; is there a phone # associated w/ it?
	je	notFound		; if not, continue searching

	; allocate a new memory block

	mov	ax, es:[di].PE_length	; ax - size of memory block to allocate
	mov	ds:fieldLengths[TEFO_PHONE_NO], ax	; save the size of phone number
DBCS<	shl	ax, 1			; ax - string size		>
	add	di, size PhoneEntry	; di - points to the next phone number
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK		; HeapAllocFlags
	call	MemAlloc
EC <	Assert	dgroup	ds						>
	mov	ds:fieldHandles[TEFO_PHONE_NO], bx	; save the mem handle
	mov	cx, ds:fieldLengths[TEFO_PHONE_NO]	; cx - number of chars to copy

	; copy the phone number from the record into a memory block

	push	ds
	push	es
	push	es, di
	mov	es, ax			; set up the segment
	clr	di			; ES:DI starts the string
	pop	ds, si
	LocalCopyNString
	pop	es
	pop	ds
noError:
	call	DBUnlock
	ret
GetQuickButtonMoniker	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeleteQuickViewEntry2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Dose the same thing as DeleteQuickViewEntry except that 
		this routine is called when you know which button is 
		being deleted. 

CALLED BY:	RolodexQuickButton

PASS:		di - handle of quick dial table to delete from
		cx - quick button number

RETURN:		al - phone number type name ID #
		bx - record handle of entry just deleted
		bp - number of phone calls made to this number

DESTROYED:	es, di, cx, dx

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	12/12/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeleteQuickViewEntry2	proc	near
	push	di			; save handle of table
EC <	Assert	vmFileHandle ds:[fileHandle]				>
	call	DBLockNO		
	mov	di, es:[di]		; open up frequency or history table
	mov	dx, cx
	shl	dx, 1
	shl	dx, 1			; dx - button number * 4
	add	dx, cx 			; dx - button number * 5
CheckHack < (size QuickViewEntry) eq 5 >
	add	di, dx			; di - pointer to this phone entry
	mov	bx, es:[di].QVE_item	; bx - record handle of this entry
	mov	bp, es:[di].QVE_key	; bp - number of phone calls made 
	mov	al, es:[di].QVE_phoneID	; al - phone number type name ID number
	call	DBUnlock
	pop	di			; restore handle of quick dial table
	mov	cx, size QuickViewEntry	; cx - number of bytes to delete
	call	DBDeleteAtNO		; delete the old phone entry
	ret
DeleteQuickViewEntry2	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateMonikers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Re-creates monikers for both frequency and history
		phone entries.

CALLED BY:	UTILITY

PASS:		gmb.GMB_numFreqTab - number of frequency table entries
		gmb.GMB_numHistTab - number of history table entries

RETURN:		carry set if error found		

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	For all the entries in frequency table
		Create a moniker for each button
	For all the entries in history table
		Create a moniker for each button
	Update the changes all at once

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	12/5/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateMonikers	proc	far
EC <	Assert	dgroup	ds						>
	test	ds:[phoneFlag], mask PF_TABLE_DIRTY ; quickdial table chaned?
	je	quit			; if not, just exit 
	push	ax, bx, cx, dx, es, ds, si, di, bp

	mov	dx, ds:[gmb.GMB_numFreqTab]	; dx - number of entries in freq table
	add	dx, ds:[gmb.GMB_numHistTab]	; add number of entries in hist table 

	tst	dx			; are quick dial tables empty?
	je	setUnusable		; set the window unuable

	mov	cx, ds:[gmb.GMB_numFreqTab]	; cx - number of frequency entries
loop1:
	; update the monikers for the frequency table

	ornf	ds:[phoneFlag], mask PF_FREQ_TABLE	; do frequency table
	call	CreateMoniker		; create new monikers 
	jc	exit			; exit if error
	loop	loop1			; next entry

	mov	cx, ds:[gmb.GMB_numHistTab]	; cx - number of history table entries
loop2:
	; update the monikers for the frequency table

	andnf	ds:[phoneFlag], not mask PF_FREQ_TABLE	; do history table
	call	CreateMoniker		; create new monikers
	loop	loop2			; next entry

	; update the quick dial window with the new monikers

	mov	si, offset QuickDialWindow	; bx:si - OD of quick window
	GetResourceHandleNS	QuickDialWindow, bx	
	mov	ax, MSG_GEN_UPDATE_VISUAL
	mov	di, mask MF_FIXUP_DS	; di - set flags 
	mov	dl, VUM_NOW		; update it now
	call	ObjMessage		; display new buttons
noError:
	clc				; exit with no error	
exit:
	DoPop	bp, di, si, ds, es, dx, cx, bx, ax
quit:
	pushf
	andnf	ds:[phoneFlag], not mask PF_TABLE_DIRTY ; clear the flag
	popf
	ret

setUnusable:
	; mark the quick dial buttons unusable

	mov	si, offset QuickDialWindow	; bx:si - OD of quick window
	GetResourceHandleNS	QuickDialWindow, bx
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	di, mask MF_FIXUP_DS	
	mov	dl, VUM_NOW		; do it right now
	call	ObjMessage		; make the window disappear
	jmp	short	noError	
UpdateMonikers	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateFreqTable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Updates the frequency table after a phone call 
		has been made to one of the numbers in the table. 

CALLED BY:	RolodexDial

PASS:		bx - current record handle
		bp - number of phone calles made
		cl - phone number type name ID #
		gmb.GMB_freqTable - handles of frequency table 
		gmb.GMB_numFreqTab - number of entries in freq. table

RETURN:		gmb.GMB_numFreqTab is updated
		cl - phone number type name ID #
		carry flag set if error

DESTROYED:	ax, bx, cx, dx, es, di, bp

PSEUDO CODE/STRATEGY:
	Locate the number that is called from the table
	Delete this phone entry
	Up the phone call count by one
	Find the place to insert this phone entry
	Insert it

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	12/8/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateFreqTable		proc	far
	test	ds:[phoneFlag], mask PF_QUICK_BUTTON ; one of quick buttons? 
	jne	search				; if so, find a place to insert

	ornf	ds:[phoneFlag], mask PF_FREQ_TABLE	; update freq. table
	andnf	ds:[phoneFlag], not mask PF_DELETE_ALL	; delele one entry
	mov	di, ds:[gmb.GMB_freqTable]		; di - handle of frequency tab
	mov	ax, ds:[gmb.GMB_numFreqTab]		; ax - number entries in table
	tst	ax				; is freq. table empty
	jne	delete				; if so, just insert	
	mov	al, cl				; al - phone # type name ID 
	jmp	short	search			; skip to insert this entry
delete:
	; delete the old quick dial entry

	call	DeleteQuickViewEntry		
	jc	error				; exit if error
search:						; bp - phone call count
	; find a place to inser the new quick dial entry

	inc	bp				; one more phone call is made
	mov	di, ds:[gmb.GMB_freqTable]	; di - handle of frequency tab
	call	DBLockNO
	mov	di, es:[di]			; open it frequency table
	mov	dx, di				; dx - ptr to place to insert
	mov	cx, ds:[gmb.GMB_numFreqTab]	; cx - number of phone entries
						; if table empty (cx == 0),
	jcxz	found				; we found a place to insert
loop2:
	cmp	bp, es:[di].QVE_key		; check for # of phone calls
	jg	found				; skip if greater than or equal
	add	di, size QuickViewEntry		; otherwise, 
	loop	loop2				; check the next entry
found:
	xchg	dx, di
	sub	dx, di				; dx - offset to place to insert

	call	DBUnlock

	; exit if the frequency table is already full

	cmp	ds:[gmb.GMB_numFreqTab], MAX_FREQ_ENTRY	
	je	exit				

	; otherwise, insert the new entry into the frequency table

	mov	di, ds:[gmb.GMB_freqTable]	; di - handle of table to insert
	call	InsertQuickViewEntry		; insert updated phone entry
	mov	cl, al				; al - phone number ID
	inc	ds:[gmb.GMB_numFreqTab]		; update number of entries
EC <	cmp	ds:[gmb.GMB_numFreqTab], MAX_FREQ_ENTRY			>
EC <	ERROR_G	ILLEGAL_FREQ_TABLE_ENTRY_NUMBER				>
	add	ds:[gmb.GMB_offsetFreqTab], size QuickViewEntry	; update the offset

	; enable the quick dial icon

	push	bx				; save handle of DB block
	GetResourceHandleNS	QuickDial, bx
	mov	si, offset QuickDial	; bx:si - OD of quick dial button
	call	EnableObject			; enable this button
	pop	bx				; restore handle of DB block
exit:
	clc					; exit with no error
error:
	ret
UpdateFreqTable		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateHistTable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Updates history phone entry table after a phone call has
		been made to one of the numbers in the table.

CALLED BY:	RolodexDial

PASS:		bx - current record handle
		cl - phone number type name ID #
		gmb.GMB_histTable - handle of history table
		gmb.GMB_numHistTable - number of history table phone entries

RETURN:		gmb.GMB_numHistTable is updated
		cl - phone number type name ID #
		bx - current record handle
		carry flag set if error

DESTROYED:	ax, bx, cx, dx, es, bp, di	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	12/7/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateHistTable		proc	far
	test	ds:[phoneFlag], mask PF_QUICK_BUTTON ; one of quick buttons? 
	jne	insert				; if so, skip to insert
	andnf	ds:[phoneFlag], not mask PF_FREQ_TABLE	; search history table
	andnf	ds:[phoneFlag], not mask PF_DELETE_ALL	; delete only one entry 
	mov	di, ds:[gmb.GMB_histTable]	; di - handle of history table
	mov	ax, ds:[gmb.GMB_numHistTab]	; ax - number of entries
	tst	ax				; is hist. table empty?
	jne	delete				; if so, just insert
	mov	al, cl				; al - phone # type name ID	
	jmp	short	insert			; skip to insert this entry
delete:
	; delete the old quick dial entry

	call	DeleteQuickViewEntry		; delete the old entry
	jc	error				; exit if error
insert:
	; insert the new quick dial entry

	clr	dx				; dx - insert it at the beg.
	mov	di, ds:[gmb.GMB_histTable]		; di - handle of hist table
	call	InsertQuickViewEntry		; insert the phone entry
	mov	cl, al				; al - phone number ID
	inc	ds:[gmb.GMB_numHistTab]			; update total # of entries 
EC <	cmp	ds:[gmb.GMB_numHistTab], MAX_FREQ_ENTRY				>
EC <	ERROR_G	ILLEGAL_HIST_TABLE_ENTRY_NUMBER				>
	add	ds:[gmb.GMB_offsetHistTab], size QuickViewEntry	; update the offset

	; enable the quick dial icon

	push	bx				; save record handle
	GetResourceHandleNS	QuickDial, bx
	mov	si, offset QuickDial	; bx:si - OD of quick dial button
	call	EnableObject			; enable this button
	pop	bx				; restore record handle
	clc					; exit with no error
error:
	ret
UpdateHistTable		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClearMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Erases the contents of monikers for quick dial buttons.
		You are always clearing the last moniker

CALLED BY:	DeleteQuickViewEntry	

PASS:		phoneFlag - flag indicating which table is being searched
		di - offset to genTrigger object

RETURN:		nothing

DESTROYED:	di, bx

NOTE:		You are always clearing the last moniker for the remaining
		entries will be moved up one trigger.

PSEUDO CODE/STRATEGY:
	Allocat a data block
	Initialize some variables
	Copy the empty string
	Create a chunk for this string inside UI block
	Set the moniker for the button

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Right now, empty button is represented by a space character.
	We might change this to something else.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	12/8/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClearMoniker	proc	far	uses	ax, bx, cx, dx, si, bp, es
	.enter

	; allocate a new memory block for the moniker

	push	di				; save offset of trigger obj
SBCS <	mov	ax, 2*(size char)+(size word)	; ax - size of mem block >
DBCS <	mov	ax, 2*(size wchar)+(size word)	; ax - size of mem block >
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK	; HeapAllocFlags | HeapFlags
	call	MemAlloc			; allocate the block
	mov	es, ax				; set up the segment
	mov	es:[0], bx			; store the block handle
	mov	di, (size hptr)			; ES:DI starts the string

	; initialize it with a space character
	LocalLoadChar	ax, ' '			; just store a space char
	LocalPutChar	esdi, ax
	LocalClrChar	ax			; null terminator
	LocalPutChar	esdi, ax

	pop	si				
	GetResourceHandleNS	MenuResource, bx  ; bx:si - OD of genTrigger

	; set the new moniker for the quick dial button

	mov	di, (size hptr)
	mov	cx, es
	mov	dx, di				; es:di - ptr to the string 
	mov	bp, VUM_MANUAL
 	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_TEXT
	mov	di, mask MF_CALL or mask MF_FIXUP_DS or mask MF_FIXUP_ES 
	call	ObjMessage			; set the new moniker

	mov	bx, es:[0]			; put block handle in BX
	call	MemFree				; free it up
	clc					; exit with no error

	.leave
	ret
ClearMoniker	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates a new moniker for a GenTrigger.

CALLED BY:	UpdateMonikers	

PASS:		cx - indicates which button is being created

RETURN:		carry flag set if error

DESTROYED:	ax, bx, dx, es, bp, si, di

PSEUDO CODE/STRATEGY:
	Allocate a data block
	Initialize some variables
	Copy the index field text string 
	Copy the phone number type name field text string
	Create a chunk for this string inside UI block
	Set the moniker for the button

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	12/8/89		Initial version
	witt	1/24/94		DBCS-ized

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateMoniker	proc	near

	; create a new memory block for the vis moniker

	push	cx				; # of monikers left to set
	mov	ax, PHONE_MONIKER_SIZE		; ax - # of bytes to allocate
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK	; HeapAllocFlags | HeapFlags
	call	MemAlloc			; allocate the block
	mov	es, ax				; set up the segment
	mov	es:[0], bx			; store the block handle
	mov	di, (size hptr)			; ES:DI starts the string

	pop	cx				; cx - # of monikers left 
	push	cx
	push	ds
	push	es				; save segment registers
	push	di				; es:di - destination

	dec	cx
	mov	ax, size QuickViewEntry		; ax - size of phone entry
	mul	cx				; cx - offset to entry
	mov	di, ds:[gmb.GMB_freqTable]	; di - handle of freq. table
	test	ds:[phoneFlag], mask PF_FREQ_TABLE	; search freq. table?
	jne	lockBlock			; if so, skip
	mov	di, ds:[gmb.GMB_histTable]	; if not, get the right handle
lockBlock:
	; lock the proper quick dial table

	call	DBLockNO
	mov	di, es:[di]			; open up the table
	add	di, ax				; di - points to entry
	mov	bl, es:[di].QVE_phoneID		; bl - phone name type ID
	mov	di, es:[di].QVE_item		; di - handle of this record
	call	DBUnlock

	; lock the record entry with this quick dial phone entry 

	call	DBLockNO			
	mov	si, es:[di]

if PZ_PCGEOS
	; use phonetic field if exists rather than index field 
	mov	cx, es:[si].DBR_phoneticSize	; cx - size of phonetic field
	mov	ax, es:[si].DBR_toPhonetic	; assume phonetic field exists
	tst	cx				; is phonetic field empty?
	jne	useIt				; if so, use it!
	mov	cx, es:[si].DBR_indexSize	; cx - size of index field
	mov	ax, size DB_Record		; ax - offset to index field
useIt:
	add	si, ax				; si - ptr to non Null field
	tst	cx				; is index field empty?
	je	copyString
else
	mov	cx, es:[si].DBR_indexSize	; cx - size of index field
	tst	cx				; is index field empty?
	je	copyString			; if so, copy just phone type
endif
	LocalPrevChar	escx			; sub one for null terminator

if DBCS_PCGEOS
	mov	dx, PHONE_MONIKER_SIZE-(size wchar)
	cmp	cx, dx
	jl	copyString
	mov	cx, dx				; max is MONIKER_SIZE-1char
copyString:
	sub	dx, cx				; dx - number of bytes left
else
	cmp	cx, PHONE_MONIKER_SIZE-(size char); is it longer than 29 chars?
	jl	copyString			; if not, skip
	mov	cx, PHONE_MONIKER_SIZE-(size char) ; if so, copy only 29 chars
copyString:
	mov	dx, PHONE_MONIKER_SIZE-(size char)
	sub	dx, cx				; dx - number of byets left
endif

NPZ <	add	si, size DB_Record					>

	segmov	ds, es				; ds:si - source string
	pop	di
	pop	es				; es:di - destination string

	; copy the index field into the moniker block

EC <	Assert	okForRepMovsb						>
	rep	movsb				; copy the name

	tst	dx				; is buffer full?
	je	setMoniker			; if so, skip

	LocalLoadChar	ax, '/'			; put '/' b/w phone # and type
	LocalPutChar	esdi, ax

	LocalPrevChar	esdx			; if buffer now full?
	je	setMoniker			; if so, skip

	push	es
	segmov	es, ds				; es - seg address of data block
	call	DBUnlock			; close this record
	pop	es
	pop	ds

	push	ds				; ds - seg address of core block
	push	es, di

	clr	bh				; bx - phone number type ID #
	shl	bx, 1				; bx - offset to string offset
	tst	bx				; is offset zero?
	jne	nonZero				; if not, skip
	mov	bx, 2				; if so, adjust the offset
nonZero:
	; lock the phone type name block

	mov	di, ds:[gmb.GMB_phoneTypeBlk]		; di - handle of phone name blk
	call	DBLockNO
	mov	di, es:[di]			; open up this block
	mov	si, di
	add	di, bx				; di - ptr to string offset
	add	si, es:[di]			; si - ptr to text string
	segmov	ds, es				; ds:si - phone type name string

	pop	es, di				; es:di - destination
loop1:
	; copy the phone type name into the moniker block

	LocalGetChar	ax, dssi		; read in a character
	LocalIsNull	ax			; are we done?

	je	setMoniker			; if so, skip
	LocalPutChar	esdi, ax		; if not, store the character

	LocalPrevChar	esdx			; is buffer full?
	jne	loop1				; if not, continue
setMoniker:

	LocalClrChar	ax			; null-terminate the buffer
	LocalPutChar	esdi, ax

	push	es
	segmov	es, ds				; es - seg address of data block
	call	DBUnlock			; close this record
	pop	es				; es - seg addr of dest. record

	; copy the moniker chunk into the correct block

	pop	ds				; ds - seg address of core block

	pop	bx				; bx - # of monikers left
	push	bx
	dec	bx
	shl	bx, 1				; bx - offset to offset table
	mov	si, ds:[SpeedDialTable][bx]	; si - handle of moniker to set
	test	ds:[phoneFlag], mask PF_FREQ_TABLE	; do frequency table?
	jne	frequentTable			; if so, skip
	mov	si, ds:[HistoryTable][bx]	; if not, do history table
frequentTable:

	; and set the new moniker
	
	GetResourceHandleNS	MenuResource, bx; bx - handle of UI block

	mov	di, (size hptr)			; string is after handle
	mov	cx, es
	mov	dx, di				; es:di - ptr to the string 
	mov	bp, VUM_MANUAL
 	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_TEXT
	mov	di, mask MF_CALL or mask MF_FIXUP_DS or mask MF_FIXUP_ES 
	call	ObjMessage			; set new moniker

	mov	bx, es:[0]			; put block handle in BX
	call	MemFree				; free it up
	pop	cx				; restore the counter
	clc
	ret
CreateMoniker	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InsertQuickDial
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Inserts new phone entry into both frequency and history
		table.

CALLED BY:	UTILITY

PASS:		gmb.GMB_freqTable, gmb.GMB_histTable - handles of tables
		gmb.GMB_numFreqTab, gmb.GMB_numHistTab - number of entries 
		gmb.GMB_offsetFreqTab, gmb.GMB_offsetHistTab - offset to place to insert
		al - phone number type name ID number
		bp - phone call count

RETURN:		gmb.GMB_numFreqTab, gmb.GMB_numHistTab,
		gmb.GMB_offsetFreqTab, gmb.GMB_offsetHistTab all updated

DESTROYED:	ax, bx, cx, dx, es, si, di

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	8/29/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InsertQuickDial	proc	near
	mov	bx, ds:[curRecord]	; bx - current record handle
	cmp	ds:[gmb.GMB_numFreqTab], MAX_FREQ_ENTRY	; is frequency table full?
	je	history			; skip if so

	; lock the frequency table

	mov	di, ds:[gmb.GMB_freqTable]	; di - handle of frequency table
	mov	cx, ds:[gmb.GMB_numFreqTab]	; cx - # of entries in frequency table
	call	DBLockNO			
	mov	di, es:[di]		; open up frequency table
	mov	dx, di			; di - offset to beg. of data
	tst	cx			; is table empty?
	je	found1			; if so, found a place to insert
miniLoop1:
	; find the place to insert a quick dial entry into frequency table

	cmp	bp, es:[di].QVE_key	; is this # called more times?
	jg	found1			; if so, we've found a place to insert
	add	di, size QuickViewEntry	; if not greater, check the next entry 
	loop	miniLoop1
found1:
	; inser the quick dial entry

	sub	di, dx			; di - offset to insert at
	mov	dx, di			; dx - offset to insert at
	call	DBUnlock		; unlock the data block
	mov	di, ds:[gmb.GMB_freqTable]	; di - handle of frequency table
	call	InsertQuickViewEntry		; insert the phone entry
	inc	ds:[gmb.GMB_numFreqTab]		; update the count
EC <	cmp	ds:[gmb.GMB_numFreqTab], MAX_FREQ_ENTRY			>
EC <	ERROR_G	ILLEGAL_FREQ_TABLE_ENTRY_NUMBER				>
	add	ds:[gmb.GMB_offsetFreqTab], size QuickViewEntry	; update the offset
history:
	cmp	ds:[gmb.GMB_numHistTab], MAX_FREQ_ENTRY	; is history table full?
	je	exit			; exit if so

	; lock the history table

	mov	di, ds:[gmb.GMB_histTable]	; di - handle of history table
	mov	cx, ds:[gmb.GMB_numHistTab]	; cx - # of entries in history table
	call	DBLockNO			
	mov	di, es:[di]		; open up history table
	mov	dx, di			; di - offset to beg. of data

	; find the place to insert a quick dial entry into history table
	
	tst	cx			; is table empty?
	je	found2			; if so, found a place to insert
miniLoop2:
	add	di, size QuickViewEntry	; if not greater, check the next entry 
	loop	miniLoop2
found2:
	; inser the quick dial entry

	sub	di, dx			; di - offset to insert at
	mov	dx, di			; dx - offset to insert at
	call	DBUnlock		; unlock the data block
	mov	di, ds:[gmb.GMB_histTable]	; di - handle of history table
	call	InsertQuickViewEntry		; insert the phone entry
	inc	ds:[gmb.GMB_numHistTab]		; update the count
EC <	cmp	ds:[gmb.GMB_numHistTab], MAX_FREQ_ENTRY			>
EC <	ERROR_G	ILLEGAL_HIST_TABLE_ENTRY_NUMBER				>
	add	ds:[gmb.GMB_offsetHistTab], size QuickViewEntry	; update the offset
exit:
	ret
InsertQuickDial	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InsertAllQuickViewEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert all the phone numbers that belong to one record
		into quick dial tables.

CALLED BY:	UTILITY

PASS:		curRecord - current record handle

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, es, si, di, bp

PSEUDO CODE/STRATEGY:
	Open up the record
	For each phone number entry in the record
		Insert phone entry into quick dial tables
	Next phone number
	Close up the record

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	12/7/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InsertAllQuickViewEntry	proc	far

	; lock the current record entry

	mov	di, ds:[curRecord]	; di - current record handle
	call	DBLockNO
	mov	di, es:[di]		
	mov	si, di			; si - ptr to beg of data
	mov	cx, es:[di].DBR_noPhoneNo ; cx - number of phone type names
	add	di, es:[di].DBR_toPhone	; di - points to beg. of phone data
loop1:
	tst	es:[di].PE_length	; is there phone # attached to it?
	je	next			; if not, check the next phone field
	mov	bp, es:[di].PE_count	; bp - phone call count
	mov	al, es:[di].PE_type	; al - phone name type ID
	sub	di, si			; di - offset to current phone number
	mov	dx, di			; dx - offset to current phone number
	call	DBUnlock		; unlock this data block

	; insert this phone entry into both history and frequency table

	push	cx, dx
	call	InsertQuickDial		; insert this phone entry
	pop	cx, dx

	; lock the current record entry again

	mov	di, ds:[curRecord]	; di - current record handle
	call	DBLockNO
	mov	di, es:[di]		
	mov	si, di			; si - ptr to beg of data
	add	di, dx			; di - points to current phone number
next:
if DBCS_PCGEOS
	mov	dx, es:[di].PE_length
	shl	dx, 1
	add	di, dx			; advance record pointer
else
	add	di, es:[di].PE_length	; advance record pointer
endif
	add	di, size PhoneEntry	; di - points to the next phone number
	loop	loop1			; continue

	call	DBUnlock		; unlock the data block
	test	ds:[phoneFlag], mask PF_SAVE_RECORD  ; called by SaveCurRecord?
	jne	exit			; if so, just exit

	mov	dx, ds:[gmb.GMB_numFreqTab]	; dx - number of entries in freq table
	add	dx, ds:[gmb.GMB_numHistTab]	; add number of entries in hist table 

	tst	dx			; are quick dial tables empty?
	je	exit			; if so, exit

	; enable the quick dial icon

	GetResourceHandleNS	QuickDial, bx
	mov	si, offset QuickDial	; bx:si - OD of quick dial button
	call	EnableObject		; enable this button
exit:
	ret
InsertAllQuickViewEntry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InsertQuickViewEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Inserts the phone entry into quick dial table.

CALLED BY:	UTILITY

PASS:		al - phone number type name ID number
		bp - phone call count
		bx - record handle
		dx - offset to insert at
		di - handle of quick dial table

RETURN:		nothing

DESTROYED:	si

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	12/8/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InsertQuickViewEntry	proc	near
	mov	cx, size QuickViewEntry	; cx - length of phone entry
	call	DBInsertAtNO		; make room for one
	call	DBLockNO	
	mov	si, es:[di]		; open up the record
	add	si, dx			; si - pointer to place to insert
	mov	es:[si].QVE_item, bx	; save the record handle 
	mov	es:[si].QVE_key, bp 	; savea phone count
	mov	es:[si].QVE_phoneID, al	; store phone # type name ID number
	call	DBUnlock		; close the table
	ornf	ds:[phoneFlag], mask PF_TABLE_DIRTY	; moniker changed
	ret
InsertQuickViewEntry	endp	


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeleteQuickDial
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deletes phone entries from both frequency and history tables.

CALLED BY:	UTILITY

PASS:		gmb.GMB_numFreqTab, gmb.GMB_numHistTab - number of phone entries
		gmb.GMB_freqTable, gmb.GMB_histTable - handles of quick dial tables

RETURN:		gmb.GMB_numFreqTab, gmb.GMB_numHistTable updated		
		carry flag set if error found

DESTROYED:	ax, bx, cx, dx, si, di, es, bp

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	8/29/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeleteQuickDial	proc	far
	ornf	ds:[phoneFlag], mask PF_DELETE_ALL or \
			mask PF_FREQ_TABLE 	; do frequency table
	mov	ax, ds:[gmb.GMB_numFreqTab]	; ax - number of entries in freq. tab
	tst	ax			; is frequency table empty?
	je	history			; if so, skip
	mov	di, ds:[gmb.GMB_freqTable]	; di - handle of frequency table
	mov	bx, ds:[curRecord]	; bx - current record handle
	cmp	ds:[undoAction], UNDO_CHANGE
	jl	skip
	mov	bx, ds:[gmb.GMB_orgRecord]	; bx - current record handle
skip:
	; delete quick dial entry from frequency table

	call	DeleteQuickViewEntry	; delete quick dial entry
	jc	error			; exit if error
history:
	andnf	ds:[phoneFlag], not mask PF_FREQ_TABLE	; do history table	
	mov	ax, ds:[gmb.GMB_numHistTab]	; ax - number of entries in hist tab
	tst	ax			; is history table empty?
	je	noError			; if so, exit

	; delete quick dial entry from history table

	mov	di, ds:[gmb.GMB_histTable]	; di - handle of history table
	call	DeleteQuickViewEntry	; delete phone entries

ifndef	GCM
	test	ds:[phoneFlag], mask PF_SAVE_RECORD  ; called by SaveCurRecord?
	jne	noError			; if so, just exit

	mov	dx, ds:[gmb.GMB_numFreqTab]	; dx - number of entries in freq table
	add	dx, ds:[gmb.GMB_numHistTab]	; add number of entries in hist table 

	tst	dx			; are quick dial tables empty?
	jne	noError			; if so, exit

	; if quick dial table empty, disable quick dial icon

	GetResourceHandleNS	QuickDial, bx
	mov	si, offset QuickDial	; bx:si - OD of quick dial button
	call	DisableObject		; disable quick dial button
endif

noError:
	clc				; return with no error
error:
	ret
DeleteQuickDial	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeleteQuickViewEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete a phone entry from quick view table.

CALLED BY:	UTILITY

PASS:		phoneFlag - various flags
		bp - number of phone calles made
		ax - number of entries in table
		bx - record handle to search for
		cl - phone number type name ID #
		di - handle of quick dial table

RETURN:		al - phone number type name ID #
		bx - record handle
		bp - number of phone calles made
		gmb.GMB_numFreqTab, gmb.GMB_numHistTable updated		
		gmb.GMB_offsetFreqTab, gmb.GMB_offsetHistTab updated
		carry set if error 

DESTROYED:	ax, bx, cx, dx, es, bp, si, di

PSEUDO CODE/STRATEGY:

Delete:
	Delete the phone entry from the table
	Clear the moniker for this GenTrigger
	If delet all then Goto Delete
	Otherwise, exit

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	12/8/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeleteQuickViewEntry	proc	near
	push	cx			; save phone type number ID

	; lock the quick dial table

	mov	si, di			; si - save record handle
	call	DBLockNO	
	mov	di, es:[di]		; open up this record
	mov	dx, di
loop1:
	cmp	es:[di].QVE_item, bx	; search for this record
	jne	next			; if no match, check next entry
	test	ds:[phoneFlag], mask PF_DELETE_ALL ; if match, delete all?
	jne	delete			; if so, skip to delete this entry
	cmp	es:[di].QVE_phoneID, cl	; does phone type match?
	jne	next			; if not, check the next entry
delete:
	mov	bp, es:[di].QVE_key	; bp - # of phone calls
	xchg	dx, di
	sub	dx, di			; dx - offset to place to delete at
	call	DBUnlock	

	; delete this phone entry from quick dial table

	ornf	ds:[phoneFlag], mask PF_ENTRY_FOUND	; phone entry found
	call	ClearMonikerAndDeleteQuickDialEntry
	jc	exit			; if error, exit

	test	ds:[phoneFlag], mask PF_DELETE_ALL ; delete all?
	je	noError			; if not, exit

	; lock the quick dial table again

	mov	di, si			; di - record handle
	call	DBLockNO
	mov	di, es:[di]		; open up this record
	push	di			; save ptr to beg of record data
	add	di, dx			; di - pointer to the next phone entry
	pop	dx			; dx - ptr to beg of record data
	jmp	short	decrement	; check the next phone entry
next:
	add	di, size QuickViewEntry	; di - pointer to the next phone entry
decrement:
	dec	ax			; ax - # of entries left
	jne	loop1			; continue if not done

	test	ds:[phoneFlag], mask PF_DELETE_ALL ; called by DeleteQuickEntry
	jne	unlock			; if so, skip

	test	ds:[phoneFlag], mask PF_ENTRY_FOUND ; already deleted?
	jne	unlock			; if so, skip

	sub	di, size QuickViewEntry
	test	ds:[phoneFlag], mask PF_FREQ_TABLE ; freq. table searched?
	je	delete2			; if not, skip to delete 

	cmp	ds:[gmb.GMB_numFreqTab], MAX_FREQ_ENTRY	; is frequency table full?
	jl	unlock			; if not, skip

	; check to see if we can insert this entry into quick dial table

	push	es
	call	CheckForInsertability	
	pop	es
	jne	unlock			
delete2:
	cmp	ds:[gmb.GMB_numHistTab], MAX_FREQ_ENTRY	; is history table full?
	jl	unlock			; if not, skip

	xchg	dx, di
	sub	dx, di			; dx - offset to place to delete at
	call	DBUnlock	

	; delete this phone entry from quick dial table

	call	ClearMonikerAndDeleteQuickDialEntry
	jc	exit			; if error, exit
	jmp	short	noError
unlock:
	call	DBUnlock		; if so, exit
noError:
	clc
exit:
	pushf
	andnf	ds:[phoneFlag], not mask PF_ENTRY_FOUND ; clear flag
	popf
	pop	ax			; al - restore phone # type name ID
	ret
DeleteQuickViewEntry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClearMonikerAndDeleteQuickDialEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clears the moniker and deletes quick dial entry.	

CALLED BY:	DeleteQuickViewEntry	

PASS:		bx - current record handle
		cx - phone type name 

RETURN:		nothing

DESTROYED:	ax, di, si

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClearMonikerAndDeleteQuickDialEntry	proc	near
	test	ds:[phoneFlag], mask PF_DONT_CLEAR ; clear the moniker?
	jne	short	skip		; if you're not supposed to, skip

	ornf	ds:[phoneFlag], mask PF_TABLE_DIRTY ; update monikers

	push	bx				; save current record handle
	mov	bx, ds:[gmb.GMB_numFreqTab]		; bx - number of freq. entries
	dec	bx
	shl	bx, 1				; bx - offset to current button
	mov	di, ds:[SpeedDialTable][bx]	; si - handle of button
	test	ds:[phoneFlag], mask PF_FREQ_TABLE	; do frequency table?
	jne	frequentTable			; if so, skip
	mov	bx, ds:[gmb.GMB_numHistTab]	; bx - number of hist entries
	dec	bx
	shl	bx, 1				; bx - offset to current button
	mov	di, ds:[HistoryTable][bx]	; si - handle of a hist button
frequentTable:
	pop	bx			; restore current record handle

	; clear the vis moniker from quick dial button 

	call	ClearMoniker		; erase the moniker for this button
	jc	exit			; exit if error
skip:
	; delete the quick dial entry from quick dial table

	push	cx			; save phone number type name ID
	mov	cx, size QuickViewEntry	; cx - # of bytes to delete
	mov	di, si			; di - record handle
	call	DBDeleteAtNO		; delete this phone entry
	pop	cx			; restore phone number type name ID

	test	ds:[phoneFlag], mask PF_FREQ_TABLE	; frequency table?
	je	history			; if not, skip

	dec	ds:[gmb.GMB_numFreqTab]		; if so, update the count 
EC <	ERROR_S	ILLEGAL_FREQ_TABLE_ENTRY_NUMBER				>
	sub	ds:[gmb.GMB_offsetFreqTab], size QuickViewEntry	; update the offset
	jmp	short	quit		; quit 
history:
	dec	ds:[gmb.GMB_numHistTab]		; if history, update the count
EC <	ERROR_S	ILLEGAL_HIST_TABLE_ENTRY_NUMBER				>
	sub	ds:[gmb.GMB_offsetHistTab], size QuickViewEntry	; update the offset
quit:
	clc
exit:
	ret
ClearMonikerAndDeleteQuickDialEntry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckForInsertability
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see this entry can be inserted.

CALLED BY:	DeleteQuickViewEntry

PASS:		si - handle of either frequency or history table

RETURN:		zero flag set if you can insert
		zero flag clear if you can't insert

DESTROYED:	cx, dx, di, bp

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckForInsertability	proc	near
	test	ds:[phoneFlag], mask PF_AUTO_DIAL ; called from RolodexDial?
	je	quit			; if not, skip 

	; figure out which quick dial table is being checked for

	mov	cx, ds:[gmb.GMB_numFreqTab]	; cx - # of entries in freq. table
	test	ds:[phoneFlag], mask PF_FREQ_TABLE	; frequency table?
	jne	common			; if so, skip
	mov	cx, ds:[gmb.GMB_numHistTab]	; cx - # of entries in hist. table
common:
	; lock this quick dial table

	mov	di, si			; di - record handle of dial table
	call	DBLockNO
	mov	di, es:[di]	
	mov	dx, di			; save the offset to beg of table
mainLoop:
	cmp	bp, es:[di].QVE_key	; compare # of phone calls made
	je	found			; if so, this entry can be inserted
	add	di, size QuickViewEntry	; di - pointer to the next phone entry
	loop	mainLoop
	call	DBUnlock
quit:
	mov	cx, 1
exit:
	tst	cx			; return with zero flag clear
	ret
found:
	call	DBUnlock
	clr	cx			; return with zero flag set
	jmp	short	exit
CheckForInsertability	endp


if ERROR_CHECK

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AssertGlobalVars
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Assert some dgroup vars, including some in GeodexMapBlock

CALLED BY:	UTILITY
PASS:		ds - dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	8/16/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AssertGlobalVars	proc	near
	uses	di,ds,es
	.enter

	Assert	dgroup	ds

	Assert	srange, ds:[gmb.GMB_numFreqTab], 0, COUNT_QUICK_PHONE_NUMBERS
	Assert	srange, ds:[gmb.GMB_numHistTab], 0, COUNT_QUICK_PHONE_NUMBERS
	
	Assert	vmFileHandle, ds:[fileHandle]

	mov	di, ds:[gmb.GMB_freqTable]
	call	DBLockNO
	call	DBUnlock

	mov	di, ds:[gmb.GMB_histTable]
	call	DBLockNO
	call	DBUnlock

	.leave
	ret
AssertGlobalVars	endp

endif

QuickDialCode	ends
