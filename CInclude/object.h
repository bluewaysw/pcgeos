/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved
 *
 * PROJECT:	PC GEOS
 * FILE:	object.h
 * AUTHOR:	Tony Requist: February 14, 1991
 *
 * DECLARER:	Kernel
 *
 * DESCRIPTION:
 *	This file defines object structures and routines.
 *
 *	$Id: object.h,v 1.1 97/04/04 15:58:06 newdeal Exp $
 *
 ***********************************************************************/

#ifndef	__OBJECT_H
#define __OBJECT_H

#include <geode.h>
#include <lmem.h>

/*
 *	Flags sent to ObjMessage
 */

typedef WordFlags MessageFlags;
#define MF_CALL				0x8000
#define MF_FORCE_QUEUE			0x4000
#define MF_STACK			0x2000
#define MF_CHECK_DUPLICATE		0x0800
#define MF_CHECK_LAST_ONLY		0x0400
#define MF_REPLACE			0x0200
#define MF_CUSTOM			0x0100
#define MF_FIXUP_DS			0x0080
#define MF_FIXUP_ES			0x0040
#define MF_DISCARD_IF_NO_MATCH		0x0020
#define MF_MATCH_ALL			0x0010
#define MF_INSERT_AT_FRONT		0x0008
#define MF_CAN_DISCARD_IF_DESPERATE	0x0004
#define MF_RECORD			0x0002
#define MF_DISPATCH_DONT_FREE		0x0002

/* Return values for ObjMessage */

typedef enum /* word */ {
    MESSAGE_NO_ERROR,
    MESSAGE_NO_HANDLES
} MessageError;

/* Return values for custom compare routine called when sending events */

#define PROC_SE_EXIT		0x8000
#define PROC_SE_STORE_AT_BACK	1
#define PROC_SE_CONTINUE	0

/*
 *	Object Structures
 */

typedef void MessageMethod();

typedef struct {
    LMemBlockHeader	OLMBH_header;
    word		OLMBH_inUseCount;
    word		OLMBH_interactibleCount;
    optr		OLMBH_output;
    word		OLMBH_resourceSize;
} ObjLMemBlockHeader;

/* Flags kept for each chunk in an object block */

typedef ByteFlags ObjChunkFlags;
#define OCF_VARDATA_RELOC   	0x10
#define OCF_DIRTY		0x08
#define OCF_IGNORE_DIRTY	0x04
#define OCF_IN_RESOURCE		0x02
#define OCF_IS_OBJECT		0x01

/* Class structure */

typedef ByteFlags ClassFlags;
#define CLASSF_HAS_DEFAULT	0x80
#define CLASSF_MASTER_CLASS	0x40
#define CLASSF_VARIANT_CLASS	0x20
#define CLASSF_DISCARD_ON_SAVE	0x10
#define CLASSF_NEVER_SAVED	0x08
#define CLASSF_HAS_RELOC	0x04
#define CLASSF_C_HANDLERS	0x02

typedef struct _ClassStruct {
    struct _ClassStruct	*Class_superClass;
    word		Class_masterOffset;
    word		Class_methodCount;
    word		Class_instanceSize;
    word    	    	Class_vdRelocTable;
    word		Class_relocTable;
    ClassFlags		Class_flags;
    byte		Class_masterMessages;
} ClassStruct;

#define NullClass ((ClassStruct *)0)

typedef struct {
    word	methodParameterDef;
    byte	handlerTypeDef;
} CMethodDef;

/*
 *	Constants and Structures for Object Variable Storage Mechanism
 */

typedef struct {
    word	VDE_dataType;
    /* for data type with extra data, the following exist */
    word	VDE_entrySize;
} VarDataEntry;

/* offset to extra data */
#define VDE_extraData	sizeof(VarDataEntry)

/* Offset from a pointer to extra data to the data type . */
/* THIS SHOULD ONLY BE USED IN EXCEPTIONAL CIRCUMSTANCES. */

#define VEDP_dataType	(-4)	/* offset to data type */
#define VEDP_entrySize	(-2)	/* offset to data size (valid only if   */
				/* VDF_EXTRA_DATA bit set in data type) */

typedef WordFlags VarDataFlags;
#define VDF_TYPE		0xfffc
#define VDF_EXTRA_DATA		0x0002
#define VDF_SAVE_TO_STATE	0x0001


/* Macro for fetching the type of a variable data entry given a pointer to
 * the extra data stored in it.
 */

#define VarDataTypePtr(ptr) ((*(((word *)ptr)-2))&VDF_TYPE)

#define VarDataFlagsPtr(ptr) ((*(((word *)ptr)-2))&~VDF_TYPE)

#define VarDataSizePtr(ptr) ((*(((word *)ptr)-2))&VDF_EXTRA_DATA \
                                ? (*(((word *)ptr)-1)) \
                                : 0)


typedef struct {
    word	VDCH_dataType;
    PCB(void, 	VDCH_handler,(MemHandle mh, ChunkHandle chnk,
				VarDataEntry *extraData,
				word dataType, void *handlerData));
} VarDataCHandler;


#define DEFAULT_MASTER_MESSAGES		8192
#define FIRST_MASTER_MESSAGE		16384
#define DEFAULT_CLASS_MESSAGES		512
#define DEFAULT_EXPORTED_MESSAGES	48
#define DEFAULT_EXPORTED_MESSAGES_2	96
#define DEFAULT_EXPORTED_MESSAGES_3	144
#define DEFAULT_EXPORTED_MESSAGES_4	192
#define DEFAULT_EXPORTED_MESSAGES_5	240
#define DEFAULT_EXPORTED_MESSAGES_6	288

/*
 *	Structures used when relocating objects
 */

typedef ByteEnum ObjRelocationType;
#define RELOC_END_OF_LIST 0
#define RELOC_RELOC_HANDLE 1
#define RELOC_RELOC_SEGMENT 2
#define RELOC_RELOC_ENTRY_POINT 3

typedef struct {
    ObjRelocationType	OR_type;
    word		OR_offset;
} ObjRelocation;

typedef struct {
    char    	    EPR_geodeName[GEODE_NAME_SIZE];
    word    	    EPR_entryNumber;
} EntryPointRelocation;

typedef struct {
    VarDataFlags	VOR_type;   	/* type and tag */
    word		VOR_offset;
} VarObjRelocation;

/***/

typedef ByteEnum ObjRelocationSource;
#define ORS_NULL 		0
#define ORS_OWNING_GEODE 	1
#define ORS_KERNEL 		2
#define ORS_LIBRARY 		3
#define ORS_CURRENT_BLOCK 	4
#define ORS_VM_HANDLE 		5
#define ORS_OWNING_GEODE_ENTRY_POINT 6
#define ORS_NON_STATE_VM 	7
#define ORS_UNKNOWN_BLOCK 	8
#define ORS_EXTERNAL 		9

#define RID_SOURCE_OFFSET 12

extern dword
    _pascal CObjMessage();

extern dword
    _pascal CObjCallSuper();

extern dword
    _pascal CMessageDispatch(EventHandle, MessageFlags, word);

extern void
    _pascal CObjSendToChildren(optr o, EventHandle message, word masterOffset,
				    word compOffset, word linkOffset);

extern Boolean
    _pascal ObjRelocOrUnRelocSuper(optr oself, ClassStruct *class, word frame);

/***/

extern void	/*XXX*/
    _pascal ObjProcBroadcastMessage(EventHandle event);

/***/

extern optr
    _pascal ObjInstantiate(MemHandle block, ClassStruct *class);

/***/

extern optr
    _pascal ObjInstantiateForThread(ThreadHandle thread, ClassStruct *class);

/***/

extern void *
    _pascal ObjLockObjBlock(MemHandle mh);

/***/

extern MemHandle	/*XXX*/
    _pascal ObjDuplicateResource(MemHandle blockToDup,
			 GeodeHandle owner,
			 ThreadHandle burdenThread);

/***/

extern void	/*XXX*/
    _pascal ObjFreeDuplicate(MemHandle mh);

/***/

extern void	/*XXX*/
    _pascal ObjFreeChunk(optr o);

#define ObjFreeChunkHandles(mh, ch) \
    ObjFreeChunk(ConstructOptr(mh, ch))

/***/

extern void	/*XXX*/
    _pascal ObjIncInUseCount(MemHandle mh);

/***/

extern void	/*XXX*/
    _pascal ObjDecInUseCount(MemHandle mh);

/***/

extern void	/*XXX*/
    _pascal ObjIncInteractibleCount(MemHandle mh);

/***/

extern void	/*XXX*/
    _pascal ObjDecInteractibleCount(MemHandle mh);

/***/

extern Boolean		/* TRUE if error */	/*XXX*/
    _pascal ObjDoRelocation(ObjRelocationType type,
		    MemHandle block,
		    void *sourceData,
		    void *destData);

/***/

extern Boolean		/* TRUE if error */	/*XXX*/
    _pascal ObjDoUnRelocation(ObjRelocationType type,
		      MemHandle block,
		      void *sourceData,
		      void *destData);

/***/

extern void *
    _pascal ObjRelocateEntryPoint(EntryPointRelocation *relocData);

/***/

extern void
    _pascal ObjUnRelocateEntryPoint(EntryPointRelocation *relocData,
			    void *entryPoint);

/***/

extern void	/*XXX*/
    _pascal ObjResizeMaster(optr obj, word masterOffset, word newSize);

#define ObjResizeMasterHandles(mh, ch, mo, sz) \
    ObjResizeMaster(ConstructOptr(mh, ch), mo, sz)

/***/

extern void	/*XXX*/
    _pascal ObjInitializeMaster(optr obj, ClassStruct *class);

#define ObjInitializeMasterHandles(mh, ch, cl) \
    ObjInitializeMaster(ConstructOptr(mh, ch), cl)

/***/

extern void	/*XXX*/
    _pascal ObjInitializePart(optr obj, word masterOffset);

#define ObjInitializePartHandles(mh, ch, mo) \
    ObjInitializePart(ConstructOptr(mh, ch), mo)

/***/

extern ObjChunkFlags	/*XXX*/
    _pascal ObjGetFlags(optr o);

#define ObjGetFlagsHandles(mh, ch) \
    ObjGetFlags(ConstructOptr(mh, ch))

/***/

extern void	/*XXX*/
    _pascal ObjSetFlags(optr o,
		ObjChunkFlags bitsToSet,
		ObjChunkFlags bitsToClear);

#define ObjSetFlagsHandles(mh, ch, bs, bc) \
    ObjSetFlags(ConstructOptr(mh, ch), bs, bc)

/***/

extern void	/*XXX*/
    _pascal ObjMarkDirty(optr o);

#define ObjMarkDirtyHandles(mh, ch) \
    ObjMarkDirty(ConstructOptr(mh, ch))

/***/

extern Boolean	/*XXX*/
    _pascal ObjTestIfObjBlockRunByCurThread(MemHandle mh);

/***/

extern void	/*XXX*/
    _pascal ObjSaveBlock(MemHandle mh);

/***/

extern VMBlockHandle	/*XXX*/
    _pascal ObjMapSavedToState(MemHandle mh);

/***/

extern MemHandle	/*XXX*/
    _pascal ObjMapStateToSaved(VMBlockHandle vmbh, GeodeHandle gh);

/***/

extern Boolean	/*XXX*/
    _pascal ObjIsObjectInClass(optr obj, ClassStruct *class);

#define ObjIsObjectInClassHandles(mh, ch, cl) \
    ObjIsObjectInClass(ConstructOptr(mh, ch), cl)

/***/

/* Is class1 a subclass of class2? */

extern Boolean	/*XXX*/
    _pascal ObjIsClassADescendant(ClassStruct *class1, ClassStruct *class2);

/***/

extern void	/*XXX*/
    _pascal ObjFreeObjBlock(MemHandle block);

/***/

extern void	/*XXX*/
    _pascal ObjFreeMessage(EventHandle event);

/***/

extern Message	/*XXX*/
    _pascal ObjGetMessageInfo(EventHandle event, optr *dest);

/***/

typedef struct {
    word MDS_cx;
    word MDS_dx;
    word MDS_bp;
} MessageDataStruct;

extern Boolean  /*XXX*/
    _pascal ObjGetMessageData(EventHandle event, MessageDataStruct *data);

/***/

extern dword	/*XXX*/
    _pascal MessageSetDestination(EventHandle, optr);

/***/

extern EventHandle	/*XXX*/
    _pascal ObjDuplicateMessage(EventHandle msg);

/***/

extern void	/*XXX*/
    _pascal ObjSetEventInfo(EventHandle event, Message msg, optr dest);

/***/

		/* C cannot get return values from ObjDispatchMessage */
extern void	/*XXX*/
    _pascal ObjDispatchMessage(EventHandle event, Message replacementMessage,
				    optr replacementDest, MessageFlags flags);

/***/

extern void *	/*XXX*/
    _pascal ObjDeref(optr obj, word masterLevel);

#define ObjDerefHandles(mh, ch, ml) ObjDeref(ConstructOptr(mh, ch), ml)


extern void *	/*XXX*/
    _pascal ObjDeref1(optr obj);

#define ObjDeref1Handles(mh, ch) ObjDeref1(ConstructOptr(mh, ch))


extern void *	/*XXX*/
    _pascal ObjDeref2(optr obj);

#define ObjDeref2Handles(mh, ch) ObjDeref2(ConstructOptr(mh, ch))

/***/

extern void *
    _pascal ObjVarAddData(optr obj, VardataKey dataType, word dataSize);

#define ObjVarAddDataHandles(mh, ch, sz) \
		ObjVarAddData(ConstructOptr(mh, ch), sz)

/***/

extern Boolean
    _pascal ObjVarDeleteData(optr obj, VardataKey dataType);

#define ObjVarDeleteDataHandles(mh, ch, d) \
    ObjVarDeleteData(ConstructOptr(mh, ch), d)

/***/

extern void
    _pascal ObjVarDeleteDataAt(optr obj, word extraDataOffset);

#define ObjVarDeleteDataAtHandles(mh, ch, edo) \
    ObjVarDeleteDataAt(ConstructOptr(mh, ch), edo)

/***/

extern void
    _pascal ObjVarScanData(optr obj,
		   word numHandlers,
		   VarDataCHandler *handlerTable,
		   void *handlerData);

#define ObjVarScanDataHandles(mh, ch, nh, ht, hd) \
    ObjVarScanData(ConstructOptr(mh, ch), nh, ht, hd)

/***/

extern void *
    _pascal ObjVarFindData(optr obj, VardataKey dataType);

#define ObjVarFindDataHandles(mh, ch, dt) \
    ObjVarFindData(ConstructOptr(mh, ch), dt)

/***/

extern void *
    _pascal ObjVarDerefData(optr obj, VardataKey dataType);

#define ObjVarDerefDataHandles(mh, ch, dt) \
    ObjVarDerefData(ConstructOptr(mh, ch), dt)

/***/

extern void
    _pascal ObjVarDeleteDataRange(optr obj,
			  word rangeStart,
			  word rangeEnd,
			  Boolean useStateFlag);

#define ObjVarDeleteDataRangeHandles(mh, ch, rs, re, fl) \
    ObjVarDeleteDataRange(ConstructOptr(mh, ch), rs, re, fl)

/***/

extern void	/* XXX */
    _pascal ObjVarCopyDataRange(optr source,
			optr dest,
			word rangeStart,
			word rangeEnd);

/***/

extern void	/* XXX */
    _pascal ObjBlockSetOutput(MemHandle mh, optr o);

/***/

extern optr	/* XXX */
    _pascal ObjBlockGetOutput(MemHandle mh);

/***/

#ifdef __HIGHC__
pragma Alias(CObjMessage, "COBJMESSAGE");
pragma Alias(CObjCallSuper, "COBJCALLSUPER");
pragma Alias(CMessageDispatch, "CMESSAGEDISPATCH");
pragma Alias(CObjSendToChildren, "COBJSENDTOCHILDREN");
pragma Alias(ObjRelocOrUnRelocSuper, "OBJRELOCORUNRELOCSUPER");
pragma Alias(ObjProcBroadcastMessage, "OBJPROCBROADCASTMESSAGE");
pragma Alias(ObjInstantiate, "OBJINSTANTIATE");
pragma Alias(ObjInstantiateForThread, "OBJINSTANTIATEFORTHREAD");
pragma Alias(ObjLockObjBlock, "OBJLOCKOBJBLOCK");
pragma Alias(ObjDuplicateResource, "OBJDUPLICATERESOURCE");
pragma Alias(ObjFreeDuplicate, "OBJFREEDUPLICATE");
pragma Alias(ObjFreeChunk, "OBJFREECHUNK");
pragma Alias(ObjIncInUseCount, "OBJINCINUSECOUNT");
pragma Alias(ObjDecInUseCount, "OBJDECINUSECOUNT");
pragma Alias(ObjIncInteractibleCount, "OBJINCINTERACTIBLECOUNT");
pragma Alias(ObjDecInteractibleCount, "OBJDECINTERACTIBLECOUNT");
pragma Alias(ObjDoRelocation, "OBJDORELOCATION");
pragma Alias(ObjDoUnRelocation, "OBJDOUNRELOCATION");
pragma Alias(ObjRelocateEntryPoint, "OBJRELOCATEENTRYPOINT");
pragma Alias(ObjUnRelocateEntryPoint, "OBJUNRELOCATEENTRYPOINT");
pragma Alias(ObjResizeMaster, "OBJRESIZEMASTER");
pragma Alias(ObjInitializeMaster, "OBJINITIALIZEMASTER");
pragma Alias(ObjInitializePart, "OBJINITIALIZEPART");
pragma Alias(ObjGetFlags, "OBJGETFLAGS");
pragma Alias(ObjSetFlags, "OBJSETFLAGS");
pragma Alias(ObjMarkDirty, "OBJMARKDIRTY");
pragma Alias(ObjTestIfObjBlockRunByCurThread, "OBJTESTIFOBJBLOCKRUNBYCURTHREAD");
pragma Alias(ObjSaveBlock, "OBJSAVEBLOCK");
pragma Alias(ObjMapSavedToState, "OBJMAPSAVEDTOSTATE");
pragma Alias(ObjMapStateToSaved, "OBJMAPSTATETOSAVED");
pragma Alias(ObjIsObjectInClass, "OBJISOBJECTINCLASS");
pragma Alias(ObjIsClassADescendant, "OBJISCLASSADESCENDANT");
pragma Alias(ObjFreeObjBlock, "OBJFREEOBJBLOCK");
pragma Alias(ObjGetMessageInfo, "OBJGETMESSAGEINFO");
pragma Alias(ObjGetMessageData, "OBJGETMESSAGEDATA");
pragma Alias(MessageSetDestination, "MESSAGESETDESTINATION");
pragma Alias(ObjFreeMessage, "OBJFREEMESSAGE");
pragma Alias(ObjDeref, "OBJDEREF");
pragma Alias(ObjDeref1, "OBJDEREF1");
pragma Alias(ObjDeref2, "OBJDEREF2");

pragma Alias(ObjVarAddData, "OBJVARADDDATA");
pragma Alias(ObjVarDeleteData, "OBJVARDELETEDATA");
pragma Alias(ObjVarDeleteDataAt, "OBJVARDELETEDATAAT");
pragma Alias(ObjVarScanData, "OBJVARSCANDATA");
pragma Alias(ObjVarFindData, "OBJVARFINDDATA");
pragma Alias(ObjVarDerefData, "OBJVARDEREFDATA");
pragma Alias(ObjVarDeleteDataRange, "OBJVARDELETEDATARANGE");
pragma Alias(ObjVarCopyDataRange, "OBJVARCOPYDATARANGE");

pragma Alias(ObjBlockSetOutput, "OBJBLOCKSETOUTPUT");
pragma Alias(ObjBlockGetOutput, "OBJBLOCKGETOUTPUT");
pragma Alias(ObjDuplicateMessage, "OBJDUPLICATEMESSAGE");

#endif

#endif
