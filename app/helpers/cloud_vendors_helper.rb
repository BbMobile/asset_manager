module CloudVendorsHelper

  def setSidebar(assetsMenu,fieldsMenu,usersMenu,indexMenu,notificationMenu,groupMenu = nil,securityMenu = nil,mailMenu = nil,cloudMenu = nil)
    @assetsMenu = assetsMenu
    @fieldsMenu = fieldsMenu
    @usersMenu = usersMenu
    @indexMenu = indexMenu
    @notificationMenu = notificationMenu
    @groupMenu = groupMenu
    @securityMenu = securityMenu
    @mailMenu = mailMenu
    @cloudMenu = cloudMenu
  end

  def vendorAlert(vendorName,vendorAction)
    @vendorName = vendorName
    @vendorAction = vendorAction
  end

  def vendorErrorAlert(vendorErrorName,vendorErrorAction)
    @vendorErrorName = vendorErrorName
    @vendorErrorAction = vendorErrorAction
  end


  def add_rs_fields(fields,asset,section)
    cloudVendor = CloudVendor.find(asset.vendor_creds)
    cs = CloudServers::Connection.new(:username => cloudVendor.username, :api_key => cloudVendor.api_key)

    fields.each do |field|
      if field != ''
        case field
          when 'flavor'
            if Field.where(:name => 'RS Flavor').count == 0
              flavor = Field.create(:field_type_id => FieldType.first(:type_name => "Select Field").id ,:description => 'RS Flavor',:name => 'RS Flavor',:vendor_type => cloudVendor.cloud_vendor_type,:locked => true)
              cs.flavors.each do |flavor_rs|
                flavor.field_option.build(:option => flavor_rs[:name],:field_id => flavor.id,:vendor_key => flavor_rs[:id])
              end
              flavor.save
              section.asset_screen.build(:field_id => flavor.id.to_s ,:asset_id => asset.id,:required => true)
            end
          when 'operating_system'
            if Field.where(:name => 'RS Operating System').count == 0
              image = Field.create(:field_type_id => FieldType.first(:type_name => "Select Field").id ,:description => 'RS Operating System',:name => 'RS Operating System',:vendor_type => cloudVendor.cloud_vendor_type,:locked => true)
              cs.images.each do |image_rs|
                if !image_rs[:serverId].present? and !image_rs[:created].present?
                  image.field_option.build(:option => image_rs[:name],:field_id => image.id,:vendor_key => image_rs[:id])
                end
              end
              image.save
              section.asset_screen.build(:field_id => image.id.to_s ,:asset_id => asset.id,:required => true,:vendor_type => cloudVendor.cloud_vendor_type)
            end
          when 'public_ip'
            if Field.where(:name => 'RS Public IP').count == 0
              public = Field.create(:field_type_id => FieldType.first(:type_name => "IP Field").id ,:description => 'RS Public IP',:name => 'RS Public IP',:vendor_type => cloudVendor.cloud_vendor_type,:locked => true)
              section.asset_screen.build(:field_id => public.id.to_s ,:asset_id => asset.id,:required => false)
            end
          when 'private_ip'
            if Field.where(:name => 'RS Private IP').count == 0
              private = Field.create(:field_type_id => FieldType.first(:type_name => "IP Field").id ,:description => 'RS Private IP',:name => 'RS Private IP',:vendor_type => cloudVendor.cloud_vendor_type,:locked => true)
              section.asset_screen.build(:field_id => private.id.to_s ,:asset_id => asset.id,:required => false)
            end
        end
      end
    end

    section.save

  end

  def get_current_status(vendor_creds,server_id)

    cloud_vendor = CloudVendor.find(BSON::ObjectId.from_string(vendor_creds))
    cs = CloudServers::Connection.new(:username => cloud_vendor.username, :api_key => cloud_vendor.api_key)

    server = cs.server(server_id)

    server.refresh

    status = Hash.new
    status['text'] = server.status
    status['progress'] = server.progress

    return status
  end

  def create_server_vendor(asset)
    cloud_vendor = CloudVendor.find(AssetType.find(asset.asset_type_id).vendor_creds)
    cs = CloudServers::Connection.new(:username => cloud_vendor.username, :api_key => cloud_vendor.api_key)

    field = Field.first(:name => 'RS Flavor')
    flavor_asset = asset.field_value.detect { |c| c.field_id == field.id }
    flavor_option = field.field_option.detect {|c|c.option == flavor_asset.text_value}

    field = Field.first(:name => 'RS Operating System')
    operating_asset = asset.field_value.detect { |c| c.field_id == field.id }
    operating_option = field.field_option.detect {|c|c.option == operating_asset.text_value}

    new_server = cs.create_server(:name => asset.asset_name , :imageId => Integer(operating_option.vendor_key) ,:flavorId => Integer(flavor_option.vendor_key))

    update_rs_asset(asset,new_server)
  end

  def delete_server_vendor(asset)
    begin
    cloud_vendor = CloudVendor.find(AssetType.find(asset.asset_type_id).vendor_creds)
    cs = CloudServers::Connection.new(:username => cloud_vendor.username, :api_key => cloud_vendor.api_key)

    cs.server(asset.vendor_server_id).delete!
    rescue
    end


  end

  def resize_server_vendor(asset)
    cloud_vendor = CloudVendor.find(AssetType.find(asset.asset_type_id).vendor_creds)
    cs = CloudServers::Connection.new(:username => cloud_vendor.username, :api_key => cloud_vendor.api_key)

    field = Field.first(:name => 'RS Flavor')
    flavor_asset = asset.field_value.detect { |c| c.field_id == field.id }
    flavor_option = field.field_option.detect {|c|c.option == flavor_asset.text_value}

    server = cs.server(asset.vendor_server_id)
    server.resize!(Integer(flavor_option.vendor_key))

  end

  def update_rs_asset(asset,server)

    asset.asset_name = server.name
    asset.searchable_name =  server.name.gsub("-"," ")
    asset.vendor_server_id = server.id

    field = Field.first(:name => 'RS Flavor')
    asset.field_value.select { |b| b.field_id == field.id }.each { |b| b.locked = true }
    update_existing_asset_rs(field,server,asset)

    field = Field.first(:name => 'RS Operating System')
    asset.field_value.select { |b| b.field_id == field.id }.each { |b| b.locked = true }
    update_existing_asset_rs(field,server,asset)

    field = Field.first(:name => 'RS Public IP')
    if  (asset.field_value.detect {|c|c.field_id == field.id}) != nil

    else
      asset.field_value.build(:asset_id => asset.id,
                              :text_value => server.addresses[:public][0],
                              :field_name_value => {field.name.downcase.gsub(" ","_") => server.addresses[:public] } ,
                              :field_id => field.id,
                              :locked => true)
    end

    field = Field.first(:name => 'RS Private IP')
    if  (asset.field_value.detect {|c|c.field_id == field.id}) != nil

    else
      asset.field_value.build(:asset_id => asset.id,
                              :text_value => server.addresses[:private][0],
                              :field_name_value => {field.name.downcase.gsub(" ","_") => server.addresses[:private] } ,
                              :field_id => field.id,
                              :locked => true)
    end

    asset.save

  end
end
