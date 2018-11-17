#include "impdefs.h"
#include <Objects/Text/tcommon.h>

/* 	All functions which return a pointer must call GroupsUnlock() when done
	with the pointer.  The returned pointer may become invalid after calling
	GroupsUnlock(). */

Boolean GroupsInit(void);
void GroupsFree(void);
void GroupsUnlock(void);
void EmitTextToCurrentDestination(char *pText, int nLen);
VisTextCharAttr* GetGroupCharAttrs(void);
void SetGroupCharAttrsDirty(void);
VisTextParaAttr* GetGroupParaAttrs(void);
void SetGroupParaAttrsDirty(void);
Tab* GetGroupWorkTab(void);

void OpenGroup(GroupType eType);
void CloseGroup(GroupType eType);

ColorQuad* GroupColorTableGetWorkspace(void);
void GroupColorTableAddColor(ColorQuad* pColor, Boolean bDefault);
Boolean GroupColorTableFindColor(int nIndex, ColorQuad* pColor);
Boolean GroupColorTableFindColorByQuad(ColorQuad* pColor,
	int* pIndex);
Boolean GroupColorTableEmitTable(void);

void GroupFontTableWorkSetCharset(byte nCharSet);
void GroupFontTableWorkSetFontID(word nFID);
void GroupFontTableWorkSetFamily(FontFamily eFamily);
void GroupFontTableWorkSetPitch(word nFixed);
FontID GroupFontTableFindFont(word nFID);
void GroupFontTableAddFontByID(FontID nFID);
Boolean GroupFontTableEmitTable(void);
Boolean GroupFontTableFindFontIndex(FontID nFID, word* pnIdx);
DosCodePage GroupFontTableGetCodePage(word nIdx);

