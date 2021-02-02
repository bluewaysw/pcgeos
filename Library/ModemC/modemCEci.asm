COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996 -- All Rights Reserved
	GEOWORKS CONFIDENTIAL

PROJECT:	PC GEOS
MODULE:		modemc library
FILE:		modemCEci.asm

AUTHOR:		Chris Thomas, Sep 23, 1996

ROUTINES:
	Name			Description
	----			-----------
    INT ModemClearBlacklist	Send an ECI message to clear the blacklist.

    INT ModemRegisterECI	Register for ECI notification of call
				termination. ECI_CALL_RELEASE_STATUS is
				received when mobile user ends the call.
				ECI_CALL_TERMINATE_STATUS is received when
				the remote user or network ends the call.

    INT ModemUnregisterECI	Unregister from ECI notifications.

    INT ModemECICallback	Callback routine for ECI notifications.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	9/23/96   	Initial revision


DESCRIPTION:

	Contains responder-specific routines for supporting
	end-call notification.  We detect when the call ends
	by registering to receive ECI messages.

	In order to detect call-end, we must monitor creation of
	the call, so we can match call ID's.  RegisterECI should
	be called before anything that could possibly create
	a data call, and UnregisterECI should be called
	after a data call has ended.

	$Id: modemCEci.asm,v 1.1 97/04/05 01:23:56 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

