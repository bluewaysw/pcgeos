#include <runint.h>

typedef enum
{
#define BTABLE_ENUM
#ifdef LIBERTY
#include "Legos/btable.h"
#else
#include <Legos/Bridge/btable.h>
#endif
#undef BTABLE_ENUM
    NUM_BUILT_IN_FUNCTIONS
} BuiltInFuncEnum;

typedef void (BuiltInVector)(RMLPtr, BuiltInFuncEnum);


typedef struct {
    BuiltInVector       *BIFE_vector;
} BuiltInFuncEntry;

#ifdef __BORLANDC__
extern BuiltInFuncEntry _far BuiltInFuncs[NUM_BUILT_IN_FUNCTIONS];
#else /* __HIGHC__ */
extern const BuiltInFuncEntry BuiltInFuncs[NUM_BUILT_IN_FUNCTIONS];
#endif

extern void FunctionStringCommon(register RMLPtr rms, BuiltInFuncEnum id);
extern void FunctionStringInstr(register RMLPtr rms, BuiltInFuncEnum id);
extern void FunctionCommonStringToNumber(register RMLPtr rms, BuiltInFuncEnum id);
extern void FunctionCommonNumberToString(register RMLPtr rms, BuiltInFuncEnum id);
extern void FunctionRoundFormat(register RMLPtr rms, BuiltInFuncEnum id);
extern void FunctionMathCommon(register RMLPtr rms, BuiltInFuncEnum id);
extern void FunctionComponent(register RMLPtr rms, BuiltInFuncEnum id);
extern void FunctionLoadModule(register RMLPtr rms, BuiltInFuncEnum id);
extern void SubroutineSetTop(register RMLPtr rms, BuiltInFuncEnum id);
extern void FunctionValidParent(register RMLPtr rms, BuiltInFuncEnum id);
extern void FunctionHasProperty(register RMLPtr rms, BuiltInFuncEnum id);
extern void FunctionUpdate(register RMLPtr rms, BuiltInFuncEnum id);
extern void FunctionGetComplex(register RMLPtr rms, BuiltInFuncEnum id);
extern void FunctionCurModule(register RMLPtr rms, BuiltInFuncEnum id);
extern void FunctionIsNullComponent(register RMLPtr rms, BuiltInFuncEnum id);
extern void FunctionStringStrComp(register RMLPtr rms, BuiltInFuncEnum id);
extern void FunctionRaiseEvent(register RMLPtr rms, BuiltInFuncEnum id);
extern void SubroutineExportAggregate(register RMLPtr rms, BuiltInFuncEnum id);
extern void FunctionGetArrayDims(register RMLPtr rms, BuiltInFuncEnum id);
extern void FunctionGetArraySize(register RMLPtr rms, BuiltInFuncEnum id);
extern void FunctionSystemModule(register RMLPtr rms, BuiltInFuncEnum id);
extern void FunctionIsNullComplex(register RMLPtr rms, BuiltInFuncEnum id);
extern void FunctionGetError(register RMLPtr rms, BuiltInFuncEnum id);
extern void SubroutineRaiseError(register RMLPtr rms, BuiltInFuncEnum id);
extern void FunctionRefCounts(register RMLPtr rms, BuiltInFuncEnum id);
extern void FunctionEnableDisableEvents(register RMLPtr rms, BuiltInFuncEnum id);
extern void FunctionType(register RMLPtr rms, BuiltInFuncEnum id);
extern void FunctionUnloadModuleCommon(register RMLPtr rms, BuiltInFuncEnum id);
extern void FunctionLoadModuleShared(register RMLPtr rms, BuiltInFuncEnum id);
extern void SubroutineUseLibrary(register RMLPtr rms, BuiltInFuncEnum id);
extern void FunctionIsNull(register RMLPtr rms, BuiltInFuncEnum id);
extern void FunctionGetSourceExport(register RMLPtr rms, BuiltInFuncEnum id);
extern void FunctionGetMemoryUsedBy(register RMLPtr rms, BuiltInFuncEnum id);
