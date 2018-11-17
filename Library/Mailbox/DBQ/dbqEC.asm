COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		dbqEC.asm

AUTHOR:		Adam de Boor, Apr  7, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	4/ 7/94		Initial revision


DESCRIPTION:
	Error-checking code for the DBQ module.
		

	$Id: dbqEC.asm,v 1.1 97/04/05 01:19:40 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DBQ	segment	resource

if	ERROR_CHECK


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBQCheckQueue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure the passed file handle and VM block handle are a
		HugeArray

CALLED BY:	(INTERNAL)
PASS:		bx	= VM file handle
		di	= queue handle
RETURN:		if no error
DESTROYED:	flags
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 7/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBQCheckQueue	proc	near
		uses	ax, cx, di
		.enter
	;
	; First make sure we've got a VM file (also checks the file integrity)
	; 
		call	ECVMCheckVMFile
	;
	; Now make sure the passed handle is an allocated VM block handle and
	; its uid is that for a HugeArray directory block.
	; 
		push	di
		mov_tr	ax, di
		call	VMInfo
		ERROR_C	INVALID_DBQ_HANDLE
		cmp	di, SVMID_HA_DIR_ID
		ERROR_NE INVALID_DBQ_HANDLE
		pop	di
	;
	; Make sure the thing's actually a DBQ HugeArray
	; 
		mov	ax, di
		push	ds, bp
		call	VMLock
		mov	ds, ax
		cmp	ds:[DBQH_magic], DBQ_MAGIC_NUMBER
		ERROR_NE NOT_A_DBQ
		call	VMUnlock
		pop	ds, bp
	;
	; Finally, check the integrity of the HugeArray itself.
	; 
		call	ECCheckHugeArray
		.leave
		ret
DBQCheckQueue	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBQCheckGroupAndItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure the passed DBGroupAndItem are just that.

CALLED BY:	(INTERNAL)
PASS:		bx	= VM file handle
		dxax	= DBGroupAndItem
RETURN:		only if valid
DESTROYED:	nothing (flags destroyed)
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 7/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBQCheckGroupAndItem proc near
		uses	es, di, ax
		.enter
	;
	; Easiest is just to call DBLock on the thing -- the dbase code
	; does beaucoup error checking (everything we'd do, anyway)
	; 
		mov_tr	di, ax		; di <- item
		mov	ax, dx		; ax <- group
		call	DBLock
		call	DBUnlock
		.leave
		ret
DBQCheckGroupAndItem endp

endif	; ERROR_CHECK

DBQ	ends
