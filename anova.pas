unit anova;
{$MODE Delphi}
interface

uses
  LCLIntf, LResources,
  SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Spin, Grids,Utils, Buttons, ExtCtrls,anovafx;

type

  { TANOVAForm }

  TANOVAForm = class(TForm)
    OpenBtn: TButton;
    ALabel: TLabel;
    OKBtn: TButton;
    CancelBtn: TButton;
    AVal: TSpinEdit;
    AEdit: TEdit;
    NameLabel: TLabel;
    LevelLabel: TLabel;
    NamesLabel: TLabel;
    ALevelNames: TStringGrid;
    RowLabel: TLabel;
    RowEdit: TSpinEdit;
    DesignDrop: TComboBox;
    ARepCheck: TCheckBox;
    DesignLabel: TLabel;
    FactorCPanel: TPanel;
    FactorBPanel: TPanel;
    BLabel: TLabel;
    BVal: TSpinEdit;
    BEdit: TEdit;
    BLevelNames: TStringGrid;
    BRepCheck: TCheckBox;
    CLabel: TLabel;
    CVal: TSpinEdit;
    CEdit: TEdit;
    CRepCheck: TCheckBox;
    CLevelNames: TStringGrid;
    WithinLabel: TLabel;
    function doDesign: integer;
    procedure SetFactors(lFactors: integer);
    procedure OKBtnClick(Sender: TObject);
    procedure CValChange(Sender: TObject);
    procedure BValChange(Sender: TObject);
    procedure AValChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure ALevelNamesEnter(Sender: TObject);
    procedure ALevelNamesExit(Sender: TObject);
    procedure BLevelNamesEnter(Sender: TObject);
    procedure BLevelNamesExit(Sender: TObject);
    procedure CLevelNamesEnter(Sender: TObject);
    procedure CLevelNamesExit(Sender: TObject);
    function ComputeANOVA(var lglobalDFError,lglobalMSError: Double): boolean;
    procedure OpenBtnClick(Sender: TObject);
    procedure DesignDropChange(Sender: TObject);
    procedure LoadModel(var m: TANOVAModel);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  ANOVAForm: TANOVAForm;
implementation

uses main, Results,Mat;

procedure TANOVAForm.LoadModel(var m: TANOVAModel);
begin
     m.Alabel := AEdit.text;
     m.Alevels := AVal.Value;
     m.BLabel := BEdit.text;
     m.Blevels := BVal.Value;
     m.CLabel := CEdit.text;
     m.Clevels := CVal.Value;
   m.Design := doDesign;
   if m.Blevels < 2 then begin
        m.vars := 1;
        m.BLevels := 1;
        m.CLevels := 1;
   end else if m.Clevels < 2 then begin
        m.CLevels := 1;
        m.vars := 2
   end else
       m.vars := 3;
end;//proc LoadModel

function TANOVAForm.doDesign: integer;
begin
     result := DesignDrop.itemIndex;
end;


function TANOVAForm.ComputeANOVA(var lglobalDFError,lglobalMSError: Double): boolean;
var
   m: TANOVAModel;
   Results: TStrings;
   lCol,lRow: integer;
   lX: double;
   lEmptyCell: boolean;
begin
     result := false;
     if (gnCol < 2) or (gnRow < 2)  then
        exit;
     lEmptyCell := false;
     m.data := TMatrix.Create (gnRow, gnCol);
     for lCol := 1 to gnCol do begin
         for lRow := 1 to gnRow do begin
             if IsNumX(lRow,lCol,lX) then
               m.data[lRow,lCol] := lX
             else begin
                 m.data[lRow,lCol] := 0;
                 lEmptyCell := true;
             end;
         end; //for row
     end; //for col
     if lEmptyCell then begin
        showmessage('Unable to perform ANOVA - there are empty cells.');
        exit;
     end;
     LoadModel(m);
   Results := TStringList.Create;
   doANOVA (Results, m,  lglobalDFError,lglobalMSError);
   ResultsForm.Memo1.lines.AddStrings(Results);
   Results.free;
   m.data.free;
   result := true;
end;

procedure TANOVAForm.OKBtnClick(Sender: TObject);
begin
    if BVal.value = 1 then
       BVal.Value := 0;
    if CVal.value = 1 then
       CVal.Value := 0;
end;

procedure TANOVAForm.CValChange(Sender: TObject);
var lI,lC: integer;
begin
     if (CVal.value < 2) or (BVal.value < 2) then begin
        CLevelNames.Visible := false;
        CEdit.Visible := false;
        if (BVal.value < 2) then begin
            CVal.value := 0;
        end;
     end else begin
        CLevelNames.Visible := true;
        CEdit.Visible := true;
     lC := CLevelNames.ColCount;
     CLevelNames.ColCount := CVal.Value;
     if lC < CLevelNames.ColCount then begin
        for lI := (lC) to (CLevelNames.ColCount-1) do
            ClevelNames.Cells[lI,0] := 'c'+inttostr(lI+1);
     end;
     end;
end;

procedure TANOVAForm.BValChange(Sender: TObject);
var lI,lC: integer;
begin
    if BVal.value < 2 then begin
        BLevelNames.Visible := false;
        BEdit.Visible := false;
        if (CVal.value > 0) then
           CValChange(nil);
     end else begin
        BLevelNames.Visible := true;
        BEdit.Visible := true;
     lC := BLevelNames.ColCount;
     BLevelNames.ColCount := BVal.Value;
     if lC < BLevelNames.ColCount then begin
        for lI := (lC) to (BLevelNames.ColCount-1) do
            BlevelNames.Cells[lI,0] := 'b'+inttostr(lI+1);
     end;
     end;
end;

procedure TANOVAForm.AValChange(Sender: TObject);
var lI,lC: integer;
begin
     lC := ALevelNames.ColCount;
     ALevelNames.ColCount := AVal.Value;
     if lC < ALevelNames.ColCount then begin
        for lI := (lC) to (ALevelNames.ColCount-1) do
            AlevelNames.Cells[lI,0] := 'a'+inttostr(lI+1);
     end;
end;

procedure TANOVAForm.FormCreate(Sender: TObject);
var lC: integer;
begin
     DesignDrop.Items.Clear;
     for lC := kb1w0 to kb1w2 do
         DesignDrop.Items.Add(kDesignStr[lC]);
     DesignDrop.ItemIndex := 2;
     DesignDropChange(nil);
     AlevelNames.Selection:=TGridRect(Rect(-1,-1,-1,-1));
     BlevelNames.Selection:=TGridRect(Rect(-1,-1,-1,-1));
     ClevelNames.Selection:=TGridRect(Rect(-1,-1,-1,-1));
     AlevelNames.ColCount := 0;
     BlevelNames.ColCount := 0;
     ClevelNames.ColCount := 0;
     AValChange(nil);
     BValChange(nil);
     CValChange(nil);
     //BlevelNames.ColCount := 9;
     //ClevelNames.ColCount := 9;
     MainForm.UpdateLabels;
end;

procedure TANOVAForm.ALevelNamesEnter(Sender: TObject);
begin
     AlevelNames.Selection:=TGridRect(Rect(0,0,0,0));
end;

procedure TANOVAForm.ALevelNamesExit(Sender: TObject);
begin
     AlevelNames.Selection:=TGridRect(Rect(-1,-1,-1,-1));

end;

procedure TANOVAForm.BLevelNamesEnter(Sender: TObject);
begin
     BlevelNames.Selection:=TGridRect(Rect(0,0,0,0));
end;

procedure TANOVAForm.BLevelNamesExit(Sender: TObject);
begin
     BlevelNames.Selection:=TGridRect(Rect(-1,-1,-1,-1));
end;

procedure TANOVAForm.CLevelNamesEnter(Sender: TObject);
begin
     ClevelNames.Selection:=TGridRect(Rect(0,0,0,0));
end;

procedure TANOVAForm.CLevelNamesExit(Sender: TObject);
begin
     ClevelNames.Selection:=TGridRect(Rect(-1,-1,-1,-1));
end;

procedure TANOVAForm.OpenBtnClick(Sender: TObject);
begin
     MainForm.OpenBtnClick(nil);
end;

procedure TANOVAForm.SetFactors(lFactors: integer);
begin
     if lFactors < 2 then begin
        BVal.MinValue := 0;
        BVal.Value := 0;
     end else begin
         if BVal.Value < 2 then
            BVal.Value := 2;
         BVal.MinValue := 2;
     end;
     if lFactors < 3 then begin
        CVal.MinValue := 0;
        CVal.Value := 0
     end else begin
         if CVal.Value < 2 then
            CVal.Value := 2;
         CVal.MinValue := 2;
     end;
end;

procedure TANOVAForm.DesignDropChange(Sender: TObject);
var
    lCond,lFactors: integer;
begin
     lCond := DesignDrop.ItemIndex;
     lFactors := (lCond mod 3) + 1;
     ARepCheck.Checked := lCond in [kb0w1..kb0w3];
     BRepCheck.Checked := lCond in [kb0w2..kb1w1,kb1w2];
     CRepCheck.Checked := lCond in [kb0w3,kb2w1,kb1w2];
     if lCond = 8 then
        lFactors := 3
     else if lCond > 5 then
        inc(lFactors);
     FactorCPanel.Enabled := (lFactors > 2);
     FactorBPanel.Enabled := (lFactors > 1);
     FactorCPanel.Visible := (lFactors > 2);
     FactorBPanel.Visible := (lFactors > 1);
     SetFactors(lFactors);
end;

initialization
  {$i anova.lrs}
end.
