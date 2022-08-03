unit uLightPath;

{$MODE objfpc}{$H+}
{$INLINE ON}
{$modeswitch advancedrecords}
interface
uses SysUtils,Classes,uVect,uModel,uFlux,Math;

const 
 LightPathMax=5;
type 
  LightPathRecord=record
    LPMax:integer;
    Ary:array[0..LightPathMax] of VertexRecord;
    procedure clear;
    procedure Add(V_:VertexRecord);
  end;

  LightPathList=record
    LMax:integer;
    ary:array[0..255] of LightPathRecord;
    mdl:TList;
    procedure Clear;
    procedure Add(LP : LightPathRecord);
  end;

  TLightPathFluxClass=Class(TFluxClass)
    LP:LightPathRecord;
    LPList:LightPathList;
    procedure CreateLightPath;
    function Radiance( r:RayRecord;depth:INTEGER):VecRecord;override;
  end;


implementation

procedure LightPathRecord.clear;
begin
  LPMax:=-1;
end;

procedure LightPathRecord.Add(V_:VertexRecord);
begin
  inc(LPMax);
  if LPMax>4 then begin
    writeln('Over List!');
    halt(0);
  end;
  ary[LPMax]:=v_;
end;

procedure LightPathList.Clear;
begin
  LMax:=-1;
end;

procedure LightPathList.Add(LP : LightPathRecord);
begin
  Inc(LMax);
  Ary[LMax]:=LP;
end;

procedure TLightPathFluxCLass.CreateLightPath;
var
  tVert,cV:VertexRecord;
  i,depth,k:integer;
  r:RayRecord;
  id:integer;
  obj:SphereClass;
  x,n,f,nl,u,v,w,d:VecRecord;
  p,r1,r2,r2s,t,ss,cc,nrd,OMEGA,cos_a_max:real;
  into:boolean;
  RefRay:RayRecord;
  nc,nt,nnt,ddn,cos2t,q,a,b,c,R0,Re,RP,Tr,TP,ts:real;
  tDir:VecRecord;
  tu,tv,sw:VecRecord;
  cl,cf:VecRecord;
begin
  LPList.Clear;
  for i:=0 to mdl.Count-1 do begin
    if ModelClass(mdl[i]).isLight then begin
      tVert:=ModelClass(mdl[i]).CreateLight(i,cam.o);
      LP.Clear;
      LP.Add(tVert);
      r.d:=tVert.n;//CreateLightで帳尻を合わせる予定。現在は球であるからこその省略
      r.o:=tVert.p;
      depth:=1;
      repeat
        cf:=tVert.cf;
//球以外無視する雑な構成
        if (ModelClass(mdl[i]) is SphereClass)=false then break;
        
        if intersect(r,t,id) =false then BREAK;
//get radiance
        obj:=SphereClass(mdl[id]);
        if obj.isLight then Break;
        x:=r.o+r.d*t; n:=VecNorm(x-obj.p); f:=obj.c;
        nrd:=n*r.d;
        if nrd<0 then nl:=n else nl:=n*-1;
        cV.p:=x;cV.n:=nl;cV.id:=id;
        if (f.x>f.y)and(f.x>f.z) then 
          p:=f.x
        else if f.y>f.z then 
          p:=f.y
        else
          p:=f.z;


        cf:=VecMul(cf,f);
        case obj.refl of
          DIFF:begin
            r1:=M_2PI*random;r2:=random;r2s:=sqrt(r2);
            w:=nl;
            if abs(w.x)>0.01 then u:=VecNorm(CreateVec(0,1,0)/w) else u:=VecNorm(CreateVec(1,0,0)/w);
            v:=w/u;
            sincos(r1,ss,cc);
            u:=u*(cc*r2s);v:=v*(ss*r2s);w:=w*(sqrt(1-r2));
            d:=VecNorm( VecAdd3(u,v,w) );
            r:=CreateRay(x,d)
          end;(*DIFF*)
          SPEC:begin
//            tv:=n*2*nrd ;tv:=r.d-tv;
            r:=CreateRay(x,(r.d-(n*2*nrd) ) );
          end;(*SPEC*)
          REFR:begin
//            tv:=n*2*nrd ;tv:=r.d-tv;
            RefRay:=CreateRay(x,(r.d-(n*2*nrd) ) );
            into:= (n*nl>0);
            nc:=1;nt:=1.5; if into then nnt:=nc/nt else nnt:=nt/nc; ddn:=r.d*nl;
            cos2t:=1-nnt*nnt*(1-ddn*ddn);
            if cos2t<0 then begin   // Total internal reflection
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
              r:=RefRay;
            end
            else begin//屈折
              cf:=cf*TP;
              r:=CreateRay(x,tdir);
            end
          end;(*REFR*)
        end;(*CASE*)

//OMEGA 算出
        if obj.REFL=DIFF then begin
          sw:=r.d;
          tr:=VecSQR(SphereClass(mdl[tVert.id]).p-x);
          tr:=SphereClass(mdl[tVert.id]).rad2/tr;
          ts:=sw*cV.n;
          if ts<0 then ts:=-ts;
          if tr>1 then begin
              (*半球内部なら乱反射した寄与全てを取ればよい・・はず*)
            OMEGA:=1;
          end
          else begin //半球外部の場合;
            cos_a_max := sqrt(1-tr );
            OMEGA := 2*PI*(1-cos_a_max)/PI;// 1/pi for brdf
            OMEGA:=OMEGA*ts;
          end;
    //OMEGA算出
          cf:=cf*OMEGA;
        end;
        cV.cf:=cf;
        LP.Add( cV);
        tVert:=cV;
        Inc(Depth)
      until Depth>=LightPathMax;
      LPList.Add(LP);
    end;(*is Light*)
  end;(*obj毎*)
end;
  
function TLightPathFluxClass.Radiance( r:RayRecord;depth:INTEGER):VecRecord;
VAR
  id,i,j,tid:INTEGER;
  obj,s:SphereClass;
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
  LPRec:LightPathRecord;
  tVert:VertexRecord;
  FUNCTION GetLightPathEvent:VecRecord;
  VAR
    i,j:INTEGER;
    tRay:RayRecord;
    ts:real;
  BEGIN
    result:=ZeroVec;tid:=id;
    FOR i:=0 TO LPList.LMax DO BEGIN
      LPRec:=LPList.Ary[i];
      FOR j:=0 TO LPRec.LPMax DO BEGIN
        tVert:=LPRec.Ary[j];
        IF tVert.id=tid THEN continue;//光源だったら飛ばすに変えるべき
        s:=SphereClass(mdl[tVert.id]);
        sw:=VecNorm(tVert.p-x);
        tRay.d:=sw;tRay.o:=x;
        IF sw*nl<0 THEN continue;//裏側につきぬけないように
        IF intersect(tRay,t,id)=FALSE THEN continue;
        IF id<>tVert.id THEN CONTINUE;//影がある？
        tr:=VecSQR(s.p-x);//ここが怖いところ。
        tr:=tVert.rad2/tr;
        ts:=sw*tVert.n;
        IF ts<0 THEN ts:=-ts;//球の表裏で変わるので・・・・
        IF tr>1 THEN BEGIN
          result:=result+VecMul(f,tVert.cf*ts );
        END
        ELSE BEGIN
          cos_a_max := sqrt(1-tr );
          omega := 2*PI*(1-cos_a_max);
          result:=result + VecMul(f,(tVert.cf*ts*omega))*M_1_PI;// 1/pi for brdf
        END;
      END;
    END;
  END;
BEGIN
  LPList.Clear;
  CreateLightPath;//////LPL
//writeln(' DebugY=',DebugY,' DebugX=',DebugX);
  depth:=0;
  id:=0;cl:=ZeroVec;cf:=CreateVec(1,1,1);E:=1;
  WHILE (TRUE) DO BEGIN
    Inc(depth);
    IF intersect(r,t,id)=FALSE THEN BEGIN
       result:=cl;
       EXIT;
    END;
    obj:=SphereClass(mdl[id]);
    x:=r.o+r.d*t; n:=VecNorm(x-obj.p); f:=obj.c;
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
        r1:=M_2PI*random;r2:=random;r2s:=sqrt(r2);
        w:=nl;
        IF abs(w.x)>0.01 THEN
          u:=VecNorm(CreateVec(0,1,0)/w)
        ELSE BEGIN
          u:=VecNorm(CreateVec(1,0,0)/w);
        END;
        v:=w/u;

        sincos(r1,ss,cc);
        u:=u*(cc*r2s);v:=v*(ss*r2s);w:=w*(sqrt(1-r2));
        d:=VecNorm((u+v)+w);

//        EL:=GetNextEvent;
        EL:=GetLightPathEvent;
//        EL:=GetFirstLight;
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

begin
end.


