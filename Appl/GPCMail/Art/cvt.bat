cvtpcx -f -G -t -x1 -y1 -m1 -nMail pcx\ge000-8.pcx
cvtpcx -f -G -t -z -x49 -y0 -dTM,TCGA -w48 -h30 -m1 -nTinyMail pcx\ge000-8.pcx

REM New Message DB
cvtpcx -f -G -t -x0 -y0 -w40 -h20 -m225 -ncomposeSign pcx\ge013-8.pcx
cvtpcx -f -G -t -x0 -y0 -w40 -h20 -m225 -ncomposeAttach pcx\ge014-8.pcx
cvtpcx -f -G -t -x0 -y0 -w40 -h20 -m225 -ncomposeSend pcx\ge015-8.pcx

REM Main Toolbar
cvtpcx -f -G -t -x0 -y0 -w34 -h19 -m225 -nsendReceiveTool pcx\ge001-8.pcx
cvtpcx -f -G -t -x0 -y0 -w28 -h19 -m225 -ncreateNewMessageTool pcx\ge002-8.pcx
cvtpcx -f -G -t -x0 -y0 -w25 -h19 -m225 -nreadMessageTool pcx\ge003-8.pcx
cvtpcx -f -G -t -x0 -y0 -w25 -h19 -m225 -neditMessageTool pcx\ge003-8.pcx
cvtpcx -f -G -t -x0 -y0 -w44 -h19 -m225 -nmoveMessageTool pcx\ge004-8.pcx
REM cvtpcx -f -G -t -x0 -y0 -w44 -h19 -m225 -nthrowAwayTool pcx\ge005-8.pcx
cvtpcx -f -G -t -x0 -y0 -w40 -h19 -m37  -nthrowAwayTool pcx\readMessage_discard.pcx
cvtpcx -f -G -t -x0 -y0 -w44 -h19 -m225 -nrecoverTool pcx\ge006-8.pcx

REM read message toolbar
REM cvtpcx -f -G -t -x0 -y0 -w40 -h20 -m225 -naddressTool pcx\ge016-8.pcx
cvtpcx -f -G -t -x0 -y0 -w40 -h20 -m37  -naddressTool pcx\readMessage_address.pcx
cvtpcx -f -G -t -x0 -y0 -w40 -h20 -m225 -nreplyTool pcx\ge017-8.pcx
cvtpcx -f -G -t -x0 -y0 -w40 -h20 -m225 -nreplyAllTool pcx\ge018-8.pcx
cvtpcx -f -G -t -x0 -y0 -w40 -h20 -m225 -nforwardTool pcx\ge019-8.pcx
cvtpcx -f -G -t -x0 -y0 -w40 -h20 -m225 -nprintTool pcx\ge020-8.pcx
cvtpcx -f -G -t -x0 -y0 -w40 -h20 -m225 -npreviousTool pcx\ge021-8.pcx
cvtpcx -f -G -t -x0 -y0 -w40 -h20 -m225 -nnextTool pcx\ge022-8.pcx

REM folder icons
cvtpcx -f -G -g -t -x42 -y1 -w20 -h16 -m225 -ndraftsFolder pcx\ge007-8.pcx
cvtpcx -f -G -g -t -x42 -y1 -w20 -h16 -m225 -ninboxFolder pcx\ge008-8.pcx
cvtpcx -f -G -g -t -x42 -y1 -w20 -h16 -m225 -noutboxFolder pcx\ge009-8.pcx
cvtpcx -f -G -g -t -x42 -y1 -w20 -h16 -m225 -nsentFolder pcx\ge010-8.pcx
cvtpcx -f -G -g -t -x42 -y1 -w20 -h16 -m225 -ntrashFolder pcx\ge011-8.pcx
cvtpcx -f -G -g -t -x42 -y1 -w20 -h16 -m225 -ngenericFolder pcx\ge012-8.pcx

REM message icons
cvtpcx -f -G -g -t -x0 -y0 -w25 -h12 -m225 -nunreadNoAttach pcx\ge030-8.pcx
cvtpcx -f -G -g -t -x0 -y0 -w25 -h12 -m225 -nreadNoAttach pcx\ge031-8.pcx
cvtpcx -f -G -g -t -x0 -y0 -w25 -h12 -m225 -nunreadAttach pcx\ge032-8.pcx
cvtpcx -f -G -g -t -x0 -y0 -w25 -h12 -m225 -nreadAttach pcx\ge033-8.pcx

REM CUI icons
cvtpcx -f -G -g -t -x1 -y1 -w40 -h20 -m225 -nCUIDraftsFolder pcx\ge007-8.pcx
cvtpcx -f -G -g -t -x1 -y1 -w40 -h20 -m225 -nCUIInboxFolder pcx\ge008-8.pcx
cvtpcx -f -G -g -t -x1 -y1 -w40 -h20 -m225 -nCUIOutboxFolder pcx\ge009-8.pcx
cvtpcx -f -G -g -t -x1 -y1 -w40 -h20 -m225 -nCUISentFolder pcx\ge010-8.pcx
cvtpcx -f -G -g -t -x1 -y1 -w40 -h20 -m225 -nCUITrashFolder pcx\ge011-8.pcx

REM zoom in zoom out
cvtpcx -f -G -t -x0 -y0 -2 -w18 -h16 -m225 -nZoomOut pcx\A113-8.pcx
cvtpcx -f -G -t -x0 -y0 -2 -w18 -h16 -m225 -nZoomIn pcx\A114-8.pcx
