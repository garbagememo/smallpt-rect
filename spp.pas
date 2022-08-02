program smallptrect;
{$MODE objfpc}{$H+}
{$INLINE ON}
{$modeswitch advancedrecords}
uses SysUtils,Classes,uVect,uBMP,uModel,uScene,uFlux,Math,getopts;

var
   x,y,sx,sy,s,cc    : integer;
   w,h,samps,height  : integer;
   temp              : VecRecord;
   tColor,r: VecRecord;

   BMPClass:BMPIOClass;
   T1,T2:TDateTime;
   HH,MM,SS,MS:WORD;
   vColor:rgbColor;
   ArgInt,AlgolNum:integer;
   FN,ArgFN:string;
   c:char;
   Rt:TFluxClass;
   ModelID:integer;
   SceneRec:SceneRecord;
begin
  FN:='temp';
  w:=320 ;h:=240;  samps := 16;
  Rt:=TFluxClass.Create;
  ModelID:=0;
  c:=#0;
  repeat
    c:=getopt('m:o:a:s:w:');
    case c of
      'a':begin
            ArgInt:=StrToInt(OptArg);
            AlgolNum:=ArgInt;
            case ArgInt of
              1 : begin
                    writeln('Render=Orignal')
                  end;
              2 : begin
                    Rt:=TNEEFluxClass.Create;
                    writeln('Render=NEE');
                  end;
              3 : begin
                    Rt:=TLoopFluxClass.Create;
                    writeln('Render=Non Loop');
                  end;
            end;
          end;
      'm':begin
            ModelID:=StrToInt(OptArg);
          end;
      'o': begin
             ArgFN:=OptArg;
             if ArgFN<>'' then FN:=ArgFN;
             writeln ('Output FileName =',FN);
           end;
      's': begin
             ArgInt:=StrToInt(OptArg);
             samps:=ArgInt;
             writeln('samples =',ArgInt);
           end;
      'w': begin
             ArgInt:=StrToInt(OptArg);
             w:=ArgInt;h:=w *3 div 4;
             writeln('w=',w,' ,h=',h);
           end;
      '?': begin
             writeln(' -a [Render Algrithm] a1=Orignal  a2=Next Event  a3=No Loop ');
             writeln(' -m [model Number ] default=0');
             writeln(' -o [finename] output filename');
             writeln(' -s [samps] sampling count');
             writeln(' -w [width] screen width pixel');
             halt;
           end;
    end; { case }
  until c=endofoptions;
  height:=h;
  BMPClass:=BMPIOClass.Create(w,h);
  
  Randomize;

  SRList.InitSceneRecord(w,h);
  SceneRec:=SRList.SRL[ModelID];
  RT.mdl:=TList.Create;
  for cc:=0 to SceneRec.mdl.count-1 do begin
    RT.mdl.add(ModelClass(SceneRec.mdl[cc]).DeepCopy);
  end;
  RT.cam:=SceneRec.cam;
  
  
  T1:=Time;
  writeln ('The time is : ',TimeToStr(Time));

  for y := 0 to h-1 do begin
    if y mod 10 =0 then writeln('y=',y);
    for x := 0 to w - 1 do begin
      r:=CreateVec(0, 0, 0);
      tColor:=ZeroVec;
      for sy := 0 to 1 do begin
        for sx := 0 to 1 do begin
          for s := 0 to samps - 1 do begin
            temp:=Rt.Radiance(RT.Cam.Ray(x,y,sx,sy), 0);
            temp:= temp/ samps;
            r:= r+temp;
          end;(*samps*)
          temp:= ClampVector(r)* 0.25;
          tColor:=tColor+ temp;
          r:=CreateVec(0, 0, 0);
        end;(*sx*)
      end;(*sy*)
      vColor:=ColToRGB(tColor);
      BMPClass.SetPixel(x,height-y,vColor);
    end;(* for x *)
  end;(*for y*)
  T2:=Time-T1;
  DecodeTime(T2,HH,MM,SS,MS);
  writeln ('The time is : ',HH,'h:',MM,'min:',SS,'sec');
  
  BMPClass.WriteBMPFile(FN+'.bmp');
end.



