namespace :qu do

  task :start  => :environment do
    queues = (ENV['QUEUES'] || ENV['QUEUE']).to_s.split(',')

    Qu::Worker.new(*queues).start
  end

end
