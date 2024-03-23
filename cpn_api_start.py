import logging

import cpn_api.configurator as configurator
import cpn_api.collector as collector
import cpn_api.connector as connector

from config import FILEPATH_LOG_DEBUG


logging.basicConfig(
    level=logging.CRITICAL,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.FileHandler(FILEPATH_LOG_DEBUG),
        logging.StreamHandler()
    ],
)

logger = logging.getLogger(__name__)

if __name__ == "__main__":
    connector.mainloop()