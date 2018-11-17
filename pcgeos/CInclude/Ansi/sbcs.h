/*
 * Even for DBCS, always use SBCS versions
 */
#ifdef DO_DBCS
#define sprintf sprintfsbcs
#define vsprintf vsprintfsbcs
#define strlen(s) strlensbcs(s)
#define strchr(s,c) strchrsbcs(s,c)
#define strrchr(s,c) strrchrsbcs(s,c)
#define strpos strpossbcs
#define strrpos strrpossbcs
#define strcpy(s,t) strcpysbcs(s,t)
#define strncpy(s,t,n) strncpysbcs(s,t,n)
#define strcmp(s,t) strcmpsbcs(s,t)
#define strncmp(s,t,n) strncmpsbcs(s,t,n)
#define strcat(s,t) strcatsbcs(s,t)
#define strncat(s,t,n) strncatsbcs(s,t,n)
#define strspn(s,t) strspnsbcs(s,t)
#define strcspn(s,t) strcspnsbcs(s,t)
#define strpbrk(s,t) strpbrksbcs(s,t)
#define strrpbrk(s,t) strrpbrksbcs(s,t)
#define strstr(s,t) strstrsbcs(s,t)
#define strrev(s) strrevsbcs(s)
#define atoi(s) atoisbcs(s)
#define itoa(n,s) itoasbcs(n,s)
#endif
