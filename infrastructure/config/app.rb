Terraspace.configure do |config|
  config.logger.level = :info
  config.test_framework = "rspec"
  #config.allow.envs = ["ci", "dev", "qa", "stage", "prod", "prodeu", "prodapj", "dbudko"]
end
