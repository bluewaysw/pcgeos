extern void _cdecl MapHeapEnter(MemHandle phyMemInfoBlk);
extern void _cdecl MapHeapLeave(void);
extern Boolean _cdecl MapHeapCreate(char permName[GEODE_NAME_SIZE],
				MemHandle *phyMemInfoBlk);
extern void _cdecl MapHeapDestroy(MemHandle phyMemInfoBlk);
extern Boolean _cdecl MapHeapMaybeInHeap(void *blockPtr);
extern void *_cdecl MapHeapMalloc(word blockSize);
extern void _cdecl MapHeapFree(void *blockPtr);
extern void *_cdecl MapHeapRealloc(void *blockPtr, word newSize);
extern ChunkHandle _cdecl LMemLockAllocAndReturnError(MemHandle block,
    word chunkSize);
extern ChunkHandle _cdecl LMemLockReAllocAndReturnError(optr chunkOptr,
    word chunkSize);
