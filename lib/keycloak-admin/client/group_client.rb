module KeycloakAdmin
  class GroupClient < Client
    def initialize(configuration, realm_client)
      super(configuration)
      raise ArgumentError.new("realm must be defined") unless realm_client.name_defined?
      @realm_client = realm_client
    end

    def list
      response = execute_http do
        RestClient::Resource.new(groups_url, @configuration.rest_client_options).get(headers)
      end
      JSON.parse(response).map { |group_as_hash| GroupRepresentation.from_hash(group_as_hash) }
    end

    def create!(name, path = nil)
      response = save(build(name, path))
      created_id(response)
    end

    def save(group_representation)
      execute_http do
        RestClient::Resource.new(groups_url, @configuration.rest_client_options).post(
          create_payload(group_representation), headers
        )
      end
    end

    def create_subgroup!(parent_id, name)
      url = "#{groups_url(parent_id)}/children"
      response = execute_http do
        RestClient::Resource.new(url, @configuration.rest_client_options).post(
          create_payload(build(name, nil)), headers
        )
      end
      created_id(response)
    end
    
    def members(group_id, first=0, max=100)
      url = "#{groups_url(group_id)}/members"
      query = {first: first.try(:to_i), max: max.try(:to_i)}.compact
      unless query.empty?
        query_string = query.to_a.map { |e| "#{e[0]}=#{e[1]}" }.join("&")
        url = "#{url}?#{query_string}"
      end
      response = execute_http do
        RestClient::Resource.new(url, @configuration.rest_client_options).get(headers)
      end
      JSON.parse(response).map { |user_as_hash| UserRepresentation.from_hash(user_as_hash) }
    end

    def groups_url(id=nil)
      if id
        "#{@realm_client.realm_admin_url}/groups/#{id}"
      else
        "#{@realm_client.realm_admin_url}/groups"
      end
    end

    private

    def build(name, path)
      group      = GroupRepresentation.new
      group.name = name
      group.path = path
      group
    end
  end
end
