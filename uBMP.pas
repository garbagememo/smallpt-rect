UNIT uBMP;
{$MODE objfpc}{$H+}
INTERFACE
USES Classes,SysUtils,uVect,math;

CONST
    MaxArrayNum=1024*1024*2*2;
    AllocMemSize=1024*1024*3+5120;

TYPE
    rgbColor=RECORD b,g,r:BYTE; END;

    BMPArray=ARRAY[0..MaxArrayNum*3] OF BYTE;
    BMPIOClass=CLASS
      bmpBodySize:LONGINT;
      BMPWidth,BMPHeight:LONGINT;
      bmpfileheader : packed ARRAY[0..14-1] OF BYTE;
      bmpinfoheader : packed ARRAY[0..40-1] OF BYTE;
      bmpBody:BMPArray;
      CONSTRUCTOR Create(x,y:INTEGER);virtual;
      PROCEDURE SetPixel(x,y:INTEGER;col:rgbColor);
      PROCEDURE WriteBMPFile(FN:string);
    END;

   FUNCTION ClampVector(v:VecRecord):VecRecord;
   FUNCTION ColToRGB(v:VecRecord):rgbColor;
IMPLEMENTATION
CONSTRUCTOR BMPIOClass.Create(x,y:LONGINT);
VAR
  headersize, bfSize : LONGINT;
  bits_per_pixel, cmap_entries : INTEGER;
  i:INTEGER;
BEGIN
   BMPWidth:=x;BMPHeight:=y;
   bits_per_pixel := 24;
   cmap_entries := 0;
   headersize:=14+40;
   bfsize:=headersize+LONGINT(x*y)*3;
   bmpBodySize:=bfSize;
   FOR i:=0 TO 14-1 DO bmpfileheader[i]:=0;
   FOR i:=0 TO 40-1 DO bmpinfoheader[i]:=0;

  { Fill the file header }
   bmpfileheader[0] := $42;	{ first 2 bytes are ASCII 'B', 'M' }
   bmpfileheader[1] := $4D;
  {PUT_4B(bmpfileheader, 2, bfSize);} { bfSize }
	 bmpfileheader[2] := BYTE ((bfSize) AND $FF);
	 bmpfileheader[2+1] := BYTE (((bfSize) shr 8) AND $FF);
	 bmpfileheader[2+2] := BYTE (((bfSize) shr 16) AND $FF);
	 bmpfileheader[2+3] := BYTE (((bfSize) shr 24) AND $FF);
  { we leave bfReserved1 & bfReserved2 = 0 }
  {PUT_4B(bmpfileheader, 10, headersize);} { bfOffBits }
	 bmpfileheader[10] := BYTE (headersize AND $FF);
	 bmpfileheader[10+1] := BYTE ((headersize shr 8) AND $FF);
	 bmpfileheader[10+2] := BYTE ((headersize shr 16) AND $FF);
	 bmpfileheader[10+3] := BYTE ((headersize shr 24) AND $FF);

  { Fill the info header (Microsoft calls this a BITMAPINFOHEADER) }
  {PUT_2B(bmpinfoheader, 0, 40);}   { biSize }
	 bmpinfoheader[0] := BYTE ((40) AND $FF);
	 bmpinfoheader[0+1] := BYTE (((40) shr 8) AND $FF);

  {PUT_4B(bmpinfoheader, 4, cinfo^.output_width);} { biWidth }
         bmpinfoheader[4] := BYTE ((x) AND $FF);
         bmpinfoheader[4+1] := BYTE ((x shr 8) AND $FF);
         bmpinfoheader[4+2] := BYTE ((x shr 16) AND $FF);
         bmpinfoheader[4+3] := BYTE ((x shr 24) AND $FF);
  {PUT_4B(bmpinfoheader, 8, cinfo^.output_height);} { biHeight }
         bmpinfoheader[8] := BYTE (y AND $FF);
         bmpinfoheader[8+1] := BYTE ((y shr 8) AND $FF);
         bmpinfoheader[8+2] := BYTE ((y shr 16) AND $FF);
         bmpinfoheader[8+3] := BYTE ((y shr 24) AND $FF);
  {PUT_2B(bmpinfoheader, 12, 1);}	{ biPlanes - must be 1 }
         bmpinfoheader[12] := BYTE (1 AND $FF);
         bmpinfoheader[12+1] := BYTE ((1 shr 8) AND $FF);

  {PUT_2B(bmpinfoheader, 14, bits_per_pixel);} { biBitCount }
         bmpinfoheader[14] := BYTE (bits_per_pixel AND $FF);
         bmpinfoheader[14+1] := BYTE ((bits_per_pixel shr 8) AND $FF);
  { we leave biCompression = 0, for none }
  { we leave biSizeImage = 0; this is correct for uncompressed data }
  { we leave biClrImportant := 0 }

END;

PROCEDURE BMPIOClass.SetPixel(x,y:INTEGER;col:rgbColor);
BEGIN
   bmpBody[(y*BMPWidth+x)*3  ]:=col.b;
   bmpBody[(y*BMPWidth+x)*3+1]:=col.g;
   bmpBody[(y*BMPWidth+x)*3+2]:=col.r;

END;

PROCEDURE BMPIOClass.WriteBMPFile(FN:string);
VAR
   B : file;
BEGIN
   Assign(B,FN);rewrite(B,1);
   BlockWrite(B,bmpfileheader,14);
   Blockwrite(B,bmpInfoheader,40);
   blockwrite(b,bmpBody,bmpBodySize);
    Close(b);
END;
FUNCTION Clamp(x:real):real;inline;
BEGIN
   IF x<0 THEN EXIT(0);
   IF x>1 THEN EXIT(1);
   EXIT(x);
END;

FUNCTION ClampVector(v:VecRecord):VecRecord;
BEGIN
  result.x:=clamp(v.x);
  result.y:=clamp(v.y);
  result.z:=clamp(v.z);
END;
FUNCTION ColToByte(x:real):BYTE;inline;
BEGIN
    result:=trunc(power(x,1/2.2)*255+0.5);
END;
FUNCTION ColToRGB(v:VecRecord):rgbColor;
BEGIN
    result.r:=ColToByte(v.x);
    result.g:=ColToByte(v.y);
    result.b:=ColToByte(v.z);
END;

BEGIN
END.
{ test code

var
   BMPIO : BMPIOClass;
   Vcolor : rgbColor;
   yAxis,xAxis: integer;
begin
   Vcolor.r:=$FF;Vcolor.g:=$0;Vcolor.b:=0;
   BMPIO:=BMPIOClass.Create(512,512);
   for yAxis:=0 to BMPIO.bmpHeight-1 do
      for xAxis:=0 to BMPIO.bmpWidth-1 do begin
	 vColor.r:= round( (yAxis/BMPIO.bmpWidth) *255);
	 vColor.g:=round((xAxis/BMPIO.bmpHeight)*255);
         vColor.b:=128;
         BMPIO.SetPixel(xAxis,yAxis,vColor);
      end;
    BMPIO.WriteBMPFile('test.bmp');
end.
//$Log: WriteBMP.pas,v $
//Revision 1.3  2017/08/27 06:30:43  average
//上下反転にした
//
//Revision 1.2  2017/08/26 14:50:31  average
//Unixのビットマップと違うみたいなので、上下を反転
//
//Revision 1.1  2016/11/22 16:03:11  average
//Initial revision
//

//
}
