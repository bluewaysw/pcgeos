/***********************************************************************
 *
 *      Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved
 *
 * PROJECT:     PC GEOS
 * FILE:        chunkarr.h
 * AUTHOR:      Tony Requist: February 1, 1991
 *
 * DECLARER:    Kernel
 *
 * DESCRIPTION:
 *      This file defines chunk array structures and routines.
 *
 *      $Id: chunkarr.h,v 1.1 97/04/04 15:56:54 newdeal Exp $
 *
 ***********************************************************************/

#ifndef __CHUNKARR_H
#define __CHUNKARR_H

#include <object.h>

/*
 *      Constants and Structures
 */

#define CA_NULL_ELEMENT     0xffff

#define CA_LAST_ELEMENT     0xff00

typedef struct {
    word        CAH_count;
    word        CAH_elementSize;
    word        CAH_curOffset;
    word        CAH_offset;
} ChunkArrayHeader;

#define EA_FREE_LIST_TERMINATOR CA_NULL_ELEMENT

typedef struct {
    ChunkArrayHeader    EAH_meta;
    word                EAH_freePtr;
} ElementArrayHeader;

typedef struct {
    WordAndAHalf        REH_refCount;
} RefElementHeader;

/***/

extern ChunkHandle      /*XXX*/
    _pascal ChunkArrayCreateAt(optr arr, word elementSize, word headerSize,
				ObjChunkFlags ocf);

#define ChunkArrayCreateAtHandles(mh, ch, esize, hsize, ocf)    \
	ChunkArrayCreateAt(ConstructOptr(mh, ch), esize, hsize, ocf)

#define ChunkArrayCreate(mh, esize, hsize, ocf) \
	ChunkArrayCreateAt(HandleToOptr(mh), esize, hsize, ocf)

/***/

extern void *   /*XXX*/
    _pascal ChunkArrayElementToPtr(optr arr, word elementNumber, word *elementSize);

#define ChunkArrayElementToPtrHandles(mh, ch, en, es) \
	ChunkArrayElementToPtr(ConstructOptr(mh, ch), en, es)

/***/

extern word     /*XXX*/
    _pascal ChunkArrayPtrToElement(optr arr, void *element);

#define ChunkArrayPtrToElementHandle(ch, el) \
	ChunkArrayPtrToElement(ConstructOptr(0, ch), el)

/***/

extern void     /*XXX*/
    _pascal ChunkArrayGetElement(optr arr, word elementNumber, void *buffer);

#define ChunkArrayGetElementHandles(mh, ch, en, buf) \
		ChunkArrayGetElement(ConstructOptr(mh, ch), en, buf)

/***/

extern void *   /*XXX*/
    _pascal ChunkArrayAppend(optr arr, word elementSize);

#define ChunkArrayAppendHandles(mh, ch, es) \
		ChunkArrayAppend(ConstructOptr(mh, ch), es)

/***/

extern void *   /*XXX*/
    _pascal ChunkArrayInsertAt(optr arr, void *insertPointer, word elementSize);

#define ChunkArrayInsertAtHandle(ch, ip, es) \
		ChunkArrayInsertAt(ConstructOptr(0, ch), ip, es)

/***/

extern void     /*XXX*/
    _pascal ChunkArrayDelete(optr arr, void *element);

#define ChunkArrayDeleteHandle(ch, el) \
		ChunkArrayDelete(ConstructOptr(0, ch), el)

/***/

extern void     /*XXX*/
    _pascal ChunkArrayDeleteRange(optr arr, word firstElement, word count);

/***/

extern word     /*XXX*/
    _pascal ChunkArrayGetCount(optr arr);

#define ChunkArrayGetCountHandles(mh, ch) \
		ChunkArrayGetCount(ConstructOptr(mh, ch))

/***/

extern void     /*XXX*/
    _pascal ChunkArrayElementResize(optr arr, word element, word newSize);

#define ChunkArrayElementResizeHandles(mh, ch, el, ns) \
		ChunkArrayElementResize(ConstructOptr(mh, ch), el, ns)

/***/

extern Boolean  /*XXX*/
    _pascal ChunkArrayEnum(optr arr, void *enumData,
		   PCB(Boolean, callback,       /* TRUE to stop */
				(void *element, void *enumData)));

#define ChunkArrayEnumHandles(mh, ch, ed, cb) \
		ChunkArrayEnum(ConstructOptr(mh, ch), ed, cb)
/***/


extern Boolean  /*XXX*/
    _pascal ChunkArrayEnumRange(optr array, word startElement, word count,
			void *enumData,
			PCB(Boolean, callback,  /* TRUE to stop */
				(void *element, void *enumData)));

#define ChunkArrayEnumRangeHandles(mh, ch, st, co, ed, cb) \
	ChunkArrayEnumRange(ConstructOptr(mh,ch),st,co,ed,cb)



extern void     /*XXX*/
    _pascal ChunkArrayZero(optr arr);

#define ChunkArrayZeroHandles(mh, ch) ChunkArrayZero(ConstructOptr(mh, ch))

/***/

extern void     /*XXX*/
    _pascal ChunkArraySort(optr arr, word valueForCallback,
		   PCB(sword, callback, (void *el1, void *el2,
				      word valueForCallback)));

#define ChunkArraySortHandles(mh, ch, vfc, cb) \
		ChunkArraySort(ConstructOptr(mh, ch), vfc, cb)

/***/

/*
 * Structure passed to ArrayQuickSort.
 */

typedef struct _QuickSortParameters {
	PCB(word,  QSP_compareCallback, (void *el1, void *el2,
					   word valueForCallback));
	PCB(void,  QSP_lockCallback, (void *el, word valueForCallback));
	PCB(void,  QSP_unlockCallback, (void *el, word valueForCallback));
	word       QSP_insertLimit;
	word       QSP_medianLimit;

	/* These are set internally by the quicksort algorithm and should not
	   be set by the caller: */

	word       QSP_nLesser;
	word       QSP_nGreater;
	
} QuickSortParameters;

extern void     /*XXX*/
    _pascal ArrayQuickSort(void *array, word count, word elementSize,
			   word valueForCallback,
			   QuickSortParameters *parameters);

/*
 *      Element array routines
 */

extern ChunkHandle      /*XXX*/
    _pascal ElementArrayCreateAt(optr arr, word elementSize, word headerSize,
					ObjChunkFlags ocf);

#define ElementArrayCreateAtHandles(mh, ch, esize, hsize, ocf)  \
	ElementArrayCreateAt(ConstructOptr(mh, ch), esize, hsize, ocf)

#define ElementArrayCreate(mh, esize, hsize, ocf) \
	ElementArrayCreateAtHandles(mh, NullChunk, esize, hsize, ocf)

/***/

extern void     /*XXX*/
    _pascal ElementArrayAddReference(optr arr, word token);

#define ElementArrayAddReferenceHandles(mh, ch, tok) \
		ElementArrayAddReference(ConstructOptr(mh, ch), tok)

/***/

extern word     /*XXX*/
    _pascal ElementArrayAddElement(optr arr, void *element, dword callbackData,
			   PCB(Boolean, callback, (void *elementToAdd,
						void *elementFromArray,
						dword valueForCallback)));

#define ElementArrayAddElementHandles(mh, ch, el, cbd, cb) \
		ElementArrayAddElement(ConstructOptr(mh, ch), el, cbd, cb)

/***/

extern void     /*XXX*/
    _pascal ElementArrayRemoveReference(optr arr, word token, dword callbackData,
				PCB(void, callback, (void *element,
						  dword valueForCallback)));

#define ElementArrayRemoveReferenceHandles(mh, ch, tok, cbd, cb) \
		ElementArrayRemoveReference(ConstructOptr(mh, ch), tok, cbd, cb)

/***/

extern void     /*XXX*/
    _pascal ElementArrayDelete(optr arr, word token);

#define ElementArrayDeleteHandles(mh, ch, tok) \
		ElementArrayDelete(ConstructOptr(mh, ch), tok)

/***/

extern word     /*XXX*/
    _pascal ElementArrayElementChanged(optr arr, word token, dword callbackData,
			   PCB(Boolean, callback, (void *elementChanged,
						void *elementToCompare,
						dword valueForCallback)));

#define ElementArrayElementChangedHandles(mh, ch, tok) \
		ElementArrayElementChanged(ConstructOptr(mh, ch), tok, \
					   callbackData, callback)

/***/

extern word     /*XXX*/
    _pascal ElementArrayGetUsedCount(optr arr, dword callbackData,
			     PCB(Boolean, callback, (void *element,
						     dword cbData)));

#define ElementArrayGetUsedCountHandles(mh, ch, cbd, cb) \
		ElementArrayGetUsedCount(ConstructOptr(mh, ch), cbd, cb)

/***/

extern word     /*XXX*/
    _pascal ElementArrayUsedIndexToToken(optr arr, word index, dword callbackData,
				 PCB(Boolean, callback, (void *element,
						     dword cbData)));

#define ElementArrayUsedIndexToTokenHandles(mh, ch, in, cbd, cb) \
	ElementArrayUsedIndexToToken(ConstructOptr(mh, ch), in, cbd, cb)

/***/

extern word     /*XXX*/
    _pascal ElementArrayTokenToUsedIndex(optr arr, word token, dword callbackData,
				 PCB(Boolean, callback, (void *element,
						     dword cbData)));

#define ElementArrayTokenToUsedIndexHandles(mh, ch, in, cbd, cb) \
	ElementArrayTokenToUsedIndex(ConstructOptr(mh, ch), in, cbd, cb)

/*
 *      Name array routines
 */

#define NAME_ARRAY_MAX_NAME_SIZE 256
#ifdef DO_DBCS
#define NAME_ARRAY_MAX_NAME_LENGTH 127
#else
#define NAME_ARRAY_MAX_NAME_LENGTH 255
#endif
#define NAME_ARRAY_MAX_DATA_SIZE 64

typedef struct {
    ElementArrayHeader  NAH_meta;
    word                NAH_dataSize;
} NameArrayHeader;

typedef struct {
    RefElementHeader    NAE_meta;
} NameArrayElement;

typedef struct {
    RefElementHeader    NAME_meta;
    byte                NAME_data[NAME_ARRAY_MAX_DATA_SIZE];
    TCHAR                NAME_name[NAME_ARRAY_MAX_NAME_LENGTH];
} NameArrayMaxElement;

typedef WordFlags NameArrayAddFlags;
#define NAAF_SET_DATA_ON_REPLACE    0x8000

/***/

extern ChunkHandle      /*XXX*/
    _pascal NameArrayCreateAt(optr arr, word dataSize, word headerSize,
					ObjChunkFlags ocf);

#define NameArrayCreateAtHandles(mh, ch, dsize, hsize, ocf)     \
	NameArrayCreateAt(ConstructOptr(mh, ch), dsize, hsize, ocf)

#define NameArrayCreate(mh, dsize, hsize, ocf) \
	NameArrayCreateAt(ConstructOptr(mh, 0), dsize, hsize, ocf)

/***/

extern word     /*XXX*/
    _pascal NameArrayAdd(optr arr, const TCHAR *nameToAdd, word nameLength,
		 NameArrayAddFlags flags, const void *data);

#define NameArrayAddHandles(mh, ch, nm, len, fl, data) \
		NameArrayAdd(ConstructOptr(mh, ch), nm, len, fl, data)

/***/

extern word     /*XXX*/
    _pascal NameArrayFind(optr arr, const TCHAR *nameToAdd, word nameLength,
		  void *returnData);

#define NameArrayFindHandles(mh, ch, nm, len, data) \
		NameArrayFind(ConstructOptr(mh, ch), nm, len, data)

/***/

extern void     /*XXX*/
    _pascal NameArrayChangeName(optr arr, word nameToken, const TCHAR *newName,
			word nameLength);

#define NameArrayChangeNameHandles(mh, ch, tok, nm, len) \
		NameArrayChangeName(ConstructOptr(mh, ch), tok, nm, len)

/***/

#ifdef __HIGHC__
pragma Alias(ChunkArrayCreateAt, "CHUNKARRAYCREATEAT");
pragma Alias(ChunkArrayElementToPtr, "CHUNKARRAYELEMENTTOPTR");
pragma Alias(ChunkArrayPtrToElement, "CHUNKARRAYPTRTOELEMENT");
pragma Alias(ChunkArrayGetElement, "CHUNKARRAYGETELEMENT");
pragma Alias(ChunkArrayAppend, "CHUNKARRAYAPPEND");
pragma Alias(ChunkArrayInsertAt, "CHUNKARRAYINSERTAT");
pragma Alias(ChunkArrayDelete, "CHUNKARRAYDELETE");
pragma Alias(ChunkArrayDeleteRange, "CHUNKARRAYDELETERANGE");
pragma Alias(ChunkArrayGetCount, "CHUNKARRAYGETCOUNT");
pragma Alias(ChunkArrayElementResize, "CHUNKARRAYELEMENTRESIZE");
pragma Alias(ChunkArrayEnum, "CHUNKARRAYENUM");
pragma Alias(ChunkArrayEnumRange, "CHUNKARRAYENUMRANGE");
pragma Alias(ChunkArrayZero, "CHUNKARRAYZERO");
pragma Alias(ChunkArraySort, "CHUNKARRAYSORT");
pragma Alias(ArrayQuickSort, "ARRAYQUICKSORT");
pragma Alias(ElementArrayCreateAt, "ELEMENTARRAYCREATEAT");
pragma Alias(ElementArrayAddReference, "ELEMENTARRAYADDREFERENCE");
pragma Alias(ElementArrayAddElement, "ELEMENTARRAYADDELEMENT");
pragma Alias(ElementArrayRemoveReference, "ELEMENTARRAYREMOVEREFERENCE");
pragma Alias(ElementArrayDelete, "ELEMENTARRAYDELETE");
pragma Alias(ElementArrayElementChanged, "ELEMENTARRAYELEMENTCHANGED");
pragma Alias(ElementArrayGetUsedCount, "ELEMENTARRAYGETUSEDCOUNT");
pragma Alias(ElementArrayUsedIndexToToken, "ELEMENTARRAYUSEDINDEXTOTOKEN");
pragma Alias(ElementArrayTokenToUsedIndex, "ELEMENTARRAYTOKENTOUSEDINDEX");
pragma Alias(NameArrayCreateAt, "NAMEARRAYCREATEAT");
pragma Alias(NameArrayAdd, "NAMEARRAYADD");
pragma Alias(NameArrayFind, "NAMEARRAYFIND");
pragma Alias(NameArrayChangeName, "NAMEARRAYCHANGENAME");
#endif

#endif
