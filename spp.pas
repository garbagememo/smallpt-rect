program smallpt;
{$MODE objfpc}{$H+}
{$INLINE ON}
{$modeswitch advancedrecords}

uses SysUtils,Classes,uVect,uBMP,Math,getopts;

const 
  eps=1e-4;
  INF=1e20;
  DefaultSamples=16;


type 
  ModelClass=CLASS
    p,e,c:VecRecord;// position. emission,color
    refl:RefType;
    isLight:boolean;
    constructor Create(p_,e_,c_:VecRecord;refl_:RefType);
    function intersect(const r:RayRecord):real;virtual;abstract;
    function GetNorm(x:VecRecord):VecRecord;virtual;abstract;
  END;

  SphereClass=CLASS(ModelClass)
    rad:real;       //radius
    rad2:real;
    constructor Create(rad_:real;p_,e_,c_:VecRecord;refl_:RefType);
    function intersect(const r:RayRecord):real;override;
    function GetNorm(x:VecRecord):VecRecord;override;
  END;

  RectClass=CLASS(ModelClass)
    H1,H2,V1,V2:Real;
    RA:RectAxisType;
    n:VecRecord;
    constructor Create(RA_:RectAxisType;H1_,H2_,V1_,V2_:real;p_,e_,c_:VecRecord;refl_:RefType);
    function intersect(const r:RayRecord):real;override;
    function GetNorm(x:VecRecord):VecRecord;override;
  END;

  CameraRecord=RECORD
    o,d,cx,cy : VecRecord;
    dist      : real;
    w,h       : INTEGER;
    ratio     : real;
    samples   : INTEGER;
    PROCEDURE Setup(o_,d_: VecRecord;w_,h_:INTEGER;ratio_,dist_:real);
    PROCEDURE SetSamples(sam :INTEGER);
    FUNCTION Ray(x,y,sx,sy : INTEGER):RayRecord;
  END;

PROCEDURE CameraRecord.Setup(o_,d_:VecRecord;w_,h_:INTEGER;ratio_,dist_:real);
BEGIN
  ratio:=ratio_;dist:=dist_;w:=w_;h:=h_;
  o:=o_;d:=VecNorm(d_);
  cx:=CreateVec(ratio*w_/h_,0,0);
  cy:=VecNorm(cx/d_)*ratio;
   samples:=DefaultSamples;
END;

PROCEDURE CameraRecord.SetSamples(sam :INTEGER );
BEGIN
   samples:=sam;
END;

FUNCTION CameraRecord.Ray(x,y,sx,sy:INTEGER):RayRecord;
VAR
  r1,r2,dx,dy:real;
  td:VecRecord;
BEGIN
  r1:=2*random;
  IF r1<1 THEN dx:=sqrt(r1)-1 ELSE dx:=1-sqrt(2-r1);
  r2:=2*random;
  IF (r2 < 1) THEN dy := sqrt(r2)-1 ELSE dy := 1-sqrt(2-r2);
  td:= cy*(((sy + 0.5 + dy)/2 + (h-y-1))/h - 0.5)+cx*(((sx + 0.5 + dx)/2 + x)/w - 0.5)+d;
  td:=VecNorm(td);
  result.o:= td*dist+ o;
  result.d := td;
END;


  
constructor ModelClass.Create(p_,e_,c_:VecRecord;refl_:RefType);
begin
  p:=p_;e:=e_;c:=c_;refl:=refl_;IF VecSQR(e)>0 THEN isLight:=TRUE ELSE isLight:=FALSE;
END;
constructor SphereClass.Create(rad_:real;p_,e_,c_:VecRecord;refl_:RefType);
begin
  rad:=rad_;rad2:=rad*rad; inherited create(p_,e_,c_,refl_);
end;
function SphereClass.intersect(const r:RayRecord):real;
var
  op:VecRecord;
  t,b,det:real;
begin
  op:=p-r.o;
  t:=eps;b:=op*r.d;
  det:=b*b-op*op+rad*rad;
  IF det<0 THEN 
    result:=INF
  ELSE BEGIN
    det:=sqrt(det); t:=b-det;
    IF t>eps then 
      result:=t
    ELSE BEGIN
      t:=b+det;
      if t>eps then 
        result:=t
      else
        result:=INF;
    END;
  END;
end;
function SphereClass.GetNorm(x:VecRecord):VecRecord;
BEGIN
  result:=VecNorm(x-p)
END;

constructor RectClass.Create(RA_:RectAxisType;H1_,H2_,V1_,V2_:real;p_,e_,c_:VecRecord;refl_:RefType);
BEGIN
  RA:=RA_;H1:=H1_;H2:=H2_;V1:=V1_;V2:=V2_;inherited create(p_,e_,c_,refl_);
END;
function RectClass.intersect(const r:RayRecord):real;
var
  t:real;
  pt:VecRecord;
BEGIN
(**光線と平行に近い場合の処理が必要だが・・・**)
  case RA OF
    xy:begin
      result:=INF;
      if abs(r.d.z)<eps THEN exit;
      t:=(p.z-r.o.z)/r.d.z;
      pt:=r.o+r.d*t;
      IF (pt.x<H2) and (pt.x>H1) and (pt.y<V2)and (pt.y>V1) THEN result:=t;
      IF t<eps THEN t:=INF;
    end;(*xy*)
    xz:begin
      result:=INF;
      if abs(r.d.y)<eps THEN exit;
      t:=(p.y-r.o.y)/r.d.y;
      pt:=r.o+r.d*t;
      IF (pt.x<H2) and (pt.x>H1) and (pt.z<V2)and (pt.z>V1) THEN result:=t;
      IF t<eps THEN t:=INF;
    end;(*xz*)
    yz:begin
      result:=INF;
      if abs(r.d.y)<eps THEN exit;
      t:=(p.x-r.o.x)/r.d.x;
      pt:=r.o+r.d*t;
      IF (pt.y<H2) and (pt.y>H1) and (pt.z<V2)and (pt.z>V1) THEN result:=t;
      IF t<eps THEN t:=INF;
    end;(*yz*)
  END;(*case*)
END;

function RectClass.GetNorm(x:VecRecord):VecRecord;
begin
  case RA of
    xy:result:=CreateVec(0,0,1);
    xz:result:=CreateVec(0,1,0);
    yz:result:=CreateVec(1,0,0);
  end;
end;

var
  mdl:TList;
procedure InitScene;
begin
  mdl:=TList.Create;
  mdl.add( sphereClass.Create(1e5, CreateVec( 1e5+1,40.8,81.6),  ZeroVec,CreateVec(0.75,0.25,0.25),DIFF) );//Left
  mdl.add( sphereClass.Create(1e5, CreateVec(-1e5+99,40.8,81.6), ZeroVec,CreateVec(0.25,0.25,0.75),DIFF) );//Right
  mdl.add( sphereClass.Create(1e5, CreateVec(50,40.8, 1e5),      ZeroVec,CreateVec(0.75,0.75,0.75),DIFF) );//Back
  mdl.add( sphereClass.Create(1e5, CreateVec(50,40.8,-1e5+170),  ZeroVec,CreateVec(0,0,0),      DIFF) );//Front
  mdl.add( sphereClass.Create(1e5, CreateVec(50, 1e5, 81.6),     ZeroVec,CreateVec(0.75,0.75,0.75),DIFF) );//Bottomm
  mdl.add( sphereClass.Create(1e5, CreateVec(50,-1e5+81.6,81.6), ZeroVec,CreateVec(0.75,0.75,0.75),DIFF) );//Top
  mdl.add( sphereClass.Create(16.5,CreateVec(27,16.5,47),        ZeroVec,CreateVec(1,1,1)*0.999, SPEC) );//Mirror
  mdl.add( sphereClass.Create(16.5,CreateVec(73,16.5,88),        ZeroVec,CreateVec(1,1,1)*0.999, REFR) );//Glass
  mdl.add( sphereClass.Create(600, CreateVec(50,681.6-0.27,81.6),CreateVec(12,12,12),    ZeroVec,DIFF) );//Ligth
  mdl.add( RectClass.Create(XZ,20,80,60,100,CreateVec(50,40,80), zeroVec,  CreateVec(0.25,0.75,0.25),DIFF) );
end;

function intersect(const r:RayRecord;var t:real; var id:integer):boolean;
var 
  n,d:real;
  i:integer;
begin
  t:=INF;
  for i:=0 to mdl.count-1 do begin
    d:=ModelClass(mdl[i]).intersect(r);
    if d<t THEN BEGIN
      t:=d;
      id:=i;
    END;
  end;
  result:=(t<inf);
END;

function radiance(const r:RayRecord;depth:integer):VecRecord;
var
  id:integer;
  obj:ModelClass;
  x,n,f,nl,u,v,w,d:VecRecord;
  p,r1,r2,r2s,t,pr:real;
  into:boolean;
  RefRay:RayRecord;
  nc,nt,nnt,ddn,cos2t,q,a,b,c,R0,Re,RP,Tr,TP:real;
  tDir:VecRecord;
begin
  id:=0;depth:=depth+1;
  if intersect(r,t,id)=FALSE then begin
    result:=ZeroVec;exit;
  end;
  obj:=ModelClass(mdl[id]);
  x:=r.o+r.d*t; n:=obj.GetNorm(x); f:=obj.c;
  IF VecDot(n,r.d)<0 THEN nl:=n else nl:=n*-1;
  IF (f.x>f.y)and(f.x>f.z) THEN
    p:=f.x
  ELSE IF f.y>f.z THEN 
    p:=f.y
  ELSE
    p:=f.z;
   if (depth>5) then begin
    if random<p then 
      f:=f/p 
    else begin
      result:=obj.e;
      exit;
    end;
  end;
  CASE obj.refl OF
    DIFF:BEGIN
      r1:=2*PI*random;r2:=random;r2s:=sqrt(r2);
      w:=nl;
      IF abs(w.x)>0.1 THEN
        u:=VecNorm(CreateVec(0,1,0)/w) 
      ELSE
        u:=VecNorm(CreateVec(1,0,0)/w) ;
      v:=w/u;
      d := VecNorm(u*cos(r1)*r2s + v*sin(r1)*r2s + w*sqrt(1-r2));
      result:=obj.e+VecMul(f,radiance(CreateRay(x,d),depth) );
    END;(*DIFF*)
    SPEC:BEGIN
      result:=obj.e+VecMul(f,(radiance(CreateRay(x,r.d-n*2*(n*r.d) ),depth)));
    END;(*SPEC*)
    REFR:BEGIN
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
      IF into then Q:=-ddn else Q:=tdir*n;
      a:=nt-nc; b:=nt+nc; R0:=a*a/(b*b); c := 1-Q;
      Re:=R0+(1-R0)*c*c*c*c*c;Tr:=1-Re;P:=0.25+0.5*Re;RP:=Re/P;TP:=Tr/(1-P);
      IF depth>2 THEN BEGIN
        IF random<p then // 反射
          result:=obj.e+VecMul(f,radiance(RefRay,depth)*RP)
        ELSE //屈折
          result:=obj.e+VecMul(f,radiance(CreateRay(x,tdir),depth)*TP);
      END
      ELSE BEGIN// 屈折と反射の両方を追跡
        result:=obj.e+VecMul(f,radiance(RefRay,depth)*Re+radiance(CreateRay(x,tdir),depth)*Tr);
      END;
    END;(*REFR*)
  END;(*CASE*)
end;


VAR
  x,y,sx,sy,i,s: INTEGER;
  w,h,samps,height    : INTEGER;
  temp       : VecRecord;
  cam:CameraRecord;
  tColor,r : VecRecord;

  BMPClass:BMPIOClass;
  vColor:rgbColor;
  ArgInt:integer;
  FN,ArgFN:string;
  c:char;
   T1,T2:TDateTime;
   HH,MM,SS,MS:WORD;

BEGIN
  randomize;
  FN:='temp.bmp';
  w:=640 ;h:=480;  samps := 16;
  c:=#0;
  repeat
    c:=getopt('o:s:w:');

    case c of
      'o' : BEGIN
         ArgFN:=OptArg;
         IF ArgFN<>'' THEN FN:=ArgFN;
         writeln ('Output FileName =',FN);
      END;
      's' : BEGIN
        ArgInt:=StrToInt(OptArg);
        samps:=ArgInt;
        writeln('samples =',ArgInt);
      END;
      'w' : BEGIN
         ArgInt:=StrToInt(OptArg);
         w:=ArgInt;h:=w *3 div 4;
         writeln('w=',w,' ,h=',h);
      END;
      '?',':' : BEGIN
         writeln(' -o [finename] output filename');
         writeln(' -s [samps] sampling count');
         writeln(' -w [width] screen width pixel');
      END;
    end; { case }
  until c=endofoptions;
  height:=h;
  BMPClass:=BMPIOClass.Create(w,h);
  InitScene;
  Randomize;

 
  T1:=Time;
  WRITELN ('The time is : ',TimeToStr(Time));

  Cam.Setup(CreateVec(50,52,295.6),CreateVec(0,-0.042612,-1),w,h,0.5135,140);

  FOR y := 0 TO h-1 DO BEGIN
    IF y mod 10 =0 THEN WRITELN('y=',y);
    FOR x := 0 TO w - 1 DO BEGIN
      r:=CreateVec(0, 0, 0);
      tColor:=ZeroVec;
      FOR sy := 0 TO 1 DO BEGIN
        FOR sx := 0 TO 1 DO BEGIN
          FOR s := 0 TO samps - 1 DO BEGIN
            temp:=Radiance(Cam.Ray(x,y,sx,sy), 0);
            temp:= temp/ samps;
            r:= r+temp;
          END;(*samps*)
          temp:= ClampVector(r)* 0.25;
          tColor:=tColor+ temp;
          r:=CreateVec(0, 0, 0);
        END;(*sx*)
      END;(*sy*)
      vColor:=ColToRGB(tColor);
      BMPClass.SetPixel(x,height-y,vColor);
    END;(* for x *)
  END;(*for y*)

  T2:=Time-T1;
  DecodeTime(T2,HH,MM,SS,MS);
  WRITELN ('The time is : ',HH,'h:',MM,'min:',SS,'sec');

  BMPClass.WriteBMPFile(FN);
END.
