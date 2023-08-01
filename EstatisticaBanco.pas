unit EstatisticaBanco;

interface

uses
  Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, FireDAC.Stan.Intf,
  FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf,
  FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys,
  FireDAC.Phys.FB, FireDAC.Phys.FBDef, FireDAC.VCLUI.Wait, FireDAC.Stan.Param,
  FireDAC.DatS, FireDAC.DApt.Intf, FireDAC.DApt, Data.DB, FireDAC.Comp.DataSet,
  FireDAC.Comp.Client, FireDAC.Phys.IBBase, VclTee.TeeGDIPlus, VCLTee.TeEngine,
  Vcl.ExtCtrls, VCLTee.TeeProcs, VCLTee.Chart, VCLTee.Series, VCLTee.TeeFunci,ShellAPI,
  Vcl.ComCtrls;

type
  TForm14 = class(TForm)
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    Label14: TLabel;
    Label15: TLabel;
    Label16: TLabel;
    Label17: TLabel;
    Label18: TLabel;
    edtVersaoFB: TEdit;
    edtTamPagina: TEdit;
    edtIntervaloSWeep: TEdit;
    edtVersaoODS: TEdit;
    edtBuffers: TEdit;
    edtModoShutdown: TEdit;
    edtDialeto: TEdit;
    GroupBox1: TGroupBox;
    Label8: TLabel;
    Label9: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    edtOldest: TEdit;
    edtOldestActive: TEdit;
    edtOldestSnapshot: TEdit;
    edtNext: TEdit;
    edtModLeitura: TEdit;
    edtForcedWrithe: TEdit;
    edtReservaEspaco: TEdit;
    edtReservaExternas: TEdit;
    edtID: TEdit;
    edtStatusNBackup: TEdit;
    edtUltimoRestore: TEdit;
    FDConnection1: TFDConnection;
    Qry: TFDQuery;
    FDPhysFBDriverLink1: TFDPhysFBDriverLink;
    Chart1: TChart;
    Series2: THorizBarSeries;
    Series1: TBarSeries;
    Button1: TButton;
    mo: TMemo;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    TabSheet3: TTabSheet;
    Button5: TButton;
    mc: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
  private
    function RunCaptured(const _dirName, _exeName, _cmdLine: string): Boolean;
    procedure GetDosOutput(pCommandLine: string; pMemo: TMemo);
  public
    { Public declarations }
  end;

var
  Form14: TForm14;

implementation

uses
  Winapi.Windows;

{$R *.dfm}

procedure TForm14.Button1Click(Sender: TObject);
var
  TableList: TStringList;
  I: Integer;
begin
  try
    mo.Lines.Clear;
    FDConnection1.Connected := True;
    TableList := TStringList.Create;
    try
      // Obter a lista de tabelas do banco de dados
      Qry.SQL.Text :=
      'SELECT RDB$INDEX_NAME ' +
      'FROM RDB$INDICES ' +
      'WHERE RDB$INDEX_NAME IS NOT NULL ' +
      'ORDER BY RDB$INDEX_NAME;';
       Qry.Open;

       Qry.First;
      while not Qry.Eof do
      begin
        TableList.Add( qry.FieldByName('RDB$INDEX_NAME').AsString );

        Qry.Next;
      end;
      Qry.Close;

      // Recalcular os índices para cada tabela
      for I := 0 to TableList.Count - 1 do
      begin
        Qry.SQL.Text := 'set statistics index ' + TableList[I];
        Qry.ExecSQL;
        mo.Lines.Add('atualizando index: ' + TableList[i]);
      end;
    finally
      mo.Lines.Add(TableList.Count.ToString + ' index recalculados');
      TableList.Free;
    end;
  finally
    FDConnection1.Connected := False;
  end;
end;

procedure TForm14.GetDosOutput(pCommandLine: string; pMemo: TMemo);
var
  SA: TSecurityAttributes;
  SI: TStartupInfo;
  PI: TProcessInformation;
  StdOutPipeRead, StdOutPipeWrite: THandle;
  WasOK: Boolean;
  Buffer: array[0..255] of AnsiChar;
  BytesRead: Cardinal;
  Handle: Boolean;
  WorkDir : String;
begin
  WorkDir := 'C:\temp\';
  SA.nLength              := SizeOf(SA);
  SA.bInheritHandle       := True;
  SA.lpSecurityDescriptor := nil;
  CreatePipe(StdOutPipeRead, StdOutPipeWrite, @SA, 0);
  try
    FillChar(SI, SizeOf(SI), 0);
    SI.cb          := SizeOf(TStartupInfo);
    SI.dwFlags     := STARTF_USESHOWWINDOW or STARTF_USESTDHANDLES;
    SI.wShowWindow := SW_HIDE;
    SI.hStdInput   := StdOutPipeRead;
    SI.hStdOutput  := StdOutPipeWrite;
    SI.hStdError   := StdOutPipeWrite;
    FillChar(PI, SizeOf(PI), 0);

    Handle := CreateProcessW(PChar(nil), PChar('cmd.exe /c ' + pCommandLine), nil, nil, True, NORMAL_PRIORITY_CLASS, nil, PChar(WorkDir), SI, PI);

    CloseHandle(StdOutPipeWrite);
    if Handle then
      try
        repeat
          Application.ProcessMessages;
          WasOK := ReadFile(StdOutPipeRead, Buffer, 255, BytesRead, nil);
          if BytesRead > 0 then
          begin
            Buffer[BytesRead] := #0;
            pMemo.Text        := pMemo.Text + String(Buffer);
            pMemo.Perform(EM_LINESCROLL,0,pMemo.Lines.Count);
            Application.ProcessMessages;
          end;
        until not WasOK or (BytesRead = 0);
        WaitForSingleObject(PI.hProcess, INFINITE);
      finally
        CloseHandle(PI.hThread);
        CloseHandle(PI.hProcess);
      end;
  finally
    CloseHandle(StdOutPipeRead);
  end;
end;

function TForm14.RunCaptured(const _dirName, _exeName, _cmdLine: string): Boolean;
var
  start: TStartupInfo;
  procInfo: TProcessInformation;
  tmpName: string;
  tmp: THandle;
  tmpSec: TSecurityAttributes;
  res: TStringList;
  return: Cardinal;
begin
  Result := False;
  try
    // set a temporary file
    tmpName := 'Test.tmp';
    FillChar(tmpSec, SizeOf(tmpSec), #0);
    tmpSec.nLength := SizeOf(tmpSec);
    tmpSec.bInheritHandle := True;
    tmp := CreateFile(PChar(tmpName),
           Generic_Write, File_Share_Write,
           @tmpSec, Create_Always, File_Attribute_Normal, 0);
    try
      FillChar(start, SizeOf(start), #0);
      start.cb          := SizeOf(start);
      start.hStdOutput  := tmp;
      start.dwFlags     := StartF_UseStdHandles or StartF_UseShowWindow;
      start.wShowWindow := SW_Minimize;
      // Start the program
      if CreateProcess(nil, PChar(_exeName + ' ' + _cmdLine), nil, nil, True,
                       0, nil, PChar(_dirName), start, procInfo) then
      begin
        SetPriorityClass(procInfo.hProcess, Idle_Priority_Class);
        WaitForSingleObject(procInfo.hProcess, Infinite);
        GetExitCodeProcess(procInfo.hProcess, return);
        Result := (return = 0);
        CloseHandle(procInfo.hThread);
        CloseHandle(procInfo.hProcess);
        CloseHandle(tmp);
        // Add the output
        res := TStringList.Create;
        try
          res.LoadFromFile(tmpName);
          mo.Lines.AddStrings(res);
        finally
          res.Free;
        end;
        DeleteFile(PChar(tmpName));
      end
      else
        Application.MessageBox(PChar(SysErrorMessage(GetLastError())), 'RunCaptured Error', MB_OK);
    except
      CloseHandle(tmp);
      DeleteFile(PChar(tmpName));
      raise;
    end;
  finally

  end;
end;

procedure TForm14.Button2Click(Sender: TObject);
var
Resp : String;
begin
  Resp := InputBox('Informe o numero a ser coletado: ' , 'Informe o numero a ser coletado: ', '1000' );

  mo.Lines.Clear;
  if RunCaptured('C:\Program Files\Firebird\Firebird_2_1\bin\', 'C:\Program Files\Firebird\Firebird_2_1\bin\gfix.exe', '-h '+ Resp +' ' + FDConnection1.Params.Values['Database'] + ' -user ' + FDConnection1.Params.Values['User_Name'] + ' -pa ' + FDConnection1.Params.Values['Password'] + '') then
   mo.Lines.Add('Coleta de Lixo ajustada para - ' + Resp)
   else
   mo.Lines.Add('não foi possível ajustar a coleta de lixo');
end;

procedure TForm14.Button3Click(Sender: TObject);
begin
  mo.Lines.Clear;
  if RunCaptured('C:\Program Files\Firebird\Firebird_2_1\bin\', 'C:\Program Files\Firebird\Firebird_2_1\bin\gfix.exe', '-h 0 ' + FDConnection1.Params.Values['Database'] + ' -user ' + FDConnection1.Params.Values['User_Name'] + ' -pa ' + FDConnection1.Params.Values['Password'] + '') then
   mo.Lines.Add('Coleta de Lixo desativada com sucesso')
   else
   mo.Lines.Add('não foi possível desativar a coleta de lixo');
end;

procedure TForm14.Button4Click(Sender: TObject);
begin
   mo.Lines.Clear;
   if RunCaptured('C:\Program Files\Firebird\Firebird_2_1\bin\', 'C:\Program Files\Firebird\Firebird_2_1\bin\gfix.exe', '-sw ' + FDConnection1.Params.Values['Database'] + ' -user ' + FDConnection1.Params.Values['User_Name'] + ' -pa ' + FDConnection1.Params.Values['Password'] + '') then
   mo.Lines.Add('Lixo coletado com sucesso')
   else
   mo.Lines.Add('não foi possível coletar o lixo');

   //GetDosOutput('"C:\Program Files\Firebird\Firebird_2_1\bin\gfix.exe -sw c:\supersys10\dados\supersys.fdb -user SYSDBA -pa masterkey"', mo);

end;

procedure TForm14.Button5Click(Sender: TObject);
var
i : integer;
ColName, ColValue : string;
begin
      mc.Lines.Clear;

      Qry.SQL.Text :=
      ' SELECT * ' +
      ' FROM MON$ATTACHMENTS M ' +
      ' WHERE NOT EXISTS (SELECT MA.MON$REMOTE_PROCESS, MA.MON$REMOTE_ADDRESS FROM MON$ATTACHMENTS MA ' +
      ' WHERE MA.MON$REMOTE_PROCESS = M.MON$REMOTE_PROCESS AND MA.MON$REMOTE_ADDRESS = M.MON$REMOTE_ADDRESS ' +
      ' AND MA.MON$ATTACHMENT_ID = CURRENT_CONNECTION) ' +
      ' AND M.MON$USER <> ''SWEEPER'' ' ;

      Qry.Open;
      while not Qry.Eof do
      begin
            for I := 0 to Qry.FieldCount - 1 do
            begin
              ColName  := Qry.Fields[I].FieldName;
              ColValue := Qry.Fields[I].AsString;

              if ColName = 'MON$ATTACHMENT_ID' then
                mc.Lines.Add('=================================================');

              mc.Lines.Add(ColName + ' = ' + ColValue);
            end;

            Qry.Next;
      end;
      if qry.RecordCount = 0 then
       mc.Lines.Add('NÃO EXISTEM CONEXÕES ATIVAS');
      Qry.Close;

      mc.Lines.Add('=================================================');
end;

procedure TForm14.FormCreate(Sender: TObject);
begin
     Qry.SQL.Text :=
     ' SELECT ' +
     ' MON$DATABASE_NAME        AS BANCO_DADOS, ' +
     ' MON$PAGE_SIZE            AS TAMANHO_PAGINA, ' +
     ' (SELECT RDB$GET_CONTEXT(''SYSTEM'', ''ENGINE_VERSION'') FROM RDB$DATABASE) AS VERSAO_FIREBIRD, ' +
     ' MON$ODS_MAJOR || ''.'' || MON$ODS_MINOR AS VERSAO_ODS, ' +
     ' MON$OLDEST_TRANSACTION   AS OLDEST_TRANSACTION, ' +
     ' MON$OLDEST_ACTIVE        AS OLDEST_ACTIVE, ' +
     ' MON$OLDEST_SNAPSHOT      AS OLD_SNAPSHOT, ' +
     ' MON$NEXT_TRANSACTION     AS NEXT_TRANSACTION, ' +
     ' MON$PAGE_BUFFERS         AS BUFFERS, ' +
     ' MON$SQL_DIALECT          AS DIALETO, ' +
     ' CASE MON$SHUTDOWN_MODE ' +
     ' WHEN 0 THEN ''DATABASE ONLINE'' ' +
     ' WHEN 1 THEN ''MULTI USUÁRIOS'' ' +
     ' WHEN 2 THEN ''USUÁRIO ÚNICO'' ' +
     ' WHEN 3 THEN ''FULL'' ' +
     ' ELSE ''DESCONHECIDO'' ' +
     ' END AS MODO_SHUTDOWN, ' +
     ' MON$SWEEP_INTERVAL AS INTERVALO_SWEEP, ' +
     ' CASE MON$READ_ONLY ' +
     ' WHEN 0 THEN ''READ-WRITE'' ' +
     ' WHEN 1 THEN ''READ ONLY'' ' +
     ' ELSE ''DESCONHECIDO'' ' +
     ' END AS MODO_LEITURA, ' +
     ' CASE MON$FORCED_WRITES ' +
     ' WHEN 0 THEN ''OFF'' ' +
     ' WHEN 1 THEN ''ON'' ' +
     ' ELSE ''DESCONHECIDO'' ' +
     ' END AS FORCED_WRITES, ' +
     ' CASE MON$RESERVE_SPACE ' +
     ' WHEN 0 THEN ''ALL_SPACE'' ' +
     ' WHEN 1 THEN ''RESERVE_SPACE'' ' +
     ' ELSE ''DESCONHECIDO'' ' +
     ' END AS RESERVA_ESPACO, ' +
     ' MON$CREATION_DATE AS ULTIMO_RESTORE, ' +
     ' MON$PAGES AS PAGINAS_DISPOSITIVOS_EXTERNOS, ' +
     ' MON$STAT_ID AS ID_ESTATISTICA, ' +
     ' CASE MON$BACKUP_STATE ' +
     ' WHEN 0 THEN ''NORMAL'' ' +
     ' WHEN 1 THEN ''STALLED'' ' +
     ' WHEN 2 THEN ''MERGE'' ' +
     ' ELSE ''DESCONHECIDO'' ' +
     ' END AS STATUS_NBACKUP ' +
     ' FROM ' +
     ' MON$DATABASE ';

     Qry.Open;
     edtVersaoFB.Text            := Qry.FieldByName('VERSAO_FIREBIRD').AsString;
     edtDialeto.Text             := Qry.FieldByName('DIALETO').AsString;
     edtVersaoODS.Text           := Qry.FieldByName('VERSAO_ODS').AsString;
     edtTamPagina.Text           := Qry.FieldByName('TAMANHO_PAGINA').AsString;
     edtIntervaloSWeep.Text      := FloatToStr( Qry.FieldByName('OLDEST_ACTIVE').AsFloat - Qry.FieldByName('OLDEST_TRANSACTION').AsFloat );
     edtBuffers.Text             := Qry.FieldByName('BUFFERS').AsString;
     edtModoShutdown.Text        := Qry.FieldByName('MODO_SHUTDOWN').AsString;
     edtOldest.Text              := Qry.FieldByName('OLDEST_TRANSACTION').AsString;
     edtOldestActive.Text        := Qry.FieldByName('OLDEST_ACTIVE').AsString;
     edtOldestSnapshot.Text      := Qry.FieldByName('OLD_SNAPSHOT').AsString;
     edtNext.Text                := Qry.FieldByName('NEXT_TRANSACTION').AsString;
     edtModLeitura.Text          := Qry.FieldByName('MODO_LEITURA').AsString;
     edtForcedWrithe.Text        := Qry.FieldByName('FORCED_WRITES').AsString;
     edtReservaEspaco.Text       := Qry.FieldByName('RESERVA_ESPACO').AsString;
     edtReservaExternas.Text     := Qry.FieldByName('PAGINAS_DISPOSITIVOS_EXTERNOS').AsString;
     edtID.Text                  := Qry.FieldByName('ID_ESTATISTICA').AsString;
     edtStatusNBackup.Text       := Qry.FieldByName('STATUS_NBACKUP').AsString;
     edtUltimoRestore.Text       := Qry.FieldByName('ULTIMO_RESTORE').AsString;

     Qry.Close;

     Chart1.Series[0].Clear;
     Chart1.Series[0].Add( StrToFloat( edtOldest.Text ), 'Oldest');
     Chart1.Series[0].Add( StrToFloat( edtOldestActive.Text ), 'Oldest Active');
     Chart1.Series[0].Add( StrToFloat( edtOldestSnapshot.Text ), 'Oldest Snapshot');
     Chart1.Series[0].Add( StrToFloat( edtNext.Text ), 'Next');

end;

end.
