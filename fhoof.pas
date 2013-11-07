unit FHoof;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, sqldb, db, sqlite3conn, FileUtil, Forms, Controls,
  Graphics, Dialogs, DBGrids, DbCtrls, StdCtrls, EditBtn, ComCtrls;

type
  TBytes = array of Byte;
  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    edtDBver: TEdit;
    edtIncDir: TDirectoryEdit;
    DirectoryEdit2: TDirectoryEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    lblHoev: TLabel;
    prgB: TProgressBar;
    sqlIncrMDB: TSQLite3Connection;
    qryContainers: TSQLQuery;
    qryHeaders: TSQLQuery;
    qryCommonData: TSQLQuery;
    SQLTransaction1: TSQLTransaction;
    procedure Button1Click(Sender: TObject);
    procedure qryContainersContainerIDGetText(Sender: TField; var aText: string;
      DisplayText: Boolean);
  private
    { private declarations }
    baseDir : String;
    function createoutPutFile(dataText : String;filenumber : Integer):Boolean;
  public
    { public declarations }
  end; 

var
  Form1: TForm1; 

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.qryContainersContainerIDGetText(Sender: TField; var aText: string;
  DisplayText: Boolean);
begin
    aText := Sender.AsString;
    displaytext:= true;
end;

function TForm1.createoutPutFile(dataText: String; filenumber: Integer
  ): Boolean;
begin
  //s
end;

procedure TForm1.Button1Click(Sender: TObject);
var
    lastCID,CFilename,ActVFileN,eMailcontents : String;
    fS_In : TFileStream;
    counter,startPos,readL,beforeReadPos: Integer;
    Buffer: TBytes;
begin
  //conenct vget info
  baseDir := edtIncDir.text;

  if (baseDir[length(baseDir)] <> '\') then begin
      baseDir := baseDir + '\';
  end;

  sqlIncrMDB.DatabaseName := baseDir+'\Containers.db';
  sqlIncrMDB.Open;
  qryCommonData.open;
  edtDBver.Text := qryCommonData.fieldbyname('CommonValue').AsString;

  //get messages count
  qryHeaders.open;
  prgB.Max:= qryHeaders.RecordCount;
  lblHoev.Caption:= '0/'+inttostr(prgB.Max);

  //work with messages
  lastCID := '';
  CFilename := '';
  ActVFileN := '';
  counter :=1;
  fS_In := nil;
  while not qryHeaders.eof do begin
    if (lastCID <> qryHeaders.fieldbyname('ContainerID').AsString) then begin
        lastCID := qryHeaders.fieldbyname('ContainerID').AsString;
        qryContainers.close;
        qryContainers.Params.ParamByName('C_ID').AsString := lastCID;
        qryContainers.open;
        CFilename := qryContainers.fieldbyname('FileName').AsString;
        qryContainers.close;
    end;
    if (ActVFileN <> CFilename)  then begin
       ActVFileN := CFilename;
       counter := 1;
       if Assigned(fS_In) then begin
          fS_In.Destroy;
          fS_In := nil;
       end;
       fS_In := TFileStream.Create(baseDir+ActVFileN+'.imm',fmOpenRead);
    end;
     startPos := qryHeaders.FieldByName('MsgPos').AsInteger;
     readL := qryHeaders.FieldByName('LightMsgSize').AsInteger;
     beforeReadPos := fS_In.Position;
     if ((fS_In.Position = startPos) or (fS_In.Seek(startPos,soBeginning) = 0)) then begin
       eMailcontents := '';

       SetLength(Buffer, readL);
       fS_In.ReadBuffer(Pointer(Buffer)^, readL);
       SetString(eMailcontents, PAnsiChar(@Buffer[0]), Length(Buffer));

       //create output file
       createoutPutFile(eMailcontents,counter);
       SetLength(Buffer, 0);

       //set progress
       inc(counter);
       prgB.Position := prgB.Position+1;
       lblHoev.Caption:= inttostr(prgB.Position)+'/'+inttostr(prgB.Max);
       Application.ProcessMessages;
       sleep(50);
     end else begin
          counter := GetLastOSError;
         MessageDlg('Error reading input File : '+ActVFileN+', FileSize : '+inttostr(fs_In.Size)+', FilePos : '+inttostr(fs_In.Position)+', LastErrorcode : '+inttostr(counter)+', Before Read Pos : '+inttostr(beforeReadPos),mtError,[mbOk],0);
         break;
     end;
     qryHeaders.Next;

  end;



  //clean up
  qryCommonData.close;
  sqlIncrMDB.close;
end;

end.

