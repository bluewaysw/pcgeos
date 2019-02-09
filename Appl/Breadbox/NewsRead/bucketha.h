typedef dword BucketHugeArrayHandle ;
#define BUCKET_HUGE_ARRAY_HANDLE_BAD         (0xFFFFFFFF)

extern void BucketsStart(char *dirname) ;
extern void BucketsEnd(void) ;

extern BucketHugeArrayHandle
    BucketHugeArrayCreate(
        VMFileHandle vmFile,
        word elemSize,
        word headerSpace) ;

extern void
    BucketHugeArrayDestroy(
        VMFileHandle vmFile,
        BucketHugeArrayHandle vmBlock) ;

extern dword
    BucketHugeArrayLock(
        VMFileHandle vmFile,
        BucketHugeArrayHandle vmBlock,
	    dword elemNum,
        void **elemPtr,
        word *elemSize);


extern void
    BucketHugeArrayUnlock(
        void *elemPtr);

extern dword
    BucketHugeArrayAppend(
        VMFileHandle vmFile,
        BucketHugeArrayHandle vmBlock,
		word numElem,
        const void *initData);

extern void
    BucketHugeArrayInsert(
        VMFileHandle vmFile,
        BucketHugeArrayHandle vmBlock,
		word numElem,
        dword elemNum,
        const void *initData);

extern void
    BucketHugeArrayDelete(
        VMFileHandle vmFile,
        BucketHugeArrayHandle vmBlock,
		word numElem,
        dword elemNum);

extern dword
    BucketHugeArrayGetCount(
        VMFileHandle vmFile,
        BucketHugeArrayHandle vmBlock);


extern void
    BucketHugeArrayDirty(
        const void *elemPtr);

extern void
    BucketHugeArraySave(void);

extern dword BucketHugeArrayTextSearch(char *str2, word str2Size,
				       dword str1Size, dword curOffset,
				       dword endOffset, 
				       FileHandle hugeArrayFile,
					   BucketHugeArrayHandle arrayID,
				       word searchOptions, 
				       dword *matchLen) ;
