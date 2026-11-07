fields @timestamp, @message
| filter @message like /Running Start Crawl|has finished running/
| sort @timestamp asc