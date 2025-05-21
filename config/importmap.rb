# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "bootstrap", to: "bootstrap.min.js", preload: true
# pin "bootstrap", to: "vendor/javascript/bootstrap.bundle.min.js"
pin "jquery", to: "https://code.jquery.com/jquery-3.6.0.min.js", preload: true
pin "sb_admin_2", to: "sb_admin_2/sb-admin-2.js", preload: true
pin_all_from "sb_admin_2/demo", under: "sb_admin_2/demo"
pin "jquery-easing", to: "jquery-easing/jquery.easing.min.js", preload: true