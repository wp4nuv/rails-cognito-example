require 'cognito_urls'

if !ENV['AWS_COGNITO_DOMAIN'].blank?
  CognitoUrls.init(ENV['AWS_COGNITO_DOMAIN'],
                   ENV['AWS_COGNITO_REGION'])
else
  puts "Skipping Cognito initialization"
end
