#include <geos.h>
#include <file.h>
#include <vm.h>
#include <hugearr.h>
#include <timedate.h>
#include <library.h>
#include <graphics.h>
#include <ansi\string.h>
#include <sem.h>
#include <dbase.h>
#include <heap.h>


#ifndef __THUMBDB_H
#define __THUMBDB_H

typedef enum {

	TE_NO_ERROR,
	TE_NO_LOCK_SEMAPHORE,
	TE_NO_DB_FILE,
	TE_WRONG_SOURCE_TYPE,
	TE_ITEM_NOT_FOUND,
	TE_THUMBNAIL_NOT_FOUND

} ThumbError ;

typedef word ThumbSourceType ;
#define TST_HUGE_BITMAP	1

typedef byte ThumbHorizontalJustification ;
#define THJ_CENTER				1
#define THJ_RIGHT_JUSTIFIED		2


typedef byte ThumbVerticalJustification ;
#define TVJ_CENTER				1
#define TVJ_BUTTOM_JUSTIFIED	2

#define TDB_NO_ITEM_EXISTING	0xFFFFFFFF

/* entry point routine */
Boolean _pascal _export
ThumbEntry(LibraryCallType ty, GeodeHandle client) ;

ThumbError _pascal _export
ThumbCreateItem(FileLongName name, dword size, FileDateAndTime date,
                VMFileHandle file, VMBlockHandle block, ThumbSourceType ty) ;
/* find item */
Boolean _pascal _export
ThumbFindItem(FileLongName name, dword size, FileDateAndTime date) ;

/* remove item */
ThumbError _pascal _export
ThumbRemoveItem(FileLongName name, dword size, FileDateAndTime date) ;
/* compact db */
ThumbError _pascal _export
ThumbCompactDB(dword diff) ;

/* draw item */
ThumbError _pascal _export
ThumbDrawItem(GStateHandle gstate, int x, int y,
              ThumbHorizontalJustification xalign,
              ThumbVerticalJustification yalign,
              FileLongName name, dword size, FileDateAndTime date) ;

#endif
