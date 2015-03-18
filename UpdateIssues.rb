require 'octokit'
require 'dbi'
require 'active_record'
require 'mysql2'

class UpdateIssues
	def update_since(date)
		client=Octokit::Client.new(:access_token => 'a2d8eb494d41bb4a2b9e2dcc38d7b1ba666b340e')
		client.auto_paginate=true
		issues=client.issues('mFieldwork/mFieldwork', {:since => date})
		ActiveRecord::Base.establish_connection(adapter: 'mysql2', host: 'localhost',database: 'gitissues',username:'root',password: 'root')
		issues.each do |issue|
			db_issue=Issue.where(number: issue.number).take
			if db_issue
				db_issue.state=issue.state
				db_issue.save
				events=client.issue_events('mFieldwork/mFieldwork',issue.number)
				events.each do |event|
					if !Event.where(event_id: event.event_id).take
						db_event=Event.new()
						db_event.issue_number=issue.number
						db_event.event_id=event.id
						db_event.event_type=event.event
						db_event.actor=event.actor.login
						db_event.created_on=event.created_at
						db_event.assignee = event.assignee.login if event.assignee
						db_event.save
					end
				end
			end
			if !db_issue
				db_issue=Issue.new()
				db_issue.number=issue.number
				db_issue.state=issue.state
				db_issue.title=issue.title
				db_issue.body=issue.body
				db_issue.user=issue.user.login
				db_issue.assignee=issue.assignee.login if issue.assignee
				db_issue.created_on=issue.created_at
				db_issue.updated_on=issue.updated_at
				db_issue.closed_on=issue.closed_at if issue.closed_at
				if issue.labels
					issue.labels.each do |label|
						db_issue.labels=db_issue.labels.to_s + ' ' + label.name.to_s
					end
				end
				db_issue.save
				events=client.issue_events('mFieldwork/mFieldwork',issue.number)
				events.each do |event|
					db_event=Event.new()
					db_event.issue_number=issue.number
					db_event.event_id=event.id
					db_event.event_type=event.event
					db_event.actor=event.actor.login
					db_event.created_on=event.created_at
					db_event.assignee = event.assignee.login if event.assignee
					db_event.save
				end
			end
		end
	end
end
class Event < ActiveRecord::Base
end

class Issue < ActiveRecord::Base
end

class Assignment < ActiveRecord::Base
end
