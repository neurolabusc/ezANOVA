program ezANOVA;
   {$mode objfpc}{$H+}
uses
  Interfaces,
  Forms,
  main in 'main.pas' {MainForm},
  Results in 'Results.pas' {ResultsForm},
  About in 'About.pas' {AboutForm},
  anova in 'anova.pas' {ANOVAForm},
  Utils in 'Utils.pas',
  Stat in 'Stat.pas',
  graph in 'graph.pas' {GraphForm},
  graphsettings in 'graphsettings.pas' {GraphSettingsForm};


{$R *.res}

begin
  Application.Scaled:=True;
  Application.Title:='ezANOVA';
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TResultsForm, ResultsForm);
  Application.CreateForm(TAboutForm, AboutForm);
  Application.CreateForm(TANOVAForm, ANOVAForm);
  Application.CreateForm(TGraphForm, GraphForm);
  Application.CreateForm(TGraphSettingsForm, GraphSettingsForm);
  Application.Run;
end.
