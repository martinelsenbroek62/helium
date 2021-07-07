Rails.application.routes.draw do
  get 'settings' => 'organizations#edit', as: :settings

  match '/tableau/org/:organization_id/upload' => 'tableau#handle_upload', via: [:post, :put]
  get '/tableau/current_org/:image' => 'tableau#current_org_image'
  get '/tableau/any_org/:image' => 'tableau#any_org_image'

  resource :admin do
    resources :organizations, controller: 'admin/organizations' do
      post :change_to, to: 'admin/organizations#change_to', as: :change_to, on: :member
    end

    match '/user_merge' => 'admin/organizations#user_merge', via: [:get, :post]

    root 'admin/organizations#index', as: :admin_root
  end

  get '/org/:organization_uuid/srv/:survey_uuid' => 'splashes#show', as: :anonymous_survey
  get '/org/:organization_uuid/srv/:survey_uuid/create_anonymous_survey' => 'splashes#create_anonymous_survey', as: :create_anonymous_survey

  resources :claim_attachments

  resources :organizations do
    get :self_signup, on: :member, to: 'organizations#self_signup'
    get :profile, on: :member, to: 'users#profile'
    get :setup, on: :member, to: 'organizations#setup'
    get :manage_org_admins, on: :member, to: 'organizations#manage_org_admins'

    match '/editor/(:field)' => 'organizations#editor', via: [:get, :post], as: :editor

    resources :notes, controller: 'organizations/notes', only: [:index]
    resources :offers, controller: 'organizations/offers'

    resources :claims, controller: 'organizations/claims' do
      match :import, via: [:get, :post], on: :collection
      post :reimburse, on: :member
      get :proof, on: :member
      post :bulk, on: :collection
      get :historical, on: :collection

      match :export, on: :collection, via: [:get, :post]
      match :export_agg, on: :collection, via: [:get, :post]

      resources :notes, controller: 'organizations/notes'
    end
    resources :people, controller: 'organizations/people', path: "employees" do
      match :deposit, via: [:get, :post], on: :collection
      match :upload, via: [:get, :post], on: :collection
      match :import, via: [:get, :post], on: :collection
      match :invitations, on: :collection, via: [:get, :post]
      post :reset_password, on: :member
      post :send_invite, on: :member
    end
    resources :funds, controller: 'organizations/funds'
    resources :products, controller: 'organizations/products', path: 'specific_products' do
      match :upload, to: 'organizations/products#upload', on: :collection, via: [:get, :post]
    end

    resources :reimbursement_rules, controller: 'organizations/reimbursement_rules', path: 'benefits_database' do
      post :import, on: :collection
    end

    resources :pages, controller: 'organizations/pages'

    resources :benefit_categories, only: [:edit, :show, :update, :destroy], controller: 'organizations/benefit_categories'
    resources :benefit_programs, controller: 'organizations/benefit_programs' do
      member do
        get :program_funds
        get :program_claims
      end

      resources :benefit_categories, controller: 'organizations/benefit_categories' do
        collection do
          post :upload
        end
      end
    end

    resources :surveys, controller:'organizations/surveys' do
      get :overview, on: :member
      get :preview, on: :member
      get :search_questions, on: :member
      get :help, on: :member
      post :upload, on: :member
      post :import, on: :member
      post :import_report_questions, on: :member
      post :reset, on: :member
      post :deploy_changes, on: :member
      get :clone, on: :member
      post :clone, on: :member
      get :move_to, on: :member
      post :move_to, on: :member
      post :push_changes_to, on: :member
      match 'report' => 'organizations/surveys#report', as: :report, via: [:get, :post, :put], on: :member

      get :remove, on: :member

      match 'templates' => 'organizations/surveys#templates', via:[:get,:post]
      post :restore_template, on: :member

      resources :messages, controller: 'organizations/messages' do
        post :deliver, on: :member
      end

      resources :sections,controller:'organizations/sections' do
        resources :groups,controller:'organizations/groups' do
          resources :questions,controller:'organizations/questions'
        end
      end

      resources :rules, controller: 'organizations/rules'
      resources :questions, controller: 'organizations/questions'
      resources :users, controller: 'organizations/users' do
        post :import, on: :collection
        post :import_historical_records, on: :collection
        post :attach_meta_data, on: :collection
        post :invite, on: :collection
        post :reset, on: :collection
        post :download_data, on: :collection
        post :download_results, on: :collection
        post :make_admin, on: :member
        post :rerun_calculations, on: :collection
        post :toggle_survey_is_valid, on: :member
        post :allowed_to_submit_answers, on: :member
        post :add_from_organization, on: :collection
        post :toggle_open_and_closed_surveys, on: :collection, via: [:post]
        post :share_spreadsheet, on: :collection
        get :compare, on: :collection

        post :run_results, on: :member
        post :reinvite, on: :member
      end
    end
  end

  get 'footprint' => 'surveys#footprint', as: :footprint
  get 'no_footprint_yet' => 'surveys#no_footprint', as: :no_footprint
  resources :surveys do
    get :report
    get :data
    get :faq
    get :complete
    get :start
    get :profile, on: :member, to: 'users#profile'

    resources :sections, controller:'surveys/sections' do
      get :start, to: 'surveys/sections#start'
      get :complete
      get :info

      resources :groups, controller: 'surveys/groups' do
        get :next, on: :member
        get :prev, on: :member
        resources :questions, controller: 'surveys/questions'
      end
    end

    resources :questions, controller: 'surveys/questions' do
      post :answer, on: :member
    end

    get 'report/results' => 'surveys/results#index'
    get 'report/histogram' => 'surveys/results#histogram'

    get 'finish' => 'surveys#finish'
  end

  resources :benefit_categories, path: 'explore', only: [:index]
  resources :benefit_categories
  resources :programs, path: 'programs' do
    match :submit_claim, on: :collection, via: [:get, :post]
  end

  resources :products, path: 'benefits' do
    get 'about', on: :collection
    get 'focus_area', on: :collection
    get 'category', on: :collection
    match 'saved', on: :collection, path: 'wishlist', via: [:get, :post]

    resources :claims, only: [:new]
  end

  resources :claims do
    member do
      match 'change_benefit_category' => 'claims#change_benefit_category', via: [:get, :post]
    end
  end

  get '/pages/:id' => 'pages#show', as: :page
  get '/offers' => 'pages#offers', as: :offers

  match 'profile' => 'users#profile', via: [:get, :post]
  match 'login' => 'users#login',via:[:get,:post], as: :login
  match 'logout' => 'users#logout', via: [:get, :post, :delete]
  match 'password' => 'users#password', via:[:get,:post]
  match 'reset_password/:user_uuid' => 'users#reset_password', via:[:get], as: :reset_password

  match 'profile' => 'users#update', via: :put
  match 'invite/:user_uuid' => 'users#login_with_token', via: [:get], as: :login_with_token
  match 'relogin' => 'users#relogin_super_admin', via: [:get], as: :relogin_super_admin
  match ':organization_name/invites/:employee_invite_uuid' => 'organizations#employee_invitation', via: [:get, :post], as: :employee_invitation

  match 'create-new-org' => 'users#register', via: [:get, :post], as: :register

  match "/delayed_job" => DelayedJobWeb, :anchor => false, via: [:get, :post]


  get '/saml/:idp/sso' => 'saml#sso'
  match '/saml/:idp/acs' => 'saml#acs', via: [:get, :post]
  get '/saml/:idp/metadata' => 'saml#metadata'
  get '/saml/:idp/logout' => 'saml#logout'

  match '/:signup_slug' => 'signup_slug#show', via: [:get, :post], as: :signup_slug
  match '/:signup_slug/continue_signup' => 'signup_slug#continue_signup', via: [:get, :post], as: :continue_signup


  root 'organizations#dashboard'
end
