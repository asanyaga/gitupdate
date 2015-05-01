select issue_number,issues.title,issues.assignee as currently_assigned,issues.state,datediff(ifnull(issues.closed_on,curdate()),issues.created_on) as days_open,
sum(case when (aa.assignee='acholasam') then numberofdays_assigned else 0 end) as 'acholasam',
sum(case when (aa.assignee='AlexMuriithi') then numberofdays_assigned else 0 end) as 'AlexMuriithi',
sum(case when (aa.assignee='asanyaga') then numberofdays_assigned else 0 end) as 'asanyaga',
sum(case when (aa.assignee='colleowino') then numberofdays_assigned else 0 end) as 'colleowino',
sum(case when (aa.assignee='john-mwendwa') then numberofdays_assigned else 0 end) as 'john-mwendwa',
sum(case when (aa.assignee='kevinmwangi') then numberofdays_assigned else 0 end) as 'kevinmwangi',
sum(case when (aa.assignee='kmasha') then numberofdays_assigned else 0 end) as 'kmasha',
sum(case when (aa.assignee='knjendu') then numberofdays_assigned else 0 end) as 'knjendu',
sum(case when (aa.assignee='Leithb') then numberofdays_assigned else 0 end) as 'Leithb',
sum(case when (aa.assignee='Njigi') then numberofdays_assigned else 0 end) as 'Njigi',
sum(case when (aa.assignee='Rodgy') then numberofdays_assigned else 0 end) as 'Rodgy',
sum(times_assigned) as number_of_assigns
 from(
select issue_number,assignments.assignee,sum(datediff(ifnull(unassign_date,if(issues.closed_on is null,curdate(),issues.closed_on)),assign_date)) as numberofdays_assigned,count(assignments.assignee) as times_assigned from assignments 
join issues on assignments.issue_number=issues.number
group by issue_number,assignee order by cast(issue_number as signed) desc) 
aa
join issues on aa.issue_number=issues.number
group by issue_number
order by cast(issue_number as signed) desc