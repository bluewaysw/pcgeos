#ifndef __SVG_LOG_H
#define __SVG_LOG_H

#include "Import/svg.h"

#if ERROR_CHECK

void _pascal SvgLogInit(SvgImportContext *contextP);
void _pascal SvgLogStart(SvgImportContext *contextP);
void _pascal SvgLogEnd(SvgImportContext *contextP);
void _cdecl SvgLogPrintf(SvgImportContext *contextP, const char *label,
                         const char *format, ...);
void _cdecl SvgLogPrintfPlain(SvgImportContext *contextP,
                              const char *format, ...);
void _pascal SvgLogValue(SvgImportContext *contextP, const char *label,
                         sdword value, Boolean signedValue, Boolean hexValue);
void _pascal SvgLogStr(SvgImportContext *contextP, const char *label,
                       const char *value);
void _pascal SvgLogStrSegment(SvgImportContext *contextP, const char *label,
                              const char *value, word from, word to);

#define LOG_INIT(c) SvgLogInit(c)
#define LOG_START(c) SvgLogStart(c)
#define LOG_END(c) SvgLogEnd(c)
#define LOGF(args) ((void)0)
#define LOGF0(args) ((void)0)
#define LOG_BYTE(c,l,v) SvgLogValue(c,l,(sdword)(byte)(v),FALSE,FALSE)
#define LOG_SBYTE(c,l,v) SvgLogValue(c,l,(sdword)(sbyte)(v),TRUE,FALSE)
#define LOG_WORD(c,l,v) SvgLogValue(c,l,(sdword)(word)(v),FALSE,FALSE)
#define LOG_SWORD(c,l,v) SvgLogValue(c,l,(sdword)(sword)(v),TRUE,FALSE)
#define LOG_DWORD(c,l,v) SvgLogValue(c,l,(sdword)(dword)(v),FALSE,FALSE)
#define LOG_SDWORD(c,l,v) SvgLogValue(c,l,(sdword)(v),TRUE,FALSE)
#define LOG_BOOL(c,l,v) SvgLogStr(c,l,(v) ? "TRUE" : "FALSE")
#define LOG_PTR(c,l,v) SvgLogValue(c,l,(sdword)(dword)(v),FALSE,TRUE)
#define LOG_CHUNK(c,l,v) SvgLogValue(c,l,(sdword)(word)(v),FALSE,TRUE)
#define LOG_MEM(c,l,v) SvgLogValue(c,l,(sdword)(word)(v),FALSE,TRUE)
#define LOG_FILE(c,l,v) SvgLogValue(c,l,(sdword)(word)(v),FALSE,TRUE)
#define LOG_OPTR(c,l,v) SvgLogValue(c,l,(sdword)(dword)(v),FALSE,TRUE)
#define LOG_STR(c,l,v) SvgLogStr(c,l,v)
#define LOG_STR_SEGMENT(c,l,s,f,t) SvgLogStrSegment(c,l,s,f,t)
#define LOG_STR_HEAD(c,l,s,n) SvgLogStrSegment(c,l,s,0,n)
#define LOG_STR_TAIL(c,l,s,n) SvgLogStrSegment(c,l,s,0xffff-(n),0xffff)
#define LOG_STR_RANGE(c,l,s,f,t) SvgLogStrSegment(c,l,s,f,t)
#define LOG_STR_ALL(c,l,s) SvgLogStr(c,l,s)

#else

#define LOG_INIT(c) ((void)0)
#define LOG_START(c) ((void)0)
#define LOG_END(c) ((void)0)
#define LOGF(args) ((void)0)
#define LOGF0(args) ((void)0)
#define LOG_BYTE(c,l,v) ((void)0)
#define LOG_SBYTE(c,l,v) ((void)0)
#define LOG_WORD(c,l,v) ((void)0)
#define LOG_SWORD(c,l,v) ((void)0)
#define LOG_DWORD(c,l,v) ((void)0)
#define LOG_SDWORD(c,l,v) ((void)0)
#define LOG_BOOL(c,l,v) ((void)0)
#define LOG_PTR(c,l,v) ((void)0)
#define LOG_CHUNK(c,l,v) ((void)0)
#define LOG_MEM(c,l,v) ((void)0)
#define LOG_FILE(c,l,v) ((void)0)
#define LOG_OPTR(c,l,v) ((void)0)
#define LOG_STR(c,l,v) ((void)0)
#define LOG_STR_SEGMENT(c,l,s,f,t) ((void)0)
#define LOG_STR_HEAD(c,l,s,n) ((void)0)
#define LOG_STR_TAIL(c,l,s,n) ((void)0)
#define LOG_STR_RANGE(c,l,s,f,t) ((void)0)
#define LOG_STR_ALL(c,l,s) ((void)0)

#endif
#endif
