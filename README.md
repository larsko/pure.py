# pure.py
A set of Python tools to make help transform and data for Pure.

*Disclaimer:* This code is provided "as-is" for educational purposes under the MIT license and should in no way be considered production-ready code. The author is not obligated to maintain, fix or otherwise provide technical support to end-users. Please refer to the license for more details. 

Tools:
- *patents.py* Python script to harvest Inteum patents and convert them to XML according to the publications.xsd used in the Pure bulk XML import wizard. 
- *pureapi.py* A simple wrapper for the Pure API. Will default to the latest Pure API version if nothing else is specified.


## Harvesting patents from Inteum:
1. Determine your Inteum RSS 2.0 URL.
1. Create a Pure API key (required for resolving persons).
1. Run `pip install -r requirements.txt` to add packages. 
1. Initialize sites.json with your institution's values (see below for details).
1. Run python patents.py (Output will be saved to current directory).
1. `<YOUR_PURE_NAME>\_out.xml` can be imported into Pure.

### sites.json
Each site is a `Site` object that contains a Pure API key, name, Pure URL, root org ID and source URL (to pull XML data from). 

The script supports harvesting multiple sites. Simply add these to the sites.json file to instantiate additional `Site` objects.
```javascript
[
    {
        "py/object": "puresite.Site",
        "api_key": "<YOUR_API_KEY",
        "name": "<YOUR_PURE_NAME>",
        "pure_url": "<YOUR_PURE_URL>",
        "root_org": "<YOUR_ROOT_ORG_ID>",
        "url": "<YOUR_DATA_PURL>"
    }
]
```

Example:
```javascript
[
    {
        "py/object": "puresite.Site",
        "api_key": "xxxxxxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
        "name": "my_name",
        "pure_url": "https://mypure.elsevierpure.com",
        "root_org": "my_root_org_source_id",
        "url": "http://my_inteum_site.technologypublisher.com/RssDataFeed.aspx?UpdateOnOrAfter=1/1/2010"
    }
]
```

### Transforming Inteum RSS 2.0 to Publications
See `rss-to-pubs.xsl` for a stylesheet that converts the XML to be ingested by Pure. Note that parameters are passed from Python, hence the transformation will not be complete when run outside of `patents.py`.

- For reference, the schema files publications.xsd and commons.xsd files can be downloaded from Pure as an Administrator.
- Default visibility of converted patents is set to _Restricted_.

### Resolving Persons
The RSS feed does not contain unique identifiers for inventors. Pure will only match inventors to internal persons if there is an exact match on the name, which cannot always be guaranteed. To get around this, the script will attempt to map inventors to persons in Pure.

See puresite.py for details on how to match internal Pure persons with a Lucene query against the Pure API. Successful matches are mapped to the `externalId` (Pure source ID) of a person with a closely matching name. 

Note: If multiple persons match on the same name, only the last match will be saved. Additional functionality can be added for more sophisticated matching logic.

Each match will be added to a dictionary and saved to a JSON file "<YOUR_PURE_NAME>.json" for faster re-run, e.g.
```javascript
{"John;Doe": "7213cfd7abac1973c9d018a3fb1022f3"}
```
Matches are used by the XSLT to enrich persons with an internal ID using an extension function `python:lookup_person`.

### Contributors
- Lars K Oestergaard
