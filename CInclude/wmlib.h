
#define WM_MAX_SIZE_WORD 20

#define WME_NONE		0
#define WME_NO_FILE	1
#define WME_TOO_SMALL	2
#define WME_TOO_BIG	3
#define WME_NO_BLOCK	4

typedef struct {
    word WMPS_lengthWord ;
    char WMPS_search[WM_MAX_SIZE_WORD] ;
    char WMPS_found[WM_MAX_SIZE_WORD] ;
    VMFileHandle WMPS_file ;

    /* Internal data. */
    VMBlockHandle WMPS_currentBlock ;
    word          WMPS_currentOffset ;
    Boolean       WMPS_searchDone ;
} WMParamsStruct ;

word WMAddWord(WMParamsStruct *wmStruct) ;
Boolean WMFindWord(WMParamsStruct *wmStruct, Boolean newSearch) ;
void WMRenameWord(WMParamsStruct *wmStruct, Boolean doSearch) ;
void WMDeleteWord(WMParamsStruct *wmStruct, Boolean doSearch) ;

