var
  s: string;
  a: array of integer;
  
function getVarArr(s: string): array of integer;
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
  
begin
  s := '2;1000;50;200;500;';
  
  a := getVarArr(s);
  writeln(a[1]);
end.