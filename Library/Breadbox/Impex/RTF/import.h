#include "impdefs.h"
#include <xlatLib.h>

extern TransError RTFError;
extern ReaderStruct ReaderState;

#define GetDestMode() ( ReaderState.RS_destMode )
#define SetDestMode(mode)   ReaderState.RS_destMode = (mode)
#define GetReadMode() ( ReaderState.RS_readMode )
#define SetReadMode(mode) ReaderState.RS_readMode = (mode)
#define GetGroupDepth() ( ReaderState.RS_depth )
#define GetDestination() ( ReaderState.RS_destType )
#define GetGroup() ( ReaderState.RS_groupType )
#define GetGroupFlags() ( ReaderState.RS_groups )
#define SetReaderBinCount(x) ReaderState.RS_binCount = (x)

void IncGroupDepth(void);
void DecGroupDepth(void);
void SetDestination(DestinationType newType);
void SetGroup(GroupType newType);
void SetGroupFlag(GroupFlags newFlag);
