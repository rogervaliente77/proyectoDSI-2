module Admin
  class DocumentsController < ApplicationController
    #before_action :check_admin_access
    #before_action :set_current_user
    layout 'dashboard'
    
    def index
      @documents = Document.all
    end

    def new
      #@conference = Conference.new
      @document = Document.new
    end

    def show
       @document = Document.find(params[:document_id]) || nil
    end

    def edit
      @document = Document.find(params[:document_id]) || nil
      @users_json = User.all.select(:id, :email).to_json.html_safe
    end

    def create
      @document = Document.new

      if params.dig(:document, :image).present?
        uploaded_file = params[:document][:image]
        cloudinary_response = Cloudinary::Uploader.upload(uploaded_file.path)

        #saving the document
        @document.url = cloudinary_response['secure_url']

        file_name = uploaded_file.original_filename
        basename = File.basename(file_name, File.extname(file_name))

        @document.doc_type = uploaded_file.content_type
        @document.title = basename
        @document.uploaded_by_id = current_user.id
        @document.uploaded_by_email = current_user.email
        @document.filename = file_name

        if @document.save
          flash[:notice] = "Documento subido con exito"
          redirect_to admin_documentos_path
        else
          flash[:alert] = "Hubo un error al subir el documento"
          redirect_to admin_documentos_path
        end
      else
        flash[:alert] = "Por favor, selecciona un archivo para subir."
        redirect_to admin_documentos_path
      end
    end

    def update
      @document = Document.find(params[:document_id]) || nil

      if @document
        
      else
      
      end
    end

    private

    def check_admin_access
      admin_email = ENV['USER_ADMIN']

      unless current_user && current_user.email == admin_email
        redirect_to portal_home_path, alert: "No tienes acceso a esta sección."
      end
    end

    def set_current_user
      @current_user = current_user
    end

    def conference_params
      params.require(:conference).permit(:title, :speaker_name, :description, :start_date, :end_date, :max_limit_of_attendees, :image_url)
    end
  end
end