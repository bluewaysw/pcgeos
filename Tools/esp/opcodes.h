/* C code produced by gperf version 2.7.1 (19981006 egcs) */
/* Command-line: gperf -i8 -o -j1 -S 1 -DtlTC -k1-3,$ -N findOpcode -H hashOpcode opcodes.gperf  */

#define TOTAL_KEYWORDS 172
#define MIN_WORD_LENGTH 2
#define MAX_WORD_LENGTH 6
#define MIN_HASH_VALUE 36
#define MAX_HASH_VALUE 443
/* maximum key range = 408, duplicates = 2 */

#ifdef __GNUC__
__inline
#endif
static unsigned int
hashOpcode (str, len)
     register const char *str;
     register unsigned int len;
{
  static const unsigned short asso_values[] =
    {
      444, 444, 444, 444, 444, 444, 444, 444, 444, 444,
      444, 444, 444, 444, 444, 444, 444, 444, 444, 444,
      444, 444, 444, 444, 444, 444, 444, 444, 444, 444,
      444, 444, 444, 444, 444, 444, 444, 444, 444, 444,
      444, 444, 444, 444, 444, 444, 444, 444, 444, 444,
      444, 444, 444, 444, 444, 444, 444, 444, 444, 444,
      444, 444, 444, 444, 444, 444, 444, 444, 444, 444,
      444, 444, 444, 444, 444, 444, 444, 444, 444, 444,
      444, 444, 444, 444, 444, 444, 444, 444, 444, 444,
      444, 444, 444, 444, 444, 444, 444,  92,  33,  42,
       12,  14, 123,  75, 104, 104,  43,   9,   9, 110,
      114,  18,  40,   9,  27,   8,  53, 191, 133, 176,
       88, 444,  89, 444, 444, 444, 444, 444, 444, 444,
      444, 444, 444, 444, 444, 444, 444, 444, 444, 444,
      444, 444, 444, 444, 444, 444, 444, 444, 444, 444,
      444, 444, 444, 444, 444, 444, 444, 444, 444, 444,
      444, 444, 444, 444, 444, 444, 444, 444, 444, 444,
      444, 444, 444, 444, 444, 444, 444, 444, 444, 444,
      444, 444, 444, 444, 444, 444, 444, 444, 444, 444,
      444, 444, 444, 444, 444, 444, 444, 444, 444, 444,
      444, 444, 444, 444, 444, 444, 444, 444, 444, 444,
      444, 444, 444, 444, 444, 444, 444, 444, 444, 444,
      444, 444, 444, 444, 444, 444, 444, 444, 444, 444,
      444, 444, 444, 444, 444, 444, 444, 444, 444, 444,
      444, 444, 444, 444, 444, 444, 444, 444, 444, 444,
      444, 444, 444, 444, 444, 444
    };
  register int hval = len;

  switch (hval)
    {
      default:
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
findOpcode (str, len)
     register const char *str;
     register unsigned int len;
{
  static const unsigned char lengthtable[] =
    {
       3,  3,  3,  3,  4,  5,  2,  2,  5,  6,  3,  2,  2,  3,
       5,  3,  2,  4,  3,  4,  4,  3,  4,  3,  4,  5,  4,  5,
       3,  3,  3,  3,  2,  3,  3,  5,  5,  4,  5,  3,  3,  3,
       3,  3,  3,  2,  3,  2,  3,  4,  3,  5,  4,  3,  5,  6,
       3,  3,  3,  3,  3,  4,  4,  4,  4,  4,  3,  3,  5,  5,
       3,  3,  3,  4,  4,  5,  3,  3,  5,  4,  4,  4,  3,  3,
       4,  2,  3,  4,  3,  4,  4,  4,  5,  3,  3,  4,  5,  3,
       5,  4,  3,  2,  4,  3,  5,  2,  5,  3,  3,  3,  3,  3,
       3,  3,  4,  3,  3,  4,  4,  4,  6,  6,  5,  5,  5,  3,
       4,  4,  4,  3,  3,  4,  4,  5,  5,  3,  4,  3,  4,  5,
       5,  3,  4,  4,  3,  4,  3,  3,  5,  3,  4,  4,  2,  5,
       3,  3,  5,  4,  4,  4,  5,  3,  5,  3,  3,  4,  3,  4,
       4,  3,  5,  5
    };
  static const OpCode wordlist[] =
    {
      {"lss",	LDPTR,	0x0fb2,},
      {"lsl",    LSINFO, 0x030f,},
      {"lds",    LDPTR,  0x00c5,},
      {"les",    LDPTR,  0x00c4,},
      {"lods",   LODS,   0x00ac,},
      {"lodsd",	NASTRGD,0x00ad,},
      {"js",     JUMP,   0x0078,},
      {"jl",     JUMP,   0x007c,},
      {"loope",  LOOP,   0x00e1,},
      {"loopne", LOOP,   0x00e0,},
      {"rol",    SHIFT,  0x00d0,},
      {"je",     JUMP,   0x0074,},
      {"or",     OR, 	0x0008,},
      {"cdq",	NOARGD,	0x0099,},
      {"lodsb",  NASTRG, 0x00ac,},
      {"cld",    NOARG,  0x00fc,},
      {"jo",     JUMP,   0x0070,},
      {"lock",   LOCK,   0x00f0,},
      {"jle",    JUMP,   0x007e,},
      {"sldt",   PWORD,  0x0000, /* 0f 00 /0 */},
      {"lldt",   PWORD,  0x1000, /* 0f 00 /2 */},
      {"std",    NOARG,  0x00fd,},
      {"loop",   LOOP,   0x00e2,},
      {"rcl",    SHIFT,  0x10d0,},
      {"stos",   STOS,   0x00aa,},
      {"stosd",  NOARGD, 0x00ab,},
      {"repe",   REP,    0x00f3,},
      {"repne",  REP,    0x00f2,},
      {"ror",    SHIFT,  0x08d0,},
      {"lgs",	LDPTR,	0x0fb5,},
      {"jbe",    JUMP,   0x0076,},
      {"sbb",    ARITH2, 0x0018,},
      {"jb",     JUMP,   0x0072,},
      {"dec",    WREG1,  0x0048,},
      {"jpe",    JUMP,   0x007a,},
      {"popad",	NOARGD, 0x0061,},
      {"popfd",	NOARGD, 0x009d,},
      {"clts",   NAPRIV, 0x060f,},
      {"stosb",  NOARG,  0x00aa,},
      {"str",    PWORD,  0x0800, /* 0f 00 /1 */},
      {"ltr",    PWORD,  0x1800, /* 0f 00 /3 */},
      {"sal",    SHIFT,  0x20d0,},
      {"jpo",    JUMP,   0x007b,},
      {"das",    NOARG,  0x002f,},
      {"rep",    REP,    0x00f3,},
      {"jp",     JUMP,   0x007a,},
      {"rcr",    SHIFT,  0x18d0,},
      {"jc",     JUMP,   0x0072,},
      {"add",    ARITH2, 0x0000,},
      {"test",   TEST,   0x0084,},
      {"shl",    SHL,  	0x20d0,},
      {"leave",  LEAVE,  0x00c9,},
      {"shld",	SHLD,	0x00a4, /* 0f a4 */},
      {"clc",    NOARG,  0x00f8,},
      {"loopz",  LOOP,   0x00e1,},
      {"loopnz", LOOP,   0x00e0,},
      {"pop",    POP,    0x0058, /* yyparse knows to deal with seg regs */},
      {"stc",    NOARG,  0x00f9,},
      {"jge",    JUMP,   0x007d,},
      {"ret",    RET,    0x00c3,},
      {"lfs",	LDPTR,	0x0fb4,},
      {"sgdt",   LSDT,   0x0000, /* 0f 01 /0 */},
      {"lgdt",   LSDT,   0x0010, /* 0f 01 /2 */},
      {"scas",   SCAS,   0x00ae,},
      {"shrd",	SHRD,	0x00ac, /* 0f ac */},
      {"call",   CALL,   0x0000, /* Known in yyparse() */},
      {"sar",    SHIFT,  0x38d0,},
      {"lar",    LSINFO, 0x020f,},
      {"scasd",	NOARGD, 0x00af,},
      {"iretd",	NOARGD,	0x00cf,},
      {"xor",    XOR, 	0x0030,},
      {"jae",    JUMP,   0x0073,},
      {"shr",    SHR,  	0x28d0,},
      {"arpl",   ARPL,   0x0063,},
      {"repz",   REP,    0x00f3,},
      {"repnz",  REP,    0x00f2,},
      {"jns",    JUMP,   0x0079,},
      {"jnl",    JUMP,   0x007d,},
      {"scasb",  NOARG,  0x00ae,},
      {"sidt",   LSDT,   0x0008, /* 0f 01 /1 */},
      {"lidt",   LSDT,   0x0018, /* 0f 01 /3 */},
      {"jnle",   JUMP,   0x007f,},
      {"jne",    JUMP,   0x0075,},
      {"adc",    ARITH2, 0x0010,},
      {"popa",   NOARGW, 0x0061,},
      {"jg",     JUMP,   0x007f,},
      {"jno",    JUMP,   0x0071,},
      {"iret",   NOARGW, 0x00cf,},
      {"aas",    NOARG,  0x003f,},
      {"cmps",   CMPS,   0x00a6,},
      {"verr",   PWORD,  0x2000, /* 0f 00 /4 */},
      {"jnbe",   JUMP,   0x0077,},
      {"cmpsd",  NASTRGD,0x00a7,},
      {"lea",    LEA,    0x008d,},
      {"aad",    NOARG,  0x0ad5,},
      {"retn",   RETN,   0x00c3,},
      {"enter",  ENTER,  0x00c8,},
      {"nop",    NOARG,  0x0090,},
      {"lodsw",  NASTRGW,0x00ad,},
      {"retf",   RETF,   0x00cb,},
      {"hlt",    NAIO,   0x00f4,},
      {"jz",     JUMP,   0x0074,},
      {"popf",   NOARGW, 0x009d,},
      {"jnb",    JUMP,   0x0073,},
      {"xlatb",  NASTRG, 0x00d7,},
      {"ja",     JUMP,   0x0077,},
      {"cmpsb",  NASTRG, 0x00a6,},
      {"and",    AND, 	0x0020,},
      {"cmp",    ARITH2, 0x0038,},
      {"jmp",    JMP,    0x0000, /* yyparse knows what to do */},
      {"ins",    INS,    0x006c,},
      {"cmc",    NOARG,  0x00f5,},
      {"jnp",    JUMP,   0x007b,},
      {"not",    NOT, 	0x10f6,},
      {"insd",	NOARGD,	0x006d,},
      {"jnc",    JUMP,   0x0073,},
      {"cwd",    NOARG,  0x0099,},
      {"xlat",   XLAT,   0x00d7,},
      {"cwde",	NOARGD,	0x0098,},
      {"jnge",   JUMP,   0x007c,},
      {"pushad",	NOARGD, 0x0060,},
      {"pushfd",	NOARGD, 0x009c,},
      {"bound",  BOUND,  0x0062,},
      {"stosw",  NOARGW, 0x00ab,},
      {"xornf",  BITNF,	0x0030,},
      {"cli",    NAIO,   0x00fa,},
      {"insb",   NOARG,  0x006c,},
      {"jcxz",   JUMP,   0x00e3,},
      {"jnae",   JUMP,   0x0072,},
      {"sub",    ARITH2, 0x0028,},
      {"sti",    NOARG,  0x00fb,},
      {"movs",   MOVS,   0x00a4,},
      {"outs",   OUTS,   0x006e,},
      {"movsd",  NASTRGD,0x00a5,},
      {"outsd",  NASTRGD,0x006f,},
      {"neg",    GROUP1, 0x18f6,},
      {"ornf",   BITNF,	0x0008,},
      {"daa",    NOARG,  0x0027,},
      {"into",   NOARG,  0x00ce,},
      {"movsb",  NASTRG, 0x00a4,},
      {"outsb",  NASTRG, 0x006e,},
      {"inc",    WREG1,  0x0040,},
      {"smsw",   PWORD,  0x2001, /* 0f 01 /4 */},
      {"lmsw",   PWORD,  0x3001, /* 0f 01 /6 */},
      {"jng",    JUMP,   0x007e,},
      {"xchg",   XCHG,   0x0090,},
      {"out",    IO,     0x00e6,},
      {"mul",    GROUP1, 0x20f6,},
      {"scasw",  NOARGW, 0x00af,},
      {"int",    INT,    0x00cd,},
      {"sahf",   NOARG,  0x009e,},
      {"lahf",   NOARG,  0x009f,},
      {"in",     IO,     0x00e4,},
      {"pusha",  NOARGW, 0x0060,},
      {"jnz",    JUMP,   0x0075,},
      {"jna",    JUMP,   0x0076,},
      {"andnf",  BITNF,	0x0020,},
      {"push",   PUSH,   0x0050, /* yyparse knows to deal with segs etc. */},
      {"verw",   PWORD,  0x2800, /* 0f 00 /5 */},
      {"idiv",   GROUP1, 0x38f6,},
      {"pushf",  NOARGW, 0x009c,},
      {"aaa",    NOARG,  0x0037,},
      {"cmpsw",  NASTRGW,0x00a7,},
      {"div",    GROUP1, 0x30f6,},
      {"mov",    MOV,    0x0000, /* yyparse knows what to do */},
      {"insw",   NOARGW, 0x006d,},
      {"aam",    NOARG,  0x0ad4,},
      {"imul",   IMUL,   0x28f6,},
      {"wait",   NOARG,  0x009b,},
      {"cbw",    NOARGW, 0x0098,},
      {"movsw",  NASTRGW,0x00a5,},
      {"outsw",  NASTRGW,0x006f,}
    };

  if (len <= MAX_WORD_LENGTH && len >= MIN_WORD_LENGTH)
    {
      register int key = hashOpcode (str, len);

      if (key <= MAX_HASH_VALUE && key >= MIN_HASH_VALUE)
        {
          register const unsigned char *lengthptr;
          register const OpCode *wordptr;
          register const OpCode *wordendptr;
          register const OpCode *resword;

          switch (key - 36)
            {
              case 0:
                if (len == 3)
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
                if (len == 3)
                  {
                    resword = &wordlist[2];
                    goto compare;
                  }
                break;
              case 6:
                if (len == 3)
                  {
                    resword = &wordlist[3];
                    goto compare;
                  }
                break;
              case 15:
                if (len == 4)
                  {
                    resword = &wordlist[4];
                    goto compare;
                  }
                break;
              case 20:
                if (len == 5)
                  {
                    resword = &wordlist[5];
                    goto compare;
                  }
                break;
              case 25:
                if (len == 2)
                  {
                    resword = &wordlist[6];
                    goto compare;
                  }
                break;
              case 27:
                if (len == 2)
                  {
                    resword = &wordlist[7];
                    goto compare;
                  }
                break;
              case 28:
                if (len == 5)
                  {
                    resword = &wordlist[8];
                    goto compare;
                  }
                break;
              case 29:
                if (len == 6)
                  {
                    resword = &wordlist[9];
                    goto compare;
                  }
                break;
              case 30:
                if (len == 3)
                  {
                    resword = &wordlist[10];
                    goto compare;
                  }
                break;
              case 37:
                if (len == 2)
                  {
                    resword = &wordlist[11];
                    goto compare;
                  }
                break;
              case 38:
                if (len == 2)
                  {
                    resword = &wordlist[12];
                    goto compare;
                  }
                break;
              case 39:
                if (len == 3)
                  {
                    resword = &wordlist[13];
                    goto compare;
                  }
                break;
              case 41:
                if (len == 5)
                  {
                    resword = &wordlist[14];
                    goto compare;
                  }
                break;
              case 42:
                if (len == 3)
                  {
                    resword = &wordlist[15];
                    goto compare;
                  }
                break;
              case 45:
                if (len == 2)
                  {
                    resword = &wordlist[16];
                    goto compare;
                  }
                break;
              case 46:
                if (len == 4)
                  {
                    resword = &wordlist[17];
                    goto compare;
                  }
                break;
              case 47:
                if (len == 3)
                  {
                    resword = &wordlist[18];
                    goto compare;
                  }
                break;
              case 50:
                if (len == 4)
                  {
                    resword = &wordlist[19];
                    goto compare;
                  }
                break;
              case 51:
                if (len == 4)
                  {
                    resword = &wordlist[20];
                    goto compare;
                  }
                break;
              case 52:
                if (len == 3)
                  {
                    resword = &wordlist[21];
                    goto compare;
                  }
                break;
              case 53:
                if (len == 4)
                  {
                    resword = &wordlist[22];
                    goto compare;
                  }
                break;
              case 54:
                if (len == 3)
                  {
                    resword = &wordlist[23];
                    goto compare;
                  }
                break;
              case 55:
                if (len == 4)
                  {
                    resword = &wordlist[24];
                    goto compare;
                  }
                break;
              case 60:
                if (len == 5)
                  {
                    resword = &wordlist[25];
                    goto compare;
                  }
                break;
              case 63:
                if (len == 4)
                  {
                    resword = &wordlist[26];
                    goto compare;
                  }
                break;
              case 64:
                if (len == 5)
                  {
                    resword = &wordlist[27];
                    goto compare;
                  }
                break;
              case 66:
                if (len == 3)
                  {
                    resword = &wordlist[28];
                    goto compare;
                  }
                break;
              case 67:
                if (len == 3)
                  {
                    resword = &wordlist[29];
                    goto compare;
                  }
                break;
              case 71:
                if (len == 3)
                  {
                    resword = &wordlist[30];
                    goto compare;
                  }
                break;
              case 74:
                if (len == 3)
                  {
                    resword = &wordlist[31];
                    goto compare;
                  }
                break;
              case 75:
                if (len == 2)
                  {
                    resword = &wordlist[32];
                    goto compare;
                  }
                break;
              case 77:
                if (len == 3)
                  {
                    resword = &wordlist[33];
                    goto compare;
                  }
                break;
              case 78:
                if (len == 3)
                  {
                    resword = &wordlist[34];
                    goto compare;
                  }
                break;
              case 79:
                lengthptr = &lengthtable[35];
                wordptr = &wordlist[35];
                wordendptr = wordptr + 2;
                goto multicompare;
              case 80:
                if (len == 4)
                  {
                    resword = &wordlist[37];
                    goto compare;
                  }
                break;
              case 81:
                if (len == 5)
                  {
                    resword = &wordlist[38];
                    goto compare;
                  }
                break;
              case 82:
                if (len == 3)
                  {
                    resword = &wordlist[39];
                    goto compare;
                  }
                break;
              case 83:
                if (len == 3)
                  {
                    resword = &wordlist[40];
                    goto compare;
                  }
                break;
              case 85:
                if (len == 3)
                  {
                    resword = &wordlist[41];
                    goto compare;
                  }
                break;
              case 86:
                if (len == 3)
                  {
                    resword = &wordlist[42];
                    goto compare;
                  }
                break;
              case 87:
                if (len == 3)
                  {
                    resword = &wordlist[43];
                    goto compare;
                  }
                break;
              case 88:
                if (len == 3)
                  {
                    resword = &wordlist[44];
                    goto compare;
                  }
                break;
              case 89:
                if (len == 2)
                  {
                    resword = &wordlist[45];
                    goto compare;
                  }
                break;
              case 90:
                if (len == 3)
                  {
                    resword = &wordlist[46];
                    goto compare;
                  }
                break;
              case 93:
                if (len == 2)
                  {
                    resword = &wordlist[47];
                    goto compare;
                  }
                break;
              case 95:
                if (len == 3)
                  {
                    resword = &wordlist[48];
                    goto compare;
                  }
                break;
              case 96:
                if (len == 4)
                  {
                    resword = &wordlist[49];
                    goto compare;
                  }
                break;
              case 97:
                if (len == 3)
                  {
                    resword = &wordlist[50];
                    goto compare;
                  }
                break;
              case 98:
                if (len == 5)
                  {
                    resword = &wordlist[51];
                    goto compare;
                  }
                break;
              case 101:
                if (len == 4)
                  {
                    resword = &wordlist[52];
                    goto compare;
                  }
                break;
              case 102:
                if (len == 3)
                  {
                    resword = &wordlist[53];
                    goto compare;
                  }
                break;
              case 103:
                if (len == 5)
                  {
                    resword = &wordlist[54];
                    goto compare;
                  }
                break;
              case 104:
                if (len == 6)
                  {
                    resword = &wordlist[55];
                    goto compare;
                  }
                break;
              case 105:
                if (len == 3)
                  {
                    resword = &wordlist[56];
                    goto compare;
                  }
                break;
              case 112:
                if (len == 3)
                  {
                    resword = &wordlist[57];
                    goto compare;
                  }
                break;
              case 113:
                if (len == 3)
                  {
                    resword = &wordlist[58];
                    goto compare;
                  }
                break;
              case 114:
                if (len == 3)
                  {
                    resword = &wordlist[59];
                    goto compare;
                  }
                break;
              case 115:
                if (len == 3)
                  {
                    resword = &wordlist[60];
                    goto compare;
                  }
                break;
              case 116:
                if (len == 4)
                  {
                    resword = &wordlist[61];
                    goto compare;
                  }
                break;
              case 117:
                if (len == 4)
                  {
                    resword = &wordlist[62];
                    goto compare;
                  }
                break;
              case 118:
                if (len == 4)
                  {
                    resword = &wordlist[63];
                    goto compare;
                  }
                break;
              case 119:
                if (len == 4)
                  {
                    resword = &wordlist[64];
                    goto compare;
                  }
                break;
              case 120:
                if (len == 4)
                  {
                    resword = &wordlist[65];
                    goto compare;
                  }
                break;
              case 121:
                if (len == 3)
                  {
                    resword = &wordlist[66];
                    goto compare;
                  }
                break;
              case 122:
                if (len == 3)
                  {
                    resword = &wordlist[67];
                    goto compare;
                  }
                break;
              case 123:
                if (len == 5)
                  {
                    resword = &wordlist[68];
                    goto compare;
                  }
                break;
              case 126:
                if (len == 5)
                  {
                    resword = &wordlist[69];
                    goto compare;
                  }
                break;
              case 127:
                if (len == 3)
                  {
                    resword = &wordlist[70];
                    goto compare;
                  }
                break;
              case 130:
                if (len == 3)
                  {
                    resword = &wordlist[71];
                    goto compare;
                  }
                break;
              case 133:
                if (len == 3)
                  {
                    resword = &wordlist[72];
                    goto compare;
                  }
                break;
              case 136:
                if (len == 4)
                  {
                    resword = &wordlist[73];
                    goto compare;
                  }
                break;
              case 138:
                if (len == 4)
                  {
                    resword = &wordlist[74];
                    goto compare;
                  }
                break;
              case 139:
                if (len == 5)
                  {
                    resword = &wordlist[75];
                    goto compare;
                  }
                break;
              case 140:
                if (len == 3)
                  {
                    resword = &wordlist[76];
                    goto compare;
                  }
                break;
              case 142:
                if (len == 3)
                  {
                    resword = &wordlist[77];
                    goto compare;
                  }
                break;
              case 144:
                if (len == 5)
                  {
                    resword = &wordlist[78];
                    goto compare;
                  }
                break;
              case 145:
                if (len == 4)
                  {
                    resword = &wordlist[79];
                    goto compare;
                  }
                break;
              case 146:
                if (len == 4)
                  {
                    resword = &wordlist[80];
                    goto compare;
                  }
                break;
              case 148:
                if (len == 4)
                  {
                    resword = &wordlist[81];
                    goto compare;
                  }
                break;
              case 152:
                if (len == 3)
                  {
                    resword = &wordlist[82];
                    goto compare;
                  }
                break;
              case 155:
                if (len == 3)
                  {
                    resword = &wordlist[83];
                    goto compare;
                  }
                break;
              case 158:
                if (len == 4)
                  {
                    resword = &wordlist[84];
                    goto compare;
                  }
                break;
              case 159:
                if (len == 2)
                  {
                    resword = &wordlist[85];
                    goto compare;
                  }
                break;
              case 160:
                if (len == 3)
                  {
                    resword = &wordlist[86];
                    goto compare;
                  }
                break;
              case 166:
                if (len == 4)
                  {
                    resword = &wordlist[87];
                    goto compare;
                  }
                break;
              case 167:
                if (len == 3)
                  {
                    resword = &wordlist[88];
                    goto compare;
                  }
                break;
              case 168:
                if (len == 4)
                  {
                    resword = &wordlist[89];
                    goto compare;
                  }
                break;
              case 169:
                if (len == 4)
                  {
                    resword = &wordlist[90];
                    goto compare;
                  }
                break;
              case 172:
                if (len == 4)
                  {
                    resword = &wordlist[91];
                    goto compare;
                  }
                break;
              case 173:
                if (len == 5)
                  {
                    resword = &wordlist[92];
                    goto compare;
                  }
                break;
              case 174:
                if (len == 3)
                  {
                    resword = &wordlist[93];
                    goto compare;
                  }
                break;
              case 175:
                if (len == 3)
                  {
                    resword = &wordlist[94];
                    goto compare;
                  }
                break;
              case 176:
                if (len == 4)
                  {
                    resword = &wordlist[95];
                    goto compare;
                  }
                break;
              case 177:
                if (len == 5)
                  {
                    resword = &wordlist[96];
                    goto compare;
                  }
                break;
              case 179:
                if (len == 3)
                  {
                    resword = &wordlist[97];
                    goto compare;
                  }
                break;
              case 184:
                if (len == 5)
                  {
                    resword = &wordlist[98];
                    goto compare;
                  }
                break;
              case 185:
                if (len == 4)
                  {
                    resword = &wordlist[99];
                    goto compare;
                  }
                break;
              case 186:
                if (len == 3)
                  {
                    resword = &wordlist[100];
                    goto compare;
                  }
                break;
              case 187:
                if (len == 2)
                  {
                    resword = &wordlist[101];
                    goto compare;
                  }
                break;
              case 189:
                if (len == 4)
                  {
                    resword = &wordlist[102];
                    goto compare;
                  }
                break;
              case 190:
                if (len == 3)
                  {
                    resword = &wordlist[103];
                    goto compare;
                  }
                break;
              case 191:
                if (len == 5)
                  {
                    resword = &wordlist[104];
                    goto compare;
                  }
                break;
              case 193:
                if (len == 2)
                  {
                    resword = &wordlist[105];
                    goto compare;
                  }
                break;
              case 194:
                if (len == 5)
                  {
                    resword = &wordlist[106];
                    goto compare;
                  }
                break;
              case 197:
                if (len == 3)
                  {
                    resword = &wordlist[107];
                    goto compare;
                  }
                break;
              case 199:
                if (len == 3)
                  {
                    resword = &wordlist[108];
                    goto compare;
                  }
                break;
              case 200:
                if (len == 3)
                  {
                    resword = &wordlist[109];
                    goto compare;
                  }
                break;
              case 201:
                if (len == 3)
                  {
                    resword = &wordlist[110];
                    goto compare;
                  }
                break;
              case 203:
                if (len == 3)
                  {
                    resword = &wordlist[111];
                    goto compare;
                  }
                break;
              case 204:
                if (len == 3)
                  {
                    resword = &wordlist[112];
                    goto compare;
                  }
                break;
              case 205:
                if (len == 3)
                  {
                    resword = &wordlist[113];
                    goto compare;
                  }
                break;
              case 206:
                if (len == 4)
                  {
                    resword = &wordlist[114];
                    goto compare;
                  }
                break;
              case 208:
                if (len == 3)
                  {
                    resword = &wordlist[115];
                    goto compare;
                  }
                break;
              case 209:
                if (len == 3)
                  {
                    resword = &wordlist[116];
                    goto compare;
                  }
                break;
              case 210:
                if (len == 4)
                  {
                    resword = &wordlist[117];
                    goto compare;
                  }
                break;
              case 212:
                if (len == 4)
                  {
                    resword = &wordlist[118];
                    goto compare;
                  }
                break;
              case 214:
                if (len == 4)
                  {
                    resword = &wordlist[119];
                    goto compare;
                  }
                break;
              case 221:
                lengthptr = &lengthtable[120];
                wordptr = &wordlist[120];
                wordendptr = wordptr + 2;
                goto multicompare;
              case 223:
                if (len == 5)
                  {
                    resword = &wordlist[122];
                    goto compare;
                  }
                break;
              case 224:
                if (len == 5)
                  {
                    resword = &wordlist[123];
                    goto compare;
                  }
                break;
              case 225:
                if (len == 5)
                  {
                    resword = &wordlist[124];
                    goto compare;
                  }
                break;
              case 226:
                if (len == 3)
                  {
                    resword = &wordlist[125];
                    goto compare;
                  }
                break;
              case 227:
                if (len == 4)
                  {
                    resword = &wordlist[126];
                    goto compare;
                  }
                break;
              case 230:
                if (len == 4)
                  {
                    resword = &wordlist[127];
                    goto compare;
                  }
                break;
              case 231:
                if (len == 4)
                  {
                    resword = &wordlist[128];
                    goto compare;
                  }
                break;
              case 232:
                if (len == 3)
                  {
                    resword = &wordlist[129];
                    goto compare;
                  }
                break;
              case 236:
                if (len == 3)
                  {
                    resword = &wordlist[130];
                    goto compare;
                  }
                break;
              case 237:
                if (len == 4)
                  {
                    resword = &wordlist[131];
                    goto compare;
                  }
                break;
              case 238:
                if (len == 4)
                  {
                    resword = &wordlist[132];
                    goto compare;
                  }
                break;
              case 242:
                if (len == 5)
                  {
                    resword = &wordlist[133];
                    goto compare;
                  }
                break;
              case 243:
                if (len == 5)
                  {
                    resword = &wordlist[134];
                    goto compare;
                  }
                break;
              case 245:
                if (len == 3)
                  {
                    resword = &wordlist[135];
                    goto compare;
                  }
                break;
              case 250:
                if (len == 4)
                  {
                    resword = &wordlist[136];
                    goto compare;
                  }
                break;
              case 255:
                if (len == 3)
                  {
                    resword = &wordlist[137];
                    goto compare;
                  }
                break;
              case 257:
                if (len == 4)
                  {
                    resword = &wordlist[138];
                    goto compare;
                  }
                break;
              case 263:
                if (len == 5)
                  {
                    resword = &wordlist[139];
                    goto compare;
                  }
                break;
              case 264:
                if (len == 5)
                  {
                    resword = &wordlist[140];
                    goto compare;
                  }
                break;
              case 269:
                if (len == 3)
                  {
                    resword = &wordlist[141];
                    goto compare;
                  }
                break;
              case 270:
                if (len == 4)
                  {
                    resword = &wordlist[142];
                    goto compare;
                  }
                break;
              case 271:
                if (len == 4)
                  {
                    resword = &wordlist[143];
                    goto compare;
                  }
                break;
              case 274:
                if (len == 3)
                  {
                    resword = &wordlist[144];
                    goto compare;
                  }
                break;
              case 277:
                if (len == 4)
                  {
                    resword = &wordlist[145];
                    goto compare;
                  }
                break;
              case 282:
                if (len == 3)
                  {
                    resword = &wordlist[146];
                    goto compare;
                  }
                break;
              case 286:
                if (len == 3)
                  {
                    resword = &wordlist[147];
                    goto compare;
                  }
                break;
              case 287:
                if (len == 5)
                  {
                    resword = &wordlist[148];
                    goto compare;
                  }
                break;
              case 291:
                if (len == 3)
                  {
                    resword = &wordlist[149];
                    goto compare;
                  }
                break;
              case 295:
                if (len == 4)
                  {
                    resword = &wordlist[150];
                    goto compare;
                  }
                break;
              case 296:
                if (len == 4)
                  {
                    resword = &wordlist[151];
                    goto compare;
                  }
                break;
              case 298:
                if (len == 2)
                  {
                    resword = &wordlist[152];
                    goto compare;
                  }
                break;
              case 300:
                if (len == 5)
                  {
                    resword = &wordlist[153];
                    goto compare;
                  }
                break;
              case 302:
                if (len == 3)
                  {
                    resword = &wordlist[154];
                    goto compare;
                  }
                break;
              case 308:
                if (len == 3)
                  {
                    resword = &wordlist[155];
                    goto compare;
                  }
                break;
              case 310:
                if (len == 5)
                  {
                    resword = &wordlist[156];
                    goto compare;
                  }
                break;
              case 311:
                if (len == 4)
                  {
                    resword = &wordlist[157];
                    goto compare;
                  }
                break;
              case 318:
                if (len == 4)
                  {
                    resword = &wordlist[158];
                    goto compare;
                  }
                break;
              case 321:
                if (len == 4)
                  {
                    resword = &wordlist[159];
                    goto compare;
                  }
                break;
              case 331:
                if (len == 5)
                  {
                    resword = &wordlist[160];
                    goto compare;
                  }
                break;
              case 335:
                if (len == 3)
                  {
                    resword = &wordlist[161];
                    goto compare;
                  }
                break;
              case 337:
                if (len == 5)
                  {
                    resword = &wordlist[162];
                    goto compare;
                  }
                break;
              case 349:
                if (len == 3)
                  {
                    resword = &wordlist[163];
                    goto compare;
                  }
                break;
              case 361:
                if (len == 3)
                  {
                    resword = &wordlist[164];
                    goto compare;
                  }
                break;
              case 370:
                if (len == 4)
                  {
                    resword = &wordlist[165];
                    goto compare;
                  }
                break;
              case 371:
                if (len == 3)
                  {
                    resword = &wordlist[166];
                    goto compare;
                  }
                break;
              case 382:
                if (len == 4)
                  {
                    resword = &wordlist[167];
                    goto compare;
                  }
                break;
              case 393:
                if (len == 4)
                  {
                    resword = &wordlist[168];
                    goto compare;
                  }
                break;
              case 394:
                if (len == 3)
                  {
                    resword = &wordlist[169];
                    goto compare;
                  }
                break;
              case 406:
                if (len == 5)
                  {
                    resword = &wordlist[170];
                    goto compare;
                  }
                break;
              case 407:
                if (len == 5)
                  {
                    resword = &wordlist[171];
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
