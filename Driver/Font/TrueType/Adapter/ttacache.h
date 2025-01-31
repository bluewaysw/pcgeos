#ifndef _TTACACHE_H_
#define _TTACACHE_H_

#include <geos.h>
#include "ttadapter.h"

#define TRUETYPE_CACHE_MAX_BUF_ENTRIES 10

typedef struct {
    WWFixedAsDWord 	TTCBS_pointSize;
    byte 		TTCBS_width;
    byte 		TTCBS_weight;
    TextStyle 		TTCBS_stylesToImplement;
} TrueTypeCacheBufSpec;

typedef struct {
    TrueTypeCacheBufSpec	TTCBE_spec;
    word			TTCBE_bufSize;
    VMBlockHandle		TTCBE_block;
} TrueTypeCacheBufEntry;

typedef struct {
    TCHAR			TTCE_ttfFileName[FILE_LONGNAME_BUFFER_SIZE];
    dword			TTCE_ttfFileSize;
    word			TTCE_magicWord;
    FontHeader			TTCE_fontHeader;
    byte			TTCE_bufEntryCount;
    TrueTypeCacheBufEntry	TTCE_bufEntry[TRUETYPE_CACHE_MAX_BUF_ENTRIES];
} TrueTypeCacheDirEntry;


VMFileHandle _pascal TrueType_Cache_Init();

void _pascal TrueType_Cache_Exit(VMFileHandle cacheFile);

Boolean _pascal TrueType_Cache_LoadFontBlock(
		VMFileHandle cacheFile, const TCHAR* fontFileName,
		dword fontFileSize, word fontFileMagic, 
		TrueTypeCacheBufSpec* bufSpec, MemHandle *fontHandle
);

void _pascal TrueType_Cache_UpdateFontBlock(VMFileHandle cacheFile, const TCHAR* fontFileName,
		dword fontFileSize, word fontFileMagic, 
		TrueTypeCacheBufSpec* bufSpec, MemHandle fontBuf);

Boolean _pascal TrueType_Cache_ReadHeader(VMFileHandle cacheFile, const TCHAR* fontFileName, 
		dword fontFileSize, word fontMagic, FontHeader* headerPtr);

void _pascal TrueType_Cache_WriteHeader(VMFileHandle cacheFile, const TCHAR* fontFileName, 
                        dword fontFileSize, word fontMagic, FontHeader* headerPtr);

#endif /* _TTCACHE_H_ */