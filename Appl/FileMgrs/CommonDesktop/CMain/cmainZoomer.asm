COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		cmainZoomer.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	don	2/10/93   	Initial version.

DESCRIPTION:
	

	$Id: cmainZoomer.asm,v 1.1 97/04/04 15:00:07 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _CONNECT_TO_REMOTE

ConnectCode	segment	resource

UseDriver	Internal/fsDriver.def		; FS driver definitions
include		Internal/rfsd.def		; RFS driver definitions


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DesktopOpenConnection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open a connection with another machine

CALLED BY:	GLOBAL (MSG_DESKTOP_OPEN_CONNECTION)

PASS:		DS	= dgroup
		CX	= ConnectionType

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	1/28/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

openRoutines	nptr.near \
		OpenFileLinkingConnection,
		OpenFileTransferConnection

DesktopOpenConnection	method dynamic	DesktopClass,
					MSG_DESKTOP_OPEN_CONNECTION
		.enter

		; Try to open the connection, after storing current type
		;
EC <		test	cx, 1						>
EC <		ERROR_NZ ILLEGAL_CONNECTION_TYPE			>
EC <		cmp	cx, ConnectionType				>
EC <		ERROR_AE ILLEGAL_CONNECTION_TYPE			>
EC <		ECCheckDGroup	ds					>
NOFXIP<		segmov	es, dgroup, bx					>
FXIP<		GetResourceSegmentNS dgroup, es, TRASH_BX		>
		cmp	es:[connection], -1
		jne	errorAlreadyOpen	; connection already established
		cmp	cx, CT_FILE_TRANSFER
		je	noStore			; don't store CT_FILE_TRANSFER
						;	as we'll either shutdown
						;	or cancel shutdown
		mov	es:[connection], cx
noStore:
		mov	bx, cx
		call	cs:[openRoutines][bx]
		jc	errorOpening
exit:
		.leave
		ret

		; The connection is already open. Tell the user
errorAlreadyOpen:
		mov	ax, CDT_ERROR shl offset CDBF_DIALOG_TYPE or \
			    GIT_NOTIFICATION shl offset CDBF_INTERACTION_TYPE
		mov	dx, offset ConnectionAlreadyOpen
		jmp	errorCommon

		; The connection could not be opened. Display error to user
errorOpening:
		mov	es:[connection], -1
		tst	dx			; no error message to report
		jz	exit
		mov	ax, CDT_ERROR shl offset CDBF_DIALOG_TYPE or \
			    GIT_NOTIFICATION shl offset CDBF_INTERACTION_TYPE
errorCommon:
		call	ConnectStandardDialog
		jmp	exit
DesktopOpenConnection	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpenFileLinkingConnection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open a connection with RFSD

CALLED BY:	DesktopOpenConnection

PASS:		ES	= DGroup

RETURN:		Carry	= Clear (success)
			- or -
		Carry	= Set (connection couldn't be opened)
		DX	= Chunk handle of string to display to user

DESTROYED:	AX, BX, CX, DI, SI, BP, DS

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	1/28/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EC <	rfsdDriverName	char	"rfsdec.geo", 0				>
NEC <	rfsdDriverName	char	"rfsd.geo", 0				>

OpenFileLinkingConnection	proc	near
		.enter
EC<		ECCheckDGroup	es					>
if _KEEP_MAXIMIZED
		;
		; ask user
		;
		mov	ax, WARNING_FILE_LINKING
		call	DesktopYesNoWarning
		cmp	ax, YESNO_YES
		stc				; assume error
		mov	dx, 0			; no error message
		LONG jne	done		; user doesn't want to continue
endif ; _KEEP_MAXIMIZED
	
		; Load the RFSD
		;
		mov	ax, SP_FILE_SYSTEM_DRIVERS
		call	FileSetStandardPath
		segmov	ds, cs
		mov	si, offset rfsdDriverName
		mov	ax, FS_PROTO_MAJOR
		mov	bx, FS_PROTO_MINOR
		call	GeodeUseDriver
		mov	dx, offset ZoomerConnectionFailed
		LONG jc	done

		; Store the driver handle away, and start a connection
		;
		mov	es:[rfsdHandle], bx
		call	GeodeInfoDriver
		mov	di, DR_RFS_OPEN_CONNECTION
		call	ds:[si].DIS_strategy
		LONG jc	rfsdError		; error, bail

if _KEEP_MAXIMIZED or _ZMGR
		;
		; maximize app and disable express menu and bring above
		; desk accessories (not necessarily in that order)
		;
		mov	ax, MSG_VIS_QUERY_WINDOW
		mov	bx, handle Desktop
		mov	si, offset Desktop
		mov	di, mask MF_CALL
		call	ObjMessage		; cx = window
		jcxz	noWindow
		push	cx
		mov	ax, LAYER_PRIO_ON_TOP
		push	ax			; data
		mov	dx, sp			; ss:dx = LAYER_PRIO_ON_TOP
.assert (offset AVDP_data eq 0)
.assert (offset AVDP_dataSize eq (offset AVDP_data)+4)
.assert (offset AVDP_dataType eq (offset AVDP_dataSize)+2)
		mov	ax, ATTR_GEN_WINDOW_CUSTOM_LAYER_PRIORITY
		push	ax			; AVDP_dataType
		mov	ax, size LayerPriority
		push	ax			; AVDP_dataSize
		pushdw	ssdx			; AVDP_data
		mov	ax, MSG_META_ADD_VAR_DATA
		mov	dx, size AddVarDataParams
		mov	bp, sp
		mov	di, mask MF_CALL or mask MF_STACK
		call	ObjMessage
		add	sp, size AddVarDataParams	; throw away AVDP
		pop	ax			; throw away data
		pop	di			; di = window
		mov	ax, mask WPF_LAYER or \
				(LAYER_PRIO_ON_TOP shl offset WPD_LAYER)
		call	GeodeGetProcessHandle	; bx = owner = layer ID
		mov	dx, bx
		call	WinChangePriority
noWindow:

if _KEEP_MAXIMIZED
		call	 OpenFileLinkingConnectionSetMinimizeRestoreUI

		mov	ax, MSG_MAXIMIZED_PRIMARY_MAXIMIZE_TEMPORARILY
		mov	bx, handle FileSystemDisplay
		mov	si, offset FileSystemDisplay
		clr	di
		call	ObjMessage
endif ; _KEEP_MAXIMIZED

		mov	ax, MSG_GEN_GUP_QUERY
		mov	cx, GUQT_FIELD
		mov	bx, handle Desktop
		mov	si, offset Desktop
		mov	di, mask MF_CALL
		call	ObjMessage		; ^lcx:dx = field
		movdw	bxsi, cxdx

		mov	ax, MSG_VIS_FIND_CHILD_AT_POSITION
		clr	cx			; (first child)
		mov	di, mask MF_CALL
		call	ObjMessage		; ^lcx:dx = tool area

		movdw	bxsi, cxdx
		mov	ax, MSG_GEN_FIND_CHILD_AT_POSITION
		clr	cx
		mov	di, mask MF_CALL
		call	ObjMessage		; ^lcx:dx = express menu

		movdw	es:[expressMenu], cxdx
		movdw	bxsi, cxdx
		mov	ax, MSG_GEN_SET_NOT_ENABLED
		mov	dl, VUM_NOW
		clr	di
		call	ObjMessage


endif		; if _KEEP_MAXIMIZED or _ZMGR

		; Display the modal connection initiate status dialog
		;
		mov	bx, handle FileLinkingStatusDialog
		mov	si, offset FileLinkingStatusDialog
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		clr	di
		call	ObjMessage

if _PREFERENCES_LAUNCH
		call	 OpenFileLinkingConnectionSetPreferencesLaunchUI
endif	;_PREFERENCES_LAUNCH

if _CONNECT_TO_REMOTE
		call	 OpenFileLinkingConnectionSetConnectToRemoteUI
endif	; _CONNECT_TO_REMOTE

		mov	es:[fileLinkingPending], TRUE

		clc
done:
		.leave
		ret

rfsdError:
		;
		; unload RFSD, return nice error message
		;	ax = error code
		;
		xchg	bx, es:[rfsdHandle]
		call	GeodeFreeDriver
		mov	dx, offset RFSDConfigError
		cmp	ax, RFSDCE_CONFIG_ERROR
		je	errorExit
		mov	dx, offset RFSDAlreadyConnected
		cmp	ax, RFSDCE_ALREADY_CONNECTED
		je	errorExit
		mov	dx, offset RFSDClosingConnection
		cmp	ax, RFSDCE_CLOSING_CONNECTION
		je	errorExit
		mov	dx, offset RFSDCommError
		cmp	ax, RFSDCE_COMM_ERROR
		je	errorExit
		mov	dx, offset RFSDMemError
		cmp	ax, RFSDCE_MEM_ERROR
		je	errorExit
		mov	dx, ZoomerConnectionFailed
errorExit:
		stc				; indicate error
		jmp	short done

OpenFileLinkingConnection	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileLinkingEstablished
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	add close connection button and bring drives dialog

CALLED BY:	EXTERNAL
			DesktopDriveChangeNotify

PASS:		es - dgroup

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	6/8/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileLinkingEstablished	proc	far
		uses	ax, bx, cx, dx, bp, si, di, ds
		.enter
EC<		ECCheckDGroup	es					>
		cmp	es:[fileLinkingPending], TRUE
		jne	done

		mov	bx, es:[rfsdHandle]
		tst	bx
		jz	done
		call	GeodeInfoDriver
		mov	di, DR_RFS_GET_STATUS
		call	ds:[si].DIS_strategy	; ax = status
		cmp	ax, RFS_CONNECTED
		jne	done			; not RFSD drive change

		mov	es:[fileLinkingPending], FALSE

		; Bring down status dialog
		;
		mov	bx, handle FileLinkingStatusDialog
		mov	si, offset FileLinkingStatusDialog
		mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
		mov	cx, IC_DISMISS
		clr	di
		call	ObjMessage

		
		; Display the connection icon & the drives dialog
		;
		mov	ax, MSG_GEN_SET_USABLE
		mov	bx, MSG_GEN_INTERACTION_INITIATE
		call	ConnectUISetState
done:
		.leave
		ret
FileLinkingEstablished	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileLinkingRemoved
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	if RFSD is gone, close connection

CALLED BY:	EXTERNAL
			DesktopDriveChangeNotify

PASS:		es - dgroup

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	6/11/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileLinkingRemoved	proc	far
		uses	ax, bx, cx, dx, bp, si, di, ds
		.enter
EC<		ECCheckDGroup	es					>
		cmp	es:[connection], CT_FILE_LINKING
		jne	done

		mov	bx, es:[rfsdHandle]
		tst	bx
		jz	done
		call	GeodeInfoDriver
		mov	di, DR_RFS_GET_STATUS
		call	ds:[si].DIS_strategy	; ax = status
		cmp	ax, RFS_CONNECTED
		je	done			; RFSD still connected
		cmp	ax, RFS_CONNECTING
		je	done			; RFSD still connected

		call	AbortFileLinking	; sets es:[connection] = -1
done:
		.leave
		ret
FileLinkingRemoved	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpenFileTransferConnection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open a file-transfer connection

CALLED BY:	DesktopOpenConnection

PASS:		ES	= dgroup

RETURN:		Carry	= Clear (success)
			- or -
		Carry	= Set (connection couldn't be opened)
		DX	= Handle of string to display to user
				(or 0 to ignore error)

DESTROYED:	AX, BX, CX, DI, SI, BP, DS

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	1/28/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

OpenFileTransferConnection	proc	near

		uses	es

		.enter
EC<	ECCheckDGroup	es						>
		;
		; ask user
		;
		mov	ax, WARNING_FILE_TRANSFER
		call	DesktopYesNoWarning
		cmp	ax, YESNO_YES
		stc				; assume error
		mov	dx, 0
		jne	exit			; user doesn't want to continue

		;
		; get app from .ini file
		;
		segmov	ds, cs, cx
		mov	si, offset fileTransferCommandCategory
		mov	dx, offset fileTransferApplicationKey
		mov	bp, 0			; return buffer
		call	InitFileReadString	; bx = buffer
		jc	done			; not found
		push	bx			; save buffer

		;
		; get parameters from .ini file
		;
		segmov	ds, cs, cx
		mov	si, offset fileTransferCommandCategory
		mov	dx, offset fileTransferParametersKey
		mov	bp, 0			; return buffer
		call	InitFileReadString	; bx = buffer
		jnc	haveParamsBlock		; found
		clr	bx			; indicate no buffer
haveParamsBlock:
		pop	dx			; dx = app block
		push	dx			; save app block
		push	bx			; save param block
		;
		; DosExec the thing
		;
NOFXIP <	segmov	es, cs			; in case no params	>
NOFXIP <	mov	di, offset nullString				>
FXIP <		mov	di, bx						>
FXIP <		GetResourceSegmentNS dgroup, es, TRASH_BX		>
FXIP <		mov	bx, di						>
FXIP <		mov	di, offset es:[nullString]			>
		tst	bx
		jz	haveParamString
		call	MemLock
		mov	es, ax			; es:di = params
		clr	di
haveParamString:
		mov	bx, dx			; bx = app block
		call	MemLock
		mov	ds, ax			; ds:si = app
		clr	ax,dx,bx,bp,si
		call	DosExec
		pop	bx			; bx = param block
		pop	dx			; dx = app block
		pushf				; save error flag
		tst	bx
		jz	noParamBlock
		call	MemFree
noParamBlock:
		mov	bx, dx			; bx = app block
		call	MemFree
		popf				; restore error flag
done:
						; in case of error
		mov	dx, offset FileTransferConnectionFailed
exit:
		.leave
		ret
OpenFileTransferConnection	endp

fileTransferApplicationKey	byte	'command',0
fileTransferParametersKey	byte	'parameters',0
fileTransferCommandCategory	byte	'fileTransfer' ; <-- NOTE: NULL FOLLOWS

if FULL_EXECUTE_IN_PLACE
idata	segment
endif

nullString			byte	0

if FULL_EXECUTE_IN_PLACE
idata	ends
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DesktopCancelFileLinking
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Cancel a file linking attempt

CALLED BY:	GLOBAL (MSG_DESKTOP_CANCEL_FILE_LINKING)

PASS:		ds	= dgroup

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	1/28/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DesktopCancelFileLinking	method dynamic	DesktopClass,
					MSG_DESKTOP_CANCEL_FILE_LINKING
		.enter
NOFXIP<	segmov	es, dgroup, bx		; es = dgroup			>
FXIP  <	GetResourceSegmentNS dgroup, es, TRASH_BX			>

		mov	es:[fileLinkingPending], FALSE

		; Close the proper connection
		;
		mov	bx, -1
		xchg	bx, es:[connection]
		call	CloseFileLinkingConnection
		.leave
		ret
DesktopCancelFileLinking	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DesktopCloseConnection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close a connection

CALLED BY:	GLOBAL (MSG_DESKTOP_CLOSE_CONNECTION)

PASS:		ds	= dgroup

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	1/28/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

closeRoutines	nptr.near \
		CloseFileLinkingConnection,
		CloseFileTransferConnection

DesktopCloseConnection	method dynamic	DesktopClass,
					MSG_DESKTOP_CLOSE_CONNECTION
		.enter
NOFXIP<	segmov	es, dgroup, bx		; es = dgroup			>
FXIP  <	GetResourceSegmentNS dgroup, es, TRASH_BX			>

	; Ask the user if he/she really wants to close the connection
	;
		mov	dx, offset ConnectionCloseVerify
		mov	ax, CDT_QUESTION shl offset CDBF_DIALOG_TYPE or \
			    GIT_AFFIRMATION shl offset CDBF_INTERACTION_TYPE
		call	ConnectStandardDialog
		cmp	ax, IC_YES
		jne	done

	; Close the proper connection
	;
		mov	bx, -1
		xchg	bx, es:[connection]
		cmp	bx, -1
		jz	done
		call	cs:[closeRoutines][bx]
done:
		.leave
		ret
DesktopCloseConnection	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CloseFileLinkingConnection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close a connection with RFSD

CALLED BY:	DesktopCloseConnection

PASS:		es	= dgroup

RETURN:		Carry	= Clear (success)
			- or -
		Carry	= Set (connection couldn't be opened)

DESTROYED:	AX, BX, CX, DX, DI, SI, BP, DS

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	1/28/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CloseFileLinkingConnection	proc	near
		.enter
EC	<	ECCheckDGroup	es					>
if _CONNECT_TO_REMOTE
		call	CloseFileLinkingConnectionSetConnectToRemoteUI
endif

if _PREFERENCES_LAUNCH
		call	CloseFileLinkingConnectionSetPreferencesLaunchUI
endif	;_PREFERENCES_LAUNCH

if _KEEP_MAXIMIZED
		call	CloseFileLinkingConnectionSetMinimizeRestoreUI
endif ; _KEEP_MAXIMIZED
	
		; First, kill off the connection, and then free the driver
		;
		clr	bx
		xchg	bx, es:[rfsdHandle]
		tst	bx
		jz	done
		call	GeodeInfoDriver
		mov	di, DR_RFS_CLOSE_CONNECTION
		call	ds:[si].DIS_strategy
		call	GeodeFreeDriver

		; Remove the connection icon
		;
		mov	ax, MSG_GEN_SET_NOT_USABLE
		mov	bx, MSG_GEN_INTERACTION_ACTIVATE_COMMAND
		mov	cx, IC_DISMISS
		call	ConnectUISetState
done:

if _KEEP_MAXIMIZED
		mov	ax, MSG_MAXIMIZED_PRIMARY_RESTORE
		LoadBXSI	FileSystemDisplay
		call	ObjMessageNone
endif ; _KEEP_MAXIMIZED

if _KEEP_MAXIMIZED or _ZMGR
		
		;
		; re-enable express menu, restore layer priority
		;
		movdw	bxsi, es:[expressMenu]
		mov	ax, MSG_GEN_SET_ENABLED
		mov	dl, VUM_NOW
		call	ObjMessageNone

		mov	ax, MSG_META_DELETE_VAR_DATA
		mov	cx, ATTR_GEN_WINDOW_CUSTOM_LAYER_PRIORITY
		mov	bx, handle Desktop
		mov	si, offset Desktop
		call	ObjMessageCall
		mov	ax, MSG_VIS_QUERY_WINDOW
		call	ObjMessageCall	; cx = window
		jcxz	noWindow
		mov	di, cx			; di = window
		mov	ax, mask WPF_LAYER or \
				(LAYER_PRIO_STD shl offset WPD_LAYER)
		call	GeodeGetProcessHandle	; bx = owner = layer ID
		mov	dx, bx
		call	WinChangePriority
noWindow:
endif		; _KEEP_MAXIMIZED or _ZMGR

		.leave
		ret
CloseFileLinkingConnection	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CloseFileTransferConnection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close a file-transfer connection

CALLED BY:	DesktopCloseConnection

PASS:		ES	= dgroup

RETURN:		Carry	= Clear (success)
			- or -
		Carry	= Set (connection couldn't be opened)

DESTROYED:	AX, BX, CX, DX, DI, SI, BP, DS

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	1/28/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CloseFileTransferConnection	proc	near
		.enter
	
		.leave
		ret
CloseFileTransferConnection	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AbortFileLinking
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	abort file linking

CALLED BY:	DesktopCloseApplication

PASS:		es - dgroup

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp, di, si

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	6/10/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AbortFileLinking	proc	far
	uses	ds
	.enter
EC<	ECCheckDGroup	es						>
	cmp	es:[connection], CT_FILE_LINKING
	jne	done
	mov	es:[connection], -1
	call	CloseFileLinkingConnection
done:
	.leave
	ret
AbortFileLinking	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConnectUISetState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the proper state for the Connect UI

CALLED BY:	UTILITY

PASS:		AX	= Message to send to ConnectionActive trigger
		BX	= Message to send to FloatingDrivesDialog
		CX	= Data to pass in CX for both messages

RETURN:		Nothing

DESTROYED:	bx,si

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	2/ 1/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ConnectUISetState	proc	near

if not _CONNECT_ICON
		; Set usable or not usable the Connection button
		;
		push	bx, cx
		mov	bx, handle ConnectionActive
		mov	si, offset ConnectionActive
		call	ObjMessage_connect_UI
		pop	ax, cx

		; Initiate or close the drives dialog box
		;
		mov	bx, handle FloatingDrivesDialog
		mov	si, offset FloatingDrivesDialog
		FALL_THRU	ObjMessage_connect_UI
else
		ret
endif ; (not _CONNECT_ICON)
ConnectUISetState	endp

if not _CONNECT_ICON
ObjMessage_connect_UI	proc	near
		mov	dl, VUM_DELAYED_VIA_UI_QUEUE
		clr	di
		call	ObjMessage
		ret
ObjMessage_connect_UI	endp
endif		; if (not _CONNECT_ICON)


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConnectStandardDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Display a message to the user

CALLED BY:	UTILITY

PASS:		DX	= Chunk handle in DeskStringsCommon resource
		AX	= CustomDialogBoxFlags

RETURN:		AX	= InteractionCommand

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	2/ 1/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ConnectStandardDialog	proc	near
		uses	bx, cx
		.enter
	
		clr	cx
		pushdw	cxcx			; SDOP_helpContext
		pushdw	cxcx			; SDOP_customTriggers
		pushdw	cxcx			; SDOP_stringArg2
		pushdw	cxcx			; SDOP_stringArg1
		mov	bx, handle DeskStringsCommon
		pushdw	bxdx			; SDOP_customString
		push	ax			; SDOP_customFlags
		call	UserStandardDialogOptr

		.leave
		ret
ConnectStandardDialog	endp


if _CONNECT_TO_REMOTE

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpenFileLinkingConnectionSetConnectToRemoteUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Swap monikers and messages for connection ui after making 
		a successful connection

CALLED BY:	INTERNAL
		OpenFileLinkingConnection

PASS:		
		nothing
RETURN:		
		nothing

DESTROYED:	
		ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/ 7/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OpenFileLinkingConnectionSetConnectToRemoteUI		proc	near
		.enter

if not _CONNECT_MENU
		LoadBXSI	DiskMenuFileLinking
		mov	ax, MSG_GEN_USE_VIS_MONIKER
		mov	cx, offset StopFileLinkingMoniker
		mov	dl, VUM_DELAYED_VIA_UI_QUEUE
		clr	di
		call	ObjMessage
		mov	ax, MSG_GEN_TRIGGER_SET_ACTION_MSG
		mov	cx, MSG_DESKTOP_CLOSE_CONNECTION
		clr	di
		call	ObjMessage
endif ; (not _CONNECT_MENU)

if _CONNECT_ICON
		LoadBXSI	ConnectionConnect
		mov	ax, MSG_GEN_SET_NOT_USABLE
		mov	dl, VUM_DELAYED_VIA_APP_QUEUE
		clr	di
		call	ObjMessage

		LoadBXSI	ConnectionDisconnect
		mov	ax, MSG_GEN_SET_USABLE
		mov	dl, VUM_DELAYED_VIA_APP_QUEUE
		clr	di
		call	ObjMessage
endif ; _CONNECT_ICON
		.leave
		ret
OpenFileLinkingConnectionSetConnectToRemoteUI		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CloseFileLinkingConnectionSetConnectToRemoteUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Swap monikers and messages for connection ui after closing
		a connection

CALLED BY:	INTERNAL
		CloseFileLinkingConnection

PASS:		
		nothing
RETURN:		
		nothing

DESTROYED:	
		ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/ 7/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CloseFileLinkingConnectionSetConnectToRemoteUI		proc	near
		.enter

if not _CONNECT_MENU
		LoadBXSI DiskMenuFileLinking
		mov	ax, MSG_GEN_USE_VIS_MONIKER
		mov	cx, offset FileLinkingMoniker
		mov	dl, VUM_DELAYED_VIA_UI_QUEUE
		clr	di
		call	ObjMessage
		mov	ax, MSG_GEN_TRIGGER_SET_ACTION_MSG
		mov	cx, MSG_DESKTOP_OPEN_CONNECTION
		clr	di
		call	ObjMessage
endif ; (not _CONNECT_MENU)

if _CONNECT_ICON
		mov	bx, handle ConnectionDisconnect
		mov	si, offset ConnectionDisconnect
		mov	ax, MSG_GEN_SET_NOT_USABLE
		mov	dl, VUM_DELAYED_VIA_APP_QUEUE
		clr	di
		call	ObjMessage

		mov	bx, handle ConnectionConnect
		mov	si, offset ConnectionConnect
		mov	ax, MSG_GEN_SET_USABLE
		mov	dl, VUM_DELAYED_VIA_APP_QUEUE
		clr	di
		call	ObjMessage
endif ; _CONNECT_ICON

		.leave
		ret
CloseFileLinkingConnectionSetConnectToRemoteUI		endp


endif


if _PREFERENCES_LAUNCH


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpenFileLinkingConnectionSetPreferencesLaunchUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Disable preferences button
		

CALLED BY:	INTERNAL
		OpenFileLinkingConnection

PASS:		
		nothing
RETURN:		
		nothing

DESTROYED:	
		ax,bx,cx,dx,bp,si,di

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/ 7/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OpenFileLinkingConnectionSetPreferencesLaunchUI		proc	near
		.enter

		;Disable preferences button during connect
		;

		mov	bx,handle PreferencesLaunch
		mov	si,offset PreferencesLaunch
		mov	dl, VUM_NOW
		mov	di,mask MF_CALL			;do it now
		mov	ax,MSG_GEN_SET_NOT_ENABLED
		call	ObjMessage

		.leave
		ret
OpenFileLinkingConnectionSetPreferencesLaunchUI		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CloseFileLinkingConnectionSetPreferencesLaunchUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enable preferences button
		

CALLED BY:	INTERNAL
		CloseFileLinkingConnection

PASS:		
		nothing
RETURN:		
		nothing

DESTROYED:	
		ax,bx,cx,dx,bp,si,di

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/ 7/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CloseFileLinkingConnectionSetPreferencesLaunchUI		proc	near
		.enter

		;
		;Enable preferences button now that connect is done
		;

		mov	bx,handle PreferencesLaunch
		mov	si,offset PreferencesLaunch
		mov	dl, VUM_NOW
		mov	di,mask MF_CALL			;do it now
		mov	ax,MSG_GEN_SET_ENABLED
		call	ObjMessage

		.leave
		ret
CloseFileLinkingConnectionSetPreferencesLaunchUI		endp


endif	;_PREFERENCES_LAUNCH

if _KEEP_MAXIMIZED


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpenFileLinkingConnectionSetMinimizeRestoreUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Prevent minimize and restore buttons from working on 
		GeoManager
		
		
CALLED BY:	INTERNAL
		OpenFileLinkingConnection

PASS:		
		nothing
RETURN:		
		nothing

DESTROYED:	
		ax,bx,cx,dx,bp,si,di

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/ 7/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OpenFileLinkingConnectionSetMinimizeRestoreUI		proc	near
		.enter

	;    We don't want the user to able to access other
	;    applications while connected. So we must not let them
	;    minimize or restore the just maximized GeoManager.
	;

		mov	bx,handle FileSystemDisplay
		mov	si,offset FileSystemDisplay
		mov	dx,size AddVarDataParams
		sub	sp,dx
		mov	bp,sp
		clrdw	ss:[bp].AVDP_data
		clr	ss:[bp].AVDP_dataSize
		mov	ss:[bp].AVDP_dataType,ATTR_GEN_DISPLAY_NOT_MINIMIZABLE
		mov	di,mask MF_CALL or mask MF_STACK
		mov	ax,MSG_META_ADD_VAR_DATA
		push	ax,dx,bp,di
		call	ObjMessage
		pop	ax,dx,bp,di
		mov	ss:[bp].AVDP_dataType,ATTR_GEN_DISPLAY_NOT_RESTORABLE
		call	ObjMessage
		add	sp,size AddVarDataParams

		.leave
		ret
OpenFileLinkingConnectionSetMinimizeRestoreUI		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CloseFileLinkingConnectionSetMinimizeRestoreUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enable preferences button
		

CALLED BY:	INTERNAL
		CloseFileLinkingConnection

PASS:		
		nothing
RETURN:		
		nothing

DESTROYED:	
		ax,bx,cx,dx,bp,si,di

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/ 7/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CloseFileLinkingConnectionSetMinimizeRestoreUI		proc	near
		.enter

		mov	bx,handle FileSystemDisplay
		mov	si,offset FileSystemDisplay
		mov	cx,ATTR_GEN_DISPLAY_NOT_MINIMIZABLE
		mov	di,mask MF_CALL
		mov	ax,MSG_META_DELETE_VAR_DATA
		push	ax,di
		call	ObjMessage
		pop	ax,di
		mov	cx,ATTR_GEN_DISPLAY_NOT_RESTORABLE
		call	ObjMessage

		.leave
		ret
CloseFileLinkingConnectionSetMinimizeRestoreUI		endp


endif ; _KEEP_MAXIMIZED

ConnectCode	ends

endif ; _CONNECT_TO_REMOTE
