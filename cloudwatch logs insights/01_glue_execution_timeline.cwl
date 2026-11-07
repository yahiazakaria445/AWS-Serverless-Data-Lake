SOURCE "arn:aws:logs:us-west-2:253742142632:log-group:/aws-glue/crawlers" START=-1h END=0s |
SOURCE "arn:aws:logs:us-west-2:253742142632:log-group:/aws-glue/jobs/error" |
fields @timestamp, @message
| sort @timestamp desc
| limit 10000
| stats count(*) by bin(5s)