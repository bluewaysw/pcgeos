/* C code produced by gperf version 1.9 (K&R C version) */
/* Command-line: /usr/public/gperf -i1 -o -j1 -agSDptlC -k1-3 tokens.gperf  */


struct _Token {
    char        *name;
    int         token;
};

#define MIN_WORD_LENGTH 2
#define MAX_WORD_LENGTH 18
#define MIN_HASH_VALUE 4
#define MAX_HASH_VALUE 82
/*
   56 keywords
   79 is the maximum key range
*/

#ifdef __GNUC__
inline
#endif
static int
hash (register const char *str, register int len)
{
  static const unsigned char hash_table[] =
    {
     82, 82, 82, 82, 82, 82, 82, 82, 82, 82,
     82, 82, 82, 82, 82, 82, 82, 82, 82, 82,
     82, 82, 82, 82, 82, 82, 82, 82, 82, 82,
     82, 82, 82, 82, 82, 82, 82, 82, 82, 82,
     82, 82, 82, 82, 82, 46, 82, 82, 82, 82,
     82, 82, 82, 82, 82, 82, 82, 82, 82, 82,
     82, 82, 82, 82, 82, 82, 82, 82, 82, 82,
     82, 82, 82, 82, 82, 82, 82, 82, 82, 82,
     82, 82, 82, 82, 82, 82, 82, 82, 82, 82,
     82, 82, 82, 82, 82, 82, 82,  1, 20, 30,
      9,  1, 43, 82, 30,  1,  7, 34, 36, 11,
      5,  2,  5, 82, 43,  1, 19,  5,  1, 14,
     20,  3, 82, 82, 82, 82, 82, 82,
    };
  register int hval = len ;

  switch (hval)
    {
      default:
      case 3:
        hval += hash_table[str[2]];
      case 2:
        hval += hash_table[str[1]];
      case 1:
        hval += hash_table[str[0]];
    }
  return hval ;
}

#ifdef __GNUC__
inline
#endif
const struct _Token *
in_word_set (register const char *str, register int len)
{

  static const struct _Token  wordlist[] =
    {
      {"as",              AS,},
      {"system", 		SYSTEM,},
      {"single",          SINGLE,},
      {"nosort",          NOSORT,},
      {"appl",            APPL,},
      {"usernotes", 	USERNOTES,},
      {"appobj",          APPOBJ,},
      {"uses-coproc", 	USES_COPROC,},
      {"needs-coproc",    NEEDS_COPROC,},
      {"endif",           ENDIF,},
      {"name",            NAME,},
      {"discardable", 	DISCARDABLE,},
      {"discard-only",    DISCARDONLY,},
      {"swapable",        SWAPABLE,},
      {"swap-only", 	SWAPONLY,},
      {"stack",           STACK,},
      {"exempt",          EXEMPT,},
      {"discardable-dgroup",  DISCARDABLE_DGROUP,},
      {"entry", 		ENTRY,},
      {"type",            TYPE,},
      {"export",          EXPORT,},
      {"data",            DATA,},
      {"until",           UNTIL,},
      {"object",          OBJECT,},
      {"ship",            SHIP,},
      {"publish",         PUBLISH,},
      {"shared",          SHARED,},
      {"has-gcm", 	HAS_GCM,},
      {"skip",            SKIP,},
      {"heapspace", 	HEAPSPACE,},
      {"else",            ELSE,},
      {"load", 		LOAD,},
      {"incminor",        INCMINOR,},
      {"code",            CODE,},
      {"conforming",      CONFORMING,},
      {"rev",             REV,},
      {"noload",          NOLOAD,},
      {"platform",        PLATFORM,},
      {"longname",        LONGNAME,},
      {"lmem",            LMEM,},
      {"resource",        RESOURCE,},
      {"read-only",       READONLY,},
      {"ifndef",          IFNDEF,},
      {"preload",         PRELOAD,},
      {"process",         PROCESS,},
      {"ifdef",           IFDEF,},
      {"driver",          DRIVER,},
      {"no-swap",         NOSWAP,},
      {"ui-object",       UIOBJECT,},
      {"tokenid",         TOKENID,},
      {"no-discard",      NODISCARD,},
      {"library",         LIBRARY,},
      {"tokenchars",      TOKENCHARS,},
      {"fixed",           FIXED,},
      {"class",           CLASS,},
      {"c-api", 		C_API,},
    };

  if (len <= MAX_WORD_LENGTH && len >= MIN_WORD_LENGTH)
    {
      register int key = hash (str, len);

      if (key <= MAX_HASH_VALUE && key >= MIN_HASH_VALUE)
        {
          const struct _Token  *resword; int key_len;

          switch (key)
            {
            case   4:
              resword = &wordlist[0]; key_len = 2; break;
            case  11:
              resword = &wordlist[1]; key_len = 6; break;
            case  13:
              resword = &wordlist[2]; key_len = 6; break;
            case  14:
              resword = &wordlist[3]; key_len = 6; break;
            case  15:
              resword = &wordlist[4]; key_len = 4; break;
            case  16:
              resword = &wordlist[5]; key_len = 9; break;
            case  17:
              resword = &wordlist[6]; key_len = 6; break;
            case  18:
              resword = &wordlist[7]; key_len = 11; break;
            case  19:
              resword = &wordlist[8]; key_len = 12; break;
            case  20:
              resword = &wordlist[9]; key_len = 5; break;
            case  21:
              resword = &wordlist[10]; key_len = 4; break;
            case  22:
              resword = &wordlist[11]; key_len = 11; break;
            case  23:
              resword = &wordlist[12]; key_len = 12; break;
            case  24:
              resword = &wordlist[13]; key_len = 8; break;
            case  25:
              resword = &wordlist[14]; key_len = 9; break;
            case  26:
              resword = &wordlist[15]; key_len = 5; break;
            case  28:
              resword = &wordlist[16]; key_len = 6; break;
            case  29:
              resword = &wordlist[17]; key_len = 18; break;
            case  30:
              resword = &wordlist[18]; key_len = 5; break;
            case  31:
              resword = &wordlist[19]; key_len = 4; break;
            case  32:
              resword = &wordlist[20]; key_len = 6; break;
            case  33:
              resword = &wordlist[21]; key_len = 4; break;
            case  34:
              resword = &wordlist[22]; key_len = 5; break;
            case  35:
              resword = &wordlist[23]; key_len = 6; break;
            case  36:
              resword = &wordlist[24]; key_len = 4; break;
            case  37:
              resword = &wordlist[25]; key_len = 7; break;
            case  38:
              resword = &wordlist[26]; key_len = 6; break;
            case  39:
              resword = &wordlist[27]; key_len = 7; break;
            case  40:
              resword = &wordlist[28]; key_len = 4; break;
            case  41:
              resword = &wordlist[29]; key_len = 9; break;
            case  42:
              resword = &wordlist[30]; key_len = 4; break;
            case  43:
              resword = &wordlist[31]; key_len = 4; break;
            case  44:
              resword = &wordlist[32]; key_len = 8; break;
            case  45:
              resword = &wordlist[33]; key_len = 4; break;
            case  47:
              resword = &wordlist[34]; key_len = 10; break;
            case  48:
              resword = &wordlist[35]; key_len = 3; break;
            case  49:
              resword = &wordlist[36]; key_len = 6; break;
            case  50:
              resword = &wordlist[37]; key_len = 8; break;
            case  51:
              resword = &wordlist[38]; key_len = 8; break;
            case  52:
              resword = &wordlist[39]; key_len = 4; break;
            case  53:
              resword = &wordlist[40]; key_len = 8; break;
            case  54:
              resword = &wordlist[41]; key_len = 9; break;
            case  55:
              resword = &wordlist[42]; key_len = 6; break;
            case  56:
              resword = &wordlist[43]; key_len = 7; break;
            case  57:
              resword = &wordlist[44]; key_len = 7; break;
            case  58:
              resword = &wordlist[45]; key_len = 5; break;
            case  59:
              resword = &wordlist[46]; key_len = 6; break;
            case  60:
              resword = &wordlist[47]; key_len = 7; break;
            case  61:
              resword = &wordlist[48]; key_len = 9; break;
            case  62:
              resword = &wordlist[49]; key_len = 7; break;
            case  63:
              resword = &wordlist[50]; key_len = 10; break;
            case  64:
              resword = &wordlist[51]; key_len = 7; break;
            case  65:
              resword = &wordlist[52]; key_len = 10; break;
            case  69:
              resword = &wordlist[53]; key_len = 5; break;
            case  72:
              resword = &wordlist[54]; key_len = 5; break;
            case  82:
              resword = &wordlist[55]; key_len = 5; break;
            default: return 0;
            }
          if (len == key_len && *str == *resword->name && !strcmp (str + 1, resword->name + 1))
            return resword;
      }
  }
  return 0;
}
