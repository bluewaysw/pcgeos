/* C code produced by gperf version 1.9 (K&R C version) */
/* Command-line: gperf -i1 -o -k1,2,$ -j1 -agSDptlC tokens.gperf  */


struct _ScanToken {
    char        *name;
    int         token;
};

#define MIN_WORD_LENGTH 3
#define MAX_WORD_LENGTH 8
#define MIN_HASH_VALUE 8
#define MAX_HASH_VALUE 49
/*
   36 keywords
   42 is the maximum key range
*/

#ifdef __GNUC__
inline
#endif
static int
hash (register const char *str, register int len)
{
  static const unsigned char hash_table[] =
    {
     49, 49, 49, 49, 49, 49, 49, 49, 49, 49,
     49, 49, 49, 49, 49, 49, 49, 49, 49, 49,
     49, 49, 49, 49, 49, 49, 49, 49, 49, 49,
     49, 49, 49, 49, 49, 49, 49, 49, 49, 49,
     49, 49, 49, 49, 49, 49, 49, 49, 49, 49,
     49, 49, 49, 49, 49, 49, 49, 49, 49, 49,
     49, 49, 49, 49, 49, 49, 49, 49, 49, 49,
     49, 49, 49, 49, 49, 49, 49, 49, 49, 49,
     49, 49, 49, 49, 49, 49, 49, 49, 49, 49,
     49, 49, 49, 49, 49,  1, 49,  7,  5, 20,
      1,  1,  8,  4,  7, 21, 49, 49, 21, 22,
     16, 19,  5, 49,  1,  2,  1,  8, 10,  1,
     49, 11, 49, 49, 49, 49, 49, 49,
  };
  return len + hash_table[str[1]] + hash_table[str[0]] + hash_table[str[len - 1]];
}

#ifdef __GNUC__
inline
#endif
const struct _ScanToken *
in_word_set (register const char *str, register int len)
{

  static const struct _ScanToken  wordlist[] =
    {
      {"dword",           DWORD,},
      {"sword",           SWORD,},
      {"sdword",          SDWORD,},
      {"_seg",            DA_SEG,},
      {"sptr",            SPTR,},
      {"sbyte",           SBYTE,},
      {"_far",            DA_FAR,},
      {"short",           SHORT,},
      {"_handle",         DA_HANDLE,},
      {"hptr",            HPTR,},
      {"fptr",            FPTR,},
      {"far",             DA_FAR,},
      {"vptr",            VPTR,},
      {"byte",            BYTE,},
      {"near",            DA_NEAR,},
      {"_near",           DA_NEAR,},
      {"vfptr",           VFPTR,},
      {"word",            WORD,},
      {"nptr",            NPTR,},
      {"double",          DOUBLE,},
      {"_object",         DA_OBJECT,},
      {"optr",            OPTR,},
      {"signed",          SIGNED,},
      {"lptr",            LPTR,},
      {"char",            CHAR,},
      {"unsigned",        UNSIGNED,},
      {"void",            VOID,},
      {"float",           FLOAT,},
      {"_vm",             DA_VM,},
      {"sizeof",          SIZEOF,},
      {"volatile",        VOLATILE,},
      {"_virtual",        DA_VIRTUAL,},
      {"int",             INT,},
      {"const",           CONST,},
      {"long",            LONG,},
      {"_lmem",           DA_LMEM,},
    };

  if (len <= MAX_WORD_LENGTH && len >= MIN_WORD_LENGTH)
    {
      register int key = hash (str, len);

      if (key <= MAX_HASH_VALUE && key >= MIN_HASH_VALUE)
        {
          const struct _ScanToken  *resword; int key_len;

          switch (key)
            {
            case   8:
              resword = &wordlist[0]; key_len = 5; break;
            case   9:
              resword = &wordlist[1]; key_len = 5; break;
            case  10:
              resword = &wordlist[2]; key_len = 6; break;
            case  11:
              resword = &wordlist[3]; key_len = 4; break;
            case  12:
              resword = &wordlist[4]; key_len = 4; break;
            case  13:
              resword = &wordlist[5]; key_len = 5; break;
            case  14:
              resword = &wordlist[6]; key_len = 4; break;
            case  15:
              resword = &wordlist[7]; key_len = 5; break;
            case  16:
              resword = &wordlist[8]; key_len = 7; break;
            case  17:
              resword = &wordlist[9]; key_len = 4; break;
            case  18:
              resword = &wordlist[10]; key_len = 4; break;
            case  19:
              resword = &wordlist[11]; key_len = 3; break;
            case  20:
              resword = &wordlist[12]; key_len = 4; break;
            case  21:
              resword = &wordlist[13]; key_len = 4; break;
            case  22:
              resword = &wordlist[14]; key_len = 4; break;
            case  23:
              resword = &wordlist[15]; key_len = 5; break;
            case  24:
              resword = &wordlist[16]; key_len = 5; break;
            case  25:
              resword = &wordlist[17]; key_len = 4; break;
            case  26:
              resword = &wordlist[18]; key_len = 4; break;
            case  27:
              resword = &wordlist[19]; key_len = 6; break;
            case  28:
              resword = &wordlist[20]; key_len = 7; break;
            case  29:
              resword = &wordlist[21]; key_len = 4; break;
            case  30:
              resword = &wordlist[22]; key_len = 6; break;
            case  31:
              resword = &wordlist[23]; key_len = 4; break;
            case  32:
              resword = &wordlist[24]; key_len = 4; break;
            case  33:
              resword = &wordlist[25]; key_len = 8; break;
            case  34:
              resword = &wordlist[26]; key_len = 4; break;
            case  35:
              resword = &wordlist[27]; key_len = 5; break;
            case  36:
              resword = &wordlist[28]; key_len = 3; break;
            case  37:
              resword = &wordlist[29]; key_len = 6; break;
            case  38:
              resword = &wordlist[30]; key_len = 8; break;
            case  40:
              resword = &wordlist[31]; key_len = 8; break;
            case  41:
              resword = &wordlist[32]; key_len = 3; break;
            case  45:
              resword = &wordlist[33]; key_len = 5; break;
            case  48:
              resword = &wordlist[34]; key_len = 4; break;
            case  49:
              resword = &wordlist[35]; key_len = 5; break;
            default: return 0;
            }
          if (len == key_len && *str == *resword->name && !strcmp (str + 1, resword->name + 1))
            return resword;
      }
  }
  return 0;
}
