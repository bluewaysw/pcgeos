/* C code produced by gperf version 2.7.1 (19981006 egcs) */
/* Command-line: gperf -i1 -o -j1 -S 1 -DtlTC -k* -N isDWordPart -H hashDWordPart dword.gperf  */

#define TOTAL_KEYWORDS 6
#define MIN_WORD_LENGTH 4
#define MAX_WORD_LENGTH 8
#define MIN_HASH_VALUE 8
#define MAX_HASH_VALUE 16
/* maximum key range = 9, duplicates = 0 */

#ifdef __GNUC__
__inline
#endif
static unsigned int
hashDWordPart (str, len)
     register const char *str;
     register unsigned int len;
{
  static const unsigned char asso_values[] =
    {
      17, 17, 17, 17, 17, 17, 17, 17, 17, 17,
      17, 17, 17, 17, 17, 17, 17, 17, 17, 17,
      17, 17, 17, 17, 17, 17, 17, 17, 17, 17,
      17, 17, 17, 17, 17, 17, 17, 17, 17, 17,
      17, 17, 17, 17, 17, 17,  1, 17, 17, 17,
      17, 17, 17, 17, 17, 17, 17, 17, 17, 17,
      17, 17, 17, 17, 17, 17, 17, 17, 17, 17,
      17, 17, 17, 17, 17, 17, 17, 17, 17, 17,
      17, 17, 17, 17, 17, 17, 17, 17, 17, 17,
      17, 17, 17, 17, 17, 17, 17,  2, 17,  1,
       1,  1,  1,  1,  1,  1, 17,  1,  1,  1,
       1,  1, 17, 17, 17,  1,  1,  1, 17,  1,
      17, 17, 17, 17, 17, 17, 17, 17, 17, 17,
      17, 17, 17, 17, 17, 17, 17, 17, 17, 17,
      17, 17, 17, 17, 17, 17, 17, 17, 17, 17,
      17, 17, 17, 17, 17, 17, 17, 17, 17, 17,
      17, 17, 17, 17, 17, 17, 17, 17, 17, 17,
      17, 17, 17, 17, 17, 17, 17, 17, 17, 17,
      17, 17, 17, 17, 17, 17, 17, 17, 17, 17,
      17, 17, 17, 17, 17, 17, 17, 17, 17, 17,
      17, 17, 17, 17, 17, 17, 17, 17, 17, 17,
      17, 17, 17, 17, 17, 17, 17, 17, 17, 17,
      17, 17, 17, 17, 17, 17, 17, 17, 17, 17,
      17, 17, 17, 17, 17, 17, 17, 17, 17, 17,
      17, 17, 17, 17, 17, 17, 17, 17, 17, 17,
      17, 17, 17, 17, 17, 17
    };
  register int hval = len;

  switch (hval)
    {
      default:
      case 8:
        hval += asso_values[(unsigned char)str[7]];
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
isDWordPart (str, len)
     register const char *str;
     register unsigned int len;
{
  static const OpCode wordlist[] =
    {
      {".low",           LOWPART,        0,},
      {".high",          HIGHPART,       0,},
      {".chunk",         OFFPART,        0,},
      {".offset",        OFFPART,        0,},
      {".handle",        SEGPART,        0,},
      {".segment",       SEGPART,        0,}
    };

  if (len <= MAX_WORD_LENGTH && len >= MIN_WORD_LENGTH)
    {
      register int key = hashDWordPart (str, len);

      if (key <= MAX_HASH_VALUE && key >= MIN_HASH_VALUE)
        {
          register const unsigned char *lengthptr;
          register const OpCode *wordptr;
          register const OpCode *wordendptr;
          register const OpCode *resword;

          switch (key - 8)
            {
              case 0:
                if (len == 4)
                  {
                    resword = &wordlist[0];
                    goto compare;
                  }
                break;
              case 2:
                if (len == 5)
                  {
                    resword = &wordlist[1];
                    goto compare;
                  }
                break;
              case 4:
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
                if (len == 7)
                  {
                    resword = &wordlist[4];
                    goto compare;
                  }
                break;
              case 8:
                if (len == 8)
                  {
                    resword = &wordlist[5];
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
