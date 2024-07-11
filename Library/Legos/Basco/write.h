/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	Legos
MODULE:		Code saving
FILE:		write.h

AUTHOR:		Paul L. DuBois, Jan 10, 1995

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	 1/10/95	Initial version.

DESCRIPTION:
	

	$Id: write.h,v 1.1 98/10/13 21:44:03 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#ifndef _WRITE_H_
#define _WRITE_H_

#include <geos.h>
#include <Legos/Internal/fformat.h>

/* Top-level file manipulation routines.
 */
extern Boolean Write_WriteBC(TCHAR* name, MemHandle taskHan);
extern Boolean Write_WriteBCL(TCHAR* name, MemHandle taskHan);

extern VMFileHandle WriteInitFile(TCHAR* fileName);
extern void WriteAddHeader(VMFileHandle vmfh, MemHandle codeHeaderH);
extern word WriteAddPage(VMFileHandle vmfh, MemHandle page, word pageNum);
extern void WriteAddComplex(VMFileHandle resFile, RunHeapToken rht,
			    RunHeapInfo* rhi);
extern void WriteAddComplexForLiberty(VMFileHandle resFile, RunHeapToken rht,
			    RunHeapInfo* rhi, dword *pos);
extern void WriteCloseFile(VMFileHandle vmfh);

/* These create headers/pages to be written out to a file.
 */
extern MemHandle WriteCreateHeader(TaskPtr task, int *size, word pageSize);

#define MAX_CODE_PAGE_SIZE  0x2000

extern MemHandle WriteCreatePage(TaskPtr task, int *size, int *start, 
				 word	 maxSize);

/* These routines take a handle to a _locked_ block and a pointer to the
 * size; the size will be fixed up, and the block resized (be sure to
 * re-deref the handle after calling).
 * They're also internal, but I don't want to create a writeint.h.
 */
extern void Write_AddGlobalVarTable(MemHandle, word*, TaskPtr);
extern void Write_AddFuncTable(MemHandle, word*, TaskPtr task, word pageSize);
extern void Write_AddSTable(MemHandle, word*, PageMarker, optr stable,
			    TaskPtr, Boolean addIndex);
extern void Write_AddStructInfo(MemHandle, word*, TaskPtr);
extern Boolean Write_AddFunc(MemHandle, word*, TaskPtr, word funcNum);

#define APPEND_PAGE 0xffff
#define CODE_FILE_REVISION	2
typedef struct {
    LMemBlockHeader	CFH_meta;
    word		CFH_revision;	/* So we don't shoot ourselves */
    VMBlockHandle	CFH_header;	/* Block containing "title page" */
    ChunkHandle		CFH_pageArray;
    ChunkHandle		CFH_complexDataArray; /* array of dwords */
} CodeFileHeader;

/* Keep this in line with driver/vmfi/vmfi.def */
typedef struct {
    dword	CDE_format;	/* ClipboardItemFormatID */
    VMChain	CDE_chain;
} ComplexDataElt;

/* requires local variables: page, pageHan, size */
#define PAGE_EXPAND(_size)					\
 MemReAlloc(pageHan, *size+(_size), HAF_NO_ERR);		\
 page = MemDeref(pageHan);

/* Pretty sure this will _not_ work with parens, due to weird
 * definition of sizeof operator
 */
#define PAGE_APPEND_THING(_thing)				\
 MemReAlloc(pageHan, *size+(sizeof _thing), HAF_NO_ERR);	\
 page = MemDeref(pageHan);					\
 memcpy(page+*size, &_thing, sizeof _thing);			\
 *size += sizeof _thing;

#define PAGE_APPEND_BYTE(_byte) \
 MemReAlloc(pageHan, *size+1, HAF_NO_ERR);			\
 page = MemDeref(pageHan);					\
 page[*size] = (_byte);						\
 *size += 1;

#define PAGE_APPEND_WORD(_word) \
 MemReAlloc(pageHan, *size+2, HAF_NO_ERR);			\
 page = MemDeref(pageHan);					\
 *( (word*) (page+*size) ) = (_word);				\
 if (BIG_ENDIAN) swapWord((word*)(page+*size));                       \
 *size += 2;

#define PAGE_APPEND_DWORD(_dword) \
 MemReAlloc(pageHan, *size+4, HAF_NO_ERR);			\
 page = MemDeref(pageHan);					\
 *( (dword*) (page+*size) ) = (_dword);				\
 if (BIG_ENDIAN) swapDword((dword*)(page+*size));                      \
 *size += 4;


#endif /* _WRITE_H_ */

