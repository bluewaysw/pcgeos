#include <geos.h>
#include <lmem.h>
#include <hugearr.h>
#include <ec.h>
#include <vm.h>
#include <Ansi\string.h>
#include <Ansi\stdio.h>
#include <file.h>
#include "errors.goh"
#include "bucketha.h"
#include "news.h"

#define FREE_LINK_NONE      0xFFFF

#define ARRAYS_PER_BUCKET                    128
#define BUCKET_HUGE_ARRAY_GET_MAJOR(array)   ((array)/ARRAYS_PER_BUCKET)
#define BUCKET_HUGE_ARRAY_GET_MINOR(array)   ((array)%ARRAYS_PER_BUCKET)

#define MAX_BUCKETS_OPEN             10
#define MAX_BUCKET_LOCKS             20

#define BUCKET_NAME_FORMAT           "name%ld"
#define BUCKET_INDEX_FILENAME        "News Reader Index"

#define BUCKETS_NUM_FREE_FILES_ALWAYS_OPEN         3

typedef union {
    word numLocks ;
    word freeLink ;
} T_numLocksOrFreeLink ;

typedef struct {
    BucketHugeArrayHandle B_arrayID ;
    VMFileHandle B_ownerFile ;
    VMFileHandle B_realFile ;
    VMBlockHandle B_mapBlock ;
    T_numLocksOrFreeLink B_nf ;
    dword B_openID ;
} T_bucket ;

typedef struct {
    void *p_ptr ;
    T_bucket *p_bucket ;
} T_lockEntry ;

typedef struct {
    VMBlockHandle arrayList[ARRAYS_PER_BUCKET] ;
} T_bucketMap ;

static T_bucket G_bucketArray[MAX_BUCKETS_OPEN] ;
static word G_numLocks = 0 ;
static word G_numOpenFiles = 0 ;
static word G_numOpenFreeFiles = 0 ;
static word G_firstFreeBucket = 0 ;
static T_lockEntry G_bucketLocks[MAX_BUCKET_LOCKS] ;
static FileLongName G_path ;
static VMFileHandle G_indexFile = NullHandle ;
static VMBlockHandle G_bucketsMapBlock = NullHandle ;
static BucketHugeArrayHandle G_nextID = 0 ;
static dword G_openID ;

/* Internal prototypes: */
/* XXX */ T_bucket *IBucketFind(VMFileHandle vmFile, BucketHugeArrayHandle array) ;
/* XXX */ T_bucket *IBucketAlloc(void) ;
/* XXX */ void IBucketFree(word bucketIndex) ;
/* XXX */ T_bucket *IBucketOpen(BucketHugeArrayHandle arrayID) ;
/* XXX */ void IBucketClose(T_bucket *p_bucket) ;
/* XXX */ void IBucketSave(T_bucket *p_bucket) ;
/* XXX */ T_bucket *IBucketLock(
                  VMFileHandle vmFile,
                  BucketHugeArrayHandle array) ;
/* XXX */ void IBucketUnlock(T_bucket *p_bucket) ;
/* XXX */ void IAddLock(void *p_data, T_bucket *p_bucket) ;
/* XXX */ T_bucket *IFindAndRemoveLock(void *p_data) ;
/* XXX */ VMBlockHandle IBucketLookup(T_bucket *p_bucket, dword arrayID) ;
/* XXX */ void IBucketEnsureClose(T_bucket *p_bucket) ;
/* XXX */ void IBucketEnsureAllFilesClose(void) ;
/* XXX */ void IBucketCloseOldestFiles(void) ;
/* XXX */ VMFileHandle IBucketCreate(char *name) ;

typedef struct {
    dword BIMB_nextUniqueArrayID ;
} T_bucketIndexMapBlock ;

extern dword
    _pascal TextSearchInHugeArray(char *str2, word str2Size,
				       dword str1Size, dword curOffset,
				       dword endOffset, 
				       FileHandle hugeArrayFile,
				       VMBlockHandle hugeArrayBlock,
				       word searchOptions, 
				       dword *matchLen);

/*-------------------------------------------------------------------------*/
/* XXX */
BucketHugeArrayHandle
    BucketHugeArrayCreate(
        VMFileHandle vmFile,
        word elemSize,
        word headerSpace)
{
    T_bucket *p_bucket ;
    T_bucketMap *p_map ;
    MemHandle map ;
    VMBlockHandle *p_arrayEntry ;
    BucketHugeArrayHandle newID ;

    newID = G_nextID++ ;

    /* Lock the bucket (creating if necessary) */
    p_bucket = IBucketLock(vmFile, newID) ;
    if ((p_bucket) && (p_bucket->B_realFile))  {
        p_map = VMLock(p_bucket->B_realFile, p_bucket->B_mapBlock, &map) ;
        p_arrayEntry = p_map->arrayList + BUCKET_HUGE_ARRAY_GET_MINOR(newID) ;
        EC_ERROR_IF(
            (*p_arrayEntry != NullHandle),
            ERROR_BUCKETS_ARRAY_ALREADY_IN_USE) ;

        /* Create a new huge array and store the lookup in the map block */
        *p_arrayEntry = HugeArrayCreate(
                            p_bucket->B_realFile,
                            elemSize,
                            headerSpace) ;
        VMDirty(map) ;
        VMUnlock(map) ;
    }
    IBucketUnlock(p_bucket) ;

    return newID ;
}

/*-------------------------------------------------------------------------*/
void BucketHugeArrayDestroy(
         VMFileHandle vmFile,
         BucketHugeArrayHandle arrayID)
{
    T_bucket *p_bucket ;
    T_bucketMap *p_map ;
    MemHandle map ;
    VMBlockHandle *p_arrayEntry ;

    /* Lock the bucket (creating if necessary) */
    p_bucket = IBucketLock(vmFile, arrayID) ;
    if ((p_bucket) && (p_bucket->B_realFile))  {
        p_map = VMLock(p_bucket->B_realFile, p_bucket->B_mapBlock, &map) ;
        p_arrayEntry = p_map->arrayList + BUCKET_HUGE_ARRAY_GET_MINOR(arrayID) ;
        EC_ERROR_IF(
            (*p_arrayEntry == NullHandle),
            ERROR_BUCKETS_ARRAY_ALREADY_DESTROYED) ;

        /* Destroy the old one and null out in the map */
        HugeArrayDestroy(p_bucket->B_realFile, *p_arrayEntry) ;
        *p_arrayEntry = NullHandle ;

        VMDirty(map) ;
        VMUnlock(map) ;
    }
    IBucketUnlock(p_bucket) ;
}

/*-------------------------------------------------------------------------*/
/* XXX */
dword BucketHugeArrayAppend(
        VMFileHandle vmFile,
        BucketHugeArrayHandle arrayID,
		word numElem,
        const void *initData)
{
    T_bucket *p_bucket ;
    VMBlockHandle realArray ;
    dword ret ;

    p_bucket = IBucketLock(vmFile, arrayID) ;
    realArray = IBucketLookup(p_bucket, arrayID) ;

    ret = HugeArrayAppend(
              p_bucket->B_realFile,
              realArray,
              numElem,
              initData) ;

    IBucketUnlock(p_bucket) ;

    return ret ;
}


/*-------------------------------------------------------------------------*/
void BucketHugeArrayInsert(
        VMFileHandle vmFile,
        BucketHugeArrayHandle arrayID,
		word numElem,
        dword elemNum,
        const void *initData)
{
    T_bucket *p_bucket ;
    VMBlockHandle realArray ;

    p_bucket = IBucketLock(vmFile, arrayID) ;
    realArray = IBucketLookup(p_bucket, arrayID) ;

    HugeArrayInsert(
        p_bucket->B_realFile,
        realArray,
        numElem,
        elemNum,
        initData) ;

    IBucketUnlock(p_bucket) ;
}

/*-------------------------------------------------------------------------*/
void BucketHugeArrayDelete(
        VMFileHandle vmFile,
        BucketHugeArrayHandle arrayID,
		word numElem,
        dword elemNum)
{
    T_bucket *p_bucket ;
    VMBlockHandle realArray ;

    p_bucket = IBucketLock(vmFile, arrayID) ;
    realArray = IBucketLookup(p_bucket, arrayID) ;

    HugeArrayDelete(
        p_bucket->B_realFile,
        realArray,
        numElem,
        elemNum) ;

    IBucketUnlock(p_bucket) ;
}

/*-------------------------------------------------------------------------*/
/* XXX */
dword BucketHugeArrayGetCount(
        VMFileHandle vmFile,
        BucketHugeArrayHandle arrayID)
{
    T_bucket *p_bucket ;
    VMBlockHandle realArray ;
    dword ret ;

    p_bucket = IBucketLock(vmFile, arrayID) ;
    realArray = IBucketLookup(p_bucket, arrayID) ;

    ret = HugeArrayGetCount(p_bucket->B_realFile, realArray) ;

    IBucketUnlock(p_bucket) ;

    return ret ;
}

/*-------------------------------------------------------------------------*/
/* XXX */
dword BucketHugeArrayTextSearch(char *str2, word str2Size,
				       dword str1Size, dword curOffset,
				       dword endOffset, 
				       FileHandle hugeArrayFile,
					   BucketHugeArrayHandle arrayID,
				       word searchOptions, 
				       dword *matchLen)
{
    T_bucket *p_bucket ;
    VMBlockHandle realArray ;
    dword ret ;

    p_bucket = IBucketLock(hugeArrayFile, arrayID) ;
    realArray = IBucketLookup(p_bucket, arrayID) ;

    ret = TextSearchInHugeArray(
				str2, str2Size, str1Size, curOffset,
				endOffset, 
				realArray, p_bucket->B_realFile, 
				searchOptions, matchLen) ;

    IBucketUnlock(p_bucket) ;

    return ret ;
}

/*-------------------------------------------------------------------------*/
/* XXX */
dword BucketHugeArrayLock(
        VMFileHandle vmFile,
        BucketHugeArrayHandle arrayID,
	    dword elemNum,
        void **elemPtr,
        word *elemSize)
{
    T_bucket *p_bucket ;
    VMBlockHandle realArray ;
    dword ret ;

    p_bucket = IBucketLock(vmFile, arrayID) ;
    realArray = IBucketLookup(p_bucket, arrayID) ;

    /* Do real lock here and get elemPtr */
    ret = HugeArrayLock(
              p_bucket->B_realFile,
              realArray,
              elemNum,
              elemPtr,
              elemSize) ;

    if (*elemPtr)
        IAddLock(*elemPtr, p_bucket) ;
    else
        IBucketUnlock(p_bucket) ;

    return ret ;
}


/*-------------------------------------------------------------------------*/
/* XXX */
void BucketHugeArrayUnlock(void *elemPtr)
{
    /* Do the real unlock */
    HugeArrayUnlock(elemPtr) ;

    /* Now do the bucket unlock for this pointer */
    IBucketUnlock(IFindAndRemoveLock(elemPtr)) ;
}

/*-------------------------------------------------------------------------*/
void BucketHugeArrayDirty(const void *elemPtr)
{
    HugeArrayDirty(elemPtr) ;
}

/*-------------------------------------------------------------------------*/
/* XXX */
void BucketsStart(char *dirname)
{
    word i ;
    T_bucketIndexMapBlock *newMap ;
    MemHandle mapMem ;

    /* Reset the global variables */
    G_numLocks = 0 ;
    memset(G_bucketArray, 0, sizeof(G_bucketArray)) ;
    for (i=0; i<MAX_BUCKETS_OPEN; i++)  {
        G_bucketArray[i].B_arrayID = BUCKET_HUGE_ARRAY_HANDLE_BAD ;
        G_bucketArray[i].B_nf.freeLink = i+1 ;
    }
    G_bucketArray[MAX_BUCKETS_OPEN-1].B_nf.freeLink = FREE_LINK_NONE ;
    memset(G_bucketLocks, 0, sizeof(G_bucketLocks)) ;

    /* Create the subdirectory for the files */
    FilePushDir() ;
    FileSetStandardPath(SP_PRIVATE_DATA) ;
    strcpy(G_path, dirname) ;
    FileCreateDir(G_path);
    FileSetCurrentPath(SP_PRIVATE_DATA, G_path);

    /* Open/create the index file */
    G_indexFile = VMOpen(
                      BUCKET_INDEX_FILENAME,
                      VMAF_FORCE_READ_WRITE | VMAF_FORCE_DENY_WRITE,
                      VMO_OPEN,
                      0);
    if (!G_indexFile)  {
        /* Create a new index file */
        FileDelete(BUCKET_INDEX_FILENAME) ;
        G_indexFile = VMOpen(
                          BUCKET_INDEX_FILENAME,
                          VMAF_FORCE_READ_WRITE | VMAF_FORCE_DENY_WRITE,
                          VMO_CREATE,
                          0);
        G_bucketsMapBlock = VMAlloc(G_indexFile, sizeof(*newMap), 0);
        VMSetMapBlock(G_indexFile, G_bucketsMapBlock) ;
        newMap = VMLock(G_indexFile, G_bucketsMapBlock, &mapMem) ;
        newMap->BIMB_nextUniqueArrayID = 0 ;
        G_nextID = 0 ;
        VMUnlock(mapMem) ;
    } else {
        VMRevert(G_indexFile);

        G_bucketsMapBlock = VMGetMapBlock(G_indexFile) ;

        /* Copy the index over to memory so we don't have to keep locking */
        newMap = VMLock(G_indexFile, G_bucketsMapBlock, &mapMem) ;
        G_nextID = newMap->BIMB_nextUniqueArrayID ;
        VMUnlock(mapMem) ;
    }

    FilePopDir() ;
}

/*-------------------------------------------------------------------------*/
/* XXX */
void BucketsEnd(void)
{
    T_bucketIndexMapBlock *p_map ;
    MemHandle mapMem ;

    IBucketEnsureAllFilesClose() ;

    EC_ERROR_IF(G_numLocks > 0, ERROR_BUCKETS_STILL_HAVE_LOCKS) ;
    EC_ERROR_IF(G_numOpenFiles > 0, ERROR_BUCKETS_FILES_STILL_OPEN) ;

    /* Store the index */
    p_map = VMLock(G_indexFile, G_bucketsMapBlock, &mapMem) ;
    p_map->BIMB_nextUniqueArrayID = G_nextID ;
    VMDirty(mapMem) ;
    VMUnlock(mapMem) ;

    VMSave(G_indexFile) ;
    VMClose(G_indexFile, FALSE) ;
}

/*-------------------------------------------------------------------------*/
T_bucket *IBucketFind(VMFileHandle vmFile, BucketHugeArrayHandle array)
{
    word i ;
    T_bucket *p_bucket ;
    T_bucket *p_foundBucket = NULL ;

    p_bucket = G_bucketArray ;
    for (i=0; i<MAX_BUCKETS_OPEN; i++, p_bucket++)  {
        if ((p_bucket->B_arrayID == array) &&
            (p_bucket->B_ownerFile == vmFile))  {
            p_foundBucket = p_bucket ;
            break ;
        }
    }

    return p_foundBucket ;
}

/*-------------------------------------------------------------------------*/
T_bucket *IBucketAlloc(void)
{
    T_bucket *newBucket ;

    /* If we are at our limit, make sure any other ones are out of the way */
    if (G_numOpenFiles >= MAX_BUCKETS_OPEN)
        IBucketCloseOldestFiles() ;

    if (G_firstFreeBucket != FREE_LINK_NONE)  {
        newBucket = G_bucketArray + G_firstFreeBucket ;
        G_firstFreeBucket = newBucket->B_nf.freeLink ;
        newBucket->B_nf.numLocks = 0 ;
    } else {
        newBucket = NULL ;
    }
    G_numLocks++ ;

    EC_ERROR_IF(newBucket == NULL, ERROR_BUCKETS_TOO_MANY_FILES_OPENED) ;
    return newBucket ;
}

/*-------------------------------------------------------------------------*/
void IBucketFree(word bucketIndex)
{
    T_bucket *p_bucket ;

    p_bucket = G_bucketArray + bucketIndex ;
    p_bucket->B_arrayID = BUCKET_HUGE_ARRAY_HANDLE_BAD ;
    p_bucket->B_nf.freeLink = G_firstFreeBucket ;
    G_firstFreeBucket = bucketIndex ;

    G_numLocks-- ;
}

/*-------------------------------------------------------------------------*/
T_bucket *IBucketOpen(BucketHugeArrayHandle arrayMajorID)
{
    T_bucket *p_bucket ;
    FileLongName name ;

    p_bucket = IBucketAlloc() ;
    if (p_bucket)  {
        p_bucket->B_arrayID = arrayMajorID ;

        /* Now open the file based on the ID */
        sprintf(name, BUCKET_NAME_FORMAT, arrayMajorID) ;
        FilePushDir() ;
        FileSetCurrentPath(SP_PRIVATE_DATA, G_path);
        p_bucket->B_realFile =
            VMOpen(name, VMAF_FORCE_READ_WRITE, VMO_OPEN, 0) ;
        if (p_bucket->B_realFile == NullHandle)  {
            p_bucket->B_realFile = IBucketCreate(name) ;
        } else {
            VMRevert(p_bucket->B_realFile) ;
        }

        p_bucket->B_mapBlock = VMGetMapBlock(p_bucket->B_realFile) ;
        FilePopDir() ;

        p_bucket->B_openID = G_openID++ ;
        p_bucket->B_nf.numLocks = 1 ;
        G_numOpenFiles++ ;
    }

    return p_bucket ;
}

/*-------------------------------------------------------------------------*/
void IBucketClose(T_bucket *p_bucket)
{
    if (p_bucket)  {
        EC_ERROR_IF(
            p_bucket->B_nf.numLocks != 0,
            ERROR_BUCKETS_ARRAY_CANT_CLOSE_LOCKED_BUCKET) ;

        if(p_bucket) {

            BucketHugeArrayHandle  array ;
            word arrayCount ;
            word loopCount ;
            T_bucketMap *p_map ;
            MemHandle mapBlock ;

            array = p_bucket->B_arrayID ;

            p_map = VMLock(p_bucket->B_realFile, p_bucket->B_mapBlock, &mapBlock) ;
            arrayCount = 0 ;
            loopCount = 0 ;

            while(loopCount < ARRAYS_PER_BUCKET) {

                if(p_map->arrayList[loopCount])
                    arrayCount++ ;
            
                loopCount++ ;
            }

            VMUnlock(mapBlock) ;
            
            IBucketUnlock(p_bucket) ;

            /* Close the bucket here */
            VMClose(p_bucket->B_realFile, FALSE) ;
            p_bucket->B_realFile = NullHandle ;

            if(!arrayCount) {
    
                FileLongName name;

                /* Now open the file based on the ID */
                sprintf(name, BUCKET_NAME_FORMAT, array) ;

                FilePushDir() ;
                FileSetCurrentPath(SP_PRIVATE_DATA, G_path);
                
                FileDelete(name) ;
            
                FilePopDir() ;
            }
        }

        IBucketFree(p_bucket - G_bucketArray) ;

        G_numOpenFiles-- ;
        G_numOpenFreeFiles-- ;
    }
}

/*-------------------------------------------------------------------------*/
T_bucket *IBucketLock(
                  VMFileHandle vmFile,
                  BucketHugeArrayHandle array)
{
    T_bucket *p_bucket ;

    array = BUCKET_HUGE_ARRAY_GET_MAJOR(array) ;

    p_bucket = IBucketFind(vmFile, array) ;
    if (!p_bucket)  {
        p_bucket = IBucketOpen(array) ;
        p_bucket->B_ownerFile = vmFile ;
    } else {
        /* Touched the file, make it more recent than rest in list */
        /* to keep it cached */
        p_bucket->B_openID = G_openID++ ;
        if (p_bucket->B_nf.numLocks == 0)
            G_numOpenFreeFiles-- ;
        p_bucket->B_nf.numLocks++ ;
    }

    return p_bucket ;
}

/*-------------------------------------------------------------------------*/
void IBucketUnlock(T_bucket *p_bucket)
{
    if (p_bucket)  {
        if ((--p_bucket->B_nf.numLocks)==0)  {
            G_numOpenFreeFiles++ ;
            if (G_numOpenFreeFiles >= BUCKETS_NUM_FREE_FILES_ALWAYS_OPEN)  {
                IBucketCloseOldestFiles() ;
            }
        }
    }
}

/*-------------------------------------------------------------------------*/
void IAddLock(void *p_data, T_bucket *p_bucket)
{
    word i ;

    for (i=0; i<MAX_BUCKET_LOCKS; i++)
        if (G_bucketLocks[i].p_ptr == NULL)
            break ;

    EC_ERROR_IF(i>=MAX_BUCKET_LOCKS, ERROR_BUCKETS_TOO_MANY_LOCKS) ;

    G_bucketLocks[i].p_ptr = p_data ;
    G_bucketLocks[i].p_bucket = p_bucket ;

    G_numLocks++ ;
}

/*-------------------------------------------------------------------------*/
T_bucket *IFindAndRemoveLock(void *p_data)
{
    T_bucket *p_bucket = NULL ;
    word i ;

    for (i=0; i<MAX_BUCKET_LOCKS; i++)
        if (G_bucketLocks[i].p_ptr == p_data)  {
            p_bucket = G_bucketLocks[i].p_bucket ;
            G_bucketLocks[i].p_ptr = NULL ;
            G_numLocks-- ;
            break ;
        }

    return p_bucket ;
}

/*-------------------------------------------------------------------------*/
VMBlockHandle IBucketLookup(T_bucket *p_bucket, dword arrayID)
{
    MemHandle mapBlock ;
    T_bucketMap *p_map ;
    VMBlockHandle foundArray = NullHandle ;

    if (p_bucket)  {
        p_map = VMLock(p_bucket->B_realFile, p_bucket->B_mapBlock, &mapBlock) ;
        foundArray = p_map->arrayList[BUCKET_HUGE_ARRAY_GET_MINOR(arrayID)] ;
        VMUnlock(mapBlock) ;
    }

    return foundArray ;
}

/*-------------------------------------------------------------------------*/
void IBucketEnsureClose(T_bucket *p_bucket)
{
    if (p_bucket->B_realFile)
        IBucketClose(p_bucket) ;
}

/*-------------------------------------------------------------------------*/
void IBucketSave(T_bucket *p_bucket)
{
    if (p_bucket->B_realFile)
    {
        VMSave(p_bucket->B_realFile) ;
    }
}

/*-------------------------------------------------------------------------*/
void IBucketEnsureAllFilesClose(void)
{
    word i ;

    for (i=0; i<MAX_BUCKETS_OPEN; i++)
        IBucketEnsureClose(G_bucketArray + i) ;
}

/*-------------------------------------------------------------------------*/
void BucketHugeArraySave(void)
{
    word i ;
    MemHandle mapMem ;
    T_bucketIndexMapBlock *p_map ;

    for (i=0; i<MAX_BUCKETS_OPEN; i++)
        IBucketSave(G_bucketArray + i) ;

    p_map = VMLock(G_indexFile, G_bucketsMapBlock, &mapMem) ;
    p_map->BIMB_nextUniqueArrayID = G_nextID ;
    VMDirty(mapMem) ;
    VMUnlock(mapMem) ;

    VMSave(G_indexFile) ;
}

/*-------------------------------------------------------------------------*/
void IBucketCloseOldestFiles(void)
{
    word i ;
    word oldest ;
    dword oldestID ;
    T_bucket *p_bucket ;

    while (G_numOpenFreeFiles > BUCKETS_NUM_FREE_FILES_ALWAYS_OPEN)  {
        oldest = 0xFFFF ;
        oldestID = 0xFFFFFFFF ;
        p_bucket = G_bucketArray ;
        for (i=0; i<MAX_BUCKETS_OPEN; i++, p_bucket++)  {
            if ((p_bucket->B_realFile) && (!p_bucket->B_nf.numLocks))  {
                if (p_bucket->B_openID < oldestID)  {
                    oldestID = p_bucket->B_openID ;
                    oldest = i ;
                }
            }
        }

        if (oldest == 0xFFFF)
            break ;

        IBucketClose(G_bucketArray + oldest) ;
    }
}

/*-------------------------------------------------------------------------*/
VMFileHandle IBucketCreate(char *name)
{
    VMFileHandle file ;
    VMBlockHandle map ;
    MemHandle mapBlock ;
    T_bucketMap *p_map ;

    file = VMOpen(
               name,
               VMAF_FORCE_READ_WRITE | VMAF_FORCE_DENY_WRITE,
               VMO_CREATE,
               0);
    if (file)  {
        map = VMAlloc(file, sizeof(*p_map), 0) ;
        p_map = VMLock(file, map, &mapBlock) ;

        /* Make everything null handles */
        memset(p_map, 0, sizeof(*p_map)) ;

        VMDirty(mapBlock) ;
        VMUnlock(mapBlock) ;
        VMSetMapBlock(file, map) ;
        VMSave(file) ;
    }

    return file ;
}

