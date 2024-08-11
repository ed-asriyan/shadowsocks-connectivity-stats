#!/usr/bin/env python
# https://chatgpt.com/share/8957bb80-520e-49ac-86a8-e24caa7ac588

import argparse
import sys

import graphviz
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from sklearn.preprocessing import OneHotEncoder
from sklearn.tree import DecisionTreeClassifier
from sklearn import tree


def create_model(path_to_csv: str):
    data = pd.read_csv(path_to_csv)

    X = data.iloc[:, 1:-2]
    y = data.iloc[:, -2]

    ohe = OneHotEncoder(sparse_output=False)
    X_encoded = ohe.fit_transform(X)

    feature_names = ohe.get_feature_names_out(X.columns)

    model = DecisionTreeClassifier()
    model.fit(X_encoded, y)

    return model, feature_names

def create_graphviz_rules(tree, feature_names, class_names, node_index=0):
    left_child = tree.children_left[node_index]
    right_child = tree.children_right[node_index]
    feature = tree.feature[node_index]
    
    if left_child == right_child:
        leaf_value = np.argmax(tree.value[node_index])
        class_label = class_names[leaf_value]
        return f'{node_index} [label="{class_label}", shape="ellipse"];\n'

    rules = []
    for value in feature_names:
        if value.startswith(feature_names[feature]):
            condition = f'{node_index} [label="{value.split("_")[0]} == \\"{value.split("_")[1]}\\"?", shape="box"];\n'
            left_rule = create_graphviz_rules(tree, feature_names, class_names, left_child)
            right_rule = create_graphviz_rules(tree, feature_names, class_names, right_child)
            rules.append(condition)
            rules.append(f'{node_index} -> {left_child} [label="no"];\n')
            rules.append(f'{node_index} -> {right_child} [label="yes"];\n')
            rules.append(left_rule)
            rules.append(right_rule)
            break
    return "".join(rules)


def main():
    parser = argparse.ArgumentParser(
        description='The script renders decision table based on Shadowsocs',
    )
    parser.add_argument(
        '--input',
        help='Path to CSV table; the 2nd from the right column should be true/false if connection succeded. The rest of columns are any traits (e.g. ISP, Hoster, etc)',
        required=True,
    )
    args = parser.parse_args()

    model, feature_names = create_model(args.input)
    graph_rules = create_graphviz_rules(model.tree_, feature_names, model.classes_)
    graph = graphviz.Source(f'digraph Tree {{\n{graph_rules}\n}}')

    sys.stdout.buffer.write(graph.pipe(format='svg'))


if __name__ == '__main__':
    main()
