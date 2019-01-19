unit stat;
{$MODE Delphi}
interface
uses
Dialogs,SysUtils;

function betai (a, b, x: double): double; {see numerical recipes for Pascal page 188}
procedure ConfidenceInterval (lN: integer;lSD, lMean: double;var pMin, pMax: double);
procedure Descriptive (nV, SumOfSqrs, Sum: double; var lMn,lVar,lSD,lSE: double);
function t025(lDF: integer): double; //returns value of T that includes 47.5 of distribution
function MultifactorialConfidenceInterval (lN, lDF: integer;lMSerror: double): double;
procedure PairedTTest (N, SumOfDifSqrs, SumDif: double;var t, p,DF: double);
procedure Ttest (N, N2, SumOfSqrs, SumOfSqrs2, Sum, Sum2: double;var t, p,lDF: double);
procedure Ftest (N, N2, SumOfSqrs, SumOfSqrs2, Sum, Sum2: double;var f, p,lDFLov,lDFhiv: double);
procedure TukeyCrit (lDF,lComp: integer; var l05, l01: double);
function gammq( a,x: double): double;
function t2p (t,df: double): double; //convert T-score to p-value

const
     ITMAX = 300;
     EPS = 3.0e-7;
     kMinTukeyComp = 2;
     kMaxTukeyComp = 10;
     kMinTukeyDF = 5;

implementation

const
     kMaxTukeyDF = 26;
     gTukeyRA05 : array [kMinTukeyDF..kMaxTukeyDF,kMinTukeyComp..kMaxTukeyComp] of double =
      (
      {df5}(3.64,4.60,5.22,5.67,6.03,6.33,6.58,6.80,6.99),
      (3.46,4.34,4.90,5.30,5.63,5.90,6.12,6.32,6.49),
      {df7}(3.34,4.16,4.68,5.06,5.36,5.61,5.82,6,6.16),
      (3.26,4.04,4.53,4.89,5.17,5.4,5.6,5.77,5.92),
      {df9}(3.2,3.95,4.41,4.76,5.02,5.24,5.43,5.59,5.74),
      (3.15,3.88,4.33,4.65,4.91,5.12,5.3,5.46,5.6),
      {df11}(3.11,3.82,4.26,4.57,4.82,5.03,5.2,5.35,5.49),
      (3.08,3.77,4.2,4.51,4.75,4.95,5.12,5.27,5.39),
      {df13}(3.06,3.73,4.15,4.45,4.69,4.88,5.05,5.19,5.32),
      (3.03,3.7,4.11,4.41,4.64,4.83,4.99,5.13,5.25),
      {df15}(3.01,3.67,4.08,4.37,4.59,4.78,4.94,5.08,5.2),
      (3,3.65,4.05,4.33,4.56,4.74,4.9,5.03,5.15),
      {df17}(2.98,3.63,4.02,4.3,4.52,4.7,4.86,4.99,5.11),
      (2.97,3.61,4,4.28,4.49,4.67,4.82,4.96,5.07),
      {df19}(2.96,3.59,3.98,4.25,4.47,4.65,4.79,4.92,5.04),
      {df20}(2.95,3.58,3.96,4.23,4.45,4.62,4.77,4.9,5.01),
      {df24}(2.92,3.53,3.9,4.17,4.37,4.54,4.68,4.81,4.92),
      {df30}(2.89,3.49,3.85,4.1,4.3,4.46,4.6,4.72,4.82),
      {df40}(2.86,3.44,3.79,4.04,4.23,4.39,4.52,4.63,4.73),
      {df60}(2.83,3.4,3.74,3.98,4.16,4.31,4.44,4.55,4.65),
      {df120}(2.8,3.36,3.68,3.92,4.1,4.24,4.36,4.47,4.56),
      {dfinf}(2.77,3.31,3.63,3.86,4.03,4.17,4.29,4.39,4.47)

      );
gTukeyRA01 : array [kMinTukeyDF..kMaxTukeyDF,kMinTukeyComp..kMaxTukeyComp] of double =
      (
      {df5}(5.7,6.98,7.8,8.42,8.91,9.32,9.67,9.97,10.24),
      (5.24,6.33,7.03,7.56,7.97,8.32,8.61,8.87,9.1),
      {df7}(4.95,5.92,6.54,7.01,7.37,7.68,7.94,8.17,8.37),
      (4.75,5.64,6.2,6.62,6.96,7.24,7.47,7.68,7.86),
      {df9}(4.6,5.43,5.96,6.35,6.66,6.91,7.13,7.33,7.49),
      (4.48,5.27,5.77,6.14,6.43,6.67,6.87,7.05,7.21),
      {df11}(4.39,5.15,5.62,5.97,6.25,6.48,6.67,6.84,6.99),
      (4.32,5.05,5.5,5.84,6.1,6.32,6.51,6.67,6.81),
      {df13}(4.26,4.96,5.4,5.73,5.98,6.19,6.37,6.53,6.67),
      (4.21,4.89,5.32,5.63,5.88,6.08,6.26,6.41,6.54),
      {df15}(4.17,4.84,5.25,5.56,5.8,5.99,6.16,6.31,6.44),
      (4.13,4.79,5.19,5.49,5.72,5.92,6.08,6.22,6.35),
      {df17}(4.1,4.74,5.14,5.43,5.66,5.85,6.01,6.15,6.27),
      (4.07,4.7,5.09,5.38,5.6,5.79,5.94,6.08,6.2),
      {df19}(4.05,4.67,5.05,5.33,5.55,5.73,5.89,6.02,6.14),
      {df20}(4.02,4.64,5.02,5.29,5.51,5.69,5.84,5.97,6.09),
      {df24}(3.96,4.55,4.91,5.17,5.37,5.54,5.69,5.81,5.92),
      {df30}(3.89,4.45,4.8,5.05,5.24,5.4,5.54,5.65,5.76),
      {df40}(3.82,4.37,4.7,4.93,5.11,5.26,5.39,5.5,5.6),
      {df60}(3.76,4.28,4.59,4.82,4.99,5.13,5.25,5.36,5.45),
      {df120}(3.7,4.2,4.5,4.71,4.87,5.01,5.12,5.21,5.3),
      {inf}(3.64,4.12,4.4,4.6,4.76,4.88,4.99,5.08,5.16)
      );
procedure TukeyCrit (lDF,lComp: integer; var l05, l01: double);
var
   lDFclosest : integer;
begin
     l05 := 666;
     l01 := 666;
    if (lComp < kMinTukeyComp) or (lComp > kMaxTukeyComp) then
       exit;
    if lDF < kMinTukeyDF then
       exit;
    if lDF <= 20 then
       lDFclosest := lDF
    else if lDF < 24 then
         lDFclosest := 20
    else if lDF < 30 then
         lDFclosest := 21
    else if lDF < 40 then
         lDFclosest := 22
    else if lDF < 60 then
         lDFclosest := 23
    else if lDF < 120 then
         lDFclosest := 24
    else
        lDFclosest := 25; //n >=120
    l01 := gTukeyRA01[lDFclosest, lComp];
    l05 := gTukeyRA01[lDFclosest, lComp];
end;
procedure TellUser (lStr: String);
begin
     MessageDlg('Stat Unit Error: ' +lStr,mtInformation,[mbOK],0);
end;

function t2p (t,df: double): double; //convert T-score to p-value
begin
  result := 0;
  if (df = 0) or ((df + sqr(t)) = 0) then
    exit;
  result := betai(0.5 * df, 0.5, df / (df + sqr(t)));
end;

function MultifactorialConfidenceInterval (lN, lDF: integer;lMSerror: double): double;
var
   lT: double;
begin
     lT := t025(lDF);
     if sqrt(lN) > 0 then
        result := lT * sqrt(abs(lMSerror) / lN)
     else
       result := 0;
end;



procedure ConfidenceInterval (lN: integer;lSD, lMean: double;var pMin, pMax: double);
var
			lT: double;
			lDF: integer;
begin
     lDF := lN - 1;
     lT := t025(lDF);
     if sqrt(lN) > 0 then begin
				pMin := lMean - (lT * (abs(lSD) / (sqrt(lN))));
				pMax := lMean + (lT * (abs(lSD) / (sqrt(lN))));
     end else begin
				pMin := 0;
				pMax := 0;
     end;
end;  //confidence intervals

procedure PairedTTest (N, SumOfDifSqrs, SumDif: double;var t, p,DF: double);
        var
			meanDif, SumDifSqr, temp: double;
	begin
		df := n - 1;
                t := 0;
                p := 1;

        if (SumOfDifSqrs <> 0)and (SumDif <> 0)and (df <> 0) and (N <> 0) then begin
           meanDif := SumDif / N;
           SumDifSqr := sqr(SumDif);
           temp := SumOfDifSqrs - (SumDifSqr / n);
           temp := temp / (n * df);
           temp := sqrt(temp);
           if temp <> 0 then begin
              t := meanDif / temp;
              p := betai(0.5 * df, 0.5, df / (df + sqr(t)))
           end else {t is infinitely big}
               p := -1.0;
        end;
end; {paired ttest}

function t025(lDF: integer): double; //returns value of T that includes 47.5 of distribution
//This is the same as Excel =TINV(0.05,lDF)
var lT: double;
begin
     case lDF of
          1: lT := 12.706;
			2:lT := 4.303;
			3:lT := 3.182;
			4:lT := 2.776;
			5:lT := 2.571;
			6:lT := 2.447;
			7:lT := 2.365;
			8:lT := 2.306;
			9:lT := 2.262;
			10:lT := 2.228;
			11:lT := 2.201;
			12:lT := 2.179;
			13:lT := 2.160;
			14:lT := 2.145;
			15:lT := 2.131;
			16:lT := 2.120;
			17:lT := 2.110;
			18:lT := 2.101;
			19:lT := 2.093;
			20:lT := 2.086;
			21:lT := 2.080;
			22:lT := 2.074;
			23:lT := 2.069;
			24:lT := 2.064;
			25:lT := 2.060;
			26:lT := 2.056;
			27:lT := 2.052;
			28:lT := 2.048;
			29:lT := 2.045;
			30..39:lT := 2.042;
			40..49:lT := 2.021;
			50..59:lT := 2.009;
                        60..79: lT := 2;
                        80..99: lT := 1.99;
                        100..119: lT := 1.984;
                        120..139: lT := 1.98;
                        140..149: lT := 1.977;
                        150..159: lT := 1.976;
                        160..179: lT := 1.975;
                        180..199: lT := 1.973;
                        200..999: lT := 1.972;
			else {>=999} lT := 1.962; //value for 1000, infinity is 1.96
     end; {case}
     result := lT;
     //showmessage(floattostr( tinv( 0.025,lDF ))+'   '+floattostr(lT));
end;

procedure Ttest (N, N2, SumOfSqrs, SumOfSqrs2, Sum, Sum2: double;var t, p,lDF: double);
    {for independent samples}
    var {quick t-test- given mean, variance, etc: requires only one pass of data}
        mean, mean2,lSumSqr,lSumSqr2: double;
     Temp1, Temp2, StdDev: real;
	begin
        ldf := 0;
        t := 0;
        p := 1;
        lDF := 0;
        if (n = 0) or (n2 = 0) or ((n+n2-2) < 1) then
           exit; {MessageDlg('T-test divide by 0 error.', mtWarning, [mbOk],0)}
        mean := Sum / n;
        mean2 := Sum2 / n2;
        lSumSqr := sqr(Sum);
        lSumSqr2 := sqr(Sum2);
        ldf := N + N2 - 2;
        if (N=N2) and (mean=mean2) and (SumOfSqrs=SumOfSqrs2) and (lSumSqr=lSumSqr2) then begin
           {p := 1;}
           exit;
        end;
        if (N<1) or (N2=0) or (ldf=0) then
           exit;

        Temp1 := SumOfSqrs - (lSumSqr / N);   {gStatRl[1..NOC, Mean, SumOfSqrs, SumSqr, Sd]}
        Temp2 := SumOfSqrs2 - (lSumSqr2 / N2);
        StdDev := sqrt(((Temp1 + Temp2) / ldf) * (1.0 / N + 1.0 / N2));
         if (StdDev <> 0) then
		  t := (Mean - Mean2) / StdDev;

         if ((ldf + sqr(t)) <> 0) and (t <> 0) then
		 p := betai(0.5 * round(ldf), 0.5, round(ldf) / (ldf + sqr(t)));

 end;  {ttest}

procedure Descriptive (nV, SumOfSqrs, Sum: double; var lMn,lVar,lSD,lSE: double);
begin
     lSD := 0;
     lSE := 0;
     lMn := 0;
     if (nV > 0) then
        lMn := Sum / nV;
     if (nV > 1) then begin
        lVar := SumOfSqrs-(Sum*Sum/nV);
        lVar := (lVar)/(nV-1);
        lSD := sqrt(lVar );
	lSE := lSD/ sqrt(nV);
     end;
end;

      function gammln (xx: double): double;  {Numerical Recipes for Pascal, p 177}
		const
			stp = 2.50662827465;
		var
			x, tmp, ser: double;
	begin
		x := xx - 1.0;
		tmp := x + 5.5;
		tmp := (x + 0.5) * ln(tmp) - tmp;
		ser := 1.0 + 76.18009173 / (x + 1.0) - 86.50532033 /
         (x + 2.0) + 24.01409822 / (x + 3.0) - 1.231739516 / (x + 4.0) + 0.120858003e-2 / (x + 5.0) - 0.536382e-5 / (x + 6.0);
		gammln := tmp + ln(stp * ser)
	end; {procedure gammln}
	function betacf (a, b, x: double): double;
		label
			99;
		const
			itmax = 100;
			eps = 3.0e-7;
		var
			tem, qap, qam, qab, em, d, bz, bpp, bp, bm, az, app, am, aold, ap: double;
			m: integer;
	begin
		am := 1.0;
		bm := 1.0;
		az := 1.0;
		qab := a + b;
		qap := a + 1.0;
		qam := a - 1.0;
		bz := 1.0 - qab * x / qap;
		for m := 1 to itmax do begin
				em := m;
				tem := em + em;
				d := em * (b - m) * x / ((qam + tem) * (a + tem));
				ap := az + d * am;
				bp := bz + d * bm;
				d := -(a + em) * (qab + em) * x / ((a + tem) * (qap + tem));
				app := ap + d * az;
				bpp := bp + d * bz;
				aold := az;
				am := ap / bpp;
				bm := bp / bpp;
				az := app / bpp;
				bz := 1.0; {what the hell is this for?}
				if abs(az - aold) < eps * abs(az) then
					goto 99
			end;
		TellUser('Error in Betacf function: a or b to big or itmax to small.');
99:
		betacf := az;
	end; {betacf}


	function betai (a, b, x: double): double; {see numerical recipes for Pascal page 188}
		var
			bt: double;
	begin
                if (a <= 0) or (b <=0) then begin
                   result := 1;
                   //TellUser('Error in Betai function: DF<=0');
                   exit;

                end;
		if (x < 0.0) or (x > 1.0) then begin
                   TellUser('Error in Betai function: p<0 or p>1.');
                   exit;
                end;
		if (x = 0.0) or (x > 1.0) then
			bt := 0.0
		else
			bt := exp(gammln(a + b) - gammln(a) - gammln(b) + a * ln(x) + b * ln(1.0 - x));
		if x < (a + 1.0) / (a + b + 2.0) then
			betai := bt * betacf(a, b, x) / a
		else
			betai := 1.0 - bt * betacf(b, a, 1.0 - x) / b
	end; {betai}

procedure Ftest (N, N2, SumOfSqrs, SumOfSqrs2, Sum, Sum2: double;var f, p,lDFLov,lDFhiv: double);
		var
			{dfLov, dfHiV,} v1, v2: double;
	begin
             ldfLov := (n - 1);
             ldfHiV := (n2 - 1);
             f := 0;
             p := 1;
             if (N=1) or (N2=1) then exit;
             v1 := (SumofSqrs - ((Sum * Sum) / N)) / (N - 1); {variance of 1}
             v2 := (SumofSqrs2 - ((Sum2 * Sum2) / N2)) / (N2 - 1); {variance of 2}
             {if v1 = v2 then exit;}
             if (v2 <> 0) and (v1 <> 0) then begin
                if (v2 > v1) then begin
                   f := v2 / v1;
                   ldfLov := (n - 1);
                   ldfHiV := (n2 - 1);
                end else begin
                    f := v1 / v2;
                    ldfLov := (n2 - 1);
                    ldfHiV := (n - 1);
                end;
                p := betai(0.5 * ldfLov, (0.5 * ldfHiV), (ldfLov / (ldfLov + ldfHiV * f)));
                p := p * 2;//two-tailed test
                //if (v2 > v1) then p := -p;  {returns p in negative value if v2 greater than v1, allowing one to determine df order}
        end {v2 & v1 <> 0}
end;  {ftest}

procedure gser(var gamser, a,x, gln: double);
var n: integer;
	sum, del, ap: double;
begin
	gln := gammln(a);
	if x <= 0.0 then begin
		if x < 0.0 then Showmessage('x less then 0 in routine GSER');
		gamser:= 0.0;
	end else begin
		ap := a;
		sum := 1.0/a;
		del := sum;
		for n := 1 to ITMAX do begin
			ap := ap + 1;
			del := del * (x/ap);
			sum := sum + del;
			if (abs(del) < abs((sum)*EPS) )then begin
				gamser := sum * exp(-x+a*ln(x)-gln);
				exit;
			end;
		end;
		Showmessage('GSER error: ITMAX too small for requested a-value');
	end;
end;

procedure gcf(var gammcf: double; a,x, gln: double);
var n: integer;
	gold,fac,b1,b0,a0,g,ana,anf,an,a1: double;
begin
	fac := 1.0;
	b1 := 1.0;
	b0 := 0.0;
	a0 := 1.0;
    gold := 0.0;
	gln := gammln(a);
	a1 := x;
	for n := 1 to ITMAX do begin
		an :=(n);
		ana := an - a;
		a0 := (a1 + a0*ana)*fac;
		b0 := (b1 + b0*ana)*fac;
		anf := an * fac;
		a1 := x*a0+anf*a1;
		b1 := x*b0+anf*b1;
		if a1 <> 0 then begin
			fac := 1.0/a1;
			g := b1*fac;
			if (abs((g-gold)/g)<EPS) then begin
				gammcf := exp(-x+a*ln(x)-gln)*g;
				exit;
			end;
			gold := g;
        end;
	end;
	Showmessage('GCF error: ITMAX too small for requested a-value');
end;



function gammq( a,x: double): double;
	var gamser, gammcf, gln: double;
begin
        gammq := 0;
	if (x < 0) or (a <= 0.0) then showmessage('Invalid arguments in routine GAMMQ')
	else begin
		if (x < (a+1.0)) then begin
			gser(gamser,a,x,gln);
			gammq := 1.0 - gamser;
		end else begin
			gcf(gammcf,a,x,gln);
			gammq := gammcf;
		end;
	end;
end;

end.
