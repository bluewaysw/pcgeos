COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Calendar/Main
FILE:		mainManager.asm

AUTHOR:		Don Reeves, March 2, 1991

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/2/91		Initial revision

DESCRIPTION:
	Manager file for Main module
		
	$Id: mainManager.asm,v 1.1 97/04/04 14:47:57 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

_Main		= 1				; module being defined

; Included definitions
;
include		calendarGeode.def		; geode declarations
include		calendarConstant.def		; structure definitions
include		calendarGlobal.def		; global definitions
include		calendarMacro.def		; macro definitions
include		input.def
include		timedate.def
include		system.def			; localization entry point
include		rolodex.def			; include rolodex definitions
include		vm.def				; definitions for kernel VM
include		initfile.def
include		mainMailbox.def			; definitions for mailbox
						; related stuff
include		Internal/gstate.def

UseLib		dbase.def			; definitions for database
UseLib		config.def			; for PrefTimeDateControlClass

if	HANDLE_MAILBOX_MSG
include		mailbox.def
include		Mailbox/appt.def
include		Mailbox/vmtree.def
include		Internal/Resp/smdefine.def
include		contlog.def
endif

;Included source files
;
include		mainApp.asm			; application object stuff
include		mainCalc.asm			; date calculation code
include		mainCalendar.asm		; process management code
include		mainDatabase.asm		; event database code
include		mainFile.asm			; file management code
include		mainGeometry.asm		; geometry management code
include		mainUndo.asm			; undo code
include		mainUtils.asm			; utility functions
include		mainMailbox.asm			; mailbox event code
include		mainVersitStrings.asm		; versit strings for booking
include		mainBookEvent.asm		; book event
include		mainRecvEvent.asm		; receive event
include		mainEventsContent.asm		; events (list) dialog
include		mainConfirmDlg.asm		; confirm dialog code
include		mainAddressCtrl.asm		; sms address control
include		mainMenu.asm			; calendar main menu
include		mainApi.asm			; Calendar API code
include		mainUpdateEvent.asm		; cancel / update event

end
