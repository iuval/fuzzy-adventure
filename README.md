fuzzy-adventure
===============







Mongo 

begin
  # your operation
rescue Mongo::OperationFailure => e
  if e.message =~ /^11000/
    puts "Duplicate key error #{$!}"
    # do something to recover from duplicate
  else
    raise e
  end
end
# the rest of the exceptions follow ..
# if you just care about the dup error
# then ignore them
#rescue Mongo::MongoRubyError
#  #Mongo::ConnectionError, Mongo::ConnectionTimeoutError, Mongo::GridError, Mongo::InvalidSortValueError, Mongo::MongoArgumentError, Mongo::NodeWithTagsNotFound
#  puts "Ruby Error :  #{$!}"
#rescue Mongo::MongoDBError
#  # Mongo::AuthenticationError, Mongo::ConnectionFailure, Mongo::InvalidOperation, Mongo::OperationFailure
#  puts "DB Error :  #{$!}"
#rescue Mongo::OperationTimeout
#  puts "Socket operation timeout Error :  #{$!}"
#rescue Mongo::InvalidNSName
#  puts "invalid collection or database Error :  #{$!}"
#end
