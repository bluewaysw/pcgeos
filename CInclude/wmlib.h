
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

word _pascal _export WMAddWord(WMParamsStruct *wmStruct) ;
Boolean _pascal _export WMFindWord(WMParamsStruct *wmStruct, Boolean newSearch) ;
void _pascal _export WMRenameWord(WMParamsStruct *wmStruct, Boolean doSearch) ;
void _pascal _export WMDeleteWord(WMParamsStruct *wmStruct, Boolean doSearch) ;

/*---------------------------------------------------------------------------
	2024-07-01	RainerB	- quick creation of a new wordlist added 
 ---------------------------------------------------------------------------*/

#define WL_DB_IS_UNCOMPRESSED 		1
#define WL_DB_UNDER_CONSTRUCTION 	2

/*--------------------- WLCreateNewDB ---------------------
 *	Purpose:	Start building a new, empty word list data base.
 ---------------------------------------------------------------------------*/
void _pascal _export WLCreateNewDB(VMFileHandle fh, Boolean compressed, optr debugText);

/*--------------------- WLAddWordToNewDBUnchecked ---------------------
 *	Purpose:	Add a word to new database, created with WLCreateNewDB
 *			For perfomance, it is not checked whether the word already exists!
---------------------------------------------------------------------------*/
Boolean _pascal _export WLAddWordToNewDBUnchecked(VMFileHandle fh, char *newWord, optr debugText);

/*--------------------- WLFinishNewDB ---------------------
 *	Purpose:	Finsh building the new word list data base.
 ---------------------------------------------------------------------------*/
Boolean _pascal _export WLFinishNewDB(VMFileHandle fh, Boolean closeFile, optr debugText);
