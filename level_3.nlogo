Extensions [gis]

globals [
  waters
  landcover
  amenity

  roads
  buildings

  destination
]

breed [vertices vertex]
breed [commuters commuter]

patches-own[
  center?

]

vertices-own [
  jam?
  entrance?

  visited?

  commuters-visited
  commuters-cost
  commuters-pre-pointers
]

commuters-own [
  strategy

  path
  path-cost

  foundGoal?
  foundStart?

  current-traverse
  myorder
  frontier
  myroot
]

to setup
  ca
  reset-ticks
  import-scenes
  import-buildings
  import-roads

  import-scenes
  import-buildings
  import-roads

  set destination nobody
  set-entrances
end

to import-scenes
  if map-type = "Tokyo_Japan"[
    set waters gis:load-dataset "map/1/water_areas-polygon.shp"
    set landcover gis:load-dataset "map/1/landcover-polygon.shp"
    set amenity gis:load-dataset "map/1/amenity_polygons-polygon.shp"
  ]
  if map-type = "Florida_American"[
    set waters gis:load-dataset "map/2/water_areas-polygon.shp"
    set landcover gis:load-dataset "map/2/landcover-polygon.shp"
    set amenity gis:load-dataset "map/2/amenity_polygons-polygon.shp"
  ]
  if map-type = "HoChiMinh_District-7_VietNam"[
    set waters gis:load-dataset "map/3/water_areas-polygon.shp"
    set landcover gis:load-dataset "map/3/landcover-polygon.shp"
    set amenity gis:load-dataset "map/3/amenity_polygons-polygon.shp"
  ]
  if map-type = "Changchun_China"[
    set waters gis:load-dataset "map/4/water_areas-polygon.shp"
    set landcover gis:load-dataset "map/4/landcover-polygon.shp"
    set amenity gis:load-dataset "map/4/amenity_polygons-polygon.shp"
  ]
  if map-type = "Kyiv_Ukraine"[
    set waters gis:load-dataset "map/5/water_areas-polygon.shp"
    set landcover gis:load-dataset "map/5/landcover-polygon.shp"
    set amenity gis:load-dataset "map/5/amenity_polygons-polygon.shp"
  ]

  gis:set-drawing-color 33 gis:fill landcover 3
  gis:set-drawing-color 133 gis:fill amenity 1
  gis:set-drawing-color cyan gis:fill waters 1
end

to import-buildings
  if map-type = "Tokyo_Japan"[
    set buildings gis:load-dataset "map/1/buildings-polygon.shp"
  ]
  if map-type = "Florida_American"[
    set buildings gis:load-dataset "map/2/buildings-polygon.shp"
  ]
  if map-type = "HoChiMinh_District-7_VietNam"[
    set buildings gis:load-dataset "map/3/buildings-polygon.shp"
  ]
  if map-type = "Changchun_China"[
    set buildings gis:load-dataset "map/4/buildings-polygon.shp"
  ]
  if map-type = "Kyiv_Ukraine"[
    set buildings gis:load-dataset "map/5/buildings-polygon.shp"
  ]

  gis:set-world-envelope gis:envelope-of buildings
  gis:set-drawing-color gray gis:fill buildings 1

  foreach gis:feature-list-of buildings [
    building ->
    let center gis:location-of gis:centroid-of building
    ask patch item 0 center item 1 center [
      set center? true
      ;set plabel gis:property-value building "name"
    ]
  ]
end

to import-roads

  if map-type = "Tokyo_Japan"[
    set roads gis:load-dataset "map/1/roads-line.shp"
  ]
  if map-type = "Florida_American"[
    set roads gis:load-dataset "map/2/roads-line.shp"
  ]
  if map-type = "HoChiMinh_District-7_VietNam"[
    set roads gis:load-dataset "map/3/roads-line.shp"
  ]
  if map-type = "Changchun_China"[
    set roads gis:load-dataset "map/4/roads-line.shp"
  ]
  if map-type = "Kyiv_Ukraine"[
    set roads gis:load-dataset "map/5/roads-line.shp"
  ]

  foreach gis:feature-list-of roads [
    road-feature ->
    foreach gis:vertex-lists-of road-feature [
      v ->

      ;in these vertex, traffic jam happen randomly
      let jam-roads random 100

      let pre-node-pointer nobody

      foreach v [
        node ->
        let location gis:location-of node
        if not empty? location [
          create-vertices 1 [
            set shape "star"
            set size 0.3
            set color brown
            set jam? false
            setxy item 0 location item 1 location

            ;traffic jam happen
            if jam-roads < rush-hours-probability[
              set-vertex-jam
            ]

            if pre-node-pointer != nobody [
              create-link-with pre-node-pointer

            ]

            set pre-node-pointer self
          ]
        ]
      ]
    ]
  ]
  delete-duplicates
  delete-not-connected

  reset-entire-path
end

to set-vertex-jam
  set shape "x"
  set size 0.8
  set color red
  set jam? true
end

to delete-duplicates
  ask vertices [
    if count vertices-here > 1[
      ask other vertices-here [
        ask myself [
          create-links-with other [link-neighbors] of myself
        ]
        die
      ]
    ]
  ]

end

to delete-not-connected
  ask vertices [set visited? false]
  ask one-of vertices [set visited? true]
  repeat 500 [
    ask vertices with [ visited? = true] [
      ask link-neighbors [
        set visited? true
      ]
    ]
  ]
  ask vertices with [ visited? = false][die]
end

to set-entrances
  ask patches with [center? = true][
    let entrance min-one-of vertices [distance myself]
    ask entrance [
      if not jam?[
        set entrance? true
        set shape "star"
        set size 0.8
        set color turquoise
      ]
    ]
  ]
end

to generate-commuters
  ask commuters[die]

  ask vertices[
    set commuters-visited []
    set commuters-cost []
    set commuters-pre-pointers []

    repeat number-of-commuters[
      set commuters-visited lput false commuters-visited
      set commuters-cost lput 0 commuters-cost
      set commuters-pre-pointers lput nobody commuters-pre-pointers
    ]
  ]

  ;;create the commuter agents
  let i 0
  let equal_distance 0
  create-commuters number-of-commuters [
    set color white
    set size 1.2
    set shape "person business"
    set path []
    set current-traverse nobody
    set myorder i
    set foundGoal? false
    set foundStart? false
    set i i + 1
    set label i
    set strategy ""

    let root one-of vertices with [ center? != true and one-of commuters-here = nobody ]
    ifelse equal_distance = 0[
      set equal_distance [distance destination] of root
    ] [
      set root one-of vertices with [ center? != true and one-of commuters-here = nobody and ([distance destination] of self - equal_distance > -1 and [distance destination] of self - equal_distance < 1)]
    ]

    set frontier []
    set myroot root
    set frontier lput root frontier
    move-to root

  ]
end

to rand-search-strategy
  let strategy-list ["GBFS" "A*" "UCS" "BFS" "DFS" "GBFS" "A*" "UCS" "BFS" "DFS"]

  ask commuters[
    set strategy item myorder strategy-list
    if strategy = "GBFS" [ set color yellow ]
    if strategy = "A*" [ set color violet ]
    if strategy = "UCS" [ set color blue ]
    if strategy = "BFS" [ set color green ]
    if strategy = "DFS" [ set color pink ]

    set label word word (myorder + 1) "." strategy
  ]
end

to generate-destination
  if destination != nobody [
    ask destination [
      set shape "star"
      set size 0.8
      set color turquoise
    ]
  ]

  set destination one-of vertices with [ entrance? = true ]
  ask destination [
    set shape "house"
    set size 1.5
    set color yellow

    watch-me
  ]
end

to clear-path
  ask commuters[
    set path []
    set path-cost 0
  ]
  reset-entire-path
end

to reset-entire-path
  ask links [set thickness 0.2 set color 23]
end

to find-path
  let isStop? true
  ask commuters[
    if foundStart? = false[set isStop? false]
  ]
  if isStop? = true[
    stop
  ]

  ask commuters[
    if strategy = "GBFS" [ gbfs self ]
    if strategy = "A*" [ a-star self ]
    if strategy = "UCS" [ ucs self ]
    if strategy = "BFS" [ bfs self ]
    if strategy = "DFS" [ dfs self ]

  ]

  tick
  wait delay
  display
end

to go
  ask commuters [
    let order myorder
    let cmter self

    if strategy != "" [
      ifelse not empty? path [
        set current-traverse first path
        set path but-first path

        move-to current-traverse
        if item order [commuters-pre-pointers] of current-traverse != nobody [
          ask link [who] of current-traverse [who] of item order [commuters-pre-pointers] of current-traverse  [set color orange set thickness 0.2]
        ]
      ][
;        ask vertices with [ item order commuters-visited = true or member? self [frontier] of cmter ][
;          let cur-vertice self
;          ask link-neighbors with [ item order commuters-visited = true or member? self [frontier] of cmter ][
;            ask link [who] of self [who] of cur-vertice  [set color orange set thickness 0.2]
;          ]
;        ]
      ]
    ]
  ]

  wait delay
  display
end

to gbfs [#commuter]
  ask #commuter [
    let cmter self
    let order myorder

    if destination != nobody [
      if not empty? frontier and foundGoal? = false [
        ;vertex which h is minimum is first chosen
        set frontier sort-by [[v1 v2] -> [distance destination] of v1 < [distance destination] of v2] frontier
        let current-vertice first frontier
        ask current-vertice [set commuters-visited replace-item order commuters-visited true]
        set frontier but-first frontier

        ;push successors which were not in the extended-state to frontier
        ask [link-neighbors] of current-vertice[
          let current_neighbor self

          if not item order commuters-visited and not member? current_neighbor [frontier] of cmter and not jam? and [foundGoal?] of cmter = false [
            set commuters-cost replace-item order commuters-cost (item order [commuters-cost] of current-vertice + distance current-vertice)
            set commuters-pre-pointers replace-item order commuters-pre-pointers current-vertice
            ask cmter[
              set frontier lput current_neighbor frontier
            ]
          ]

          if current_neighbor = destination[
            ask cmter[
              set foundGoal? true
              set current-traverse current_neighbor
            ]
          ]
        ]
      ]


      if foundGoal? = true and foundStart? = false[
        ifelse current-traverse != myroot [
          ask cmter[
            set path-cost path-cost + item order [commuters-cost] of current-traverse
            set path fput current-traverse path
            set current-traverse item order [commuters-pre-pointers] of current-traverse

            ask link [who] of current-traverse [who] of first path  [set color yellow set thickness 0.3]
          ]
        ] [
          set path fput myroot path
          set foundStart? true
        ]
      ]
    ]
  ]
end

to a-star [#commuter]
  ask #commuter [
    let cmter self
    let order myorder

    if destination != nobody [
      if not empty? frontier and foundGoal? = false [
        ;vertex which h is minimum is first chosen
        set frontier sort-by [[v1 v2] -> [distance destination] of v1 + item order [commuters-cost] of v1 < [distance destination] of v2 + item order [commuters-cost] of v2] frontier
        let current-vertice first frontier
        ask current-vertice [set commuters-visited replace-item order commuters-visited true]
        set frontier but-first frontier

        if current-vertice = destination[
          set foundGoal? true
          set current-traverse current-vertice
        ]

        ;push successors which were not in the extended-state to frontier
        ask [link-neighbors] of current-vertice[
          let current_neighbor self

          if not item order commuters-visited and not member? current_neighbor [frontier] of cmter and not jam? and [foundGoal?] of cmter = false [
            set commuters-cost replace-item order commuters-cost (item order [commuters-cost] of current-vertice + distance current-vertice)
            set commuters-pre-pointers replace-item order commuters-pre-pointers current-vertice
            ask cmter[
              set frontier lput current_neighbor frontier

            ]
          ]


        ]
      ]

      if foundGoal? = true and foundStart? = false[
        ifelse current-traverse != myroot [
          ask cmter[
            set path-cost path-cost + item order [commuters-cost] of current-traverse
            set path fput current-traverse path
            set current-traverse item order [commuters-pre-pointers] of current-traverse

            ask link [who] of current-traverse [who] of first path  [set color violet set thickness 0.3]
          ]
        ] [
          set path fput myroot path
          set foundStart? true
        ]
      ]
    ]
  ]
end

to ucs [#commuter]
  ask #commuter [
    let cmter self
    let order myorder

    if destination != nobody [
      if not empty? frontier and foundGoal? = false [
        ;vertex which h is minimum is first chosen
        set frontier sort-by [[v1 v2] -> item order [commuters-cost] of v1 < item order [commuters-cost] of v2] frontier
        let current-vertice first frontier
        ask current-vertice [set commuters-visited replace-item order commuters-visited true]
        set frontier but-first frontier

        if current-vertice = destination[
          set foundGoal? true
          set current-traverse current-vertice
        ]

        ;push successors which were not in the extended-state to frontier
        ask [link-neighbors] of current-vertice[
          let current_neighbor self

          if not item order commuters-visited and not member? current_neighbor [frontier] of cmter and not jam? and [foundGoal?] of cmter = false [
            set commuters-cost replace-item order commuters-cost (item order [commuters-cost] of current-vertice + distance current-vertice)
            set commuters-pre-pointers replace-item order commuters-pre-pointers current-vertice
            ask cmter[
              set frontier lput current_neighbor frontier
            ]
          ]


        ]
      ]

      if foundGoal? = true and foundStart? = false[
        ifelse current-traverse != myroot [
          ask cmter[
            set path-cost path-cost + item order [commuters-cost] of current-traverse
            set path fput current-traverse path
            set current-traverse item order [commuters-pre-pointers] of current-traverse

            ask link [who] of current-traverse [who] of first path  [set color blue set thickness 0.3]
          ]
        ] [
          set path fput myroot path
          set foundStart? true
        ]
      ]
    ]
  ]
end

to bfs [#commuter]
  ask #commuter [
    let cmter self
    let order myorder

    if destination != nobody [
      if not empty? frontier and foundGoal? = false [
        let current-vertice first frontier
        ask current-vertice [set commuters-visited replace-item order commuters-visited true]
        set frontier but-first frontier

        ;push successors which were not in the extended-state to frontier
        ask [link-neighbors] of current-vertice[
          let current_neighbor self

          if not item order commuters-visited and not member? current_neighbor [frontier] of cmter and not jam? and [foundGoal?] of cmter = false [
            set commuters-cost replace-item order commuters-cost (item order [commuters-cost] of current-vertice + distance current-vertice)
            set commuters-pre-pointers replace-item order commuters-pre-pointers current-vertice
            ask cmter[
              set frontier lput current_neighbor frontier
            ]
          ]

          if current_neighbor = destination[
            ask cmter[
              set foundGoal? true
              set current-traverse current_neighbor
            ]
          ]
        ]
      ]


      if foundGoal? = true and foundStart? = false[
        ifelse current-traverse != myroot [
          ask cmter[
            set path-cost path-cost + item order [commuters-cost] of current-traverse
            set path fput current-traverse path
            set current-traverse item order [commuters-pre-pointers] of current-traverse

            ask link [who] of current-traverse [who] of first path  [set color green set thickness 0.3]
          ]
        ] [
          set path fput myroot path
          set foundStart? true
        ]
      ]
    ]
  ]
end

to dfs [#commuter]
  ask #commuter [
    let cmter self
    let order myorder

    if destination != nobody [
      if not empty? frontier and foundGoal? = false [
        let current-vertice first frontier
        ask current-vertice [set commuters-visited replace-item order commuters-visited true]
        set frontier but-first frontier

        ;push successors which were not in the extended-state to frontier
        ask [link-neighbors] of current-vertice[
          let current_neighbor self

          if not item order commuters-visited and not member? current_neighbor [frontier] of cmter and not jam? and [foundGoal?] of cmter = false [
            set commuters-cost replace-item order commuters-cost (item order [commuters-cost] of current-vertice + distance current-vertice)
            set commuters-pre-pointers replace-item order commuters-pre-pointers current-vertice
            ask cmter[
              set frontier fput current_neighbor frontier
            ]
          ]

          if current_neighbor = destination[
            ask cmter[
              set foundGoal? true
              set current-traverse current_neighbor
            ]
          ]
        ]
      ]


      if foundGoal? = true and foundStart? = false[
        ifelse current-traverse != myroot [
          ask cmter[
            set path-cost path-cost + item order [commuters-cost] of current-traverse
            set path fput current-traverse path
            set current-traverse item order [commuters-pre-pointers] of current-traverse

            ask link [who] of current-traverse [who] of first path  [set color pink set thickness 0.3]
          ]
        ] [
          set path fput myroot path
          set foundStart? true
        ]
      ]
    ]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
199
64
1337
645
-1
-1
13.95122
1
10
1
1
1
0
0
0
1
-40
40
-20
20
1
1
1
ticks
30.0

BUTTON
9
103
105
136
Create Map
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
10
182
182
215
number-of-commuters
number-of-commuters
1
10
10.0
1
1
NIL
HORIZONTAL

BUTTON
20
254
167
287
generate destination
generate-destination
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
27
666
154
699
Go to Destination
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

TEXTBOX
33
416
172
434
color of GBFS: yellow
11
0.0
1

TEXTBOX
33
440
183
458
color of A*: violet
11
0.0
1

TEXTBOX
33
516
183
534
color of DFS: pink
11
0.0
1

TEXTBOX
33
466
183
484
color of UCS: blue
11
0.0
1

TEXTBOX
33
490
183
508
color of BFS: green
11
0.0
1

SLIDER
10
143
182
176
delay
delay
0
1
0.0
0.1
1
seconds
HORIZONTAL

BUTTON
20
294
166
327
generate commuters
generate-commuters
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
27
622
122
655
reset roads
clear-path
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
19
333
181
366
random search strategy
rand-search-strategy
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
28
536
180
569
Find path respectively
find-path
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SLIDER
9
63
196
96
rush-hours-probability
rush-hours-probability
0
100
0.0
1
1
%
HORIZONTAL

CHOOSER
9
12
204
57
map-type
map-type
"Tokyo_Japan" "Florida_American" "HoChiMinh_District-7_VietNam" "Changchun_China" "Kyiv_Ukraine"
2

BUTTON
110
104
185
138
unfocus
reset-perspective
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
1027
12
1235
57
number of commuters arrived home
count [commuters-here] of destination
17
1
11

MONITOR
437
15
717
60
min path cost
[path-cost] of min-one-of commuters with [path-cost != 0] [path-cost]
17
1
11

MONITOR
720
15
817
60
search strategy
[strategy] of min-one-of commuters with [path-cost != 0] [path-cost]
17
1
11

BUTTON
823
23
1020
57
focus min path cost commuter
watch min-one-of commuters with [path-cost != 0] [path-cost]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
1239
14
1571
460
Nodes in frontier
time
amount
0.0
10.0
0.0
100.0
true
true
"" ""
PENS
"1" 1.0 0 -1184463 true "" "let cmt one-of commuters with [myorder = 0]\n\nif count commuters > 0[\nplot (length [frontier] of cmt) + (count vertices with [ item 0 commuters-visited = true ])\n]"
"2" 1.0 0 -8630108 true "" "let cmt one-of commuters with [myorder = 1]\n\nif count commuters > 1[\nplot (length [frontier] of cmt) + (count vertices with [ item 1 commuters-visited = true ])\n]"
"3" 1.0 0 -13345367 true "" "let cmt one-of commuters with [myorder = 2]\n\nif count commuters > 2[\nplot (length [frontier] of cmt) + (count vertices with [ item 0 commuters-visited = true ])\n]"
"4" 1.0 0 -13840069 true "" "let cmt one-of commuters with [myorder = 3]\n\nif count commuters > 3[\nplot (length [frontier] of cmt) + (count vertices with [ item 0 commuters-visited = true ])\n]"
"5" 1.0 0 -2064490 true "" "let cmt one-of commuters with [myorder = 4]\n\nif count commuters > 4[\nplot (length [frontier] of cmt) + (count vertices with [ item 0 commuters-visited = true ])\n]"
"6" 1.0 0 -1184463 true "" "let cmt one-of commuters with [myorder = 5]\n\nif count commuters > 5[\nplot (length [frontier] of cmt) + (count vertices with [ item 0 commuters-visited = true ])\n]"
"7" 1.0 0 -8630108 true "" "let cmt one-of commuters with [myorder = 6]\n\nif count commuters > 6[\nplot (length [frontier] of cmt) + (count vertices with [ item 0 commuters-visited = true ])\n]"
"8" 1.0 0 -13345367 true "" "let cmt one-of commuters with [myorder = 7]\n\nif count commuters > 7[\nplot (length [frontier] of cmt) + (count vertices with [ item 0 commuters-visited = true ])\n]"
"9" 1.0 0 -13840069 true "" "let cmt one-of commuters with [myorder = 8]\n\nif count commuters > 8[\nplot (length [frontier] of cmt) + (count vertices with [ item 0 commuters-visited = true ])\n]"
"10" 1.0 0 -2064490 true "" "let cmt one-of commuters with [myorder = 9]\n\nif count commuters > 9[\nplot (length [frontier] of cmt) + (count vertices with [ item 0 commuters-visited = true ])\n]"

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

ambulance
false
0
Rectangle -7500403 true true 30 90 210 195
Polygon -7500403 true true 296 190 296 150 259 134 244 104 210 105 210 190
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Circle -16777216 true false 69 174 42
Rectangle -1 true false 288 158 297 173
Rectangle -1184463 true false 289 180 298 172
Rectangle -2674135 true false 29 151 298 158
Line -16777216 false 210 90 210 195
Rectangle -16777216 true false 83 116 128 133
Rectangle -16777216 true false 153 111 176 134
Line -7500403 true 165 105 165 135
Rectangle -7500403 true true 14 186 33 195
Line -13345367 false 45 135 75 120
Line -13345367 false 75 135 45 120
Line -13345367 false 60 112 60 142

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

person business
false
0
Rectangle -1 true false 120 90 180 180
Polygon -13345367 true false 135 90 150 105 135 180 150 195 165 180 150 105 165 90
Polygon -7500403 true true 120 90 105 90 60 195 90 210 116 154 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 183 153 210 210 240 195 195 90 180 90 150 165
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 76 172 91
Line -16777216 false 172 90 161 94
Line -16777216 false 128 90 139 94
Polygon -13345367 true false 195 225 195 300 270 270 270 195
Rectangle -13791810 true false 180 225 195 300
Polygon -14835848 true false 180 226 195 226 270 196 255 196
Polygon -13345367 true false 209 202 209 216 244 202 243 188
Line -16777216 false 180 90 150 165
Line -16777216 false 120 90 150 165

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.2
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
1
@#$#@#$#@
