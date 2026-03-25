# Optional variables:
# cluster_name = "csdac-dev-cluster"
cluster_name = "<%= expansion('csdac-:ENV-cluster') %>"
region = "<%= expansion(':REGION') %>"
