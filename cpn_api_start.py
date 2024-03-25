import logging

import cpn_api.configurator as configurator
import cpn_api.collector as collector
import cpn_api.connector as connector

from misc.generate_socel_xml import generate_socel_xml

from config import FILEPATH_LOG_DEBUG


logging.basicConfig(
    level=logging.WARN,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.FileHandler(FILEPATH_LOG_DEBUG),
        logging.StreamHandler()
    ],
)

logger = logging.getLogger(__name__)

if __name__ == "__main__":
    connector.mainloop()
    print("Simulation terminated. Try generating OCEL XML ...")
    generate_socel_xml()
    print("Finished.")
    
    