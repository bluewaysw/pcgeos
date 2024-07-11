/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996 -- All Rights Reserved

PROJECT:	Legos
MODULE:		Runtime
FILE:		fidoutil.c

AUTHOR:		Paul L. Du Bois, Apr 15, 1996

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	4/15/96  	Initial version.

DESCRIPTION:
	Utility routines for Fido.

	$Revision: 1.2 $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

#include <Ansi/string.h>
#include "compat.h"
#include "mystdapp.h"
#include "fixds.h"
#include "fidoint.h"


/*********************************************************************
 *			Fido_MakeMLCanonical
 *********************************************************************
 * SYNOPSIS:	Make a URL canonical -- fully qualified and absolute
 * CALLED BY:	EXTERNAL (assembly Fido code)
 * RETURN:	FALSE on failure
 * SIDE EFFECTS:
 * STRATEGY:
 *	Assume ftaskHan is locked.
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	4/15/96  	Initial version
 * 
 *********************************************************************/
Boolean _pascal
Fido_MakeMLCanonical(FTaskHan	ftaskHan,
		      ModuleToken loading_module,
		      TCHAR*	old_ml,
		      TCHAR*	buffer,
		      word	buffer_length)
{
    FidoTask_C*	ftask;
    optr	module_array;
    word	head_length;
    DS_DECL;
    DS_DGROUP;

    /* First, deal with old-style ML's, that look like
     * C:\FOO\BAR or ~D\FOO\BAR.
     */
    if ((old_ml[0] == C_ASCII_TILDE) || (old_ml[1] == C_COLON))
    {
	Boolean	restore_colon = FALSE;
	word	i;

	/* Prepend DOS://, change backslash to forward slash */
	head_length = 6;
	if (strlen(old_ml) + head_length >= buffer_length) goto failure;

	if (old_ml[1] == C_COLON) {
	    /* lose the colon after the drive letter */
	    old_ml[1] = old_ml[0];
	    old_ml++;
	    restore_colon = TRUE;
	}

	strcpy(buffer, _TEXT("DOS://"));
	strcat(buffer, old_ml);

	for (i=0; i<buffer_length; i++)	{
	    if (buffer[i] == C_BACKSLASH) {
		buffer[i] = C_SLASH;
	    }
	}

	if (restore_colon) {
	    old_ml[0] = C_COLON;
	}
	goto success;
    }
    
    ftask = MemDeref(ftaskHan);
    module_array = ConstructOptr(ftaskHan, ftask->FT_modules);
    
    /* Since colon is a reserved char, it's a decent way to check
     * if the ML is absolute or relative.
     */
    if (strchr(old_ml, C_COLON) == NULL)
    {
	/* Relative -- prepend prev module's path
	 */
	ModuleData_C*	md;
	TCHAR*		loading_ml;
	TCHAR*		ml_tail;
	
	/* No prev module */
	if (loading_module == NULL_MODULE) goto failure;

	md = ChunkArrayElementToPtr(module_array, loading_module, NULL);
	loading_ml = LMemDerefHandles(ftaskHan, md->MD_ml);
	ml_tail = strrchr(loading_ml, C_SLASH);

	/* Unexpected -- prev module's ML is not absolute?! */
	if ((ml_tail == NULL)) goto failure;

	head_length = (ml_tail+1) - loading_ml;

	/* Yuck, buffer overrun */
	if (strlen(old_ml) + head_length >= buffer_length) goto failure;

	strncpy(buffer, loading_ml, head_length);
	buffer[head_length] = C_NULL;
	strcat(buffer, old_ml);
    } else {
	if (strlen(old_ml) >= buffer_length) goto failure;
	strcpy(buffer, old_ml);
    }

 success:
    DS_RESTORE;
    return TRUE;

 failure:
    DS_RESTORE;
    return FALSE;
}

/*********************************************************************
 *			Fido_GetML
 *********************************************************************
 * SYNOPSIS:	Extract ML from a module
 * CALLED BY:	EXTERNAL
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 *	Make sure the FidoTask is locked.
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	4/23/96  	Initial version
 * 
 *********************************************************************/
TCHAR*
Fido_GetML(FTaskHan ftaskHan, ModuleToken module)
{
    FidoTask_C*	ftask;
    optr	moduleArray;
    ModuleData_C* md;

    if (module == NULL_MODULE) {
	DS_DECL;
	TCHAR*	retval;
	DS_DGROUP;
	retval = _TEXT("<Unloading>");
	DS_RESTORE;
	return retval;
    } else {
	ftask = MemDeref(ftaskHan);
	ASSERT(ftask->FT_tag == FT_MAGIC_NUMBER);
	moduleArray = ConstructOptr(ftaskHan, ftask->FT_modules);
	md = ChunkArrayElementToPtr(moduleArray, module, NULL);
	EC_BOUNDS(md);
	return LMemDerefHandles(ftaskHan, md->MD_ml);
    }
}

/*********************************************************************
 *			Fido_GetExport
 *********************************************************************
 * SYNOPSIS:	Get name of exported agg
 * CALLED BY:	EXTERNAL
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 *	Make sure the FidoTask is locked.
 *
 *	The ModuleToken's connected to the	ModuleData
 *	The ModuleData's  connected to the	LibraryData
 *	The LibraryData's connected to the	AggCompDecl
 *	The AggCompDecl's connected to the	TCHAR*
 *
 *	and we return the TCHAR*
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	4/26/96  	Initial version
 * 
 *********************************************************************/
#ifdef LIBERTY
#error This will probably have to be re-implemented from scratch
#endif
TCHAR*
Fido_GetExport(FTaskHan ftaskHan, ModuleToken module)
{
    FidoTask_C*	ftask;
    ModuleData_C*	md;
    LibraryData_C*	ld;
    optr	exports;
    AggCompDecl_C* acd;
    TCHAR*	exportName;
    
    ftask = MemDeref(ftaskHan);

    md = ChunkArrayElementToPtrHandles
	(ftaskHan, ftask->FT_modules, module, NULL);

    if (md->MD_myLibrary == CA_NULL_ELEMENT) return NULL;
    ld = ChunkArrayElementToPtrHandles
	(ftaskHan, ftask->FT_libraries, md->MD_myLibrary, NULL);

    exports = ConstructOptr(ftaskHan, ld->LD_components);
    if (ChunkArrayGetCount(exports) == 0) return NULL;

    acd = ChunkArrayElementToPtr(exports, 0, NULL);
    exportName = (TCHAR*)(acd+1);

    return exportName;
}
