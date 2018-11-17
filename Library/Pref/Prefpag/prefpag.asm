COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Pager
FILE:		prefpag.asm

AUTHOR:		Jennifer Wu, Mar 10, 1993

ROUTINES:
	Name			Description
	----			-----------
	PrefPagGetPrefUITree	Return the root of the UI tree for "Preferences"
	PrefPagGetModuleInfo	Fill in the PrefModuleInfo buffer so that
				PrefMgr can decide whether to show this button.
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	3/10/93		Initial revision

DESCRIPTION:
	

	$Id: prefpag.asm,v 1.1 97/04/05 01:29:41 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


;-----------------------------------------------------------------------------
;	CODE		
;-----------------------------------------------------------------------------

PrefPagCode	segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefPagGetPrefUITree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the root of the UI tree for "Preferences"

CALLED BY:	PrefMgr

PASS:		nothing

RETURN:		dx:ax	= OD of root of tree

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	3/10/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefPagGetPrefUITree	proc	far
		mov	dx, handle PrefPagRoot
		mov	ax, offset PrefPagRoot
		ret
PrefPagGetPrefUITree	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefPagGetModuleInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fill in the PrefModuleInfo buffer so that PrefMgr 
		can decide whether to show this button.

CALLED BY:	PrefMgr

PASS:		ds:si	= PrefModuleInfo structure to be filled in

RETURN:		ds:si	= buffer filled in

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	3/10/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefPagGetModuleInfo	proc	far
	uses	ax,bx
	.enter

	clr	ax
		
	mov	ds:[si].PMI_requiredFeatures, mask PMF_USER
	mov	ds:[si].PMI_prohibitedFeatures, ax
	mov	ds:[si].PMI_minLevel, ax
	mov	ds:[si].PMI_maxLevel, UIInterfaceLevel-1
	mov	ds:[si].PMI_monikerList.handle, handle PrefPagMonikerList
	mov	ds:[si].PMI_monikerList.offset, offset PrefPagMonikerList
 	mov	{word} ds:[si].PMI_monikerToken,  'P' or ('F' shl 8)
	mov	{word} ds:[si].PMI_monikerToken+2, 'P' or ('G' shl 8)
	mov	{word} ds:[si].PMI_monikerToken+4, MANUFACTURER_ID_APP_LOCAL 

	.leave
	ret
PrefPagGetModuleInfo	endp

;;-------------------------------------------------------------------------
;;		Implementation for PrefPagDialog class
;;-------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefPagDialogOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Intercepted to initialize whatever needs to be initialized
		when the dialog is opened.

CALLED BY:	MSG_VIS_OPEN
PASS:		*ds:si	= PrefPagDialogClass object
		ds:di	= PrefPagDialogClass instance data
		es 	= segment of PrefPagDialogClass
		ax	= message #
		bp	= 0 if top window, else window for object to open on
		
RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JW	3/18/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefPagDialogOpen	method dynamic PrefPagDialogClass, 
					MSG_VIS_OPEN
	uses	di,si
	.enter
	;
	; First pass the message on to our superclass.
	;
		mov	di, offset PrefPagDialogClass
		call	ObjCallSuperNoLock
	;
	; Initialize the installed list.
	;
		mov	si, offset PrefPagInstalledList
		mov	ax, MSG_PREF_PAG_INSTALLED_LIST_BUILD_ARRAY
		call	ObjCallInstanceNoLock
	;
	; Initialize the application list.
	;
		mov	si, offset PrefPagAppList
		mov	ax, MSG_PREF_PAG_APP_LIST_BUILD_ARRAY
		call	ObjCallInstanceNoLock
	;
	; Set the used ports.
	;
		call	SetUsedPorts
	.leave
	ret
PrefPagDialogOpen	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefPagDialogClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Accepted to send out IACP notification to pager watcher to
		update notification preferences.  

CALLED BY:	MSG_VIS_CLOSE
PASS:		*ds:si	= PrefPagDialogClass object
		ds:di	= PrefPagDialogClass instance data
		ds:bx	= PrefPagDialogClass object (same as *ds:si)
		es 	= segment of PrefPagDialogClass
		ax	= message #

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
		allowed: bx, si, di, ds
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JW	4/ 7/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefPagDialogClose	method dynamic PrefPagDialogClass, 
					MSG_VIS_CLOSE
	;
	; First pass the message on to our superclass.
	;
		mov	di, offset PrefPagDialogClass
		call	ObjCallSuperNoLock	; destroys ax, cx, dx, bp
	;
	; Make sure any open VM files used by the PrefContainer 
	; are closed.
	;
		mov	ax, MSG_PREF_NOTIFY_DIALOG_CHANGE
		mov	cx, PDCT_SHUTDOWN	
		mov	si, offset PrefPagConfigContainer
		call	ObjCallInstanceNoLock
	;
	; Disable the change interaction so that when we open again,
	; the user won't be able to use it.  
	;
		mov	si, offset PrefPagChangeInteraction
		mov	ax, MSG_GEN_SET_NOT_ENABLED
		mov	dl, VUM_NOW
		call	ObjCallInstanceNoLock
	;
	; Check if there any installed pagers.  We don't want to start
	; up the watcher if there are no pagers installed.
	;
		mov	si, offset PrefPagInstalledList
		mov	ax, MSG_PREF_PAG_DYNAMIC_LIST_GET_ARRAY
		call	ObjCallInstanceNoLock	; *ds:ax <- the array

		mov	si, ax			; *ds:si <- the array
		call	ChunkArrayGetCount	; cx <- # of elements
		jcxz	done
	;
	; Use IACP to send a message to the watcher to update notification
	; preferences.  (Things may or may not have changed.)
	;
		segmov	ds, cs, ax
		mov	di, offset watcherToken
		mov	ax, MSG_PAGER_WATCHER_UPDATE_NOTIFICATION
		clr	bx			; no completion msg
		mov	si, MSG_GEN_PROCESS_OPEN_APPLICATION
		call	IACP_SimpleConnectAndSend
done:	
	ret
PrefPagDialogClose	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefPagRemovePager
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Removes the selected pager from list of installed pagers
		in the INI file and updates the dynamic list, internally
		and visually.  Notifies the watcher of the removed pager.

CALLED BY:	MSG_PREF_PAG_REMOVE_PAGER
PASS:		*ds:si	= PrefPagDialogClass object
		
RETURN:		nothing
		
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JW	3/17/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefPagRemovePager	method dynamic PrefPagDialogClass, 
					MSG_PREF_PAG_REMOVE_PAGER
	uses	di, si
	.enter	
	;
	; Was anything selected?
	;
		mov	si, offset PrefPagInstalledList
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjCallInstanceNoLock

		tst	ax			; ax = selection
		js	noSelection
	;
	; Get the name of the pager that was selected.
	;
		mov	dx, ax			; dx <- selection
		mov	ax, MSG_PREF_PAG_DYNAMIC_LIST_GET_ITEM
		call	ObjCallInstanceNoLock	; cx:dx <- asciiZ pager name
						; ax <- item #
EC	<	mov	di, ds					>
EC	< 	cmp	di, cx					>		
EC	< ERROR_NE	BLOCK_MOVED_WHEN_IT_SHOULD_NOT_HAVE	>		

		mov	si, dx			; ds:si <- pager name
	;
	; Free the port that was used by the pager.
	;
		call	ResetUsedPort
	;
	; Remove the category for this pager from the INI file.
	;
		call	InitFileDeleteCategory
	;
	; Remove the selected item from the list of devices in the INI file.
	;
		push	ds
		segmov	ds, cs, cx
		mov	si, offset pagerCategoryString
		mov	dx, offset devicesKeyString
		call	InitFileDeleteStringSection
		pop	ds
	
EC	< ERROR_C	CANNOT_REMOVE_A_PAGER_THAT_IS_NOT_INSTALLED	>

	;
	; Remove the selected item from the list of installed pagers.
	;
		mov	dx, ax			; dx <- the selection
		mov	si, offset PrefPagInstalledList
		mov	ax, MSG_PREF_PAG_DYNAMIC_LIST_DELETE_ITEM
		call	ObjCallInstanceNoLock	
	;
	; Notify the watcher of the change.
	;
		call	PrefPagNotifyPagerWatcherPagerRemoved
done:
	.leave
	ret

noSelection:
		mov	si, offset PrefPagRemoveErrorBox
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		call	ObjCallInstanceNoLock
		
		jmp	short done

PrefPagRemovePager	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefPagAddPager
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notifies the watcher that a new pager has been added.
		Updates InstalledList onscreen and internally.

CALLED BY:	MSG_PREF_PAG_ADD_PAGER
PASS:		*ds:si	= PrefPagDialogClass object
		ds:di	= PrefPagDialogClass instance data
		
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JW	3/18/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefPagAddPager	method dynamic PrefPagDialogClass, 
					MSG_PREF_PAG_ADD_PAGER
pagerName	local	PAGER_NAME_LENGTH	dup (byte)
appName		local	APPLICATION_NAME_LENGTH	dup (byte)
portName	local	PORT_NAME_LENGTH	dup (byte)
		uses 	bx,di,si,es
		.enter
	;
	; Was a pager selected?
	;
		push	bp
		mov	si, offset PrefPagDeviceList
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjCallInstanceNoLock
		pop	bp
		
		tst	ax
		LONG	js	badSelection
	;
	; Get the moniker of the selected pager.
	;
		push	bp
		mov	cx, ss
		mov	dx, bp
		add	dx, offset pagerName		; cx:dx = buffer for name
		mov	bp, PAGER_NAME_LENGTH		; bp <- size of buffer
		mov	si, offset PrefPagDeviceList
		mov	ax, MSG_PREF_ITEM_GROUP_GET_SELECTED_ITEM_TEXT
		call	ObjCallInstanceNoLock

EC <		tst	bp						>
EC < 		ERROR_Z	CANNOT_GET_PAGER_NAME_FROM_LIST			>

	;
	; Was an application selected?
	;
		mov	si, offset PrefPagAppList
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjCallInstanceNoLock		; ax <- the selection
		pop	bp

		tst	ax
		LONG	js	badSelection		; no application selected
	;
	; Get the name of the application.
	;
		mov	dx, ax				; the selected item
		mov	ax, MSG_PREF_PAG_DYNAMIC_LIST_GET_ITEM
		call	ObjCallInstanceNoLock		; cx:dx <- string name

EC	<	mov	di, ds					>
EC	<	cmp	di, cx					>
EC	< ERROR_NE	BLOCK_MOVED_WHEN_IT_SHOULD_NOT_HAVE	>
	
	;
	; Place the name of the application on the stack.
	;		
		mov	si, dx				; ds:si <- string name
		segmov	es, ss, ax
		mov	di, bp
		add	di, offset appName		; es:di <- loc on stack
		mov	cx, APPLICATION_NAME_LENGTH
		rep	movsb
	;
	; Was a port selected?
	;
		push	bp
		mov	si, offset PrefPagPortList
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjCallInstanceNoLock		; ax <- the selection
		pop	bp

		tst	ax				
		LONG	js	badSelection		; nothing selected
	;
	; Disable the selected port so the user can't select it again.
	; The offset of the port object is already in ax because of the
	; way the identifiers were set up.
	;
		push	bp
		mov	si, ax
		mov	dl, VUM_MANUAL			; window is closing so
		mov	ax, MSG_GEN_SET_NOT_ENABLED	; point in updating now
		call	ObjCallInstanceNoLock
		pop	bp				; need to use it
	;	
	; Get the name of the port.
	;
		push	bp				; save it again
		mov	cx, ss
		mov	dx, bp
		add	dx, offset portName		; cx:dx = buffer
		mov	bp, PORT_NAME_LENGTH		; bp <- size of buffer
		mov	ax, MSG_PREF_ITEM_GROUP_GET_SELECTED_ITEM_TEXT
		mov	si, offset PrefPagPortList
		call	ObjCallInstanceNoLock

EC <		tst	bp						>
EC < 		ERROR_Z	CANNOT_GET_PORT_NAME_FROM_LIST			>
	
	;
	; Make the PortList have no selection so that the next "add" won't
	; select the same port.
	;
		mov	si, offset PrefPagPortList
		clr	dx
		mov	ax, MSG_GEN_ITEM_GROUP_SET_NONE_SELECTED
		call	ObjCallInstanceNoLock
		pop	bp
	;
	; Append pager to devices list in INI file.
	;
		mov	bx, ds				; save ds in bx
		segmov	ds, cs, cx
		mov	si, offset pagerCategoryString
		mov	dx, offset devicesKeyString
		segmov	es, ss, ax
		mov	di, bp
		add	di, offset pagerName		; es:di=asciiZ pager name
		call	InitFileWriteStringSection
	;
	; Write the application's name under the category for the selected pager.
	;
		segmov	ds, es, ax
		mov	si, di				; ds:si = pager name
		mov	dx, offset applicationKeyString	; cx:dx = key string
		mov	di, bp
		add	di, offset appName		; es:di= asciiz app name
		call	InitFileWriteString
	;
	; Now write the port's name under the same category.
	;
		mov	dx, offset portKeyString	; cx:dx = key string
		mov	di, bp
		add	di, offset portName		; es:di=asciiz port name
		call	InitFileWriteString
	;
	; Set INI category of PrefPagDeviceList to the selected pager.
	;
		mov	cx, ds
		mov	dx, si				; cx:dx = pager name
		push	cx, dx				; save name of pager
		push	bp
		mov	ds, bx				; ds <- dgroup again
		mov	ax, MSG_PREF_SET_INIT_FILE_CATEGORY
		mov	si, offset PrefPagDeviceList
		call	ObjCallInstanceNoLock
	;
	; Pass MSG_META_SAVE_OPTIONS to PrefPagDeviceList so that it will
	; write the name of the driver to the INI file.
	;
		segmov	es, ds, bx			; es <- dgroup
		mov	ax, MSG_META_SAVE_OPTIONS
		call	ObjCallInstanceNoLock
		pop	bp
		pop	cx, dx				; restore name of pager
	;
	; Finally, add the new pager to the list of installed devices.
	;
		mov	si, offset PrefPagInstalledList
		mov	ax, MSG_PREF_PAG_DYNAMIC_LIST_ADD_ITEM
		call	ObjCallInstanceNoLock
	;
	; Notify the watcher of the change.
	;
		call	PrefPagNotifyPagerWatcherPagerAdded
done:		
		.leave					
		ret
badSelection:
	;
	; Put up dialog box telling user that the pager cannot be added
	; because something was not selected.
	;
		push	bp
		mov	si, offset PrefPagErrorBox
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		call	ObjCallInstanceNoLock
		pop	bp
		jmp	short done

PrefPagAddPager	endm

;;--------------------------------------------------------------------------
;;		Implementation of PrefPagDynamicList class
;;--------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefPagInstalledListBuildArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the installed list to contain the names of
		all currently installed devices.

CALLED BY:	MSG_PREF_PAG_INSTALLED_LIST_BUILD_ARRAY
PASS:		*ds:si	= PrefPagDynamicListClass object

RETURN:		nothing
		
DESTROYED:	nothing
		
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JW	3/18/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefPagInstalledListBuildArray	method dynamic PrefPagDynamicListClass, 
					MSG_PREF_PAG_INSTALLED_LIST_BUILD_ARRAY
	uses	ax,cx,dx,di,bp
	.enter
		mov	bp, si			; save si
	;
	; Build the array.
	;
		mov	dx, offset devicesKeyString
		call	BuildArray		; *ds:si<-array, cx<- numItems
	;
	; Save the handle to the chunk array.
	;
		mov	di, ds:[bp]
		add	di, ds:[di].PrefPagDynamicList_offset
		mov	ds:[di].PPDLI_array, si
	;
	; Initialize the PrefPagInstalledList.
	;
		mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
		mov	si, bp
		call	ObjCallInstanceNoLock
	.leave
	ret
PrefPagInstalledListBuildArray	endm
		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefPagAppListBuildArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the application list to contain the names of
		all applications that can be notified by the watcher.

CALLED BY:	MSG_PREF_PAG_APP_LIST_BUILD_ARRAY
PASS:		*ds:si	= PrefPagDynamicListClass object

RETURN:		nothing
		
DESTROYED:	nothing
		
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JW	3/18/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefPagAppListBuildArray	method dynamic PrefPagDynamicListClass, 
					MSG_PREF_PAG_APP_LIST_BUILD_ARRAY
	uses	ax,cx,dx,di,bp
	.enter
		mov	bp, si			; save si
	;
	; Build the array.
	;
		mov	dx, offset appListKeyString
		call	BuildArray		; *ds:si <- array, cx = numItems
	;
	; Save handle to chunk array.
	;
		mov	di, ds:[bp]
		add	di, ds:[di].PrefPagDynamicList_offset
		mov	ds:[di].PPDLI_array, si
	;
	; Initialize the PagAppList.
	;
		mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
		mov	si, bp
		call	ObjCallInstanceNoLock
		
	.leave
	ret
PrefPagAppListBuildArray	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefPagGetInstalledListMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The message used to query the installed list for item
		monikers.

CALLED BY:	MSG_PREF_PAG_GET_INSTALLED_LIST_MONIKER
PASS:		*ds:si	= PrefPagDynamicListClass object
		ds:di	= PrefPagDynamicListClass instance data
		bp	= the position of the item requested
		
RETURN:		nothing
		
DESTROYED:	ax, cx, dx, bp
		
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Very lame hack for creating the text string for the moniker:
			Get device name.
			Append " on ".
			Append port name.
			Append " to ".
			Append application name.
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JW	3/18/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefPagGetInstalledListMoniker	method dynamic PrefPagDynamicListClass, 
					MSG_PREF_PAG_GET_INSTALLED_LIST_MONIKER
itemMoniker	local MONIKER_STRING_LENGTH	dup (byte)
 	uses	bx,di,es

		.enter
		push	bp		
		push 	ds,si			; save the list
	;
	; Get the device name.
	;
		mov	ax, ss:[bp]		; ax <- item position
		mov	si, ds:[di].PPDLI_array
		call	ChunkArrayElementToPtr	; ds:di <- device name
						; cx <- length
		dec	cx			; discard null terminator
		mov	si, di			; ds:si <- device name

EC	< ERROR_C	ITEM_NOT_IN_CHUNK_ARRAY			>
	
	;
	; Copy device name to the itemMoniker string.
	;
		push	ds, si			; save device name
		segmov	es, ss, bx
		mov	di, bp
		add	di, offset itemMoniker	; es:di <- buffer for moniker
		rep	movsb
	;
	; Append " on " to the itemMoniker string.
	;
		segmov	ds, cs, bx
		mov	si, offset onString
		mov	cx, 4			; string length
		rep 	movsb
		pop	ds, si			; restore device name

	;
	; Append the port name to the itemMoniker string.
	;
		mov	cx, cs
		mov	dx, offset portKeyString
		mov	bp, InitFileReadFlags <IFCC_INTACT, 0,, \
						PORT_NAME_LENGTH>
		call	InitFileReadString	; cx <- # of bytes read

EC	< ERROR_C	CANNOT_READ_PORT_FOR_DEVICE		>

	;
	; Append " to " to the itemMoniker string.
	;
		push	ds, si			; save device name
		add	di, cx			; es:di <- current end of buffer
		segmov	ds, cs, bx
		mov	si, offset toString
		mov	cx, 4			; string length
		rep 	movsb
		pop	ds, si			; restore device name
	;
	; Append the application name to the itemMoniker string.
	;
		mov	cx, cs
		mov	dx, offset applicationKeyString
		mov	bp, InitFileReadFlags <IFCC_INTACT, 0,, \
						APPLICATION_NAME_LENGTH>
		call	InitFileReadString	

EC	< ERROR_C	CANNOT_READ_APPLICATION_FOR_DEVICE	>

	;
	; Pass the moniker string to the list.
	;
		pop	ds, si			; ds:si <- the list
		pop	bp
		mov	cx, ss
		mov	dx, bp
		add	dx, offset itemMoniker	; cx:dx <- itemMoniker string
		push	bp
		mov	bp, ax			; bp <- item position
		mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_TEXT
		call	ObjCallInstanceNoLock
		pop	bp
	.leave
	ret
PrefPagGetInstalledListMoniker	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefPagGetAppListMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The message used to query the installed list for item
		monikers.

CALLED BY:	MSG_PREF_PAG_GET_APP_LIST_MONIKER
PASS:		*ds:si	= PrefPagDynamicListClass object
		ds:di	= PrefPagDynamicListClass instance data
		bp	= the position of the item requested
		
RETURN:		nothing

DESTROYED:	ax, cx, dx, bp
		
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JW	3/18/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefPagGetAppListMoniker	method dynamic PrefPagDynamicListClass, 
					MSG_PREF_PAG_GET_APP_LIST_MONIKER
appName		local	APPLICATION_NAME_LENGTH		dup (byte)	
	uses	di
	.enter
	;
	; Get the string for the item.
	;
		mov	ax, ss:[bp]		; ax <- the position of the item
		mov	si, ds:[di].PPDLI_array
		call	ChunkArrayElementToPtr	; ds:di <- element, cx <- length

EC	< ERROR_C	ITEM_NOT_IN_CHUNK_ARRAY			>	
	;
	; Copy the string to the appName buffer.
	;
		mov	si, di			; ds:si <- element
		segmov	es, ss, bx
		mov	di, bp
		add	di, offset appName	; es:di <- appName buffer
		rep	movsb
	;
	; Tell the list to replace the moniker with the null terminated
	; text string.
	;
		push	bp
		mov	cx, ss
		mov	dx, bp			
		add	dx, offset appName	; cx:dx <- asciiZ appName
		mov	si, offset PrefPagAppList
		mov	bp, ax
		mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_TEXT
		call	ObjCallInstanceNoLock
		pop	bp
	.leave
	ret
PrefPagGetAppListMoniker	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefPagInstalledDeviceSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tell the PrefContainer object to open the VMfile corresponding
		to the selected device.

CALLED BY:	MSG_PREF_PAG_INSTALLED_DEVICE_SELECTED
PASS:		*ds:si	= PrefPagDynamicListClass object
		ds:di	= PrefPagDynamicListClass instance data
		cx	= current selection, or GIGS_NONE if no selection

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
		allowed: bx, di, si, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JW	5/10/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefPagInstalledDeviceSelected	method dynamic PrefPagDynamicListClass, 
					MSG_PREF_PAG_INSTALLED_DEVICE_SELECTED
driverName	local	FileLongName
matchAttrs	local	2 dup (FileExtAttrDesc)	
filePath	local	PathName	
	.enter
		cmp	cx, GIGS_NONE
		LONG	je	noSpecialPrefs
		
		push	ds			; save ds
	;
	; Get the device name.
	; 
		mov	ax, cx			; ax <- item position
		mov	si, ds:[di].PPDLI_array 
		call	ChunkArrayElementToPtr	; ds:di <- asciiz device name
	;
	; Get the driver name for the device from the INI file.
	;
		push	bp			; save bp
		mov	si, di			; ds:si <- device name
		mov	cx, cs
		mov	dx, offset driverKeyString	
		segmov	es, ss, di
		mov	di, bp
		add	di, offset driverName	
		mov	bp, InitFileReadFlags <IFCC_INTACT,,,
					       FILE_LONGNAME_BUFFER_SIZE>
		call	InitFileReadString	
		pop	bp
		pop	ds

		LONG	jc	done		; can't find driver name
						; this should never happen
	;
	; Strip off any leading "EC " from the driverName, as prefs are the
	; same for either one.
	;
		cmp	{word}ss:[driverName], 'E' or ('C' shl 8)
		jne	findFile
		cmp	ss:[driverName][2], ' '
		jne	findFile
	;
	; Shuffle the name down over top of the "EC "
	;
		push	ds, si
		lea	si, ss:[driverName][3]
		segmov	ds, ss, cx
		mov	es, cx
		lea 	di, ss:[driverName]
		mov	cx, size driverName - 3
		rep	movsb
		pop	ds, si

findFile:
	;
	; Look for a file in SP_PAGER_DRIVERS whose FEA_NOTICE attribute 
	; matches the driver longname. 
	;
		call	FilePushDir

		mov	ax, SP_PAGER_DRIVERS
		call	FileSetStandardPath
		
		mov	ss:[matchAttrs][0*FileExtAttrDesc].FEAD_attr, FEA_NOTICE
		mov	ss:[matchAttrs][0*FileExtAttrDesc].FEAD_value.segment, ss
		lea	ax, ss:[driverName]
		mov	ss:[matchAttrs][0*FileExtAttrDesc].FEAD_value.offset, ax
		mov	ss:[matchAttrs][0*FileExtAttrDesc].FEAD_size, \
			size driverName
		mov	ss:[matchAttrs][1*FileExtAttrDesc].FEAD_attr, \
			FEA_END_OF_LIST

		push	bp
		lea	ax, ss:[matchAttrs]
		sub	sp, size FileEnumParams
		mov	bp, sp
		mov	ss:[bp].FEP_searchFlags, mask FESF_GEOS_NON_EXECS or \
						 mask FESF_GEOS_EXECS
		mov	ss:[bp].FEP_returnAttrs.segment, 0
		mov	ss:[bp].FEP_returnAttrs.offset, FESRT_NAME
		mov	ss:[bp].FEP_returnSize, size FileLongName
		movdw	ss:[bp].FEP_matchAttrs, ssax
		mov	ss:[bp].FEP_bufSize, 1
		mov	ss:[bp].FEP_skipCount, 0

		call	FileEnum		
		pop	bp

		call	FilePopDir
		
		jc	noSpecialPrefs
		jcxz	noSpecialPrefs
	
	;
	; Build the full path of the file in question. 
	;
		push	bp
		push	ds
		push	bx			; save block handle of filename
		call	MemLock
		mov	ds, ax
		clr	si			; ds:si = FileLongName
		clr	dx			; don't add drive name
		mov	bx, SP_PAGER_DRIVERS
		segmov	es, ss, di
		lea	di, ss:[filePath]	; es:di = buffer for path
		mov	cx, size PathName
		call	FileConstructFullPath
		mov	cx, ss
		lea	dx, ss:[filePath]	
		mov	bp, bx			; bp <- disk handle
		pop	bx			; bx <- block handle of filename
		pop	ds		
		jc	freeFullPath
	;
	; Tell the container about it.
	;
		mov	ax, MSG_GEN_PATH_SET
		mov	si, offset PrefPagConfigContainer
		call	ObjCallInstanceNoLock
		jc	freeFullPath
	;	
	; Set the change interaction enabled.
	;
		mov	ax, MSG_GEN_SET_ENABLED
		mov	dl, VUM_NOW
		mov	si, offset PrefPagChangeInteraction
		call	ObjCallInstanceNoLock
		clc
freeFullPath:	
	;
	; Free the full-path block.
	;
		lahf
		call	MemFree
		sahf
		pop	bp
		jc	noSpecialPrefs	; => path set was bad, so make sure
					; change intereaction is disabled
done:	
	.leave
	ret
noSpecialPrefs:
	;
	; Set the change interaction not enabled.
	;
		mov	ax, MSG_GEN_SET_NOT_ENABLED
		mov	dl, VUM_NOW
		mov	si, offset PrefPagChangeInteraction
		call	ObjCallInstanceNoLock
			
		jmp	short done
		

PrefPagInstalledDeviceSelected	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefPagDynamicListGetArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the array of data for the list.

CALLED BY:	MSG_PREF_PAG_DYNAMIC_LIST_GET_ARRAY
PASS:		*ds:si	= PrefPagDynamicListClass object
		ds:di	= PrefPagDynamicListClass instance data

RETURN:		*ds:ax  = the array
		
DESTROYED:	nothing
		
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JW	3/18/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefPagDynamicListGetArray	method dynamic PrefPagDynamicListClass, 
					MSG_PREF_PAG_DYNAMIC_LIST_GET_ARRAY
		mov	ax, ds:[di].PPDLI_array
		ret
PrefPagDynamicListGetArray	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefPagDynamicListGetItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the specified item from the list.	

CALLED BY:	MSG_PREF_PAG_DYNAMIC_LIST_GET_ITEM
PASS:		*ds:si	= PrefPagDynamicListClass object
		ds:di	= PrefPagDynamicListClass instance data
		dx	= the number of the item to get

RETURN:		cx:dx	= element
		ax	= the item number of the element

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JW	3/19/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefPagDynamicListGetItem	method dynamic PrefPagDynamicListClass, 
					MSG_PREF_PAG_DYNAMIC_LIST_GET_ITEM
	uses	di,si
	.enter
		mov	si, ds:[di].PPDLI_array	; *ds:si <- the array
		mov	ax, dx			; ax <- the selection
		call	ChunkArrayElementToPtr	; ds:di <- the element
		mov	dx, di			
		mov	cx, ds			; cx:dx <- the element
	
EC	< ERROR_C	ITEM_NOT_IN_CHUNK_ARRAY			>

	.leave
	ret
PrefPagDynamicListGetItem	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefPagDynamicListDeleteItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove an item from the list, internally and visually.

CALLED BY:	MSG_PREF_PAG_DYNAMIC_LIST_DELETE_ITEM
PASS:		*ds:si	= PrefPagDynamicListClass object
		ds:di	= PrefPagDynamicListClass instance data
		dx	= the item to be removed

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JW	3/19/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefPagDynamicListDeleteItem	method dynamic PrefPagDynamicListClass, 
					MSG_PREF_PAG_DYNAMIC_LIST_DELETE_ITEM
		uses	ax, cx, dx, bp, ds
		.enter
	;
	; Delete the item from the array of data for the list.
	;
		mov	bp, si				; save si in bp
		mov	si, ds:[di].PPDLI_array		; *ds:si <- the array
		mov	ax, dx				; ax <- the selection
		mov	cx, 1				; just delete 1
		call	ChunkArrayDeleteRange
	;
	; Update the list visually.
	;
		mov	si, bp				; restore si from bp
		xchg	dx, cx			; dx <- 1, cx <- the selection
		mov	ax, MSG_GEN_DYNAMIC_LIST_REMOVE_ITEMS
		call	ObjCallInstanceNoLock
		.leave
		ret

PrefPagDynamicListDeleteItem	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefPagDynamicListAddItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add the item to the list internally and visually.	

CALLED BY:	MSG_PREF_PAG_DYNAMIC_LIST_ADD_ITEM
PASS:		*ds:si	= PrefPagDynamicListClass object
		ds:di	= PrefPagDynamicListClass instance data
		cx:dx	= asciiZ string to be added

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JW	3/19/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefPagDynamicListAddItem	method dynamic PrefPagDynamicListClass, 
					MSG_PREF_PAG_DYNAMIC_LIST_ADD_ITEM
	uses	ax,cx,dx,di,si,bp,es
	.enter
		push	cx, dx			; save string
		mov	bp, si			; save si in bp
	;
	; Get the length of the passed string, including the null terminator.
	;
		mov	es, cx
		mov	di, dx			; es:di = the string
		clr	al
		mov	cx, -1
		repne	scasb
		not	cx			; cx <- the length (including
	;
	; Append a new item to the array for the list.
	;
		mov	di, ds:[si]
		add	di, ds:[di].PrefPagDynamicList_offset
		mov	si, ds:[di].PPDLI_array	; *ds:si <- the array
		mov	ax, cx			; ax <- string length
		call	ChunkArrayAppend	; ds:di <- new element
	;
	; Copy the string to the new element.
	;
		segmov	es, ds, dx		; es:di <- the new element
		pop	ds, si			; ds:si <- the string
		rep	movsb
	;
	; Update the list visually.
	;
		segmov	ds, es, ax		
		mov	si, bp			; *ds:si <- the list
		mov	cx, GDLP_LAST		; add at end
		mov	dx, 1			; just add 1
		mov	ax, MSG_GEN_DYNAMIC_LIST_ADD_ITEMS
		call 	ObjCallInstanceNoLock
	.leave
	ret
PrefPagDynamicListAddItem	endm

;;------------------------------------------------------------------------
;;		Procedures
;;------------------------------------------------------------------------

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BuildArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Build the chunk array for the given list.

CALLED BY:	PrefPagInstalledListBuildArray, PrefPagAppListBuildArray

PASS:		dx 	= offset to asciiZ key string

RETURN:		*ds:si	= chunk array
		cx	= number of items in the chunk array

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	3/17/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BuildArray	proc	near
	uses	ax,bx
	.enter
	;
	; Create the chunk array.
	;
		clr	ax, bx, cx, si	; variable sized, default header, alloc
					; a chunk handle, no ObjChunkFlags set
		call	ChunkArrayCreate	; *ds:si <- array
	;
	; Get the items and put them in the chunk array.
	;
		call	PrefPagGetItems		; *ds:si = chunk array
	;
	; Get the number of items in the chunk array.
	;
		call	ChunkArrayGetCount	; cx <- number of items

	.leave
	ret
BuildArray	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefPagGetItems
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the items to be put in the chunk array from the
		specified key under the pager category in the INI file.

CALLED BY:	BuildArray

PASS:		*ds:si 	= chunk array 
		dx	= offset to asciiZ key string

RETURN:		*ds:si	= chunk array

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	3/16/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefPagGetItems		proc	near
	uses	ax,bx,cx,di,bp,es
	.enter
	;
	; Read the names of the items from the INI file.
	;
		segmov	es, ds, bx
		mov	bx, si		; *es:bx = chunk array for callback proc
		segmov	ds, cs, cx
		mov	si, offset pagerCategoryString
		mov	bp, InitFileReadFlags< IFCC_INTACT, 0,1,0>
		mov	di, cx
		mov	ax, offset BuildArrayCallBack	; di:ax = callback proc
		call	InitFileEnumStringSection

		segmov	ds, es, ax
		mov	si, bx				; *ds:si = chunk array

	.leave
	ret
PrefPagGetItems	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BuildArrayCallBack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine to insert passed string into a chunk array.

CALLED BY:	PrefPagGetItems via InitFileEnumStringSection

PASS:		ds:si	= string section (null-terminated)
		cx	= length of section
		*es:bx	= chunk array 

RETURN:		*es:bx	= chunk array

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	3/16/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BuildArrayCallBack	proc	far
	uses	ax,cx,dx,ds
	.enter
		push	bx			; save chunk array handle
		push	ds, si			; save string section
	;
	; Append the string to the chunk array.
	;
		segmov	ds, es, ax
		mov	si, bx			; *ds:si = chunk array
		mov	ax, cx			; size of string
		inc	ax			; for null terminator
		call	ChunkArrayAppend	; ds:di <- new element
	;
	; Copy the string section to the new element.
	;
		segmov	es, ds, ax		; es:di = new element
		pop	ds, si			; ds:si = string section
		rep	movsb
		
		pop	bx			; *es:bx = chunk array again
	.leave
	ret
BuildArrayCallBack	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResetUsedPort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the port used by the given pager and make it usable.

CALLED BY:	PrefPagRemovePager

PASS:		ds:si 	= asciiZ pager name

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	3/19/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResetUsedPort	proc	near
	uses	ax,bx,cx,dx,si,bp
	.enter
	;
	; Get the name of the port that this pager used.
	;
		mov	cx, cs
		mov	dx, offset portKeyString
		mov	bp, InitFileReadFlags <IFCC_INTACT, 0,,0>
		call	InitFileReadString	; bx <- block for port name

EC	< ERROR_C	CANNOT_READ_PORT_FOR_DEVICE		>		
		
	;
	; Find the port with this name.
	;
		call	MemLock			; ax <- address of port name

		push	ds			; save ds
		mov	ds, ax
		clr	si			; ds:si = port name
		call	FindPort		; si <- offset to port object
		pop	ds			
		
EC	< ERROR_C	INVALID_PORT_NAME			>
		
		call	MemFree
	;
	; Enable the port. (ds:si = the port object).
	;
		mov	dl, VUM_MANUAL		; dialog will close so no point
		mov	ax, MSG_GEN_SET_ENABLED ; in updating it on screen
		call	ObjCallInstanceNoLock
	.leave
	ret
ResetUsedPort	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindPort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the port with the given string as it's moniker.

CALLED BY:	ResetUsedPort

PASS:		ds:si	= asciiZ port name

RETURN:		carry clear if successful
			si	= offset to the port object if found
		else carry set

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	3/19/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindPort	proc	near
	uses	bx,cx,di,es
	.enter

		segmov	es, cs, cx
		mov	bx, 12
	;
	; Find the matching string.
	;
findPortLoop:
		push	si			; save start of port name
		mov	di, cs:portStringOffsetTable[bx]
		mov	cx, 4			; length of strings
		repe	cmpsb			
		pop	si			; restore start of port name
		jz	foundPort
		sub	bx, 2
		jns 	findPortLoop		; keep looking

		stc
		jmp	short done
foundPort:
		mov	si, cs:portOffsetTable[bx]
		clc
done:		
		.leave
	ret

portStringOffsetTable		word \
		offset Lpt1String,	; 0
		offset Lpt2String,	; 2
		offset Lpt3String,	; 4
		offset Com1String,	; 6
		offset Com2String,	; 8
		offset Com3String,	; 10
		offset Com4String	; 12
		
portOffsetTable			word \
		offset Lpt1Item,	; 0
		offset Lpt2Item,	; 2
		offset Lpt3Item,	; 4
		offset Com1Item,	; 6
		offset Com2Item,	; 8
		offset Com3Item,	; 10
		offset Com4Item		; 12

FindPort	endp

Lpt1String	char	"LPT1"
Lpt2String	char	"LPT2"
Lpt3String 	char 	"LPT3"
Com1String	char	"COM1"
Com2String	char	"COM2"
Com3String	char	"COM3"
Com4String	char	"COM4"


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetUsedPorts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Disables all used ports.

CALLED BY:	PrefPagDialogOpen

PASS: 		ds	= dgroup

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
			
REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	3/19/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetUsedPorts	proc	near
	uses	ax,bx,di,si
	.enter
	;
	; Get the array for the list of installed pagers.
	;
		mov	si, offset PrefPagInstalledList
		mov	ax, MSG_PREF_PAG_DYNAMIC_LIST_GET_ARRAY
		call	ObjCallInstanceNoLock		; *ds:ax <- the array
	;
	; Set the port for each installed pager as used.
	;
		mov	si, ax				; *ds:si <- the array
		mov	bx, cs
		mov	di, offset DisablePort		; callback routine
		call	ChunkArrayEnum		
	.leave
	ret
SetUsedPorts	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisablePort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine for disabling the port for the passed
		pager.

CALLED BY:	SetUsedPorts via ChunkArrayEnum

PASS:		ds:di	= asciiZ name of pager

RETURN: 	nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	3/19/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisablePort	proc	far
	uses	ax,bx,cx,dx,si,bp
	.enter
	;
	; Read the port name for the pager.
	;
		mov	si, di			; ds:si <- pager name
 		mov	cx, cs
		mov	dx, offset portKeyString
		mov	bp, InitFileReadFlags <IFCC_INTACT, 0,,0>
		call	InitFileReadString	; bx <- block for port name
		
EC	< ERROR_C	CANNOT_READ_PORT_FOR_DEVICE		>

	;
	; Find the port with this name.
	;
		call	MemLock			; ax <- address of port name

		push	ds			; save ds
		mov	ds, ax
		clr	si			; ds:si = port name
		call	FindPort		; si <- offset to port object
		pop	ds

EC	< ERROR_C	INVALID_PORT_NAME			>

		call	MemFree

	;
	; Disable the port (ds:si = the port object).
	;
		mov	dl, VUM_MANUAL		; dialog isn't opened yet
		mov	ax, MSG_GEN_SET_NOT_ENABLED
		call	ObjCallInstanceNoLock
	.leave
	ret
DisablePort	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefPagNotifyPagerWatcherPagerRemoved
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notifies the pager watcher that a pager has been removed.
		If there are no further installed pagers, removes the
		pager watcher from execOnStartup list in the INI file.

CALLED BY:	PrefPagRemovePager

PASS:		ds	= dgroup
		dx	= the selection that was removed

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	3/23/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefPagNotifyPagerWatcherPagerRemoved	proc	near
	uses	ax,bx,cx,di,si,ds,bp
	.enter
	;
	; Find out how many pagers are currently installed.
	;
		mov	si, offset PrefPagInstalledList
		mov	ax, MSG_PREF_PAG_DYNAMIC_LIST_GET_ARRAY
		call	ObjCallInstanceNoLock		; *ds:ax <- the array
		
		mov	si, ax				; *ds:si <- the array
		call	ChunkArrayGetCount		; cx <- # of elements
		jcxz	noMorePagers
		
continue:
	;
	; Use IACP to send a message to the watcher that a pager has been
	; removed.  The device removed is in dx already.
	;
		segmov	ds, cs, ax
		mov	di, offset watcherToken
		mov	ax, MSG_PAGER_WATCHER_DEVICE_REMOVED
		clr	bx				; no completion msg
		mov	si, MSG_GEN_PROCESS_OPEN_APPLICATION
		call	IACP_SimpleConnectAndSend
		
		.leave
		ret
noMorePagers:
	;
	; Remove the watcher from the execOnStartup list so it won't start
	; up automatically when the system is booted.
	;
		segmov	ds, cs, ax
		mov	si, offset watcherName		; ds:si <- name of app
		call	UserRemoveAutoExec
		jmp	short continue
		
PrefPagNotifyPagerWatcherPagerRemoved	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefPagNotifyPagerWatcherPagerAdded
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notifies the pager watcher that a pager has been added.
		If this is the first pager that is added, the pager watcher
		is added to the execOnStartup list in the INI file and
		the pager watcher is launched.

CALLED BY:	PrefPagAddPager

PASS:		ds	= dgroup

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	3/23/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefPagNotifyPagerWatcherPagerAdded	proc	near
	uses	ax,cx,si,ds,bp
	.enter
	;
	; Find out how many pagers are currently installed.
	;
		mov	si, offset PrefPagInstalledList
		mov	ax, MSG_PREF_PAG_DYNAMIC_LIST_GET_ARRAY
		call	ObjCallInstanceNoLock		; *ds:ax <- the array

		mov	si, ax				; *ds:si <- the array
		call	ChunkArrayGetCount		; cx <- # of elements
		
		segmov	ds, cs, si			

		cmp	cx, 1
		jne	continue
	;
	; Add the pager watcher to the execOnStartup list so that it
	; will startup automatically when the system is booted.
	;
		mov	si, offset watcherName		; ds:si <- name of app
		call	UserAddAutoExec

EC	<	mov	si, offset ECwatcherName	; ds:si = name of ec app>
EC	<	call	UserAddAutoExec						>
EC	< 	; added this so that the EC version will be written to the 	>
EC	<	;  INI file if we are running in EC mode			>

continue:
	;
	; Use IACP to send a message to the watcher that a pager has been
	; added.  
	;
		mov	di, offset watcherToken		; ds:di = GeodeToken
		mov	ax, MSG_PAGER_WATCHER_DEVICE_ADDED
		clr	bx				; no completion msg
		dec	cx		; 0 based position of pager in list
		mov	si, MSG_GEN_PROCESS_OPEN_APPLICATION
		call	IACP_SimpleConnectAndSend
		
		.leave
		ret
PrefPagNotifyPagerWatcherPagerAdded	endp


;;---------------------------------------------------------------------------
;;			Strings
;;---------------------------------------------------------------------------
pagerCategoryString		char	"pager",0
appListKeyString		char	"appList",0
devicesKeyString		char	"devices",0		
applicationKeyString		char	"application",0
portKeyString			char	"port",0
driverKeyString			char	"driver",0
		
onString			char 	" on "
toString			char	" to "
		
watcherName			char	"Pager Watcher",0
ECwatcherName			char	"EC Pager Watcher", 0

watcherToken	GeodeToken	<<'PWAT'>, MANUFACTURER_ID_GEOWORKS>

PrefPagCode	ends

