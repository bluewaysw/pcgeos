typedef enum
    {
    SST_DWORD = 0,
    SST_BYTEFLAG = 1,
    SST_WORDFLAG,
    SST_BYTENUM,
    SST_WORDNUM,
    SST_BBFIXED,
    SST_133,
    SST_WBFIXED,
    SST_WWFIXED,
    SST_WORD,
    }
ScanSourceType;

typedef enum
    {
    SDT_NONE,
    SDT_VALUE = 1,
    SDT_TOGGLE,
    SDT_FLAG,
    }
ScanDestType;

#define SCAN_LABEL_MAX_LENGTH	32

#define UNRESETTABLE_CHAR_ATTRS_DIFFS	( VTCAD_

char* StringCopyWord(char* pString, char* pBuf, int nBufLen, int nWord);
WWFixedAsDWord ScanConvertData(void* pData, ScanSourceType sst, word extra);
Boolean ScanEmitControlFromData(long int nParam, ScanDestType sdt, char* pcaControl,
  int nWord);

typedef Boolean ScanFunc(WWFixedAsDWord fxParam, void* pData, ScanSourceType sst,
  ScanDestType sdt, char* control, word extra);

void ScanFindCharAttrDiffs(VisTextCharAttr* p1, VisTextCharAttr* p2,
  VisTextCharAttrDiffs *pd);
void ScanFindParaAttrDiffs(VisTextParaAttr* p1, VisTextParaAttr* p2,
  VisTextParaAttrDiffs *pd);
Boolean ScanTestUnresettableCharAttrs(VisTextCharAttr* pa,
  VisTextCharAttrDiffs* pd, Boolean* pbAttrChangeOrReset);

Boolean ScanEmitCharDiffs(VisTextCharAttr* pNew, VisTextCharAttrDiffs* pd);
Boolean ScanEmitParaDiffs(VisTextParaAttr* pNew, VisTextParaAttrDiffs* pd);
Boolean ScanEmitDocAttrs(void);
Boolean ScanEmitChar(unsigned char c);

Boolean ScanInit(void);
void ScanFree(void);
