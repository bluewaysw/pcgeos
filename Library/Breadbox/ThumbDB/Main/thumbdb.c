#include <geos.h>
#include <file.h>
#include <vm.h>
#include <hugearr.h>
#include <timedate.h>
#include <thumbdb.h>
#include <library.h>
#include <graphics.h>
#include <Ansi/string.h>
#include <sem.h>
#include <dbase.h>
#include <heap.h>


/***************************************************************************/
/* local definitions */

#define THUMB_WIDTH     88
#define THUMB_HEIGHT    80

typedef struct
{
  DBGroupAndItem TDBM_firstItem;
  DBGroupAndItem TDBM_lastItem;
  word           TDBM_version;  
  dword          TDBM_size;
} thumbDBMap;

typedef struct
{
  FileLongName    TDBIO_name;
  FileDateAndTime TDBIO_date;
  dword           TDBIO_size;
  VMBlockHandle   TDBIO_thumbnail;
  DBGroupAndItem  TDBIO_next;
} thumbDBItemOld;

typedef struct {
    FileLongName    TDBI_name;
    dword           TDBI_size;
    FileDateAndTime TDBI_date;
    dword           TDBI_changed;

    Bitmap          TDBI_bitmap ;

} thumbDBItem;

/***************************************************************************/
/* declaration of local functions */

/* gets:
    -1 for not found; index of item before
    0 item found
    1 for not found; index of item after */
int
thumbLookForItem(FileLongName name, dword size, FileDateAndTime date,
                    dword *index);

dword
thumbGetDate(void);

int
thumbCompareItem(thumbDBItem *item1, thumbDBItem *item2);

void
thumbUpdateOldLib(thumbDBMap *mapptr);

/***************************************************************************/
/* global variables */

VMFileHandle thumbDBFile = 0;
VMBlockHandle thumbDBArray = 0;

ThreadLockHandle thumbLockSem = 0;

/***************************************************************************/
/* implementation of exported functions */

/* entry point routine */
Boolean _pascal _export
ThumbEntry(LibraryCallType ty, GeodeHandle client)
{
    VMBlockHandle mapblock;
    MemHandle mem;
    thumbDBMap *mapptr;

    if(ty == LCT_ATTACH)
    {
        thumbDBFile = 0;
        thumbDBArray = 0;
        thumbLockSem = ThreadAllocThreadLock();

        /* opening or creating thumbnail database */
        FilePushDir();
        FileSetCurrentPath(SP_PRIVATE_DATA, ".");
        thumbDBFile = VMOpen("Thumbnail Database", 0, VMO_CREATE, 0);
        FilePopDir();

        if(thumbDBFile != 0)
        {
            mapblock = VMGetMapBlock(thumbDBFile);

            if(mapblock == 0)
            {
                /* create map block */
                mapblock = VMAlloc(thumbDBFile, sizeof(thumbDBMap), 0);

                if(mapblock != 0)
                {
                    /* set huge array block as map block */
                    VMSetMapBlock(thumbDBFile, mapblock);

                    /* create huge array */
                    thumbDBArray = HugeArrayCreate(thumbDBFile,
                                                 0, 0);

                    if(thumbDBArray != 0)
                    {

                        mapptr = VMLock(thumbDBFile, mapblock, &mem);

                        if(mapptr != 0)
                        {
                            mapptr->TDBM_firstItem = thumbDBArray;
                            mapptr->TDBM_lastItem = 0;
                            mapptr->TDBM_version = 2;  
                            mapptr->TDBM_size = 0;  

                            VMDirty(mem);
                            VMUnlock(mem);
                        }
                    }
                    else
                    {
                        mapptr = VMLock(thumbDBFile, mapblock, &mem);

                        if(mapptr == 0)
                        {
                            mapptr->TDBM_firstItem = 0;
                            mapptr->TDBM_lastItem = 0;
                            mapptr->TDBM_version = 2;  

                            VMDirty(mem);
                            VMUnlock(mem);
                        }
                    }
                }
            }
            else
            {
                mapptr = VMLock(thumbDBFile, mapblock, &mem);

                if(mapptr != 0)
                {
                    if(mapptr->TDBM_version == 2)
                    {
                        thumbDBArray = mapptr->TDBM_firstItem;
                        VMUnlock(mem);
                    }
                    else
                    {
                        /* update version 1 thumbnail database files */
                        thumbUpdateOldLib(mapptr);
                        VMDirty(mem);
                        VMUnlock(mem);
                    }
                }
            }
        }
    }
    else
        if(ty == LCT_DETACH)
        {
            if(thumbDBFile != 0)
                VMClose(thumbDBFile, FILE_NO_ERRORS);

            thumbDBFile = 0;
            thumbDBArray = 0;

            if(thumbLockSem != 0)
            {
                ThreadFreeSem(thumbLockSem);
                thumbLockSem = 0;
            }
        }

    return(FALSE);
}

/*-------------------------------------------------------------------------*/

void
dummy(void){}

/* creating new item */
ThumbError _pascal _export
ThumbCreateItem(FileLongName name, dword size, FileDateAndTime date,
                VMFileHandle file, VMBlockHandle block, ThumbSourceType ty)
{
    word width, height;
    MemHandle mem;
    byte *ptr;
    byte type;
    WWFixedAsDWord sx, sy;
    VMBlockHandle uncompact;
    GStateHandle gstate;
    dword index;
    thumbDBItem initItem;
    dword numItems;
    word size_x, size_y;
    VMBlockHandle compact ;
    word loopCount, elemSize ;
    dword newPlace ;
    byte *elemPtr ;
    word bitmapSize = 0 ;
    thumbDBMap *map ;

    if(thumbLockSem == 0)
        return(TE_NO_LOCK_SEMAPHORE);

    if(thumbDBFile == 0)
        return(TE_NO_DB_FILE);

    ThreadGrabThreadLock(thumbLockSem);

    if(ThumbFindItem(name, size, date) != 0)
    {
        ThreadReleaseThreadLock(thumbLockSem);
        return(TE_NO_ERROR);
    }

    if(ty == TST_HUGE_BITMAP)
    {
/*****  extended graphics library */
        ptr = VMLock(file, block, &mem);

        width = ptr[0x1a]+256*(ptr[0x1b]);
        height = ptr[0x1c]+256*(ptr[0x1d]);
        type = ptr[0x1f] & 7;
        VMUnlock(mem);
/*****/

        /* creating thumbnail */
        sx=GrSDivWWFixed(MakeWWFixed(THUMB_WIDTH), MakeWWFixed(width));
        sy=GrSDivWWFixed(MakeWWFixed(THUMB_HEIGHT), MakeWWFixed(height));

        /* bigger scaling is the used scale in sx */
        if(sx > sy)
            sx = sy;

        size_x = IntegerOf(GrMulWWFixed(MakeWWFixed(width),sx));
        if(size_x == 0) size_x = 1;
        size_y = IntegerOf(GrMulWWFixed(MakeWWFixed(height),sx));
        if(size_y == 0) size_y = 1;

        if(type == BMF_24BIT)
            type = BMF_8BIT;
        
        uncompact = GrCreateBitmap(type, size_x, size_y,
                        thumbDBFile, 0, &gstate);

        GrApplyScale(gstate, sx, sx);
        GrDrawHugeBitmap(gstate, 0, 0, file, block);
        GrDestroyBitmap(gstate, BMD_LEAVE_DATA);

        compact = GrCompactBitmap(thumbDBFile, uncompact,
                                                thumbDBFile);

        VMFreeVMChain(thumbDBFile,
                            VMCHAIN_MAKE_FROM_VM_BLOCK(uncompact));
  
        /* transfer the standard data */
        initItem.TDBI_bitmap.B_width = size_x ;
        initItem.TDBI_bitmap.B_height = size_y ;
        initItem.TDBI_bitmap.B_compact = BMC_PACKBITS ;
        initItem.TDBI_bitmap.B_type = type;

        /* get bitmap data size */
        loopCount = 0 ;        
        while(loopCount < size_y) {
        
            byte *p_data ;

            HugeArrayLock(thumbDBFile, compact, loopCount, (void**) &p_data, &elemSize) ;

            bitmapSize += elemSize ;

            HugeArrayUnlock(p_data) ;
            
            loopCount++ ;
        }
    }
    else
    {
        ThreadReleaseThreadLock(thumbLockSem);

        return(TE_WRONG_SOURCE_TYPE);
    }

    /* add the created thumbnail to the data base */

    numItems = HugeArrayGetCount( thumbDBFile,
                                  thumbDBArray );

    /* prepairing record */
    initItem.TDBI_changed = thumbGetDate();
    strcpy(initItem.TDBI_name, name);
    initItem.TDBI_size = size;
    initItem.TDBI_date = date;

    if(numItems == 0)
    {
        /* append as first item */
        HugeArrayAppend(thumbDBFile, thumbDBArray,
                            sizeof(thumbDBItem) + bitmapSize, &initItem);
    
        newPlace = 0 ;
    }
    else
        {
        if(thumbLookForItem(name, size, date, &index) <= 0) {

                /* insert before */
                HugeArrayInsert(thumbDBFile, thumbDBArray,
                                sizeof(thumbDBItem) + bitmapSize, index, &initItem);
            
                newPlace = index ;
            }
            else
                if(index >= numItems) {

                    /* append after */
                    HugeArrayAppend(thumbDBFile, thumbDBArray,
                                    sizeof(thumbDBItem) + bitmapSize, &initItem);
                
                    newPlace = numItems ;
                }
                else {

                    /* insert before */
                    HugeArrayInsert(thumbDBFile, thumbDBArray,
                                        sizeof(thumbDBItem) + bitmapSize, index+1, &initItem);
                
                    newPlace = index + 1;
                }
        }

    /* transfer the bitmap data */
    HugeArrayLock(thumbDBFile, thumbDBArray, newPlace, (void**) &elemPtr, &elemSize) ;

    elemPtr += sizeof(thumbDBItem)  ;

    loopCount = 0 ;
    while(loopCount < size_y) {

        byte *p_data ;

        HugeArrayLock(thumbDBFile, compact, loopCount, (void**) &p_data, &elemSize) ;

        memcpy(elemPtr, p_data, elemSize) ;
        elemPtr += elemSize ;

        HugeArrayUnlock(p_data) ;
        
        loopCount++ ;
    } 

    HugeArrayDirty(elemPtr) ;
    HugeArrayUnlock(elemPtr) ;

    /* free the huge bitmap */
    HugeArrayDestroy(thumbDBFile, compact) ;

    numItems++ ;

    map = VMLock(thumbDBFile, VMGetMapBlock(thumbDBFile), &mem) ;

    /* add the size */
    map->TDBM_size += sizeof(thumbDBItem) + bitmapSize ;

    /* if we are over the size */
    if(((dword)map->TDBM_size) > ((dword)1024 * 1024 * 2)) {

        dword deleteCount = numItems / 10 ;
        dword loopCount = 0 ;
        MemHandle removeList ;
        dword *p_removeList ;

        /* determine 10% or maximum 200 oldest items */
        if(deleteCount > 200) {
            
            deleteCount = 200 ;
        }

        removeList = MemAlloc(deleteCount * (sizeof(dword) * 3), 
                        HF_SWAPABLE, HAF_LOCK) ;
        // [0] = item index, 0xFFFFFFFF for not used
        // [1] = date in some strange form 
        // [2] = size
        
        if(removeList) {

            p_removeList = MemDeref(removeList) ;

            /* init remove list */
            memset(p_removeList, 0xFF, deleteCount * sizeof(dword) * 3) ;

            loopCount = 0 ;        
            while(loopCount < numItems) {
            
                word elemSize ;
                thumbDBItem *thisElem ;
                dword itemDate ;
                word removeCount ;

                HugeArrayLock(
                    thumbDBFile, thumbDBArray, loopCount,
                    (void**) &thisElem, &elemSize) ;
                                                    
                itemDate = thisElem->TDBI_changed ;

                HugeArrayUnlock(thisElem) ; 

                /* look for the item to replace, search newer item */
                removeCount = 0 ;
                while(removeCount < deleteCount) {
                
                    if(p_removeList[
                        (deleteCount - removeCount 
                        - 1) * 3 + 1] > itemDate) {
                    
                        break ;
                    }

                    removeCount++ ;                    
                }

                /* if we found a newer item */
                if(removeCount < deleteCount) {

                    if(p_removeList[
                        (deleteCount - removeCount - 1) * 3] != 0xFFFFFFFF) {
                    
                        map->TDBM_size += p_removeList[
                            (deleteCount - removeCount - 1) * 3 + 2] ;
                    }

                    /* remove the item */
                    memmove(&p_removeList[3], &p_removeList[0], 
                        (deleteCount - removeCount - 1) * 
                                            (sizeof(dword) * 3)) ;

                    /* set the new item the last */
                    p_removeList[0] = loopCount ;
                    p_removeList[1] = itemDate ;
                    p_removeList[2] = elemSize ;

                    dummy() ;
                    
                    map->TDBM_size -= p_removeList[2] ;
                }

                loopCount++ ;
            }

            /* remove them items on the list */
            loopCount = 0 ;
            while(loopCount < deleteCount) {
                
                /* if this is an item to remove */
                if(p_removeList[loopCount * 3] != 0xFFFFFFFF) {
                    
                    HugeArrayDelete(
                        thumbDBFile,
                        thumbDBArray,
                        1, p_removeList[loopCount * 3]) ;
                }

                loopCount++ ;
            }
        
            MemFree(removeList) ;
        }
    }

    VMDirty(mem) ;
    VMUnlock(mem) ;

    ThreadReleaseThreadLock(thumbLockSem);

    return(0);
}

/*-------------------------------------------------------------------------*/

/* find item */
Boolean _pascal _export
ThumbFindItem(FileLongName name, dword size, FileDateAndTime date)
{
    dword index;

    if(thumbLockSem == 0)
        return(TE_NO_LOCK_SEMAPHORE);

    ThreadGrabThreadLock(thumbLockSem);

    if(thumbLookForItem(name, size, date, &index) != 0)
    {
        ThreadReleaseThreadLock(thumbLockSem);
        return(0);
    }

    ThreadReleaseThreadLock(thumbLockSem);

    return(TRUE);
}

/*-------------------------------------------------------------------------*/

/* remove item */
ThumbError _pascal _export
ThumbRemoveItem(FileLongName name, dword size, FileDateAndTime date)
{
    dword index;

    if(thumbLockSem == 0)
        return(TE_NO_LOCK_SEMAPHORE);


    ThreadGrabThreadLock(thumbLockSem);

    if(thumbLookForItem(name, size, date, &index) != 0)
    {
        ThreadReleaseThreadLock(thumbLockSem);
        return(TE_ITEM_NOT_FOUND);
    }

    HugeArrayDelete(thumbDBFile, thumbDBArray, 1, index);

    ThreadReleaseThreadLock(thumbLockSem);

    return(TE_NO_ERROR);
}

/*-------------------------------------------------------------------------*/

/* compact db */
ThumbError _pascal _export
ThumbCompactDB(dword diff)
{
    return(TE_NO_ERROR);
}

/*-------------------------------------------------------------------------*/

/* draw item */
ThumbError _pascal _export
ThumbDrawItem(GStateHandle gstate, int x, int y,
              ThumbHorizontalJustification xalign,
              ThumbVerticalJustification yalign,
              FileLongName name, dword size, FileDateAndTime date)
{
    word height, width;
    dword index ;
    word elemSize ;
    thumbDBItem *elemPtr ;

    if(thumbLockSem == 0)
        return(TE_NO_LOCK_SEMAPHORE);

    ThreadGrabThreadLock(thumbLockSem);

    if(thumbLookForItem(name, size, date, &index) != 0)
    {
        ThreadReleaseThreadLock(thumbLockSem);
        return(TE_THUMBNAIL_NOT_FOUND);
    }

    HugeArrayLock(thumbDBFile,
                    thumbDBArray, index, (void**) &elemPtr, &elemSize) ;

    width = elemPtr->TDBI_bitmap.B_width ;
    height = elemPtr->TDBI_bitmap.B_height ;

    switch(xalign)
    {
        case THJ_CENTER:
            x -= (width / 2);
            break;

        case THJ_RIGHT_JUSTIFIED:
            x -= width;
            break;
    }

    switch(yalign)
    {
        case TVJ_CENTER:
            y -= (height / 2);
            break;

        case TVJ_BUTTOM_JUSTIFIED:
            y -= height;
            break;
    }
    GrDrawBitmap(gstate, x , y, &elemPtr->TDBI_bitmap, 0);
    
    /* this item is used lately */
    elemPtr->TDBI_changed = thumbGetDate(); 

    HugeArrayDirty(elemPtr) ;
    HugeArrayUnlock(elemPtr) ;

    ThreadReleaseThreadLock(thumbLockSem);

    return(TE_NO_ERROR);
}

/***************************************************************************/
/* implementation of local functions */

/* gets:
    -1 for not found; index of item before
    0 item found
    1 for not found; index of item after */
int
thumbLookForItem(FileLongName name, dword size, FileDateAndTime date,
                 dword *index)
{
    dword left, right;
    thumbDBItem item;
    int found;
    thumbDBItem *itemptr;
    dword numItem;
    word shortSize;

    *index = TDB_NO_ITEM_EXISTING;

    if(thumbDBFile == 0)
        return(2);
    if(thumbDBArray == 0)
        return(2);

    strcpy(item.TDBI_name, name);
    item.TDBI_size = size;
    item.TDBI_date = date;
 
    left = 0;
    numItem = HugeArrayGetCount(thumbDBFile, thumbDBArray);
    right = numItem - 1;

    if(numItem == 0)
        return(2);

    HugeArrayLock(thumbDBFile, thumbDBArray, left,
                            (void**) &itemptr, &shortSize);
    size = shortSize;
    
    if(itemptr == 0)
        return(2);

    found = thumbCompareItem(&item, itemptr);

    HugeArrayUnlock(itemptr);

    if(found <= 0)
    {
        *index = left;
        return(found);
    }

    HugeArrayLock(thumbDBFile, thumbDBArray, right,
                            (void**) &itemptr, &shortSize);
    size = shortSize;
    if(itemptr == 0)
        return(2);

    found = thumbCompareItem(&item, itemptr);

    HugeArrayUnlock(itemptr);

    if(found >= 0)
    {
        *index = right;
        return(found);
    }

    do
    {
        *index = ((right - left) >> 1) + left;

        if(*index >= numItem)
            return(2);

        HugeArrayLock(thumbDBFile, thumbDBArray, *index,
                            (void**) &itemptr, &shortSize);
        size = shortSize;
        if(itemptr == 0)
            return(2);

        found = thumbCompareItem(&item, itemptr);

        HugeArrayUnlock(itemptr);

        if(found < 0)
            right = *index;
        if(found > 0)
            left = *index;
    }
    while ( ((right-left) > 1) && (found != 0));

    if(found == 0) 
      return(found);

    *index = left;

    return(1);
}

/*-------------------------------------------------------------------------*/

dword
thumbGetDate(void)
{
    TimerDateAndTime date;

    TimerGetDateAndTime(&date);

    /* calculates index for the day for comparison */
    return( date.TDAT_year * 12 * 31 +
            date.TDAT_month * 31 +
            date.TDAT_day );
}

/*-------------------------------------------------------------------------*/

/* <0 if item1  < item2
    0 if item1 == item2
   >0 if item1 >  item2 */
int
thumbCompareItem(thumbDBItem *item1, thumbDBItem *item2)
{
    int result;

    result = strcmp(item1->TDBI_name, item2->TDBI_name);

    if(result != 0)
        return(result);

    if(item1->TDBI_size != item2->TDBI_size)
    {
        if(item1->TDBI_size < item2->TDBI_size)
            return(-1);
        else
            return(1);
    }

    if(item1->TDBI_date != item2->TDBI_date)
    {
        if(item1->TDBI_date < item2->TDBI_date)
            return(-1);
        else
            return(1);
    }

    return(0);
}

/*-------------------------------------------------------------------------*/

void
thumbUpdateOldLib(thumbDBMap *mapptr)
{
    DBGroupAndItem item, newitem;
    thumbDBItemOld *itemptr;

    /* create huge array */
    thumbDBArray = HugeArrayCreate(thumbDBFile,
                                 sizeof(thumbDBItem), 0);

    if(thumbDBArray)
    {
        item = mapptr->TDBM_firstItem;
    
        while(item != 0)
        {
            itemptr = DBLockUngrouped(thumbDBFile, item);

            ThumbCreateItem(itemptr->TDBIO_name,
                            itemptr->TDBIO_size,
                            itemptr->TDBIO_date,
                            thumbDBFile,
                            itemptr->TDBIO_thumbnail,
                            TST_HUGE_BITMAP);

            VMFreeVMChain(thumbDBFile,
                VMCHAIN_MAKE_FROM_VM_BLOCK(itemptr->TDBIO_thumbnail));

            newitem = itemptr->TDBIO_next;
            DBUnlock(itemptr);
            DBFreeUngrouped(thumbDBFile, item);

            item = newitem;
        }

        mapptr->TDBM_firstItem = thumbDBArray;
        mapptr->TDBM_lastItem = 0;
        mapptr->TDBM_version = 2;  
    }

}
