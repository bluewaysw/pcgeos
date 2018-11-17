typedef struct
    {
    PageSetupInfo RTFTD_pageInfo;
    }
RTFTransferData;

/***********************************************************************
 * RTFImport
 *
 * Read an RTF file into a VisText object.
 *
 * Pass: source - file handle of RTF file
 *       dest - optr of large VisText to receive text
 *       data - pointer to data block to be filled in
 *
 * Returns: TransError
 ***********************************************************************/
extern TransError RTFImport (FileHandle source, optr dest,
  RTFTransferData* data);

/***********************************************************************
 * Export
 *
 * Write an RTF file from a VisText object.
 *
 * Pass: source - optr of *large* VisText to receive text
 *       dest - file handle of RTF file
 *       data - pointer to export info data block
 *
 * Returns: TransError
 ***********************************************************************/

extern TransError _export RTFExport (optr source, FileHandle dest,
  RTFTransferData* data);

