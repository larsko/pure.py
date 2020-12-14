import requests
import json
import lxml.etree as ET

class PureAPI:
	# Initializes API with Pure site and latest version
	def __init__(self, site, version = ''):
		self.site = site
		
		# if no version provided, use the latest Pure API
		if not version:
			self.version = self.get_latest_version()
		else:
			self.version = version

	# Makes Pure API request and return
	def request(self, endpoint, parameters = {}, accept = "application/json"):
		headers = {
			"Accept": accept, 
			"api-key": self.site.api_key
		}

		url = "{0}/ws/api/{1}/{2}".format(self.site.pure_url, self.version, endpoint)
		response = requests.get(url, parameters, headers = headers)

		if response.status_code is 200:
			return json.loads(response.content)	
		else:
			print("Error! " + response.status_code)

	# gets the API version
	def get_latest_version(self):

		url = "{0}/ws/apiversions".format(self.site.pure_url)
		# Note: Ensure that basic auth is disabled here for this to work
		response = requests.get(url)

		if response.status_code is 200:
			return ET.fromstring(response.content).xpath("//version")[0].text
		#else:
		#	raise Exception("HTTP error {0}. Please check if {1} is accessible.".format(response.status_code,url))