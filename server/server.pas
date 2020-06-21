{$reference MSHP.Sockets.dll}

uses 
  MSHP.Sockets, Timers, Events;

const 
  ClientDataToSend : array of byte = (1, 2, 3, 4);
  SERVER_IP = '127.0.0.1';
  SERVER_PORT = 3127;
  WIDTH = 1000;
  HEIGHT = 800;
  
type
  basicItem = class
    x: integer;
    y: integer;
  end;
  player = class(basicItem)
    //id: integer;
    nick: string;
    password: integer;
    visible: boolean;
    color: integer;
    vx: integer;
    vy: integer;
    score: integer;
    defeat: boolean;
    connected: boolean;
    constructor Create(fnick: string; fpas, fx, fy: integer);
    function getRadius(): integer;
    begin
      result := score + 10;
    end;
    function getData(): string;
    begin
      if (connected) then
        result := inttostr(x) + ';' + inttostr(y) + ';' + inttostr(getRadius()) + ';'
      else
        result := '-10;-10;0;';
    end;
    procedure respawn();
  end;
  food = class(basicItem)
    radius: integer;
    constructor Create(frad: integer);
    function getData(): string;
    procedure respawn();
  end;
  
var
  server: System.Net.Sockets.Socket;
  handler: System.Net.Sockets.Socket;
  players: array[1..4] of player;
  foods: array[1..4] of food;
  a: array of integer;
  counter: timer;
  playersCount, id, act, pas: integer;
  
constructor player.Create(fnick: string; fpas, fx, fy: integer);
begin
  nick := fnick;
  password := fpas;
  x := fx;
  y := fy;
  vy := 0;
  vx := 0;
  score := 0;
  defeat := false;
  connected := false;
end; 
procedure player.respawn();
begin
  x := random(1000 - 40 - getRadius() * 2) + 20 + getRadius();
  y := random(800 - 40 - getRadius() * 2) + 20 + getRadius();
  vy := 0;
  vx := 0;
  score := 0;
end;

constructor food.Create(frad: integer);
begin
  radius := frad;
  respawn();
end;
function food.getData(): string;
begin
  result := inttostr(x) + ';' + inttostr(y) + ';';
end;
procedure food.respawn();
begin
  x := random(1000 - 40 - radius * 2) + 20 + radius;
  y := random(800 - 40 - radius * 2) + 20 + radius;
end;

function getIntArr(s: string): array of integer;
var
  a: array of integer;
  temp: string;
  i, j: integer;
begin
  SetLength(a, 502);
  i := 1; j := 1; temp := '';
  while (j < length(s)) do
  begin
    while (s[j] <> ';') do
    begin
      temp += s[j];
      j += 1;
    end;
    j += 1;
    try
      a[i] := strtoint(temp);
    except
      a[i] := 0;
    end;
    i += 1;
    temp := '';
  end;
  
  result := a;
end;

function getStringArr(s: string): array of string;
var
  a: array of string;
  temp: string;
  i, j: integer;
begin
  SetLength(a, 502);
  i := 1; j := 1; temp := '';
  while (j < length(s)) do
  begin
    while (s[j] <> ';') do
    begin
      temp += s[j];
      j += 1;
    end;
    j += 1;
    a[i] := temp;
    i += 1;
    temp := '';
  end;
  
  result := a;
end;

function radius(x1, y1, x2, y2: integer): real;
begin 
  result := Sqrt(Sqr(x2 - x1) + Sqr(y2 - y1)); 
end;
  
function getMessage(): string;
var
  mes: string;
  d: byte;
  serverData : array of byte;
begin
  serverData := Socket.TCPSocketSyncReceive(handler, 128);
   
  mes := '';
  foreach d in serverData do
    mes += chr(d);
  result := mes;
end;

procedure sendAnswer(mes: string);
begin
  Socket.TCPSocketSend(handler, Encoding.ASCII.GetBytes(mes));
end;

Procedure Count;
var
  tvx, tvy: integer;
begin
  for var i := 1 to 4 do
  begin
    
    if (not players[i].defeat) then
    begin
      players[i].x += players[i].vx; players[i].y += players[i].vy;
      var tL := 8 + random(2);
      players[i].defeat := (players[i].x < tL + players[i].getRadius()) or
                           (players[i].x > WIDTH - tL - players[i].getRadius()) or 
                           (players[i].y < tL + players[i].getRadius()) or 
                           (players[i].y > HEIGHT - tL - players[i].getRadius());
                           
      for var j := 1 to 3 do
        if (radius(players[i].x, players[i].y, foods[j].x, foods[j].y) < players[i].getRadius()) then
        begin
          players[i].score += 1;
          foods[j].respawn();
        end;
     for var j := 1 to 4 do
      if ((i <> j) and
          (radius(players[i].x, players[i].y, players[j].x, players[j].y) < players[i].getRadius() + players[j].getRadius()) and
          players[j].connected and players[i].connected) then
      begin
        tvx := players[j].vx;
        tvy := players[j].vy;
        players[j].vx := players[i].vx;
        players[j].vy := players[i].vy;
        players[i].vx := tvx;
        players[i].vy := tvy;
      end;
    end
  end;
end;
  
begin
  Randomize;
  playersCount := 0;
  
  players[1] := player.Create('Nyasha', 2591, random(width - 50) + 50, random(height - 50) + 50);
  players[2] := player.Create('Mouse', 3491, random(width - 50) + 50, random(height - 50) + 50);
  players[3] := player.Create('KoroLion', 9217, random(width - 50) + 50, random(height - 50) + 50);
  players[4] := player.Create('TestUser', 1234, random(width - 50) + 50, random(height - 50) + 50);
  
  for var i := 1 to 4 do
    foods[i] := food.Create(8);
  
  write('#INFO Initialising main thread... ');
  counter := new Timer(15, count);
  counter.Start;
  writeln('Success!');
  
  write('#INFO Starting up TCP server... ');
  server := Socket.CreateTCPServerSocket(Socket.GetIPByHostname(SERVER_IP), SERVER_PORT);
  Socket.TCPServerSocketListen(server, 1);
  writeln('Success!');
  
  writeln('#INFO OK, server is now online.');
  while (true) do begin
    handler := Socket.TCPServerSocketSyncAccept(server);
    try
      a := getIntArr(getMessage());
    except
      writeln('#ERROR An error occured while receiving package from (', handler.RemoteEndPoint.ToString, ')!');
      writeln('#WARNING The server is going to stop!');
      break;
    end;
    id := a[1];
    act := a[2];
    pas := a[3];
    if ((id >= 1) and (id <= 4)) then
    begin
      if ((act <> 5) and (players[id].defeat)) then
      begin
        sendAnswer('-1;');
        players[id].respawn();
        players[id].defeat := false;
      end
      else
        case (act) of
          1: //INCVX
            inc(players[id].vx);
          2: //DECVX
            dec(players[id].vx);
          3: //INCVY
            inc(players[id].vy);
          4: //DECVY
            dec(players[id].vy);
          0: //GETDATA'
            sendAnswer('3;' + foods[1].getData() + foods[2].getData() + foods[3].getData() + '4;' 
                            + players[1].getData() + players[2].getData() + players[3].getData() + players[4].getData());
          5: //CONNECT
          begin
            write('#INFO Player (', handler.RemoteEndPoint.ToString, ') authorising... ');
            if (pas = players[id].password) then
            begin
              if (not players[id].connected) then
              begin
                sendAnswer('OK');
                writeln('Success!');
                inc(playersCount);
                players[id].connected := true;
                case (id) of
                  1: players[id].nick := 'Nyasha';
                  2: players[id].nick := 'Mouse';
                  3: players[id].nick := 'KoroLion';
                  4: players[id].nick := 'TestUser';
                end;
                writeln('#INFO ', players[id].nick, ' (', handler.RemoteEndPoint.ToString, ') connected.');
                writeln('#INFO Players (', playersCount , '/4)');
              end
              else
              begin
                writeln('ERROR (Already connected)!');
                sendAnswer('ALRCON');
              end;
            end
            else
            begin
              writeln('ERROR (Auth failed)!');
              sendAnswer('AUTHFAIL');
            end;
          end;
          6: //DISCONNECT
          begin
            dec(playersCount);
            writeln('#INFO ', players[id].nick, ' (', handler.RemoteEndPoint.ToString, ') disconnected. Players (', playersCount , '/4)');
            writeln('#INFO Players (', playersCount , '/4)');
            players[id].connected := false;
            players[id].respawn();
          end;
        end;
      Socket.TCPSocketClose(handler, System.Net.Sockets.SocketShutdown.Both);
    end
    else
    begin
      writeln('#WARNING Unknown player trying to connect (', handler.RemoteEndPoint.ToString, ')!');
      sendAnswer('AUTHFAIL');
    end;
  end;
  writeln('#INFO Server is now offline!');
end.