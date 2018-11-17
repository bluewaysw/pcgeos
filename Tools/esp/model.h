/* C code produced by gperf version 2.7.1 (19981006 egcs) */
/* Command-line: gperf -i16 -o -j1 -S 1 -DtlTC -k* -N findModelToken -H hashModelToken model.gperf  */

#define TOTAL_KEYWORDS 9
#define MIN_WORD_LENGTH 1
#define MAX_WORD_LENGTH 7
#define MIN_HASH_VALUE 1
#define MAX_HASH_VALUE 12
/* maximum key range = 12, duplicates = 0 */

#ifdef __GNUC__
__inline
#endif
static unsigned int
hashModelToken (str, len)
     register const char *str;
     register unsigned int len;
{
  static const unsigned char asso_values[] =
    {
      13, 13, 13, 13, 13, 13, 13, 13, 13, 13,
      13, 13, 13, 13, 13, 13, 13, 13, 13, 13,
      13, 13, 13, 13, 13, 13, 13, 13, 13, 13,
      13, 13, 13, 13, 13, 13, 13, 13, 13, 13,
      13, 13, 13, 13, 13, 13, 13, 13, 13, 13,
      13, 13, 13, 13, 13, 13, 13, 13, 13, 13,
      13, 13, 13, 13, 13, 13, 13, 13, 13, 13,
      13, 13, 13, 13, 13, 13, 13, 13, 13, 13,
      13, 13, 13, 13, 13, 13, 13, 13, 13, 13,
      13, 13, 13, 13, 13, 13, 13,  0,  5,  0,
       5,  0,  5,  4,  0,  0, 13, 13,  0,  0,
       0,  0,  0, 13,  0,  0,  0,  0, 13, 13,
      13, 13, 13, 13, 13, 13, 13, 13, 13, 13,
      13, 13, 13, 13, 13, 13, 13, 13, 13, 13,
      13, 13, 13, 13, 13, 13, 13, 13, 13, 13,
      13, 13, 13, 13, 13, 13, 13, 13, 13, 13,
      13, 13, 13, 13, 13, 13, 13, 13, 13, 13,
      13, 13, 13, 13, 13, 13, 13, 13, 13, 13,
      13, 13, 13, 13, 13, 13, 13, 13, 13, 13,
      13, 13, 13, 13, 13, 13, 13, 13, 13, 13,
      13, 13, 13, 13, 13, 13, 13, 13, 13, 13,
      13, 13, 13, 13, 13, 13, 13, 13, 13, 13,
      13, 13, 13, 13, 13, 13, 13, 13, 13, 13,
      13, 13, 13, 13, 13, 13, 13, 13, 13, 13,
      13, 13, 13, 13, 13, 13, 13, 13, 13, 13,
      13, 13, 13, 13, 13, 13
    };
  register int hval = len;

  switch (hval)
    {
      default:
      case 7:
        hval += asso_values[(unsigned char)str[6]];
      case 6:
        hval += asso_values[(unsigned char)str[5]];
      case 5:
        hval += asso_values[(unsigned char)str[4]];
      case 4:
        hval += asso_values[(unsigned char)str[3]];
      case 3:
        hval += asso_values[(unsigned char)str[2]];
      case 2:
        hval += asso_values[(unsigned char)str[1]];
      case 1:
        hval += asso_values[(unsigned char)str[0]];
        break;
    }
  return hval;
}

#ifdef __GNUC__
__inline
#endif
const OpCode *
findModelToken (str, len)
     register const char *str;
     register unsigned int len;
{
  static const OpCode wordlist[] =
    {
      {"c",		LANGUAGE,	LANG_C,},
      {"small",		MEMMODEL,	MM_SMALL,},
      {"pascal",		LANGUAGE,	LANG_PASCAL,},
      {"compact",	MEMMODEL,	MM_COMPACT,},
      {"huge",		MEMMODEL,	MM_HUGE,},
      {"large",		MEMMODEL,	MM_LARGE,},
      {"basic",		LANGUAGE,	LANG_BASIC,},
      {"medium",		MEMMODEL,	MM_MEDIUM,},
      {"fortran",	LANGUAGE,	LANG_FORTRAN,}
    };

  if (len <= MAX_WORD_LENGTH && len >= MIN_WORD_LENGTH)
    {
      register int key = hashModelToken (str, len);

      if (key <= MAX_HASH_VALUE && key >= MIN_HASH_VALUE)
        {
          register const unsigned char *lengthptr;
          register const OpCode *wordptr;
          register const OpCode *wordendptr;
          register const OpCode *resword;

          switch (key - 1)
            {
              case 0:
                if (len == 1)
                  {
                    resword = &wordlist[0];
                    goto compare;
                  }
                break;
              case 4:
                if (len == 5)
                  {
                    resword = &wordlist[1];
                    goto compare;
                  }
                break;
              case 5:
                if (len == 6)
                  {
                    resword = &wordlist[2];
                    goto compare;
                  }
                break;
              case 6:
                if (len == 7)
                  {
                    resword = &wordlist[3];
                    goto compare;
                  }
                break;
              case 7:
                if (len == 4)
                  {
                    resword = &wordlist[4];
                    goto compare;
                  }
                break;
              case 8:
                if (len == 5)
                  {
                    resword = &wordlist[5];
                    goto compare;
                  }
                break;
              case 9:
                if (len == 5)
                  {
                    resword = &wordlist[6];
                    goto compare;
                  }
                break;
              case 10:
                if (len == 6)
                  {
                    resword = &wordlist[7];
                    goto compare;
                  }
                break;
              case 11:
                if (len == 7)
                  {
                    resword = &wordlist[8];
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
