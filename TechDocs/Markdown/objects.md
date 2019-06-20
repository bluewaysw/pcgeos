### Objects

List of C Examples	27

List of Figures	35

**[1 System Classes](Objects/osyscla.md)**  
[1.1 MetaClass](Objects/osyscla.md#11-metaclass)  
[1.1.1 Special Messages](Objects/osyscla.md#111-special-messages)  
[1.1.2 Utility Messages](Objects/osyscla.md#112-utility-messages)  
[1.1.3 Exported Message Ranges](Objects/osyscla.md#113-exported-message-ranges)  
[1.2 ProcessClass](Objects/osyscla.md#12-processclass)  
[1.3 GenProcessClass](Objects/osyscla.md#13-genprocessclass)  
[1.3.1 Starting and Stopping](Objects/osyscla.md#131-starting-and-stopping)  
[1.3.2 Undo Mechanism](Objects/osyscla.md#132-undo-mechanism)

**[2 GenClass](Objects/ogen.md)**  
[2.1 GenClass Features](Objects/ogen.md#21-genclass-features)  
[2.2 GenClass Instance Data](Objects/ogen.md#22-genclass-instance-data)  
[2.2.1 Instance Fields](Objects/ogen.md#221-instance-fields)  
[2.2.2 Vardata](Objects/ogen.md#222-vardata)  
[2.3 GenClass Basics](Objects/ogen.md#23-genclass-basics)  
[2.3.1 Visual Monikers](Objects/ogen.md#231-visual-monikers)  
[2.3.2 Composite Link](Objects/ogen.md#232-composit-link)  
[2.3.3 Keyboard Accelerators](Objects/ogen.md#233-keyboard-accelerators)  
[2.3.4 Attributes](Objects/ogen.md#234-attributes)  
[2.3.5 States](Objects/ogen.md#235-states)  
[2.4 Modifying GenClass Instance Data](Objects/ogen.md#24-modifying-genclass-instance-data)  
[2.4.1 Visual Monikers](Objects/ogen.md#241-visual-monkiers)  
[2.4.2 Managing Visual Monikers](Objects/ogen.md#242-mamaging-visual-monikers)  
[2.4.3 Managing Keyboard Accelerators](Objects/ogen.md#243-managing-keyboard-accelerators)  
[2.5 Generic Trees](Objects/ogen.md#25-generic-trees)  
[2.5.1 Child/Parent Searches](Objects/ogen.md#252-child/parent-searches)  
[2.5.2 Manipulating Children Directly](Objects/ogen.md#252-manipulating-children-directly)  
[2.5.3 Branch Construction/Destruction](Objects/ogen.md#253-branch-construction/destruction)  
[2.6 Vardata](Objects/ogen.md#26-vardata)  
[2.6.1 Optional Attributes (ATTRs)](Objects/ogen.md#261-optional-attributes-(attrs))  
[2.6.2 Hints to the Specific UI](Objects/ogen.md#262-hints-to-the-specific-ui)  
[2.6.3 Dynamically Managing VarData](Objects/ogen.md#263-dynamically-managing-vardata)  
[2.7 Special Message Passing](Objects/ogen.md#27-special-message-passing)  
[2.7.1 Parent and Child Message Passing](Objects/ogen.md#271-parent-and-child-message-passing)  
[2.7.2 Generic Upward Queries](Objects/ogen.md#272-generic-upward-queries)  
[2.7.3 Object-Specific Queries](Objects/ogen.md#273-object-specific-queries)  
[2.8 Visual Refreshing](Objects/ogen.md#28-visual-refreshing)  
[2.9 Setting Sizes](Objects/ogen.md#279-setting-sizes)  
[2.10 Activation Messages](Objects/ogen.md#210-activation-messages)  
[2.11 Focus Modifications](Objects/ogen.md#211-focus-modifications)  
[2.12 Navigation Methods](Objects/ogen.md#212-navigation-methods)  
[2.13 Window Positions and Sizes](Objects/ogen.md#213-window-positions-and-sizes)

3	GenApplication	279

	3.1	GenApplication Basics					 OGenApp : 281

		3.1.1	Instance Data				OGenApp : 282

		3.1.2	Application GCN Lists				OGenApp : 285

		3.1.3	Application Instance Reference				OGenApp : 293

		3.1.4	Attach and Launch Flags				OGenApp : 295

		3.1.5	ApplicationStates				OGenApp : 298

		3.1.6	Application Features and Levels				OGenApp : 302

		3.1.7	IACP				OGenApp : 310

	3.2	Advanced GenApplication Usage					 OGenApp : 315

		3.2.1	An Application's Life Cycle				OGenApp : 315

		3.2.2	Application Busy States				OGenApp : 315

		3.2.3	The GenApplication's Moniker				OGenApp : 319

		3.2.4	Measurement Type				OGenApp : 320

		3.2.5	Interaction with the UI				OGenApp : 321

4	GenDisplay / GenPrimary	331

	4.1	A First Look at GenDisplay					 OGenDis : 333

		4.1.1	GenDisplay Object Structure				OGenDis : 334

		4.1.2	Minimizing and Maximizing				OGenDis : 337

	4.2	Using the GenPrimary					 OGenDis : 340

	4.3	Using Multiple Displays					 OGenDis : 344

		4.3.1	GenDisplayGroup				OGenDis : 345

		4.3.2	GenDisplayControl				OGenDis : 351

		4.3.3	Using GenDisplayClass Objects				OGenDis : 352

5	GenTrigger	359

	5.1	GenTrigger Overview					 OGenTrg : 361

	5.2	GenTrigger Usage					 OGenTrg : 363

	5.3	Supplemental GenTrigger Usage					 OGenTrg : 365

		5.3.1	Passing Data with a GenTrigger				OGenTrg : 365

		5.3.2	Interaction Commands				OGenTrg : 367

		5.3.3	Interpreting Double-Clicks				OGenTrg : 369

		5.3.4	Initiating an Action				OGenTrg : 370

		5.3.5	Setting a Trigger As the Default				OGenTrg : 371

		5.3.6	Manipulating Instance Data				OGenTrg : 372

		5.3.7	Other Hints				OGenTrg : 374

	5.4	Customizations					 OGenTrg : 374

6	GenGlyph	377

	6.1	GenGlyph Features					 OGenGly : 379

	6.2	GenGlyph Basics					 OGenGly : 380

	6.3	Modifying a GenGlyph					 OGenGly : 381

7	GenInteraction	385

	7.1	GenInteraction Features					 OGenInt : 387

		7.1.1	Sub-Group Interactions				OGenInt : 388

		7.1.2	Popup Interactions (Menus)				OGenInt : 389

		7.1.3	Dialog Boxes				OGenInt : 389

		7.1.4	PopOuts				OGenInt : 391

	7.2	GenInteraction Instance Data					 OGenInt : 392

		7.2.1	GenInteraction Visibility				OGenInt : 396

		7.2.2	Standard Interactions (Menus)				OGenInt : 398

		7.2.3	GenInteraction Types				OGenInt : 399

		7.2.4	GenInteraction Attributes				OGenInt : 402

	7.3	GenInteraction Usage					 OGenInt : 405

		7.3.1	Visibilities				OGenInt : 405

		7.3.2	Types				OGenInt : 413

	7.4	Supplemental Usage					 OGenInt : 435

		7.4.1	Initiating Interactions				OGenInt : 436

		7.4.2	Dismissing Interactions				OGenInt : 439

		7.4.3	Modality for Dialogs				OGenInt : 439

		7.4.4	Managing Input				OGenInt : 441

		7.4.5	Thread Blocking Routines				OGenInt : 442

	7.5	Interaction Commands					 OGenInt : 450

		7.5.1	InteractionCommand Types				OGenInt : 451

		7.5.2	Dialog Control				OGenInt : 453

		7.5.3	Standard Response Triggers				OGenInt : 455

		7.5.4	Replacing Default Triggers				OGenInt : 457

		7.5.5	Triggers Completing Interactions				OGenInt : 459

8	GenValue	461

	8.1	GenValue Features					 OGenVal : 463

	8.2	GenValue Instance Data					 OGenVal : 465

	8.3	GenValue Basics					 OGenVal : 470

		8.3.1	The Value				OGenVal : 470

		8.3.2	The Minimum and Maximum				OGenVal : 473

		8.3.3	The Increment				OGenVal : 475

		8.3.4	GenValue States				OGenVal : 477

		8.3.5	Display Formats				OGenVal : 480

		8.3.6	Sending an Action				OGenVal : 484

	8.4	Supplemental Usage					 OGenVal : 487

		8.4.1	Adjusting the Value Indirectly				OGenVal : 488

		8.4.2	Status Messages				OGenVal : 490

		8.4.3	Retrieving Text				OGenVal : 491

		8.4.4	Using Value Ratios				OGenVal : 495

		8.4.5	Text Filters for the GenValue				OGenVal : 496

		8.4.6	Using Ranges in GenValues				OGenVal : 497

Volume 2

9	GenView	499

	9.1	GenView Overview					 OGenVew : 501

		9.1.1	GenView Model				OGenVew : 501

		9.1.2	View Features and Goals				OGenVew : 502

		9.1.3	The GenViewControl Object				OGenVew : 505

	9.2	Getting Started: View Basics					 OGenVew : 505

		9.2.1	Graphics System Review				OGenVew : 505

		9.2.2	Defining the Basic View				OGenVew : 507

		9.2.3	Handling View Messages				OGenVew : 509

	9.3	Basic View Attributes					 OGenVew : 510

		9.3.1	The GVI_attrs Attribute				OGenVew : 512

		9.3.2	Dimensional Attributes				OGenVew : 516

		9.3.3	Setting the Background Color				OGenVew : 519

		9.3.4	The GVI_increment Attribute				OGenVew : 523

	9.4	Advanced Concepts and Uses					 OGenVew : 524

		9.4.1	The Life of a View				OGenVew : 525

		9.4.2	Documents in a View				OGenVew : 527

		9.4.3	Drawing the Document				OGenVew : 534

		9.4.4	Document and View Size				OGenVew : 535

		9.4.5	Document Scaling				OGenVew : 538

		9.4.6	Children of the View				OGenVew : 542

		9.4.7	Scrolling				OGenVew : 543

		9.4.8	Monitoring Input				OGenVew : 560

		9.4.9	Linking Views				OGenVew : 569

		9.4.10	Setting the Content				OGenVew : 572

		9.4.11	Internal Utilities				OGenVew : 573

	9.5	The GenViewControl					 OGenVew : 574

		9.5.1	GenViewControl Instance Data				OGenVew : 576

		9.5.2	Notification Received				OGenVew : 577

		9.5.3	GenViewControl Example				OGenVew : 578

		9.5.4	Messages Handled				OGenVew : 580

10	The Text Objects	583

	10.1	The Text Objects					 OText : 587

		10.1.1	Which Object Should I Use?				OText : 588

		10.1.2	How this Chapter is Organized				OText : 589

	10.2	General Text Features					 OText : 589

		10.2.1	Input Management and Filters				OText : 590

		10.2.2	Text Flow Through Regions				OText : 590

		10.2.3	Style Sheets				OText : 591

		10.2.4	Undo				OText : 592

		10.2.5	General Import and Export				OText : 592

		10.2.6	Geometry Management				OText : 592

		10.2.7	Embedded Graphics and Characters				OText : 593

		10.2.8	Search and Replace				OText : 593

		10.2.9	Spell-Checking				OText : 593

		10.2.10	Printing				OText : 594

		10.2.11	Text Controller Objects				OText : 594

	10.3	The Text Object Library					 OText : 595

		10.3.1	Character Attribute Definitions				OText : 595

		10.3.2	Paragraph Attribute Definitions				OText : 600

		10.3.3	Storage Flags				OText : 611

	10.4	Text Object Chunks					 OText : 613

		10.4.1	The Text				OText : 614

		10.4.2	Lines and Fields				OText : 638

		10.4.3	Character Runs				OText : 638

		10.4.4	Paragraph Runs				OText : 646

	10.5	Using VisText					 OText : 653

		10.5.1	VisText Features				OText : 658

		10.5.2	VisText States				OText : 659

		10.5.3	VisText VM File Storage				OText : 663

		10.5.4	Text Filters				OText : 666

		10.5.5	Key Functions				OText : 669

		10.5.6	Setting Text Confines				OText : 671

		10.5.7	Output Messages				OText : 673

		10.5.8	Getting Geometry Information				OText : 678

	10.6	Using GenText					 OText : 680

		10.6.1	GenText Instance Data				OText : 681

		10.6.2	GenText Basics				OText : 687

	10.7	The Controllers					 OText : 696

		10.7.1	Character Attribute Controllers				OText : 696

		10.7.2	Paragraph Attribute Controllers				OText : 700

		10.7.3	Search and Replace and Spell-Checking				
OText : 706

11	The List Objects	717

	11.1	List Object Features					 OGenLst : 719

	11.2	Common Behavior					 OGenLst : 721

		11.2.1	Applying the Action				OGenLst : 721

		11.2.2	State Information				OGenLst : 723

	11.3	GenItemGroups					 OGenLst : 723

		11.3.1	GenItemGroup Instance Data				OGenLst : 724

		11.3.2	GenItem Instance Data				OGenLst : 727

		11.3.3	GenItemGroup Basics				OGenLst : 728

		11.3.4	Working with Items				OGenLst : 747

		11.3.5	Scrolling GenItemGroups				OGenLst : 751

		11.3.6	GenItemGroup Links				OGenLst : 752

		11.3.7	Limitations of the GenItemGroup				OGenLst : 753

	11.4	GenDynamicListClass					 OGenLst : 753

		11.4.1	DynamicList Instance Data				OGenLst : 754

		11.4.2	DynamicList Basics				OGenLst : 756

		11.4.3	Altering Instance Data				OGenLst : 762

	11.5	GenBooleanGroups					 OGenLst : 765

		11.5.1	GenBooleanGroup Instance Data				OGenLst : 766

		11.5.2	GenBooleanGroup Usage				OGenLst : 768

		11.5.3	Altering Instance Data				OGenLst : 774

12	Generic UI Controllers	785

	12.1	Controller Features and Functions					 OGenCtl : 787

		12.1.1	Controller Features				OGenCtl : 788

		12.1.2	How Controllers Work				OGenCtl : 789

		12.1.3	Using Controllers				OGenCtl : 791

	12.2	Standard Controllers					 OGenCtl : 794

	12.3	Using Controllers					 OGenCtl : 796

		12.3.1	Using a Basic GenControl Object				OGenCtl : 797

		12.3.2	Using Tools				OGenCtl : 801

	12.4	Creating Your Own Controllers					 OGenCtl : 810

		12.4.1	GenControlClass Instance Data				OGenCtl : 811

		12.4.2	Subclassing GenControlClass				OGenCtl : 812

		12.4.3	Advanced GenControlClass Usage				OGenCtl : 827

	12.5	GenToolControlClass					 OGenCtl : 840

	12.6	GenToolGroupClass					 OGenCtl : 842

	12.7	Other Controllers					 OGenCtl : 843

		12.7.1	ColorSelectorClass				OGenCtl : 844

		12.7.2	GenPageControlClass				OGenCtl : 853

		12.7.3	The Float Format Controller				OGenCtl : 855

13	GenDocument	861

	13.1	Document Control Overview					 OGenDoc : 863

		13.1.1	The Document Control Objects				OGenDoc : 864

		13.1.2	Document Control Interaction				OGenDoc : 866

		13.1.3	Document Control Models				OGenDoc : 867

	13.2	Document Control Data Fields					 OGenDoc : 870

		13.2.1	GenDocumentControl Data				OGenDoc : 870

		13.2.2	GenDocumentGroup Data				OGenDoc : 885

		13.2.3	GenDocument Attributes				OGenDoc : 896

	13.3	Basic DC Messages					 OGenDoc : 904

		13.3.1	Other Document Group Messages				OGenDoc : 904

		13.3.2	From the Doc Control Objects				OGenDoc : 907

	13.4	Advanced DC Usage					 OGenDoc : 916

		13.4.1	Document Protocols				OGenDoc : 916

		13.4.2	Multiple Document Model				OGenDoc : 920

		13.4.3	Working with DOS files				OGenDoc : 921

		13.4.4	Special-Purpose Messages				OGenDoc : 928

		13.4.5	Forcing Actions				OGenDoc : 932

14	GenFile Selector	937

	14.1	File Selector Overview					 OGenFil : 939

	14.2	File Selector Basics					 OGenFil : 941

		14.2.1	Setting Up the File Selector				OGenFil : 942

		14.2.2	Supporting the File Selector				OGenFil : 943

		14.2.3	Messages to Handle				OGenFil : 944

		14.2.4	Some Common Customizations				OGenFil : 949

	14.3	File Selector Instance Data					 OGenFil : 951

		14.3.1	The GFSI_attrs Field				OGenFil : 955

		14.3.2	The GFSI_fileCriteria Field				OGenFil : 957

		14.3.3	Matching a File's Token				OGenFil : 959

		14.3.4	Matching a File's Creator App				OGenFil : 962

		14.3.5	Matching a File's Geode Attributes				OGenFil : 964

		14.3.6	Masking File Names				OGenFil : 967

		14.3.7	Matching a File's File Attributes				OGenFil : 969

		14.3.8	Searching Via Callback Routine				OGenFil : 972

		14.3.9	Resetting a Filter				OGenFil : 977

	14.4	File Selector Use					 OGenFil : 977

		14.4.1	When a User Selects a File				OGenFil : 977

		14.4.2	The Current Selection				OGenFil : 979

		14.4.3	Rescanning Directories				OGenFil : 987

		14.4.4	Setting Scalable UI Data				OGenFil : 989

Volume 3

15	Help Object Library	991

	15.1	What Is Help?					 OHelp : 993

		15.1.1	Normal Help				OHelp : 994

		15.1.2	First Aid				OHelp : 995

		15.1.3	Simple Help				OHelp : 996

	15.2	Adding Help to Your Application					 OHelp : 996

		15.2.1	Help Contexts and Help Triggers				OHelp : 997

		15.2.2	Adding Default Normal Help				OHelp : 999

		15.2.3	Bringing Up Help on the Fly				OHelp : 1000

	15.3	Customizing Help					 OHelp : 1001

		15.3.1	Bringing Up Initial Help				OHelp : 1002

		15.3.2	Adding the HelpControl				OHelp : 1002

		15.3.3	Sizing the Help Dialog Box				OHelp : 1004

		15.3.4	Managing Help Types				OHelp : 1004

		15.3.5	Managing Help Files				OHelp : 1005

		15.3.6	Customizing the Pointer Image				OHelp : 1007

		15.3.7	Changing the Help Features				OHelp : 1007

	15.4	Creating Help Files					 OHelp : 1007

		15.4.1	Enabling the Help Editor				OHelp : 1008

		15.4.2	Organizing and Writing the Text				OHelp : 1008

		15.4.3	Defining Files and Contexts				OHelp : 1011

		15.4.4	Using Hyperlinks				OHelp : 1013

		15.4.5	Generating the Help Files				OHelp : 1013

	15.5	HelpControlClass Reference					 OHelp : 1014

16	Impex Library	1019

	16.1	Impex Basics					 OImpex : 1022

		16.1.1	The Impex Objects				OImpex : 1022

		16.1.2	How the Impex Objects Work				OImpex : 1023

	16.2	Using Impex					 OImpex : 1025

		16.2.1	Common Impex Concepts				OImpex : 1025

		16.2.2	The ImportControl Object				OImpex : 1028

		16.2.3	The ExportControl Object				OImpex : 1034

	16.3	Writing Translation Libraries					 OImpex : 1040

		16.3.1	How Translation Libraries Work				OImpex : 1041

		16.3.2	Intermediate Formats				OImpex : 1042

17	The Spool Library	1045

	17.1	Introduction to Printing					 OPrint : 1047

	17.2	Simple Printing Example					 OPrint : 1049

	17.3	How Jobs Get Printed					 OPrint : 1052

		17.3.1	Printing System Components				OPrint : 1052

		17.3.2	Chronology				OPrint : 1053

	17.4	Print Control Instance Data					 OPrint : 1056

		17.4.1	Alerting the GenApplication				OPrint : 1058

		17.4.2	Attributes				OPrint : 1058

		17.4.3	Page Range Information				OPrint : 1061

		17.4.4	Document Size				OPrint : 1063

		17.4.5	Print Output Object				OPrint : 1069

		17.4.6	Document Name Output				OPrint : 1073

		17.4.7	The Default Printer				OPrint : 1074

		17.4.8	Adding UI Gadgetry				OPrint : 1075

	17.5	Print Control Messages					 OPrint : 1076

		17.5.1	Common Response Messages				OPrint : 1076

		17.5.2	Flow of Control Messages				OPrint : 1077

		17.5.3	Working with Instance Data				OPrint : 1081

	17.6	Page Size Control					 OPrint : 1087

	17.7	Other Printing Components					 OPrint : 1094

		17.7.1	Spooler and Scheduling				OPrint : 1094

		17.7.2	Printer Drivers				OPrint : 1096

		17.7.3	Page Size Related Routines				OPrint : 1098

	17.8	Debugging Tips					 OPrint : 1099

18	Graphic Object Library	1101

	18.1	Setting Up the Objects					 OGrObj : 1103

		18.1.1	Initializing the Objects				OGrObj : 1106

		18.1.2	GrObj in a GenDocument				OGrObj : 1106

	18.2	Managing a Graphic Layer					 OGrObj : 1107

		18.2.1	Selection				OGrObj : 1108

		18.2.2	Creating GrObjs				OGrObj : 1109

		18.2.3	Action Notification				OGrObj : 1110

		18.2.4	Locks and Forbidding Actions				OGrObj : 1111

		18.2.5	Wrapping				OGrObj : 1113

		18.2.6	Cut, Paste, and Transfer Items				OGrObj : 1114

	18.3	GrObj Controllers					 OGrObj : 1115

		18.3.1	GrObjToolControl				OGrObj : 1115

		18.3.2	GrObjStyleSheetControl				OGrObj : 1117

		18.3.3	GrObjAreaColorSelector				OGrObj : 1117

		18.3.4	GrObjAreaAttrControl				OGrObj : 1117

		18.3.5	GrObjLineColorSelector				OGrObj : 1118

		18.3.6	GrObjLineAttrControl				OGrObj : 1119

		18.3.7	GrObjNudgeControl				OGrObj : 1119

		18.3.8	GrObjDepthControl				OGrObj : 1120

		18.3.9	GrObjArcControl				OGrObj : 1121

		18.3.10	GrObjHandleControl				OGrObj : 1121

		18.3.11	GrObjRotateControl				OGrObj : 1122

		18.3.12	GrObjFlipControl				OGrObj : 1122

		18.3.13	GrObjSkewControl				OGrObj : 1123

		18.3.14	GrObjAlignToGridControl				OGrObj : 1123

		18.3.15	GrObjGroupControl				OGrObj : 1124

		18.3.16	GrObjAlignDistributeControl				OGrObj : 1124

		18.3.17	GrObjLocksControl				OGrObj : 1125

		18.3.18	GrObjConvertControl				OGrObj : 1126

		18.3.19	GrObjDefaultAttributesControl				OGrObj : 1126

		18.3.20	GrObjObscureAttrControl				OGrObj : 1126

		18.3.21	GrObjInstructionControl				OGrObj : 1127

		18.3.22	GrObjGradientFillControl				OGrObj : 1128

		18.3.23	GrObjBackgroundColorSelector				OGrObj : 1128

		18.3.24	Gradient Color Selectors				OGrObj : 1128

		18.3.25	Paste Inside Controls				OGrObj : 1128

		18.3.26	Controls From Other Libraries				OGrObj : 1129

	18.4	GrObj Body					 OGrObj : 1130

		18.4.1	GrObjBody Instance Data				OGrObj : 1130

		18.4.2	GrObjBody Messages				OGrObj : 1132

	18.5	GrObjHead					 OGrObj : 1141

	18.6	GrObjAttributeManager					 OGrObj : 1143

	18.7	Graphic Objects					 OGrObj : 1146

		18.7.1	GrObj Instance Data				OGrObj : 1146

		18.7.2	GrObj Messages				OGrObj : 1148

		18.7.3	Shape Classes				OGrObj : 1170

		18.7.4	GroupClass				OGrObj : 1171

		18.7.5	PointerClass				OGrObj : 1172

		18.7.6	GrObjVisGuardian Classes				OGrObj : 1172

19	Ruler Object Library	1175

	19.1	Ruler Features					 ORuler : 1177

	19.2	Ruler Setup					 ORuler : 1178

	19.3	VisRuler Instance Data					 ORuler : 1180

	19.4	Managing Rulers					 ORuler : 1189

		19.4.1	RulerShowControl				ORuler : 1190

		19.4.2	Mouse Tracking				ORuler : 1191

		19.4.3	Grid Spacing and Constraint				ORuler : 1192

		19.4.4	Guide Constraints and Guidelines				ORuler : 1196

		19.4.5	Other Mouse Constraints				ORuler : 1200

		19.4.6	Esoteric Messages				ORuler : 1203

20	Spreadsheet Objects	1207

	20.1	Spreadsheet Overview					 OSsheet : 1209

		20.1.1	Quick Look at the Objects				OSsheet : 1210

		20.1.2	Managing Cell Files				OSsheet : 1211

		20.1.3	Parsing Expressions				OSsheet : 1212

	20.2	The Spreadsheet Objects					 OSsheet : 1213

		20.2.1	SpreadsheetClass				OSsheet : 1213

		20.2.2	Spreadsheet Rulers				OSsheet : 1224

		20.2.3	The Spreadsheet Controller				OSsheet : 1225

	20.3	Basic Use					 OSsheet : 1225

		20.3.1	Declaring the Objects				OSsheet : 1226

		20.3.2	Working with Files				OSsheet : 1230

		20.3.3	Interacting with the Edit Bar				OSsheet : 1234

	20.4	Other Spreadsheet Controllers					 OSsheet : 1235

		20.4.1	The SSEditControl				OSsheet : 1236

		20.4.2	Notes and SSNoteControlClass				OSsheet : 1236

		20.4.3	Row and Column Size				OSsheet : 1236

		20.4.4	Sorting and SSSortControlClass				OSsheet : 1237

		20.4.5	Defining and Using Names				OSsheet : 1237

		20.4.6	Headers and Footers				OSsheet : 1237

21	Pen Object Library	1239

	21.1	The Ink Object					 OPen : 1241

		21.1.1	Instance Data and Messages				OPen : 1242

		21.1.2	Storing Ink to DB Items				OPen : 1247

	21.2	Working with the Ink DB					 OPen : 1250

		21.2.1	Getting Started				OPen : 1250

		21.2.2	Displaying the Data				OPen : 1251

		21.2.3	Titles and Keywords				OPen : 1251

		21.2.4	Navigating the Folder Tree				OPen : 1252

		21.2.5	Managing Notes and Folders				OPen : 1253

		21.2.6	Manipulating Notes				OPen : 1254

		21.2.7	Searching and Traversing the Tree				OPen : 1255

	21.3	InkControlClass					 OPen : 1255

22	Config Library	1257

	22.1	Providing the UI					 OConfig : 1260

		22.1.1	Designing the UI Tree.				OConfig : 1260

		22.1.2	UI Fetch Routine				OConfig : 1263

	22.2	Module Information Routine					 OConfig : 1264

	22.3	Important Messages					 OConfig : 1267

	22.4	Object Class Reference					 OConfig : 1269

		22.4.1	PrefClass				OConfig : 1269

		22.4.2	PrefValueClass				OConfig : 1274

		22.4.3	PrefItemGroupClass				OConfig : 1275

		22.4.4	PrefStringItemClass				OConfig : 1279

		22.4.5	PrefBooleanGroupClass				OConfig : 1280

		22.4.6	PrefDynamicListClass				OConfig : 1280

		22.4.7	TitledGlyphClass				OConfig : 1282

		22.4.8	PrefInteractionClass				OConfig : 1282

		22.4.9	PrefDialogClass				OConfig : 1283

		22.4.10	PrefTextClass				OConfig : 1284

		22.4.11	PrefControlClass				OConfig : 1285

		22.4.12	PrefTimeDateControlClass				OConfig : 1285

		22.4.13	PrefTriggerClass				OConfig : 1285

		22.4.14	PrefTocListClass				OConfig : 1286

23	VisClass	1291

	23.1	Introduction to VisClass					 OVis : 1293

	23.2	The Visible Class Tree					 OVis : 1297

	23.3	VisClass Instance Data					 OVis : 1297

		23.3.1	VI_bounds				OVis : 1300

		23.3.2	VI_typeFlags				OVis : 1300

		23.3.3	VI_attrs				OVis : 1304

		23.3.4	VI_optFlags				OVis : 1306

		23.3.5	VI_geoAttrs				OVis : 1308

		23.3.6	VI_specAttrs				OVis : 1311

		23.3.7	VI_link				OVis : 1312

	23.4	Using VisClass					 OVis : 1312

		23.4.1	Basic VisClass Rules				OVis : 1313

		23.4.2	Drawing to the Screen				OVis : 1315

		23.4.3	Positioning Visible Objects				OVis : 1338

		23.4.4	Handling Input				OVis : 1351

	23.5	Working with Visible Object Trees					 OVis : 1373

		23.5.1	Creating and Destroying				OVis : 1373

		23.5.2	Adding and Removing				OVis : 1374

		23.5.3	Getting Visible Tree Information				OVis : 1381

		23.5.4	Sending Messages Through the Tree				OVis : 1383

		23.5.5	Visible Object Window Operations				OVis : 1391

	23.6	Visible Layers and 32-Bit Graphics					 OVis : 1393

		23.6.1	Using Visible Document Layers				OVis : 1395

		23.6.2	Using 16-Bit Drawing Commands				OVis : 1396

		23.6.3	The 16-Bit Limit on Visual Bounds				OVis : 1397

		23.6.4	Handling MSG_VIS_DRAW				OVis : 1398

		23.6.5	Managing 32-Bit Geometry				OVis : 1398

		23.6.6	Handling Mouse Events				OVis : 1398

		23.6.7	Setting Up the Objects				OVis : 1399

	23.7	VisClass Error Checking					 OVis : 1401

	23.8	Creating Specific UIs					 OVis : 1403

	23.9	Basic Summary					 OVis : 1403

24	VisComp	1405

	24.1	VisCompClass Features					 OVisCmp : 1407

	24.2	VisCompClass Instance Data					 OVisCmp : 1408

		24.2.1	VCI_comp				OVisCmp : 1410

		24.2.2	VCI_gadgetExcl				OVisCmp : 1410

		24.2.3	VCI_window				OVisCmp : 1411

		24.2.4	VCI_geoAttrs				OVisCmp : 1412

		24.2.5	VCI_geoDimensionAttrs				OVisCmp : 1413

		24.2.6	Managing Instance Data				OVisCmp : 1415

	24.3	Using VisCompClass					 OVisCmp : 1416

		24.3.1	Managing Geometry				OVisCmp : 1417

		24.3.2	Managing Graphic Windows				OVisCmp : 1420

25	VisContent	1423

	25.1	VisContent Instance Data					 OVisCnt : 1425

		25.1.1	The VCNI_attrs Field				OVisCnt : 1427

		25.1.2	Fields That Affect the View				OVisCnt : 1429

		25.1.3	Fields That Affect the Document				OVisCnt : 1431

		25.1.4	Fields That Affect Input Events				OVisCnt : 1433

	25.2	Basic VisContent Usage					 OVisCnt : 1440

		25.2.1	Setting Up Sizing Behavior				OVisCnt : 1441

		25.2.2	Messages Received from the View				OVisCnt : 1443

26	Generic System Classes	1451

	26.1	The System Objects					 OSysObj : 1453

	26.2	The GenSystem Object					 OSysObj : 1455

		26.2.1	GenSystem Features				OSysObj : 1455

		26.2.2	GenSystem Instance Data				OSysObj : 1455

		26.2.3	GenSystem Basics				OSysObj : 1457

		26.2.4	Advanced GenSystem Usage				OSysObj : 1458

	26.3	The GenScreen Object					 OSysObj : 1461

		26.3.1	GenScreen Instance Data				OSysObj : 1462

	26.4	GenField Objects					 OSysObj : 1462

		26.4.1	GenField Features				OSysObj : 1462

		26.4.2	GenField Instance Data				OSysObj : 1463

Index	IX-1
