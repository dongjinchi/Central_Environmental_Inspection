cd ~
insheet using inspection.csv ,clear

gen time1 = date(date,"YMD")
xtset city time1

gen lpm=log(pm25) //logarithm of PM2.5 concentration
gen laqi = log(aqi) //logarithm of AQI index
gen lcomp = log(comp+1) // logarithm of the number of public complaints
gen lair = log(comp_air+1) // logarithm of the number of public air complaints
gen lsent = log(negative_comp+1) // logarithm of the sentiment of public complaints
gen lasent = log(negative_air+1) // logarithm of the sentiment of public air complaints
gen postv = assignment_start >0
gen runv = assignment_start
gen treat = round >2

save inspection.dta, replace

*******Make Table 1*********
*third batch
preserve
drop if year ==2018
drop if round == 4
keep if time <=146
gen post = time >112
local vars lcomp lair lasent
foreach var of loc vars  {
 	reghdfe `var' post treat c.post#c.treat pm25 tem pre win, absorb(i.time i.city i.city#c.time) vce(cluster city)
	estimates store r3`var'
}	

* fourth batch
preserve
drop if year == 2018
drop if round == 3
keep if time < = 256
gen post = time >217
local vars lcomp lair lasent
foreach var of loc vars  {
 	reghdfe `var' post treat c.post#c.treat pm25 tem pre win, absorb(i.time i.city i.city#c.time) vce(cluster city)
	estimates store r4`var'
}
esttab r3lcomp r3lair r3lasent r4lcomp r4lair r4lasent using Table1.rtf, star(* .1 ** .05  *** .01) nogap nonumber replace se(%5.4f) ar2 aic(%10.4f) bic(%10.4f)
restore

*******Make Table 2*********
preserve
drop if year == 2018
drop if round == 4
keep if time <=146
gen post = time >112
replace negative_air = round(negative_air*10)
local invars comp_air negative_air
foreach invar of loc invars{
		 reghdfe lpm post treat `invar' c.treat#c.`invar' c.post#c.`invar' c.treat#c.post c.post#c.treat#c.`invar' tem pre win, absorb(i.time i.city i.city#c.time) vce(cluster city)
		estimates store r3`var'	
//		coefplot (r1,drop(_cons)  ), vert yline(0,lwidth(thin) lcolor(black) lpattern(dash))  
}
restore

preserve
drop if year == 2018
drop if round == 3
keep if time < = 256
gen post = time >217
replace negative_air = round(negative_air*10)
local invars comp_air negative_air
foreach invar of loc invars{
		 reghdfe lpm post treat `invar' c.treat#c.`invar' c.post#c.`invar' c.treat#c.post c.post#c.treat#c.`invar' tem pre win, absorb(i.time i.city i.city#c.time) vce(cluster city)
	estimates store r4`var'	
//			coefplot (r1,drop(_cons)  ), vert yline(0,lwidth(thin) lcolor(black) lpattern(dash))  
}
restore
esttab r3comp_air r3negative_air r4comp_air r4negative_air using Table2.rtf, star(* .1 ** .05  *** .01)   nogap      nonumber replace se(%5.4f) ar2 aic(%10.4f) bic(%10.4f)

**********Make Figure 1**********
*third round
drop if round == 4
keep if time <=218
gen post = time >112
local vars lcomp lair lasent
foreach var of loc vars {
	if "`var'" == "lcomp"{
	local ytitle = "Growth Rate of Public Complaints"
}
else if "`var'" == "lair"{
	local ytitle = "Growth Rate of Public Air Complaints"
}
else if "`var'" == "lasent"{
	local ytitle = "Growth Rate of Public Air Sentiment"
}
	reghdfe `var' post treat c.post#c.treat#i.time tem pre win, absorb(i.time i.city i.city#c.time) vce(cluster city)
preserve
parmest, norestore level(95)
drop if missing(t) | parm == "pm25" | parm == "tem"| parm == "pre"|parm == "win" |parm == "_cons"
egen  x = seq(), from(-1) to(105)
drop parm 
keep if  x<=100
twoway ///
(rarea min max x, fcolor( "190 50 190%30") lcolor(%0) ) ///
(line est x , lcolor("190 50 190") )  ///
 , ///
xlabel(0(10)100, labsize(small)) ///
xline(34,lwidth(thin) lcolor(black) lpattern(dash)) ///
yline(0,lwidth(thin) lcolor(gs10) ) ///
 legend(off)  xtitle("") ytitle(`ytitle', size(small)) graphregion(color(white))
  graph save "~\Plot\Figure1_3`var'.gph",replace
restore
}

*reload the data
use inspection.dta, clear

*fourth round
drop if round == 3
gen post = time >217
local vars lcomp lair lasent
foreach var of loc vars {
if "`var'" == "lcomp"{
	local ytitle = "Growth Rate of Public Complaints"
}
else if "`var'" == "lair"{
	local ytitle = "Growth Rate of Public Air Complaints"
}
else if "`var'" == "lasent"{
	local ytitle = "Growth Rate of Public Air Sentiment"
}
reghdfe `var' post treat c.post#c.treat#i.time tem pre win, absorb(i.time i.city i.city#c.time) vce(cluster city)
preserve
parmest, norestore level(95)
drop if missing(t) | parm == "pm25" | parm == "tem"| parm == "pre"|parm == "win" |parm == "_cons"
egen  x = seq(), from(-1) to(145)
drop parm 
keep if  x<=145
twoway ///
(rarea min max x, fcolor( "0 175 80%30") lcolor(%0) ) ///
(line est x , lcolor("0 175 80") )  ///
 , ///
xlabel(0(20)140, labsize(small)) ///
xline(39,lwidth(thin) lcolor(black) lpattern(dash)) ///
yline(0,lwidth(thin) lcolor(gs10) ) ///
 legend(off)  xtitle("") ytitle(`ytitle', size(small)) graphregion(color(white))
   graph save "~\Plot\Figure1_4`var'.gph",replace
restore
}
preserve
cd ~\Plot
graph combine Figure1_3lcomp.gph Figure1_3lair.gph Figure1_3lasent.gph  Figure1_4lcomp.gph Figure1_4lair.gph Figure1_4lasent.gph, imargin(vsmall) graphregion(color(white)) 
restore

*******Make Table 3*********
preserve
drop if round == 4
drop if year == 2018
drop if time >112 & time <=(146+30)
keep if time <=(180+30)
gen post = time >112
replace negative_air = round(negative_air*10)
local invars comp_air negative_air
foreach invar of loc invars{
		 reghdfe lpm post treat `invar' c.treat#c.`invar' c.post#c.`invar' c.treat#c.post c.post#c.treat#c.`invar' tem pre win, absorb(i.time i.city i.city#c.time) vce(cluster city)
		estimates store ra`var'	
//		coefplot (r1,drop(_cons)  ), vert yline(0,lwidth(thin) lcolor(black) lpattern(dash))  
}
restore


preserve
drop if year == 2018
drop if round == 3
drop if time > 217 & time <=(256+30)
keep if time <=(295+30)
gen post = time >217
replace negative_air = round(negative_air*10)
local invars comp_air negative_air
foreach invar of loc invars{
		 	reghdfe lpm post treat `invar' c.treat#c.`invar' c.post#c.`invar' c.treat#c.post c.post#c.treat#c.`invar' tem pre win, absorb(i.time i.city i.city#c.time) vce(cluster city)
	estimates store ra`var'	
//		coefplot (r1,drop(_cons)  ), vert yline(0,lwidth(thin) lcolor(black) lpattern(dash))  
}
restore
esttab ra3comp_air ra3negative_air ra4comp_air ra4negative_air using Table3.rtf, star(* .1 ** .05  *** .01)   nogap      nonumber replace se(%5.4f) ar2 aic(%10.4f) bic(%10.4f)



**********Make Table S3**********
use inspection.dta, clear

*third round
preserve
drop if year ==2018
drop if round == 4
gen post = time >112
gen end  = 0
forvalues i = 1(1)53 {
  replace end = `i' if time >= (0+(`i'-1)*7) & time < (0+`i'*7)
}
drop if end >=28
local vars lcom lair lasent
foreach var of loc vars  {
 	reghdfe `var' post treat c.post#c.treat#i.end pm25 tem pre win, absorb(    i.time i.city i.city#c.time) vce(cluster city)
	estimates store rw3`var'
}	
restore

*fourth round
preserve
drop if year ==2018
drop if round == 3
gen post = time >217
gen end  = 0
forvalues i = 1(1)53 {
  replace end = `i' if time >= (0+(`i'-1)*7) & time < (0+`i'*7)
}
drop if end >=44
local vars lcom lair lasent
foreach var of loc vars  {
 	reghdfe `var' post treat c.post#c.treat#i.end pm25 tem pre win, absorb(    i.time i.city i.city#c.time) vce(cluster city)
	estimates store rw4`var'
}	
restore
esttab rw3lcom rw3lair rw3lasent rw4lcom rw4lair rw4lasent using tableS3.rtf, star(* .1 ** .05  *** .01)   nogap      nonumber replace se(%5.4f) ar2 aic(%10.4f) bic(%10.4f)


**********Make Table S4**********
*third batch
preserve
drop if year ==2018
drop if round == 4
keep if time <=146
gen post = time >112
local vars lpm laqi
foreach var of loc vars  {
 	reghdfe `var' post treat c.post#c.treat  tem pre win, absorb(i.time i.city i.city#c.time) vce(cluster city)
	estimates store r3`var'
}
restore

* fourth batch
preserve
drop if year == 2018
drop if round == 3
keep if time < = 256
gen post = time >217
local vars lpm laqi
foreach var of loc vars  {
 	reghdfe `var' post treat c.post#c.treat tem pre win, absorb(i.time i.city i.city#c.time) vce(cluster city)
	estimates store r4`var'
}
esttab r3lpm r3laqi r4lpm r4laqi using TableS4.rtf, star(* .1 ** .05  *** .01) nogap nonumber replace se(%5.4f) ar2 aic(%10.4f) bic(%10.4f)
restore

*********Make Figure S2***********
*third round
drop if round == 4
keep if time <=218
gen post = time >112
local vars lpm laqi
foreach var of loc vars {
if "`var'" == "lpm"{
	local ytitle = "Growth Rate of PM2.5 concentration"
}
else if "`var'" == "laqi"{
	local ytitle = "Growth Rate of AQI"
}
	reghdfe `var' post treat c.post#c.treat#i.time tem pre win, absorb(i.time i.city i.city#c.time) vce(cluster city)
preserve
parmest, norestore level(95)
drop if missing(t) | parm == "pm25" | parm == "tem"| parm == "pre"|parm == "win" |parm == "_cons"
egen  x = seq(), from(-1) to(105)
drop parm 
keep if  x<=100
twoway ///
(rarea min max x, fcolor( "190 50 190%30") lcolor(%0) ) ///
(line est x , lcolor("190 50 190") )  ///
 , ///
xlabel(0(10)100, labsize(small)) ///
xline(34,lwidth(thin) lcolor(black) lpattern(dash)) ///
yline(0,lwidth(thin) lcolor(gs10) ) ///
 legend(off)  xtitle("") ytitle(`ytitle', size(small)) graphregion(color(white))
  graph save "~\Plot\FigureS2_3`var'.gph",replace
restore
}

*reload the data
use inspection.dta, clear

*fourth round
drop if round == 3
gen post = time >217
local vars lpm laqi
foreach var of loc vars {
if "`var'" == "lpm"{
	local ytitle = "Growth Rate of PM2.5 concentration"
}
else if "`var'" == "laqi"{
	local ytitle = "Growth Rate of AQI"
}
reghdfe `var' post treat c.post#c.treat#i.time tem pre win, absorb(i.time i.city i.city#c.time) vce(cluster city)
preserve
parmest, norestore level(95)
drop if missing(t) | parm == "pm25" | parm == "tem"| parm == "pre"|parm == "win" |parm == "_cons"
egen  x = seq(), from(-1) to(145)
drop parm 
keep if  x<=145
twoway ///
(rarea min max x, fcolor( "0 175 80%30") lcolor(%0) ) ///
(line est x , lcolor("0 175 80") )  ///
 , ///
xlabel(0(20)140, labsize(small)) ///
xline(39,lwidth(thin) lcolor(black) lpattern(dash)) ///
yline(0,lwidth(thin) lcolor(gs10) ) ///
 legend(off)  xtitle("") ytitle(`ytitle', size(small)) graphregion(color(white))
   graph save "~\Plot\FigureS2_4`var'.gph",replace
restore
}
preserve
cd ~\Plot
graph combine FigureS2_3lpm.gph FigureS2_3laqi.gph FigureS2_4lpm.gph FigureS2_4laqi.gph, imargin(vsmall) graphregion(color(white)) 
restore

*********Make Table S5***********
use inspection.dta, clear
*third round
preserve
drop if year ==2018
drop if round == 4
gen post = time >112
gen end  = 0
forvalues i = 1(1)53 {
  replace end = `i' if time >= (0+(`i'-1)*7) & time < (0+`i'*7)
}
drop if end >=28
local vars lpm laqi
foreach var of loc vars  {
 	reghdfe `var' post treat c.post#c.treat#i.end tem pre win, absorb(    i.time i.city i.city#c.time) vce(cluster city)
	estimates store rw3`var'
}	
restore

*fourth round
preserve
drop if year ==2018
drop if round == 3
gen post = time >217
gen end  = 0
forvalues i = 1(1)53 {
  replace end = `i' if time >= (0+(`i'-1)*7) & time < (0+`i'*7)
}
drop if end >=44
local vars lpm laqi
foreach var of loc vars  {
 	reghdfe `var' post treat c.post#c.treat#i.end tem pre win, absorb(    i.time i.city i.city#c.time) vce(cluster city)
	estimates store rw4`var'
}	
restore
esttab rw3lpm rw3laqi rw4lpm rw4laqi using tableS5.rtf, star(* .1 ** .05  *** .01)   nogap      nonumber replace se(%5.4f) ar2 aic(%10.4f) bic(%10.4f)


*************************************
**       Analysis for CELR         **
*************************************

*********Make Table S6***********
*First batch
preserve
drop if year ==2017
keep if time <=187
gen post = time >148
gen treat_b = (prov ==13 |prov ==15 | prov ==23| prov ==32|prov ==36|prov ==41|prov ==45|prov ==53|prov ==64|prov ==44)
local vars lcomp lair lasent
foreach var of loc vars  {
 	reghdfe `var' post treat_b c.post#c.treat_b pm25 tem pre win, absorb(i.time i.city i.city#c.time) vce(cluster city)
	estimates store r1`var'
}
restore	

*Second batch
preserve
drop if year ==2017
keep if time <=339
drop if comp_air >18
gen post = time >302
gen treat_b = (prov ==42 | prov ==61| prov ==34|prov ==14|prov ==21|prov ==22|prov ==43|prov ==52|prov ==37|prov ==51)
local vars lcomp lair lasent
foreach var of loc vars  {
 	reghdfe `var' post treat_b c.post#c.treat_b pm25 tem pre win, absorb(i.time i.city i.city#c.time) vce(cluster city)
	estimates store r2`var'
}	
restore
esttab r1lcomp r1lair r1lasent r2lcomp r2lair r2lasent using TableS6.rtf, star(* .1 ** .05  *** .01) nogap nonumber replace se(%5.4f) ar2 aic(%10.4f) bic(%10.4f)


*********Make Table S7***********
*First batch
preserve
drop if year ==2017
gen post = time >148
gen treat_b = (prov ==13 |prov ==15 | prov ==23| prov ==32|prov ==36|prov ==41|prov ==45|prov ==53|prov ==64|prov ==44)
gen end  = 0
forvalues i = 1(1)53 {
  replace end = `i' if time >= (0+(`i'-1)*7) & time < (0+`i'*7)
}
drop if end >=34
local vars lcomp lair lasent
foreach var of loc vars  {
 	reghdfe `var' post treat_b c.post#c.treat_b#i.end pm25 tem pre win, absorb(    i.time i.city i.city#c.time) vce(cluster city)
	estimates store rw1`var'
}	
restore

*Second batch
preserve
drop if year ==2017
gen post = time >302
gen treat_b = (prov ==42 | prov ==61| prov ==34|prov ==14|prov ==21|prov ==22|prov ==43|prov ==52|prov ==37|prov ==51)
gen end  = 0
forvalues i = 1(1)53 {
  replace end = `i' if time >= (0+(`i'-1)*7) & time < (0+`i'*7)
}
local vars lcomp lair lasent
foreach var of loc vars  {
 	reghdfe `var' post treat c.post#c.treat#i.end pm25 tem pre win, absorb(    i.time i.city i.city#c.time) vce(cluster city)
	estimates store rw2`var'
}	
restore

esttab rw1lcomp rw1lair rw1lasent rw2lcomp rw2lair rw2lasent using TableS3_2.rtf, star(* .1 ** .05  *** .01)   nogap      nonumber replace se(%5.4f) ar2 aic(%10.4f) bic(%10.4f)


*********Make Table S8***********
*First batch
preserve
drop if year ==2017
keep if time <=187
gen post = time >148
gen treat_b = (prov ==13 |prov ==15 | prov ==23| prov ==32|prov ==36|prov ==41|prov ==45|prov ==53|prov ==64|prov ==44)
replace negative_air = round(negative_air*10)
local invars comp_air negative_air
foreach invar of loc invars{
		 reghdfe lpm post treat `invar' c.treat#c.`invar' c.post#c.`invar' c.treat#c.post c.post#c.treat#c.`invar' tem pre win, absorb(i.time i.city i.city#c.time) vce(cluster city)
		estimates store r1`var'	
//		coefplot (r1,drop(_cons)  ), vert yline(0,lwidth(thin) lcolor(black) lpattern(dash))  
}

*Second batch
preserve
drop if year ==2017
keep if time <=339
drop if comp_air >18
gen post = time >302
gen treat_b = (prov ==42 | prov ==61| prov ==34|prov ==14|prov ==21|prov ==22|prov ==43|prov ==52|prov ==37|prov ==51)
replace negative_air = round(negative_air*10)
local invars comp_air negative_air
foreach invar of loc invars{
		 reghdfe lpm post treat `invar' c.treat#c.`invar' c.post#c.`invar' c.treat#c.post c.post#c.treat#c.`invar' tem pre win, absorb(i.time i.city i.city#c.time) vce(cluster city)
		estimates store r2`var'	
//		coefplot (r1,drop(_cons)  ), vert yline(0,lwidth(thin) lcolor(black) lpattern(dash))  
}
restore

esttab r1comp_air r1negative_air r1comp_air r1negative_airr using TableS8.rtf, star(* .1 ** .05  *** .01)   nogap      nonumber replace se(%5.4f) ar2 aic(%10.4f) bic(%10.4f)




*********Make Table S9***********
local lags 30 60 90
foreach lag of loc lags{
preserve
drop if year ==2017
drop if time >148 & time <=(187+`lag')
keep if time <=(187+30+`lag')
gen post = time >148
gen treat_b = (prov ==13 |prov ==15 | prov ==23| prov ==32|prov ==36|prov ==41|prov ==45|prov ==53|prov ==64|prov ==44)
replace negative_air = round(negative_air*10)
reghdfe lpm post treat negative_air c.treat#c.negative_air c.post#c.negative_air c.treat#c.post c.post#c.treat#c.negative_air tem pre win, absorb(i.time i.city i.city#c.time) vce(cluster city)
estimates store ra1_`lag'
restore	
}

preserve
drop if year ==2017
drop if time >302 & time <=339
gen post = time >302
gen treat_b = (prov ==42 | prov ==61| prov ==34|prov ==14|prov ==21|prov ==22|prov ==43|prov ==52|prov ==37|prov ==51)
replace negative_air = round(negative_air*10)
reghdfe lpm post treat negative_air c.treat#c.negative_air c.post#c.negative_air c.treat#c.post c.post#c.treat#c.negative_air tem pre win, absorb(i.time i.city i.city#c.time) vce(cluster city)
estimates store ra2
restore	
esttab ra1_30 ra1_60 ra1_90 ra2 using TableS9.rtf, star(* .1 ** .05  *** .01)   nogap      nonumber replace se(%5.4f) ar2 aic(%10.4f) bic(%10.4f)


*******************************************
*************Parallel Trend Test***********
*******************************************

***********Make Figure S3***********
drop if year == 2018
local vars lcomp lair lpm lasent
foreach var of loc vars {
preserve
replace time = date(date, "YMD")
format time %tdCY/N/D
replace round = 0 if round == 1 | round ==2
egen mean_y=mean(`var'),by(round time)
tssmooth ma smooth_y=mean_y,window(7 1)
summarize smooth_y
egen min_y = min(smooth_y)
egen max_y = max(smooth_y)
 twoway  ///
 (scatter smooth_y time if round ==0 , connect(|) msymbol(none) mcolor(navy) lcolor("black") sort) ///
 (scatter smooth_y time if round ==3 , connect(|) msymbol(none) mcolor(navy) lcolor("190 50 190") sort) ///
 (scatter smooth_y time if round ==4 , connect(|) msymbol(none) lcolor("0 175 80") sort) ///
 (rarea min max time  if time>=date("2017-04-24", "YMD") & time<=date("2017-05-28", "YMD"), fcolor( "190 50 190%30") lcolor(%0) ) ///
 (rarea min max time if time>=date("2017-08/-07", "YMD") & time<=date("2017-09-15", "YMD") ,  fcolor("0 175 80%30") fi(inten40) lw(none)) ///
 , l2title(ln(Public total complaints)) xtitle("")  legend(order(1 "Control group" 2 "Round 3" 3 "Round 4")  rows(1) ) ///
 graphregion(color(white)) plotregion(margin(r+3))
 graph save "~Plot\FigureS3_`var'.gph",replace
 restore
} 
preserve
cd ~\Plot
graph combine FigureS3_lcomp.gph FigureS3_lair.gph FigureS3_lasent.gph  FigureS3_lpm.gph, imargin(vsmall) graphregion(color(white)) 
restore

************Make Figure S4***********
*First batch
local vars lcomp lair lasent lpm laqi
foreach var of loc vars {
preserve
drop if year == 2017
replace time = date(date, "YMD")
format time %tdCY/N/D
replace round= 0
replace round = (prov ==13 |prov ==15 | prov ==23| prov ==32|prov ==36|prov ==41|prov ==45|prov ==53|prov ==64|prov ==44)
egen mean_y=mean(`var'),by(round time)
tssmooth ma smooth_y=mean_y,window(7 1)
summarize smooth_y
egen min_y = min(smooth_y)
egen max_y = max(smooth_y)
 twoway  ///
 (scatter smooth_y time if round ==0 , connect(|) msymbol(none) mcolor(navy) lcolor("black") sort) ///
 (scatter smooth_y time if round ==1 , connect(|) msymbol(none) mcolor(navy) lcolor("190 50 190") sort) ///
 (rarea min max time  if time>=date("2018-05-30", "YMD") & time<=date("2018-07-07", "YMD"), fcolor( "190 50 190%30") lcolor(%0) ) ///
 , l2title(ln(Public total complaints)) xtitle("")  legend(order(1 "Control group" 2 "Batch 1")  rows(1) ) ///
 graphregion(color(white)) plotregion(margin(r+3))
 graph save " ~Plot\FigureS4_1`var'.gph",replace
 restore
} 

*Second batch
local vars lcomp lair lasent lpm laqi
foreach var of loc vars {
preserve
drop if year == 2017
replace time = date(date, "YMD")
format time %tdCY/N/D
replace round= 0
replace round = 2 if (prov ==42 | prov ==61| prov ==34|prov ==14|prov ==21|prov ==22|prov ==43|prov ==52|prov ==37|prov ==51)
egen mean_y=mean(`var'),by(round time)
tssmooth ma smooth_y=mean_y,window(7 1)
summarize smooth_y
egen min_y = min(smooth_y)
egen max_y = max(smooth_y)
 twoway  ///
 (scatter smooth_y time if round ==0 , connect(|) msymbol(none) mcolor(navy) lcolor("black") sort) ///
  (scatter smooth_y time if round ==2 , connect(|) msymbol(none) lcolor("0 175 80") sort) ///
 (rarea min max time if time>=date("2018-10-30", "YMD") & time<=date("2018-12-06", "YMD") ,  fcolor("0 175 80%30") fi(inten40) lw(none)) ///
 , l2title(ln(Public total complaints)) xtitle("")  legend(order(1 "Control group" 2 "Batch 2" )  rows(1) ) ///
 graphregion(color(white)) plotregion(margin(r+3))
 graph save "~Plot\FigureS4_2`var'.gph",replace
 restore
} 

preserve
cd ~\Plot
graph combine FigureS4_1lcomp.gph FigureS4_1lair.gph FigureS4_1lasent.gph  FigureS4_1lpm.gph FigureS4_2lcomp.gph FigureS4_2lair.gph FigureS4_2lasent.gph  FigureS4_2lpm.gph, imargin(vsmall) graphregion(color(white)) 
restore

************Make Figure S5***********
*Third barch
preserve
drop if year == 2018
drop if round == 4
gen period = time - 113
forvalues i = 112(-1)1{
gen pr_`i' = (period == -`i' & treat == 1)
}
gen current = (period == 0 & treat == 1)
forvalues j = 1(1)100{
gen po_`j' = (period == `j' & treat == 1)
}
local vars lcomp lair lasent
foreach var of loc vars {
qui reghdfe `var'  pr_* current po_* pm25 tem pre win,absorb(i.city i.time i.city#c.year) vce(cluster city)
est sto reg
coefplot reg, keep(pr_* current po_*) vertical recast(connect) yline(0) xline(113, lp(dash)) graphregion(color(white))  mcolor("190 50 190") ciopts(color("190 50 190%30")) clcolor("190 50 190") msymbol(none) xlabel(0 (20) 210) ytitle(Growth rate of `var') plotregion(margin(r+3))
  graph save "~Plot\FigureS5_3`var'.gph",replace
}
restore

*Fourth batch
preserve
drop if year == 2018
drop if round == 3
gen period = time - 217
forvalues i = 216(-1)1{
gen pr_`i' = (period == -`i' & treat == 1)
}
gen current = (period == 0 & treat == 1)
forvalues j = 1(1)140{
gen po_`j' = (period == `j' & treat == 1)
}
local vars lcomp lair lasent
foreach var of loc vars {
 reghdfe `var'  pr_* current po_* pm25 tem pre win,absorb(i.city i.time i.city#c.year) vce(cluster city)
est sto reg
coefplot reg, keep(pr_* current po_*) vertical recast(connect) yline(0) xline(217, lp(dash)) graphregion(color(white))  mcolor("0 175 80") ciopts(color("0 175 80%30")) clcolor("0 175 80") msymbol(none) xlabel(0 (50) 350) ytitle(Growth rate of `var') plotregion(margin(r+3))
  graph save "~Plot\FigureS5_4`var'.gph",replace
}
restore

preserve
cd ~\Plot
graph combine FigureS5_3lcomp.gph FigureS5_3lair.gph FigureS5_3lasent.gph FigureS5_4lcomp.gph FigureS5_4lair.gph FigureS5_4lasent.gph, imargin(vsmall) graphregion(color(white)) 
restore



************Make Figure S6***********
*First batch
preserve
drop if year == 2017
gen period = time - 149
gen treat_b = (prov ==13 |prov ==15 | prov ==23| prov ==32|prov ==36|prov ==41|prov ==45|prov ==53|prov ==64|prov ==44)
forvalues i = 148(-1)1{
gen pr_`i' = (period == -`i' & treat_b == 1)
}
gen current = (period == 0 & treat_b == 1)
forvalues j = 1(1)100{
gen po_`j' = (period == `j' & treat_b == 1)
}
local vars lcomp lair lasent
foreach var of loc vars {
qui reghdfe `var'  pr_* current po_* pm25 tem pre win,absorb(i.city i.time i.city#c.year) vce(cluster city)
est sto reg
coefplot reg, keep(pr_* current po_*) vertical recast(connect) yline(0) xline(149, lp(dash)) graphregion(color(white))  mcolor("190 50 190") ciopts(color("190 50 190%30")) clcolor("190 50 190") msymbol(none) xlabel(0 (20) 250) ytitle(Growth rate of `var') plotregion(margin(r+3))
  graph save "~Plot\FigureS6_1`var'.gph",replace
}
restore

*Second batch
preserve
drop if year == 2017
gen period = time - 303
gen treat_b = (prov ==13 |prov ==15 | prov ==23| prov ==32|prov ==36|prov ==41|prov ==45|prov ==53|prov ==64|prov ==44)
forvalues i = 302(-1)1{
gen pr_`i' = (period == -`i' & treat_b == 1)
}
gen current = (period == 0 & treat_b == 1)
forvalues j = 1(1)61{
gen po_`j' = (period == `j' & treat_b == 1)
}
local vars lcomp lair lasent
foreach var of loc vars {
qui reghdfe lcomp  pr_* current po_* pm25 tem pre win,absorb(i.city i.time i.city#c.year) vce(cluster city)
est sto reg
coefplot reg, keep(pr_* current po_*) vertical recast(connect) yline(0) xline(303, lp(dash)) graphregion(color(white))  mcolor("0 175 80") ciopts(color("0 175 80%30")) clcolor("0 175 80") msymbol(none) xlabel(0 (40) 350) ytitle(Growth rate of `var') plotregion(margin(r+3))
  graph save "~Plot\FigureS6_2`var'.gph",replace
}
restore

preserve
cd ~\Plot
graph combine FigureS6_1lcomp.gph FigureS6_1lair.gph FigureS6_1lasent.gph FigureS6_2lcomp.gph FigureS6_2lair.gph FigureS6_2lasent.gph, imargin(vsmall) graphregion(color(white)) 
restore

******************************************
****************Placebo Test**************
******************************************

**********Make Table S10*************
*third round
preserve
drop if year ==2017
drop if round == 4
keep if time <=146
gen post = time >112
local vars lcomp lair lasent
foreach var of loc vars  {
 	reghdfe `var' post treat c.post#c.treat pm25 tem pre win, absorb(i.time i.city i.city#c.time) vce(cluster city)
	estimates store rp3`var'
}	
restore

** fourth round
preserve
drop if year ==2017
drop if round == 3
keep if time < = 256 & time >= 35
gen post = time >217
local vars lcomp lair lasent 
foreach var of loc vars  {
 	reghdfe `var' post treat c.post#c.treat pm25 tem pre win, absorb(i.time i.city i.city#c.time) vce(cluster city)
	estimates store rp4`var'
}
restore

esttab rp3lcomp rp3lair rp3lasent rp4lcomp rp4lair rp4lasent using TableS10.rtf, star(* .1 ** .05  *** .01) nogap nonumber replace se(%5.4f) ar2 aic(%10.4f) bic(%10.4f)

**********Make Table S11*************
local lags 0 30 60
foreach lag of loc lags{
preserve
drop if year ==2017
keep if time <=(148-`lag')
gen post = time >148-30-`lag'
gen treat_b = (prov ==13 |prov ==15 | prov ==23| prov ==32|prov ==36|prov ==41|prov ==45|prov ==53|prov ==64|prov ==44)
replace negative_air = round(negative_air*10)
reghdfe lpm post treat negative_air c.treat#c.negative_air c.post#c.negative_air c.treat#c.post c.post#c.treat#c.negative_air tem pre win, absorb(i.time i.city i.city#c.time) vce(cluster city)
estimates store rp1_`lag'
restore	
}

esttab rp1_0 rp1_30 rp1_60 using TableS11.rtf, star(* .1 ** .05  *** .01) nogap nonumber replace se(%5.4f) ar2 aic(%10.4f) bic(%10.4f)


*************************************************
*        Rregression discontinuity design       *
*************************************************
**********Make Table S12*************
*Third Batch
preserve
keep if year == 2017
keep if round == 3 
keep if runv >= -34 & runv <= 34
local vars lcomp lair lasent
foreach var of loc vars {
reghdfe `var'  c.postv runv  c.runv#c.postv pm25 tem pre win , absorb(i.day i.week i.city ) vce(cluster city)
estimates store rdd3`var'
}
restore

*Fourth Batch
preserve
keep if year == 2017
keep if round == 4
keep if runv >= -39 & runv <= 39
local vars lcomp lair lasent
foreach var of loc vars {
reghdfe `var'  c.postv runv  c.runv#c.postv pm25 tem pre win , absorb(i.day i.week i.city ) vce(cluster city)
estimates store rdd4`var'
}
restore

esttab  rdd3lcomp rdd3lair rdd3lasent rdd4lcomp rdd4lair rdd4lasent using TableS12.rtf,star(* .1 ** .05  *** .01) nogap nonumber replace se(%5.4f) ar2 aic(%10.4f) bic(%10.4f)

**********Make Table S13*************
preserve
keep if year == 2017
keep if round == 3 
keep if runv >= -34 & runv <= 34
local vars lpm laqi
foreach var of loc vars {
reghdfe `var'  c.postv runv  c.runv#c.postv tem pre win , absorb(i.day i.week i.city ) vce(cluster city)
estimates store rdd3`var'
}
restore

preserve
keep if year == 2017
keep if round == 4
keep if runv >= -39 & runv <= 39
local vars lpm laqi
foreach var of loc vars {
reghdfe `var'  c.postv runv  c.runv#c.postv tem pre win , absorb(i.day i.week i.city ) vce(cluster city)
estimates store rdd4`var'
}
restore
esttab  rdd3lpm rdd3laqi rdd4lpm rdd4laqi using TableS13.rtf,star(* .1 ** .05  *** .01) nogap nonumber replace se(%5.4f) ar2 aic(%10.4f) bic(%10.4f)