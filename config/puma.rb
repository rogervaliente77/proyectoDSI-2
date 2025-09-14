
# config/puma.rb

max_threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
min_threads_count = ENV.fetch("RAILS_MIN_THREADS") { max_threads_count }
threads min_threads_count, max_threads_count

port        ENV.fetch("PORT") { 3000 }
environment ENV.fetch("RAILS_ENV") { "development" }

# 👇 Ajuste según el environment
if Rails.env.production?
  workers ENV.fetch("WEB_CONCURRENCY") { 1 } # cluster en producción
else
  workers 0  # single mode en dev/test
end

preload_app!
plugin :tmp_restart
