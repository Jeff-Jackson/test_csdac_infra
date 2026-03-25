# Optional variables:
# cluster_name = "cylon-dev-cluster"
cluster_name = "<%= expansion('cylon-:ENV-cluster') %>"
region = "<%= expansion(':REGION') %>"
env = "<%= expansion(':ENV') %>"
