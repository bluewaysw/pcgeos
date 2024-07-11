
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

/*--------------------- WMCreateNewDB ---------------------
 *	Purpose:	Start building a new, empty word list data base.
 ---------------------------------------------------------------------------*/
void _pascal _export WMCreateNewDB(VMFileHandle fh, Boolean compressed, optr debugText);

/*--------------------- WMAddWordToNewDBUnchecked ---------------------
 *	Purpose:	Add a word to new database, created with WMCreateNewDB
 *			For perfomance, it is not checked whether the word already exists!
---------------------------------------------------------------------------*/
Boolean _pascal _export WMAddWordToNewDBUnchecked(VMFileHandle fh, char *newWord, optr debugText);

/*--------------------- WMFinishNewDB ---------------------
 *	Purpose:	Finish building the new word list data base.
 ---------------------------------------------------------------------------*/
Boolean _pascal _export WMFinishNewDB(VMFileHandle fh, Boolean closeFile, optr debugText);
