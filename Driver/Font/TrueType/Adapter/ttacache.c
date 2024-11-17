#include <geos.h>
#include <vm.h>
#include <file.h>
#include <geode.h>
#include "ttacache.h"
#include <Ansi/string.h>

VMFileHandle _pascal TrueType_Cache_Init() {

	VMFileHandle cacheFile;
	TCHAR cacheFileName[] = "TTF Cache";

	/* Try to open/create TTF cache VM file */
	FilePushDir();
	FileSetStandardPath(SP_PRIVATE_DATA);
	cacheFile = VMOpen(cacheFileName, VMAF_FORCE_READ_WRITE, VMO_OPEN, 0);
	if( cacheFile == NullHandle ) {
		cacheFile = VMOpen(cacheFileName, VMAF_FORCE_READ_WRITE, VMO_CREATE, 0);
	}
	if( cacheFile != NullHandle ) {
		HandleModifyOwner(cacheFile, GeodeGetCodeProcessHandle());
	}
	FilePopDir();

	return cacheFile;
}

static char* strcpy( char* dest, const char* source )
{
        while( (*dest++ = *source++) != '\0' );
        return dest;
}

static int strcmp( const char* s1, const char* s2 )
{
        while ( *s1 && ( *s1 == *s2 ) )
        {
                ++s1;
                ++s2;
        }
        return *(const unsigned char*)s1 - *(const unsigned char*)s2;
}

void _pascal TrueType_Cache_Exit(VMFileHandle cacheFile) {
    
    VMSave(cacheFile);
    VMClose(cacheFile, FILE_NO_ERRORS);	
}

Boolean _pascal TrueType_Cache_LoadFontBlock(VMFileHandle cacheFile, const TCHAR* fontFileName,
		TrueTypeCacheBufSpec* bufSpec, MemHandle* fontHandle) {
    VMBlockHandle dirBlock;

    dirBlock = VMGetMapBlock(cacheFile);
    if( dirBlock != NullHandle ) {

	VMInfoStruct vmInfo;

	if ( VMInfo(cacheFile, dirBlock, &vmInfo) ) {

	    MemHandle dirMem;
	    TrueTypeCacheDirEntry* dirEntry;
	    word entryCount = vmInfo.size / sizeof(TrueTypeCacheDirEntry);
	    word loopCount = 0;

	    dirEntry = VMLock(cacheFile, dirBlock, &dirMem);
	
	    while( loopCount < entryCount ) {

		if( strcmp(dirEntry[loopCount].TTCE_ttfFileName, fontFileName) == 0 ) {

		    word loopCount2 = 0;

		    while(loopCount2 < dirEntry[loopCount].TTCE_bufEntryCount) {

			if( (dirEntry[loopCount].TTCE_bufEntry[loopCount2].TTCBE_spec.TTCBS_pointSize == bufSpec->TTCBS_pointSize) &&
				(dirEntry[loopCount].TTCE_bufEntry[loopCount2].TTCBE_spec.TTCBS_width == bufSpec->TTCBS_width) &&
				(dirEntry[loopCount].TTCE_bufEntry[loopCount2].TTCBE_spec.TTCBS_weight == bufSpec->TTCBS_weight) &&
				(dirEntry[loopCount].TTCE_bufEntry[loopCount2].TTCBE_spec.TTCBS_stylesToImplement == bufSpec->TTCBS_stylesToImplement) 
			) {

			    MemHandle blockMem;
			    word size = dirEntry[loopCount].TTCE_bufEntry[loopCount2].TTCBE_bufSize;
			    VMBlockHandle block = dirEntry[loopCount].TTCE_bufEntry[loopCount2].TTCBE_block;
			    
			    VMUnlock(dirMem);

			    /* found block, alloc */
			    if( *fontHandle == NullHandle )
			    {
				*fontHandle = MemAllocSetOwner( FONT_MAN_ID, MAX( size, MAX_FONTBUF_SIZE ), 
						HF_SWAPABLE | HF_SHARABLE,
						HAF_NO_ERR | HAF_LOCK | HAF_ZERO_INIT );
EC(             		ECCheckMemHandle( *fontHandle ) );
				HandleP( *fontHandle );
			    }
			    else
			    {
				MemReAlloc( *fontHandle, MAX( size, MAX_FONTBUF_SIZE ), HAF_NO_ERR | HAF_LOCK );
EC(             		ECCheckMemHandle( *fontHandle ) );
			    }

			    {
				byte* srcPtr = VMLock(cacheFile, block, &blockMem);
				byte* destPtr = MemLock(*fontHandle);
				memcpy(destPtr, srcPtr, size);
				MemUnlock(*fontHandle);
				VMUnlock(blockMem);
			    }

			    return TRUE;
			}
			loopCount2++;
		    }		

		}
		loopCount++;
	    }
	    VMUnlock(dirMem);
	}
    }
    return FALSE;
}

void _pascal TrueType_Cache_UpdateFontBlock(VMFileHandle cacheFile, const TCHAR* fontFileName,
		TrueTypeCacheBufSpec* bufSpec, MemHandle fontBuf) {

    VMBlockHandle dirBlock;

    dirBlock = VMGetMapBlock(cacheFile);
    if( dirBlock != NullHandle ) {

	VMInfoStruct vmInfo;

	if ( VMInfo(cacheFile, dirBlock, &vmInfo) ) {

		MemHandle dirMem;
		TrueTypeCacheDirEntry* dirEntry;
		word entryCount = vmInfo.size / sizeof(TrueTypeCacheDirEntry);
		word loopCount = 0;

		dirEntry = VMLock(cacheFile, dirBlock, &dirMem);
	
		while( loopCount < entryCount ) {

		if( strcmp(dirEntry[loopCount].TTCE_ttfFileName, fontFileName) == 0 ) {

			word loopCount2 = 0;
			word memSize = MemGetInfo(fontBuf, MGIT_SIZE);

			while(loopCount2 < dirEntry[loopCount].TTCE_bufEntryCount) {

			if( (dirEntry[loopCount].TTCE_bufEntry[loopCount2].TTCBE_spec.TTCBS_pointSize == bufSpec->TTCBS_pointSize) &&
				(dirEntry[loopCount].TTCE_bufEntry[loopCount2].TTCBE_spec.TTCBS_width == bufSpec->TTCBS_width) &&
				(dirEntry[loopCount].TTCE_bufEntry[loopCount2].TTCBE_spec.TTCBS_weight == bufSpec->TTCBS_weight) &&
				(dirEntry[loopCount].TTCE_bufEntry[loopCount2].TTCBE_spec.TTCBS_stylesToImplement == bufSpec->TTCBS_stylesToImplement) 
			) {

				/* update if new/current block is large*/
				if(TRUE/*memSize > dirEntry[loopCount].TTCE_bufEntry[loopCount2].TTCBE_bufSize*/) {
					
					VMBlockHandle thisBlock = dirEntry[loopCount].TTCE_bufEntry[loopCount2].TTCBE_block;
					MemHandle blockMem;

					dirEntry[loopCount].TTCE_bufEntry[loopCount2].TTCBE_bufSize = memSize;
					VMDirty(dirMem);
					VMUnlock(dirMem);

					VMLock(cacheFile, thisBlock, &blockMem);
					MemReAlloc(blockMem, memSize, HAF_NO_ERR);
					{
						byte* destPtr = MemDeref(blockMem);

						byte* srcPtr = MemLock(fontBuf);
						memcpy(destPtr, srcPtr, memSize);
						MemUnlock(fontBuf);
						VMDirty(blockMem);
						VMUnlock(blockMem);
						VMSave(cacheFile);
					}
				} else {
					VMUnlock(dirMem);
				}
				return;
			}
			loopCount2++;
			}		
			/* not found append entry if free slots*/
			if(loopCount2 < TRUETYPE_CACHE_MAX_BUF_ENTRIES) {

			VMBlockHandle newBlock = VMAlloc(cacheFile, memSize, 0);
			if( newBlock != NullHandle ) {
				dirEntry[loopCount].TTCE_bufEntry[loopCount2].TTCBE_spec = *bufSpec;
				dirEntry[loopCount].TTCE_bufEntry[loopCount2].TTCBE_block = newBlock;
				dirEntry[loopCount].TTCE_bufEntry[loopCount2].TTCBE_bufSize = memSize;
				dirEntry[loopCount].TTCE_bufEntryCount++;
				VMDirty(dirMem);
			}
			VMUnlock(dirMem);
			if( newBlock != NullHandle ) {

				MemHandle newBlockMem;
				byte* destPtr = VMLock(cacheFile, newBlock, &newBlockMem);
				/* fill in the block */
				byte* srcPtr = MemLock(fontBuf);
				memcpy(destPtr, srcPtr, memSize);
				MemUnlock(fontBuf);
				VMDirty(newBlockMem);
				VMUnlock(newBlockMem);
			}
			return;
			}
			break;
		}
		loopCount++;
		}
	    VMUnlock(dirMem);
	}
    }
}

Boolean _pascal TrueType_Cache_ReadHeader(VMFileHandle cacheFile, const TCHAR* fontFileName, FontHeader* headerPtr) {
    
    VMBlockHandle dirBlock;
    Boolean result = FALSE;

    dirBlock = VMGetMapBlock(cacheFile);
    if ( dirBlock != NullHandle ) {
	VMInfoStruct vmInfo;

	if ( VMInfo(cacheFile, dirBlock, &vmInfo) ) {

	    MemHandle dirMem;
	    TrueTypeCacheDirEntry* dirEntry;
	    word entryCount = vmInfo.size / sizeof(TrueTypeCacheDirEntry);
	    word loopCount = 0;

	    dirEntry = VMLock(cacheFile, dirBlock, &dirMem);

	    while( loopCount < entryCount ) {

		if( strcmp(dirEntry[loopCount].TTCE_ttfFileName, fontFileName) == 0 ){

			*headerPtr = dirEntry[loopCount].TTCE_fontHeader;
			result = TRUE;
			break;
		}
	    	loopCount++;
	    }

	    VMUnlock(dirMem);
	}
    }
    return result;
}

void _pascal TrueType_Cache_WriteHeader(VMFileHandle cacheFile, const TCHAR* fontFileName, FontHeader* headerPtr) {
    
    VMBlockHandle dirBlock;

    dirBlock = VMGetMapBlock(cacheFile);
    if ( dirBlock == NullHandle ) {
	
	MemHandle dirMem;
	TrueTypeCacheDirEntry* dirEntry;

	/* handle first entry */
	dirBlock = VMAlloc(cacheFile, sizeof(TrueTypeCacheDirEntry), 0);
	VMSetMapBlock(cacheFile, dirBlock);

	dirEntry = VMLock(cacheFile, dirBlock, &dirMem);
	dirEntry->TTCE_bufEntryCount = 0;
	strcpy(dirEntry->TTCE_ttfFileName, fontFileName);
	dirEntry->TTCE_fontHeader = *headerPtr;

	VMDirty(dirMem);
	VMUnlock(dirMem);

    } else {

	VMInfoStruct vmInfo;

	if ( VMInfo(cacheFile, dirBlock, &vmInfo) ) {
	    
	    TrueTypeCacheDirEntry* dirEntry;
	    MemHandle dirMem;
	    word entryCount = vmInfo.size / sizeof(TrueTypeCacheDirEntry);

	    VMLock(cacheFile, dirBlock, &dirMem);

	    /* handle append */
	    MemReAlloc(dirMem, sizeof(TrueTypeCacheDirEntry) * (entryCount + 1), HAF_NO_ERR | HAF_ZERO_INIT);
	    dirEntry = MemDeref(dirMem);
	    
	    strcpy(dirEntry[entryCount].TTCE_ttfFileName, fontFileName);
	    dirEntry[entryCount].TTCE_fontHeader = *headerPtr;
	    
	    VMDirty(dirMem);
	    VMUnlock(dirMem);
	}
    }
}
