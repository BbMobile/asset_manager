class AssetsController < ApplicationController
  include AssetsHelper
  include AdminFieldHelper
  include SearchHelper
  include EncryptDecryptPasswordHelper

  respond_to :html, :xml, :json

  def index
    @assets = Asset.all

    respond_with(@assets) do |format|
      format.html
      format.json { render :json => @assets }
    end
  end

  def overview

    @asset_types = AssetType.all

    render :template => 'assets/overview/overview', :layout => 'assets_overview'
  end

  def get_assets_from_asset_type
    @asset_types = AssetType.all
    @assets = search_asset_type_assets( params[:asset_type_id])

    @asset_type_id = params[:asset_type_id]

    @overview_columns = OverviewColumn.first(:user_id => current_user.id)

    render :template => 'assets/overview/overview', :layout => 'assets_overview'
  end

  def update_overview_columns
    overview_column = OverviewColumn.first_or_create(:user_id => current_user.id)

    overview_column.overview_columns = params[:custom_columns][:custom_columns]

    if overview_column.save

      @asset_types = AssetType.all

      @asset_type_id = params[:asset_type][:asset_type_id]
      @assets = search_asset_type_assets( params[:asset_type][:asset_type_id])

      @overview_columns = OverviewColumn.first(:user_id => current_user.id)

      render :template => 'assets/overview/overview', :layout => 'assets_overview'
    end
  end

  def paginate

    @asset_types = AssetType.all

    search_asset_type_assets(params[:asset_type_id],Integer(params[:page]))

    @asset_type_id = params[:asset_type_id]

    @overview_columns = OverviewColumn.first(:user_id => current_user.id)

    render :template => 'assets/overview/overview', :layout => 'assets_overview'
  end

  def create
    @asset_type = AssetType.find(BSON::ObjectId.from_string(params[:id]))
  end

  def save

    @asset = Asset.new(:asset_name => params[:name][:name],:searchable_name =>(params[:name][:name]).gsub("-"," "),:description => params[:description][:description])

    asset_type = AssetType.find(BSON::ObjectId.from_string(params[:asset_type][:asset_type_id]))

    @asset.asset_type_id = asset_type.id
    @asset.asset_type_name = asset_type.name

    asset_type.asset_screen_section.each do |section|
      section.asset_screen.each do |field|
        fieldObj = Field.find(field.field_id)
        if params[fieldObj.name][fieldObj.name] != nil and params[fieldObj.name][fieldObj.name] != ''
          setFieldValue(params,fieldObj,@asset)
        elsif params[fieldObj.name.gsub(" ","_")+"_parent"] != nil and params[fieldObj.name.gsub(" ","_")+"_parent"][fieldObj.name.gsub(" ","_")+"_parent"] != nil
          setCascadeValue(params,fieldObj,@asset)
        end
      end
    end

    @asset.created_at = DateTime.now

    @asset.created_by = current_user.id

    @asset.save

    assetAlert(@asset.name,"Created")

    sendNotificationEmailsViaScheme(@asset,'create')

    render :template => 'assets/view'

  end

  def delete
    asset = Asset.find(params[:asset_id])

    delete_asset(asset)

    @assets = Asset.all

    render :template => 'assets/index'
  end

  def edit
    @asset = Asset.find(params[:id])

  end

  def update

    @asset = Asset.find(params[:asset][:asset_id])

    changeHistory = ChangeHistory.new(:asset_id => @asset.id,:asset_type_id => @asset.asset_type_id,:changed_by => current_user.id)

    if @asset.asset_name != params[:name][:name]
      changeHistory.change_history_detail.build(:string_previous_value => @asset.asset_name,:string_new_value => params[:name][:name])
    end
    @asset.asset_name = params[:name][:name]
    @asset.searchable_name = (params[:name][:name]).gsub("-"," ")

    if params[:description][:description] != nil
      @asset.description = params[:description][:description]
    else
      @asset.description = nil
    end

    if @asset.description != params[:description][:description]
      changeHistory.change_history_detail.build(:string_previous_value => @asset.description,:string_new_value => params[:description][:description])
    end

    fieldsToDelete = Array.new
    AssetType.find(@asset.asset_type_id).asset_screen_section.each do |section|
      section.asset_screen.each do |field|
        fieldObj = Field.find(field.field_id)
        createField = true
        if params[fieldObj.name][fieldObj.name] != nil and params[fieldObj.name][fieldObj.name]  != ''
          @asset.field_value.each do |fieldValue|
            if fieldObj.id == fieldValue.field_id
              createField = false
              updateFieldValue(params,fieldObj,fieldValue,@asset)
            end
          end
          if createField
            setFieldValue(params,fieldObj,@asset)
          end
        elsif params[fieldObj.name.gsub(" ","_")+"_parent"] != nil and params[fieldObj.name.gsub(" ","_")+"_parent"][fieldObj.name.gsub(" ","_")+"_parent"] != ""
          updateCascadeValue(params,fieldObj,@asset)
        elsif params[fieldObj.name.gsub(" ","_")+"_parent"] != nil and params[fieldObj.name.gsub(" ","_")+"_parent"][fieldObj.name.gsub(" ","_")+"_parent"] == "" and  @asset.field_value.detect {|c|c.field_id == fieldObj.id} != nil
          fieldsToDelete.push(fieldObj.id)
        elsif params[fieldObj.name][fieldObj.name]  == '' and  @asset.field_value.detect {|c|c.field_id == fieldObj.id} != nil
          fieldsToDelete.push(fieldObj.id)
        end
      end
    end

    changeHistory.changed_at = DateTime.now
    changeHistory.save

    @asset.save

    sendNotificationEmailsViaScheme(@asset,'edit')

    deleteFields(fieldsToDelete,@asset)

    assetAlert(@asset.name,"Updated")

    render :template => 'assets/view'
  end

  def view
    @asset = Asset.find(params[:id])
    respond_with(@asset) do |format|
      format.html
      format.json { render :json => @asset }
    end
  end

  def getChildOptions()

    field = Field.find(BSON::ObjectId.from_string(params['field_id']))

    @childOptions = Array.new
    field.field_option.each do |field_option|
      if field_option.parent_field_option == BSON::ObjectId.from_string(params['data'])
        @childOptions.push(field_option)
      end
    end

    respond_to do |format|
      format.json { render :json => @childOptions }
    end

  end

  def api_decryptPassword
    @password = decryptPassword(params['data'])
    respond_to do |format|
      format.json { render :json => @password }
    end

  end

  def pull_all_vendor_assets

    # Create or update vendor assets for third party vendors
    create_update_vendor_assets(params)

    sync_assets(params)

    redirect_to :controller => 'admin_field', :action => 'list_asset_types'
  end

end
