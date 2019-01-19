unit anovafx;
 {$mode delphi}
 {$H+}
interface
uses Mat,Math,Dialogs,Classes,SysUtils,utils;
Type
  TDescriptives =  record
          sum, sumSq : double;
          n: integer;
  end;
  DescriptivesRA = array [1..1] of TDescriptives;
  DescriptivesRAp = ^DescriptivesRA;
  TANOVAModel = record
     Alabel,Blabel,Clabel: string;
     Design, Alevels,Blevels,CLevels,Vars: integer;
     Arep,Brep,Crep: boolean; //repeated measures
     data: TMatrix;
     SS,BR,S,DF,DFErr,SSErr: array [0..7] of double;
     //BR = Basic Ratio for Treatment Sums
     //S = Basic Ratio for the basic observations or scores
  end;

const
 kb1w0 = 0;// = 1 Between Subject Factor
 kb2w0 = 1;// = 2 Between Subject Factors
 kb3w0 = 2;// = 3 Between Subject Factors
 kb0w1 = 3;// = 1 Within Subject Factor
 kb0w2 = 4;// = 2 Within Subject Factors
 kb0w3 = 5;// = 3 Within Subject Factors
 kb1w1 = 6;// = 2 Factors 1 Within, 1 Between
 kb2w1 = 7;// = 3 Factors 1 Within, 2 Between
 kb1w2 =8;// Factors 2 Within, 1 Between

 kDesignStr: array [kb1w0..kb1w2] of string =

('1 Between Subject Factor',
'2 Between Subject Factors',
'3 Between Subject Factors',
'1 Within Subject Factor',
'2 Within Subject Factors',
'3 Within Subject Factors',
'2 Factors 1 Within, 1 Between',
'3 Factors 1 Within, 2 Between',
'3 Factors 2 Within, 1 Between');

//function GreenhouseGeiserEpsilon (var x: TMatrix): double;
procedure doANOVA (var Results: TStrings; var m: TANOVAModel;  var lglobalDFError,lglobalMSamp: double); {using globals Vars, L1, L2, L3 set by doANOVA}

implementation
uses
Stat;
const
     T=0;//all combined
     A=1;
     B=2;
     C=3;
     AB=4;
     AC=5;
     BC=6;
     ABC=7;

function GreenhouseGeiserEpsilon (var x: TMatrix): double;
//comuputes GG correction for a given dataset
{Returns same solution as this R code:
x0 <- c(450,390,570,450,510,360,510,510,510,510)
x2 <- c(510,480,630,660,660,450,600,660,660,540)
x4 <- c(630,540,660,720,630,450,720,780,660,660)
S <- var(cbind(x0, x2, x4))
k <- 3;
D  <- k^2 * ( mean ( diag ( S ) ) - mean ( S ) ) ^2
N1 <- sum(S^2)
N2 <- 2 * k * sum(apply(S, 1, mean)^2)
N3 <- k^2 * mean(S)^2
epsilon <- D / ((k - 1) * (N1 - N2 + N3))}
var
   nf: integer;
   DiagMn,Mn,D,N1,N2,N3: Double;
   y: TMatrix;
begin
   result := 1;
   nf := x.c;
   if nf < 3 then //only compute for >2 factors
      exit;
   y := TMatrix.Create (nf,nf);
   y.cov(x);
   //reportmatrix(y);
   DiagMn := y.DiagonalMean;
   Mn := y.Mean;
   //   fx(DiagMn-Mn);
   D := power(nf,2)* power((DiagMn-Mn),2);
   N1 := y.SumSqr;
   N2 := 2 * nf * y.SumColMeanSqr;
   //fx(N1,y.SumColMeanSqr);
   N3 := power(nf,2) * power(Mn,2);
   result := D / ((nf - 1) * (N1 - N2 + N3));
   y.free;
end;

procedure Collapse (lA,lB,lC: integer; var m: TANOVAModel; var x: TMatrix);
var
   lut: longintp;
   r,i,j,col: integer;
begin
     col := m.data.c;
     getmem(lut,col * sizeof(longint));
     for j := 1 to col do
         lut[j] := 0;
     for i := 1 to col do begin//fill RA
         j :=  ((i mod m.Clevels)*lC)+ ((((i-1) div m.CLevels) mod m.Blevels)*lB*m.CLevels)
         + ((((i-1) div (m.BLevels*m.CLevels)) mod m.Alevels)*lA*m.BLevels*m.CLevels)+1 ;
         lut[j] := 1;
     end; //for each column
     i := 0;
     for j := 1 to col do begin
         if lut[j] <> 0 then begin
            inc(i);
            lut[j] := i;
         end;
     end;
     //fx(i,lA,lB,lC);
     x := TMatrix.Create (m.data.r,i);
     for r := 1 to x.r do
         for j := 1 to x.c do
             x.M[r,j] := 0;
     for r := 1 to x.r do begin
         for i := 1 to m.data.c do begin//fill RA
             j :=  ((i mod m.Clevels)*lC)+ ((((i-1) div m.CLevels) mod m.Blevels)*lB*m.CLevels)
             + ((((i-1) div (m.BLevels*m.CLevels)) mod m.Alevels)*lA*m.BLevels*m.CLevels)+1 ;
             x.M[r,lut[j]] := x.M[r,lut[j]] + m.data.M[r,i];
         end; //for each column
     end; //for each row
     freemem(lut);
     //We do not need to divide by number of samples - proportion remains the same...
     // This is probably only true for Greenhouse-Geiser, not other computations.
end;

procedure Crush (var lin,lout: TMatrix; lSpan: integer);
var
   lr,lc: integer;
begin
     if (lin.c mod lspan) <> 0 then begin
        Showmessage('Serious error with function crush.');
        exit;
     end;
     lOut := TMatrix.Create (lIn.r,lIn.c div 2{abba});
     for lr := 1 to lOut.r do
         for lc := 1 to lOut.c do 
             lOut.m[lr,lc] := lIn.m[lr,lc] - lIn[lr,lc+lOut.c];
end;


procedure Greenhouse (var Results: TStrings; var m: TANOVAModel; lComp: integer);
var
    Epsilon,GGp,HFp,EpsilonHF, F,df,dfEr: double;
    k,n: integer;
    x,t: TMatrix;
begin
     if (not (m.Design in [kB0w1..kB0w3])) or (m.DF[lComp] < 2) or (m.DFErr[lComp] < 1)
     or (m.SSErr[lComp] = 0) or (m.SS[lComp] = 0) then
        exit;
     if (lComp > C) then begin
        results.Add(' -Note: ezANOVA does not compute sphericity correction for interactions.');
      exit;
     end;
     F := (m.SS[lComp]/m.DF[lComp]) / (m.SSErr[lComp]/m.DFErr[lComp]);
     if (lComp = A) and (m.Vars = 1) then //use full model
        Epsilon := GreenhouseGeiserEpsilon(m.data)
     else begin //extract the relevant condition
          case lComp of
               A: Collapse (1,0,0,m,x);
               B: Collapse (0,1,0,m,x);
               C: Collapse (0,0,1,m,x);
               AB: begin
                   if (m.Alevels <> 2) then begin
                      showmessage('Greenhouse-Geisser not yet set for this design');
                      exit;//abba
                   end;
                   Collapse (1,1,0,m,t); Crush(t,x,m.Blevels); t.free;  end;
               AC: Collapse (1,0,1,m,x);
               BC: Collapse (0,1,1,m,x);
               ABC: Collapse (1,1,1,m,x);
          end; //case of comp
          Epsilon := GreenhouseGeiserEpsilon(x);
          //reportmatrix(x);
          x.Free;
     end;
     //compute Greenhouse Geisser Correction...
     df := m.DF[lComp] * Epsilon;
     dfEr := m.DFErr[lComp] * Epsilon;
     GGp := betai((0.5 * dfEr), (0.5 * df), (dfEr / (dfEr + (df * F))));;
     //Huynh-Feldt correction.
     k := round(m.DF[lComp]+1);
     n := m.data.r;
     EpsilonHF :=  (n * (k-1) * Epsilon - 2) / ((k-1) * ((n-1) - (k-1)*Epsilon));
     if EpsilonHF < 0 then
        EpsilonHF := 0;
     if EpsilonHF > 1 then
        EpsilonHF := 1;
     df := m.DF[lComp] * EpsilonHF;
     dfEr := m.DFErr[lComp] * EpsilonHF;
     if (dfEr + (df * F)) = 0 then
        HFp := 1
     else
         HFp := betai((0.5 * dfEr), (0.5 * df), (dfEr / (dfEr + (df * F))));;
     Results.Add(' Greenhouse-Geisser{'+realtostr(Epsilon,4)+'} p<'+realtostr(GGp,7)+ ' Huynh-Feldt{'+realtostr(EpsilonHF,3)+'} p<'+realtostr(HFp,7));
end;

function CohensD (mnt,mnc,nt,nc,MSE:double): double;
//Compute Cohen's d for ANOVA
//http://www.work-learning.com/white_papers/effect_sizes/Effect_Sizes_pdf5.pdf
//inputs - mean and number for treatment and control, mean square error
var
   numer,denom: double;
begin
     result := 0;
     if (nt+nc)= 0 then exit;
     numer := mnt-mnc;
     denom := sqrt(MSE*((nt+nc-2)/(nt+nc)));
     if denom = 0 then
        exit;
     result := numer / denom;
end;


procedure Report (var Results: TStrings; Name: string; SS, df, dfEr, SSer: double; LabelLen: integer);
var
   NameStr, str: string;
    p, F,lMSEr: double;
    lDec: integer;
begin

     NameStr := PadString(Name,LabelLen)+' ';
     if (df > 0) and (dfEr > 0) and (SSEr > 0) then begin //error sets dfError to 0 so p and f not computed
        lMSEr := SSEr/dfEr;
        F := (SS/df) / lMSEr;
        if F = 0 then
           p := 1
        else
            p := betai((0.5 * dfEr), (0.5 * df), (dfEr / (dfEr + (df * F))));
     end else begin
         F := 0;
         lMSEr := 0;
         p := 1;
     end;
     if F > 100 then lDec := 0
     else if F > 10 then lDec := 1
     else if F > 1 then lDec := 2
     else lDec := 3;
     Str := 'F('+inttostr(round(df))+','+inttostr(round(dfEr))+') = '+realtostr(F,lDec)+' p<'+realtostr(p , 6 ) + ' SS='+realtostr(SS,2)+' MSe='+realtostr(lMSEr,2);

     Results.Add(Concat(NameStr+Str));
end; //Report

procedure GenerateDescriptives ( x: TMatrix; var CondRA: DescriptivesRAp);
//compute n, sum, sumOfSqrs for each column...
var
   lCol,lRow: integer;
begin
     if (x.r < 1) or (x.c < 1) then
        exit;
     for lCol := 1 to x.c do begin
         CondRA[lCol].n := x.r;
         CondRA[lCol].sum := 0;
         CondRA[lCol].sumSq := 0;
         for lRow := 1 to x.r do begin
             CondRA[lCol].sum := CondRA[lCol].sum + x.m[lRow,lCol];
             CondRA[lCol].sumSq := CondRA[lCol].sumSq + (x.m[lRow,lCol]*x.m[lRow,lCol]);
         end;//for each row
     end; //for each Col
end;  //procedure GenerateDescriptives

function ANOVASetup (var m: TANOVAModel; var {Vars,L1,L2,L3,}LabelLen: integer): boolean;
begin
     result := false;
     if (m.data.c < 2) or (m.data.r < 2) then begin
                 showmessage('ANOVA error: must have at least 2 observations and 2 levels.');
                 exit;
     end;
     LabelLen := length(m.Alabel);
     if m.Alevels < 2 then begin
                 showmessage('ANOVA error: First factor must have at least two levels.');
                 exit;
     end;
     if m.BLevels < 2 then
        m.Blevels := 1;
     if m.CLevels < 2 then
        m.Clevels := 1;
     if m.Blevels < 2 then begin //single factor ANOVA
        m.Clevels := 1;
        m.vars := 1;
     end else begin
         LabelLen := LabelLen +1+length(m.Blabel);//+1 for asterix A*B
         if m.Clevels < 2 then begin
            m.vars := 2;
         end else begin
             m.vars := 3;
             LabelLen := LabelLen + 1+length(m.Clabel);//+1 for asterix A*B*C
         end;
     end;
     if (m.Alevels*m.Blevels*m.Clevels) <> m.data.c then begin
                 showmessage('Error: model describes data with '+inttostr(m.Alevels*m.Blevels*m.Clevels) +' columns');
                 exit;
     end;
     //if LabelLen < 8 then
     //   LabelLen := 8;
     result := true;
end;

function GetSS (CondRA: DescriptivesRAp;  var m: TANOVAModel; lA, lB, lC: integer): double;
var
   tempSum: doublep;// array[1..maxElements] of double;
   ColPerVal, i, j: integer;
begin
     result := 0;
     getmem(tempSum,m.data.c * sizeof(double));
     for i := 1 to m.data.c do {init RA}
         TempSum[i] := 0;
     ColPerVal := 0;
     for i := 1 to m.data.c do begin//fill RA
         j :=  ((i mod m.Clevels)*lC)+ ((((i-1) div m.CLevels) mod m.Blevels)*lB*m.CLevels)
         + ((((i-1) div (m.BLevels*m.CLevels)) mod m.Alevels)*lA*m.BLevels*m.CLevels)+1 ;
         TempSum[j] := TempSum[j] + CondRA[i].sum;
         if j = 1 then
            inc(ColPerVal);
     end;
     for i := 1 to m.data.c do
         result := result + (TempSum[i] * TempSum[i]); {set to sum squared}
     if (ColPerVal * CondRA[1].n)<>0 then
        result := result / (ColPerVal * CondRA[1].n);
     freemem(tempSum);
end;

function GetSubjSS (var m: TANOVAModel; lA, lB, lC: integer): double;
var
   tempSum,rowSum: doublep;// array[1..maxElements] of double;
   ColPerVal, s,i, j: integer;
begin
     result := 0;
     getmem(tempSum,m.data.c * sizeof(double));
     getmem(rowSum,m.data.c * sizeof(double));
     for i := 1 to m.data.c do {init RA}
         TempSum[i] := 0;
     ColPerVal := 0;
     for s := 1 to m.data.r do begin //for each subj
       for i := 1 to m.data.c do {init RA}
         RowSum[i] := 0;
       for i := 1 to m.data.c do begin//fill RA
         j :=  ((i mod m.Clevels)*lC)+ ((((i-1) div m.CLevels) mod m.Blevels)*lB*m.CLevels)
         + ((((i-1) div (m.BLevels*m.CLevels)) mod m.Alevels)*lA*m.BLevels*m.CLevels)+1 ;
         //if (lB=1) and (lA=1) then fx(j);
         RowSum[j] := RowSum[j] +  m.data[s,i];
         if (j = 1) and (s = 1) then
            inc(ColPerVal);
       end;//for each column
       for i := 1 to m.data.c do {init RA}
         TempSum[i] := TempSum[i] + sqr(RowSum[i]);
     end; //for each subj
     for i := 1 to m.data.c do
         result := result + TempSum[i]; {set to sum squared}
     if (ColPerVal)<>0 then
        result := result / (ColPerVal);
     freemem(rowSum);
     freemem(tempSum);
end;

procedure SubjError (var m: TANOVAModel);
var
   i: integer;
begin
     for i := T to ABC do
         m.S[i] := 0;
     m.S[T] := GetSubjSS(m,0,0,0);
     m.S[A] := GetSubjSS(m,1,0,0);
     if m.Vars > 1 then begin
        m.S[B] := GetSubjSS(m,0,1,0);
        m.S[AB] := GetSubjSS(m,1,1,0);
        if m.Vars > 2 then begin
           m.S[C] := GetSubjSS(m,0,0,1);
           m.S[AC] := GetSubjSS(m,1,0,1);
           m.S[BC] := GetSubjSS(m,0,1,1);
           m.S[ABC] := GetSubjSS(m,1,1,1);
        end; //>2 vars
     end; //>1 var
end;

procedure BasicRatios (var m: TANOVAModel; var CondRA: DescriptivesRAp);
var
   i: integer;
begin
     for i := T to ABC do
         m.BR[i] := 0;
     m.BR[T] := GetSS(CondRA,m,0,0,0);
     m.BR[A] := GetSS(CondRA,m,1,0,0);
     if m.Vars > 1 then begin
        m.BR[B] := GetSS(CondRA,m,0,1,0);
        m.BR[AB] := GetSS(CondRA,m,1,1,0);
        if m.Vars > 2 then begin
             m.BR[C] := GetSS(CondRA,m,0,0,1);
             m.BR[AC] := GetSS(CondRA,m,1,0,1);
             m.BR[BC] := GetSS(CondRA,m,0,1,1);
             m.BR[ABC] := GetSS(CondRA,m,1,1,1);
        end; //>2 vars
     end; //>1 var
end;//proc BasicRatios

procedure MixedMSErb1w1 (var m: TANOVAModel);
//a 2 factor ANOVA with B repeated and A between...
begin
     SubjError(m);
     m.SSErr[A] :=  m.S[A]-m.BR[A];
     m.dfErr[A] := (m.Alevels)*(m.data.r-1);
     m.SSErr[B] :=  m.S[AB]-m.BR[AB]-m.S[A]+m.BR[A];
     m.dfErr[B] := (m.Alevels)*(m.Blevels-1)*(m.data.r-1);
     m.SSErr[AB] := m.SSErr[B];//  m.S[AB]-m.BR[AB]-m.S[A]-m.S[B]+m.BR[A]+m.BR[B]+m.S[T]-m.BR[T];
     m.dfErr[AB] := m.dfErr[B];//(m.Alevels-1)*(m.Blevels-1)*(m.data.r-1);
end;

procedure MixedMSErb2w1 (var m: TANOVAModel);
//a 3 factor ANOVA with C repeated and A,B between...
//see Kirk 1982, p525 table 11.9-1, 11.9-2
begin
     SubjError(m);
     m.SSErr[A] :=  m.S[AB]-m.BR[AB];
     m.dfErr[A] := (m.Alevels*m.Blevels)*(m.data.r-1);
     m.SSErr[B] :=  m.SSErr[A];
     m.dfErr[B] := m.dfErr[A];
     m.SSErr[AB] :=  m.SSErr[A];
     m.dfErr[AB] := m.dfErr[A];
     m.SSErr[C] :=  m.S[ABC]-m.BR[ABC]-m.S[AB]+m.BR[AB];
     m.dfErr[C] := (m.Alevels*m.Blevels)*(m.data.r-1)*(m.CLevels-1);
     m.SSErr[AC] :=  m.SSErr[C];
     m.dfErr[AC] := m.dfErr[C];
     m.SSErr[BC] :=  m.SSErr[C];
     m.dfErr[BC] := m.dfErr[C];
     m.SSErr[ABC] :=  m.SSErr[C];
     m.dfErr[ABC] := m.dfErr[C];
end;

procedure MixedMSErb1w2 (var m: TANOVAModel);
//a 3 factor ANOVA with B,C repeated and A between...
//see Kirk 1982, p537-540 Tables 11.11-1, 11.11-2
begin
     SubjError(m);
     m.SSErr[A] :=  m.S[A]-m.BR[A];
     m.dfErr[A] := (m.Alevels)*(m.data.r-1);
     m.SSErr[B] :=  m.S[AB]-m.BR[AB]-m.S[A]+m.BR[A];
     m.dfErr[B] := (m.Alevels)*(m.data.r-1)*(m.Blevels-1);
     m.SSErr[AB] :=  m.SSErr[B];
     m.dfErr[AB] := m.dfErr[B];
     m.SSErr[C] :=  m.S[AC]-m.BR[AC]-m.S[A]+m.BR[A];
     m.dfErr[C] := (m.Alevels)*(m.data.r-1)*(m.Clevels-1);
     m.SSErr[AC] :=  m.SSErr[C];
     m.dfErr[AC] := m.dfErr[C]; 

     m.SSErr[BC] :=  m.S[ABC]-m.BR[ABC]
                 -m.S[AB]-m.S[AC]+m.BR[AB]+m.BR[AC]
                 +m.S[A]-m.BR[A];
     m.dfErr[BC] := (m.Alevels)*(m.data.r-1)*(m.Blevels-1)*(m.Clevels-1);
     m.SSErr[ABC] :=  m.SSErr[BC];
     m.dfErr[ABC] := m.dfErr[BC];
end;

procedure RepeatedMeasuresMSEr (var m: TANOVAModel);
begin
     SubjError(m);
     m.SSErr[A] :=  m.S[A]-m.BR[A]-m.S[T]+m.BR[T];
     m.dfErr[A] := (m.Alevels-1)*(m.data.r-1);
     if m.Vars > 1 then begin
              m.SSErr[B] :=  m.S[B]-m.BR[B]-m.S[T]+m.BR[T];
              m.dfErr[B] := (m.Blevels-1)*(m.data.r-1);
              m.SSErr[AB] :=  m.S[AB]-m.BR[AB]-m.S[A]-m.S[B]+m.BR[A]+m.BR[B]+m.S[T]-m.BR[T];
              m.dfErr[AB] := (m.Alevels-1)*(m.Blevels-1)*(m.data.r-1);
     end; //Vars > 1
     if m.Vars > 2 then begin
              m.SSErr[C] :=  m.S[C]-m.BR[C]-m.S[T]+m.BR[T];
              m.dfErr[C] := (m.Clevels-1)*(m.data.r-1);
              m.SSErr[AC] :=  m.S[AC]-m.BR[AC]-m.S[A]-m.S[C]+m.BR[A]+m.BR[C]+m.S[T]-m.BR[T];
              m.dfErr[AC] := (m.Alevels-1)*(m.Clevels-1)*(m.data.r-1);

              m.SSErr[BC] :=  m.S[BC]-m.BR[BC]-m.S[B]-m.S[C]+m.BR[B]+m.BR[C]+m.S[T]-m.BR[T];
              m.dfErr[BC] := (m.Blevels-1)*(m.Clevels-1)*(m.data.r-1);
              m.SSErr[ABC] :=  m.S[ABC]-m.BR[ABC]
                           -m.S[AB]-m.S[AC]-m.S[BC]
                           +m.BR[AB]+m.BR[AC]+m.BR[BC]
                           +m.S[A]+m.S[B]+m.S[C]
                           -m.BR[A]-m.BR[B]-m.BR[C]
                                 -m.S[T]+m.BR[T];
              m.dfErr[ABC] := (m.Alevels-1)*(m.Blevels-1)*(m.Clevels-1)*(m.data.r-1);
     end; //Vars > 2
end; //proc RepeatedMeasuresMSEr

procedure ReportEta (var Results: TStrings;  lVal: double; lLabel: string);
begin
     Results.Add('Eta '+lLabel+' = '+realtostr(lVal,6));
end;

procedure doGeneralizedEta(var Results: TStrings; var m: TANOVAModel; TotMSEr: double);
var
   SSs,lA,lB,lAB: double;
begin
     if m.Vars > 2 then
        exit;
     if m.Vars = 1 then begin
         //xxx
         exit;
     end;
     SSs := TotMSEr - m.SSErr[A] - m.SSErr[B] - m.SSErr[AB];
     lA := m.SS[A] / ( m.SS[A] + m.SSErr[A] + m.SSErr[B] + m.SSErr[AB]+ SSs);
     lB := m.SS[B] / ( m.SS[B] + m.SSErr[A] + m.SSErr[B] + m.SSErr[AB]+ SSs);
     lAB := m.SS[AB] / ( m.SS[AB] + m.SSErr[A] + m.SSErr[B] + m.SSErr[AB]+ SSs);
     Results.Add(realtostr(m.SSErr[A],6) +': '+ realtostr(m.SSErr[B],6) +': '+ realtostr(m.SSErr[AB],6) +': '+ realtostr(SSs,6));
     ReportEta (Results,lA,m.Alabel);
     ReportEta (Results,lB,m.Blabel);
     ReportEta (Results,lAB,m.Alabel+'*'+m.Blabel);

end;

procedure doANOVA (var Results: TStrings; var m: TANOVAModel; var lglobalDFError,lglobalMSamp: double);
//label   11, 21;
var
   CondRA: DescriptivesRAp;
   SubjSS,TotDFer,TotMSer: double;
   j,i,Comps,labellen: integer;
begin
     lglobalDFError := 0;
     lglobalMSamp := 0;
     //next - check that model matrix x matches described model m
     if not ANOVASetup (m,  labellen) then exit;
     if (m.design < kb1w0) or (m.design > kb1w2 ) then
        exit;
     //next get memory for descriptive statistics
     GetMem( CondRA,m.data.c*sizeof(TDescriptives) );
     GenerateDescriptives(m.data,CondRA);
     //next - generate basic ratios for each factor
     BasicRatios(m,CondRA);
     //report if this is a repeated, between or mixed design
     Results.Add('ANOVA: Design '+kDesignStr[m.Design]);
     //next - compute Effect Sizes (SumSquares) using Basic Ratios
     m.SS[A] := m.BR[A]-m.BR[T];
     if m.Vars > 1 then begin
        m.SS[B] := m.BR[B]-m.BR[T];
        m.SS[AB] := m.BR[AB]-m.BR[A]-m.BR[B] +m.BR[T];
        if m.Vars > 2 then begin
              m.SS[C] := m.BR[C]-m.BR[T];
              m.SS[AC] := m.BR[AC]-m.BR[A]-m.BR[C] +m.BR[T];
              m.SS[BC] := m.BR[BC]-m.BR[B]-m.BR[C] +m.BR[T];
              m.SS[ABC] := m.BR[ABC]-m.BR[AB]-m.BR[AC]-m.BR[BC]
                        +m.BR[A]+m.BR[B]+m.BR[C]- m.BR[T];
        end; //>2 vars
     end; //>1 var
     //Next - compute Effect DF
     SubjSS := 0;
     for j := 1 to m.data.r do
         for i := 1 to m.data.c do
             SubjSS :=  SubjSS + sqr(m.data[j,i]);
     m.df[A] := m.Alevels-1;
     if m.Vars > 1 then begin
        m.df[B] := m.Blevels-1;
        m.df[AB] := (m.Alevels-1)*(m.Blevels-1);
        if m.Vars > 2 then begin
              m.df[C] := m.Clevels-1;
              m.df[AC] := (m.Alevels-1)*(m.Clevels-1);
              m.df[BC] := (m.Blevels-1)*(m.Clevels-1);
              m.df[ABC] := (m.Alevels-1)*(m.Blevels-1)*(m.Clevels-1);
        end; //>2 vars
     end; //>1 vars
     if m.Vars = 1 then
        Comps := A
     else if m.Vars = 2 then
          Comps := AB //A,B,AB
     else
         Comps := ABC;
     //COMPUTE ERRORS
     //total DF for errors
     TotDFer := m.Alevels*m.Blevels*m.Clevels*(m.data.r-1);
     //Total Error - including within and between
     case m.Vars of
         1: TotMSEr := SubjSS -m.BR[A];
         2: TotMSEr := SubjSS - m.BR[AB];
         else TotMSEr := SubjSS - m.BR[ABC];
     end;
        for i := 1 to Comps do begin
             m.dfErr[i] := 0;
             m.SSErr[i] := 0;
        end;
     //repeated measures designs partion error, while between subjects designs do not
     if  (m.design >= kb0w1) and (m.Design <= kb0w3) then begin //all repeated-subj factors
         RepeatedMeasuresMSEr(m);
     end else if (m.design >= kb1w0) and (m.Design <= kb3w0) then begin //next - between subject design
         for i := 1 to Comps do begin
             m.dfErr[i] := TotDFer;
             m.SSErr[i] := TotMSEr;
         end;
     end else begin //Mixed Design
         if m.design = kb1w1 then
            MixedMSErb1w1(m)
         else if m.design = kb2w1 then
            MixedMSErb2w1(m)
         else if m.design = kb1w2 then
            MixedMSErb1w2(m)
         else
             Showmessage('Unknown design '+inttostr(m.design));
     end; //End Mixed design
//REPORT RESULTS
     Report (Results,m.Alabel, m.SS[A], m.df[A], m.dfErr[A], m.SSErr[A], LabelLen);

     //if (m.Design in [kb0w1]) and (m.Alevels > 2) then
     if (m.Design in [kb0w1..kb0w3]) and (m.Alevels > 2) then
        Greenhouse(Results,m,A);
     if m.Vars > 1 then begin
        Report (Results,m.Blabel, m.SS[B], m.df[B], m.dfErr[B], m.SSErr[B], LabelLen);
        if (m.Design in [kb0w1..kb0w3]) and (m.Blevels > 2) then
           Greenhouse(Results,m,B);
        if m.Vars > 2 then begin
           Report (Results,m.Clabel, m.SS[C], m.df[C], m.dfErr[C], m.SSErr[C], LabelLen);
           if (m.Design in [kb0w1..kb0w3]) and (m.Clevels > 2) then
              Greenhouse(Results,m,C);
        end;
        Report (Results,m.Alabel+'*'+m.Blabel, m.SS[AB], m.df[AB], m.dfErr[AB], m.SSErr[AB], LabelLen);
        if (m.Design in [kb0w1..kb0w3]) and ((m.Blevels > 2) or (m.Alevels > 2)) then
           Greenhouse(Results,m,AB);
        if m.Vars > 2 then begin
           Report (Results,m.Alabel+'*'+m.Clabel, m.SS[AC], m.df[AC], m.dfErr[AC], m.SSErr[AC], LabelLen);
           Report (Results,m.Blabel+'*'+m.Clabel, m.SS[BC], m.df[BC], m.dfErr[BC], m.SSErr[BC], LabelLen);
           Report (Results,m.Alabel+'*'+m.Blabel+'*'+m.Clabel, m.SS[ABC], m.df[ABC], m.dfErr[ABC], m.SSErr[ABC], LabelLen);
        end; //>2 vars
     end; //>1 var
     //if m.RepMix > 0 then //report residual Between-Subject Error Term
     doGeneralizedEta(Results,m,TotMSEr);
   if (m.design >= kb0w1) and (m.design <= kb0w3) then begin
      //only compute this for within subj
        for i := 1 to Comps do begin
             lglobalDFError := lglobalDFError + m.dfErr[i];
             lglobalMSamp := lglobalMSamp + m.SSErr[i];
        end;
       if lglobalDFError = 0 then
          lglobalMSamp := 0
       else
           lglobalMSamp := lglobalMSamp / lglobalDFError; //Mason and Loftus, 2003, Canadian J of Exp Psych, 57, 203-220
    end else if (m.design >= kb1w0) and (m.design <= kb3w0) then begin
      lglobalMSamp := TotMSEr/TotDFer;
      lglobalDFError := round(TotDFer);
    end else begin
       //mixed design - not sure correct tactic...
       lglobalMSamp := 0;
       lglobalDFError := 0;
    end;
    FreeMem( CondRA);
end;//procedure doANOVA;

end.
