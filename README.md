# thesis-sOCEL

This project integrates a CPN-Tools model with Python to generate an object-centric event log (sOCEL) enriched with sustainability data.

## Setup

- Install [CPN-Tools](http://cpntools.org/).
- Get [Climatiq API](https://www.climatiq.io/) key and insert it in `config.py` (rename `config.py.default`)
- Run `pip install -r requirements.txt`.
- Run `cpn_api_start.py` to start the local API.
- Run simulation in CPN-Tools. Preconfigured, it needs to run for 60000 cycles. After that the API connection needs to be closed manually in CPN-Tools by trigering the close transition.

The sOCEL (csvs and xml) can be analyzed using [analyse_socel_csvs.ipynb](analyse_socel_csvs.ipynb) and [analyse_socel_xml.ipynb](analyse_socel_xml.ipynb).

## Run without API / Offline Mode

- In CPN-Tools under `declarations`, set `API_ENABLED` to `false` in the SML code and don't start the `cpn_api` tool for simulation.

## Structure

- `/cpn`: Contains the CPN-Tools model and the necessary SML code. Set `API_ENABLED` to `false` in the SML code to run in dummy mode without a backend.
- `/cpn_api`: Contains a Python tool that connects to CPN-Tools via socket. Use `cpn_api_frontend.ipynb` for configuring calls to include sustainability data.
- `/data`: Stores the sOCEL in CSV and XML formats, along with configuration files for `cpn_api`.

## Troubleshooting

If CPN Tools displays a "Compile error when generating code", use `/misc/remap_cpn_tools_ids.py` on an uncompromised file to remap the IDs of the CPN model.

## Credits

Based on/using:
- [PyCPN GitHub repository](https://github.com/vgehlot/PyCPN)
- [SML Code Base](https://doi.org/10.5281/zenodo.8289899)
- [PM4PY](https://pm4py.fit.fraunhofer.de/) ([GitHub](https://github.com/pm4py/pm4py-core))
