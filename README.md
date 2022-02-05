# systemd_metrics
Script to extract systemd metrics for InfluxDB. Was written as telegraf plugin `[[inputs.systemd_units]]` was not working on certain versions of Linux distributions.

# Usage
Ensure that you have filled config.conf with your patterns. Script format is `gather.sh [type]`:
```
gather.sh timer
gather.sh service
```
