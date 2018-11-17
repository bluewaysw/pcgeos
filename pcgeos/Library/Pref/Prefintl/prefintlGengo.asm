COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	PC GEOS/Pizza	
MODULE:		
FILE:		prefintlGengo.asm

AUTHOR:		Koji Murakami, Jan 26, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	KM	1/26/94   	Initial revision


DESCRIPTION:
	Define Gengo modules.  This is quite simple.  However, this is 
	politically delicate.  I have no responsibility about it.
	I do not want to make anyone angry.
	Probably nobody will use it, or everybody will have to use it
	sometime.   Therefore, please test it carefully.

	$Id: prefintlGengo.asm,v 1.1 97/04/05 01:39:18 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefGengoInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize Gengo Dialogbox

CALLED BY:	MSG_VIS_OPEN

PASS:		*ds:si	= PrefGengoInteractionClass object
		ds:di	= PrefGengoInteractionClass instance data
		ds:bx	= PrefGengoInteractionClass object (same as *ds:si)
		es 	= segment of PrefGengoInteractionClass
		ax	= message #

RETURN:		nothing

DESTROYED:	ax, cx, dx, si, di

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	I do not want bother PrefIntlDialogInit.
	I have to disable the delete trigger everytime,
	because DynamicLIst is initialized everytime.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	KM	1/26/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefGengoInit	method dynamic PrefGengoInteractionClass, 
					MSG_VIS_OPEN
	;
	; call super
	;
	push	di
	mov	di, offset PrefGengoInteractionClass
	call	ObjCallSuperNoLock
	pop	di
	;
	; initialize dynamic list
	;
	call	PrefGengoListInit
	call	PrefGengoMakeListFromIni
	;
	; disable Delete trigger for Re-open Dialog box
	;
	mov	si, offset DeleteGengoTrigger	;ds:si - object
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	call	PrefGengoEnableDisable

	ret
PrefGengoInit	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefGengoMakeListFromIni
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make Gengo list from .ini file

CALLED BY:	PrefGengoInit

PASS:		ds:di	= PrefGengoInteractionClass instance data

RETURN:		nothing

DESTROYED:	ax, di

SIDE EFFECTS:

PSEUDO CODE/STRATEGY:
	Get every Gengo from the kernel library.
	And make each entry to DynamicList.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	KM	1/26/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefGengoMakeListFromIni	proc	near

	class	PrefGengoInteractionClass	;friend to this class

	;
	; loop until the last Gengo
	;
	clr	ax				;ax - start entry #
	lea	di, ds:[di].PGD_gengo		;ds:di - GengoNameData
doEachGengo:
	;
	; get one Gengo entry from Kernel
	;
	call	PrefGengoFindById
	jc	done				;if no more gengo, exit
	;
	; add one entry to the Dynamic list
	;
	call	PrefGengoListAdd		;add it to Dynamic list
	inc	ax				;next entry #
	jmp	doEachGengo			;loop for each Gengo
done:

	ret
PrefGengoMakeListFromIni	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefGengoFindById
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find Gengo by item number

CALLED BY:	PrefGengoMakeListFromIni
		PrefGengoRequestListMoniker
		PrefGengoDelete


PASS:		ds:di	= GengoNameDate structure to be filled in
		ax	= item number (0-)

RETURN:		carry clear if found
			ds:di	= GengoNameDate filled in
		carry set otherwise

DESTROYED:	nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	KM	1/26/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefGengoFindById	proc	near
	uses	es
	.enter

	segmov	es, ds			;es:di - GengoNameData structure
	call	LocalGetGengoInfo

	.leave
	ret
PrefGengoFindById	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefGengoRequestListMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	display each DynamicList item moniker

CALLED BY:	MSG_PREF_GENGO_REQUEST_LIST_MONIKER

PASS:		*ds:si	= PrefGengoInteractionClass object
		ds:di	= PrefGengoInteractionClass instance data
		ds:bx	= PrefGengoInteractionClass object (same as *ds:si)
		es 	= segment of PrefGengoInteractionClass
		ax	= message #
		^lcx:dx	= PrefGengoDynamicListClass object (sender)
		bp	= entry # of requested moniker

RETURN:		nothing

DESTROYED:	ax, cx, dx, di, si

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Get one Gengo information from the kernel.
	Format the Gengo item to display.
	Display it on DynamicList.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	KM	1/26/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefGengoRequestListMoniker	method dynamic PrefGengoInteractionClass, 
					MSG_PREF_GENGO_REQUEST_LIST_MONIKER
passedBP	local word \
		push	bp			;save passed BP : item#
itemMoniker	local GENGO_ITEM_STRING_LENGTH + 1 dup (wchar)

	.enter					;need for local data
	push	bp				;need to save base pointer
	mov	ax, passedBP			;ax - item #
	;
	; get one entry of Gengo
	;
	lea	di, ds:[di].PGD_gengo		;ds:di - GengoNameData
	call	PrefGengoFindById		;find Gengo by item #
						;ds:di - filled
	jc	done				;if not found, exit
	push	ax				;save item#
	;
	; make a Gengo item into buffer
	;
	mov	si, di				;ds:si - GengoNameData
	push	es				;save es
	segmov	es, ss				;es - stack segment
	lea	di, ss:itemMoniker		;es:di - local buffer
	call	PrefGengoFormatItem		;format. ds:si -> es:di
	pop	es				;restore es
	;
	; replace item moniker in the DynamicList
	;
	mov	si, offset GengoList		;ds:si - object
	mov	cx, ss				;cx - stack segment
	lea	dx, ss:itemMoniker		;cx:dx - local buffer
	pop	bp				;restore item#
	mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_TEXT
	call	ObjCallInstanceNoLock		;replace item moniker
done:
	pop	bp				;restore base & stack ptr
	.leave

	ret
PrefGengoRequestListMoniker	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefGengoFormatItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	format Gengo item into the buffer for Dynamic list

CALLED BY:	PrefGengoRequestListMoniker

PASS:		es:di	= buffer to be formatted in
		ds:si	= GengoNameData structure
		
RETURN:		es:di	= fill with formated string
		di	= unchanged.

DESTROYED:	ax, bx, cx, dx, si

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	format : starting date, longName, shortName

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	KM	1/26/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefGengoFormatItem	proc	near

	class	PrefGengoInteractionClass	;friend to this class

	uses	di
	.enter
	;
	; format starting date
	;
	mov	ax, ds:[si].GND_year		;year
	mov	bl, ds:[si].GND_month		;month
	mov	bh, ds:[si].GND_date		;day
	push	si				;save si - structure pointer
	call	PrefGengoFormatDate		;format starting date
	;
	; space
	;
	mov	ax, C_SPACE
	LocalPutChar esdi, ax
	LocalPutChar esdi, ax
	;
	; put long name into buffer
	;
	pop	si				;restore si - structure ptr
	push	si				;save si - structure pointer
	lea	si, ds:[si].GND_longName	;ds:si - long name
	LocalCopyString				;copy ds:si to es:di
	LocalPrevChar	esdi			;point at null
	mov	ax, C_SPACE
	LocalPutChar esdi, ax			;fill space
	LocalPutChar esdi, ax			;fill space
	;
	; put short name into buffer
	;
	pop	si				;restore si - structure ptr
	lea	si, ds:[si].GND_shortName	;ds:si - short name
	LocalCopyString				;copy ds:si to es:di

	.leave
	ret
PrefGengoFormatItem	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefGengoFormatDate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert date format into the buffer.

CALLED BY:	PrefGengoFormatItem

PASS:		es:di	= buffer to be formatted in
		ax	= year
		bl	= month
		bh	= day

RETURN:		es:di	= pointer after the inserted text.
		di	= changed

DESTROYED:	bx, cx, dx, si

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	format: Prefix Year Suffix Month Suffix Day Suffix

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	KM	1/27/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefGengoFormatDate	proc	near
	uses	ds
	.enter

EC<	push	es				;save es >
	push	ax, bx				;save year, month, day
	mov	bx, handle GengoStrings		;bx - lmem handle
	call	MemLock				;ax - address
	mov	ds, ax				;ds - block segment
	mov	dx, bx				;dx - save lmem handle
	pop	ax, bx				;restore year, month, day
	mov	si, offset GengoListDateFormat	;si - offset
	mov	si, ds:[si]			;ds:si - format string
	call	LocalCustomFormatDateTime	;es:di - formatted text
	mov	bx, dx				;bx - restore lmem handle
	call	MemUnlock
	shl	cx				;# of bytes for DBCS
	add	di, cx				;string pointer after date
EC <	pop	es				;restore es >

	.leave
	ret
PrefGengoFormatDate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefGengoListSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Dynamic list item is selected, Enable Delete trigger

CALLED BY:	MSG_PREF_GENGO_LIST_SELECTED

PASS:		*ds:si	= PrefGengoInteractionClass object
		ds:di	= PrefGengoInteractionClass instance data
		ds:bx	= PrefGengoInteractionClass object (same as *ds:si)
		es 	= segment of PrefGengoInteractionClass
		ax	= message #
		cx	= item #

RETURN:		nothing

DESTROYED:	ax, si

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	KM	1/26/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefGengoListSelected	method dynamic PrefGengoInteractionClass, 
					MSG_PREF_GENGO_LIST_SELECTED

	mov	si, offset DeleteGengoTrigger	;ds:si - object
	tst	cx				;item selected?
	jns	selected			;yes, branch
	;
	; deselected. disable Delete trigger
	;
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	jmp	doEnableDisable
selected:
	;
	; item was selected. enable Delete trigger
	;
	mov	ax, MSG_GEN_SET_ENABLED
doEnableDisable:
	call	PrefGengoEnableDisable

	ret
PrefGengoListSelected	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefGengoEnableDisable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enable or Disable Trigger

CALLED BY:	PrefGengoListSelected
		PrefGengoItemChanged
		PrefGengoAdd
		PrefGengoDelete

PASS:		ds:si	= object
		ax	= message to send

RETURN:		nothing

DESTROYED:	ax, cx, dx, di

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	KM	1/26/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefGengoEnableDisable	proc	near
	uses	bp
	.enter

	mov	dl, VUM_NOW
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjCallInstanceNoLock

	.leave
	ret
PrefGengoEnableDisable	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefGengoItemChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gengo item is changed. Enable add trigger

CALLED BY:	MSG_PREF_GENGO_ITEM_CHANGED

PASS:		*ds:si	= PrefGengoInteractionClass object
		ds:di	= PrefGengoInteractionClass instance data
		ds:bx	= PrefGengoInteractionClass object (same as *ds:si)
		es 	= segment of PrefGengoInteractionClass
		ax	= message #

RETURN:		nothing

DESTROYED:	ax, cx, dx, si, di

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	This message should come everytime when user changes
	long-name, short-name or date.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	KM	2/ 1/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefGengoItemChanged	method dynamic PrefGengoInteractionClass, 
					MSG_PREF_GENGO_ITEM_CHANGED

	mov	si, offset AddGengoTrigger	;ds:si - object
	mov	ax, MSG_GEN_SET_ENABLED
	call	PrefGengoEnableDisable

	ret
PrefGengoItemChanged	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefGengoAdd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add new Gengo

CALLED BY:	MSG_PREF_GENGO_ADD

PASS:		*ds:si	= PrefGengoInteractionClass object
		ds:di	= PrefGengoInteractionClass instance data
		ds:bx	= PrefGengoInteractionClass object (same as *ds:si)
		es 	= segment of PrefGengoInteractionClass
		ax	= message #

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, di

SIDE EFFECTS:	
	Remember, I am using the DoError.
	Please check me before you change it.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	KM	1/26/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefGengoAdd	method dynamic PrefGengoInteractionClass, 
					MSG_PREF_GENGO_ADD
	
	;
	; get Gengo items to add
	;
	lea	di, ds:[di].PGD_gengo		;ds:di - GengoNameData
	call	PrefGengoGetGengoItem		;ds:di <- gengo data to add
	jnc	addToGeos			;if OK, add it into Kernel
	;
	; if item is not correct, show error dialog
	;
	mov	si, offset badGengoItemString
	mov	bx, handle Strings		;bx:si - error message
	call	DoError
	jmp	done
addToGeos:
	;
	; add new Gengo into the kernel
	;
	mov	ax, ds:[di].GND_year		;ax - year
	mov	bl, ds:[di].GND_month		;bl - month
	mov	bh, ds:[di].GND_date		;bh - day
	push	es				;save es
	segmov	es, ds				;es - UI object
	lea	si, ds:[di].GND_longName	;ds:si - long name
	lea	di, ds:[di].GND_shortName	;es:di - short name
	call	LocalAddGengoName		;add it into kernel
	pop	es				;restore es
	jnc	addToList			;if OK, add list
	;
	; if Gengo could not added, show error dialog
	;
	mov	si, offset badAddGengoString
	mov	bx, handle Strings		;bx:si - error message
	call	DoError
	jmp	done
addToList:
	;
	; add new Gengo to DynamicList
	;
	call	PrefGengoListAdd		;add it to Dynamic list
	;
	; disable Add trigger
	;
	mov	si, offset AddGengoTrigger	;ds:si - object
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	call	PrefGengoEnableDisable
done:
	ret
PrefGengoAdd	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefGengoGetGengoItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get GengoItemInteraction values

CALLED BY:	PrefGengoAdd

PASS:		*ds:si	= PrefGengoInteractionClass object
		ds:di	= GengoNameData structure to be filled in

RETURN:		carry clear if items is completed
			ds:di = GengoNameData filled in
		carry set otherwise

DESTROYED:	ax, cx, dx, si, es

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Remember, I am using the PrefIntlGetTextIntoBuffer and
	PrefIntlGetValue.  Please check me before you change them.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	KM	1/26/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefGengoGetGengoItem	proc	near
	uses	bp
	.enter
	;
	; long name
	;
	segmov	es, ds				;es - GengoNameData seg
	lea	dx, ds:[di].GND_longName	;es:dx - buffer
	mov	si, offset GengoLongNameText	;ds:si - object
	call	PrefIntlGetTextIntoBuffer	;es:dx - filled
	tst	cx				;text exist?
	jz	doError				;if not, error
	;
	; short name
	;
	segmov	es, ds				;es - possibly destroyed
	lea	dx, ds:[di].GND_shortName	;es:dx - buffer
	mov	si, offset GengoShortNameText	;ds:si - object
	call	PrefIntlGetTextIntoBuffer	;es:dx - filled
	tst	cx				;text exist?
	jz	doError				;if not, error
	;
	; year
	;
	mov	si, offset GengoYearValue	;ds:si - object
	call	PrefIntlGetValue		;cx - value
	mov	ds:[di].GND_year, cx		;set year
	;
	; month
	;
	mov	si, offset GengoMonthValue	;ds:si - object
	call	PrefIntlGetValue		;cx - value
	mov	ds:[di].GND_month, cl		;set month
	;
	; day
	;
	mov	si, offset GengoDayValue	;ds:si - object
	call	PrefIntlGetValue		;cx - value
	mov	ds:[di].GND_date, cl		;set day

	;
	; Check to verify the date is legal.
	;
	call	PrefGengoCheckDate
	jmp	done

doError:
	stc					;set carry
done:
	.leave
	ret
PrefGengoGetGengoItem	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                PrefGengoCheckDate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       check for wrong date

CALLED BY:      PrefGengoGetGengoItem

PASS:           ds:di   = GengoNameData structure
                'day' may be 1 to 31
                'month' may be 1 to 12
                'year' may be 1900 to 9999

RETURN:         carry set if date is invalid
                carry clear if otherwise

DESTROYED:      ax, bx, cx, dx
SIDE EFFECTS:
PSEUDO CODE/STRATEGY:
        month   1    2     3    4    5    6    7    8    9   10   11   12
        day    31  28/29  31   30   31   30   31   31   30   31   30   31

        if(year % 4 == 0 && year % 100 != 0 || year % 400 == 0)
                leap year!
        (by Kernighan & Ritchie. The C programming language)

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        KM      7/21/94         Initial version
	gene	7/25/94		Rewrote to use LocalCalcDaysInMonth()

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefGengoCheckDate      proc    near
	;
	; Verify the month is reasonable
	;
	mov	bl, ds:[di].GND_month		;bl <- month
EC <	tst	bl							>
EC <	ERROR_Z	-1							>
EC <	cmp	bl, 12							>
EC <	ERROR_A	-1							>
	;
	; See if the day is reasonable
	;
	mov	dl, ds:[di].GND_date		;dl <- day
	tst	dl				;branch if day < 1
	jz	badDate
	;
	; Find out how many days are in the given the month & year
	; and check the day.
	;
	mov	ax, ds:[di].GND_year		;ax <- year
	call	LocalCalcDaysInMonth		;ch == days in month
	cmp	dl, ch				;day too high?
	ja	badDate				;branch if day > days in month
	clc					;carry <- no error
	jmp	done

badDate:
        stc					;carry <- error
done:
        ret
PrefGengoCheckDate      endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefGengoDelete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete Gengo

CALLED BY:	MSG_PREF_GENGO_DELETE

PASS:		*ds:si	= PrefGengoInteractionClass object
		ds:di	= PrefGengoInteractionClass instance data
		ds:bx	= PrefGengoInteractionClass object (same as *ds:si)
		es 	= segment of PrefGengoInteractionClass
		ax	= message #

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, di

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Remember, I am using the DoError.
	Please check me before you change it.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	KM	1/26/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefGengoDelete	method dynamic PrefGengoInteractionClass, 
					MSG_PREF_GENGO_DELETE
	;
	; get Gengo List Item from GenDynamicList
	;
	push	bp
	mov	si, offset GengoList		;ds:si - object
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	call	ObjCallInstanceNoLock		;ax - selection #
	pop	bp
	;
	; get starting date of Gengo
	;
	lea	di, ds:[di].PGD_gengo		;ds:di - GengoNameData
	call	PrefGengoFindById		;find Gengo by item #
	jc	done				;if not found, exit
	;
	; remove Gengo from kernel
	;
	mov	cx, ax				;cx - item #
	mov	ax, ds:[di].GND_year		;ax - year
	mov	bl, ds:[di].GND_month		;bl - month
	mov	bh, ds:[di].GND_date		;bh - day
	call	LocalRemoveGengoName		;delete it from geos.ini
	jnc	removeFromList			;if OK, remove list item
	;
	; if not removed, show error dialog
	;
	mov	si, offset badDeleteGengoString
	mov	bx, handle Strings		;bx:si - error message
	call	DoError
	jmp	done	
removeFromList:
	;
	; remove Gengo from DynamicList
	;
	call	PrefGengoListDelete		;delete it from list
	;
	; disable Delete trigger
	;
	mov	si, offset DeleteGengoTrigger	;ds:si - object
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	call	PrefGengoEnableDisable
done:
	ret
PrefGengoDelete	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefGengoListInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize Gengo DynamicList

CALLED BY:	PrefGengoInit

PASS:		ds = segment of PrefGengoInteractionClass object

RETURN:		nothing

DESTROYED:	ax, cx, dx, si

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	KM	1/26/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefGengoListInit	proc	near
	uses	bp
	.enter

	mov	si, offset GengoList			;ds:si - object
	clr	cx					;cx - no. of items
	mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
	call	ObjCallInstanceNoLock

	.leave
	ret
PrefGengoListInit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefGengoListAdd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add an item to Gengo DynamicList

CALLED BY:	PrefGengoMakeListFromIni, PrefGengoAdd

PASS:		ds = segment of PrefGengoInteractionClass object

RETURN:		nothing

DESTROYED:	cx, dx, si

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	KM	1/12/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefGengoListAdd	proc	near
	uses	ax, bp
	.enter

	mov	si, offset GengoList		;ds:si - list object
	mov	cx, GDLP_LAST			;cx - insert position
	mov	dx, 1				;dx - no. of items to add
	mov	ax, MSG_GEN_DYNAMIC_LIST_ADD_ITEMS
	call	ObjCallInstanceNoLock

	.leave
	ret
PrefGengoListAdd	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefGengoListDelete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete an item from Gengo DynamicList

CALLED BY:	PrefGengoDelete

PASS:		ds = segment of PrefGengoInteractionClass object
		cx	= item #

RETURN:		nothing

DESTROYED:	ax, cx, dx, si

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	KM	1/12/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefGengoListDelete	proc	near
	uses	bp
	.enter

	mov	si, offset GengoList		;ds:si - list object
	mov	dx, 1				;dx - no. of items to remove
	mov	ax, MSG_GEN_DYNAMIC_LIST_REMOVE_ITEMS
	call	ObjCallInstanceNoLock

	.leave
	ret
PrefGengoListDelete	endp



