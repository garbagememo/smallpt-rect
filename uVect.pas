UNIT uVect;
{$MODE objfpc}{$H+}
{$INLINE ON}

INTERFACE

USES
    sysutils,math;
TYPE

  RefType=(DIFF,SPEC,REFR);// material types, used in radiance()
{
	DIFFUSE,    // 完全拡散面。いわゆるLambertian面。
	SPECULAR,   // 理想的な鏡面。
	REFRACTION, // 理想的なガラス的物質。
}
  
  RectAxisType=(XY,YZ,XZ);(*平面がどっち向いているか*)

  VecRecord=RECORD
    x,y,z:real;
  END;
  NormVecRecord=Record
    u,v,w:VecRecord;
  end;
  RayRecord=RECORD
    o, d:VecRecord;
  END;
  FUNCTION CreateRay(o_,d_:VecRecord):RayRecord;

CONST
   BackGroundColor:VecRecord = (x:0;y:0;z:0);
   ZeroVec:VecRecord = (x:0;y:0;z:0);
   OneVec:VecRecord=(x:1;y:1;z:1);
   
FUNCTION CreateVec(x_,y_,z_:real):VecRecord;
FUNCTION VecMul(CONST V1,V2:VecRecord):VecRecord;inline;
FUNCTION VecNeg(CONST V:VecRecord):VecRecord;inline;
FUNCTION VecSQR(CONST V:VecRecord):real;inline;
FUNCTION Veclen(V:VecRecord):real;inline;
FUNCTION VecNorm(V:VecRecord):VecRecord;inline;
FUNCTION VecDot(CONST V1,V2 :VecRecord):real;//内積
FUNCTION VecCross(CONST V1,V2 :VecRecord):VecRecord;//外積
FUNCTION VecAdd3(CONST V1,V2,V3:VecRecord):VecRecord;inline;
function GetNormVec(const l:VecRecord):NormVecRecord;inline;
FUNCTION VecSphereRef(const w:VecRecord):VecRecord;inline;(*vを法線に半球状に分布する光線を求める*)
PROCEDURE VecWriteln(V:VecRecord);

operator * (CONST v1:VecRecord;CONST r:real)v:VecRecord;inline;
operator / (CONST v1:VecRecord;CONST r:real)v:VecRecord;inline;
operator * (CONST v1,v2:VecRecord)r:real;inline;//内積
operator / (CONST v1,v2:VecRecord)v:VecRecord;inline;//外積

operator + (CONST v1,v2:VecRecord)v:VecRecord;inline;
operator - (CONST v1,v2:VecRecord)v:VecRecord;inline;
operator + (CONST v1:VecRecord;CONST r:real)v:VecRecord;inline;
operator - (CONST v1:VecRecord;CONST r:real)v:VecRecord;inline;

IMPLEMENTATION

FUNCTION CreateVec(x_,y_,z_:real):VecRecord;
BEGIN
    result.x:=x_;result.y:=y_;result.z:=z_;
END;
FUNCTION CreateRay(o_,d_:VecRecord):RayRecord;
BEGIN
    result.o:=o_;
    result.d:=d_;
END;

FUNCTION VecMul(CONST V1,V2:VecRecord):VecRecord;inline;
BEGIN
    result.x:=V1.x*V2.x;
    result.y:=V1.y*V2.y;
    result.z:=V1.z*V2.z;
END;

FUNCTION VecNeg(CONST V:VecRecord):VecRecord;inline;
BEGIN
    result.x:=-V.x;
    result.y:=-V.y;
    result.z:=-V.z;
END;
FUNCTION VecSQR(CONST V:VecRecord):real;inline;
BEGIN
  result:=V.x*V.x+V.y*V.y+V.z*V.z;
END;
FUNCTION Veclen(V:VecRecord):real;inline;
BEGIN
   result:=sqrt(V.x*V.x+V.y*V.y+V.z*V.z);
END;

FUNCTION VecNorm(V:VecRecord):VecRecord;inline;
BEGIN
    result:=V/VecLen(V) ;
END;
FUNCTION VecDot(CONST V1,V2 :VecRecord):real;//内積
BEGIN
    result:=v1.x*v2.x+v1.y*v2.y+v1.z*v2.z;
END;
FUNCTION VecCross(CONST V1,V2 :VecRecord):VecRecord;//外積
BEGIN
    result.x:=V1.y * v2.z - v2.y * V1.z;
    result.y:=V1.z * v2.x - v2.z * V1.x;
    result.z:=V1.x * v2.y - v2.x * V1.y;
END;
FUNCTION VecAdd3(CONST V1,V2,V3:VecRecord):VecRecord;inline;
BEGIN
    result.x:=V1.x+V2.x+V3.x;
    result.y:=V1.y+V2.y+V3.y;
    result.z:=V1.z+V2.z+V3.z;
    
END;
FUNCTION FtoSF(r:real):string;
VAR
  i,j:LONGINT;
BEGIN
  i:=5;j:=5;
  result:=FloatToStrf(r,ffFixed,I,J);
END;

PROCEDURE VecWriteln(V:VecRecord);
BEGIN
    WRITELN(v.x:8:2,' : ',v.y:8:2,' : ',v.z:8:2);
END;

function GetNormVec(const l:VecRecord):NormVecRecord;inline;
var
  r1,r2,r2s:real;
begin
  r1:=2*PI*random;r2:=random;r2s:=sqrt(r2);
  result.w:=l;
  if abs(result.w.x)>0.1 then
    result.u:=VecNorm(CreateVec(0,1,0)/result.w) 
  else
    result.u:=VecNorm(CreateVec(1,0,0)/result.w) ;
  result.v:=result.w/result.u;
end;
FUNCTION VecSphereRef(const w:VecRecord):VecRecord;inline;
var
  r1,r2,r2s:real;
  uvw:NormVecRecord;
begin
  uvw:=GetNormVec(w);
  result := VecNorm(uvw.u*cos(r1)*r2s + uvw.v*sin(r1)*r2s + uvw.w*sqrt(1-r2));
end;


operator * (CONST v1:VecRecord;CONST r:real)v:VecRecord;inline;
BEGIN
   v.x:=v1.x*r;
   v.y:=v1.y*r;
   v.z:=v1.z*r;
END;

operator / (CONST v1:VecRecord;CONST r:real)v:VecRecord;inline;
BEGIN
   v.x:=v1.x/r;
   v.y:=v1.y/r;
   v.z:=v1.z/r;
END;

operator * (CONST v1,v2:VecRecord)r:real;inline;//内積
BEGIN
   r:=v1.x*v2.x+v1.y*v2.y+v1.z*v2.z;
END;

operator / (CONST v1,v2:VecRecord)v:VecRecord;inline; //外積
BEGIN
    v.x:=V1.y * v2.z - v2.y * V1.z;
    v.y:=V1.z * v2.x - v2.z * V1.x;
    v.z:=V1.x * v2.y - v2.x * V1.y;
END;

operator + (CONST v1,v2:VecRecord)v:VecRecord;inline;
BEGIN
   v.x:=v1.x+v2.x;
   v.y:=v1.y+v2.y;
   v.z:=v1.z+v2.z;
END;

operator - (CONST v1,v2:VecRecord)v:VecRecord;inline;
BEGIN
    v.x:=v1.x-v2.x;
    v.y:=v1.y-v2.y;
    v.z:=v1.z-v2.z;
END;

operator + (CONST v1:VecRecord;CONST r:real)v:VecRecord;inline;
BEGIN
   v.x:=v1.x+r;
   v.y:=v1.y+r;
   v.z:=v1.z+r;
END;
operator - (CONST v1:VecRecord;CONST r:real)v:VecRecord;inline;
BEGIN
    v.x:=v1.x-r;
    v.y:=v1.y-r;
    v.z:=v1.z-r;
END;




BEGIN
END.
/*/$Log: rpdef.pas,v $
/*/Revision 2.2  2017/08/29 13:06:30  average
/*/とりあえず、徐々にBDPTの導入を始める
/*/
/*/Revision 2.1  2017/08/28 16:10:54  average
/*/設定ファイルの読み書き導入
/*/
/*/Revision 1.1  2017/08/28 13:05:49  average
/*/Initial revision
/*/
/*/Revision 1.5  2017/08/27 06:30:43  average
/*/Operator Inlineを導入
/*/
/*/Revision 1.4  2016/11/28 13:53:54  average
/*/変えた
/*/
//Revision 1.3  2016/11/23 13:04:34  average
//デバッグスタを入れる
//
//Revision 1.2  2016/11/22 16:02:48  average
//テストでんがな
////
