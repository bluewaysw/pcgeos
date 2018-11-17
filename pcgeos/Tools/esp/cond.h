/* C code produced by gperf version 2.7.1 (19981006 egcs) */
/* Command-line: gperf -i1 -o -j1 -S 1 -DtlTC -k* -N findCondToken -H hashCondToken cond.gperf  */

#define TOTAL_KEYWORDS 33
#define MIN_WORD_LENGTH 2
#define MAX_WORD_LENGTH 10
#define MIN_HASH_VALUE 5
#define MAX_HASH_VALUE 50
/* maximum key range = 46, duplicates = 0 */

#ifdef __GNUC__
__inline
#endif
static unsigned int
hashCondToken (str, len)
     register const char *str;
     register unsigned int len;
{
  static const unsigned char asso_values[] =
    {
      51, 51, 51, 51, 51, 51, 51, 51, 51, 51,
      51, 51, 51, 51, 51, 51, 51, 51, 51, 51,
      51, 51, 51, 51, 51, 51, 51, 51, 51, 51,
      51, 51, 51, 51, 51, 51, 51, 51, 51, 51,
      51, 51, 51, 51, 51, 51, 51, 51, 51, 26,
      29, 51, 51, 51, 51, 51, 51, 51, 51, 51,
      51, 51, 51, 51, 51, 51, 51, 51, 51, 51,
      51, 51, 51, 51, 51, 51, 51, 51, 51, 51,
      51, 51, 51, 51, 51, 51, 51, 51, 51, 51,
      51, 51, 51, 51, 51, 51, 51, 51, 13, 13,
       3,  1,  1, 51, 51,  2, 51, 51,  1,  1,
      13,  1, 51, 51, 51,  8,  1, 51, 51, 51,
      51, 51, 51, 51, 51, 51, 51, 51, 51, 51,
      51, 51, 51, 51, 51, 51, 51, 51, 51, 51,
      51, 51, 51, 51, 51, 51, 51, 51, 51, 51,
      51, 51, 51, 51, 51, 51, 51, 51, 51, 51,
      51, 51, 51, 51, 51, 51, 51, 51, 51, 51,
      51, 51, 51, 51, 51, 51, 51, 51, 51, 51,
      51, 51, 51, 51, 51, 51, 51, 51, 51, 51,
      51, 51, 51, 51, 51, 51, 51, 51, 51, 51,
      51, 51, 51, 51, 51, 51, 51, 51, 51, 51,
      51, 51, 51, 51, 51, 51, 51, 51, 51, 51,
      51, 51, 51, 51, 51, 51, 51, 51, 51, 51,
      51, 51, 51, 51, 51, 51, 51, 51, 51, 51,
      51, 51, 51, 51, 51, 51, 51, 51, 51, 51,
      51, 51, 51, 51, 51, 51
    };
  register int hval = len;

  switch (hval)
    {
      default:
      case 10:
        hval += asso_values[(unsigned char)str[9]];
      case 9:
        hval += asso_values[(unsigned char)str[8]];
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
findCondToken (str, len)
     register const char *str;
     register unsigned int len;
{
  static const OpCode wordlist[] =
    {
      {"if",         IF,         0,},
      {"ife",        IFE,        0,},
      {"elif",       IF,         1,},
      {"elife",      IFE,        1,},
      {"ifdef",      IFDEF,      0,},
      {"ifdif",      IFDIF,      0,},
      {"else",       ELSE,       0,},
      {"elifdef",    IFDEF,      1,},
      {"elifdif",    IFDIF,      1,},
      {"ifb",        IFB,        0,},
      {"elseif",     IF,         1,},
      {"elseife",    IFE,        1,},
      {"elifb",      IFB,        1,},
      {"endif",      ENDIF,      0,},
      {"ifidn",      IFIDN,      0,},
      {"ifndef",     IFNDEF,     0,},
      {"elseifdef",  IFDEF,      1,},
      {"elseifdif",  IFDIF,      1,},
      {"elifidn",    IFIDN,      1,},
      {"elifndef",   IFNDEF,     1,},
      {"if1",        IF1,        0,},
      {"ifnb",       IFNB,       0,},
      {"elseifb",    IFB,        1,},
      {"if2",        IF2,        0,},
      {"elif1",      IF1,        1,},
      {"elifnb",     IFNB,       1,},
      {"comment",    COMMENT,	0,},
      {"elif2",      IF2,        1,},
      {"elseifidn",  IFIDN,      1,},
      {"elseifndef", IFNDEF,     1,},
      {"elseif1",    IF1,        1,},
      {"elseifnb",   IFNB,       1,},
      {"elseif2",    IF2,        1,}
    };

  if (len <= MAX_WORD_LENGTH && len >= MIN_WORD_LENGTH)
    {
      register int key = hashCondToken (str, len);

      if (key <= MAX_HASH_VALUE && key >= MIN_HASH_VALUE)
        {
          register const unsigned char *lengthptr;
          register const OpCode *wordptr;
          register const OpCode *wordendptr;
          register const OpCode *resword;

          switch (key - 5)
            {
              case 0:
                if (len == 2)
                  {
                    resword = &wordlist[0];
                    goto compare;
                  }
                break;
              case 2:
                if (len == 3)
                  {
                    resword = &wordlist[1];
                    goto compare;
                  }
                break;
              case 4:
                if (len == 4)
                  {
                    resword = &wordlist[2];
                    goto compare;
                  }
                break;
              case 6:
                if (len == 5)
                  {
                    resword = &wordlist[3];
                    goto compare;
                  }
                break;
              case 8:
                if (len == 5)
                  {
                    resword = &wordlist[4];
                    goto compare;
                  }
                break;
              case 9:
                if (len == 5)
                  {
                    resword = &wordlist[5];
                    goto compare;
                  }
                break;
              case 10:
                if (len == 4)
                  {
                    resword = &wordlist[6];
                    goto compare;
                  }
                break;
              case 12:
                if (len == 7)
                  {
                    resword = &wordlist[7];
                    goto compare;
                  }
                break;
              case 13:
                if (len == 7)
                  {
                    resword = &wordlist[8];
                    goto compare;
                  }
                break;
              case 14:
                if (len == 3)
                  {
                    resword = &wordlist[9];
                    goto compare;
                  }
                break;
              case 15:
                if (len == 6)
                  {
                    resword = &wordlist[10];
                    goto compare;
                  }
                break;
              case 17:
                if (len == 7)
                  {
                    resword = &wordlist[11];
                    goto compare;
                  }
                break;
              case 18:
                if (len == 5)
                  {
                    resword = &wordlist[12];
                    goto compare;
                  }
                break;
              case 20:
                if (len == 5)
                  {
                    resword = &wordlist[13];
                    goto compare;
                  }
                break;
              case 21:
                if (len == 5)
                  {
                    resword = &wordlist[14];
                    goto compare;
                  }
                break;
              case 22:
                if (len == 6)
                  {
                    resword = &wordlist[15];
                    goto compare;
                  }
                break;
              case 23:
                if (len == 9)
                  {
                    resword = &wordlist[16];
                    goto compare;
                  }
                break;
              case 24:
                if (len == 9)
                  {
                    resword = &wordlist[17];
                    goto compare;
                  }
                break;
              case 25:
                if (len == 7)
                  {
                    resword = &wordlist[18];
                    goto compare;
                  }
                break;
              case 26:
                if (len == 8)
                  {
                    resword = &wordlist[19];
                    goto compare;
                  }
                break;
              case 27:
                if (len == 3)
                  {
                    resword = &wordlist[20];
                    goto compare;
                  }
                break;
              case 28:
                if (len == 4)
                  {
                    resword = &wordlist[21];
                    goto compare;
                  }
                break;
              case 29:
                if (len == 7)
                  {
                    resword = &wordlist[22];
                    goto compare;
                  }
                break;
              case 30:
                if (len == 3)
                  {
                    resword = &wordlist[23];
                    goto compare;
                  }
                break;
              case 31:
                if (len == 5)
                  {
                    resword = &wordlist[24];
                    goto compare;
                  }
                break;
              case 32:
                if (len == 6)
                  {
                    resword = &wordlist[25];
                    goto compare;
                  }
                break;
              case 33:
                if (len == 7)
                  {
                    resword = &wordlist[26];
                    goto compare;
                  }
                break;
              case 34:
                if (len == 5)
                  {
                    resword = &wordlist[27];
                    goto compare;
                  }
                break;
              case 36:
                if (len == 9)
                  {
                    resword = &wordlist[28];
                    goto compare;
                  }
                break;
              case 37:
                if (len == 10)
                  {
                    resword = &wordlist[29];
                    goto compare;
                  }
                break;
              case 42:
                if (len == 7)
                  {
                    resword = &wordlist[30];
                    goto compare;
                  }
                break;
              case 43:
                if (len == 8)
                  {
                    resword = &wordlist[31];
                    goto compare;
                  }
                break;
              case 45:
                if (len == 7)
                  {
                    resword = &wordlist[32];
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
