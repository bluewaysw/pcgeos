/* Cookie routines */
optr _pascal CookieFind(TCHAR *anchorPath, TCHAR *anchorHost, Boolean secure) ;
void _pascal CookieParse(TCHAR *anchorPath, TCHAR *anchorHost, char *cTxt) ;
void _pascal CookieSet(
    TCHAR *anchorPath, 
    TCHAR *anchorHost,
    const char *name, 
    const char *value,
    const char *expires, 
    const char *path, 
    const char *domain, 
    Boolean secure) ;
void _pascal CookiesWrite(void) ;
//void _pascal CookiesCleanup(void) ;

/* Utility routines */
void _pascal CookieParseTime(char *p, TimerDateAndTime *t) ;
