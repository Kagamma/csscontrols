unit CSSCtrls;

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

interface
uses
  Classes, SysUtils,  Types,
  strutils,
  {$ifdef fpc}
  Controls,  Graphics, Forms,
  LMessages,LCLIntf,
  FPimage, LCLType, LCLProc, IntfGraphics, GraphType, EasyLazFreeType, LazFreeTypeIntfDrawer,      // font rendering
  {$endif}
  cssbase;

type

  { TCSSShape }

  TCSSShape = Class(TGraphicControl, ICSSControl)
  private
    FCachedWidth,
    FCachedHeight: Integer;
    FIsChanged: Boolean;
    FMouseDownNode: THtmlNode;
    FOnPaint: TNotifyEvent;
    FBodyNode: THtmlNode;
    function GetBodyNode: THtmlNode;
    function GetStyle: String;
    procedure SetStyle(AValue: String);
    procedure Relayout(AWidth, AHeight: Integer);
  protected
    procedure CalculatePreferredSize(var PreferredWidth,
      PreferredHeight: Integer; WithThemeSpace: Boolean); override;
    procedure Paint; override;
    procedure SetParent(NewParent: TWinControl); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer
      ); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
      override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseLeave; override;
    procedure MouseEnter; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Changed;
    procedure ChangeBounds(ALeft, ATop, AWidth, AHeight: integer;
      KeepBase: boolean); override;
    procedure DoSetBounds(ALeft, ATop, AWidth, AHeight: integer); override;
    function NodeMarginToScreen(ANode: THtmlNode): TRect;
    function NodeMarginToClient(ANode: THtmlNode): TRect;

  published
    property Align;
    property AutoSize;
    property Anchors;
    property Body: THtmlNode read GetBodyNode;
    property BorderSpacing;
    property Constraints;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property ParentShowHint;
    property OnChangeBounds;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDock;
    property OnEndDrag;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    property OnMouseWheel;
    property OnMouseWheelDown;
    property OnMouseWheelUp;
    property OnMouseWheelHorz;
    property OnMouseWheelLeft;
    property OnMouseWheelRight;
    property OnPaint: TNotifyEvent read FOnPaint write FOnPaint;
    property OnResize;
    property OnStartDock;
    property OnStartDrag;
    property ShowHint;
    property Style: String read GetStyle write SetStyle;
    property Visible;
  end;

  { TFaIcon }

 TFaIcon = class
  private
		FCachedBitmap: TBitmap;
    FCachedIcon: String;
    FCachedColor: TColor;
	public
		constructor Create;
		destructor Destroy; override;
		function Icon(AIcon: String; ASize: Integer; AColor: TColor): TBitmap;
    property Bitmap: TBitmap read FCachedBitmap;
	end;


  { THTMLFaNode }

  THTMLFaNode = class (THtmlNode)
  private
    FA: TFaIcon;
    FIconSize: Integer;
  protected
    procedure DrawNode(ACanvas: TCanvas; AClipRect: TRect); override;
    procedure CalculateSize(out AWidth, AHeight, ABaseLine: Integer); override;
  public
    Icon: String;
    constructor Create(AInlineStyle: String = '');override;
    destructor Destroy; override;
  end;

  function HTMLFa(AInlineStyle: String; AIcon: String = ''; AId: String = ''): THTMLFaNode;
  procedure Register;

implementation
{$R csspckg_lazarus.res}

var
  FAFont: TFreeTypeFont;


function HTMLFa(AInlineStyle: String; AIcon: String; AId: String): THTMLFaNode;
begin
  Result := THTMLFaNode.Create;
  Result.InlineStyle := AInlineStyle;
  Result.Id := AId;
  Result.Element := 'span';
  Result.Icon := Copy(AIcon, 1,4);
end;

procedure Register;
begin
	RegisterComponents('CSS',[ TCSSShape]);
end;

{ THTMLFaNode }

procedure THTMLFaNode.DrawNode(ACanvas: TCanvas; AClipRect: TRect);
begin
  inherited DrawNode(ACanvas, AClipRect);
  ACanvas.Draw(CompSize.ContentRect.Left + CompSize.Border.Left + CompSize.Padding.Left,
    CompSize.ContentRect.Top + CompSize.Border.Top + CompSize.Padding.Top,
    FA.Icon(Icon, FIconSize, CompStyle.Color.Value));
end;

procedure THTMLFaNode.CalculateSize(out AWidth, AHeight, ABaseLine: Integer);
begin
  Text := ' ';
  inherited CalculateSize(AWidth, AHeight, ABaseLine);
  Text := '';
  FIconSize := AHeight;
  AWidth := FIconSize;
  ABaseLine := Round( AHeight / 5);
//  ABaseLine :=  Round(FIconSize * 0.14);  // https://stackoverflow.com/questions/32781414/what-is-the-baseline-font-height-of-fontawesome-font
end;

constructor THTMLFaNode.Create(AInlineStyle: String);
begin
  inherited Create(AInlineStyle);
  FA := TFaIcon.Create;
end;

destructor THTMLFaNode.Destroy;
begin
  FA.Free;
  inherited Destroy;
end;

{ TFaIcon }

constructor TFaIcon.Create;
begin
	FCachedBitmap := TBitmap.Create;
  FCachedIcon := '';
  FCachedColor := clNone;
end;

destructor TFaIcon.Destroy;
begin
  FCachedBitmap.Free;
  inherited Destroy;
end;

function TFaIcon.Icon(AIcon: String; ASize: Integer; AColor: TColor): TBitmap;
var
	img: TLazIntfImage;
	d: TIntfFreeTypeDrawer;
begin
	Result := FCachedBitmap;
  if Length(AIcon) >= 4 then AIcon := UTF8Encode( WideChar(Hex2Dec( Copy(AIcon, 1, 4))));
  if (AIcon = FCachedIcon) and (FCachedColor = AColor) and (ASize = FCachedBitmap.Width) then Exit;
	FCachedIcon := AIcon;
	FCachedColor := AColor;
	img := TLazIntfImage.Create(0,0, [riqfRGB, riqfAlpha]);
	d := TIntfFreeTypeDrawer.Create(img);
	try
  	img.SetSize(ASize, ASize);
		d.FillPixels(colTransparent);
    if FAFont.Name <> '' then begin
		  FAFont.SizeInPixels := ASize-2;
		  FAFont.Hinted := True;
		  FAFont.ClearType := True;
		  FAFont.Quality := grqHighQuality;
		  FAFont.SmallLinePadding := False;
  		d.DrawText(FCachedIcon, FAFont, ASize div 2, 1, TColorToFPColor(FCachedColor), [ftaTop, {ftaLeft}ftaCenter]);
    end;
    FCachedBitmap.LoadFromIntfImage(img);
	finally
		d.Free;
		img.Free;
	end;
end;

{ TCSSShape }

function TCSSShape.GetBodyNode: THtmlNode;
begin
  Result := FBodyNode;
end;

function TCSSShape.GetStyle: String;
begin
  Result := Body.InlineStyle;
end;

procedure TCSSShape.SetStyle(AValue: String);
begin
  if Body.InlineStyle = AValue then Exit;
  Body.InlineStyle := AValue;
  Body.ApplyStyles;
  Changed;
end;

procedure TCSSShape.Relayout(AWidth, AHeight: Integer);
begin
  if (FCachedWidth <> AWidth) or (FCachedHeight <> AHeight) or (FIsChanged) then begin
//    Writeln(Format('ChangeBounds :%d, %d, %d, %d, - %s',  [ATop, ALeft, AWidth, AHeight, KeepBase.ToString]));
    Body.LayoutTo(0, 0, AWidth, AHeight);
    Body.AlignControlsTo(Left, Top);
  end;
  FCachedWidth := AWidth;
  FCachedHeight := AHeight;
  FIsChanged := False;
end;

procedure TCSSShape.Paint;
begin
{  if FIsChanged then begin
    FIsChanged := False;
  end;}
  Body.PaintTo(Self.Canvas);
  if Assigned(FOnPaint) then FOnPaint(Self);
end;

procedure TCSSShape.SetParent(NewParent: TWinControl);
begin
  inherited SetParent(NewParent);
  if Assigned(NewParent) then begin
    InvalidatePreferredSize;
    AdjustSize;
  end;
end;

procedure TCSSShape.MouseDown(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  FMouseDownNode := FBodyNode.NodeAtPosition( Point(X, Y));
end;

procedure TCSSShape.MouseUp(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
begin
  inherited MouseUp(Button, Shift, X, Y);
  if Assigned(FMouseDownNode) then begin
    if FMouseDownNode = FBodyNode.NodeAtPosition( Point(X, Y)) then begin
      if Assigned(FMouseDownNode.OnClick) then FMouseDownNode.OnClick(FMouseDownNode);
    end;
    FMouseDownNode := Nil;
  end;
end;

procedure TCSSShape.MouseMove(Shift: TShiftState; X, Y: Integer);
// TODO: move this part into Node handling to provide support for various controls
// TODO: check for changes after style applied to prevent redrawing
var
  Node: THtmlNode;
  Modified: Boolean;
  NewCursor: TCursor;
begin
  inherited MouseMove(Shift, X, Y);
  Node :=  GetBodyNode;
  Modified := False;
  NewCursor :=  crNone;
  while Assigned(Node) do begin
    if PtInRect(Node.CompSize.ContentRect, Point(X,Y)) then begin
      if Node.CompStyle.Cursor <> crDefault then NewCursor := Node.CompStyle.Cursor;
      if not Node.Hovered then begin
        Node.Hovered := True;
        Modified := True;
      end;
    end else begin
      if (Node.Hovered) then begin    // remove hovered styles -> rebuild styles
        Node.Hovered := False;
        Modified := True;
      end;
    end;
    Node := Node.GetNext(Node, True);
  end;
  if NewCursor <> crNone then Self.Cursor := NewCursor else Self.Cursor := crDefault;
  if Modified then begin
    Body.ApplyStyles;
    Changed;
  end;
end;

procedure TCSSShape.MouseLeave;
begin
  inherited MouseLeave;
  MouseMove([], -1, -1);
end;

procedure TCSSShape.MouseEnter;
var
  pt: TPoint;
begin
  inherited MouseEnter;
  pt := ScreenToControl(Mouse.CursorPos);
  MouseMove([], pt.x, pt.y);
end;

(*
  Calculate size based on autosize settings.
*)

procedure TCSSShape.CalculatePreferredSize(var PreferredWidth,
  PreferredHeight: Integer; WithThemeSpace: Boolean);
var
  AWidth, AHeight: Integer;
begin
  if (Parent = nil) or (not Parent.HandleAllocated) then Exit;
  if WidthIsAnchored then AWidth := Width else AWidth := -1;
  if (HeightIsAnchored and AutoSize) then AHeight := Height else AHeight := -1;
  FBodyNode.LayoutTo( 0, 0, AWidth, AHeight);
  if WidthIsAnchored then PreferredWidth := 0 else PreferredWidth := FBodyNode.CompSize.MarginRect.Width;
  if (HeightIsAnchored and AutoSize) then PreferredHeight := 0 else PreferredHeight := FBodyNode.CompSize.MarginRect.Height;
end;

constructor TCSSShape.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FBodyNode := THtmlNode.Create;
  FBodyNode.Id := 'body';
  FBodyNode.ParentControl := Self;
  FIsChanged := True;
  SetBounds(0,0, 150, 150);  // default size
end;

destructor TCSSShape.Destroy;
begin
  FBodyNode.Free;
  inherited Destroy;
end;

procedure TCSSShape.Changed;
begin
  FIsChanged := True;
  Relayout(Width, Height);

  InvalidatePreferredSize;
  AdjustSize;
  Invalidate;
end;

procedure TCSSShape.ChangeBounds(ALeft, ATop, AWidth, AHeight: integer;
  KeepBase: boolean);
begin
  inherited ChangeBounds(ALeft, ATop, AWidth, AHeight, KeepBase);
//  if AutoSize then AWidth :=  -1;
  Relayout(AWidth, AHeight);
end;

procedure TCSSShape.DoSetBounds(ALeft, ATop, AWidth, AHeight: integer);
// TODO: add align controls only when Left or Top Changed without invalidating preffered size
var
  LeftChanged, TopChanged,
  WidthChanged, HeightChanged: Boolean;
begin
  WidthChanged := AWidth <> Width;
  HeightChanged := AHeight <> Height;
  LeftChanged := ALeft <> Left;
  TopChanged := ATop <> Top;
  inherited DoSetBounds(ALeft, ATop, AWidth, AHeight);
  exit;
  if WidthChanged or HeightChanged { or LeftChanged or TopChanged} then begin // this is allways TRUE :)
//    FIsChanged := True;
    if AutoSize then begin
      InvalidatePreferredSize;
      AdjustSize;
//      FIsChanged := False;
    end;
  end;
end;

function TCSSShape.NodeMarginToScreen(ANode: THtmlNode): TRect;
var
  P: TPoint;
begin
  P := ClientToScreen(Point(ANode.CompSize.MarginRect.Left, ANode.CompSize.MarginRect.Top));
  Result := Rect(P.x, P.y, P.x + ANode.CompSize.MarginRect.Width, P.y + ANode.CompSize.MarginRect.Height);
end;

function TCSSShape.NodeMarginToClient(ANode: THtmlNode): TRect;
var
  P: TPoint;
begin
  P := ClientToParent(Point(ANode.CompSize.MarginRect.Left, ANode.CompSize.MarginRect.Top), TWinControl(Self.GetTopParent));
  Result := Rect(P.x, P.y, P.x + ANode.CompSize.MarginRect.Width, P.y + ANode.CompSize.MarginRect.Height);
end;

initialization
begin
	FAFont := TFreeTypeFont.Create;
  // TODO: this is not best way!
  if FileExists(Application.Location + 'data/fonts/fontawesome-webfont.ttf') then
    FAFont.Name :=  Application.Location + 'data/fonts/fontawesome-webfont.ttf';
end;

finalization
begin
	FAFont.Free;
end;

end.

