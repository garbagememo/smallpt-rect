program smallpt;
{$MODE objfpc}{$H+}
{$INLINE ON}
{$modeswitch advancedrecords}

uses SysUtils,Classes,uVect,uModel,uBMP,Math,getopts;

type 

  CameraRecord=record
    o,d,cx,cy : VecRecord;
    dist      : real;
    w,h       : integer;
    ratio     : real;
    samples   : integer;
    procedure Setup(o_,d_: VecRecord;w_,h_:integer;ratio_,dist_:real);
    procedure SetSamples(sam :integer);
    function Ray(x,y,sx,sy : integer):RayRecord;
  end;

  SceneClass=class
    mdl:TList;
    cam:CameraRecord;
    constructor Create(mdl_:TList;cam_:CameraRecord);
  end;
  
  TRenderThreadClass=Class
    function radiance(r:RayRecord;depth:integer):VecRecord;virtual;
  end;
  TLoopRenderThreadClass=class(TRenderThreadClass)
    function radiance(r:RayRecord;depth:integer):VecRecord;override;
  end;

  TNEERenderClass=Class(TRenderThreadClass)
    FUNCTION Radiance( r:RayRecord;depth:INTEGER):VecRecord;override;
  end;

  constructor SceneClass.Create(mdl_:TList;cam_:CameraRecord);
  begin
    mdl:=mdl_;cam:=cam_;
  end;
  
  procedure CameraRecord.Setup(o_,d_:VecRecord;w_,h_:integer;ratio_,dist_:real);
  begin
    ratio:=ratio_;dist:=dist_;w:=w_;h:=h_;
    o:=o_;d:=VecNorm(d_);
    cx:=CreateVec(ratio*w_/h_,0,0);
    cy:=VecNorm(cx/d_)*ratio;
    samples:=DefaultSamples;
  end;

  procedure CameraRecord.SetSamples(sam :integer );
  begin
    samples:=sam;
  end;

  function CameraRecord.Ray(x,y,sx,sy:integer):RayRecord;
  var
    r1,r2,dx,dy:real;
    td:VecRecord;
  begin
    r1:=2*random;
    if r1<1 then dx:=sqrt(r1)-1 else dx:=1-sqrt(2-r1);
    r2:=2*random;
    if (r2 < 1) then dy := sqrt(r2)-1 else dy := 1-sqrt(2-r2);
    td:= cy*(((sy + 0.5 + dy)/2 + (h-y-1))/h - 0.5)+cx*(((sx + 0.5 + dx)/2 + x)/w - 0.5)+d;
    td:=VecNorm(td);
    result.o:= td*dist+ o;
    result.d := td;
  end;
var
  cam:CameraRecord;


function TRenderThreadClass.radiance( r:RayRecord;depth:integer):VecRecord;
var
  id:integer;
  obj:ModelClass;
  x,n,f,nl,d:VecRecord;
  p,t:real;
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
      d:=VecSphereRef(nl);
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

function TLoopRenderThreadClass.Radiance(r:RayRecord;depth:INTEGER):VecRecord;
VAR
  id:INTEGER;
  obj:ModelClass;
  x,n,f,nl,d:VecRecord;
  p,t,nrd:real;
  into:BOOLEAN;
  RefRay:RayRecord;
  nc,nt,nnt,ddn,cos2t,q,a,b,c,R0,Re,RP,Tr,TP:real;
  tDir:VecRecord;
  tv:VecRecord;
  cl,cf:VecRecord;
BEGIN
//writeln(' DebugY=',DebugY,' DebugX=',DebugX);
  depth:=0;
  id:=0;cl:=ZeroVec;cf:=CreateVec(1,1,1);
  WHILE (TRUE) DO BEGIN
    Inc(depth);
    IF intersect(r,t,id)=FALSE THEN BEGIN
      result:=cl;
      EXIT;
    END;
    obj:=ModelClass(mdl[id]);
    x:=r.o+r.d*t; n:=obj.GetNorm(x); f:=obj.c;
    nrd:=n*r.d;
    IF nrd<0 THEN nl:=n ELSE nl:=n*-1;
    IF (f.x>f.y)AND(f.x>f.z) THEN
      p:=f.x
    ELSE IF f.y>f.z THEN
      p:=f.y
    ELSE
      p:=f.z;
    cl:=cl+VecMul(cf,obj.e);
    IF (Depth > 5) OR (p = 0) THEN BEGIN
       //p=0は要するに発光体に撃ちあたる場合＝発光体は色がぜろだから
      IF (random < p) THEN BEGIN
        f:= f / p;
      END
      ELSE BEGIN
        Result := cl;
        EXIT;
      END;
    END;
    cf:=VecMul(cf,f);
    CASE obj.refl OF
      DIFF:BEGIN
        d:=VecSphereRef(nl);
        r:=CreateRay(x,d);
      END;(*DIFF*)
      SPEC:BEGIN
        tv:=n*2*nrd ;tv:=r.d-tv;
        r:=CreateRay(x,tv);
      END;(*SPEC*)
      REFR:BEGIN
        tv:=n*2*nrd ;tv:=r.d-tv;
        RefRay:=CreateRay(x,tv);
        into:= (n*nl>0);
        nc:=1;nt:=1.5; IF into THEN nnt:=nc/nt ELSE nnt:=nt/nc; ddn:=r.d*nl;
        cos2t:=1-nnt*nnt*(1-ddn*ddn);
        IF cos2t<0 THEN BEGIN   // Total internal reflection
          cl:=cl+VecMul(cf,obj.e);
          r:=RefRay;
          continue;
        END;
        IF into THEN q:=1 ELSE q:=-1;
        tdir := VecNorm(r.d*nnt - n*(q*(ddn*nnt+sqrt(cos2t))));
        IF into THEN Q:=-ddn ELSE Q:=tdir*n;
        a:=nt-nc; b:=nt+nc; R0:=a*a/(b*b); c := 1-Q;
        Re:=R0+(1-R0)*c*c*c*c*c;Tr:=1-Re;P:=0.25+0.5*Re;RP:=Re/P;TP:=Tr/(1-P);
        IF random<p THEN BEGIN// 反射
          cf:=cf*RP;
          cl:=cl+VecMul(cf,obj.e);
          r:=RefRay;
        END
        ELSE BEGIN//屈折
          cf:=cf*TP;
          cl:=cl+VecMul(cf,obj.e);
          r:=CreateRay(x,tdir);
        END
      END;(*REFR*)
    END;(*CASE*)
  END;(*WHILE LOOP *)
END;


FUNCTION TNEERenderClass.Radiance( r:RayRecord;depth:INTEGER):VecRecord;
VAR
  id,i,tid:INTEGER;
  obj,s:ModelClass;
  x,n,f,nl,u,v,w,d:VecRecord;
  p,r1,r2,r2s,t,m1,ss,cc:real;
  into:BOOLEAN;
  RefRay:RayRecord;
  nc,nt,nnt,ddn,cos2t,q,a,b,c,R0,Re,RP,Tr,TP:real;
  tDir:VecRecord;
  EL,sw,su,sv,l,tw,tu,tv:VecRecord;
  cos_a_max,eps1,eps2,eps2s,cos_a,sin_a,phi,omega:real;
  cl,cf:VecRecord;
  E:INTEGER;
BEGIN
//writeln(' DebugY=',DebugY,' DebugX=',DebugX);
  depth:=0;
  id:=0;cl:=ZeroVec;cf:=CreateVec(1,1,1);E:=1;
  WHILE (TRUE) DO BEGIN
    Inc(depth);
    IF intersect(r,t,id)=FALSE THEN BEGIN
       result:=cl;
       EXIT;
    END;
    obj:=ModelClass(mdl[id]);
    x:=r.o+r.d*t; n:=obj.GetNorm(x); f:=obj.c;
    IF n*r.d<0 THEN nl:=n ELSE nl:=n*-1;
    IF (f.x>f.y)AND(f.x>f.z) THEN p:=f.x ELSE IF f.y>f.z THEN p:=f.y ELSE p:=f.z;
    tw:=obj.e*E;
    cl:=cl+VecMul(cf,tw);

    IF (Depth > 5) OR (p = 0) THEN
       IF (random < p) THEN BEGIN
         f:= f / p;
       END
       ELSE BEGIN
         Result := cl;
         EXIT;
       END;

    cf:=VecMul(cf,f);
    CASE obj.refl OF
      DIFF:BEGIN
        d:=VecSphereRef(nl);
        d:=VecNorm(d);

        // Loop over any lights
        EL:=ZeroVec;
        tid:=id;
        FOR i:=0 TO SceneRec.spl.count-1 DO BEGIN
          s:=SphereClass(SceneRec.spl[i]);
          IF (i=tid) THEN BEGIN
            continue;
          END;
          IF (s.e.x<=0) AND  (s.e.y<=0) AND (s.e.z<=0)  THEN continue; // skip non-lights
          sw:=s.p-x;
          tr:=sw*sw;  tr:=s.rad2/tr;
          IF abs(sw.x)/sqrt(tr)>0.1 THEN 
            su:=VecNorm(CreateVec(0,1,0)/sw) 
          ELSE 
            su:=VecNorm(CreateVec(1,0,0)/sw);
          sv:=sw/su;
          IF tr>1 THEN BEGIN
            (*半球の内外=cos_aがマイナスとsin_aが＋、－で場合分け*)
            (*半球内部なら乱反射した寄与全てを取ればよい・・はず*)
            eps1:=M_2PI*random;eps2:=random;eps2s:=sqrt(eps2);
            sincos(eps1,ss,cc);
            l:=VecNorm(u*(cc*eps2s)+v*(ss*eps2s)+w*sqrt(1-eps2));
            IF SceneRec.intersect(CreateRay(x,l),t,id) THEN BEGIN
              IF id=i THEN BEGIN
                tr:=l*nl;
                tw:=s.e*tr;
                EL:=EL+VecMul(f,tw);
              END;
            END;
          END
          ELSE BEGIN //半球外部の場合;
            cos_a_max := sqrt(1-tr );
            eps1 := random; eps2:=random;
            cos_a := 1-eps1+eps1*cos_a_max;
            sin_a := sqrt(1-cos_a*cos_a);
            IF (1-2*random)<0 THEN sin_a:=-sin_a; 
            phi := M_2PI*eps2;
            tw:=sw*(cos(phi)*sin_a);tw:=tw+sv*(sin(phi)*sin_a);tw:=tw+sw*cos_a;
            l:=VecNorm(tw);
            IF (SceneRec.intersect(CreateRay(x,l), t, id) ) THEN BEGIN 
              IF id=i THEN BEGIN  // shadow ray
                omega := 2*PI*(1-cos_a_max);
                tr:=l*nl;
                IF tr<0 THEN tr:=-tr;
                tw:=s.e*tr*omega;tw:=VecMul(f,tw);tw:=tw*M_1_PI;
                EL := EL + tw;  // 1/pi for brdf
              END;
            END;
          END;
        END;(*for*)
        tw:=obj.e*e+EL;
        cl:= cl+VecMul(cf,tw );
        E:=0;
        r:=CreateRay(x,d)
      END;(*DIFF*)
      SPEC:BEGIN
        tw:=obj.e*e;
        cl:=cl+VecMul(cf,tw);
        E:=1;tv:=n*2*(n*r.d) ;tv:=r.d-tv;
        r:=CreateRay(x,tv);
      END;(*SPEC*)
      REFR:BEGIN
        tv:=n*2*(n*r.d) ;tv:=r.d-tv;
        RefRay:=CreateRay(x,tv);
        into:= (n*nl>0);
        nc:=1;nt:=1.5; IF into THEN nnt:=nc/nt ELSE nnt:=nt/nc; ddn:=r.d*nl;
        cos2t:=1-nnt*nnt*(1-ddn*ddn);
        IF cos2t<0 THEN BEGIN   // Total internal reflection
          cl:=cl+VecMul(cf,obj.e*E);
          E:=1;
          r:=RefRay;
          continue;
        END;
        IF into THEN q:=1 ELSE q:=-1;
        tdir := VecNorm(r.d*nnt - n*(q*(ddn*nnt+sqrt(cos2t))));
        IF into THEN Q:=-ddn ELSE Q:=tdir*n;
        a:=nt-nc; b:=nt+nc; R0:=a*a/(b*b); c := 1-Q;
        Re:=R0+(1-R0)*c*c*c*c*c;Tr:=1-Re;P:=0.25+0.5*Re;RP:=Re/P;TP:=Tr/(1-P);
        IF random<p THEN BEGIN// 反射
          cf:=cf*RP;
          cl:=cl+VecMul(cf,obj.e*E);
          E:=1;
          r:=RefRay;
        END
        ELSE BEGIN//屈折
          cf:=cf*TP;
          cl:=cl+VecMul(cf,obj.e*E);
          E:=1;
          r:=CreateRay(x,tdir);
        END
      END;(*REFR*)
    END;(*CASE*)
  END;(*WHILE LOOP *)
END;




var
  x,y,sx,sy,i,s: integer;
  w,h,samps,height    : integer;
  temp       : VecRecord;

  tColor,r : VecRecord;

  BMPClass:BMPIOClass;
  vColor:rgbColor;
  ArgInt:integer;
  FN,ArgFN:string;
  c:char;
   T1,T2:TDateTime;
   HH,MM,SS,MS:WORD;
   Rt:TRenderThreadClass;
begin
  randomize;
  FN:='temp.bmp';
  w:=640 ;h:=480;  samps := 16;
  Rt:=TLoopRenderThreadClass.Create;
  c:=#0;
  repeat
    c:=getopt('o:s:w:a:');
    case c of
      'a':begin
          Rt:=TRenderThreadClass.Create;
      end;
      'o' : begin
         ArgFN:=OptArg;
         if ArgFN<>'' then FN:=ArgFN;
         writeln ('Output FileName =',FN);
      end;
      's' : begin
        ArgInt:=StrToInt(OptArg);
        samps:=ArgInt;
        writeln('samples =',ArgInt);
      end;
      'w' : begin
         ArgInt:=StrToInt(OptArg);
         w:=ArgInt;h:=w *3 div 4;
         writeln('w=',w,' ,h=',h);
      end;
      '?',':' : begin
         writeln(' -o [finename] output filename');
         writeln(' -s [samps] sampling count');
         writeln(' -w [width] screen width pixel');
      end;
    end; { case }
  until c=endofoptions;
  height:=h;
  BMPClass:=BMPIOClass.Create(w,h);
  InitScene;
  Randomize;

 
  T1:=Time;
  writeln ('The time is : ',TimeToStr(Time));

  Cam.Setup(CreateVec(50,52,295.6),CreateVec(0,-0.042612,-1),w,h,0.5135,140);

  for y := 0 to h-1 do begin
    if y mod 10 =0 then writeln('y=',y);
    for x := 0 to w - 1 do begin
      r:=CreateVec(0, 0, 0);
      tColor:=ZeroVec;
      for sy := 0 to 1 do begin
        for sx := 0 to 1 do begin
          for s := 0 to samps - 1 do begin
            temp:=RT.Radiance(Cam.Ray(x,y,sx,sy), 0);
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

  BMPClass.WriteBMPFile(FN);
end.

{
検証が必要な点として
・thread外にデータ持って大丈夫？
がある。最終にはそっちに持ってく?
mdl,camとintersection関数が必要だが・・・

}
