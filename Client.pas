uses
  GraphABC, Timers, Events, LioElements;
  
const 
  IP = '127.0.0.1';
  PORT = 3127;
  VERSION = 'Beta 0.2';
  REFRESH_DELAY = 30;
  
var
  graph: timer;
  MainForm: form;
  SGButton: lioButton;
  LabelServiceInfo, LabelInfo, LabelNick, LabelPassword, LabelScore, LabelGameInfo, LabelMessage: liolabel;
  EditNick, EditPassword: lioEdit;
  Edits: array[1..100] of lioEdit;
  Client: LioTCPClient;
  serverData: string;
  inGame: boolean;
  a: array of integer;
  id: shortint;

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

Procedure InterfaceHidden(state: boolean);
begin
  state := not state;
  SGButton.Visible := state;
  LabelNick.Visible := state;
  EditNick.Visible := state;
  LabelPassword.visible := state;
  EditPassword.visible := state;
  LabelInfo.visible := state;
  LabelMessage.visible := state;
  LabelScore.visible := not state;
  LabelGameInfo.visible := not state;
end;

procedure Connect();
var
  ans: string;
begin
  case (EditNick.text) of
    'Nyasha': id := 1;
    'Mouse': id := 2;
    'KoroLion': id := 3;
    'TestUser': id := 4;
    else id := 0;
  end;
  if (id = 0) then
    LabelMessage.caption := 'Игрока не существует!'
  else 
  begin
    try
      ans := Client.connect(id, strtoint(EditPassword.text));
      if (ans = 'OK') then
      begin
        LabelGameInfo.Caption := 'Подключён к ' + Client.serverIp + ':' + inttostr(Client.serverPort) + '. Для отключения нажмите ESC.';
        InterfaceHidden(true);
        inGame := true;
      end
      else
        case (ans) of
          'ALRCON': LabelMessage.caption := 'Уже подключён!';
          'AUTHFAIL': LabelMessage.caption := 'Ошибка авторизации';
          else
            LabelMessage.Caption := 'Ошибка подключения!';
        end;
    except
      LabelMessage.caption := 'Пароль некорректный';
    end;
  end;
end;
procedure Disconnect(defeat: boolean);
begin
  if (defeat) then
    LabelMessage.caption := 'Бактерия погибла!'
  else
    LabelMessage.caption := '';
  Client.disconnect(ID);
  inGame := false;
  InterfaceHidden(false);
end;

procedure EditsMouseMoveCheck(x, y: integer);
begin
  var i := 1;
  while (true) do
  begin
    try
      Edits[i].MouseMoveCheck(x, y);
      inc(i);
    except
      break;
    end;
  end;
end;

//События
Procedure MouseMove(x, y, mb: integer);
begin
  SGButton.MouseMoveCheck(x, y);
  EditsMouseMoveCheck(x, y);
end;

procedure SGButtonAction();
begin
  Connect();
end;

Procedure MouseDown(x, y, mb: integer);
begin
  if (SGButton.MouseDownCheck(x, y)) then SGButtonAction();
  
  var i := 1; var stop := false;
  while (not stop) do
  begin
    try
      if (Edits[i].MouseDownCheck(x, y)) then Edits[i].focused := true;
      inc(i);
    except
      exit;
    end;
  end;
end;

Procedure DrawBall(x, y, r: integer; cl: color);
begin
  brush.Color := cl;
  Ellipse(x - r, y - r, x + r, y + r);
end;

procedure KeyDown(Key: integer);
begin
  if (inGame) then
    case Key of
      VK_Right:
        Client.sendMessage(ID + ';1;');
      VK_Left:
        Client.sendMessage(ID + ';2;');
      VK_Down:
        Client.sendMessage(ID + ';3;');
      VK_UP:
        Client.sendMessage(ID + ';4;');
      27:
        if (Client.connected) then
          Disconnect(false);
    end;
end;

procedure KeyPress(ch: char);
begin
  if (not inGame) then
  begin
    var i := 1; var focus := false;
    while (not focus) do
    begin
      try
        focus := Edits[i].focused;
        inc(i);
      except
        break;
      end;
    end;
    dec(i);
    if (focus) then
      case (ord(ch)) of
        8: delete(Edits[i].text, length(Edits[i].text), 1);
        13:;
        27: Edits[i].focused := false;
        else Edits[i].text += ch;
      end;
  end;
end;

procedure drawThorns();
begin
  SetPenWidth(3);
  var i := 0;
  var c := true;
  MoveTo(0, 0);
  while (i < MainForm.width) do
  begin
    if (c) then
      LineTo(i, -5)
    else
      LineTo(i, 10);
    i += 10;
    c := not c;
  end;
  i := 0;
  while(i < MainForm.height) do
  begin
    if (c) then
      LineTo(MainForm.width + 5, i)
    else
      LineTo(MainForm.width - 10, i);
    i += 10;
    c := not c;
  end;
  MoveTo(0, 0);
  i := 0;
  while(i < MainForm.height) do
  begin
    if (c) then
      LineTo(10, i)
    else
      LineTo(-5, i);
    i += 10;
    c := not c;
  end;
  i := 0;
  while (i < MainForm.width) do
  begin
    if (c) then
      LineTo(i, MainForm.height + 5)
    else
      LineTo(i, MainForm.height - 10);
    i += 10;
    c := not c;
  end;
end;

Procedure Graphics;
begin 
  Window.Clear;
  
  //Рисуем элементы
  SetPenWidth(1);
  SGButton.Draw();
  LabelInfo.Draw();
  LabelServiceInfo.Draw();
  LabelGameInfo.Draw();
  LabelScore.Draw();
  LabelMessage.Draw();
  EditNick.Draw();
  LabelNick.Draw();
  EditPassword.Draw();
  LabelPassword.Draw();
  
  //если играем
  if (inGame) then
  begin
    drawThorns();
    SetPenWidth(1);
    //получаем игровые данные
    serverData := Client.sendMessage(ID + ';0;');
    a := getIntArr(serverData);
    if (a[1] = -1) then
      Disconnect(true);
      
    //Рисуем еду 1
    DrawBall(a[2], a[3], 6, clBrown);
    DrawBall(a[4], a[5], 6, clBrown);
    DrawBall(a[6], a[7], 6, clBrown);
   
    //Рисуем игроков 8
    DrawBall(a[9], a[10], a[11], clGreen);
    DrawBall(a[12], a[13], a[14], clPurple);
    DrawBall(a[15], a[16], a[17], clOrange);
    DrawBall(a[18], a[19], a[20], clGray);
    LabelScore.caption := 'Очки: ' + (a[11 + (id - 1) * 3] - 10); 
  end;
  
  Redraw;
end;

Procedure Close();
begin
  if (inGame) then
    Disconnect(false);
end;

begin
  //создание формы и элементов
  Client := LioTCPClient.Create(IP, PORT);
  MainForm := form.Create(1000, 800, '"Creatures Arena ' + VERSION + '" by LioKor Team', true);
  
  SGButton := lioButton.Create(200, 50, MainForm.width div 2 - 100, MainForm.height div 2 - 25, 'Присоединиться');
  LabelMessage := lioLabel.Create(MainForm.width div 2 - 55, MainForm.height div 2 - 180, '');
  LabelMessage.visible := true; LabelMessage.bColor := clRed;
  
  LabelServiceInfo := liolabel.Create(20, 20, 'Сервер: ' + Client.serverIp + ':' + inttostr(Client.serverPort) + '; FPS: ' + 1000 div REFRESH_DELAY + '; Версия: ' + VERSION);
  LabelInfo := lioLabel.Create(MainForm.width div 2 - 230, MainForm.height div 2 - 150, 'Вы - маленькая бактерия, которая пытается выжить на жестокой арене!');
  LabelScore := lioLabel.Create(MainForm.width - 100, 20, 'Очки: 0');
  LabelScore.bColor := clOrange; LabelScore.visible := false;
  LabelGameInfo := liolabel.Create(20, 20, 'Сервер: ');
  LabelGameInfo.bColor := clOrange; LabelGameInfo.visible := false;
  
  EditNick := lioEdit.Create(MainForm.width div 2 - 45, MainForm.height div 2 - 110, 150, 30, '');
  LabelNick := lioLabel.Create(MainForm.width div 2 - 110, MainForm.height div 2 - 105, 'Логин: ');
  EditPassword := lioEdit.Create(MainForm.width div 2 - 45, MainForm.height div 2 - 70, 150, 30, '');
  EditPassword.forPassword := true;
  LabelPassword := lioLabel.Create(MainForm.width div 2 - 110, MainForm.height div 2 - 65, 'Пароль: ');
  
  //регистрация Edit
  Edits[1] := EditNick;
  Edits[2] := EditPassword;
  
  //регистрация событий
  OnKeyDown := KeyDown;
  OnKeyPress := KeyPress;
  OnMouseMove := MouseMove;
  OnMouseDown := MouseDown;
  OnClose := Close;
  
  //не в игре (в меню)
  inGame := false;
  
  //запуск таймера отрисовки графики
  graph := new timer(REFRESH_DELAY, Graphics);
  graph.Start;
end.