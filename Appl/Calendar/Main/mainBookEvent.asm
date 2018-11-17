COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	(c) Copyright Geoworks 1996 -- All Rights Reserved
	GEOWORKS CONFIDENTIAL

PROJECT:	PCGEOS
MODULE:		Calendar/Main
FILE:		mainBookEvent.asm

AUTHOR:		Jason Ho, Nov 4, 1996

ROUTINES:
	Name				Description
	----				-----------
    INT CreateVersitTextIntoBlock
				Create Versit text and write it to the
				block that is allocated.

    INT AddBookSMSPrefixHeader	Add SMS prefix to the block. The prefix
				should be found in INI file, but use
				backupPrefix if not found.

    INT WriteVersitKeyword	Write the versit keyword to the buffer.

    INT AddVersitEventOrTodoBody
				Translate the normal event or to-do item
				into versit format, and write it to the
				buffer.

    INT AddVersitNormalEvent	Translate the normal event into versit
				format, and write it to the buffer.

    INT AddVersitToDoEvent	Translate the to-do item into versit
				format, and write it to the buffer.

    INT WriteCRLF		Write CRLF to buffer.

    INT WriteStartTime		Get the start time of event, and write to
				buffer.

    INT WriteEndTime		Get the end time of event, and write to
				buffer.

    INT WriteVersitDateAndTime	Translate the date and time into versit
				format, and write it to the buffer. CRLF
				not added.

    INT CopyStringUpdateCount	Do a string copy, and the size written is
				subtracted from count register.
				
				This routine would only write up to
				MAX_TEXT_FIELD_LENGTH+1 (256) chars. A ';'
				or '\' counts as two chars because it is
				escaped by backslash.

    INT WriteDescriptionText	Write description to buffer, in versit
				format.

    INT WriteUID		Write unique ID string to buffer, in versit
				format.

    INT WriteDWordToAscii	Write the passed dword into buffer, in
				ascii format.

    INT WriteAlarmInfo		Write alarm information to buffer, in
				versit format.

    INT WriteReserveDaysInfo	Write reservation days info to buffer, in
				versit format.

    INT WriteRepeatInfo		Write repeat information to buffer, in
				versit format.

    INT WritePassword		Write password information to buffer, in
				versit format.

    INT WriteCreatedEventID	Write remote event ID, if any, in versit
				format.

    MTD MSG_CALENDAR_BOOK_AS_SMS
				User presses "Send as SMS" in booking event
				view. Bring up SMS address controller.

    MTD MSG_CALENDAR_DISPLAY_EVENT_SUMMARY
				Stuff and display the summary window for
				the booking event.

    INT StuffSMSEventSummary	Stuff the SMS event summary window with
				text.

    INT CreateFileDateTimeFromGetTime
				Stuff the SMS event summary window with
				text.

    INT StuffNameAndSMSToText	Stuff name and sms number into
				EventRecipientText. We are doing multiple
				selections, so we have to traverse the
				selection list.

    MTD MSG_CALENDAR_SEND_SMS_CONFIRMED
				In the event summary window, user presses
				"Send". Time to send the message to
				mailbox.

    INT GetBookEventType	Return the selection of BookingItemGroup,
				which defines whether we are doing event
				request or reservation.

    INT DoSMSUpdateIfNecessary	Notify the currently selected DayEventClass
				object to send out any SMS update, if
				necessary (ie. if time has changed since
				last time the Details dialog is up.)

    MTD MSG_CALENDAR_REGISTER_MAILBOX_EVENT_TEXT
				Recipient is already picked and password
				already input. Register the event text to
				mailbox now.

    INT CheckServiceNumber	Check if service number is already found in
				INI file. If not, show a dialog to input
				the service number.

    INT CalStripNonNumeric	Strips non-numeric characters from this
				string

    INT AddSentToInfo		Add the sent-to information (with the name
				/ sms number / contact ID in instance data
				of CalendarAddressCtrlClass object) to the
				currently selected event.

    INT GetNextBookIdOfCurrentEvent
				Return the currently selected event's next
				book ID.

    MTD MSG_META_CLIPBOARD_CUT	Disable cut/copy in password text.

    MTD MSG_META_FUP_KBD_CHAR	Pass the META_FUP_KBD_CHAR to vis parent
				(GenView) so that the GenContent scrolls.

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho		11/14/96   	Initial revision


DESCRIPTION:
	Code of GeoPlannerClass that is used to book calendar events
	(sending appointment request to another user.)
		

	$Id: mainBookEvent.asm,v 1.1 97/04/04 14:48:15 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	HANDLE_MAILBOX_MSG

	;
	; There must be an instance of every class in a resource.
	;
idata		segment
	CalendarPasswordTextClass
	ScrollableGenContentClass
idata		ends

MailboxCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateVersitTextIntoBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create Versit text and write it to the block that is
		allocated.

CALLED BY:	(INTERNAL) GeoPlannerMetaMailboxCreateMessage
PASS:		es	= segment of block to write to, of size
			  INITIAL_VERSIT_TEXT_BLOCK_SIZE
		cx	= size of buffer available
RETURN:		cx	= actual size of text written to block
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		In the block, we want to put in:

		o	a word of NULL (for VMCL_next, because this is a VM
			block)
		o	[Calendar]bookSMSPrefix
		o	versit start keywords
		o	event text in versit format
		o	versit end keywords

		Since we are writing from es:[0], and es:di will be the next
		char to write to, di will be the size of text written.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	11/ 4/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateVersitTextIntoBlock	proc	near
		uses	ax, ds, si, es, di
		.enter
		Assert	segment, es
		Assert	e, cx, INITIAL_VERSIT_TEXT_BLOCK_SIZE
		
		clr	di				; es:di <- destination
	;
	; This will be a VM block, which has VMChainLink at the start.
	;
		clr	es:[VMCL_next]
		add	di, size VMCL_next
		sub	cx, size VMCL_next
	;
	; Read the INI file, and put in the prefix header.
	;
		call	AddBookSMSPrefixHeader		; es:di <- EOS,
							; cx adjusted
	;
	; Write versit header.
	;
		; BEGIN:VCALENDAR
		mov	ax, VersitStringFlags<CRLF_YES, VKT_BEGIN_VCALENDAR>
		call	WriteVersitKeyword		; es:di, cx adjusted
		
		; VERSION:1.0
		mov	ax, VersitStringFlags<CRLF_YES, VKT_VERSION_1_0>
		call	WriteVersitKeyword		; es:di, cx adjusted
	;
	; Add the event body.
	;
		call	AddVersitEventOrTodoBody	; es:di, cx adjusted
	;
	; Write versit end keywords.
	;
		; END:VCALENDAR
		mov	ax, VersitStringFlags<CRLF_YES, VKT_END_VCALENDAR>
		call	WriteVersitKeyword		; es:di, cx adjusted
	;
	; Return size.
	;
		mov	cx, di
done::
		.leave
		ret
CreateVersitTextIntoBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddBookSMSPrefixHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add SMS prefix to the block. The prefix should be found in
		INI file, but use backupPrefix if not found.

CALLED BY:	(INTERNAL) CreateVersitTextIntoBlock
PASS:		es	= segment of block to write to (block size is
			  INITIAL_VERSIT_TEXT_BLOCK_SIZE, so it should have
			  enough space for prefix string)
		cx	= size of buffer available
RETURN:		es:di	= end of buffer, ie. the NULL
		cx	= updated
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	11/ 5/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

bookSMSKey	char	"bookSMSPrefix", 0

AddBookSMSPrefixHeader	proc	near
		uses	ax, bx, dx, ds, si, bp
		.enter
		Assert	ge, cx, CALENDAR_BOOK_SMS_PREFIX_MAX_LENGTH+2
	;
	; Read the buffer header (prefix) that tells the recipient, this SMS
	; is for a special app (Calendar helper) instead of SMS app.
	;
		push	cx				; remember size
		mov	bp, InitFileReadFlags<IFCC_INTACT, 0, 0, \
					    CALENDAR_BOOK_SMS_PREFIX_MAX_LENGTH>
							; buffer available=20
	;		segmov	ds, cs, cx
		mov	cx, cs
		GetResourceSegmentNS	dgroup, ds
		mov	si, offset calendarCategory
		mov	dx, offset bookSMSKey
		call	InitFileReadString		; carry set if not
							;  found, bx destroyed;
							; else
							;  cx <-#char read,
							;  (null not included)
							;  buffer filled,
							;  di NOT changed
		mov_tr	ax, cx
		pop	cx
EC <		WARNING_C CALENDAR_BOOK_EVENT_PREFIX_NOT_FOUND		>
		jc	entryNotFound
	;
	; Update es:di <- EOS, and update count.
	;
		add	di, ax				; es:di <- EOS
		sub	cx, ax				; size available
	;
	; Write a "CRLF" to text.
	;
		mov	ax, VersitStringFlags<CRLF_NO, VKT_CRLF>
writeKeyword:
		call	WriteVersitKeyword
		
		.leave
		ret
entryNotFound:
	;
	; Oops, prefix not found. Use the backupPrefix.
	;
		mov	ax, VersitStringFlags<CRLF_YES, VKT_SMS_PREFIX>
		jmp	writeKeyword

AddBookSMSPrefixHeader	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteVersitKeyword
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write the versit keyword to the buffer.

CALLED BY:	(INTERNAL)
PASS:		es:di	= buffer to write to
		cx	= size of buffer available (in bytes)
		ax	= VersitStringFlags
RETURN:		es:di	= EOS, ie. NULL
		cx	= updated
		carry	= cleared

		if not enough space:
		carry	= set
		di, cx	= not changed

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Get string from string table and write it.
		If this is a property, add a colon too.
		Adjust es:di so it points to null, not the char after it.
		Write CRLF if we have to.
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	11/ 6/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteVersitKeyword	proc	near
		uses	ax, dx, ds, si, bp
		.enter
		Assert	segment, es
		Assert	record, ax, VersitStringFlags

		mov	si, ax
		andnf	si, mask VSF_KEYWORD		; si<-VersitKeywordType
		Assert	etype, si, VersitKeywordType

		mov_tr	dx, ax
		andnf	dx, mask VSF_ADD_CRLF		; dx <- boolean
	;
	; Find the amount of space we need.
	;
		mov	bp, cs:[keywordSizeTable][si]	; size of string,
							;  including NULL.
		tst	dx
		jz	noCRLF
		add	bp, size crlf-size TCHAR	; account for CRLF,
							;  but just one null
noCRLF:
	;
	; Do we have enough space?
	;
		cmp	cx, bp
EC <		WARNING_B CALENDAR_BUFFER_TOO_SMALL_TO_WRITE_VERSIT	>
		jb	quit				; carry set
		
		sub	cx, bp				; cx <- size available
							;  after copy
		add	cx, size TCHAR			; don't count the NULL
writeString:
	;
	; Copy string.
	;
		segmov	ds, cs, ax
		push	si
		mov	si, cs:[keywordStringTable][si]	; ds:si <- string
		LocalCopyString				; ax, si destroyed,
							; es:di <- EOS ie NULL
		pop	si
	;
	; Is this a property? (If so, add a colon.)
	;
		cmp	si, VKT_LAST_PROPERTY
		ja	notProperty
		mov	si, offset colonString
		LocalPrevChar	esdi
		LocalCopyString
notProperty:
		LocalPrevChar	esdi
	;
	; Should we add CRLF?
	;
		tst	dx
		jz	done
	;
	; Add CRLF.
	;
		clr	dx				; no CRLF this time
		mov	si, VKT_CRLF
		jmp	writeString
done:
		clc					; no error
quit:
		.leave
		ret
WriteVersitKeyword	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddVersitEventOrTodoBody
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Translate the normal event or to-do item into versit format,
		and write it to the buffer.

CALLED BY:	(INTERNAL) CreateVersitTextIntoBlock
PASS:		es:di	= buffer to write to
		cx	= size of buffer available (in bytes)
RETURN:		es:di	= EOS, ie. NULL
		cx	= updated
		carry	= cleared

		if not enough space:
		carry	= set
		di, cx	= not changed

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	11/ 6/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddVersitEventOrTodoBody	proc	near
		uses	ax, bx, si, bp
		.enter
		Assert	segment, es
	;
	; See if the selected event is a normal event or to-do item.
	;
		call	GetSelectedDayEventObject	; ^lbx:si <- DayEvent,
							;  si <- 0 if none
							;  selected 
	;
	; If no event is selected, quit.
	;
		tst	si
EC <		WARNING_Z EVENT_HANDLE_DOESNT_EXIST_SO_OPERATION_IGNORED>
		stc					; assume error
		jz	quit
	;
	; Is it a to-do list?
	;
		mov	ax, MSG_DE_GET_STATE_FLAGS
		call	ObjMessage_mailbox_call		; al <- EventInfoFlags
		Assert	record, al, EventInfoFlags
		test	al, mask EIF_TODO
		jnz	toDo
	;
	; Write normal event.
	;
		call	AddVersitNormalEvent		; di / cx adjusted
quit:
		.leave
		ret
toDo:
	;
	; Write to-do item.
	;
		call	AddVersitToDoEvent		; di / cx adjusted
		jmp	quit
AddVersitEventOrTodoBody	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddVersitNormalEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Translate the normal event into versit format, and write it
		to the buffer.

CALLED BY:	(INTERNAL) AddVersitEventOrTodoBody
PASS:		^lbx:si	= DayEventClass object
		es:di	= buffer to write to
		cx	= size of buffer available (in bytes)
RETURN:		es:di	= EOS, ie. NULL
		cx	= updated
		carry	= cleared

		if not enough space:
		carry	= set
		di, cx	= destroyed

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	11/ 6/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddVersitNormalEvent	proc	near
		uses	ax, dx, ds
		.enter
		Assert	segment, es
		Assert	optr, bxsi
	;
	; Write event header.
	;
		; BEGIN:EVENT
		mov	ax, VersitStringFlags<CRLF_YES, VKT_BEGIN_EVENT>
		call	WriteVersitKeyword
	;
	; Write category. We will hardcode a category because GeoPlanner does
	; not support it.
	;
		; CATEGORIES:APPOINTMENT
		mov	ax, VersitStringFlags<CRLF_YES, \
					      VKT_CATEGORIES_APPOINTMENT>
		call	WriteVersitKeyword
	;
	; Write status. Since we are sending the request, the status is
	; "Needs action".
	;
		; STATUS:
		mov	ax, VersitStringFlags<CRLF_NO, VKT_STATUS_PROP>
		call	WriteVersitKeyword
		; NEEDS ACTION
		mov	ax, VersitStringFlags<CRLF_YES, VKT_NEEDS_ACTION_VAL>
		call	WriteVersitKeyword
	;
	; Write Start/End Time.
	;
		call	WriteStartTime
		call	WriteEndTime
	;
	; Write subject summary.
	;
		; SUBJECT:
		mov	ax, VersitStringFlags<CRLF_NO, VKT_SUMMARY_PROP>
		call	WriteVersitKeyword
	;
	; Subject is the string MailboxSubjectText.
	;
		push	bx, si
		mov	bx, handle MailboxSubjectText
		call	MemLock
		mov_tr	ds, ax
assume	ds:DataBlock
		mov	si, ds:[MailboxSubjectText]
assume	ds:nothing
		call	CopyStringUpdateCount		; cx, di adjusted
		call	MemUnlock
		pop	bx, si		
		; add CRLF
		call	WriteCRLF
	;
	; Write description (event text).
	;
		call	WriteDescriptionText		
	;
	; Write alarm info, if any.
	;
		call	WriteAlarmInfo
	;
	; Write reservation day info, if any.
	;
		call	WriteReserveDaysInfo
	;
	; Write repeat info, if any.
	;
		call	WriteRepeatInfo
	;
	; Write unique identifier.
	;
		call	WriteUID
	;
	; Write password, if user specifies it.
	;
		call	WritePassword
	;
	; Write event end keywords.
	;
		; END:EVENT
		mov	ax, VersitStringFlags<CRLF_YES, VKT_END_EVENT>
		call	WriteVersitKeyword
		
		.leave
		ret
AddVersitNormalEvent	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddVersitToDoEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Translate the to-do item into versit format, and write it
		to the buffer.

CALLED BY:	(INTERNAL) AddVersitEventOrTodoBody
PASS:		^lbx:si	= DayEventClass object
		es:di	= buffer to write to
		cx	= size of buffer available (in bytes)
RETURN:		es:di	= EOS, ie. NULL
		cx	= updated
		carry	= cleared

		if not enough space:
		carry	= set
		di, cx	= destroyed

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	11/ 6/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddVersitToDoEvent	proc	near
		uses	ax, dx, ds
		.enter
		Assert	segment, es
		Assert	optr, bxsi
	;
	; Write event header.
	;
		; BEGIN:TODO
		mov	ax, VersitStringFlags<CRLF_YES, VKT_BEGIN_TODO>
		call	WriteVersitKeyword
	;
	; Write category. We will hardcode a category because GeoPlanner does
	; not support it.
	;
		; CATEGORIES:APPOINTMENT
		mov	ax, VersitStringFlags<CRLF_YES, \
					      VKT_CATEGORIES_APPOINTMENT>
		call	WriteVersitKeyword
	;
	; Write status. Since we are sending the request, the status is
	; "Needs action".
	;
		; STATUS:
		mov	ax, VersitStringFlags<CRLF_NO, VKT_STATUS_PROP>
		call	WriteVersitKeyword
		; NEEDS ACTION
		mov	ax, VersitStringFlags<CRLF_YES, VKT_NEEDS_ACTION_VAL>
		call	WriteVersitKeyword
	;
	; Write subject summary.
	;
		; SUBJECT:
		mov	ax, VersitStringFlags<CRLF_NO, VKT_SUMMARY_PROP>
		call	WriteVersitKeyword
	;
	; Subject is the string VersitTodoSubjectText.
	;
		push	bx, si
		mov	bx, handle VersitTodoSubjectText
		call	MemLock
		mov_tr	ds, ax
assume	ds:DataBlock
		mov	si, ds:[VersitTodoSubjectText]
assume	ds:nothing
		call	CopyStringUpdateCount		; cx, di adjusted
		call	MemUnlock
		pop	bx, si
		; add CRLF
		call	WriteCRLF
	;
	; Write description (event text).
	;
		call	WriteDescriptionText
	;
	; Write unique identifier.
	;
		call	WriteUID
	;
	; Write password, if user specifies it.
	;
		call	WritePassword
	;
	; Write event end keywords.
	;
		; END:TODO
		mov	ax, VersitStringFlags<CRLF_YES, VKT_END_TODO>
		call	WriteVersitKeyword
		
		.leave
		ret
AddVersitToDoEvent	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteCRLF
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write CRLF to buffer.

CALLED BY:	(INTERNAL)
PASS:		es:di	= buffer to write to
		cx	= size of buffer available (in bytes)
RETURN:		es:di	= EOS, ie. NULL
		cx	= updated
		carry	= cleared

		if not enough space:
		carry	= set
		di, cx	= not changed

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	11/ 7/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteCRLF	proc	near
		uses	ax, si
		.enter
		Assert	segment, es

		mov	ax, VersitStringFlags<CRLF_NO, VKT_CRLF>
		call	WriteVersitKeyword		; carry set if error
		.leave
		ret
WriteCRLF	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteStartTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the start time of event, and write to buffer.

CALLED BY:	(INTERNAL) AddVersitNormalEvent
PASS:		^lbx:si	= DayEventClass object
		es:di	= buffer to write to
		cx	= size of buffer available (in bytes)
RETURN:		es:di	= EOS, ie. NULL
		cx	= updated
		carry	= cleared

		if not enough space:
		carry	= set
		di, cx	= destroyed
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	11/15/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteStartTime	proc	near
		uses	ax, dx, bp
		.enter
		Assert	optr, bxsi
		Assert	segment, es
	;
	; Write start time.
	;
		; DTSTART:
		mov	ax, VersitStringFlags<CRLF_NO, VKT_DTSTART_PROP>
		call	WriteVersitKeyword
	;
	; Get start date/time of event.
	;
		; ^lbx:si = DayEvent obj
		mov	ax, MSG_DE_GET_TIME
		push	cx				; size
		call	ObjMessage_mailbox_call		; bp <- year, (*)
							; dx <- month/day,(*)
							; cx <- hour/min
							; carry set if no 
							; start time
		mov_tr	ax, cx				; ax <- hour/min(*)
		pop	cx
	;
	; If no start time, change the hour/min to -1.
	;
		jnc	hasTime
		mov	ax, CAL_NO_TIME
hasTime:
		call	WriteVersitDateAndTime
		
		; add CRLF
		call	WriteCRLF

		clc					; no error
		.leave
		ret
WriteStartTime	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteEndTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the end time of event, and write to buffer.

CALLED BY:	(INTERNAL) AddVersitNormalEvent
PASS:		^lbx:si	= DayEventClass object
		es:di	= buffer to write to
		cx	= size of buffer available (in bytes)
RETURN:		es:di	= EOS, ie. NULL
		cx	= updated
		carry	= cleared

		if not enough space:
		carry	= set
		di, cx	= destroyed
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Get end date.
		Get end time.
		if (no end time) {
			if (has end date) {
				time <- -1,
				write text
			} else {
				return, no text written
			}
		} else {
			use start date as date
			write text
		}

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	11/15/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteEndTime	proc	near
		uses	ax, dx, bp
		.enter
		Assert	optr, bxsi
		Assert	segment, es
	;
	; Any end date?
	;
		push	cx
		mov	ax, MSG_DE_GET_END_DATE_TIME
		call	ObjMessage_mailbox_call	; bp <- year, (*)
						;  dx <- month/date (*) 
						;  cx <- hour/min or -1,
						;  bp, dx <- start date,
						;  ax destroyed
						;  carry set if no time/date
		mov_tr	ax, cx
		pop	cx
		jc	quit
	;
	; Write end time property and end time.
	;
		; DTEND:
		push	ax
		mov	ax, VersitStringFlags<CRLF_NO, VKT_DTEND_PROP>
		call	WriteVersitKeyword
		pop	ax

		call	WriteVersitDateAndTime
		; add CRLF
		call	WriteCRLF
quit:
		clc					; no error
		.leave
		ret
WriteEndTime	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteVersitDateAndTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Translate the date and time into versit format, and write it
		to the buffer. CRLF not added.

CALLED BY:	(INTERNAL) CreateVersitTextIntoBlock
PASS:		bp	= year
		dx	= month / day
		ax	= hour / min, CAL_NO_TIME (-1) if none
		es:di	= buffer to write to
		cx	= size of buffer available (in bytes)
RETURN:		es:di	= EOS, ie. NULL
		cx	= updated
		carry	= cleared

		if not enough space:
		carry	= set
		di, cx	= not changed

DESTROYED:	Nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Because the kernel has the wonderful
		LocalCustomFormatDateTime, we will make use of it.

		Versit date time format is
			yyyymmddThhmmss		e.g. 19960401T033000

		if no time is specified, we skip writing the time;
		ie.
			yyyymmdd		e.g. 19960401

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	11/ 7/96    	Initial version
	kho	2/17/97		Time can now be -1.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
iso8601FormatString	TCHAR	\
	TOKEN_DELIMITER, TOKEN_LONG_YEAR, TOKEN_DELIMITER, \
	TOKEN_DELIMITER, TOKEN_ZERO_PADDED_MONTH, TOKEN_DELIMITER, \
	TOKEN_DELIMITER, TOKEN_ZERO_PADDED_DATE, TOKEN_DELIMITER, \
	'T', \
	TOKEN_DELIMITER, TOKEN_ZERO_PADDED_24HOUR, TOKEN_DELIMITER, \
	TOKEN_DELIMITER, TOKEN_ZERO_PADDED_MINUTE, TOKEN_DELIMITER, \
	TOKEN_DELIMITER, TOKEN_ZERO_PADDED_SECOND, TOKEN_DELIMITER, 0;

iso8601DateFormatString	TCHAR	\
	TOKEN_DELIMITER, TOKEN_LONG_YEAR, TOKEN_DELIMITER, \
	TOKEN_DELIMITER, TOKEN_ZERO_PADDED_MONTH, TOKEN_DELIMITER, \
	TOKEN_DELIMITER, TOKEN_ZERO_PADDED_DATE, TOKEN_DELIMITER, 0;

WriteVersitDateAndTime	proc	near
		uses	ax, bx, dx, ds, si
		.enter
		Assert	segment, es
	;
	; If not enough space to write to, return.
	;
		cmp	cx, ISO8601_DATE_TIME_STRING_LENGTH*size TCHAR
		jb	quit				; carry set if b
	;
	; Set up the date/time registers.
	;
		push	cx

		mov_tr	cx, ax				; ch <- hour, (*)
							; cl <- min
		mov	ax, bp				; ax <- year (*)
		mov	bx, dx
		xchg	bh, bl				; bl <- month, (*)
							; bh <- day (*)
		mov	dl, cl				; dl <- min (*)
		clr	dh				; dh <- second (*)
	;
	; Call LocalCustomFormatDateTime
	;
		segmov	ds, cs, si
		mov	si, offset iso8601FormatString
		cmp	ch, CAL_NO_TIME
		jne	gotFormatString
		mov	si, offset iso8601DateFormatString
gotFormatString:
		call	LocalCustomFormatDateTime	; cx <- # chars in
DBCS <		shl	cx, 1						>
		pop	ax				; # bytes available
							;  before
	;
	; Update es:di <- EOS and cx byte count.
	;
		sub	ax, cx				; # bytes available now
		add	di, cx				; update es:di
		mov_tr	cx, ax
quit:
		.leave
		ret
WriteVersitDateAndTime	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyStringUpdateCount
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do a string copy, and the size written is subtracted from
		count register.

		This routine would only write up to
		MAX_TEXT_FIELD_LENGTH+1 (256) chars. A ';' or '\' counts as two
		chars because it is escaped by backslash.

CALLED BY:	(INTERNAL)
PASS:		ds:si	= ptr to source (null terminated string)
		es:di	= ptr to dest
		cx	= count register
RETURN:		es:di	= end of string, ie. NULL
		cx	= updated
		carry	= cleared

		if not enough space to write string:
		carry	= set
		cx, di	= destroyed

DESTROYED:	nothing (cx, di if not enough space)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	11/ 7/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyStringUpdateCount	proc	near
		uses	ax, si
		.enter
	;
	; Enough space?
	;
		cmp	cx, (MAX_TEXT_FIELD_LENGTH)*(size TCHAR)
EC <		WARNING_B CALENDAR_BUFFER_TOO_SMALL_TO_WRITE_VERSIT	>
		jb	quit				; carry set
	;
	; We write at most MAX_TEXT_FIELD_LENGTH+1
	;
		push	cx
		mov	cx, MAX_TEXT_FIELD_LENGTH+1

charLoop:	;-------------------------------------------------------

		jcxz	enough				; if already 255
							; chars, quit
SBCS <		lodsb							>
DBCS <		lodsw							>
	;
	; Is it a backslash?
	;
		LocalCmpChar	ax, '\\'
		je	addBackslash
	;
	; Is it a semi-colon?
	;
		LocalCmpChar	ax, ';'
		jne	notSemi
addBackslash:
	;
	; Add backslash.
	;
		push	ax
		LocalLoadChar	ax, '\\'
SBCS <		stosb							>
DBCS <		stosw							>
		dec	cx
		pop	ax
		jcxz	enough				; quit if enough chars
notSemi:
	;
	; Convert a carriage-return to a space.
	;
		LocalCmpChar	ax, C_CR
		jne	notCR
		LocalLoadChar	ax, C_SPACE
notCR:
	;
	; Store the char.
	;
SBCS <		stosb							>
DBCS <		stosw							>
		dec	cx
	;
	; Do we have null?
	;
SBCS <		tst	al						>
DBCS <		tst	ax						>
		jnz	charLoop
		;-------------------------------------------------------
	;
	; es:di should point to NULL, not the char after it.
	;
		LocalPrevChar	esdi
		inc	cx				; excluding null
enough:
		pop	ax
	;
	; Now:		ax = original # char available
	;		cx = (MAX_TEXT_FIELD_LENGTH+1) - # char written
	;			(excluding null)
	; Need:		cx = original - # char written (excluding null)
	;
	; Return the updated size:  ax + cx -(MAX_TEXT_FIELD_LENGTH+1)
	;
		add	cx, ax
		sub	cx, MAX_TEXT_FIELD_LENGTH+1
		clc					; no error
quit:
		.leave
		ret
CopyStringUpdateCount	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteDescriptionText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write description to buffer, in versit format.

CALLED BY:	(INTERNAL)
PASS:		^lbx:si	= DayEventClass object
		es:di	= buffer to write to
		cx	= size of buffer available (in bytes)
RETURN:		es:di	= EOS, ie. NULL
		cx	= updated
		carry	= cleared

		if not enough space:
		carry	= set
		di, cx	= not changed
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		We are writing...

			DESCRIPTION:Exciting event text...

		The max size of text written would be =
			(MAX_TEXT_FIELD_LENGTH) * size TCHAR +
			size descriptionProp

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	11/17/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteDescriptionText	proc	near
		uses	ax, dx, ds, si
eventText	local	MAX_TEXT_FIELD_LENGTH+1 dup (TCHAR)	; +1 for null
		.enter
		Assert	optr, bxsi
		Assert	segment, es
	;
	; Enough space?
	;
		cmp	cx, MAX_TEXT_FIELD_LENGTH*(size TCHAR)+\
				(size descriptionProp)
EC <		WARNING_B CALENDAR_BUFFER_TOO_SMALL_TO_WRITE_VERSIT	>
		jb	quit				; carry set if b
	;
	; Write the property.
	;
		; DESCRIPTION:
		mov	ax, VersitStringFlags<CRLF_NO, VKT_DESCRIPTION_PROP>
		call	WriteVersitKeyword
	;
	; Get the event text into local eventText buffer.
	;
		push	cx, bp
		mov	ax, MSG_DE_GET_TEXT_ALL_PTR
		mov	dx, ss
		lea	bp, ss:[eventText]		; dx:bp = ptr to text
		call	ObjMessage_mailbox_call		; cx <- string length
							; not counting NULL
	; Make sure the buffer doesn't overflow.
EC <		cmp	cx, MAX_TEXT_FIELD_LENGTH			>
EC <		ERROR_A	CALENDAR_EVENT_TEXT_TOO_BIG			>
		pop	cx, bp				; ax <- available size
	;
	; Copy to the buffer.
	;
		mov	ds, dx
		lea	si, ss:[eventText]		; ds:si <- text
		call	CopyStringUpdateCount
		; add CRLF
		call	WriteCRLF

		clc					; no error
quit:
		.leave
		ret
WriteDescriptionText	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteUID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write unique ID string to buffer, in versit format.

CALLED BY:	(INTERNAL)
PASS:		^lbx:si	= DayEventClass object
		es:di	= buffer to write to
		cx	= size of buffer available (in bytes)
RETURN:		es:di	= EOS, ie. NULL
		cx	= updated
		carry	= cleared

		if not enough space:
		carry	= set
		di, cx	= not changed
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		We are writing...

			UID:9000i-131074-15

		ie.
			UID: lizzy-uid-prefix <unique ID> <book ID>

		max length is VERSIT_UID_STRING_MAX_LENGTH + length(UID:).


REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	2/ 3/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteUID	proc	near
		uses	ax, bx, dx, si, bp
		.enter
		Assert	optr, bxsi
		Assert	segment, es
	;
	; Enough space?
	;
		cmp	cx, VERSIT_UID_STRING_MAX_LENGTH*(size TCHAR)+\
				(size uidProp)
EC <		WARNING_B CALENDAR_BUFFER_TOO_SMALL_TO_WRITE_VERSIT	>
		jb	quit				; carry set if b
	;
	; Write the property.
	;
		; UID:
		mov	ax, VersitStringFlags<CRLF_NO, VKT_UID_PROP>
		call	WriteVersitKeyword
	;
	; Write the lizzy UID Prefix with the dash.
	;
		; 9000i-
		mov	ax, VersitStringFlags<CRLF_NO, VKT_LIZZY_UID_PREFIX>
		call	WriteVersitKeyword
	;
	; Get the unique event ID.
	;
		push	cx
		mov	ax, MSG_DE_GET_UNIQUE_ID
		call	ObjMessage_mailbox_call		; cxdx <- unique ID

		mov_tr	ax, dx
		mov	dx, cx				; dxax <- ID
		pop	cx
	;
	; Write the unique event ID.
	;
		call	WriteDWordToAscii		; di, cx updated
	;
	; Write the dash.
	;
		mov	ax, VersitStringFlags<CRLF_NO, VKT_DASH>
		call	WriteVersitKeyword
	;
	; Get the appointment book ID for the event from
	; BookingSMSAddressControl.
	;
		push	cx
		mov	bx, handle BookingSMSAddressControl
		mov	si, offset BookingSMSAddressControl
		mov	ax, MSG_CALENDAR_ADDRESS_CTRL_GET_BOOK_ID
		call	ObjMessage_mailbox_call		; cx <- ID, ax gone

		mov_tr	ax, cx
		clr	dx				; dxax <- ID
		pop	cx
	;
	; Write the book ID.
	;
		call	WriteDWordToAscii		; di, cx updated
		; add CRLF
		call	WriteCRLF

		clc					; no error
quit:
		.leave
		ret
WriteUID	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteDWordToAscii
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write the passed dword into buffer, in ascii format.

CALLED BY:	(INTERNAL) WriteUID, CreateVersitReplyIntoBlock
PASS:		dxax	= dword
		es:di	= buffer to write to
		cx	= size of buffer available (in bytes)
RETURN:		es:di	= EOS, ie. NULL
		cx	= updated
		carry	= cleared

		if not enough space:
		carry	= set
		di, cx	= not changed
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Just call UtilHex32ToAscii and update the count.

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	2/10/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteDWordToAscii	proc	near
		uses	ax
		.enter
		Assert	segment, es
	;
	; Enough space? A dword ascii-ized would take up to ten	characters.
	;
SBCS <		cmp	cx, 11						>
DBCS <		cmp	cx, 22						>
		jb	quit				; carry set if b
	;
	; Write to buffer.
	;
		push	cx
		mov	cx, mask UHTAF_NULL_TERMINATE	; flags
		call	UtilHex32ToAscii		; cx <- string length
							;  not including null
DBCS <		shl	cx						>
	;
	; Update string pointer.
	;
		add	di, cx				; es:di <- str end
	;
	; Calculate updated size.
	;
		mov_tr	ax, cx
		pop	cx
		sub	cx, ax				; cx <- size left

		clc					; no error
quit:
		.leave
		ret
WriteDWordToAscii	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteAlarmInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write alarm information to buffer, in versit format.

CALLED BY:	(INTERNAL)
PASS:		^lbx:si	= DayEventClass object
		es:di	= buffer to write to
		cx	= size of buffer available (in bytes)
RETURN:		es:di	= EOS, ie. NULL
		cx	= updated
		carry	= cleared

		if not enough space:
		carry	= set
		di, cx	= not changed
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Versit format:

			DALARM:19960415T235000Z;PT5M;2;Text

		Keyword, alarm time, snooze time, repeat count, display string

		We would only write Keyword and alarm time, ie.

			DALARM:19960415T235000Z;;0;

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	11/11/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteAlarmInfo	proc	near
		uses	ax, bx, dx, ds, si, bp
		.enter
		Assert	segment, es
		Assert	optr, bxsi
	;
	; Enough space?
	;
		cmp	cx, VERSIT_ALARM_INFO_MAX_LENGTH*(size TCHAR)
EC <		WARNING_B CALENDAR_BUFFER_TOO_SMALL_TO_WRITE_VERSIT	>
		jb	quit				; carry set
	;
	; Any alarm?
	;
		push	cx
		mov	ax, MSG_DE_GET_ALARM
		call	ObjMessage_mailbox_call		; carry cleared if no
							; alarm, else:
							;  bp <- year,
							;  dx <- month/day,
							;  cx <- hour/min
		mov	si, cx				; si <- hour/min
		pop	cx
		jnc	quit
	;
	; Write property.
	;
		; DALARM:
		mov	ax, VersitStringFlags<CRLF_NO, VKT_DALARM_PROP>
		call	WriteVersitKeyword
	;
	; Arrange the registers for LocalCustomFormatDateTime
	;
		push	cx
		mov_tr	ax, bp				; ax <- year (*)
		mov	bx, dx
		xchg	bl, bh				; bh <- day, (*)
							; bl <- month (*)
		clr	dh				; dh <- seconds (*)
		mov	cx, si				; ch <- hour (*)
		mov	dl, cl				; dl <- Minutes (*)
	;
	; Call LocalCustomFormatDateTime to write the string, using the
	; format string iso8601FormatString.
	;
		segmov	ds, cs, si
		mov	si, offset iso8601FormatString
		call	LocalCustomFormatDateTime	; cx <- # chars in
							;  string
DBCS <		shl	cx, 1						>
		pop	ax				; # bytes available
							;  before
	;
	; Update es:di <- EOS and cx byte count.
	;
		sub	ax, cx				; # bytes available now
		add	di, cx				; update es:di
		mov_tr	cx, ax
	;
	; And end the whole line with a canned string, ";;0;".
	;
		mov	ax, VersitStringFlags<CRLF_YES, VKT_DALARM_SUFFIX>
		call	WriteVersitKeyword
		clc					; no error
quit:
		.leave
		ret
WriteAlarmInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteReserveDaysInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write reservation days info to buffer, in versit format.

CALLED BY:	(INTERNAL)
PASS:		^lbx:si	= DayEventClass object
		es:di	= buffer to write to
		cx	= size of buffer available (in bytes)
RETURN:		es:di	= EOS, ie. NULL
		cx	= updated
		carry	= cleared

		if not enough space:
		carry	= set
		di, cx	= not changed
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Versit has no such support, so we write..

			X-NOKIA-RESERVED-DAYS:5

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	2/20/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteReserveDaysInfo	proc	near
		uses	ax, dx
		.enter
		Assert	segment, es
		Assert	optr, bxsi
	;
	; Enough space?
	;
		cmp	cx, size xNokiaReservedDaysProp+3*(size TCHAR)
EC <		WARNING_B CALENDAR_BUFFER_TOO_SMALL_TO_WRITE_VERSIT	>
		jb	quit				; carry set
	;
	; See if we have reserved-days?
	;
		push	cx
		mov	ax, MSG_DE_GET_RESERVED_DAYS
		call	ObjMessage_mailbox_call		; cx <- # reserved
							;  days, carry
							;  set if none
		mov	dx, cx
		pop	cx
	;
	; Quit if no reserved days.
	;
		cmc
		jnc	quit
	;
	; Write property.
	;
		; X-NOKIA-RESERVED-DAYS:
		mov	ax, VersitStringFlags<CRLF_NO, \
				VKT_X_NOKIA_RESERVED_DAYS_PROP>  
		call	WriteVersitKeyword
	;
	; Write value.
	;
		; dx == # of days
		clr	ax
		xchg	ax, dx				; dxax <- #
		call	WriteDWordToAscii
	;
	; Write CRLF.
	;
		call	WriteCRLF
quit:		
		.leave
		ret
WriteReserveDaysInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteRepeatInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write repeat information to buffer, in versit format.

CALLED BY:	(INTERNAL)
PASS:		^lbx:si	= DayEventClass object
		es:di	= buffer to write to
		cx	= size of buffer available (in bytes)
RETURN:		es:di	= EOS, ie. NULL
		cx	= updated
		carry	= cleared

		if not enough space:
		carry	= set
		di, cx	= not changed
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Versit format:

			RRULE:D1 #0		(daily)
			RRULE:W1 #0		(weekly)
			RRULE:M1 #0		(monthly)
			RRULE:Y1 #0		(yearly)
			RRULE:W2 #0		(biweekly)
			RRULE:D1 19970701Txxxxxx(daily until July 1 1997)

		Responder calendar only does repeat until (date). Versit
		format insists on a time too, so we will use a dummy time.
		(REPEAT_RULE_DUMMY_TIME, 00:00)

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Even though the MBRepeatIntervalType is
		MBRIT_MONTHLY_WEEKDAY, the written versit text still
		says MD1 (i.e. monthly by day, instead of by
		position). Ditto for MBRIT_YEARLY_WEEKDAY.

		It's ok, because calendar does not support the
		by-position repeat rules.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	11/12/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteRepeatInfo	proc	near
		uses	ax, bx, dx, si, bp
		.enter
		Assert	segment, es
	;
	; Find repeat type of event.
	;
		mov	ax, MSG_DE_GET_REPEAT_TYPE
		call	ObjMessage_mailbox_call		; ax <-
							; EventOptionsTypeType
							; if repeat until:
							; dx <- month/day,
							; bp <- year, cf set
							; else dx, bp <- -1
		Assert	etype, ax, EventOptionsTypeType
	;
	; One time only?
	;
		cmp	ax, EOTT_ONE_TIME
		je	quitNoError
		mov_tr	bx, ax				; bx <- frequency
	;
	; Enough space?
	;
		cmp	cx, VERSIT_REPEAT_INFO_MAX_LENGTH*(size TCHAR)
EC <		WARNING_B CALENDAR_BUFFER_TOO_SMALL_TO_WRITE_VERSIT	>
		jb	quit				; carry set
	;
	; Write property.
	;
		; RRULE:
		mov	ax, VersitStringFlags<CRLF_NO, VKT_RRULE_PROP>
		call	WriteVersitKeyword
	;
	; Write the right string.  D1/W1/M1/Y1/W2
	;
		mov	ax, cs:[repeatRuleTable][bx]
		call	WriteVersitKeyword
	;
	; Is it repeat forever?
	;
		cmp	bp, CAL_NO_DATE
		jne	notForever
	;
	; Write repeat forever token.
	;
		; #0
		mov	ax, VersitStringFlags<CRLF_YES, VKT_REPEAT_FOREVER>
		call	WriteVersitKeyword
		
quitNoError:
		clc
quit:
		.leave
		ret
notForever:
	;
	; Now we should write the end date of repeat-until. ie.
	; we write:
	;
	;	RRULE: D1 19970701T080000
	;
		; dx == month/day, bp == year
		mov	ax, REPEAT_RULE_DUMMY_TIME	; 00:00
		call	WriteVersitDateAndTime
	;
	; Write CRLF.
	;
		call	WriteCRLF
		jmp	quitNoError
		
WriteRepeatInfo	endp

CheckHack<(length repeatRuleTable*2) eq EventOptionsTypeType>

repeatRuleTable VersitKeywordType \
	-1,			; EOTT_ONE_TIME			; illegal!
	VKT_YEARLY_RULE,	; EOTT_ANNIVERSARY
	VKT_DAILY_RULE,		; EOTT_DAILY
	VKT_WEEKLY_RULE,	; EOTT_WEEKLY
	VKT_MONTHLY_RULE,	; EOTT_MONTHLY
	VKT_BIWEEKLY_RULE,	; EOTT_BIWEEKLY
	VKT_WORKING_DAYS_RULE	; EOTT_WORKING_DAYS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WritePassword
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write password information to buffer, in versit format.

CALLED BY:	(INTERNAL)
PASS:		es:di	= buffer to write to
		cx	= size of buffer available (in bytes)
RETURN:		es:di	= EOS, ie. NULL
		cx	= updated
		carry	= cleared

		if not enough space:
		carry	= set
		di, cx	= not changed
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Use X-NOKIA-PASSWD for property, because versit
		doesn't have this property.

		e.g.	X-NOKIA-PASSWD:blahblah

		Password is at most CALENDAR_PASSWORD_LENGTH (8) chars
		long.

		Usually the password of a recipient is fetched
		from contdb. However, if the user manually enters a
		number, and the number does not match any contact,
		then we bring up password dialog.

		if (recipient has matching contact) {
			fetch password from BookingSMSAddressControl
		} else {
			fetch password from password dialog text
		}

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	11/12/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WritePassword	proc	near
		uses	ax
		.enter
		Assert	segment, es
	;
	; Do we have enough space to write info?
	;
		cmp	cx, VERSIT_PASSWORD_INFO_MAX_LENGTH
EC <		WARNING_B CALENDAR_BUFFER_TOO_SMALL_TO_WRITE_VERSIT	>
		jb	quit				; carry set
	;
	; Are we doing event request or event reservation?
	;
		call	GetBookEventType		; ax <-BookingEventType
		cmp	ax, BET_NORMAL_EVENT
		je	noPasswd
	;
	; Write the password.
	; Property first.
	;
		; X-NOKIA-PASSWD
		mov	ax, VersitStringFlags<CRLF_NO, VKT_X_NOKIA_PASSWD_PROP>
		call	WriteVersitKeyword
	;
	; Write the password to buffer.
	;
		push	bx, cx, dx, si, bp
	;
	; Do we have matching contact for recipient?
	;
		mov	bx, handle BookingSMSAddressControl
		mov	si, offset BookingSMSAddressControl
		mov	ax, MSG_CALENDAR_ADDRESS_CTRL_GET_MISC_FLAGS
		call	ObjMessage_mailbox_call		; cl <-
							; CalAddressCtrlFlags
		Assert	record, cl, CalAddressCtrlFlags

		mov	ax, MSG_CALENDAR_ADDRESS_CTRL_GET_RECIPIENT_PASSWD
		test	cl, mask CACF_HAS_MATCHING_CONTACT
		jnz	fetchText
	;
	; Fetch text from PasswordText instead.
	;
		mov	bx, handle PasswordText
		mov	si, offset PasswordText
		mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
fetchText:
		mov	dx, es
		mov	bp, di				; dx:bp <- buffer
		call	ObjMessage_mailbox_call		; buffer filled,
							; cx <- length
							;  not counting NULL
							; ax destroyed
		mov_tr	ax, cx				; ax <- length
		Assert	le, ax, CALENDAR_PASSWORD_LENGTH
		pop	bx, cx, dx, si, bp
	;
	; Adjust es:di and cx.
	;
DBCS <		shl	ax						>
		sub	cx, ax
		add	di, ax
	;
	; Write CRLF
	;
		call	WriteCRLF
noPasswd:		
		clc
quit:
		.leave
		ret
WritePassword	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteCreatedEventID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write remote event ID, if any, in versit format.

CALLED BY:	(INTERNAL)
PASS:		es:di	= buffer to write to
		cx	= size of buffer available (in bytes)
		dxax	= created event ID
RETURN:		es:di	= EOS, ie. NULL
		cx	= updated
		carry	= cleared

		if not enough space:
		carry	= set
		di, cx	= not changed
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		We are writing...

			X-NOKIA-CREATED-EVENT:10303040

		max length is VERSIT_UID_STRING_MAX_LENGTH +
		length(dword ascii-ized).

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	2/15/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteCreatedEventID	proc	near
		.enter
	;
	; Enough space?
	;
		cmp	cx, VERSIT_UID_STRING_MAX_LENGTH*(size TCHAR)+11
EC <		WARNING_B CALENDAR_BUFFER_TOO_SMALL_TO_WRITE_VERSIT	>
		jb	quit				; carry set if b
	;
	; If created event ID is invalid, don't write it.
	;
		cmpdw	dxax, INVALID_EVENT_ID
		je	done
	;
	; Write property.
	;
		; X-NOKIA-CREATED-EVENT:
		push	ax
		mov	ax, VersitStringFlags<CRLF_NO, \
				VKT_X_NOKIA_CREATED_EVENT_PROP>
		call	WriteVersitKeyword
		pop	ax
	;
	; Write value.
	;
		; dxax == dword
		call	WriteDWordToAscii		; di, cx updated
	;
	; Add CR-LF.
	;
		call	WriteCRLF
done:
		clc					; no error
quit:
		.leave
		ret
WriteCreatedEventID	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoPlannerBookAsSMS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User presses "Send as SMS" in booking event
		view. Bring up SMS address controller.

CALLED BY:	MSG_CALENDAR_BOOK_AS_SMS
PASS:		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	10/31/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoPlannerBookAsSMS	method dynamic GeoPlannerClass, 
					MSG_CALENDAR_BOOK_AS_SMS
mediumArgs	local	MACSetMediumArgs
		.enter
	;
	; Ask for recipient with contact selector.
	; Curiously, we do not initialize the mediumArgs, and yet the
	; super class of BookingSMSAddressControl is doing the right
	; thing. I suspect that is because the controller only knows
	; how to do SMS, and so it ignores theMACSetMediumArgs.
	;
		push	bp
		mov	bx, handle BookingSMSAddressControl
		mov	si, offset BookingSMSAddressControl
		lea	bp, ss:[mediumArgs]		; ss:bp <-
							;  MACSetMediumArgs
		mov	ax, MSG_MAILBOX_ADDRESS_CONTROL_SET_MEDIUM
		call	ObjMessage_mailbox_call_fixup	; ax, cx, dx, bp gone
		pop	bp

		.leave
		ret
GeoPlannerBookAsSMS	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoPlannerDisplayEventSummary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stuff and display the summary window for the booking event.

CALLED BY:	MSG_CALENDAR_DISPLAY_EVENT_SUMMARY
PASS:		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	1/ 8/97   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoPlannerDisplayEventSummary	method dynamic GeoPlannerClass, 
					MSG_CALENDAR_DISPLAY_EVENT_SUMMARY
		.enter
	;
	; Stuff the SMS event summary window with text.
	;
		call	StuffSMSEventSummary		; everything destroyed
	;
	; Initiate the summary window.
	;
		mov	bx, handle BookingSummaryDialog
		mov	si, offset BookingSummaryDialog
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		call	ObjMessage_mailbox_call
	;
	; Send the text object an invalidate message to recalculate
	; geometry, because of a bug in spui.
	;
		mov	bx, handle EventRecipientText
		mov	si, offset EventRecipientText
		mov	ax, MSG_VIS_MARK_INVALID
		mov	cl, mask VOF_GEOMETRY_INVALID or mask VOF_IMAGE_INVALID
		mov	dl, VUM_DELAYED_VIA_APP_QUEUE
		call	ObjMessage_mailbox_send
	;
	; Scroll the GenView to top; because no children of the
	; content has focus, the view is scrolled to bottom by
	; default.
	;
		mov	bx, handle BookingSummaryView
		mov	si, offset BookingSummaryView
		mov	ax, MSG_GEN_VIEW_SCROLL_TOP
		call	ObjMessage_mailbox_send
		
		.leave
		ret
GeoPlannerDisplayEventSummary	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StuffSMSEventSummary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stuff the SMS event summary window with text.

CALLED BY:	(INTERNAL) GeoPlannerDisplayEventSummary
PASS:		nothing
RETURN:		nothing
DESTROYED:	everything
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Create an MBAppointment structure.
		Fill in the details with the data from selected
		DayEventObject.
		Call CopyAndFormatWritableChunk.
		Copy tempWritableChunk to EventSummaryText.

		Call CopyAndFormatWritableChunk to copy
		EFST_RECIPIENT_INFO string.
		Create recipient info from BookingSMSAddressControl.
		Copy tempWritableChunk to EventRecipientText.
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	12/30/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StuffSMSEventSummary	proc	near
		.enter
	;
	; We need to create an MBAppointment struct.
	;
		call	AllocateAndInitMBAppointment	; es <- MBAppointment,
							;  bx <- block handle,
							;  carry set if error.
		jc	quit
		Assert	handle, bx
		Assert	segment, es
	;
	; See if the selected event is a normal event or to-do item.
	;
		push	bx

		call	GetSelectedDayEventObject	; ^lbx:si <- DayEvent,
							;  si <- 0 if none
							;  selected 
	;
	; If no event is selected, quit.
	;
		tst	si
EC <		WARNING_Z EVENT_HANDLE_DOESNT_EXIST_SO_OPERATION_IGNORED>
		jz	freeMem
	;
	; Write description into MBAppointment.
	;
		mov	dx, es
		lea	bp, es:[MBA_description]	; dx:bp <- buffer
		mov	ax, MSG_DE_GET_TEXT_ALL_PTR
		call	ObjMessage_mailbox_call_fixup	; cx <- string length
							; not counting NULL
DBCS <		shl	cx						>
		mov	es:[MBA_descSize], cx
	;
	; If we are doing to-do item, no more stuff to add in the
	; MBAppointment structure.
	;
		mov	ax, MSG_DE_GET_STATE_FLAGS
		call	ObjMessage_mailbox_call_fixup	; al <- EventInfoFlags
		Assert	record, al, EventInfoFlags
		test	al, mask EIF_TODO
		jnz	createString
	;
	; Get start date/time of event.
	;
		; ^lbx:si = DayEvent obj
		mov	ax, MSG_DE_GET_TIME
		call	ObjMessage_mailbox_call_fixup	; bp <- year,
							;  dx <- month/day,
							;  cx <- hour/min,
							;  carry set if no
							;  start time
		jnc	hasStartTime
		mov	cx, CAL_NO_TIME
hasStartTime:
		push	dx
		call	CreateFileDateTimeFromGetTime	; dx <- FileDate,
							;  cx <- FileTime
							;  ax destroyed
		movdw	es:[MBA_start], cxdx
		pop	dx
		
	;
	; Get end date/time of event, if any.
	;
		mov	ax, MSG_DE_GET_END_DATE_TIME
		call	ObjMessage_mailbox_call_fixup
						; bp <- year, (*)
						;  dx <- month/date (*) 
						;  cx <- hour/min or -1,
						;  bp, dx <- start date,
						;  ax destroyed
						;  carry set if no time/date
		
		jc	noEndDateTime

		call	CreateFileDateTimeFromGetTime	; dx <- FileDate,
							;  cx <- FileTime
							;  ax destroyed
		movdw	es:[MBA_end], cxdx
noEndDateTime:
	;
	; Get reservation days, if any.
	;
		mov	ax, MSG_DE_GET_RESERVED_DAYS
		call	ObjMessage_mailbox_call		; cx <- # reserved
							;  days, carry
							;  set if none
		jc	noReserve
		mov	es:[CALENDAR_ESCAPE_DATA_OFFSET].CAET_reserveWholeDay,\
				cx
		mov	es:[MBA_end].FDAT_date, MB_NO_TIME
							; no end date
							;  if reserve
noReserve:
	;
	; Get alarm time, if any.
	;
		mov	ax, MSG_DE_GET_ALARM_PRECEDE_TIME
		call	ObjMessage_mailbox_call		; ax <- # alarm minute
							;  carry set if none
		jc	noAlarm

		CheckHack<(offset MBAI_HAS_ALARM) eq 13>
		Assert	le, ax, 8192			; MBAI_INTERVAL 
							; is 13 bits long 
		ornf	ax, MBAlarmInfo<MBAIT_MINUTES, 1, 0>
		mov	es:[MBA_alarmInfo], ax
noAlarm:
	;
	; Check repetition.
	;
		mov	ax, MSG_DE_GET_REPEAT_TYPE
		call	ObjMessage_mailbox_call		; ax <-
							; EventOptionsTypeType
							; if repeat until:
							; dx <- month/day,
							; bp <- year, cf set
		cmp	ax, EOTT_ONE_TIME
		je	createString
	;
	; Get MBRepeatInterval, and fill it to MBAppointment.
	;
		mov_tr	si, ax
		mov	ax, cs:[eottToMBRepeatTable][si]; ax <-
							;  MBRepeatInterval
		mov	di, CALENDAR_REPEAT_INFO_OFFSET
		mov	es:[MBA_repeatInfo], di
		mov	es:[di].MBRI_interval, ax
		clr	es:[di].MBRI_numExceptions
	;
	; Create repeat-until date, if we have it.
	;
		cmp	dx, CAL_NO_DATE
		je	createString
		
		mov	cx, CAL_NO_TIME
		call	CreateFileDateTimeFromGetTime	; dx <- FileDate,
							;  ax, cx destroyed
		mov	es:[di].MBRI_duration, MBRD_UNTIL
		mov	es:[di].MBRI_durationData.MBRDD_until, dx
createString:
	;
	; Finally, MBAppointment is all filled in. Let's do copy
	; string.
	;
		mov	si, EFST_NORMAL_EVENT_REQUEST
		call	CopyAndFormatWritableChunk	; tempWritableChunk
							;  written
	;
	; We get our string now, so put it into EventSummaryText.
	;
		mov	bx, handle EventSummaryText
		mov	si, offset EventSummaryText	; ^bx:si - text obj
		mov	dx, handle tempWritableChunk
		mov	bp, offset tempWritableChunk
		clr	cx				; null terminated
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_OPTR
		call	ObjMessage_mailbox_call_fixup	; ax, cx, dx, bp gone
	;
	; Handle multiple selection from SMS controller.
	;
		call	StuffNameAndSMSToText		; everthing destroyed
	;
	; Free the MBAppointment struct.
	;
freeMem:
		pop	bx
		Assert	handle, bx
		call	MemFree				; bx destroyed
quit:
		.leave
		ret
StuffSMSEventSummary	endp

eottToMBRepeatTable	MBRepeatInterval \
	-1,						; EOTT_ONE_TIME
	MBRepeatInterval<0, 0, 0, MBRIT_YEARLY_DATE>,	; EOTT_ANNIVERSARY
	MBRepeatInterval<0, 0, 0, MBRIT_DAILY>,		; EOTT_DAILY
	MBRepeatInterval<0, 0, 0, MBRIT_WEEKLY>,	; EOTT_WEEKLY
	MBRepeatInterval<0, 0, 0, MBRIT_MONTHLY_DATE>,	; EOTT_MONTHLY
	MBRepeatInterval<0, 0, 1, MBRIT_WEEKLY>,	; EOTT_BIWEEKLY
	MBRepeatInterval<0, 0, 0, MBRIT_MON_TO_FRI>	; EOTT_WORKING_DAYS

CheckHack<length eottToMBRepeatTable eq (EventOptionsTypeType/2)>
;
; PASS:		bp	= year
;		dx	= month/date
;		cx	= hour/min
; Return:	dx	= FileDate
;		cx	= FileTime
; Destroyed:	ax
;
CreateFileDateTimeFromGetTime	proc	near
		uses	bx
		.enter
		mov	ax, bp				; ax <- year (*)
		mov	bx, dx
		xchg	bh, bl				; bx <- day/month (*)
		clr	dh				; dh <- second (*)
		mov	dl, cl				; dl <- minute (*)
		call	CreateFileDateTimeRecords	; dx <- FileDate,
							;  cx <- FileTime
		.leave
		ret
CreateFileDateTimeFromGetTime	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StuffNameAndSMSToText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stuff name and sms number into EventRecipientText. We
		are doing multiple selections, so we have to traverse
		the selection list.

CALLED BY:	(INTERNAL) StuffSMSEventSummary
PASS:		nothing
RETURN:		nothing
DESTROYED:	everything
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	2/13/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StuffNameAndSMSToText	proc	near
nameBuffer	local	MAX_NAME_DATA_LEN+1 dup (TCHAR)	; buffer for name
numberBuffer	local	MAX_NUMBER_FIELD_DATA_LEN+1 dup (TCHAR)	; number
nameLength	local	word				; length of name
elementCount	local	word				; count for multiple
							;  selection
		.enter
	;
	; First, clear the text EventRecipientText.
	;
		push	bp
		mov	ax, MSG_VIS_TEXT_DELETE_ALL
		mov	bx, handle EventRecipientText
		mov	si, offset EventRecipientText	; ^bx:si - text obj
		call	ObjMessage_mailbox_call		; ax, cx, dx, bp gone
		pop	bp
	;
	; The rest of the code fetches the recipient name/number one
	; by one from the address controller, and append the
	; name/number string into EventRecipientText.
	;
	; Start with the first element.
	;
		clr	ss:[elementCount]
oneElement:
	;
	; Ask the address controller to fetch nth element recipient
	; name and sms.
	;
		mov	ax, MSG_CALENDAR_ADDRESS_CTRL_FETCH_RECIPIENT_INFO
		mov	bx, handle BookingSMSAddressControl
		mov	si, offset BookingSMSAddressControl
		mov	cx, ss:[elementCount]
		inc	ss:[elementCount]		; increment count
		call	ObjMessage_mailbox_call		; carry set if out of
							;  bound, else
							;  name / sms
							;  number fetched
		jc	quit
	;
	; Now create the recipient string.
	;
		mov	si, EFST_RECIPIENT_INFO
		clr	cx
		mov	es, cx				; just copy to chunk
		call	CopyAndFormatWritableChunk	; tempWritableChunk
							;  filled
	;
	; Find the recipient name and number from address controller.
	;
		push	bp
		lea	cx, ss:[nameBuffer]
		push	cx
		mov	ax, MSG_CALENDAR_ADDRESS_CTRL_GET_SELECTED_SMS_NUM
		mov	bx, handle BookingSMSAddressControl
		mov	si, offset BookingSMSAddressControl
		mov	dx, ss
		lea	bp, ss:[numberBuffer]		; dx:bp <- number
		call	ObjMessage_mailbox_call		; cx <- str len not
							;  counting NULL
EC <		tst	cx						>
EC <		ERROR_Z	CALENDAR_INTERNAL_ERROR				>

		pop	bp				; dx:bp <- name
		mov	ax, MSG_CALENDAR_ADDRESS_CTRL_GET_SELECTED_NAME
		call	ObjMessage_mailbox_call		; cx <- str len not
							;  counting NULL
		pop	bp
	;
	; Get name string address. If the name is empty, use SMS number.
	;
		mov	ss:[nameLength], cx
		lea	dx, ss:[nameBuffer]
		tst	cx
		jnz	nameNotNull
		lea	dx, ss:[numberBuffer]
nameNotNull:
		mov	cx, ss				; cx:dx <- name 
	;
	; Lock down tempWritableChunk string and replace name.
	;
		mov	bx, handle WritableStrings
		call	ObjLockObjBlock			; ax <- segment
		mov_tr	ds, ax
		mov	si, offset tempWritableChunk	; *ds:si <- string
		mov	ax, BOOK_EVENT_RECIPIENT_NAME
		call	SubstituteStringArg
	;
	; Change the recipient number.
	; If name length was zero, we used SMS number for name, so
	; write a null this time.
	;
		tst	ss:[nameLength]
		jnz	nameNotNull2
		mov	{TCHAR} ss:[numberBuffer], C_NULL
nameNotNull2:
		lea	dx, ss:[numberBuffer]		; cx:dx <- sms num
		mov	ax, BOOK_EVENT_RECIPIENT_NUMBER
		call	SubstituteStringArg
	;
	; Unlock string.
	;
		call	MemUnlock
	;
	; We get our string now, so put it into EventRecipientText.
	;
		push	bp
		mov	bx, handle EventRecipientText
		mov	si, offset EventRecipientText	; ^bx:si - text obj
		mov	dx, handle tempWritableChunk
		mov	bp, offset tempWritableChunk
		clr	cx				; null terminated
		mov	ax, MSG_VIS_TEXT_APPEND_OPTR
		call	ObjMessage_mailbox_call
		pop	bp
	;
	; Fetch next recipient name / number.
	;
		jmp	oneElement
quit:
		.leave
		ret
StuffNameAndSMSToText	endp
	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoPlannerSendSMSConfirmed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	In the event summary window, user presses "Send". Time
		to send the message to mailbox.

CALLED BY:	MSG_CALENDAR_SEND_SMS_CONFIRMED
		MSG_CALENDAR_PASSWD_ENTERED_SEND_SMS
PASS:		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Usually the password of a recipient is fetched
		from contdb. However, if the user manually enters a
		number, and the number does not match any contact,
		then we bring up password dialog.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	12/22/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoPlannerSendSMSConfirmed	method dynamic GeoPlannerClass, 
					MSG_CALENDAR_SEND_SMS_CONFIRMED,
					MSG_CALENDAR_PASSWD_ENTERED_SEND_SMS
elementCount	local	word				; count for multiple
							;  selection
processHandle	local	hptr
flashNote	local	optr		
		.enter
	;
	; If password already filled in, send SMS now.
	;
		cmp	ax, MSG_CALENDAR_PASSWD_ENTERED_SEND_SMS
		je	normal
	;
	; Get the selection of BookingItemGroup and see if we are
	; sending event request or event reservation.
	;
		call	GetBookEventType		; ax <-BookingEventType
	;
	; If just sending normal event, then register mailbox message.
	;
		cmp	ax, BET_NORMAL_EVENT
		je	normal
	;
	; Check if we have matching contact for the recipient.
	;
		mov	bx, handle BookingSMSAddressControl
		mov	si, offset BookingSMSAddressControl
		mov	ax, MSG_CALENDAR_ADDRESS_CTRL_GET_MISC_FLAGS
		call	ObjMessage_mailbox_call		; cl <-
							; CalAddressCtrlFlags
		Assert	record, cl, CalAddressCtrlFlags
	;
	; If doing multiple recipients, don't show password
	; dialog. Rather, just use PasswordText (which is NULL) if the
	; recipient is not found in contdb.
	;
		test	cl, mask CACF_MULTIPLE_RECIPIENTS
		jnz	normal
	;
	; If doing single recipient, and the sms doesn't match in
	; contdb, show password dialog.
	;
		test	cl, mask CACF_HAS_MATCHING_CONTACT
		jz	requestPasswd
normal:
	;
	; If the DayEvent object time has changed since last time
	; Details dialog is open, we should do any SMS update first.
	;
		call	DoSMSUpdateIfNecessary
	;
	; Do a flashing note.
	;
		mov	ax, offset StartingToSendEventText
		call	PutUpFlashingNote		; ^lbx:si <- dialog
		movdw	ss:[flashNote], bxsi
	;
	; Find process handle.
	;
		call	GeodeGetProcessHandle		; bx <- process handle
		mov	ss:[processHandle], bx
	;
	; Start with the first element.
	;
		clr	ss:[elementCount]
oneElement:
	;
	; Ask the address controller to fetch nth element recipient
	; name and sms.
	;
		mov	ax, MSG_CALENDAR_ADDRESS_CTRL_FETCH_RECIPIENT_INFO
		mov	bx, handle BookingSMSAddressControl
		mov	si, offset BookingSMSAddressControl
		mov	cx, ss:[elementCount]
		inc	ss:[elementCount]		; increment count
		call	ObjMessage_mailbox_call		; carry set if out of
							;  bound, else
							;  name / sms
							;  number fetched
		jc	quit
	;
	; Send one SMS.
	;
		push	bp
		mov	ax, MSG_CALENDAR_REGISTER_MAILBOX_EVENT_TEXT
		mov	bx, ss:[processHandle]
		clr	si
		call	ObjMessage_mailbox_call		; ax, cx, dx, bp gone
		pop	bp
	;
	; Do next recipient name / number.
	;
		jmp	oneElement
quit:
	;
	; Bring down flashing note.
	;
		movdw	bxsi, ss:[flashNote]
		call	BringDownFlashingNote
	;
	; Close the contact window.
	;
		mov	bx, handle BookingSMSAddressControl
		mov	si, offset BookingSMSAddressControl
		mov	ax, MSG_SMAC_CANCEL
		call	ObjMessage_mailbox_send
	;
	; Close all booking dialogs.
	;
		mov	bx, handle BookingDialog
		mov	si, offset BookingDialog
		mov	ax, MSG_GEN_INTERACTION_ACTIVATE_COMMAND
		mov	cx, IC_DISMISS
		call	ObjMessage_mailbox_send		; nothing destroyed
		
		mov	bx, handle BookingSummaryDialog
		mov	si, offset BookingSummaryDialog
		call	ObjMessage_mailbox_send		; nothing destroyed
done:		
		.leave
		ret
requestPasswd:
	;
	; We must be doing event reservation. Show password dialog.
	;
		mov	bx, handle InputPasswordDialog
		mov	si, offset InputPasswordDialog
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		call	ObjMessage_mailbox_send		; ds destroyed
		jmp	done
GeoPlannerSendSMSConfirmed	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetBookEventType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the selection of BookingItemGroup, which
		defines whether we are doing event request or
		reservation.

CALLED BY:	(INTERNAL) GeoPlannerSendSMSConfirmed
PASS:		nothing
RETURN:		ax	= BookingEventType
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	1/ 8/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetBookEventType	proc	near
		uses	bx, cx, dx, si, bp
		.enter
	;
	; Get the selection of BookingItemGroup and see if we are
	; sending event request or event reservation.
	;
		mov	bx, handle BookingItemGroup
		mov	si, offset BookingItemGroup
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjMessage_mailbox_call		; ax <- current
							; selection, carry
							; set if none,
							; cx, dx, bp destroyed
		Assert	ne, ax, GIGS_NONE
		Assert	etype, ax, BookingEventType

		.leave
		ret
GetBookEventType	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoSMSUpdateIfNecessary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify the currently selected DayEventClass object to
		send out any SMS update, if necessary (ie. if time has
		changed since last time the Details dialog is up.)

CALLED BY:	(INTERNAL) GeoPlannerSendSMSConfirmed
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	3/ 6/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DoSMSUpdateIfNecessary	proc	near
		uses	ax, bx, cx, dx, si, bp
		.enter
	;
	; Get selected day event object.
	;
		call	GetSelectedDayEventObject	; ^lbx:si <- DayEvent,
							;  si <- 0 if none
							;  selected 
	;
	; If no event is selected, quit.
	;
		tst	si
EC <		WARNING_Z EVENT_HANDLE_DOESNT_EXIST_SO_OPERATION_IGNORED>
		jz	quit
	;
	; Send it a message to do SMS update, if necessary.
	;
		mov	ax, MSG_DE_UPDATE_APPOINTMENT_IF_NECESSARY
		call	ObjMessage_mailbox_call		; ax, cx, dx,
							;  bp destroyed 
quit:
		.leave
		ret
DoSMSUpdateIfNecessary	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoPlannerRegisterMailboxEventText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Recipient is already picked and password already
		input. Register the event text to mailbox now.

CALLED BY:	MSG_CALENDAR_REGISTER_MAILBOX_EVENT_TEXT
PASS:		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		The selected contact name and number is already
		stored in instance variables of	BookingSMSAddressControl.
		(selectedName / selectedSMSNum).

		Usually the password of a recipient is fetched
		from contdb. However, if the user manually enters a
		number, and the number does not match any contact,
		then we bring up password dialog.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	12/22/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
smsCategory	char	SMS_CATEGORY, 0
smsSCNumber	char	SMS_OPTIONS_SC_NUMBER, 0
if	_LOCAL_SMS
recvAppToken	GeodeToken <<'PLN2'>,MANUFACTURER_ID_GEOWORKS>
else
smsAppToken	GeodeToken <<'SMRC'>,MANUFACTURER_ID_TBD>
endif

GeoPlannerRegisterMailboxEventText	method dynamic GeoPlannerClass, 
				MSG_CALENDAR_REGISTER_MAILBOX_EVENT_TEXT
myAppRef	local	VMTreeAppRef
mrma		local	MailboxRegisterMessageArgs
mta		local	MailboxTransAddr
recipientNum	local	MAX_NUMBER_FIELD_DATA_LEN+1 dup (TCHAR)		
recipientName	local	MAX_NAME_DATA_LEN+1 dup (TCHAR)
		.enter
	;
	; Check we have a good SC number, or input one.
	;
		call	CheckServiceNumber		; carry set if error
		jc	quit
	;
	; Ask the selected event for the booking ID.
	;
		call	GetNextBookIdOfCurrentEvent	; cx <- ID, carry set
							;  if error
		jc	quit
	;
	; Add that ID to BookingSMSAddressControl, because WriteUID and
	; DayEventAddSentToInfo would ask for the number from the
	; controller.
	;
		mov	bx, handle BookingSMSAddressControl
		mov	si, offset BookingSMSAddressControl
		mov	ax, MSG_CALENDAR_ADDRESS_CTRL_SET_BOOK_ID
		call	ObjMessage_mailbox_call		; ax destroyed
	;
	; Fill in recipientNum / recipientName.
	;
		push	bp
		mov	dx, ss
		lea	bp, ss:[recipientName]		; dx:bp <- buffer
		mov	ax, MSG_CALENDAR_ADDRESS_CTRL_GET_SELECTED_NAME
		call	ObjMessage_mailbox_call		; cx <- strlen not
							;  counting NULL
		pop	bp
		push	bp
		lea	bp, ss:[recipientNum]		; dx:bp <- buffer
		mov	ax, MSG_CALENDAR_ADDRESS_CTRL_GET_SELECTED_SMS_NUM
		call	ObjMessage_mailbox_call		; cx <- strlen not
							;  counting NULL
		mov_tr	ax, bp
		pop	bp
	;
	; Strip non-numeric chars from recipientNum.
	;
		mov	ds, dx
		mov	si, ax				; ds:si <- source
		mov	es, dx
		mov	di, ax				; es:di <- destination
		; cx == # of chars
		call	CalStripNonNumeric		; cx <- # chars in
							;  dest string
	;
	; If the number is too long, change the length.
	;
		cmp	cx, TRANS_ADDR_STRING_MAX_LENGTH-1	; 22
		jbe	smsLengthGood
EC <		WARNING CALENDAR_SMS_NUMBER_TRUNCATED			>
		mov	cx, TRANS_ADDR_STRING_MAX_LENGTH-1
smsLengthGood:
	;
	; Address to receive this SMS, and user readable trans addr.
	; If user readable trans addr is NULL, use the SMS number.
	;
		movdw	ss:[mta].MTA_transAddr, dxax
		LocalCmpChar	ss:[recipientName], C_NULL
		je	noName
		lea	ax, ss:[recipientName]
noName:
		movdw	ss:[mta].MTA_userTransAddr, dxax
		mov	ss:[mta].MTA_transAddrLen, cx
	;
	; Now create the message in mailbox vm file.
	; Get mailbox VM file.
	;
		mov	bx, 1				; 1 VM block
		call	MailboxGetVMFile		; carry set on error,
							; else
							;  bx <- VMFileHandle,
							;  ax destroyed
		LONG jc	error
		Assert	vmFileHandle, bx
	;
	; Allocate a block of size INITIAL_VERSIT_TEXT_BLOCK_SIZE.
	;
		GetResourceSegmentNS	dgroup, ds
		mov	cx, INITIAL_VERSIT_TEXT_BLOCK_SIZE
		clr	ax				; user id?
		call	VMAlloc				; ax <- VM block handle
							; marked dirty
	;
	; Remember the chain info before we lose it.
	;
		mov	ss:[myAppRef].VMTAR_vmChain.segment, ax
		clr	ss:[myAppRef].VMTAR_vmChain.offset
		mov	ss:[myAppRef].VMTAR_vmFile, bx
	;
	; Lock down the block to write.
	;
		push	bp
		call	VMLock				; ax <- segment,
							; bp <- memory handle
		mov_tr	es, ax				; es <- segment to
							;  write
		call	CreateVersitTextIntoBlock	; cx <- size of
							;  text written
		call	VMDirty
		call	VMUnlock			; es destroyed
		pop	bp
	;
	; Register a VM chain with the mailbox system.
	;
		CheckHack<MANUFACTURER_ID_GEOWORKS eq 0>
		clr	ss:[mrma].MRA_bodyStorage.MS_manuf
		mov	ss:[mrma].MRA_bodyStorage.MS_id, GMSID_VM_TREE
		clr	ss:[mrma].MRA_bodyFormat.MDF_manuf
		mov	ss:[mrma].MRA_bodyFormat.MDF_id, GMDFID_SHORT_MESSAGE
		mov	ss:[mrma].MRA_bodyRef.segment, ss
		lea	ax, ss:[myAppRef]
		mov	ss:[mrma].MRA_bodyRef.offset, ax
		mov	ss:[mrma].MRA_bodyRefLen, cx
	;
	; Allocate a DB item in the mailbox admin file to store
	; SMSendingOptions. This is passed to transport driver as trans
	; data. These options can also read from .ini file under category
	; [SMS].
	;
		push	bx
		call	MailboxGetAdminFile		; bx <- file handle
		Assert	vmFileHandle, bx
		mov	ax, DB_UNGROUPED
		mov	cx, size SMSendingOptions
		call	DBAlloc				; ax <- group,
							; di <- item
		movdw	ss:[mrma].MRA_transData, axdi
		call	DBLock				; *es:di <- item ptr
		mov	di, es:[di]
		mov	es:[di].SMSO_replyPath, SMRP_NO
		mov	es:[di].SMSO_validityPeriod, SMVP_24_HOURS
		CheckHack<SMMC_NORMAL eq 0>
		clr	es:[di].SMSO_messageConversion	; no conversion
		clr	es:[di].SMSO_dataCodingScheme
		clr	es:[di].SMSO_userDataLength
		clr	es:[di].SMSO_userDataHeader
	;
	; Read in center number from init file.
	;
		push	bp
		lea	di, es:[di].SMSO_scAddress	; es:di <- buffer
		segmov	ds, cs, cx
		mov	si, offset smsCategory		; ds:si <- category
		mov	dx, offset smsSCNumber		; cx:dx <- key
		mov	bp, InitFileReadFlags<IFCC_INTACT, 0, 0, \
					      size SMSO_scAddress>
		call	InitFileReadString		; cx <- # chars not
							;  including null
EC <		tst	cx						>
EC <		ERROR_Z CALENDAR_INTERNAL_ERROR				>
	;
	; Strip non numeric chars.
	;
		; es:di <- buffer
		segmov	ds, es, si
		mov	si, di				; ds:si <- buffer
		call	CalStripNonNumeric		; cx <- # chars
		pop	bp
	;
	; Mark the item dirty.
	;
		call	DBDirty
		call	DBUnlock			; es destroyed
	;
	; Transport info.
	;
if	_LOCAL_SMS
		mov	ss:[mrma].MRA_transport.MT_id, GMTID_LOCAL
else
		mov	ss:[mrma].MRA_transport.MT_id, GMTID_SM
endif
		clr	ss:[mrma].MRA_transport.MT_manuf
		clr	ss:[mrma].MRA_transOption
	;
	; Transport addr. mta is already filled.
	;
		mov	ss:[mrma].MRA_transAddrs.segment, ss
		lea	ax, ss:[mta]
		mov	ss:[mrma].MRA_transAddrs.offset, ax
		mov	ss:[mrma].MRA_numTransAddrs, 1
	;
	; Subject is the string MailboxSubjectText.
	;
		mov	bx, handle MailboxSubjectText
		call	MemLock
		mov_tr	ds, ax
		mov	ss:[mrma].MRA_summary.segment, ds
assume	ds:DataBlock
		mov	ax, ds:[MailboxSubjectText]
		mov	ss:[mrma].MRA_summary.offset, ax
assume	ds:nothing
	;
	; Flags and time.
	;
		mov	ss:[mrma].MRA_flags, CALENDAR_SEND_APPT_MAILBOX_FLAGS

		CheckHack<(MAILBOX_NOW eq 0)>
		clrdw	ss:[mrma].MRA_startBound	; MAILBOX_NOW
		movdw	ss:[mrma].MRA_endBound, MAILBOX_ETERNITY
	;
	; SMS receive app is the geode to receive the SMS text.
	;
if	_LOCAL_SMS
		movtok	ss:[mrma].MRA_destApp, cs:[recvAppToken], ax
else
		movtok	ss:[mrma].MRA_destApp, cs:[smsAppToken], ax
endif
	;
	; do the register!
	;
		mov	cx, ss
		lea	dx, mrma
doTheRegister::
		call	MailboxRegisterMessage		; carry set on error
							; dxax <-MailboxMessage
		
	;
	; Unlock string resource.
	;
		call	MemUnlock			; ds destroyed
	;
	; Done with vm file
	;
		pop	bx				; file handle
		call	MailboxDoneWithVMFile
	;
	; Add sent-to info.
	;
		call	AddSentToInfo			; everything destroyed
							;  destroyed except bp
error:
quit:		
		.leave
		ret
GeoPlannerRegisterMailboxEventText	endm

;
;<volatile, send wo query, priority, verb, delete after trans>
;
CALENDAR_SEND_APPT_MAILBOX_FLAGS equ \
	MailboxMessageFlags <0, 0, MMP_EMERGENCY, MDV_READ, 1>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckServiceNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if service number is already found in INI
		file. If not, show a dialog to input the service
		number.

CALLED BY:	(INTERNAL) GeoPlannerRegisterMailboxEventText,
			   ReplyAcceptOrDeny
PASS:		nothing
RETURN:		carry clear if number found, or input from user	properly.
		carry set if number not found, and user does not input
			number.	
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Read [SMS]scNumber into buffer
		(we don't care about the number, so just allocate 2
		bytes for it.)
		if found {
			return ok
		}
		UserDoDialog(InputServiceCenterDialog)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	1/ 2/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckServiceNumber	proc	near
smallBuffer	local	2 dup (TCHAR)
		uses	ax, bx, cx, dx, ds, si, es, di
		.enter
	;
	; Check init file.
	;
		push	bp
		segmov	es, ss, di
		lea	di, ss:[smallBuffer]		; es:di <- buffer
		segmov	ds, cs, cx
		mov	si, offset smsCategory		; ds:si <- category
		mov	dx, offset smsSCNumber		; cx:dx <- key
		mov	bp, InitFileReadFlags<IFCC_INTACT, 0, 0, \
					      size smallBuffer>
		call	InitFileReadString		; cx <- # chars not
							;  including null,
							;  cx <-0 if not found.
							;  bx destroyed
		pop	bp
		jcxz	notFound
success:
		clc					; success!
quit:
		.leave
		ret
notFound:
	;
	; Show dialog to input number.
	;
		mov	bx, handle InputServiceCenterDialog
		mov	si, offset InputServiceCenterDialog
		call	UserDoDialog			; ax <- IC_YES
							;  / NO / NULL /..
							;  ds destroyed
	;
	; Does user input number?
	;
		cmp	ax, IC_YES
		stc					; assume error
		jne	quit				; ie. jnz
	;
	; Ask ServiceCenterText to save its option to init file.
	;
		push	bp
		mov	bx, handle ServiceCenterText
		mov	si, offset ServiceCenterText
		mov	ax, MSG_META_SAVE_OPTIONS
		call	ObjMessage_mailbox_call		; ax, cx, dx, bp gone
		pop	bp

		jmp	success
CheckServiceNumber	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalStripNonNumeric
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Strips non-numeric characters from this string

CALLED BY:	(INTERNAL) GeoPlannerRegisterMailboxEventText
PASS:		ds:si - string to strip non-numeric chars from
		es:di - dest for string
		cx - # chars in source string
RETURN:		cx - # chars in dest string, not counting null.
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:
		This routine does these:
		(1) if the first character is +, copy it.
		(2) filter out all characters except 0-9, *, #, p, P,
			w, W.
		That's all.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 3/95   	Initial version
	kho	3/27/96		Strip string before #, and preserve *
	kho	12/26/96	Stolen from contdb (StripNonNumeric)
				and null terminate destination string.
	kho	1/14/97		Preserve the first + sign.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalStripNonNumeric	proc	near	uses	ax, bx, si
	.enter

;	Scan through the source string in DS:SI, and copy the number
;	characters to the dest string in ES:DI.

	mov	bx, di
	jcxz	exit

;	First, check if the first character is a '+'.

	LocalGetChar	ax, dssi
	LocalCmpChar	ax, C_PLUS
	je	addChar
	jmp	firstNotPlus
		
loopTop:

;	DS:SI <- ptr to next char in string
;	ES:DI <- ptr to where to store next char in stripped string

	LocalGetChar	ax, dssi

firstNotPlus:

;	Deal with characters differently.

if	not DBCS_PCGEOS
	cmp	al, C_ZERO
	jb	notNumber
	cmp	al, C_NINE
	ja	notNumber
else
PrintError <Need to change this code for DBCS>
endif

addChar:
	LocalPutChar	esdi, ax
	
doLoop:	
	loop	loopTop
exit:
	mov	{TCHAR} es:[di], C_NULL		; null terminated
	mov	cx, di
	mov	di, bx		;restore di
	sub	cx, di		;CX <- # chars in dest string
DBCS <	shr	cx							>
EC <	cmp	cx, MAX_NUMBER_FIELD_DATA_LEN				>
EC <	ERROR_A	CALENDAR_INTERNAL_ERROR					>

quit::
	.leave
	ret
notNumber:
	
;	Keep any p/P/w/W.

	LocalCmpChar	ax, C_CAP_W
	jz	addChar
	LocalCmpChar	ax, C_CAP_P
	jz	addChar
	
	LocalCmpChar	ax, C_SMALL_W
	jz	addChar
	LocalCmpChar	ax, C_SMALL_P
	jz	addChar

;	Keep any '*'.
	
	LocalCmpChar	ax, C_ASTERISK
	jz	addChar

;	Keep any '#'.

	LocalCmpChar	ax, C_NUMBER_SIGN
	jz	addChar
	jmp	doLoop

CalStripNonNumeric	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddSentToInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add the sent-to information (with the name / sms
		number / contact ID in instance data of
		CalendarAddressCtrlClass object) to the currently
		selected event.

CALLED BY:	(INTERNAL) GeoPlannerRegisterMailboxEventText
PASS:		nothing
RETURN:		nothing
DESTROYED:	everything except bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Get the selected event, and send it a message.


REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	1/29/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddSentToInfo	proc	near
		uses	bp
		.enter
	;
	; Get currently selected event.
	;
		call	GetSelectedDayEventObject	; ^lbx:si <- DayEvent,
							;  si <- 0 if none
							;  selected 
	;
	; If no event is selected, quit.
	;
		tst	si
EC <		WARNING_Z EVENT_HANDLE_DOESNT_EXIST_SO_OPERATION_IGNORED>
		jz	quit
	;
	; Send it a message.
	;
		mov	ax, MSG_DE_ADD_SENT_TO_INFO
		call	ObjMessage_mailbox_call		; ax, cx, dx, bp gone
quit:
		.leave
		ret
AddSentToInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetNextBookIdOfCurrentEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the currently selected event's next book ID.

CALLED BY:	(INTERNAL) GeoPlannerRegisterMailboxEventText
PASS:		nothing
RETURN:		carry set if error,
			cx	= destroyed
		else
			cx	= next book ID
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	2/ 3/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetNextBookIdOfCurrentEvent	proc	near
		uses	ax, bx, si, bp
		.enter
	;
	; Find selected event.
	;
		call	GetSelectedDayEventObject	; ^lbx:si <- DayEvent,
							;  si <- 0 if none
							;  selected 
	;
	; If no event is selected, quit.
	;
		tst	si
EC <		WARNING_Z EVENT_HANDLE_DOESNT_EXIST_SO_OPERATION_IGNORED>
		stc					; assume error
		jz	quit
	;
	; Get next book event ID, and consider that ID used.
	;
		mov	ax, MSG_DE_USE_NEXT_BOOK_ID
		call	ObjMessage_mailbox_call		; cx <- booking ID to
							;  use, ax destroyed
		clc					; no error
quit:
		.leave
		ret
GetNextBookIdOfCurrentEvent	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalendarPasswordTextClipboardCut
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Disable cut/copy in password text.

CALLED BY:	MSG_META_CLIPBOARD_CUT / COPY
PASS:		*ds:si	= CalendarPasswordTextClass object
		ds:di	= CalendarPasswordTextClass instance data
		ds:bx	= CalendarPasswordTextClass object (same as *ds:si)
		es 	= segment of CalendarPasswordTextClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	12/ 1/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalendarPasswordTextClipboardCut	method dynamic \
					CalendarPasswordTextClass, 
					MSG_META_CLIPBOARD_CUT,
					MSG_META_CLIPBOARD_COPY
		.enter
	;
	; Just beep.
	;
		mov	ax, SST_NO_INPUT
		call	UserStandardSound
		
		.leave
		ret
CalendarPasswordTextClipboardCut	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScrollableContentMetaFupKbdChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Pass the META_FUP_KBD_CHAR to vis parent (GenView) so
		that the GenContent scrolls.

CALLED BY:	MSG_META_FUP_KBD_CHAR
PASS:		*ds:si	= ScrollableGenContentClass object
		ds:di	= ScrollableGenContentClass instance data
		ds:bx	= ScrollableGenContentClass object (same as *ds:si)
		es 	= segment of ScrollableGenContentClass
		ax	= message #
		cx	= character value
		dl	= CharFlags
		dh	= ShiftState
		bp low	= ToggleState
		bp high	= scan code
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	1/28/97   	Copy AboutGenContentMetaFupKbdChar

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScrollableContentMetaFupKbdChar	method dynamic ScrollableGenContentClass, 
					MSG_META_FUP_KBD_CHAR
		.enter
	;
	; must be 1st press or repeated press
	;
		test	dl, mask CF_FIRST_PRESS or mask CF_REPEAT_PRESS
		jz	normal	
	;
	; must not have any ShiftState
	;
		tst	dh
		je	maybeDown
	;
	; send the keystroke to parent
	;
normal:
		call	VisCallParent
		jmp	done

	;
	; down arrow scrolls down a line
	;
maybeDown:
SBCS <		cmp	cx, VC_DOWN or (CS_CONTROL shl 8)		>
DBCS <		cmp	cx, C_SYS_DOWN					>
		jne	notDown

		mov	ax, MSG_GEN_VIEW_SCROLL_DOWN
		jmp	callScroll

	;
	; up arrow scrolls up a line
	;
notDown:
SBCS <		cmp	cx, VC_UP or (CS_CONTROL shl 8)			>
DBCS <		cmp	cx, C_SYS_UP					>
		jne	normal

		mov	ax, MSG_GEN_VIEW_SCROLL_UP
callScroll:
		call	VisCallParent
		stc
done:
		.leave
		ret
ScrollableContentMetaFupKbdChar	endm

MailboxCode	ends

endif	; HANDLE_MAILBOX_MSG
