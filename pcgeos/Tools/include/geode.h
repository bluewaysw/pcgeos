/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Tools -- GEODE description
 * FILE:	  geode.h
 *
 * AUTHOR:  	  Adam de Boor: Nov 14, 1988
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	11/14/88  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	The types in this file describe the layout of a GEODE in PCGEOS.
 *	This is used by both exe2geos and swat.
 *
 *
 * 	$Id: geode.h,v 1.26 94/03/25 12:13:27 andrew Exp $
 *
 ***********************************************************************/
#ifndef _GEODE_H_
#define _GEODE_H_

#include    <os90File.h>

/*
 * Executable file header
 */

typedef struct {
    GeosFileHeader	geosFileHeader;
    word	attributes;	/* Flags: */
#define GA_PROCESS	    	0x8000	    /* Needs a process */
#define GA_LIBRARY	    	0x4000	    /* Exports library calls */
#define GA_DRIVER	    	0x2000	    /* Device driver */
#define GA_KEEP_FILE_OPEN	0x1000	    /* Keep .geo file open */
#define GA_SYSTEM	    	0x0800	    /* Compiled into kernel */
#define GA_MULTI_LAUNCHABLE	0x0400	    /* May be executed more than once*/
#define GA_APPLICATION	    	0x0200	    /* User application */
#define GA_DRIVER_INITIALIZED	0x0100	    /* Driver aspect initialized */
#define GA_LIBRARY_INITIALIZED	0x0080	    /* Library aspect initialized */
#define GA_GEODE_INITIALIZED	0x0040	    /* Entire geode initialized */
#define GA_USES_COPROC	    	0x0020	    /* Uses coprocessor, if present */
#define GA_REQUIRES_COPROC  	0x0010	    /* Requires coprocessor, if no
					     * emulator present */
#define	GA_HAS_GENERAL_CONSUMER_MODE	0x0008 /* Can be run in GCM mode */
#define	GA_ENTRY_POINTS_IN_C	0x0004	    /* C API for entry points */
#define	GA_XIP			0x0002	    /* is XIP */

    word	fileType;		/* GEODE file type */
#define GEODE_TYPE_APPLICATION	1
#define GEODE_TYPE_LIBRARY	2
#define GEODE_TYPE_DRIVER	3

    ProtocolNumber  kernelProtocol;
    word	resourceCount;	/* Number of resources */
    word	importLibraryCount;  /* Number of imported libraries */
    word	exportEntryCount;    /* Number of exported entry points */
    word	udataSize;	     /* Size of uninitialized data */
#define PROCESS_DEF_STACK_SIZE	2000 /* Default stack size for the initial
				      * thread of a geode that is a process */
#define INTERFACE_THREAD_DEF_STACK_SIZE	2000   /* Default stack size for the
						* "UI" thread of an application,
						* i.e. the thread that runs
						* the Application object.  This
						* is used as the stack size
						* for the process thread in
						* single-threaded applications.
						* NOTE: If you change the
						* constant here, be sure to
						* update the constant
						* UI_THREAD_DEF_STACK_SIZE
						* in /staff/pcgeos/Library/
						* User/uiConstant.def so 
						* that the UI will correctly
						* set the size of the UI 
						* thread in multi-threaded 
						* applications if they do
						* not specify a size to use */
    word 	classOffset;  	/* Offset and resource at which class */
    word 	classResource; 	/* record is found (if process) */
    word	appObjChunkHandle; /* Lmem handle of app object */
    word	appObjResource;	/* Resource ID of app object */
} ExecutableFileHeader;

typedef struct {
    GeosFileHeader2 geosFileHeader;
    word	attributes;	/* Flags: */
    word	fileType;		/* GEODE file type */
    word	heapSpace;
    word    	unused[1];
    word	resourceCount;	/* Number of resources */
    word	importLibraryCount;  /* Number of imported libraries */
    word	exportEntryCount;    /* Number of exported entry points */
    word	udataSize;	     /* Size of uninitialized data */
    word 	classOffset;  	/* Offset and resource at which class */
    word 	classResource; 	/* record is found (if process) */
    word	appObjChunkHandle; /* Lmem handle of app object */
    word	appObjResource;	/* Resource ID of app object */
} ExecutableFileHeader2;

/*
 * Executable file header
 */

#define GEODE_NAME_SIZE	    8	    /* Length of geode permanent name */
#define GEODE_NAME_EXT_SIZE 4	    /* Length of extension to perm. name */

typedef struct geodeHeaderStruc {		/* GEODE header */
    ExecutableFileHeader	execHeader;

    word	geodeHandle;		/* handle of geode (0 in file) */
    word	geodeAttr;		/* COPY OF geodehAttributes */
    word	geodeFileType;		/* COPY OF geodehFileType */
    ReleaseNumber   geodeRelease;
    ProtocolNumber  geodeProtocol;
    word 	geodeSerial;	    	/* Serial number of geode (set by
					 * exe2geos) */
    char	geodeName[GEODE_NAME_SIZE];	/* Permanent name */
    char	geodeNameExt[GEODE_NAME_EXT_SIZE];	/* Name extension */
    IconToken	geodeToken;		/* Token for this GEODE */
    word	geodeRefCount;		/* Starting reference count for GEODE*/
    word	driverTabOff;		/* Offset (in memory) of driver table*/
    word	driverTabResource;	/* Offset (in memory) of driver table*/
    word	libEntryOff;		/* Offset of library entry routine */
    word	libEntryResource;	/* Offset of library entry routine */
    word	exportLibTabOff;	/* Offset (in memory) of library */
					/* entry point table */
    word	exportEntryCount;	/* Number of exported entry points */

    word	libCount;		/* Number of imported libraries */
    word	libOffset;		/* Offset (in memory) of library
					 * table. Filled in by kernel */
    word	resCount;		/* Number of resources */
    word	resHandleOff;		/* offset (in memory) of resource
					 * handle table. Filled in by kernel */
    word	resPosOff;		/* offset (in memory) of resource
					 * position table. Filled in by
					 * kernel */
    word	resRelocOff;		/* offset (in memory) of resource
					 * relocation size table. Filled in by
					 * kernel */
} GeodeHeader, *GeodePtr;


typedef struct geodeHeaderStruc2 {		/* GEODE header */
    ExecutableFileHeader2	execHeader;

    word	geodeHandle;		/* handle of geode (0 in file) */
    word	geodeAttr;		/* COPY OF geodehAttributes */
    word	geodeFileType;		/* COPY OF geodehFileType */
    ReleaseNumber   geodeRelease;
    ProtocolNumber  geodeProtocol;
    word 	geodeSerial;	    	/* Serial number of geode (set by
					 * exe2geos) */
    char	geodeName[GEODE_NAME_SIZE];	/* Permanent name */
    char	geodeNameExt[GEODE_NAME_EXT_SIZE];	/* Name extension */
    IconToken	geodeToken;		/* Token for this GEODE */
    word	geodeRefCount;		/* Starting reference count for GEODE*/
    word	driverTabOff;		/* Offset (in memory) of driver table*/
    word	driverTabResource;	/* Offset (in memory) of driver table*/
    word	libEntryOff;		/* Offset of library entry routine */
    word	libEntryResource;	/* Offset of library entry routine */
    word	exportLibTabOff;	/* Offset (in memory) of library */
					/* entry point table */
    word	exportEntryCount;	/* Number of exported entry points */

    word	libCount;		/* Number of imported libraries */
    word	libOffset;		/* Offset (in memory) of library
					 * table. Filled in by kernel */
    word	resCount;		/* Number of resources */
    word	resHandleOff;		/* offset (in memory) of resource
					 * handle table. Filled in by kernel */
    word	resPosOff;		/* offset (in memory) of resource
					 * position table. Filled in by
					 * kernel */
    word	resRelocOff;		/* offset (in memory) of resource
					 * relocation size table. Filled in by
					 * kernel */
} GeodeHeader2, *Geode2Ptr;

/*
 * Imported library entry
 */

typedef struct {
    char		name[GEODE_NAME_SIZE];	/* Permanent name of library */
    word 	    	geodeAttrs; 	/* Attributes to match */
    ProtocolNumber	protocol;   	/* Expected protocol of library */
} ImportedLibraryEntry;

/*
 * Resource-allocation flags. These are taken from the HeapFlags and
 * HeapAllocFlags records located in Include/heap.def
 */
/* HeapFlags definitions (for special cases) */
#define RESF_MEM_SWAP	    0x0001  /* Swapped to e-mem (should never be set)*/
#define RESF_DISCARDED	    0x0002  /* Needs to be brought in from the
				     * executable */
#define RESF_DEBUG  	    0x0004  /* Attached to debugger (should never be
				     * set) */
#define RESF_LMEM   	    0x0008  /* Managed by LMem module in kernel */
#define RESF_SWAPABLE	    0x0010  /* May be swapped to disk */
#define RESF_DISCARDABLE    0x0020  /* May be discarded */
#define RESF_SHARED 	    0x0040  /* May be shared among geodes */
#define RESF_FIXED  	    0x0080  /* Must be fixed in memory */

/* HeapAllocFlags definitions */
#define RESF_CONFORMING	    0x0100  /* May be called from lower privilege
				     * level */
#define RESF_CODE   	    0x0200  /* Block contains code (else data) */
#define RESF_OBJECT 	    0x0400  /* Block contains objects */
#define RESF_READ_ONLY	    0x0800  /* Block will not be modified by geode */
#define RESF_UI	    	    0x1000  /* Combined with RESF_OBJECT, indicates
				     * a block of objects that will be run
				     * by the UI */
/* Remaining HeapAllocFlags do not pertain to resources */

/* Standard resource flag combinations */
#define RESF_PRELOAD	0x0030	    /* Preloaded standard (discardable and
				     * swapable, but not discarded) */
#define RESF_STANDARD	0x0032	    /* Standard (discardable and swapable
				     * but discarded) */
#define RESF_SELFMOD	0x0012	    /* Self-modifying (swapable, discarded) */

/*
 * Resource relocation definitions
 */

typedef enum {
    GRS_KERNEL,	    	/* Object being relocated is in the kernel. Word
			 * contains entry point number. "extra" is unused */
    GRS_LIBRARY,    	/* Object being relocated is in a library. Word
			 * contains entry point number. "extra" is
			 * imported-library number */
    GRS_RESOURCE    	/* Object being relocated is in the geode. Word
			 * contains the resource ID. "extra" is unused */
} GeodeRelocationSources;

typedef enum {
    GRT_FAR_PTR,    	/* Unused (was used by exe2geos to make life simple) */
    GRT_OFFSET,	    	/* Offset to kernel or library routine */
    GRT_SEGMENT,    	/* Segment or handle >> 4 */
    GRT_HANDLE,	    	/* Handle ID for geode or library */
    GRT_CALL,	    	/* Far call. May be transformed to software interrupt*/
    GRT_LAST_XIP_HANDLE,/* Special relocation for last handle in XIP image */
} GeodeRelocationTypes;


typedef struct {
    unsigned char   info;   /* Info describing relocation */
#define GRI_SOURCE  0xf0    	/* Source for relocation is in the top nibble*/
#define GRI_TYPE    0x0f    	/* Type of relocation is in the low nibble */
    unsigned char   extra;  /* Extra data required for relocation. Used
			     * only for GRT_OFFSET+GRS_LIBRARY. */
    unsigned short  offset; /* Offset of relocation */
} GeodeRelocEntry;

/* Object elocation stuff */

typedef enum /* byte */ {
    ORS_NULL,
    ORS_OWNING_GEODE,
    ORS_KERNEL,
    ORS_LIBRARY,
    ORS_CURRENT_BLOCK,
    ORS_VM_HANDLE,
    ORS_OWNING_GEODE_ENTRY_POINT,
    ORS_NON_STATE_VM,
    ORS_UNKNOWN_BLOCK,
    ORS_EXTERNAL
} ObjRelocationSources;


typedef struct /* word */ {
    word			ORID_INDEX:12;
    ObjRelocationSources	RID_SOURCE:4;
} ObjRelocationID;

#define RID_SOURCE_OFFSET 12

#endif /* _GEODE_H_ */
