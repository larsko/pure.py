
import lxml.etree as ET
from dateutil import parser
from puresite import *
import requests

# TODO: Create  external inventors
# TODO: get root Org dynamically from Pure API, if desired...
# TODO: search for all external persons, return matches, choose one with most external orgs/info

# Main entry point
def main():	

	sites = Serializer().load("njeda")

	for site in sites:
		get_patents(site)

# Downloads Inteum patents from a site
def get_patents(site):
	print("------------------")
	print(site.name)
	print("------------------")

	print("Saving XML from {0}...".format(site.url))
	save_file(requests.get(site.url), '.', site.name)
	
	# Resolve inventor names and save if not done yet.
	if not PersonResolver(site).load_matches():
		match_persons(site)

	print("Transforming XML {0}.xml to {0}_out.xml...".format(site.name))
	transform(site)

def save_file(response, folder, name):
	tree = ET.fromstring(response.content)
	print("Patents: {0}".format(len(tree.xpath('//item'))))

	path = os.path.join(folder, name+".xml")

	ET.ElementTree(tree).write(path, pretty_print = True)

# Attempts to match inventors with internal persons in a Pure site using API 
def match_persons(site):
	# search for all internal persons, return matches

	xml = ET.parse(site.name + ".xml")
	ns = {'dataField': 'https://www.inteum.com/technologies/data/'}

	# Get all inventor names from RSS feed
	candidates = {}
	for inventor in xml.xpath("//dataField:inventor", namespaces = ns):
		first = inventor.find("dataField:firstName", ns).text
		last = inventor.find("dataField:lastName", ns).text

		# Hash candidates by full name, so we prune repeat occurences
		candidates["{0};{1}".format(first,last)] = (first,last)

	print("Candidates: {0}".format(len(candidates)))

	pr = PersonResolver(site)
	matches = pr.match(candidates)

	#Save matches to disk
	pr.save_matches()

	print("Matches found: {0}".format(len(matches)))

#Custom XSLT functions:
# Parse, s and return the desired {%Y, %m or %d} component
def get_date(context, s, component):
	dt = parser.parse(s)
	return dt.strftime("%{0}".format(component))

def transform(site):
	# get files for particular site
	xml_filename = site.name + ".xml"
	xsl_filename = 'rss-to-pubs.xsl'
	xml_output_filename = site.name + "_out.xml"

	# Person resolver for current site to get names
	pr = PersonResolver(site)
	pr.load_matches()

	# Add custom functions to XSLT context
	ns = ET.FunctionNamespace("python")
	ns['get_date'] = get_date
	ns['lookup_person'] = pr.lookup_person

	# Transform XML
	xml = ET.parse(xml_filename)
	transform = ET.XSLT(ET.parse(xsl_filename))

	# pass dynamic parameters to XSLT, e.g. root Org ID
	transformed = transform(xml, site = ET.XSLT.strparam(site.name), root_org = ET.XSLT.strparam(site.root_org))

	# Save transformed XML file
	transformed.write(xml_output_filename, pretty_print = True, xml_declaration = True, encoding = "utf-8")

main()