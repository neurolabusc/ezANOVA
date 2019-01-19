unit main;
{$MODE Delphi}
interface

uses
  LCLIntf,LResources,
{$IFNDEF UNIX}
Registry,ShlObj,
{$ENDIF}
   SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Grids, Menus, ComCtrls, Buttons,Clipbrd,Results,anova, StdCtrls,
  anovafx,Utils, ToolWin, ExtCtrls,Stat;

type

  { TMainForm }

  TMainForm = class(TForm)
    ResultsBtn: TButton;
    GraphBtn: TButton;
    DesignBtn: TButton;
    DataGrid: TStringGrid;
    MainMenu1: TMainMenu;
    FileMenu: TMenuItem;
    AppleMenu: TMenuItem;
    AppleAboutMenu: TMenuItem;
    FontMenu: TMenuItem;
    GraphMenu: TMenuItem;
    DesignMenu: TMenuItem;
    ToolPanel: TPanel;
    ResultsMenu: TMenuItem;
    ViewMenu: TMenuItem;
    New1: TMenuItem;
    Open1: TMenuItem;
    Quit1: TMenuItem;
    Help1: TMenuItem;
    HelpMenu: TMenuItem;
    StatusBar1: TStatusBar;
    Save1: TMenuItem;
    Edit1: TMenuItem;
    Copy1: TMenuItem;
    Paste1: TMenuItem;
    OpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;
    Selectall1: TMenuItem;
    DataMenu: TMenuItem;
    Transform1: TMenuItem;
    Reciprocal1: TMenuItem;
    Log1: TMenuItem;
    Sq1: TMenuItem;
    None1: TMenuItem;
    Sqrt1: TMenuItem;
    Log2: TMenuItem;
    Reciprocal2: TMenuItem;
    ArcSinMenu: TMenuItem;
    Clearallcells1: TMenuItem;
    AssociateezafileswithezANOVA1: TMenuItem;
    procedure GraphBtnClick(Sender: TObject);
    procedure UpdateLabels;
    procedure Quit1Click(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure HelpMenuClick(Sender: TObject);
    procedure OpenBtnClick(Sender: TObject);
    procedure DataGridSelectCell(Sender: TObject; ACol, ARow: Integer;
      var CanSelect: Boolean);
    procedure NewBtnClick(Sender: TObject);
    procedure Save1Click(var NoCancel: boolean);
    procedure FormCreate(Sender: TObject);
    procedure DataGridMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure OpenTextFile (var lFilename:string);
    function CheckSave2Close (lAllowCancel: boolean): boolean;
    procedure DataGridKeyPress(Sender: TObject; var Key: Char);
    procedure Copy1Click(Sender: TObject);
    procedure Paste1Click(Sender: TObject);
    procedure SaveBtnClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    function ComputeResults: boolean;
    procedure ResultsBtnClick(Sender: TObject);
    procedure ShowStatus;
    procedure ReadCells2Buffer;
    procedure Selectall1Click(Sender: TObject);
    procedure DataGridMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure DataGridDrawCell(Sender: TObject; Col, Row: Integer;
      Rect: TRect; State: TGridDrawState);
    procedure DesignBtnClick(Sender: TObject);
    procedure TransformMenu(Sender: TObject);
    procedure Clearallcells1Click(Sender: TObject);
    procedure AssociateezafileswithezANOVA1Click(Sender: TObject);
    procedure FontBtnClick(Sender: TObject);
    procedure FontSet;
    procedure FormShow(Sender: TObject);
    procedure AddMRU(lNewStr: String);
    procedure UpdateMRUMenu;
    procedure MRUClick (Sender: TOBject);
    procedure ANOVABtnLabelUpdate;
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormDropFiles(Sender: TObject; const FileNames: array of String);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation
uses About,  math, graphsettings, graph;

procedure TMainForm.FormDropFiles(Sender: TObject; const FileNames: array of String);
var
   lFilename: string;
begin;
      if gChanges then begin
         if not CheckSave2Close(true) then exit;
      end;
      OpenDialog1.filename := Filenames[0];
      lFilename := OpenDialog1.filename;
      if not fileexists(lFilename) then exit;
      OpenTextFile(lFilename);
end;

procedure TMainForm.MRUClick (Sender: TOBject);
var
   lFilename: string;
begin;
     if gChanges then begin
        if not CheckSave2Close(true) then exit;
     end;
     OpenDialog1.filename := gMRUra[(Sender as TMenuItem).tag];
     lFilename := OpenDialog1.filename;
     if not fileexists(lfilename) then exit;
     OpenTextFile(lfilename);
end;

procedure TMainForm.UpdateMRUMenu;
const
knMenup1 = 5;
var lF,lN: integer;
  NewItem: TMenuItem;
begin
     While Filemenu.Count > (knMenup1-1) do FileMenu.Items[(knMenup1-1)].Free;
     lF := 0;
     repeat
           inc(lF);
     until (lF = kMaxMRU) or (gMRUra[lF] = '');
     if gMRUra[lF] = '' then
        lF := lF - 1;
     if lF = 0 then exit;
     NewItem := TMenuItem.Create(Self);
        NewItem.Caption := '-';
        FileMenu.Add(NewItem);
     for lN := 1 to lF do begin
        NewItem := TMenuItem.Create(Self);
        NewItem.Caption := gMRUra[lN];
        NewItem.Tag := lN;
        NewItem.Onclick := MRUClick;
        FileMenu.Add(NewItem);
    end;
end;

procedure TMainForm.AddMRU(lNewStr: String);
var
lI,lI2: integer;
begin
  for lI := 1 to kMaxMRu do begin {remove repeats}
      if lNewStr = gMRUra[lI] then
         gMRUra[lI] := '';
  end;
  for lI := 1 to (kMaxMRU-1) do begin {compact empty cells}
      if (gMRUra[lI] = '') then begin
          lI2 := lI;
          repeat
                inc(lI2);
                if gMRUra[lI2] <> '' then begin
                 gMRUra[lI] := gMRUra[lI2];
                 gMRUra[lI2] := '';
                end;
          until  (lI2 =kMaxMRU) or (gMRUra[lI] <> '');
      end;
  end;
  for lI := kMaxMRU downto 2 do
      gMRUra[lI] := gMRUra[lI-1];
  gMRUra[1] := lNewStr;
  UpdateMRUMenu;
end;

procedure TMainForm.Quit1Click(Sender: TObject);
begin
     if not CheckSave2Close(true) then exit;
     gChanges := false;
     Close;
end;

procedure TMainForm.FormResize(Sender: TObject);
begin
 GridResize(DataGrid);
end;

procedure TMainForm.UpdateLabels;
begin
    UpdateGridLabels(DataGrid); //Utils Unit
end;

procedure TMainForm.GraphBtnClick(Sender: TObject);
begin
  if ComputeResults then //compute results
     GraphForm.Show;
end;

procedure TMainForm.HelpMenuClick(Sender: TObject);
begin
     AboutForm.Showmodal;
end;

function TMainForm.CheckSave2Close (lAllowCancel: boolean): boolean;
begin
     result := true;
     if not gChanges then exit;
     result := false;
     if lAllowCancel then begin
       case MessageDlg( 'Save changes?', mtWarning, [mbYes, mbNo, mbCancel], 0 ) of
            mrYes : begin
                         Save1Click( result ) ;
                         exit;
                end ;
            mrCancel : exit ;
        end ;
     end else
       case MessageDlg( 'Save any changes?', mtWarning, [mbYes, mbNo], 0 ) of
            mrYes : begin
                    Save1Click( result ) ;
                end ;
        end ;
     result := true;
end;

procedure ClearDesignMatrix;
begin
    gDesignUnspecified := true;
    MainForm.DesignBtn.Caption := 'Design: not specified';
end;

procedure TMainForm.ANOVABtnLabelUpdate;
var
   lFactors,lDesign: integer;
   Arep,Brep,CRep: boolean;
   //lBStr,lCStr,
   lDesignStr: string;
begin
     //exit; //aqw
     //first - check if this is a supported design...
     //count factors:
     lFactors := 0;
     if ANOVAForm.AVal.Value > 1 then
        inc(lFactors);
     if ANOVAForm.BVal.Value > 1 then
        inc(lFactors);
     if ANOVAForm.CVal.Value > 1 then
        inc(lFactors);
     Arep := ANOVAForm.ARepCheck.Checked;
     Brep := ANOVAForm.BRepCheck.Checked;
     Crep := ANOVAForm.CRepCheck.Checked;
     if lFactors = 1 then begin
         if ARep then
            lDesign := kb0w1
         else
             lDesign := kb1w0;
     end else if lFactors = 2 then begin
         if (ARep) and (BRep) then
            lDesign := kb0w2
         else if (not (ARep)) and (not (BRep)) then
             lDesign := kb2w0
         else if (not (ARep)) and (BRep) then
             lDesign := kb1w1
         else begin
             Showmessage('WARNING: unsupported mixed design.');
             lDesign := kb1w1;
         end;
     end else if lFactors = 3 then begin
         if (ARep) and (BRep)and (CRep)  then
            lDesign := kb0w3
         else if (not (ARep)) and (not (BRep)) and (not(CRep)) then
             lDesign := kb3w0
         else if (not (ARep)) and (not (BRep)) and (CRep) then
             lDesign := kb2w1
         else if (not (ARep)) and (BRep) and (CRep) then
             lDesign := kb1w2
         else begin
             Showmessage('WARNING: unsupported mixed design.');
             lDesign := kb1w2;
         end;
     end else begin//3 factors
             Showmessage('WARNING: unsupported mixed design.');
             lDesign := kb1w2;
     end;
     ANOVAForm.DesignDrop.itemindex := lDesign;
     ANOVAForm.DesignDropChange(nil);

     lDesignStr := ANOVAForm.DesignDrop.Text; //'  ANOVA';
     MainForm.DesignBtn.Caption := 'Design '+lDesignStr;
     MainForm.UpdateLabels;
     MainForm.FormResize(nil);
end;

function ReadNextColonStr (var lStr: string; var lPos: integer): string;
var
   lLen: integer;
begin
    result := '';
    if lPos < 1 then lPos := 1;
    lLen := length(lStr);
    while (lPos <= lLen) and (lStr[lPos] <> ':') do begin
          result := result + lStr[lPos];
          inc(lPos);
    end;
    inc(lPos);
end;

procedure TMainForm.OpenTextFile (var lFilename:string);
var
   lNumStr,lStr,lExt: string;
   F: TextFile;
   lCh: char;
   lI,lPos,lALevels,lBLevels,lCLevels,lInc,MaxC,lRi,lCi,R,C:integer;
   lAWithin,lBWithin,lCWithin: boolean;
begin
     if not fileexists(lFilename) then exit;
     lExt := StrLower(PChar(extractfileext(lFilename)));
     if (lExt = kCsvExt) or (lExt = kTxtExt) or (lExt = kNativeExt) then
     else begin
        Showmessage('ezANOVA is unable to recognize the extension of the file: '+lFilename);
         exit;
     end;
     Self.Caption := 'ezANOVA: '+extractfilename(lFilename);
     gChanges := false;
     AssignFile(F, lFilename);
     FileMode := 0;  //Set file access to read only
     //First pass: determine column height/width
     Reset(F);
     C := 0;
     MaxC := 0;
     R := 1;
     ClearDesignMatrix;
     if lExt = kNativeExt then begin
        Readln(F,lStr);//Version
        if lStr <> kNativeSignature then begin
            showmessage('This software can not read this file. Perhaps you need to upgrade your software. The first line should read "'+kNativeSignature+'".');
            CloseFile(F);
            FileMode := 2;  //Set file access to read only
            exit;
        end;
        //Factor1
        Readln(F,lStr);//Factor1
        lPos := 0; //start at beginning of line
        ReadNextColonStr(lStr,lPos); //'factor1'
        lALevels := strtoint(ReadNextColonStr(lStr,lPos));
        ANOVAForm.AVal.Value := lALevels;
        ANOVAForm.AEdit.Text := ReadNextColonStr(lStr,lPos);
        ANOVAForm.AlevelNames.ColCount := lALevels;
        for lInc := 1 to lALevels do
            ANOVAForm.ALevelNames.Cells[lInc-1,0] := ReadNextColonStr(lStr,lPos);
        if ReadNextColonStr(lStr,lPos)= 'w' then
           lAWithin := true
        else
            lAWithin := false;
        //Factor2
        Readln(F,lStr);//Factor2
        lPos := 0; //start at beginning of line
        ReadNextColonStr(lStr,lPos); //'factor2'
        lBLevels := strtoint(ReadNextColonStr(lStr,lPos));
        ANOVAForm.BVal.Value := lBLevels;
        ANOVAForm.BEdit.Text := ReadNextColonStr(lStr,lPos);
        ANOVAForm.BlevelNames.ColCount := lBLevels;

        for lInc := 1 to lBLevels do
            ANOVAForm.BLevelNames.Cells[lInc-1,0] := ReadNextColonStr(lStr,lPos);
        if ReadNextColonStr(lStr,lPos)= 'w' then
           lBWithin := true
        else
            lBWithin := false;
        //Factor3
        Readln(F,lStr);//Factor3
        lPos := 0; //start at beginning of line
        ReadNextColonStr(lStr,lPos); //'factor3'
        lCLevels := strtoint(ReadNextColonStr(lStr,lPos));
        ANOVAForm.CVal.Value := lCLevels;
        ANOVAForm.CEdit.Text := ReadNextColonStr(lStr,lPos);
        ANOVAForm.ClevelNames.ColCount := lCLevels;
        for lInc := 1 to lCLevels do
            ANOVAForm.CLevelNames.Cells[lInc-1,0] := ReadNextColonStr(lStr,lPos);
        if ReadNextColonStr(lStr,lPos)= 'w' then
           lCWithin := true
        else
            lCWithin := false;
        if (lCLevels > 1) and (lBLevels > 1) and (lALevels > 1) then
           ANOVAForm.SetFactors(3)
        else if  (lBLevels > 1) and (lALevels > 1) then
           ANOVAForm.SetFactors(2)
        else
           ANOVAForm.SetFactors(1);
        ANOVAForm.AVal.Value := lALevels;
        ANOVAForm.BVal.Value := lBLevels;
        ANOVAForm.CVal.Value := lCLevels;
        //paired data?
        Readln(F,lStr);//PairDat : obsolete
        //next - check this is a supported design...
        ANOVAForm.ARepCheck.checked := lAWithin;//(lStr = '#PairDat:1');
        ANOVAForm.BRepCheck.checked := lBWithin;//(lStr = '#PairDat:1');
        ANOVAForm.CRepCheck.checked := lCWithin;//(lStr = '#PairDat:1');
        gDesignUnspecified := false;
        ANOVABtnLabelUpdate;
        AddMRU(lFilename);
     end;

     while not Eof(F) do begin
        //read next line
        Read(F, lCh);
        if (lCh in [#10,#13]) then begin //EndOfLine: Mac use CR, Unix use LF, PC use CR+LF
            if C > 0 then begin
               inc(C);
               //DataGrid.Cells[ C, kMaxFactors+R ] := (lNumStr) ;
               //lNumStr := '';
               if C > MaxC then MaxC := C;
               C := 0;
               inc(R);
            end;
        end else if (lCh in ['-','0'..'9',{DecSeparator}'.',BS,DEL,CR]) then begin
           //lNumStr := lNumStr + lCh;
        end else {if lNumStr <> '' then} begin
            //read current entry
            inc(C);
        end;
     end;
     DataGrid.RowCount := kMaxFactors+R;
     DataGrid.ColCount := MaxC+1;
     for lCi := 1 to (MaxC) do
         for lRi := 1 to (R-1) do
           DataGrid.Cells[ lCi, kMaxFactors+lRi ] := ('') ;
     //Second pass: fill values
    Reset(F);
     if lExt = kNativeExt then begin
        Readln(F,lStr);//Version
        Readln(F,lStr);//Factor1
        Readln(F,lStr);//Factor2
        Readln(F,lStr);//Factor3
        Readln(F,lStr);//PairDat
     end;     C := 0;
     MaxC := 0;
     R := 1;
     lNumStr := '';
     while not Eof(F) do begin
        //read next line
        Read(F, lCh);
        if (lCh in [#10,#13]) then begin //EndOfLine: Mac use CR, Unix use LF, PC use CR+LF
            if C > 0 then begin
               inc(C);
               DataGrid.Cells[ C, kMaxFactors+R ] := (lNumStr) ;
               lNumStr := '';
               if C > MaxC then MaxC := C;
               C := 0;
               inc(R);
            end;
        end else if (lCh in ['-','0'..'9','.'{DecSeparator},BS,DEL,CR]) then begin
           lNumStr := lNumStr + lCh;
        end else {if lNumStr <> '' then} begin
            //read current entry
            inc(C);
            if (DecSeparator = ',') and (Length(lNumStr) > 1) then begin
                 for lI := length(lNumStr) downto 1 do
                     if lNumStr[lI] = '.' then
                        lNumStr[lI] := ',';
            end;{}
            DataGrid.Cells[ C, kMaxFactors+R ] := (lNumStr) ;
            lNumStr := '';
        end;
     end;
     //Tidy Up...
    UpdateLabels;
    FormResize(nil);
     CloseFile(F);
     FileMode := 2;  //Set file access to read only
    if gDesignUnspecified then
     Showmessage('You need to define the experiment design [press the ''Design'' button]');
end;

procedure TMainForm.OpenBtnClick(Sender: TObject);
var lFileName: string;
begin
     if gChanges then begin
        if not CheckSave2Close(true) then exit;
     end;
     if not OpenDialog1.execute then exit;
     lFilename := OpenDialog1.filename;
     if not fileexists(lFilename) then exit;
     OpenTextFile(lFilename);
end;

procedure TMainForm.ShowStatus;
begin
    GridToStatusBar(DataGrid,StatusBar1);
end;

procedure TMainForm.DataGridSelectCell(Sender: TObject; ACol, ARow: Integer;
  var CanSelect: Boolean);
begin
   gEnterCell := true;
end;


procedure TMainForm.NewBtnClick(Sender: TObject);
begin
     ANOVAForm.RowEdit.value := 12;
     ANOVAForm.Showmodal;
     DataGrid.RowCount := ANOVAForm.RowEdit.Value+1+kMaxFactors;
     gDesignUnspecified := false;
     ANOVABtnLabelUpdate;
end;

function RemoveColons( lStr: string): string;
var lLen,lPos: integer;
begin
     result := lStr;
     lLen := length(lStr);
     if lLen < 1 then exit;
     for lPos := 1 to lLen do
         if result[lPos] = ':' then
            result[lPos] := ';';
end;

procedure TMainForm.Save1Click(var NoCancel: boolean);
const
     kNative = 1;
     kCSV = 2;
     kTxt = 3;
var
  f: TextFile;
  lFormat,C, R,lLen,lPos,ColStart,ColEnd,RowStart,RowEnd : integer ;
  lLevelStr,lFilename,S,lExt,lWithinSubjStr : string ;
  kSpacer : char;
begin
    NoCancel := false;
   if not SaveDialog1.Execute then exit;
   lFormat := SaveDialog1.FilterIndex;
   if (lFormat < kNative) or (lFormat > kTxt) then
      lFormat := kNative;
   case lFormat of
        kCSV: lExt := kCSVext;
        3: lExt := kTXText;
        else lExt := kNativeExt;
   end;
   if lFormat <> kNative then begin
      case MessageDlg( 'Export file as a text format? Note you will lose information about the experiment design [save to Native format to preserve condition information]', mtWarning, [mbYes, mbCancel], 0 ) of
            mrCancel : exit ;
        end ;
   end; //not native
   if (lFormat = kNative) and (gDesignUnspecified) then begin
       showmessage('Unable to save this data as an ezANOVA format file until you have specified the conditions [press the ''Design'' button]');
       exit;
   end;
   //lExt := StrUpper(PChar(extractfileext(SaveDialog1.Filename)));
   lFilename := SaveDialog1.Filename;
   ChangeFileExt(lFilename,lExt);
   AddMRU(lFilename);
    // Setup...
    if (DecSeparator = ',') or (lFormat <> kCSV) then //e.g. in German, 12.13 is written "12,13"
       kSpacer := #9 //tab
    else
        kSpacer := ',';
    S := '' ;
    RowStart := kMaxFactors+1 ;
    RowEnd := DataGrid.RowCount - 1;
    ColStart := 1 ;
    ColEnd := DataGrid.ColCount - 1;
    if (ColEnd < ColStart) or (RowEnd < RowStart) then exit;
    // Copy to string
    for R := RowStart to RowEnd do
    begin
        for C := ColStart to ColEnd do begin
            S := S + DataGrid.Cells[ C, R ] ;
            if( C < DataGrid.ColCount - 1 ) then
            begin
                S := S + kSpacer{#9} ; // Tab
            end ;
        end ;
        if R <> (DataGrid.RowCount - 1) then //all except last line
           S := S + #13#10 ; // End line
    end ;
    if (DecSeparator = ',') {and (lFormat = kCSV)} then begin//e.g. in German, 12.13 is written "12,13"
       //replace ',' decimal points with '.'
       lLen := length(S);
       for lPos := 1 to lLen do begin
           if S[lPos] = ',' then S[lPos] := '.'; //change decimal point
           if S[lPos] = #9 then S[lPos] := ',';
       end;
    end;
    AssignFile(f, lFileName);
    rewrite(f);
    if lFormat = kNative then begin
       writeln(f,kNativeSignature);
       //Details for 1st factor
       lLevelStr := '';
       if ANOVAForm.ARepCheck.checked then //not mixed
          lWithinSubjStr := ':w'
       else
           lWithinSubjStr := ':b';
       lLen := ANOVAForm.AVal.value;
       if lLen < 2 then lLen := 0;
       if lLen > 1 then
          for lPos := 1 to lLen do
              lLevelStr := lLevelStr+':'+RemoveColons(ANOVAForm.ALevelNames.Cells[lPos-1,0]);
       writeln(f,'#Factor1:'+inttostr(lLen)+':'+RemoveColons(ANOVAForm.AEdit.text)+lLevelStr+lWithinSubjStr);
       //details for second factor
       lLevelStr := '';
       if ANOVAForm.BVal.value < 2 then
          //use prev WithinSubj value
       else if ANOVAForm.BRepCheck.checked then //not mixed
          lWithinSubjStr := ':w'
       else
           lWithinSubjStr := ':b';
       lLen := ANOVAForm.BVal.value;
       if lLen < 2 then lLen := 0;
       if lLen > 1 then
          for lPos := 1 to lLen do
              lLevelStr := lLevelStr+':'+RemoveColons(ANOVAForm.BLevelNames.Cells[lPos-1,0]);
       writeln(f,'#Factor2:'+inttostr(lLen)+':'+RemoveColons(ANOVAForm.BEdit.text)+lLevelStr+lWithinSubjStr);
       //details for 3rd factor
       lLevelStr := '';
       if ANOVAForm.CVal.value < 2 then
          //use prev WithinSubj value - only create mixed designs if specified
       else if ANOVAForm.CRepCheck.checked then
          lWithinSubjStr := ':w'
       else
           lWithinSubjStr := ':b';
       lLen := ANOVAForm.CVal.value;
       if lLen < 2 then lLen := 0;
       if lLen > 1 then
          for lPos := 1 to lLen do
              lLevelStr := lLevelStr+':'+RemoveColons(ANOVAForm.CLevelNames.Cells[lPos-1,0]);
       writeln(f,'#Factor3:'+inttostr(lLen)+':'+RemoveColons(ANOVAForm.CEdit.text)+lLevelStr+lWithinSubjStr);
       writeln(f,'#UNUSEDv:2');
       Self.Caption := 'ezANOVA: '+extractfilename(SaveDialog1.Filename);//remove any previous filename
       gChanges := false;
    end;
    Writeln(f, S);
    Flush(f);  { ensures that the text was actually written to file }
    CloseFile(f);
    NoCancel := true;
end;

{$IFNDEF UNIX}
function registerfiletype(inft,inkey,desc,icon:string): boolean;
var myreg : treginifile;
    ct : integer;
    ft,key: string;
begin
     result := true;
     ft := inft;
     key := inkey;
     ct := pos('.',ft);
     while ct > 0 do begin
           delete(ft,ct,1);
           ct := pos('.',ft);
     end;
     if (ft = '') or (Application.ExeName = '') then exit; //not a valid file-ext or ass. app
     ft := '.'+ft;
     myreg := treginifile.create('');
     try
        myreg.rootkey := hkey_classes_root; // where all file-types are described
        if key = '' then key := copy(ft,2,maxint)+'_auto_file'; // if no key-name is given, create one
        myreg.writestring(ft,'',key); // set a pointer to the description-key
        myreg.writestring(key,'',desc); // write the description
        myreg.writestring(key+'\DefaultIcon','',icon); // write the def-icon if given
        //showmessage(key);
        myreg.writestring(key+'\shell\open\command','',Application.ExeName+' %1'); //association
     except
           result := false;
           showmessage('Only administrators can change file associations. You are currently logged in as a restricted user.');
     end;
     //finally
            myreg.free;
     //end;
end;
{$ENDIF}

procedure TMainForm.FormCreate(Sender: TObject);
begin
     {$IFDEF Darwin}
     //Application.OnDropFiles:= AppDropFiles;
     New1.ShortCut := ShortCut(Word('N'), [ssMeta]);
     Open1.ShortCut := ShortCut(Word('O'), [ssMeta]);
     Save1.ShortCut := ShortCut(Word('S'), [ssMeta]);
     Quit1.ShortCut := ShortCut(Word('Q'), [ssMeta]);
     Copy1.ShortCut := ShortCut(Word('C'), [ssMeta]);
     Paste1.ShortCut := ShortCut(Word('V'), [ssMeta]);
     Selectall1.ShortCut := ShortCut(Word('A'), [ssMeta]);
     DesignMenu.ShortCut:=ShortCut(Word('D'), [ssMeta]);
     ResultsMenu.ShortCut:=ShortCut(Word('R'), [ssMeta]);
     GraphMenu.ShortCut:=ShortCut(Word('G'), [ssMeta]);
     HelpMenu.Visible := false;
    {$ELSE}
     AppleMenu.Visible := false;
    {$ENDIF}//Darwin
     {$IFDEF UNIX}
     AssociateezafileswithezANOVA1.visible := false;
     {$ENDIF}
     gTransform := 0;
     Randomize;
     DecSeparator := DecimalSeparator;
     g64rBufP := nil;
     gEnterCell := false;
     gChanges := false;
    DataGrid.ColCount := 9;
    DataGrid.RowCount := 15;

    FormResize(nil);
end;

procedure TMainForm.DataGridMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var C, R : integer ;
    Rect : TGridRect ;
begin
    DataGrid.MouseToCell( X, Y, C, R ) ;
    Rect.Left := C ;
    Rect.Right := C ;
    Rect.Top := R ;
    Rect.Bottom := R ;
    DataGrid.Selection := Rect ;
end;

procedure TMainForm.DataGridKeyPress(Sender: TObject; var Key: Char);
var S : string ;

begin
    if (Key in ['0'..'9',DecSeparator,BS,DEL,CR]) or ((Key='-') and (gEnterCell)) then
    else
        exit;
    if(
        ( DataGrid.Selection.Top = DataGrid.Selection.Bottom )
        and
        ( DataGrid.Selection.Left = DataGrid.Selection.Right )
      ) then
    begin
        gChanges := true;
        if gEnterCell then begin
           S := ''
        end else
            S := DataGrid.Cells[ DataGrid.Selection.Left,DataGrid.Selection.Top ] ;
        gEnterCell := false;
        if ( ( Key = DEL ) or ( Key = BS ) )then
        begin
            if( length( S ) > 0 ) then
            begin
                setlength( S, length( S ) - 1 ) ;
            end ;
        end else
        if ( Key = CR ) then
        begin
            //Edit_Box.Text := S ;
            exit ;
        end else
        begin
            S := S + Key ;
        end ;
        DataGrid.Cells[ DataGrid.Selection.Left, DataGrid.Selection.Top ] := S ;
    end ;
end;

procedure TMainForm.Copy1Click(Sender: TObject);
begin
     CopyStringGridToClipBoard(DataGrid);
end;

procedure TMainForm.Paste1Click(Sender: TObject);
var StartC,C, R,I : integer ;
    Dummy : integer ;
    lSciNotation,EOF: boolean;
    lValue: double;
    Line, S, Work,WorkFilter : string ;
begin
    // Setup...
    S := Clipboard.AsText ;
    EOF:= false;
    if (DataGrid.Selection.Left < 0) or (DataGrid.Selection.Top < 0) then begin
        Selectall1Click(nil);
    end;
    gChanges := true;
    StartC := DataGrid.Selection.Left;
    R := DataGrid.Selection.Top;
    C := StartC;
    while( length( S ) > 0 ) do begin
        // Extract next line...
        {$IFDEF UNIX}
        Dummy := pos( #13, S + #13 ) ;
        //Dummy := pos( #10, S + #10 ) ;
        {$ELSE}
        Dummy := pos( #13#10, S + #13#10 ) ;
        {$ENDIF}
        Line := copy( S, 1, Dummy - 1 ) ;
        if (Dummy+1) < length(S) then //last line may not have eol
           S := copy( S, Dummy + 1, length( S ) )
        else
            EOF := true;
        while( length( Line ) > 0 ) do begin
            // Extract next cell...
            lSciNotation := false;
            Dummy := pos( #9, Line + #9 ) ;
            Work := copy( Line, 1, Dummy - 1 ) ;
            Line := copy( Line, Dummy + 1, length( S ) ) ;
            WorkFilter :=  '';
            if length(Work) > 0 then begin
                for I := length(Work) downto 1 do begin
                    if (Work[i] in ['-','0'..'9','E','e',DecSeparator,BS,DEL,CR]) then
                       WorkFilter := Work[i]+WorkFilter;
                    if (Work[i] in ['E','e']) then
                       lSciNotation := true;
                end;
            end;
            if lSciNotation then begin
               try
                  lValue := strtofloat(Workfilter);
               except
                     on EConvertError do
                        lValue := NaN
                     else
                         lValue := NaN;
               end; //try..except
               if lValue <> NaN then
                  DataGrid.Cells[ C, R ] :=(floattostr(lValue));
            end else if(length(WorkFilter) > 0) and ( C < DataGrid.ColCount ) then begin
                DataGrid.Cells[ C, R ] := WorkFilter ;
                //Format_Grid.Cells[ C, R ] := '' ;
            end ;
            inc( C ) ;
        end ;
        inc( R ) ; // Move to next row
        if( R >= DataGrid.RowCount ) or (EOF) then begin
            break ; // All done with paste
        end ;
        C := StartC;
    end ; // While length(S) > 0
end; //proc Paste1Click

procedure TMainForm.SaveBtnClick(Sender: TObject);
var
   b: boolean;
begin
     Save1Click(b);
end;

function ASin (var X: double): double; //asin
begin
  result := arctan(x / sqrt(1-sqr(x)))
end;

procedure TMainForm.ReadCells2Buffer;
var
   lDbl: double;
   lRend,lRStart,lCStart,lCEnd,lC,lR,lPos: integer;
   lStr: string;
begin
    if g64rBufP <> nil then
        freemem(g64rBufP);
    GetMem(g64rBufP,(DataGrid.ColCount*DataGrid.RowCount*sizeof(double))+16);
    //g64rBuf := DoubleP((integer(g64rBufP) and $FFFFFFF0)+16);
    lRStart := {1}kMaxFactors+1;
    lREnd := DataGrid.RowCount - 1;
    lCstart := 1;
    lCend := DataGrid.ColCount - 1;
    gnCol := lCEnd;
    gnRow := lREnd-lRStart+1;
    // Copy to string
    lPos := 0;
    for lR := lRStart to lREnd do begin
        for lC := lCStart to lCEnd do begin
            inc(lPos);
            lStr := (DataGrid.Cells[ lC, lR ]);
            lDbl := NaN;
            if length(lStr) > 0 then begin
                try
                   lDbl :=  Strtofloat(lStr);
                except
                      on EConvertError do begin
                         showmessage('Cell '+ColLabel(lC)+inttostr(lR-kMaxFactors)+ ': Unable to convert the string '+lStr+' to a number');
                         DataGrid.Cells[ lC, lR ] := '';
                         lDbl := NaN; //NAN? Not-A-Number
                      end; //Error
                end; //except
            end; //length > 0
            g64rBufp[lPos] :=lDbl;
        end ; //for each col
    end ; //for each row
end;

function TMainForm.ComputeResults: boolean;
var
   lInc,lnCells,lTransform: integer;
   lK,lHalf,lMin,lMax,lV,lMult,lglobalDFError,lglobalMSError: double;
begin
   result := false;
     ResultsForm.Memo1.Lines.Clear;
     ReadCells2Buffer;
     lnCells := gnRow*gnCol;
     if (gTransform <> 0) and (lnCells > 0) then begin
         lMin := g64rBufp[1];
         lMax := g64rBufp[1];
         lHalf := 0.5;
         for lInc := 1 to lnCells do begin
             lV := g64rBufp[lInc];
             if lV < lMin then lMin := lV;
             if lV > lMax then lMax := lV;
             //if lV = 0 then lZeroPresent := true;
         end;
         lK := 1+ lMax;
         lTransform := gTransform;
         if lTransform <> 0 then begin
            for lInc := 1 to lnCells do
                if (g64rBufp[lInc] < 0) then
                   lTransform := 0;
            if lTransform = 0 then
               Showmessage('No transform applied: some negative values.');
         end;

         case lTransform of
              -3: begin //Recip
                      ResultsForm.Memo1.Lines.Add('Transform applied: INVERSE RECIPROCAL');
                      for lInc := 1 to lnCells do g64rBufp[lInc] := (1/(lK-g64rBufp[lInc]));
                 end;
              -2: begin //Log
                      ResultsForm.Memo1.Lines.Add('Transform applied: INVERSE LOGARITHM');
                      for lInc := 1 to lnCells do g64rBufp[lInc] := ln(lK-g64rBufp[lInc]);
                 end;
              -1: begin //Sqrt
                      ResultsForm.Memo1.Lines.Add('Transform applied: INVERSE SQUARE ROOT');
                      for lInc := 1 to lnCells do g64rBufp[lInc] := sqrt(lK-g64rBufp[lInc]);
                 end;
              1: begin //Sqrt
                      ResultsForm.Memo1.Lines.Add('Transform applied: SQUARE ROOT');
                      for lInc := 1 to lnCells do
                              g64rBufp[lInc] := sqrt(g64rBufp[lInc]);
                 end;
              2: begin //Log
                      ResultsForm.Memo1.Lines.Add('Transform applied: LOGARITHM');
                      for lInc := 1 to lnCells do g64rBufp[lInc] := ln(g64rBufp[lInc]);
                 end;
              3: begin //Recip
                      if lMin <= 0 then //avoid divide by zero errors!
                         lK := 1 - lMin  //make smallest value equal to one
                      else
                          lK := 0;
                      ResultsForm.Memo1.Lines.Add('Transform applied: RECIPROCAL');
                      for lInc := 1 to lnCells do g64rBufp[lInc] := (1/(lK+g64rBufp[lInc]));
                 end;
              4: begin //ArcSin
                     if (lMin < 0) or (lMax > 100) then begin
                        Showmessage('Unable to compute ArcSin transform: data must be in the range 0..100.');
                     end else begin
                         if lMax > 1 then
                            lMult := 0.01 //% data 0..100%
                         else
                             lMult := 1; //proportion data, 0..1
                         ResultsForm.Memo1.Lines.Add('Transform applied: ARCSIN');
                         for lInc := 1 to lnCells do begin
                          lV := g64rBufp[lInc]*lMult;
                          if lV = 1 then begin
                             g64rBufp[lInc] := 1;
                          end else begin
                              lV := POWER(lV,lHalf);
                              g64rBufp[lInc] := (2*ASIN(lV))/PI;
                          end;
                         end;
                     end; //not out of range
                 end;
              else
                  ;//showmessage('Transform not yet implemented.');
         end;
         ResultsForm.Memo1.Lines.Add('');
     end;
     if not ANOVAForm.ComputeANOVA (lglobalDFError,lglobalMSError) then exit;
     ResultsForm.DescriptiveStats (ANOVAForm.doDesign in [kb0w1..kb0w3], lglobalDFError,lglobalMSError);
     result := true;
end;

procedure TMainForm.ResultsBtnClick(Sender: TObject);
begin
     if ComputeResults then
        ResultsForm.Show;
end;

procedure TMainForm.Selectall1Click(Sender: TObject);
begin
     StringGridSelectAll(DataGrid);
end;

procedure TMainForm.DataGridMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
     ShowStatus;
end;

procedure TMainForm.DataGridDrawCell(Sender: TObject; Col, Row: Integer;
  Rect: TRect; State: TGridDrawState);
begin
          ShowStatus;
end;

procedure TMainForm.DesignBtnClick(Sender: TObject);
var
   lRows:integer;
begin
     lRows := DataGrid.RowCount-kMaxFactors-1;
     if lRows < 2 then lRows := 2;
     ANOVAForm.RowEdit.Value := lRows;
     ANOVAForm.Showmodal;
     if ANOVAForm.ModalResult = mrCancel then exit;
     if ANOVAForm.RowEdit.Value <> (lRows) then
          DataGrid.RowCount := ANOVAForm.RowEdit.Value+kMaxFactors+1;
     gDesignUnspecified := false;
     Self.Caption := 'ezANOVA';//remove any previous filename
     ANOVABtnLabelUpdate;
     gChanges := true;
end;

procedure TMainForm.TransformMenu(Sender: TObject);
begin
     (sender as TMenuItem).Checked := true;
     gTransform := (sender as TMenuItem).Tag;
end;

procedure TMainForm.Clearallcells1Click(Sender: TObject);
var
 lR,lC,lRi,lCi: integer;
begin
    lR := DataGrid.RowCount-1;
    lC := DataGrid.ColCount-1;
    for lRi := 1 to lR do begin
        for lCi := 1 to lC do begin
           DataGrid.Cells[lCi,kMaxFactors+lRi] := '';
        end;//for cols
    end;//for rows
end;


procedure TMainForm.AssociateezafileswithezANOVA1Click(Sender: TObject);
begin
{$IFNDEF UNIX}
  case MessageDlg('ezANOVA installation:'+chr (13)+'Do you want ezANOVA to automatically open .eza files when you double click on their icons?', mtConfirmation,
     [mbYes, mbNo], 0) of	{ produce the message dialog box }
     mrNo: exit;
  end;
  registerfiletype(kNativeExt,'ezANOVA'{key},'ezANOVA',Application.ExeName+',1');
{$ENDIF}
end;

procedure TMainForm.FontSet;
begin
        DataGrid.Font := GraphSettingsForm.GridFontDialog.Font;
        GridFontResize(DataGrid);
        FormResize(nil);
        ResultsForm.DescriptiveGrid.Font := GraphSettingsForm.GridFontDialog.Font;
        ResultsForm.GridHeight;
        ResultsForm.Memo1.Font :=  GraphSettingsForm.GridFontDialog.Font;
end;

procedure TMainForm.FontBtnClick(Sender: TObject);
begin
  //GraphSettingsForm.GridFontDialog.Font := DataGrid.Font;
  if GraphSettingsForm.GridFontDialog.Execute then
     FontSet;
end;

procedure TMainForm.FormShow(Sender: TObject);
var lFilename: string;
begin
     lFilename := gMRUra[1];
     if fileexists(lFilename) then
      OpenTextFile(lFilename);
     ANOVABtnLabelUpdate;
end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
     CanClose :=  CheckSave2Close(true);
end;

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
     if g64rBufP <> nil then
        freemem(g64rBufP);
     GraphSettingsForm.WriteIniFile;
end;

initialization
  {$i main.lrs}
end.
