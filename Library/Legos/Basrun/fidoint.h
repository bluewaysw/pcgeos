/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996 -- All Rights Reserved

PROJECT:	Legos
MODULE:		Basrun
FILE:		fidoint.h

AUTHOR:		Paul L. Du Bois, Apr 15, 1996

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	4/15/96  	Initial version.

DESCRIPTION:
	Analog of fidoint.def

	$Id: fidoint.h,v 1.2 98/10/05 12:55:00 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#ifndef _FIDOINT_H_
#define _FIDOINT_H_

#include <geos.h>
#include <lmem.h>
#include <chunkarr.h>
#include <Legos/fido.h>

/*- Structures
 */
typedef struct
{
    LMemBlockHeader	FT_meta;
#if ERROR_CHECK
#define FT_MAGIC_NUMBER	(0xb015)
    word	FT_tag;
#endif
    ChunkHandle	FT_modules;
    ChunkHandle	FT_libraries;
    ChunkHandle	FT_drivers;
    ChunkHandle	FT_globalLibs;
} FidoTask_C;

/*- Module array structs */

typedef struct
{
    ElementArrayHeader	MAH_meta;
} ModuleArrayHeader_C;

typedef struct {
    RefElementHeader	MD_meta;
    GeodeHandle	MD_driver;
    word	MD_driverData;
    void _far*	MD_strategy;
    ChunkHandle	MD_ml;
    ChunkHandle	MD_localLibs;
    word	MD_myLibrary;
} ModuleData_C;

/*- Library array structs (FT_libraries) */

typedef struct {
    ElementArrayHeader	LAH_meta;
} LibraryArrayHeader_C;

#define LDF_AGGREGATE 0x2
#define LDF_STATIC 0x1
typedef struct {
    RefElementHeader	LD_meta;
    word	LD_flags;
    GeodeHandle	LD_library;	/* or RTaskHan */
    word	LD_myModule;
    ChunkHandle	LD_components;
} LibraryData_C;

typedef struct {
    word	ACD_constructor;
/*  label TCHAR	ACD_name;*/
} AggCompDecl_C;

#define CDR_MAGIC_NUMBER 0xccd3
typedef struct {
    word	CDR_count;
    word	CDR_unused;
/*  label hptr	CDR_data;	*/
} ClientDrivers_C;

extern Boolean _far _pascal
FidoUseLibrary_Agg(FTaskHan ftaskHan,
		   ModuleToken using_module, ModuleToken lib_module);

extern Boolean _far _pascal
FidoUseLibrary_Geode(FTaskHan ftaskHan,
		     ModuleToken using_module, TCHAR* lib_name);

extern Boolean _pascal
Fido_MakeMLCanonical(FTaskHan ftaskHan, ModuleToken loading_module,
		      TCHAR* url, TCHAR* buffer, word buffer_length);

extern TCHAR*
Fido_GetML(FTaskHan ftaskHan, ModuleToken module);

extern TCHAR*
Fido_GetExport(FTaskHan ftaskHan, ModuleToken module);

#ifdef __HIGHC__
pragma Alias(FidoUseLibrary_Geode,"FIDOUSELIBRARY_GEODE");
pragma Alias(FidoUseLibrary_Agg,"FIDOUSELIBRARY_AGG");
pragma Alias(FidoCleanTask,"FIDOCLEANTASK");
#endif

#endif /* _FIDOINT_H_ */




