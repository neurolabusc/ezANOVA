unit Results;
{$mode delphi}
interface

uses
  LResources,LCLIntf,
  SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ComCtrls, StdCtrls, Buttons,Stat, ExtCtrls, Grids,Utils,ClipBrd,
  Menus;

type

  { TResultsForm }

  TResultsForm = class(TForm)
    OpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;
    MainMenu1: TMainMenu;
    File1: TMenuItem;
    SaveMenu: TMenuItem;
    Edit1: TMenuItem;
    CopyMenu: TMenuItem;
    CloseMenu: TMenuItem;
    View1: TMenuItem;
    CopyDescriptivesMenu: TMenuItem;
    CopyResultsMenu: TMenuItem;
    GraphMenu: TMenuItem;
    StatusBar1: TStatusBar;
    Panel1: TPanel;
    Memo1: TMemo;
    DescriptiveGrid: TStringGrid;
    procedure CopyBtnClick(Sender: TObject);
    procedure FontBtnClick(Sender: TObject);
    procedure DescriptiveStats (lRepeatedMeasures: boolean;  lglobalDFError,lglobalMSError: double);
    procedure SaveBtnClick(Sender: TObject);
    procedure OpenBtnClick(Sender: TObject);
    procedure GridHeight;
    procedure NewBtnClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure DescriptiveGridMouseMove(Sender: TObject; Shift: TShiftState;
      X, Y: Integer);
    procedure DescriptiveGridDrawCell(Sender: TObject; Col, Row: Integer;
      Rect: TRect; State: TGridDrawState);
    procedure CloseMenuClick(Sender: TObject);
    procedure CopyDescriptivesMenuClick(Sender: TObject);
    procedure CopyResultsMenuClick(Sender: TObject);
    procedure LineGraphBtnClick(Sender: TObject);
    procedure FormShow(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  ResultsForm: TResultsForm;
implementation

uses main, graph,math, graphsettings;

function MemoAndGridContents: string;
var C, R : integer ;
    S : string ;
    RStart,CStart,REnd,CEnd : integer ;
begin
    // Setup...
    S := '' ;
    //copy ANOVA and t-tests
    if ResultsForm.Memo1.Lines.Count > 0 then begin
        for R := 1 to ResultsForm.Memo1.Lines.Count do
            S := S + ResultsForm.Memo1.Lines[R-1]+ #13#10;//add line and eoln marker
    end;
    S := S + #13#10;
    //Next copy descriptives
    S := S + 'DESCRIPTIVE DETAILS'+ #13#10;
    CStart := 0;
    Cend := ResultsForm.DescriptiveGrid.ColCount-1;
    RStart := 0;
    REnd := ResultsForm.DescriptiveGrid.RowCount-1;
    Result := S;
    if (CEnd <= CStart) or (REnd <= RStart) then exit;
    // Copy to string
    for R := RStart to REnd do begin
        for C := CStart to CEnd do begin
            S := S + ResultsForm.DescriptiveGrid.Cells[ C, R ] ;
            if( C < CEnd ) then begin
                S := S + #9 ; // Tab
            end ;
        end ;
        S := S + #13#10 ; // End line
    end ;
    Result := S;
end;

procedure TResultsForm.CopyBtnClick(Sender: TObject);

begin
    Clipboard.SetTextBuf( PChar( MemoAndGridContents ) ) ;
end;

procedure TResultsForm.FontBtnClick(Sender: TObject);
begin
     MainForm.FontBtnClick(nil);
end;

function  ComputeSkew(lCol,ln: integer; lSD,lMn: double; var ZSkew: double): double;
var
   lRow: integer;
   lSigma,lX: double;
begin
    ZSkew := 0;
    result := 0;
    if (gnRow < 3) or (lN <3) or (lSD = 0) or (( (lN-1)*(lN-2)) = 0) then exit; //avoid DivByZero
    lSigma := 0;
    for lRow := 1 to gnRow do begin
       if IsNumX(lRow,lCol,lX) then begin
          lSigma := lSigma + Power( ((lX-lMn) / lSD)  ,3);  //cube of value
       end;
    end; //for each item
    result := (lN/( (lN-1)*(lN-2)))*lSigma;
    ZSkew := result/(sqrt(6/lN))
end;

procedure DesciptiveGridLabel (lRepeatedMeasures: boolean);
begin
     With ResultsForm.DescriptiveGrid do begin
         Cells[0,kMaxFactors+1] := 'Mean';
         if lRepeatedMeasures then begin
             Cells[0,kMaxFactors+2] := 'nStDev';
             Cells[0,kMaxFactors+3] := 'nSE';
             Cells[0,kMaxFactors+4] := 'nVar';
             Cells[0,kMaxFactors+5] := 'nCI95%';
         end else begin
             Cells[0,kMaxFactors+2] := 'StDev';
             Cells[0,kMaxFactors+3] := 'SE';
             Cells[0,kMaxFactors+4] := 'Var';
             Cells[0,kMaxFactors+5] := 'CI95%';
         end;
         Cells[0,kMaxFactors+6] := 'N';
         Cells[0,kMaxFactors+7] := 'Skew';
         Cells[0,kMaxFactors+8] := 'zSkew';
     end;
end;

function TukeyHSD(lDF,lnComparisons: integer; ln1,ln2,lT1,lT2,lQDiv: double): string;
var lQ,lMn1,lMn2,l05,l01: double;
begin
     result := '';
     if (ln1 < 1) or (ln2 < 1) or (lQDiv= 0)
        or (lDF < kMinTukeyDF) or (lnComparisons < kMinTukeyComp) or (lnComparisons > kMaxTukeyComp) then exit;
     lMn1 := lT1/ln1;
     lMn2 := lT2/ln2;
     lQ := abs((lMn1-lMn2)/lQDiv);
     result := '  Q='+RealToStr(lQ,4);
     TukeyCrit (lDF,lnComparisons, l05, l01);
     if lQ >= l01 then
        result := result + '**'
     else if lQ >= l05 then
          result := result+ '*'
end;

procedure TResultsForm.GridHeight;
var
   lHt,lR: integer;
begin
     GridFontResize(DescriptiveGrid);
     lHt := 0;
     for lR := 1 to DescriptiveGrid.RowCount do begin
         lHt := lHt + DescriptiveGrid.RowHeights[lR]+1;
     end;
     DescriptiveGrid.ClientHeight := lHt;
     GridResize(DescriptiveGrid);
end;

function PairWiseLabel (lColA,lColB: integer): string;
begin
    result := Col2Label(lColA)+'vs'+Col2Label(lColB)
end;

function CohensD (mean1,mean2,SD: double): double;
begin
     if SD = 0 then
        result := 0
     else
         result := abs(mean1-mean2)/SD;
end;


function GroupSD (nV, SumOfSqrs, Sum, nV2, SumOfSqrs2, Sum2: double): double;
var
   lSD2, lMn,lVar,lSD,lSE: double;
begin
     result := 0;
     if (nV < 2) or (nV2 < 2) then
        exit;
     Descriptive (nV, SumOfSqrs, Sum, lMn,lVar,lSD,lSE);
     Descriptive (nV2, SumOfSqrs2, Sum2, lMn,lVar,lSD2,lSE);
     result := (nV-1)*sqr(lSD) + (nV2-1)*sqr(lSD2);
     result := result / (nV+nV2);
     result := sqrt(result );
end;

{$DEFINE TUKEY} //to compute Tukey HSD

procedure TResultsForm.DescriptiveStats (lRepeatedMeasures: boolean; lglobalDFError,lglobalMSError: double);
var
   lTukeyDF,lnComparisons,lPairN,lnCol,lnRow,lCol,lRow,lCond,lCond2: longint;
   //lValCol: boolean;
   lQStr: string;
   lnRowPtrP,ltRowPtrP,lnPtrp,ltPtrp,lSqrtPtrp: DoubleP;
   lMn1,lMn2,lCohensD, lSum1,lSum2,lSumSqr1,lSumSqr2,
   lCI,lQDiv,lHarmonicMean,lT,lGrandSqrT,lGrandT,lGrandN,lGrandMn,lAdj,
   lVar,lZSkew,lSkew,lPairDF,lPairP,lPairT,lPairSum,lPairSqrSum,lX,lX2,lP,
   lDF,lMn,lSE,lSD,lMin,lMax: double;
   //lF,lDF2,lQ,ln,lSqrT,: double;
begin
     //caption := floattostr(lglobalMSError)+'   888';
     lnRow := gnRow;
     lnCol := gnCol;
     ResultsForm.DescriptiveGrid.ColCount := lnCol+1;
     UpdateGridLabels(DescriptiveGrid);
     DesciptiveGridLabel (lRepeatedMeasures);
     GridHeight;
     if lnCol < 2 then begin
         showmessage('You need more than 1 column to analyze.');
         exit;
     end;
     GetMem(lnRowPtrP, lnRow* SizeOf(double)+16);
     GetMem(ltRowPtrP, lnRow* SizeOf(double)+16);
     GetMem(lnPtrP, lnCol* SizeOf(double)+16);
     GetMem(ltptrP, lnCol* SizeOf(double)+16);
     GetMem(lSqrTptrP, lnCol* SizeOf(double)+16);
     for lRow := 1 to lnRow do begin
         lnRowPtrP^[lRow] := 0;
         ltRowPtrP^[lRow] := 0;
     end;
     for lCol := 1 to lnCol do begin
         lnPtrP^[lCol] := 0;
         ltPtrP^[lCol] := 0;
         lSqrTPtrP^[lCol] := 0;
     end;
     for lCol := 1 to lnCol do begin
         for lRow := 1 to lnRow do begin
             if IsNumX(lRow,lCol,lX) then begin
               lnRowPtrP^[lRow] := lnRowPtrP^[lRow] + 1;
               ltRowPtrP^[lRow] := ltRowPtrP^[lRow] + lX;
               lnPtrP^[lCol] := lnPtrP^[lCol] + 1;
               ltPtrP^[lCol] := ltPtrP^[lCol] + lX;
               lSqrTPtrP^[lCol] := lSqrTPtrP^[lCol] + sqr(lX);
             end; //valid cell
         end; //for row
     end; //for col
     lGrandN := 0;
     lGrandT := 0;
     lGrandSqrT := 0;
     for lCond := 1 to (lnCol) do begin
         Descriptive (lnPtrP^[lCond], lSqrTPtrP^[lCond], lTPtrP^[lCond],lMn,lVar,lSD,lSE);
         if lglobalDFError = 0 then begin
            ConfidenceInterval (round(lnPtrP^[lCond]),lSD, lMn, lMin, lMax);
            lCI := (lMax-lMin)/ 2;
         end else
             lCI := MultifactorialConfidenceInterval(round(lnPtrP^[lCond]),round(lglobalDFError),lglobalMSError);
         lSkew := ComputeSkew(lCond,round(lnPtrP^[lCond]),lSD,lMn,lZSkew);
         With ResultsForm.DescriptiveGrid do begin
              Cells[lCond,kMaxFactors+1] := realtostr(lMn,2);
              Cells[lCond,kMaxFactors+2] := RealToStr(lSD,2);
              Cells[lCond,kMaxFactors+3] := RealToStr(lSE,2);
              Cells[lCond,kMaxFactors+4] := RealToStr(lVar,2);
              Cells[lCond,kMaxFactors+5] := RealToStr(lCI,2);
              Cells[lCond,kMaxFactors+6] := realtostr(lnPtrP^[lCond],0);
              Cells[lCond,kMaxFactors+7] := RealToStr(lSkew,3);
              Cells[lCond,kMaxFactors+8] := RealToStr(lZSkew,3);
         end;
         lGrandSqrT := lGrandSqrT + lSqrTPtrP^[lCond];
         lGrandT := lGrandT + lTPtrP^[lCond];
         lGrandN := lGrandN + lNPtrP^[lCond];
     end;
     if lGrandN > 0 then
        lGrandMn := lGrandT/lGrandN //overall mean value
     else
         lGrandMn := 0;
if lRepeatedMeasures then begin
   //Compute paired t-test
  {$IFDEF TUKEY}
     //compute harmonic mean number of subjects: used by Tukey HSD
     lHarmonicMean := 0;
     lCond := 0;
     lnComparisons := 0;
     lTukeyDF := 0;
     for lCol := 1 to lnCol do begin
         if lnPtrP^[lCol] > 1 then begin
            lHarmonicMean := lHarmonicMean + (1/lnPtrP^[lCol]);
            inc(lCond);
            lnComparisons := lnComparisons + (lCond-1);
            lTukeyDF := lTukeyDF+ round(lnPtrP^[lCol]-1);
         end;
     end;
     lQDiv := 0;
     if lHarmonicMean > 0 then begin
        lHarmonicMean := lCond / lHarmonicMean;
        lQDiv := sqrt(lglobalMSError/lHarmonicMean);//LQDivisor: used to estimate Q for Tukey HSD
     end;
     //if lnCol > 1 then begin
     //fx(lTukeyDF);
        Memo1.Lines.Add('');
     if  (lTukeyDF < kMinTukeyDF) or (lQDiv = 0) then begin
        lQStr := '';
        Memo1.Lines.Add('PAIRWISE COMPARISONS');
     end else
        Memo1.Lines.Add('PAIRWISE COMPARISONS [Q=TukeyHSD: *=p<0.05 **=p<0.01]');
{$ELSE}
     Memo1.Lines.Add('');
     Memo1.Lines.Add('PAIRWISE COMPARISONS');
{$ENDIF}
     for lCond := 1 to (lnCol-1) do begin
         for lCond2 := (lCond+1) to lnCol do begin
             lPairN := 0;
             lPairSum := 0;
             lPairSqrSum := 0;
             lSum1 := 0;
             lSum2 := 0;
             lSumSqr1 := 0;
             lSumSqr2 := 0;

             //lnValCol := 0;
             for lRow := 1 to lnRow do begin
                 //inc(lnValCol);
                 if IsNumX(lRow,lCond,lX) and (IsNumX (lRow,lCond2,lX2)) then begin
                       //if lCOnd = (lnValCol-1) then showmessage(inttostr(lRow));
                       lPairN := lPairN + 1;
                       lPairSum := lPairSum +  (lX-lX2);
                       lPairSqrSum := lPairSqrSum + sqr( (lX-lX2) );

                       lSum1 := lSum1 + lX;
                       lSum2 := lSum2 + lX2;
                       lSumSqr1 := lSumSqr1 + sqr(lX);
                       lSumSqr2 := lSumSqr2 + sqr(lX2);
                 end; //valid values
             end; //for lRow
             if (lPairN > 1) then begin //valid rows
                PairedTTest (lPairN, lPairSqrSum, abs(lPairSum), lPairt, lPairp,lPairDF);
{$IFDEF TUKEY}
                if  (lTukeyDF >= kMinTukeyDF) then
                    lQStr := TukeyHSD(lTukeyDF,lnComparisons,lnPtrP^[lCond],lnPtrP^[lCond2],lTPtrP^[lCond],lTPtrP^[lCond2],lQDiv);
{$ENDIF}
                lMn1 := lSum1 / lPairN;
                lMn2 := lSum2 / lPairN;
                lSD := GroupSD (lPairN, lSumSqr1, lSum1, lPairN, lSumSqr2, lSum2);
                //lCohensD := lSD;
                lCohensD := CohensD (lMn1,lMn2,lSD);
                //procedure Descriptive (nV, SumOfSqrs, Sum: double; var lMn,lVar,lSD,lSE: double);
                ResultsForm.Memo1.Lines.Add(PairWiseLabel(lCond,lCond2)+' t('+realtostr(lPairDF,0)+')='+RealToStr(lPairt,2)+'  p< '+RealToStr(lPairp,4) +' '+lQStr+'  CohensD = '+RealToStr(lCohensD,4));
             end; //lPairN > 1, valid rows
         end; //for lCond2
     end; //for lCond1
   //Adjusted SDs
   //First: compute Loftus adjusted SD
   //start by filling array with adjusted values
   for lCol := 1 to lnCol do begin
       lnPtrP^[lCol] := 0;
       lSqrTPtrP^[lCol]:= 0;
       lTPtrP^[lCol]:= 0;
   end;
   for lRow := 1 to lnRow do begin
       if lnRowPtrP^[lRow] > 0 then begin
          lAdj := lGrandMn-(ltRowPtrP^[lRow]/lnRowPtrP^[lRow]); //is this individual's mean greater or less than the grand mean
          for lCol := 1 to lnCol do
              if IsNumX(lRow,lCol,lX) then begin //read untransformed data
                 lX := lX+lAdj;
                 lnPtrP^[lCol] := lnPtrP^[lCol]+1;
                 lSqrTPtrP^[lCol]:= lSqrTPtrP^[lCol]+Sqr(lX);
                 lTPtrP^[lCol]:= lTPtrP^[lCol]+lX;
              end; //valid value
       end; //data from this subject
   end; //for each subject
   //compute adjusted SD values : we have essentially removed overall subject variance
     for lCond := 1 to (lnCol) do begin
       Descriptive (lnPtrP^[lCond], lSqrTPtrP^[lCond], lTPtrP^[lCond],lMn,lVar,lSD,lSE);
       if lglobalDFError = 0 then begin
          ConfidenceInterval (round(lnPtrP^[lCond]),lSD, lMn, lMin, lMax);
          lCI := (lMax-lMin)/ 2;
       end else
           lCI := MultifactorialConfidenceInterval(round(lnPtrP^[lCond]),round(lglobalDFError),lglobalMSError);
      //showmessage(inttostr(globalDFError)+'@'+floattostr(globalmSError));
         With ResultsForm.DescriptiveGrid do begin
              Cells[lCond,kMaxFactors+2] := RealToStr(lSD,2);
              Cells[lCond,kMaxFactors+3] := RealToStr(lSE,2);
              Cells[lCond,kMaxFactors+4] := RealToStr(lVar,2);
              Cells[lCond,kMaxFactors+5] := RealToStr(lCI,2);
         end; //with table
   end; //for col
end else if lnCol > 1 then  begin
     //between Subj tests...
     //compute harmonic mean number of subjects: used by Tukey HSD
     lHarmonicMean := 0;
     lCond := 0;
     lnComparisons := 0;
     lTukeyDF := 0;
     for lCol := 1 to lnCol do begin
         if lnPtrP^[lCol] > 1 then begin
            lHarmonicMean := lHarmonicMean + (1/lnPtrP^[lCol]);
            inc(lCond);
            lnComparisons := lnComparisons + (lCond-1);
            lTukeyDF := lTukeyDF+ round(lnPtrP^[lCol]-1);
         end;
     end;
     lQDiv := 0;
     if lHarmonicMean > 0 then begin
        lHarmonicMean := lCond / lHarmonicMean;
        lQDiv := sqrt(lglobalMSError/lHarmonicMean);//LQDivisor: used to estimate Q for Tukey HSD
     end;
     //if lnCol > 1 then begin
     //fx(lTukeyDF);
        Memo1.Lines.Add('');
     if  (lTukeyDF < kMinTukeyDF) or (lQDiv = 0) then begin
        lQStr := '';
        Memo1.Lines.Add('PAIRWISE COMPARISONS');
     end else
        Memo1.Lines.Add('PAIRWISE COMPARISONS [Q=TukeyHSD: *=p<0.05 **=p<0.01]');
     for lCond := 1 to (lnCol-1) do begin
      for lCond2 := (lCond+1) to lnCol do begin
          if (lnPtrP^[lCond]>1)and (lnPtrP^[lCond2]>1)
          and (ltPtrP^[lCond]>0) and (ltPtrP^[lCond2]>0) then begin
if SameSubj(lCond,lCond2) then begin //for mixed designs
             lPairN := 0;
             lPairSum := 0;
             lPairSqrSum := 0;
             //lnValCol := 0;
             for lRow := 1 to lnRow do begin
                 //inc(lnValCol);
                 if IsNumX(lRow,lCond,lX) and (IsNumX (lRow,lCond2,lX2)) then begin
                       //if lCOnd = (lnValCol-1) then showmessage(inttostr(lRow));
                       lPairN := lPairN + 1;
                       lPairSum := lPairSum +  (lX-lX2);
                       lPairSqrSum := lPairSqrSum + sqr( (lX-lX2) );
                 end; //valid values
             end; //for lRow
             if (lPairN > 1) then begin //valid rows
{$IFDEF TUKEY}
                if  (lTukeyDF >= kMinTukeyDF) then
                    lQStr := TukeyHSD(lTukeyDF,lnComparisons,lnPtrP^[lCond],lnPtrP^[lCond2],lTPtrP^[lCond],lTPtrP^[lCond2],lQDiv);
{$ENDIF}
                PairedTTest (lPairN, lPairSqrSum, abs(lPairSum), lPairt, lPairp,lPairDF);
                ResultsForm.Memo1.Lines.Add(PairWiseLabel(lCond,lCond2)+' PAIRED t('+realtostr(lPairDF,0)+')='+RealToStr(lPairt,2)+'  p< '+RealToStr(lPairp,4)+' '+lQStr);
             end; //lPairN > 1, valid rows
end else begin //between subject
          if  (lTukeyDF >= kMinTukeyDF) then
             lQStr := TukeyHSD(lTukeyDF,lnComparisons,lnPtrP^[lCond],lnPtrP^[lCond2],lTPtrP^[lCond],lTPtrP^[lCond2],lQDiv);
         Ttest (lnPtrP^[lCond],lnPtrP^[lCond2],lSqrTPtrP^[lCond],lSqrTPtrP^[lCond2],ltPtrP^[lCond],ltPtrP^[lCond2],lt,lp,lDF);
         lt := abs(lt);//no need to show direction
         //Ftest (lnPtr^[lCond],lnPtr^[lCond2],lSqrTPtr^[lCond],lSqrTPtr^[lCond2],ltPtr^[lCond],ltPtr^[lCond2],lf,lfp,lDF1,lDF2);
ResultsForm.Memo1.Lines.Add(PairWiseLabel(lCond,lCond2)+' t('+realtostr(lDF,0)+')='+RealToStr(lt,2)+
'  p< '+RealToStr(lp,4)+lQStr );
end; //if repeated else between
          end;
         end;
      end;
end; //if..else repeated measures
     FreeMem(lnRowPtrP);
     FreeMem(ltRowptrP);
     FreeMem(lnPtrP);
     FreeMem(ltptrP);
     FreeMem(lSqrTptrP);
end;

procedure TResultsForm.SaveBtnClick(Sender: TObject);
var lF: textfile;
begin
     if Memo1.Lines.Count = 0 then begin
        showmessage('No text to save.');
        exit;
     end;
     if not SaveDialog1.execute then exit;
     //Memo1.Lines.SaveToFile(SaveDialog1.FileName);
     AssignFile(lF,SaveDialog1.FileName);
      {$I-}
     Rewrite(lF);
     {$I+}
     if IoResult <> 0 then exit;
     write(lF,MemoAndGridContents);
     CloseFile(lF);
end;

procedure TResultsForm.OpenBtnClick(Sender: TObject);
begin
    if not OpenDialog1.execute then exit;
    if not Fileexists(OpenDialog1.Filename) then exit;
    Memo1.Lines.LoadFromFile(OpenDialog1.Filename);
end;

procedure TResultsForm.NewBtnClick(Sender: TObject);
begin
     Memo1.Lines.Clear;
end;

procedure TResultsForm.FormResize(Sender: TObject);
begin
        if DescriptiveGrid.visible then
        GridResize(DescriptiveGrid);
end;

procedure TResultsForm.DescriptiveGridMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
begin
     GridToStatusBar(DescriptiveGrid,StatusBar1);
end;

procedure TResultsForm.DescriptiveGridDrawCell(Sender: TObject; Col,
  Row: Integer; Rect: TRect; State: TGridDrawState);
begin
        GridToStatusBar(DescriptiveGrid,StatusBar1);
end;

procedure TResultsForm.CloseMenuClick(Sender: TObject);
begin
     Close;
end;

procedure TResultsForm.CopyDescriptivesMenuClick(Sender: TObject);
begin
     StringGridSelectAll(DescriptiveGrid);
     CopyStringGridToClipBoard(DescriptiveGrid);
end;

procedure TResultsForm.CopyResultsMenuClick(Sender: TObject);
begin
     Memo1.SelectAll;
     Memo1.CopyToClipBoard;
end;

procedure TResultsForm.LineGraphBtnClick(Sender: TObject);
begin
     GraphForm.Show;
end;

{$IFNDEF UNIX}
(*procedure SetTabs (var lMemo: TMemo);
var
  FTabWidth: Integer;
begin
  lMemo.WantTabs := True;
  FTabWidth := 96;
  SendMessage(lMemo.Handle, EM_SETTABSTOPS, 1, Longint(@FTabWidth));
end;  *)
{$ENDIF}

procedure TResultsForm.FormShow(Sender: TObject);
begin
  {$IFDEF Darwin}
  CopyMenu.ShortCut:=ShortCut(Word('C'), [ssMeta]);
  SaveMenu.ShortCut:=ShortCut(Word('S'), [ssMeta]);
  GraphMenu.ShortCut:=ShortCut(Word('G'), [ssMeta]);
  CloseMenu.ShortCut:=ShortCut(Word('W'), [ssMeta]);
  {$ENDIF}
  //{$IFNDEF UNIX}SetTabs(Memo1);{$ENDIF}
end;

initialization
  {$i Results.lrs}
end.
