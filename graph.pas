unit graph;
{$MODE Delphi}
{$IFDEF LCLCocoa}
{$ModeSwitch objectivec1}
{$ENDIF}
interface

uses
 {$IFDEF LCLCocoa}MacOSAll, CocoaAll,{$ENDIF}
 LCLIntf,LResources,
 SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Buttons, ComCtrls, ExtCtrls,ClipBrd,Utils,GraphSettings,
  Menus, StdCtrls, Spin, ToolWin;
const
     kMaxCol = 2000;
     kMaxRow = 10;
     knItem = 10;
type
  TGraphData = record
    Row, Col: Integer;
    RA: array [1..kMaxCol,1..kMaxRow] of single;
    ColStr: array [1..kMaxCol] of string[255];
    RowStr: array [1..kMaxRow] of string[255];
  end;
  TBezPts= array [1..kMaxCol] of TPoint;

  { TGraphForm }

  TGraphForm = class(TForm)
    ErrorDrop: TComboBox;
    Factor3Edit: TSpinEdit;
    FactorDrop: TComboBox;
    OptionBtn: TButton;
    ToolPanel: TPanel;
    RefreshMenu: TMenuItem;
    SaveDialog1: TSaveDialog;
    Image1: TImage;
    MainMenu1: TMainMenu;
    File1: TMenuItem;
    SaveMenu: TMenuItem;
    CloseMenu: TMenuItem;
    Edit1: TMenuItem;
    CopyMenu: TMenuItem;
    View1: TMenuItem;
    FontMenu: TMenuItem;
    OptionsMenu: TMenuItem;
    procedure FormResize(Sender: TObject);
    procedure RefreshBtnClick(Sender: TObject);
    procedure DrawGraph (lFilename: string; lCopyToClipBoard,lPrint: boolean);
    procedure CopyBtnClick(Sender: TObject);
    procedure FontBtn2Click(Sender: TObject);
    procedure SaveBtnClick(Sender: TObject);
    procedure SetupBtnClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    function ReadGraf: boolean;
    procedure FormShow(Sender: TObject);
    procedure FactorDropChange(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  GraphForm: TGraphForm;
  gGraphData: TGraphData;
implementation
uses anovafx,anova, Results;


{$IFDEF LCLCocoa}
type
NSScreenFix = objccategory external (NSScreen)
function backingScaleFactor: CGFloat ; message 'backingScaleFactor';
end;
{$ENDIF}

var
kBGClr : TColor = clWhite;// $00C8FAF0;//clWhite;
kGridClr: TColor = clSilver;// $00B0E0FF;
kForeClr : TColor = clBlack;
 gMarkerShape: array [1..kMaxCol] of integer;
 gMarkerFill: array [1..kMaxCol] of boolean;
 gActive : boolean = false;
 gItemColorRA: array [1..knItem] of integer =
    (clBlue,clRed,clGreen,clYellow,clLime,clFuchsia,clAqua,clGray,clBlack,clMaroon);
 gMarkerColor: array [1..kMaxCol] of TColor;
const
 kAB = 0;
 kBA = 1;
 kAC = 2;
 kCA = 3;
 kBC = 4;
 kCB = 5;
 kGrafStr: array [kAB..kCB] of string =
('AxB',
'BxA',
'AxC',
'CxA',
'BxC',
'CxB');

function AutoRange: boolean;
var
    lRow,lCol: integer;
    lMinMaxNotSet: boolean;
    lErrorHt,lStep,lGraphMin,lGraphMax,lRange,lX,lMin,lMax: double;
begin
     result := false;
     if (gGraphData.Row < 1) or (gGraphData.Col < 1) then
        exit;
     lMin := 0;
     lMax := 0;
     lMinMaxNotSet := true;
     for lCol := 1 to gGraphData.Col do begin
         for lRow := 1 to gGraphData.Row do begin
             lX := gGraphData.RA[lCol,lRow];
             lErrorHt := 0; //ERROR
             //showmessage(floattostr(lX));
                if lMinMaxNotSet then begin
                   lMinMaxNotSet := false;
                   lMin := lX-abs(lErrorHt);
                   lMax := lX+abs(lErrorHt);
                end else if (lX-abs(lErrorHt)) < lMin then
                    lMin := lX-abs(lErrorHt)
                else if (lX+abs(lErrorHt)) > lMax then
                     lMax := lX+abs(lErrorHt);

         end; //for Row
     end; //for Col
     lRange := lMax - lMin;
     lStep := 0;
     if lRange = 0 then lStep := 0
     else if lRange <= 1 then lStep := 0.1
     else if lRange <= 10 then lStep := 1
     else if lRange <= 100 then lStep := 10
     else if lRange <= 250 then lStep := 25
     else if lRange <= 500 then lStep := 50
     else if lRange <= 1000 then lStep := 100
     else if lRange <= 2500 then lStep := 250
     else if lRange <= 5000 then lStep := 500
     else if lRange <= 10000 then lStep := 1000;
     if lStep = 0 then begin
         lGraphMin := lMin;
         lGraphMax := lMax;
     end else begin

         if (lMin/lStep) = 0 then
            lGraphMin := lMin
         else begin
             lGraphMin := trunc(lMin / lStep) * lStep;
             if lMin < 0 then
                lGraphMin := lGraphMin-lStep; //fxfx
         end;
         if (lMax/lStep) = 0 then
            lGraphMax := lMax
         else
             lGraphMax := trunc((lMax+lStep) / lStep) * lStep;
     end;
     GraphSettingsForm.MinRangeEdit.value := (lGraphMin);
     GraphSettingsForm.MaxRangeEdit.value := (lGraphMax);
     GraphSettingsForm.VertSpacing.value := (lStep);
     result := true;
end;

procedure ReadVal (lA,lB,lC,lError: integer; var m: TANOVAModel; var lMeanVal,lErrorVal: Single);
var
   lCol: integer;
begin
     lCol := lC + ((lB-1)* m.CLevels) + ((lA-1)* m.BLevels* m.CLevels);
     lMeanVal := strtofloat(ResultsForm.DescriptiveGrid.Cells[lCol,kMaxFactors+1]);
     lErrorVal := strtofloat(ResultsForm.DescriptiveGrid.Cells[lCol,kMaxFactors+1+lError]);
end;

function TGraphForm.ReadGraf: boolean;
label
     666;
var
   lColStr,lFactor3Txt: string;
   m: TANOVAModel;
   lRows,lC,lR,lAxis,lFactor3,lErrorBars: integer;

begin
     lErrorBars := ErrorDrop.ItemIndex;
     //result := false;
     gActive := false;
     ANOVAForm.LoadModel(m);
     lAxis := FactorDrop.ItemIndex;
     if m.Vars > 2 then
        lFactor3 := Factor3Edit.value
     else
         lFactor3 := 1;
     if m.Vars = 1 then begin
        lAxis := kAB;
        gGraphData.Row := 2;
        gGraphData.RowStr[1] := m.Alabel;
     end else case lAxis of //set rows
          kBA,kCA: begin
               gGraphData.Row := m.Alevels*2;//*2 for error bars
               for lR := 1 to m.Alevels do
                   gGraphData.RowStr[lR] := ANOVAForm.ALevelNames.Cells[lR-1,0];
          end;
          kAB,kCB: begin
               gGraphData.Row := m.Blevels*2;//*2 for error bars
               for lR := 1 to m.Blevels do
                   gGraphData.RowStr[lR] := ANOVAForm.BLevelNames.Cells[lR-1,0];

          end;
          kAC,kBC: begin
               gGraphData.Row := m.Clevels*2;//*2 for error bars
               for lR := 1 to m.Clevels do
                   gGraphData.RowStr[lR] := ANOVAForm.CLevelNames.Cells[lR-1,0];

          end;
     end; //set rows
     case lAxis of //set cols
          kAB,kAC: begin
               gGraphData.Col := m.Alevels;
               for lR := 1 to m.Alevels do
                   gGraphData.ColStr[lR] := ANOVAForm.ALevelNames.Cells[lR-1,0];

          end;
          kBA,kBC: begin
               gGraphData.Col := m.Blevels;
               for lR := 1 to m.Blevels do
                   gGraphData.ColStr[lR] := ANOVAForm.BLevelNames.Cells[lR-1,0];
          end;
          kCA,kCB: begin
               gGraphData.Col := m.Clevels;
               for lR := 1 to m.Clevels do
                   gGraphData.ColStr[lR] := ANOVAForm.CLevelNames.Cells[lR-1,0];
          end;
     end; //set cols
     //set titles
     lFactor3Txt := '';
     if m.Vars = 1 then begin
        GraphSettingsForm.TitleEdit.text := m.Alabel;
        for lC := 1 to gGraphData.Col do
            gGraphData.RA[lC,1] := strtofloat(ResultsForm.DescriptiveGrid.Cells[lC,kMaxFactors+1]);// := 'Mean';;
        for lC := 1 to gGraphData.Col do
            gGraphData.RA[lC,2] := strtofloat(ResultsForm.DescriptiveGrid.Cells[lC,kMaxFactors+1+lErrorBars]);// := 'Mean';;
     end else begin //> 1 var
         case lAxis of //set Titles
          kAB,kBA: begin
               if m.Vars > 2 then
                  lFactor3Txt := ' at '+ANOVAForm.CLevelNames.Cells[lFactor3-1,0];
               GraphSettingsForm.TitleEdit.text := m.Alabel+'*'+m.BLabel+lFactor3Txt;
          end;
          kAC,kCA: begin
               if m.Vars > 2 then
                  lFactor3Txt := ' at '+ANOVAForm.BLevelNames.Cells[lFactor3-1,0];
               GraphSettingsForm.TitleEdit.text := m.Alabel+'*'+m.CLabel+lFactor3Txt;
          end;
          else {kBC,kCB:} begin
               if m.Vars > 2 then
                  lFactor3Txt := ' at '+ANOVAForm.ALevelNames.Cells[lFactor3-1,0];
               GraphSettingsForm.TitleEdit.text := m.Blabel+'*'+m.CLabel+lFactor3Txt;
          end;
         end; //case lAxis: set titles
         lRows := gGraphData.Row div 2;
         case lAxis of //loadgraf
          kAB: begin
               for lR := 1 to lRows do
                   for lC := 1 to gGraphData.Col do
                       ReadVal (lC,lR,lFactor3,lErrorBars,m,gGraphData.RA[lC,lR],gGraphData.RA[lC,lR+lRows]);
          end;
          kBA: begin
               for lR := 1 to lRows do
                   for lC := 1 to gGraphData.Col do
                       ReadVal (lR,lC,lFactor3,lErrorBars,m,gGraphData.RA[lC,lR],gGraphData.RA[lC,lR+lRows]);
          end;
          kAC: begin
               for lR := 1 to lRows do
                   for lC := 1 to gGraphData.Col do
                       ReadVal (lC,lFactor3,lR,lErrorBars,m,gGraphData.RA[lC,lR],gGraphData.RA[lC,lR+lRows]);
          end;
          kCA: begin
               for lR := 1 to lRows do
                   for lC := 1 to gGraphData.Col do
                       ReadVal (lR,lFactor3,lC,lErrorBars,m,gGraphData.RA[lC,lR],gGraphData.RA[lC,lR+lRows]);
          end;
          kBC: begin
               for lR := 1 to lRows do
                   for lC := 1 to gGraphData.Col do
                       ReadVal (lFactor3,lC,lR,lErrorBars,m,gGraphData.RA[lC,lR],gGraphData.RA[lC,lR+lRows]);
          end;
          kCB: begin
               for lR := 1 to lRows do
                   for lC := 1 to gGraphData.Col do
                       ReadVal (lFactor3,lR,lC,lErrorBars,m,gGraphData.RA[lC,lR],gGraphData.RA[lC,lR+lRows]);
          end;
         end; //case lAxis: loadgraf
     end; //>1 var
     result := AutoRange;
     gActive := true;
     GraphForm.DrawGraph('',false,false);
     exit;
666:
    showmessage('This software can not read files with more than '+inttostr(kMaxCol)+' columns and '+inttostr(kMaxRow)+' rows.');
     result := AutoRange;
     gActive := true;
     //GraphForm.DrawGraph('',false,false);
end;

procedure TGraphForm.RefreshBtnClick(Sender: TObject);
begin
     DrawGraph('',false,false);
end;

procedure TGraphForm.FormResize(Sender: TObject);
begin
  DrawGraph('',false,false);
end;

function ReturnColor (lLine: integer): integer;
begin
       result := gMarkerColor[lLine];
end;

function ColorBound(lColor: integer): TColor;
var
   lByte: integer;
begin
    if (lColor < 1) or (lColor > (knItem)) then begin
        result := clBlack;
        exit;
    end;
    //result := lColor;
    if not GraphSettingsForm.MonochromeCheck.Checked then
       result := gItemColorRA[lColor]
    else begin
        lByte := round((255*(lColor-1))/knItem);
        result := TColor(lByte+(lByte shl 8)+(lByte shl 16) );
    end;
end;

procedure MarkerShapes;
var
   lInc: integer;
begin
    for lInc := 1 to kMaxCol do
       gMarkerShape[lInc] := (lInc mod 8) + 1;
   with GraphSettingsForm do begin
        gMarkerShape[1] := Shape1Edit.value;
        gMarkerFill[1] := Fill1Check.Checked;
        gMarkerShape[2] := Shape2Edit.value;
        gMarkerFill[2] := Fill2Check.Checked;
        gMarkerShape[3] := Shape3Edit.value;
        gMarkerFill[3] := Fill3Check.Checked;
        gMarkerShape[4] := Shape4Edit.value;
        gMarkerFill[4] := Fill4Check.Checked;
        gMarkerShape[5] := Shape5Edit.value;
        gMarkerFill[5] := Fill5Check.Checked;
        gMarkerShape[6] := Shape6Edit.value;
        gMarkerFill[6] := Fill6Check.Checked;
        gMarkerShape[7] := Shape7Edit.value;
        gMarkerFill[7] := Fill7Check.Checked;
        gMarkerShape[8] := Shape8Edit.value;
        gMarkerFill[8] := Fill8Check.Checked;
        gMarkerColor[1] := ColorBound(Color1.value);
        gMarkerColor[2] := ColorBound(Color2.value);
        gMarkerColor[3] := ColorBound(Color3.value);
        gMarkerColor[4] := ColorBound(Color4.value);
        gMarkerColor[5] := ColorBound(Color5.value);
        gMarkerColor[6] := ColorBound(Color6.value);
        gMarkerColor[7] := ColorBound(Color7.value);
        gMarkerColor[8] := ColorBound(Color8.value);
   end;
end;

function IsDrawCol(lCol,lnDrawCol,lnCol: integer): boolean;
var
   lV,lfudge: single;
begin
    result := true;
    if (lCol = lnCol) or (lCol = 1) or (lnCol < 2) or (lnDrawCol < 2) then
       exit;
    lV := (lnCol-1)/(lnDrawCol-1);
    if lV = 0 then
       exit;
    lFudge := (lnDrawCol-1)/(lnCol);
    lV := abs(frac((lCol-1)/lV));
    if lV >  lfudge then
       result := false;
end;

function GraphPt(lCol,lLine,lGraphLeft,lGraphBottom,lColWid: integer; lMinVal,lYMult: double; var lSlope: double): TPoint;
begin
     result.X := lGraphLeft+ ((lCOl-1)*lColWid);
     result.Y := lGraphBottom-round(lYMult * (gGraphData.RA[lCol,lLine]-lMinVal));
     if (lCol > 1) then
         lSlope :=  gGraphData.RA[lCol,lLine]-gGraphData.RA[lCol-1,lLine]
     else
         lSlope := -5;
end;

function DeciPlaces(lVertSpacing: double): integer;
var
   lStr: String;
   lP: integer;
begin
  if (lVertSpacing = trunc(lVertSpacing)) then result := 0
  else begin
       lStr := IntToStr(round(lVertSpacing*100000));
       lP := length(lStr);
       while (lP > 0) and (lStr[lP] = '0') do
             dec(lP);
       result := 5-(length(lStr)-lP);
  end;
end;

function InterPt (var lBezPts: TBezPts; lPos: single; lnPts: integer): TPoint;
var
   lRemainder: single;
   lTrunc: integer;
begin
   lTrunc := trunc(lPos);
   lRemainder := lPos - lTrunc;
   if (lRemainder = 0) or (lTrunc < 1) or ((lTrunc+1)> lnPts)then  begin
      result := lBezPts[round(lPos)];
      exit;
   end;
   result.X := round ( (lBezPts[lTrunc].X*(1-lRemainder))+(lBezPts[ltrunc+1].X*(lRemainder)) );
   result.Y := round( (lBezPts[lTrunc].Y*(1-lRemainder))+(lBezPts[ltrunc+1].Y*(lRemainder))   );
end;

procedure TGraphForm.DrawGraph (lFilename: string; lCopyToClipBoard,lPrint: boolean);
var
   lStr,lFilenameExt: String;
   //png: TPortableNetworkGraphic;
   lErrorBars: boolean;
  lScale: single;
  lnDrawCol,lLegendWid,lnLines,lPos,lnCol,lLine,lNodeSz,
  lLegendLineLen,lT,lR,lB,
  lTxtWid,lTxtHtDiv2,lDecimalPlaces,lRow,lCol,lX,lY,lGraphTop,lGraphBottom,
  lGraphLeft,lGraphRight,lWid,lHt,lColWid,lFrameBorder,lnPolyPts,lLegL: integer;
  lPt,lPrevPt: TPoint;
  lPolyPts: TBezPts;
  lSlope,lPrevSlope,lVertSpacing,lMinVal,lMaxVal,lVal,lYMult: double;
begin
     if not gActive then exit;
     MarkerShapes;
     lFrameBorder := 3+GraphSettingsForm.PenThickEdit.value;
     lnCol := gGraphData.Col;
     lnLines := gGraphData.Row;
     if (lnLines < 1) or (lnCol < 1) then exit;
     lErrorBars :=  (GraphForm.ErrorDrop.itemindex > 0);
 if (lErrorBars) and odd(lnLines) then begin
    lErrorBars := false;
    showmessage('Error bars require even number of lines.');
 end;
 //due to error bars there are half as many lines... if (lErrorBars) then
     lnLines := lnLines div 2;
 if not gActive then exit;
 lHt := Image1.ClientHeight;
 lWid := Image1.ClientWidth;
 lScale := 1;
 {$IFDEF LCLCocoa}
 lScale := (NSScreen.mainScreen.backingScaleFactor);
 {$ELSE}
 lScale := 1;
 {$ENDIF}
 if lCopyToClipBoard or lPrint then
     lScale := 2;
 lHt := round(lHt * lScale);
 lWid :=  round(lWid * lScale);
 Image1.Picture.Bitmap.Width:=lWid;
 Image1.Picture.Bitmap.Height:=lHt;
 //Image1.Picture.Bitmap.PixelFormat := pf32bit; //<- this can disrupt PNG creation on Windows OS
lVertSpacing := GraphSettingsForm.VertSpacing.value;
lMinVal := GraphSettingsForm.MinRangeEdit.value;
lMaxVal := GraphSettingsForm.MaxRangeEdit.value;
lNodeSz := GraphSettingsForm.NodeSize.value;
lNodeSz := lNodeSz - (GraphSettingsForm.PenThickEdit.value div 2);
lDecimalPlaces := DeciPlaces(lVertSpacing);
Image1.Canvas.Font := GraphSettingsForm.GraphFontDialog.Font;
//Image1.Canvas.Font.Size := round(Image1.Canvas.Font.Size  * lScale);
lTxtHtDiv2 := (Image1.Canvas.TextHeight('X')+1) div 2;
if (lNodeSz+1) > lTxtHtDiv2 then
   lTxtHtDiv2 := (lNodeSz+1);
inc(lTxtHtDiv2);
lGraphTop := 15+(lTxtHtDiv2*2);
lGraphBottom := lHt - 6-(4*lTxtHtDiv2);
lLegendWid := 0;
lLegendLineLen := 8;
if {(lnLines > 1) and} (GraphSettingsForm.ShowLegendCheck.checked) then begin //compute size of figure legend
   lTxtWid := Image1.Canvas.TextWidth(gGraphData.RowStr[1]);
   for lRow := (lnLines) downto 1 do begin
       lPos := Image1.Canvas.TextWidth(gGraphData.RowStr[lRow]);
       if lPos > lTxtWid then lTxtWid := lPos;
   end;
   lLegendLineLen := (6*lNodeSz);
   if lLegendLineLen < 12 then
      lLegendLineLen := 12;
   lLegendWid := lTxtWid+lLegendLineLen+(3*lFrameBorder);// lTxtWid is the length of the longest label
end; //multiple lines/factors
lTxtWid := Image1.Canvas.TextWidth(realtostr(lMaxVal,lDecimalPlaces))+8+lFrameBorder;
lGraphLeft := 10 + lTxtWid{space for labels}+(lTxtHtDiv2*2) {space for vertical title};
lGraphRight := lWid - lNodeSz - lFrameBorder- lFrameBorder-lLegendWid;
if (GraphSettingsForm.SquareCheck.checked) then begin
   if (lGraphRight-lGraphLeft) > (lGraphBottom-lGraphTop) then
      lGraphRight := lGraphLeft + (lGraphBottom-lGraphTop)
   else
       lGraphBottom := lGraphTop + (lGraphRight-lGraphLeft);
end;
lColWid := (lGraphRight-lGraphLeft) div (lnCol-1);
lGraphRight := lGraphLeft + (lColWid * (lnCol-1));
if lMaxVal > lMinVal then
   lYMult := (lGraphBottom-lGraphTop) / (lMaxVal-lMinVal)
else
    lYMult := 1;
With Image1.Canvas do begin
 Font := GraphSettingsForm.GraphFontDialog.Font;
 Font.Color := kForeClr;
 Pen.Color := kForeClr;
 Pen.Width := GraphSettingsForm.PenThickEdit.value;
 Brush.Color := kBGClr;
 Brush.Style := bsSolid;
 FillRect(Rect(0,0,lWid,lHt));
 Brush.Color := kForeClr;//LtGray;
 Brush.Style := bsClear;
 //Next: draw legend
 if {(lnLines > 1) and} (lLegendWid > 0) then begin
   lT := (lTxtHtDiv2*2)-1-lFrameBorder;
   //lB := 1+((lnLines+1)*2*lTxtHtDiv2);
   lB := round((1+lnLines)*(lTxtHtDiv2*2))+lFrameBorder;
   lLegL := lGraphRight + lFrameBorder+lFrameBorder;
   lR := lLegL + lLegendWid{-lFrameBorder};
   Rectangle(lLegL,lT,lR,lB);
   Brush.Color := kBGClr;
   for lLine := 1 to lnLines do begin
       lStr := gGraphData.RowStr[lLine];
       lY := ((lLine)*2*lTxtHtDiv2){+lTxtHtDiv2};
       Brush.Style := bsClear;
       TextOut({lWid-lLegendWid}lLegL+ lLegendLineLen+(2*GraphSettingsForm.PenThickEdit.value),lY,lStr);
       lY := lY + lTxtHtDiv2;
       Pen.Color := ReturnColor(lLine);
       moveto({lWid-lLegendWid}lLegL+GraphSettingsForm.PenThickEdit.value, lY);
       lineto({lWid-lLegendWid}lLegL+lLegendLineLen+GraphSettingsForm.PenThickEdit.value, lY);
       lX := {lWid-lLegendWid}lLegL+round(lLegendLineLen div 2)+GraphSettingsForm.PenThickEdit.value;
       if lNodeSz > 0 then begin
          Brush.Style := bsSolid;
          if gMarkerFill[lLine]  then
              Brush.Color := Pen.Color
          else
             Brush.Color := kBGClr;
          case gMarkerShape[lLine] of
               1: Ellipse(lX-lNodeSz,lY-lNodeSz,lX+lNodeSz,lY+lNodeSz);
               2: Rectangle(lX-lNodeSz,lY-lNodeSz,lX+lNodeSz,lY+lNodeSz);
               3:Polygon([Point(lX,lY-lNodeSz),Point(lX-lNodeSz,lY),Point(lX,lY+lNodeSz),Point(lX+lNodeSz,lY)]);

               4:Polygon([Point(lX,lY-lNodeSz),Point(lX-lNodeSz,lY+lNodeSz),Point(lX+lNodeSz,lY+lNodeSz)]);
               5: Polygon([Point(lX,lY+lNodeSz),Point(lX-lNodeSz,lY-lNodeSz),Point(lX+lNodeSz,lY-lNodeSz)]);
               6: begin //x
                  MoveTo(lX-lNodeSz,lY-lNodeSz);
                  LineTo(lX+lNodeSz,lY+lNodeSz);
                  MoveTo(lX+lNodeSz,lY-lNodeSz);
                  LineTo(lX-lNodeSz,lY+lNodeSz);
               end;
               7: begin //+
                  MoveTo(lX,lY-lNodeSz);
                  LineTo(lX,lY+lNodeSz);
                  MoveTo(lX+lNodeSz,lY);
                  LineTo(lX-lNodeSz,lY);
               end;
               8: begin//*
                  MoveTo(lX-lNodeSz,lY-lNodeSz);
                  LineTo(lX+lNodeSz,lY+lNodeSz);
                  MoveTo(lX+lNodeSz,lY-lNodeSz);
                  LineTo(lX-lNodeSz,lY+lNodeSz);
                  MoveTo(lX,lY-lNodeSz);
                  LineTo(lX,lY+lNodeSz);
                  MoveTo(lX+lNodeSz,lY);
                  LineTo(lX-lNodeSz,lY);
               end;
          end; //case
          Brush.Color := clWhite;
       end; //nodesz > 0
       Pen.Color := kForeClr;
   end;
 end;
 //next = border for graphics
    Pen.Color := kForeClr;
 Brush.Style := bsClear;//LtGray;
  Rectangle(lGraphLeft-lFrameBorder, lGraphBottom+lFrameBorder,lGraphRight+lFrameBorder, lGraphTop-lFrameBorder);
 //Next: draw grid lines and vertical range
 Brush.Color := kBGClr;
 Pen.Color := kForeClr;//clLtGray; //clSilver;
 if lVertSpacing > 0 then begin
    lY := lGraphBottom;
    TextOut(lGraphLeft-lTxtWid,lY-lTxtHtDiv2,realtostr(lMinVal,lDecimalPlaces));
        if GraphSettingsForm.GridCheck.Checked then begin
           Pen.Width := 1;
           Pen.Color := kGridClr;
           MoveTo(lGraphLeft {-lFrameBorder},lY);
           LineTo(lGraphRight{+lFrameBorder},lY);
           Pen.Width := GraphSettingsForm.PenThickEdit.value;
        end;
    //MoveTo(lGraphLeft-3,lY);
    //LineTo(lGraphRight+3,lY);
    lVal := trunc((lMinVal+lVertSpacing) / lVertSpacing)*lVertSpacing;
    while lVal <= lMaxVal do begin
        lY := lGraphBottom-round(lYMult * (lVal-lMinVal));

        if GraphSettingsForm.GridCheck.Checked then begin
           Pen.Width := 1;
           Pen.Color := kGridClr;
           MoveTo(lGraphLeft {-lFrameBorder},lY);
           LineTo(lGraphRight{+lFrameBorder},lY);
           Pen.Width := GraphSettingsForm.PenThickEdit.value;
        end;
        TextOut(lGraphLeft-lTxtWid,lY-lTxtHtDiv2,realtostr(lVal,lDecimalPlaces));
        lVal := lVal + lVertSpacing;
    end;
    //lY := lGraphBottom-round(lYMult * (lMaxVal-lMinVal));
 end;
//Next: vertical label
 lStr := GraphSettingsForm.VerticalLabelEdit.Text;
 lTxtWid := TextWidth(lStr) div 2;
  TextOut(5, lTxtWid+lGraphTop+((lGraphBottom-lGraphTop)div 2) , lStr);
 Font.Size := Font.Size+2;
 lStr := GraphSettingsForm.TitleEdit.Text;
 lTxtWid := TextWidth(lStr) div 2;
 Textout(lGraphLeft+((lGraphRight-lGraphLeft)div 2)-lTxtWid ,4,lStr);
 Font.Size := Font.Size-2;
 lStr := GraphSettingsForm.HorEdit.Text;
 lTxtWid := TextWidth(lStr) div 2;
 Textout(lGraphLeft+((lGraphRight-lGraphLeft)div 2)-lTxtWid ,lGraphBottom+(lTxtHtDiv2*2)+2+lFrameborder,lStr);
 //vertical lines obscure error bars
 lnDrawCol := lnCol;
 for lCol := 1 to lnCol do begin
  Pen.Color := kForeClr;
  if IsDrawCol(lCol,lnDrawCol,lnCol) then begin
     lX := lGraphLeft+ ((lCol-1)*lColWid);
     if GraphSettingsForm.GridCheck.Checked then begin
         pen.Color := kGridClr;
         Pen.Width := 1;
         MoveTo(lX,lGraphTop);
         LineTo(lX,lGraphBottom );
         Pen.Width := GraphSettingsForm.PenThickEdit.value;
         pen.Color := kForeClr;
     end else
         MoveTo(lX,lGraphBottom );

     LineTo(lX,lGraphBottom +lFrameBorder+lFrameBorder);
     lStr := gGraphData.ColStr[lCol];
     lTxtWid := (TextWidth(lStr))div 2;
     Textout(lX-lTxtWid ,4+ lGraphBottom+lFrameborder+lFrameborder,lStr);
  end;//if lCol
 end;
 for lLine := 1 to lnLines do begin
     Pen.Color := ReturnColor(lLine);
     Brush.Color := ReturnColor(lLine);
     lPrevPt := GraphPt(1,lLine,lGraphLeft,lGraphBottom,lColWid, lMinVal,lYMult, lSlope);
     lnPolyPts := 1;
     lPolyPts[lnPolyPts] := lPrevPt;
     //MoveTo(lPrevPT.X,lPrevPt.Y);
     if lnCol > 1 then begin
        lPrevPt := GraphPt(2,lLine,lGraphLeft,lGraphBottom,lColWid, lMinVal,lYMult, lSlope);
        lPrevSlope := lSlope;
        if lnCol > 2 then begin
           for lCol := 3 to lnCol do begin
               lPt := GraphPt(lCol,lLine,lGraphLeft,lGraphBottom,lColWid, lMinVal,lYMult, lSlope);
               if lSlope <> lPrevSlope then begin
                  inc(lnPolyPts);
                  lPolyPts[lnPolyPts] := lPrevPt;
                  //LineTo(lPrevPt.X,lPrevPt.Y);
               end;
               lPrevPt := lPt;
               lPrevSlope := lSlope;
           end;
        end; //lnCol > 2
     end; //lnCol > 1;
                  inc(lnPolyPts);
                  lPolyPts[lnPolyPts] := lPrevPt;
     //if not GraphSettingsForm.SmoothCheck.checked) or (lnPolyPts < 4) then
        PolyLine( Slice(lPolyPts, lnPolyPts))
 end;//for each line
//next markers
if lErrorBars then begin
 for lLine := 1 to lnLines do begin
     Pen.Color := ReturnColor(lLine);
     for lCol := 1 to lnCol do begin
         lPt := GraphPt(lCol,lLine,lGraphLeft,lGraphBottom,lColWid, lMinVal,lYMult, lSlope);
         lT := round(lYMult*gGraphData.RA[lCol,lLine+lnLines]) ;
         moveto(lPt.X, lPt.Y -lT);
         lineto(lPt.X, lPt.Y+lT);
     end;//lCol
 end;//lLine
end;//ErrorBars
if lNodeSz > 0 then begin
 //Pen.Width := 1;
 for lLine := 1 to lnLines do begin
     for lCol := 1 to lnCol do begin
         lPt := GraphPt(lCol,lLine,lGraphLeft,lGraphBottom,lColWid, lMinVal,lYMult, lSlope);
       //if lNodeSz > 0 then begin
          Brush.Style := bsSolid;
          Pen.Color := ReturnColor(lLine);
          if gMarkerFill[lLine]  then
              Brush.Color := Pen.Color
          else
             Brush.Color := clWhite;
          case gMarkerShape[lLine] of
               1: Ellipse(lPt.X-lNodeSz,lPt.Y-lNodeSz,lPt.X+lNodeSz,lPt.Y+lNodeSz);
               2: Rectangle(lPt.X-lNodeSz,lPt.Y-lNodeSz,lPt.X+lNodeSz,lPt.Y+lNodeSz);
               3:Polygon([Point(lPt.X,lPt.Y-lNodeSz),Point(lPt.X-lNodeSz,lPt.Y),Point(lPt.X,lPt.Y+lNodeSz),Point(lPt.X+lNodeSz,lPt.Y)]);
               4:Polygon([Point(lPt.X,lPt.Y-lNodeSz),Point(lPt.X-lNodeSz,lPt.Y+lNodeSz),Point(lPt.X+lNodeSz,lPt.Y+lNodeSz)]);
               5: Polygon([Point(lPt.X,lPt.Y+lNodeSz),Point(lPt.X-lNodeSz,lPt.Y-lNodeSz),Point(lPt.X+lNodeSz,lPt.Y-lNodeSz)]);
               6: begin //x
                  MoveTo(lPt.X-lNodeSz,lPt.Y-lNodeSz);
                  LineTo(lPt.X+lNodeSz,lPt.Y+lNodeSz);
                  MoveTo(lPt.X+lNodeSz,lPt.Y-lNodeSz);
                  LineTo(lPt.X-lNodeSz,lPt.Y+lNodeSz);
               end;
               7: begin //+
                  MoveTo(lPt.X,lPt.Y-lNodeSz);
                  LineTo(lPt.X,lPt.Y+lNodeSz);
                  MoveTo(lPt.X+lNodeSz,lPt.Y);
                  LineTo(lPt.X-lNodeSz,lPt.Y);
               end;
               8: begin//*
                  MoveTo(lPt.X-lNodeSz,lPt.Y-lNodeSz);
                  LineTo(lPt.X+lNodeSz,lPt.Y+lNodeSz);
                  MoveTo(lPt.X+lNodeSz,lPt.Y-lNodeSz);
                  LineTo(lPt.X-lNodeSz,lPt.Y+lNodeSz);
                  MoveTo(lPt.X,lPt.Y-lNodeSz);
                  LineTo(lPt.X,lPt.Y+lNodeSz);
                  MoveTo(lPt.X+lNodeSz,lPt.Y);
                  LineTo(lPt.X-lNodeSz,lPt.Y);
               end;

          end; //case

          Brush.Color := clWhite;
       //end; //nodesz > 0
       Pen.Color :=  kForeClr;
     end;//each Col
 end;//for each line
end;//NodeSz > 0
end;
//Image1.Refresh;
//Image1.Canvas.Refresh;
if lCopyToClipBoard then begin
       if (Image1.Picture.Graphic = nil) then begin //1420z
      	Showmessage('You need to load an image before you can copy it to the clipboard.');
      	exit;
       end;
       ClipBoard.Assign(Image1.Picture.Bitmap);
end;//clipboard
if lFilename <> '' then begin
   //lFilenameExt := changefileext(lFilename,'.bmp');
   //Image1.Picture.Bitmap.SaveToFile(lFilenameExt);
   lFilenameExt := changefileext(lFilename,'.png');
   //Image1.Picture.Bitmap.PixelFormat := pf24bit;
   Image1.Picture.SaveToFile(lFilenameExt);
   (*
   png := TPortableNetworkGraphic.Create;
     png.PixelFormat := pf32bit;
     png.Assign(Image1.Picture.Bitmap);
     png.Transparent:=false;
     png.SaveToFile(lFilenameExt);
     png.free;  *)
end; //save to disk
 Image1.Stretch:=true;
 Image1.Proportional:=true;
 Image1.AntialiasingMode:= amOn;
 Image1.Height := Image1.ClientHeight;
 Image1.Width := Image1.ClientWidth;
end;

procedure TGraphForm.CopyBtnClick(Sender: TObject);
begin
     DrawGraph('',true,false);
end;

procedure TGraphForm.FontBtn2Click(Sender: TObject);
begin
     if GraphSettingsForm.GraphFontDialog.Execute then
        DrawGraph('',false,false);
end;

procedure TGraphForm.SaveBtnClick(Sender: TObject);
begin
     if not SaveDialog1.execute then exit;
     DrawGraph(SaveDialog1.filename,false,false);
end;

procedure TGraphForm.SetupBtnClick(Sender: TObject);
begin
     GraphSettingsForm.SetNumLines(gGraphData.Row div 2);
     GraphSettingsForm.ShowModal;
end;

procedure TGraphForm.FormCreate(Sender: TObject);
begin
 ErrorDrop.ItemIndex := 0;
 gGraphData.Row := 3;
 gGraphData.Col := 3;
 gGraphData.RowStr[1] := 'L1';
 gGraphData.RowStr[2] := 'L2';
 gGraphData.RowStr[3] := 'L3';
 gGraphData.ColStr[1] := 'COL1';
 gGraphData.ColStr[2] := 'COL2';
 gGraphData.ColStr[3] := 'COL3';
 gGraphData.RA[1,1] := 0.001;
 gGraphData.RA[2,1] := random;
 gGraphData.RA[3,1] := random;
 gGraphData.RA[1,2] := random;
 gGraphData.RA[2,2] := random;
 gGraphData.RA[3,2] := random;
 gGraphData.RA[1,3] := random;
 gGraphData.RA[2,3] := random;
 gGraphData.RA[3,3] := 1;
end;

procedure TGraphForm.FormShow(Sender: TObject);
var
 m: TANOVAModel;
 lC: integer;
begin
  {$IFDEF Darwin}
  SaveMenu.ShortCut := ShortCut(Word('S'), [ssMeta]);
  CloseMenu.ShortCut := ShortCut(Word('W'), [ssMeta]);
  CopyMenu.ShortCut := ShortCut(Word('C'), [ssMeta]);
  FontMenu.ShortCut := ShortCut(Word('F'), [ssMeta]);
  OptionsMenu.ShortCut := ShortCut(Word('O'), [ssMeta]);
  //RefreshMenu.ShortCut := ShortCut(Word('R'), [ssMeta]);
  {$ENDIF}
  ANOVAForm.LoadModel(m);
     Factor3Edit.visible := (m.vars > 2);
     if m.vars < 2 then begin
        FactorDrop.visible := false;
        ReadGraf;
        exit;
     end else begin
        FactorDrop.visible := true;
        FactorDrop.Items.Clear;
        if m.vars < 3 then begin
           for lC := kAB to kBA do
               FactorDrop.Items.Add(kGrafStr[lC]);
        end else begin
           for lC := kAB to kCB do
               FactorDrop.Items.Add(kGrafStr[lC]);
        end;
     end; //> 1 var
     FactorDrop.ItemIndex := 0;
     FactorDropChange(nil);
     GraphForm.refresh;
     //DrawGraph('',false,false);
end;

procedure TGraphForm.FactorDropChange(Sender: TObject);
var
 m: TANOVAModel;
 lC: integer;
begin
     ANOVAForm.LoadModel(m);
     if m.vars > 2 then begin
        lC := FactorDrop.ItemIndex;
        if lC in [kAB..kBA] then
           Factor3Edit.MaxValue := m.CLevels
        else if lC in [kAC..kCA] then
           Factor3Edit.MaxValue := m.BLevels
        else
           Factor3Edit.MaxValue := m.ALevels;
     end;
     ReadGraf;
end;

initialization
  {$i graph.lrs}
end.


