cd ~\02data
/// the authors do no have the permission to share the data
insheet using inspection.csv ,clear 

gen time1 = date(date,"YMD")
xtset city time1
gen lpm=log(pm25)
gen laqi = log(aqi)
gen lcomp = log(comp+1)
gen lair = log(comp_air+1)
gen lsent = log(negative_comp+1)
gen lasent = log(negative_air+1)
gen postv = assignment_start >0
gen runv = assignment_start
gen treat = round >2

****Difference in Difference***
*********************************
*        Code for Table 1       *
*********************************
** third round-direct effect
preserve
drop if year ==2018
drop if round == 4
keep if time <=146
drop if comp_air >10
gen post = time >112
local vars lcomp lair lasent
foreach var of loc vars  {
 	reghdfe `var' post treat c.post#c.treat pm25 tem pre win, absorb(i.time i.city i.city#c.time) vce(cluster city)
	estimates store r`var'
}	
esttab rlcomp rlair rlasent using Table1_3.rtf, star(* .1 ** .05  *** .01) nogap nonumber replace se(%5.4f) ar2 aic(%10.4f) bic(%10.4f)
restore

** fourth round-direct effect
preserve
drop if year == 2018
drop if round == 3
keep if time < = 256
gen post = time >217
drop if comp_air >16
local vars lcomp lair lasent
foreach var of loc vars  {
 	reghdfe `var' post treat c.post#c.treat tem pre win, absorb(i.time i.city i.city#c.time) vce(cluster city)
	estimates store r`var'
}
esttab rlcomp rlair rlasent using Table1_4.rtf, star(* .1 ** .05  *** .01) nogap nonumber replace se(%5.4f) ar2 aic(%10.4f) bic(%10.4f)
restore

***********************************************
*        Code for Figure 3 and Figure 4       *
***********************************************
*third round-long term effect
drop if round == 4
keep if time <=218
drop if comp_air >10
gen post = time >112
local vars lcomp lair lasent lpm laqi
foreach var of loc vars {
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
 legend(off)  xtitle("") ytitle(ln(Public Complaints), size(small)) graphregion(color(white))
  graph save "~\02data\Plot\figure_long_3`var'.gph",replace
restore
}

*fourth round-long term effect
drop if round == 3
gen post = time >217
drop if comp_air >16
local vars lcomp lair lasent lpm laqi
foreach var of loc vars {
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
 legend(off)  xtitle("") ytitle(ln(Public Complaints), size(small)) graphregion(color(white))
   graph save "~\02data\Plot\figure_long_4`var'.gph",replace
restore
}
preserve
cd ~\02data\Plot
graph combine figure_long_3lcomp.gph figure_long_3lair.gph figure_long_3lasent.gph  figure_long_4lcomp.gph figure_long_4lair.gph figure_long_4lasent.gph, imargin(vsmall) graphregion(color(white)) 
restore
preserve
cd ~\02data\Plot
graph combine figure_long_3lpm.gph figure_long_3laqi.gph figure_long_4lpm.gph figure_long_4laqi.gph, imargin(vsmall) graphregion(color(white)) 
restore

*********************************
*        Code for Table 2       *
*********************************
*interaction effect-third round
preserve
drop if year == 2018
drop if round == 4
keep if time <=146
drop if comp_air >10
gen post = time >112
replace negative_air = round(negative_air*10)
local vars lpm laqi 
local invars comp_air negative_air
foreach var of loc vars  {
	foreach invar of loc invars{
		 	reghdfe `var' post treat `invar' c.treat#c.`invar' c.post#c.`invar' c.treat#c.post c.post#c.treat#c.`invar' tem pre win, absorb(i.time i.city i.city#c.time) vce(cluster city)
			estimates store `invar'r`var'	
//			
//			reghdfe `var' post treat `invar' c.treat#c.`invar' c.post#c.`invar' c.treat#c.post c.post#c.treat#i.`invar'  tem pre win, absorb(i.time i.city i.city#c.time) vce(cluster city)
//			estimates store r1
//			coefplot (r1,drop(_cons)  ), vert yline(0,lwidth(thin) lcolor(black) lpattern(dash))  
	}
}
esttab comp_airrlpm negative_airrlpm comp_airrlaqi negative_airrlaqi using Table2_3.rtf, star(* .1 ** .05  *** .01)   nogap      nonumber replace se(%5.4f) ar2 aic(%10.4f) bic(%10.4f)
restore

*interaction effect-third round-after
preserve
drop if round == 4
drop if year == 2018
drop if time >112 & time <=(146+30)
keep if time <=(180+30)
drop if comp_air >10
gen post = time >112
replace negative_air = round(negative_air*10)
local vars laqi lpm
local invars comp_air negative_air
foreach var of loc vars  {
	foreach invar of loc invars{
		 	reghdfe `var' post treat `invar' c.treat#c.`invar' c.post#c.`invar' c.treat#c.post c.post#c.treat#c.`invar' tem pre win, absorb(i.time i.city i.city#c.time) vce(cluster city)
			estimates store `invar'r`var'	
//			
//			reghdfe `var' post treat `invar' c.treat#c.`invar' c.post#c.`invar' c.treat#c.post c.post#c.treat#i.`invar'  tem pre win, absorb(i.time i.city i.city#c.time) vce(cluster city)
//			estimates store r1
//			coefplot (r1,drop(_cons)  ), vert yline(0,lwidth(thin) lcolor(black) lpattern(dash))  
	}
}
esttab comp_airrlpm negative_airrlpm comp_airrlaqi negative_airrlaqi using Table2a_3.rtf, star(* .1 ** .05  *** .01)   nogap      nonumber replace se(%5.4f) ar2 aic(%10.4f) bic(%10.4f)
restore

*interaction effect-fourth round
preserve
drop if year == 2018
drop if round == 3
keep if time < = 256
gen post = time >217
drop if comp_air >16
replace negative_air = round(negative_air*10)
local vars laqi lpm
local invars comp_air negative_air
foreach var of loc vars  {
	foreach invar of loc invars{
		 	reghdfe `var' post treat `invar' c.treat#c.`invar' c.post#c.`invar' c.treat#c.post c.post#c.treat#c.`invar' tem pre win, absorb(i.time i.city i.city#c.time) vce(cluster city)
	estimates store `invar'r`var'	
//			
//			reghdfe `var' post treat `invar' c.treat#c.`invar' c.post#c.`invar' c.treat#c.post c.post#c.treat#i.`invar'  tem pre win, absorb(i.time i.city i.city#c.time) vce(cluster city)
//			estimates store r1
//			coefplot (r1,drop(_cons)  ), vert yline(0,lwidth(thin) lcolor(black) lpattern(dash))  
	}
}
esttab comp_airrlpm negative_airrlpm comp_airrlaqi negative_airrlaqi using Table2_4.rtf, star(* .1 ** .05  *** .01)   nogap      nonumber replace se(%5.4f) ar2 aic(%10.4f) bic(%10.4f)
restore

*interaction effect-fourth round-after
preserve
drop if year == 2018
drop if round == 3
drop if time > 217 & time <=(256+30)
keep if time <=(295+30)
gen post = time >217
drop if comp_air >16
replace negative_air = round(negative_air*10)
local vars laqi lpm
local invars comp_air negative_air
foreach var of loc vars  {
	foreach invar of loc invars{
		 	reghdfe `var' post treat `invar' c.treat#c.`invar' c.post#c.`invar' c.treat#c.post c.post#c.treat#c.`invar' tem pre win, absorb(i.time i.city i.city#c.time) vce(cluster city)
	estimates store `invar'r`var'	
esttab `invar'r`var' using `invar'r`var'_inter4.rtf, star(* .1 ** .05  *** .01)   nogap      nonumber replace se(%5.4f) ar2 aic(%10.4f) bic(%10.4f)
//			
//			reghdfe `var' post treat `invar' c.treat#c.`invar' c.post#c.`invar' c.treat#c.post c.post#c.treat#i.`invar'  tem pre win, absorb(i.time i.city i.city#c.time) vce(cluster city)
//			estimates store r1
//			coefplot (r1,drop(_cons)  ), vert yline(0,lwidth(thin) lcolor(black) lpattern(dash))  
	}
}
esttab comp_airrlpm negative_airrlpm comp_airrlaqi negative_airrlaqi using Table2a_4.rtf, star(* .1 ** .05  *** .01)   nogap      nonumber replace se(%5.4f) ar2 aic(%10.4f) bic(%10.4f)
restore

**********************************
*        Code for Table S2       *
**********************************
*Long-term effects for third round
preserve
drop if year ==2018
drop if round == 4
drop if comp_air >10
gen post = time >112
gen end  = 0
forvalues i = 1(1)53 {
  replace end = `i' if time >= (0+(`i'-1)*7) & time < (0+`i'*7)
}
drop if end >=28
local vars lcomp lair lasent
foreach var of loc vars  {
 	reghdfe `var' post treat c.post#c.treat#i.end pm25 tem pre win, absorb(    i.time i.city i.city#c.time) vce(cluster city)
	estimates store rw`var'
}	
esttab rwlcomp rwlair rwlasent using TableS2_3.rtf, star(* .1 ** .05  *** .01)   nogap      nonumber replace se(%5.4f) ar2 aic(%10.4f) bic(%10.4f)
restore

*Long-term effects for fourth round
preserve
drop if year ==2018
drop if round == 3
drop if comp_air >16
gen post = time >217
gen end  = 0
forvalues i = 1(1)53 {
  replace end = `i' if time >= (0+(`i'-1)*7) & time < (0+`i'*7)
}
drop if end >=44
local vars lcomp lair lasent
foreach var of loc vars  {
 	reghdfe `var' post treat c.post#c.treat#i.end pm25 tem pre win, absorb(    i.time i.city i.city#c.time) vce(cluster city)
	estimates store rw`var'
}	
esttab rwlcomp rwlair rwlasent using rw_4.rtf, star(* .1 ** .05  *** .01)   nogap      nonumber replace se(%5.4f) ar2 aic(%10.4f) bic(%10.4f)
restore

**********************************
*        Code for Table S3       *
**********************************
** third round-direct effect
preserve
drop if year ==2018
drop if round == 4
keep if time <=146
drop if comp_air >10
gen post = time >112
local vars lpm laqi
foreach var of loc vars  {
 	reghdfe `var' post treat c.post#c.treat tem pre win, absorb(i.time i.city i.city#c.time) vce(cluster city)
	estimates store r`var'
}	
esttab rlpm rlaqi using tables3_3.rtf, star(* .1 ** .05  *** .01) nogap nonumber replace se(%5.4f) ar2 aic(%10.4f) bic(%10.4f)
restore

** fourth round-direct effect
preserve
drop if year == 2018
drop if round == 3
keep if time < = 256
gen post = time >217
drop if comp_air >16
local vars lpm laqi
foreach var of loc vars  {
 	reghdfe `var' post treat c.post#c.treat tem pre win, absorb(i.time i.city i.city#c.time) vce(cluster city)
	estimates store r`var'
}
esttab rlpm rlaqi using tables3_4.rtf, star(* .1 ** .05  *** .01) nogap nonumber replace se(%5.4f) ar2 aic(%10.4f) bic(%10.4f)
restore

**********************************
*        Code for Table S4       *
**********************************
*Long-term effects for third round
preserve
drop if year ==2018
drop if round == 4
drop if comp_air >10
gen post = time >112
gen end  = 0
forvalues i = 1(1)53 {
  replace end = `i' if time >= (0+(`i'-1)*7) & time < (0+`i'*7)
}
drop if end >=28
local vars lpm laqi
foreach var of loc vars  {
 	reghdfe `var' post treat c.post#c.treat#i.end tem pre win, absorb(    i.time i.city i.city#c.time) vce(cluster city)
	estimates store rw`var'
}	
esttab rwlpm rwlaqi using tables4_3.rtf, star(* .1 ** .05  *** .01)   nogap      nonumber replace se(%5.4f) ar2 aic(%10.4f) bic(%10.4f)
restore

*Long-term effects for fourth round
preserve
drop if year ==2018
drop if round == 3
drop if comp_air >16
gen post = time >217
gen end  = 0
forvalues i = 1(1)53 {
  replace end = `i' if time >= (0+(`i'-1)*7) & time < (0+`i'*7)
}
drop if end >=44
local vars lpm laqi
foreach var of loc vars  {
 	reghdfe `var' post treat c.post#c.treat#i.end tem pre win, absorb(    i.time i.city i.city#c.time) vce(cluster city)
	estimates store rw`var'
}	
esttab rwlpm rwlaqi using tables4_4.rtf, star(* .1 ** .05  *** .01)   nogap      nonumber replace se(%5.4f) ar2 aic(%10.4f) bic(%10.4f)
restore

***********************************
*        Code for Figure S2       *
***********************************
*Parallel trend test:plot*  laqi  lsent 
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
 graph save "~\02data\Plot\figure_`var'.gph",replace
 restore
} 
preserve
cd ~\02data\Plot
graph combine figure_lcomp.gph figure_lair.gph figure_lasent.gph  figure_lpm.gph, imargin(vsmall) graphregion(color(white)) 
restore

***********************************
*        Code for Figure S3       *
***********************************
*Parallel trend test-third round
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
  graph save "~\02data\Plot\figure_paral_3`var'.gph",replace
}
restore

*Parallel trend test
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
  graph save "~\02data\Plot\figure_paral_4`var'.gph",replace
}
restore

preserve
cd ~\02data\Plot
graph combine figure_paral_3lcomp.gph figure_paral_3lair.gph figure_paral_3lasent.gph figure_paral_4lcomp.gph figure_paral_4lair.gph figure_paral_4lasent.gph, imargin(vsmall) graphregion(color(white)) 
restore

****robustness checks***
**********************************
*        Code for Table S5       *
**********************************
*Placebo test
*third round - direct effect
preserve
drop if year ==2017
drop if round == 4
keep if time <=146
gen post = time >112
local vars lcomp lair lasent
foreach var of loc vars  {
 	reghdfe `var' post treat c.post#c.treat pm25 tem pre win, absorb(i.time i.city i.city#c.time) vce(cluster city)
	estimates store r`var'
}	
esttab rlcomp rlair rlasent using TableS5_3.rtf, star(* .1 ** .05  *** .01) nogap nonumber replace se(%5.4f) ar2 aic(%10.4f) bic(%10.4f)
restore

** fourth round - direct effect
preserve
drop if year ==2017
drop if round == 3
keep if time < = 256 & time >= 35
gen post = time >217
local vars lcomp lair lasent 
foreach var of loc vars  {
 	reghdfe `var' post treat c.post#c.treat pm25 tem pre win, absorb(i.time i.city i.city#c.time) vce(cluster city)
	estimates store r`var'
}
esttab rlcomp rlair rlasent using TableS5_4.rtf, star(* .1 ** .05  *** .01) nogap nonumber replace se(%5.4f) ar2 aic(%10.4f) bic(%10.4f)
restore

**Rregression discontinuity design****
**********************************
*        Code for Table S6       *
**********************************
preserve
keep if year == 2017
keep if round == 3 
keep if runv >= -34 & runv <= 34
drop if comp_air >10
local vars lcomp lair lasent
foreach var of loc vars {
reghdfe `var'  c.postv runv  c.runv#c.postv pm25 tem pre win , absorb(i.day i.week i.city ) vce(cluster city)
estimates store r`var'
}
esttab  rlcomp rlair rlasent using TableS6_3.rtf,star(* .1 ** .05  *** .01) nogap nonumber replace se(%5.4f) ar2 aic(%10.4f) bic(%10.4f)
restore

preserve
keep if year == 2017
keep if round == 4
keep if runv >= -39 & runv <= 39
drop if comp_air >16
local vars lcomp lair lasent
foreach var of loc vars {
reghdfe `var'  c.postv runv  c.runv#c.postv pm25 tem pre win , absorb(i.day i.week i.city ) vce(cluster city)
estimates store r`var'
}
esttab  rlcomp rlair rlasent using TableS6_4.rtf,star(* .1 ** .05  *** .01) nogap nonumber replace se(%5.4f) ar2 aic(%10.4f) bic(%10.4f)
restore


**********************************
*        Code for Table S7       *
**********************************
preserve
keep if year == 2017
keep if round == 3 
keep if runv >= -34 & runv <= 34
drop if comp_air >10
local vars lpm laqi
foreach var of loc vars {
reghdfe `var'  c.postv runv  c.runv#c.postv tem pre win , absorb(i.day i.week i.city ) vce(cluster city)
estimates store r`var'
}
esttab  rlpm rlaqi using TableS7_3.rtf,star(* .1 ** .05  *** .01) nogap nonumber replace se(%5.4f) ar2 aic(%10.4f) bic(%10.4f)
restore

preserve
keep if year == 2017
keep if round == 4
keep if runv >= -39 & runv <= 39
drop if comp_air >16
local vars lpm laqi
foreach var of loc vars {
reghdfe `var'  c.postv runv  c.runv#c.postv tem pre win , absorb(i.day i.week i.city ) vce(cluster city)
estimates store r`var'
}
esttab  rlpm rlaqi using TableS7_4.rtf,star(* .1 ** .05  *** .01) nogap nonumber replace se(%5.4f) ar2 aic(%10.4f) bic(%10.4f)
restore
