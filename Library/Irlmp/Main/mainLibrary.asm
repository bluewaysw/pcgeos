COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		IrLMP Library
FILE:		mainLibrary.asm

AUTHOR:		Chung Liu, Mar 15, 1995

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/15/95   	Initial revision


DESCRIPTION:
	Library entry for IrLMP Library.
		

	$Id: mainLibrary.asm,v 1.1 97/04/05 01:08:18 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ResidentCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlmpLibraryEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Library entry routine. 

CALLED BY:	(GLOBAL) Kernel
PASS:		di	= LibraryCallType
		cx	= handle of client geode, if LCT_NEW_CLIENT,
			  or LCT_CLIENT_EXIT.
RETURN:		carry clear
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	LCT_DETACH:
		Send MSG_META_DETACH to process thread, so it knows to exit.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/10/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlmpLibraryEntry	proc	far
	cmp	di, LCT_ATTACH
	je	attach
	cmp	di, LCT_DETACH
	je	detach
done:
	clc
	ret

attach:
	call	IrdbOpenDatabase
	call	IrlmpAllocRegisterSem
	jmp	done

detach:
	call	IrdbCloseDatabase
	call	IrdbDestroyDatabase
	call	IrlmpFreeRegisterSem
	jmp	done
IrlmpLibraryEntry	endp
	
public	IrlmpLibraryEntry

ResidentCode	ends

