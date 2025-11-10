## Python Script to help filter Nessus Csv for reporting

`Changes`
* Added Solutions column 

**`Workflow`**

1. Read your original Excel (test.xlsx),

2. Merge by Description,

3. Filter by highest-risk per Host,

4. Merge by Name,

5. Write the final Excel (final_merged_by_name.xlsx) with formatting.

| Step | Action | Purpose |
|------|---------|----------|
| **1** | **Read input Excel** | Load the raw data file (`test.xlsx`) into a pandas DataFrame. |
| **2** | **Validate columns** | Ensure all required columns (`Risk`, `Host`, `Name`, `Synopsis`, `Description`) are present. |
| **3** | **Merge by Description** | Group rows with the same vulnerability description and combine all corresponding hosts. |
| **4** | **Expand hosts** | Split newline-separated host lists into individual rows (one host per row). |
| **5** | **Normalize risk** | Standardize risk labels (e.g., `high`, `critical`) and assign numeric ranking values. |
| **6** | **Filter by host** | For each host, retain only the entry with the highest risk level. |
| **7** | **Merge by Name** | Regroup data by vulnerability name, combining all affected hosts. |
| **8** | **Save Excel** | Write the final, formatted dataset to `final_merged_by_name.xlsx` with text wrapping for readability. |

**`Code::`**

```
import pandas as pd
import sys

# === Configuration ===
INPUT_FILE = 'test.xlsx'                    # Input Excel or CSV file
OUTPUT_FILE = 'final_merged_by_name.xlsx'   # Final output file

try:
    print("=== Step 1: Reading input file ===")

    # Auto-detect CSV or Excel
    if INPUT_FILE.lower().endswith('.csv'):
        df = pd.read_csv(INPUT_FILE)
    else:
        df = pd.read_excel(INPUT_FILE)

    print(f"✅ Loaded {len(df)} rows from '{INPUT_FILE}'")

    # === Step 2: Check required columns ===
    required_cols = {'Risk', 'Host', 'Name', 'Synopsis', 'Description', 'Solution'}
    missing = required_cols - set(df.columns)
    if missing:
        raise ValueError(f"Missing required columns: {', '.join(missing)}")

    # === Step 3: Merge by Description (combine hosts) ===
    merged_by_desc = (
        df.groupby(['Description'], as_index=False)
          .agg({
              'Risk': 'first',
              'Name': 'first',
              'Synopsis': 'first',
              'Solution': 'first',
              'Host': lambda x: '\n'.join(sorted(set(str(v) for v in x if pd.notna(v))))
          })
    )
    print(f"✅ Merged by Description → {len(merged_by_desc)} unique descriptions")

    # === Step 4: Expand multiline hosts (split lines into individual host entries) ===
    expanded_rows = []
    for _, row in merged_by_desc.iterrows():
        hosts = str(row['Host']).split('\n')
        for host in hosts:
            host = host.strip()
            if host:
                new_row = row.copy()
                new_row['Host'] = host
                expanded_rows.append(new_row)
    expanded_df = pd.DataFrame(expanded_rows)
    print(f"✅ Expanded to {len(expanded_df)} total host entries")

    # === Step 5: Normalize and rank Risk values ===
    expanded_df['Risk'] = expanded_df['Risk'].astype(str).str.strip().str.lower()
    risk_priority = {
        'critical': 4,
        'high': 3,
        'medium': 2,
        'low': 1,
        'info': 0
    }
    expanded_df['Risk_Level'] = expanded_df['Risk'].map(risk_priority).fillna(0)

    # === Step 6: Keep highest-risk row per host ===
    filtered_df = (
        expanded_df.sort_values('Risk_Level', ascending=False)
                   .drop_duplicates(subset=['Host'], keep='first')
                   .drop(columns=['Risk_Level'])
    )
    print(f"✅ Filtered to {len(filtered_df)} unique hosts (highest risk kept)")

    # === Step 7: Merge again by Name (combine hosts per vulnerability) ===
    filtered_df['Host'] = filtered_df['Host'].astype(str).str.strip()
    final_merged = (
        filtered_df.groupby(['Name'], as_index=False)
                   .agg({
                       'Risk': 'first',
                       'Synopsis': 'first',
                       'Description': 'first',
                       'Solution': 'first',
                       'Host': lambda x: '\n'.join(sorted(set(h.strip() for h in x if pd.notna(h))))
                   })
    )
    print(f"✅ Final merge complete → {len(final_merged)} unique vulnerability Names")

    # === Step 8: Save final Excel with wrapping ===
    with pd.ExcelWriter(OUTPUT_FILE, engine='xlsxwriter') as writer:
        final_merged.to_excel(writer, index=False, sheet_name='Final')

        workbook = writer.book
        worksheet = writer.sheets['Final']
        wrap_format = workbook.add_format({'text_wrap': True, 'valign': 'top'})
        worksheet.set_column('A:Z', 30, wrap_format)

    print(f"🎉 All steps complete! Final file saved as '{OUTPUT_FILE}'")

except FileNotFoundError:
    print(f"❌ Error: '{INPUT_FILE}' not found in the current directory.")
    sys.exit(1)
except ValueError as ve:
    print(f"⚠️ Data Error: {ve}")
    sys.exit(1)
except Exception as e:
    print(f"🚨 Unexpected Error: {e}")
    sys.exit(1)

```
