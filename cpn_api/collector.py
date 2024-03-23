import logging
from requests_cache import CachedSession, NEVER_EXPIRE

from cpn_api.configurator import *
from config import API_KEY_CLIMATIQ, FILEPATH_REQUEST_CACHE, OFFLINE_MODE


logger = logging.getLogger(__name__)

# Maby replace with https://stackoverflow.com/questions/28918086/does-requests-cache-automatically-update-cache-on-update-of-info

def get_co2e(request_id: str, quantity: float):
    """
    Get the CO2 value for the given quantity and id by first checking the config-xml for an api request with the
    given id, then checking for a default value in the xml and finally throw an error.
    """
    logger.debug(f"get_co2e: {request_id} [x{quantity}]")
    factor = None
    if check_default_entry(request_id):
        factor = read_default_entry(request_id)
        return factor * quantity
    elif OFFLINE_MODE:
        return 0
    elif check_request_entry(request_id):
        endpoint, json_body, quantity_name = get_request_entry(request_id)
        json_body["parameters"][quantity_name] = 1
        factor = get_co2e_by_climatiq_call(endpoint, json_body)
        return factor * quantity
    
    raise ValueError(f"No CO2e value found for request_id {request_id}")


def get_co2e_by_climatiq_call(url: str, json_body: dict):
    """
    Get the CO2 value by calling the climatiq api.
    :param url:
    :param json_body: For parameters, see https://www.climatiq.io/docs/api-reference/models/parameters and for emission_factor, see https://www.climatiq.io/docs/api-reference/models/selector
    :return: CO2e value
    """
    session = CachedSession(
        FILEPATH_REQUEST_CACHE,
        backend='sqlite',
        serializer='json',
        allowable_codes=(200, 443, 304),
        allowable_methods=('GET', 'POST', 'HEAD'),
        cache_control=False,
        ignored_parameters=('cache-control', 'expires', 'set-cookie', 'etag', 'last-modified'),
        expire_after = NEVER_EXPIRE
    )
    
    authorization_headers = {"Authorization": f"Bearer: {API_KEY_CLIMATIQ}"}
    response = session.post(url, json=json_body, headers=authorization_headers).json()
    
    session.close()
    
    # Check if the response is valid
    if "error" in response:
        logger.error(f"Climatiq: {response}")
        raise ValueError(f"Error in response: {response['message']}")
    else:
        co2e = response["co2e"]
        co2e_unit = response["co2e_unit"] 
        #TODO: Unit check

    logger.info(f"Climatiq: {co2e} [{co2e_unit}]: {json_body} --> {response}")
    return co2e
