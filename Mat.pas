unit Mat;

interface
{$mode delphi}
Uses SysUtils, Classes,dialogs;

type EMatrixError     = class (Exception);
     EMatrixSizeError = class (EMatrixError);
     ESingularMatrix  = class (EMatrixError);
     ENonSquareMatrix = class (EMatrixError);
 TMatElement = double; //extended;
     TMatError = (Singular, NonSingular, NonSquare);
         TMatElementRA = array [1..1] of TMatElement;
    TMatElementp = ^TMatElementRA;


     { A Matrix is made up of a set of rows of type TRow, pTRow is
     a pointer to a single row and a matrix is a row of pTRows, this
     allows arrays larger then 65K to be built, the max size of
     a matrix is roughly 4096 MBytes }
     MatRA = array [1..1] of Double;
     Matp = ^MatRA;

     { forward declare the Matrix class }
     TMatrix = class;

     TMatrix = class (TObject)
                private
                   nr, nc : integer;
                   mx   :matp;//: pTRowList;  { pointer to a list of rows }
                   procedure SetSize (ri, ci : integer);
                   procedure FreeSpace;
                public
                   constructor  create (r, c : integer); overload; virtual;
                   constructor  create (n : integer); overload; virtual;
                   constructor  create (c : integer; d : array of TMatElement); overload; virtual;
                   destructor   destroy; override;
                   procedure Setval (ri, ci : integer; v : TMatElement);
                   function  Getval (ri, ci : integer) : TMatElement;
                   property  M[x, y : Integer] : TMatElement read GetVal write SetVal; default;
                   property  r : integer read nr;
                   property  c : integer read nc;
                    function  IsSquare : boolean;
                    function Zero:TMatrix;
                   function DiagonalMean: TMatElement;
                   function Mean: TMatElement;
                   function Cov (v: TMatrix): TMatrix;
                   function SumSqr: TMatElement;
                   function SumColMeanSqr: TMatElement;
                end;


implementation

const MATERROR = 'Matrix Operation Error:';





{ ******************************************************************** }
{ Usage:  A := TMatrix.create (3, 2);                                  }
{ ******************************************************************** }
constructor TMatrix.create (r, c : integer);
begin
  Inherited Create; nr := 0; nc := 0; mx := Nil;
  Self.SetSize (r, c);

end;

{ ******************************************************************** }
{ Create an identity matrix                                            }
{                                                                      }
{ Usage:   A := TMatrix.createI (3);                                   }
{ ******************************************************************** }
constructor TMatrix.create (n : integer);
var i : integer;
begin
  Inherited Create; nr := 0; nc := 0; mx := Nil;
  Self.SetSize (n, n);
  for i := 1 to n do Self[i,i] := 1.0;
end;


{ ******************************************************************** }
{ Create a matrix filled with values from array d given that the       }
{ number of columns equals c.                                          }
{                                                                      }
{ Usage:  A := TMatrix.createLit (2, [1, 2, 3, 4]);                    }
{         Creates a 2 by 2 array                                       }
{ ******************************************************************** }
constructor  TMatrix.create (c : integer; d : array of TMatElement);
var i, j, ri, count : integer;
begin
  Inherited Create; nr := 0; nc := 0; mx := Nil;
  ri := (High(d)+1) div c;
  Self.SetSize (ri, c);
  count := 0;
  for i := 1 to ri do
      for j := 1 to c do
          begin
          Self[i,j] := d[count];
          inc (count);
          end;
end;


{ ******************************************************************** }
{ Usage:    A.destroy, use a.free in a program                         }
{ ******************************************************************** }
destructor TMatrix.destroy;
begin
  FreeSpace;
  Inherited Destroy;
end;



{ Free the data space but not the object }
procedure TMatrix.FreeSpace;
//var i : integer;
begin
  if mx <> Nil then
     begin
     FreeMem (mx); mx := Nil;
     end;
end;


{ Internal routine used set size of matrix and allocate space }
procedure TMatrix.SetSize (ri, ci : integer);
//var i : integer;
begin
  if (mx <> Nil) and ((ri*ci)= (nr*nc)  ) then begin
     nr := ri; nc := ci;
     exit;
  end;
  //if gMat then beep;
  FreeSpace;
  nr := ri; nc := ci;
  //if gMat then beep;
  Getmem(mx,ri*ci*sizeof(TMatElement));//AllocMem (sizeof (pTRowList) * (nr+1));  { r+1 so that I can index from 1 }
end;


{ ---------------------------------------------------------------------------- }
{                               BASIC ROUTINES                                 }
{ ---------------------------------------------------------------------------- }


{ ******************************************************************** }
{ Used internally but is also accessible from the outside              }
{                                                                      }
{ Normal Usage:  A[2, 3] := 1.2;                                       }
{                                                                      }
{ ******************************************************************** }
procedure TMatrix.Setval (ri, ci : integer; v : TMatElement);
begin
  if ri > r then
     raise EMatrixSizeError.Create ('ri index out of range: ' + inttostr (ri));

  if ci > c then
     raise EMatrixSizeError.Create ('ci index out of range: ' + inttostr (ci));

  mx^[ri + ((ci-1)* r )] := v;
end;


{ ******************************************************************** }
{ Used internally but is also accessible from the outside              }
{                                                                      }
{ Normal Usage:  d := A[2, 3];                                         }
{                                                                      }
{ ******************************************************************** }
function TMatrix.Getval (ri, ci : integer) : TMatElement;
begin
  result := mx^[ri + ((ci-1)* r )];
end;

function TMatrix.IsSquare : boolean;
begin
  result := Self.nr = Self.nc;
end;

function TMatrix.Zero : TMatrix;
var i, j : integer;
begin
  for i := 1 to r do
      for j := 1 to c do
          Self[i,j] := 0.0;
  result := Self;
end;

function TMatrix.DiagonalMean: TMatElement;
var i : integer;
begin
     result := 0;
  if Self.r < 1 then
     exit;
  if Self.IsSquare then
     begin
          result := 0;
          for i := 1 to r do
              result := result + Self[i,i];
          result := result / r;
     end
  else
     raise EMatrixSizeError.Create ('Can only compute diagonal mean if matrix is square');
end;

function TMatrix.Mean: TMatElement;
var i,j : integer;
begin
     result := 0;
  if (Self.r < 1) or (Self.c < 1) then
     exit;
    for i := 1 to r do
        for j := 1 to c do
            result := result + Self[i,j];
    result := result / (r*c);
end;

function TMatrix.SumSqr: TMatElement;
var i,j : integer;
begin
     result := 0;
  if (Self.r < 1) or (Self.c < 1) then
     exit;
    for i := 1 to r do
        for j := 1 to c do
            result := result + (Self[i,j]*Self[i,j]);
end;

function TMatrix.SumColMeanSqr: TMatElement;
var i,j : integer;
    Sum: TMatElement;
begin
     result := 0;
     if (Self.r < 1) or (Self.c < 1) then
        exit;
     for i := 1 to r do begin
        Sum := 0;
        for j := 1 to c do
            Sum := Sum + (Self[i,j]);
        Sum := Sum/c; //mean
        result := result + Sum*Sum;
     end;
end;



{ ******************************************************************** }
{ This forms a diagonal matrix from the elements of vector v.          }
{                                                                      }
{ Usage: A.Diagonal (v)                                                }
{                                                                      }
{ ******************************************************************** }
(*function TMatrix.Diagonal (v : TVector) : TMatrix;
var i : integer;
begin
  if Self.IsSquare then
     begin
     if v.size = Self.nr then
        begin
        Self.zero;
        for i := 1 to r do Self[i,i] := v[i];
        result := Self;
        end
     else
        raise EMatrixSizeError.Create ('Vector must be same size as matrix in DiagonalV');
     end
  else
     raise EMatrixSizeError.Create ('Can only form a diagonal matrix from a square matrix');
end; *)

function TMatrix.Cov (v: TMatrix): TMatrix;
var i, j, sub : integer;
    sum: TMatElement;
    meanc: TMatElementp;
begin
  if (v.c <> Self.r) or (v.c <> Self.c) then
     raise EMatrixSizeError.Create ('Incorrectly sized result matrix for matrix variance-covariance');
  if (v.c < 1) or (v.r < 2) then
     raise EMatrixSizeError.Create ('Variance-covariance matrices must have at least two rows/columns');

  getmem(meanc,v.c*sizeof(TMatElement));
  for j := 1 to c do begin
      sum := 0;
      for i := 1 to v.r do
          sum := sum + v[i,j];
      meanc[j] := sum /v.r;
      //self[1,j] := meanc[j];
  end;
  for i := 1 to v.c do begin
      for j := 1 to v.c do begin
          sum := 0;
          for sub := 1 to v.r do
              sum := sum + ( (v[sub,i]-meanc[i])*( v[sub,j]-meanc[j])  );
          Self[i,j] := sum/ (v.r-1);
      end;//for j
  end;//for i
  freemem(meanc);
  result := Self;
end;

end.
