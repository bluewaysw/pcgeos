#ifndef _IMPDEFS_H_
#define _IMPDEFS_H_

typedef ByteEnum DestMode;
#define DM_NORMAL       0
#define DM_SKIP         1
#define DM_NO_BUFFER    2
#define DM_CONTEXT_ID   3

typedef ByteEnum ReadMode;
#define RM_NORMAL   0
#define RM_HEX      1
#define RM_BIN      2

typedef enum { DT_NONE, DT_RTF, DT_FONTTBL, DT_COLORTBL } DestinationType;
typedef enum { GT_NONE, GT_RTF, GT_FONTTBL, GT_COLORTBL } GroupType;

typedef ByteFlags GroupFlags;
#define GF_FONTTBL		0x01
#define GF_COLORTBL 	0x02

typedef struct
    {
    DestMode RS_destMode;
    ReadMode RS_readMode;
    char RS_hexNibble;
    long int RS_binCount;
    word RS_depth;
    DestinationType RS_destType;
    GroupType RS_groupType;
    GroupFlags RS_groups;
    }
ReaderStruct;

#endif
