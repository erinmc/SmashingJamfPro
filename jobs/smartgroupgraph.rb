#!/usr/bin/ruby

# Job to populate a Graph widget with the cout of devices in a Smart Computer Group

#Add required libraries

require 'net/http'
require 'uri'
require 'json'

config = YAML.load_file("lib/jamfpro.yml")
url = config['url']
# If running multiple jobs pulling graphs, change the config[ggroup1] to reflect the group in your yml file
graphgroup = config['ggroup1']

# Schedule job to do

# Determine points on the graph.  Below will output a 1 second interval
# If you wish to do 1 minute data pulls, for example, change line 23 to read '(1..120).each do |i|'
# 2 X 60 seconds 

points = []
(1..10).each do |i|
	points << { x: i }
end
last_x = points.last[:x]

# Get JSON from specific Smart Computer Group

uri = URI.parse("#{url}/JSSResource/computergroups/id/#{graphgroup}")
request = Net::HTTP::Get.new(uri)
request.basic_auth(config['user'], config['password'])
request["Accept"] = "application/json"

req_options = {
	use_ssl: uri.scheme == "https",
}
# Change the .every in SCHEDULER to reflect the frequency of the pull (i.e. '5m' for 5 minutes)

SCHEDULER.every '5s', :first_in => 0 do |job|
response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
	http.request(request)
end

# Check for HTTP Status OK.  

if (response.code == "200") then
# If OK, get count of computers and name of smart group

	devicecount = JSON.parse(response.body)['computer_group']['computers'].size
	searchname = JSON.parse(response.body)['computer_group']['name']
	points.shift
	last_x += 1
	points << { x: last_x, y: devicecount }
	send_event('managedgraph', 
	{points: points,
	title: searchname
	})
	
	else
	
# If not OK, display status code in Smashing Output
	
	print "Smart Computer Group ID: #{graphgroup}"
	print "#{searchname} - Error: HTTP Status code #{response.code}"
	end

end
