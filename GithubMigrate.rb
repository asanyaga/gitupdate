require 'octokit'
require 'dbi'
require 'active_record'
require 'mysql2'
class MigrateIssue

	def migrate_all_issues
		client=Octokit::Client.new(:access_token => ENV['GITBAN_AUTH'])
		client.auto_paginate=true
		issues=client.issues('mFieldwork/mFieldwork', {:state => 'all'})

		ActiveRecord::Base.establish_connection(adapter: 'mysql2', host: 'localhost',database: 'gitissues',username:'root',password: 'root')

		issues.each do |issue|
			db_issue=Issue.new()
			db_issue.number=issue.number
			db_issue.state=issue.state
			db_issue.title=issue.title
			db_issue.body=issue.body.to_s
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
		end
	end

	def update_since(date)
		client=Octokit::Client.new(:access_token => ENV['GITBAN_AUTH'])
		client.auto_paginate=true
		issues=client.issues('mFieldwork/mFieldwork', {:since => date})
		ActiveRecord::Base.establish_connection(adapter: 'mysql2', host: 'localhost',database: 'gitissues',username:'root',password: 'root')

		issues.each do |issue|
			db_issue=Issue.find(issue.number)
			if db_issue
				db_issue.state=issue.state
				events=client.issue_events('mFieldwork/mFieldwork',issue.number)
				events.each do |event|
					if Event.where(event_id: event.event_id).take != nil
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
				db_issue.save
			else
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

	def migrate_test
		client=Octokit::Client.new(:access_token => ENV['GITBAN_AUTH'])
		client.auto_paginate=true

		ActiveRecord::Base.establish_connection(adapter: 'mysql2', host: 'localhost',database: 'gitissues',username:'root',password: 'root')
		number_range = (1..48).to_a
		number_range.each do |issue_number|
			issue=client.issue('mFieldwork/mFieldwork', issue_number)
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
		end
	end

	def save_new_issue(issue)
		ActiveRecord::Base.establish_connection(adapter: 'mysql2', host: 'localhost',database: 'gitissues',username:'root',password: 'root')

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
	end

	def save_event(event)
		db_event=Event.new()
		db_event.issue_number=event.issue.number
		db_event.event_id=event.id
		db_event.event_type=event.event
		db_event.actor=event.actor.login
		db_event.created_on=event.created_at
		db_event.assignee = event.assignee.login if event.assignee
		db_event.save
	end

	def migrate_update_closed
		ActiveRecord::Base.establish_connection(adapter: 'mysql2', host: 'localhost',database: 'gitissues',username:'root',password: 'root')
		client=Octokit::Client.new(:access_token => ENV['GITBAN_AUTH'])
		client.auto_paginate=true
		issues=client.issues('mFieldwork/mFieldwork', {:state => 'closed'})

		issues.each do |issue|
			db_issue=Issue.where("number = #{issue.number}")
			db_issue[0].closed_on=issue.closed_at
			db_issue[0].save
		end
	end

	def migrate_events
		ActiveRecord::Base.establish_connection(adapter: 'mysql2', host: 'localhost',database: 'gitissues',username:'root',password: 'root')
		client=Octokit::Client.new(:access_token => ENV['GITBAN_AUTH'])
		client.auto_paginate=true
		#issues=Issue.find(:all)
		Issue.find_each do |issue|
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

	def migrate_time_assigned
		#Issue.find_each do |db_issue|
		ActiveRecord::Base.establish_connection(adapter: 'mysql2', host: 'localhost',database: 'gitissues',username:'root',password: 'root')
		#issues=Issue.where('number = 1812')
		#issues.each do |db_issue|
		Issue.find_each do |db_issue|
			issue_assignees=Event.where("issue_number=#{db_issue.number} and (event_type='assigned' or event_type='unassigned')").select(:assignee).distinct
			#puts "asignees are " + issue_assignees.count.to_s
			issue_assignees.each do |issue_assignee|
				#puts "assignee is " + issue_assignee.assignee
				events=Event.where("issue_number=#{db_issue.number} and (event_type='assigned' or event_type='unassigned') and assignee='#{issue_assignee.assignee}'").order("cast(created_on as DATETIME) asc")
				events.each do |event|
					if event.event_type=='assigned'
						db_assignment=Assignment.new
						db_assignment.issue_number=event.issue_number
						db_assignment.assign_date=event.created_on
						db_assignment.assignee=event.assignee
						eventindex=events.index(event)
						unassignevent=events[eventindex+1]
						if unassignevent
							if unassignevent.event_type=='unassigned'
								db_assignment.unassign_date=unassignevent.created_on
							end
						end
						db_assignment.save
					end
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
