/* C code produced by gperf version 1.9 (K&R C version) */
/* Command-line: /usr/public/gperf -i16 -o -j1 -agSDptlC -N findSegAttr -H hashSegAttr segattrs.gperf  */


struct _SegAttr {
    char	*name;
    int		token;
    int		value;
};

#define MIN_WORD_LENGTH 4
#define MAX_WORD_LENGTH 8
#define MIN_HASH_VALUE 4
#define MAX_HASH_VALUE 14
/*
   11 keywords
   11 is the maximum key range
*/

#ifdef __GNUC__
inline
#endif
static int
hashSegAttr (register const char *str, register int len)
{
  static const unsigned char hash_table[] =
    {
     14, 14, 14, 14, 14, 14, 14, 14, 14, 14,
     14, 14, 14, 14, 14, 14, 14, 14, 14, 14,
     14, 14, 14, 14, 14, 14, 14, 14, 14, 14,
     14, 14, 14, 14, 14, 14, 14, 14, 14, 14,
     14, 14, 14, 14, 14, 14, 14, 14, 14, 14,
     14, 14, 14, 14, 14, 14, 14, 14, 14, 14,
     14, 14, 14, 14, 14, 14, 14, 14, 14, 14,
     14, 14, 14, 14, 14, 14, 14, 14, 14, 14,
     14, 14, 14, 14, 14, 14, 14, 14, 14, 14,
     14, 14, 14, 14, 14, 14, 14,  6,  5,  0,
      0,  0, 14, 14, 14, 14, 14,  8,  7, 14,
      6, 14,  0, 14,  0,  0, 14, 14, 14,  7,
     14,  0, 14, 14, 14, 14, 14, 14,
    };
  return len + hash_table[str[len - 1]] + hash_table[str[0]];
}

#ifdef __GNUC__
inline
#endif
const struct _SegAttr *
findSegAttr (register const char *str, register int len)
{

  static const struct _SegAttr  wordlist[] =
    {
      {"page",            ALIGNMENT,      255,},
      {"dword",           ALIGNMENT,      3,},
      {"public", 	        COMBINE,        SEG_PUBLIC,},
      {"private",         COMBINE,        SEG_PRIVATE,},
      {"resource",        COMBINE,        SEG_RESOURCE,},
      {"byte",            ALIGNMENT,      0,},
      {"para",            ALIGNMENT,      15,},
      {"word",            ALIGNMENT,      1,},
      {"common",          COMBINE,        SEG_COMMON,},
      {"stack",           COMBINE,        SEG_STACK,},
      {"library",         COMBINE,        SEG_LIBRARY,},
    };

  if (len <= MAX_WORD_LENGTH && len >= MIN_WORD_LENGTH)
    {
      register int key = hashSegAttr (str, len);

      if (key <= MAX_HASH_VALUE && key >= MIN_HASH_VALUE)
        {
          const struct _SegAttr  *resword; int key_len;

          switch (key)
            {
            case   4:
              resword = &wordlist[0]; key_len = 4; break;
            case   5:
              resword = &wordlist[1]; key_len = 5; break;
            case   6:
              resword = &wordlist[2]; key_len = 6; break;
            case   7:
              resword = &wordlist[3]; key_len = 7; break;
            case   8:
              resword = &wordlist[4]; key_len = 8; break;
            case   9:
              resword = &wordlist[5]; key_len = 4; break;
            case  10:
              resword = &wordlist[6]; key_len = 4; break;
            case  11:
              resword = &wordlist[7]; key_len = 4; break;
            case  12:
              resword = &wordlist[8]; key_len = 6; break;
            case  13:
              resword = &wordlist[9]; key_len = 5; break;
            case  14:
              resword = &wordlist[10]; key_len = 7; break;
            default: return 0;
            }
          if (len == key_len && *str == *resword->name && !strcmp (str + 1, resword->name + 1))
            return resword;
      }
  }
  return 0;
}
