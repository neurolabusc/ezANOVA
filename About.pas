unit About;
{$MODE Delphi}
interface

uses
  LCLIntf,LResources,
  Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls ;
type
  TAboutForm = class(TForm)
    OKbtn: TButton;
    Widgetset: TLabel;
    ProductName: TLabel;
    Author: TLabel;
    Bevel1: TBevel;
    Version: TLabel;
    URL: TLabel;
    procedure FormShow(Sender: TObject);
    procedure URLClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  AboutForm: TAboutForm;

implementation

procedure TAboutForm.FormShow(Sender: TObject);
var
  w: string;
begin
  w := '';
  {$IFDEF LCLCocoa}
  w := 'Cocoa';
  {$ENDIF}
  {$IFDEF LCLQT5}
  w := 'QT5';
  {$ENDIF}
  {$IFDEF LCLQT}
  w := 'QT4';
  {$ENDIF}
  {$IFDEF LCLGTK2}
  w := 'GTK2';
  {$ENDIF}
  {$IFDEF LCLGTK3}
  w := 'GTK3';
  {$ENDIF}
  {$IFDEF LCLWin64}
  w := 'Windows';
  {$ENDIF}
  w := w +{$IFDEF CPU64} ' 64-bit'{$ELSE} ' 32-bit'{$ENDIF};
  Widgetset.caption := w;
end;

procedure TAboutForm.URLClick(Sender: TObject);
begin
  OpenURL('http://people.cas.sc.edu/rorden/ezanova/index.html');
end;

initialization
  {$i About.lrs}
end.
