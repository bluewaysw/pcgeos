/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	GEOS Tools
MODULE:		Patch
FILE:		patchStr.h

AUTHOR:		Chris Boyke, Apr  5, 1994

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	4/ 5/94   	Initial version.

DESCRIPTION:
        Data structures used in patch files.

	$Id: patchStr.h,v 1.4 97/04/17 17:51:25 dbaumann Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

#define swapdw swapl		/* from bswap.h */

typedef struct {
    char   	    PFH_signature[4];
    char	    PFH_geodeName[GEODE_NAME_SIZE];
    char	    PFH_geodeNameExt[GEODE_NAME_EXT_SIZE];
    IconToken	    PFH_token;
    word    	    PFH_geodeAttr;
    ReleaseNumber   PFH_oldRelease;  
    ProtocolNumber  PFH_oldProtocol;
    ReleaseNumber   PFH_newRelease;  
    ProtocolNumber  PFH_newProtocol;
    word   	    PFH_resourceCount;
    word    	    PFH_newResourceCount;
    word    	    PFH_flags;
    word    	    PFH_udataSize;
    word   	    PFH_classOffset;
    word   	    PFH_classResource;
    word       	    PFH_appObjChunkHandle;
    word    	    PFH_appObjResource;
} PatchFileHeader;

#define PFH_SIZE (offsetof(PatchFileHeader,PFH_appObjResource) + sizeof(word))

#define PARTIAL_HEADER_OFFSET   (offsetof(PatchFileHeader,PFH_oldRelease))
#define PARTIAL_HEADER_SIZE	(PFH_SIZE - PARTIAL_HEADER_OFFSET)

/* PatchFileHeaderFlags	*/
#define PFHF_DYNAMIC		0x1

/* The actual data is stored in a PatchElement -- there may be */
/* more than one of these per resource. */
 
typedef struct PE {
    struct PE *PE_next;
    word       PE_pos;
    word       PE_flags;
    /* The low 14 bits are the size of the patch data, the top 2 bits
       are the type of patch */
} PatchElement;

/* Since the sparc pads everything out to be word-aligned, etc. we */
/* have to jump through hoops to get the exact sizes we need */

#define PE_SIZE     	(offsetof(PatchElement,PE_flags)+sizeof(word))
#define PE_WRITE_OFFSET (offsetof(PatchElement,PE_pos))
#define PE_FINAL_SIZE	(PE_SIZE - PE_WRITE_OFFSET)


#define MAX_PATCH_SIZE	4095

/* Make this number larger to reduce the number of patches in a file. */

#define PATCH_GRANULARITY 8

typedef word PatchType;
#define PT_REPLACE  	0x0000
#define PT_DELETE   	0x4000
#define PT_INSERT   	0x8000
#define PT_INSERT_ZERO  0xC000

#define PE_SIZE_MASK 	0x0FFF
#define PE_TYPE_MASK 	0xC000    


/* One of these structures exists for each resource that has data in */
/* the patch file */

typedef struct PRE {
    struct PRE *PRE_next;
    PatchElement    *PRE_resourcePatches;
    PatchElement    *PRE_relocPatches;
    word    PRE_id;
    word    PRE_size;
    dword   PRE_pos;
    word    PRE_relocSize;
    word    PRE_resourceSizeDiff;   /* Rounded to nearest paragraph */
    word    PRE_maxResourceSize;
    word    PRE_maxRelocSize;
    word    PRE_flags;
} PatchedResourceEntry;

#define PRE_SIZE	 (offsetof(PatchedResourceEntry,PRE_flags)+2)
#define PRE_WRITE_OFFSET (offsetof(PatchedResourceEntry,PRE_id))
#define PRE_FINAL_SIZE   (PRE_SIZE - PRE_WRITE_OFFSET)

typedef struct
{
    word	GH_geodeHandle;		/* handle of geode (0 in file) */
    word	GH_geodeAttr;		/* COPY OF geodehAttributes */
    word	GH_geodeFileType;		/* COPY OF geodehFileType */
    ReleaseNumber   GH_geodeRelease;
    ProtocolNumber  GH_geodeProtocol;
    word 	GH_geodeSerial;	    	/* 12h */
    char	GH_geodeName[GEODE_NAME_SIZE];	/* Permanent name */
    char	GH_geodeNameExt[GEODE_NAME_EXT_SIZE];	/* Name extension */
    IconToken	GH_geodeToken;		/* Token for this GEODE */
    word	GH_geodeRefCount;	/* Starting reference count for GEODE*/
    word	GH_driverTabOff;
    word	GH_driverTabSegment;
    word	GH_libEntryOff;		/* Offset of library entry routine */
    word	GH_libEntrySegment;	/* Offset of library entry routine */
    word	GH_exportLibTabOff;	/* Offset (in memory) of library */
					/* entry point table */
    word	GH_exportEntryCount;	/* Number of exported entry points */

    word	GH_libCount;		/* Number of imported libraries */
    word	GH_libOffset;		/* Offset (in memory) of library
					 * table. Filled in by kernel */
    word	GH_resCount;		/* 38h */
    word	GH_resHandleOff;	/* 3ah */
    word	GH_resPosOff;		/* 3ch */
    word	GH_resRelocOff;		/* 3eh */

    /************end of data in the GeodeHeader2 struct ***************/
    word    GH_geoHandle;    	    	/* handle to geodes .geo file */
    word    GH_parentProcess;  	    	/* handle of parent process */
    word    GH_nextGeode;    	    	/* handle of next geode on list */
    word    GH_privData;    	    	/* special priv data for each geode */
    word    GH_extraLibOffset; 	    	/* offset of extra library table */
    word    GH_extraLibCount;  	    	/* number of extra libraries */
    word    GH_patchData;   	    	/* 4ch */
} CoreBlockHeader;

#define GEODE_HEADER_SIZE (offsetof(CoreBlockHeader,GH_patchData) \
			   + sizeof(word));

typedef struct {
    CoreBlockHeader PH_geodePart;
    word    PH_appObjectChunkHandle;
    word    PH_appObjectResource;
    word    PH_vmHandle;    	    	/* vm handle of state file */
    word    PH_savedBlockPtr;           /* first handle on "saved" chain */
    word    PH_uiData;    	     	/* one word of data for UI */
    word    PH_uiThread;                /* Second, "UI" thread for process, if
					  any.  Runs all "ui-object" blocks */
    word    PH_stdFileHandles[4];
} ProcessHeader;    

#define PROCESS_HEADER_SIZE (offsetof(ProcessHeader, PH_stdFileHandles) \
			     + (4 * sizeof(word)));
