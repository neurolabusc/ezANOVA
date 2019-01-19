unit Utils;
      {$mode delphi}
interface
uses Graphics, Grids,SysUtils,Classes,ClipBrd,comctrls,dialogs;
type
    DoubleRA = array [1..1] of Double;
    Doublep = ^DoubleRA;
    LongIntRA = array [1..1] of LongInt;
    LongIntp = ^LongIntRA;
    function ModUp (lValue, lDiv: integer): integer;
    function RealToStr(lR: double; lDec: integer): string;
     function StringOf(lR: double;lSpace, lDec: integer): string;
     function IsNumX(lRow,lCol: integer; var lX: double): boolean;
     function IsNum(lRow,lCol: integer; var lOut: integer): boolean;
     procedure StringGridSelectAll(lGrid: TStringGrid);
     procedure CopyStringGridToClipBoard(lGrid: TStringGrid);
     function ColLabel(lCol: integer; isLowerCase: boolean = false): string; //first column= A, 26th=Z,27th AA, etc...
     procedure GridResize(lGrid: TStringGrid);
     procedure GridFontResize(lGrid: TStringGrid);
     procedure UpdateGridLabels(lGrid: TStringGrid);
     procedure GridToStatusBar(lGrid: TStringGrid; lStatus: TStatusBar);
     procedure SwapInt(var lA,lB: integer);
     function PadString(var lStr: string; lLen: integer): string;
     function SameSubj (lColA,lColB: integer): boolean;
     function Col2Label(lCol: integer): string;
procedure fx (a: double); overload;
procedure fx (a,b: double); overload;
procedure fx (a,b,c: double); overload;
procedure fx (a,b,c,d: double); overload;
Const
     kMaxFactors = 3;
     kNativeSignature = '#Version:B';
     kCSVExt = '.csv';
     kTxtExt = '.txt';
     kNativeExt = '.eza';
      BS = #8 ; { Backspace }
      CR = #13 ; { Carriage return }
      DEL = #127 ; { Delete }
      HT = #9 ; { Horizontal Tab }
      LF = #10 ; { Line Feed }
      VT = #11 ; { Vertical Tab }
      NaN : double = 1/0;

var
 DecSeparator: char;
 gDesignUnspecified,gEnterCell,gChanges: boolean;
 gTransform: integer;
 g64rBufP: Doublep;
 gnCol,gnRow: integer;

implementation
uses ANOVA;

procedure fx (a: double); overload; //fx used to help debugging - reports number values
begin
	showmessage(floattostr(a));
end;

procedure fx (a,b: double); overload; //fx used to help debugging - reports number values
begin
	showmessage(floattostr(a)+'x'+floattostr(b));
end;

procedure fx (a,b,c: double); overload; //fx used to help debugging - reports number values
begin
	showmessage(floattostr(a)+'x'+floattostr(b)+'x'+floattostr(c));
end;

procedure fx (a,b,c,d: double); overload; //fx used to help debugging - reports number values
begin
	showmessage(floattostr(a)+'x'+floattostr(b)+'x'+floattostr(c)+'x'+floattostr(d));
end;

function PadString(var lStr: string; lLen: integer): string;
var
   lL,lP: integer;
begin
     result := '';
     if lLen < 1 then
        exit;
     lL := length(lStr);
     if lL > lLen then
        lL := lLen;
     if lL > 0 then
        for lP := 1 to lL do
            result := result + lStr[lP];
     if lL < lLen then
        for lP := (lL+1) to lLen do
            result := result + ' ';
end;

procedure SwapInt(var lA,lB: integer);
var lTemp: integer;
begin
     lTemp := lA;
     lA := lB;
     lB := lTemp;
end;

function ModUp (lValue, lDiv: integer): integer;
begin
    result := lValue mod lDiv;
    if result = 0 then
       result := lDiv;
end;

function StringOf(lR: double;lSpace, lDec: integer): string;
const
 kMax32bitS = 2147483647;
 kMin32bitS = -2147483647;
var lStr: string;
    lRvar,lMult: double;
    lInc: longint;
begin
     lMult := 1;
     if lDec > 0 then
        for lInc := 1 to lDec do
            lMult := lMult * 10;
     lRVar := ((lR * lMult));
     if (lRVar > kMax32bitS) or (lRVar < kMin32bitS) then begin
          lStr := FloatToStr(lR);
     end else begin
         lRVar := (round(lRVar));
         if (lRVar = 0) and (lR > 0) then lRVar := 1; //instead of p<0.000 more conservative is p<0.001
         lRvar := lRvar/lMult;
         if lSpace > 0 then
            lStr := FloatToStrF(lRvar, ffFixed,lSpace-lDec,lDec)
         else
             lStr := FloatToStrF(lRvar, ffFixed,15,lDec);
     end;
     if Length(lStr) < (lSpace) then begin
         for lInc := (Length(lStr)+1) to (lSpace) do
             lStr := ' '+lStr;
     end;
     Result:= lStr;
end;

function RealToStr(lR: double; lDec: integer): string;
begin
     Result := StringOf(lR,0,lDec)
end;

FUNCTION specialdouble (d:double): boolean;
//returns true if s is Infinity, NAN or Indeterminate
//8byte IEEE: msb[63] = signbit, bits[52-62] exponent, bits[0..51] mantissa
//exponent of all 1s =   Infinity, NAN or Indeterminate
CONST kSpecialExponent = 2047 shl 20;
VAR Overlay: ARRAY[1..2] OF LongInt ABSOLUTE d;
BEGIN
  IF ((Overlay[2] AND kSpecialExponent) = kSpecialExponent) THEN
     RESULT := true
  ELSE
      RESULT := false;
END;

function IsNumX(lRow,lCol: integer; var lX: double): boolean;
var
   lPos: integer;
begin
     result := false;
     lPos := ((lRow-1)*gnCol)+lCol;
     if (g64rBufP = nil) or (lPos > (gnCol*gnRow)) then exit; //buffer not loaded
     lX := g64rBufp[lPos];
     if specialdouble(lX) then
        result := false
     else
         result := true;
end;

function IsNum(lRow,lCol: integer; var lOut: integer): boolean;
var
   lPos: integer;
   lX: double;
begin
     lOut := 0;
     result := false;
     lPos := ((lRow-1)*gnCol)+lCol;
     if (g64rBufP = nil) or (lPos > (gnCol*gnRow)) then exit; //buffer not loaded
     lX := g64rBufp[lPos];
     if specialdouble(lX) then
        result := false
     else begin
         result := true;
         lOut := round(lX);
     end;
end;

procedure GridToStatusBar(lGrid: TStringGrid; lStatus: TStatusBar);
begin
    if (lGrid.Selection.Top <= kMaxFactors) or (lGrid.Selection.Left <= 0) then begin
       lGrid.Selection:=TGridRect(Rect(-1,-1,-1,-1));
       lStatus.Panels[0].Text := '';
       exit;
    end;
    if lGrid.Selection.Top < 0 then exit;
    if((lGrid.Selection.Top = lGrid.Selection.Bottom ) and ( lGrid.Selection.Left = lGrid.Selection.Right )) then begin
      lStatus.Panels[0].Text := ColLabel(lGrid.Selection.Left)+lGrid.Cells[0,lGrid.Selection.Top]{inttostr(lGrid.Selection.Top-kMaxFactors)}+' = '+lGrid.Cells[lGrid.Selection.Left,lGrid.Selection.Top];
      lStatus.Panels[1].Text := lGrid.Cells[lGrid.Selection.Left,0]+' '+ lGrid.Cells[lGrid.Selection.Left,1]+' '+lGrid.Cells[lGrid.Selection.Left,2];
    end else begin
        lStatus.Panels[0].Text := inttostr(lGrid.Selection.Bottom-lGrid.Selection.Top + 1)+'R x '+ inttostr(lGrid.Selection.Right-lGrid.Selection.Left + 1)+'C';
        lStatus.Panels[1].Text := '';
    end;
end;

procedure StringGridSelectAll(lGrid: TStringGrid);
begin
     lGrid.Selection:= TGridRect(Rect(1,1+kMaxFactors,lGrid.ColCount-1,lGrid.RowCount-1));
end;


procedure CopyStringGridToClipBoard(lGrid: TStringGrid);
var C, R : integer ;
    S : string ;
    RStart,CStart,REnd,CEnd : integer ;

begin
    // Setup...
    S := '' ;
    if (lGrid.Selection.Left < 0) or (lGrid.Selection.Top < 0) then begin
        StringGridSelectAll(lGrid);
    end;
    CStart := lGrid.Selection.Left;
    CEnd := lGrid.Selection.Right;
    RStart := lGrid.Selection.Top;
    REnd := lGrid.Selection.Bottom;
    // Copy to string
    for R := RStart to REnd do
    begin
        for C := CStart to CEnd do
        begin
            S := S + lGrid.Cells[ C, R ] ;
            if( C < CEnd ) then begin
                S := S + #9 ; // Tab
            end ;
        end ;
        S := S + #13#10 ; // End line
    end ;
    Clipboard.SetTextBuf( PChar( S ) ) ;
end;

function ColLabel (lCol: integer; isLowerCase: boolean = false): string; //first column= A, 26th=Z,27th AA, etc...
var lColDiv,lColMod: integer;
begin
    result := '';
    lColDiv := lCol;
    repeat
          lColMod := lColDiv mod 26;
          if lColMod = 0 then lColMod := 26;
          if isLowerCase then
             result := chr(ord('a')+lColMod-1)+result
          else
              result := chr(ord('A')+lColMod-1)+result;
              lColDiv := (lColDiv-1) div 26;
    until lColDiv <= 0;
end;

function RepLength: integer; //how many columns of repeated data?
//returns 1 for between subj
//returns lnCol for within subj
//returns intermediate value for mixed design...
var
 lA,lB,lC,lCol: integer;
begin
     lA := ANOVAForm.AVal.value;
     lB := ANOVAForm.BVal.value;
     lC := ANOVAForm.CVal.value;
         lCol := 1;//assume between
     if (lC > 1) and (ANOVAForm.CRepCheck.checked) then
        lCol := lCol * lC;
     if (lB > 1) and (ANOVAForm.BRepCheck.checked) then
        lCol := lCol * lB;
     if (lA > 1) and (ANOVAForm.ARepCheck.checked) then
        lCol := lCol * lA;
     result := lCol;
end;

function SameSubj (lColA,lColB: integer): boolean;
//is data from ColumnA acquired from same subject as ColumnB?
//ALWAYS returns true for repeated subject design
//ALWAYS retruns false for between-subject design
//SOMETIMES returns true for mixed designs
var
   lRepLength : integer;
begin
    lRepLength := RepLength;
    if ((lColA-1) div lRepLength) = ((lColB-1) div lRepLength) then
       result := true
    else
        result := false;
end;

function Col2Label(lCol: integer): string;
var
   lA,lB,lC,lV: integer;
begin
     result := '';
     lC := ANOVAForm.CVal.value;
     if lC = 0 then lC := 1;
     lB := ANOVAForm.BVal.value;
     if lB = 0 then lB := 1;
     lA := ANOVAForm.AVal.value;
     if (lC > 1) then
        result := '_'+ANOVAForm.CLevelNames.Cells[ ((lCol-1) mod lC),0];
     if (lB > 1) then begin
        lV := ((lCol-1) div lC);
        result := '_'+ANOVAForm.BLevelNames.Cells[ ((lV) mod lB),0]+result;
     end;
     lV := ((lCol-1) div (lB*lC));
     result := ANOVAForm.ALevelNames.Cells[ ((lV) mod lA),0]+result;
     result := '['+result+']';
end;

procedure UpdateGridLabels(lGrid: TStringGrid);
var
   lABC,lCol,lA,lB,lC,lBC,{lBi,}lInc,lInc2: integer;
begin
     if lGrid.RowCount < (kMaxFactors+1) then exit;
     if (lGrid.ColCount) < 2 then exit;
     for lInc := 1 to (lGrid.RowCount -kMaxFactors-1) do //fxfx
         lGrid.Cells[0,kMaxFactors+lInc] := inttostr(lInc);

     //Next enter ANOVA labels for each row
     for lInc := (lGrid.ColCount-1) downto 0 do //fxfx
         for lInc2 := 0 to 2 do
             lGrid.Cells[lInc,lInc2] := '';

     if gDesignUnspecified then begin
         lGrid.RowHeights[1] := 0;
         lGrid.RowHeights[2] := 0;
        exit;
     end;

     lC := ANOVAForm.CVal.value;
     if lC = 0 then lC := 1;
      if ANOVAForm.CLevelNames.ColCount < 1 then
         lC := 1;
     lB := ANOVAForm.BVal.value;
     if lB = 0 then lB := 1;
     lBC := lB*lC;
     lA := ANOVAForm.AVal.value;
     lABC := lBC * lA;//fxfx
     //fx(lA,lB,lC,ANOVAForm.CLevelNames.ColCount);
     if (lABC+1) > lGrid.ColCount then begin
        lGrid.ColCOunt := (lABC+1);
        //fx(lGrid.ColCount,lABC+1 );
        //exit;
     end;
     //exit;
     if lC > 1 then begin
         lGrid.Cells[0,2] := ANOVAForm.CEdit.text;
         for lInc := 1 to lABC do begin
             lInc2 := lInc mod lC;
             if lInc2 = 0 then
                lInc2 := lC;
             lGrid.Cells[lInc,2] := ANOVAForm.CLevelNames.Cells[lInc2-1,0];
         end; //for each row
         lGrid.RowHeights[2] := lGrid.DefaultRowHeight;
     end else
         lGrid.RowHeights[2] := 0;


     if lB > 1 then begin
        //lBi := 0;
        lGrid.Cells[0,1] := ANOVAForm.BEdit.text;
        for lInc := 1 to lABC do begin
            lInc2 := (lInc-1) div lC;
            lInc2 := lInc2 mod lB;
            lGrid.Cells[lInc,1] := ANOVAForm.BLevelNames.Cells[lInc2,0];
        end;
        lGrid.RowHeights[1] := lGrid.DefaultRowHeight;
     end else //lB > 1
         lGrid.RowHeights[1] := 0;
     lCol := 0;
     for lInc := 1 to lA do begin
         lGrid.Cells[0,0] := ANOVAForm.AEdit.text;
        for lInc2 := 1 to lBC do begin
            inc(lCol);
            lGrid.Cells[lCol,0] := ANOVAForm.ALevelNames.Cells[lInc-1,0];
        end;
     end;

     if (lABC+1) <> lGrid.ColCount then begin
           lGrid.ColCount := lABC+1;
           UpdateGridLabels(lGrid);
     end;
     lCol := RepLength;
     lInc2 := 1;
     for lInc := 1 to (lGrid.ColCount-1 ) do begin
        if (lCol > 1) then
           lGrid.Cells[lInc,kMaxFactors+0] := ColLabel(lInc)+ColLabel(lInc2, true)
        else
            lGrid.Cells[lInc,kMaxFactors+0] := ColLabel(lInc);
         if (lInc mod lCol) = 0 then
            inc(lInc2);
     end;
     //for lInc := 1 to (lGrid.ColCount-1 ) do begin  //fxfx
     //    lGrid.Cells[lInc,kMaxFactors+0] := ColLabel(lInc);
     //end;//chr(ord('A')+lInc);
end;

{$IFDEF UNIX}
procedure GridFontResize(lGrid: TStringGrid);
begin
     lGrid.DefaultRowHeight:= abs(lGrid.Font.Size)+8;
end;
{$ELSE}
procedure GridFontResize(lGrid: TStringGrid);
begin
   lGrid.DefaultRowHeight:= round(abs((Graphics.ScreenInfo.PixelsPerInchX /96 ) *lGrid.Font.Size))+8;
end;
{$ENDIF}
procedure GridResize(lGrid: TStringGrid);
var lClient,lWid,lCount,lCol1Wid: integer;
begin
  lCount := lGrid.ColCount-1;
  //lCount := lGrid.ColCount;
  lClient := lGrid.ClientWidth;
  if lCount < 1 then begin
      lGrid.ColWidths[0] := lClient;
      exit;
  end;
  lCol1Wid := (abs(lGrid.Font.Size) * 6)+6;
  lClient := lClient - lCol1Wid ;
  lWid := ((lClient) div lCount);
  if lWid < lCol1Wid then
    lWid := lCol1Wid;
  lGrid.DefaultColWidth := lWid;
  lGrid.ColWidths[0] := lCol1Wid;
  //mainform.caption := format('%d / %d = %d + %d',[lCount, lClient, lCol1Wid, lWid]);
end;

end.
 
