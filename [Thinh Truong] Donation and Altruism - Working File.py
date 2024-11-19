# -*- coding: utf-8 -*-
"""
Created on Sun Sep 22 10:41:27 2024

@author: HP
"""

import numpy as np 
import pandas as pd
from scipy import stats
from patsy import dmatrices
import re
import matplotlib.pyplot as plt
import seaborn as sns
import statsmodels.api as sm


#Prepare Data - VCB
df_vcb_10 = pd.read_excel("D:/Storm/Data/VCB 2024-09-10_01.xlsx")
df_vcb_11 = pd.read_excel("D:/Storm/Data/VCB 2024-09-11.xlsx")
df_vcb_12 = pd.read_excel("D:/Storm/Data/VCB 2024-09-12.xlsx")
df_vcb_13 = pd.read_excel("D:/Storm/Data/VCB 2024-09-13.xlsx")
df_vcb_14 = pd.read_excel("D:/Storm/Data/VCB 2024-09-14.xlsx")
df_vcb_23 = pd.read_excel("D:/Storm/Data/VCB 2024-09-23_15.xlsx")
df_vcb_29 = pd.read_excel("D:/Storm/Data/VCB 2024-09-29_24.xlsx")

df_vcb = pd.concat([df_vcb_10, df_vcb_11, df_vcb_12, df_vcb_13, df_vcb_14, df_vcb_23,df_vcb_29])

#Prepare Data - VTB
df_vtb_12 = pd.read_excel("D:/Storm/Data/VTB 2024-09-12_10.xlsx")
df_vtb_13 = pd.read_excel("D:/Storm/Data/VTB 2024-09-13.xlsx")
df_vtb_14 = pd.read_excel("D:/Storm/Data/VTB 2024-09-14.xlsx")
df_vtb_15 = pd.read_excel("D:/Storm/Data/VTB 2024-09-15.xlsx")
df_vtb_16 = pd.read_excel("D:/Storm/Data/VTB 2024-09-16.xlsx")
df_vtb_17 = pd.read_excel("D:/Storm/Data/VTB 2024-09-17.xlsx")
df_vtb_18 = pd.read_excel("D:/Storm/Data/VTB 2024-09-18.xlsx")

df_vtb = pd.concat([df_vtb_12, df_vtb_13, df_vtb_14, df_vtb_15, df_vtb_16, df_vtb_17])

#Prepare Data - BIDV
df_bid1_19 = pd.read_excel("D:/Storm/Data/BIDV1 2024-09-24_01.xlsx")
df_bid2_22 = pd.read_excel("D:/Storm/Data/BIDV2 2024-09-22_04.xlsx")

df_bidv = pd.concat([df_bid1_19, df_bid2_22])

#Combine all sources
df_raw = pd.concat([df_vcb, df_vtb, df_bidv])

import re

def extract_message(text):
    if not isinstance(text, str):
        return text
    # Define multiple patterns to match and remove unwanted prefixes
    patterns = [
        r'(?:MBVCB\.\d+\.\d+\.)|(?:MBVCB\.\d+\.)|(?:CT nhanh 247 den: MBVCB\.\d+\.\d+\.)',  # For MBVCB cases
        r'^\d+-\d+-',  # For numeric prefixes before the name (e.g., "66693414954-0329756310-")
        r'Noi dung:\s*',  # For "Noi dung:" case
        r'^PARTNER\.[\w\.]+-\d+_\d+_\d+-',  # Original PARTNER case
        r'^PARTNER\.[\w\.]+\.\d+\.\d+\.\d+-\d+_',  # Adjusted PARTNER case with detailed number formats
        #r'^\d{13,20}[A-Z0-9\.]+\.\d+\.\d+\.\d+.',  # New pattern for the long alphanumeric prefix
        r'^\d{13,20}[A-Z0-9]+(?:\.\d+)+\.',
        r'^\d{13,20}[A-Za-z0-9]+(?:\.\d+)+\.\s\d+\.',
        r'^TKThe\s*:\d+[A-Z0-9\-]+(?:\s*-\s*CRE.*)?', #TK The
        r'^CT\s*nhanh\s*247\s*den\s*:\s*',
        r'^\d+\.\d+\.\d+\.',  # Matches sequences like "563774.040924.092651."
        r'^[0-9A-Za-z\.]+(?:\s*\.\s*)?[A-Za-z]+:\d+:',  # Match numbers, alphanumeric, bank info, and colons
        r'^[0-9A-Za-z\.\s]+Vietcombank:\d+:',  # Match the prefix including bank info up to the last colon
        r'^[A-Za-z0-9\.\:\-_ ]*\.\d{6}\.\d{6}\.\s*',
        r'^PARTNER\.DIRECT_DEBITS_VCB\.ZLP\.[A-z0-9]+\s[A-z0-9]+\.\d+\.',
        r'^PARTNER\.DIRECT_DEBITS_VCB\.[A-Z]+\.\d+\s\d+\.\d+\.\d+\-',
        r'^PARTNER\.DIRECT_DEBITS_VCB\.[A-Z]+\.\d+\.\d+\.\d+\s\d+\-',
        r'^02009704[A-Za-z0-9]+\.\d+\s\.\d+\.',
        r'^02009704[A-Za-z0-9]+\.\d+\s\d+\.\d+\.',
        r'^02009704[A-Za-z0-9]+\.\d+\.\d+\.',
        r'^Chuyen\stien\sden\stu\sNAPAS',
        r'^MBBIZ\d+\.',
        r'^IBBIZ\d+\.',
        r'^SHGD\:\d+\.DD\:\d+\.BO\:',
        r'^IBVCB\.\d+\.'
    ]
    
    # Apply each pattern sequentially to remove the prefix
    for pattern in patterns:
        text = re.sub(pattern, '', text)
    
    # Return the cleaned text
    return text.strip()

# Example usage:
texts = [
    "CT nhanh 247 den: MBVCB.7018057206.704314.HO YEN NHI chia se voi dong bao bi lu lut.",
    "MBVCB.7027766531.trong tk cua e con co nhieu day mong giup dc 1 phan nho xiu nao do de giup do mng a",
    "66693414954-0329756310-NGOC THI PHUONG chuyen tien qua MoMo; thoi gian GD:12/09/2024 23:19:07",
    "Chuyen tien den tu NAPAS Noi dung: TRAN NGOC KHUE TU CHUYEN KHOAN- 120924-23:21:31 767817 (ct1111)",
    "PARTNER.DIRECT_DEBITS_VCB.MSE.66768884444.20240913.66768884444-0368115952_Da con chi con nhieu day con mong moi nguoi som vuot qua",
    "0200970422091322563320241ODG844486.69891.225634.NGUYEN VU DUC MINH chuyen tien ho tro dong bao bi thiet hai boi bao Yagi",
    "020097040509041008052024HEVJ019980.37909 .100752.Vietcombank:0011001932418:TRAN THI ANH NGUYET chuyen tien",
    "PARTNER.DIRECT_DEBITS_VCB.ZLP.ZP6R 34H953F5.20240901.Nguyet chuyen tien qua Zalopay",
    "020097042209081718272024FNGV372976.1905 7.171828.LE DIEU LINH ung ho khac phuc hau qua bao so 3 Yagi",
    "020097042209081739582024FQHE408928.7578 6.173958.Gia dinh NGUYEN VU THU HUONG chuyen tien UNG HO KHAC PHUC CON BAO SO 3 YAGI",
    "020097041509190927472024rLPt578527.85895.092747.Ngoc ung ho nguoi dan khac phuc hau qua bao lu"
]

# Apply the function to each text
cleaned_texts = [extract_message(text) for text in texts]

# Output the cleaned results
for message in cleaned_texts:
    print(message)

df_raw['cleaned_message'] = df_raw['short'].apply(extract_message)

# Checking
df_raw['prefix'] = df_raw['cleaned_message'].str[:20]

aaa = df_raw[['prefix', 'amount']].groupby('prefix').count().sort_values(by='amount', ascending=False)

bbb = df_raw[['cleaned_message', 'short']].sample(n=10000)

print(aaa)

end_file_path22 = "D:/Storm/Data/22 Data 2024-10-02.csv"
aaa.to_csv(end_file_path22)

### NEW CLASSIFIER

import unidecode

# Function to remove diacritics and set priority with "contains" logic
def datetime_binary(datetime):
    if datetime <= pd.to_datetime('12/09/2024', format='%d/%m/%Y'):
        return 0
    else:
        return 1

def common_lastnames(note_refined):
    note_refined = unidecode.unidecode(str(note_refined).upper())  # Remove accents and convert to uppercase
    
    # Set priority based on contains logic
    if "NGUYEN " in note_refined:
        return "NGUYEN"
    elif "TRAN " in note_refined and "MAT TRAN" not in note_refined:
        return "TRAN"
    elif "LE " in note_refined:
        return "LE"
    elif "PHAM " in note_refined:
        return "PHAM"
    elif "HOANG " in note_refined:
        return "HOANG"
    elif "BUI " in note_refined:
        return "BUI"
    elif "HUYNH " in note_refined:
        return "HUYNH"
    elif "VU " in note_refined:
        return "VU"
    elif "DANG " in note_refined:
        return "DANG"
    elif "PHAN " in note_refined:
        return "PHAN"
    elif "VO " in note_refined:
        return "VO"
    elif "DINH " in note_refined:
        return "DINH"
    elif "DUONG " in note_refined:
        return "DUONG"
    elif "HO " in note_refined and "UNG HO" not in note_refined and "HO TRO" not in note_refined:
        return "HO"
    elif "TRUONG " in note_refined:
        return "TRUONG"
    elif "NGO " in note_refined:
        return "NGO"
    elif "HA " in note_refined:
        return "HA"
    elif "DOAN " in note_refined:
        return "DOAN"
    elif "TRINH " in note_refined:
        return "TRINH"
    elif "MAI " in note_refined:
        return "MAI"
    elif "DAO " in note_refined:
        return "DAO"
    elif "CAO " in note_refined:
        return "CAO"
    elif "LUONG " in note_refined:
        return "LUONG"
    elif "LUU " in note_refined:
        return "LUU"
    else:
        return 'NONE'  # Return None if no match
    
def common_lastnames2(common_lastnames):
    note_refined = unidecode.unidecode(str(common_lastnames).upper())  # Remove accents and convert to uppercase
    
    # Set priority based on contains logic
    if note_refined == 'NONE':
        return 0
    else:
        return 1  # Return None if no match

keywords_religious_christian = ["AMEN", "MARIA", "XINCHUA", "CHUAGIESU", "CHUAPHUHO"]
keywords_religious_buddhist = ["ADIDAPHAT", "AMIDAPHAT", "THICHCAMAUNI", "QUANTHEAM", "QUANAM", "DIATANG", "BOTAT"]
keywords_religious_general = ['PHUHO', 'CAUNGUYEN', 'BANPHUC', 'BANPHUOC', 'XOTTHUONG', 'THUONGXOT']

def keyword_religious(note):
    if any(keyword in note.upper() for keyword in keywords_religious_buddhist):
        return "1_Buddhist"
    elif any(keyword in note.upper() for keyword in keywords_religious_christian):
        return "2_Christian"
    elif any(keyword in note.upper() for keyword in keywords_religious_general):
        return "3_General"
    else:
        return "4_None"

def keyword_religious_binary(note):
    if any(keyword in note.upper() for keyword in keywords_religious_buddhist):
        return 1
    elif any(keyword in note.upper() for keyword in keywords_religious_christian):
        return 1
    elif any(keyword in note.upper() for keyword in keywords_religious_general):
        return 1
    else:
        return 0
    
keywords_business = ['CONGTY', 'CTY', 'TAPDOAN', 'GROUP', 'COMPANY', 'LTD', 'LLC' 'TNHH', 'DOANHNGHIEP', 'KINHDOANH', 'DNTN', 'MOTTHANHVIEN']

def keyword_business_binary(note):
    if any(keyword in note.upper() for keyword in keywords_business):
        return 1
    else:
        return 0

keywords_kol = ['CASI', 'NGHESI', 'NSUT', 'NSND', 'DIENVIEN', 'NGUOIMAU', 'KOL', 'KOC', 'DIVA', 'SIEUMAU', 'HOAHAU', 'MISS', 'VEDETTE']

def keyword_kol_binary(note):
    if any(keyword in note.upper() for keyword in keywords_kol):
        return 1
    else:
        return 0
   
### Preparing data:
df_raw['amount_mil'] = df_raw['amount'] / 1000000
df_raw['note_refined'] = df_raw['cleaned_message'].apply(lambda x: re.sub(r"\s+", " ", str(x))) #multi break to single break 
df_raw['datetime'] = pd.to_datetime(df_raw['date'], format='%d/%m/%Y')
df_raw['is_after'] = df_raw['datetime'].apply(datetime_binary)
df_raw['log_amount'] = np.log(df_raw['amount'] + 1) 
df_raw['amount_mil'] = df_raw['amount'] / 1000000
df_raw['note_refined'] = df_raw['cleaned_message'].apply(lambda x: re.sub(r"\s+", " ", str(x))) #multi break to single break 
df_raw['note_refined2'] = df_raw['cleaned_message'].apply(lambda x: re.sub(r"\s+", "", str(x)))
df_raw['log_amount2'] = np.log(df_raw['amount']/1000 + 1) 
   
### Data labelling
df_raw['last_names'] = df_raw['note_refined'].apply(common_lastnames)
df_raw['is_name_declared'] = df_raw['last_names'].apply(common_lastnames2)
df_raw['religious_text'] = df_raw['note_refined2'].apply(keyword_religious)
df_raw['is_religious'] = df_raw['note_refined2'].apply(keyword_religious_binary)
df_raw['is_business_related'] = df_raw['note_refined2'].apply(keyword_business_binary)
df_raw['is_kol_related'] = df_raw['note_refined2'].apply(keyword_kol_binary)
    
### Export data
df_clean = df_raw[['source', 'datetime', 'amount', 'amount_mil', 'log_amount', 'is_after', 'last_names', 'is_name_declared', 'religious_text', 'is_religious', 'is_business_related', 'is_kol_related']]
df_clean.head()
end_file_path = "D:/Storm/Data/Clean Data 2024-10-02.csv"
df_clean.to_csv(end_file_path)

### Create the pivot table with aggfunc for mean and count
pivot_table = df_raw.pivot_table(
    index='datetime',
    columns=['is_business_related'],
    values='log_amount',
    fill_value=0,
    aggfunc='count'
)

# Print the pivot table
print(pivot_table)

df_biz = df_raw[['source', 'datetime', 'amount', 'log_amount', 'is_after', 'is_business_related', 'cleaned_message']][df_raw['is_business_related']==1]

file_path_biz = 'D:/Storm/Data/Clean Data 2024-10-02 Biz trans.csv'
df_biz.to_csv(file_path_biz)

### OLS
import statsmodels.api as sm
import pandas as pd

# Specify the outcome variable (log_amount) and the treatment, time, and interaction terms
model = sm.formula.ols('log_amount ~ is_after + is_name_declared + is_after * is_name_declared + C(source) + C(last_names) + C(is_religious) + C(is_business_related) + C(is_kol_related)', data=df_raw).fit()

# Display results
print(model.summary())

from statsmodels.stats.diagnostic import het_breuschpagan
# Perform Breusch-Pagan test for heteroskedasticity
bp_test = het_breuschpagan(model.resid, model.model.exog)

# Breusch-Pagan test results
bp_test_labels = ['Lagrange multiplier statistic', 'p-value', 'f-value', 'f p-value']
bp_test_results = dict(zip(bp_test_labels, bp_test))

# Display the results
print("Breusch-Pagan test for heteroskedasticity:")
for key, value in bp_test_results.items():
    print(f"{key}: {value}")
    
# Apply robust standard errors (heteroskedasticity-consistent, HC1)
robust_model = model.get_robustcov_results(cov_type='HC1')

# Display results with robust standard errors
print(robust_model.summary())


## FIXED EFFECTS
from linearmodels import PanelOLS

fem2 = PanelOLS.from_formula("log_amount ~ is_after * is_name_declared + TimeEffects + EntityEffects", df_clean.set_index(['last_names', 'datetime']))
fem_result2 = fem2.fit(cov_type="clustered", cluster_time=True, group_debias=True, drop_absorbed=True)
fem_result2.summary()


import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

# Example data (replace this with your actual DataFrame)

df_chart = df_clean[df_clean['datetime']>=pd.to_datetime('09/09/2024', format='%d/%m/%Y')]
# Grouping the data by 'is_name_declared' and 'datetime', calculating mean and standard deviation
grouped = df_chart.groupby(['datetime', 'is_name_declared']).agg(
    mean_log_amount=('log_amount', 'median'),
    std_log_amount=('log_amount', 'std')
).reset_index()

### Plotting
plt.figure(figsize=(10, 6))

# Loop through each group in 'is_name_declared'
for name_declared in grouped['is_name_declared'].unique():
    subset = grouped[grouped['is_name_declared'] == name_declared]
    
    # Plot mean line
    plt.plot(subset['datetime'], subset['mean_log_amount'], label=f'Name Declared: {name_declared}')
    
    # Add standard deviation as shaded region
    plt.fill_between(subset['datetime'], 
                     subset['mean_log_amount'] - subset['std_log_amount'], 
                     subset['mean_log_amount'] + subset['std_log_amount'], 
                     alpha=0.3)

# Labels and title
plt.xlabel('Date')
plt.ylabel('Mean Log Amount')
plt.title('Mean Log Amount Over Time with Standard Deviation')
plt.legend()
plt.xticks(rotation=45)
plt.tight_layout()

# Show the plot
plt.show()
