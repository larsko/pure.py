import os
from pureapi import PureAPI
import jsonpickle
import json

# Source URL represents source where XML data is being loaded from
# inherits form object to support serialization
class Site(object):
	names = {}
	def __init__(self, name, source_url, root_org, api_key = '', pure_url = ''):
		self.name = name
		self.url = source_url
		self.root_org = root_org
		self.api_key = api_key
		self.pure_url = pure_url

# Utility class load/save objects to disk
class Serializer:
	# Serialize dictionary to disk, e.g. for person matches
	def save(self, obj, name):
		with open(name + '.json', 'w') as f: 
			f.write(jsonpickle.encode(obj))

	# Load person matches from disk
	def load(self, name):
		if(os.path.exists(name + '.json')):
			with open(name + '.json', 'rb') as f:
				return jsonpickle.decode(f.read())

# Resolves person IDs using the Pure API based on Lucene query
class PersonResolver:
	def __init__(self, site):
		self.site = site
		self.api = PureAPI(site, '512')
		self.matches = {}

	# load previous matches from JSON file
	def load_matches(self):
		self.matches = Serializer().load(self.site.name)
		return self.matches

	def save_matches(self):
		Serializer().save(self.matches, self.site.name)

	# matches persons against a list of candidates and returns results
	def match(self, candidates, query = "^firstname:{0} AND lastname:{1}", fields = "externalId, name.*"):
		# reset matches
		self.matches = {}
		# Check each unique name combo once
		for (fullname, names) in candidates.items():
			# Lucene query to search for first and last
			q = query.format(names[0], names[1])

			parameters = { 
				"q": q, 
				"fields": fields 
			}
			print(parameters)
			# We only need the ID and name
			results = self.api.request("persons", parameters)

			if results:
				for item in results["items"]:
					self.matches[fullname] = item['externalId']

		# mapping of internal persons, i.e. (firstname,lastname) = externalId
		return self.matches					

	#custom func to lookup on (firstname,lastname)
	def lookup_person(self, context, firstname, lastname):
		lookup = "{0};{1}".format(firstname, lastname)
		if lookup in self.matches:
			return self.matches[lookup]
