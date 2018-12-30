/* A Bison parser, made by GNU Bison 3.0.4.  */

/* Bison interface for Yacc-like parsers in C

   Copyright (C) 1984, 1989-1990, 2000-2015 Free Software Foundation, Inc.

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.  */

/* As a special exception, you may create a larger work that contains
   part or all of the Bison parser skeleton and distribute that work
   under terms of your choice, so long as that work isn't itself a
   parser generator using the skeleton or a modified version thereof
   as a parser skeleton.  Alternatively, if you modify or redistribute
   the parser skeleton itself, you may (at your option) remove this
   special exception, which will cause the skeleton and the resulting
   Bison output files to be licensed under the GNU General Public
   License without this special exception.

   This special exception was added by the Free Software Foundation in
   version 2.2 of Bison.  */

#ifndef YY_YY_PARSE_H_INCLUDED
# define YY_YY_PARSE_H_INCLUDED
/* Debug traces.  */
#ifndef YYDEBUG
# define YYDEBUG 0
#endif
#if YYDEBUG
extern int yydebug;
#endif

/* Token type.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
  enum yytokentype
  {
    CLASS = 258,
    META = 259,
    MASTER = 260,
    VARIANT = 261,
    ENDC = 262,
    CLASSDECL = 263,
    NEVER_SAVED = 264,
    MESSAGE = 265,
    STACK = 266,
    CARRY = 267,
    AX = 268,
    CX = 269,
    DX = 270,
    BP = 271,
    AL = 272,
    AH = 273,
    CL = 274,
    CH = 275,
    DL = 276,
    DH = 277,
    BPL = 278,
    BPH = 279,
    SS = 280,
    AXBPCXDX = 281,
    AXCXDXBP = 282,
    CXDXBPAX = 283,
    DXCX = 284,
    BPAXDXCX = 285,
    MULTIPLEAX = 286,
    ALIAS = 287,
    PROTOTYPE = 288,
    RESERVE_MESSAGES = 289,
    EXPORT_MESSAGES = 290,
    IMPORT_MESSAGE = 291,
    SET_MESSAGE_NUM = 292,
    INSTANCE = 293,
    COMPOSITE = 294,
    LINK = 295,
    VIS_MONIKER = 296,
    KBD_ACCELERATOR = 297,
    DEFAULT = 298,
    RELOC = 299,
    FPTR = 300,
    HPTR = 301,
    OPTR = 302,
    DEFAULT_MODEL = 303,
    METHOD = 304,
    FAR = 305,
    NEAR = 306,
    BASED = 307,
    CALL = 308,
    CALL_SUPER = 309,
    SEND = 310,
    RECORD = 311,
    DISPATCH = 312,
    DISPATCHCALL = 313,
    FORCE_QUEUE = 314,
    RETURN_ERROR = 315,
    CHECK_DUPLICATE = 316,
    NO_FREE = 317,
    CHECK_LAST_ONLY = 318,
    REPLACE = 319,
    INSERT_AT_FRONT = 320,
    CAN_DISCARD_IF_DESPARATE = 321,
    NULL_TOKEN = 322,
    PARENT = 323,
    CHILDREN = 324,
    LOCALIZE = 325,
    COMPILER = 326,
    HIGHC = 327,
    MSC = 328,
    START = 329,
    DATA = 330,
    NOT_LMEM = 331,
    NOT_DETACHABLE = 332,
    END = 333,
    HEADER = 334,
    CHUNK = 335,
    CHUNK_ARRAY = 336,
    ELEMENT_ARRAY = 337,
    OBJECT = 338,
    SPECIFIC_UI = 339,
    KBD_PATH = 340,
    RESOURCE_OUTPUT = 341,
    VARDATA = 342,
    VARDATA_ALIAS = 343,
    IGNORE_DIRTY = 344,
    DEFLIB = 345,
    ENDLIB = 346,
    EXTERN = 347,
    GCN_LIST = 348,
    PROTOMINOR = 349,
    PROTORESET = 350,
    OPTIMIZE = 351,
    NORELOC = 352,
    USES = 353,
    NOT = 354,
    FIRSTSYM = 355,
    CLASS_SYM = 356,
    OBJECT_SYM = 357,
    MSG_SYM = 358,
    EXPORT_SYM = 359,
    RESOURCE_SYM = 360,
    CHUNK_SYM = 361,
    VIS_MONIKER_CHUNK_SYM = 362,
    VARDATA_SYM = 363,
    PROTOMINOR_SYM = 364,
    REG_INSTANCE_SYM = 365,
    COMPOSITE_SYM = 366,
    LINK_SYM = 367,
    VIS_MONIKER_SYM = 368,
    VARIANT_PTR_SYM = 369,
    KBD_ACCELERATOR_SYM = 370,
    OPTR_SYM = 371,
    CHUNK_INST_SYM = 372,
    LIST_SYM = 373,
    GSTRING_SYM = 374,
    ATTRIBUTES_SYM = 375,
    COLOR_SYM = 376,
    SIZE_SYM = 377,
    ASPECT_RATIO_SYM = 378,
    CACHED_SIZE_SYM = 379,
    SIZE_COMP_SYM = 380,
    COLOR_COMP_SYM = 381,
    ASPECT_RATIO_COMP_SYM = 382,
    STYLE_SYM = 383,
    STYLE_COMP_SYM = 384,
    KBD_SYM = 385,
    KBD_MODIFIER_SYM = 386,
    GCN_LIST_SYM = 387,
    GCN_LIST_OF_LISTS_SYM = 388,
    LASTSYM = 389,
    SPECIAL_DEBUG_TOKEN = 390,
    SPECIAL_UNDEBUG_TOKEN = 391,
    IDENT = 392,
    STRING = 393,
    FAKESTRING = 394,
    ASCIISTRING = 395,
    LSTRING = 396,
    SJISSTRING = 397,
    TSTRING = 398,
    CHAR = 399,
    CONST = 400
  };
#endif
/* Tokens.  */
#define CLASS 258
#define META 259
#define MASTER 260
#define VARIANT 261
#define ENDC 262
#define CLASSDECL 263
#define NEVER_SAVED 264
#define MESSAGE 265
#define STACK 266
#define CARRY 267
#define AX 268
#define CX 269
#define DX 270
#define BP 271
#define AL 272
#define AH 273
#define CL 274
#define CH 275
#define DL 276
#define DH 277
#define BPL 278
#define BPH 279
#define SS 280
#define AXBPCXDX 281
#define AXCXDXBP 282
#define CXDXBPAX 283
#define DXCX 284
#define BPAXDXCX 285
#define MULTIPLEAX 286
#define ALIAS 287
#define PROTOTYPE 288
#define RESERVE_MESSAGES 289
#define EXPORT_MESSAGES 290
#define IMPORT_MESSAGE 291
#define SET_MESSAGE_NUM 292
#define INSTANCE 293
#define COMPOSITE 294
#define LINK 295
#define VIS_MONIKER 296
#define KBD_ACCELERATOR 297
#define DEFAULT 298
#define RELOC 299
#define FPTR 300
#define HPTR 301
#define OPTR 302
#define DEFAULT_MODEL 303
#define METHOD 304
#define FAR 305
#define NEAR 306
#define BASED 307
#define CALL 308
#define CALL_SUPER 309
#define SEND 310
#define RECORD 311
#define DISPATCH 312
#define DISPATCHCALL 313
#define FORCE_QUEUE 314
#define RETURN_ERROR 315
#define CHECK_DUPLICATE 316
#define NO_FREE 317
#define CHECK_LAST_ONLY 318
#define REPLACE 319
#define INSERT_AT_FRONT 320
#define CAN_DISCARD_IF_DESPARATE 321
#define NULL_TOKEN 322
#define PARENT 323
#define CHILDREN 324
#define LOCALIZE 325
#define COMPILER 326
#define HIGHC 327
#define MSC 328
#define START 329
#define DATA 330
#define NOT_LMEM 331
#define NOT_DETACHABLE 332
#define END 333
#define HEADER 334
#define CHUNK 335
#define CHUNK_ARRAY 336
#define ELEMENT_ARRAY 337
#define OBJECT 338
#define SPECIFIC_UI 339
#define KBD_PATH 340
#define RESOURCE_OUTPUT 341
#define VARDATA 342
#define VARDATA_ALIAS 343
#define IGNORE_DIRTY 344
#define DEFLIB 345
#define ENDLIB 346
#define EXTERN 347
#define GCN_LIST 348
#define PROTOMINOR 349
#define PROTORESET 350
#define OPTIMIZE 351
#define NORELOC 352
#define USES 353
#define NOT 354
#define FIRSTSYM 355
#define CLASS_SYM 356
#define OBJECT_SYM 357
#define MSG_SYM 358
#define EXPORT_SYM 359
#define RESOURCE_SYM 360
#define CHUNK_SYM 361
#define VIS_MONIKER_CHUNK_SYM 362
#define VARDATA_SYM 363
#define PROTOMINOR_SYM 364
#define REG_INSTANCE_SYM 365
#define COMPOSITE_SYM 366
#define LINK_SYM 367
#define VIS_MONIKER_SYM 368
#define VARIANT_PTR_SYM 369
#define KBD_ACCELERATOR_SYM 370
#define OPTR_SYM 371
#define CHUNK_INST_SYM 372
#define LIST_SYM 373
#define GSTRING_SYM 374
#define ATTRIBUTES_SYM 375
#define COLOR_SYM 376
#define SIZE_SYM 377
#define ASPECT_RATIO_SYM 378
#define CACHED_SIZE_SYM 379
#define SIZE_COMP_SYM 380
#define COLOR_COMP_SYM 381
#define ASPECT_RATIO_COMP_SYM 382
#define STYLE_SYM 383
#define STYLE_COMP_SYM 384
#define KBD_SYM 385
#define KBD_MODIFIER_SYM 386
#define GCN_LIST_SYM 387
#define GCN_LIST_OF_LISTS_SYM 388
#define LASTSYM 389
#define SPECIAL_DEBUG_TOKEN 390
#define SPECIAL_UNDEBUG_TOKEN 391
#define IDENT 392
#define STRING 393
#define FAKESTRING 394
#define ASCIISTRING 395
#define LSTRING 396
#define SJISSTRING 397
#define TSTRING 398
#define CHAR 399
#define CONST 400

/* Value type.  */
#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED

union YYSTYPE
{


    char	*string;
    char	ch;
    int		num;
    Symbol	*sym;
    Method  	*meth;
    MessageParam	*param;
    SymbolListEntry	*sle;
    TypeDeclString      *tdecl;
    ObjDest		*od;
    SentMessage		*sm;
    MsgInvocType	mit;


};

typedef union YYSTYPE YYSTYPE;
# define YYSTYPE_IS_TRIVIAL 1
# define YYSTYPE_IS_DECLARED 1
#endif


extern YYSTYPE yylval;

int yyparse (void);

#endif /* !YY_YY_PARSE_H_INCLUDED  */
