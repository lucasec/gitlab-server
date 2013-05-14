module GitLabURL
  def self.buildURL( hash )
    url = hash['secure_port'].nil? ? 'http://' : 'https://'
	url += hash['hostname']
	unless hash['secure_port'].nil?
		url += ':' + hash['secure_port'] unless hash['secure_port']=='443'
	else
		url += ':' + hash['port'] unless hash['port']=='80'
	end
	url += hash['path']
	return url
  end
end