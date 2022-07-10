unit uModel;
{$MODE objfpc}
{$INLINE ON}
{$modeswitch advancedrecords}
interface
uses SysUtils,Classes,uVect,math;


const
  eps            = 1e-4;
  INF            = 1e20;
  M_1_PI         = 1/pi;
  M_2PI          = 2*pi;
  DefaultSamples = 16;
type

  VertexRecord=record
    cf:VecRecord;
    p,n:VecRecord;
    rad2:real;
    id:integer;
  //omega,ts,tr,preTR,preRad2:real;//debug
  end;

  ModelClass=class
    p,e,c:VecRecord;// position. emission,color
    refl:RefType;
    isLight:boolean;
    constructor Create(p_,e_,c_:VecRecord;refl_:RefType);
    function intersect(const r:RayRecord):real;virtual;abstract;
    function GetNorm(x:VecRecord):VecRecord;virtual;abstract;
  end;

  SphereClass=class(ModelClass)
    rad:real;       //radius
    rad2:real;
    constructor Create(rad_:real;p_,e_,c_:VecRecord;refl_:RefType);
    function intersect(const r:RayRecord):real;override;
    function GetNorm(x:VecRecord):VecRecord;override;
  end;

  RectClass=class(ModelClass)
    H1,H2,V1,V2:Real;
    RA:RectAxisType;
    constructor Create(RA_:RectAxisType;H1_,H2_,V1_,V2_:real;p_,e_,c_:VecRecord;refl_:RefType);
    function intersect(const r:RayRecord):real;override;
    function GetNorm(x:VecRecord):VecRecord;override;
  end;


  RectAngleClass=class(ModelClass)
    RAary:array[0..5] of RectClass;
    HitID:integer;
    constructor Create(p1,p2,e_,c_:VecRecord;refl_:RefType);
    function intersect(const r:RayRecord):real;override;
    function GetNorm(x:VecRecord):VecRecord;override;
  end;

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

  SceneRecord=record
    SceneName : string;
    mdl       : TList;
    cam       : CameraRecord;
  end;


procedure InitScene(w,h:integer);
function Intersect(const r:RayRecord;var t:real; var id:integer):boolean;

var
  mdl:TList;
  cam:CameraRecord;
implementation
function Intersect(const r:RayRecord;var t:real; var id:integer):boolean;
var
  d:real;
  i:integer;
begin
  t:=INF;
  for i:=0 to mdl.count-1 do begin
    d:=SphereClass(mdl[i]).intersect(r);
    if d<t then begin
      t:=d;
      id:=i;
    end;
  end;
  result:=(t<inf);
end;

procedure InitScene(w,h:integer);
begin
   mdl:=TList.Create;
   mdl.add( SphereClass.Create(1e5, CreateVec( 1e5+1,40.8,81.6),  ZeroVec,CreateVec(0.75,0.25,0.25),DIFF) );//Left
   mdl.add( SphereClass.Create(1e5, CreateVec(-1e5+99,40.8,81.6), ZeroVec,CreateVec(0.25,0.25,0.75),DIFF) );//Right
   mdl.add( SphereClass.Create(1e5, CreateVec(50,40.8, 1e5),      ZeroVec,CreateVec(0.75,0.75,0.75),DIFF) );//Back
   mdl.add( SphereClass.Create(1e5, CreateVec(50,40.8,-1e5+170+eps),ZeroVec,CreateVec(0,0,0)       ,DIFF) );//Front
   mdl.add( SphereClass.Create(1e5, CreateVec(50, 1e5, 81.6),     ZeroVec,CreateVec(0.75,0.75,0.75),DIFF) );//Bottomm
   mdl.add( SphereClass.Create(1e5, CreateVec(50,-1e5+81.6,81.6), ZeroVec,CreateVec(0.75,0.75,0.75),DIFF) );//Top
   mdl.add( SphereClass.Create(16.5,CreateVec(27,16.5,47),        ZeroVec,CreateVec(1,1,1)*0.999,   SPEC) );//Mirror
   mdl.add( SphereClass.Create(16.5,CreateVec(73,16.5,88),        ZeroVec,CreateVec(1,1,1)*0.999,   REFR) );//Glass
   mdl.add( SphereClass.Create(600,CreateVec(50,681.6-0.27,81.6), CreateVec(4,4,4),   ZeroVec,  DIFF) );//Ligth
   Cam.Setup(CreateVec(50,52,295.6),CreateVec(0,-0.042612,-1),w,h,0.5135,140);
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


  constructor ModelClass.Create(p_,e_,c_:VecRecord;refl_:RefType);
  begin
    p:=p_;e:=e_;c:=c_;refl:=refl_;if VecSQR(e)>0 then isLight:=TRUE else isLight:=false;
  end;
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
    if det<0 then 
      result:=INF
    else begin
      det:=sqrt(det); t:=b-det;
      if t>eps then 
         result:=t
      else begin
         t:=b+det;
         if t>eps then 
          result:=t
         else
          result:=INF;
      end;
    end;
  end;
  function SphereClass.GetNorm(x:VecRecord):VecRecord;
  begin
    result:=VecNorm(x-p)
  end;

  constructor RectClass.Create(RA_:RectAxisType;H1_,H2_,V1_,V2_:real;p_,e_,c_:VecRecord;refl_:RefType);
  begin
    RA:=RA_;H1:=H1_;H2:=H2_;V1:=V1_;V2:=V2_;inherited create(p_,e_,c_,refl_);
  end;
  function RectClass.intersect(const r:RayRecord):real;
  var
    t:real;
    pt:VecRecord;
  begin
    (**光線と平行に近い場合の処理が必要だが・・・**)
    case RA of
      xy:begin
            result:=INF;
            if abs(r.d.z)<eps then exit;
            t:=(p.z-r.o.z)/r.d.z;
            if t<eps then exit;//result is INF
            pt:=r.o+r.d*t;
            if (pt.x<H2) and (pt.x>H1) and (pt.y<V2)and (pt.y>V1) then result:=t;
          end;(*xy*)
      xz:begin
            result:=INF;
            if abs(r.d.y)<eps then exit;
            t:=(p.y-r.o.y)/r.d.y;
            if t<eps then exit;//result is INF
            pt:=r.o+r.d*t;
            if (pt.x<H2) and (pt.x>H1) and (pt.z<V2)and (pt.z>V1) then result:=t;
          end;(*xz*)
      yz:begin
            result:=INF;
            if abs(r.d.y)<eps then exit;
            t:=(p.x-r.o.x)/r.d.x;
            if t<eps then exit;//result is INF
            pt:=r.o+r.d*t;
            if (pt.y<H2) and (pt.y>H1) and (pt.z<V2)and (pt.z>V1) then result:=t;
          end;(*yz*)
    end;(*case*)
  end;

  function RectClass.GetNorm(x:VecRecord):VecRecord;
  begin
    case RA of
      xy:result:=CreateVec(0,0,1);
      xz:result:=CreateVec(0,1,0);
      yz:result:=CreateVec(1,0,0);
    end;
  end;

constructor RectAngleClass.Create(p1,p2,e_,c_:VecRecord;refl_:RefType);
begin
  inherited create(p2,e_,c_,refl_);
  (*xy*)
  RAary[0]:=RectClass.Create(XY,p1.x,p2.x,p1.y,p2.y,p1,e_,c_,refl_);
  RAary[1]:=RectClass.Create(XY,p1.x,p2.x,p1.y,p2.y,p2,e_,c_,refl_);
  (*xz*)
  RAary[2]:=RectClass.Create(XZ,p1.x,p2.x,p1.z,p2.z,p1,e_,c_,refl_);
  RAary[3]:=RectClass.Create(XZ,p1.x,p2.x,p1.z,p2.z,p2,e_,c_,refl_);
  (*YZ*)
  RAary[4]:=RectClass.Create(YZ,p1.y,p2.y,p1.z,p2.z,p1,e_,c_,refl_);
  RAary[5]:=RectClass.Create(YZ,p1.y,p2.y,p1.z,p2.z,p2,e_,c_,refl_);  
end;

function RectAngleClass.intersect(const r:RayRecord):real;
var
  i:integer;
  d,t:real;
begin
  t:=INF;HitID:=-1;
  for i:=0 to 5 do begin
    d:=RAary[i].intersect(r);
    if d<t then begin
      t:=d;
      HitID:=i;
    end;
  end;
  result:=t;
end;

function RectAngleClass.GetNorm(x:VecRecord):VecRecord;
begin
  result:=RAary[HitID].GetNorm(x);
end;



begin
end.



