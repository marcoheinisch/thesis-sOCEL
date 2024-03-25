# This file is used to read and write the requests.xml file.
# The requests.xml file contains the requests that can be made to the backend.
# 
# XML structure:
# <Configuration>
#     <Requests>
#         <APIRequest id="id_example_call_existing" quantity_name="weight">
#             ...
#         </APIRequest>
#         ...
#     </Requests>
# </Configuration>

import os
import xml.etree.ElementTree as ET
import config
import logging


logger = logging.getLogger(__name__)
   
def _ceckfix_requests(root):
    requests = root.find('Requests')
    if requests is None:
        requests = ET.SubElement(root, "Requests")
    return requests
        

def clear_requests():
    """
    Clear the requests.xml file.
    :return:
    """
    root = ET.Element("Configuration")
    requests = _ceckfix_requests(root)
    tree = ET.ElementTree(root)
    with open(config.FILEPATH_REQUESTS_XML, "wb") as file:
        tree.write(file)
    logger.debug(f"XML: Requests cleared.")
        
        
def add_request_climatiq(request_id, param_data, factor_data, quantity_name):
    """
    Add a new or override existing api request entry to the config xml file based on request id.
    :param param_data:
    :param factor_data:
    :param quantity_name:
    :return:
    """
    root = ET.parse(config.FILEPATH_REQUESTS_XML).getroot()
    requests = _ceckfix_requests(root)

    exisiting_request = root.findall(f'./Requests/APIRequest[@id="{request_id}"]')
    for request in exisiting_request if exisiting_request is not None else []:
        requests.remove(request)

    api_request = ET.SubElement(requests, "APIRequest", id=request_id, quantity_name=quantity_name)

    endpoint = ET.SubElement(api_request, "Endpoint")
    endpoint.text = "https://beta4.api.climatiq.io/estimate"

    parameters = ET.SubElement(api_request, "Parameters")
    for param_name, param_value in param_data.items():
        param = ET.SubElement(parameters, param_name)
        param.text = str(param_value)

    factors = ET.SubElement(api_request, "Emission_factor")
    for factor_name, factor_value in factor_data.items():
        factor = ET.SubElement(factors, factor_name)
        factor.text = str(factor_value)

    tree = ET.ElementTree(root)
    with open(config.FILEPATH_REQUESTS_XML, "wb") as file:
        tree.write(file)
        
    logger.debug(f"XML: Added Climatiq request {request_id}.")


def check_request_entry(request_id):
    """
    Check if the api request with the given id exists in the config xml file.
    :param request_id:
    :return: True if the request exists, False otherwise
    """
    tree = ET.parse(config.FILEPATH_REQUESTS_XML)
    root = tree.getroot() 
    requests = _ceckfix_requests(root)

    api_request = root.find(f'./Requests/APIRequest[@id="{request_id}"]')
    is_found = api_request is not None
    
    logger.debug(f"XML: check_request_entry {request_id} -> {is_found}")
    return is_found


def get_request_entry(request_id):
    """
    Read the api request with the given id from the config xml file. Raise a ValueError if no request is found.
    :param request_id:
    :return:
    """
    tree = ET.parse(config.FILEPATH_REQUESTS_XML)
    root = tree.getroot()
    requests = _ceckfix_requests(root)

    api_request = root.find(f'./Requests/APIRequest[@id="{request_id}"]')
    if api_request is None:
        raise ValueError(f'No APIRequest found with id: {request_id}')

    endpoint = api_request.find('Endpoint').text
    parameters = {param.tag: param.text for param in api_request.find('Parameters')}
    factors = {factor.tag: factor.text for factor in api_request.find('Emission_factor')}
    quantity_name = api_request.attrib['quantity_name']

    json_body = {
        "emission_factor": factors,
        "parameters": parameters
    }
    
    json_body["parameters"][quantity_name] = float(json_body["parameters"][quantity_name])
    
    logger.debug(f"XML: get_request_entry {request_id} -> {json_body}")
    return endpoint, json_body, quantity_name

def get_list_of_request_ids():
    """
    Get a list of all request ids in the config xml file.
    :return: list of request ids
    """
    tree = ET.parse(config.FILEPATH_REQUESTS_XML)
    root = tree.getroot()
    requests = _ceckfix_requests(root)

    api_requests = requests.findall('./APIRequest')
    request_ids = [api_request.attrib['id'] for api_request in api_requests]
    
    default_requests = requests.findall('./Default')
    request_ids += [default_request.attrib['id'] for default_request in default_requests]

    logger.debug(f"XML: get_list_of_request_ids -> {request_ids}")
    return request_ids

def add_default_entry(request_id, co2e_value_factor):
    """
    Add a new or override existing default entry to the config xml file based on request id.
    :param request_id:
    :param co2e_value_factor: factor to multiply the quantity with to get the CO2e value 
    :return:
    """
    root = ET.parse(config.FILEPATH_REQUESTS_XML).getroot()
    requests = _ceckfix_requests(root)

    exisiting_request = root.findall(f'./Requests/Default[@id="{request_id}"]')
    for request in exisiting_request if exisiting_request is not None else []:
        requests.remove(request)

    default = ET.SubElement(requests, "Default", id=request_id)
    default.text = str(co2e_value_factor)

    tree = ET.ElementTree(root)
    with open(config.FILEPATH_REQUESTS_XML, "wb") as file:
        tree.write(file)
        
    logger.debug(f"XML: Added default entry {request_id}.")

def check_default_entry(request_id):
    """
    Check if the default entry with the given id exists in the config xml file.
    :param request_id:
    :return: True if the default entry exists, False otherwise
    """
    tree = ET.parse(config.FILEPATH_REQUESTS_XML)
    root = tree.getroot()
    requests = _ceckfix_requests(root)

    default = root.find(f'./Requests/Default[@id="{request_id}"]')
    is_found = default is not None
    
    logger.debug(f"XML: check_default_entry {request_id} -> {is_found}")
    return is_found


def read_default_entry(request_id):
    """
    Read the default entry with the given id from the config xml file. Raise a ValueError if no default entry is found.
    :param request_id:
    :return: CO2e value
    """
    tree = ET.parse(config.FILEPATH_REQUESTS_XML)
    root = tree.getroot()
    requests = _ceckfix_requests(root)

    default = root.find(f'./Requests/Default[@id="{request_id}"]')
    if default is None:
        raise ValueError(f'No Default found with id: {request_id}')

    co2e = float(default.text)
    
    logger.debug(f"XML: read_default_entry {request_id} -> {co2e}")
    return co2e