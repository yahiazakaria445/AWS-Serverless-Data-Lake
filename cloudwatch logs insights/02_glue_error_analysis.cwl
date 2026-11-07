fields @timestamp, @log, @message
| filter @message like /ERROR|Exception|AccessDenied|FAILED/
| sort @timestamp desc
| limit 50