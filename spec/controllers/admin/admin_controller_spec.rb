require 'rails_helper'

RSpec.describe Admin::AdminController, type: :controller do
  let(:admin_user) { create(:user, :admin) }
  let(:regular_user) { create(:user) }

  before do
    # Mock authentication
    allow(controller).to receive(:current_user).and_return(admin_user)
    allow(controller).to receive(:authenticate_user!)
  end

  describe "private methods" do
    describe "#valid_table?" do
      it "returns true for valid table names" do
        %w[users golfers tournaments match_picks match_results scores].each do |table|
          expect(controller.send(:valid_table?, table)).to be(true)
        end
      end

      it "returns false for invalid table names" do
        %w[schema_migrations invalid_table ar_internal_metadata].each do |table|
          expect(controller.send(:valid_table?, table)).to be(false)
        end
      end

      it "returns false for nil or empty table names" do
        expect(controller.send(:valid_table?, nil)).to be(false)
        expect(controller.send(:valid_table?, "")).to be(false)
      end
    end

    describe "#associations_for_table" do
      it "returns correct associations for match_picks" do
        associations = controller.send(:associations_for_table, 'match_picks')
        expect(associations).to eq([ :user, :tournament, :golfer ])
      end

      it "returns correct associations for match_results" do
        associations = controller.send(:associations_for_table, 'match_results')
        expect(associations).to eq([ :user, :tournament ])
      end

      it "returns correct associations for scores" do
        associations = controller.send(:associations_for_table, 'scores')
        expect(associations).to eq([ :match_pick ])
      end

      it "returns empty array for tables without associations" do
        associations = controller.send(:associations_for_table, 'users')
        expect(associations).to eq([])
      end
    end

    describe "#get_table_columns" do
      it "returns column information for User model" do
        columns = controller.send(:get_table_columns, User)

        expect(columns).to be_an(Array)
        expect(columns).not_to be_empty

        email_column = columns.find { |col| col[:name] == 'email' }
        expect(email_column).to be_present
        expect(email_column[:type]).to eq(:string)
        expect(email_column[:null]).to be(false)

        admin_column = columns.find { |col| col[:name] == 'admin' }
        expect(admin_column).to be_present
        expect(admin_column[:type]).to eq(:boolean)
      end

      it "returns column information for Tournament model" do
        columns = controller.send(:get_table_columns, Tournament)

        name_column = columns.find { |col| col[:name] == 'name' }
        expect(name_column).to be_present
        expect(name_column[:type]).to eq(:string)

        year_column = columns.find { |col| col[:name] == 'year' }
        expect(year_column).to be_present
        expect(year_column[:type]).to eq(:integer)
      end
    end

    describe "#record_params" do
      let(:params) do
        ActionController::Parameters.new({
          record: {
            name: "Test User",
            email: "test@example.com",
            admin: true,
            id: 123,
            created_at: Time.current,
            updated_at: Time.current
          }
        })
      end

      before do
        allow(controller).to receive(:params).and_return(params)
      end

      it "permits valid attributes and excludes timestamps and id" do
        permitted = controller.send(:record_params, User)

        expect(permitted['name']).to eq("Test User")
        expect(permitted['email']).to eq("test@example.com")
        expect(permitted['admin']).to be(true)
        expect(permitted.key?('id')).to be(false)
        expect(permitted.key?('created_at')).to be(false)
        expect(permitted.key?('updated_at')).to be(false)
      end

      it "only permits attributes that exist on the model" do
        permitted = controller.send(:record_params, User)

        # Should not include non-existent attributes
        expect(permitted.key?('non_existent_field')).to be(false)
      end
    end
  end

  describe "authentication behavior" do
    context "when user is not admin" do
      before do
        allow(controller).to receive(:current_user).and_return(regular_user)
      end

      it "calls authenticate_admin! and should be forbidden" do
        expect(controller).to receive(:authenticate_admin!)
        get :index
      end
    end

    context "when user is admin" do
      it "allows access to controller actions" do
        expect(controller).to receive(:authenticate_admin!)
        get :index
        # Should not raise an error
      end
    end
  end

  describe "error handling" do
    before do
      allow(controller).to receive(:authenticate_admin!)
    end

    context "when model operations fail" do
      it "handles ActiveRecord::RecordNotFound in update_record" do
        allow(User).to receive(:find).and_raise(ActiveRecord::RecordNotFound)

        put :update_record, params: { table: 'users', id: 999, record: { name: 'Test' } }

        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Record not found')
      end

      it "handles ActiveRecord::RecordNotFound in delete_record" do
        allow(User).to receive(:find).and_raise(ActiveRecord::RecordNotFound)

        delete :delete_record, params: { table: 'users', id: 999 }

        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Record not found')
      end
    end

    context "when invalid table names are provided" do
      it "returns bad request for invalid table in table_data" do
        get :table_data, params: { table: 'invalid_table' }

        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Invalid table')
      end

      it "returns bad request for invalid table in create_record" do
        post :create_record, params: { table: 'invalid_table', record: { name: 'Test' } }

        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Invalid table')
      end
    end
  end
end
