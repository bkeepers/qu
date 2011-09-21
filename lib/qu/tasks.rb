namespace :qu do

  describe "Start a worker"
  task :work  => :environment do
    queues = (ENV['QUEUES'] || ENV['QUEUE'] || 'default').to_s.split(',')

    Qu::Worker.new(*queues).start
  end

end
