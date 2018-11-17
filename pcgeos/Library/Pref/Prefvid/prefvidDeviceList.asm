COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		prefvidDeviceList.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	5/ 4/93   	Initial version.

DESCRIPTION:
	

	$Id: prefvidDeviceList.asm,v 1.1 97/04/05 01:36:19 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefVidDeviceListLoadOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	- PrefVidDeviceListClass object
		ds:di	- PrefVidDeviceListClass instance data
		es	- dgroup

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	2/ 8/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


PrefVidDeviceListLoadOptions	method	dynamic	PrefVidDeviceListClass, 
					MSG_GEN_LOAD_OPTIONS

	;
	; See if the key exists in the .INI file
	;

		push	cx,dx,bp,ds,si,es
		sub	sp, GEODE_MAX_DEVICE_NAME_SIZE
		mov	di, sp
		mov	cx, ss
		mov	es, cx
		mov	ds, cx
		lea	si, ss:[bp].GOP_category
		lea	dx, ss:[bp].GOP_key
		mov	bp, GEODE_MAX_DEVICE_NAME_SIZE
		call	InitFileReadString
		lea	sp, ss:[di][GEODE_MAX_DEVICE_NAME_SIZE]
		pop	cx,dx,bp,ds,si,es
		jc	notFound
		
	;
	; Just call the superclass -- it knows what to do.
	;
		
		mov	di, offset PrefVidDeviceListClass
		GOTO	ObjCallSuperNoLock
	;----------------------------------------
		
		
notFound:
		
	;
	; There's no .INI key, so ask the driver which device it's
	; running. 
	;
		
		push	ds, si
		mov	ax, GDDT_VIDEO
		call	GeodeGetDefaultDriver
		mov_tr	bx, ax
		call	GeodeInfoDriver		; ds:si - strategy routine
		mov	bx, ds:[si].DEIS_resource  ; lmem block
						   ; containing device names
		mov	di, ds:[si].VDI_device	; current device
		call	MemLock
		mov	es, ax
		mov	bp, es:[DEIT_nameTable]
		mov	di, es:[bp][di]		; device name
		pop	ds, si
		
		mov	cx, es
		mov	dx, es:[di]
		clr	bp
		mov	ax, MSG_PREF_DYNAMIC_LIST_FIND_ITEM
		call	ObjCallInstanceNoLock
		mov_tr	cx, ax			; cx <- item #
		
	;
	; Unlock the device name block
	;
		call	MemUnlock
		
		
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		clr	dx
		GOTO	ObjCallInstanceNoLock
		
		
		
		
PrefVidDeviceListLoadOptions	endm



