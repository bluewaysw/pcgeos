typedef struct {
    optr tableArray ;
    optr cellArray ;
    word numCells ;
    dword deltaX ;
    dword deltaY ;
} T_shiftInfo ;

typedef struct {
    dword min ;
    dword max ;
    dword proportion ;
    dword percent ;
    dword pixel ;
} T_columnSizing ;

/* T_rowSizing structures are used to keep track of how far down a */
/* cell is on a column (number of rows and pixel height) */
typedef struct {
    word cellIndex ;        /* Cell this row cell started at */
    word rowEnd ;           /* What row number it ends at (for row spanning) */
    sdword minHeight ;      /* Minimum height of this cell */
    sdword RS_realHeight ;     /* Height actually being used (to calculate slack height) */
    dword y ;               /* Y position row started at */
} T_rowSizing ;

#define BOUNDARY_EDGE_LEFT  0
#define BOUNDARY_EDGE_RIGHT 1

typedef struct {
    word BE_width ;         /* Side that the boundary encompases */
    dword BE_height ;      /* Remaining pixels from the top to end boundary */
} T_boundaryEdge ;

#define MAX_BOUNDARIES_PER_CELL  5

typedef struct {
    T_boundaryEdge BESS_edgeArray[MAX_BOUNDARIES_PER_CELL] ;
    word BESS_count ;
} T_boundaryEdgeStackSide ;

typedef struct {
    T_boundaryEdgeStackSide BES_sides[2] ;
} T_boundaryEdgeStack ;

void IEdgeAdd(
         T_boundaryEdgeStack *p_edges,
         dword height,
         word width,
         HTMLAlignment align) ;
void IEdgeTrim(
         T_boundaryEdgeStack *p_edges,
         dword height) ;
word IEdgeGetTopLeftAndRight(
         T_boundaryEdgeStack *p_edges,
         word fullWidth,
         word *p_left) ;
Boolean IEdgeCreatePathInRegion(
         T_boundaryEdgeStack *p_edges,
         VMFileHandle file,
         T_regionArrayHandle regArray,
         word regionIndex,
         word fullWidth) ;
dword IEdgeGetRemainingHeight(T_boundaryEdgeStack *p_edges) ;
dword IEdgesSkip(T_boundaryEdgeStack *p_edges, byte breakType) ;


Boolean CalculateCellArrayLongestLines(
               T_regionArrayHandle regArray,
               optr cellArray,
               optr oself,
               word firstCell,
               word lastCell) ;

typedef struct {
    word MMTF_hardMinArray[TABLE_MAX_USED_COLUMNS] ;
    word MMTF_min[TABLE_MAX_USED_COLUMNS] ;
    word MMTF_max[TABLE_MAX_USED_COLUMNS] ;
    word MMTF_percent[TABLE_MAX_USED_COLUMNS] ;
    T_columnIndex MMTF_indexArray[TABLE_MAX_COLUMNS] ;
    byte MMTF_spanUsed[TABLE_MAX_COLUMNS+1] ;
} T_minMaxTableFrame ;

typedef struct {
    MemHandle MMS_self ;
    word MMS_used ;
    T_minMaxTableFrame MMS_frames[HTML_MAXTABLE] ;
} T_minMaxStack ;

T_minMaxStack *MinMaxStackCreate(void) ;
void MinMaxStackDestroy(T_minMaxStack *p_stack) ;

word ICalculateTableMinMax(
                T_minMaxStack *p_stack,
                HTMLTextInstance *pself,
                word tableIndex,
                word *p_min,
                word *p_max,
                word *p_hardMin) ;
word IResolveCellLayout(
         optr oself,
         word cellIndex,
         word availableWidth,
         dword x,
         dword y,
         word cellpadding,
         dword *p_height,
         Boolean *p_didCalc) ;
word ICalculateCellMinMax(
    T_minMaxStack *p_stack,
    HTMLTextInstance *pself,
    word cellIndex,
    word cellLimit,
    word *p_min,
    word *p_max,
    word *p_hardMin,
    word *p_percent);

word IResolveTableLayout(
         optr oself,
         word tableIndex,
         word availableWidth,
         dword x,
         dword y,
         T_boundaryEdgeStack *p_edges,
         dword *p_height) ;
void IAdjustRegions(optr oself, HTMLTextInstance *pself, word firstCell, word lastCell) ;
void ICalculateRegionBoundries(optr oself, RectDWord *p_rect) ;

word ICellGetNextIndex(HTMLTextInstance *pself, word cellIndex) ;

void ICellsShiftHorizontally(
         T_regionArrayHandle regionArray,
         word firstCell,
         word lastCell,
         sdword amount) ;

void ICollectSizeForCell(
               MemHandle spreadState,
               HTMLcellData *p_cell,
               word tableColumns) ;

word ICellDetermineFirstRegion(T_cellArrayHandle cellArray, word cellNum) ;

Boolean EmptyTopRegion(
            VisLargeTextRegionArrayElement *p_region,
            optr textObj) ;

void MarkTableLayoutDirty(HTMLTextInstance *pself, word tableIndex) ;

#ifdef COMPILE_OPTION_OUTPUT_LAYOUT_LOG
void ECDumpHTMLText(HTMLTextInstance *pself, char *comment) ;
FileHandle OpenLayoutLog(void) ;
void CloseLayoutLog(FileHandle file) ;
void ECDumpSizesArray(char *comment, word num, T_columnSizing *p_sizing, word id) ;
#else
#define ECDumpHTMLText(pself, comment)
#define ECDumpSizesArray(comment, num, p_sizing, id)
#endif

void fprintf(FileHandle file, char *fmt, ...) ;

word ICalculateViewSize(optr view, dword *p_viewHeight) ;

word ITranslateTablePosition(
          word tableIndex,
          T_shiftInfo *p_info) ;


/* ------------------------------------------------------------------------
                           LAYOUT STACK INTERNALS
   ------------------------------------------------------------------------ */
#define HTML_LAYOUT_MAX_LAYOUT_LEVELS      (HTML_MAXTABLE+1)

typedef word LayoutLevelCellFlags ;
#define LAYOUT_LEVEL_CELL_FLAG_DID_PERFORM_REGION_CALCULATION      0x0001
#define LAYOUT_LEVEL_CELL_FLAG_PROCESSING_TABLE                    0x0002

typedef struct {
    /* Cell index that we start this cell grouping with */
    word                          LLC_originalCellIndex ;

    /* Current cell index */
    word                          LLC_cellIndex ;

    /* Flags noting any special boolean conditions */
    LayoutLevelCellFlags          LLC_flags ;

    /* Location we are currently while formatting this cell group */
    dword                         LLC_x ;
    dword                         LLC_y ;

    /* Currently locked cell (which stayes locked between updates) */
//    HTMLcellData                * LLC_cell ;

    /* Edge stack to determine shape of region (left/right limits) */
    T_boundaryEdgeStack           LLC_edges ;

    /* Calculated total height thus far */
    dword                         LLC_totalHeight ;

    /* Location that Y started */
    dword                         LLC_startY ;

    /* How much width this cell group is given (if fully taken) */
    word                          LLC_availableWidth ;

    /* ??? Do I need this one? */
    word                          LLC_cellpadding ;
    word                          LLC_firstTableLevel ;
} T_layoutLevelCell ;

typedef word LayoutLevelTableFlags ;
#define LAYOUT_LEVEL_TABLE_FLAG_NOT_FIRST         0x0001
#define LAYOUT_LEVEL_TABLE_FLAG_DID_CALCULATION   0x0002
#define LAYOUT_LEVEL_TABLE_PROCESSING_CELL        0x0004

typedef struct {
    /* Current table index being processed */
    word                          LLT_tableIndex ;

    /* Various boolean flags for this table state */
    LayoutLevelTableFlags         LLT_flags ;

    /* Current X, Y position of left of table row */
    dword                         LLT_x ;
    dword                         LLT_y ;
    
    /* Current cell within table being processed */
    word                          LLT_cellIndex ;

    /* Array of column left points and their widths */
    T_columnIndex                 LLT_indexArray[TABLE_MAX_COLUMNS] ;
    dword                         LLT_columnLeftArray[TABLE_MAX_USED_COLUMNS] ;
    word                          LLT_columnWidthArray[TABLE_MAX_USED_COLUMNS] ;

    /* Current row and column being processed */
    word                          LLT_row ;
    word                          LLT_column ;

    /* Calculated table width */
    word                          LLT_wantedWidth ;

    /* Actual table width being used */
    word                          LLT_availableWidth ;

    /* What we original were given for the table width */
    word                          LLT_originalWidth ;

    /* Top Y position of table (used to determine final height) */
    dword                         LLT_startY ;

    /* Offset from left edge for centering or aligning of table */
    sword                         LLT_tableOffset ;

    /* Amount space taken to draw lines between cells (0 or 1) */
    word                          LLT_innerBorder ;

    /* Tracked information about the row spans of columns */
    T_rowSizing                   LLT_sizingArray[TABLE_MAX_USED_COLUMNS] ;

    /* Final calculated height and */
    dword                         LLT_height ;
    dword                         LLT_realHeight ;
    word                          LLT_width ;
    word                          LLT_lastX ;
} T_layoutLevelTable ;

typedef byte T_layoutStackElementType ;

#define LAYOUT_STACK_ELEMENT_TYPE_CELL       0
#define LAYOUT_STACK_ELEMENT_TYPE_TABLE      1

typedef struct {
    /* Memory block containing T_layoutLevelTable struct */
    MemHandle           block ;

    /* Which T_layoutLevelTable structure in the block */
    word                index ;

    /* Direct pointer when locked into memory, else NULL */
    T_layoutLevelTable *p_level ;
} T_tableLayoutStackReference ;

#define LAYOUT_STACK_TABLE_LEVELS_PER_BLOCK  4

typedef struct {
    /* A simple array stack of cell layout structures */
    T_layoutLevelCell LS_cellLayoutStack[HTML_LAYOUT_MAX_LAYOUT_LEVELS] ;
    word LS_stackCellDepth ;

    /* More complex array of table layout structures (structures are grouped into blocks) */
    T_tableLayoutStackReference LS_tableLayoutStackRef[HTML_LAYOUT_MAX_LAYOUT_LEVELS] ;

    word LS_numActiveReferences ;
    word LS_stackTableDepth ;
    
    /* Type of action pending */
    T_layoutStackElementType LS_type ;

    /* Next cell to act upon */
    word LS_nextCellIndex ;

    /* Cell, table, and region array */
    T_cellArrayHandle LS_cellArray ;
    T_tableArrayHandle LS_tableArray ;
    T_regionArrayHandle LS_regionArray ;

    /* Number of cells and regions currently */
    word LS_numCells ;
    word LS_numRegions ;

    /* What width we are calculating for */
    word LS_viewWidth ;

    /* How far we can go before we have to add a scroll bar and recalc */
    dword LS_maxViewHeight ;

    /* Flag nothing if we have gone past LS_maxViewHeight */
    Boolean LS_pastHeight ;

    /* Current HTMLTextClass object we're processing */
    optr LS_textObj ;

    /* What file is all this junk stored in */
    VMFileHandle LS_vmFile ;

    /* Final flag to note when all processing is done. */
    Boolean LS_done ;

    /* Master cell currently being processed */
    /* When a master cell is completed, the value here is */
    /* passed to LS_lastMasterCell and LS_undoCell updated */
    word LS_currentMasterCell ;

    /* Last completed master cell */
    /* LS_undoCell corresponds to this cell. */
    word LS_lastMasterCell ;

    /* Cell layout if we need to undo a step. */
    /* We then move back to LS_lastMasterCell */
    T_layoutLevelCell LS_undoCell ;

    /* Flag to tell if we have something has changed */
    Boolean LS_layoutHasChanged ;

    word LS_lastSeekedRegion ;  /* 0xFFFF if none */
    dword LS_seekedChar ;
    dword LS_seekedLine ;
    Boolean LS_needCompleteRedraw ;

    /* Flag telling if the current master cell being formatted had a change */
    /* from finding an image of unknown size. */
    Boolean LS_currentMasterCellGotImage ;
    word LS_currentCell ;
    Boolean LS_oneMorePass ;

    /* MemHandle to this data block */
    MemHandle LS_self ;
} T_layoutStack ;

MemHandle LayoutStackAlloc(void) ;
void LayoutStackFree(MemHandle layoutStack) ;
T_layoutStack *LayoutStackLock(MemHandle layoutStack) ;
void LayoutStackUnlock(T_layoutStack *p_stack) ;
T_layoutLevelTable *LayoutStackTableLevelAccess(T_layoutStack *p_stack, word level) ;

void ILayoutCellStart(
         T_layoutStack *p_stack,
         word availableWidth,
         dword x,
         dword y,
         word cellpadding) ;

void IHideCells(T_layoutStack *p_stack, word startCell, word endCell) ;

/*
 * Macros to access table/cell arrays regardless of whether they are huge
 * or not. Since this decision is made in the local OPTIONS.GOH file at
 * compile time, the actual format is not available to outside applications,
 * so table and cell arrays must be considered "opaque" types.
 */

/* To use this header, you must decide if you are using cells in a huge */
/* array or in a chunk array.  There can only be one way. */
#if COMPILE_OPTION_HUGE_ARRAY_CELLS
#define CAH_file(cah)  ((VMFileHandle)(((word *)&(cah))[1]))
#define CAH_block(cah) ((VMBlockHandle)(((word *)&(cah))[0]))
#define CellArrayStartAccess(cah)  /* Do nothing */
#define CellArrayEndAccess(cah)  /* Do nothing */
#define CellLock(cah, index, pp_cell, p_size) HAL_EC(\
  HugeArrayLock(CAH_file(cah), CAH_block(cah), index, ((void **)(pp_cell)), (p_size)))
#define CellDirty(p_cell)      HugeArrayDirty(p_cell)
#define CellUnlock(p_cell)     HugeArrayUnlock(p_cell)
#define CellArrayGetCount(cah) HugeArrayGetCount(CAH_file(cah), CAH_block(cah))
#define CellArrayDestroy(cah)       HugeArrayDestroy(CAH_file(cah), CAH_block(cah))
#else
#define CAH_mem(cah)           OptrToHandle(cah)
#define CAH_chunk(cah)         OptrToChunk(cah)
#define CellArrayStartAccess(cah)  MemLock(CAH_mem(cah))
#define CellArrayEndAccess(cah)    MemUnlock(CAH_mem(cah))
#define CellLock(cah, index, pp_cell, p_size) \
            (*pp_cell) = ChunkArrayElementToPtr(cah, index, p_size)
#define CellDirty(p_cell)      /* Do nothing */
#define CellUnlock(p_cell)     /* Do nothing */
#define CellArrayGetCount(cah) ChunkArrayGetCount(cah)
#define CellArrayDestroy(cah)       MemFree(CAH_mem(cah))
#endif

/* To use this header, you must decide if you are using tables in a huge */
/* array or in a chunk array.  There can only be one way. */
#if COMPILE_OPTION_HUGE_ARRAY_TABLES
#define TAH_file(tah)  ((VMFileHandle)(((word *)&(tah))[1]))
#define TAH_block(tah) ((VMBlockHandle)(((word *)&(tah))[0]))
#define TableArrayStartAccess(tah)  /* Do nothing */
#define TableArrayEndAccess(tah)  /* Do nothing */
void ITableLock(void) ;
#define TableLock(tah, index, pp_table, p_size) HAL_EC(\
  HugeArrayLock(TAH_file(tah), TAH_block(tah), index, ((void **)(pp_table)), (p_size)))
#define TableDirty(p_table)      HugeArrayDirty(p_table)
#define TableUnlock(p_table)     HugeArrayUnlock(p_table)
#define TableArrayGetCount(tah) HugeArrayGetCount(TAH_file(tah), TAH_block(tah))
#define TableArrayDestroy(tah)       HugeArrayDestroy(TAH_file(tah), TAH_block(tah))
#else
#define TAH_mem(tah)           OptrToHandle(tah)
#define TAH_chunk(tah)         OptrToChunk(tah)
#define TableArrayStartAccess(tah)  MemLock(TAH_mem(tah))
#define TableArrayEndAccess(tah)    MemUnlock(TAH_mem(tah))
#define TableLock(tah, index, pp_table, p_size) \
            (*pp_table) = ChunkArrayElementToPtr(tah, index, &size)
#define TableDirty(p_table)      /* Do nothing */
#define TableUnlock(p_table)     /* Do nothing */
#define TableArrayGetCount(tah) ChunkArrayGetCount(tah)
#define TableArrayDestroy(tah)       MemFree(TAH_mem(tah))
#endif

#if COMPILE_OPTION_PROFILING_ON
void ProfPointRoutine(char *str) ;
#define ProfPoint(str)  ProfPointRoutine(str)
#else
#define ProfPoint(str)  
#endif

void PrepareCellNextIndices(
        T_cellArrayHandle cellArray, 
        T_tableArrayHandle tableArray) ;

/* Redo a complete region and return its height as calculated */
word IRegionRepositionResizeAndReflow(
         T_layoutStack *p_stack,
         word regionNum,
         sdword x,
         sdword y,
         word width,
         Boolean forcedRecalc,
         HTMLcellData *p_cell,
         Boolean *didCall) ;

word ICalculateColumnStarts(
               MemHandle spreadState,
               T_layoutLevelTable *p_level,
               HTMLtableData *p_table) ;

dword ICalculateRowHeights(
          T_cellArrayHandle cellArray,
          T_layoutLevelTable *p_level,
          word numColumns,
          word row,
          word cellspacing,
          dword minHeight) ;

word ICollectRowInfo(
         T_layoutLevelTable *p_level,
         HTMLtableData *p_table,
         HTMLcellData *p_cell,
         word cellpadding) ;

word RegionGetPathTopBound(
         VMFileHandle file,
         DBGroupAndItem path) ;
