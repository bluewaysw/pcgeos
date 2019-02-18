#include <localize.h>
#include "codepage.h"

#define DEFAULT_CODEPAGE	CP_WESTEUROPE
#define SHUTDOWN_CODEPAGE	CP_NIL

wchar RTFCodePageToGeos(wchar ch);
wchar RTFGeosToCodePage(wchar ch);
void RTFSetCodePage(DosCodePage nCP);

