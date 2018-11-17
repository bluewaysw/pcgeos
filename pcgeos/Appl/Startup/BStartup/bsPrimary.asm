COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		bsPrimary.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	8/26/93   	Initial version.

DESCRIPTION:
	

	$Id: bsPrimary.asm,v 1.1 97/04/04 16:53:05 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BSPrimaryComingUp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We're coming on-screen.

CALLED BY:	MSG_BS_PRIMARY_COMING_UP

PASS:		*ds:si	= BSPrimaryClass object
		ds:di	= BSPrimaryClass instance data

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	7/15/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BSPrimaryComingUp	method dynamic BSPrimaryClass, 
					MSG_BS_PRIMARY_COMING_UP
		uses	ax, cx, dx, bp
		.enter
	;
	;  Put up the welcome dialog.
	;
		GetResourceHandleNS	WelcomeDialog, bx
		mov	si, offset	WelcomeDialog
		mov	di, mask MF_CALL
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		call	ObjMessage

		.leave
		ret
BSPrimaryComingUp	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BSPrimaryDoCalibration
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Put up the calibration dialog.

CALLED BY:	MSG_BS_PRIMARY_DO_CALIBRATION

PASS:		es	= dgroup
		*ds:si	= BSPrimaryClass object
		ds:di	= BSPrimaryClass instance data

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	7/15/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BSPrimaryDoCalibration	method dynamic BSPrimaryClass, 
					MSG_BS_PRIMARY_DO_CALIBRATION
	;
	;  Put up the calibration dialog.
	;
		mov	es:[doingSomething], DS_CALIBRATION
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		mov	bx, handle CalibrationDialog
		mov	si, offset CalibrationDialog
		mov	di, mask MF_CALL
		GOTO	ObjMessage

BSPrimaryDoCalibration	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BSPrimaryDoTheTimeDateThing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Put up the time/date entry dialog.

CALLED BY:	MSG_BS_PRIMARY_DO_THE_TIME_DATE_THING

PASS:		*ds:si	= BSPrimaryClass object
		ds:di	= BSPrimaryClass instance data

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	7/15/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BSPrimaryDoTheTimeDateThing	method dynamic BSPrimaryClass, 
					MSG_BS_PRIMARY_DO_THE_TIME_DATE_THING
		uses	ax, cx, dx, bp
		.enter
	;
	;  Put up the calibration dialog.
	;
		mov	es:[doingSomething], DS_DATE_TIME
		GetResourceHandleNS	TimeDateDialog, bx
		mov	si, offset	TimeDateDialog
		mov	di, mask MF_CALL
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		call	ObjMessage

		.leave
		ret
BSPrimaryDoTheTimeDateThing	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BSPrimaryDoneDateTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User's done entering date & time.

CALLED BY:	MSG_BS_PRIMARY_DONE_DATE_TIME

PASS:		*ds:si	= BSPrimaryClass object
		ds:di	= BSPrimaryClass instance data

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	7/15/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
systemCatString	char	"system",0
continueSetupString char "continueSetup",0

BSPrimaryDoneDateTime	method dynamic BSPrimaryClass, 
					MSG_BS_PRIMARY_DONE_DATE_TIME
		.enter
	;
	;  Put up a dialog saying we're done with startup.
	;
		mov	si, offset DoneStartupString
		call	DisplayNotification
	;
	;  Do the other stuff...
	;
		call	QuitStartupCommon

		.leave
		ret
BSPrimaryDoneDateTime	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		QuitStartupCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write INI file and bail.

CALLED BY:	BSPrimaryDoneDateTime, WelcomeStartSelect

PASS:		ds = any object block

RETURN:		nothing

DESTROYED:	all

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	11/13/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
QuitStartupCommon	proc	far
		.enter
	;
	;  set "continueSetup = false" in the .INI file
	;
		push	ds
		mov	cx, cs
		mov	ds, cx
		mov	es, cx
		mov	si, offset systemCatString
		mov	dx, offset continueSetupString
		mov	ax, FALSE
		call	InitFileWriteBoolean
		call	InitFileCommit
		pop	ds
		
	;
	;  Send a MSG_META_QUIT to the app object
	;
		mov	ax, MSG_META_QUIT
		call	UserCallApplication

		.leave
		ret
QuitStartupCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisplayNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Pops up a notification dialog box for the user to close

CALLED BY:	EXTERNAL
PASS:		si - chunk handle of string in Strings resource to display.
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	11/16/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisplayNotification	proc	near
		uses	ax,bp
		.enter
		
		sub	sp, size StandardDialogParams
		mov	bp, sp
		mov	ss:[bp].SDP_customFlags, 
		 CustomDialogBoxFlags <0, CDT_NOTIFICATION, GIT_NOTIFICATION,0>
		
		mov	ss:[bp].SDOP_customString.segment, handle Strings
		mov	ss:[bp].SDOP_customString.offset, si
		
		clrdw	ss:[bp].SDOP_stringArg1
		clrdw	ss:[bp].SDOP_stringArg2
		clr	ss:[bp].SDP_helpContext.segment
		
		call	UserStandardDialogOptr
		
		.leave
		ret
DisplayNotification	endp
