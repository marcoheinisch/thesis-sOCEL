import cpn_api_start # enables logging while testing

import unittest
import os
import logging

import cpn_api.configurator as xml
import config


class TestConfigurator(unittest.TestCase):

    def setUp(self):
        self.param_data = {
            "weight": 1,
            "weight_unit": "t"
        }
        self.factor_data = {
            "activity_id": "metals-type_steel_cold_rolled_coil",
            "region": "GLOBAL",
            "data_version": "^3"
        }
        self.quantity_name = "weight"
        self.exisiting_id = "id_example_call_existing"
        self.not_exisiting_id = "id_example_call_nooooot_existing"
        xml.clear_requests()

    def test_xml_write(self):
        xml.clear_requests()
        xml.add_request_climatiq(self.exisiting_id, self.param_data, self.factor_data, self.quantity_name)

    def test_xml_read_id(self):
        xml.add_request_climatiq(self.exisiting_id, self.param_data, self.factor_data, self.quantity_name)
        endpoint, json_body, quantity_name = xml.get_request_entry(self.exisiting_id)
        for key, value in self.param_data.items():
            self.assertEqual(json_body["parameters"][key], value)
        for key, value in self.factor_data.items():
            self.assertEqual(json_body["emission_factor"][key], value)

    def test_xml_read_no_id(self):
        self.assertEqual(xml.check_request_entry(self.not_exisiting_id), False)
        with self.assertRaises(ValueError):
            xml.get_request_entry(self.not_exisiting_id)


if __name__ == '__main__':
    unittest.main()
