#define CONTROL_MAX_LENGTH 20

#define CONTROL_GEOS_HELP  0xa

typedef ByteEnum ControlType;
#define CT_CPROP        1       /* character property */
#define CT_PPROP        2       /* paragraph property */
#define CT_DEST         3       /* destination change */
#define CT_CHAR         4       /* destination character */
#define CT_OTHER        5       /* calls functions */
#define CT_TABPROP      6       /* tab property */
#define CT_DEFCPROP     7       /* default character property */
#define CT_DEFPPROP     8       /* default paragraph property */
#define CT_DEFDOCPROP   9       /* document property */

typedef enum
    {
    CST_VALUE = 1,
    CST_TOGGLE,
    CST_FLAGSET,
    CST_FLAGRESET,
    CST_FLAGMASK,
    CST_LONGINT
    }
ControlSourceType;

typedef enum
    {
    CDT_DWORD = 0,
    CDT_BYTEFLAG = 1,
    CDT_WORDFLAG,
    CDT_BYTENUM,
    CDT_WORDNUM,
    CDT_BBFIXED,
    CDT_133,
    CDT_WBFIXED,
    CDT_WWFIXED
    }
ControlDestType;
typedef byte ControlSourceDestType;
#define MAKE_CSDT(s,d)      ((s) | ((d) << 4))
#define CSDT_GET_SRC(sd)    ((sd) & 0x0F)
#define CSDT_GET_DEST(sd)   (((sd) & 0xF0) >> 4)

typedef void (*ControlFuncPtr)();       /* Parameters here matter not */

typedef struct
    {
    char CTE_label[CONTROL_MAX_LENGTH];
    ControlType CTE_type;
    ControlFuncPtr CTE_pfFunc;
    byte CTE_offset;
    ControlSourceDestType CTE_SDType;
    word CTE_extra;
    }
ControlTableEntry;

/* ControlType eType -- what is this?  A destination character, change, other, etc? 
   ControlTableEntry* pEntry -- a pointer to the entry for this control in the control table.
   WWFixedAsDWord* pfParam -- any  parameter to the token
   Boolean bHasParam -- TRUE if *pfParam contains anything meaningful. */
typedef Boolean ControlFunc(ControlType eType,
  ControlTableEntry* pEntry, WWFixedAsDWord* pfParam, Boolean bHasParam);

/* Used by special control functions to convert parameters. */
dword ConvertParameter(WWFixedAsDWord fParam, ControlDestType eType);

void ControlParse(void);

void HandleDestControl(ControlTableEntry entry);

void HandleControls(ControlTableEntry entry, long int param,
		    Boolean bHasParam);
Boolean ControlLookup(char *pLabel, ControlTableEntry *pResult);
Boolean ControlGet(char *control, long int *param, Boolean *pbHasParam);
