extern dword TextCurPos;   /* insertion position in output text object */

void TextInit(optr obj);
void TextAppendText(char *pText);
void TextAppendCharAttrs(VisTextCharAttr *pAttrs);
void TextAppendParaAttrs(VisTextParaAttr *pAttrs);

#define VISTEXTPARAATTRSIZE(pPara)  ( sizeof(VisTextParaAttr) + ((pPara)->VTPA_numberOfTabs * sizeof(Tab)) )

#define C_SECTION_BREAK C_CTRL_K
#define C_PAGE_BREAK    C_CTRL_L
#define C_COLUMN_BREAK  C_PAGE_BREAK

