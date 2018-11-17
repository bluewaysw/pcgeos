cvtpcx -f -G -t -x1 -y1 -m13 -nMail ND16PCX\ge000-8.pcx
cvtpcx -f -G -t -z -x49 -y0 -dTM,TCGA -w48 -h30 -m13 -nTinyMail ND16PCX\ge000-8.pcx
cvtpcx -f -G -t -z -g -x49 -y0 -dTM,TCGA -m13 -nAttach ND16PCX\ATTACH.PCX

REM New Message DB
cvtpcx -f -G -t -x0 -y0 -w40 -h20 -m13 -ncomposeSign ND16PCX\ge013-8.pcx
cvtpcx -f -G -t -x0 -y0 -w40 -h20 -m13 -ncomposeAttach ND16PCX\ge014-8.pcx
cvtpcx -f -G -t -x0 -y0 -w40 -h20 -m13 -ncomposeSend ND16PCX\ge015-8.pcx

REM Main Toolbar
cvtpcx -f -G -t -x0 -y0 -w34 -h19 -m13 -nsendReceiveTool ND16PCX\ge001-8.pcx
cvtpcx -f -G -t -x0 -y0 -w28 -h19 -m13 -ncreateNewMessageTool ND16PCX\ge002-8.pcx
cvtpcx -f -G -t -x0 -y0 -w25 -h19 -m13 -nreadMessageTool ND16PCX\ge003-8.pcx
cvtpcx -f -G -t -x0 -y0 -w25 -h19 -m13 -neditMessageTool ND16PCX\ge003-8.pcx
cvtpcx -f -G -t -x0 -y0 -w44 -h19 -m13 -nmoveMessageTool ND16PCX\ge004-8.pcx
cvtpcx -f -G -t -x0 -y0 -w44 -h19 -m13 -nthrowAwayTool ND16PCX\ge005-8.pcx
cvtpcx -f -G -t -x0 -y0 -w44 -h19 -m13 -nrecoverTool ND16PCX\ge006-8.pcx

REM read message toolbar
cvtpcx -f -G -t -x0 -y0 -w40 -h20 -m13 -naddressTool ND16PCX\ge016-8.pcx
cvtpcx -f -G -t -x0 -y0 -w40 -h20 -m13 -nreplyTool ND16PCX\ge017-8.pcx
cvtpcx -f -G -t -x0 -y0 -w40 -h20 -m13 -nreplyAllTool ND16PCX\ge018-8.pcx
cvtpcx -f -G -t -x0 -y0 -w40 -h20 -m13 -nforwardTool ND16PCX\ge019-8.pcx
cvtpcx -f -G -t -x0 -y0 -w40 -h20 -m13 -nprintTool ND16PCX\ge020-8.pcx
cvtpcx -f -G -t -x0 -y0 -w40 -h20 -m13 -npreviousTool ND16PCX\ge021-8.pcx
cvtpcx -f -G -t -x0 -y0 -w40 -h20 -m13 -nnextTool ND16PCX\ge022-8.pcx

REM folder icons
cvtpcx -f -G -g -t -x42 -y1 -w20 -h16 -m13 -ndraftsFolder ND16PCX\ge007-8.pcx
cvtpcx -f -G -g -t -x42 -y1 -w20 -h16 -m13 -ninboxFolder ND16PCX\ge008-8.pcx
cvtpcx -f -G -g -t -x42 -y1 -w20 -h16 -m13 -noutboxFolder ND16PCX\ge009-8.pcx
cvtpcx -f -G -g -t -x42 -y1 -w20 -h16 -m13 -nsentFolder ND16PCX\ge010-8.pcx
cvtpcx -f -G -g -t -x42 -y1 -w20 -h16 -m13 -ntrashFolder ND16PCX\ge011-8.pcx
cvtpcx -f -G -g -t -x42 -y1 -w20 -h16 -m13 -ngenericFolder ND16PCX\ge012-8.pcx

REM message icons
cvtpcx -f -G -g -t -x0 -y0 -w25 -h12 -m13 -nunreadNoAttach ND16PCX\ge030-8.pcx
cvtpcx -f -G -g -t -x0 -y0 -w25 -h12 -m13 -nreadNoAttach ND16PCX\ge031-8.pcx
cvtpcx -f -G -g -t -x0 -y0 -w25 -h12 -m13 -nunreadAttach ND16PCX\ge032-8.pcx
cvtpcx -f -G -g -t -x0 -y0 -w25 -h12 -m13 -nreadAttach ND16PCX\ge033-8.pcx

REM CUI icons
cvtpcx -f -G -g -t -x1 -y1 -w40 -h20 -m13 -nCUIDraftsFolder ND16PCX\ge007-8.pcx
cvtpcx -f -G -g -t -x1 -y1 -w40 -h20 -m13 -nCUIInboxFolder ND16PCX\ge008-8.pcx
cvtpcx -f -G -g -t -x1 -y1 -w40 -h20 -m13 -nCUIOutboxFolder ND16PCX\ge009-8.pcx
cvtpcx -f -G -g -t -x1 -y1 -w40 -h20 -m13 -nCUISentFolder ND16PCX\ge010-8.pcx
cvtpcx -f -G -g -t -x1 -y1 -w40 -h20 -m13 -nCUITrashFolder ND16PCX\ge011-8.pcx

