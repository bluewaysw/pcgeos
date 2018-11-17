/***********************************************************************
 *
 * FILE:          _impex.h
 *
 * AUTHOR:        Marcus Gr”ber
 *
 ***********************************************************************/

struct my_ImpEx_block {                 /*** outdated ***/
  word          IEB_SubFormat;
  MemHandle     IEB_OptionsBlock;
  FileHandle    IEB_SourceFile;
  char          IEB_SourcePath[234];
  DiskHandle    IEB_diskHandle;
  FileHandle    IEB_TransferFile;
};

struct my_ImportFrame {
  word          IF_formatNumber;
  MemHandle     IF_importOptions;
  FileHandle    IF_sourceFile;
  FileLongName  IF_sourceFileName;
  PathName      IF_sourcePathName;
  DiskHandle    IF_sourcePathDisk;
  VMFileHandle  IF_transferVMFile;
};

struct my_ExportFrame {
  word          EF_formatNumber;
  MemHandle     EF_exportOptions;
  FileHandle    EF_outputFile;
  FileLongName  EF_outputFileName;
  PathName      EF_outputPathName;
  DiskHandle    EF_outputPathDisk;
  VMFileHandle  EF_transferVMFile;
  VMChain       EF_transferVMChain;
  ManufacturerID        EF_manufacturerID;   
  ClipboardItemFormat   EF_clipboardFormat;
};

#define IMPEX_EP_TransGetImportUI 0
#define IMPEX_EP_TransGetExportUI 1
#define IMPEX_EP_TransInitImportUI 2
#define IMPEX_EP_TransInitExportUI 3
#define IMPEX_EP_TransGetImportOptions 4
#define IMPEX_EP_TransGetExportOptions 5
#define IMPEX_EP_TransImport 6
#define IMPEX_EP_TransExport 7
#define IMPEX_EP_TransGetFormat 8

