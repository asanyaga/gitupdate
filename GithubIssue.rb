require 'data_mapper'

DataMapper.setup(:default, 'mysql://root:root@localhost:3306/gitissues')

class Issue
	include DataMapper::Resource
	
	property :id, Serial
	property :number, String
	property :issue_id, String
	property :state, String
	property :title, String
end

DataMapper.auto_migrate!