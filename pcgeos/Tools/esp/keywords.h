/* C code produced by gperf version 2.7.1 (19981006 egcs) */
/* Command-line: gperf -i1 -o -j1 -S 1 -DtlTC -k1-4,6,8,$ -N findKeyword -H hashKeyword keywords.gperf  */

#define TOTAL_KEYWORDS 214
#define MIN_WORD_LENGTH 1
#define MAX_WORD_LENGTH 10
#define MIN_HASH_VALUE 3
#define MAX_HASH_VALUE 496
/* maximum key range = 494, duplicates = 1 */

#ifdef __GNUC__
__inline
#endif
static unsigned int
hashKeyword (str, len)
     register const char *str;
     register unsigned int len;
{
  static const unsigned short asso_values[] =
    {
      497, 497, 497, 497, 497, 497, 497, 497, 497, 497,
      497, 497, 497, 497, 497, 497, 497, 497, 497, 497,
      497, 497, 497, 497, 497, 497, 497, 497, 497, 497,
      497, 497, 497, 497, 497, 497,   2, 497, 497, 497,
      497, 497, 497, 497, 497, 497,  51, 497,   9,  30,
       44,  12, 497, 497,   1,   2,   1, 497, 497, 497,
      497, 497, 497,   1, 497, 497, 497, 497, 497, 497,
      497, 497, 497, 497, 497, 497, 497, 497, 497, 497,
      497, 497, 497, 497, 497, 497, 497, 497, 497, 497,
      497, 497, 497, 497, 497,   1, 497, 135, 103,  38,
        3,   1,   4,  94,  69,  29, 497,  61,   8,  99,
       85,  24, 180,   5,   1,   2,  51,  90,  86,  81,
      150,  59,  12, 497, 497, 497, 497, 497, 497, 497,
      497, 497, 497, 497, 497, 497, 497, 497, 497, 497,
      497, 497, 497, 497, 497, 497, 497, 497, 497, 497,
      497, 497, 497, 497, 497, 497, 497, 497, 497, 497,
      497, 497, 497, 497, 497, 497, 497, 497, 497, 497,
      497, 497, 497, 497, 497, 497, 497, 497, 497, 497,
      497, 497, 497, 497, 497, 497, 497, 497, 497, 497,
      497, 497, 497, 497, 497, 497, 497, 497, 497, 497,
      497, 497, 497, 497, 497, 497, 497, 497, 497, 497,
      497, 497, 497, 497, 497, 497, 497, 497, 497, 497,
      497, 497, 497, 497, 497, 497, 497, 497, 497, 497,
      497, 497, 497, 497, 497, 497, 497, 497, 497, 497,
      497, 497, 497, 497, 497, 497, 497, 497, 497, 497,
      497, 497, 497, 497, 497, 497
    };
  register int hval = len;

  switch (hval)
    {
      default:
      case 8:
        hval += asso_values[(unsigned char)str[7]];
      case 7:
      case 6:
        hval += asso_values[(unsigned char)str[5]];
      case 5:
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
  return hval + asso_values[(unsigned char)str[len - 1]];
}

#ifdef __GNUC__
__inline
#endif
const OpCode *
findKeyword (str, len)
     register const char *str;
     register unsigned int len;
{
  static const unsigned char lengthtable[] =
    {
       1,  1,  2,  2,  2,  2,  2,  2,  2,  3,  2,  4,  2,  7,
       6,  9, 10,  3,  2,  5,  2,  5,  5,  4,  4,  7,  7,  2,
       9,  4,  5,  8,  2,  2,  3,  3,  7,  7,  5,  5,  4,  4,
       8,  5,  6,  5,  2,  7,  6,  4,  2,  5,  5,  7,  3,  3,
       4,  2,  2,  4,  4,  7,  4,  2,  2,  2,  9,  5,  4,  5,
       5,  2,  6,  3,  7,  5,  3,  6,  7,  5,  6,  2,  3,  5,
       7,  5,  5,  2,  5,  4,  5,  2,  4,  3,  7,  5,  2,  5,
       3,  5,  3,  6,  3,  2,  6,  6,  6,  8,  2,  3,  5,  3,
       5,  4,  5,  5,  4,  8,  6,  6,  3,  6,  5,  4,  5,  4,
       3,  2,  8,  4,  4,  7,  5,  6,  6,  6,  9,  5,  4,  4,
       7,  6,  6,  5,  7,  2,  5,  4,  5,  6,  4,  4,  4,  4,
       5,  8,  4,  5,  6,  5,  2,  4,  3,  5, 10,  6,  4,  4,
       4,  5,  4,  5,  6,  4,  5,  9,  7,  2,  3,  7,  5,  5,
       6,  6,  5,  5,  4,  2,  3,  7, 10,  5,  8,  4,  5,  8,
       3,  5,  7,  2,  3,  4,  9,  2,  3, 10, 10,  4,  3,  8,
       6,  2,  3,  6
    };
  static const OpCode wordlist[] =
    {
      {"?",          UNDEF,      0,},
      {"$",          DOT,        0,},
      {"es",         SEGREG,     REG_ES,},
      {"ss",         SEGREG,     REG_SS,},
      {"ds",         SEGREG,     REG_DS,},
      {"fs",         SEGREG,     REG_FS,},
      {"dd",         DEF,        4,},
      {"le",         LE,         0,},
      {"eq",         EQ,         0,},
      {"dsd",        DEF,        -4,},
      {"dq",         DEF,        8,},
      {"else",       ELSE,       0,},
      {"dl",         BYTEREG,    REG_DL,},
      {"elseife",    IFE,        1,},
      {"elseif",     IF,         1,},
      {"elseifdef",  IFDEF,      1,},
      {"elseifndef", IFNDEF,     1,},
      {"ife",        IFE,        0,},
      {"if",         IF,         0,},
      {"resid",      RESID,      0,},
      {"cs",         SEGREG,     REG_CS,},
      {"ifdef",      IFDEF,      0,},
      {"elife",      IFE,        1,},
      {"size",       SIZE,       0,},
      {"elif",       IF,         1,},
      {"elseif1",    IF1,        1,},
      {"elifdef",    IFDEF,      1,},
      {"cl",         BYTEREG,    REG_CL,},
      {"elseifdif",  IFDIF,      1,},
      {".err",       ERR,        0,},
      {".erre",      ERRE,       0,},
      {"elifndef",   IFNDEF,     1,},
      {"si",         WORDREG,    REG_SI,},
      {"di",         WORDREG,    REG_DI,},
      {"esi",        DWORDREG,   REG_ESI,},
      {"edi",        DWORDREG,   REG_EDI,},
      {".errdef",    ERRDEF,     0,},
      {"elseif2",    IF2,        1,},
      {".8086",      PROCESSOR,  PROC_8086,},
      {".8087",      COPROCESSOR,PROC_8087,},
      {".386",       PROCESSOR,  PROC_80386|PROC_80286|PROC_80186|PROC_8086,},
      {".387",       COPROCESSOR,PROC_80387,},
      {".errndef",   ERRNDEF,    0,},
      {"ifdif",      IFDIF,      0,},
      {"record",     RECORD,     0,},
      {"elif1",      IF1,        1,},
      {"dc",         DEF,        0,      /* Special case */},
      {"elifdif",    IFDIF,      1,},
      {".errnz",     ERRNZ,      0,},
      {".186",       PROCESSOR,  PROC_80186|PROC_8086,},
      {"ne",         NE,         0,},
      {"elif2",      IF2,        1,},
      {"first",      FIRST,      0,},
      {".errdif",    ERRDIF,     0,},
      {"end",        END,        0,},
      {"if1",        IF1,        0,},
      {"ends",       ENDS,       0,},
      {"ge",         GE,         0,},
      {"gs",         SEGREG,     REG_GS,},
      {"uses",       USES,       0,},
      {".286",       PROCESSOR,  PROC_80286|PROC_80186|PROC_8086,},
      {"sizestr",    SIZESTR,    0,},
      {".287",       COPROCESSOR,PROC_80287,},
      {"st",         ST,         0,},
      {"dt",         DEF,        10,},
      {"lt",         LT,         0,},
      {"elseifidn",  IFIDN,      1,},
      {"sword",      CAST,       -2,},
      {"word",       CAST,       2,},
      {"dword",      CAST,       4,},
      {"qword",      CAST,       8,},
      {"bl",         BYTEREG,    REG_BL,},
      {"sdword",     CAST,       -4,},
      {"if2",        IF2,        0,},
      {"elseifb",    IFB,        1,},
      {"endif",      ENDIF,      0,},
      {"mod",        MOD,        0,},
      {"ifndef",     IFNDEF,     0,},
      {"elifidn",    IFIDN,      1,},
      {".286c",      PROCESSOR,  PROC_80286|PROC_80186|PROC_8086,},
      {"offset",     OFFSET,     0,},
      {"dh",         BYTEREG,    REG_DH,},
      {"far",        FAR,        0,},
      {"title",      OPCODE,     0,},
      {".erridn",    ERRIDN,     0,},
      {"elifb",      IFB,        1,},
      {"short",      SHORT,      0,},
      {"al",         BYTEREG,    REG_AL,},
      {"ifidn",      IFIDN,      0,},
      {"this",       THIS,       0,},
      {".errb",      ERRB,       0,},
      {"dw",         DEF,        2,},
      {"endc",       ENDC,       0,},
      {"dsw",        DEF,        -2,},
      {"include",    INCLUDE,    0,},
      {"instr",      INSTR,      0,},
      {"ch",         BYTEREG,    REG_CH,},
      {"struc",      STRUC,      0,},
      {"equ",        EQU,        0,},
      {"class",      CLASS,      0,},
      {"seg",        SEG,        0,},
      {".enter",     DOTENTER,   0,},
      {"low",        LOW,        0,},
      {"gt",         GT,         0,},
      {".model",     MODEL,      0,},
      {".leave",     DOTLEAVE,   0,},
      {"substr",     SUBSTR,     0,},
      {"segregof",   SEGREGOF,   0,},
      {"db",         DEF,        1,},
      {"dsb",        DEF,        -1,},
      {".lall",      OPCODE,     0,},
      {"org",        ORG,        0,},
      {"local",      LOCAL,      0,},
      {"byte",       CAST,       1,},
      {"sbyte",      CAST,       -1,},
      {".inst",      INST,       0,},
      {"near",       NEAR,       0,},
      {"elseifnb",   IFNB,       1,},
      {"method",     METHOD,     0,},
      {"catstr",     CATSTR,     0,},
      {"ptr",        PTR,        0,},
      {"assume",     ASSUME,     0,},
      {"width",      WIDTH,      0,},
      {"sptr",       PNTR,       's',},
      {"exitf",      EXITF,      0,},
      {"fptr",       PNTR,       'f',},
      {"ifb",        IFB,        0,},
      {"bh",         BYTEREG,    REG_BH,},
      {"localize",   LOCALIZE,   0,},
      {"lptr",       PNTR,       'l',},
      {"char",       CAST,       0,      /* Special case */},
      {".assert",    ASSERT,     0,},
      {".386p",      PROCESSOR,  PROC_80386|PROC_PROT|PROC_80286|PROC_80186|PROC_8086,},
      {"global",     GLOBAL,     0,},
      {"struct",     STRUC,      0,},
      {"elifnb",     IFNB,       1,},
      {".ioenable",  IOENABLE,   0,},
      {"label",      LABEL,      0,},
      {"optr",       PNTR,       'o',},
      {"even",       EVEN,       0,},
      {".rcheck",    READCHECK,0,},
      {".errnb",     ERRNB,      0,},
      {"subttl",     OPCODE,     0,},
      {"tbyte",      CAST,       10,},
      {"inherit",    INHERIT,    0,},
      {"ah",         BYTEREG,    REG_AH,},
      {"super",      SUPER,      0,},
      {"vseg",       VSEG,       0,},
      {".286p",      PROCESSOR,  PROC_PROT|PROC_80286|PROC_80186|PROC_8086,},
      {".break",     BREAK,      0,},
      {"proc",       PROC,       0,},
      {"rept",       REPT,       0,},
      {"irpc",       IRPC,       0,},
      {"endm",       ENDM,       0,},
      {"extrn",      GLOBAL,     0,},
      {"vsegment",   VSEG,       0,},
      {"type",       TYPE,       0,},
      {"etype",      DEFETYPE,   0,},
      {"handle",     HANDLE,     0,},
      {"macro",      MACRO,      0,},
      {"dx",         WORDREG,    REG_DX,},
      {"hptr",       PNTR,       'h',},
      {"edx",        DWORDREG,   REG_EDX,},
      {"union",      UNION,      0,},
      {"protoreset", PROTORESET, 0,},
      {"static",     STATIC,     0,},
      {"nptr",       PNTR,       'n',},
      {"vptr",       PNTR,       'v',},
      {"name",       OPCODE,     0,},
      {"vfptr",      PNTR,       'F',},
      {"ifnb",       IFNB,       0,},
      {"wchar",      CAST,       'z',      /* Special case */},
      {"length",     LENGTH,     0,},
      {"high",       HIGH,       0,},
      {"exitm",      EXITM,      0,},
      {".norcheck",  NOREADCHECK,0,},
      {"segment",    SEGMENT,    0,},
      {"cx",         WORDREG,    REG_CX,},
      {"ecx",        DWORDREG,   REG_ECX,},
      {".wcheck",    WRITECHECK,0,},
      {".type",      DOTTYPE,    0,},
      {"chunk",      CHUNK,      0,},
      {".showm",     SHOWM,      1,},
      {".debug",     DEBUG,      1,},
      {"align",      ALIGN,      0,},
      {".warn",      WARN,       0,},
      {"mask",       MASK,       0,},
      {"sp",         WORDREG,    REG_SP,},
      {"esp",        DWORDREG,   REG_ESP,},
      {".nomasm",    MASM,       0,},
      {".fall_thru", FALLTHRU,   0,},
      {"purge",      OPCODE,     0,},
      {"on_stack",   ON_STACK,   0,},
      {"enum",       ENUM,       0,},
      {".masm",      MASM,       1,},
      {".noshowm",   SHOWM,      0,},
      {"irp",        IRP,        0,},
      {"group",      GROUP,      0,},
      {"comment",    COMMENT,    0,},
      {"bx",         WORDREG,    REG_BX,},
      {"ebx",        DWORDREG,   REG_EBX,},
      {"page",       OPCODE,     0,},
      {".nowcheck",  NOWRITECHECK,0,},
      {"ax",         WORDREG,    REG_AX,},
      {"eax",        DWORDREG,   REG_EAX,},
      {".unreached", UNREACHED,  0,},
      {"protominor", PROTOMINOR, 0,},
      {"endp",       ENDP,       0,},
      {"dup",        DUP,        0,},
      {".nodebug",   DEBUG,      0,},
      {"public",     PUBLIC,     0,},
      {"bp",         WORDREG,    REG_BP,},
      {"ebp",        DWORDREG,   REG_EBP,},
      {".radix",     OPCODE,     0,}
    };

  if (len <= MAX_WORD_LENGTH && len >= MIN_WORD_LENGTH)
    {
      register int key = hashKeyword (str, len);

      if (key <= MAX_HASH_VALUE && key >= MIN_HASH_VALUE)
        {
          register const unsigned char *lengthptr;
          register const OpCode *wordptr;
          register const OpCode *wordendptr;
          register const OpCode *resword;

          switch (key - 3)
            {
              case 0:
                if (len == 1)
                  {
                    resword = &wordlist[0];
                    goto compare;
                  }
                break;
              case 2:
                if (len == 1)
                  {
                    resword = &wordlist[1];
                    goto compare;
                  }
                break;
              case 4:
                if (len == 2)
                  {
                    resword = &wordlist[2];
                    goto compare;
                  }
                break;
              case 5:
                if (len == 2)
                  {
                    resword = &wordlist[3];
                    goto compare;
                  }
                break;
              case 6:
                if (len == 2)
                  {
                    resword = &wordlist[4];
                    goto compare;
                  }
                break;
              case 7:
                if (len == 2)
                  {
                    resword = &wordlist[5];
                    goto compare;
                  }
                break;
              case 8:
                if (len == 2)
                  {
                    resword = &wordlist[6];
                    goto compare;
                  }
                break;
              case 9:
                if (len == 2)
                  {
                    resword = &wordlist[7];
                    goto compare;
                  }
                break;
              case 10:
                if (len == 2)
                  {
                    resword = &wordlist[8];
                    goto compare;
                  }
                break;
              case 11:
                if (len == 3)
                  {
                    resword = &wordlist[9];
                    goto compare;
                  }
                break;
              case 12:
                if (len == 2)
                  {
                    resword = &wordlist[10];
                    goto compare;
                  }
                break;
              case 14:
                if (len == 4)
                  {
                    resword = &wordlist[11];
                    goto compare;
                  }
                break;
              case 18:
                if (len == 2)
                  {
                    resword = &wordlist[12];
                    goto compare;
                  }
                break;
              case 21:
                if (len == 7)
                  {
                    resword = &wordlist[13];
                    goto compare;
                  }
                break;
              case 23:
                if (len == 6)
                  {
                    resword = &wordlist[14];
                    goto compare;
                  }
                break;
              case 27:
                if (len == 9)
                  {
                    resword = &wordlist[15];
                    goto compare;
                  }
                break;
              case 30:
                if (len == 10)
                  {
                    resword = &wordlist[16];
                    goto compare;
                  }
                break;
              case 35:
                if (len == 3)
                  {
                    resword = &wordlist[17];
                    goto compare;
                  }
                break;
              case 36:
                if (len == 2)
                  {
                    resword = &wordlist[18];
                    goto compare;
                  }
                break;
              case 38:
                if (len == 5)
                  {
                    resword = &wordlist[19];
                    goto compare;
                  }
                break;
              case 41:
                if (len == 2)
                  {
                    resword = &wordlist[20];
                    goto compare;
                  }
                break;
              case 43:
                if (len == 5)
                  {
                    resword = &wordlist[21];
                    goto compare;
                  }
                break;
              case 45:
                if (len == 5)
                  {
                    resword = &wordlist[22];
                    goto compare;
                  }
                break;
              case 46:
                if (len == 4)
                  {
                    resword = &wordlist[23];
                    goto compare;
                  }
                break;
              case 47:
                if (len == 4)
                  {
                    resword = &wordlist[24];
                    goto compare;
                  }
                break;
              case 50:
                if (len == 7)
                  {
                    resword = &wordlist[25];
                    goto compare;
                  }
                break;
              case 51:
                if (len == 7)
                  {
                    resword = &wordlist[26];
                    goto compare;
                  }
                break;
              case 53:
                if (len == 2)
                  {
                    resword = &wordlist[27];
                    goto compare;
                  }
                break;
              case 55:
                if (len == 9)
                  {
                    resword = &wordlist[28];
                    goto compare;
                  }
                break;
              case 56:
                if (len == 4)
                  {
                    resword = &wordlist[29];
                    goto compare;
                  }
                break;
              case 57:
                if (len == 5)
                  {
                    resword = &wordlist[30];
                    goto compare;
                  }
                break;
              case 58:
                if (len == 8)
                  {
                    resword = &wordlist[31];
                    goto compare;
                  }
                break;
              case 59:
                if (len == 2)
                  {
                    resword = &wordlist[32];
                    goto compare;
                  }
                break;
              case 60:
                if (len == 2)
                  {
                    resword = &wordlist[33];
                    goto compare;
                  }
                break;
              case 61:
                if (len == 3)
                  {
                    resword = &wordlist[34];
                    goto compare;
                  }
                break;
              case 62:
                if (len == 3)
                  {
                    resword = &wordlist[35];
                    goto compare;
                  }
                break;
              case 63:
                if (len == 7)
                  {
                    resword = &wordlist[36];
                    goto compare;
                  }
                break;
              case 64:
                if (len == 7)
                  {
                    resword = &wordlist[37];
                    goto compare;
                  }
                break;
              case 65:
                if (len == 5)
                  {
                    resword = &wordlist[38];
                    goto compare;
                  }
                break;
              case 66:
                if (len == 5)
                  {
                    resword = &wordlist[39];
                    goto compare;
                  }
                break;
              case 67:
                if (len == 4)
                  {
                    resword = &wordlist[40];
                    goto compare;
                  }
                break;
              case 69:
                if (len == 4)
                  {
                    resword = &wordlist[41];
                    goto compare;
                  }
                break;
              case 70:
                if (len == 8)
                  {
                    resword = &wordlist[42];
                    goto compare;
                  }
                break;
              case 71:
                if (len == 5)
                  {
                    resword = &wordlist[43];
                    goto compare;
                  }
                break;
              case 73:
                if (len == 6)
                  {
                    resword = &wordlist[44];
                    goto compare;
                  }
                break;
              case 74:
                if (len == 5)
                  {
                    resword = &wordlist[45];
                    goto compare;
                  }
                break;
              case 78:
                if (len == 2)
                  {
                    resword = &wordlist[46];
                    goto compare;
                  }
                break;
              case 79:
                if (len == 7)
                  {
                    resword = &wordlist[47];
                    goto compare;
                  }
                break;
              case 81:
                if (len == 6)
                  {
                    resword = &wordlist[48];
                    goto compare;
                  }
                break;
              case 85:
                if (len == 4)
                  {
                    resword = &wordlist[49];
                    goto compare;
                  }
                break;
              case 86:
                if (len == 2)
                  {
                    resword = &wordlist[50];
                    goto compare;
                  }
                break;
              case 88:
                if (len == 5)
                  {
                    resword = &wordlist[51];
                    goto compare;
                  }
                break;
              case 89:
                if (len == 5)
                  {
                    resword = &wordlist[52];
                    goto compare;
                  }
                break;
              case 91:
                if (len == 7)
                  {
                    resword = &wordlist[53];
                    goto compare;
                  }
                break;
              case 92:
                if (len == 3)
                  {
                    resword = &wordlist[54];
                    goto compare;
                  }
                break;
              case 93:
                if (len == 3)
                  {
                    resword = &wordlist[55];
                    goto compare;
                  }
                break;
              case 94:
                if (len == 4)
                  {
                    resword = &wordlist[56];
                    goto compare;
                  }
                break;
              case 95:
                if (len == 2)
                  {
                    resword = &wordlist[57];
                    goto compare;
                  }
                break;
              case 97:
                if (len == 2)
                  {
                    resword = &wordlist[58];
                    goto compare;
                  }
                break;
              case 98:
                if (len == 4)
                  {
                    resword = &wordlist[59];
                    goto compare;
                  }
                break;
              case 99:
                if (len == 4)
                  {
                    resword = &wordlist[60];
                    goto compare;
                  }
                break;
              case 100:
                if (len == 7)
                  {
                    resword = &wordlist[61];
                    goto compare;
                  }
                break;
              case 101:
                if (len == 4)
                  {
                    resword = &wordlist[62];
                    goto compare;
                  }
                break;
              case 103:
                if (len == 2)
                  {
                    resword = &wordlist[63];
                    goto compare;
                  }
                break;
              case 104:
                if (len == 2)
                  {
                    resword = &wordlist[64];
                    goto compare;
                  }
                break;
              case 109:
                if (len == 2)
                  {
                    resword = &wordlist[65];
                    goto compare;
                  }
                break;
              case 110:
                if (len == 9)
                  {
                    resword = &wordlist[66];
                    goto compare;
                  }
                break;
              case 113:
                lengthptr = &lengthtable[67];
                wordptr = &wordlist[67];
                wordendptr = wordptr + 2;
                goto multicompare;
              case 114:
                if (len == 5)
                  {
                    resword = &wordlist[69];
                    goto compare;
                  }
                break;
              case 116:
                if (len == 5)
                  {
                    resword = &wordlist[70];
                    goto compare;
                  }
                break;
              case 118:
                if (len == 2)
                  {
                    resword = &wordlist[71];
                    goto compare;
                  }
                break;
              case 119:
                if (len == 6)
                  {
                    resword = &wordlist[72];
                    goto compare;
                  }
                break;
              case 121:
                if (len == 3)
                  {
                    resword = &wordlist[73];
                    goto compare;
                  }
                break;
              case 123:
                if (len == 7)
                  {
                    resword = &wordlist[74];
                    goto compare;
                  }
                break;
              case 124:
                if (len == 5)
                  {
                    resword = &wordlist[75];
                    goto compare;
                  }
                break;
              case 129:
                if (len == 3)
                  {
                    resword = &wordlist[76];
                    goto compare;
                  }
                break;
              case 132:
                if (len == 6)
                  {
                    resword = &wordlist[77];
                    goto compare;
                  }
                break;
              case 134:
                if (len == 7)
                  {
                    resword = &wordlist[78];
                    goto compare;
                  }
                break;
              case 137:
                if (len == 5)
                  {
                    resword = &wordlist[79];
                    goto compare;
                  }
                break;
              case 139:
                if (len == 6)
                  {
                    resword = &wordlist[80];
                    goto compare;
                  }
                break;
              case 140:
                if (len == 2)
                  {
                    resword = &wordlist[81];
                    goto compare;
                  }
                break;
              case 141:
                if (len == 3)
                  {
                    resword = &wordlist[82];
                    goto compare;
                  }
                break;
              case 142:
                if (len == 5)
                  {
                    resword = &wordlist[83];
                    goto compare;
                  }
                break;
              case 146:
                if (len == 7)
                  {
                    resword = &wordlist[84];
                    goto compare;
                  }
                break;
              case 147:
                if (len == 5)
                  {
                    resword = &wordlist[85];
                    goto compare;
                  }
                break;
              case 149:
                if (len == 5)
                  {
                    resword = &wordlist[86];
                    goto compare;
                  }
                break;
              case 150:
                if (len == 2)
                  {
                    resword = &wordlist[87];
                    goto compare;
                  }
                break;
              case 152:
                if (len == 5)
                  {
                    resword = &wordlist[88];
                    goto compare;
                  }
                break;
              case 154:
                if (len == 4)
                  {
                    resword = &wordlist[89];
                    goto compare;
                  }
                break;
              case 159:
                if (len == 5)
                  {
                    resword = &wordlist[90];
                    goto compare;
                  }
                break;
              case 164:
                if (len == 2)
                  {
                    resword = &wordlist[91];
                    goto compare;
                  }
                break;
              case 166:
                if (len == 4)
                  {
                    resword = &wordlist[92];
                    goto compare;
                  }
                break;
              case 167:
                if (len == 3)
                  {
                    resword = &wordlist[93];
                    goto compare;
                  }
                break;
              case 168:
                if (len == 7)
                  {
                    resword = &wordlist[94];
                    goto compare;
                  }
                break;
              case 170:
                if (len == 5)
                  {
                    resword = &wordlist[95];
                    goto compare;
                  }
                break;
              case 175:
                if (len == 2)
                  {
                    resword = &wordlist[96];
                    goto compare;
                  }
                break;
              case 184:
                if (len == 5)
                  {
                    resword = &wordlist[97];
                    goto compare;
                  }
                break;
              case 186:
                if (len == 3)
                  {
                    resword = &wordlist[98];
                    goto compare;
                  }
                break;
              case 187:
                if (len == 5)
                  {
                    resword = &wordlist[99];
                    goto compare;
                  }
                break;
              case 191:
                if (len == 3)
                  {
                    resword = &wordlist[100];
                    goto compare;
                  }
                break;
              case 193:
                if (len == 6)
                  {
                    resword = &wordlist[101];
                    goto compare;
                  }
                break;
              case 194:
                if (len == 3)
                  {
                    resword = &wordlist[102];
                    goto compare;
                  }
                break;
              case 195:
                if (len == 2)
                  {
                    resword = &wordlist[103];
                    goto compare;
                  }
                break;
              case 196:
                if (len == 6)
                  {
                    resword = &wordlist[104];
                    goto compare;
                  }
                break;
              case 200:
                if (len == 6)
                  {
                    resword = &wordlist[105];
                    goto compare;
                  }
                break;
              case 202:
                if (len == 6)
                  {
                    resword = &wordlist[106];
                    goto compare;
                  }
                break;
              case 205:
                if (len == 8)
                  {
                    resword = &wordlist[107];
                    goto compare;
                  }
                break;
              case 208:
                if (len == 2)
                  {
                    resword = &wordlist[108];
                    goto compare;
                  }
                break;
              case 211:
                if (len == 3)
                  {
                    resword = &wordlist[109];
                    goto compare;
                  }
                break;
              case 212:
                if (len == 5)
                  {
                    resword = &wordlist[110];
                    goto compare;
                  }
                break;
              case 213:
                if (len == 3)
                  {
                    resword = &wordlist[111];
                    goto compare;
                  }
                break;
              case 215:
                if (len == 5)
                  {
                    resword = &wordlist[112];
                    goto compare;
                  }
                break;
              case 216:
                if (len == 4)
                  {
                    resword = &wordlist[113];
                    goto compare;
                  }
                break;
              case 218:
                if (len == 5)
                  {
                    resword = &wordlist[114];
                    goto compare;
                  }
                break;
              case 220:
                if (len == 5)
                  {
                    resword = &wordlist[115];
                    goto compare;
                  }
                break;
              case 224:
                if (len == 4)
                  {
                    resword = &wordlist[116];
                    goto compare;
                  }
                break;
              case 227:
                if (len == 8)
                  {
                    resword = &wordlist[117];
                    goto compare;
                  }
                break;
              case 229:
                if (len == 6)
                  {
                    resword = &wordlist[118];
                    goto compare;
                  }
                break;
              case 231:
                if (len == 6)
                  {
                    resword = &wordlist[119];
                    goto compare;
                  }
                break;
              case 233:
                if (len == 3)
                  {
                    resword = &wordlist[120];
                    goto compare;
                  }
                break;
              case 234:
                if (len == 6)
                  {
                    resword = &wordlist[121];
                    goto compare;
                  }
                break;
              case 235:
                if (len == 5)
                  {
                    resword = &wordlist[122];
                    goto compare;
                  }
                break;
              case 236:
                if (len == 4)
                  {
                    resword = &wordlist[123];
                    goto compare;
                  }
                break;
              case 237:
                if (len == 5)
                  {
                    resword = &wordlist[124];
                    goto compare;
                  }
                break;
              case 238:
                if (len == 4)
                  {
                    resword = &wordlist[125];
                    goto compare;
                  }
                break;
              case 239:
                if (len == 3)
                  {
                    resword = &wordlist[126];
                    goto compare;
                  }
                break;
              case 240:
                if (len == 2)
                  {
                    resword = &wordlist[127];
                    goto compare;
                  }
                break;
              case 241:
                if (len == 8)
                  {
                    resword = &wordlist[128];
                    goto compare;
                  }
                break;
              case 242:
                if (len == 4)
                  {
                    resword = &wordlist[129];
                    goto compare;
                  }
                break;
              case 245:
                if (len == 4)
                  {
                    resword = &wordlist[130];
                    goto compare;
                  }
                break;
              case 246:
                if (len == 7)
                  {
                    resword = &wordlist[131];
                    goto compare;
                  }
                break;
              case 247:
                if (len == 5)
                  {
                    resword = &wordlist[132];
                    goto compare;
                  }
                break;
              case 248:
                if (len == 6)
                  {
                    resword = &wordlist[133];
                    goto compare;
                  }
                break;
              case 249:
                if (len == 6)
                  {
                    resword = &wordlist[134];
                    goto compare;
                  }
                break;
              case 251:
                if (len == 6)
                  {
                    resword = &wordlist[135];
                    goto compare;
                  }
                break;
              case 255:
                if (len == 9)
                  {
                    resword = &wordlist[136];
                    goto compare;
                  }
                break;
              case 257:
                if (len == 5)
                  {
                    resword = &wordlist[137];
                    goto compare;
                  }
                break;
              case 258:
                if (len == 4)
                  {
                    resword = &wordlist[138];
                    goto compare;
                  }
                break;
              case 259:
                if (len == 4)
                  {
                    resword = &wordlist[139];
                    goto compare;
                  }
                break;
              case 262:
                if (len == 7)
                  {
                    resword = &wordlist[140];
                    goto compare;
                  }
                break;
              case 263:
                if (len == 6)
                  {
                    resword = &wordlist[141];
                    goto compare;
                  }
                break;
              case 265:
                if (len == 6)
                  {
                    resword = &wordlist[142];
                    goto compare;
                  }
                break;
              case 267:
                if (len == 5)
                  {
                    resword = &wordlist[143];
                    goto compare;
                  }
                break;
              case 268:
                if (len == 7)
                  {
                    resword = &wordlist[144];
                    goto compare;
                  }
                break;
              case 272:
                if (len == 2)
                  {
                    resword = &wordlist[145];
                    goto compare;
                  }
                break;
              case 276:
                if (len == 5)
                  {
                    resword = &wordlist[146];
                    goto compare;
                  }
                break;
              case 278:
                if (len == 4)
                  {
                    resword = &wordlist[147];
                    goto compare;
                  }
                break;
              case 279:
                if (len == 5)
                  {
                    resword = &wordlist[148];
                    goto compare;
                  }
                break;
              case 281:
                if (len == 6)
                  {
                    resword = &wordlist[149];
                    goto compare;
                  }
                break;
              case 282:
                if (len == 4)
                  {
                    resword = &wordlist[150];
                    goto compare;
                  }
                break;
              case 285:
                if (len == 4)
                  {
                    resword = &wordlist[151];
                    goto compare;
                  }
                break;
              case 287:
                if (len == 4)
                  {
                    resword = &wordlist[152];
                    goto compare;
                  }
                break;
              case 288:
                if (len == 4)
                  {
                    resword = &wordlist[153];
                    goto compare;
                  }
                break;
              case 290:
                if (len == 5)
                  {
                    resword = &wordlist[154];
                    goto compare;
                  }
                break;
              case 291:
                if (len == 8)
                  {
                    resword = &wordlist[155];
                    goto compare;
                  }
                break;
              case 293:
                if (len == 4)
                  {
                    resword = &wordlist[156];
                    goto compare;
                  }
                break;
              case 294:
                if (len == 5)
                  {
                    resword = &wordlist[157];
                    goto compare;
                  }
                break;
              case 297:
                if (len == 6)
                  {
                    resword = &wordlist[158];
                    goto compare;
                  }
                break;
              case 299:
                if (len == 5)
                  {
                    resword = &wordlist[159];
                    goto compare;
                  }
                break;
              case 302:
                if (len == 2)
                  {
                    resword = &wordlist[160];
                    goto compare;
                  }
                break;
              case 303:
                if (len == 4)
                  {
                    resword = &wordlist[161];
                    goto compare;
                  }
                break;
              case 304:
                if (len == 3)
                  {
                    resword = &wordlist[162];
                    goto compare;
                  }
                break;
              case 315:
                if (len == 5)
                  {
                    resword = &wordlist[163];
                    goto compare;
                  }
                break;
              case 317:
                if (len == 10)
                  {
                    resword = &wordlist[164];
                    goto compare;
                  }
                break;
              case 318:
                if (len == 6)
                  {
                    resword = &wordlist[165];
                    goto compare;
                  }
                break;
              case 319:
                if (len == 4)
                  {
                    resword = &wordlist[166];
                    goto compare;
                  }
                break;
              case 320:
                if (len == 4)
                  {
                    resword = &wordlist[167];
                    goto compare;
                  }
                break;
              case 322:
                if (len == 4)
                  {
                    resword = &wordlist[168];
                    goto compare;
                  }
                break;
              case 324:
                if (len == 5)
                  {
                    resword = &wordlist[169];
                    goto compare;
                  }
                break;
              case 325:
                if (len == 4)
                  {
                    resword = &wordlist[170];
                    goto compare;
                  }
                break;
              case 326:
                if (len == 5)
                  {
                    resword = &wordlist[171];
                    goto compare;
                  }
                break;
              case 329:
                if (len == 6)
                  {
                    resword = &wordlist[172];
                    goto compare;
                  }
                break;
              case 331:
                if (len == 4)
                  {
                    resword = &wordlist[173];
                    goto compare;
                  }
                break;
              case 332:
                if (len == 5)
                  {
                    resword = &wordlist[174];
                    goto compare;
                  }
                break;
              case 335:
                if (len == 9)
                  {
                    resword = &wordlist[175];
                    goto compare;
                  }
                break;
              case 336:
                if (len == 7)
                  {
                    resword = &wordlist[176];
                    goto compare;
                  }
                break;
              case 337:
                if (len == 2)
                  {
                    resword = &wordlist[177];
                    goto compare;
                  }
                break;
              case 339:
                if (len == 3)
                  {
                    resword = &wordlist[178];
                    goto compare;
                  }
                break;
              case 342:
                if (len == 7)
                  {
                    resword = &wordlist[179];
                    goto compare;
                  }
                break;
              case 344:
                if (len == 5)
                  {
                    resword = &wordlist[180];
                    goto compare;
                  }
                break;
              case 345:
                if (len == 5)
                  {
                    resword = &wordlist[181];
                    goto compare;
                  }
                break;
              case 347:
                if (len == 6)
                  {
                    resword = &wordlist[182];
                    goto compare;
                  }
                break;
              case 349:
                if (len == 6)
                  {
                    resword = &wordlist[183];
                    goto compare;
                  }
                break;
              case 353:
                if (len == 5)
                  {
                    resword = &wordlist[184];
                    goto compare;
                  }
                break;
              case 355:
                if (len == 5)
                  {
                    resword = &wordlist[185];
                    goto compare;
                  }
                break;
              case 359:
                if (len == 4)
                  {
                    resword = &wordlist[186];
                    goto compare;
                  }
                break;
              case 361:
                if (len == 2)
                  {
                    resword = &wordlist[187];
                    goto compare;
                  }
                break;
              case 363:
                if (len == 3)
                  {
                    resword = &wordlist[188];
                    goto compare;
                  }
                break;
              case 364:
                if (len == 7)
                  {
                    resword = &wordlist[189];
                    goto compare;
                  }
                break;
              case 365:
                if (len == 10)
                  {
                    resword = &wordlist[190];
                    goto compare;
                  }
                break;
              case 368:
                if (len == 5)
                  {
                    resword = &wordlist[191];
                    goto compare;
                  }
                break;
              case 374:
                if (len == 8)
                  {
                    resword = &wordlist[192];
                    goto compare;
                  }
                break;
              case 375:
                if (len == 4)
                  {
                    resword = &wordlist[193];
                    goto compare;
                  }
                break;
              case 388:
                if (len == 5)
                  {
                    resword = &wordlist[194];
                    goto compare;
                  }
                break;
              case 389:
                if (len == 8)
                  {
                    resword = &wordlist[195];
                    goto compare;
                  }
                break;
              case 390:
                if (len == 3)
                  {
                    resword = &wordlist[196];
                    goto compare;
                  }
                break;
              case 391:
                if (len == 5)
                  {
                    resword = &wordlist[197];
                    goto compare;
                  }
                break;
              case 400:
                if (len == 7)
                  {
                    resword = &wordlist[198];
                    goto compare;
                  }
                break;
              case 402:
                if (len == 2)
                  {
                    resword = &wordlist[199];
                    goto compare;
                  }
                break;
              case 404:
                if (len == 3)
                  {
                    resword = &wordlist[200];
                    goto compare;
                  }
                break;
              case 412:
                if (len == 4)
                  {
                    resword = &wordlist[201];
                    goto compare;
                  }
                break;
              case 415:
                if (len == 9)
                  {
                    resword = &wordlist[202];
                    goto compare;
                  }
                break;
              case 434:
                if (len == 2)
                  {
                    resword = &wordlist[203];
                    goto compare;
                  }
                break;
              case 436:
                if (len == 3)
                  {
                    resword = &wordlist[204];
                    goto compare;
                  }
                break;
              case 441:
                if (len == 10)
                  {
                    resword = &wordlist[205];
                    goto compare;
                  }
                break;
              case 448:
                if (len == 10)
                  {
                    resword = &wordlist[206];
                    goto compare;
                  }
                break;
              case 450:
                if (len == 4)
                  {
                    resword = &wordlist[207];
                    goto compare;
                  }
                break;
              case 453:
                if (len == 3)
                  {
                    resword = &wordlist[208];
                    goto compare;
                  }
                break;
              case 459:
                if (len == 8)
                  {
                    resword = &wordlist[209];
                    goto compare;
                  }
                break;
              case 460:
                if (len == 6)
                  {
                    resword = &wordlist[210];
                    goto compare;
                  }
                break;
              case 462:
                if (len == 2)
                  {
                    resword = &wordlist[211];
                    goto compare;
                  }
                break;
              case 464:
                if (len == 3)
                  {
                    resword = &wordlist[212];
                    goto compare;
                  }
                break;
              case 493:
                if (len == 6)
                  {
                    resword = &wordlist[213];
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
