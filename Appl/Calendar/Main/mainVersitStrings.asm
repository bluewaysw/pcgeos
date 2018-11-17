COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	(c) Copyright Geoworks 1996 -- All Rights Reserved
	GEOWORKS CONFIDENTIAL

PROJECT:	PC GEOS
MODULE:		GeoPlanner
FILE:		mainVersitStrings.asm

AUTHOR:		Jason Ho, Nov 13, 1996

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho		11/14/96   	Initial revision


DESCRIPTION:
	Versit strings.
		

	$Id: mainVersitStrings.asm,v 1.1 97/04/04 14:48:25 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	HANDLE_MAILBOX_MSG

MailboxCode	segment resource

;
; Each VersitKeywordType corresponds to one entry in KeywordStringTable and
; KeywordSizeTable.
;
keywordStringTable nptr \
	offset	beginProp,		; VKT_BEGIN_PROP
	offset	categoriesProp,		; VKT_CATEGORIES_PROP
	offset	classProp,		; VKT_CLASS_PROP
	offset	dalarmProp,		; VKT_DALARM_PROP
	offset	descriptionProp,	; VKT_DESCRIPTION_PROP
	offset	dtendProp,		; VKT_DTEND_PROP
	offset	dtstartProp,		; VKT_DTSTART_PROP
	offset	endProp,		; VKT_END_PROP
	offset	rruleProp,		; VKT_RRULE_PROP
	offset	statusProp,		; VKT_STATUS_PROP
	offset	summaryProp,		; VKT_SUMMARY_PROP
	offset	uidProp,		; VKT_UID_PROP
	offset	versionProp,		; VKT_VERSION_PROP
	offset	xNokiaCreatedEventProp,	; VKT_NOKIA_CREATED_EVENT_PROP
	offset	xNokiaPasswdProp,	; VKT_NOKIA_PASSWD_PROP
	offset	xNokiaReservedDaysProp,	; VKT_X_NOKIA_RESERVED_DAYS_PROP

	offset	onePtZeroVal,		; VKT_1_0_VAL
	offset	acceptedVal,		; VKT_ACCEPTED_VAL
	offset	appointmentVal,		; VKT_APPOINTMENT_VAL
	offset	changedVal,		; VKT_CHANGED_VAL
	offset	confirmedVal,		; VKT_CONFIRMED_VAL
	offset	declinedVal,		; VKT_DECLINED_VAL
	offset	deletedVal,		; VKT_DELETED_VAL
	offset	needsActionVal,		; VKT_NEEDS_ACTION_VAL
	offset	textChangedVal,		; VKT_TEXT_CHANGED_VAL
	offset	vcalendarVal,		; VKT_VCALENDAR_VAL
	offset	eventVal,		; VKT_VEVENT_VAL
	offset	todoVal,		; VKT_VTODO_VAL

	offset	dailyRule,		; VKT_DAILY_RULE
	offset	monthlyRule,		; VKT_MONTHLY_RULE
	offset	weeklyRule,		; VKT_WEEKLY_RULE
	offset  workingDaysRule,	; VKT_WORKING_DAYS_RULE
	offset  biweeklyRule,		; VKT_BIWEEKLY_RULE
	offset	yearlyRule,		; VKT_YEARLY_RULE

	offset	beginVCalendar,		; VKT_BEGIN_VCALENDAR
	offset	endVCalendar,		; VKT_END_VCALENDAR
	offset	version10,		; VKT_VERSION_1_0
	offset	beginEvent,		; VKT_BEGIN_EVENT
	offset	endEvent,		; VKT_END_EVENT
	offset	beginTodo,		; VKT_BEGIN_TODO
	offset	endTodo,		; VKT_END_TODO
	offset	crlf,			; VKT_CRLF
	offset	categoriesAppointment,	; VKT_CATEGORIES_APPOINTMENT

	offset	smsPrefix,		; VKT_SMS_PREFIX
	offset	smsReplyPrefix,		; VKT_SMS_REPLY_PREFIX
	offset	smsPrefixNoPorts,	; VKT_SMS_PREFIX_NO_PORTS
	offset	dalarmSuffix,		; VKT_DALARM_SUFFIX
	offset	repeatForever,		; VKT_REPEAT_FOREVER
	offset	lizzyUIDPrefix,		; VKT_LIZZY_UID_PREFIX
	offset	dash			; VKT_DASH

keywordSizeTable word\
	size	beginProp + size TCHAR,	; for ':' at the end
	size	categoriesProp + size TCHAR,
	size	classProp + size TCHAR,
	size	dalarmProp + size TCHAR,
	size	descriptionProp + size TCHAR,
	size	dtendProp + size TCHAR,
	size	dtstartProp + size TCHAR,
	size	endProp + size TCHAR,
	size	rruleProp + size TCHAR,
	size	statusProp + size TCHAR,
	size	summaryProp + size TCHAR,
	size	uidProp + size TCHAR,
	size	versionProp + size TCHAR,
	size	xNokiaCreatedEventProp + size TCHAR,
	size	xNokiaPasswdProp + size TCHAR,
	size	xNokiaReservedDaysProp + size TCHAR,

	size	onePtZeroVal,
	size	acceptedVal,
	size	appointmentVal,
	size	changedVal,
	size	confirmedVal,
	size	declinedVal,
	size	deletedVal,
	size	needsActionVal,
	size	textChangedVal,
	size	vcalendarVal,
	size	eventVal,
	size	todoVal,

	size	dailyRule,
	size	monthlyRule,
	size	weeklyRule,
	size	workingDaysRule,
	size	biweeklyRule,
	size	yearlyRule,

	size	beginVCalendar,
	size	endVCalendar,
	size	version10,
	size	beginEvent,
	size	endEvent,
	size	beginTodo,
	size	endTodo,
	size	crlf,
	size	categoriesAppointment,
	
	size	smsPrefix,
	size	smsReplyPrefix,
	size	smsPrefixNoPorts,
	size	dalarmSuffix,
	size	repeatForever,
	size	lizzyUIDPrefix,
	size	dash

CheckHack<length keywordStringTable eq length keywordSizeTable>
CheckHack<length keywordStringTable*2 eq VersitKeywordType>

;
; Strings that will appear in vCalendar text. They are not to be localized,
; so they appear in code segment.
;

;
; These are properties. Make sure VERSIT_PROP_KEYWORD_MAX_LENGTH is
; updated if you add properties.
; When they are written by WriteVersitString, a colon will be added at
; the end.
; Also, the properties are sorted according to string.
;
beginProp		TCHAR	"BEGIN", 0
categoriesProp		TCHAR	"CATEGORIES", 0
classProp		TCHAR	"CLASS", 0
dalarmProp		TCHAR	"DALARM", 0
descriptionProp		TCHAR	"DESCRIPTION", 0
dtendProp		TCHAR	"DTEND", 0
dtstartProp		TCHAR	"DTSTART", 0
endProp			TCHAR	"END", 0
rruleProp		TCHAR	"RRULE", 0
statusProp		TCHAR	"STATUS", 0
summaryProp		TCHAR	"SUMMARY", 0
uidProp			TCHAR	"UID", 0
versionProp		TCHAR	"VERSION", 0
xNokiaCreatedEventProp	TCHAR	"X-NOKIA-CREATED-EVENT", 0
xNokiaPasswdProp	TCHAR	"X-NOKIA-PASSWD", 0
xNokiaReservedDaysProp	TCHAR	"X-NOKIA-RESERVED-DAYS", 0

	VERSIT_PROP_KEYWORD_MAX_LENGTH	equ	\
		(length xNokiaCreatedEventProp+size TCHAR)	; for colon
;
; These are values. Make sure VERSIT_VALUE_KEYWORD_MAX_LENGTH is
; updated if you add values.
; Also, the values are sorted according to string.
;
onePtZeroVal		TCHAR	"1.0", 0
acceptedVal		TCHAR	"ACCEPTED", 0
appointmentVal		TCHAR	"APPOINTMENT", 0
changedVal		TCHAR	"CHANGED", 0
confirmedVal		TCHAR	"CONFIRMED", 0
declinedVal		TCHAR	"DECLINED", 0
deletedVal		TCHAR	"DELETED", 0
needsActionVal		TCHAR	"NEEDS ACTION", 0
textChangedVal		TCHAR	"TEXT CHANGED", 0
vcalendarVal		TCHAR	"VCALENDAR", 0
eventVal		TCHAR	"VEVENT", 0
todoVal			TCHAR	"VTODO", 0

	VERSIT_VALUE_KEYWORD_MAX_LENGTH	equ	(length needsActionVal)

dailyRule		TCHAR	"D1 ", 0
monthlyRule		TCHAR	"M1 ", 0
weeklyRule		TCHAR	"W1 ", 0
workingDaysRule		TCHAR	"W1 MO TU WE TH FR ", 0
biweeklyRule		TCHAR	"W2 ", 0
yearlyRule		TCHAR	"Y1 ", 0

	VERSIT_REPEAT_RULE_MAX_LENGTH equ	(length workingDaysRule)
	VERSIT_REPEAT_RULE_MIN_LENGTH equ	(length dailyRule)

beginVCalendar		TCHAR	"BEGIN:VCALENDAR", 0
endVCalendar		TCHAR	"END:VCALENDAR", 0
version10		TCHAR	"VERSION:1.0", 0
beginEvent		TCHAR	"BEGIN:VEVENT", 0
endEvent		TCHAR	"END:VEVENT", 0
beginTodo		TCHAR	"BEGIN:VTODO", 0
endTodo			TCHAR	"END:VTODO", 0
crlf			TCHAR	C_CR, C_LF, 0	; ie. C_ENTER + C_LINEFEED
categoriesAppointment	TCHAR	"CATEGORIES:APPOINTMENT", 0

if	_LOCAL_SMS
smsPrefix		TCHAR	LONG_SMS_PREFIX_WITH_NO_PORTS, "E477 ", 0
smsReplyPrefix		TCHAR	LONG_SMS_PREFIX_WITH_NO_PORTS, "77E4 ", 0
else
smsPrefix		TCHAR	LONG_SMS_PREFIX_WITH_NO_PORTS, "E4E4 ", 0
smsReplyPrefix		TCHAR	LONG_SMS_PREFIX_WITH_NO_PORTS, "E4E4 ", 0
endif
smsPrefixNoPorts	TCHAR	LONG_SMS_PREFIX_WITH_NO_PORTS, 0
dalarmSuffix		TCHAR	";;0;", 0
repeatForever		TCHAR	"#0", 0
lizzyUIDPrefix		TCHAR	"9000i-", 0
dash			TCHAR	"-", 0

colonString		TCHAR	":", 0		; used in WriteVersitString

MailboxCode	ends

endif	; HANDLE_MAILBOX_MSG
