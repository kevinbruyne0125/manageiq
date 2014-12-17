FastGettext.add_text_domain('manageiq',
                            :path           => Rails.root.join("config/locales"),
                            :type           => :po,
                            :report_warning => false)
FastGettext.default_available_locales = %w(en hu it nl sk)
FastGettext.default_text_domain = 'manageiq'
