*==============================================================*
*  TFM - ECB communication tone and euro-area sovereign yields
*  Estimacion (all_tone + qa_tone, 3 vencimientos), identidad
*  en dos pasos, robustez, inferencia y exportacion a LaTeX.
*==============================================================*

* --- rutas (AJUSTA si cambia la carpeta) ---
global DATA "C:\Users\PC\Desktop\TFM\Stata"
global OUT  "C:\Users\PC\Desktop\TFM\tfmecon-25_26-garro"

/* PART 1: GLOBAL (LEVEL) EFFECT OF TONE  --  Route 1 & Route 2
Answers "does tone move sovereign yields at all?"*/

use "$DATA\FULL DATASET 10Y .dta", clear
encode country, gen(country_id)
egen   meeting_id = group(date)


*--------------------------------------------------------------*
* ROUTE 1 -- LEVELS.
* Drop meeting FE (delta_m) and add the tone/factor MAIN effects.
* Keep country FE (eta_i); D_i is time-invariant within country,
* hence absorbed by country FE and not entered on its own.
*   all_tone        -> alpha : common (core) response   [GLOBAL]
*   D_i_x_all_tone  -> beta  : periphery - core          [differential]
*   alpha + beta            -> periphery response
* Cluster by meeting: effective N is ~104 meetings, not N x M.
*--------------------------------------------------------------*
areg dY all_tone D_i_x_all_tone F_target D_i_x_F_target, ///
    absorb(country_id) vce(cluster meeting_id)
estimates store GLOB1

* periphery total response (alpha + beta) with clustered SE
lincom all_tone + D_i_x_all_tone

lincom F_target + D_i_x_F_target

*--------------------------------------------------------------*
* ROUTE 2 -- TWO-STEP.
* Estimate the FE DiD (same spec as ALL10) to recover the
* estimated meeting effects delta_m_hat, then regress them on
* tone across meetings.
*
* IMPORTANT: this is NOT the TWOSTEP block above. That one
* reproduces BETA (the periphery-core difference). This one
* recovers ALPHA (the common level). Same "two-step" name,
* different estimand.
*   coef on all_tone in step B = alpha  -> should ~ GLOB1's alpha
*--------------------------------------------------------------*
* step A: FE DiD to extract delta_m_hat
areg dY D_i_x_all_tone D_i_x_F_target i.country_id, absorb(meeting_id)
predict double delta_m_hat, d          // estimated meeting effects

* step B: regress meeting effects on tone (one obs per meeting)
preserve
    collapse (mean) delta_m_hat all_tone F_target, by(meeting_id)
    regress delta_m_hat all_tone F_target
    estimates store GLOB2
    * NOTE: these SEs are NOT valid -- delta_m_hat is a generated
    * regressor. For inference on alpha use GLOB1's clustered SE,
    * or the optional bootstrap block below.
restore

*==============================================================*
* OPTIONAL -- valid inference for Route 2 (generated regressor)
*     Manual block bootstrap over meetings of the WHOLE two-step.
*     Slow: reps x (areg + collapse + regress). Start at 999;
*     raise to 9999 to mirror the boottest setting.
*     Route 1's clustered SE is already valid, so run this only if
*     you want to report an SE for the Route 2 column itself.
*==============================================================*
tempfile bootres
tempname P
postfile `P' double alpha using `bootres', replace

set seed 12345
local reps 999
forvalues b = 1/`reps' {
    preserve
        bsample, cluster(meeting_id) idcluster(bmid)
        quietly areg dY D_i_x_all_tone D_i_x_F_target i.country_id, absorb(bmid)
        quietly predict double dh, d
        quietly collapse (mean) dh all_tone F_target, by(bmid)
        quietly regress dh all_tone F_target
        post `P' (_b[all_tone])
    restore
}
postclose `P'

preserve
    use `bootres', clear
    quietly summarize alpha
    display as text "Route 2 bootstrap SE(alpha) = " as result r(sd)
    centile alpha, centile(2.5 97.5)     // 95% percentile CI
restore



/*PART 2: DIFFERENTIAL EFFECT BETWEEN CORE AND PERIPHERY*/
*==============================================================*
* 1) 10 AÑOS: all_tone, qa_tone, sin Francia, dos pasos, bootstrap
*==============================================================*
use "$DATA\FULL DATASET 10Y .dta", clear
encode country, gen(country_id)
egen   meeting_id = group(date)

* comprobacion rapida
corr all_tone F_target

* baseline (all_tone)
areg dY D_i_x_all_tone D_i_x_F_target i.country_id, ///
    absorb(meeting_id) vce(cluster meeting_id)
estimates store ALL10

* mismo DiD con qa_tone
areg dY D_i_x_qa_tone D_i_x_F_target i.country_id, ///
    absorb(meeting_id) vce(cluster meeting_id)
estimates store QA10

* sin Francia (all_tone)  -- OJO: guardar ANTES de sobreescribir la muestra
areg dY D_i_x_all_tone D_i_x_F_target i.country_id if country!="FR", ///
    absorb(meeting_id) vce(cluster meeting_id)
estimates store SINFR

* identidad en dos pasos (misma beta que ALL10, hecha a mano)
preserve
    collapse (mean) dY F_target all_tone, by(meeting_id D_i)
    reshape wide dY, i(meeting_id) j(D_i)
    gen d_diff = dY1 - dY0                 // periferia - core
    list meeting_id dY0 dY1 d_diff all_tone in 1/5
    regress d_diff all_tone F_target, cluster(meeting_id)
    estimates store TWOSTEP
restore

* inferencia: wild cluster bootstrap (sobre el baseline 10Y)
quietly regress dY D_i_x_all_tone D_i_x_F_target i.country_id i.meeting_id, ///
    cluster(meeting_id)
boottest D_i_x_all_tone, reps(9999) cluster(meeting_id) nograph
* -> anota a mano en el texto el p-valor y el IC 95% que devuelve

*==============================================================*
* 2) 5 AÑOS: all_tone y qa_tone
*==============================================================*
use "$DATA\FULL DATASET 5Y .dta", clear
encode country, gen(country_id)
egen   meeting_id = group(date)

areg dY D_i_x_all_tone D_i_x_F_target i.country_id, ///
    absorb(meeting_id) vce(cluster meeting_id)
estimates store ALL5

areg dY D_i_x_qa_tone D_i_x_F_target i.country_id, ///
    absorb(meeting_id) vce(cluster meeting_id)
estimates store QA5

*==============================================================*
* 3) 2 AÑOS: all_tone y qa_tone
*==============================================================*
use "$DATA\FULL DATASET 2Y .dta", clear
encode country, gen(country_id)
egen   meeting_id = group(date)

areg dY D_i_x_all_tone D_i_x_F_target i.country_id, ///
    absorb(meeting_id) vce(cluster meeting_id)
estimates store ALL2

areg dY D_i_x_qa_tone D_i_x_F_target i.country_id, ///
    absorb(meeting_id) vce(cluster meeting_id)
estimates store QA2

*==============================================================*
* 4) EXPORTAR TABLAS A LaTeX  (fragment = solo el tabular)
*==============================================================*
* Nota: etiquetas en modo mate \$...\$ y guion normal. Si esttab
* escribe  D\_{i}  con barra, corrige a mano  D\_{i} -> D_{i}
* en el .tex (es formato, no dato).

local LALL D_i_x_all_tone "\$D_{i}\times\$ Tone" D_i_x_F_target "\$D_{i}\times\$ F-target"

local LMIX D_i_x_all_tone "\$D_{i}\times\$ Tone (all)" ///
           D_i_x_qa_tone  "\$D_{i}\times\$ Tone (Q\&A)" ///
           D_i_x_F_target "\$D_{i}\times\$ F-target"

*--- TABLE 0: GLOBAL (LEVEL) EFFECT: Route 1 vs Route 2	

esttab GLOB1 GLOB2 using "$OUT\tab_global.tex", replace ///
    keep(all_tone D_i_x_all_tone F_target D_i_x_F_target) ///
    order(all_tone D_i_x_all_tone F_target D_i_x_F_target) ///
    mtitles("Levels (R1)" "Two-step (R2)") ///
    coeflabels(all_tone "\$\alpha\$: Tone (global)" ///
               D_i_x_all_tone "\$\beta\$: \$D_{i}\times\$ Tone" ///
               F_target "F-target" ///
               D_i_x_F_target "\$D_{i}\times\$ F-target") ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N r2, labels("Observations" "R-squared") fmt(0 3)) ///
    booktabs fragment nonumbers	 

*--- TABLA A: PRINCIPAL (baseline 10Y + identidad en dos pasos) ---
esttab ALL10 TWOSTEP using "$OUT\tab_principal.tex", replace ///
    keep(D_i_x_all_tone all_tone D_i_x_F_target F_target) ///
    mtitles("DiD (FE)" "Two-step") ///
    coeflabels(D_i_x_all_tone "\$D_{i}\times\$ Tone" ///
               all_tone "Tone (diff.)" ///
               D_i_x_F_target "\$D_{i}\times\$ F-target" ///
               F_target "F-target (diff.)") ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N r2, labels("Observations" "R-squared") fmt(0 3)) ///
    booktabs fragment nonumbers

*--- TABLA B: ROBUSTEZ DE VENCIMIENTOS (all_tone: 10Y, 5Y, 2Y) ---
esttab ALL10 ALL5 ALL2 using "$OUT\tab_vencimientos.tex", replace ///
    keep(D_i_x_all_tone D_i_x_F_target) ///
    mtitles("10Y" "5Y" "2Y") ///
    coeflabels(`LALL') ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N r2, labels("Observations" "R-squared") fmt(0 3)) ///
    booktabs fragment nonumbers

*--- TABLA C: ROBUSTEZ SIN FRANCIA (con vs sin, 10Y) ---
esttab ALL10 SINFR using "$OUT\tab_francia.tex", replace ///
    keep(D_i_x_all_tone D_i_x_F_target) ///
    mtitles("With France" "Without France") ///
    coeflabels(`LALL') ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N r2, labels("Observations" "R-squared") fmt(0 3)) ///
    booktabs fragment nonumbers

*--- TABLA D: DESCOMPOSICION all_tone vs qa_tone (3 vencimientos) ---
esttab ALL10 QA10 ALL5 QA5 ALL2 QA2 using "$OUT\tab_all_vs_qa.tex", replace ///
    keep(D_i_x_all_tone D_i_x_qa_tone D_i_x_F_target) ///
    mgroups("10Y" "5Y" "2Y", pattern(1 0 1 0 1 0) ///
            prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
    mtitles("all" "Q\&A" "all" "Q\&A" "all" "Q\&A") ///
    coeflabels(`LMIX') ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N r2, labels("Observations" "R-squared") fmt(0 3)) ///
    booktabs fragment nonumbers

*--- TABLA E: SALIDA COMPLETA del baseline 10Y ---------------*
*   todas las filas (pais, constante) y columnas (b, se, t, p, IC)
*   pensada para APENDICE: es ancha, puede necesitar \resizebox
esttab ALL10 using "$OUT\tab_baseline_full.tex", replace ///
    cells("b(fmt(3)) se(fmt(3)) t(fmt(2)) p(fmt(3)) ci(fmt(3))") ///
    coeflabels(D_i_x_all_tone "\$D_{i}\times\$ Tone" ///
               D_i_x_F_target "\$D_{i}\times\$ F-target" ///
               2.country_id "Spain (ES)" ///
               3.country_id "France (FR)" ///
               4.country_id "Italy (IT)" ///
               _cons "Constant") ///
    stats(N F r2 r2_a rmse, ///
          labels("Observations" "F-stat" "R-squared" "Adj. R-squared" "Root MSE") ///
          fmt(0 3 3 3 3)) ///
    booktabs fragment nonumbers varwidth(22)

*==============================================================*
* FIN
*==============================================================*
