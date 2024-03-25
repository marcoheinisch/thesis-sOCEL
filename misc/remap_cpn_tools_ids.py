import re

def replace_ids(cpn_string):
    # Regular expression to match ID strings (starting with "ID" followed by digits)
    # RegEx Group 1 is the digits!
    id_pattern = re.compile(r'\bID(\d+)\b')

    ids_found = set(id_pattern.findall(cpn_string))
    id_mapping = {old_id: f"ID{i+1}" for i, old_id in enumerate(sorted(ids_found))}

    def new_id_by(match):
        old_id = match.group(1)  
        return id_mapping[old_id]
    
    # Replace all occurrences of the old IDs with the new IDs
    print(f"Mapping {len(id_mapping)} IDs to new IDs.")
    updated_cpn_string = id_pattern.sub(lambda match: new_id_by(match), cpn_string)

    return updated_cpn_string


def replace_cpn_ids(cpm_file_path):
    with open(cpm_file_path, 'r') as file:
        data = file.read()
        
    updated_data = replace_ids(data)
    
    with open(cpm_file_path, 'w') as file:
        file.write(updated_data)
        
replace_cpn_ids(cpm_file_path='.//cpn//HingeProduction.cpn')