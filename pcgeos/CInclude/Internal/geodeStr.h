/***********************************************************************
 *
 *	Copyright (c) Geoworks 1995 -- All Rights Reserved
 *
 * PROJECT:	  PC GEOS
 * MODULE:	  Kernel
 * FILE:	  geodeStr.h
 *
 * AUTHOR:  	  Peter Trinh: Sep  5, 1995
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	PT	9/ 5/95   	Initial version
 *
 * DESCRIPTION:
 *	This file defines standard file structures.
 *
 *
 *	Sections of this file are #if'ed out because those sections 
 *	have not been checked for correctness.
 *
 * 	$Id: geodeStr.h,v 1.1 97/04/04 15:53:51 newdeal Exp $
 *
 ***********************************************************************/
#ifndef _GEODESTR_H_
#define _GEODESTR_H_

#include <geode.h>

/*
 *	Definitions for standard files
 */
#define NUMBER_OF_STANDARD_FILES 4

/*
 *      Geode file types (correspond to location in PCGEOS source tree)
 */

/* enum GeodeType */
typedef enum {
    GEODE_TYPE_APPLICATION = 0x1,
    GEODE_TYPE_LIBRARY,
    GEODE_TYPE_DRIVER,
} GeodeType;

#if 0  /* This section has not been checked for correctness. */
/*
 *  Define the actual state variable structure
 */
typedef struct {		/* CHECKME */

/* *** Standard position for handle to segment */

    hptr.GeodeHeader	GH_geodeHandle; /* handle to this segment */

/* *** Variables from core data information (loaded from file) */

    /* *** Generic information *** */
    GeodeAttrs	<>	GH_geodeAttr;
/* GEODE file type, see GEODE spec */
    GeodeType	GH_geodeFileType;
/* release # */
    ReleaseNumber	<>	GH_geodeRelease;
/* protocol # */
    ProtocolNumber	<>	GH_geodeProtocol;
/* time stamp (SWAT uniqueness) */
    word	GH_geodeSerial;
/*
 * (permanent name
 * of GEODE)
 */
    char	GEODE_NAME_SIZE dup(?)	GH_geodeName;
/*  name extension */
    char	GEODE_NAME_EXT_SIZE dup(?)	GH_geodeNameExt;
    GeodeToken	<>	GH_geodeToken;
/* reference count for GEODE */
    sword	GH_geodeRefCount;

/* *** Driver variables */
    fptr.DriverInfoStruct	GH_driverTab;
    equ <GH_driverTab.offset>	GH_driverTabOff;
    equ <GH_driverTab.segment>	GH_driverTabSegment;

/* *** Exported library information */
/*
 * Library entry routine for kernel
 *  to call
 */
    fptr.far	GH_libEntry;
    equ <GH_libEntry.offset>	GH_libEntryOff;
    equ <GH_libEntry.segment>	GH_libEntrySegment;

/* Offset of entry point table */
    nptr.fptr	GH_exportLibTabOff;
/* number of exported entry points */
    sword	GH_exportEntryCount;

/* *** Imported library information *** */
/*
 * number of imported library table
 * entries
 */
    sword	GH_libCount;
/*
 * offset (in memory) of imported
 * library table
 */
    nptr.hptr	GH_libOffset;

/* *** Resource information *** */
/* number of resources */
    sword	GH_resCount;
/*
 * offset (in memory) to resource handle
 * table
 */
    nptr.hptr	GH_resHandleOff;
/*
 * offset (in memory) to resource
 * position table
 */
    nptr.dword	GH_resPosOff;
/*
 * offset (in memory) to resource
 * relocation size table
 */
    nptr.word	GH_resRelocOff;

/*
 *  NOTE: if you change anything above this label in GeodeHeader then 
 *  be sure to to update the tools header file in
 *   /staff/pcgeos/include/geode.h or things like swat will be
 *  unhappy - jimmy 6/94
 */

    label	byte	GH_endOfVariablesFromFile;
/* *** END of variables loaded from file */

/* *** GEODE generic variables */

/* handle to GEODE's .geo file */
    hptr	GH_geoHandle;
/* handle of parent process */
    hptr.GeodeHeader	GH_parentProcess;
/* handle of next GEODE on list */
    hptr.GeodeHeader	GH_nextGeode;
/*
 * If this is not the kernel
 *  geode, then it contains data
 *  to be accessed via the
 *  GeodePrivXXXX routines.
 * If this *is* the kernel geode,
 *  then this contains a map of
 *  the allocated privData
 *  offsets.
 */
    hptr	GH_privData;
/*
 * Pointer to table of extra
 *  libraries (those imported
 *  by the libraries this geode
 *  imports, but not imported
 *  directly by this geode)
 */
    nptr.hptr	GH_extraLibOffset;
/*
 * Number of entries in the
 *  extraLib table.
 */
    word	GH_extraLibCount;
/*
 * Handle of memory
 *  block containing
 *  general patch data
 */
    hptr	GH_generalPatchData;
/*
 * Handle of memory
 *  block containing
 *  language patch data
 */
    hptr	GH_languagePatchData;

/*
 * *** The remaining state variables are only present if the GEODE is
 * *** a process
 */

} GeodeHeader;

typedef struct {		/* CHECKME */
    GeodeHeader <>	PH_geodePart;

/* *** User interface information */
/* Application object */
    optr	PH_appObject;
/* Handle of state file */
    hptr	PH_vmHandle;
/* First handle on "saved" chain */
    hptr	PH_savedBlockPtr;
/* One word of data for UI */
    word	PH_uiData;
/*
 * Second, "UI" thread for process, if
 * any.  Runs all "ui-object" blocks
 */
    hptr	PH_uiThread;

/* *** File system variables */
    hptr	NUMBER_OF_STANDARD_FILES dup (?)	PH_stdFileHandles;
} ProcessHeader;


typedef ByteEnum GeodeRelocationSource;		/* CHECKME */

/*
 *  Relocation to a kernel entry point.
 * 	GRE_extra - unused
 * 	word at relocation - kernel entry point number
 */
#define GRS_KERNEL	0x0

/*
 *  Relocation to a library entry point.
 * 	GRE_extra - imported library number
 * 	word at relocation - library entry point number
 */
#define GRS_LIBRARY	0x1

/*
 *  Relocation to a resource of the geode.  This is never used with
 *  GRT_OFFSET or GRT_FAR_PTR since the linker eliminates GRT_OFFSET and
 *  convert GRT_FAR_PTR to GRT_SEGMENT.
 * 	GRE_extra - unused
 * 	word at relocation - resource number
 * 	for GRT_CALL - word at relocation+2 - offset of call
 */
/* geode's resource */
#define GRS_RESOURCE	0x2


typedef ByteEnum GeodeRelocationType;		/* CHECKME */

/*
 *  Relocation to a far pointer to an entry point (4 bytes).  If the
 *  target is movable then the segment is replaced by the handle>>4.  The
 *  second word of data at the target is not used.
 */
#define GRT_FAR_PTR	0x0

/*  Relocation to the offset of an entry point (2 bytes). */
#define GRT_OFFSET	0x1

/*
 *  Relocation to the segment of an entry point (2 bytes).  If the
 *  target is movable then the segment is replace by the handle>>4.
 */
#define GRT_SEGMENT	0x2

/*  Relocation to the handle of an entry point (2 bytes). */
#define GRT_HANDLE	0x3

/*
 *  Relocation to a call to a possibly movable routine (5 bytes).  The
 *  offset stored points to the byte AFTER the call opcode.  If the
 *  target is fixed, behavior is the same as GRT_FAR_PTR.  If the
 *  target is movable, the call opcode is replaced with a software
 *  interrupt and the other three bytes are replaced with data that
 *  defines the call:
 * 	Sixteen Software interrupts are used for geode resource and
 * 	library calls with the low four bits of the interrupt number
 * 	being the low byte of the handle to call (when shifted left
 * 	four bits).
 * 	bytes 0 and 1:INT RESOURCE_CALL_INT..RESOURCE_CALL_INT+15
 * 	byte 2: high byte of handle
 * 	byte 3 and 4: offset of call
 */
#define GRT_CALL	0x4

/*  Relocation to the last handle in an XIP resource. */
#define GRT_LAST_XIP_RESOURCE	0x5


typedef ByteFlags GeodeRelocationInfo;		/* CHECKME */
#define GeodeRelocationSource	(0x80 | 0x40 | 0x20 | 0x10)
#define GeodeRelocationSource_OFFSET	4
#define GeodeRelocationType	(0x08 | 0x04 | 0x02 | 0x01)
#define GeodeRelocationType_OFFSET	0


typedef struct {		/* CHECKME */
    GeodeRelocationInfo	GRE_info;
/* extra data depending on source */
    byte	GRE_extra;
/* offset of relocation */
    word	GRE_offset;
} GeodeRelocationEntry;

#endif /* End of section that has not been checked for correctness. */


/*---------------------------------------------------------------------------
 * 		Method parameter definition for C
 *---------------------------------------------------------------------------*/

/* 	Return parameter... */

typedef ByteEnum MethodReturnType;
#define MRT_VOID		0x0
#define MRT_BYTE_OR_WORD	0x1
#define MRT_DWORD		0x2
#define MRT_MULTIPLE		0x3

typedef ByteEnum MethodReturnByteWordType;
#define MRBWT_AL	0x0
#define MRBWT_AH	0x1
#define MRBWT_CL	0x2
#define MRBWT_CH	0x3
#define MRBWT_DL	0x4
#define MRBWT_DH	0x5
#define MRBWT_BPL	0x6
#define MRBWT_BPH	0x7
#define MRBWT_AX	0x8
#define MRBWT_CX	0x9
#define MRBWT_DX	0xa
#define MRBWT_BP	0xb

typedef ByteEnum MethodReturnDWordReg;
#define MRDWR_AX	0x0
#define MRDWR_CX	0x1
#define MRDWR_DX	0x2
#define MRDWR_BP	0x3

typedef ByteEnum MethodReturnMultipleType;
#define MRMT_AXBPCXDX	0x0
#define MRMT_AXCXDXBP	0x1
#define MRMT_CXDXBPAX	0x2
#define MRMT_DXCX	0x3
#define MRMT_BPAXDXCX	0x4
#define MRMT_MULTIPLEAX	0x5

typedef ByteFlags MethodReturnDWordInfo;
#define MTDI_HIGH_REG	0xc	/* MethodReturnDWordReg */
#define MTDI_LOW_REG	0x3	/* MethodReturnDWordReg */

#define MTDI_HIGH_REG_OFFSET	2
#define MTDI_LOW_REG_OFFSET	0

typedef union {					/* MPD_RETURN_TYPE = */
    MethodReturnByteWordType	MRI_byteWord;	/*   MRT_BYTE_OR_WORD*/
    MethodReturnDWordInfo	MRI_dword;	/*   MRT_DWORD */
    MethodReturnMultipleType	MRI_multiple;	/*   MRT_MULTIPLE */
} MethodReturnInfo;

/* 	Passed parameters... */

typedef ByteFlags MethodStackInfo;
#define MSI_STRUCT_AT_SS_BP	0x80	/*
					 * if 1: Single C parameter is a far
					 *       pointer to a structure which
					 *       must be copied onto the stack,
					 *       passed in ss:bp and copied back
					 * if 0: Multiple paramters passed on
					 *       the stack because they don't
					 *       fit in regs.  Pass ss:bp
					 *       pointing to the parameters
					 */
#define MSI_PARAM_SIZE		0x7f

#define MSI_PARAM_SIZE_OFFSET	0

typedef union {					/* MPM_C_PARAMS = */
    byte		MMI_C_PARAM_SIZE;	/* 	1 */
    MethodStackInfo	MMI_STACK_INFO;		/* 	0 */
} MethodMemoryInfo;

typedef WordFlags MethodPassMemory;
#define MPM_C_PARAMS		0x0100
#define MPM_MEMORY_INFO		0x00ff /* MethodMemoryInfo */

#define MPM_MEMORY_INFO_OFFSET	0

typedef ByteEnum MethodPassReg;
#define MPR_NONE	0x0
#define MPR_CL		0x1
#define MPR_CH		0x2
#define MPR_DL		0x3
#define MPR_DH		0x4
#define MPR_CX		0x5
#define MPR_DX		0x6
#define MPR_BP		0x7

typedef WordFlags MethodPassRegisters;
/* Reg to put 3rd parameter in */
#define MPR_PARAM3	0x01c0	/* MethodPassReg 
/* Reg to put 2nd parameter in */
#define MPR_PARAM2	0x0038	/* MethodPassReg */
/* Reg to put 1st parameter in */
#define MPR_PARAM1	0x0007	/* MethodPassReg */

#define MPR_PARAM3_OFFSET	6
#define MPR_PARAM2_OFFSET	3
#define MPR_PARAM1_OFFSET	0

typedef union {				/* MPD_REGISTER_PARAMS = */
    MethodPassRegisters	MPI_REGISTERS;	/*     1 */
    MethodPassMemory	MPI_MEMORY;	/*     0 */
} MethodPassInfo;

/* 	The full thing... */

typedef WordFlags MethodParameterDef;

/*  Bits used to encode return type */

#define MPD_RETURN_TYPE		0xc000	/* MethodReturnType */
#define MPD_RETURN_INFO		0x3c00	/* MethodReturnInfo */

/*  Bits used to encode passed parameters */

#define MPD_REGISTER_PARAMS	0x0200	/* Set if params passed in registers */
#define MPD_PASS_INFO		0x01ff	/* MethodPassInfo */

#define MPD_RETURN_TYPE_OFFSET	14
#define MPD_RETURN_INFO_OFFSET	10
#define MPD_PASS_INFO_OFFSET	0




#if 0  /* This section has not been checked for correctness. */

/* --------------- */

typedef ByteEnum HandlerModel;		/* CHECKME */
#define HM_FAR	0x0
#define HM_NEAR	0x1
#define HM_BASED	0x2

typedef ByteFlags HandlerTypeDef;		/* CHECKME */
#define HandlerModel	(0x80 | 0x40)
#define HandlerModel_OFFSET	6
#define HTD_PROCESS_CLASS	(0x20)
/* 5 bits unused */

/* ------------------------------------------------------------------------------
 * 		Relocation information
 * ------------------------------------------------------------------------------*/

/* INT 80h thru 8fh */
#define RESOURCE_CALL_INT_BASE	(080h)

/* INT 80h vector */
#define RESOURCE_CALL_VECTOR_BASE	(RESOURCE_CALL_INT_BASE * fptr)

/* opcode for INT XX */
#define INT_OPCODE	(0cdh)


/* --------------------------------------------------------------------------
 * 			Executable file header
 * --------------------------------------------------------------------------*/

typedef struct {		/* CHECKME */
    GeodeAttrs	EFH_attributes;
    word	EFH_fileType;
    word	EFH_heapSpace;
/*
 *  Heap space requirement -- used for applications only.  Amout of space
 *  that will come out of the operating space of the heap if this application
 *  is launched.  Is a somewhat magical value, roughly equivalent to the #
 *  of paragraphs of non-Discardable memory req'd, used to determine whether
 *  the app may safely be loaded into the heap or not.  The exact value
 *  will be determined by running the "heapspace" TCL script on the
 *  application, the result of which will then be stored by the programmer
 *  in the .gp file.  glue will then store that value here.	-- Doug 3/2/93
 */

/* used to be 2nd word of kernel protocol */
    word	EFH_unused;
    word	EFH_resourceCount;
    word	EFH_importLibraryCount;
    word	EFH_exportEntryCount;
    word	EFH_udataSize;
    dword	EFH_classPtr;
    optr	EFH_appObj;
} ExecutableFileHeader;

/* 	Imported library entry */

typedef struct {		/* CHECKME */
    char	GEODE_NAME_SIZE dup(?)	ILE_name;
    word	ILE_attrs;
    ProtocolNumber <>	ILE_protocol;
} ImportedLibraryEntry;

/* --------------------------------------------------------------------------
 * 			Geode file header
 * --------------------------------------------------------------------------*/

typedef struct {		/* CHECKME */
    ExecutableFileHeader	GFH_execHeader;
    GeodeHeader	GFH_coreBlock;
} GeodeFileHeader;

#endif /* End of section that has not been checked for correctness. */



#endif /* _GEODESTR_H_ */
