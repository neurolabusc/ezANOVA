unit graphsettings;
{$MODE Delphi}
interface

uses
  LCLIntf,  LResources,
  Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Spin, ExtCtrls,Buttons,IniFiles,UserDir;

type

  { TGraphSettingsForm }

  TGraphSettingsForm = class(TForm)
    FontBtn: TButton;
    Color1: TSpinEdit;
    Color2: TSpinEdit;
    Color3: TSpinEdit;
    Color4: TSpinEdit;
    Color5: TSpinEdit;
    Color6: TSpinEdit;
    Color7: TSpinEdit;
    Color8: TSpinEdit;
    Fill1Check: TCheckBox;
    Fill2Check: TCheckBox;
    Fill3Check: TCheckBox;
    Fill4Check: TCheckBox;
    Fill5Check: TCheckBox;
    Fill6Check: TCheckBox;
    Fill7Check: TCheckBox;
    Fill8Check: TCheckBox;
    MinLabel: TLabel;
    MaxLabel: TLabel;
    TickLabel: TLabel;
    LineBox: TGroupBox;
    MaxRangeEdit: TFloatSpinEdit;
    MinRangeEdit: TFloatSpinEdit;
    RangeBox: TGroupBox;
    LineLabel: TLabel;
    NodeLabel: TLabel;
    MonochromeCheck: TCheckBox;
    NodeSize: TSpinEdit;
    Shape1Edit: TSpinEdit;
    Shape2Edit: TSpinEdit;
    Shape3Edit: TSpinEdit;
    Shape4Edit: TSpinEdit;
    Shape5Edit: TSpinEdit;
    Shape6Edit: TSpinEdit;
    Shape7Edit: TSpinEdit;
    Shape8Edit: TSpinEdit;
    TitleEdit: TEdit;
    TitleLabel: TLabel;
    OKBtn: TButton;
    VertLabel: TLabel;
    VerticalLabelEdit: TEdit;
    ThickLabel: TLabel;
    PenThickEdit: TSpinEdit;
    GridCheck: TCheckBox;
    HorLabel: TLabel;
    HorEdit: TEdit;
    ShowLegendCheck: TCheckBox;
    SquareCheck: TCheckBox;
    GraphFontDialog: TFontDialog;
    GridFontDialog: TFontDialog;
    VertSpacing: TFloatSpinEdit;
    procedure Update(Sender: TObject);
    procedure SetNumLines(lines: integer);
    procedure OKBtnClick(Sender: TObject);
    procedure FontBtnClick(Sender: TObject);
    procedure WriteIniFile;
    procedure ReadIniFile;
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

const
  kMaxMRU = 5;
var
  GraphSettingsForm: TGraphSettingsForm;
  gMRUra: array [1..kMaxMRU] of string=('','','','','');
implementation

uses Graph, main;

//next - ini file code
function Bool2Char (lBool: boolean): char;
begin
	if lBool then
		result := '1'
	else
		result := '0';
end;
function Char2Bool (lChar: char): boolean;
begin
	if lChar = '1' then
		result := true
	else
		result := false;
end;

function SaveIniFont(lIniFile: TIniFile; lIdent: string; var lGFD: TFontDialog): string;
begin
     lIniFile.WriteString('FNTID',lIdent,(lGFD.Font.Name));
     lIniFile.WriteString('FNTSZ',lIdent,inttostr(lGFD.Font.Size));
end;

function IniFont(lIniFile: TIniFile; lIdent: string; var lGFD: TFontDialog): string;
var
	lStr: string;
begin
	lStr := lIniFile.ReadString('FNTID',lIdent, '');
	if length(lStr) < 1 then
		exit;
        lGFD.Font.Name := lStr;
	lStr := lIniFile.ReadString('FNTSZ',lIdent, '');
	if length(lStr) < 1 then
		exit;
        lGFD.Font.Size := strtoint(lStr);
end; //nested IniStr

function IniStr(lIniFile: TIniFile; lIdent,lDefault: string): string;
var
	lStr: string;
begin
	result := lDefault;
	lStr := lIniFile.ReadString('STR',lIdent, '');
	if length(lStr) > 0 then
		result :=(lStr);
end; //nested IniStr

function IniInt(lIniFile: TIniFile; lIdent: string;  lDefault: integer): integer;
var
	lStr: string;
begin
	result := lDefault;
	lStr := lIniFile.ReadString('INT',lIdent, '');
	if length(lStr) > 0 then
		result := StrToInt(lStr);
end; //nested IniInt

function IniBool(var lIniFile: TIniFile; lIdent: string;  lDefault: boolean): boolean;
var
   lStr: string;
begin
  result := lDefault;
  lStr := lIniFile.ReadString('BOOL',lIdent, '');
  if length(lStr) > 0 then
     result := Char2Bool(lStr[1]);
end; //nested IniBool

procedure TGraphSettingsForm.SetNumLines(lines: integer);
var
   i: integer;
begin

  if lines < 1 then exit;
  for i:=0 to LineBox.ControlCount-1 do
    LineBox.Controls[i].Enabled := (LineBox.Controls[i].tag) <= lines; // or just 'False' / 'True'
end;

procedure TGraphSettingsForm.ReadIniFile;
var
  lFilename: string;
  lIniFile: TIniFile;
  lInc: integer;
begin
  lFilename := IniName;
  if not Fileexists(lFilename) then
     exit;
  lIniFile := TIniFile.Create(lFilename);
  MonochromeCheck.checked := IniBool(lIniFile,'Monochrome',false);
  GridCheck.checked := IniBool(lIniFile,'Grid',true);
  ShowLegendCheck.checked := IniBool(lIniFile,'Legend',true);
  SquareCheck.checked := IniBool(lIniFile,'Square',false);
  for lInc := 1 to kMaxMRU do
      gMRUra[lInc] := IniStr(lIniFile,'MRU'+inttostr(lInc),'');
  NodeSize.value := IniInt(lIniFile,'NodeSz',3);
  MainForm.width := IniInt(lIniFile,'GridWid',640);
  MainForm.height := IniInt(lIniFile,'GridHt',480);
  IniFont(lIniFile,'GRID',GridFontDialog);
  IniFont(lIniFile,'GRAPH',GraphFontDialog);
  MainForm.FontSet;
  lIniFile.Free;
end; //ReadIniFile

procedure TGraphSettingsForm.WriteIniFile;
var
  lIniName: string;
  lIniFile: TIniFile;
  lInc: integer;
begin
     lIniName := IniName;
     lIniFile := TIniFile.Create(lIniName);
     lIniFile.WriteString('BOOL', 'Monochrome',Bool2Char(MonochromeCheck.checked));
     lIniFile.WriteString('BOOL', 'Grid',Bool2Char(GridCheck.checked));
     lIniFile.WriteString('BOOL', 'Legend',Bool2Char(ShowLegendCheck.checked));
     lIniFile.WriteString('BOOL', 'Square',Bool2Char(SquareCheck.checked));
     for lInc := 1 to kMaxMRU do
         lIniFile.WriteString('STR','MRU'+inttostr(lInc),gMRUra[lInc]);
     lIniFile.WriteString('INT','NodeSz',inttostr(NodeSize.value));
     lIniFile.WriteString('INT','GraphWid',inttostr(GraphForm.width));
     lIniFile.WriteString('INT','GraphHt',inttostr(GraphForm.Height));
     lIniFile.WriteString('INT','GridWid',inttostr(MainForm.width));
     lIniFile.WriteString('INT','GridHt',inttostr(MainForm.Height));
     SaveIniFont(lIniFile,'GRID',GridFontDialog);
     SaveIniFont(lIniFile,'GRAPH',GraphFontDialog);
     lIniFile.Free;
end;

procedure TGraphSettingsForm.Update(Sender: TObject);
begin
     GraphForm.DrawGraph('',false,false);
end;

procedure TGraphSettingsForm.OKBtnClick(Sender: TObject);
begin
   GraphSettingsForm.Close;
end;

procedure TGraphSettingsForm.FontBtnClick(Sender: TObject);
begin
     if GraphFontDialog.Execute then
        GraphForm.DrawGraph('',false,false);
end;

procedure TGraphSettingsForm.FormCreate(Sender: TObject);
var
   lStr: string;
begin
  ReadIniFile;
  if ParamCount > 0 then begin
       lStr := ParamStr(1);
       MainForm.OpenTextFile(lStr);
  end else begin
       MainForm.ANOVABtnLabelUpdate;
       MainForm.UpdateMRUMenu;
       MainForm.OpenTextFile(lStr);
  end;
end;

initialization
  {$i graphsettings.lrs}
end.
