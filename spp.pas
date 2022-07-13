program smallptrect;
{$MODE objfpc}{$H+}
{$INLINE ON}

uses SysUtils,Classes,uVect,uBMP,uModel,uScene,Math,getopts;

type 

  TRenderClass=class
    function Radiance(r : RayRecord;Depth:integer ):VecRecord;Virtual;
  end;                
  TNEERenderClass=class(TRenderClass)
    function Radiance(r : RayRecord;Depth:integer ):VecRecord;OverRide;
  end;                
  TLoopRenderClass=class(TRenderClass)
    function Radiance(r : RayRecord;Depth:integer ):VecRecord;OverRide;
  end;                

function TRenderClass.radiance( r:RayRecord;depth:integer):VecRecord;
var
  id:integer;
  obj:ModelClass;
  x,n,f,nl,u,v,w,d:VecRecord;
  p,r1,r2,r2s,t:real;
  into:boolean;
  RefRay:RayRecord;
  nc,nt,nnt,ddn,cos2t,q,a,b,c,R0,Re,RP,Tr,TP:real;
  tDir:VecRecord;
begin
  id:=0;depth:=depth+1;
  if intersect(r,t,id)=false then begin
    result:=ZeroVec;exit;
  end;
  obj:=ModelClass(mdl[id]);
  x:=r.o+r.d*t; n:=obj.GetNorm(x); f:=obj.c;
  if VecDot(n,r.d)<0 then nl:=n else nl:=n*-1;
  if (f.x>f.y)and(f.x>f.z) then
    p:=f.x
  else if f.y>f.z then 
    p:=f.y
  else
    p:=f.z;
   if (depth>5) then begin
    if random<p then 
      f:=f/p 
    else begin
      result:=obj.e;
      exit;
    end;
  end;
  case obj.refl of
    DIFF:begin
      d := VecSphereRef(nl);
      result:=obj.e+VecMul(f,radiance(CreateRay(x,d),depth) );
    end;(*DIFF*)
    SPEC:begin
      result:=obj.e+VecMul(f,(radiance(CreateRay(x,r.d-n*2*(n*r.d) ),depth)));
    end;(*SPEC*)
    REFR:begin
      RefRay:=CreateRay(x,r.d-n*2*(n*r.d) );
      into:= (n*nl>0);
      nc:=1;nt:=1.5; if into then nnt:=nc/nt else nnt:=nt/nc; ddn:=r.d*nl; 
      cos2t:=1-nnt*nnt*(1-ddn*ddn);
      if cos2t<0 then begin   // Total internal reflection
        result:=obj.e + VecMul(f,radiance(RefRay,depth));
        exit;
      end;
      if into then q:=1 else q:=-1;
      tdir := VecNorm(r.d*nnt - n*(q*(ddn*nnt+sqrt(cos2t))));
      if into then Q:=-ddn else Q:=tdir*n;
      a:=nt-nc; b:=nt+nc; R0:=a*a/(b*b); c := 1-Q;
      Re:=R0+(1-R0)*c*c*c*c*c;Tr:=1-Re;P:=0.25+0.5*Re;RP:=Re/P;TP:=Tr/(1-P);
      if depth>2 then begin
        if random<p then // 反射
          result:=obj.e+VecMul(f,radiance(RefRay,depth)*RP)
        else //屈折
          result:=obj.e+VecMul(f,radiance(CreateRay(x,tdir),depth)*TP);
      end
      else begin// 屈折と反射の両方を追跡
        result:=obj.e+VecMul(f,radiance(RefRay,depth)*Re+radiance(CreateRay(x,tdir),depth)*Tr);
      end;
    end;(*REFR*)
  end;(*CASE*)
end;


function TNEERenderClass.Radiance( r:RayRecord;depth:integer):VecRecord;
var
  id,i,tid:integer;
  obj,s:ModelClass;// Rect Implement
  x,n,f,nl,u,v,w,d:VecRecord;
  p,r1,r2,r2s,t,m1,ss,cc:real;
  into:boolean;
  RefRay:RayRecord;
  nc,nt,nnt,ddn,cos2t,q,a,b,c,R0,Re,RP,Tr,TP:real;
  tDir:VecRecord;
  EL,sw,su,sv,l,tw,tu,tv:VecRecord;
  cos_a_max,eps1,eps2,eps2s,cos_a,sin_a,phi,omega:real;
  cl,cf:VecRecord;
  E:integer;
begin
  //writeln(' DebugY=',DebugY,' DebugX=',DebugX);
  depth:=0;
  id:=0;cl:=ZeroVec;cf:=CreateVec(1,1,1);E:=1;
  while (TRUE) do begin
    Inc(depth);
    if intersect(r,t,id)=false then begin
      result:=cl;
      exit;
    end;
    obj:=ModelClass(mdl[id]);
    x:=r.o+r.d*t; n:=obj.GetNorm(x); f:=obj.c;
    if n*r.d<0 then nl:=n else nl:=n*-1;
    if (f.x>f.y)and(f.x>f.z) then p:=f.x else if f.y>f.z then p:=f.y else p:=f.z;
    tw:=obj.e*E;
    cl:=cl+VecMul(cf,tw);

    if (Depth > 5) or (p = 0) then
      if (random < p) then begin
        f:= f / p;
      end
      else begin
        Result := cl;
        exit;
      end;

    cf:=VecMul(cf,f);
    case obj.refl of
      DIFF:
        begin
          d:=VecSphereRef(nl);
          // Loop over any lights
          EL:=ZeroVec;
          tid:=id;
          for i:=0 to mdl.count-1 do begin
            s:=ModelClass(mdl[i]);
            if (i=tid) then begin
              continue;
            end;
            if s.isLight=false  then continue; // skip non-lights
            l:=s.GetLightPath(x);	  
            if intersect(CreateRay(x,l),t,id) then begin
              if id=i then begin
                tr:=l*nl;
                tw:=s.e*tr*s.omega_1_pi;
                EL:=EL+VecMul(f,tw);
              end;
            end;
          end;(*for*)
          tw:=obj.e*e+EL;
          cl:= cl+VecMul(cf,tw );
          E:=0;
          r:=CreateRay(x,d);
        end;(*DIFF*)
      SPEC:
        begin
          tw:=obj.e*e;
          cl:=cl+VecMul(cf,tw);
          E:=1;tv:=n*2*(n*r.d) ;tv:=r.d-tv;
          r:=CreateRay(x,tv);
        end;(*SPEC*)
      REFR:
        begin
          tv:=n*2*(n*r.d) ;tv:=r.d-tv;
          RefRay:=CreateRay(x,tv);
          into:= (n*nl>0);
          nc:=1;nt:=1.5; if into then nnt:=nc/nt else nnt:=nt/nc; ddn:=r.d*nl;
          cos2t:=1-nnt*nnt*(1-ddn*ddn);
          if cos2t<0 then begin   // Total internal reflection
            cl:=cl+VecMul(cf,obj.e*E);
            E:=1;
            r:=RefRay;
            continue;
          end;
          if into then q:=1 else q:=-1;
          tdir := VecNorm(r.d*nnt - n*(q*(ddn*nnt+sqrt(cos2t))));
          if into then Q:=-ddn else Q:=tdir*n;
          a:=nt-nc; b:=nt+nc; R0:=a*a/(b*b); c := 1-Q;
          Re:=R0+(1-R0)*c*c*c*c*c;Tr:=1-Re;P:=0.25+0.5*Re;RP:=Re/P;TP:=Tr/(1-P);
          if random<p then begin// 反射
            cf:=cf*RP;
            cl:=cl+VecMul(cf,obj.e*E);
            E:=1;
            r:=RefRay;
          end
          else begin//屈折
            cf:=cf*TP;
            cl:=cl+VecMul(cf,obj.e*E);
            E:=1;
            r:=CreateRay(x,tdir);
          end
        end;(*REFR*)
    end;(*CASE*)
  end;(*WHILE LOOP *)
end;



function TLoopRenderClass.Radiance( r:RayRecord;depth:integer):VecRecord;
var
  id:integer;
  obj:ModelClass;
  x,n,f,nl,u,v,w,d:VecRecord;
  p,r1,r2,r2s,t,ss,cc,nrd:real;
  into:boolean;
  RefRay:RayRecord;
  nc,nt,nnt,ddn,cos2t,q,a,b,c,R0,Re,RP,Tr,TP:real;
  tDir:VecRecord;
  tu,tv:VecRecord;
  cl,cf:VecRecord;
begin
//writeln(' DebugY=',DebugY,' DebugX=',DebugX);
  depth:=0;
  id:=0;cl:=ZeroVec;cf:=CreateVec(1,1,1);
  while (TRUE) do begin
    Inc(depth);
    if intersect(r,t,id)=false then begin
      result:=cl;
      exit;
    end;
    obj:=ModelClass(mdl[id]);
    x:=r.o+r.d*t; n:=obj.GetNorm(x); f:=obj.c;
    nrd:=n*r.d;
    if nrd<0 then nl:=n else nl:=n*-1;
    if (f.x>f.y)and(f.x>f.z) then
      p:=f.x
    else if f.y>f.z then
      p:=f.y
    else
      p:=f.z;
    cl:=cl+VecMul(cf,obj.e);
    if (Depth > 5) or (p = 0) then begin
       //p=0は要するに発光体に撃ちあたる場合＝発光体は色がぜろだから
      if (random < p) then begin
        f:= f / p;
      end
      else begin
        Result := cl;
        exit;
      end;
    end;
    cf:=VecMul(cf,f);
    case obj.refl of
      DIFF:begin
        d:=VecSphereRef(nl);
        r:=CreateRay(x,d)
      end;(*DIFF*)
      SPEC:begin
        tv:=n*2*nrd ;tv:=r.d-tv;
        r:=CreateRay(x,tv);
      end;(*SPEC*)
      REFR:begin
        tv:=n*2*nrd ;tv:=r.d-tv;
        RefRay:=CreateRay(x,tv);
        into:= (n*nl>0);
        nc:=1;nt:=1.5; if into then nnt:=nc/nt else nnt:=nt/nc; ddn:=r.d*nl;
        cos2t:=1-nnt*nnt*(1-ddn*ddn);
        if cos2t<0 then begin   // Total internal reflection
          cl:=cl+VecMul(cf,obj.e);
          r:=RefRay;
          continue;
        end;
        if into then q:=1 else q:=-1;
        tdir := VecNorm(r.d*nnt - n*(q*(ddn*nnt+sqrt(cos2t))));
        if into then Q:=-ddn else Q:=tdir*n;
        a:=nt-nc; b:=nt+nc; R0:=a*a/(b*b); c := 1-Q;
        Re:=R0+(1-R0)*c*c*c*c*c;Tr:=1-Re;P:=0.25+0.5*Re;RP:=Re/P;TP:=Tr/(1-P);
        if random<p then begin// 反射
          cf:=cf*RP;
          cl:=cl+VecMul(cf,obj.e);
          r:=RefRay;
        end
        else begin//屈折
          cf:=cf*TP;
          cl:=cl+VecMul(cf,obj.e);
          r:=CreateRay(x,tdir);
        end
      end;(*REFR*)
    end;(*CASE*)
  end;(*WHILE LOOP *)
end;


var
   x,y,sx,sy,s       : integer;
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
   Rt:TRenderClass;
   ModelID:integer;
   SceneRec:SceneRecord;
begin
  FN:='temp';
  w:=320 ;h:=240;  samps := 16;
  Rt:=TRenderClass.Create;
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
                    Rt:=TNEERenderClass.Create;
                    writeln('Render=NEE');
                  end;
              3 : begin
                    Rt:=TLoopRenderClass.Create;
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
  SceneRec:=SRList.GetScene(ModelID);
  mdl:=SceneRec.mdl;
  cam:=SceneRec.cam;
  
  
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
            temp:=Rt.Radiance(Cam.Ray(x,y,sx,sy), 0);
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



