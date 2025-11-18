***** IMPORT ANNUAL DATA *****
clear all
cls

global new "/Users/ASUS/Dropbox/NUS RA/RA Thinh/"
global raw "/Users/ASUS/Dropbox/NUS RA/raw/"
global overleaf "/Users/ASUS/Dropbox/Apps/Overleaf/Leverage Regressions/tables/"


***** Predict target debt ratio when refinancing
use "$new/data_tmp/reg_a.dta", clear
use "$raw/ccm_a_70_25.dta", clear

****** Replicate Table IV in Byoun 2008

	* Pre-filter
	rename *, lower
	destring sic gvkey, replace
	keep if fic == "USA" 
	keep if linkprim == "P"  | linkprim == "C" 
	
	* Filter the year range
	keep if inrange(fyear, 1971, 2003)
	display _N

	* Filter the SIC code to remove financial firms and regulated utilities: SIC 6000-6799 and 4800-4999
	keep if !inrange(sic, 6000, 6799) & !inrange(sic, 4800, 4999)
	display _N
	
	* Variable preps
	gen mrktval_equity = prcc_f*csho
	gen bookval_equity = seq
	gen bookval_asset = at
	
	*gen deffered_tax = cond(missing(!txditc), txditc, 0)
	
	gen deffered_tax = txditc
	gen preferred_stock_val = cond(!missing(pstkl), pstkl, cond(!missing(pstkrv), pstkrv, .))
	gen mrktval_asset = bookval_asset - bookval_equity - deffered_tax + mrktval_equity + preferred_stock_val
	
	gen total_debt = dltt + dlc
	gen longtm_debt = dltt + dd1
	
	gen td_ba = total_debt / bookval_asset 
	gen td_ma = total_debt / mrktval_asset
	gen ld_ba = longtm_debt / bookval_asset
	gen ld_ma = longtm_debt / mrktval_asset
	label variable td_ba "$TD/BA$"
	label variable td_ma "$TD/MA$"
	label variable ld_ba "$LD/BA$"
	label variable ld_ma "$LD/MA$"
	
	* Variable construction
	gen IndGroup = substr(string(sic), 1, 2)
	sort fyear IndGroup
	by fyear IndGroup: egen Med_td_ba = median(td_ba)
	by fyear IndGroup: egen Med_td_ma = median(td_ma)
	by fyear IndGroup: egen Med_ld_ba = median(ld_ba)
	by fyear IndGroup: egen Med_ld_ma = median(ld_ma)
	label variable Med_td_ba "Med"
	label variable Med_td_ma "Med"
	label variable Med_ld_ba "Med"
	label variable Med_ld_ma "Med"
	
	gen statutory_tax_rate = . 
	replace statutory_tax_rate = 0.48 if inrange(fyear, 1971, 1978) 
	replace statutory_tax_rate = 0.46 if inrange(fyear, 1979, 1986) 
	replace statutory_tax_rate = 0.40 if fyear == 1987 
	replace statutory_tax_rate = 0.34 if inrange(fyear, 1988, 1992) 
	replace statutory_tax_rate = 0.35 if inrange(fyear, 1993, 2003)
	gen Tax = 0 
	replace Tax = statutory_tax_rate if txt > 0 & pi > 0
	
	gen OI = oibdp / bookval_asset

	gen MB = mrktval_asset / bookval_asset

	gen LnA = log(bookval_asset)

	gen DEP = dp / bookval_asset 

	gen FA = ppent / bookval_asset 
	
	gen xrd_0 = xrd
	replace xrd_0 = 0 if missing(xrd)
	gen RND = xrd_0 / sale
	drop xrd_0
	gen D_RND = 0
	replace D_RND = 1 if missing(xrd)

	gen DIV = dv / bookval_asset

	gen AZ = (3.3 * (oibdp - dp) + sale + 1.4 * re + 1.2 * (act - lct)) / bookval_asset 
	
	* Post-filters
	keep if !missing(bookval_asset, bookval_equity, mrktval_equity, sale) & bookval_asset>0 & bookval_equity>0 & mrktval_equity>0 & sale>0
	
	keep if !missing(td_ba, td_ma, ld_ba, ld_ma, Med_td_ba, Med_ld_ba, Med_td_ma, Med_ld_ma, Tax, OI, MB, LnA, DEP, FA, RND, D_RND, DIV, AZ)
	xtset gvkey fyear
	
	* Winsorize at percentile 1% and 99% for all variables
	*local winsor_vars_0199 "td_ba td_ma ld_ba ld_ma OI MB LnA DEP FA AZ" 
	local winsor_vars_0199 "OI MB DEP FA AZ" 
	foreach var of local winsor_vars_0199 { 
	winsor2 `var', replace cut(1 99) 
	} 

	* Except for RND and DIV only winsorize at percentile 99%
	local winsor_vars_0099 "RND DIV" 
	foreach var of local winsor_vars_0099 { 
	winsor2 `var', replace cut(0 99)
	} 

	* List out lagged variables
	local x_vars "td_ba td_ma ld_ba ld_ma Med_td_ba Med_ld_ba Med_td_ma Med_ld_ma Tax OI MB LnA DEP FA RND D_RND DIV AZ"

	* Generate lagged variables
	foreach var of local x_vars {
		gen L2_`var' = L2.`var'
	}
	foreach var of local x_vars {
		gen L1_`var' = L1.`var'
	}
	foreach var of local x_vars {
		gen L0_`var' = `var'
	}
	drop `x_vars'
	
	local lag0_x_vars "L0_td_ba L0_td_ma L0_ld_ba L0_ld_ma L0_Med_td_ba L0_Med_ld_ba L0_Med_td_ma L0_Med_ld_ma L0_Tax L0_OI L0_MB L0_LnA L0_DEP L0_FA L0_RND L0_D_RND L0_DIV L0_AZ"
	local lag1_x_vars "L1_td_ba L1_td_ma L1_ld_ba L1_ld_ma L1_Med_td_ba L1_Med_ld_ba L1_Med_td_ma L1_Med_ld_ma L1_Tax L1_OI L1_MB L1_LnA L1_DEP L1_FA L1_RND L1_D_RND L1_DIV L1_AZ"
	local lag2_x_vars "L2_td_ba L2_td_ma L2_ld_ba L2_ld_ma L2_Med_td_ba L2_Med_ld_ba L2_Med_td_ma L2_Med_ld_ma L2_Tax L2_OI L2_MB L2_LnA L2_DEP L2_FA L2_RND L2_D_RND L2_DIV L2_AZ"
	preserve
	
	eststo clear
	
	* Regressors
	foreach var of local lag0_x_vars {
    local newname = subinstr("`var'", "L0_", "", 1)
    rename `var' `newname'
	}
	local regressor_vars "Tax OI MB LnA DEP FA RND D_RND DIV AZ"
	
	* Perform regression for Equation (7) 
	display "--- Pooled OLS Regression for Equation 7 on Total Debt / Book Value of Assets (TD/BA) ---"
	rename Med_td_ba Med
	qui: eststo eq7_td_ba: quietly regress td_ba Med `regressor_vars'
	estimates store eq7_td_ba, title("TD/BA")
	rename Med Med_td_ba

	display "--- Pooled OLS Regression for Equation 7 on Total Debt / Market Value of Assets (TD/MA) ---"
	rename Med_td_ma Med
	qui: eststo eq7_td_ma: quietly regress td_ma Med `regressor_vars'
	estimates store eq7_td_ma, title("TD/MA")
	rename Med Med_td_ma

	display "--- Pooled OLS Regression for Equation 7 on Long-term Debt / Book Value of Assets (LD/BA) ---"
	rename Med_ld_ba Med
	qui: eststo eq7_ld_ba: quietly regress ld_ba Med `regressor_vars'
	estimates store eq7_ld_ba, title("LD/BA")
	rename Med Med_ld_ba
	
	display "--- Pooled OLS Regression for Equation 7 on Long-term Debt / Market Value of Assets (LD/MA) ---"
	rename Med_ld_ma Med
	qui: eststo eq7_ld_ma: quietly regress ld_ma Med `regressor_vars'
	estimates store eq7_ld_ma, title("LD/MA")
	rename Med Med_ld_ma
	
	restore
	preserve
	
	* Perform regression for Equation (8) 
	foreach var of local lag1_x_vars {
    local newname = subinstr("`var'", "L1_", "", 1)
    rename `var' `newname'
	}
	local regressor_vars "Tax OI MB LnA DEP FA RND D_RND DIV AZ"
	local instrument_vars "L2_Tax L2_OI L2_MB L2_LnA L2_DEP L2_FA L2_RND L2_D_RND L2_DIV L2_AZ"
	
	ssc install ftools
	ssc install reghdfe
	
	display "--- FE IV Regression for Equation 8 on Total Debt / Book Value of Assets (TD/BA) ---"
	rename Med_td_ba Med
	rename td_ba IV_endo
	rename L0_td_ba td_ba
	local instruments_td_ba "L2_td_ma L2_Med_td_ba `instrument_vars'"
	quietly reghdfe IV_endo `instruments_td_ba', absorb(gvkey)
	predict IV_fitted, xb
	rename IV_fitted IV
	qui: eststo eq8_td_ba: quietly reghdfe td_ba IV Med `regressor_vars', absorb(gvkey) nocons
	estimates store eq8_td_ba, title("TD/BA")
	rename td_ba L0_td_ba
	rename IV_endo td_ba
	rename Med Med_td_ba
	drop IV
	
	display "--- FE IV Regression for Equation 8 on Total Debt / Market Value of Assets (TD/MA) ---"
	rename Med_td_ma Med
	rename td_ma IV_endo
	rename L0_td_ma td_ma
	local instruments_td_ma "L2_td_ba L2_Med_td_ma `instrument_vars'"
	quietly reghdfe IV_endo `instruments_td_ma', absorb(gvkey)
	predict IV_fitted, xb
	rename IV_fitted IV
	qui: eststo eq8_td_ma: quietly reghdfe td_ma IV Med `regressor_vars', absorb(gvkey) nocons
	estimates store eq8_td_ma, title("TD/MA")
	rename td_ma L0_td_ma
	rename IV_endo td_ma
	rename Med Med_td_ma
	drop IV
	
	* --- Model 3: LD/BA (Col 6) --- MANUAL 2SLS ---
	display "--- FE IV Regression for Equation 8 on Long-term Debt / Book Value of Assets (LD/BA) ---"
	rename Med_ld_ba Med
	rename ld_ba IV_endo
	rename L0_ld_ba ld_ba
	local instruments_ld_ba "L2_ld_ma L2_Med_ld_ba `instrument_vars'"
	quietly reghdfe IV_endo `instruments_ld_ba', absorb(gvkey)
	predict IV_fitted, xb
	rename IV_fitted IV
	qui: eststo eq8_ld_ba: quietly reghdfe ld_ba IV Med `regressor_vars', absorb(gvkey) nocons
	estimates store eq8_ld_ba, title("LD/BA")
	rename ld_ba L0_ld_ba
	rename IV_endo ld_ba
	rename Med Med_ld_ba
	drop IV
	
	* --- Model 4: LD/MA (Col 8) --- MANUAL 2SLS ---
	display "--- FE IV Regression for Equation 8 on Long-term Debt / Market Value of Assets (LD/MA) ---"
	rename Med_ld_ma Med
	rename ld_ma IV_endo
	rename L0_ld_ma ld_ma
	local instruments_ld_ma "L2_ld_ba L2_Med_ld_ma `instrument_vars'"
	quietly reghdfe IV_endo `instruments_ld_ma', absorb(gvkey)
	predict IV_fitted, xb
	rename IV_fitted IV
	qui: eststo eq8_ld_ma: quietly reghdfe ld_ma IV Med `regressor_vars', absorb(gvkey) nocons
	estimates store eq8_ld_ma, title("LD/MA")
	rename ld_ma L0_ld_ma
	rename IV_endo ld_ma
	rename Med Med_ld_ma
	drop IV

	* View results
	esttab eq7_td_ba eq8_td_ba eq7_td_ma eq8_td_ma eq7_ld_ba eq8_ld_ba eq7_ld_ma eq8_ld_ma, replace t(3) b(3) nonumbers nogaps label nonotes keep(_cons IV Med Tax OI MB LnA DEP FA RND D_RND DIV AZ) order(_cons IV Med Tax OI MB LnA DEP FA RND D_RND DIV AZ) starlevels(* 0.10 ** 0.05 *** 0.01) stats(r2_a N, labels(Adj.R-squared Observations) fmt(3 0)) obslast mgroups("TD/BA" "TD/MA" "LD/BA" "LD/MA", pattern(1 0 1 0 1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span) mtitles("Eq. (7)" "Eq. (8)" "Eq. (7)" "Eq. (8)" "Eq. (7)" "Eq. (8)" "Eq. (7)" "Eq. (8)")
	
	* Export to Overleaf
	esttab eq7_td_ba eq8_td_ba eq7_td_ma eq8_td_ma eq7_ld_ba eq8_ld_ba eq7_ld_ma eq8_ld_ma using "$overleaf/Byoun_2008_IV.tex", replace t(3) b(3) nonumbers nogaps label nonotes keep(_cons IV Med Tax OI MB LnA DEP FA RND D_RND DIV AZ) order(_cons IV Med Tax OI MB LnA DEP FA RND D_RND DIV AZ) starlevels(* 0.10 ** 0.05 *** 0.01) stats(r2_a N, labels(Adj.R-squared Observations) fmt(3 0)) obslast mgroups("TD/BA" "TD/MA" "LD/BA" "LD/MA", pattern(1 0 1 0 1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span) mtitles("Eq. (7)" "Eq. (8)" "Eq. (7)" "Eq. (8)" "Eq. (7)" "Eq. (8)" "Eq. (7)" "Eq. (8)")



