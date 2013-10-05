desc "Run application using shotgun"
task :start do
  system "shotgun --server=thin --host=0.0.0.0 --port=9292 config.ru"
end

desc "Loads irb console with environment loaded"
task :console do
  system "bundle exec irb -r./app/init"
end

