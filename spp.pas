program smallpt;
{$MODE objfpc}{$H+}
{$INLINE ON}
{$modeswitch advancedrecords}
uses SysUtils,Classes,uVect,uBMP,uModel,uScene,uFlux,uLightPath,Math,getopts;

const 
  DefaultOutFileName='out.bmp';
type
  FluxOptionRecord=record
    w,h,samps:integer;
    AlgolID,ModelID:integer;
    OutFN:string;
    procedure Setup(w_,h_,samp_,Algol,Model:integer;OFN:string);
    function OutFileName:string;
  end;
  procedure FluxOptionRecord.Setup(w_,h_,samp_,Algol,Model:integer;OFN:string);
  begin
    w:=w_;h:=h_;samps:=samp_;AlgolID:=Algol;ModelID:=Model;
    OutFN:=OFN;
  end;
  function FluxOptionRecord.OutFileName:string;
  var
    AlgolStr:string;
  begin
    if OutFN<>'' then begin
      result:=OutFN;
    end
    else begin
      AlgolStr:='Org';
      if AlgolID=1 then AlgolStr:='ORG';
      if AlgolID=2 then AlgolStr:='NEE';
      if AlgolID=3 then AlgolStr:='Loop';
      if AlgolID=4 then AlgolStr:='LP';
      result:='M'+IntToStr(ModelID)+AlgolStr+DefaultOutFileName;
    end;
  end;


var
   x,y,sx,sy,s                    : integer;
   temp                            : VecRecord;
   tempRay                           : RayRecord;
   Cam                              : CameraRecord;
   tColor,r: VecRecord;

   BMPClass:BMPIOClass;
   T1,T2:TDateTime;
   HH,MM,SS,MS:WORD;
   vColor:rgbColor;
   ArgInt:integer;
   FN,ArgFN:string;
   c:char;
   Rt:TFluxClass;
   Scene:SceneRecord;
   FluxOpt:FluxOptionRecord;
   
begin
  FluxOpt.OutFN:='';//空白のとき名前を作る
  FluxOpt.AlgolID:=1;
  FluxOpt.ModelID:=0;
  FluxOpt.w:=320 ;FluxOpt.h:=240;  FluxOpt.samps := 16;


  c:=#0;
  repeat
    c:=getopt('m:o:a:s:w:');
    case c of
    'm': begin
           ArgInt:=StrToInt(OptArg);
           FluxOpt.ModelId:=ArgInt;
         end;
    'a': begin
           ArgInt:=StrToInt(OptArg);
           FluxOpt.AlgolID:=ArgInt;
           case ArgInt of
           1 : begin
                 writeln('Render=Orignal')
               end;
           2 : begin
                 writeln('Render=NEE');
               end;
           3 : begin
                 writeln('Render=Non Loop');
               end;
           4:begin
               writeln('Render=LightPath');
           end;
           else FluxOpt.AlgolID:=1;
           end;
         end;
    'o': begin
           ArgFN:=OptArg;
           if ArgFN<>'' then FluxOpt.OutFN:=ArgFN;
           writeln ('Output FileName =',FN);
         end;
    's': begin
           ArgInt:=StrToInt(OptArg);
           FluxOpt.samps:=ArgInt;
           writeln('samples =',ArgInt);
         end;
    'w': begin
           ArgInt:=StrToInt(OptArg);
           FluxOpt.w:=ArgInt;FluxOpt.h:=FluxOpt.w *3 div 4;
           writeln('w=',FluxOpt.w,' ,h=',FluxOpt.h);
         end;
    '?': begin
           writeln(' -m [Model ID] Rendering Model');
           writeln(' -a [Render Algrithm] r1=Orignal  r2=Next Event  r3=No Loop r4=Light Path');
           writeln(' -o [finename] output filename');
           writeln(' -s [samps] sampling count');
           writeln(' -w [width] screen width pixel');
           halt;
         end;
    end; { case }
  until c=endofoptions;
//  height:=FluxOpt.h;

  Randomize;
  BMPClass:=BMPIOClass.Create(FluxOpt.w,FluxOpt.h);

  case FluxOpt.AlgolID of
  1:RT:=TFluxClass.Create;
  2:RT:=TNEEFluxClass.Create;
  3:RT:=TLoopFluxClass.Create;
  4:RT:=TLightPathFluxClass.Create;
  else Rt:=TFluxClass.Create;
  end;

  SRList.InitSceneRecord(FluxOpt.w,FluxOpt.h);
  Scene:=SRList.SRL[FluxOpt.ModelID];
  RT.Scene.mdl:=SRList.DeepCopyModel(FluxOpt.ModelID);
  RT.Scene.cam:=Scene.cam;

  writeln('Model of Scene =',Scene.SceneName);
  
//  if FluxOpt.AlgolID=4 then begin
//    TLightPathFluxClass(Rt).LPList.SetScene(Rt.Scene)
//  end;


 
  T1:=Time;
  writeln ('The time is : ',TimeToStr(Time));

  for y := 0 to FluxOpt.h-1 do begin
    if y mod 10 =0 then writeln('y=',y);
    for x := 0 to FluxOpt.w - 1 do begin
      r:=CreateVec(0, 0, 0);
      tColor:=ZeroVec;
      for sy := 0 to 1 do begin
        for sx := 0 to 1 do begin
          for s := 0 to FluxOpt.samps - 1 do begin
            temp:=Rt.Radiance(Rt.Scene.Cam.Ray(x,y,sx,sy), 0);
            temp:= temp/ FluxOpt.samps;
            r:= r+temp;
          end;(*samps*)
          temp:= ClampVector(r)* 0.25;
          tColor:=tColor+ temp;
          r:=CreateVec(0, 0, 0);
        end;(*sx*)
      end;(*sy*)
      vColor:=ColToRGB(tColor);
      BMPClass.SetPixel(x,FluxOpt.h-y,vColor);
    end;(* for x *)
  end;(*for y*)
  T2:=Time-T1;
  DecodeTime(T2,HH,MM,SS,MS);
  writeln ('The time is : ',HH,'h:',MM,'min:',SS,'sec');
   
  BMPClass.WriteBMPFile(FluxOpt.OutFileName);
end.
