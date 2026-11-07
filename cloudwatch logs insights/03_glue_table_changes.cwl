fields @timestamp, @message
| filter @message like /Created table|Created partitions|Run Summary|ADD:|UPDATE:|DELETE:/
| sort @timestamp asc