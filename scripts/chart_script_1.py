
import plotly.graph_objects as go

# Create a flowchart-style diagram using Plotly
fig = go.Figure()

# Define node positions and labels
nodes = [
    {"label": "Development", "x": 0.5, "y": 9, "color": "#B3E5EC"},
    {"label": "GitHub Push", "x": 0.5, "y": 8, "color": "#B3E5EC"},
    {"label": "CI/CD<br>GitHub Actions", "x": 0.5, "y": 7, "color": "#B3E5EC"},
    {"label": "Tests<br>Unit/Integration", "x": 0.5, "y": 6, "color": "#B3E5EC"},
    {"label": "Docker Build", "x": 0.5, "y": 5, "color": "#A5D6A7"},
    {"label": "ECR Push", "x": 0.5, "y": 4, "color": "#A5D6A7"},
    {"label": "AWS ECS Deploy", "x": 0.5, "y": 3, "color": "#A5D6A7"},
    {"label": "CloudWatch<br>Monitoring", "x": 0.5, "y": 2, "color": "#A5D6A7"},
    {"label": "Test Failed", "x": 0.15, "y": 5.5, "color": "#FFCDD2"},
    {"label": "Deploy Failed", "x": 0.15, "y": 2.5, "color": "#FFCDD2"},
    {"label": "End", "x": 0.5, "y": 1, "color": "#9FA8B0"},
]

# Add nodes as shapes and annotations
for node in nodes:
    # Add rectangle shape for node
    fig.add_shape(
        type="rect",
        x0=node["x"]-0.08, y0=node["y"]-0.3,
        x1=node["x"]+0.08, y1=node["y"]+0.3,
        fillcolor=node["color"],
        line=dict(color="#333333", width=2),
    )
    
    # Add text annotation
    fig.add_annotation(
        x=node["x"], y=node["y"],
        text=node["label"],
        showarrow=False,
        font=dict(size=11, color="#13343b"),
        align="center"
    )

# Add arrows for connections
arrows = [
    # Main success path
    {"x0": 0.5, "y0": 8.7, "x1": 0.5, "y1": 8.3, "color": "#333333"},
    {"x0": 0.5, "y0": 7.7, "x1": 0.5, "y1": 7.3, "color": "#333333"},
    {"x0": 0.5, "y0": 6.7, "x1": 0.5, "y1": 6.3, "color": "#333333"},
    {"x0": 0.5, "y0": 5.7, "x1": 0.5, "y1": 5.3, "color": "#A5D6A7"},
    {"x0": 0.5, "y0": 4.7, "x1": 0.5, "y1": 4.3, "color": "#A5D6A7"},
    {"x0": 0.5, "y0": 3.7, "x1": 0.5, "y1": 3.3, "color": "#A5D6A7"},
    {"x0": 0.5, "y0": 2.7, "x1": 0.5, "y1": 2.3, "color": "#A5D6A7"},
    {"x0": 0.5, "y0": 1.7, "x1": 0.5, "y1": 1.3, "color": "#A5D6A7"},
    # Failure paths
    {"x0": 0.45, "y0": 5.75, "x1": 0.23, "y1": 5.55, "color": "#FFCDD2"},
    {"x0": 0.45, "y0": 2.75, "x1": 0.23, "y1": 2.55, "color": "#FFCDD2"},
    {"x0": 0.15, "y0": 5.2, "x1": 0.15, "y1": 1.5, "color": "#FFCDD2"},
    {"x0": 0.15, "y0": 2.2, "x1": 0.15, "y1": 1.5, "color": "#FFCDD2"},
    {"x0": 0.2, "y0": 1.3, "x1": 0.42, "y1": 1.15, "color": "#FFCDD2"},
]

for arrow in arrows:
    fig.add_annotation(
        x=arrow["x1"], y=arrow["y1"],
        ax=arrow["x0"], ay=arrow["y0"],
        xref="x", yref="y",
        axref="x", ayref="y",
        showarrow=True,
        arrowhead=2,
        arrowsize=1,
        arrowwidth=2,
        arrowcolor=arrow["color"]
    )

# Add labels for success/failure paths
fig.add_annotation(x=0.35, y=5.65, text="Success", showarrow=False, 
                   font=dict(size=9, color="#A5D6A7"), bgcolor="white")
fig.add_annotation(x=0.3, y=5.5, text="Failure", showarrow=False, 
                   font=dict(size=9, color="#FFCDD2"), bgcolor="white")
fig.add_annotation(x=0.35, y=2.65, text="Success", showarrow=False, 
                   font=dict(size=9, color="#A5D6A7"), bgcolor="white")
fig.add_annotation(x=0.3, y=2.5, text="Failure", showarrow=False, 
                   font=dict(size=9, color="#FFCDD2"), bgcolor="white")

# Update layout
fig.update_layout(
    title={
        "text": "Deployment Pipeline with Success and Failure Paths<br><span style='font-size: 18px; font-weight: normal;'>Automated CI/CD workflow from dev to production monitoring</span>"
    },
    xaxis=dict(range=[0, 1], showticklabels=False, showgrid=False, zeroline=False),
    yaxis=dict(range=[0, 10], showticklabels=False, showgrid=False, zeroline=False),
    plot_bgcolor="white",
    showlegend=False
)

fig.update_xaxes(title_text="")
fig.update_yaxes(title_text="")

# Save the figure
fig.write_image("chart.png")
print("Chart saved successfully")
