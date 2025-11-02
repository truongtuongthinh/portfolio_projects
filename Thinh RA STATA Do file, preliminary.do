***** IMPORT ANNUAL DATA *****
clear all
cls

* The paper works on annual data 
use "C:\Users\ASUS\Documents\RA\ccm_a_70_25.dta"



***** PREMILINARY CLEANS *****
* Since I noticed around ~2000 data lines are having perfect duplicates with the only difference is the column LINKPRIM, I decided to cut them out.
* As they are perfect duplications and initially I am not sure which LINKPRIM I should keep, my method is for each GVKEY-fyear observation, I keep the latest datadate and the descending ordered LINKPRIM. So that only one line out of the duplicates for each GVKEY-fyear observation remains.
*** 2,872 observations deleted
*gsort GVKEY fyear -datadate -LINKPRIM
*by GVKEY fyear: gen keep_flag = (_n == 1)
*keep if keep_flag == 1
*drop keep_flag
*display _N 

* Filter LINKPRIM 
keep if LINKPRIM == "P" | LINKPRIM == "C" 
display _N

* Filter the year range
keep if inrange(fyear, 1971, 2003)
display _N

* Filter the SIC code to remove financial firms and regulated utilities: SIC 6000-6799 and 4800-4999
gen sic_no = real(sic)
keep if !inrange(sic_no, 6000, 6799) & !inrange(sic_no, 4800, 4999)
display _N

* Filter US companies
keep if fic == "USA"
display _N

* The last filter is to drop non-positive book value of asset, book and market value of equity, and net sales. Market value equity is not available so I will construct it
* Market value of Equity = ITEM199 * ITEM54
*** ITEM199   : Price_Fiscal Year_Close (prcc_f)
*** ITEM54    : Common Shares Used to Calculate Earnings Per Share (csho)
*** According to the instruction I should filter the book value of equity by teq (Total Equity) but maybe due to something wrong in the data retrieving process, marjority of this column is missing, so I use seq (Total Equity - Parent) instead, as I see their data (where available) is the same. I will double check once I got the the direct Compustat access.
gen mktval_equity = prcc_f*csho

keep if at > 0 & seq > 0 & mktval_equity > 0 & sale > 0 & !missing(at, seq, mktval_equity, sale)
display _N



***** VARIABLE CONSTRUCTIONS *****
* Book value of Assets
gen bookval_asset = at

* Market value of Assets = ITEM6 - ITEM216 - ITEM35 + Market value of Equity + ITEM10 (if ITEM10 is missing, replace by ITEM56)
*** ITEM6    : Assets - Total/Liabilities and Stockholders' Equity - Total (at)
*** ITEM216  : Stockholders' Equity - Total (teq -> seq)
*** ITEM35   : Deferred Taxes and Investment Tax Credit (Balance Sheet) (txditc)
*** ITEM10   : Preferred Stock - Liquidating Value (not given, let's denote as pslv)
*** ITEM56   : Preferred Stock - Redemption Value (not given, let's denote as psrv)
*gen txditc_0 = cond(missing(txditc), 0, txditc)
*gen preferred_stock_val = cond(!missing(pslv), pslv, cond(!missing(psrv), psrv, 0)
*gen mktval_asset = bookval_asset - seq - txditc + mktval_equity + preferred_stock_val

* Total Debt = ITEM9 + ITEM34
*** ITEM9    : Long-Term Debt - Total (dltt)
*** ITEM34   : Debt in Current Liabilities (dlc)
gen total_debt = dltt + dlc

* Long-term Debt = ITEM9 + ITEM44
*** ITEM44   : Debt - Due in One Year (dd1)
gen longtm_debt = dltt + dd1

* Debt Ratios
gen td_ba = total_debt / bookval_asset 
*gen td_ma = total_debt / mktval_asset
gen ld_ba = longtm_debt / bookval_asset
*gen ld_ma = longtm_debt / mktval_asset

* Regressor  : Med = Median of Debt Ratios by 2-digit SIC
gen IndGroup = substr(sic, 1, 2)
sort fyear IndGroup
by fyear IndGroup: egen Med_td_ba = median(td_ba)
*by fyear IndGroup: egen Med_td_ma = median(td_ma)
by fyear IndGroup: egen Med_ld_ba = median(ld_ba)
*by fyear IndGroup: egen Med_ld_ma = median(ld_ma)

* Regressor  : Tax = the Statutory Tax Rate if ITEM52 is zero or missing and ITEM170 is positive
*** ITEM52   : Net Operating Loss Carry Forward - Unused Portion (not given, let's denote as nolcf)
*** ITEM170  : Pretax Income (pi)
*gen statutory_tax_rate = . 
*replace statutory_tax_rate = 0.48 if inrange(fyear, 1971, 1978) 
*replace statutory_tax_rate = 0.46 if inrange(fyear, 1979, 1986) 
*replace statutory_tax_rate = 0.40 if fyear == 1987 
*replace statutory_tax_rate = 0.34 if inrange(fyear, 1988, 1992) 
*replace statutory_tax_rate = 0.35 if inrange(fyear, 1993, 2003)

*gen Tax = 0 
*replace Tax = statutory_tax_rate if (nolcf == 0 | missing(nolcf)) & pi > 0 
*drop statutory_tax_rate 

* Regressor  : OI = ITEM13
*** ITEM13   : Operating Income Before Depreciation (oibdp)
gen OI = oibdp / bookval_asset

* Regressor  : MB = Market-to-book ratio of Assets
*gen MB = mktval_asset / bookval_asset

* Regressor  : LnA = Natural log of Assets
gen LnA = log(bookval_asset)

* Regressor  : DEP = ITEM14 / Book value of Assets
*** ITEM14   : Depreciation and Amortization (Income Statement) (dp)
gen DEP = dp / bookval_asset 

* Regressor  : FA = ITEM8 / Book value of Assets
*** ITEM8    : Property, Plant, and Equipment - Total (Net) (ppent)
gen FA = ppent / bookval_asset 

* Regressor  : RND = ITEM46 / ITEM12
*** ITEM46   : Research and Development Expense (xrd)
*** ITEM12   : Sales (Net) (sale)
gen xrd_0 = xrd
replace xrd_0 = 0 if missing(xrd)
gen RND = xrd_0 / sale
drop xrd_0

* Regressor  : D_RND = 1 if ITEM46 is missing, 0 otherwise
gen D_RND = 0
replace D_RND = 1 if missing(xrd)

* Regressor  : DIV = ITEM127 / Book value of Assets
*** ITEM127  : Cash Dividends (Statement of Cash Flows) (dv)
gen DIV = dv / bookval_asset

* Regressor  : AZ = (3.3 * (ITEM178) + ITEM12 + 1.4 * ITEM36 + 1.2 * (ITEM4 - ITEM5)) / Book value of Assets 
*** ITEM178  : Operating Income After Depreciation (not given, let's denote as ebit)
*** ITEM12   : Sales (Net) (sale)
*** ITEM36   : Retained Earnings (re)
*** ITEM4    : Current Assets - Total (act)
*** ITEM5    : Current Liabilities - Total (lct)
gen AZ = (3.3 * (oibdp - dp) + sale + 1.4 * re + 1.2 * (act - lct)) / bookval_asset 

* Plot the the table II for Book value of Assets to check for number of observations
display "--- Descriptive Table for the Book Value of Assets in 1973, 1983, 1993, 2003 ---"
tabstat bookval_asset if fyear == 1973 | fyear == 1983 | fyear == 1993 | fyear == 2003, stats(n mean min median max sd) by(fyear)



***** WINSORIZATION *****
* Install the package
ssc install winsor2

* Winsorize at percentile 1% and 99% for all variables
local winsor_vars_0199 "td_ba ld_ba OI LnA DEP FA AZ" 
foreach var of local winsor_vars_0199 { 
winsor2 `var', replace cut(1 99) 
} 

* Except for RND and DIV only winsorize at percentile 99%
local winsor_vars_0099 "RND DIV" 
foreach var of local winsor_vars_0099 { 
winsor2 `var', replace cut(0 99)
} 

keep if !missing(td_ba, ld_ba, Med_td_ba, Med_ld_ba, OI, LnA, DEP, FA, RND, D_RND, DIV, AZ)



***** LAGGED VARIABLES *****
* Declare the panel data format
destring GVKEY, replace
xtset GVKEY fyear

* List out lagged variables
local x_vars "Med_td_ba Med_ld_ba OI LnA DEP FA RND D_RND DIV AZ"

* Generate lagged variables
foreach var of local x_vars {
    gen L2_`var' = L2.`var'
}



***** REGRESSION ANALYSIS *****
* Perform regression for Equation (7) 
display "--- Pooled OLS Regression for Equation 7 on Total Debt / Book Value of Assets (TD/BA) ---"
regress td_ba Med_td_ba OI LnA DEP FA RND D_RND DIV AZ

display "--- Pooled OLS Regression for Equation 7 on Long-term Debt / Book Value of Assets (LD/BA) ---"
regress ld_ba Med_ld_ba OI LnA DEP FA RND D_RND DIV AZ