import pandas as pd
import plotly.graph_objects as go

# Load the data
file_path = r"C:\Users\boba4\Box\Zach_repo\Projects\Remote_memory\Miniscope data\shock to tone sankey.xlsx"  # Update with your file path
df = pd.read_excel(file_path)

# Count occurrences of each (D0 shock response, D28 tone response) transition
transition_counts = df.groupby(["D0 shock response", "D28 tone response"]).size().reset_index(name="count")

# Compute percentage of total transitions for each group
total = transition_counts["count"].sum()
transition_counts["percent"] = transition_counts["count"] / total * 100

# Extract unique labels (nodes) from both columns
unique_labels = list(set(df["D0 shock response"]).union(set(df["D28 tone response"])))
label_to_index = {label: i for i, label in enumerate(unique_labels)}

# Create source, target, and value lists along with percent for each transition
sources = [label_to_index[src] for src in transition_counts["D0 shock response"]]
targets = [label_to_index[tgt] for tgt in transition_counts["D28 tone response"]]
values = transition_counts["count"].tolist()
percents = transition_counts["percent"].tolist()

# Generate Sankey diagram with customized hover information displaying counts and percentages
fig = go.Figure(go.Sankey(
    node=dict(
        label=unique_labels,
        pad=15,
        thickness=20,
        color="lightblue"
    ),
    link=dict(
        source=sources,
        target=targets,
        value=values,
        customdata=percents,
        hovertemplate="Count: %{value}<br>Percent: %{customdata:.1f}%<extra></extra>"
    )
))

fig.update_layout(title_text="Sankey Diagram of D0 Shock to D28 Tone modulation", font_size=12)
fig.write_image(r"C:\Users\boba4\Box\Zach_repo\Projects\Remote_memory\Miniscope data\sankey_shock_to_tone.svg", width=800, height=600)  # Save the figure as a SVG file
fig.show()
