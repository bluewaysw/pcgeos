/* Cookie routines */
optr _pascal _export CookieFind(TCHAR *anchorPath, TCHAR *anchorHost, Boolean secure) ;
void _pascal _export CookieParse(TCHAR *anchorPath, TCHAR *anchorHost, char *cTxt) ;
void _pascal _export CookieSet(
    TCHAR *anchorPath, 
    TCHAR *anchorHost,
    const char *name, 
    const char *value,
    const char *expires, 
    const char *path, 
    const char *domain, 
    Boolean secure) ;
void _pascal _export CookiesWrite(void) ;
//void _pascal CookiesCleanup(void) ;

/* Utility routines */
void _pascal _export CookieParseTime(char *p, TimerDateAndTime *t) ;
