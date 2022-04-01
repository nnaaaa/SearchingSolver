# Apply Search Strategies to Netlogo

## 1. Introduction

- In [Netlogo](https://ccl.northwestern.edu/netlogo), we imitate the reality maps in the world by [GIS Extension](https://github.com/NetLogo/GIS-Extension) support by Netlogo. 
To simplify the maps, we only display some important entity such as 
    - land: ![](map_key/land.PNG)
    - water: ![](map_key/water.PNG)
    - buildings: ![](map_key/building.PNG)
    - roads: ![](map_key/road.PNG)
    - junction: ![](map_key/junction.PNG) 

- We apply search strategies to find the way to home for anonymous peoples and help them go back home as fast as possible


## 2. Implementation

- We need to find some location in [Open Street Map](https://openstreetmap.org), export and convert `file.osm` to `file.shp` and import them to Netlogo throw GIS Extension. Let compare the map which we imported to Netlogo and the map in open street map:

> District 5, Ho Chi Minh, Viet Nam: <br>
Around areas
![](map_from_satelite/HCM_District7_VietNam.png)
Areas
![](map_from_satelite/HCM_District7_VietNam_detail.png)
Netlogo
![](map_from_satelite/HCM_District7_VietNam_gis.png)

> Kyiv capital, Ukraine: <br>
Around areas
![](map_from_satelite/Kyiv_Ukraine.png)
Areas
![](map_from_satelite/Kyiv_Ukraine_detail.png)
Netlogo
![](map_from_satelite/Kyiv_Ukraine_gis.png)




- We create 3 file with 3 level to operate easier. In 2 last level, we wanna find path in traffic jam situation. People have to avoid junctions where happen the jam ![](map_key/jam.PNG)




