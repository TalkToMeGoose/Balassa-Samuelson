globals [
  UK-TG-Patches
  UK-TG-Price
  UK-TG-Wage
  UK-TG-MPL
  UK-NTG-Patches
  UK-NTG-Price
  UK-NTG-Wage
  UK-NTG-MPL
  PL-TG-Patches
  PL-TG-Price
  PL-TG-Wage
  PL-NTG-Patches
  PL-NTG-Price
  PL-NTG-Wage
  PL-NTG-MPL
]

breed [ workers worker ]
breed [ goods good ]

workers-own [
  age            ; how old the workers are. if older, they will be less likely to migrate [ to be added ]
  initiative     ; what their natural initiative is. this is moderated by age.
  migrating?     ; true when worker is currently migrating
  job-changer?   ; true when worker is currently in process of switching sectors
]

to setup
  clear-all
  setup-patches
  setup-turtles
  setup-parameters
  reset-ticks
end

to setup-patches   ; creates sectors for each country
  ask patches [set pcolor gray + 2 ]                                      ; sets background color
  ask patches with [ pxcor = 0 and pycor >= -2] [ set pcolor gray - 2 ]   ; visualizes immobility of labor between countries
  ask patches with [ pycor = 0 ] [ set pcolor gray - 2 ]                  ; visualizes immobility of labor between sectors
  open-close-border                                                       ; matches "barrier" visual with open and closed borders
  open-close-sectors                                                      ; matches "barrier" visual with open sector movement within countires
  set UK-TG-Patches patches with [pxcor < -4 and pycor > 2]               ; the following color the sector and country patches
  ask UK-TG-Patches [ set pcolor blue + 2 ]

  set UK-NTG-Patches patches with [pxcor < -4 and pycor < -2]
  ask UK-NTG-Patches [ set pcolor blue + 3 ]

  set PL-TG-Patches patches with [pxcor > 4 and pycor > 2]
  ask PL-TG-Patches [ set pcolor red + 2 ]

  set PL-NTG-Patches patches with [pxcor > 4 and pycor < -2]
  ask PL-NTG-Patches [ set pcolor red + 3 ]

end

to open-close-border
  ifelse not open-borders?                                                       ; if borders are closed
  [ ask patches with [ pxcor = 0 and pycor <= -2] [ set pcolor gray - 2 ] ]      ; draw borders
  [ ask patches with [ pxcor = 0 and pycor <= -2] [ set pcolor gray + 2 ] ]      ; else remove borders
end

to open-close-sectors
  ifelse not allow-sector-mvmt?                                                  ; if sectors are open within countries
  [ ask patches with [ pxcor > 4 and pycor = 0]   [ set pcolor gray - 2 ]        ; draw borders
  ;  ask patches with [ pxcor < -4 and pycor = 0 ] [ set pcolor gray - 2 ] ]     ; INACTIVE WHILE TROUBLESHOOTING: UK and PL sector changes not working together
  ]
  [ ask patches with [ pxcor > 4 and pycor = 0]   [ set pcolor gray + 2 ]        ; else remove borders
      ;  ask patches with [ pxcor < -4 and pycor = 0 ] [ set pcolor gray + 2 ] ] ; INACTIVE WHILE TROUBLESHOOTING: UK and PL sector changes not working together
    ]
end

to setup-turtles                              ; create 200 total workers, split evenly between sectors and coutnries
  set-default-shape goods "box"
  set-default-shape workers "person"
  create-workers 50 [
    set color blue - 1
    move-to one-of UK-TG-Patches
  ]
    create-workers 50 [
    set color blue - 1
    move-to one-of UK-NTG-Patches
  ]
    create-workers 50 [
    set color red - 1
    move-to one-of PL-TG-Patches
  ]
    create-workers 50 [
    set color red - 1
    move-to one-of PL-NTG-Patches
  ]
  ask workers [
    set heading 0                 ; set headings of workers, to intiialize movement up and down
    set initiative random-float 1 ; gives workers a random propensity to migrate or change jobs from 0 - 0.5
    set migrating? false          ; set default value of not migrating
    set job-changer? false        ; set default value of not changing jobs
  ]
end

to setup-parameters ;; sets initial values, relationships, and parameters
  set UK-TG-Wage 20
  set UK-TG-MPL 10
  set UK-TG-Price UK-TG-Wage / UK-TG-MPL
  set UK-NTG-Wage 20
  set UK-NTG-MPL 10
  set UK-NTG-Price UK-NTG-Wage / UK-NTG-MPL
  set PL-TG-Wage 10
  set PL-TG-Price PL-TG-Wage / PL-TG-MPL
  set PL-NTG-Wage 10
  set PL-NTG-MPL 10
  set PL-NTG-Price PL-NTG-Wage / PL-NTG-MPL
end

to go
  arbitrage             ; arbitrage goods between countries, leveling price
  identify-job-changers ; check to see if anyone decides to change sectors
  change-jobs           ; move job changers from one sector to the other
  settle-job-changers   ; adds job changers to new sectors
  identify-migrants     ; check to see if anyone decides to migrate
  migrate               ; move one migrant one at a time to other sector
  settle-migrants       ; adds migrant to working sector
  move-about            ; moves workers within their sector and country
  open-close-border     ; update border status
  open-close-sectors    ; update sector status
  tick
end

to arbitrage           ; step 1) make goods 2) ship goods 3) recceive goods, updating prices
  ; step 1. make goods
    if not any? goods                                                            ; if no goods are currently transferring (approx. even prices)
  [
    set PL-TG-Price PL-TG-Wage / PL-TG-MPL                                       ; set price relationship
    if UK-TG-Price > PL-TG-Price and abs ( UK-TG-Price - PL-TG-Price ) > 0.01    ; if UK-TG prices are more than 0.01 higher than PL-TG
    [
      ask one-of PL-TG-Patches
      [ sprout-goods 1 [set color yellow set heading 270] ]                      ; make goods at a PL patch
    ]

    if UK-TG-Price < PL-TG-Price and abs ( UK-TG-Price - PL-TG-Price ) > 0.01    ; and UK-TG prices are lower than 0.01 of PL-TG
     [
      ask one-of UK-TG-Patches
      [ sprout-goods 1 [set color yellow set heading 90] ]                       ; make goods at a UK patch
    ]
  ]

  ; step 2. ship goods
  ask goods
    [ fd 2]  ; move goods (quickly) towards their destination


  ; step 3. recieve goods, adjust prices
  ask goods
    [
      if [pcolor] of patch-here = gray + 2       ; if goods are in transport
      [
        if [pcolor] of patch-ahead 2 = blue + 2  ; and they reach the UK border
        [
          set UK-TG-Price UK-TG-Price - 0.001    ; lower UK TG price (by a little, simulating lower market share of PL)
          set PL-TG-Price PL-TG-Price + 0.01     ; and raise PL TG price (this simulates supply/demand of TG)
          set UK-TG-Wage UK-TG-Price * UK-TG-MPL ; change relationship to drive wage up, observing LOP
          set PL-TG-Wage PL-TG-Price * PL-TG-MPL
          die                                    ; remove goods

        ]
        if [pcolor] of patch-ahead 2 = red + 2   ; if goods reach PL border
        [
          set UK-TG-Price UK-TG-Price + 0.01     ; raise UK TG price (simulating supply/demand of TG)
          set PL-TG-Price PL-TG-Price - 0.001    ; and lower PL TG price (by a little, simulating lower market share of PL)
          set UK-TG-Wage UK-TG-Price * UK-TG-MPL ; change relationship to drive wage up, observing LOP
          set PL-TG-Wage PL-TG-Price * PL-TG-MPL
          die                                    ; remove goods
        ]
      ]
    ]
end

to identify-job-changers ; TROUBLESHOOT: two scenarios currently incompatible with each other
  if allow-sector-mvmt?                          ; if sectors are open and no workers currently changing sectors
  and not any? workers with [job-changer?]       ; and there are no job-changers already
  and not any? workers with [migrating?]         ; and there is no one migrating
  and abs (UK-TG-Price - PL-TG-Price) < 0.02     ; and there is no price disparity of TG goods (within 0.02)
  [
    if abs (PL-TG-Wage - PL-NTG-Wage ) > 0.02    ; if PL wage disparity exists (greater than 0.02)
    [
      if PL-TG-Wage > PL-NTG-Wage                ; and TG wages are higher than NTG wages in PL
      [
        ask one-of workers-on PL-NTG-Patches     ; select one of NTG workers in PLland
        [
          if random-float 1 < initiative         ; change sectors if random no. < worker's initiative
          [
            set job-changer? true set PL-NTG-Wage PL-NTG-Wage + 0.2
          ]
        ]
      ]
      if PL-TG-Wage < PL-NTG-Wage                ; and TG wages are lower than NTG wages in PL
      [
        ask one-of workers-on PL-TG-Patches      ; select one of TG workers in PL
        [
          if random-float 1 < initiative         ; change sectors if random no. < worker's initiative
          [
            set job-changer? true set PL-TG-Wage PL-TG-Wage + 0.2
          ]
        ]
      ]
    ]

; TROUBLESHOOT THIS: If this is active, PL workers will not change job sectors for some reason
;    if abs (UK-TG-Wage - UK-NTG-Wage ) > 0.02
;    [
;      if UK-TG-Wage > UK-NTG-Wage     ; and TG wages are higher than NTG wages in PL
;      [
;        ask one-of workers-on UK-NTG-Patches     ; select one of NTG workers in PLland
;        [
;          if random-float 1 < initiative; change sectors if random no. < worker's initiative
;          [
;            set job-changer? true set UK-NTG-Wage UK-NTG-Wage + 0.2
;          ]
;        ]
;     ]
;     if UK-TG-Wage < UK-NTG-Wage     ; and TG wages are lower than NTG wages in PL
;      [
;        ask one-of workers-on UK-TG-Patches     ; select one of TG workers in PL
;        [
;          if random-float 1 < initiative; change sectors if random no. < worker's initiative
;         [
;          set job-changer? true set PL-TG-Wage PL-TG-Wage + 0.2
;         ]
;       ]
;      ]
;    ]
  ]
end

to change-jobs
  ask workers with [ pxcor > 0 ]           ; ask workers on right side of map (in Poland)
  [
    if job-changer?                        ; if they are changing jobs
    [
      ifelse PL-TG-Wage > PL-NTG-Wage      ; if TG wages is higher
      [ set heading 0 ]                    ; workers looks look torwards TG sector
      [ set heading 180 ]                  ; otherwise, look towards NTG sector
      fd 1
    ]
  ]

  ask workers with [ pxcor < 0 ]           ; ask workers on left side of map (in UK)
  [
    if job-changer?                        ; if they are changing jobs
    [
      ifelse UK-TG-Wage > UK-NTG-Wage      ; if TG wages is higher
      [ set heading 0 ]                    ; workers looks look torwards TG sector
      [ set heading 180 ]                  ; otherwise, look towards NTG sector
      fd 1
    ]
  ]
end

to settle-job-changers
    ask workers
  [
    if job-changer?
    [
      if PL-TG-Wage >= PL-NTG-Wage and [pcolor] of patch-here = red + 2  ; if job changers on higher wage patch (PL TG)
      [
        move-to one-of PL-TG-Patches                                     ; add to TG sector
        set job-changer? false
        set heading 0
        set PL-TG-Wage PL-TG-Wage - 0.2                                  ; lower wages due to supply/demand of labor in TG sector
        set PL-TG-Price PL-TG-Wage / PL-TG-MPL
      ]
      if PL-TG-Wage <= PL-NTG-Wage and [pcolor] of patch-here = red + 3  ; if job changers on higher wage patch (PL NTG)
      [
        move-to one-of PL-NTG-Patches                                    ; add to NTG sector
        set job-changer? false
        set heading 0
        set PL-NTG-Wage PL-NTG-Wage - 0.2                                ; lower wages due to supply/demand of labor in NTG sector
        set PL-NTG-Price PL-NTG-Wage / PL-NTG-MPL
      ]

      if UK-TG-Wage >= UK-NTG-Wage and [pcolor] of patch-here = blue + 2 ; if job changers on higher wage patch (UK TG)
      [
        move-to one-of UK-TG-Patches                                     ; add to TG sector
        set migrating? false
        set heading 0
        set UK-TG-Wage UK-TG-Wage - 0.2                                  ; lower wages due to supply/demand of labor in TG sector
        set UK-TG-Price UK-TG-Wage / UK-TG-MPL
      ]
      if UK-TG-Wage <= UK-NTG-Wage and [pcolor] of patch-here = blue + 3 ; if job changers on higher wage patch (UK NTG)
      [
        move-to one-of UK-NTG-Patches                                    ; add to NTG sector
        set migrating? false
        set heading 0
        set UK-NTG-Wage UK-NTG-Wage - 0.2                                ; lower wages due to supply/demand of labor in NTG sector
        set UK-NTG-Price UK-NTG-Wage / UK-TG-MPL
      ]
    ]
  ]
end


to identify-migrants     ; selects migrants. Done one worker at a time for visual reasons
  if open-borders?
  and not any? workers with [migrating?]
  and not any? workers with [job-changer?]                       ; if borders are open and no workers currently migrating or changing jobs
  [
    if UK-NTG-Wage > PL-NTG-Wage                                 ; and UK-NTG wages are higher
    [
      ask one-of workers-on PL-NTG-Patches                       ; select one of NTG workers in PLland
      [
        if random-float 1 < initiative + mvmt-bias-towards-UK    ; migrate if random no. < worker's initiative + movement bias towards UK
        [
          set migrating? true set PL-NTG-Wage PL-NTG-Wage + 0.2
        ]
      ]
    ]
    if UK-NTG-Wage < PL-NTG-Wage                                 ; if PL-NTG wages are higher
    [
      ask one-of workers-on UK-NTG-Patches                       ; select one of NTG workers in UK
      [
        if random-float 1 < initiative + mvmt-bias-towards-PL    ; migrate if random no. < worker's initiative + movement bias towards PL
        [
          set migrating? true set UK-NTG-Wage UK-NTG-Wage + 0.2
        ]
      ]
    ]
  ]
end

to migrate
  ask workers
  [
    if migrating?                       ; if they are migrating
    [
      ifelse UK-NTG-Wage > PL-NTG-Wage  ; if UK wage is higher
      [ set heading 270 ]               ; workers looks towards UK
      [ set heading 90 ]                ; otherwise, PL wage higher and workers look towards PL
      fd 1
    ]
  ]
end

to settle-migrants
  ask workers
  [
    if migrating?
    [
      if UK-NTG-Wage >= PL-NTG-Wage and [pcolor] of patch-here = blue + 3 ; if migrants on higher wage patch
      [
        move-to one-of UK-NTG-Patches                                     ; add to UK workforce
        set migrating? false
        set heading 0
        set UK-NTG-Wage UK-NTG-Wage - 0.2                                 ; lower wages due to supply/demand of labor in UK
      ]
      if UK-NTG-Wage <= PL-NTG-Wage and [pcolor] of patch-here = red + 3  ; when migrant reaches PL
      [
        move-to one-of PL-NTG-Patches                                     ; add to PL workforce
        set migrating? false
        set heading 0
        set PL-NTG-Wage PL-NTG-Wage - 0.2                                 ; lower wages due to supply/demand of labor in PL
      ]
    ]
  ]
  set UK-NTG-Price UK-NTG-Wage / UK-NTG-MPL
  set PL-NTG-Price PL-NTG-Wage / PL-NTG-MPL
end

to move-about
  ask workers [
    if not migrating? and not job-changer?                                ; if workers aren't migrating
    [
    if abs pycor = max-pycor or [pcolor] of patch-ahead 1 = gray + 2      ; avoid edges of sector and map
      [ set heading (180 - heading) ]
  fd 1                                                                    ; and move forward
  ]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
561
73
1008
521
-1
-1
13.303030303030303
1
10
1
1
1
0
0
0
1
-16
16
-16
16
1
1
1
ticks
30.0

BUTTON
8
10
71
43
setup
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

BUTTON
82
10
145
43
go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
208
181
422
278
Assumptions:\nbarriers to movement vaires (mvmt-bias)\nworkers cannot change jobs, only countries
11
0.0
1

TEXTBOX
430
335
580
373
Non-tradable goods (NTG) sector
15
0.0
1

TEXTBOX
453
67
555
113
Tradable goods (TG) sector
15
0.0
1

TEXTBOX
573
34
758
92
United Kingdom
20
0.0
1

TEXTBOX
899
34
1049
71
Poland
20
0.0
1

PLOT
183
337
343
457
TG Price
NIL
NIL
0.0
10.0
0.0
3.0
true
false
"" ""
PENS
"default" 1.0 0 -13345367 true "" "plot UK-TG-Price"
"pen-1" 1.0 0 -2674135 true "" "plot PL-TG-Price"

PLOT
183
462
343
582
NTG Price
NIL
NIL
0.0
10.0
0.0
3.0
true
false
"" ""
PENS
"pen-1" 1.0 0 -13345367 true "" "plot UK-NTG-Price"
"pen-2" 1.0 0 -2674135 true "" "plot PL-NTG-Price"

BUTTON
153
11
228
44
go once
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
207
71
343
104
open-borders?
open-borders?
1
1
-1000

SLIDER
207
106
385
139
mvmt-bias-towards-UK
mvmt-bias-towards-UK
-1
1
0.0
.1
1
NIL
HORIZONTAL

MONITOR
508
381
558
426
Wage
UK-NTG-Wage
2
1
11

MONITOR
508
437
558
482
MPL
UK-NTG-MPL
17
1
11

MONITOR
432
412
482
457
Price
UK-NTG-Price
2
1
11

TEXTBOX
488
423
505
441
=
13
0.0
1

TEXTBOX
512
415
563
435
_____
16
0.0
1

TEXTBOX
493
163
531
181
=
13
0.0
1

MONITOR
509
124
559
169
Wage
UK-TG-Wage
2
1
11

MONITOR
509
177
559
222
MPL
UK-TG-MPL
2
1
11

MONITOR
437
149
487
194
Price
UK-TG-Price
5
1
11

TEXTBOX
511
156
570
176
_____
16
0.0
1

TEXTBOX
1071
161
1086
179
=
13
0.0
1

MONITOR
1010
119
1067
164
Wage
PL-TG-Wage
2
1
11

MONITOR
1010
175
1067
220
MPL
PL-TG-MPL
2
1
11

MONITOR
1085
144
1142
189
Price
PL-TG-Price
2
1
11

TEXTBOX
1015
153
1073
173
_____
16
0.0
1

MONITOR
1009
385
1066
430
Wage
PL-NTG-Wage
2
1
11

MONITOR
1009
438
1066
483
MPL
PL-NTG-MPL
2
1
11

MONITOR
1084
411
1141
456
Price
PL-NTG-Price
2
1
11

TEXTBOX
1071
423
1118
441
=
13
0.0
1

TEXTBOX
1017
416
1060
436
_____
16
0.0
1

PLOT
9
461
178
581
NTG-Workers by Country
NIL
NIL
0.0
10.0
20.0
80.0
true
false
"" ""
PENS
"pen-1" 1.0 0 -13345367 true "" "plot count turtles-on UK-NTG-Patches"
"pen-3" 1.0 0 -2674135 true "" "plot count turtles-on PL-NTG-Patches"

SLIDER
207
143
386
176
mvmt-bias-towards-PL
mvmt-bias-towards-PL
-1
1
0.0
.1
1
NIL
HORIZONTAL

MONITOR
1008
276
1070
321
Price diff
abs (PL-TG-Price - PL-NTG-Price)
2
1
11

MONITOR
1069
276
1136
321
Wage diff
abs (PL-TG-Wage - PL-NTG-Wage)
2
1
11

MONITOR
433
272
495
317
Price diff
abs (UK-TG-Price - UK-NTG-Price)
2
1
11

MONITOR
495
272
562
317
Wage diff
abs (UK-TG-Wage - UK-NTG-Wage)
2
1
11

MONITOR
726
29
784
74
Price diff
abs (UK-TG-Price - PL-TG-Price)
2
1
11

MONITOR
784
29
845
74
Wage diff
abs (UK-TG-Wage - PL-TG-Wage)
2
1
11

MONITOR
722
520
784
565
Price diff
abs (UK-NTG-Price - PL-NTG-Price)
2
1
11

MONITOR
784
520
844
565
Wage diff
abs (UK-NTG-Wage - PL-NTG-Wage)
2
1
11

SWITCH
8
71
148
104
allow-sector-mvmt?
allow-sector-mvmt?
1
1
-1000

SLIDER
8
103
148
136
PL-TG-MPL
PL-TG-MPL
5
10
5.0
1
1
NIL
HORIZONTAL

TEXTBOX
7
45
90
67
Scenario 1
18
0.0
1

TEXTBOX
208
45
358
67
Scenario 2
18
0.0
1

TEXTBOX
12
139
210
209
Assumptions:\nLaw of One Price holds\nPL has a small share of TG market\nPrices update much faster than wages\nNo labor mvmt barrier w/in PL sectors
11
0.0
1

PLOT
9
335
178
457
TG-Workers by Country
NIL
NIL
0.0
10.0
0.0
80.0
true
false
"" ""
PENS
"default" 1.0 0 -13345367 true "" "plot count workers-on UK-TG-Patches"
"pen-1" 1.0 0 -2674135 true "" "plot count workers-on PL-TG-Patches"

PLOT
10
212
178
332
PL Price Level
NIL
NIL
0.0
10.0
2.5
4.0
true
false
"" ""
PENS
"default" 1.0 0 -2674135 true "" "plot PL-TG-Price + PL-NTG-Price"

@#$#@#$#@
## To Do

add barriers to vertical migration
integrate the two migrations somehow

## WHAT IS IT?



## HOW IT WORKS


## HOW TO USE IT


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
NetLogo 6.2.0
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
0
@#$#@#$#@
