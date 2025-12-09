#!/usr/bin/env nix-shell
#!nix-shell -i python3 -p python3Packages.plotly python3Packages.pandas

import plotly.express as px
import pandas as pd

data = [
    tuple(map(float, line.split(',')))
    for line in open('inputs/day09.txt').read().strip().split('\n')
]
df = pd.DataFrame(data, columns=['x', 'y'])

fig = px.line(df, x='x', y='y', title='Day 09 Points', markers=True)
fig.update_layout(yaxis_scaleanchor='x')  # Equal aspect ratio
fig.show()
