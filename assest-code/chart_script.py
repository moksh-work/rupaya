
import plotly.graph_objects as go

# Create figure
fig = go.Figure()

# Define positions for components (x, y coordinates)
# Client layer
ios_pos = (1, 9)
android_pos = (3, 9)

# Backend layer
api_pos = (2, 7)
auth_pos = (0.5, 5)
trans_pos = (2, 5)
analytics_pos = (3.5, 5)

# Data layer
db_pos = (1, 3)
redis_pos = (3, 3)

# AWS layer
s3_pos = (0.5, 1)
lambda_pos = (2, 1)
cloudwatch_pos = (3.5, 1)

# Component positions dictionary
components = {
    'iOS App': {'pos': ios_pos, 'color': '#B3E5EC'},
    'Android App': {'pos': android_pos, 'color': '#B3E5EC'},
    'Backend API': {'pos': api_pos, 'color': '#FFCDD2'},
    'Authentication': {'pos': auth_pos, 'color': '#FFCDD2'},
    'Transaction<br>Processor': {'pos': trans_pos, 'color': '#FFCDD2'},
    'Analytics<br>Engine': {'pos': analytics_pos, 'color': '#FFCDD2'},
    'Database': {'pos': db_pos, 'color': '#A5D6A7'},
    'Redis Cache': {'pos': redis_pos, 'color': '#A5D6A7'},
    'S3 Storage': {'pos': s3_pos, 'color': '#FFEB8A'},
    'Lambda': {'pos': lambda_pos, 'color': '#FFEB8A'},
    'CloudWatch': {'pos': cloudwatch_pos, 'color': '#FFEB8A'}
}

# Define connections with labels (from_node, to_node, label)
connections = [
    (ios_pos, api_pos, 'API Request'),
    (android_pos, api_pos, 'API Request'),
    (api_pos, auth_pos, '1. Auth'),
    (auth_pos, db_pos, '2. Verify'),
    (auth_pos, redis_pos, '3. Session'),
    (api_pos, trans_pos, '5. Process'),
    (trans_pos, db_pos, '6. Write'),
    (trans_pos, redis_pos, '7. Cache'),
    (trans_pos, s3_pos, '8. Store'),
    (api_pos, analytics_pos, '9. Events'),
    (analytics_pos, lambda_pos, '10. Process'),
    (lambda_pos, db_pos, '11. Metrics'),
    (analytics_pos, cloudwatch_pos, '12. Log'),
]

# Add arrows/connections
for start, end, label in connections:
    fig.add_annotation(
        x=end[0], y=end[1],
        ax=start[0], ay=start[1],
        xref='x', yref='y',
        axref='x', ayref='y',
        showarrow=True,
        arrowhead=2,
        arrowsize=1,
        arrowwidth=2,
        arrowcolor='#9FA8B0',
        opacity=0.6
    )
    
    # Add label at midpoint
    mid_x = (start[0] + end[0]) / 2
    mid_y = (start[1] + end[1]) / 2
    fig.add_annotation(
        x=mid_x, y=mid_y,
        text=label,
        showarrow=False,
        font=dict(size=9, color='#666666'),
        bgcolor='white',
        opacity=0.9
    )

# Add component boxes
for name, props in components.items():
    x, y = props['pos']
    fig.add_shape(
        type='rect',
        x0=x-0.35, y0=y-0.25,
        x1=x+0.35, y1=y+0.25,
        fillcolor=props['color'],
        line=dict(color='#666666', width=2),
        opacity=0.8
    )
    
    fig.add_annotation(
        x=x, y=y,
        text=f"<b>{name}</b>",
        showarrow=False,
        font=dict(size=11, color='#13343b'),
        align='center'
    )

# Add layer labels
fig.add_annotation(x=-0.5, y=9, text="<b>Client Apps</b>", showarrow=False,
                   font=dict(size=12, color='#333333'), xanchor='right')
fig.add_annotation(x=-0.5, y=7, text="<b>Backend</b>", showarrow=False,
                   font=dict(size=12, color='#333333'), xanchor='right')
fig.add_annotation(x=-0.5, y=3, text="<b>Data Layer</b>", showarrow=False,
                   font=dict(size=12, color='#333333'), xanchor='right')
fig.add_annotation(x=-0.5, y=1, text="<b>AWS Services</b>", showarrow=False,
                   font=dict(size=12, color='#333333'), xanchor='right')

# Update layout
fig.update_layout(
    title={
        'text': "RUPAYA System Architecture<br><span style='font-size: 18px; font-weight: normal;'>Authentication, transactions, and analytics data flow</span>",
        'x': 0.5,
        'xanchor': 'center'
    },
    xaxis=dict(
        range=[-1, 4.5],
        showgrid=False,
        showticklabels=False,
        zeroline=False,
        title_text=""
    ),
    yaxis=dict(
        range=[0, 10],
        showgrid=False,
        showticklabels=False,
        zeroline=False,
        title_text=""
    ),
    plot_bgcolor='white',
    showlegend=False
)

# Save the figure
fig.write_image('rupaya_architecture.png')
print("RUPAYA architecture diagram created successfully!")
