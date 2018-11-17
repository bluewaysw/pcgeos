COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		bsWelcome.asm

AUTHOR:		Steve Yegge, Jul 15, 1993

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	7/15/93		Initial revision

DESCRIPTION:

	

	$Id: bsWelcome.asm,v 1.1 97/04/04 16:52:58 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


WelcomeCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WelcomeStartSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make ourselves go away!

CALLED BY:	MSG_META_START_SELECT

PASS:		*ds:si	= WelcomeContentClass object
		ds:di	= WelcomeContentClass instance data

RETURN:		ax	= MouseReturnFlags
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	7/15/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WelcomeStartSelect	method dynamic	WelcomeContentClass, 
					MSG_META_START_SELECT,
					MSG_META_KBD_CHAR
		uses	cx, dx, bp
		.enter
	;
	;  Get the block our view is in (this is the same block
	;  as the main dialog).  Tell ourselves to disappear.
	;
		mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
		mov	bx, ds:[di].VCNI_view.handle
		mov	si, offset WelcomeDialog
		mov	cx, IC_DISMISS
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
	;
	;  If the pen has already been calibrated, the INI file
	;  will have the entry penCalibrated = TRUE under [system].
	;  If this is the case, don't do calibration or date/time
	;  screens.
	;
		call	BSCheckCalibration
		jc	calibrate
	;
	;  Don't calibrate -- just bail.
	;
		call	QuitStartupCommon
		jmp	done
calibrate:
	;
	;  Put up calibration screen.
	;
		mov	ax, MSG_BS_PRIMARY_DO_CALIBRATION
		mov	bx, handle MyBSPrimary
		mov	si, offset MyBSPrimary
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
done:
		mov	ax, mask MRF_PROCESSED
		
		.leave
		ret
WelcomeStartSelect	endm

WelcomeEndSelect	method dynamic	WelcomeContentClass, 
					MSG_META_END_SELECT,
					MSG_META_PTR
		ret
WelcomeEndSelect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WelcomeVisDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the picture (if any) and welcome string.

CALLED BY:	MSG_VIS_DRAW

PASS:		*ds:si	= WelcomeContentClass object
		ds:di	= WelcomeContentClass instance data
		^hbp	= gstate to draw through

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	7/15/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WelcomeVisDraw	method dynamic WelcomeContentClass, MSG_VIS_DRAW
		uses	ax, cx, dx, bp
		.enter
	;
	;  Draw the hello-there string.
	;
		mov	di, bp			; gstate
		mov	bp, TRUE
		mov	bx, WELCOME_STRING_TOP
		mov	si, offset WelcomeString
		call	DrawCenteredString
	;
	;  Draw the touch-me string.  Touch me, touch me.
	;
		mov	bx, TOUCH_SCREEN_STRING_TOP
		mov	si, offset TouchAnywhereString
		call	DrawCenteredString

		.leave
		ret
WelcomeVisDraw	endm

WelcomeCode	ends
