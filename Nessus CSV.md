> * Hosts will appear once for each group of vulnerabilities.
> * If the same vulnerability name appears multiple times for the same host, it will be merged into one row with an additional note about how many times it was detected or simply combined into a single row for clarity.


```
import pandas as pd

# Read the Excel file (replace with your actual file path)
file_path = 'vulnerabilities.xlsx'  # Change this to your file path
df = pd.read_excel(file_path)

# Check the first few rows to verify the data structure
print("Sample of the raw data:")
print(df.head())

# Group the data by Host and Vulnerability (Name)
grouped = df.groupby(['Host', 'Name'], as_index=False).agg({
    'Severity': 'first',    # Keep the first value of severity
    'Port': 'first',        # Keep the first value of port
    'Protocol': 'first',    # Keep the first value of protocol
    'Description': 'first', # Keep the first description
    'Solution': 'first',    # Keep the first solution
    'Host': 'first'         # Keep the first value of Host
})

# Count the occurrences of each vulnerability for a host
grouped['Count'] = df.groupby(['Host', 'Name']).size().values

# Now, let's prepare the output where we merge the Host and show the repeated vulnerabilities
rows = []

for host, group in grouped.groupby('Host'):
    for idx, row in group.iterrows():
        new_row = {
            'Host': host if idx == group.index[0] else '',  # Only add the host on the first row for each group
            'Name': row['Name'],
            'Severity': row['Severity'],
            'Port': row['Port'],
            'Protocol': row['Protocol'],
            'Description': row['Description'],
            'Solution': row['Solution'],
            'Count': row['Count']
        }
        rows.append(new_row)

# Create a DataFrame from the rows
expanded_df = pd.DataFrame(rows)

# Save the expanded DataFrame into a new Excel file
output_file_path = 'merged_vulnerabilities_with_repeated_merged.xlsx'
expanded_df.to_excel(output_file_path, index=False)

print(f"\nVulnerabilities have been written to: {output_file_path}")

```
---
---

> * Reads the original Excel file with vulnerability data.
> * Groups the data by Host and Vulnerability Name.
> * Merges multiple CVE IDs, Ports, and Solutions for the same host and vulnerability name.
> * Counts how many times each vulnerability is detected for each host.
> * Prepares the data to ensure the Host appears only once for each vulnerability and that all merged columns (CVE, Ports, Solutions) are properly combined.
> * Writes the processed data into a new Excel file.

```
import pandas as pd

# Read the Excel file (replace with your actual file path)
file_path = 'vulnerabilities.xlsx'  # Change this to your file path
df = pd.read_excel(file_path)

# Check the first few rows to verify the data structure
print("Sample of the raw data:")
print(df.head())

# Group by Host and Vulnerability Name (i.e., merge CVEs, Ports, and Solutions for same vulnerability)
grouped = df.groupby(['Host', 'Name'], as_index=False).agg({
    'Severity': 'first',             # Keep the first value of severity
    'Protocol': 'first',             # Keep the first value of protocol
    'Description': 'first',          # Keep the first description
    'Host': 'first',                 # Keep the first value of Host
    'CVE': lambda x: ', '.join(x),   # Merge CVE IDs into a single string, separated by commas
    'Port': lambda x: ', '.join(map(str, x.unique())),  # Merge ports into a single string, separated by commas
    'Solution': lambda x: ', '.join(x.unique())  # Merge solutions into a single string, separated by commas
})

# Count the occurrences of each vulnerability for a host (Optional, if you want to show how many times the vulnerability is detected)
grouped['Count'] = df.groupby(['Host', 'Name']).size().values

# Now, let's prepare the output where we merge the Host and show the repeated vulnerabilities
rows = []

for host, group in grouped.groupby('Host'):
    for idx, row in group.iterrows():
        new_row = {
            'Host': host if idx == group.index[0] else '',  # Only add the host on the first row for each group
            'Name': row['Name'],
            'Severity': row['Severity'],
            'Protocol': row['Protocol'],
            'Description': row['Description'],
            'Solution': row['Solution'],
            'CVE': row['CVE'],
            'Port': row['Port'],
            'Count': row['Count']
        }
        rows.append(new_row)

# Create a DataFrame from the rows
expanded_df = pd.DataFrame(rows)

# Save the expanded DataFrame into a new Excel file
output_file_path = 'merged_vulnerabilities_with_merged_CVEs_Ports_and_Solutions.xlsx'
expanded_df.to_excel(output_file_path, index=False)

print(f"\nVulnerabilities have been written to: {output_file_path}")

```
---