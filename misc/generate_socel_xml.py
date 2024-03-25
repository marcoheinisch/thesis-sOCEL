import pandas as pd
import sqlite3
import glob
import os
import pm4py
import warnings 
import sys

def generate_socel_xml():
    PATH_PREFIX = os.path.join(os.path.dirname(__file__), os.pardir, 'data', 'socel-csv\\')
    PATH_PREFIX_OUT = os.path.join(os.path.dirname(__file__), os.pardir, 'data', 'socel\\')
    PATH_SQLITE = os.path.join(PATH_PREFIX_OUT, "socel_hinge_pre.sqlite")


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


    # Convert TABLES to SQLite
    if os.path.exists(PATH_SQLITE):
        os.remove(PATH_SQLITE)
    conn = sqlite3.connect(PATH_SQLITE)
    for tn, df in TABLES.items():
        try:
            #print(df.index.name)
            df.to_sql(tn, conn, if_exists='replace', index=True)
        except(ValueError) as e:
            print('ValueError')
    conn.close()


    # Write the XML file
    ocel = pm4py.read_ocel2_sqlite(PATH_SQLITE)
    pm4py.write_ocel2_xml(ocel, PATH_PREFIX_OUT + 'socel_hinge_pre.xml')
    if os.path.exists(PATH_SQLITE):
        os.remove(PATH_SQLITE)


    # Read and clean the XML file from SQLite fragmets like @@cumcount and index
    from lxml import etree
    with open(PATH_PREFIX_OUT + 'socel_hinge_pre.xml', 'rb') as file:
        tree = etree.parse(file)
    xpath = ".//attribute[@name='@@cumcount']"
    cumcount_elements = tree.xpath(xpath)
    for elem in cumcount_elements:
        elem.getparent().remove(elem)
    xpath = ".//attribute[@name='index']"
    othr_elements = tree.xpath(xpath)
    for elem in othr_elements:
        elem.getparent().remove(elem)
    tree.write(PATH_PREFIX_OUT + 'socel_hinge.xml', pretty_print=True, xml_declaration=False, encoding='UTF-8')
    if os.path.exists(PATH_PREFIX_OUT + 'socel_hinge_pre.xml'):
        os.remove(PATH_PREFIX_OUT + 'socel_hinge_pre.xml')
        
    print("Generated xml to: " + PATH_PREFIX_OUT + 'socel_hinge.xml')