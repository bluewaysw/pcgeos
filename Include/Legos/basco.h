/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



	Copyright (c) Geoworks 1995 -- All Rights Reserved



PROJECT:        Legos

MODULE:         Basic compiler

FILE:           basco.h



AUTHOR:         Paul L. DuBois, Jan 18, 1995



REVISION HISTORY:

	Name    Date            Description

	----    ----            -----------

	dubois   1/18/95        Initial version.



DESCRIPTION:

	Funcs defined in basco lib



	$Id: basco.h,v 1.1 97/12/05 12:16:04 gene Exp $

	$Revision: 1.1 $



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

#ifndef _BASCO_H_

#define _BASCO_H_



#include <Legos/opcode.h>

#include <Legos/bug.h>

#include <Legos/basrun.h>



#define FUNCTION_LENGTH 8

#define FUNCTION_LENGTH_PLUS_ONE 9

#define END_LENGTH 3

#define SUB_LENGTH 3

#define SUB_LENGTH_PLUS_ONE 4



typedef MemHandle CTaskHan;



typedef enum

{

    FT_NONE,

    FT_FUNCTION,

    FT_SUBROUTINE,

    FT_BUILT_IN_FUNC,

    FT_END_FUNCTION,

    FT_END_SUB,

    FT_ERROR

} BascoFuncType;



extern Boolean	BascoDeleteRoutine(MemHandle ctask, int funcNumber);

    

/* Returns compile task, which isn't useful for much besides passing

 * to BascoWriteCode */

extern CTaskHan	BascoCompileModule(VMFileHandle vmfh, TCHAR *file);

extern RTaskHan	BascoCompileCodeFromTask(CTaskHan ctask, Boolean updateMode);

extern word	BascoGetNumFunctions(CTaskHan ctask);

extern Boolean	BascoCompileFunction(CTaskHan ctask, int funcNumber);

extern int	BascoLoadFile(CTaskHan ctask, TCHAR *file);



/* Create/tweak compiler tasks */

extern CTaskHan	BascoAllocTask(VMFileHandle vmfh, BugBuilderInfo *bbi);

extern void	BascoSetLiberty(MemHandle comTask, Boolean libertyP);

extern void	BascoDestroyTask(CTaskHan ctask);



/* Add a source line/block to the task.

 * Used extensively by the builder/editor

 */

extern BascoFuncType BascoLineAdd(CTaskHan ctask, TCHAR *line);

extern void	BascoBlockAdd(CTaskHan ctask, TCHAR *block);

extern void	BascoTerminateRoutine(CTaskHan ctask);



/* Getting error information */

extern void	BascoReportError(CTaskHan ctask, int *funcIndex, int *line);

extern word BascoGetCompileErrorForFunction(CTaskHan ctask, int funcNumber);

extern void BascoSetTaskErrorToFunction(CTaskHan ctask, int funcNumber);

			     

/* - interface for writing out compiled code */

/* complexArray is an chunkarray of complex (dword) values.

 * It may also be null.

 */

extern Boolean	BascoWriteResources(TCHAR* name, optr complexArray,

				    RunHeapInfo* rhi,

				    Boolean liberty);

extern Boolean	BascoWriteCode(TCHAR* name, CTaskHan ctask);





extern MemHandle 

BascoCompileTaskSetFidoTask(CTaskHan ctask, MemHandle fidoTask);



extern void

BascoSetCompileTaskBuildTime(CTaskHan ctask, byte buildTime);

extern void

BascoSetCompileTaskOptimize(CTaskHan ctask, byte optimize);



extern Boolean BascoIsKeyword(TCHAR *name, int len);



#endif /* _BASCO_H_ */

