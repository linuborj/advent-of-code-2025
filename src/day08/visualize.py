#!/usr/bin/env nix-shell
#!nix-shell -i python3 -p python3Packages.plotly python3Packages.pandas

import plotly.express as px
import pandas as pd

data = [
    tuple(map(float, line.split(',')))
    for line in open('inputs/day08.txt').read().strip().split('\n')
]
df = pd.DataFrame(data, columns=['x', 'y', 'z'])
px.scatter_3d(df, x='x', y='y', z='z', title='Day 08 Points').show()
