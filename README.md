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
- To see more about map key , click [here](map_key.md)

> District 5, Ho Chi Minh, Viet Nam: <br>
Around areas <br>
![](map_from_satelite/HCM_District7_VietNam.png) <br>
Areas <br>
![](map_from_satelite/HCM_District7_VietNam_detail.png) <br>
Netlogo <br>
![](map_from_satelite/HCM_District7_VietNam_gis.png) <br>

<br>

> Kyiv capital, Ukraine: <br>
Around areas <br>
![](map_from_satelite/Kyiv_Ukraine.png) <br>
Areas <br>
![](map_from_satelite/Kyiv_Ukraine_detail.png) <br>
Netlogo <br> 
![](map_from_satelite/Kyiv_Ukraine_gis.png) <br>

<br>

> Tokyo, Japan: <br>
Around areas <br>
![](map_from_satelite/Tokyo_Japan.png) <br>
Areas <br>
![](map_from_satelite/Tokyo_Japan_detail.png) <br>
Netlogo <br>
![](map_from_satelite/Tokyo_Japan_gis.png) <br>

<br>

> Florida, American: <br>
Around areas <br>
![](map_from_satelite/Florida_America.png) <br>
Areas <br>
![](map_from_satelite/Florida_America_detail.png) <br>
Netlogo <br>
![](map_from_satelite/Florida_America_gis.png) <br>

<br>

> Changchun, China: <br>
Around areas <br>
![](map_from_satelite/Changchun_China.png) <br>
Areas <br>
![](map_from_satelite/Changchun_China_detail.png) <br>
Netlogo <br>
![](map_from_satelite/Changchun_China_gis.png) <br>

<br>

- We create 3 file with 3 level to operate easier. In 2 last level, we wanna find path in traffic jam situation. People have to avoid junctions where happen the jam ![](map_key/jam.PNG)

- Apply search strategies include `Greedy Best First Search`, `A*`, `Uniform Cost Search`, `Breadth First Search`, `Depth First Search`. ![](map_key/people.PNG) wanna go to ![](map_key/home.PNG). They find path by these search strategies: 
    - GBFS: ![](map_key/gbfs.PNG) 
    - A*: ![](map_key/a_star.PNG) 
    - UCS: ![](map_key/ucs.PNG)  
    - BFS: ![](map_key/bfs.PNG) 
    - DFS: ![](map_key/dfs.PNG)

- Some utility button:
    > Chose map which we imported: ![](images/button/maptype.PNG)

    > Chose probability for the happening of rush-hours at one junction: ![](images/button/rush_hours_probability.PNG)

    > Imitate reality map which you have chosen: ![](images/button/setup.PNG)

    > Chose delay when you observe the agents: ![](images/button/delay.PNG)

    > Randomly create people: ![](images/button/create_commuters.PNG)

    > Randomly create destination: ![](images/button/create_destination.PNG)

    > Focus one people: ![](images/button/focus.PNG)

    > Unfocus one people: ![](images/button/unfocus.PNG)

    > Find path by search strategies respectively: <br> ![](images/button/find_path.PNG)

    > Count number of people which arrived home: ![](images/button/arrived_home.PNG)

    > People have min path cost to home and his strategy: ![](images/button/min_cost.PNG) ![](images/button/strategy.PNG) 
    > <br> You can also focus on him: ![](images/button/focus_cmt_min_cost.PNG)

    > Clear all path: ![](images/button/reset_road.PNG)

    > Chose what strategy you want to go back home: ![](images/button/strategies.PNG)

    > Go home when you applied one of search strategies: ![](images/button/go.PNG)

- Level 3 we specially add the plot which compare the number of nodes in frontier of agents. It can help you to observe `time consuming` as well as how much `memory` which algorithms use <br>
![](images/button/plot.PNG)





    






