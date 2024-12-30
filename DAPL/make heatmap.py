import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt

# Load the spreadsheet data
data_path = r"C:\Users\boba4\Box\Zach_repo\Projects\DA PMA\modeling\PMA_TDmodel_params.xlsx"
df = pd.read_excel(data_path)

# Define headers and their sub-columns
major_headers = ["Header 1", "Header 2", "Header 3", "Header 4"]
sub_columns_per_major = 5

# Create a MultiIndex for the columns
multi_columns = []
for major_header in major_headers:
    multi_columns.extend([(major_header, f"Sub {i+1}") for i in range(sub_columns_per_major)])

df.columns = pd.MultiIndex.from_tuples(multi_columns)

# Generate a heatmap with seaborn
plt.figure(figsize=(12, 8))  # Set the figure size
sns.heatmap(df.values, cmap="viridis", cbar_kws={'label': 'Intensity'}, linewidths=0.5)

# Adjust axis labels
plt.xticks(
    [i + 2.5 for i in range(0, len(df.columns), sub_columns_per_major)],  # Position for major headers
    major_headers,
    fontsize=12
)
plt.yticks(fontsize=10)
plt.title("Scientific Heatmap", fontsize=16)
plt.xlabel("", fontsize=12)
plt.ylabel("Samples", fontsize=12)

# Display the heatmap
plt.tight_layout()
plt.show()
