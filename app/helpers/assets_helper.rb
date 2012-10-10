module AssetsHelper
  include EncryptDecryptPasswordHelper

  def setCascadeValue(params,fieldObj,asset)
    if params[fieldObj.name.gsub(" ","_")+"_child"][fieldObj.name.gsub(" ","_")+"_child"] != "null"
      asset.field_value.build(:asset_id => asset.id ,
                              :parent_field_option_id => params[fieldObj.name.gsub(" ","_")+"_parent"][fieldObj.name.gsub(" ","_")+"_parent"],
                              fieldObj.name.downcase.gsub(" ","_")+"_parent" => params[fieldObj.name.gsub(" ","_")+"_parent"][fieldObj.name.gsub(" ","_")+"_parent"],
                              fieldObj.name.downcase.gsub(" ","_")+"_child" => params[fieldObj.name.gsub(" ","_")+"_child"][fieldObj.name.gsub(" ","_")+"_child"],
                              :fieldNameValue => {"name" => fieldObj.name.downcase.gsub(" ","_"),"parent_value" =>params[fieldObj.name.gsub(" ","_")+"_parent"][fieldObj.name.gsub(" ","_")+"_parent"],"child_value" => params[fieldObj.name.gsub(" ","_")+"_child"][fieldObj.name.gsub(" ","_")+"_child"] } ,
                              :child_field_option_id => params[fieldObj.name.gsub(" ","_")+"_child"][fieldObj.name.gsub(" ","_")+"_child"],
                              :field_id => fieldObj.id)
    else
      asset.field_value.build(:asset_id => asset.id ,
                              :parent_field_option_id => params[fieldObj.name.gsub(" ","_")+"_parent"][fieldObj.name.gsub(" ","_")+"_parent"],
                              fieldObj.name.downcase.gsub(" ","_")+"_parent" => params[fieldObj.name.gsub(" ","_")+"_parent"][fieldObj.name.gsub(" ","_")+"_parent"],
                              :fieldNameValue => {"name" => fieldObj.name.downcase.gsub(" ","_"),"parent_value" =>params[fieldObj.name.gsub(" ","_")+"_parent"][fieldObj.name.gsub(" ","_")+"_parent"]},
                              :child_field_option_id => 'empty',
                              :field_id => fieldObj.id)
    end
  end

  def updateCascadeValue(params,fieldObj,asset)
    asset.field_value.select { |b| b.field_id == fieldObj.id }.each { |b| b.parent_field_option_id = params[fieldObj.name.gsub(" ","_")+"_parent"][fieldObj.name.gsub(" ","_")+"_parent"] }
    if params[fieldObj.name.gsub(" ","_")+"_child"][fieldObj.name.gsub(" ","_")+"_child"] != "null"
      asset.field_value.select { |b| b.field_id == fieldObj.id }.each { |b| b.child_field_option_id = params[fieldObj.name.gsub(" ","_")+"_child"][fieldObj.name.gsub(" ","_")+"_child"] }
      asset.field_value.select { |b| b.field_id == fieldObj.id }.each { |b| b.field_name_value = {fieldObj.name.downcase.gsub(" ","_")+"_parent_value" =>params[fieldObj.name.gsub(" ","_")+"_parent"][fieldObj.name.gsub(" ","_")+"_parent"],fieldObj.name.downcase.gsub(" ","_")+"_child_value" => params[fieldObj.name.gsub(" ","_")+"_child"][fieldObj.name.gsub(" ","_")+"_child"] } }
    else
      asset.field_value.select { |b| b.field_id == fieldObj.id }.each { |b| b.field_name_value = { fieldObj.name.downcase.gsub(" ","_")+"_parent_value" =>params[fieldObj.name.gsub(" ","_")+"_parent"][fieldObj.name.gsub(" ","_")+"_parent"] } }
    end

  end

  def setFieldValue(params,fieldObj,asset)
    case params[fieldObj.name][fieldObj.name+'_type']
      when 'single_option'
        asset.field_value.build(:asset_id => asset.id ,
                                :field_option_id => params[fieldObj.name][fieldObj.name],
                                :field_id => fieldObj.id,
                                :field_name_value => {fieldObj.name.downcase.gsub(" ","_") =>params[fieldObj.name][fieldObj.name] } ,
                                :text_value => fieldObj.field_option.find(BSON::ObjectId.from_string(params[fieldObj.name][fieldObj.name])).option)
      when 'multi_option'
        options = Array.new
        options.push(params[fieldObj.name][fieldObj.name])
        asset.field_value.build(:asset_id => asset.id ,
                                :field_option_id => options,
                                :field_name_value => {fieldObj.name.downcase.gsub(" ","_") =>options } ,
                                :field_id => fieldObj.id)
      when 'text','ip'
        asset.field_value.build(:asset_id => asset.id,
                                :text_value => params[fieldObj.name][fieldObj.name],
                                :field_name_value => {fieldObj.name.downcase.gsub(" ","_") =>params[fieldObj.name][fieldObj.name] } ,
                                :field_id => fieldObj.id)
      when 'date'
        asset.field_value.build(:asset_id => asset.id,
                                :date => params[fieldObj.name][fieldObj.name],
                                :field_name_value => {fieldObj.name.downcase.gsub(" ","_") =>params[fieldObj.name][fieldObj.name] } ,
                                :field_id => fieldObj.id)
      when 'file_upload'
        asset.field_value.build(:asset_id => asset.id,
                                :photo => params[fieldObj.name][fieldObj.name],
                                :field_id => fieldObj.id)
      when 'password'
        asset.field_value.build(:asset_id => asset.id,
                                :password_value => encryptPassword(params[fieldObj.name][fieldObj.name]),
                                :field_name_value => {fieldObj.name.downcase.gsub(" ","_") =>encryptPassword(params[fieldObj.name][fieldObj.name]) } ,
                                :field_id => fieldObj.id)
      else
        puts "field not found"
    end
  end

  def updateFieldValue(params,fieldObj,fieldValue,asset)
    case params[fieldObj.name][fieldObj.name+'_type']
      when 'single_option'
        asset.field_value.select { |b| b.field_id == fieldObj.id }.each { |b|  b.field_option_id = fieldObj.field_option.find(BSON::ObjectId.from_string(params[fieldObj.name][fieldObj.name]  )).id}
        asset.field_value.select {|b| b.field_id == fieldObj.id}.each {|b| b.text_value = fieldObj.field_option.find(BSON::ObjectId.from_string(params[fieldObj.name][fieldObj.name]  )).option}
        asset.field_value.select { |b| b.field_id == fieldObj.id }.each { |b| b.field_name_value = {fieldObj.name.downcase.gsub(" ","_") => params[fieldObj.name][fieldObj.name] } }
      when 'multi_option'
        options = Array.new
        options.push(params[fieldObj.name][fieldObj.name])
        asset.field_value.select { |b| b.field_id == fieldObj.id }.each { |b| b.field_option_id = options}
        asset.field_value.select { |b| b.field_id == fieldObj.id }.each { |b| b.field_name_value = {fieldObj.name.downcase.gsub(" ","_")=> options} }
      when 'text','ip'
        if params[fieldObj.name][fieldObj.name] != ''
          asset.field_value.select { |b| b.field_id == fieldObj.id }.each { |b| b.text_value = params[fieldObj.name][fieldObj.name] }
          asset.field_value.select { |b| b.field_id == fieldObj.id }.each { |b| b.field_name_value = {fieldObj.name.downcase.gsub(" ","_") => params[fieldObj.name][fieldObj.name] } }
        elsif fieldValue != nil
          Asset.pull(asset.id, {:field_option => {:_id => fieldObj.id}})
        end
      when 'date'
        asset.field_value.select { |b| b.field_id == fieldObj.id }.each { |b| b.date = params[fieldObj.name][fieldObj.name] }
        asset.field_value.select { |b| b.field_id == fieldObj.id }.each { |b| b.field_name_value = {fieldObj.name.downcase.gsub(" ","_")=> params[fieldObj.name][fieldObj.name] } }
      when 'file_upload'
        asset.field_value.select { |b| b.field_id == fieldObj.id }.each { |b| b.photo = params[fieldObj.name][fieldObj.name] }
      when 'password'
        asset.field_value.select { |b| b.field_id == fieldObj.id }.each { |b| b.field_name_value = {fieldObj.name.downcase.gsub(" ","_")=> encryptPassword(params[fieldObj.name][fieldObj.name])} }
        asset.field_value.select { |b| b.field_id == fieldObj.id }.each { |b| b.password_value = encryptPassword(params[fieldObj.name][fieldObj.name])}
      else
        puts "field not found"
    end
  end


  def deleteFields(fieldsToDelete,asset)
    fieldsToDelete.each do |field|
      Asset.pull(asset.id, {:field_value => {:field_id => field}})
    end
  end

  def assetAlert(assetName,assetAction)
    @assetName = assetName
    @assetAction = assetAction
  end

  def getLatestChangeHistoryForAsset()

    changeHistoryAsset = Hash.new

    counter = 0

    ChangeHistory.sort(:changed_at.desc).each do |changeHistoryItem|
      unless changeHistoryAsset.has_key? changeHistoryItem.asset_id
        changeHistoryAsset[changeHistoryItem.asset_id] = changeHistoryItem.id
        counter += 1
      end
      if counter > 10
        break
      end
    end

    return changeHistoryAsset

  end

  def sendNotificationEmailsViaScheme(asset,action)
    notification = NotificationScheme.first(:asset_type_id => BSON::ObjectId.from_string(asset.asset_type_id))

    addresses = Array.new

    if notification
      case action
        when 'create'
          notification.create_email['users'][0].each do |user|
            if user != ''
              addresses.push(User.find(BSON::ObjectId.from_string(user)).email)
            end
          end
          addresses.each do |address|
            AssetMailer.create(asset,address).deliver
          end
        when 'edit'
          notification.edit_email['users'][0].each do |user|
            if user != ''
              addresses.push(User.find(BSON::ObjectId.from_string(user)).email)
            end
          end
          addresses.each do |address|
            AssetMailer.edit(asset,address).deliver
          end
        when 'delete'
          notification.delete_email['users'][0].each do |user|
            if user != ''
              addresses.push(User.find(BSON::ObjectId.from_string(user)).email)
            end
          end
          addresses.each do |address|
            AssetMailer.delete(asset,address).deliver
          end
      end
    end


  end

  def create_update_vendor_assets(params)
    cloud_vendor = CloudVendor.find(params[:vendor_creds])

    if CloudVendorType.find(cloud_vendor.cloud_vendor_type).vendor_name == "Rackspace Cloud"
      begin
        cs = CloudServers::Connection.new(:username => cloud_vendor.username, :api_key => cloud_vendor.api_key)
        cs.servers.each do |server|
          if Asset.where(:vendor_server_id => server[:id]).count == 0
            asset = Asset.create(:asset_name => server[:name],:searchable_name => (server[:name]).gsub("-"," "),:asset_type_id =>params[:asset_type_id],:vendor_server_id => server[:id],:created_by => current_user.id ,:created_at => DateTime.now )
            serverDetails = cs.server(server[:id])

            Field.where(:vendor_type => cloud_vendor.cloud_vendor_type).each do |field|

              case field.name
                when 'RS Public IP'
                  asset.field_value.build(:asset_id => asset.id,
                                          :text_value => serverDetails.addresses[:public][0],
                                          :field_name_value => {field.name.downcase.gsub(" ","_") => serverDetails.addresses[:public] } ,
                                          :field_id => field.id,
                                          :locked => true)
                when 'RS Private IP'
                  asset.field_value.build(:asset_id => asset.id,
                                          :text_value => serverDetails.addresses[:private][0],
                                          :field_name_value => {field.name.downcase.gsub(" ","_") => serverDetails.addresses[:private] } ,
                                          :field_id => field.id,
                                          :locked => true)
                when 'RS Flavor'
                  option = field.field_option.detect {|c|c.option == serverDetails.flavor.name}
                  asset.field_value.build(:asset_id => asset.id,
                                          :field_option_id => option.id.to_s,
                                          :field_id => field.id,
                                          :field_name_value => {field.name.downcase.gsub(" ","_") =>option.id} ,
                                          :text_value => option.option,
                                          :locked => false)
                when 'RS Operating System'
                  option = field.field_option.detect {|c|c.option == serverDetails.image.name}
                  if option == nil
                    create_field_option(field,serverDetails.image.name)
                    option = field.field_option.detect {|c|c.option == serverDetails.image.name}
                  end
                  asset.field_value.build(:asset_id => asset.id,
                                          :field_option_id => option.id.to_s,
                                          :field_id => field.id,
                                          :field_name_value => {field.name.downcase.gsub(" ","_") =>option.id} ,
                                          :text_value =>option.option,
                                          :locked => true)
              end
            end
            asset.save
          else
            asset = Asset.first(:vendor_server_id => server[:id])
            asset.asset_name = server[:name]
            asset.searchable_name = (server[:name]).gsub("-"," ")

            serverDetails = cs.server(server[:id])

            Field.where(:vendor_type => cloud_vendor.cloud_vendor_type).each do |field|
              update_existing_asset_rs(field,serverDetails,asset)
            end

            asset.save
          end
        end

      rescue Exception => e
        puts e.message
        puts e.backtrace.inspect
      end

    end
  end

  def sync_assets(params)
    cloud_vendor = CloudVendor.find(params[:vendor_creds])

    if CloudVendorType.find(cloud_vendor.cloud_vendor_type).vendor_name == "Rackspace Cloud"
      begin
        cs = CloudServers::Connection.new(:username => cloud_vendor.username, :api_key => cloud_vendor.api_key)
        assets_to_delete = Array.new

        Asset.where(:asset_type_id =>params[:asset_type_id]).each do |asset|
          begin cs.server(asset.vendor_server_id)
          assets_to_delete.push(asset.id)
          rescue
          end
        end

        assets_to_delete.each do |asset|
          Asset.destroy(asset)
        end

      rescue
      end

    end

  end

  def update_existing_asset_rs(field,serverDetails,asset)
    case field.name
      when 'RS Public IP'
        asset.field_value.select { |b| b.field_id == field.id }.each { |b| b.text_value = serverDetails.addresses[:public][0] }
        asset.field_value.select { |b| b.field_id == field.id }.each { |b| b.field_name_value = {field.name.downcase.gsub(" ","_") => serverDetails.addresses[:public][0] } }
      when 'RS Private IP'
        asset.field_value.select { |b| b.field_id == field.id }.each { |b| b.text_value = serverDetails.addresses[:private][0] }
        asset.field_value.select { |b| b.field_id == field.id }.each { |b| b.field_name_value = {field.name.downcase.gsub(" ","_") => serverDetails.addresses[:private][0] } }
      when 'RS Flavor'
        option = field.field_option.detect {|c|c.option == serverDetails.flavor.name}
        asset.field_value.select { |b| b.field_id == field.id }.each { |b|  b.field_option_id = option.id.to_s}
        asset.field_value.select {|b| b.field_id == field.id}.each {|b| b.text_value = option.option}
        asset.field_value.select { |b| b.field_id == field.id }.each { |b| b.field_name_value = {field.name.downcase.gsub(" ","_") => option.id.to_s } }
      when 'RS Operating System'
        option = field.field_option.detect {|c|c.option == serverDetails.image.name}
        if option == nil
          create_field_option(field,serverDetails.image.name)
          option = field.field_option.detect {|c|c.option == serverDetails.image.name}
        end
        asset.field_value.select { |b| b.field_id == field.id }.each { |b|  b.field_option_id = option.id.to_s}
        asset.field_value.select {|b| b.field_id == field.id}.each {|b| b.text_value = option.option}
        asset.field_value.select { |b| b.field_id == field.id }.each { |b| b.field_name_value = {field.name.downcase.gsub(" ","_") => option.id.to_s } }
    end
  end

  def delete_asset(asset)
    Asset.destroy(asset.id)

    ChangeHistory.pull_all(:asset_id => asset.id)

    assetAlert(asset.name,"Deleted")

    sendNotificationEmailsViaScheme(asset,'delete')
  end

end
