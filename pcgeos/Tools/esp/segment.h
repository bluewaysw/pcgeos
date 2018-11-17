/* C code produced by gperf version 2.7.1 (19981006 egcs) */
/* Command-line: gperf -i16 -o -j1 -S 1 -DtlTC -N findSegToken -H hashSegToken segment.gperf  */

#define TOTAL_KEYWORDS 14
#define MIN_WORD_LENGTH 2
#define MAX_WORD_LENGTH 8
#define MIN_HASH_VALUE 4
#define MAX_HASH_VALUE 17
/* maximum key range = 14, duplicates = 0 */

#ifdef __GNUC__
__inline
#endif
static unsigned int
hashSegToken (str, len)
     register const char *str;
     register unsigned int len;
{
  static const unsigned char asso_values[] =
    {
      18, 18, 18, 18, 18, 18, 18, 18, 18, 18,
      18, 18, 18, 18, 18, 18, 18, 18, 18, 18,
      18, 18, 18, 18, 18, 18, 18, 18, 18, 18,
      18, 18, 18, 18, 18, 18, 18, 18, 18, 18,
      18, 18, 18, 18, 18, 18, 18, 18, 18, 18,
      18, 18, 18, 18, 18, 18, 18, 18, 18, 18,
      18, 18, 18, 18, 18, 18, 18, 18, 18, 18,
      18, 18, 18, 18, 18, 18, 18, 18, 18, 18,
      18, 18, 18, 18, 18, 18, 18, 18, 18, 18,
      18, 18, 18, 18, 18, 18, 18,  4,  6,  0,
       0,  0, 18,  3, 18, 18, 18, 12,  0, 10,
       6, 18,  0, 18,  1,  0,  9, 18, 18,  7,
      18,  6, 18, 18, 18, 18, 18, 18, 18, 18,
      18, 18, 18, 18, 18, 18, 18, 18, 18, 18,
      18, 18, 18, 18, 18, 18, 18, 18, 18, 18,
      18, 18, 18, 18, 18, 18, 18, 18, 18, 18,
      18, 18, 18, 18, 18, 18, 18, 18, 18, 18,
      18, 18, 18, 18, 18, 18, 18, 18, 18, 18,
      18, 18, 18, 18, 18, 18, 18, 18, 18, 18,
      18, 18, 18, 18, 18, 18, 18, 18, 18, 18,
      18, 18, 18, 18, 18, 18, 18, 18, 18, 18,
      18, 18, 18, 18, 18, 18, 18, 18, 18, 18,
      18, 18, 18, 18, 18, 18, 18, 18, 18, 18,
      18, 18, 18, 18, 18, 18, 18, 18, 18, 18,
      18, 18, 18, 18, 18, 18, 18, 18, 18, 18,
      18, 18, 18, 18, 18, 18
    };
  return len + asso_values[(unsigned char)str[len - 1]] + asso_values[(unsigned char)str[0]];
}

#ifdef __GNUC__
__inline
#endif
const OpCode *
findSegToken (str, len)
     register const char *str;
     register unsigned int len;
{
  static const OpCode wordlist[] =
    {
      {"page",           ALIGNMENT,      255,},
      {"dword",          ALIGNMENT,      3,},
      {"public",	        COMBINE,        SEG_PUBLIC,},
      {"private",        COMBINE,        SEG_PRIVATE,},
      {"para",           ALIGNMENT,      15,},
      {"resource",       COMBINE,        SEG_RESOURCE,},
      {"byte",           ALIGNMENT,      0,},
      {"word",           ALIGNMENT,      1,},
      {"common",         COMBINE,        SEG_COMMON,},
      {"library",        COMBINE,        SEG_LIBRARY,},
      {"lmem",           LMEM,           0,},
      {"at",             AT,             0,},
      {"nothing",        NOTHING,        0,},
      {"stack",          COMBINE,        SEG_STACK,}
    };

  if (len <= MAX_WORD_LENGTH && len >= MIN_WORD_LENGTH)
    {
      register int key = hashSegToken (str, len);

      if (key <= MAX_HASH_VALUE && key >= MIN_HASH_VALUE)
        {
          register const unsigned char *lengthptr;
          register const OpCode *wordptr;
          register const OpCode *wordendptr;
          register const OpCode *resword;

          switch (key - 4)
            {
              case 0:
                if (len == 4)
                  {
                    resword = &wordlist[0];
                    goto compare;
                  }
                break;
              case 1:
                if (len == 5)
                  {
                    resword = &wordlist[1];
                    goto compare;
                  }
                break;
              case 2:
                if (len == 6)
                  {
                    resword = &wordlist[2];
                    goto compare;
                  }
                break;
              case 3:
                if (len == 7)
                  {
                    resword = &wordlist[3];
                    goto compare;
                  }
                break;
              case 4:
                if (len == 4)
                  {
                    resword = &wordlist[4];
                    goto compare;
                  }
                break;
              case 5:
                if (len == 8)
                  {
                    resword = &wordlist[5];
                    goto compare;
                  }
                break;
              case 6:
                if (len == 4)
                  {
                    resword = &wordlist[6];
                    goto compare;
                  }
                break;
              case 7:
                if (len == 4)
                  {
                    resword = &wordlist[7];
                    goto compare;
                  }
                break;
              case 8:
                if (len == 6)
                  {
                    resword = &wordlist[8];
                    goto compare;
                  }
                break;
              case 9:
                if (len == 7)
                  {
                    resword = &wordlist[9];
                    goto compare;
                  }
                break;
              case 10:
                if (len == 4)
                  {
                    resword = &wordlist[10];
                    goto compare;
                  }
                break;
              case 11:
                if (len == 2)
                  {
                    resword = &wordlist[11];
                    goto compare;
                  }
                break;
              case 12:
                if (len == 7)
                  {
                    resword = &wordlist[12];
                    goto compare;
                  }
                break;
              case 13:
                if (len == 5)
                  {
                    resword = &wordlist[13];
                    goto compare;
                  }
                break;
            }
          return 0;
        multicompare:
          while (wordptr < wordendptr)
            {
              if (len == *lengthptr)
                {
                  register const char *s = wordptr->name;

                  if (*str == *s && !strcmp (str + 1, s + 1))
                    return wordptr;
                }
              lengthptr++;
              wordptr++;
            }
          return 0;
        compare:
          {
            register const char *s = resword->name;

            if (*str == *s && !strcmp (str + 1, s + 1))
              return resword;
          }
        }
    }
  return 0;
}
