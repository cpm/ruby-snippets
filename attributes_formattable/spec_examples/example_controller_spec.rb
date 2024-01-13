# frozen_string_literal: true

require 'swagger_helper'

describe ExampleController, swagger_doc: 'doc.yaml', type: :request do
  serializer_klass = ExampleSerializer
  rswag_definition = serializer_klass.rswag_definition
  let(:serializer_klass) { serializer_klass }

  subject { response }

  tags_ary = %w[SwaggerTag1 SwaggerTag2]

  url = '/api/examples'

  path url do
    parameter '$ref' => '#/components/parameters/idParam'
    parameter '$ref' => '#/components/parameters/pageAfter'
    parameter '$ref' => '#/components/parameters/pageSize'

    parameter name: 'filter[other_attribute]',
      in: :query,
      schema: { type: :integer },
      required: false,
      description: <<~DESC
        This is a filter not defined in your swagger_helper.rb
      DESC

    get 'Gets list of records' do
      tags *tags_ary
      produces 'application/json'

      response '200', 'records found' do
        schema rswag_definition.as_paginated_array

        let!(:records) do
          # create 2 records for example and to test the id filter
        end

        include_examples "rswag:index:no filters"
        include_examples "rswag:index:filter[id]"

        context 'with filter[other_attribute]' do
          let('filter[other_attribute]') { records.first.other_attribute }
          let(:expected_results) { [records.first] }

          run_test! { expect(response.body).to eq expected_serializer.serializable_hash.to_json }
        end
      end
    end

    post 'Creates a record' do
      consumes 'application/json'
      produces 'application/json'

      tags *tags_ary

      response '201', 'created' do
        schema serializer_klass.rswag_definition.as_single
        parameter name: 'payload', in: :body, schema: rswag_definition.as_create_payload

        let(:payload) do
          json_create_payload('v1/example_serializer',
            other_attriubte: "something"
          )
        end

        run_test! do
          expect(Example.count).to eq 1

          new_record = Example.last
          expect(new_record).to have_attributes(
            # ...
          )

          expect(response.body).to eq serializer_klass.new(new_record).serializable_hash.to_json
        end
      end

      response '401', 'unauthorized' do
        # do bad auth code....
    end
  end

  path url + '/{id}' do
    parameter '$ref' => '#/components/parameters/idPath'

    put 'Updates the record' do
      consumes 'application/json'
      produces 'application/json'

      tags *tags_ary

      let(:id) { record.id }

      response '200', 'updated' do
        schema serializer_klass.rswag_definition.as_single
        parameter name: 'payload', in: :body, schema: rswag_definition.as_create_payload

        let!(:record) do
          create :example
        end

        let(:payload) do
          json_update_payload('v1/example_serializer', record.id,
            # ...
          )
        end

        run_test! do
          expect(record.reload).to have_attributes(
            # ...
          )

          expect(response.body).to eq serializer_klass.new(record.reload).serializable_hash.to_json
        end
      end
    end


    delete 'Deletes the record' do
      tags *tags_ary

      let(:id) { record.id }

      response '204', 'Deleted, no content' do
        let!(:record) do
          create :example
        end

        run_test! do
          expect(Example.exists?(record.id)).to eq false
        end
      end
    end
  end
end
