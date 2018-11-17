/***********************************************************************
 *
 *      Copyright (c) GeoWorks 1992 -- All Rights Reserved
 *
 * PROJECT:       PCGEOS
 * MODULE:        ffdExtrn.h
 * FILE:          ffdExtrn.h
 *
 * AUTHOR:        Jeremy Dashe: Aug 18, 1992
 *
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      8/18/92   jeremy    Initial version
 *
 * DESCRIPTION:
 *      This file contains external declarations of globally-used
 *      database functions in the flat file database library.
 *
 *
 *      $Id: ffDExterns.h,v 1.1 97/04/04 18:03:05 newdeal Exp $
 *
 ***********************************************************************/
#ifndef _FFDEXTERNS_H_
#define _FFDEXTERNS_H_

/******************************************************************************
 ********************* Functions defined in ffDatabase.goc ********************
 ******************************************************************************/
extern void FFDEvalComputedField(optr oself, FieldID colNum);

extern void FFDFieldGrabTarget(optr oself, FieldListID fieldIndex);

extern void FFDFieldGrabTargetAndForceOnScreen(optr oself, FieldID columnNum);

extern void FFDForceFieldOnScreen(optr oself, FieldID columnNum);

extern void FFDGrabTargetOnFirstField(optr oself);

extern FieldListID DeleteAbsoluteFieldFromList(FieldID list[],
					       FieldID index,
					       FieldListID numFields);


extern FieldListID FindFieldListElement(FieldID list[],
					FieldListID colNum,
					FieldListID numFields);


extern FieldID DeleteFieldFromList(FieldID list[],
				   FieldListID index,
				   FieldListID numFields);

extern void FFDLoadFormulaCell(optr oself, FieldID colNum, CellFormula *dest);

extern MemHandle _pascal FFDGetColumnFieldName(optr oself, word columnNum,
				       TCHAR *textBuffer);

extern byte FFDHowManyInList(FieldListQuery type,
			     FlatFileDatabaseInstance *pself);

extern MemHandle StoreFieldPropertiesInBlock(byte colNum, optr oself);

extern void _pascal FFDSendRCPNotification
		     (optr oself, FFRecordControlStatusMessageBlock *ffrcpsmb);

extern Boolean FFDRCGotoRecord (optr oself, FFRecordControlRequest rcpRequest,
				word newRecord, Boolean moveGrObjBody,
				CommitRecordType commitRecordType,
				EditRecordType editRecordType,
				Boolean fieldGrabTarget);

extern void FFDCalculateBoundsForActiveRecordAndSetGrObjBody(optr oself,
						optr grObjBody,
						word newRecord,
						word numHorizontalRecords,
						word numVerticalRecords);
extern void FFDCalculateBoundsForActiveRecord(optr oself,
						optr grObjBody,
						word newRecord,
						word numHorizontalRecords,
						word numVerticalRecords,
						RectDWord *layoutBounds);

extern FieldListID FFDAddFieldNameToLayoutListAndTellControllers(FieldID colNum,
							  optr oself);

extern FieldDataType FFDGetDataTypeAndFlags(optr oself,
					    FieldID fieldNum,
					    FieldDataTypesFlags *flags);

extern void FFDRemoveDependencies(optr oself, word rowNum, FieldID colNum);



/******************************************************************************
 ****************** Functions defined in ffDatabaseCreate.goc *****************
 ******************************************************************************/

extern void SendLayoutListNotification(optr oself,
				       FieldListID field,
				       FFFieldListChangeStatus action,
				       word howMany);
extern void SendDatabaseListNotification(optr oself,
					 FieldID field,
					 FFFieldListChangeStatus action,
					 word howMany);
extern void SendWholeListNotification(optr oself,
				      FieldID field,
				      FFFieldListChangeStatus action,
				      word howMany);
extern void SendListNotifications(FieldListQuery whichList,
				  optr oself,
				  FieldID field,
				  FFFieldListChangeStatus action,
				  word howMany);

extern FieldID FFDGetFreeColumnNum(byte *columnsTaken);

extern word StoreNewFieldName(TCHAR *textPtr,
			      optr databaseObject,
			      FieldID *newColNum,
			      FFFieldCreationResult *errorValue);

extern byte InsertSortedFieldArray(MemHandle _pascal (*getnamefunc)(optr, word, TCHAR *),
				   byte *sortedColumns, byte colNum,
				   byte numFields, TCHAR *newFieldName,
				   optr databaseObject);

extern int FFDGetColumnNumForExport(FlatFileDatabaseInstance *pself,
				    int i);

extern void CreateDataBlockAndSendNotification(optr oself);

extern void FlushMapControl(optr oself);

extern void FFDGetPageBounds(optr oself, PageSizeReport *psr);

extern void FFDSetSingleRecordBounds(optr oself, LayoutSize bounds);

extern optr FFDGetCurrentLayoutGrObjBody(optr oself, LayoutType whichLayout);

extern void FFDDeleteFieldFromLayout(optr oself, byte colNum, byte layoutNum);

extern void FFDDeleteChunkElementFromLayout(optr oself, FieldID colNum,
					    byte layoutNum);

extern void FFDSetDependencies(optr oself, FieldID colNum);

extern void FFDChangeFieldNameInAllLayouts(optr oself,
					   FieldID colNum,
					   TCHAR *newName);

/******************************************************************************
 ***************** Functions defined in ffDatabaseLayout.goc ******************
 ******************************************************************************/

extern MemHandle _pascal FFDGetLayoutName (optr oself, word layoutNum,
				   TCHAR *textBuffer);

extern optr GetRecordLayoutBoundaryOptr(optr oself, byte layoutNum);

extern void FFDGetPageLayoutBoundaryStartingOffset(optr oself,
					sdword *boundaryXCoord,
					sdword *boundaryYCoord);

extern void FFDGetSingleRecordBounds(optr oself, LayoutSize *bounds);

extern optr FFDGetGrObjBodyForLayout(optr oself, byte layoutNum,
				     LayoutType layoutType);

extern void FFDResizePageIfNecessary(optr oself, LayoutSize bounds);

extern void FFDSetMultiRecordGrObjBodyToPageSize(optr oself);

/******************************************************************************
 ***************** Functions defined in ffDatabaseMeta.goc ********************
 ******************************************************************************/
extern void FFDDrawMultiRecordDataEntryGrid(optr oself, word drawFlags,
					    GStateHandle gstate,
					    LayoutSize recordLayout,
					    optr recordLayoutGrObjBody,
					    word numHorizontalRecords,
					    word numVerticalRecords,
					    word startRecord);

extern void FFDDrawRecordLayoutBoundaryForMultiRecord(GStateHandle gstate,
						    word drawFlags,
						    optr recordLayoutGrObjBody);

extern void FFDGetMultiRecordBounds(optr oself, LayoutSize *bounds);

extern word FFDCalculateNumRecordsPerPage(optr oself,
					  word *numHorizontalRecords,
					  word *numVerticalRecords);
void
SwitchLayoutModeIfNecessary(optr oself, word layoutNum, LayoutType layoutType);


/******************************************************************************
 ****************** Functions defined in ffDatabaseParse.goc ******************
 ******************************************************************************/

extern void FFD_ParserFormatExpression(MemHandle tokenStreamHandle,
				       TCHAR *textBuffer,
				       optr ffdOptr);

extern Boolean FFD_ParserParseString(MemHandle stringHandle,
			       MemHandle tokenBufferHandle,
			       word tokenBufferSize,
			       optr ffdOptr,
			       word *numTokens,
			       VisTextRange *errorOffsetPtr);

extern int FFDEvaluateDefaultExpression(optr oself, FieldID fieldNum,
					byte *resultBuffer);

extern int FFD_EvaluateExpression(byte *tokenStream,
				  byte *resultBuffer,
				  word row,
				  optr ffdOptr);

extern void _pascal FFDParseLibraryCallback(C_CallbackStruct *callbackStruct);


/******************************************************************************
 ***************** Functions defined in ffDatabaseSort.goc ********************
 ******************************************************************************/
extern sbyte _pascal FFDGetFieldColumnExtents
			(FlatFileDatabaseInstance *pself,
			 byte *startColumn,
			 byte *endColumn);


/******************************************************************************
 ***************** Functions defined in ffDatabaseSubset.goc ******************
 ******************************************************************************/

extern Boolean FFDSubsetShowOnlyMarkedRecords(optr oself);

extern Boolean FFDGetRecordMarkStatus(FlatFileDatabaseInstance *pself,
				      word recordIndex);

extern void FFDSetRecordMarkStatus(FlatFileDatabaseInstance *pself,
				   word recordIndex,
				   Boolean mark);

extern word FFDGetFirstMarkedRecord(optr oself);

extern word FFDGetNumberOfMarkedRecords(optr oself);

extern word FFDGetNextMarkedRecord(optr oself, word curRecord);

extern word FFDGetPreviousMarkedRecord(optr oself, word curRecord);

extern word FFDGetNthMarkedRecord(optr oself, word n);

extern word FFDDetermineMarkedPosition(optr oself, word recordNum);

extern SubsetEvalResult FFDSubsetTestExpression(optr oself,
						byte *tokenStream,
						word recordNum);

/******************************************************************************
 ******************* Functions defined in ffDatabaseRCP.goc *******************
 ******************************************************************************/
extern Boolean FFDRCCreateNewRecordForMultiRecDataEntry(optr oself);

extern void FFDRCMoveGrObjBodyForMultiRecDataEntry(optr oself, word newRecord,
						   Boolean *stayOnThisPage);

/******************************************************************************
 ******************* Functions defined in ffDatabaseText.goc *******************
 ******************************************************************************/

extern void FFTRequestPageNumber(optr oself);

#endif  /* _FFDEXTERNS_H_ */
