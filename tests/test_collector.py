import cpn_api_start # enables logging while testing

import unittest
import os
import logging

import cpn_api.collector as collector
import cpn_api.configurator as xml
import config


class TestCollector(unittest.TestCase):

    def setUp(self):
        self.request_id = 'id_electricity-supply_grid-source_nuclear'
        self.quantity_name = 'energy'
        self.param_data = {
            "energy": 100,
            "energy_unit": "kWh"
        }
        self.factor_data = {
            "id": 'f4eeeece-ad93-47c6-b216-b3f01d24afb6'
        }
        xml.add_request_climatiq(
            self.request_id, 
            self.param_data, 
            self.factor_data, 
            self.quantity_name
        )
        self.json_body = {
            "parameters": self.param_data,
            "emission_factor": self.factor_data
        }
        self.co2e = 5.5

    def test_get_co2e_by_climatiq_call(self):
        self.assertEqual(xml.check_request_entry(self.request_id), True)
        co2e = collector.get_co2e_by_climatiq_call(
            url="https://beta4.api.climatiq.io/estimate",
            json_body=self.json_body
        )
        self.assertEqual(co2e, self.co2e)

    def test_get_co2e(self):
        pass


if __name__ == '__main__':
    unittest.main()
