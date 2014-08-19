require "github_api"
require "pry"
require "json"

client_id = "09a10f45eeaf60ef70ad"
client_secret = "433aa2aed31b8931d894dd8e55aa4fbd25781157"

data = JSON.dump(
  :scopes => ["public_repo"],
  :note => "Foo",
  :client_id => client_id,
  :client_secret => client_secret
)

puts `curl -s 'https://api.github.com/authorizations' -d '#{data}'`
