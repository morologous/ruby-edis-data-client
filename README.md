# edis_client

The EDIS Data Webservice is a service provided by the United States International Trade Commission. For more information on either the USITC or EDIS please visit their respective websites ([www.usitc.gov](http://www.usitc.gov) or [edis.usitc.gov](http://edis.usitc.gov))

Documentation on the EDIS data webserivce can be found here

## Testing
Before running the tests via Rake you will need to add ./test/config.rb with a hash with the following keys

```ruby
CREDS = { username => 'sean', password => 'password' }
```

## Contributing to edis_client
 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Copyright

Copyright (c) 2011 The United States International Trade Commission. See LICENSE for
further details.

