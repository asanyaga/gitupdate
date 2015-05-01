require 'octokit'
require 'dbi'
require 'active_record'
require 'mysql2'

class UpdateIssues
	def update_since(date)
		client=Octokit::Client.new(:access_token => ENV['GITBAN_AUTH'])
		client.auto_paginate=true
		issues=client.issues('mFieldwork/mFieldwork', {:since => date})
		ActiveRecord::Base.establish_connection(adapter: 'mysql2', host: 'localhost',database: 'gitissues',username:'root',password: 'root')

		issues.each do |issue|
			db_issue=Issue.where(number: issue.number).take
			if db_issue
				db_issue.state=issue.state
				if issue.assignee
					db_assignee=Assignee.where("name = ?", issue.assignee.login).take
					db_issue.assignee=db_assignee
				end
				db_issue.updated_on=issue.updated_at
				db_issue.closed_on=issue.closed_at if issue.closed_at
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

				if issue.assignee
					db_issue.assignee_name=issue.assignee.login
					db_assignee=Assignee.where("name = ?", issue.assignee.login).take
					db_issue.assignee=db_assignee
				end

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

def load_stages
	ActiveRecord::Base.establish_connection(adapter: 'mysql2', host: 'localhost',database: 'gitissues',username:'root',password: 'root')
	issues=Issue.joins(assignee: :stage).where('status' => 'open')
	stages=Hash.new {|h,k| h[k]=[]}
	issues.each do |issue|
			stages[""]
	end

end

class Event < ActiveRecord::Base
end

class Issue < ActiveRecord::Base
	belongs_to :assignee
end

class Assignment < ActiveRecord::Base
end

class Assignee < ActiveRecord::Base
	belongs_to :stage
end

class Stage < ActiveRecord::Base
end
