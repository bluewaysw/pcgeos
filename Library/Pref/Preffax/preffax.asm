COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	Pasta
MODULE:		ZoomPrnt
FILE:		zoomprnt.asm

AUTHOR:		Don Reeves, Nov 30, 1992

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	11/30/92	Initial revision

DESCRIPTION:
	Implements the Zoomer Print Preferences module

	$Id: preffax.asm,v 1.1 97/04/05 01:38:40 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;------------------------------------------------------------------------------
;	Common GEODE stuff
;------------------------------------------------------------------------------

include	geos.def
include	heap.def
include geode.def
include	resource.def
include	ec.def
include	library.def

include object.def
include	graphics.def
include gstring.def
include	win.def

include char.def
include initfile.def

;-----------------------------------------------------------------------------
;	Libraries used		
;-----------------------------------------------------------------------------
 
UseLib	ui.def
UseLib	config.def
UseLib	spool.def
UseLib	Internal/spoolInt.def
UseLib	Objects/vTextC.def


;-----------------------------------------------------------------------------
;	Drivers used		
;-----------------------------------------------------------------------------
UseDriver Internal/serialDr.def
UseDriver Internal/printDr.def

;-----------------------------------------------------------------------------
;	DEF FILES		
;-----------------------------------------------------------------------------
 
include preffax.def
include preffaxGlobal.def
include preffax.rdef

;-----------------------------------------------------------------------------
;	VARIABLES		
;-----------------------------------------------------------------------------

idata	segment
	PrefFaxDialogClass
	PrefInteractionSpecialClass
	PrefItemGroupSpecialClass
	PreffaxOKTriggerClass
idata	ends

if 0
udata	segment
serialDeviceMap		SerialDeviceMap
udata	ends
endif

;-----------------------------------------------------------------------------
;		other code
;-----------------------------------------------------------------------------

include preffaxInstallGroup3.asm

PrefFaxCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefFaxGetPrefUITree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the root of the preference UI tree

CALLED BY:	PrefMgr

PASS:		Nothing

RETURN:		DX:AX	= OD of root of tree

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	11/30/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefFaxGetPrefUITree	proc	far
		mov	dx, handle PrefFaxRoot
		mov	ax, offset PrefFaxRoot
		ret
PrefFaxGetPrefUITree	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefFaxGetModuleInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns PrefModuleInfo to determine visibility of module

CALLED BY:	PrefMgr

PASS:		DS:SI	= PrefModuleInfo buffer

RETURN:		DS:SI	= PrefModuleInfo filled

DESTROYED:	AX, BX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	11/30/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefFaxGetModuleInfo	proc	far
		clr	ax
		mov	ds:[si].PMI_requiredFeatures, mask PMF_USER
		mov	ds:[si].PMI_prohibitedFeatures, ax
		mov	ds:[si].PMI_minLevel, ax
		mov	ds:[si].PMI_maxLevel, UIInterfaceLevel-1
		mov	ds:[si].PMI_monikerList.handle, handle  PrefFaxMonikerList
		mov	ds:[si].PMI_monikerList.offset, offset PrefFaxMonikerList
		mov	{word} ds:[si].PMI_monikerToken, 'Z' or ('M' shl 8) 
		mov	{word} ds:[si].PMI_monikerToken+2, 'P' or ('R' shl 8)
		mov	{word} ds:[si].PMI_monikerToken+4, MANUFACTURER_ID_APP_LOCAL 
		ret
PrefFaxGetModuleInfo	endp



;-----------------------------------------------------------------------------
;	Methods	for PrefFaxDialogClass
;-----------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefFaxDialogSaveOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Install the Group3 printer driver and save the options
		set by the user.

CALLED BY:	MSG_META_SAVE_OPTIONS

PASS:		*ds:si	= PrefFaxDialogClass object
		ds:di	= PrefFaxDialogClass instance data
		es 	= segment of PrefFaxDialogClass
		ax	= message #

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

	1) Install the Group3 printer driver
	2) Call super class to handle the rest

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	12/20/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefFaxDialogSaveOptions	method dynamic PrefFaxDialogClass, 
					MSG_META_SAVE_OPTIONS
		uses	ax, cx, dx, bp, si, ds
		.enter
	;
	;  Install the Group3 printer driver
	;
		call	PrefFaxInstallGroup3
	;
	;  Let the superclass handle the rest of it
	;
		.leave				; restore registers
		mov	di, offset PrefFaxDialogClass
		GOTO	ObjCallSuperNoLock


PrefFaxDialogSaveOptions	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefFaxDialogStartFaxSoftware
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start the fax software.

CALLED BY:	MSG_PREF_FAX_DIALOG_START_FAX_SOFTWARE

PASS:		*ds:si	= PrefFaxDialogClass object
		ds:di	= PrefFaxDialogClass instance data
		es 	= segment of PrefFaxDialogClass

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		If a device is not selected {
			inform the user a device must be selected
		}
		else {
			close the dialog
			start the spooler
			inform success or failure
			send ourself apply msg
			close dialog
		}

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	3/14/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefFaxDialogStartFaxSoftware	method dynamic PrefFaxDialogClass, 
					MSG_PREF_FAX_DIALOG_START_FAX_SOFTWARE
		uses	ax, cx, dx, bp
		.enter
	;
	; Make sure a device has been selected.
	;	
		call	PrefFaxCheckDeviceSelected
		jnc	spooler
	;
	; Inform the user that a device must be selected.
	;
		mov	si, offset NoDriverString
		call	DisplayError
		jmp	exit
spooler:
	;
	; Launch the fax spooler.
	;
		mov	si, offset FaxReadyString	; hope for the best...
		call	PrefFaxLaunchSpooler
		jnc	notifyUser
		
		mov	si, offset CannotStartString	; but expect the worst :(
notifyUser:
		call	DisplayNotification
	;
	; Send ourself an apply message like a regular apply trigger would do.
	;
		mov	si, offset PrefFaxRoot
		mov	ax, MSG_GEN_APPLY
		call	ObjCallInstanceNoLock
	;
	; Bring down the dialog.
	;
		mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
		mov	cx, IC_DISMISS
		call	ObjCallInstanceNoLock
exit:		
		.leave
		ret
	
PrefFaxDialogStartFaxSoftware	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefFaxDialogClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure the user knows that the fax software may not 
		be running before exiting.

CALLED BY:	MSG_PREF_FAX_DIALOG_CLOSE
PASS:		*ds:si	= PrefFaxDialogClass object
		ds:di	= PrefFaxDialogClass instance data
		es 	= segment of PrefFaxDialogClass

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		if a device is not selected {
			confirm close with user
			if yes
				close dialog
			else
				do nothing
		}
		else {
			if fax spooler is running 
				close dialog
			else
				inform user system won't be ready
				close dialog
		}
				
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	3/14/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefFaxDialogClose	method dynamic PrefFaxDialogClass, 
					MSG_PREF_FAX_DIALOG_CLOSE
		uses	ax, cx, dx, bp
		.enter
	;
	; Mark ourselves as busy -- this could take a while.
	;
		mov	ax, MSG_GEN_APPLICATION_MARK_BUSY
		call	GenCallApplication
	;
	; Check if a device is selected.
	;
		call	PrefFaxCheckDeviceSelected
		jc	confirmClose			
	;
	; Check if fax spooler is running.
	;
		call	PrefFaxCheckSpooler
		jnc	closeDialog
	;
	; Inform user the system won't be fax ready.
	;
		mov	si, offset NotFaxReadyString
		call	DisplayNotification
		jmp	closeDialog

confirmClose:
	;
	; Make sure the user really wants to exit without starting fax
	; software.
	;
		mov	si, offset ExitNoStartString
		call	DisplayQuestion
		cmp	ax, IC_NO
		je	exit
closeDialog:		
	;
	; Close the dialog.
	;
		mov	si, offset PrefFaxRoot
		mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
		mov	cx, IC_DISMISS
		call	ObjCallInstanceNoLock
exit:
	;
	; Mark not busy.
	;
		mov	ax, MSG_GEN_APPLICATION_MARK_NOT_BUSY
		call	GenCallApplication

		.leave
		ret
PrefFaxDialogClose	endm

;-----------------------------------------------------------------------------
;	Utilities for PrefFaxDialogClass
;-----------------------------------------------------------------------------

com1Info	PrinterPortInfo <
			mask PC_RS232C,
			PPT_SERIAL,
			mask SDM_COM1,
			SERIAL_COM1
		>

com2Info	PrinterPortInfo <
			mask PC_RS232C,
			PPT_SERIAL,
			mask SDM_COM2,
			SERIAL_COM2
		>

com3Info	PrinterPortInfo <
			mask PC_RS232C,
			PPT_SERIAL,
			mask SDM_COM3,
			SERIAL_COM3
		>

com4Info	PrinterPortInfo <
			mask PC_RS232C,
			PPT_SERIAL,
			mask SDM_COM4,
			SERIAL_COM4
		>



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefFaxCheckDeviceSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if there is a fax modem selected.

CALLED BY:	INTERNAL

PASS:		ds	= object block segment

RETURN:		carry clear if there is a fax modem selected

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	3/14/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefFaxCheckDeviceSelected	proc	near

		uses	ax, cx, dx, bp, si
		.enter
	;
	; See if anything is selected.
	;
		mov	si, offset PrefFaxDeviceList
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjCallInstanceNoLock
		jc	exit
	;
	;  Hack:  due to a bug in PrefDynamicListClass, in which
	;  the GIGI_selection and GIGI_numSelections will be set
	;  incorrectly if there is nothing in the list, we can't
	;  trust the test we just did, so we do another:  we check
	;  to see how many items are in the list.  -- Steve Y.
	;
		mov	ax, MSG_GEN_DYNAMIC_LIST_GET_NUM_ITEMS
		call	ObjCallInstanceNoLock
		stc				; assume no items
		jcxz	exit
	;
	; At this point we know something is selected.
	;		
		clc
exit:
		.leave
		ret
PrefFaxCheckDeviceSelected	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefFaxCheckSpooler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if the fax spooler is currently running.

CALLED BY:	INTERNAL

PASS:		ds	= object block segment

RETURN:		carry clear if fax spooler is running

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	3/14/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
faxspoolAppName	char	'faxspool', 0

PrefFaxCheckSpooler	proc	near
		uses	ax, bx, cx, dx, di, es
		.enter
	;
	; Check to see if the fax spooler is running.	
	;
		segmov	es, cs, ax
		mov	di, offset faxspoolAppName
		mov	ax, 8		; match name
		clr	cx, dx		; ignore attributes
		call	GeodeFind	; carry set if found 
		cmc			
		
		.leave
		ret
PrefFaxCheckSpooler	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefFaxLaunchSpooler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start the fax spooler.

CALLED BY:	INTERNAL

PASS:		nothing

RETURN:		carry set if fax spooler could not be launched

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	3/14/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NEC<	faxSpoolName	char	"Fax Spooler",0 			>
EC<	faxSpoolName	char	"EC Fax Spooler",0 			>

PrefFaxLaunchSpooler	proc	near
		uses	ax, bx, cx, dx, si, ds
		.enter

		segmov	ds, cs, ax
		clr	ax, cx, dx
		mov	si, offset faxSpoolName
		mov	bx, SP_SYS_APPLICATION
		call	UserLoadApplication
		jnc 	exit
		
		cmp	ax, GLE_NOT_MULTI_LAUNCHABLE  ; already running?
		je	exit			      

		stc
exit:
		.leave
		ret

PrefFaxLaunchSpooler	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisplayError/Notification/Question
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Display a message in a UserStandardDialog

CALLED BY:	INTERNAL
PASS:		si	- chunk handle of the error string to display
RETURN:		if DisplayQuestion, AX = response
		else nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	3/14/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisplayError	proc	near
		uses	ax
		.enter
		
		mov	ax, CustomDialogBoxFlags \
				<0, CDT_ERROR, GIT_NOTIFICATION,0>
		call	DisplayDialog
		
		.leave
		ret
DisplayError	endp


DisplayNotification	proc	near
		uses	ax
		.enter

		mov	ax, CustomDialogBoxFlags \
				<0, CDT_NOTIFICATION, GIT_NOTIFICATION, 0>
		call	DisplayDialog

		.leave	
		ret
DisplayNotification	endp


DisplayQuestion	proc	near

		mov	ax, CustomDialogBoxFlags \
				<0, CDT_QUESTION, GIT_AFFIRMATION, 0>
		call	DisplayDialog

		ret
DisplayQuestion	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisplayDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Put up a UserStandardDialog of the appropriate type.

CALLED BY:	INTERNAL

PASS:		si	- chunk handle of string to display
		ax	- CustomDialogBoxFlags

RETURN:		ax	- may contain response or garbage depending on
			  CustomDialogBoxFlags

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	3/14/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisplayDialog	proc	near
		uses	bx, si, bp, ds
		.enter
		
		sub	sp, size StandardDialogParams
		mov	bp, sp
		mov	ss:[bp].SDP_customFlags, ax
		
		mov	bx, handle Strings

		call	MemLock
		mov	ds, ax
		mov	si, ds:[si]

		mov	ss:[bp].SDOP_customString.segment, ds
		mov	ss:[bp].SDOP_customString.offset, si
		
		clrdw	ss:[bp].SDOP_stringArg1
		clrdw	ss:[bp].SDOP_stringArg2
		clr	ss:[bp].SDP_helpContext.segment

		call	UserStandardDialog		; cleans up stack

		call	MemUnlock

		.leave
		ret
DisplayDialog	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PreffaxOKTriggerSetNotEnabled
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Don't let ourselves become disabled.

CALLED BY:	MSG_GEN_SET_NOT_ENABLED

PASS:		*ds:si	= PreffaxOKTriggerClass object
		ds:di	= PreffaxOKTriggerClass instance data

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:

	Does not call superclass.

PSEUDO CODE/STRATEGY:

	Basically there's some bug in the Config stuff that causes
	an OK trigger in a multipleResponse dialog to become disabled
	when you use it (just like in a properties dialog), except
	that it never becomes re-enabled.  I don't feel like tracking
	it, so I'm just stubbornly refusing to become disabled.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	2/24/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PreffaxOKTriggerSetNotEnabled	method dynamic PreffaxOKTriggerClass, 
					MSG_GEN_SET_NOT_ENABLED
		ret
PreffaxOKTriggerSetNotEnabled	endm

	
PrefFaxCode	ends
