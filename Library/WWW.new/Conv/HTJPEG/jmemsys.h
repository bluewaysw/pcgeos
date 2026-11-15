/***********************************************************************
 *
 *	Copyright (c) Geoworks 1995 -- All Rights Reserved
 *
 * PROJECT:	  PC GEOS
 * MODULE:	  
 * FILE:	  jmemsys.h
 *
 * AUTHOR:  	  Joon Song: Oct 29, 1995
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	Joon	10/29/95   	Initial version
 *
 * DESCRIPTION:
 *	
 *
 *
 * 	$Id: jmemsys.h,v 1.1.11.5 97/11/11 10:28:35 joon Exp $
 *
 ***********************************************************************/

#ifndef _JMEMSYS_H_
#define _JMEMSYS_H_

#endif /* _JMEMSYS_H_ */
/*
 * jmemsys.h
 *
 * Copyright (C) 1992-1994, Thomas G. Lane.
 * This file is part of the Independent JPEG Group's software.
 * For conditions of distribution and use, see the accompanying README file.
 *
 * This include file defines the interface between the system-independent
 * and system-dependent portions of the JPEG memory manager.  No other
 * modules need include it.  (The system-independent portion is jmemmgr.c;
 * there are several different versions of the system-dependent portion.)
 *
 * This file works as-is for the system-dependent memory managers supplied
 * in the IJG distribution.  You may need to modify it if you write a
 * custom memory manager.  If system-dependent changes are needed in
 * this file, the best method is to #ifdef them based on a configuration
 * symbol supplied in jconfig.h, as we have done with USE_MSDOS_MEMMGR.
 */


/*
 * These two functions are used to allocate and release small chunks of
 * memory.  (Typically the total amount requested through jpeg_get_small is
 * no more than 20K or so; this will be requested in chunks of a few K each.)
 * Behavior should be the same as for the standard library functions malloc
 * and free; in particular, jpeg_get_small must return NULL on failure.
 * On most systems, these ARE malloc and free.  jpeg_free_small is passed the
 * size of the object being freed, just in case it's needed.
 * On an 80x86 machine using small-data memory model, these manage near heap.
 */

EXTERN void *jpeg_get_small(j_common_ptr cinfo, size_t sizeofobject);
EXTERN void jpeg_free_small(j_common_ptr cinfo, void * object,
			    size_t sizeofobject);

/*
 * The macro MAX_ALLOC_CHUNK designates the maximum number of bytes that may
 * be requested in a single call to jpeg_get_small.  This macro is needed
 * to model the 64Kb-segment-size limit of far addressing on 80x86 machines.
 * On those machines, we expect that jconfig.h will provide a proper value.
 * On machines with 32-bit flat address spaces, any large constant may be used.
 *
 * NB: jmemmgr.c expects that MAX_ALLOC_CHUNK will be representable as type
 * size_t and will be a multiple of sizeof(align_type).
 */

#define MAX_ALLOC_CHUNK  16384
