/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved
 *
 * PROJECT:	PC GEOS
 * FILE:	dbase.h
 * AUTHOR:	Tony Requist: February 14, 1991
 *
 * DECLARER:	Kernel
 *
 * DESCRIPTION:
 *	This file defines database structures and routines.
 *
 *	$Id: dbase.h,v 1.1 97/04/04 15:58:24 newdeal Exp $
 *
 ***********************************************************************/

#ifndef	__DBASE_H
#define __DBASE_H

#include <vm.h>		/* VMFileHandle */
#include <lmem.h>	/* LMemDeref */
/*
 * Database types
 */

/* The "GetRef" routines used to return a DBItemRef, which is functionally
 * identical to an optr. They now just use the optr. This typedef is
 * left in for those who still use DBItemRefs. */
typedef optr	 DBItemRef;

#define NullDBGroupAndItem ((DBGroupAndItem) 0)

#define DBGroupFromGroupAndItem(gi) ((DBGroup) ((gi) >> 16))
#define DBItemFromGroupAndItem(gi) ((DBItem) (gi))

#define DBCombineGroupAndItem(group, item) \
	((((DBGroupAndItem) (group)) << 16) | (item))

/***/

/* The "GetRef" versions of DBLock return an optr to the chunk in
 * addition to the far pointer.  This allows the code to do other LMem
 * things with the chunk. The optr is not generally needed, so the
 * general DBLock routine is not burdened with returning it.  */

extern void * 	/* XXX */
    _pascal DBLockUngrouped(VMFileHandle file, DBGroupAndItem id);

#define DBLock(file, group, item)	\
    DBLockUngrouped(file, DBCombineGroupAndItem(group, item))

extern void *	/*XXX*/
    _pascal DBLockGetRefUngrouped(VMFileHandle file, DBGroupAndItem id,
			  optr *refPtr);

#define DBLockGetRef(file, group, item, refPtr)	\
    DBLockGetRefUngrouped(file, DBCombineGroupAndItem(group, item), refPtr)


/***/

#define DBDeref(ref) 	LMemDeref((optr) (ref))

/***/

extern void	
    _pascal DBUnlock(void *ptr);

/***/

extern void	
    _pascal DBDirty(const void *ptr);

/***/

#define DB_UNGROUPED	((DBGroup) 0xffff)

extern DBGroupAndItem	/*XXX*/
    _pascal DBRawAlloc(VMFileHandle file, DBGroup group, word size);

#define DBAlloc(file, group, size)	\
    DBItemFromGroupAndItem(DBRawAlloc((file), (group), (size)))

#define DBAllocUngrouped(file, size)	\
    DBRawAlloc((file), DB_UNGROUPED, (size))

/***/

extern void 	/*XXX*/
    _pascal DBReAllocUngrouped(VMFileHandle file, DBGroupAndItem id, word size);

#define DBReAlloc(file, group, item, size)	\
    DBReAllocUngrouped((file), DBCombineGroupAndItem((group), (item)), (size))

/***/

extern void 	/*XXX*/
    _pascal DBFreeUngrouped(VMFileHandle file, DBGroupAndItem id);

#define DBFree(file, group, item)	\
    DBFreeUngrouped((file), DBCombineGroupAndItem((group), (item)))

/***/

extern DBGroup	/*XXX*/
    _pascal DBGroupAlloc(VMFileHandle file);

/***/

extern void	/*XXX*/
    _pascal DBGroupFree(VMFileHandle file, DBGroup group);

/***/

extern void 	/*XXX*/
    _pascal DBSetMapUngrouped(VMFileHandle file, DBGroupAndItem id);

#define DBSetMap(file, group, item)	\
    DBSetMapUngrouped((file), DBCombineGroupAndItem((group), (item)))

/***/

extern DBGroupAndItem	
    _pascal DBGetMap(VMFileHandle file);

#define DBLockMap(file) DBLockUngrouped((file), DBGetMap(file))

/***/

extern void 	/*XXX*/
    _pascal DBInsertAtUngrouped(VMFileHandle file, DBGroupAndItem id,
			word insertOffset, word insertCount);

#define DBInsertAt(file, group, item, off, count)	\
    DBInsertAtUngrouped((file), DBCombineGroupAndItem((group), (item)), (off), (count))

/***/

extern void	/*XXX*/
    _pascal DBDeleteAtUngrouped(VMFileHandle file, DBGroupAndItem id,
			word deleteOffset, word deleteCount);

#define DBDeleteAt(file, group, item, off, count)	\
    DBDeleteAtUngrouped((file), DBCombineGroupAndItem((group), (item)), (off), (count))

extern DBGroupAndItem	/*XXX*/
    _pascal DBRawCopyDBItem(VMFileHandle srcFile, DBGroupAndItem srcID,
		     VMFileHandle destFile,  DBGroup destGroup);

#define DBCopyDBItem(srcFile, srcGroup, srcItem, destFile, destGroup)	\
    DBItemFromGroupAndItem(DBRawCopyDBItem((srcFile), 			\
				DBCombineGroupAndItem((srcGroup), (srcItem)),  \
				(destFile), (destGroup)))

#define DBCopyDBItemUngrouped(srcFile, srcID, destFile)		\
    DBRawCopyDBItem((srcFile), (srcID), (destFile), DB_UNGROUPED)


extern Boolean
    _pascal DBInfoUngrouped(VMFileHandle file, DBGroupAndItem grpAndItem,
			    word *sizePtr);

#define DBInfo(file, group, item, sizePtr) \
    DBInfoUngrouped((file), DBCombineGroupAndItem((group),(item)), (sizePtr))

#ifdef __HIGHC__
pragma Alias(DBLockUngrouped, "DBLOCKUNGROUPED");
pragma Alias(DBLockGetRefUngrouped, "DBLOCKGETREFUNGROUPED");
pragma Alias(DBUnlock, "DBUNLOCK");
pragma Alias(DBDirty, "DBDIRTY");
pragma Alias(DBRawAlloc, "DBRAWALLOC");
pragma Alias(DBReAllocUngrouped, "DBREALLOCUNGROUPED");
pragma Alias(DBFreeUngrouped, "DBFREEUNGROUPED");
pragma Alias(DBGroupAlloc, "DBGROUPALLOC");
pragma Alias(DBGroupFree, "DBGROUPFREE");
pragma Alias(DBSetMapUngrouped, "DBSETMAPUNGROUPED");
pragma Alias(DBGetMap, "DBGETMAP");
pragma Alias(DBInsertAtUngrouped, "DBINSERTATUNGROUPED");
pragma Alias(DBDeleteAtUngrouped, "DBDELETEATUNGROUPED");
pragma Alias(DBRawCopyDBItem, "DBRAWCOPYDBITEM");
#endif

#endif
