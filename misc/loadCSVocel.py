import pandas as pd
import glob
import os
import glob
import os
import warnings 
import sys

def get_eo_tables(path_csv):
    eventTypeTableFilenames = [fn for fn in glob.glob(path_csv + 'event_*.csv') 
                            if not fn == path_csv + "event_map_type.csv" and not fn == path_csv + "event_object.csv"]
    objectTypeTableFilenames =  [fn for fn in glob.glob(path_csv + 'object_*.csv') 
                            if not fn == path_csv + "object_map_type.csv" and not fn == path_csv + "object_object.csv"]
    return eventTypeTableFilenames, objectTypeTableFilenames

def get_ocel_df(path_csv):
    PATH_PREFIX = path_csv
    # Suppress all warnings
    shut_up = False
    if shut_up:
        warnings.filterwarnings("ignore")
        sys.stdout = open(os.devnull, 'w')
        sys.stderr = open(os.devnull, 'w')



    # Read CSV into TABLES
    TABLES = dict()
    eventTypeTableFilenames = [fn for fn in glob.glob(PATH_PREFIX + 'event_*.csv') 
                            if not fn == PATH_PREFIX + "event_map_type.csv" and not fn == PATH_PREFIX + "event_object.csv"]
    objectTypeTableFilenames =  [fn for fn in glob.glob(PATH_PREFIX + 'object_*.csv') 
                                if not fn == PATH_PREFIX + "object_map_type.csv" and not fn == PATH_PREFIX + "object_object.csv"]
    ID_COLUMN = "ocel_id"
    TABLES["event"] = pd.read_csv(PATH_PREFIX + "event.csv", sep=";")
    TABLES["event_map_type"] = pd.read_csv(PATH_PREFIX + "event_map_type.csv", sep=";")
    TABLES["event_object"] = pd.read_csv(PATH_PREFIX + "event_object.csv", sep=";")
    TABLES["object"] = pd.read_csv(PATH_PREFIX + "object.csv", sep=";")
    TABLES["object_object"] = pd.read_csv(PATH_PREFIX + "object_object.csv", sep=";")
    TABLES["object_map_type"] = pd.read_csv(PATH_PREFIX + "object_map_type.csv", sep=";")

    for fn in eventTypeTableFilenames:
        table_name = fn.split("\\")[-1].split(".")[0]
        table = pd.read_csv(fn, sep=";")
        TABLES[table_name] = table
        
    for fn in objectTypeTableFilenames:
        table_name = fn.split("\\")[-1].split(".")[0]
        table = pd.read_csv(fn, sep=";")
        TABLES[table_name] = table
        
    for fn in eventTypeTableFilenames+objectTypeTableFilenames:
        pass
        table_name = fn.split("\\")[-1].split(".")[0]
        
    special_indexes = [
            ("event_object", ["ocel_event_id", "ocel_object_id", "ocel_qualifier"]),
            ("event", ["ocel_id"]),
            ("event_map_type", ["ocel_type"]),
            ("object_map_type", ["ocel_type"]),
            ("object_object", ["ocel_source_id", "ocel_target_id", "ocel_qualifier"]),
            ("object", ["ocel_id"]),
        ]

    for tn, indexes in special_indexes:
        TABLES[tn].set_index(indexes, inplace=True)
        
    return TABLES