/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved
 *
 * PROJECT:	PC GEOS
 * FILE:	resource.h
 * AUTHOR:	Tony Requist: February 14, 1991
 *
 * DECLARER:	Kernel
 *
 * DESCRIPTION:
 *	This file defines driver structures and routines.
 *
 *	$Id: resource.h,v 1.1 97/04/04 15:58:18 newdeal Exp $
 *
 ***********************************************************************/

#ifndef	__RESOURCE_H
#define __RESOURCE_H

extern MemHandle	/*XXX*/
    _pascal GeodeDuplicateResource(MemHandle mh);

/***/

extern void *
    _pascal ProcGetLibraryEntry(GeodeHandle library, word entryNumber);

/***/

extern dword
    _pascal ProcCallFixedOrMovable_pascal();

extern 	dword/*XXX*/
    _cdecl ProcCallFixedOrMovable_cdecl();

/***/

extern void	/*XXX*/
    _pascal GeodeLoadDGroup(MemHandle mh);

/***/

extern optr
    _pascal GeodeGetOptrNS(optr obj);


#define GeodeGetCodeOptrNS(object) \
    ConstructOptr(GeodeGetGeodeResourceHandle(GeodeGetCodeProcessHandle(), \
					 OptrToHandle(object)), \
		  OptrToChunk(object))

extern MemHandle
    _pascal GeodeGetGeodeResourceHandle(GeodeHandle geode, word resourceID);


#ifdef __HIGHC__
pragma Alias(GeodeDuplicateResource, "GEODEDUPLICATERESOURCE");
pragma Alias(ProcGetLibraryEntry, "PROCGETLIBRARYENTRY");
pragma Alias(ProcCallFixedOrMovable_pascal, "PROCCALLFIXEDORMOVABLE_PASCAL");
pragma Alias(ProcCallFixedOrMovable_cdecl, "_ProcCallFixedOrMovable_cdecl");
pragma Alias(GeodeLoadDGroup, "GEODELOADDGROUP");
pragma Alias(GeodeGetOptrNS, "GEODEGETOPTRNS");
pragma Alias(GeodeGetGeodeResourceHandle, "GEODEGETGEODERESOURCEHANDLE");
#endif

#endif
