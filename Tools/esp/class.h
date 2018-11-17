/* C code produced by gperf version 2.7.1 (19981006 egcs) */
/* Command-line: gperf -i8 -o -j1 -S 1 -DtlTC -N findClassToken -H hashClassToken class.gperf  */

#define TOTAL_KEYWORDS 15
#define MIN_WORD_LENGTH 5
#define MAX_WORD_LENGTH 8
#define MIN_HASH_VALUE 10
#define MAX_HASH_VALUE 30
/* maximum key range = 21, duplicates = 0 */

#ifdef __GNUC__
__inline
#endif
static unsigned int
hashClassToken (str, len)
     register const char *str;
     register unsigned int len;
{
  static const unsigned char asso_values[] =
    {
      31, 31, 31, 31, 31, 31, 31, 31, 31, 31,
      31, 31, 31, 31, 31, 31, 31, 31, 31, 31,
      31, 31, 31, 31, 31, 31, 31, 31, 31, 31,
      31, 31, 31, 31, 31, 31, 31, 31, 31, 31,
      31, 31, 31, 31, 31, 31, 31, 31, 31, 31,
      31, 31, 31, 31, 31, 31, 31, 31, 31, 31,
      31, 31, 31, 31, 31, 31, 31, 31, 31, 31,
      31, 31, 31, 31, 31, 31, 31, 31, 31, 31,
      31, 31, 31, 31, 31, 31, 31, 31, 31, 31,
      31, 31, 31, 31, 31, 31, 31,  8, 31,  8,
       2,  8, 31, 31, 31, 31, 31, 31, 31, 15,
      11, 31, 13, 31,  8,  0,  1, 31,  8, 31,
      31, 31, 31, 31, 31, 31, 31, 31, 31, 31,
      31, 31, 31, 31, 31, 31, 31, 31, 31, 31,
      31, 31, 31, 31, 31, 31, 31, 31, 31, 31,
      31, 31, 31, 31, 31, 31, 31, 31, 31, 31,
      31, 31, 31, 31, 31, 31, 31, 31, 31, 31,
      31, 31, 31, 31, 31, 31, 31, 31, 31, 31,
      31, 31, 31, 31, 31, 31, 31, 31, 31, 31,
      31, 31, 31, 31, 31, 31, 31, 31, 31, 31,
      31, 31, 31, 31, 31, 31, 31, 31, 31, 31,
      31, 31, 31, 31, 31, 31, 31, 31, 31, 31,
      31, 31, 31, 31, 31, 31, 31, 31, 31, 31,
      31, 31, 31, 31, 31, 31, 31, 31, 31, 31,
      31, 31, 31, 31, 31, 31, 31, 31, 31, 31,
      31, 31, 31, 31, 31, 31
    };
  return len + asso_values[(unsigned char)str[len - 1]] + asso_values[(unsigned char)str[0]];
}

#ifdef __GNUC__
__inline
#endif
const OpCode *
findClassToken (str, len)
     register const char *str;
     register unsigned int len;
{
  static const OpCode wordlist[] =
    {
      {"default",        DEFAULT,        0,},
      {"state",          STATE,          1,},
      {"static",         STATIC,         0,},
      {"export",         EXPORT,         0,},
      {"variant",        VARIANT,        0,},
      {"dynamic",        DYNAMIC,        0,},
      {"reloc",          RELOC,          0,},
      {"vardata",        VARDATA,        0,},
      {"endstate",       STATE,          0,},
      {"extern",         GLOBAL,         0,},
      {"noreloc",        NORELOC,        0,},
      {"public",         CPUBLIC,        0,},
      {"private",        PRIVATE,        0,},
      {"master",         MASTER,         0,},
      {"message",        METHOD,         0,}
    };

  if (len <= MAX_WORD_LENGTH && len >= MIN_WORD_LENGTH)
    {
      register int key = hashClassToken (str, len);

      if (key <= MAX_HASH_VALUE && key >= MIN_HASH_VALUE)
        {
          register const unsigned char *lengthptr;
          register const OpCode *wordptr;
          register const OpCode *wordendptr;
          register const OpCode *resword;

          switch (key - 10)
            {
              case 0:
                if (len == 7)
                  {
                    resword = &wordlist[0];
                    goto compare;
                  }
                break;
              case 3:
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
              case 5:
                if (len == 6)
                  {
                    resword = &wordlist[3];
                    goto compare;
                  }
                break;
              case 6:
                if (len == 7)
                  {
                    resword = &wordlist[4];
                    goto compare;
                  }
                break;
              case 7:
                if (len == 7)
                  {
                    resword = &wordlist[5];
                    goto compare;
                  }
                break;
              case 11:
                if (len == 5)
                  {
                    resword = &wordlist[6];
                    goto compare;
                  }
                break;
              case 13:
                if (len == 7)
                  {
                    resword = &wordlist[7];
                    goto compare;
                  }
                break;
              case 14:
                if (len == 8)
                  {
                    resword = &wordlist[8];
                    goto compare;
                  }
                break;
              case 15:
                if (len == 6)
                  {
                    resword = &wordlist[9];
                    goto compare;
                  }
                break;
              case 16:
                if (len == 7)
                  {
                    resword = &wordlist[10];
                    goto compare;
                  }
                break;
              case 17:
                if (len == 6)
                  {
                    resword = &wordlist[11];
                    goto compare;
                  }
                break;
              case 18:
                if (len == 7)
                  {
                    resword = &wordlist[12];
                    goto compare;
                  }
                break;
              case 19:
                if (len == 6)
                  {
                    resword = &wordlist[13];
                    goto compare;
                  }
                break;
              case 20:
                if (len == 7)
                  {
                    resword = &wordlist[14];
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
