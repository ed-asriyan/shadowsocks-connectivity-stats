COLLECTING_DATA_IMAGE_NAME=ss-collecting-data
CREATE_TREE_IMAGE_NAME=ss-decision-tree
STATS_FILE=./your-data/stats.csv
DEICISION_TREE_FILE=./your-data/decision-tree.svg

create_collecting_image:
	docker build -t $(COLLECTING_DATA_IMAGE_NAME) 1-collecting-data

1_collect_stats: create_collecting_image
	docker run --rm -e SS_CONF_URL=$(SS_CONF_URL) $(COLLECTING_DATA_IMAGE_NAME) > $(STATS_FILE)

create_decition_tree_image:
	docker build -t $(CREATE_TREE_IMAGE_NAME) 2-decision-tree

2_create_decition_tree: create_decition_tree_image
	docker run --rm -v ./your-data/stats.csv:/input.csv $(CREATE_TREE_IMAGE_NAME) > $(DEICISION_TREE_FILE)
