/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994, 1995 -- All Rights Reserved

PROJECT:	Legos
MODULE:		Fido
FILE:		fido.h

AUTHOR:		Paul L. Du Bois, Aug 23, 1994

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	 8/23/94	Initial version.

DESCRIPTION:
	C header file for fido library

	$Id: fido.h,v 1.1 97/12/05 12:16:18 gene Exp $
	$Revision: 1.1 $

	Liberty version control
	$Id: fido.h,v 1.1 97/12/05 12:16:18 gene Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#ifndef _FIDO_H_
#define _FIDO_H_

#ifdef LIBERTY
#define _far
#define _pascal
#define ClassStruct void
#define WordFlags word

/* dynamic loading of modules */
#ifdef EC_DYNAMIC_LOADED_MODULES
#define ECDLM(x) x
#else
#define ECDLM(x)
#endif

#else	/* GEOS version below */

#define ECDLM(x) 		/* only for Liberty debugging */
#include <geos.h>

#endif

/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 %              Structs and enumerated types
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

typedef MemHandle FTaskHan;

/*
 * Structure to hold a library-based class pointer, as returned
 * by FidoFindComponent (the C version, anyway).  If you change
 * this, please change the version in fido.def, and fix the C stub.
 */

/* If LCP_library == LCP_IS_AGG, treat LCP_class as a func#/RTaskHan
 * to call to create the component, instead of a ClassStruct*
 */
#define LCP_IS_AGG(_lcp) ((_lcp).LCP_library == 0xffff)
#define LCP_MODULE(_lcp) (PtrToOffset((_lcp).LCP_class))
#define LCP_FUNCNUM(_lcp) (PtrToSegment((_lcp).LCP_class))

typedef struct
{
    GeodeHandle		LCP_library;
    ClassStruct*	LCP_class;
} LibraryClassPointer;

typedef WordFlags FidoSearchFlags;
#define FSF_BUILD_TIME		       	0x8000
#define FSF_DUMMY1			0x4000
#define FSF_DUMMY2			0x2000

#define STANDARD_RUNTIME_SEARCH		0

#define RSL_FILE_SIGNATURE	0x6c6a
typedef enum
{
    RSLD_BITMAP
} RSLDataType;

typedef struct
{
    byte    RSLBH_bitmapType;
    byte    RSLBH_other;
    word    RSLBH_width;
    word    RSLBH_height;
} RSLBitmapHeader;

typedef struct
{
    word    RSLH_sig;
    word    RSLH_numItems;
} RSLHeader;

/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 %              Exported routines
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

/*
 * Module stuff
 */
typedef word ModuleToken;
#define NULL_MODULE 0xffff

#ifdef LIBERTY
typedef enum {
    FIDO_SEARCH_FAILED, 
    FIDO_SEARCH_SUCCEEDED, 
    FIDO_IS_AGG
} FidoSearchResult;

extern FidoSearchResult FidoFindAndCreateComponent(ModuleToken module,
						   TCHAR *componentName,
						   FidoSearchFlags searchFlags,
						   MemHandle *rtaskHan,
						   word *function);
#endif

extern MemHandle _far _pascal
    FidoFindComponent(FTaskHan		fidoTask,
		      ModuleToken	mod,
		      char _far*	componentName,
		      FidoSearchFlags	searchFlags,
		      LibraryClassPointer* retval);

#ifndef LIBERTY
extern void _far _pascal
    FidoRegLoadedCompLibs(FTaskHan fidoTask);

extern FTaskHan _far _pascal
    FidoAllocTask(void);
#endif

extern void _far _pascal
    FidoCleanTask(FTaskHan ftask);

extern void _far _pascal
    FidoDestroyTask(FTaskHan ftask);

#ifdef LIBERTY

extern ModuleToken
FidoOpenModule(const TCHAR *moduleLocator, ModuleToken loadingModule);

extern void
FidoCloseModule(ModuleToken mod);

extern MemHandle
FidoGetPage(ModuleToken mod, word pageNum);

extern MemHandle
FidoGetHeader(ModuleToken mod);

#else	/* GEOS version below */

extern ModuleToken _far _pascal
    FidoOpenModule(FTaskHan ftaskHan, TCHAR *moduleLocator,
		   ModuleToken loadingModule);

extern void _far _pascal
    FidoCloseModule(FTaskHan ftaskHan, ModuleToken mod);

extern MemHandle _far _pascal
    FidoGetPage(FTaskHan ftaskHan, ModuleToken mod, word pageNum);

extern MemHandle _far _pascal
    FidoGetHeader(FTaskHan ftaskHan, ModuleToken mod);

#endif

#ifdef LIBERTY

#ifndef COMPILING_BCL2C

class FidoDriver;

/*************************************/
/* Functions to register FidoDrivers */
/*************************************/
extern FidoDriver *FidoRegisterDriver(const TCHAR *driverName, 
				      FidoDriver *driver);
extern Result FidoUnregisterDriver(const TCHAR *driverName);

/*******************************************************************/
/* Functions to manipulate the path to search when loading modules */
/*******************************************************************/
/* Set a new path.  The old path is deleted.  The new path is copied. 
   Returns FAILURE if there was insufficient memory to make a copy of the
   new path. Returns SUCCESS otherwise. */
extern Result FidoSetPath(const TCHAR *newPath);

/* Get the current path.  A copy of the current path is put into buffer.
   If the bufferSize given is large enough, 0 is returned.  Else, the
   required bufferSize is returned and buffer will have as many characters
   of the path as it could hold. */
extern uint32 FidoGetPath(TCHAR *buffer, uint32 bufferSize);

/* Add the given path string to the end of the module search path. 
   Returns FAILURE if there was insufficient memory to append to the path.
   Returns SUCCESS otherwise.  */
extern Result FidoAppendPath(const TCHAR *pathToAdd);

/* Remove the given path string from the module search path.  Returns
   FAILURE if the pathToRemove is not found in the current path.
   Returns SUCCESS if the path was found and removed. */
extern Result FidoRemovePath(const TCHAR *pathToRemove);

/*********************************************************************/
/* Functions to manipulate the path to search when loading libraries */
/*********************************************************************/
/* Set a new path.  The old path is deleted.  The new path is copied. 
   Returns FAILURE if there was insufficient memory to make a copy of the
   new path. Returns SUCCESS otherwise. */
extern Result FidoSetLibraryPath(const TCHAR *newPath);

/* Get the current path.  A copy of the current path is put into buffer.
   If the bufferSize given is large enough, 0 is returned.  Else, the
   required bufferSize is returned and buffer will have as many characters
   of the path as it could hold. */
extern uint32 FidoGetLibraryPath(TCHAR *buffer, uint32 bufferSize);

/* Add the given path string to the end of the module search path. 
   Returns FAILURE if there was insufficient memory to append to the path.
   Returns SUCCESS otherwise.  */
extern Result FidoAppendLibraryPath(const TCHAR *pathToAdd);

/* Remove the given path string from the module search path.  Returns
   FAILURE if the pathToRemove is not found in the current path.
   Returns SUCCESS if the path was found and removed. */
extern Result FidoRemoveLibraryPath(const TCHAR *pathToRemove);

enum MakeComponentResultCode {
    MCRC_SUCCESS,
    MCRC_OUT_OF_MEMORY,
    MCRC_UNKNOWN_COMPONENT
};

class Component;

typedef MakeComponentResultCode (DLLMakeComponentFunction)(const TCHAR *componentName, Component **newComponent);

typedef struct {
    const TCHAR *libraryName;
    DLLMakeComponentFunction *func;
} LibraryRegistry;

#include <legos/runheap.h>
extern Boolean FidoRegisterAgg(ModuleToken module, TCHAR *aggName,
			       MemHandle /* RTaskHan */ module, word funcNum);

extern Boolean
FidoUseLibraryAgg(ModuleToken using_module, ModuleToken lib_module);

extern Boolean
FidoUseLibraryGeode(ModuleToken using_module, TCHAR* lib_name);

extern Boolean
FidoMakeMLCanonical(ModuleToken loading_module,
		     TCHAR* url, TCHAR* buffer, word buffer_length);

extern TCHAR* FidoGetML_withBuffer(ModuleToken, TCHAR*);
extern ModuleToken FidoFindML(TCHAR*, ModuleToken last_module);

extern TCHAR*
FidoGetML(ModuleToken module);

extern TCHAR*
FidoGetExport(ModuleToken module);

/* returns TRUE if the given module was registered as an aggregate module */
extern Boolean
FidoIsAggregateModule(ModuleToken module);

#include <legos/runtask.h>
extern dword
    FidoGetComplexData(RunTask *rtask, word element, RunHeapToken *rht);

#define FidoUseLibrary_Agg(junk, a, b) FidoUseLibraryAgg(a, b)
#define FidoUseLibrary_Geode(junk, a, b) FidoUseLibraryGeode(a, b)
#define Fido_MakeMLCanonical(junk, a, b, c, d) FidoMakeMLCanonical(a, b, c, d)
#define Fido_GetML(junk, a) FidoGetML(a)
#define Fido_GetExport(junk, a) FidoGetExport(a)

//=====================================================================
//
//			    W A R N I N G
//
// THE LIBERTY EXTERNAL API RESIDES ENTIRELY ABOVE THIS BARRIER.  
// ANYTHING BELOW THIS BARRIER REPRESENTS PORTIONS OF THE INTERNAL
// IMPLEMENTATION, MAY NOT BE USED OUTSIDE OF THE IMPLEMENTATION,
// AND IS SUBJECT TO CHANGE. 
//
//===================================================================== 

void FidoModuleSetNextToken(ModuleToken token, word nextIndex);
ModuleToken FidoModuleGetNextToken(ModuleToken token);

#ifdef ERROR_CHECK
Boolean FidoModuleTokenInUse(ModuleToken token);
#endif

#endif /* ifndef BCL2C */

#else	/* GEOS version below */

extern Boolean _far _pascal
    FidoGetComplexData(FTaskHan ftaskHan, ModuleToken module, word element,
		       VMFileHandle dest,
		       VMChain *chainP,
		       dword* /*ClipboardItemFormatID**/ idP);

extern Boolean _far _pascal
    FidoRegisterAgg(FTaskHan ftaskHan, ModuleToken module,
		    TCHAR* aggName,
		    MemHandle /*RTaskHan*/ rtaskHan, word funcNum);

#ifdef __HIGHC__
pragma Alias(FidoFindComponent, "FIDOFINDCOMPONENT");
pragma Alias(FidoRegLoadedCompLibs, "FIDOREGLOADEDCOMPLIBS");

pragma Alias(FidoOpenModule, "FIDOOPENMODULE");
pragma Alias(FidoCloseModule, "FIDOCLOSEMODULE");
pragma Alias(FidoGetPage, "FIDOGETPAGE");
pragma Alias(FidoGetHeader, "FIDOGETHEADER");
prgama Alias(FidoRegisterAgg, "FIDOREGISTERAGG");
#endif

#endif

#endif /* _FIDO_H_ */
