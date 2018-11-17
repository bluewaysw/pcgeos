extern void MapHeapEnter(void);
extern void MapHeapLeave(void);
extern int MapHeapCreate(void);
extern void MapHeapDestroy(void);
extern Boolean MapHeapMaybeInHeap(void *blockPtr);
extern void *MapHeapMalloc(word blockSize);
extern void MapHeapFree(void *blockPtr);
extern void *MapHeapRealloc(void *blockPtr, word newSize);
extern ChunkHandle LMemLockAllocAndReturnError(MemHandle block,
    word chunkSize);
extern ChunkHandle LMemLockReAllocAndReturnError(optr chunkOptr,
    word chunkSize);
