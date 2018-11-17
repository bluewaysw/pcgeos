COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Geode
FILE:		geodeAccess.asm

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/88		Initial version

DESCRIPTION:
	This file contains routines to handle GEODE resources.

	$Id: geodesAccess.asm,v 1.1 97/04/05 01:12:15 newdeal Exp $

-------------------------------------------------------------------------------@

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GeodeGetProcessHandle

C DECLARATION:	extern GeodeHandle
			_far _pascal GeodeGetProcessHandle();

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GEODEGETPROCESSHANDLE	proc	far
	mov	ax,ss:[TPD_processHandle]
	ret

GEODEGETPROCESSHANDLE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GeodeGetCodeProcessHandle

C DECLARATION:	extern GeodeHandle
			_far _pascal GeodeGetCodeProcessHandle();

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GEODEGETCODEPROCESSHANDLE	proc	far
	pop	ax		;ax = return address offset
	pop	cx		;cx = return address offset
	push	cx
	push	ax

	call	MemSegmentToHandle	;cx = handle
EC <	ERROR_NC	CANNOT_FIND_CODE_SEGMENT			>

	mov	bx, cx
	call	MemOwner
	mov_trash	ax, bx

	ret

GEODEGETCODEPROCESSHANDLE	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	GeodeGetProcessHandle

DESCRIPTION:	Return the handle of the current process

CALLED BY:	GLOBAL

PASS:
	none

RETURN:
	bx - process handle

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version

------------------------------------------------------------------------------@

GeodeGetProcessHandle	proc	far
	mov	bx,ss:[TPD_processHandle]
	ret

GeodeGetProcessHandle	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	GeodeGetInfo

DESCRIPTION:	Return information about a geode

CALLED BY:	GLOBAL

PASS:
	ax - GeodeGetInfoType
	bx - geode about which to return information (0 for current)
	es:di - buffer for:
		GGIT_GEODE_RELEASE (size ReleaseNumber)
		GGIT_GEODE_PROTOCOL (size ProtocolNumber)
		GGIT_TOKEN_ID (size GeodeToken)
		GGIT_PERM_NAME_AND_EXT (GEODE_NAME_LEN + GEODE_NAME_EXT_LEN)
		GGIT_PERM_NAME_ONLY (GEODE_NAME_LEN)
		GGIT_GEODE_REF_COUNT (geode reference count)

RETURN:
	ax - value dependent on GeodeGetInfoTypes passed

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/91		Initial version
	IP	6/16/94		Added GGIT_GEODE_REF_COUNT

-------------------------------------------------------------------------------@

GeodeGetInfo	proc	far
	push	ds
	push	cx, si, di

	call	GeodeAccessCoreBlock

	mov_trash	si, ax
EC <	cmp	si, size globalGeodeGetInfoTable			>
EC <	ERROR_AE	GEODE_GET_INFO_BAD_PARAMETER			>

	call	cs:[globalGeodeGetInfoTable][si]

	pop	cx, si, di

unlock_popDS_ret	label	far
	call	UnlockDS
	pop	ds
	ret

GeodeGetInfo	endp

if not DBCS_PCGEOS

globalGeodeGetInfoTable	nptr	\
	GGI_Attributes,				;GGIT_ATTRIBUTES
	GGI_Type,				;GGIT_TYPE
	GGI_GeodeRelease,			;GGIT_GEODE_RELEASE
	GGI_GeodeProtocol,			;GGIT_GEODE_PROTOCOL
	GGI_TokenID,				;GGIT_TOKEN_ID
	GGI_PermNameAndExt,			;GGIT_PERM_NAME_AND_EXT
	GGI_PermNameOnly,			;GGIT_PERM_NAME_ONLY
	GGI_GeodeRefCount			;GGIT_GEODE_REF_COUNT
else

globalGeodeGetInfoTable	nptr	\
	GGI_Attributes,				;GGIT_ATTRIBUTES
	GGI_Type,				;GGIT_TYPE
	GGI_GeodeRelease,			;GGIT_GEODE_RELEASE
	GGI_GeodeProtocol,			;GGIT_GEODE_PROTOCOL
	GGI_TokenID,				;GGIT_TOKEN_ID
	GGI_PermNameAndExt,			;GGIT_PERM_NAME_AND_EXT
	GGI_PermNameOnly,			;GGIT_PERM_NAME_ONLY
	GCI_PermNameAndExtDBCS,			;GGIT_PERM_NAME_AND_EXT_DBCS
	GCI_PermNameOnlyDBCS,			;GGIT_PERM_NAME_ONLY_DBCS
	GGI_GeodeRefCount			;GGIT_GEODE_REF_COUNT
endif

;---

GGI_Attributes	proc	near
	mov	ax, ds:[GH_geodeAttr]
	ret
GGI_Attributes	endp

;---

GGI_Type	proc	near
	mov	ax, ds:[GH_geodeFileType]
	ret
GGI_Type	endp

;---

GGI_GeodeRelease	proc	near
	mov	si, offset GH_geodeRelease
	mov	cx, size ReleaseNumber
	rep	movsb
	ret
GGI_GeodeRelease	endp

;---

GGI_GeodeProtocol	proc	near
	mov	si, offset GH_geodeProtocol
	mov	cx, size ProtocolNumber
	rep	movsb
	ret
GGI_GeodeProtocol	endp

;---

GGI_TokenID	proc	near
	mov	si, offset GH_geodeToken
	mov	cx, size GeodeToken
	rep	movsb
	ret
GGI_TokenID	endp

;---

GGI_PermNameOnly	proc	near
SBCS <	mov	cx, GEODE_NAME_SIZE					>
DBCS <	mov	cx, GEODE_NAME_SIZE/2					>
	FALL_THRU	GGI_PermNameCommon
GGI_PermNameOnly	endp

GGI_PermNameCommon	proc	near
	mov	si, offset GH_geodeName
SBCS <	rep	movsb							>
DBCS <	rep	movsw							>
	ret
GGI_PermNameCommon	endp

;---

GGI_PermNameAndExt	proc	near
SBCS <	mov	cx, GEODE_NAME_SIZE + GEODE_NAME_EXT_SIZE		>
DBCS <	mov	cx, (GEODE_NAME_SIZE + GEODE_NAME_EXT_SIZE)/2		>
	GOTO	GGI_PermNameCommon
GGI_PermNameAndExt	endp

;---

GGI_GeodeRefCount	proc	near
	mov	ax, ds:[GH_geodeRefCount]
	ret		
GGI_GeodeRefCount	endp


if DBCS_PCGEOS

;---

GCI_PermNameOnlyDBCS	proc	near
	mov	cx, GEODE_NAME_SIZE
	FALL_THRU	GCI_PermNameCommonDBCS
GCI_PermNameOnlyDBCS	endp

GCI_PermNameCommonDBCS	proc	near
	push	ax
	mov	si, offset GH_geodeName
	clr	ah
charLoop:
	lodsb				;al <- get SBCS character
	stosw				;store DBCS character
	loop	charLoop
	pop	ax
	ret
GCI_PermNameCommonDBCS	endp

;---

GCI_PermNameAndExtDBCS	proc	near
	mov	cx, GEODE_NAME_SIZE + GEODE_NAME_EXT_SIZE
	GOTO	GCI_PermNameCommonDBCS
GCI_PermNameAndExtDBCS	endp

;---

endif


COMMENT @-----------------------------------------------------------------------

FUNCTION:	GeodeInfoDriver

DESCRIPTION:	Return information about a driver

CALLED BY:	GLOBAL

PASS:
	bx - handle of driver

RETURN:
	ds:si - driver's info block (DriverInfoStruct)

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/88		Initial version
-------------------------------------------------------------------------------@

GeodeInfoDriver	proc	far

if	NUMBER_OF_SYSTEM_GEODES gt 0
	cmp	bx,NUMBER_OF_SYSTEM_GEODES	;test for system driver
	ja	notSystem

	push	ax
	segmov	ds,cs				;ds = segment
	mov	si,size GeodeEnumStruct		;compute table address
	mov	ax,bx
	dec	ax
	mul	si
	mov	si,ax
	mov	si,ds:[si][SystemGeodeTable+GES_segment]   ;get table address
	pop	ax
	ret
notSystem:
endif

EC <	call	ECCheckDriverHandle					>

	push	bx
	call	GeodeAccessCoreBlock
	mov	si,ds:[GH_driverTabOff]
	mov	ds,ds:[GH_driverTabSegment]	;ds = segment
	pop	bx
	call	NearUnlock
	ret

GeodeInfoDriver	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	GeodeGetUIData

DESCRIPTION:	Return UI data for process

CALLED BY:	GLOBAL

PASS:
	bx - process ID (or 0 for current process)

RETURN:
	bx - UI data

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version
	Don	10/90		Use common call to get segment address

------------------------------------------------------------------------------@

GeodeGetUIData	proc	far
	push	ds

	call	GeodeAccessCoreBlock		; process segment => DS
	mov	bx, ds:[PH_uiData]		; data => BX
	jmp	unlock_popDS_ret

GeodeGetUIData	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	GeodeSetUIData

DESCRIPTION:	Set UI data for process

CALLED BY:	GLOBAL

PASS:
	ax - UI data
	bx - process ID (or 0 for current process)

RETURN:
	bx - process ID

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version
	Don	10/90		Use common call to get segment address

------------------------------------------------------------------------------@

GeodeSetUIData	proc	far
	push	ds

	call	GeodeAccessCoreBlock		; process segment => DS
	mov	ds:[PH_uiData], ax
	jmp	unlock_popDS_ret

GeodeSetUIData	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	GeodeGetResourceHandle

DESCRIPTION:	Return information about a resource

CALLED BY:	GLOBAL

PASS:
	bx - resource ID

RETURN:
	bx - resource handle

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version

------------------------------------------------------------------------------@

GeodeGetResourceHandle	proc	far	uses ax
	.enter

	clr	ax
	xchg	ax, bx				;ax = res id, bx = core
	call	GeodeGetGeodeResourceHandle

	.leave
	ret

GeodeGetResourceHandle	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	GeodeGetGeodeResourceHandle

DESCRIPTION:	Return information about a resource for a specific geode

CALLED BY:	GLOBAL

PASS:
	ax - resource ID
	bx - geode handle 

RETURN:
	bx - resource handle

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	1/90		Initial version

------------------------------------------------------------------------------@

GeodeGetGeodeResourceHandle	proc	far
	push	ds
	call	GeodeAccessCoreBlock
EC <	cmp	ax, ds:[GH_resCount]					>
EC <	ERROR_AE ILLEGAL_RESOURCE					>
	shl	ax				; ax <= resid * 2
	add	ax, ds:[GH_resHandleOff]	; Offset into table
	xchg	ax, bx				; ax = core block, bx = index
	mov	bx, ds:[bx]			; bx = resource handle

	jmp	unlock_popDS_ret

GeodeGetGeodeResourceHandle	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	ThreadGetDGroupDS

DESCRIPTION:	Load DS with the current thread's dgroup

CALLED BY:	GLOBAL

PASS:
	none

RETURN:
	ds - dgroup

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/91		Initial version

------------------------------------------------------------------------------@

ThreadGetDGroupDS	proc	far
	mov	ds, ss:[TPD_dgroup]
	ret

ThreadGetDGroupDS	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GeodeLoadDGroup

C DECLARATION:	extern void
			GeodeLoadDGroup(MemHandle mh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
	SetGeosConvention
GEODELOADDGROUP	proc	far	; mh:hptr
	C_GetOneWordArg	bx,   ax,cx		;bx = handle

	tst	bx
	jnz	handlePassed
	mov	ds, ss:[TPD_dgroup]
	ret
handlePassed:
	FALL_THRU	GeodeGetDGroupDS

GEODELOADDGROUP	endp
	SetDefaultConvention

COMMENT @----------------------------------------------------------------------

FUNCTION:	GeodeGetDGroupDS

DESCRIPTION:	Get dgroup in DS

CALLED BY:	GLOBAL

PASS:
	bx - memory handle owned by geode to get dgroup for

RETURN:
	ds - dgroup

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	1/90		Initial version

------------------------------------------------------------------------------@

GeodeGetDGroupDS	proc	far	uses ax, bx
	.enter
	call	MemOwner			;bx <- owner
	mov	ax, 1				;res id of dgroup
	call	GeodeGetGeodeResourceHandle
	call	MemDerefDS

	.leave
	ret

GeodeGetDGroupDS	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	GeodeGetDGroupES

DESCRIPTION:	Get dgroup in ES

CALLED BY:	GLOBAL

PASS:
	bx - memory handle owned by geode to get dgroup for

RETURN:
	es - dgroup

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	1/90		Initial version

------------------------------------------------------------------------------@

GeodeGetDGroupES	proc	far	uses ax, bx
	.enter
	call	MemOwner			;bx <- owner
	mov	ax, 1				;res id of dgroup
	call	GeodeGetGeodeResourceHandle
	call	MemDerefES

	.leave
	ret

GeodeGetDGroupES	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	GeodeGetAppObject

DESCRIPTION:	Return the optr of the appObject for a given process

CALLED BY:	GLOBAL

PASS:
	bx - process to get appObject for (0 for current)

RETURN:
	^lbx:si - appObject

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version
	Don	10/90		Use common call to get segment address

------------------------------------------------------------------------------@

GeodeGetAppObject	proc	far
	push	ds
	
	; Just look into the process' header
	;
	call	GeodeAccessCoreBlock		; process segment => DS
	mov	bx, ds:[PH_appObject].handle
	mov	si, ds:[PH_appObject].chunk
	jmp	unlock_popDS_ret

GeodeGetAppObject	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	GeodeLockCoreBlock

DESCRIPTION:	Lock the core block of the current process

CALLED BY:	INTERNAL

PASS:
	none

RETURN:
	ds - core block (locked)
	bx - core block

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version

------------------------------------------------------------------------------@

GeodeLockCoreBlock	proc	near
	clr	bx
	FALL_THRU	GeodeAccessCoreBlock

GeodeLockCoreBlock	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	GeodeAccessCoreBlock

DESCRIPTION:	Return the segment of the process core block

CALLED BY:	INTERNAL

PASS:
	bx - process to access (0 for current)

RETURN:
	bx - handle of core block (locked)
	ds - segment of process' core block

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/90		Initial version

------------------------------------------------------------------------------@

GeodeAccessCoreBlock	proc	near	uses ax
	.enter

	; use current process if none passed
	;
	tst	bx				; process handle passed ?
	jnz	getAddress			; yes, so use it
	mov	bx, ss:[TPD_processHandle]	; else get the current process
getAddress:
EC <	call	ECCheckGeodeHandle		; verify the handle	>
	call	NearLockDS

	.leave
	ret
GeodeAccessCoreBlock	endp
