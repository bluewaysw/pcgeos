COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	(c) Copyright Geoworks 1995 -- All Rights Reserved
	GEOWORKS CONFIDENTIAL

PROJECT:	PC GEOS
MODULE:		Start up
FILE:		rstartupApp.asm

AUTHOR:		Jason Ho, Aug 28, 1995

METHODS:
	Name				Description
	----				-----------
	

ROUTINES:
	Name				Description
	----				-----------

	
REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho		8/28/95   	Initial revision


DESCRIPTION:
	Code for RStartupApplicationClass.
		

	$Id: rstartupApp.asm,v 1.1 97/04/04 16:52:36 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CommonCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RSAMetaNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	All purpose MetaClass expansion message.  Frequently used
		in conjunction with GCN mechanism

CALLED BY:	MSG_META_NOTIFY
PASS:		*ds:si	= RStartupApplicationClass object
		ds:di	= RStartupApplicationClass instance data
		es 	= segment of RStartupApplicationClass
		ax	= message #
		cx:dx 	- NotificationType
			cx - NT_manuf
			dx - NT_type
		bp - change specific data

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		In this application, we should ignore the application keys
		(so that nothing else runs) -- ie. when dx =
		GWNT_STARTUP_INDEXED_APP.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	5/ 1/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RSAMetaNotify	method dynamic RStartupApplicationClass, 
					MSG_META_NOTIFY
		.enter
	;
	; if dx != GWNT_STARTUP_INDEXED_APP, call super
	;
if 0
		PrintMessage<Take me away! No Hard icons!>
else
		cmp	dx, GWNT_STARTUP_INDEXED_APP
		jne	callSuper
	;
	; see if we are ignoring application keys right now - this is
	; necessary because we will launch phone app (or contact
	; manager) when we quit. If we keep ignoring the key, the app
	; will not start
	;
		test	ds:[di].RSAI_miscFlags, mask RSAF_ACCEPT_HARD_ICON
		jz	quit
callSuper:
	;
	; Call super
	;
endif
		mov	di, offset RStartupApplicationClass
		GOTO	ObjCallSuperNoLock
quit::
		.leave
		ret
RSAMetaNotify	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RSAMetaQuit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close IACP connection before quiting the app
		This should not be done in CLOSE_APPLICATION: you
		will never reach that far if there is IACP connection.

CALLED BY:	MSG_META_QUIT
PASS:		*ds:si	= RStartupApplicationClass object
		ds:di	= RStartupApplicationClass instance data
		es 	= segment of RStartupApplicationClass
		ax	= message #
		^lcx:dx	= object to send MSG_META_QUIT_ACK to
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	6/23/95   	Initial version (copied from
				FAMetaQuit, kertes)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if DO_ECI_SIM_CARD_CHECK	;--------------------------------------------
RSAMetaQuit	method dynamic RStartupApplicationClass, 
					MSG_META_QUIT
		uses	ax, bx, cx, dx, bp
		.enter
		CheckHack <size VpCloseIacpParams eq \
			size VpDeinstallClientParams>
	;
	; Deinstall the client from VP library, and
	; close that pesky IACP connection that they have to us or we
	; will never be able to quit
	;
		sub	sp, size VpCloseIacpParams
		mov	bp, sp
		CheckHack < size TokenChars eq 4 >
		mov	{word} ss:[bp].VCIAP_geodeToken.GT_chars, 'ST'
		mov	{word} ss:[bp].VCIAP_geodeToken.GT_chars+2, 'AU'
		mov	{word} ss:[bp].GT_manufID, MANUFACTURER_ID_GEOWORKS
		call	VpDeinstallClient		; ax, bx, cx,
							; dx destroyed
		call	VpCloseIacp			; ax, bx, cx,
							; dx destroyed
		add	sp, size VpCloseIacpParams
		.leave
	;
	; Call superclas to do normal stuff
	;
		mov	di, offset RStartupApplicationClass
		GOTO	ObjCallSuperNoLock
		
RSAMetaQuit	endm
endif		;-----------------------------------------------------------


if 0
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RSARstartupAppAcceptAppKey
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Mark that we will accept application keys

CALLED BY:	MSG_RSTARTUP_APP_ACCEPT_APP_KEY
PASS:		*ds:si	= RStartupApplicationClass object
		ds:di	= RStartupApplicationClass instance data
		es 	= segment of RStartupApplicationClass
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		We need this because we ignore app key when user is
		doing startup, but then we have to launch PHONE app
		(or CONTACT MGR) ourselves before we quit. If we do
		not mark that we accept keys, the launch from
		FoamLaunchApplication will also be ignored.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	5/ 3/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RSARstartupAppAcceptAppKey	-- OBSOLETE -- method dynamic RStartupApplicationClass, 
					MSG_RSTARTUP_APP_ACCEPT_APP_KEY
		.enter
		BitSet	ds:[di].RSAI_miscFlags, RSAF_ACCEPT_HARD_ICON
		.leave
		ret
RSARstartupAppAcceptAppKey	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RSARstartupAppKbdTypeChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Mark that the kbd type is changed, so we should reboot
		later.

CALLED BY:	MSG_RSTARTUP_APP_KBD_TYPE_CHANGED
PASS:		*ds:si	= RStartupApplicationClass object
		ds:di	= RStartupApplicationClass instance data
		es 	= segment of RStartupApplicationClass
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	8/28/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RSARstartupAppKbdTypeChanged	-- OBSOLETE -- method dynamic RStartupApplicationClass, 
					MSG_RSTARTUP_APP_KBD_TYPE_CHANGED
		.enter
		BitSet	ds:[di].RSAI_miscFlags, RSAF_KBD_TYPE_CHANGED
		.leave
		ret
RSARstartupAppKbdTypeChanged	endm

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RSARstartupAppIsKbdTypeChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return whether the kbd type is changed.

CALLED BY:	MSG_RSTARTUP_APP_IS_KBD_TYPE_CHANGED
PASS:		*ds:si	= RStartupApplicationClass object
		ds:di	= RStartupApplicationClass instance data
		es 	= segment of RStartupApplicationClass
		ax	= message #
RETURN:		cx	= TRUE or FALSE
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	8/28/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if 0
RSARstartupAppIsKbdTypeChanged	method dynamic RStartupApplicationClass, 
					MSG_RSTARTUP_APP_IS_KBD_TYPE_CHANGED
		.enter
		mov	cx, TRUE
		test	ds:[di].RSAI_miscFlags, mask RSAF_KBD_TYPE_CHANGED
		jnz	quit
		clr	cx
quit:
		.leave
		ret
RSARstartupAppIsKbdTypeChanged	endm
endif	; 0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RSARstartupAppSetAppFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the app flags.

CALLED BY:	MSG_RSTARTUP_APP_SET_APP_FLAGS
PASS:		*ds:si	= RStartupApplicationClass object
		ds:di	= RStartupApplicationClass instance data
		es 	= segment of RStartupApplicationClass
		ax	= message #
		cl	= RStartupApplicationFlags record
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	9/13/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RSARstartupAppSetAppFlags	method dynamic RStartupApplicationClass, 
					MSG_RSTARTUP_APP_SET_APP_FLAGS
		.enter
EC <		Assert	record, cl, RStartupApplicationFlags		>
		ornf	ds:[di].RSAI_miscFlags, cl
		.leave
		ret
RSARstartupAppSetAppFlags	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RStartupAppMetaBringUpHelp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ignore all help request

CALLED BY:	MSG_META_BRING_UP_HELP
PASS:		*ds:si	= RStartupApplicationClass object
		ds:di	= RStartupApplicationClass instance data
		ds:bx	= RStartupApplicationClass object (same as *ds:si)
		es 	= segment of RStartupApplicationClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	4/ 5/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RStartupAppMetaBringUpHelp	method dynamic RStartupApplicationClass, 
					MSG_META_BRING_UP_HELP
		Destroy ax
		ret
RStartupAppMetaBringUpHelp	endm

CommonCode	ends
