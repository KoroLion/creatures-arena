{$reference MSHP.Sockets.dll}
Unit LioElements;

Interface

  uses 
    GraphABC, MSHP.Sockets;
    
  type
    basicElement = class
      width: integer;
      height: integer;
      top: integer;
      left: integer;
      visible: boolean;
      focused: boolean;
      mouseIn: boolean;
      function MouseDownCheck(x, y: integer): boolean;
      procedure MouseMoveCheck(x, y: integer);
    end;
    form = class(basicElement)
      caption: string;
      fixed: boolean;
      constructor Create(fwidth, fheight: integer; fcaption: string; ffixed: boolean);
    end;
    lioButton = class(basicElement)
      caption: string;
      bColor: Color;
      constructor Create(fwidth, fheight, fleft, ftop: integer; fcaption: string);
      procedure MouseMoveCheck(x, y: integer);
      procedure Draw();
    end;
    lioLabel = class(basicElement)
      caption: String;
      bColor: Color;
      constructor Create(fleft, ftop: integer; fcaption: string);
      procedure Draw();
    end;
    lioEdit = class(basicElement)
      cols: integer;
      text: string;
      forPassword: boolean;
      constructor Create(fleft, ftop, fwidth, fheight: integer; ftext: string);
      procedure Draw();
    end;
    LioTCPClient = class
      serverIp: string;
      serverPort: integer;
      connected: boolean;
      constructor Create(ip: string; port: integer);
      function sendMessage(message: string): string;
      function Connect(id: integer; pass: integer): string;
      procedure Disconnect(id: integer);
    end;
    
Implementation

  constructor form.Create(fwidth, fheight: integer; fcaption: string; ffixed: boolean);
  begin
    width := fwidth;
    height := fheight;
    caption := fcaption;
    fixed := ffixed;
    SetWindowSize(width, height);
    SetWindowCaption(caption);
    SetWindowIsFixedSize(fixed);
    LockDrawing;
  end;
  
  procedure basicElement.MouseMoveCheck(x, y: integer);
  var
    topCheck, leftCheck: boolean;
  begin
    topCheck := (y > top) and (y <= top + height);
    leftCheck := (x > left) and (x <= left + width);
    if (topCheck and leftCheck) then
      mouseIn := true
    else if ((not topCheck or not leftCheck)) then
    begin
      mouseIn := false;
      focused := false;
    end;
  end;
  function basicElement.MouseDownCheck(x, y: integer): boolean;
  begin
    if ((mouseIn) and (Visible)) then
      result := true
    else
      result := false;
  end;
  
  constructor lioButton.Create(fwidth, fheight, fleft, ftop: integer; fcaption: string);
  begin
    width := fwidth;
    height := fheight;
    top := ftop;
    left := fleft;
    caption := fcaption;
    visible := true;
  end;
  procedure lioButton.Draw();
  begin
    if (visible) then
    begin
      if (mouseIn) then
        SetBrushColor(clOrange)
      else
        SetBrushColor(bColor);
      SetPenColor(clBlack);
      SetPenWidth(1);
      rectangle(left, top, left + width, top + height);
      TextOut(left + width div 2 - length(caption) * 4, top + height div 2 - 8, caption);
    end;
  end;
  procedure lioButton.MouseMoveCheck(x, y: integer);
  var
    topCheck, leftCheck: boolean;
  begin
    topCheck := (y > top) and (y <= top + height);
    leftCheck := (x > left) and (x <= left + width);
    if (topCheck and leftCheck and (bColor <> clOrange)) then
    begin
      bColor := clOrange;
      mouseIn := true;
    end
    else if ((not topCheck or not leftCheck) and (bColor <> clWhite)) then
    begin
      bColor := clWhite; 
      mouseIn := false;
    end;
  end;
  
  constructor lioLabel.Create(fleft, ftop: integer; fcaption: string);
  begin
    left := fleft;
    top := ftop;
    caption := fcaption;
    visible := true;
  end;
  procedure lioLabel.Draw();
  begin
    if (visible) then
    begin
      SetBrushColor(bColor);
      TextOut(left, top, caption);
    end;
  end;
  
  constructor lioEdit.Create(fleft, ftop, fwidth, fheight: integer; ftext: string);
  begin
    left := fleft;
    top := ftop;
    width := fwidth;
    height := fheight;
    text := ftext;
    visible := true;
    forPassword := false;
  end;
  procedure lioEdit.Draw();
  begin
    if (visible) then
    begin
      if (focused) then
      begin
        SetPenColor(clGreen);
        SetPenWidth(2);
      end
      else 
      begin
        SetPenColor(clBlack);
        SetPenWidth(1);
      end;
      SetBrushColor(clWhite);
      Rectangle(left, top, left + width, top + height);
      var toShow := '';
      if (not forPassword) then 
        toShow := text
      else
      begin
        for var i := 1 to length(text) do
          toShow += '*';
      end;
      Textout(left + 3, top + height div 2 - 8, toShow);
    end;
  end;
  
  constructor LioTCPClient.Create(ip: string; port: integer);
  begin
    serverIp := ip;
    serverPort := port;
    connected := false;
  end;
  function LioTCPClient.sendMessage(message: string): string;
  var
    client: System.Net.Sockets.Socket;
    ClientDataToSend: array of byte;
    data: array of byte;
  begin
    client := Socket.CreateTCPClientSocket(Socket.GetIPByHostname(serverIp), serverPort);
    SetLength(ClientDataToSend, Length(message));
    for var i := 0 to Length(message) - 1 do
      ClientDataToSend[i] := ord(message[i + 1]);
    Socket.TCPSocketSend(client, ClientDataToSend);  
    data := Socket.TCPSocketSyncReceive(client, 128);
    Socket.TCPSocketClose(client, System.Net.Sockets.SocketShutdown.Both);
    try
      result := Encoding.ASCII.GetString(data);
    except
      result := '';
    end;
  end;
  function LioTCPClient.Connect(id: integer; pass: integer): string;
  var
    ans: string;
  begin
    if (not connected) then
      ans := sendMessage(id + ';5;' + pass + ';');
    
    connected := (ans = 'OK');
      
    result := ans;
  end;
  procedure LioTCPClient.Disconnect(id: integer);
  begin
    sendMessage(id + ';6;');
    connected := false;
  end;
  
end.