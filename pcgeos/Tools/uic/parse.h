typedef union {
    char	*string;
    int		num;
    long	fixedNum;
    double	floatNum;
    char	ch;
    Symbol	*sym;
    ObjectField	*field;
    Scope	*scope;
    struct {
	int type;
	ObjectField *def;
    } classData;
    struct {
	int value;
	int maskOut;
	int modifiesDefault;
    } bfData;
    struct {
	ChunkArgs	chData;
	ChunkDataType	chDataType;
    } chData;
    LocalizeInfo	*locInfo;
} YYSTYPE;
#define	STRUCTURE_COMP	258
#define	TYPE_COMP	259
#define	FPTR_COMP	260
#define	BYTE_COMP	261
#define	WORD_COMP	262
#define	DWORD_COMP	263
#define	BIT_FIELD_COMP	264
#define	ENUM_COMP	265
#define	LINK_COMP	266
#define	COMPOSITE_COMP	267
#define	VIS_MONIKER_COMP	268
#define	KBD_ACCELERATOR_COMP	269
#define	HINT_COMP	270
#define	HELP_COMP	271
#define	OPTR_COMP	272
#define	ACTION_COMP	273
#define	ACTIVE_LIST_COMP	274
#define	NPTR_COMP	275
#define	HPTR_COMP	276
#define	VARIANT_PTR	277
#define	GSTRING	278
#define	EXTERN	279
#define	STRUCTURE_COMP_SYM	280
#define	TYPE_COMP_SYM	281
#define	FPTR_COMP_SYM	282
#define	BYTE_COMP_SYM	283
#define	WORD_COMP_SYM	284
#define	DWORD_COMP_SYM	285
#define	BIT_FIELD_COMP_SYM	286
#define	ENUM_COMP_SYM	287
#define	LINK_COMP_SYM	288
#define	COMPOSITE_COMP_SYM	289
#define	VIS_MONIKER_COMP_SYM	290
#define	KBD_ACCELERATOR_COMP_SYM	291
#define	HINT_COMP_SYM	292
#define	HELP_COMP_SYM	293
#define	OPTR_COMP_SYM	294
#define	ACTION_COMP_SYM	295
#define	ACTIVE_LIST_COMP_SYM	296
#define	NPTR_COMP_SYM	297
#define	HPTR_COMP_SYM	298
#define	VARIANT_PTR_SYM	299
#define	BIT_FIELD_SYM	300
#define	ENUM_ELEMENT_SYM	301
#define	ATTRIBUTES_SYM	302
#define	ATTRIBUTES_COMP_SYM	303
#define	COLOR_SYM	304
#define	COLOR_COMP_SYM	305
#define	SIZE_SYM	306
#define	SIZE_COMP_SYM	307
#define	ASPECT_RATIO_SYM	308
#define	ASPECT_RATIO_COMP_SYM	309
#define	CACHED_SIZE_SYM	310
#define	LIST_SYM	311
#define	STYLE_SYM	312
#define	STYLE_COMP_SYM	313
#define	KBD_SYM	314
#define	KBD_MODIFIER_SYM	315
#define	UNKNOWN_DATA_SYM	316
#define	VIS_MONIKER_SYM	317
#define	HINT_LIST_SYM	318
#define	HELP_ENTRY_SYM	319
#define	ACTIVE_LIST_SYM	320
#define	GCN_LIST_SYM	321
#define	GCN_LIST_OF_LISTS_SYM	322
#define	CHUNK_SYM	323
#define	CLASS_SYM	324
#define	HINT_SYM	325
#define	RESOURCE_SYM	326
#define	OBJECT_SYM	327
#define	METHOD_SYM	328
#define	PROCESS_RESOURCE_SYM	329
#define	STRUCTURE_SYM	330
#define	CLASS	331
#define	VIS_MONIKER	332
#define	HINT_LIST	333
#define	HELP_ENTRY	334
#define	ACTIVE_LIST	335
#define	CHUNK	336
#define	STRUCTURE	337
#define	PRINT_MESSAGE	338
#define	ERROR_MESSAGE	339
#define	SPECIFIC_UI	340
#define	KBD_PATH	341
#define	BYTE	342
#define	WORD	343
#define	DWORD	344
#define	META	345
#define	MASTER	346
#define	VARIANT	347
#define	DEFAULT	348
#define	IGNORE_DIRTY	349
#define	PROCESS	350
#define	START	351
#define	END	352
#define	NULL_TOKEN	353
#define	EMPTY	354
#define	DATA	355
#define	STATIC	356
#define	NOT_DETACHABLE	357
#define	VERSION20	358
#define	VARDATA_RELOC	359
#define	RESOURCE_OUTPUT	360
#define	VAR_DATA	361
#define	GCN_LIST	362
#define	LOCALIZE	363
#define	NOT	364
#define	SPECIAL_DEBUG_TOKEN	365
#define	SPECIAL_UNDEBUG_TOKEN	366
#define	IDENT	367
#define	STRING	368
#define	CHAR	369
#define	CONST_FIXED	370
#define	CONST_FLOAT	371


extern YYSTYPE yylval;
