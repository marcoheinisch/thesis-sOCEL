# Tested with Python 3.11 and CPN Tools 4.0.1
# Server for use with hinge_production.cpn model example

# CPN-Tools sml-code: 
# 
# openConnection("Con1", "localhost", 9999)
# send("Con1", "some_string", stringEncode);
# closeConnection("Con1") 
# 
# output(res); action receive("Con1", stringDecode);

import atexit
import logging

from cpn_api.pycpn.pyCPN import PyCPN
from cpn_api.pycpn.pyCPNEncodeDecode import stringEncode, stringDecode
from cpn_api.collector import get_co2e


logger = logging.getLogger(__name__)

def mainloop():
    print("Started. Awaiting CPN connection.")
    logger.info("mainloop: awaiting connection")
    port = 9999
    conn = PyCPN()
    conn.accept(port) # wait for connection - can block
    logger.debug("mainloop: connection established")

    def exit_handler():
        conn.disconnect()
        logger.info("mainloop: exit by exit_handler")

    atexit.register(exit_handler)

    try:
        while True:
            msg = stringDecode(conn.receive())
            if msg == 'init':
                logger.info("mainloop: init")
                conn.send(stringEncode("confirmed"))
                print("Connected.")
            elif msg == 'close':
                logger.info("mainloop: close")
                break
            elif 'call_v1%' in msg:
                # assumes a msg of the form: {"call_v1"}%{request_id}%{quantity}
                # or simplified: call(request_id, quantity)
                _, request_id, quantity = msg.split('%')
                logger.debug("mainloop: received string: " + msg)
                
                try:         
                    quantity = float(quantity) #TODO: convert to float
                except:
                    response = ""
                    logger.debug("mainloop: send string: " + response)
                    conn.send(stringEncode(response))
                else:
                    request_id = str(request_id)
                    response = str(get_co2e(request_id, quantity))
                    
                    logger.debug("mainloop: send string: " + response)
                    conn.send(stringEncode(response))
            else:
                pass
    except Exception as e:
        logger.error("mainloop: exception: " + str(e))
        conn.disconnect()
        raise e
