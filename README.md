# smallpt-rect
99行パストレーサの直方体を導入。<br>
## 現状の状態は・・
回転は動いているようだが、実映像と比較できないので合ってるかわからない・・・<br>
LightPath（双方向パストレもどき）を直方体に拡張<br>
この版ではTFluxClassにmdlと置いているがScene構造体におしこむべきかな・・・
### 詳細は
TLightPathFluxClassにLPListをメンバに<br>
現在、RectAngleまではサポートしている。<br>
Rotateは未サポート

