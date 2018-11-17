#ifndef __GLOBAL_H
#define __GLOBAL_H

#include <geos.h>
#include <graphics.h>
#include <Objects/Text/tcommon.h>
#include <xlatlib.h>

extern TransError RTFError;
#define SetError(x) RTFError = (x)
#define GetError() RTFError

#define TEXT_BUFFER_LEN 128

typedef struct
    {
    PageSetupInfo RTFDA_pageInfo;
    }
RTFDocumentAttr;

typedef struct
{
    dword HI_rangeStart;
    dword HI_rangeEnd;
    word HI_nameToken;
    word HI_nameFileToken;
} HyperlinkItem;

typedef struct
    {
    byte TBS_nCount;     /* current # of chars in buffer */
    char TBS_cData[TEXT_BUFFER_LEN];      /* text storage */
    }
TextBufferStruct;

typedef struct
{
    byte CBS_nCount;
    char CBS_cData[NAME_ARRAY_MAX_NAME_LENGTH+1];
} ContextBufferStruct;

extern VisTextParaAttr DefaultParaAttrs;
extern VisTextCharAttr DefaultCharAttrs;
extern RTFDocumentAttr DefaultDocAttrs;

void TextBufferInit(void);
void TextBufferFree(void);
Boolean TextBufferIsEmpty(void);
void TextBufferAddChar(char c);
void TextBufferDump(void);
void HyperlinkContextBufferAddChar(char c);
void ContextIDBufferAddChar(char c);
void EndHyperlink(void);
void EndContextReference(void);
void AddHyperlinkForRange(dword startPos, dword endPos);
void AddContextId(char* buffer, word* retContextToken, word* retFilenameToken);
void DefaultAttrsInit(void);

Boolean GroupStackInit(void);
void GroupStackFree(void);
Boolean GroupStackPush(void);
Boolean GroupStackPop(void);

Boolean RTFReportStatus(dword nSize, dword nPos);

TCHAR* GetNameString(word token, NameArrayMaxElement* buffer);
void StringConvertAndAppend(MemHandle *mem, TCHAR *p_string);
MemHandle DecodeEncodedString(TCHAR *p_string);

/**********************************************************************
  _DO_HELP (TOOLS ONLY): Defines the ability for the RTF Import/Export
  filter to preserve type runs involving context ranges and hyperlinks. 
  Hyperlinks are preserved by the standard WinHelp RTF mechanism: 
  overloading \ul and \uldb so that they specify the beginning of a 
  hyperlink range, and using \v to specify the target context-id for 
  the hyperlink.
  Contexts themselves are preserved using a \footnote group,
  preceded by a # symbol.

  In addition, some plain text tags have been defined:
  geoshelp, startcontextrange, endcontextrange, and button.
  These tags start and end with characters 171 and 187 respectively.
  
  geoshelp:  Defines that this is a GEOS help source file.  When the
             filter hits this token, then we start overloading the
	     \footnote, \ul, \uldb, and \v tokens.
  startcontextrange: Since WinHelp does not support the notion of context
                     type ranges, this token signals to the filter to start
		     a context range at this position.
  endcontextrange: Ends a started context range.
  button: This token is used to preserve the special "button" extended style
          attribute so commonly used in GEOS help files.  It was necessary to
	  define a plain-text tag for this purpose (in addition to defining
	  equivalent formatting styles) because some localization tools
	  running under Windows (specifically, TRADOS) were destroying the
	  equivelant formatting style.
  *************************************************************************/

#ifdef DO_HELP
#define _DO_HELP 1
#else
#define _DO_HELP 0
#endif

#endif /* __GLOBAL_H */
