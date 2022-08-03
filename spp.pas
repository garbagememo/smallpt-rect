program smallptrect;
{$MODE objfpc}{$H+}
{$INLINE ON}
{$modeswitch advancedrecords}
uses SysUtils,Classes,uVect,uBMP,uModel,uScene,uFlux,uLightPath,Math,getopts;

type
  FluxOptionRecord=Record
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
    IF OutFN<>'' THEN begin
      result:=OutFN;
    end
    else begin
      AlgolStr:='Org';
      if AlgolID=1 then AlgolStr:='Org';
      if AlgolID=2 then AlgolStr:='NEE';
      if AlgolID=3 then AlgolStr:='Loop';
      if AlgolID=4 then AlgolStr:='LightPath';
      result:='M'+IntToStr(ModelID)+AlgolStr+'out';
    end;
  end;
  
var
  x,y,sx,sy,s,cc : integer;
  h,w,samps      :integer;
  temp           : VecRecord;
  tColor,r       : VecRecord;

  BMPClass:BMPIOClass;
  T1,T2:TDateTime;
  HH,MM,SS,MS:WORD;
  vColor:rgbColor;
  ArgInt:integer;
  ArgFN:string;
  c:char;
  Rt:TFluxClass;
  SceneRec:SceneRecord;
  FluxOpt:FluxOptionRecord;
begin
  RT:=TFluxClass.Create;
  FluxOpt.setup(320,240,16,1,1,'');(* w,h,samps,algol,model,filename*)
  c:=#0;
  repeat
    c:=getopt('m:o:a:s:w:');
    case c of
      'a':begin
            ArgInt:=StrToInt(OptArg);
            FluxOpt.AlgolID:=ArgInt;
            case ArgInt of
              1 : begin
  //                  Rt:=TFluxClass.Create;
                    writeln('Render=Orignal');
                    FluxOpt.AlgolID:=1;
                  end;
              2 : begin
                    Rt:=TNEEFluxClass.Create;
                    writeln('Render=NEE');
                    FluxOpt.AlgolID:=2;
                  end;
              3 : begin
                    Rt:=TLoopFluxClass.Create;
                    writeln('Render=Non Loop');
                    FluxOpt.AlgolID:=3;
                  end;
              4:begin
                  Rt:=TLightPathFluxClass.Create;
                  writeln('Render=Light Path');
                  FluxOpt.AlgolID:=4;
                end;
              else begin
                Rt:=TFluxClass.Create;
                FluxOpt.AlgolID:=1;
              end;
            end;(*case*)
          end;
      'm':begin
            FluxOpt.ModelID:=StrToInt(OptArg);
          end;
      'o': begin
             ArgFN:=OptArg;
             if ArgFN<>'' then FluxOpt.OutFN:=ArgFN;
             writeln ('Output FileName =',FluxOpt.OutFN);
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
             writeln(' -a [Render Algrithm] a1=Orignal  a2=Next Event  a3=No Loop ');
             writeln(' -m [model Number ] default=0');
             writeln(' -o [finename] output filename');
             writeln(' -s [samps] sampling count');
             writeln(' -w [width] screen width pixel');
             halt;
           end;
    end; { case }
  until c=endofoptions;
  
  BMPClass:=BMPIOClass.Create(FluxOpt.w,FluxOpt.h);
  
  Randomize;

  SRList.InitSceneRecord(FluxOpt.w,FluxOpt.h);
  SceneRec:=SRList.SRL[FluxOpt.ModelID];
  RT.mdl:=TList.Create;
  for cc:=0 to SceneRec.mdl.count-1 do begin
    RT.mdl.add(ModelClass(SceneRec.mdl[cc]).DeepCopy);
  end;
  RT.cam:=SceneRec.cam;


  T1:=Time;
  writeln ('The time is : ',TimeToStr(Time));

  w:=FluxOpt.w;h:=FluxOpt.h;samps:=FluxOpt.samps;
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
      BMPClass.SetPixel(x,h-y,vColor);
    end;(* for x *)
  end;(*for y*)
  T2:=Time-T1;
  DecodeTime(T2,HH,MM,SS,MS);
  writeln ('The time is : ',HH,'h:',MM,'min:',SS,'sec');
  
  BMPClass.WriteBMPFile(FluxOpt.OutFileName+'.bmp');
end.



